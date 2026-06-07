-- SUPPRESSION DE L'INTERFACE ROBLOX
local coreGui = game:GetService("CoreGui")
if coreGui:FindFirstChild("RobloxGui") then
    coreGui.RobloxGui:Destroy()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIGURATION
local MY_NAME = "iptopbank03" -- Ton pseudo défini comme centre
local DISTANCE = 5             -- Distance de 5 mètres
local ROTATION_SPEED = 3       -- Vitesse de rotation
local HEIGHT_OFFSET = 0        -- Hauteur (0 = au niveau de tes pieds)

local function getCenterPlayer()
    return Players:FindFirstChild(MY_NAME)
end

local function getOthers(centerPlayer)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= centerPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    return list
end

local function startOrbit()
    RunService.Heartbeat:Connect(function()
        local centerPlayer = getCenterPlayer()
        
        if not centerPlayer or not centerPlayer.Character or not centerPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            return 
        end
        
        local centerHRP = centerPlayer.Character.HumanoidRootPart
        local others = getOthers(centerPlayer)
        local totalOthers = #others
        
        if totalOthers == 0 then return end

        for i, player in ipairs(others) do
            local otherHRP = player.Character.HumanoidRootPart
            
            local angle = (i / totalOthers) * (math.pi * 2) + (tick() * ROTATION_SPEED)
            
            local targetPos = centerHRP.Position + Vector3.new(
                math.cos(angle) * DISTANCE,
                HEIGHT_OFFSET,
                math.sin(angle) * DISTANCE
            )
            
            otherHRP.CFrame = CFrame.new(targetPos, centerHRP.Position)
            
            otherHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            otherHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

startOrbit()