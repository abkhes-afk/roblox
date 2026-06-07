-- ============================================================
--  SCRIPT: Ramper (Crawl / Prone)
--  UI deplacable + fermable + toggle + slider vitesse
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrawlUI"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 210, 0, 160)
MainFrame.Position = UDim2.new(0.5, -105, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(140, 70, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Titre
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, -30, 0, 28)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Ramper"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Parent = TitleBar

-- Bouton X
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 2)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Separateur
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -16, 0, 1)
Separator.Position = UDim2.new(0, 8, 0, 30)
Separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Separator.BorderSizePixel = 0
Separator.Parent = MainFrame

-- Label Ramper
local CrawlLabel = Instance.new("TextLabel")
CrawlLabel.Size = UDim2.new(0, 100, 0, 24)
CrawlLabel.Position = UDim2.new(0, 12, 0, 37)
CrawlLabel.BackgroundTransparency = 1
CrawlLabel.Text = "Ramper"
CrawlLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
CrawlLabel.Font = Enum.Font.GothamSemibold
CrawlLabel.TextSize = 14
CrawlLabel.TextXAlignment = Enum.TextXAlignment.Left
CrawlLabel.Parent = MainFrame

-- Toggle
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 44, 0, 24)
ToggleButton.Position = UDim2.new(1, -56, 0, 37)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = ""
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleButton

local ToggleDot = Instance.new("Frame")
ToggleDot.Size = UDim2.new(0, 18, 0, 18)
ToggleDot.Position = UDim2.new(0, 3, 0, 3)
ToggleDot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
ToggleDot.BorderSizePixel = 0
ToggleDot.Parent = ToggleButton

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(0, 9)
DotCorner.Parent = ToggleDot

-- Label Vitesse
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 50, 0, 20)
SpeedLabel.Position = UDim2.new(0, 12, 0, 68)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Vitesse"
SpeedLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.TextSize = 12
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = MainFrame

-- Valeur vitesse
local SpeedValue = Instance.new("TextLabel")
SpeedValue.Size = UDim2.new(0, 40, 0, 20)
SpeedValue.Position = UDim2.new(1, -52, 0, 68)
SpeedValue.BackgroundTransparency = 1
SpeedValue.Text = "16"
SpeedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedValue.Font = Enum.Font.GothamBold
SpeedValue.TextSize = 12
SpeedValue.TextXAlignment = Enum.TextXAlignment.Right
SpeedValue.Parent = MainFrame

-- Slider track
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -24, 0, 6)
SliderTrack.Position = UDim2.new(0, 12, 0, 92)
SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = MainFrame

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(0, 3)
TrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.32, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(140, 70, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 3)
FillCorner.Parent = SliderFill

local SliderDot = Instance.new("TextButton")
SliderDot.Size = UDim2.new(0, 14, 0, 14)
SliderDot.Position = UDim2.new(0.32, -7, 0.5, -7)
SliderDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderDot.BorderSizePixel = 0
SliderDot.Text = ""
SliderDot.AutoButtonColor = false
SliderDot.Parent = SliderTrack

local SliderDotCorner = Instance.new("UICorner")
SliderDotCorner.CornerRadius = UDim.new(0, 7)
SliderDotCorner.Parent = SliderDot

-- Separateur 2
local Separator2 = Instance.new("Frame")
Separator2.Size = UDim2.new(1, -16, 0, 1)
Separator2.Position = UDim2.new(0, 8, 0, 105)
Separator2.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Separator2.BorderSizePixel = 0
Separator2.Parent = MainFrame

-- Label Float
local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size = UDim2.new(0, 100, 0, 24)
FloatLabel.Position = UDim2.new(0, 12, 0, 112)
FloatLabel.BackgroundTransparency = 1
FloatLabel.Text = "Float"
FloatLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
FloatLabel.Font = Enum.Font.GothamSemibold
FloatLabel.TextSize = 14
FloatLabel.TextXAlignment = Enum.TextXAlignment.Left
FloatLabel.Parent = MainFrame

