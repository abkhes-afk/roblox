-- ========================================================================
-- 🧠 BRAINROT WINGS - STEALTH TRADE SIMULATOR PRO (WEB POWERED) 🧠
-- ========================================================================
-- Ce script fonctionne en tâche de fond (Stealth Mode) sans AUCUNE UI Roblox.
-- Toutes les commandes sont reçues en temps réel via WebSockets depuis ton
-- Panel d'Administration Web local !
-- ========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

-- Charger les configurations et utilitaires réels du jeu
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
local AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))

local allAnimalsList = {}
pcall(function()
    local animalsFolder = nil
    -- Essayer plusieurs chemins possibles dans le jeu
    local models = ReplicatedStorage:FindFirstChild("Models")
    if models then
        animalsFolder = models:FindFirstChild("Animals")
    end
    -- Fallback : chercher directement dans ReplicatedStorage
    if not animalsFolder then
        animalsFolder = ReplicatedStorage:FindFirstChild("Animals")
    end
    if not animalsFolder then
        animalsFolder = ReplicatedStorage:FindFirstChild("AnimalModels")
    end
    if animalsFolder then
        local count = 0
        for _, child in ipairs(animalsFolder:GetChildren()) do
            if count >= 200 then break end -- Limiter à 200 pour éviter un paquet trop gros
            if child:IsA("Model") or child:IsA("Folder") or child:IsA("Configuration") then
                table.insert(allAnimalsList, tostring(child.Name))
                count = count + 1
            end
        end
        table.sort(allAnimalsList)
    end
end)

local fakeItemsList = {}
local isFakeReady = false
local isYourFakeReady = false
local isFakeAccepted = false
local isYourFakeAccepted = false

local function isTradeActive()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    local screenGui = playerGui and playerGui:FindFirstChild("TradeLiveTrade")
    if screenGui and screenGui.Enabled then
        local mainFrame = screenGui:FindFirstChild("TradeLiveTrade")
        if mainFrame and mainFrame.Visible then
            return true
        end
    end
    return false
end

local function getLiveTradeGui()
    local playerGui = localPlayer:WaitForChild("PlayerGui", 5)
    local liveTrade = playerGui and playerGui:FindFirstChild("TradeLiveTrade")
    local mainFrame = liveTrade and liveTrade:FindFirstChild("TradeLiveTrade")
    return mainFrame
end

local function findIndexByDisplayName(displayName)
    local lname = string.lower(displayName)
    for idx, info in pairs(AnimalsData) do
        if info and info.DisplayName and string.lower(info.DisplayName) == lname then
            return idx
        end
        if string.lower(idx) == lname then return idx end
    end
    return displayName
end

local function getComputedIncome(animalName, mutation)
    if not animalName or animalName == "" then
        return 0, "$0/s"
    end
    local index = findIndexByDisplayName(animalName)
    
    local internalMutation = mutation
    if mutation == "Normal" or mutation == "" then
        internalMutation = nil
    elseif mutation == "Golden" then
        internalMutation = "Gold"
    end
    
    local ok, value = pcall(function()
        return AnimalsShared:GetGeneration(index, internalMutation, {}, nil)
    end)
    if ok and type(value) == "number" then
        return value, "$" .. NumberUtils:ToString(value) .. "/s"
    end
    return 0, "$0/s"
end

local function simulateAddBrainrot(animalName, mutation)
    if not animalName or animalName == "" then
        warn("Erreur : Nom du Brainrot vide !")
        return false
    end
    
    local tradeFrame = getLiveTradeGui()
    if not tradeFrame then
        warn("Erreur : Lance d'abord un trade avec quelqu'un !")
        return false
    end
    
    local other = tradeFrame:FindFirstChild("Other")
    local scroll = other and other:FindFirstChild("ScrollingFrame")
    if not scroll then
        warn("Erreur : ScrollingFrame de l'autre joueur introuvable.")
        return false
    end
    
    local template = nil
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Template" and child.Visible == false then
            template = child
            break
        end
    end
    if not template then template = scroll:FindFirstChild("Template") end
    if not template then
        warn("Erreur : Template de base introuvable dans ScrollingFrame.")
        return false
    end
    
    local _, incomeText = getComputedIncome(animalName, mutation)
    
    local clone = template:Clone()
    clone.Name = "FakeAdd_" .. animalName:gsub("%s+", "")
    clone.Visible = true
    clone.Parent = scroll
    
    local spacer = clone:FindFirstChild("Spacer")
    if spacer then
        local title = spacer:FindFirstChild("Title")
        local cash = spacer:FindFirstChild("Cash")
        
        if title then title.Text = animalName end
        if cash then cash.Text = incomeText end
        
        local viewport = spacer:FindFirstChild("ViewportFrame")
        if viewport then
            for _, c in ipairs(viewport:GetChildren()) do
                if c:IsA("WorldModel") or c:IsA("Camera") then c:Destroy() end
            end
            
            local internalMutation = mutation
            if mutation == "Normal" or mutation == "" then
                internalMutation = "Default"
            elseif mutation == "Golden" then
                internalMutation = "Gold"
            end
            
            pcall(function()
                AnimalsShared:AttachOnViewportWithOptimizations(animalName, viewport, nil, internalMutation, nil)
            end)
        end
    end
    
    table.insert(fakeItemsList, clone)
    -- Ajout simulé réussi
    return true
