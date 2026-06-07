-- Hub Custom: Instant Steal, Ragdoll & Speed Bypass
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Supprimer l'ancienne GUI si elle existe déjà
if CoreGui:FindFirstChild("CustomBrainrotUI") then
    CoreGui.CustomBrainrotUI:Destroy()
end

-- Création de la GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomBrainrotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 180) -- Plus grand pour le 3ème bouton
Frame.Position = UDim2.new(0.5, -100, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Brainrot Hacks"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = Frame

-- Variables d'état
local instantStealEnabled = false
local ragdollEnabled = false
local speedBypassEnabled = false

local stealLoop
local speedLoop

-- Nettoyage à la fermeture
CloseBtn.MouseButton1Click:Connect(function()
    instantStealEnabled = false
    ragdollEnabled = false
    speedBypassEnabled = false
    if stealLoop then task.cancel(stealLoop) end
    if speedLoop then speedLoop:Disconnect() end
    ScreenGui:Destroy()
end)

-- =====================================
-- INSTANT STEAL (Aura)
-- =====================================
local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(0.8, 0, 0, 35)
StealBtn.Position = UDim2.new(0.1, 0, 0, 40)
StealBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
StealBtn.Text = "Instant Steal: OFF"
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Font = Enum.Font.GothamSemibold
StealBtn.TextSize = 14
StealBtn.Parent = Frame

local UICornerSteal = Instance.new("UICorner")
UICornerSteal.Parent = StealBtn

StealBtn.MouseButton1Click:Connect(function()
    instantStealEnabled = not instantStealEnabled
    if instantStealEnabled then
        StealBtn.Text = "Instant Steal: ON"
        StealBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        stealLoop = task.spawn(function()
            while instantStealEnabled do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, prompt in pairs(Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local txt = prompt.ActionText:lower()
                            if txt:match("grab") or txt:match("steal") or txt:match("collect") then
                                local pos = nil
                                if prompt.Parent:IsA("BasePart") then pos = prompt.Parent.Position
                                elseif prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart then pos = prompt.Parent.PrimaryPart.Position end
                                
                                -- Grab automatique dans un rayon de 15 studs
                                if pos and (pos - root.Position).Magnitude <= 15 then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        StealBtn.Text = "Instant Steal: OFF"
        StealBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        if stealLoop then
            task.cancel(stealLoop)
            stealLoop = nil
        end
    end
end)

-- =====================================
-- AUTO FARM (Aura + Tween Bypass)
-- =====================================
local AutoFarmBtn = Instance.new("TextButton")
AutoFarmBtn.Size = UDim2.new(0.8, 0, 0, 35)
AutoFarmBtn.Position = UDim2.new(0.1, 0, 0, 175)
AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoFarmBtn.Text = "Auto Steal: OFF"
AutoFarmBtn.TextColor3 = Color3.new(1, 1, 1)
AutoFarmBtn.Font = Enum.Font.GothamSemibold
AutoFarmBtn.TextSize = 14
AutoFarmBtn.Parent = Frame

local UICornerAuto = Instance.new("UICorner")
UICornerAuto.Parent = AutoFarmBtn

-- Augmenter la taille du Frame pour le 4ème bouton
Frame.Size = UDim2.new(0, 200, 0, 225) 

local autoFarmEnabled = false
local farmLoop
local basePosition = nil

AutoFarmBtn.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        AutoFarmBtn.Text = "Auto Steal: ON"
        AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        -- Sauvegarder la position exacte où le joueur se trouve au moment de l'activation
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            basePosition = root.Position
        end
        
        farmLoop = task.spawn(function()
            local TweenService = game:GetService("TweenService")
            local SPEED = 150 -- Studs per second
            
            while autoFarmEnabled do
                char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                
                if hrp and hum and basePosition then
                    -- 1. Chercher le brainrot
                    local targetPrompt = nil
                    local targetPos = nil
                    local targetDist = math.huge
                    
                    for _, prompt in pairs(Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local txt = prompt.ActionText:lower()
                            if txt:match("grab") or txt:match("steal") then
                                local pos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or (prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart and prompt.Parent.PrimaryPart.Position)
                                
                                if pos and (pos - basePosition).Magnitude > 60 then
                                    local dist = (pos - hrp.Position).Magnitude
                                    if dist < targetDist then
                                        targetDist = dist
                                        targetPrompt = prompt
                                        targetPos = pos
                                    end
                                end
                            end
                        end
                    end
                    
                    if targetPrompt and targetPos then
                        -- 2. Désactiver la physique pour devenir un "fantôme" (Bypass)
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                        hrp.Anchored = true -- Fixe le joueur pour empêcher toute chute/vélocité
                        
                        -- Fonction pour créer un Tween de déplacement
                        local function tweenTo(destination)
                            local distance = (destination - hrp.Position).Magnitude
                            local timeToTake = distance / SPEED
                            local tweenInfo = TweenInfo.new(timeToTake, Enum.EasingStyle.Linear)
                            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(destination)})
                            tween:Play()
                            tween.Completed:Wait()
                        end
                        
                        -- 3. Voler vers l'objet
                        if autoFarmEnabled then
                            tweenTo(targetPos)
                        end
                        
                        -- 4. Activer le prompt
                        if autoFarmEnabled then
                            fireproximityprompt(targetPrompt)
                            task.wait(0.3)
                        end
                        
                        -- 5. Retourner à la base
                        if autoFarmEnabled then
                            tweenTo(basePosition)
                        end
                        
                        -- 6. Déposer l'objet
                        if autoFarmEnabled then
                            for _, prompt in pairs(Workspace:GetDescendants()) do
                                if prompt:IsA("ProximityPrompt") then
                                    local txt = prompt.ActionText:lower()
                                    if txt:match("collect") or txt:match("drop") or txt:match("sell") then
                                        local pPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or (prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart and prompt.Parent.PrimaryPart.Position)
                                        if pPos and (pPos - hrp.Position).Magnitude < 20 then
                                            fireproximityprompt(prompt)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        AutoFarmBtn.Text = "Auto Steal: OFF"
        AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        
        if farmLoop then
            task.cancel(farmLoop)
            farmLoop = nil
        end
        
        -- Remettre la physique normale
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end
end)
local RagdollBtn = Instance.new("TextButton")
RagdollBtn.Size = UDim2.new(0.8, 0, 0, 35)
RagdollBtn.Position = UDim2.new(0.1, 0, 0, 85)
RagdollBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RagdollBtn.Text = "Ragdoll: OFF"
RagdollBtn.TextColor3 = Color3.new(1, 1, 1)
RagdollBtn.Font = Enum.Font.GothamSemibold
RagdollBtn.TextSize = 14
RagdollBtn.Parent = Frame

local UICornerRagdoll = Instance.new("UICorner")
UICornerRagdoll.Parent = RagdollBtn

local constraints = {}
local motorData = {}
local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()

local function enableRagdoll()
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    constraints = {}
    motorData = {}

    for _, motor in pairs(character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
            table.insert(motorData, {
                motor = motor, part0 = motor.Part0, part1 = motor.Part1,
                c0 = motor.C0, c1 = motor.C1, enabled = motor.Enabled
            })

            local attachment0 = Instance.new("Attachment")
            local attachment1 = Instance.new("Attachment")
            attachment0.Parent = motor.Part0
            attachment1.Parent = motor.Part1
            attachment0.CFrame = motor.C0
            attachment1.CFrame = motor.C1

            local constraint
            if motor.Name == "Root" or motor.Name == "Neck" then
                constraint = Instance.new("HingeConstraint")
            else
                constraint = Instance.new("BallSocketConstraint")
                constraint.TwistLimitsEnabled = true
            end
            constraint.LimitsEnabled = true
            constraint.Attachment0 = attachment0
            constraint.Attachment1 = attachment1
            constraint.Parent = motor.Parent

            local noCollision = Instance.new("NoCollisionConstraint")
            noCollision.Part0 = motor.Part0
            noCollision.Part1 = humanoid.RootPart
            noCollision.Parent = motor.Parent

            motor.Enabled = false
            table.insert(constraints, { constraint = constraint, attachment0 = attachment0, attachment1 = attachment1, noCollision = noCollision })
        end
    end
    controls:Disable()
end

local function disableRagdoll()
    for _, data in pairs(constraints) do
        if data.constraint then data.constraint:Destroy() end
        if data.attachment0 then data.attachment0:Destroy() end
        if data.attachment1 then data.attachment1:Destroy() end
        if data.noCollision then data.noCollision:Destroy() end
    end
    constraints = {}
    for _, data in pairs(motorData) do
        if data.motor and data.motor.Part0 and data.motor.Part1 then
            data.motor.C0 = data.c0
            data.motor.C1 = data.c1
            data.motor.Enabled = true
        end
    end
    motorData = {}
    controls:Enable()
end

RagdollBtn.MouseButton1Click:Connect(function()
    ragdollEnabled = not ragdollEnabled
    if ragdollEnabled then
        RagdollBtn.Text = "Ragdoll: ON"
        RagdollBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        enableRagdoll()
    else
        RagdollBtn.Text = "Ragdoll: OFF"
        RagdollBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        disableRagdoll()
    end
end)

player.CharacterAdded:Connect(function(char)
    if ragdollEnabled then
        task.wait(1)
        enableRagdoll()
    end
end)

-- =====================================
-- SPEED BYPASS (FREEFALL)
-- =====================================
local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(0.8, 0, 0, 35)
SpeedBtn.Position = UDim2.new(0.1, 0, 0, 130)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SpeedBtn.Text = "Speed Bypass: OFF"
SpeedBtn.TextColor3 = Color3.new(1, 1, 1)
SpeedBtn.Font = Enum.Font.GothamSemibold
SpeedBtn.TextSize = 14
SpeedBtn.Parent = Frame

local UICornerSpeed = Instance.new("UICorner")
UICornerSpeed.Parent = SpeedBtn

local TARGET_SPEED_MODIFIER = 4 -- Multiplie la vitesse de base par 4

SpeedBtn.MouseButton1Click:Connect(function()
    speedBypassEnabled = not speedBypassEnabled
    if speedBypassEnabled then
        SpeedBtn.Text = "Speed Bypass: ON"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        -- Boucle pour appliquer en permanence le modificateur sur l'outil en main
        speedLoop = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then return end
            
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                if tool:GetAttribute("SpeedModifier") ~= TARGET_SPEED_MODIFIER then
                    tool:SetAttribute("SpeedModifier", TARGET_SPEED_MODIFIER)
                end
            else
                -- S'il n'a pas d'outil en main, on peut injecter la vitesse directement sur le Humanoid
                -- Mais pour l'anticheat, il vaut mieux l'inviter à s'équiper de l'outil
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 65 end
            end
        end)
    else
        SpeedBtn.Text = "Speed Bypass: OFF"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        
        if speedLoop then
            speedLoop:Disconnect()
            speedLoop = nil
        end
        
        -- Retirer le modificateur sur l'outil
        local char = player.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:SetAttribute("SpeedModifier", nil)
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end
    end
end)
