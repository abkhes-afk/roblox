local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Xenith-Hub/Leetchy-Hub-Dependency/refs/heads/main/FluentLibraryAxon"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Library:CreateWindow{
    Title = `Fluent {Library.Version}`,
    SubTitle = "Modded Showcase",
    TabWidth = 165,
    Size = UDim2.fromOffset(860, 545),
    Resize = true,
    MinSize = Vector2.new(500, 390),
    Acrylic = true,
    Theme = "Glass",
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {}
Tabs.Farm = Window:CreateTab{ Title = "Farm", Icon = "phosphor-plant-bold" }
Tabs.Automation = Window:CreateTab{ Title = "Automation", Icon = "phosphor-gear-six-bold" }
Tabs.Combat = Window:CreateTab{ Title = "Combat", Icon = "phosphor-sword-bold" }
Window:Divider("Visual")
Tabs.Visuals = Window:CreateTab{ Title = "Visuals", Icon = "phosphor-eye-bold" }
Tabs.World = Window:CreateTab{ Title = "World", Icon = "phosphor-globe-bold" }
Window:Divider("System")
Tabs.Settings = Window:CreateTab{ Title = "Settings", Icon = "settings" }

local Options = Library.Options

-- === [ FARM ] ===
local FarmMain = Tabs.Farm:Left("Farm Core")
local FarmRoute = Tabs.Farm:Right("Routes")

FarmMain:CreateParagraph("FarmIntro", {
    Title = "Farm Preset",
    Content = "This page demonstrates paragraphs, toggles, checkbox states, sliders, dropdowns, buttons, inputs, and dividers.",
    Tooltip = "Paragraphs support tooltip text too."
})

local AutoFarm = FarmMain:CreateToggle("AutoFarm", { Title = "Auto Farm", Default = false })
AutoFarm:Keybind("AutoFarmBind", { Title = "Auto Farm Bind", Default = Enum.KeyCode.F })
FarmMain:CreateToggle("AutoCollect", { Title = "Auto Collect Drops", Default = true })

FarmMain:CreateSlider("FarmSpeed", { Title = "Farm Speed", Default = 55, Min = 0, Max = 100, Rounding = 0 })
FarmMain:CreateSlider("FarmStepSpeed", { Title = "Farm Step Preset", Style = "Steps", Values = {25, 50, 75, 100}, Default = 50, Min = 0, Max = 100, Rounding = 0 })

FarmRoute:CreateDropdown("FarmZone", { Title = "Farm Zone", Values = {"Forest", "Desert", "Crystal Cave", "Volcano", "Sky Island"}, Default = 1 })
FarmRoute:CreateDropdown("FarmMaterials", { Title = "Materials", Values = {"Coins", "Gems", "Wood", "Ore", "Relics"}, Multi = true, Default = {"Coins", "Gems"} })
FarmRoute:CreateInput("WebhookUrl", { Title = "Webhook URL", Default = "", Placeholder = "https://discord.com/api/...", Numeric = false, Finished = true })
FarmRoute:CreateInput("ServerHopDelay", { Title = "Hop Delay", Default = "30", Numeric = true, Finished = false })
FarmRoute:CreateButton{ Title = "Start Selected Route", Callback = function() end }

-- === [ AUTOMATION ] ===
local AutoLeft = Tabs.Automation:Left("Tasks")
local AutoRight = Tabs.Automation:Right("Timing")

AutoLeft:CreateToggle("AutoQuest", { Title = "Auto Quest", Default = false })
AutoLeft:CreateToggle("AutoUpgrade", { Title = "Auto Upgrade", Default = false })
AutoLeft:CreateToggle("AutoSell", { Title = "Auto Sell", Default = true })
AutoLeft:CreateDropdown("TaskPriority", { Title = "Priority", Values = {"Quest First", "Farm First", "Sell First", "Upgrade First"}, Default = 1 })

AutoRight:CreateSlider("ActionDelay", { Title = "Action Delay", Default = 0.25, Min = 0, Max = 2, Rounding = 2 })
AutoRight:CreateSlider("LootRange", { Title = "Loot Range", Style = "Range", Default = {20, 80}, Min = 0, Max = 100, Rounding = 0 })
AutoRight:CreateKeybind("PanicKey", { Title = "Panic Key", Default = Enum.KeyCode.X })

-- === [ COMBAT ] ===
local CombatAim = Tabs.Combat:Left("Aiming")
local CombatWeapon = Tabs.Combat:Right("Weapons")