end

local function simulateAddPancarteText(text)
    local tradeFrame = getLiveTradeGui()
    if not tradeFrame then return false end
    
    local otherSign = tradeFrame:FindFirstChild("OtherSign")
    local holder = otherSign and otherSign:FindFirstChild("Holder")
    local frame = holder and holder:FindFirstChild("Frame")
    local textBox = frame and frame:FindFirstChild("TextBox")
    
    if textBox then
        textBox.Text = text
        -- Pancarte réglée
        return true
    end
    warn("Erreur : Zone d'entrée pancarte (OtherSign) introuvable.")
    return false
end

local function simulateReady(state)
    local tradeFrame = getLiveTradeGui()
    if not tradeFrame then return false end
    
    local other = tradeFrame:FindFirstChild("Other")
    local readyFrame = other and other:FindFirstChild("Ready")
    if readyFrame then
        readyFrame.Visible = state
        local label = readyFrame:FindFirstChild("Label")
        if label then label.Text = "Ready!" end
        -- Ready simulé
        return true
    end
    warn("Erreur : Overlay de ready de l'autre joueur introuvable.")
    return false
end

-- ========================================================================
-- SYSTEME DE COMPTE A REBOURS DE SECURITE DU TRADE (5 SECONDES)
-- ========================================================================
local timerConnections = {}

local function clearTimerConnections()
    for _, conn in ipairs(timerConnections) do
        pcall(function() conn:Disconnect() end)
    end
    timerConnections = {}
end

local function getSecondsFromText(text)
    local secStr = text:match("(%d+%.?%d*)")
    return secStr and tonumber(secStr) or 0
end

local function startTradeCountdown()
    local tradeFrame = getLiveTradeGui()
    if not tradeFrame then return end
    
    local timerLabel = tradeFrame:FindFirstChild("Other") and tradeFrame.Other:FindFirstChild("Timer")
    if not timerLabel then return end
    
    _G.currentTradeCountdown = os.clock()
    local myCountdown = _G.currentTradeCountdown
    clearTimerConnections()
    
    local isCountdownActive = true
    local currentCountdownText = ""
    
    table.insert(timerConnections, timerLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if isCountdownActive then
            local currentText = timerLabel.Text
            if currentText ~= currentCountdownText and currentText ~= "" then
                local sec = getSecondsFromText(currentText)
                local timeSinceFakeAdd = _G.lastFakeAddTimestamp and (os.clock() - _G.lastFakeAddTimestamp)
                
                if sec > 4.6 or (not timeSinceFakeAdd or timeSinceFakeAdd >= 5) then
                    isCountdownActive = false
                    clearTimerConnections()
                    -- Yielded to real timer
                    return
                end
            end
            
            if currentText ~= currentCountdownText then
                timerLabel.Text = currentCountdownText
            end
        end
    end))
    
    table.insert(timerConnections, timerLabel:GetPropertyChangedSignal("Visible"):Connect(function()
        if isCountdownActive and not timerLabel.Visible then
            timerLabel.Visible = true
        end
    end))
    
    task.spawn(function()
        timerLabel.Visible = true
        local startTime = os.clock()
        while true do
            if not isCountdownActive then
                break
            end
            
            if isYourFakeReady or isYourFakeAccepted or isFakeReady or isFakeAccepted then
                break
            end
            
            local elapsed = os.clock() - startTime
            local timeLeft = 5 - elapsed
            if timeLeft <= 0 then
                break
            end
            
            if _G.currentTradeCountdown ~= myCountdown then
                return
            end
            
            if not getLiveTradeGui() then
                isCountdownActive = false
                clearTimerConnections()
                return
            end
            
            local displayVal = math.floor(timeLeft * 10) / 10
            currentCountdownText = ("\226\143\176%ss Left"):format(tostring(displayVal))
            timerLabel.Text = currentCountdownText
            task.wait(0.05)
        end
        isCountdownActive = false
        clearTimerConnections()
        timerLabel.Text = ""
        timerLabel.Visible = true
    end)
