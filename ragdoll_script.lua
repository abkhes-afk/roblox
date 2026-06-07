-- Script de Ragdoll pour "Voler un Brainrot"
-- Exécute ce script pour faire ragdoll ton personnage

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local DURATION = 5 -- durée du ragdoll en secondes

-- Stocker les données pour pouvoir revert
local constraints = {}
local motorData = {}

-- Étape 1 : Remplacer tous les Motor6D par des contraintes
for _, motor in pairs(character:GetDescendants()) do
    if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
        -- Sauvegarder l'état du Motor6D
        table.insert(motorData, {
            motor = motor,
            part0 = motor.Part0,
            part1 = motor.Part1,
            c0 = motor.C0,
            c1 = motor.C1,
            enabled = motor.Enabled
        })

        -- Créer les Attachments
        local attachment0 = Instance.new("Attachment")
        local attachment1 = Instance.new("Attachment")
        attachment0.Parent = motor.Part0
        attachment1.Parent = motor.Part1
        attachment0.CFrame = motor.C0
        attachment1.CFrame = motor.C1

        -- Créer la contrainte appropriée
        local constraint
        if motor.Name == "Root" or motor.Name == "Neck" then
            constraint = Instance.new("HingeConstraint")
            constraint.LimitsEnabled = true
        else
            constraint = Instance.new("BallSocketConstraint")
            constraint.LimitsEnabled = true
            constraint.TwistLimitsEnabled = true
        end

        constraint.Attachment0 = attachment0
        constraint.Attachment1 = attachment1
        constraint.Parent = motor.Parent

        -- NoCollisionConstraint entre la partie et le RootPart
        local noCollision = Instance.new("NoCollisionConstraint")
        noCollision.Part0 = motor.Part0
        noCollision.Part1 = humanoid.RootPart
        noCollision.Parent = motor.Parent

        -- Désactiver le Motor6D
        motor.Enabled = false

        table.insert(constraints, {
            constraint = constraint,
            attachment0 = attachment0,
            attachment1 = attachment1,
            noCollision = noCollision
        })
    end
end

-- Désactiver les contrôles
local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()
controls:Disable()

print("Ragdoll activé pour " .. DURATION .. " secondes")

-- Attendre la durée
task.wait(DURATION)

-- Étape 2 : Restaurer l'état normal
for _, data in pairs(constraints) do
    if data.constraint then data.constraint:Destroy() end
    if data.attachment0 then data.attachment0:Destroy() end
    if data.attachment1 then data.attachment1:Destroy() end
    if data.noCollision then data.noCollision:Destroy() end
end

for _, data in pairs(motorData) do
    if data.motor and data.motor.Part0 and data.motor.Part1 then
        data.motor.C0 = data.c0
        data.motor.C1 = data.c1
        data.motor.Enabled = true
    end
end

-- Réactiver les contrôles
controls:Enable()

print("Ragdoll terminé")
