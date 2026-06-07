-- ============================================================
--  LOAD THE LIBRARY
-- ============================================================
local LIB_URL = "https://raw.githubusercontent.com/Xenith-Hub/Leetchy-Hub-Dependency/refs/heads/main/LibraryAxonNewTuff"
local httpOk, source = pcall(function() return game:HttpGet(LIB_URL, true) end)
if not httpOk or type(source) ~= "string" or #source < 1000 then error("[AxonHub] HTTP fetch failed", 0) end
local loader = loadstring or load
if type(loader) ~= "function" then error("[AxonHub] No loadstring", 0) end
local chunk, parseErr = loader(source, "ArvynLib")
if type(chunk) ~= "function" then error("[AxonHub] loadstring failed: " .. tostring(parseErr), 0) end
local Library = chunk()
if type(Library) ~= "table" then error("[AxonHub] Library error", 0) end
_G.ArvynLib = Library
local Toggles, Options, ThemeManager, SaveManager = Library.Toggles, Library.Options, Library.ThemeManager, Library.SaveManager

-- ============================================================
--  SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local WS                = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")
local HRP         = Character:WaitForChild("HumanoidRootPart")
LocalPlayer.CharacterAdded:Connect(function(c) Character = c; Humanoid = c:WaitForChild("Humanoid"); HRP = c:WaitForChild("HumanoidRootPart") end)

-- ============================================================
--  REMOTES & CONFIGS
-- ============================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Events  = ReplicatedStorage:WaitForChild("Events")
local UpgradeRequested   = Remotes:WaitForChild("UpgradeRequested")
local CollectedCash      = Remotes:WaitForChild("CollectedCash")
local AutoCollectToggle  = Remotes:WaitForChild("AutoCollectToggle")
local RequestBaseUpgrade = Events:WaitForChild("RequestBaseUpgrade")
local RequestRebirth     = Events:WaitForChild("RequestRebirth")
local RequestSell        = Events:WaitForChild("RequestSell")
local RequestDropItem    = Events:WaitForChild("RequestDropItem")
local GetIndexData       = Events:WaitForChild("GetIndexData")
local BuyWingsRF     = Remotes:WaitForChild("Inventory"):WaitForChild("BuyWings")
local EquipWingsRF   = Remotes:WaitForChild("Inventory"):WaitForChild("EquipWings")
local GetInventoryRF = Remotes:WaitForChild("Inventory"):WaitForChild("GetInventory")
local ItemConfig  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemConfigurations"))
local WingsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("WingsConfig"))

-- ============================================================
--  HELPERS
-- ============================================================
local function fmt(n)
    if n >= 1e12 then return ("%.2fT"):format(n/1e12)
    elseif n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.2fK"):format(n/1e3)
    else return tostring(math.floor(n)) end
end
local function tp(pos) if HRP then HRP.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end end
local function fp(p) if p and p.Enabled then fireproximityprompt(p) end end
local function getPlot()
    local p = WS:FindFirstChild("Plots"); return p and p:FindFirstChild("Plot_"..LocalPlayer.Name)
end
local function getBasePos()
    local pl = getPlot(); if not pl then return nil end
    local ab = pl:FindFirstChild("ActionButtons"); if not ab then return nil end
    local bm = ab:FindFirstChild("BanerModel"); if not bm then return nil end
    local b = bm:FindFirstChild("Baner"); return b and b.Position
end
local function getActionPrompt(name)
    local pl = getPlot(); if not pl then return nil end
    local ab = pl:FindFirstChild("ActionButtons"); if not ab then return nil end
    local bm = ab:FindFirstChild("BanerModel"); if not bm then return nil end
    for _,d in ipairs(bm:GetDescendants()) do if d:IsA("ProximityPrompt") and d.Name == name then return d end end
end
local function tpBase() local p = getBasePos(); if p then tp(p - Vector3.new(0,3,0)); task.wait(0.3) end end
local function getMut(n)
    if n:sub(1,7) == "Golden " then return "Golden", n:sub(8) end
    if n:sub(1,8) == "Diamond " then return "Diamond", n:sub(9) end
    if n:sub(1,5) == "Lava " then return "Lava", n:sub(6) end
    return "Normal", n
end
local function brData(fn)
    local m,bn = getMut(fn); local d = ItemConfig.Items[fn] or ItemConfig.Items[bn]
    return d and d.Income or 0, d and d.Rarity or "Unknown", m, bn
end
local function getSpawned()
    local r = {}; local sp = WS:FindFirstChild("ItemSpawners"); if not sp then return r end
    for _,z in ipairs(sp:GetChildren()) do for _,br in ipairs(z:GetChildren()) do
        if br:IsA("Model") then local mesh = br:FindFirstChild("Mesh"); if mesh then
            local pr = mesh:FindFirstChildOfClass("ProximityPrompt")
            if pr and pr.Enabled then local inc,rar,mut,bn = brData(br.Name)
                table.insert(r,{model=br,mesh=mesh,prompt=pr,name=br.Name,baseName=bn,mutation=mut,zone=z.Name,income=inc,rarity=rar,position=mesh.Position})
            end
        end end
    end end; return r
end
local function getEmpty()
    local pl = getPlot(); if not pl then return {} end; local e = {}
    for _,fl in ipairs(pl:GetChildren()) do if fl.Name:match("^Floor%d") then local sf = fl:FindFirstChild("Slots")
        if sf then for _,sl in ipairs(sf:GetChildren()) do local occ = false
            for _,c in ipairs(sl:GetChildren()) do if c:IsA("Model") and c:FindFirstChild("Handle") then occ=true;break end end
            if not occ then local sp = sl:FindFirstChild("Spawn"); if sp then local pp = sp:FindFirstChild("ProximityPrompt")
                if pp and pp:IsA("ProximityPrompt") and pp.Enabled and pp.ActionText == "Place Item" then table.insert(e,{slot=sl,spawn=sp,floor=fl.Name,prompt=pp,position=sp.Position}) end
            end end
        end end
    end end; return e