-- Toggle Float
local FloatToggle = Instance.new("TextButton")
FloatToggle.Size = UDim2.new(0, 44, 0, 24)
FloatToggle.Position = UDim2.new(1, -56, 0, 112)
FloatToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
FloatToggle.BorderSizePixel = 0
FloatToggle.Text = ""
FloatToggle.AutoButtonColor = false
FloatToggle.Parent = MainFrame

local FloatToggleCorner = Instance.new("UICorner")
FloatToggleCorner.CornerRadius = UDim.new(0, 12)
FloatToggleCorner.Parent = FloatToggle

local FloatToggleDot = Instance.new("Frame")
FloatToggleDot.Size = UDim2.new(0, 18, 0, 18)
FloatToggleDot.Position = UDim2.new(0, 3, 0, 3)
FloatToggleDot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
FloatToggleDot.BorderSizePixel = 0
FloatToggleDot.Parent = FloatToggle

local FloatDotCorner = Instance.new("UICorner")
FloatDotCorner.CornerRadius = UDim.new(0, 9)
FloatDotCorner.Parent = FloatToggleDot

-- ============================================================
--  ETAT
-- ============================================================
local isCrawling = false
local isFloating = false
local crawlSpeed = 16
local turnSpeed = 3
local lastYaw = 0
local bodyGyros = {}
local bodyVelocities = {}
local noCollideParts = {}
local crawlConnection = nil

-- ============================================================
--  SLIDER
-- ============================================================
local isDraggingSlider = false

local function updateSlider(inputX)
    local trackX = SliderTrack.AbsolutePosition.X
    local trackW = SliderTrack.AbsoluteSize.X
    local frac = math.clamp((inputX - trackX) / trackW, 0, 1)
    crawlSpeed = math.floor(4 + frac * 46)
    SpeedValue.Text = tostring(crawlSpeed)
    SliderFill.Size = UDim2.new(frac, 0, 1, 0)
    SliderDot.Position = UDim2.new(frac, -7, 0.5, -7)
end

SliderDot.MouseButton1Down:Connect(function() isDraggingSlider = true end)
SliderTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = true
        updateSlider(i.Position.X)
    end
end)
UIS.InputChanged:Connect(function(i)
    if isDraggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(i.Position.X)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingSlider = false end
end)

-- ============================================================
--  RAMPEMENT
-- ============================================================
local function groundY(pos)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {LocalPlayer.Character}
    local r = workspace:Raycast(pos + Vector3.new(0,5,0), Vector3.new(0,-20,0), rp)
    return r and r.Position.Y or pos.Y - 3
end

