-- ============================================================
--  ESP: Box 2D + Skeleton + Name
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local espObjects = {}
local teamCheck = false -- set to true to ignore teammates

local function worldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function createESP(player)
    if player == LocalPlayer then return end

    local function setup()
        local char = player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then return end

        -- Box 2D
        local box = Drawing.new("Square")
        box.Visible = false
        box.Thickness = 1
        box.Filled = false
        box.Color = Color3.fromRGB(255, 255, 255)

        -- Name tag
        local nameTag = Drawing.new("Text")
        nameTag.Visible = false
        nameTag.Size = 14
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Font = 2 -- SourceSansBold

        -- Skeleton lines (15 connections between body parts)
        local skeletonLines = {}
        local bonePairs = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
        }

        for _ = 1, #bonePairs do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Thickness = 1.5
            line.Color = Color3.fromRGB(255, 255, 255)
            table.insert(skeletonLines, line)
        end

        espObjects[player] = {
            box = box,
            nameTag = nameTag,
            skeletonLines = skeletonLines,
            bonePairs = bonePairs,
            root = root,
            head = head,
            hum = hum,
        }
    end

    setup()
    player.CharacterAdded:Connect(function()
        cleanup(player)
        setup()
    end)
end

local function cleanup(player)
    local obj = espObjects[player]
    if not obj then return end
    if obj.box then obj.box:Remove() end
    if obj.nameTag then obj.nameTag:Remove() end
    for _, line in ipairs(obj.skeletonLines) do
        line:Remove()
    end
    espObjects[player] = nil
end

local function updateESP()
    for player, obj in pairs(espObjects) do
        local char = player.Character
        if not char or not obj.root or not obj.root.Parent then
            cleanup(player)
            continue
        end

        if teamCheck and player.Team == LocalPlayer.Team then
            obj.box.Visible = false
            obj.nameTag.Visible = false
            for _, line in ipairs(obj.skeletonLines) do
                line.Visible = false
            end
            continue
        end

        local hum = obj.hum
        if hum.Health <= 0 then
            obj.box.Visible = false
            obj.nameTag.Visible = false
            for _, line in ipairs(obj.skeletonLines) do
                line.Visible = false
            end
            continue
        end

        -- Box 2D calculation
        local charParts = {}
        for _, part in char:GetChildren() do
            if part:IsA("BasePart") and part ~= obj.root then
                table.insert(charParts, part)
            end
        end

        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local allOffScreen = true

        for _, part in charParts do
            local pos, onScreen = worldToScreen(part.Position)
            if onScreen then
                allOffScreen = false
                if pos.X < minX then minX = pos.X end
                if pos.Y < minY then minY = pos.Y end
                if pos.X > maxX then maxX = pos.X end
                if pos.Y > maxY then maxY = pos.Y end
            end
        end

        -- Also include root and head
        local rootPos, rootOnScreen = worldToScreen(obj.root.Position)
        local headPos, headOnScreen = worldToScreen(obj.head.Position)

        if rootOnScreen then
            allOffScreen = false
            if rootPos.X < minX then minX = rootPos.X end
            if rootPos.Y < minY then minY = rootPos.Y end
            if rootPos.X > maxX then maxX = rootPos.X end
            if rootPos.Y > maxY then maxY = rootPos.Y end
        end

        if allOffScreen then
            obj.box.Visible = false
            obj.nameTag.Visible = false
            for _, line in ipairs(obj.skeletonLines) do
                line.Visible = false
            end
            continue
        end

        -- Draw box
        obj.box.Position = Vector2.new(minX, minY)
        obj.box.Size = Vector2.new(maxX - minX, maxY - minY)
        obj.box.Visible = true

        -- Draw name (scales with distance)
        local headScreenPos, headOnScreen = worldToScreen(obj.head.Position + Vector3.new(0, 1.5, 0))
        local dist = (Camera.CFrame.Position - obj.root.Position).Magnitude
        local scale = math.clamp(200 / dist, 10, 24)
        obj.nameTag.Size = scale
        obj.nameTag.Text = player.DisplayName
        obj.nameTag.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
        obj.nameTag.Visible = headOnScreen

        -- Draw skeleton
        for i, pair in ipairs(obj.bonePairs) do
            local partA = char:FindFirstChild(pair[1])
            local partB = char:FindFirstChild(pair[2])
            local line = obj.skeletonLines[i]

            if partA and partB then
                local posA, onScreenA = worldToScreen(partA.Position)
                local posB, onScreenB = worldToScreen(partB.Position)

                if onScreenA and onScreenB then
                    line.From = posA
                    line.To = posB
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

-- Connect players
for _, player in Players:GetPlayers() do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    cleanup(player)
end)

-- Render loop
RunService.RenderStepped:Connect(updateESP)