end
local function getPlaced()
    local pl = getPlot(); if not pl then return {} end; local r = {}
    for _,fl in ipairs(pl:GetChildren()) do if fl.Name:match("^Floor%d") then local sf = fl:FindFirstChild("Slots")
        if sf then for _,sl in ipairs(sf:GetChildren()) do for _,c in ipairs(sl:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("Handle") then local sp = sl:FindFirstChild("Spawn")
                local inc,rar,mut,bn = brData(c.Name)
                table.insert(r,{model=c,slot=sl,floor=fl.Name,name=c.Name,baseName=bn,mutation=mut,spawnPart=sp,income=inc,rarity=rar})
            end
        end end end
    end end; return r
end
local rarOrd = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythical=6,Secret=7,Celestial=8,Cosmic=9,God=10,Exclusive=11}
local rarCol = {Common=Color3.fromRGB(200,200,200),Uncommon=Color3.fromRGB(100,200,100),Rare=Color3.fromRGB(70,130,255),Epic=Color3.fromRGB(180,70,255),Legendary=Color3.fromRGB(255,180,0),Mythical=Color3.fromRGB(255,50,50),Secret=Color3.fromRGB(255,100,150),Celestial=Color3.fromRGB(0,220,255),Cosmic=Color3.fromRGB(100,0,200),God=Color3.fromRGB(255,215,0),Exclusive=Color3.fromRGB(255,255,255)}
local function sortBR(list, mode)
    table.sort(list, function(a,b)
        if mode=="Lowest Income" then return (a.income or 0)<(b.income or 0)
        elseif mode=="Highest Income" then return (a.income or 0)>(b.income or 0)
        elseif mode=="Lowest Rarity" then return (rarOrd[a.rarity] or 0)<(rarOrd[b.rarity] or 0)
        elseif mode=="Highest Rarity" then return (rarOrd[a.rarity] or 0)>(rarOrd[b.rarity] or 0) end; return false
    end); return list
end
local function getBuyWings()
    local w = {}; for cn,d in pairs(WingsConfig.Wings) do if not d.premium then
        table.insert(w,{configName=cn,publicName=d.PublicName,cost=d.Cost or 0,rebirthsRequired=d.RebirthsRequired or 0})
    end end; table.sort(w,function(a,b) return a.cost<b.cost end); return w
end
local function idxKey(n) local m,bn = getMut(n); return m.."_"..bn end

-- ============================================================
--  WINDOW & TABS
-- ============================================================
local Window = Library:CreateWindow({Title="Axon Hub | Brainrot Wings",Center=true,AutoShow=true})
local TabFarm    = Window:AddTab("Farm",     "zap",  "AUTOMATION")
local TabPlayer  = Window:AddTab("Player",   "user", "AUTOMATION")
local TabVisuals = Window:AddTab("Visuals",  "eye",  "AUTOMATION")
local TabSettings= Window:AddTab("Settings", "settings","AUTOMATION")

-- ============================================================
--  STATE + DELAYS
-- ============================================================
local S = {
    autoBring=false, autoBringSort="Highest Income", autoBringRar={}, autoPlace=false,
    autoIndex=false, autoSellIndex=false, autoSellEquipped=false,
    autoUpgSpeed=false, autoUpgStamina=false, autoUpgCarry=false, autoBaseLvl=false,
    autoUpgBrainrot=false, autoBuyWings=false, autoRebirth=false,
    autoCollectAll=false, autoUpgSlots=false, autoUpgMaxAll=false,
    autoDropWorst=false, autoEquipBest=false,
    fly=false, flySpd=80, infStam=false, speed=false, speedVal=50,
    jump=false, jumpVal=100, noclip=false, antiAfk=true, godMode=false,
    espBR=false, espName=true, espIncome=true, espMut=true, espRar=true, espRarFilter={},
    espPlayer=false, espPlayerName=true, espPlayerMoney=true, espPlayerRebirths=true, espPlayerHealth=true,
    -- delays (seconds)
    dBring=0.5, dPlace=0.5, dIndex=1, dSellIdx=1.5, dSellEq=2,
    dUpgStats=1.5, dUpgBR=1.5, dBuyWings=3, dRebirth=5,
    dCollect=2, dUpgSlots=2, dUpgMax=2, dBaseLvl=2,
    dDrop=3, dEquip=5,
}
local espObjBR = {}
local espObjPl = {}