end

-- ========================================================================
-- SYSTEME DE COMMUNICATION WEBSOCKET (BRIDGE NAVIGATEUR)
-- ========================================================================
local HttpService = game:GetService("HttpService")
local socket = nil

local connectWS = WebSocket and WebSocket.connect or (syn and syn.websocket and syn.websocket.connect)

local function getOfferItems(side)
    local liveTrade = getLiveTradeGui()
    local scroll = liveTrade and liveTrade:FindFirstChild(side) and liveTrade[side]:FindFirstChild("ScrollingFrame")
    local items = {}
    
    if scroll then
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") and child.Visible then
                local spacer = child:FindFirstChild("Spacer")
                local title = spacer and spacer:FindFirstChild("Title")
                local cash = spacer and spacer:FindFirstChild("Cash")
                
                if title and cash then
                    table.insert(items, {
                        name = title.Text,
                        value = cash.Text,
                        isFake = child.Name:match("^FakeAdd_") ~= nil
                    })
                end
            end
        end
    end
    return items
end

local function sendTradeUpdate()
    if not socket then return end
    
    local liveTrade = getLiveTradeGui()
    local otherName = "Inconnu"
    if liveTrade then
        local other = liveTrade:FindFirstChild("Other")
        if other then
            -- 1. Chercher dans Other.Username (ex: "@pmR_sab12's Offer")
            local usernameLabel = other:FindFirstChild("Username")
            if usernameLabel and usernameLabel:IsA("TextLabel") then
                local text = usernameLabel.Text
                if text:match("^@") then
                    otherName = text:gsub("^@", ""):gsub("'[Ss]%s?[Oo][Ff][Ff][Ee][Rr]$", "")
                else
                    otherName = text:gsub("'[Ss]%s?[Oo][Ff][Ff][Ee][Rr]$", "")
                end
            end
        end
        
        -- 2. Fallback sur OtherSign.Username (propre, ex: "@pmR_sab12")
        if otherName == "Inconnu" then
            local otherSign = liveTrade:FindFirstChild("OtherSign")
            if otherSign then
                local signUser = otherSign:FindFirstChild("Username")
                if signUser and signUser:IsA("TextLabel") then
                    local text = signUser.Text
                    if text:match("^@") then
                        otherName = text:gsub("^@", "")
                    elseif text ~= "" then
                        otherName = text
                    end
                end
            end
        end
    end
    
    local yourOfferItems = getOfferItems("Your")
    local otherOfferItems = getOfferItems("Other")
    
    pcall(function()
        socket:Send(HttpService:JSONEncode({
            type = "trade_update",
            inTrade = isTradeActive(),
            otherPlayer = otherName,
            fakeItemsCount = #fakeItemsList,
            isYourReady = isYourFakeReady,
            isOtherReady = isFakeReady,
            yourOffer = yourOfferItems,
            otherOffer = otherOfferItems
        }))
    end)
end

-- Configuration : change cette URL pour pointer vers ton serveur Railway
-- Exemple Railway : _G.TRADE_SERVER_URL = "wss://ton-projet.up.railway.app"
local SERVER_URL = (_G.TRADE_SERVER_URL or "wss://web-production-9ec54.up.railway.app")

