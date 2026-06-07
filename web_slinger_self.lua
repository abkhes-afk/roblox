-- Script: Utiliser le Web Slinger sur soi-même
-- Pour "Voler un Brainrot"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Récupérer le remote event UseItem
local Net = require(ReplicatedStorage.Packages.Net)
local useItemRemote = Net:RemoteEvent("UseItem")

-- Équiper le Web Slinger
local backpack = player:FindFirstChild("Backpack")
local webSlinger = backpack and backpack:FindFirstChild("Web Slinger")

if not webSlinger then
    -- Chercher dans le character
    webSlinger = character and character:FindFirstChild("Web Slinger")
end

if not webSlinger then
    warn("Web Slinger introuvable dans le backpack ou le personnage")
    return
end

-- Équiper l'outil si pas déjà équipé
if webSlinger.Parent == backpack then
    character.Humanoid:EquipTool(webSlinger)
    task.wait(0.3)
end

-- Utiliser le Web Slinger sur soi-même
-- On envoie la position du HumanoidRootPart et le personnage comme cible
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
    useItemRemote:FireServer(rootPart.Position, character)
    print("Web Slinger utilisé sur toi-même !")
else
    warn("HumanoidRootPart introuvable")
end