-- ============================================================
--  FARM LEFT: Bring + Place + Index + Sell
-- ============================================================
local FL1 = TabFarm:AddLeftGroupbox("Auto Bring Brainrot")
FL1:AddToggle("AutoBring",{Text="Auto Bring Brainrot",Default=false,Callback=function(v) S.autoBring=v end})
FL1:AddSlider("DelayBring",{Text="Bring Delay (s)",Default=0.5,Min=0.1,Max=5,Rounding=1,Callback=function(v) S.dBring=v end})
FL1:AddDropdown("BringSortMode",{Text="Sort Mode",Values={"Highest Income","Lowest Income","Highest Rarity","Lowest Rarity"},Default="Highest Income",Multi=false,Callback=function(v) S.autoBringSort=v end})
FL1:AddDropdown("BringRarFilter",{Text="Target Rarities",Values={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Default={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Multi=true,Callback=function(v) S.autoBringRar=v end})
FL1:AddToggle("AutoPlace",{Text="Auto Place on Base",Default=false,Callback=function(v) S.autoPlace=v end})
FL1:AddSlider("DelayPlace",{Text="Place Delay (s)",Default=0.5,Min=0.1,Max=5,Rounding=1,Callback=function(v) S.dPlace=v end})

local FL2 = TabFarm:AddLeftGroupbox("Index & Sell")
FL2:AddToggle("AutoIndex",{Text="Auto Index",Default=false,Tooltip="Pick up undiscovered brainrots, place, sell.",Callback=function(v) S.autoIndex=v end})
FL2:AddSlider("DelayIndex",{Text="Index Delay (s)",Default=1,Min=0.3,Max=10,Rounding=1,Callback=function(v) S.dIndex=v end})
FL2:AddToggle("AutoSellIndex",{Text="Auto Sell Index (Inventory)",Default=false,Callback=function(v) S.autoSellIndex=v end})
FL2:AddSlider("DelaySellIdx",{Text="Sell Index Delay (s)",Default=1.5,Min=0.5,Max=10,Rounding=1,Callback=function(v) S.dSellIdx=v end})
FL2:AddDivider()
FL2:AddToggle("AutoSellEquipped",{Text="Auto Sell Equipped",Default=false,Callback=function(v) S.autoSellEquipped=v end})
FL2:AddSlider("DelaySellEq",{Text="Sell Eq Delay (s)",Default=2,Min=0.5,Max=10,Rounding=1,Callback=function(v) S.dSellEq=v end})
FL2:AddButton("Sell Equipped Now",function() RequestSell:FireServer("Equipped"); Library:Notify("Sold equipped!",2) end)
FL2:AddButton("Sell Inventory Now",function() RequestSell:FireServer("Inventory"); Library:Notify("Sold inventory!",2) end)

local FL3 = TabFarm:AddLeftGroupbox("Auto Drop & Equip")
FL3:AddToggle("AutoDropWorst",{Text="Auto Drop Worst Brainrot",Default=false,Tooltip="Drop lowest income brainrot from base.",Callback=function(v) S.autoDropWorst=v end})
FL3:AddSlider("DelayDrop",{Text="Drop Delay (s)",Default=3,Min=1,Max=15,Rounding=1,Callback=function(v) S.dDrop=v end})
FL3:AddToggle("AutoEquipBest",{Text="Auto Equip Best Wings",Default=false,Tooltip="Keep best wings equipped.",Callback=function(v) S.autoEquipBest=v end})
FL3:AddSlider("DelayEquip",{Text="Equip Delay (s)",Default=5,Min=1,Max=30,Rounding=1,Callback=function(v) S.dEquip=v end})

-- ============================================================
--  FARM RIGHT: Upgrades + Wings + Base Actions
-- ============================================================
local FR1 = TabFarm:AddRightGroupbox("Auto Upgrades")
FR1:AddToggle("AutoUpgSpeed",{Text="Auto Upgrade Speed",Default=false,Callback=function(v) S.autoUpgSpeed=v end})
FR1:AddToggle("AutoUpgStamina",{Text="Auto Upgrade Stamina",Default=false,Callback=function(v) S.autoUpgStamina=v end})
FR1:AddToggle("AutoUpgCarry",{Text="Auto Upgrade Carry",Default=false,Callback=function(v) S.autoUpgCarry=v end})
FR1:AddToggle("AutoBaseLvl",{Text="Auto Upgrade Base Level",Default=false,Callback=function(v) S.autoBaseLvl=v end})
FR1:AddSlider("DelayUpgStats",{Text="Upgrade Delay (s)",Default=1.5,Min=0.5,Max=10,Rounding=1,Callback=function(v) S.dUpgStats=v end})
FR1:AddDivider()
FR1:AddToggle("AutoUpgBR",{Text="Auto Upgrade Brainrot",Default=false,Callback=function(v) S.autoUpgBrainrot=v end})
FR1:AddSlider("DelayUpgBR",{Text="BR Upgrade Delay (s)",Default=1.5,Min=0.3,Max=10,Rounding=1,Callback=function(v) S.dUpgBR=v end})
FR1:AddDropdown("UpgBRSort",{Text="Upgrade Priority",Values={"Highest Income First","Lowest Income First","All"},Default="All",Multi=false})
FR1:AddDropdown("UpgBRFilter",{Text="Upgrade Rarities",Values={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Default={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Multi=true})

local FR2 = TabFarm:AddRightGroupbox("Wings & Rebirth")
FR2:AddToggle("AutoBuyWings",{Text="Auto Buy Wings",Default=false,Callback=function(v) S.autoBuyWings=v end})
FR2:AddSlider("DelayBuyWings",{Text="Buy Wings Delay (s)",Default=3,Min=1,Max=30,Rounding=1,Callback=function(v) S.dBuyWings=v end})
FR2:AddToggle("AutoRebirth",{Text="Auto Rebirth",Default=false,Callback=function(v) S.autoRebirth=v end})
FR2:AddSlider("DelayRebirth",{Text="Rebirth Delay (s)",Default=5,Min=1,Max=30,Rounding=1,Callback=function(v) S.dRebirth=v end})
FR2:AddDivider()
FR2:AddButton("Unlock All Wings",function()
    local inv = GetInventoryRF:InvokeServer(); local owned = {}
    if inv and inv.Wings then for _,w in ipairs(inv.Wings) do owned[w]=true end end
    for _,w in ipairs(getBuyWings()) do if not owned[w.configName] then pcall(function() BuyWingsRF:InvokeServer(w.configName) end); task.wait(0.3) end end
    Library:Notify("Bought all affordable wings!",3)
end)
FR2:AddButton("Equip Best Wings",function()
    local inv = GetInventoryRF:InvokeServer(); if not inv or not inv.Wings then return end
    local best,bc = nil,-1; for _,wn in ipairs(inv.Wings) do local d=WingsConfig.Wings[wn]; if d and (d.Cost or 0)>bc and not d.premium then bc=d.Cost or 0;best=wn end end
    if best then EquipWingsRF:InvokeServer(best); Library:Notify("Equipped best!",3) end
end)

local FR3 = TabFarm:AddRightGroupbox("Base Actions")
FR3:AddToggle("AutoCollectAll",{Text="Auto Collect All",Default=false,Callback=function(v) S.autoCollectAll=v end})
FR3:AddSlider("DelayCollect",{Text="Collect Delay (s)",Default=2,Min=0.5,Max=15,Rounding=1,Callback=function(v) S.dCollect=v end})
FR3:AddToggle("AutoUpgSlots",{Text="Auto Upgrade All Slots",Default=false,Callback=function(v) S.autoUpgSlots=v end})
FR3:AddSlider("DelayUpgSlots",{Text="Upg Slots Delay (s)",Default=2,Min=0.5,Max=15,Rounding=1,Callback=function(v) S.dUpgSlots=v end})
FR3:AddToggle("AutoUpgMaxAll",{Text="Auto Upgrade Max All",Default=false,Callback=function(v) S.autoUpgMaxAll=v end})
FR3:AddSlider("DelayUpgMax",{Text="Max Upg Delay (s)",Default=2,Min=0.5,Max=15,Rounding=1,Callback=function(v) S.dUpgMax=v end})
FR3:AddDivider()
FR3:AddButton("Collect All Now",function() tpBase(); local p=getActionPrompt("CollectActionPrompt"); if p then fp(p) end; pcall(function() CollectedCash:FireServer() end); Library:Notify("Collected!",2) end)
FR3:AddButton("Upgrade All Slots Now",function() tpBase(); local p=getActionPrompt("UpgradeAllActionPrompt"); if p then fp(p) end; Library:Notify("Upgraded slots!",2) end)
FR3:AddButton("Upgrade Max All Now",function() tpBase(); local p=getActionPrompt("UpgradeMaxAllActionPrompt"); if p then fp(p) end; Library:Notify("Max upgraded!",2) end)
FR3:AddButton("Upgrade Base Level Now",function() RequestBaseUpgrade:FireServer(); Library:Notify("Base upgrade!",2) end)

local statsLabel = FR3:AddLabel("Loading...",true)
task.spawn(function() while task.wait(2) do pcall(function()
    local bl=LocalPlayer:FindFirstChild("BaseLevel"); local m=LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Money")
    local r=LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Rebirths")
    local sp=LocalPlayer:FindFirstChild("Upgrades") and LocalPlayer.Upgrades:FindFirstChild("SpeedLevel")
    local st=LocalPlayer:FindFirstChild("Upgrades") and LocalPlayer.Upgrades:FindFirstChild("StaminaLevel")
    local ca=LocalPlayer:FindFirstChild("Upgrades") and LocalPlayer.Upgrades:FindFirstChild("CarryLevel")
    statsLabel:SetText("$"..(m and fmt(m.Value) or "?").." | Reb:"..(r and r.Value or "0").."\nBase:"..(bl and bl.Value or "?").." Spd:"..(sp and sp.Value or "?").." Stam:"..(st and st.Value or "?").." Carry:"..(ca and ca.Value or "?"))
end) end end)

-- ============================================================
--  PLAYER LEFT: Movement
-- ============================================================
local PL = TabPlayer:AddLeftGroupbox("Movement")
PL:AddToggle("Fly",{Text="Fly",Default=false,Callback=function(v) S.fly=v end})
PL:AddSlider("FlySpd",{Text="Fly Speed",Default=80,Min=10,Max=500,Rounding=0,Callback=function(v) S.flySpd=v end})
PL:AddDivider()
PL:AddToggle("Speed",{Text="Custom Speed",Default=false,Callback=function(v) S.speed=v end})
PL:AddSlider("SpeedVal",{Text="Walk Speed",Default=50,Min=16,Max=500,Rounding=0,Callback=function(v) S.speedVal=v end})
PL:AddDivider()
PL:AddToggle("Jump",{Text="Custom Jump Power",Default=false,Callback=function(v) S.jump=v end})
PL:AddSlider("JumpVal",{Text="Jump Power",Default=100,Min=50,Max=500,Rounding=0,Callback=function(v) S.jumpVal=v end})
PL:AddDivider()
PL:AddToggle("Noclip",{Text="Noclip",Default=false,Tooltip="Walk through walls.",Callback=function(v) S.noclip=v end})
PL:AddToggle("InfStam",{Text="Infinite Stamina",Default=false,Callback=function(v) S.infStam=v end})
PL:AddToggle("AntiAfk",{Text="Anti AFK",Default=true,Tooltip="Prevent auto-kick for inactivity.",Callback=function(v) S.antiAfk=v end})
PL:AddToggle("GodMode",{Text="God Mode (Client)",Default=false,Tooltip="Max health constantly.",Callback=function(v) S.godMode=v end})

-- ============================================================
--  PLAYER RIGHT: All Teleports
-- ============================================================
local PR1 = TabPlayer:AddRightGroupbox("Quick Teleport")
PR1:AddButton("My Base",function() tpBase(); Library:Notify("TP base!",2) end)
PR1:AddButton("Brainrot Spawners",function()
    local sp = WS:FindFirstChild("ItemSpawners"); if sp then local f=sp:GetChildren()[1]; if f then local p=f:FindFirstChildWhichIsA("BasePart",true); if p then tp(p.Position); Library:Notify("TP spawners!",2) end end end
end)
PR1:AddButton("Sell Area",function() tp(Vector3.new(165,0,12)); Library:Notify("TP sell!",2) end)
PR1:AddButton("Wings Shop",function() tp(Vector3.new(100,0,28)); Library:Notify("TP wings!",2) end)
PR1:AddButton("Upgrades Area",function() tp(Vector3.new(-33,0,27)); Library:Notify("TP upgrades!",2) end)
PR1:AddButton("God Brainrot Spawn",function() tp(Vector3.new(33,5,9995)); Library:Notify("TP god spawn!",2) end)
PR1:AddButton("Collection Zone Start",function() tp(Vector3.new(33,22,54)); Library:Notify("TP collection start!",2) end)
PR1:AddButton("Collection Zone End",function() tp(Vector3.new(28,22,20589)); Library:Notify("TP collection end!",2) end)

-- Zone dropdown
local zoneNames = {}
local spawners = WS:FindFirstChild("ItemSpawners")
if spawners then for _,z in ipairs(spawners:GetChildren()) do table.insert(zoneNames, z.Name) end end
if #zoneNames > 0 then
    PR1:AddDropdown("TPZone",{Text="Brainrot Zone",Values=zoneNames,Default=zoneNames[1],Multi=false})
    PR1:AddButton("TP to Zone",function()
        local sel = Options.TPZone and Options.TPZone.Value
        if sel and spawners then local z=spawners:FindFirstChild(sel); if z then local p=z:FindFirstChildWhichIsA("BasePart",true); if p then tp(p.Position); Library:Notify("TP "..sel,2) end end end
    end)
end

local PR2 = TabPlayer:AddRightGroupbox("Player Teleport")
local function getPN() local n={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(n,p.Name) end end; return n end
local pn = getPN(); if #pn==0 then pn={"(none)"} end
PR2:AddDropdown("TPPlayer",{Text="Player",Values=pn,Default=pn[1],Multi=false})
PR2:AddButton("TP to Player Base",function()
    local sel=Options.TPPlayer and Options.TPPlayer.Value; if not sel then return end
    local pl=WS:FindFirstChild("Plots"); if pl then local plot=pl:FindFirstChild("Plot_"..sel); if plot then
        local ab=plot:FindFirstChild("ActionButtons"); if ab then local bm=ab:FindFirstChild("BanerModel"); if bm then local p=bm:FindFirstChild("Baner"); if p then tp(p.Position); Library:Notify("TP "..sel.."'s base!",2) end end end
    end end
end)
PR2:AddButton("TP to Player",function()
    local sel=Options.TPPlayer and Options.TPPlayer.Value; if not sel then return end
    local t=Players:FindFirstChild(sel); if t and t.Character then local h=t.Character:FindFirstChild("HumanoidRootPart"); if h then tp(h.Position); Library:Notify("TP "..sel,2) end end
end)
PR2:AddButton("Refresh Players",function()
    local n=getPN(); if #n==0 then n={"(none)"} end
    if Options.TPPlayer then Options.TPPlayer:SetValues(n); Options.TPPlayer:SetValue(n[1]) end
    Library:Notify("Refreshed!",2)
end)
PR2:AddDivider()
PR2:AddInput("TPX",{Text="X",Default="0",Numeric=true})
PR2:AddInput("TPY",{Text="Y",Default="0",Numeric=true})
PR2:AddInput("TPZ",{Text="Z",Default="0",Numeric=true})
PR2:AddButton("TP to Position",function()
    local x=tonumber(Options.TPX and Options.TPX.Value) or 0; local y=tonumber(Options.TPY and Options.TPY.Value) or 0; local z=tonumber(Options.TPZ and Options.TPZ.Value) or 0
    tp(Vector3.new(x,y,z)); Library:Notify("TP "..x..","..y..","..z,2)
end)

-- ============================================================
--  VISUALS LEFT: Brainrot ESP
-- ============================================================
local VL = TabVisuals:AddLeftGroupbox("Brainrot ESP")
VL:AddToggle("ESPBR",{Text="Enable Brainrot ESP",Default=false,Callback=function(v) S.espBR=v end})
VL:AddToggle("ESPName",{Text="Show Name",Default=true,Callback=function(v) S.espName=v end})
VL:AddToggle("ESPIncome",{Text="Show Income/s",Default=true,Callback=function(v) S.espIncome=v end})
VL:AddToggle("ESPMut",{Text="Show Mutation",Default=true,Callback=function(v) S.espMut=v end})
VL:AddToggle("ESPRar",{Text="Show Rarity",Default=true,Callback=function(v) S.espRar=v end})
VL:AddDropdown("ESPRarFilter",{Text="Show Rarities",Values={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Default={"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret","Celestial","Cosmic","God","Exclusive"},Multi=true,Callback=function(v) S.espRarFilter=v end})

-- ============================================================
--  VISUALS RIGHT: Player ESP
-- ============================================================
local VR = TabVisuals:AddRightGroupbox("Player ESP")
VR:AddToggle("ESPPlayer",{Text="Enable Player ESP",Default=false,Callback=function(v) S.espPlayer=v end})
VR:AddToggle("ESPPlName",{Text="Show Name",Default=true,Callback=function(v) S.espPlayerName=v end})
VR:AddToggle("ESPPlMoney",{Text="Show Money",Default=true,Callback=function(v) S.espPlayerMoney=v end})
VR:AddToggle("ESPPlReb",{Text="Show Rebirths",Default=true,Callback=function(v) S.espPlayerRebirths=v end})
VR:AddToggle("ESPPlHP",{Text="Show Health",Default=true,Callback=function(v) S.espPlayerHealth=v end})

-- ============================================================
--  SETTINGS
-- ============================================================
ThemeManager:SetLibrary(Library); ThemeManager:SetFolder("AxonHub"); ThemeManager:ApplyToTab(TabSettings)

-- Apply purple theme on launch
pcall(function()
    Library.AccentColor = Color3.fromRGB(140, 70, 255)
    Library.OutlineColor = Color3.fromRGB(100, 40, 200)
    Library.RiskyColor = Color3.fromRGB(180, 100, 255)
    Library.FontColor = Color3.fromRGB(255, 255, 255)
    Library.MainColor = Color3.fromRGB(30, 15, 50)
    Library.BackgroundColor = Color3.fromRGB(20, 10, 35)
    Library:UpdateColors()
end)
SaveManager:SetLibrary(Library); SaveManager:SetFolder("AxonHub"); SaveManager:IgnoreThemeSettings(); SaveManager:BuildConfigSection(TabSettings); SaveManager:LoadAutoloadConfig()

-- ============================================================
--  WATERMARK + UNLOAD
-- ============================================================
Library:SetWatermark("Axon Hub | Brainrot Wings"); Library:SetWatermarkVisibility(true)
Library:OnUnload(function()
    for k,v in pairs(S) do if type(v)=="boolean" then S[k]=false end end
    for _,objs in pairs(espObjBR) do for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end end; espObjBR={}
    for _,objs in pairs(espObjPl) do for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end end; espObjPl={}
    Library:Notify("Axon Hub unloaded.", 3)
end)

UIS.InputBegan:Connect(function(i,g) if g then return end; if i.KeyCode==Enum.KeyCode.RightShift then local sg=Library._ScreenGui; if sg then sg.Enabled=not sg.Enabled end end end)

-- ============================================================
--  ANTI AFK
-- ============================================================
local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:Connect(function()
    if S.antiAfk then vu:CaptureController(); vu:ClickButton2(Vector2.new()) end
end)

-- ============================================================
--  FLY + NOCLIP + SPEED + JUMP + STAMINA + GOD
-- ============================================================
local flyBV,flyBG = nil,nil
local function startFly()
    if not HRP then return end; if flyBV then flyBV:Destroy() end; if flyBG then flyBG:Destroy() end
    flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(math.huge,math.huge,math.huge); flyBV.Velocity=Vector3.zero; flyBV.Parent=HRP
    flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); flyBG.P=9e4; flyBG.Parent=HRP
end
local function stopFly() if flyBV then flyBV:Destroy();flyBV=nil end; if flyBG then flyBG:Destroy();flyBG=nil end end

RunService.Stepped:Connect(function()
    if S.noclip and Character then
        for _,p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if S.fly then
        if not flyBV or not flyBV.Parent then startFly() end
        local cam=WS.CurrentCamera; local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*S.flySpd or Vector3.zero; flyBG.CFrame=cam.CFrame
    else if flyBV then stopFly() end end
    if Humanoid then
        if S.speed then Humanoid.WalkSpeed=S.speedVal end
        if S.jump then Humanoid.JumpPower=S.jumpVal; Humanoid.UseJumpPower=true end
        if S.godMode then Humanoid.Health=Humanoid.MaxHealth end
    end
    if S.infStam then pcall(function() LocalPlayer:SetAttribute("CurrentEnergy",999) end) end
end)

-- ============================================================
--  ESP: Brainrot
-- ============================================================
local function mkBRESP(br,inc,rar,mut,bn)
    local mesh=br:FindFirstChild("Mesh"); if not mesh then return end
    local bb=Instance.new("BillboardGui"); bb.Name="AESP"; bb.Adornee=mesh; bb.Size=UDim2.new(0,200,0,80); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=mesh
    local l=Instance.new("TextLabel"); l.Name="L"; l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextColor3=rarCol[rar] or Color3.new(1,1,1)
    l.TextStrokeTransparency=0; l.TextStrokeColor3=Color3.new(0,0,0); l.Font=Enum.Font.GothamBold; l.TextSize=14; l.TextWrapped=true; l.Parent=bb
    local hl=Instance.new("Highlight"); hl.Name="ACH"; hl.FillColor=rarCol[rar] or Color3.new(1,1,1); hl.FillTransparency=0.7; hl.OutlineColor=rarCol[rar] or Color3.new(1,1,1); hl.OutlineTransparency=0; hl.Parent=br
    return bb,hl
end
local function updBRESP(bb,inc,rar,mut,bn)
    local l=bb:FindFirstChild("L"); if not l then return end; local t={}
    if S.espName then table.insert(t,bn) end; if S.espIncome then table.insert(t,"$"..fmt(inc).."/s") end
    if S.espMut and mut~="Normal" then table.insert(t,"["..mut.."]") end; if S.espRar then table.insert(t,rar) end
    l.Text=table.concat(t,"\n"); l.TextColor3=rarCol[rar] or Color3.new(1,1,1)
end

task.spawn(function() while task.wait(0.5) do pcall(function()
    if S.espBR then
        local sp=WS:FindFirstChild("ItemSpawners"); if not sp then return end; local cur={}
        for _,z in ipairs(sp:GetChildren()) do for _,br in ipairs(z:GetChildren()) do
            if br:IsA("Model") and br:FindFirstChild("Mesh") then
                local inc,rar,mut,bn = brData(br.Name); local rf=S.espRarFilter
                if type(rf)=="table" and next(rf) and not rf[rar] then
                    if espObjBR[br] then for _,o in pairs(espObjBR[br]) do if o and o.Parent then o:Destroy() end end; espObjBR[br]=nil end
                else cur[br]=true
                    if not espObjBR[br] then local bb,hl=mkBRESP(br,inc,rar,mut,bn); if bb then espObjBR[br]={bb,hl} end end
                    if espObjBR[br] then updBRESP(espObjBR[br][1],inc,rar,mut,bn) end
                end
            end
        end end
        for m,objs in pairs(espObjBR) do if not cur[m] or not m.Parent then for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end; espObjBR[m]=nil end end
    else for _,objs in pairs(espObjBR) do for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end end; espObjBR={} end
end) end end)

-- ============================================================
--  ESP: Player
-- ============================================================
local function mkPlESP(char)
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local bb=Instance.new("BillboardGui"); bb.Name="APESP"; bb.Adornee=hrp; bb.Size=UDim2.new(0,200,0,80); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=hrp
    local l=Instance.new("TextLabel"); l.Name="L"; l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(0,255,200)
    l.TextStrokeTransparency=0; l.TextStrokeColor3=Color3.new(0,0,0); l.Font=Enum.Font.GothamBold; l.TextSize=14; l.TextWrapped=true; l.Parent=bb
    local hl=Instance.new("Highlight"); hl.Name="APCH"; hl.FillColor=Color3.fromRGB(0,255,200); hl.FillTransparency=0.7; hl.OutlineColor=Color3.fromRGB(0,255,200); hl.OutlineTransparency=0; hl.Parent=char
    return bb,hl
end

task.spawn(function() while task.wait(1) do pcall(function()
    if S.espPlayer then
        local cur={}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=LocalPlayer and pl.Character then
                cur[pl]=true
                if not espObjPl[pl] then
                    local bb,hl=mkPlESP(pl.Character); if bb then espObjPl[pl]={bb,hl} end
                end
                if espObjPl[pl] then
                    local bb=espObjPl[pl][1]; local l=bb:FindFirstChild("L"); if l then
                        local t={}
                        if S.espPlayerName then table.insert(t, pl.DisplayName.." (@"..pl.Name..")") end
                        local ls=pl:FindFirstChild("leaderstats")
                        if S.espPlayerMoney and ls then local m=ls:FindFirstChild("Money"); if m then table.insert(t,"$"..fmt(m.Value)) end end
                        if S.espPlayerRebirths and ls then local r=ls:FindFirstChild("Rebirths"); if r then table.insert(t,"Reb: "..r.Value) end end
                        if S.espPlayerHealth then local h=pl.Character:FindFirstChildOfClass("Humanoid"); if h then table.insert(t,math.floor(h.Health).."/"..math.floor(h.MaxHealth).." HP") end end
                        l.Text=table.concat(t,"\n")
                    end
                end
            end
        end
        for p,objs in pairs(espObjPl) do if not cur[p] or not p.Character then for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end; espObjPl[p]=nil end end
    else for _,objs in pairs(espObjPl) do for _,o in pairs(objs) do if o and o.Parent then o:Destroy() end end end; espObjPl={} end
end) end end)

-- ============================================================
--  LOOPS: Auto Bring + Place
-- ============================================================
task.spawn(function() while true do task.wait(S.dBring)
    if S.autoBring then pcall(function()
        local brs=getSpawned()
        if next(S.autoBringRar) then local f={}; for _,b in ipairs(brs) do if S.autoBringRar[b.rarity] then table.insert(f,b) end end; brs=f end
        sortBR(brs, S.autoBringSort)
        for _,b in ipairs(brs) do
            if not S.autoBring then break end
            tp(b.position); task.wait(0.3)
            if b.prompt and b.prompt.Parent and b.prompt.Enabled then fp(b.prompt); task.wait(S.dPlace) end
            if S.autoPlace then local es=getEmpty(); if #es>0 then tp(es[1].position); task.wait(S.dPlace); fp(es[1].prompt); task.wait(0.8) end end
        end
    end) end
end end)

-- ============================================================
--  LOOPS: Auto Index
-- ============================================================
task.spawn(function() while true do task.wait(S.dIndex)
    if S.autoIndex then pcall(function()
        local idx=GetIndexData:InvokeServer(); local disc=idx and idx.DiscoveredItems or {}; local brs=getSpawned()
        for _,b in ipairs(brs) do if not S.autoIndex then break end; local key=idxKey(b.name)
            if not disc[key] then tp(b.position); task.wait(0.3)
                if b.prompt and b.prompt.Parent and b.prompt.Enabled then fp(b.prompt); task.wait(0.5)
                    local es=getEmpty(); if #es>0 then tp(es[1].position); task.wait(0.5); fp(es[1].prompt); task.wait(0.8) end
                    RequestSell:FireServer("Equipped"); task.wait(0.3)
                end
            end
        end
    end) end
end end)

-- ============================================================
--  LOOPS: Sell Index / Sell Equipped
-- ============================================================
task.spawn(function() while true do task.wait(S.dSellIdx); if S.autoSellIndex then pcall(function() RequestSell:FireServer("Inventory") end) end end end)
task.spawn(function() while true do task.wait(S.dSellEq); if S.autoSellEquipped then pcall(function() RequestSell:FireServer("Equipped") end) end end end)

-- ============================================================
--  LOOPS: Base Actions (Collect, Upgrade Slots, Max)
-- ============================================================
task.spawn(function() while true do task.wait(S.dCollect)
    if S.autoCollectAll then pcall(function() tpBase(); local p=getActionPrompt("CollectActionPrompt"); if p then fp(p) end; CollectedCash:FireServer() end) end
end end)
task.spawn(function() while true do task.wait(S.dUpgSlots)
    if S.autoUpgSlots then pcall(function() tpBase(); local p=getActionPrompt("UpgradeAllActionPrompt"); if p then fp(p) end end) end
end end)
task.spawn(function() while true do task.wait(S.dUpgMax)
    if S.autoUpgMaxAll then pcall(function() tpBase(); local p=getActionPrompt("UpgradeMaxAllActionPrompt"); if p then fp(p) end end) end
end end)

-- ============================================================
--  LOOPS: Auto Upgrade Brainrot
-- ============================================================
task.spawn(function() while true do task.wait(S.dUpgBR)
    if S.autoUpgBrainrot then pcall(function()
        local placed=getPlaced(); local sm=Options.UpgBRSort and Options.UpgBRSort.Value or "All"
        local rf=Options.UpgBRFilter and Options.UpgBRFilter.Value or {}
        if type(rf)=="table" and next(rf) then local f={}; for _,b in ipairs(placed) do if rf[b.rarity] then table.insert(f,b) end end; placed=f end
        if sm=="Highest Income First" then table.sort(placed,function(a,b) return (a.income or 0)>(b.income or 0) end)
        elseif sm=="Lowest Income First" then table.sort(placed,function(a,b) return (a.income or 0)<(b.income or 0) end) end
        for _,b in ipairs(placed) do if b.spawnPart then local p=b.spawnPart:FindFirstChild("UpgradePrompt"); if p and p:IsA("ProximityPrompt") and p.Enabled then fp(p); task.wait(0.1) end end end
    end) end
end end)

-- ============================================================
--  LOOPS: Auto Upgrade Stats + Base Level
-- ============================================================
task.spawn(function() while true do task.wait(S.dUpgStats); pcall(function()
    if S.autoUpgSpeed then
        local money = LocalPlayer.leaderstats.Money.Value
        local lvl = LocalPlayer.Upgrades.SpeedLevel.Value
        local cfg = require(ReplicatedStorage.Configs.UpgradesConfig)
        local n = 100
        while n > 1 do
            local ok, price = pcall(function() return cfg.Speed.GetPrice(lvl, n) end)
            if ok and money >= price then break end
            n = math.floor(n / 2)
        end
        UpgradeRequested:FireServer("Speed", n)
    end
    if S.autoUpgStamina then
        local money = LocalPlayer.leaderstats.Money.Value
        local lvl = LocalPlayer.Upgrades.StaminaLevel.Value
        local cfg = require(ReplicatedStorage.Configs.UpgradesConfig)
        local n = 100
        while n > 1 do
            local ok, price = pcall(function() return cfg.Stamina.GetPrice(lvl, n) end)
            if ok and money >= price then break end
            n = math.floor(n / 2)
        end
        UpgradeRequested:FireServer("Stamina", n)
    end
    if S.autoUpgCarry then local cl=LocalPlayer:FindFirstChild("Upgrades") and LocalPlayer.Upgrades:FindFirstChild("CarryLevel"); if cl and cl.Value<6 then UpgradeRequested:FireServer("Carry",1) end end
    if S.autoBaseLvl then
        RequestBaseUpgrade:FireServer()
        pcall(function()
            local pl = getPlot(); if not pl then return end
            local bu = pl:FindFirstChild("BaseUpgrade", true); if not bu then return end
            local gp = bu:FindFirstChild("GUIPart"); if not gp then return end
            local pr = gp:FindFirstChild("ProximityPrompt"); if pr and pr.Enabled then
                HRP.CFrame = CFrame.new(gp.Position + Vector3.new(0,3,0)); task.wait(0.3); fp(pr)
            end
        end)
    end
end) end end)

-- ============================================================
--  LOOPS: Auto Buy Wings / Rebirth
-- ============================================================
task.spawn(function() while true do task.wait(S.dBuyWings)
    if S.autoBuyWings then pcall(function()
        local inv=GetInventoryRF:InvokeServer(); if not inv or not inv.Wings then return end
        local owned={}; for _,w in ipairs(inv.Wings) do owned[w]=true end
        local money=LocalPlayer.leaderstats.Money.Value; local reb=LocalPlayer.leaderstats.Rebirths.Value
        for _,w in ipairs(getBuyWings()) do if not owned[w.configName] and money>=w.cost and reb>=w.rebirthsRequired then
            pcall(function() BuyWingsRF:InvokeServer(w.configName) end); Library:Notify("Bought: "..w.publicName,3)
            pcall(function() EquipWingsRF:InvokeServer(w.configName) end); task.wait(0.5)
        end end
    end) end
end end)
task.spawn(function() while true do task.wait(S.dRebirth); if S.autoRebirth then pcall(function() RequestRebirth:FireServer() end) end end end)

-- ============================================================
--  LOOPS: Auto Drop Worst / Auto Equip Best Wings
-- ============================================================
task.spawn(function() while true do task.wait(S.dDrop)
    if S.autoDropWorst then pcall(function()
        local placed=getPlaced(); if #placed<2 then return end
        table.sort(placed,function(a,b) return (a.income or 0)<(b.income or 0) end)
        local worst=placed[1]; if worst.model then RequestDropItem:FireServer(worst.model) end
    end) end
end end)

task.spawn(function() while true do task.wait(S.dEquip)
    if S.autoEquipBest then pcall(function()
        local inv=GetInventoryRF:InvokeServer(); if not inv or not inv.Wings then return end
        local best,bc=nil,-1; for _,wn in ipairs(inv.Wings) do local d=WingsConfig.Wings[wn]; if d and (d.Cost or 0)>bc and not d.premium then bc=d.Cost or 0;best=wn end end
        if best then EquipWingsRF:InvokeServer(best) end
    end) end
end end)

Library:Notify("Axon Hub loaded — RightShift to toggle.", 5)