local function connectToDashboard()
    if not connectWS then
        warn("[WEBSOCKET] Votre exécuteur ne supporte pas les WebSockets.")
        return
    end
    
    local urlsToTry = {SERVER_URL}
    -- Fallback sur localhost si Railway ne marche pas
    if SERVER_URL ~= "ws://localhost:3000" then
        table.insert(urlsToTry, "ws://localhost:3000")
    end
    
    for _, baseUrl in ipairs(urlsToTry) do
        local clientId = tostring(localPlayer.UserId)
        local wsUrl = baseUrl .. "/roblox?type=roblox&clientId=" .. clientId
        
        local success, ws = pcall(function()
            return connectWS(wsUrl)
        end)
        
        if success and ws then
            socket = ws
            break
        else
            warn("[WEBSOCKET] Échec connexion à " .. baseUrl .. " : " .. tostring(ws))
        end
    end
    
    if not socket then
        warn("[WEBSOCKET] Toutes les tentatives de connexion ont échoué. Vérifie que le serveur est lancé (node server.js) ou que l'URL Railway est accessible.")
        task.wait(10)
        connectToDashboard()
        return
    end
    
    -- WebSocket connecté
    
    pcall(function()
        socket:Send(HttpService:JSONEncode({
            type = "init",
            username = localPlayer.Name,
            displayName = localPlayer.DisplayName,
            userId = localPlayer.UserId,
            placeId = tostring(game.PlaceId),
            animalsList = allAnimalsList,
            inTrade = isTradeActive(),
            otherPlayer = nil,
            fakeItemsCount = 0
        }))
    end)
    
    socket.OnMessage:Connect(function(message)
        local ok, data = pcall(function() return HttpService:JSONDecode(message) end)
        if not ok or not data then return end
        
        -- Commande reçue
        
        if data.action == "add_fake_pet" then
            local petName = data.petName
            local petMutation = data.petMutation
            local successAdd = simulateAddBrainrot(petName, petMutation)
            if successAdd then
                _G.lastFakeAddTimestamp = os.clock()
                startTradeCountdown()
            end
            sendTradeUpdate()
            
        elseif data.action == "set_sign_text" then
            simulateAddPancarteText(data.text)
            sendTradeUpdate()
            
        elseif data.action == "toggle_other_ready" then
            isFakeReady = data.state
            simulateReady(isFakeReady)
            sendTradeUpdate()
            
        elseif data.action == "toggle_my_ready" then
            isYourFakeReady = data.state
            sendTradeUpdate()
            
        elseif data.action == "force_accept" then
            isYourFakeAccepted = true
            isFakeAccepted = true
            sendTradeUpdate()
            
        elseif data.action == "cancel_trade" then
            local liveTrade = getLiveTradeGui()
            local other = liveTrade and liveTrade:FindFirstChild("Other")
            local cancelBtn = other and other:FindFirstChild("Cancel")
            if cancelBtn then
                pcall(function()
                    cancelBtn.Activated:Fire()
                    cancelBtn.MouseButton1Click:Fire()
                end)
            end
            resetFakeTradeState()
            sendTradeUpdate()
            
        elseif data.action == "remove_fake_pet" then
            local petName = data.petName
            for idx, item in ipairs(fakeItemsList) do
                if item and (item.Name == "FakeAdd_" .. petName:gsub("%s+", "") or item:FindFirstChild("Spacer") and item.Spacer:FindFirstChild("Title") and item.Spacer.Title.Text == petName) then
                    pcall(function() item:Destroy() end)
                    table.remove(fakeItemsList, idx)
                    break
                end
            end
            sendTradeUpdate()
            
        elseif data.action == "reset_trade" then
            resetFakeTradeState()
            sendTradeUpdate()
        end
    end)
    
    socket.OnClose:Connect(function()
        -- WebSocket déconnecté, reconnexion dans 5s
        socket = nil
        task.wait(5)
        connectToDashboard()
    end)
end

task.spawn(connectToDashboard)

-- ========================================================================
-- SYSTEME DE DETECTION ET RESET AUTOMATIQUE EN FIN DE TRADE
-- ========================================================================
local lastTradeState = false

local function resetFakeTradeState()
    for _, item in ipairs(fakeItemsList) do
        if item and item.Parent then
            pcall(function() item:Destroy() end)
        end
    end
    fakeItemsList = {}
    
    pcall(function()
        local playerGui = localPlayer:FindFirstChild("PlayerGui")
        local screenGui = playerGui and playerGui:FindFirstChild("TradeLiveTrade")
        local mainFrame = screenGui and screenGui:FindFirstChild("TradeLiveTrade")
        local other = mainFrame and mainFrame:FindFirstChild("Other")
        local scroll = other and other:FindFirstChild("ScrollingFrame")
        if scroll then
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("^FakeAdd_") then
                    child:Destroy()
                end
            end
        end
    end)
    
    isFakeReady = false
    isYourFakeReady = false
    isFakeAccepted = false
    isYourFakeAccepted = false