CombatAim:CreateToggle("AimbotEnabled", { Title = "Aimbot", Default = false })
CombatAim:CreateToggle("VisibleCheck", { Title = "Visible Check", Default = true })
CombatAim:CreateSlider("AimbotFOV", { Title = "FOV", Default = 120, Min = 10, Max = 500, Rounding = 0 })
CombatAim:CreateDropdown("TargetPart", { Title = "Target Part", Values = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = 1 })

-- Mods
local GunConfig = nil
pcall(function()
    GunConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Data"):WaitForChild("GunConfig"))
end)

local state = { originalFireRates = {} }

CombatWeapon:CreateToggle("RapidFire", { 
    Title = "Rapid Fire", 
    Default = false,
    Callback = function(Value)
        if GunConfig and GunConfig.Guns then
            if Value then
                for gunName, config in pairs(GunConfig.Guns) do
                    if not state.originalFireRates[gunName] then
                        state.originalFireRates[gunName] = config.FireRate
                    end
                    config.FireRate = 0.05
                end
            else
                for gunName, config in pairs(GunConfig.Guns) do
                    if state.originalFireRates[gunName] then
                        config.FireRate = state.originalFireRates[gunName]
                    end
                end
            end
        end
    end 
})

CombatWeapon:CreateToggle("InfiniteAmmo", { 
    Title = "Infinite Ammo (Passive)", 
    Default = true,
    Callback = function(Value)
        -- In this game, guns like the Pistol appear to have infinite ammo by default.
        -- There is no 'MagSize' or 'Ammo' variable in the configuration natively.
    end 
})

CombatWeapon:CreateToggle("AutoAttack", { 
    Title = "Auto Attack", 
    Default = false,
    Callback = function(Value)
        getgenv().AutoAttackMod = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoAttackMod do
                    task.wait(0.1)
                    if mouse1click then
                        mouse1click()
                    else
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.02)
                        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end
                end
            end)
        end
    end 
})
CombatWeapon:CreateSlider("AttackSpeed", { Title = "Attack Speed", Default = 5, Min = 1, Max = 25, Rounding = 0 })
CombatWeapon:CreateDropdown("WeaponSelect", { Title = "Weapon", Values = {"Pistol", "Sword", "Bow", "Staff", "Dagger"}, Default = 1 })
CombatWeapon:CreateButton{ 
    Title = "Equip Best Weapon", 
    Callback = function() 
        local selected = Options.WeaponSelect.Value
        local player = game:GetService("Players").LocalPlayer
        local tool = player.Backpack:FindFirstChild(selected)
        if tool and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid:EquipTool(tool)
        end
    end 
}

-- === [ VISUALS ] ===
local VisualLeft = Tabs.Visuals:Left("ESP")
local VisualRight = Tabs.Visuals:Right("Colors")

VisualLeft:CreateToggle("ESPEnabled", { Title = "Player ESP", Default = false })
VisualLeft:CreateToggle("ESPBoxes", { Title = "Boxes", Default = true })
VisualLeft:CreateToggle("ESPNames", { Title = "Names", Default = true })
VisualLeft:CreateSlider("ESPDistance", { Title = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0 })

VisualRight:CreateColorpicker("ESPColor", { Title = "ESP Color", Default = Color3.fromRGB(60, 180, 255) })
VisualRight:CreateColorpicker("TracerColor", { Title = "Tracer Color", Default = Color3.fromRGB(255, 190, 80), Transparency = 0.15 })

-- === [ WORLD ] ===
local WorldLighting = Tabs.World:Left("Lighting")
local WorldCamera = Tabs.World:Right("Camera")

WorldLighting:CreateToggle("Fullbright", { Title = "Fullbright", Default = false })
WorldLighting:CreateToggle("NoFog", { Title = "No Fog", Default = false })
WorldLighting:CreateToggle("NoParticles", { Title = "No Particles", Default = false })
WorldLighting:CreateColorpicker("SkyTint", { Title = "Sky Tint", Default = Color3.fromRGB(135, 206, 235) })

WorldCamera:CreateSlider("CameraFOV", { Title = "Field of View", Default = 70, Min = 30, Max = 120, Rounding = 0 })
WorldCamera:CreateSlider("ZoomRange", { Title = "Zoom Range", Style = "Range", Default = {10, 80}, Min = 0, Max = 100, Rounding = 0 })
WorldCamera:CreateButton{ Title = "Reset Camera", Callback = function() end }

-- === [ SETTINGS ] ===
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

local SettingsSection = Tabs.Settings:CreateSection("Interface")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(3)

Library:Notify{
    Title = "Modded GUI",
    Content = "Le menu s'est bien chargé ! Allez dans Combat > Weapons.",
    Duration = 5
}

SaveManager:LoadAutoloadConfig()