local function startCrawling()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    -- Sauvegarder le yaw actuel
    local cam = workspace.CurrentCamera
    local ld = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
    local fl = Vector3.new(ld.X, 0, ld.Z)
    if fl.Magnitude < 0.01 then fl = Vector3.new(0,0,-1) end
    fl = fl.Unit
    lastYaw = math.atan2(fl.X, fl.Z)

    -- BodyGyro + BodyVelocity SEULEMENT sur HRP, autres parties Massless
    bodyGyros = {}
    bodyVelocities = {}
    noCollideParts = {}

    -- Rendre toutes les parties sans collision et sans masse
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            if part ~= hrp then
                part.Massless = true
            end
            table.insert(noCollideParts, part)
        end
    end

    -- BodyGyro sur le HRP
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 500000
    bg.D = 5000
    bg.Parent = hrp
    table.insert(bodyGyros, bg)

    -- BodyVelocity sur le HRP uniquement
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(40000, 40000, 40000)
    bv.Velocity = Vector3.zero
    bv.P = 2000
    bv.Parent = hrp
    table.insert(bodyVelocities, bv)

    crawlConnection = RunService.RenderStepped:Connect(function()
        if not isCrawling then return end
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end

        local gy = groundY(h.Position)
        local targetY = gy + 0.5

        -- Mouvement camera-relative
        local cam = workspace.CurrentCamera
        local ld = cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
        local camForward = Vector3.new(ld.X, 0, ld.Z)
        if camForward.Magnitude < 0.01 then camForward = Vector3.new(0,0,-1) end
        camForward = camForward.Unit
        local camRight = Vector3.new(camForward.Z, 0, -camForward.X).Unit

        local md = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then md = md + camForward end
        if UIS:IsKeyDown(Enum.KeyCode.S) then md = md - camForward end
        if UIS:IsKeyDown(Enum.KeyCode.A) then md = md + camRight end
        if UIS:IsKeyDown(Enum.KeyCode.D) then md = md - camRight end
        if md.Magnitude > 0 then md = md.Unit end

        -- Rotation ventre au sol (fromMatrix: right, up, look)
        local fwd = Vector3.new(math.sin(lastYaw), 0, math.cos(lastYaw))
        local rgt = Vector3.new(fwd.Z, 0, -fwd.X)
        local dwn = Vector3.new(0, -1, 0)
        local gyroCF = CFrame.fromMatrix(h.Position, rgt, fwd, dwn)
        for _, bg in ipairs(bodyGyros) do
            if bg and bg.Parent then
                bg.CFrame = gyroCF
            end
        end

        -- Coller au sol + mouvement
        local dy = targetY - h.Position.Y
        local vy = dy * 60
        local vel = Vector3.new(md.X * crawlSpeed, vy, md.Z * crawlSpeed)
        for _, bv in ipairs(bodyVelocities) do
            if bv and bv.Parent then
                bv.Velocity = vel
            end
        end
    end)
end

local function stopCrawling()
    if crawlConnection then crawlConnection:Disconnect(); crawlConnection = nil end
    for _, bg in ipairs(bodyGyros) do
        if bg then bg:Destroy() end
    end
    bodyGyros = {}
    for _, bv in ipairs(bodyVelocities) do
        if bv then bv:Destroy() end
    end
    bodyVelocities = {}
    -- Restaurer les collisions et la masse
    for _, part in ipairs(noCollideParts) do
        if part and part.Parent then
            part.CanCollide = true
            part.Massless = false
        end
    end
    noCollideParts = {}

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ============================================================
--  FLOAT
-- ============================================================
local function doFloat()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bvFloat = Instance.new("BodyVelocity")
    bvFloat.MaxForce = Vector3.new(0, 200000, 0)
    bvFloat.Velocity = Vector3.new(0, 80, 0)
    bvFloat.P = 5000
    bvFloat.Parent = hrp
    task.delay(0.4, function()
        if bvFloat then bvFloat:Destroy() end
    end)
end

local function updateFloatVisual()
    if isFloating then
        FloatToggle.BackgroundColor3 = Color3.fromRGB(140, 70, 255)
        FloatToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FloatToggleDot.Position = UDim2.new(1, -21, 0, 3)
    else
        FloatToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        FloatToggleDot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        FloatToggleDot.Position = UDim2.new(0, 3, 0, 3)
    end
end

FloatToggle.MouseButton1Click:Connect(function()
    isFloating = not isFloating
    updateFloatVisual()
    if isFloating then
        doFloat()
        task.delay(0.5, function()
            isFloating = false
            updateFloatVisual()
        end)
    end
end)

-- ============================================================
--  TOGGLE VISUEL
-- ============================================================
local function updateToggleVisual()
    if isCrawling then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(140, 70, 255)
        ToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleDot.Position = UDim2.new(1, -21, 0, 3)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        ToggleDot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        ToggleDot.Position = UDim2.new(0, 3, 0, 3)
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    isCrawling = not isCrawling
    updateToggleVisual()
    if isCrawling then startCrawling() else stopCrawling() end
end)

CloseButton.MouseButton1Click:Connect(function()
    isCrawling = false
    stopCrawling()
    ScreenGui:Destroy()
end)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function()
    if isCrawling then stopCrawling(); task.wait(0.5); startCrawling() end
end)

-- RightShift = hide/show UI
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then ScreenGui.Enabled = not ScreenGui.Enabled end
end)

print("[Ramper] Charge !")