end

local function getOfferItemsCount(side)
    local liveTrade = getLiveTradeGui()
    local scroll = liveTrade and liveTrade:FindFirstChild(side) and liveTrade[side]:FindFirstChild("ScrollingFrame")
    local count = 0
    if scroll then
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") and child.Visible then
                count = count + 1
            end
        end
    end
    return count
end

local lastSentYourReady = nil
local lastSentOtherReady = nil
local lastSentItemsCount = nil
local lastSentYourCount = nil
local lastSentOtherCount = nil

RunService.RenderStepped:Connect(function()
    local currentTradeState = isTradeActive()
    
    if currentTradeState ~= lastTradeState then
        resetFakeTradeState()
        if currentTradeState == false then
            -- Trade terminé, simulation nettoyée
        else
            -- Nouveau trade détecté
        end
        sendTradeUpdate()
    end
    lastTradeState = currentTradeState
    
    if currentTradeState then
        local currentYourCount = getOfferItemsCount("Your")
        local currentOtherCount = getOfferItemsCount("Other")
        
        if isYourFakeReady ~= lastSentYourReady or isFakeReady ~= lastSentOtherReady or #fakeItemsList ~= lastSentItemsCount or currentYourCount ~= lastSentYourCount or currentOtherCount ~= lastSentOtherCount then
            lastSentYourReady = isYourFakeReady
            lastSentOtherReady = isFakeReady
            lastSentItemsCount = #fakeItemsList
            lastSentYourCount = currentYourCount
            lastSentOtherCount = currentOtherCount
            sendTradeUpdate()
        end
        
        local liveTrade = getLiveTradeGui()
        local readyButton = liveTrade and liveTrade:FindFirstChild("Other") and liveTrade.Other:FindFirstChild("ReadyButton")
        
        if #fakeItemsList > 0 then
            if readyButton and not readyButton:GetAttribute("FakeHooked") then
                readyButton:SetAttribute("FakeHooked", true)
                local function onReadyClick()
                    local isTimerActive = _G.currentTradeCountdown and (os.clock() - _G.currentTradeCountdown < 5)
                    if not isTimerActive then
                        local buttonTextLabel = readyButton:FindFirstChild("Txt")
                        local buttonText = buttonTextLabel and buttonTextLabel.Text or ""
                        
                        if buttonText == "ACCEPT" then
                            isYourFakeAccepted = true
                            -- Your accepted toggled
                            
                            task.spawn(function()
                                task.wait(1.5)
                                if getLiveTradeGui() and #fakeItemsList > 0 then
                                    isFakeAccepted = true
                                    -- Other accepted toggled
                                end
                            end)
                        else
                            isYourFakeReady = not isYourFakeReady
                            -- Your ready toggled
                        end
                    end
                end
                table.insert(timerConnections, readyButton.Activated:Connect(onReadyClick))
                table.insert(timerConnections, readyButton.MouseButton1Click:Connect(onReadyClick))
            end
            
            local otherReady = liveTrade and liveTrade:FindFirstChild("Other") and liveTrade.Other:FindFirstChild("Ready")
            local yourReady = liveTrade and liveTrade:FindFirstChild("Your") and liveTrade.Your:FindFirstChild("Ready")
            
            if otherReady then
                local shouldShowOther = isFakeReady or isFakeAccepted
                if shouldShowOther then
                    if not otherReady.Visible then
                        otherReady.Visible = true
                    end
                    local lbl = otherReady:FindFirstChild("Label")
                    if lbl then
                        local expectedText = isFakeAccepted and "Confirmed!" or "Ready!"
                        if lbl.Text ~= expectedText then lbl.Text = expectedText end
                    end
                end
            end
            
            if yourReady then
                local shouldShowYour = isYourFakeReady or isYourFakeAccepted
                if shouldShowYour then
                    if not yourReady.Visible then
                        yourReady.Visible = true
                    end
                    local lbl = yourReady:FindFirstChild("Label")
                    if lbl then
                        local expectedText = isYourFakeAccepted and "Confirmed!" or "Ready!"
                        if lbl.Text ~= expectedText then lbl.Text = expectedText end
                    end
                end
            end
        else
            if readyButton and readyButton:GetAttribute("FakeHooked") then
                readyButton:SetAttribute("FakeHooked", nil)
            end
            clearTimerConnections()
        end
    end
end)

-- Script chargé silencieusement
