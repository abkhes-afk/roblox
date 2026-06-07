local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")

if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
pcall(function() Players.LocalPlayer:WaitForChild("PlayerGui", 10) end)
pcall(function()
    if not Players.LocalPlayer.Character then
        Players.LocalPlayer.CharacterAdded:Wait()
    end
end)

_G._FH_CarpetTP_Speed = _G._FH_CarpetTP_Speed or 214

do	
    local function _stripToolPhysics(tool)
        if not tool or not tool:IsA("Tool") then return end
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("BasePart") then
                pcall(function()
                    d.Massless   = true
                    d.CanCollide = false
                end)
            elseif d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro")
                or d:IsA("AlignPosition") or d:IsA("AlignOrientation") or d:IsA("VectorForce")
                or d:IsA("LinearVelocity") or d:IsA("AngularVelocity") then
                pcall(function() d.Enabled = false end)
            end
        end
        tool.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then
                pcall(function()
                    d.Massless   = true
                    d.CanCollide = false
                end)
            end
        end)
    end
    local function _wireChar(c)
        for _, t in ipairs(c:GetChildren()) do _stripToolPhysics(t) end
        c.ChildAdded:Connect(_stripToolPhysics)
    end
    if Players.LocalPlayer.Character then _wireChar(Players.LocalPlayer.Character) end
    Players.LocalPlayer.CharacterAdded:Connect(_wireChar)
end
local _fhCarpetActiveTween = nil
function _G._FH_CarpetTP(targetCF, speedOverride)
    local lp  = Players.LocalPlayer
    local chr = lp and lp.Character
    local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetCF then return end
    if typeof(targetCF) == "Vector3" then targetCF = CFrame.new(targetCF) end
    local dist = (hrp.Position - targetCF.Position).Magnitude
    local dur  = math.max(0.05, dist / (speedOverride or _G._FH_CarpetTP_Speed or 214))
    local bp = lp:FindFirstChildOfClass("Backpack")
    local carpet = (bp and bp:FindFirstChild("Flying Carpet")) or chr:FindFirstChild("Flying Carpet")
    local hum = chr:FindFirstChildOfClass("Humanoid")
    if carpet and hum and carpet.Parent ~= chr then pcall(function() hum:EquipTool(carpet) end) end
    if _fhCarpetActiveTween then pcall(function() _fhCarpetActiveTween:Cancel() end) end
    local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = targetCF})
    _fhCarpetActiveTween = tw
    tw:Play()
    return tw
end

do
    local _cfgOk, _cfgRaw = pcall(function() return readfile("FadedHub_Config.json") end)
    local _cfgData = nil
    if _cfgOk and _cfgRaw then
        local _parseOk, _parsed = pcall(function()
            return game:GetService("HttpService"):JSONDecode(_cfgRaw)
        end)
        if _parseOk and type(_parsed) == "table" then _cfgData = _parsed end
    end
    if _cfgData and type(_cfgData.toggles) == "table"
       and _cfgData.toggles["Optimizations"] == false then
        _G._FH_AlwaysOnFPS = false
    else
        _G._FH_AlwaysOnFPS = true
    end

    if _cfgData and type(_cfgData.sliders) == "table" then
        local cap = tonumber(_cfgData.sliders.fps_cap)
        if cap then
            local setter = rawget(getfenv(), "setfpscap") or rawget(getfenv(), "set_fps_cap")
            if setter then pcall(setter, math.floor(cap)) end
        end
    end
end

task.spawn(function()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 1e9
        Lighting.Brightness    = 1
    end)
end)
local function _buildMiniPetsSection(
    Config, T, isMobile, Corner, Stroke, Label, Tween, F,
    MiscTab, Players, configRegistry, ShowToggleNotification,
    _buildMakeAnimalCard, ANIMAL_LIST,
    _FH_AddThemeStroke, CreateToggle, GUI, FH_SaveConfig, _FH_BuildThemeSequence
)
    Config.sliders = Config.sliders or {}
    Config.toggles = Config.toggles or {}

    local selectedItem = tostring(Config.sliders.hide_gui_item or "")
    local toggleName   = "Hide GUI On Equip"
    local enabled      = Config.toggles[toggleName] == true

    local cardH = isMobile and 110 or 88
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, -16, 0, cardH)
    card.BackgroundColor3       = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel        = 0
    card.Parent                 = MiscTab.scroll
    Corner(card, 8)
    local cStroke = Stroke(card, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(cStroke)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 2)

    local nameLbl = Label(card, "Hide GUI Item", isMobile and 11 or 13, T.White, Enum.Font.GothamMedium)
    nameLbl.Size         = UDim2.new(1, -28, 0, 16)
    nameLbl.Position     = UDim2.new(0, 14, 0, 8)
    nameLbl.ZIndex       = 2

    local descLbl = Label(card, "Hides entire GUI while this item is equipped; restores on unequip", isMobile and 9 or 11, T.Dim, Enum.Font.Gotham)
    descLbl.Size         = UDim2.new(1, -28, 0, 14)
    descLbl.Position     = UDim2.new(0, 14, 0, 26)
    descLbl.ZIndex       = 2
    descLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local ddBtn = Instance.new("TextButton")
    ddBtn.Size             = UDim2.new(1, -28, 0, 28)
    ddBtn.Position         = UDim2.new(0, 14, 1, -36)
    ddBtn.BackgroundColor3 = T.Card
    ddBtn.BorderSizePixel  = 0
    ddBtn.AutoButtonColor  = false
    ddBtn.Text             = (selectedItem ~= "" and selectedItem) or "▼  Click to select item"
    ddBtn.TextSize         = isMobile and 10 or 11
    ddBtn.Font             = Enum.Font.GothamBold
    ddBtn.TextColor3       = T.White
    ddBtn.ZIndex           = 3
    ddBtn.Parent           = card
    Corner(ddBtn, 6)
    Stroke(ddBtn, T.Border, 1)

    local popup = Instance.new("Frame")
    popup.Size                   = UDim2.new(0, 240, 0, 200)
    popup.BackgroundColor3       = T.Card
    popup.BackgroundTransparency = 0
    popup.BorderSizePixel        = 0
    popup.Visible                = false
    popup.ZIndex                 = 200
    popup.Parent                 = GUI
    Corner(popup, 8)
    Stroke(popup, T.Border, 1)

    local popupScroll = Instance.new("ScrollingFrame")
    popupScroll.Size                   = UDim2.new(1, -8, 1, -8)
    popupScroll.Position               = UDim2.new(0, 4, 0, 4)
    popupScroll.BackgroundTransparency = 1
    popupScroll.BorderSizePixel        = 0
    popupScroll.ScrollBarThickness     = 4
    popupScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    popupScroll.ZIndex                 = 201
    popupScroll.Parent                 = popup

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding   = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent    = popupScroll

    local function makeItemBtn(toolName)
        local b = Instance.new("TextButton")
        b.Size                   = UDim2.new(1, -4, 0, 24)
        b.BackgroundColor3       = T.Card
        b.BackgroundTransparency = 0.4
        b.BorderSizePixel        = 0
        b.Text                   = toolName
        b.TextSize               = isMobile and 10 or 11
        b.Font                   = Enum.Font.Gotham
        b.TextColor3             = T.White
        b.AutoButtonColor        = true
        b.ZIndex                 = 202
        b.Parent                 = popupScroll
        Corner(b, 4)
        b.MouseButton1Click:Connect(function()
            selectedItem = toolName
            ddBtn.Text   = toolName
            Config.sliders.hide_gui_item = toolName
            pcall(FH_SaveConfig)
            popup.Visible = false
        end)
        return b
    end

    local function refreshList()
        for _, c in ipairs(popupScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local seen = {}
        local lp = Players and Players.LocalPlayer
        if lp then
            local bp = lp:FindFirstChild("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and not seen[t.Name] then
                        seen[t.Name] = true
                        makeItemBtn(t.Name)
                    end
                end
            end
            local ch = lp.Character
            if ch then
                for _, t in ipairs(ch:GetChildren()) do
                    if t:IsA("Tool") and not seen[t.Name] then
                        seen[t.Name] = true
                        makeItemBtn(t.Name)
                    end
                end
            end
        end
        if next(seen) == nil then
            local empty = Instance.new("TextLabel")
            empty.Size                   = UDim2.new(1, -4, 0, 24)
            empty.BackgroundTransparency = 1
            empty.Text                   = "No tools in Backpack or equipped"
            empty.TextSize               = isMobile and 10 or 11
            empty.Font                   = Enum.Font.Gotham
            empty.TextColor3             = T.Dim
            empty.ZIndex                 = 202
            empty.Parent                 = popupScroll
        end
        popupScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
    end

    ddBtn.MouseButton1Click:Connect(function()
        if popup.Visible then popup.Visible = false return end
        refreshList()
        local abs = ddBtn.AbsolutePosition
        local sz  = ddBtn.AbsoluteSize
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local px = math.min(abs.X, viewport.X - 240 - 8)
        local py = math.min(abs.Y + sz.Y + 4, viewport.Y - 200 - 8)
        popup.Position = UDim2.new(0, math.max(8, px), 0, math.max(8, py))
        popup.Visible  = true
    end)

    local function isSelectedEquipped()
        if selectedItem == "" then return false end
        local lp = Players and Players.LocalPlayer
        local ch = lp and lp.Character
        if not ch then return false end
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t.Name == selectedItem then return true end
        end
        return false
    end

    local _HIDE_GUI_ESP_NAMES = {
        "Player ESP",
        "Base ESP", "Timer ESP", "Allowed ESP",
        "Clone ESP", "Brainrot ESP",
    }
    local _espStateBeforeHide = {}
    local _espCurrentlyHidden = false

    local function disableAllESPs()
        if _espCurrentlyHidden then return end
        _espCurrentlyHidden = true
        _espStateBeforeHide = {}
        for _, espName in ipairs(_HIDE_GUI_ESP_NAMES) do
            local reg = configRegistry[espName]
            if reg and reg.getState and reg.getState() == true then
                _espStateBeforeHide[espName] = true
                pcall(function()
                    if reg.setEnabled then reg.setEnabled(false)
                    elseif reg.doToggle then reg.doToggle() end
                end)
            end
        end
    end

    local function restoreAllESPs()
        if not _espCurrentlyHidden then return end
        _espCurrentlyHidden = false
        for _, espName in ipairs(_HIDE_GUI_ESP_NAMES) do
            if _espStateBeforeHide[espName] then
                local reg = configRegistry[espName]
                if reg then
                    pcall(function()
                        if reg.setEnabled then reg.setEnabled(true)
                        elseif reg.doToggle then reg.doToggle() end
                    end)
                end
            end
        end
        _espStateBeforeHide = {}
    end

    local _petWasHidden = false

    local function hideMiniPets()
        if _petWasHidden then return end
        _petWasHidden = true
        pcall(function()
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj.Name:sub(1, 4) == "MBF_" then
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 1
                        end
                    end
                end
            end
        end)
    end

    local function showMiniPets()
        if not _petWasHidden then return end
        _petWasHidden = false
        pcall(function()
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj.Name:sub(1, 4) == "MBF_" then
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                        end
                    end
                end
            end
        end)
    end

    local _progBarGui = nil
    local _progBarFill = nil
    local _progBarWasHidden = false

    local function _findProgressBarGui()
        if _progBarGui and _progBarGui.Parent then return _progBarGui end

        local cg = game:GetService("CoreGui")
        _progBarGui = cg:FindFirstChild("FH_AutoGrabProgress")
        if not _progBarGui then
            local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
            _progBarGui = pg and pg:FindFirstChild("FH_AutoGrabProgress")
        end
        if _progBarGui and not _progBarFill then

            local frame = _progBarGui:FindFirstChildOfClass("Frame")
            if frame then
                local track = frame:FindFirstChild("Frame")

                for _, d in ipairs(frame:GetDescendants()) do
                    if d:IsA("Frame") and d.Name ~= "Frame" and d.Parent
                    and d.Parent:IsA("Frame") then
                        _progBarFill = d
                        break
                    end
                end

                if not _progBarFill then
                    local inner = frame:FindFirstChildOfClass("Frame")
                    if inner then
                        _progBarFill = inner:FindFirstChildOfClass("Frame")
                    end
                end
            end

            if _progBarFill then
                local function _syncProgBarTheme()
                    pcall(function()
                        if not (_progBarFill and _progBarFill.Parent) then return end
                        local g = _progBarFill:FindFirstChildOfClass("UIGradient")
                        if not g then
                            g = Instance.new("UIGradient")
                            g.Parent = _progBarFill
                        end
                        if _FH_BuildThemeSequence then
                            g.Color = _FH_BuildThemeSequence()
                        end

                        _progBarFill.BackgroundColor3 = _G._FH_AccentA or Color3.fromRGB(60, 210, 100)
                    end)
                end

                _syncProgBarTheme()

                _G._FH_ThemeCallbacks = _G._FH_ThemeCallbacks or {}
                table.insert(_G._FH_ThemeCallbacks, _syncProgBarTheme)
            end
        end
        return _progBarGui
    end

    local function hideProgressBar()
        if _progBarWasHidden then return end
        _progBarWasHidden = true

        _G._FH_HideAutoGrabBar = true
        pcall(function()
            local gui = _findProgressBarGui()
            if gui then gui.Enabled = false end
        end)
    end

    local function showProgressBar()
        if not _progBarWasHidden then return end
        _progBarWasHidden = false

        local reg = configRegistry["Hide Progress Bar"]
        _G._FH_HideAutoGrabBar = (reg and reg.getState and reg.getState()) or false
        pcall(function()
            if not _G._FH_HideAutoGrabBar then
                local gui = _findProgressBarGui()
                if gui then gui.Enabled = true end
            end
        end)
    end

    task.defer(_findProgressBarGui)

    do
        local function _fixAutoGrabBarTheme()
            pcall(function()
                local cg = game:GetService("CoreGui")
                local gui = cg:FindFirstChild("FH_AutoGrabProgress")
                    or (Players.LocalPlayer:FindFirstChild("PlayerGui")
                        and Players.LocalPlayer.PlayerGui:FindFirstChild("FH_AutoGrabProgress"))
                if not gui then return end
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("UIGradient") and d.Parent and d.Parent:IsA("Frame") then
                        if _FH_BuildThemeSequence then
                            d.Color = _FH_BuildThemeSequence()
                        end
                        local parentFrame = d.Parent
                        parentFrame.BackgroundColor3 = _G._FH_AccentA or Color3.fromRGB(60, 210, 100)
                    end
                end

                local frame = gui:FindFirstChildOfClass("Frame")
                if frame then
                    for _, d in ipairs(frame:GetDescendants()) do
                        if d:IsA("UIStroke") then
                            local g = d:FindFirstChildOfClass("UIGradient")
                            if not g then
                                g = Instance.new("UIGradient")
                                g.Parent = d
                                table.insert(_G._FH_ThemeStrokes, g)
                            end
                            if _FH_BuildThemeSequence then g.Color = _FH_BuildThemeSequence() end
                        end
                    end
                end
            end)
        end
        _G._FH_ThemeCallbacks = _G._FH_ThemeCallbacks or {}
        table.insert(_G._FH_ThemeCallbacks, _fixAutoGrabBarTheme)
        pcall(_fixAutoGrabBarTheme)
    end

    local function applyGuiState()
        if not GUI then return end
        if not enabled then

            GUI.Enabled = true
            restoreAllESPs()
            showMiniPets()
            showProgressBar()
            return
        end
        local equipped = isSelectedEquipped()
        GUI.Enabled = not equipped
        if equipped then
            disableAllESPs()
            hideMiniPets()
            hideProgressBar()
        else
            restoreAllESPs()
            showMiniPets()
            showProgressBar()
        end
    end

    local _charConns = {}
    local function disconnectCharConns()
        for _, c in ipairs(_charConns) do pcall(function() c:Disconnect() end) end
        _charConns = {}
    end

    local function hookChar(char)
        disconnectCharConns()
        table.insert(_charConns, char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then task.wait(); applyGuiState() end
        end))
        table.insert(_charConns, char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then task.wait(); applyGuiState() end
        end))

        if GUI then GUI.Enabled = true end
        restoreAllESPs()
        showMiniPets()
        showProgressBar()
        task.wait(0.1)
        applyGuiState()
    end

    local lp = Players and Players.LocalPlayer
    if lp then
        if lp.Character then hookChar(lp.Character) end
        lp.CharacterAdded:Connect(hookChar)
    end

    CreateToggle(MiscTab.scroll, toggleName, "Auto-hides the UI while your selected item is equipped",
        function(v)
            enabled = v
            if not v then
                if GUI then GUI.Enabled = true end
                restoreAllESPs()
                showMiniPets()
                showProgressBar()
            end
            applyGuiState()
        end
    )
end

task.spawn(function()
    pcall(function()
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect")
            or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled = false end)
            end
        end
    end)
end)
task.spawn(function()

    task.wait()
    pcall(function()
        local _step = 0
        local YIELD_EVERY = 200
        for _, obj in ipairs(workspace:GetDescendants()) do
            local cls = obj.ClassName
            if cls == "ParticleEmitter" or cls == "Trail"
            or cls == "Smoke" or cls == "Fire" or cls == "Sparkles" then
                obj.Enabled = false
            elseif obj:IsA("BasePart") then
                if obj.Material == Enum.Material.Glass then
                    pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
                end
            end
            _step = _step + 1
            if _step % YIELD_EVERY == 0 then task.wait() end
        end
    end)
end)
do
    local NetMod   = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net")
    local NetClone = require(NetMod:Clone())

    local function getRemote(name)
        if not name then return nil end
        local ok, rn = pcall(function() return NetClone:RemoteEvent(name) end)
        if not ok or not rn then return nil end
        return NetMod[tostring(rn)]
    end
    local function getRemoteFunction(name)
        if not name then return nil end
        local ok, rn = pcall(function() return NetClone:RemoteFunction(name) end)
        if not ok or not rn then return nil end
        return NetMod[tostring(rn)]
    end
    _G._FH_NetMod          = NetMod
    _G._FH_NetClone        = NetClone
    _G._FH_GetRemote       = getRemote
    _G._FH_GetRemoteFn     = getRemoteFunction
    _FH_StealRemote = getRemote("3ba148c9-7ed6-4675-93f8-9f7c356a2c54")

    _FH_UseItemRemote = getRemote("UseItem")
    _FH_TRIP_U1  = "68c86eb7-eb7e-4b4d-96ae-cf7cd847c5b0"
    _FH_TRIP_U2  = "07b9cc25-2a1f-4a26-a0ec-f2fab578d8bd"
    _FH_STEAL_U1 = "cda5c764-d4e3-45c4-94e4-53a538347590"
    _FH_STEAL_U2 = "8c852fbf-d542-4ef4-aa28-612e24db8d4a"
    function _FH_ResolvePromptTarget(prompt)
        if not prompt or not prompt.Parent then return nil end
        local att    = prompt.Parent
        local spawn  = att and att.Parent
        local base   = spawn and spawn.Parent
        local podium = base and base.Parent
        local pods   = podium and podium.Parent
        local plot   = pods and pods.Parent
        local pod    = podium and tonumber(podium.Name)
        if not (plot and pod) then return nil end
        return { plotName = plot.Name, pod = pod }
    end
    function _FH_StartTrip(target)
        local T0 = workspace:GetServerTimeNow()
        _G._FH_LastStealStart = tick()
        return { t0 = T0, startedAt = tick(), target = target }
    end
    function _FH_FinishSteal(ctx)
        if not ctx or not ctx.target then return false end
        local elapsed = tick() - ctx.startedAt
        if elapsed < 1.3 then task.wait(1.3 - elapsed) end
        local ts = ctx.t0 + 1.3 + 31
        pcall(function() _FH_StealRemote:FireServer(ts, _FH_STEAL_U1, ctx.target.plotName, ctx.target.pod) end)
        pcall(function() _FH_StealRemote:FireServer(ts, _FH_STEAL_U2, ctx.target.plotName, ctx.target.pod) end)
        return true
    end
    function _FH_FireStealPrompt(prompt)
        local target = _FH_ResolvePromptTarget(prompt)
        if not target then return false end
        local ctx = _FH_StartTrip(target)
        return _FH_FinishSteal(ctx)
    end
end

local __stealActive_v2 = false
_G.__stealActive = false

local __stealCbCache_v2 = {}
local __MIN_HOLD_TIME_v2       = 1.3
local __TRIGGER_AFTER_GREEN_v2 = 0.02

local function __buildStealCallbacks_v2(prompt)
    if __stealCbCache_v2[prompt] then return __stealCbCache_v2[prompt] end
    if not getconnections then return nil end
    local data = { hold = {}, trigger = {} }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then
        for _, c in ipairs(conns1) do
            if type(c.Function) == "function" then table.insert(data.hold, c.Function) end
        end
    end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then
        for _, c in ipairs(conns2) do
            if type(c.Function) == "function" then table.insert(data.trigger, c.Function) end
        end
    end
    if #data.hold == 0 and #data.trigger == 0 then return nil end
    __stealCbCache_v2[prompt] = data
    return data
end

local __FH_v2 = {}

function __FH_v2.startStealHold(prompt, method)
    if not prompt or not prompt.Parent then return nil end
    local cb = __buildStealCallbacks_v2(prompt)
    if not cb then return nil end

    __stealActive_v2 = true
    _G.__stealActive = true

    for _, fn in ipairs(cb.hold) do task.spawn(fn) end
    local now = tick()

    return {
        prompt          = prompt,
        cb              = cb,
        method          = method,
        ragdollFireTime = now,
        startedAt       = now,
        holdBeganAt     = now,
        holdDone        = true,
    }
end

function __FH_v2.doHoldAndWait(ctx)
    if ctx.holdDone then return end
    for _, fn in ipairs(ctx.cb.hold) do task.spawn(fn) end
    ctx.holdBeganAt = tick()
    task.wait(__MIN_HOLD_TIME_v2)
    ctx.holdDone = true
end

function __FH_v2.waitForStealTime(ctx, sec)
    if not ctx then return end
    if sec >= 1.0 then return end
    local elapsed = tick() - ctx.ragdollFireTime
    if elapsed < sec then task.wait(sec - elapsed) end
end

function __FH_v2.finishStealHold(ctx)
    if not ctx then return false end
    if not ctx.holdBeganAt then __FH_v2.doHoldAndWait(ctx) end
    local heldFor = tick() - (ctx.holdBeganAt or tick())
    if heldFor < __MIN_HOLD_TIME_v2 then task.wait(__MIN_HOLD_TIME_v2 - heldFor) end
    task.wait(__TRIGGER_AFTER_GREEN_v2)
    for _, fn in ipairs(ctx.cb.trigger) do task.spawn(fn) end
    __stealActive_v2 = false
    _G.__stealActive = false
    return true
end

local function _FH_V2FireStealPrompt(prompt, finalizeFn)
    if not prompt or not prompt.Parent then return false end
    local cb = __buildStealCallbacks_v2(prompt)
    if not cb then

        local target = _FH_ResolvePromptTarget(prompt)
        if not target then return false end
        local ctx = _FH_StartTrip(target)
        if finalizeFn then pcall(finalizeFn) end
        return _FH_FinishSteal(ctx)
    end

    local target = _FH_ResolvePromptTarget(prompt)
    local ctx = target and _FH_StartTrip(target) or nil

    for _, fn in ipairs(cb.hold) do task.spawn(fn) end
    local holdBeganAt = tick()

    if finalizeFn then
        local holdElapsed = tick() - holdBeganAt
        local waitFor = 1.3 - holdElapsed - 0.05
        if waitFor > 0 then task.wait(waitFor) end
        pcall(finalizeFn)
    else
        local holdElapsed = tick() - holdBeganAt
        if holdElapsed < __MIN_HOLD_TIME_v2 then
            task.wait(__MIN_HOLD_TIME_v2 - holdElapsed)
        end
    end

    task.wait(__TRIGGER_AFTER_GREEN_v2)

    for _, fn in ipairs(cb.trigger) do task.spawn(fn) end

    if ctx then
        task.spawn(function() _FH_FinishSteal(ctx) end)
    end
    return true
end

local _FH_SAVE_PATH = "FadedHub_Config.json"
local configRegistry = {}
local HttpService   = game:GetService("HttpService")
local function FH_LoadConfig()
    local ok, raw = pcall(function() return readfile(_FH_SAVE_PATH) end)
    if ok and raw then
        local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and type(data) == "table" then return data end
    end
    return nil
end

local _FH_RestoreComplete = false
local _FH_SaveDebounceToken = 0
local _FH_SaveLastQueued = 0
local function _FH_DoSaveConfig()
    pcall(function()
        for name, reg in pairs(configRegistry) do
            if reg.getState then
                local live = reg.getState()

                if not _G._FH_IsRestoring then
                    Config.toggles[name] = live
                elseif live == true or Config.toggles[name] == nil then
                    Config.toggles[name] = live
                end
            end
            if reg.getKeyCode then
                local kc = reg.getKeyCode()
                if kc then
                    Config.keybinds[name] = kc.Name
                elseif not _G._FH_IsRestoring then
                    Config.keybinds[name] = nil
                end
            end
        end
        if SP and SP.wsBox then
            Config.sliders = Config.sliders or {}
            Config.sliders.sp_walkspeed = SP.wsBox.Text
        end
        if SP and SP.jpBox then
            Config.sliders = Config.sliders or {}
            Config.sliders.sp_jumppower = SP.jpBox.Text
        end

        if _G._FH_PotionSpeedValue then
            Config.sliders = Config.sliders or {}
            Config.sliders.potion_speed = _G._FH_PotionSpeedValue
        end
        if _G._FH_FpsCapValue then
            Config.sliders = Config.sliders or {}
            Config.sliders.fps_cap = _G._FH_FpsCapValue
        end

        Config.mini = Config.mini or {}
        if SP  and SP.SpeedWin         then Config.mini.sp_open   = SP.SpeedWin.Visible         end
        if SS  and SS.SSWin            then Config.mini.ss_open   = SS.SSWin.Visible             end
        if AB  and AB.AllowBaseWin     then Config.mini.ab_open   = AB.AllowBaseWin.Visible      end
        if FA  and FA.FAWin            then Config.mini.fa_open   = FA.FAWin.Visible             end
        if FD  and FD.FDWin            then Config.mini.fd_open   = FD.FDWin.Visible             end
        if QP  and QP.QPWin            then Config.mini.qp_open   = QP.QPWin.Visible             end
        if CD  and CD.CDWin            then Config.mini.cd_open   = CD.CDWin.Visible             end
        if WSK and WSK.WSKWin          then Config.mini.wsk_open  = WSK.WSKWin.Visible           end
        if QS  and QS.QSWin            then Config.mini.qs_open   = QS.QSWin.Visible             end
        if UB  and UB.UBWin            then Config.mini.ub_open   = UB.UBWin.Visible             end
        if UB  and UB.isHorizontal ~= nil then Config.mini.ub_horiz = UB.isHorizontal == true end
        if FS  and FS.FSWin            then Config.mini.fs_open   = FS.FSWin.Visible              end
        if _G.SpammerGui and _G.SpammerGui.win then
            Config.mini.spam_open      = _G.SpammerGui.win.Visible
        end
        if _G.SpammerGui and _G.SpammerGui.isCustomizeOpen then
            Config.mini.customize_open = _G.SpammerGui.isCustomizeOpen()
        end
        local function _snapPos(win)
            if not win then return nil end
            return {
                x  = win.Position.X.Offset,
                y  = win.Position.Y.Offset,
                xs = win.Position.X.Scale,
                ys = win.Position.Y.Scale,
            }
        end
        if SP  and SP.SpeedWin         then Config.mini.sp_pos   = _snapPos(SP.SpeedWin)         end
        if SS  and SS.SSWin            then Config.mini.ss_pos   = _snapPos(SS.SSWin)            end
        if AB  and AB.AllowBaseWin     then Config.mini.ab_pos   = _snapPos(AB.AllowBaseWin)     end
        if FA  and FA.FAWin            then Config.mini.fa_pos   = _snapPos(FA.FAWin)            end
        if FD  and FD.FDWin            then Config.mini.fd_pos   = _snapPos(FD.FDWin)            end
        if QP  and QP.QPWin            then Config.mini.qp_pos   = _snapPos(QP.QPWin)            end
        if CD  and CD.CDWin            then Config.mini.cd_pos   = _snapPos(CD.CDWin)            end
        if WSK and WSK.WSKWin          then Config.mini.wsk_pos  = _snapPos(WSK.WSKWin)          end
        if QS  and QS.QSWin            then Config.mini.qs_pos   = _snapPos(QS.QSWin)            end
        if FS  and FS.FSWin            then Config.mini.fs_pos   = _snapPos(FS.FSWin)            end
        if Win                         then Config.mini.main_pos = _snapPos(Win)                 end
        if UB and UB.UBWin then
            local vp  = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            local ax  = UB.UBWin.Position.X.Scale * vp.X + UB.UBWin.Position.X.Offset
            local ay  = UB.UBWin.Position.Y.Scale * vp.Y + UB.UBWin.Position.Y.Offset
            Config.mini.ub_pos = { x = ax, y = ay, xs = 0, ys = 0 }
        end
        if _G.SpammerGui and _G.SpammerGui.win then
            Config.mini.spam_pos = _snapPos(_G.SpammerGui.win)
        end
        local _custWin = GUI and GUI:FindFirstChild("CustomizeSpamGui")
        if _custWin then
            Config.mini.customize_pos = _snapPos(_custWin)
        end
        local data = {
            toggles      = Config.toggles  or {},
            keybinds     = Config.keybinds or {},
            mini         = Config.mini     or {},
            sliders      = Config.sliders  or {},
            spammer      = Config.spammer  or {},
            theme        = Config.theme    or {},
            version      = 1,
        }
        local encoded = HttpService:JSONEncode(data)
        task.spawn(function()
            pcall(function() writefile(_FH_SAVE_PATH, encoded) end)
        end)
    end)
end
local function FH_SaveConfig()
    _FH_SaveDebounceToken = _FH_SaveDebounceToken + 1
    _FH_SaveLastQueued = tick()
    _FH_DoSaveConfig()
end
task.spawn(function()
    while true do
        task.wait(4)
        if _FH_RestoreComplete then
            pcall(FH_SaveConfig)
        end
    end
end)
local _FH_SavedConfig = FH_LoadConfig()
Config = {
    toggles  = (_FH_SavedConfig and _FH_SavedConfig.toggles)  or {},
    keybinds = (_FH_SavedConfig and _FH_SavedConfig.keybinds) or {},
    mini     = (_FH_SavedConfig and _FH_SavedConfig.mini)     or {},
    sliders  = (_FH_SavedConfig and _FH_SavedConfig.sliders)  or {},
    spammer  = (_FH_SavedConfig and _FH_SavedConfig.spammer)  or {},
    theme    = (_FH_SavedConfig and _FH_SavedConfig.theme)    or {},
    version  = 1,
}

if _FH_SavedConfig and _FH_SavedConfig.mini then
    _G._FH_POS = {}
    for k, v in pairs(_FH_SavedConfig.mini) do _G._FH_POS[k] = v end
end

local ShowToggleNotification
local VirtualInputManager = Instance.new("VirtualInputManager")
_G.FadedHubAlive = true
local FriendsESPEnabled = false
local FriendsESPConnections = {}
local V3 = { enabled = false, potionOn = false, giant = nil, potionEquipped = false }
local FPS = { connections = {} }
local AntiRagdoll = { connections = {}, running = false }
local SS = {
    player           = nil,
    teleporting      = false,
    debounce         = false,
    speed            = false,
    minimized        = false,
    dragging         = false,
    dragStart        = nil,
    panelStart       = nil,
    potionState      = false,
    autoTPUnlockState = false,
    stealMethod      = "Walk",
    semiInstantMode  = "Semi",
    _scriptStartTime = tick(),
    _autoFullSwitched = false,
    W = 138, H = 220,
    BG        = Color3.fromRGB(15, 15, 15),
    HDR       = Color3.fromRGB(8,  8,  8),
    BTN       = Color3.fromRGB(24, 24, 24),
    BTN_HOVER = Color3.fromRGB(38, 38, 38),
}
local SP = {
    W = 150, H = 130,
    minimized  = false,
    dragging   = false,
    dragStart  = nil,
    panelStart = nil,
    state      = false,
    entry      = { keyCode = nil },
    kb2Debounce = false,
}
local AB = {
    W = 155, H = 60,
    minimized  = false,
    dragging   = false,
    dragStart  = nil,
    panelStart = nil,
    allowState = false,
}
local FA = {}
local FD = {}
local QP = {}
local CD = {}
local SVN = {}
local STP = {}
local QS  = {}
local PS  = {}
local UB  = {
    W = 180, H = 74,
    minimized  = false,
    dragging   = false,
    dragStart  = nil,
    panelStart = nil,
}
local Win, BorderFrame
local function setGuiVisible(vis)
    Win.Visible         = vis
    BorderFrame.Visible = vis
end
local hidden    = false
local animating = false
local HIDE_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local SHOW_INFO = TweenInfo.new(0.5,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local T, F, M, S
local Tween, Corner, Stroke, Padding, Label
local GUI, WIN_W, WIN_H
local BOOK_OPEN
local BANNER_W, BANNER_H
local BannerStrokeInst
local BannerTitle, BannerDev, BannerStats
local bannerAngle, fpsClock, fpsFrames, displayFPS
local Hdr, HdrFill, HdrLine, Dot, TitleLbl, VerLbl
local TabBar, TBLine, TabLayout, ContentArea
local CreateToggle, CreateSection, MakeScroll
local Tabs, ActiveTab, TabSwiping, TabIndex
local SLIDE_IN, SLIDE_OUT, ActivateTab, TAB_W, CreateTab
local CombatTab, VisualTab, PlayerTab, MiscTab
local TopBanner
local keybindBindingTarget = nil
local keybindEntries = {}
local Player = Players.LocalPlayer
local LocalPlayer = Player

local antiDieConnection = nil
local antiDieDisabled = false
local function setupAntiDie()
    if antiDieDisabled then return end
    local character = Player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if antiDieConnection then
        pcall(function() antiDieConnection:Disconnect() end)
    end
    antiDieConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if antiDieDisabled then return end
        if humanoid.Health <= 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end
setupAntiDie()
Player.CharacterAdded:Connect(function() task.wait(0.1); setupAntiDie() end)

do
    _G._FH_AntiGummyBear  = _G._FH_AntiGummyBear  or false
    _G._FH_AntiAdminPanel = _G._FH_AntiAdminPanel or false

    local antiGummyRespawnGraceUntil = 0
    local originalScales   = {}
    local originalHipHeight = nil
    local scaleNames = {
        "HeadScale", "BodyDepthScale", "BodyHeightScale",
        "BodyProportionScale", "BodyTypeScale", "BodyWidthScale",
    }
    local function captureOriginals()
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        originalHipHeight = hum.HipHeight
        originalScales = {}
        for _, name in ipairs(scaleNames) do
            local sv = hum:FindFirstChild(name)
            if sv then originalScales[name] = sv.Value end
        end
    end
    Player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        antiGummyRespawnGraceUntil = tick() + 1.5
        task.wait(0.1)
        captureOriginals()
    end)
    task.spawn(captureOriginals)

    local _ctrlCache = nil
    local function getControls()
        if _ctrlCache then return _ctrlCache end
        local ps = Player:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if not pm then return nil end
        local ok, mod = pcall(require, pm)
        if not ok or not mod then return nil end
        local ok2, c = pcall(function() return mod:GetControls() end)
        if ok2 and c then _ctrlCache = c end
        return _ctrlCache
    end
    Player.CharacterAdded:Connect(function() _ctrlCache = nil end)

    local _charController, _jumpscareMod
    local function _tryRequireCharController()
        if _charController ~= nil then return _charController end
        local ok, mod = pcall(function()
            return require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CharacterController"))
        end)
        _charController = ok and mod or false
        return _charController
    end
    local function _tryRequireJumpscare()
        if _jumpscareMod ~= nil then return _jumpscareMod end
        local ok, mod = pcall(function()
            return require(game:GetService("ReplicatedStorage"):WaitForChild("Datas"):WaitForChild("AdminCommands"):WaitForChild("jumpscare"))
        end)
        _jumpscareMod = ok and mod or false
        return _jumpscareMod
    end

    local function clearGummyToolBlockState(char)
        for _, inst in ipairs({ Player, char }) do
            if inst then
                if inst:GetAttribute("BlockTools") ~= nil and inst:GetAttribute("BlockTools") ~= false then
                    inst:SetAttribute("BlockTools", false)
                end
                if inst:GetAttribute("Web") ~= nil and inst:GetAttribute("Web") ~= false then
                    inst:SetAttribute("Web", false)
                end
            end
        end
        if char and char:GetAttribute("BackpackReady") == false then
            char:SetAttribute("BackpackReady", true)
        end
    end

    task.spawn(function()
        while task.wait(0.1) do
            if not (_G._FH_AntiGummyBear or _G._FH_AntiAdminPanel) then continue end
            local char = Player.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then continue end

            if _G._FH_AntiGummyBear and tick() >= antiGummyRespawnGraceUntil then
                clearGummyToolBlockState(char)
            end

            if _G._FH_AntiAdminPanel then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") or v:IsA("Attachment") then
                        v:Destroy()
                    elseif v:IsA("Motor6D") then
                        v.Enabled = true
                    end
                end
                local ctrl = getControls()
                if ctrl then pcall(function() ctrl:Enable() end) end
                local state = hum:GetState()
                if state ~= Enum.HumanoidStateType.Running
                    and state ~= Enum.HumanoidStateType.Jumping
                    and state ~= Enum.HumanoidStateType.Freefall then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                end
                if workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject ~= hum then
                    workspace.CurrentCamera.CameraSubject = hum
                end
                local ragdollEnd = Player:GetAttribute("RagdollEndTime") or 0
                if ragdollEnd > workspace:GetServerTimeNow() then
                    hrp.Velocity = Vector3.zero
                    Player:SetAttribute("RagdollEndTime", 0)
                end
                local cc = _tryRequireCharController()
                if cc and ctrl then
                    ctrl.moveFunction = function(p, x, z) cc:RequestMove(p, x, z) end
                end
                local jm = _tryRequireJumpscare()
                if jm and jm.effects and jm.effects.Victim then
                    jm.effects.Victim = function() end
                end
                if originalHipHeight and hum.HipHeight ~= originalHipHeight then
                    hum.HipHeight = originalHipHeight
                end
                for _, name in ipairs(scaleNames) do
                    local sv = hum:FindFirstChild(name)
                    if sv and originalScales[name] and sv.Value ~= originalScales[name] then
                        sv.Value = originalScales[name]
                    end
                end
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("Model") and not v:IsA("BackpackItem") then
                        v:Destroy()
                    end
                end
            end
        end
    end)
end

local ToggleHandlers = {}
local instantRespawnDebounce = false
local function instantRespawn(_btn)
    if instantRespawnDebounce then return end
    instantRespawnDebounce = true
    local lp      = Players.LocalPlayer
    local oldChar = lp.Character
    if not oldChar then instantRespawnDebounce = false; return end
    local hrp = oldChar:FindFirstChild("HumanoidRootPart")
    local hum = oldChar:FindFirstChildWhichIsA("Humanoid")
    if hrp and hum then
        hum.Health = 0
        pcall(function() hrp.CFrame = CFrame.new(0, 50000, 0) end)
    end
    while lp.Character == oldChar do task.wait() end
    instantRespawnDebounce = false
end

local function doSelectedReset()
    local lp   = Players.LocalPlayer
    local char = lp and lp.Character
    if not char then return end
    task.spawn(function()
        pcall(function()
            local RSrv  = game:GetService("RunService")
            local remote = _G._FH_GetRemote and _G._FH_GetRemote("Tools/Cooldown")
            if not remote then return end
            local savedTools = {}
            local bp  = lp:FindFirstChild("Backpack")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:UnequipTools() end) end
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then table.insert(savedTools, t); t.Parent = nil end
            end
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then table.insert(savedTools, t); t.Parent = nil end
                end
            end
            lp.Character = nil
            local sending  = true
            local loopConn
            local fire     = remote.FireServer
            local throttle = 0
            loopConn = RSrv.Heartbeat:Connect(function(dt)
                if not sending then
                    if loopConn then loopConn:Disconnect(); loopConn = nil end
                    return
                end
                throttle = throttle + dt
                if throttle >= 0.1 then
                    throttle = 0
                    pcall(fire, remote, "f888ee6e-c86d-46e1-93d7-0639d6635d42", lp, "balloon")
                end
                if sending and lp.Character then lp.Character = nil end
            end)
            local charConn
            charConn = lp.CharacterAdded:Connect(function()
                sending = false
                if loopConn then loopConn:Disconnect(); loopConn = nil end
                if charConn then charConn:Disconnect() end
                task.spawn(function()
                    local newBp = lp:WaitForChild("Backpack", 3)
                    if newBp then
                        for _, t in ipairs(savedTools) do if t then t.Parent = newBp end end
                    end
                    savedTools = {}
                end)
            end)
            task.delay(4, function()
                sending = false
                if loopConn then loopConn:Disconnect(); loopConn = nil end
                local curBp = lp:FindFirstChild("Backpack")
                if curBp and #savedTools > 0 then
                    for _, t in ipairs(savedTools) do if t then t.Parent = curBp end end
                    savedTools = {}
                end
            end)
        end)
    end)
end
local _silCtx = { stealStart = 0, victim = "Unknown", halfTP = false, giantUsed = false }
local function _sil_getVictimFromPrompt(prompt)
    if not prompt then return "Unknown"end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return "Unknown"end
    for _, plot in ipairs(plots:GetChildren()) do
        if prompt:IsDescendantOf(plot) then
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local sf = sign:FindFirstChildWhichIsA("SurfaceGui", true)
                if sf then
                    local lbl = sf:FindFirstChildWhichIsA("TextLabel", true)
                    if lbl and lbl.Text ~= ""
                    then return lbl.Text end
                end
            end
            break
        end
    end
    return "Unknown"end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Toggles = {}
pcall(function() _FH_AG_AnimalsData = require(ReplicatedStorage:WaitForChild("Datas", 30):WaitForChild("Animals", 30)) end)
pcall(function() _FH_AG_NumberUtils = require(ReplicatedStorage:WaitForChild("Utils", 30):WaitForChild("NumberUtils", 30)) end)
pcall(function() _FH_AG_AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared", 30):WaitForChild("Animals", 30)) end)
_FH_AG_SyncRemotes = (function()
    local folder
    pcall(function() folder = ReplicatedStorage:WaitForChild("Packages", 30):WaitForChild("Synchronizer", 30) end)
    if not folder then return { channelFolder = nil, routeRemote = nil, requestData = nil } end
    return {
        channelFolder = folder:WaitForChild("Channel", 30),
        routeRemote = folder:WaitForChild("CommunicationRoute", 30),
        requestData = folder:FindFirstChild("RequestData"),
    }
end)()
_FH_AG_PlotSync = {
    caches = {},
    connections = {},
}
_FH_AG_CachedBrainrots = {}
function _FH_AG_SplitPath(path)
    if typeof(path) == "table" then return path end
    local out = {}
    for part in string.gmatch(tostring(path), "[^%.]+") do
        table.insert(out, tonumber(part) or part)
    end
    return out
end
function _FH_AG_ResolvePath(path, root)
    local current = root
    local parent = nil
    local key = nil
    for _, part in ipairs(_FH_AG_SplitPath(path)) do
        parent = current
        key = part
        current = current and current[part] or nil
    end
    return current, parent, key
end
function _FH_AG_IsMyPlot(plot)
    if not plot or not plot:IsA("Model") then return false end
    local sign = plot:FindFirstChild("PlotSign")
    return sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled
end
function _FH_AG_ApplyPlotDiff(channelName, packet)
    local cache = _FH_AG_PlotSync.caches[channelName]
    if typeof(cache) ~= "table" then return end
    local path, action, a, b = packet[1], packet[2], packet[3], packet[4]
    local current, parent, key = _FH_AG_ResolvePath(path, cache)
    if action == "Changed" then
        if parent ~= nil then parent[key] = a end
    elseif action == "ArrayInsert" then
        if current ~= nil then table.insert(current, b, a) end
    elseif action == "ArrayRemoved" then
        if current ~= nil then table.remove(current, b) end
    elseif action == "DictionaryInsert" then
        if current ~= nil then current[b] = a end
    elseif action == "DictionaryRemoved" then
        if current ~= nil then current[b] = nil end
    end
end
function _FH_AG_AttachPlotChannel(remote)
    if _FH_AG_PlotSync.connections[remote] then return end
    local plots = workspace:FindFirstChild("Plots")
    local channelName = tostring(remote.Name)
    if not (plots and plots:FindFirstChild(channelName)) then return end
    if _FH_AG_SyncRemotes.requestData and _FH_AG_PlotSync.caches[channelName] == nil then
        local ok, data = pcall(function()
            return _FH_AG_SyncRemotes.requestData:InvokeServer(channelName)
        end)
        _FH_AG_PlotSync.caches[channelName] = ok and typeof(data) == "table" and data or {}
    elseif _FH_AG_PlotSync.caches[channelName] == nil then
        _FH_AG_PlotSync.caches[channelName] = {}
    end
    _FH_AG_PlotSync.connections[remote] = remote.OnClientEvent:Connect(function(queue)
        for _, packet in ipairs(queue) do
            _FH_AG_ApplyPlotDiff(channelName, packet)
        end
    end)
end
function _FH_AG_DetachPlotChannel(channelName)
    for remote, conn in pairs(_FH_AG_PlotSync.connections) do
        if tostring(remote.Name) == tostring(channelName) then
            conn:Disconnect()
            _FH_AG_PlotSync.connections[remote] = nil
            _FH_AG_PlotSync.caches[tostring(channelName)] = nil
            break
        end
    end
end
function _FH_AG_RefreshPlotCache(channelName)
    if not _FH_AG_SyncRemotes.requestData then return end
    local ok, data = pcall(function()
        return _FH_AG_SyncRemotes.requestData:InvokeServer(channelName)
    end)
    if ok and typeof(data) == "table" then
        _FH_AG_PlotSync.caches[channelName] = data
    end
end
function _FH_AG_GetStealPrompt(plot, slot)
    local podiums = plot and plot:FindFirstChild("AnimalPodiums")
    local podium = podiums and podiums:FindFirstChild(tostring(slot))
    local spawn = podium and podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn")
    local att = spawn and spawn:FindFirstChild("PromptAttachment")
    local prompt = att and att:FindFirstChildWhichIsA("ProximityPrompt")
    if not (prompt and prompt.Parent) then return nil end
    return prompt, spawn
end
function _FH_AG_ScanAllPlots()
    local result = {}

    local enemyPlots
    local okPlots = pcall(function() enemyPlots = getEnemyPlots() end)
    if not (okPlots and typeof(enemyPlots) == "table") then
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return result end
        enemyPlots = {}
        for _, plot in ipairs(plots:GetChildren()) do
            if not _FH_AG_IsMyPlot(plot) then
                table.insert(enemyPlots, plot)
            end
        end
    end

    for _, plot in ipairs(enemyPlots) do
        pcall(function()
            local cache = _FH_AG_PlotSync.caches[plot.Name]
            local animalList = cache and cache.AnimalList
            if typeof(animalList) ~= "table" then
                return
            end
            for slot, data in pairs(animalList) do
                if typeof(data) ~= "table" or not data.Index then
                    continue
                end
                local prompt, base, model
                local ok, p, b, m = pcall(function() return getStealPromptForSlot(plot, slot) end)
                if ok and p then
                    prompt, base, model = p, b, m
                else
                    prompt, base = _FH_AG_GetStealPrompt(plot, slot)
                end
                if not prompt or not prompt.Parent then
                    continue
                end
                local animalInfo = _FH_AG_AnimalsData[data.Index]
                local displayName = (animalInfo and animalInfo.DisplayName) or tostring(data.Index)
                local genValue = _FH_AG_AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
                local genText = "$" .. _FH_AG_NumberUtils:ToString(genValue) .. "/s"
                table.insert(result, {
                    displayName = displayName,
                    gen         = genText,
                    num         = genValue,
                    plot        = plot,
                    plotName    = plot.Name,
                    position    = prompt.Parent.WorldPosition,
                    prompt      = prompt,
                    model       = model,
                    base        = base,
                    slot        = tostring(slot),
                    mutation    = data.Mutation,
                    animalData  = data,
                    uid         = plot.Name .. "_" .. tostring(slot),
                    pos         = prompt.Parent.WorldPosition,
                    pod         = tonumber(slot) or 0,
                    genText     = genText,
                    genValue    = genValue,
                })
            end
        end)
    end
    table.sort(result, function(a, b)
        return (a.num or 0) > (b.num or 0)
    end)
    return result
end
function _FH_AG_GetNearestBrainrot()
    local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, brainrot in ipairs(_FH_AG_CachedBrainrots) do
        local d = (brainrot.pos - hrp.Position).Magnitude
        if d < bestDist then
            bestDist = d
            best = brainrot
        end
    end
    return best, bestDist
end

task.spawn(function()
    for _, child in ipairs(_FH_AG_SyncRemotes.channelFolder:GetChildren()) do
        if child:IsA("RemoteEvent") then
            _FH_AG_AttachPlotChannel(child)
        end
    end
end)
_FH_AG_SyncRemotes.channelFolder.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") then
        _FH_AG_AttachPlotChannel(child)
    end
end)
_FH_AG_SyncRemotes.routeRemote.OnClientEvent:Connect(function(actions)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, action in ipairs(actions) do
        local kind, channelName = action[1], tostring(action[2])
        if not plots:FindFirstChild(channelName) then continue end
        if kind == "ListenerAdded" then
            local remote = _FH_AG_SyncRemotes.channelFolder:FindFirstChild(channelName)
            if remote and remote:IsA("RemoteEvent") then
                _FH_AG_AttachPlotChannel(remote)
            end
        elseif kind == "ListenerRemoved" then
            _FH_AG_DetachPlotChannel(channelName)
        end
    end
end)
task.spawn(function()
    while task.wait(1.2) do
        pcall(function()
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return end
            local pending = 0
            local done = 0
            for _, plot in ipairs(plots:GetChildren()) do
                if not _FH_AG_IsMyPlot(plot) then
                    pending = pending + 1
                    local name = plot.Name
                    task.spawn(function()
                        pcall(_FH_AG_RefreshPlotCache, name)
                        done = done + 1
                    end)
                end
            end
            local waitStart = tick()
            while done < pending and tick() - waitStart < 1.0 do
                task.wait(0.05)
            end
            _FH_AG_CachedBrainrots = _FH_AG_ScanAllPlots()
        end)
    end
end)

do
    local STRETCH_NAME = "FH_GameStretcher"
    local STRETCH_MAT  = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.8, 0, 0, 0, 1)
    local enabled = false

    local function enableStretcher()
        if enabled then return end
        enabled = true
        pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end)
        pcall(function()
            RunService:BindToRenderStep(STRETCH_NAME, Enum.RenderPriority.Last.Value - 1, function()
                local cam = workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * STRETCH_MAT
                end
            end)
        end)
    end

    local function disableStretcher()
        if not enabled then return end
        enabled = false
        pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end)
    end

    ToggleHandlers.game_stretcher = function(state)
        if state then enableStretcher() else disableStretcher() end
    end
end
do
    local wallHighlights = {}
    local wallRotAngle   = 0
    local wallHeartbeat  = nil
    local function baseESP_findMyPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local sf = sign:FindFirstChildWhichIsA("SurfaceGui", true)
                if sf then
                    local lbl = sf:FindFirstChildWhichIsA("TextLabel", true)
                    if lbl then
                        local txt = lbl.Text:lower()
                        if txt:find(Player.DisplayName:lower(), 1, true)
                        or txt:find(Player.Name:lower(), 1, true) then
                            return plot
                        end
                    end
                end
            end
        end
        return nil
    end
    local function baseESP_isWall(part)
        if not part:IsA("BasePart") then return false end
        if not part.Anchored then return false end
        local x, y, z = part.Size.X, part.Size.Y, part.Size.Z
        local minDim = math.min(x, y, z)
        local maxDim = math.max(x, y, z)
        local midDim = x + y + z - minDim - maxDim
        return minDim <= 1.2 and maxDim >= 8 and midDim >= 4
    end
    local function baseESP_clear()
        for _, hl in pairs(wallHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        wallHighlights = {}
    end
    local function baseESP_apply()
        baseESP_clear()
        local myPlot = baseESP_findMyPlot()
        if not myPlot then return end
        for _, part in ipairs(myPlot:GetDescendants()) do
            if baseESP_isWall(part) then
                local sel = Instance.new("SelectionBox")
                sel.Adornee           = part
                sel.LineThickness     = 0.08
                sel.SurfaceTransparency = 0.7
                sel.Color3            = Color3.fromRGB(255, 255, 255)
                sel.SurfaceColor3     = Color3.fromRGB(0, 0, 0)
                sel.Visible           = true
                sel.AlwaysOnTop       = true
                sel.Parent            = part
                table.insert(wallHighlights, sel)
            end
        end
    end
    do
        local ltbEnabled = false
        local ltbBeam, ltbAtt0, ltbAtt1, ltbAnchor, ltbCharConn, ltbPlotRefresh
        local ltbCachedPlot, ltbCachedPos = nil, nil
        local function _ltbFindMyPlotPos()
            if ltbCachedPlot and ltbCachedPlot.Parent then return ltbCachedPos end
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return nil end
            for _, plot in ipairs(plots:GetChildren()) do
                if _FH_AG_IsMyPlot and _FH_AG_IsMyPlot(plot) then
                    local ok, pos = pcall(function() return plot:GetPivot().Position end)
                    if ok and pos then
                        ltbCachedPlot, ltbCachedPos = plot, pos
                        return pos
                    end
                end
            end
            return nil
        end
        local function _ltbCleanup()
            if ltbCharConn then ltbCharConn:Disconnect(); ltbCharConn = nil end
            if ltbPlotRefresh then ltbPlotRefresh:Disconnect(); ltbPlotRefresh = nil end
            if ltbBeam then ltbBeam:Destroy(); ltbBeam = nil end
            if ltbAtt0 then ltbAtt0:Destroy(); ltbAtt0 = nil end
            if ltbAtt1 then ltbAtt1:Destroy(); ltbAtt1 = nil end
            if ltbAnchor then ltbAnchor:Destroy(); ltbAnchor = nil end
            ltbCachedPlot, ltbCachedPos = nil, nil
        end
        local function _ltbSetup()
            _ltbCleanup()
            local char = Players.LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local pos = _ltbFindMyPlotPos()
            if not pos then return end
            ltbAnchor = Instance.new("Part")
            ltbAnchor.Name         = "FH_LineToBaseAnchor"
            ltbAnchor.Anchored     = true
            ltbAnchor.CanCollide   = false
            ltbAnchor.Transparency = 1
            ltbAnchor.Size         = Vector3.new(0.1, 0.1, 0.1)
            ltbAnchor.CFrame       = CFrame.new(pos)
            ltbAnchor.Parent       = workspace
            ltbAtt0 = Instance.new("Attachment")
            ltbAtt0.Parent = hrp
            ltbAtt1 = Instance.new("Attachment")
            ltbAtt1.Parent = ltbAnchor
            ltbBeam = Instance.new("Beam")
            ltbBeam.Name           = "FH_LineToBaseBeam"
            ltbBeam.Attachment0    = ltbAtt0
            ltbBeam.Attachment1    = ltbAtt1
            ltbBeam.Width0         = 0.4
            ltbBeam.Width1         = 0.4
            ltbBeam.FaceCamera     = true
            ltbBeam.LightEmission  = 1
            ltbBeam.LightInfluence = 0
            ltbBeam.Transparency   = NumberSequence.new(0)
            ltbBeam.Enabled        = true
            ltbBeam.Color          = ColorSequence.new(Color3.fromRGB(255, 0, 0))
            ltbBeam.Parent = hrp
            ltbCharConn = Players.LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.4)
                if ltbEnabled then _ltbSetup() end
            end)
        end
        ToggleHandlers.line_to_base = function(state)
            ltbEnabled = state and true or false
            if ltbEnabled then _ltbSetup() else _ltbCleanup() end
        end
    end
    ToggleHandlers.base_esp = function(state)
        if state then
            baseESP_apply()
            if wallHeartbeat then wallHeartbeat:Disconnect() end
            local _wallAcc = 0
            local _lastIntensity = -1
            wallHeartbeat = RunService.Heartbeat:Connect(function(dt)
                if #wallHighlights == 0 then return end
                wallRotAngle = (wallRotAngle + dt * 0.8) % 1
                _wallAcc = _wallAcc + dt
                if _wallAcc < 1/15 then return end
                _wallAcc = 0
                local brightness = (math.sin(wallRotAngle * math.pi * 2) + 1) / 2
                local intensity  = math.floor(30 + brightness * 225)
                if intensity == _lastIntensity then return end
                _lastIntensity = intensity
                local primary    = Color3.fromRGB(intensity, intensity, intensity)
                local secondary  = Color3.fromRGB(255 - intensity, 255 - intensity, 255 - intensity)
                for _, sel in ipairs(wallHighlights) do
                    if sel and sel.Parent then
                        sel.Color3        = primary
                        sel.SurfaceColor3 = secondary
                    end
                end
            end)
            task.spawn(function()
                while state and _G.FadedHubAlive do
                    task.wait(3)
                    local stale = false
                    for _, hl in ipairs(wallHighlights) do
                        if not hl or not hl.Parent then stale = true; break end
                    end
                    if stale or #wallHighlights == 0 then baseESP_apply() end
                end
            end)
        else
            if wallHeartbeat then wallHeartbeat:Disconnect(); wallHeartbeat = nil end
            baseESP_clear()
        end
    end
end
do
    local espHighlights = {}
    local espConns      = {}
    local function removeESP(player)
        local d = espHighlights[player]
        if d then
            if d.highlight and d.highlight.Parent then d.highlight:Destroy() end
            if d.billboard and d.billboard.Parent then d.billboard:Destroy() end
            espHighlights[player] = nil
        end
    end
    local function applyESP(player)
        if player == Player then return end
        local char = player.Character
        if not char then return end
        removeESP(player)
        local hl = Instance.new("Highlight")
        hl.FillColor           = _G._FH_AccentA or Color3.fromRGB(255, 255, 255)
        hl.FillTransparency    = 0.3
        hl.OutlineColor        = _G._FH_AccentB or Color3.fromRGB(0, 0, 0)
        hl.OutlineTransparency = 0
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee             = char
        hl.Parent              = char
        local head = char:FindFirstChild("Head")
        local bb
        if head then
            bb = Instance.new("BillboardGui")
            bb.Name              = "FHPlayerESP"
            bb.Adornee           = head
            bb.Size              = UDim2.new(0, 240, 0, 50)
            bb.StudsOffset       = Vector3.new(0, 3.2, 0)
            bb.AlwaysOnTop       = true
            bb.ResetOnSpawn      = false
            bb.LightInfluence    = 0
            bb.MaxDistance        = 0
            bb.Parent            = head
            local lbl = Instance.new("TextLabel")
            lbl.Size                    = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency  = 1
            lbl.Text                    = string.format("%s (@%s)", player.DisplayName, player.Name)
            lbl.Font                    = Enum.Font.GothamBold
            lbl.TextSize                = 18
            lbl.TextColor3              = Color3.fromRGB(255, 255, 255)
            lbl.TextStrokeTransparency  = 0
            lbl.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
            lbl.TextXAlignment          = Enum.TextXAlignment.Center
            lbl.TextWrapped             = true
            lbl.ZIndex                  = 2
            lbl.Parent                  = bb
            if _G._FH_ApplyThemeGradientToText then _G._FH_ApplyThemeGradientToText(lbl) end
        end
        espHighlights[player] = { highlight = hl, billboard = bb }
    end
    local function enableESP()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                applyESP(plr)
                local c = plr.CharacterAdded:Connect(function()
                    task.wait(0.1); applyESP(plr)
                end)
                table.insert(espConns, c)
            end
        end
        table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
            if plr == Player then return end
            local c = plr.CharacterAdded:Connect(function()
                task.wait(0.1); applyESP(plr)
            end)
            table.insert(espConns, c)
            task.wait(0.5); applyESP(plr)
        end))
        table.insert(espConns, Players.PlayerRemoving:Connect(function(plr)
            removeESP(plr)
        end))
    end
    local function disableESP()
        for _, conn in ipairs(espConns) do pcall(function() conn:Disconnect() end) end
        espConns = {}
        for plr in pairs(espHighlights) do removeESP(plr) end
        espHighlights = {}
    end
    ToggleHandlers.player_esp = function(state)
        if state then enableESP() else disableESP() end
    end

    _G._FH_RecolorPlayerESP = function()
        local a = _G._FH_AccentA or Color3.fromRGB(255, 255, 255)
        local b = _G._FH_AccentB or Color3.fromRGB(0, 0, 0)
        for _, d in pairs(espHighlights) do
            if d.highlight and d.highlight.Parent then
                d.highlight.FillColor    = a
                d.highlight.OutlineColor = b
            end
        end
    end
end
do
    local SUBSPACE_FOLDER = "ToolsAdds"
    local subspaceData    = {}
    local subspaceEnabled = false
    local subspaceConns   = {}

    local function _smOwnerLabel(mineName)
        local userName = mineName:match("SubspaceTripmine(.+)")
        if not userName then return "Unknown" end
        local foundPlayer = Players:FindFirstChild(userName)
        local displayName = foundPlayer and foundPlayer.DisplayName or userName
        return string.format("%s (@%s)", displayName, userName)
    end

    local function _smCurrentColor()
        return _G._FH_SubspaceColor or Color3.fromRGB(255, 255, 255)
    end

    local function _smCreateESP(mine)
        local ownerLabel = _smOwnerLabel(mine.Name)
        local col = _smCurrentColor()

        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Name           = "ESP_Hitbox"
        selectionBox.Adornee        = mine
        selectionBox.Color3         = col
        selectionBox.LineThickness  = 0.06
        selectionBox.SurfaceColor3  = Color3.fromRGB(0, 0, 0)
        selectionBox.SurfaceTransparency = 1
        selectionBox.Parent         = mine

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name        = "ESP_Label"
        billboardGui.Adornee     = mine
        billboardGui.Size        = UDim2.new(0, 250, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent      = mine

        local textLabel = Instance.new("TextLabel")
        textLabel.Size                   = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text                   = ownerLabel .. "'s Subspace Mine"
        textLabel.TextColor3             = col
        textLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font                   = Enum.Font.GothamBold
        textLabel.TextSize               = 16
        textLabel.Parent                 = billboardGui

        return { selectionBox = selectionBox, billboardGui = billboardGui, mine = mine, textLabel = textLabel }
    end

    _G._FH_SubspaceRecolor = function()
        local col = _smCurrentColor()
        for _, data in pairs(subspaceData) do
            if data.selectionBox and data.selectionBox.Parent then
                data.selectionBox.Color3 = col
            end
            if data.textLabel and data.textLabel.Parent then
                data.textLabel.TextColor3 = col
            end
        end
    end

    local function _smClearAll()
        for _, data in pairs(subspaceData) do
            if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
            if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
        end
        table.clear(subspaceData)
    end

    local function _smIsMine(obj)
        return obj:IsA("BasePart") and obj.Name:match("^SubspaceTripmine") ~= nil
    end

    local function _smTryAdd(obj)
        if not subspaceEnabled then return end
        if not _smIsMine(obj) then return end
        if subspaceData[obj] then return end
        subspaceData[obj] = _smCreateESP(obj)
    end

    local function _smRemove(obj)
        local data = subspaceData[obj]
        if not data then return end
        if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
        if data.billboardGui and data.billboardGui.Parent then data.billboardGui:Destroy() end
        subspaceData[obj] = nil
    end

    local function _smDisconnect()
        for _, c in ipairs(subspaceConns) do pcall(function() c:Disconnect() end) end
        subspaceConns = {}
    end

    local function _smBindFolder(folder)
        table.insert(subspaceConns, folder.ChildAdded:Connect(function(obj)
            if subspaceEnabled then _smTryAdd(obj) end
        end))
        table.insert(subspaceConns, folder.ChildRemoved:Connect(function(obj)
            _smRemove(obj)
        end))
        for _, obj in ipairs(folder:GetChildren()) do _smTryAdd(obj) end
    end

    local function _smEnable()
        if subspaceEnabled then return end
        subspaceEnabled = true
        local folder = workspace:FindFirstChild(SUBSPACE_FOLDER)
        if folder then _smBindFolder(folder) end

        table.insert(subspaceConns, workspace.ChildAdded:Connect(function(child)
            if subspaceEnabled and child.Name == SUBSPACE_FOLDER then
                _smBindFolder(child)
            end
        end))
    end

    local function _smDisable()
        if not subspaceEnabled then return end
        subspaceEnabled = false
        _smDisconnect()
        _smClearAll()
    end

    ToggleHandlers.subspace_mine_esp = function(state)
        if state then _smEnable() else _smDisable() end
    end
end
do
    local function ubIsOwnPlot(obj)
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end
        for _, plot in ipairs(plots:GetChildren()) do
            local owned = (plot.Name == Player.Name)
            if not owned then
                local ov = plot:FindFirstChild("Owner")
                if ov and ov.Value == Player.Name then owned = true end
            end
            if owned and obj:IsDescendantOf(plot) then return true end
        end
        return false
    end
    local function ubNearOther(part, yLevel, thresh)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                local char = plr.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if math.abs(hrp.Position.Y - yLevel) <= thresh
                    and (hrp.Position - part.Position).Magnitude <= 60 then
                        return true
                    end
                end
            end
        end
        return false
    end
    local function ubIsLockPrompt(obj)
        local a = obj.ActionText:lower()
        local o = obj.ObjectText:lower()
        return a:find("lock") or o:find("lock")
    end
    UB.triggerFloor = function(yLevel, maxY)
        local char = Player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local THRESH = 5
        local pY = yLevel or hrp.Position.Y
        local bestSame, distSame   = nil, math.huge
        local bestFall, distFall   = nil, math.huge
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return end
        for _, obj in ipairs(plots:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled
            and not ubIsOwnPlot(obj)
            and ubIsLockPrompt(obj) then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    if not maxY or part.Position.Y <= maxY then
                        local dist  = (hrp.Position - part.Position).Magnitude
                        local yDiff = math.abs(pY - part.Position.Y)
                        if yDiff <= THRESH then
                            if ubNearOther(part, pY, THRESH) then
                                if dist < distSame then distSame = dist; bestSame = obj end
                            elseif bestSame == nil and dist < distFall then
                                distFall = dist; bestFall = obj
                            end
                        end
                    end
                end
            end
        end
        local target = bestSame or bestFall
        if not target then return end
        local orig = target.MaxActivationDistance
        target.MaxActivationDistance = 9999
        if fireproximityprompt then
            fireproximityprompt(target)
        else
            target:InputBegan(Enum.UserInputType.MouseButton1)
            task.wait(0.05)
            target:InputEnded(Enum.UserInputType.MouseButton1)
        end
        task.delay(0.2, function() target.MaxActivationDistance = orig end)
    end
    UB.floors = {
        [1] = { yLevel = -2, maxY = 19 },
        [2] = { yLevel = 15 },
        [3] = { yLevel = 32 },
    }
end
do
    local espBrainrotEnabled    = false
    local espBrainrotConnections = {}
    local Animals = nil
    local rarePets = {}
    local function initializeESP()
        local success, result = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
        end)
        if success then
            Animals = result
            rarePets = {}

            local HIGH_TIER_RARITIES = {
                ["Brainrot God"] = true,
                ["Secret"]       = true,
            }
            local HIGH_TIER_NAMES = {
                ["Garama"]                       = true,
                ["Dragon Cannelloni"]            = true,
                ["Drags"]                        = true,
                ["La Vacca Saturno Saturnita"]   = true,
                ["La Vacca"]                     = true,
                ["Tralalero Tralala"]            = true,
                ["Tralalero"]                    = true,
                ["Tung Tung Tung Sahur Secret"]  = true,
                ["Tung Tung Sahur Secret"]       = true,
            }
            for petName, petData in pairs(Animals) do
                if petData and (HIGH_TIER_RARITIES[petData.Rarity] or HIGH_TIER_NAMES[petName]) then
                    table.insert(rarePets, petName)
                end
            end
        end
    end
    local function findPlayerBase()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in pairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local yourBase = sign:FindFirstChild("YourBase")
                if yourBase and yourBase.Enabled then return plot end
            end
        end
    end
    local function formatMutationText(mutationName)
        if not mutationName or mutationName == "None"then return ""
        end
        local f = ""
        if mutationName == "Cursed"then
            f = "<font color='rgb(200,0,0)'>Cur</font><font color='rgb(0,0,0)'>sed</font>"elseif mutationName == "Gold"then
            f = "<font color='rgb(255,215,0)'>Gold</font>"elseif mutationName == "Diamond"then
            f = "<font color='rgb(0,255,255)'>Diamond</font>"elseif mutationName == "YinYang"then
            f = "<font color='rgb(255,255,255)'>Yin</font><font color='rgb(0,0,0)'>Yang</font>"elseif mutationName == "Candy"then
            f = "<font color='rgb(255,105,180)'>Candy</font>"elseif mutationName == "Divine"then
            f = "<font color='rgb(255,255,255)'>Divine</font>"elseif mutationName == "Rainbow"then
            local cols = {
                "rgb(255,0,0)","rgb(255,127,0)","rgb(255,255,0)",
                "rgb(0,255,0)","rgb(0,0,255)","rgb(75,0,130)","rgb(148,0,211)"}
            for i = 1, #mutationName do
                f = f .. "<font color='"..cols[(i-1)%#cols+1].."'>"..mutationName:sub(i,i).."</font>"end
        else
            f = mutationName
        end
        return f
    end
    local function _lookupGenForModel(model)
        if not model then return nil end
        local function scanGen(root)
            if not root then return nil end
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("BillboardGui") or d:IsA("SurfaceGui")) and d.Name ~= "PetNameTag" then
                    for _, lbl in ipairs(d:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Name == "Generation" then
                            local txt = lbl.Text
                            if txt and txt ~= "" then return txt end
                        end
                    end
                end
            end
            return nil
        end
        local txt = scanGen(model)
        if txt then return txt end
        local cur = model.Parent
        local hops = 0
        while cur and cur ~= workspace and hops < 3 do
            txt = scanGen(cur)
            if txt then return txt end
            cur = cur.Parent
            hops = hops + 1
        end
        local index = model:GetAttribute("Index") or model:GetAttribute("AnimalIndex")
        if index and _FH_AG_AnimalsShared and _FH_AG_NumberUtils then
            local mut    = model:GetAttribute("Mutation")
            local traits = model:GetAttribute("Traits")
            local ok, gen = pcall(function() return _FH_AG_AnimalsShared:GetGeneration(index, mut, traits, nil) end)
            if not (ok and gen) then
                ok, gen = pcall(function() return _FH_AG_AnimalsShared:GetGeneration(index, mut, nil, nil) end)
            end
            if not (ok and gen) then
                ok, gen = pcall(function() return _FH_AG_AnimalsShared:GetGeneration(index) end)
            end
            if ok and gen then
                local okFmt, txt = pcall(function() return "$" .. _FH_AG_NumberUtils:ToString(gen) .. "/s" end)
                if okFmt and txt then return txt end
                return "$" .. tostring(gen) .. "/s"
            end
        end
        if _FH_AG_CachedBrainrots then
            for _, br in ipairs(_FH_AG_CachedBrainrots) do
                if br.model == model then return br.genText or br.gen end
            end
            for _, br in ipairs(_FH_AG_CachedBrainrots) do
                if br.model and (model:IsDescendantOf(br.model) or br.model:IsDescendantOf(model)) then
                    return br.genText or br.gen
                end
            end
        end
        return nil
    end
    local function createNameTag(model, petName, genTextOverride)
        for _, v in ipairs(model:GetChildren()) do
            if v.Name == "PetNameTag"then v:Destroy() end
        end
        local genText = genTextOverride or _lookupGenForModel(model)
        local bb = Instance.new("BillboardGui")
        bb.Name = "PetNameTag"
bb.Size = UDim2.new(0, 190, 0, genText and 56 or 40)
        bb.StudsOffset = Vector3.new(0, 1.1, 0)
        bb.AlwaysOnTop = true
        bb.Parent = model
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = bb
        local mutation = model:GetAttribute("Mutation") or "None"local formattedMutation = formatMutationText(mutation)
        local rowH = genText and (1/3) or 0.5
        local mutLabel = Instance.new("TextLabel")
        mutLabel.Size = UDim2.new(1, 0, rowH, 0)
        mutLabel.BackgroundTransparency = 1
        mutLabel.RichText = true
        mutLabel.Text = formattedMutation
        mutLabel.Font = Enum.Font.GothamBlack
        mutLabel.TextSize = 13
        mutLabel.TextStrokeTransparency = 0
        mutLabel.TextStrokeColor3 = Color3.new(0,0,0)
        mutLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        mutLabel.Parent = frame
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, rowH, 0)
        nameLabel.Position = UDim2.new(0, 0, rowH, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = petName
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
        nameLabel.TextYAlignment = genText and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
        nameLabel.Parent = frame
        if _G._FH_ApplyThemeGradientToText then _G._FH_ApplyThemeGradientToText(nameLabel) end
        if genText then
            local genLabel = Instance.new("TextLabel")
            genLabel.Name = "GenLabel"
            genLabel.Size = UDim2.new(1, 0, rowH, 0)
            genLabel.Position = UDim2.new(0, 0, rowH * 2, 0)
            genLabel.BackgroundTransparency = 1
            genLabel.Text = genText
            genLabel.Font = Enum.Font.GothamBlack
            genLabel.TextSize = 12
            genLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
            genLabel.TextStrokeTransparency = 0
            genLabel.TextStrokeColor3 = Color3.new(0,0,0)
            genLabel.TextYAlignment = Enum.TextYAlignment.Top
            genLabel.Parent = frame
        end
    end
    local function checkForRarePetCached(model, baseModel, genTextOverride)
        if not Animals then return end
        if baseModel then
            local cur = model
            while cur and cur ~= workspace do
                if cur == baseModel then return end
                cur = cur.Parent
            end
        end
        local existing = model:FindFirstChild("PetNameTag")
        if existing then
            local frame = existing:FindFirstChildOfClass("Frame")
            local hasGen = frame and frame:FindFirstChild("GenLabel") ~= nil
            if hasGen or not (genTextOverride or _lookupGenForModel(model)) then return end
        end
        local name = model.Name
        for _, petName in ipairs(rarePets) do
            if name == petName or string.find(name, petName) then
                createNameTag(model, petName, genTextOverride)
                return
            end
        end
    end
    local function checkForRarePet(model)
        checkForRarePetCached(model, findPlayerBase())
    end
    local function scanPlots()
        if not Animals then return end
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return end
        local baseModel = findPlayerBase()
        local syncCaches = _FH_AG_PlotSync and _FH_AG_PlotSync.caches
        if not syncCaches then return end

        for _, plot in ipairs(plots:GetChildren()) do
            if _FH_AG_IsMyPlot(plot) then continue end
            pcall(function()
                local cache = syncCaches[plot.Name]
                local animalList = cache and cache.AnimalList
                if typeof(animalList) ~= "table" then return end
                for slot, data in pairs(animalList) do
                    if typeof(data) ~= "table" or not data.Index then continue end
                    local prompt, base, model
                    local ok, p, b, m = pcall(function() return getStealPromptForSlot(plot, slot) end)
                    if ok and p then
                        prompt, base, model = p, b, m
                    else
                        prompt, base = _FH_AG_GetStealPrompt(plot, slot)
                    end
                    if not prompt or not prompt.Parent or not model or not model.Parent then continue end
                    local animalInfo  = _FH_AG_AnimalsData[data.Index]
                    local displayName = (animalInfo and animalInfo.DisplayName) or tostring(data.Index)
                    local isRare = false
                    for _, petName in ipairs(rarePets) do
                        if displayName == petName or string.find(displayName, petName) then isRare = true; break end
                    end
                    if not isRare then continue end
                    local genText
                    local okGen, genValue = pcall(function()
                        return _FH_AG_AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
                    end)
                    if okGen and genValue then
                        local okFmt, txt = pcall(function() return "$" .. _FH_AG_NumberUtils:ToString(genValue) .. "/s" end)
                        if okFmt and txt then genText = txt end
                    end
                    checkForRarePetCached(model, baseModel, genText)
                end
            end)
        end
    end
    local function _stopBrainrotConns()
        for _, conn in pairs(espBrainrotConnections) do
            pcall(function() conn:Disconnect() end)
        end
        espBrainrotConnections = {}
    end
    local function startESP()
        _stopBrainrotConns()
        scanPlots()

        local _plotsFolder = workspace:FindFirstChild("Plots")
        if _plotsFolder then
            espBrainrotConnections.added = _plotsFolder.DescendantAdded:Connect(function(obj)
                if not espBrainrotEnabled then return end
                if not obj:IsA("Model") then return end
                task.wait(0.2)
                checkForRarePet(obj)
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("Model") then checkForRarePet(d) end
                end
            end)
        end

        task.spawn(function()
            while espBrainrotEnabled do
                task.wait(3)
                if espBrainrotEnabled then pcall(scanPlots) end
            end
        end)
    end
    initializeESP()
    local function enableBrainrotESP()
        espBrainrotEnabled = true
        startESP()
    end
    local function disableBrainrotESP()
        espBrainrotEnabled = false
        _stopBrainrotConns()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "PetNameTag"then obj:Destroy() end
        end
    end
    ToggleHandlers.brainrot_esp = function(state)
        if state then enableBrainrotESP() else disableBrainrotESP() end
    end
end

do
    _G._FH_CloneSwitched = false
    task.spawn(function()
        local hadOwn = false
        while task.wait(0.5) do
            local lp = Players.LocalPlayer
            if not lp then continue end
            local needle = lp.Name .. "_Clone"
            local hasOwn = false
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj.Name == needle then
                    hasOwn = true; break
                end
            end
            if hadOwn and not hasOwn then
                _G._FH_CloneSwitched = true
                task.delay(30, function() _G._FH_CloneSwitched = false end)
                if _G._FH_RescanClonesAfterSwitch then
                    pcall(_G._FH_RescanClonesAfterSwitch)
                end
            end
            hadOwn = hasOwn
        end
    end)
end
do
    local cloneEspEnabled = false
    local cloneEspConnections = {}
    local function getPlayerFromClone(clone)
        if not clone:IsA("Model") then return nil end
        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                local charHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if charHumanoid.DisplayName == humanoid.DisplayName then return player end
            end
        end
        return nil
    end
    local function highlightClone(clone)

        if not _G._FH_CloneSwitched then return end
        local existing = clone:FindFirstChild("CloneHighlight")
        if existing then existing:Destroy() end
        local existingLabel = clone.Head and clone.Head:FindFirstChild("CloneLabel")
        if existingLabel then existingLabel:Destroy() end
        local player = getPlayerFromClone(clone)
        local labelText = "CLONE"if player then labelText = player.Name .. "CLONE"end
        local highlight = Instance.new("Highlight")
        highlight.Name = "CloneHighlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Parent = clone
        local head = clone:FindFirstChild("Head")
        if head then
            local humanoid = clone:FindFirstChildOfClass("Humanoid")
            local displayName = humanoid and humanoid.DisplayName or ""
            local clonePlayerName = ""
            if player then
                clonePlayerName = player.Name
                if displayName == ""
                then displayName = player.DisplayName end
            end
            local nameTag = string.format("(%s) @%s CLONE", displayName ~= ""
            and displayName or clonePlayerName, clonePlayerName)
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "CloneLabel"
billboard.Adornee = head
            billboard.Size = UDim2.new(0, 240, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = nameTag
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 15
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Parent = billboard
            if _G._FH_ApplyThemeGradientToText then _G._FH_ApplyThemeGradientToText(textLabel) end
        end
    end
    local function clearAllCloneESP()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:find("_Clone") and obj:IsA("Model") then
                local highlight = obj:FindFirstChild("CloneHighlight")
                local label = obj.Head and obj.Head:FindFirstChild("CloneLabel")
                if highlight then highlight:Destroy() end
                if label then label:Destroy() end
            end
        end
    end
    local function startCloneESP()
        clearAllCloneESP()
        cloneEspConnections.workspaceAdded = workspace.ChildAdded:Connect(function(child)
            if cloneEspEnabled and child.Name:find("_Clone") and child:IsA("Model") then
                task.wait(0.1)
                highlightClone(child)
            end
        end)
        local _cloneTimer = 0
        cloneEspConnections.heartbeat = RunService.Heartbeat:Connect(function(dt)
            if not cloneEspEnabled then return end
            _cloneTimer = _cloneTimer + dt
            if _cloneTimer < 0.5 then return end
            _cloneTimer = 0
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name:find("_Clone") and obj:IsA("Model") and not obj:FindFirstChild("CloneHighlight") then
                    highlightClone(obj)
                end
            end
        end)
    end
    local function stopCloneESP()
        cloneEspEnabled = false
        for _, conn in pairs(cloneEspConnections) do
            if conn then conn:Disconnect() end
        end
        cloneEspConnections = {}
        clearAllCloneESP()
    end
    ToggleHandlers.clone_esp = function(state)
        cloneEspEnabled = state
        if state then startCloneESP() else stopCloneESP() end
    end

    _G._FH_RescanClonesAfterSwitch = function()
        if not cloneEspEnabled then return end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name:find("_Clone")
               and not obj:FindFirstChild("CloneHighlight") then
                pcall(highlightClone, obj)
            end
        end
    end
end
do
    local plotsFolder = workspace:FindFirstChild("Plots")
    local baseEspInstances = {}
    local BaseTimerESP = false
    local _baseTimerTexts = {}
    local _baseAllowTexts = {}
    _G._FH_BaseTimerESP_Active     = function() return BaseTimerESP end
    _G._FH_BaseTimerTexts          = _baseTimerTexts
    _G._FH_BaseAllowTexts          = _baseAllowTexts
    _G._FH_BaseEspInstances        = baseEspInstances
    _G._FH_BaseTimerESP_SetActive  = function(v) BaseTimerESP = v end
    local function _buildCombinedText(plot)
        local timer = _baseTimerTexts[plot]
        local allow = _baseAllowTexts[plot]
        if timer and allow then
            return timer .. "\n" .. allow
        elseif timer then
            return timer
        elseif allow then
            return allow
        end
        return ""
    end
    local function _getOrCreateBillboard(plot, mainPart)
        if baseEspInstances[plot] and baseEspInstances[plot].Parent then
            return baseEspInstances[plot]
        end
        if baseEspInstances[plot] then baseEspInstances[plot]:Destroy() end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "BaseTimerESP"
        billboard.Size = UDim2.new(0, 70, 0, 32)
        billboard.StudsOffset = Vector3.new(0, 6, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = mainPart
        billboard.MaxDistance = 2000
        billboard.Parent = plot
        local bg = Instance.new("Frame")
        bg.Name = "BG"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(5, 10, 30)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = billboard
        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = bg
        end
        local label = Instance.new("TextLabel")
        label.Name = "TimerText"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(100, 200, 255)
        label.TextStrokeTransparency = 0.3
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = bg
        baseEspInstances[plot] = billboard
        return billboard
    end
    local function _refreshPlotBillboard(plot)
        local text = _buildCombinedText(plot)
        if text == "" then
            if baseEspInstances[plot] then
                baseEspInstances[plot]:Destroy()
                baseEspInstances[plot] = nil
            end
            return
        end

        local purchases = plot:FindFirstChild("Purchases")
        local plotBlock = purchases and purchases:FindFirstChild("PlotBlock")
        local mainPart = plotBlock and plotBlock:FindFirstChild("Main")
        if not mainPart then
            if baseEspInstances[plot] then
                baseEspInstances[plot]:Destroy()
                baseEspInstances[plot] = nil
            end
            return
        end
        local billboard = _getOrCreateBillboard(plot, mainPart)
        local bg = billboard:FindFirstChild("BG")
        local label = bg and bg:FindFirstChild("TimerText")
        if label then
            if _baseTimerTexts[plot] and _baseAllowTexts[plot] then
                local allowText = _baseAllowTexts[plot]
                local isAllowed = allowText:find("Allowed") and not allowText:find("Dis")
                local lbl2 = bg:FindFirstChild("AllowLine")
                if not lbl2 then
                    lbl2 = Instance.new("TextLabel")
                    lbl2.Name = "AllowLine"
                    lbl2.Size = UDim2.new(1, -4, 0, 12)
                    lbl2.Position = UDim2.new(0, 2, 1, -13)
                    lbl2.BackgroundTransparency = 1
                    lbl2.TextScaled = true
                    lbl2.Font = Enum.Font.GothamBold
                    lbl2.TextStrokeTransparency = 0.3
                    lbl2.TextStrokeColor3 = Color3.new(0, 0, 0)
                    lbl2.Parent = bg
                end
                lbl2.Text = allowText
                lbl2.TextColor3 = isAllowed and Color3.fromRGB(26, 255, 0) or Color3.fromRGB(252, 3, 3)
                lbl2.Visible = true
                label.Text = _baseTimerTexts[plot]
                label.TextColor3 = Color3.fromRGB(100, 200, 255)
                billboard.Size = UDim2.new(0, 84, 0, 44)
                label.Size = UDim2.new(1, -4, 0, 26)
                label.Position = UDim2.new(0, 2, 0, 2)
            else
                local lbl2 = bg:FindFirstChild("AllowLine")
                if lbl2 then lbl2.Visible = false end
                billboard.Size = UDim2.new(0, 70, 0, 32)
                label.Size = UDim2.new(1, 0, 1, 0)
                label.Position = UDim2.new(0, 0, 0, 0)
                if _baseAllowTexts[plot] then
                    local isAllowed = _baseAllowTexts[plot]:find("Allowed") and not _baseAllowTexts[plot]:find("Dis")
                    label.TextColor3 = isAllowed and Color3.fromRGB(26, 255, 0) or Color3.fromRGB(252, 3, 3)
                else
                    label.TextColor3 = Color3.fromRGB(100, 200, 255)
                end
                label.Text = text
            end
        end
    end
    _G._FH_RefreshPlotBillboard = _refreshPlotBillboard
    local function _getPlotForPart(part)
        local plots = plotsFolder
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            if part:IsDescendantOf(plot) then return plot end
        end
        return nil
    end
    _G._FH_GetPlotForPart = _getPlotForPart
    local function clearBaseESP()
        for _, gui in pairs(baseEspInstances) do
            if gui then gui:Destroy() end
        end
        table.clear(baseEspInstances)
        table.clear(_baseTimerTexts)
    end
    local function updateBaseESP()
        if not BaseTimerESP then clearBaseESP(); return end
        if not plotsFolder then return end
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local purchases = plot:FindFirstChild("Purchases")
            local plotBlock = purchases and purchases:FindFirstChild("PlotBlock")
            local mainPart = plotBlock and plotBlock:FindFirstChild("Main")
            local timeLabel = mainPart
                and mainPart:FindFirstChild("BillboardGui")
                and mainPart.BillboardGui:FindFirstChild("RemainingTime")
            if timeLabel and mainPart then
                _baseTimerTexts[plot] = timeLabel.Text
                _refreshPlotBillboard(plot)
            else
                _baseTimerTexts[plot] = nil
                if baseEspInstances[plot] then

                    if not _baseAllowTexts[plot] then
                        baseEspInstances[plot]:Destroy()
                        baseEspInstances[plot] = nil
                    else
                        _refreshPlotBillboard(plot)
                    end
                end
            end
        end
    end
    local _baseTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        if not BaseTimerESP then return end
        _baseTimer = _baseTimer + dt
        if _baseTimer < 0.5 then return end
        _baseTimer = 0
        updateBaseESP()
    end)

    ToggleHandlers.base_timer_esp = function(state)
        BaseTimerESP = state
        if not state then
            table.clear(_baseTimerTexts)

            if FriendsESPEnabled then
                if plotsFolder then
                    for _, plot in ipairs(plotsFolder:GetChildren()) do
                        _refreshPlotBillboard(plot)
                    end
                end
            else
                clearBaseESP()
            end
        end
    end
end
do
    local function startFriendsESP()
        task.spawn(function()
            task.wait(2)
            local function upd(prompt)
                if not FriendsESPEnabled then return end
                local parent = prompt.Parent
                if not parent or not parent:IsA("BasePart") then return end

                for _, c in ipairs(parent:GetChildren()) do
                    if c.Name == "FriendInd"then
                        c:Destroy()
                    end
                end
                local text = string.lower(prompt.ObjectText or "")
                if not string.find(text, "friends") then

                    local getPlot = _G._FH_GetPlotForPart
                    if getPlot then
                        local plot = getPlot(parent)
                        if plot and _G._FH_BaseAllowTexts then
                            _G._FH_BaseAllowTexts[plot] = nil
                            if _G._FH_BaseTimerESP_Active and _G._FH_BaseTimerESP_Active() then
                                if _G._FH_RefreshPlotBillboard then _G._FH_RefreshPlotBillboard(plot) end
                            elseif _G._FH_BaseEspInstances then
                                local inst = _G._FH_BaseEspInstances[plot]
                                if inst then inst:Destroy(); _G._FH_BaseEspInstances[plot] = nil end
                            end
                        end
                    end
                    return
                end
                local isAllowed = text:find("disallow") ~= nil
                local allowLabel = isAllowed and "Allowed" or "Disallowed"
                local allowColor = isAllowed and Color3.fromRGB(26, 255, 0) or Color3.fromRGB(252, 3, 3)

                if _G._FH_BaseTimerESP_Active and _G._FH_BaseTimerESP_Active() then
                    local getPlot = _G._FH_GetPlotForPart
                    if getPlot then
                        local plot = getPlot(parent)
                        if plot then
                            _G._FH_BaseAllowTexts[plot] = allowLabel
                            _G._FH_RefreshPlotBillboard(plot)
                            return
                        end
                    end
                end

                local getPlot = _G._FH_GetPlotForPart
                if getPlot then
                    local plot = getPlot(parent)
                    if plot then
                        _G._FH_BaseAllowTexts[plot] = allowLabel

                        if _G._FH_RefreshPlotBillboard then
                            _G._FH_RefreshPlotBillboard(plot)
                            return
                        end
                    end
                end

                local bb = Instance.new("BillboardGui")
                bb.Name = "FriendInd"
                bb.Size = UDim2.new(0, 160, 0, 40)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 4, 0)
                bb.Parent = parent
                local lbl2 = Instance.new("TextLabel")
                lbl2.Size = UDim2.new(1, 0, 1, 0)
                lbl2.BackgroundTransparency = 1
                lbl2.Font = Enum.Font.GothamBlack
                lbl2.TextSize = 16
                lbl2.TextStrokeTransparency = 0.4
                lbl2.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl2.Text = allowLabel
                lbl2.TextColor3 = allowColor
                lbl2.Parent = bb
            end

            local _plotsRoot = workspace:FindFirstChild("Plots")
            local _scanRoot  = _plotsRoot or workspace
            local _step = 0
            for _, o in ipairs(_scanRoot:GetDescendants()) do
                if o:IsA("ProximityPrompt") then
                    upd(o)
                    local conn = o:GetPropertyChangedSignal("ObjectText"):Connect(function()
                        upd(o)
                    end)
                    table.insert(FriendsESPConnections, conn)
                end
                _step = _step + 1
                if _step % 500 == 0 then task.wait() end
            end
            local conn = _scanRoot.DescendantAdded:Connect(function(o)
                if not FriendsESPEnabled then return end
                if o:IsA("ProximityPrompt") then
                    task.wait(0.1)
                    upd(o)
                    local c = o:GetPropertyChangedSignal("ObjectText"):Connect(function()
                        upd(o)
                    end)
                    table.insert(FriendsESPConnections, c)
                end
            end)
            table.insert(FriendsESPConnections, conn)
        end)
    end
    local function stopFriendsESP()
        for _, conn in ipairs(FriendsESPConnections) do
            if conn then conn:Disconnect() end
        end
        table.clear(FriendsESPConnections)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "FriendInd"then
                v:Destroy()
            end
        end

        if _G._FH_BaseAllowTexts then
            for k in pairs(_G._FH_BaseAllowTexts) do
                _G._FH_BaseAllowTexts[k] = nil
            end
        end

        local plots = workspace:FindFirstChild("Plots")
        if plots and _G._FH_RefreshPlotBillboard then
            for _, plot in ipairs(plots:GetChildren()) do
                _G._FH_RefreshPlotBillboard(plot)
            end
        end
    end
    ToggleHandlers.allowed_esp = function(state)
        FriendsESPEnabled = state
        if state then startFriendsESP() else stopFriendsESP() end
    end
end
do
    local carpetSpeedEnabled = false
    local carpetSpeedConnection = nil
    local carpetStatusLabel = nil
    local _carpetToolWatchConn = nil
    local _carpetBoosterWasOn = false
    _G._FH_CarpetClearBoosterMem = function() _carpetBoosterWasOn = false end
    local function setCarpetSpeed(enabled)
        if carpetSpeedConnection then
            carpetSpeedConnection:Disconnect()
            carpetSpeedConnection = nil
        end
        if _carpetToolWatchConn then
            _carpetToolWatchConn:Disconnect()
            _carpetToolWatchConn = nil
        end
        if not enabled then
            local _c = Players.LocalPlayer.Character
            local _hrp = _c and _c:FindFirstChild("HumanoidRootPart")
            if _hrp then
                _hrp.Velocity = Vector3.new(0, _hrp.Velocity.Y, 0)
            end
            local _bp = Players.LocalPlayer:FindFirstChild("Backpack")
            local _carpet = _c and _c:FindFirstChild("Flying Carpet")
            if _carpet and _bp then
                _carpet.Parent = _bp
            end
            if _carpetBoosterWasOn then
                _carpetBoosterWasOn = false
                if SP and not SP.state then
                    SP.spBoosterDoToggle()
                end
            end
            return
        end
        if SP and SP.state then
            SP.spBoosterDoToggle()
            _carpetBoosterWasOn = true
        else
            _carpetBoosterWasOn = false
        end
        _carpetToolWatchConn = Players.LocalPlayer.CharacterAdded:Connect(function() end)
        if _carpetToolWatchConn then _carpetToolWatchConn:Disconnect() end
        local char = Players.LocalPlayer.Character
        if char then
            _carpetToolWatchConn = char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and child.Name ~= "Flying Carpet"then
                    carpetSpeedEnabled = false
                    setCarpetSpeed(false)
                    Toggles["carpet_speed"] = false
                    local reg = configRegistry["Carpet Speed"]
                    if reg and reg.getState and reg.getState() then
                        if reg.setEnabled then reg.setEnabled(false) end
                    end
                    ShowToggleNotification("Carpet Speed: OFF (tool changed)", false)
                end
            end)
        end
        carpetSpeedConnection = RunService.Heartbeat:Connect(function()
            local c = Players.LocalPlayer.Character
            if not c then return end
            local hum = c:FindFirstChild("Humanoid")
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local toolName = "Flying Carpet"local hasTool = c:FindFirstChild(toolName)
            if not hasTool then
                local tb = Players.LocalPlayer.Backpack:FindFirstChild(toolName)
                if tb then hum:EquipTool(tb) end
            end
            if hasTool then
                local md = hum.MoveDirection
                if md.Magnitude > 0 then
                    local flatDir = Vector3.new(md.X, 0, md.Z).Unit
                    hrp.Velocity = Vector3.new(flatDir.X * 140, hrp.Velocity.Y, flatDir.Z * 140)
                end
            end
        end)
    end
do
    local LocalPlayer = Players.LocalPlayer
    local function findPlayerBase_TP()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in pairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local yourBase = sign:FindFirstChild("YourBase")
                if yourBase and yourBase.Enabled then
                    return plot
                end
            end
        end
    end
    local function carpetTpNextBase()
        local MyPlot = findPlayerBase_TP()
        if not MyPlot then return end
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local order = MyPlot:GetAttribute("Order")
        local approachWaypoints, finalPos
        if order == 2 then
            approachWaypoints = {
                Vector3.new(-352.54, -6.83,   6.66),
                Vector3.new(-351.49, -6.65, 113.72),
                Vector3.new(-337.62, -3.68,  18.13),
                Vector3.new(-337,    -5,     103),
            }
            finalPos = Vector3.new(-348.617157, -6.603045, 113.494453)
        elseif order == 1 then
            approachWaypoints = {
                Vector3.new(-351.49, -6.65, 113.72),
                Vector3.new(-352.54, -6.83,   6.66),
                Vector3.new(-337.62, -3.68,  18.13),
                Vector3.new(-336.37, -3.68, 18.54),
            }
            finalPos = Vector3.new(-350.54, -5.58, 36.59)
        else
            return
        end
        if SS and SS.SSEquipGrapple then pcall(SS.SSEquipGrapple) end
        if _G._FH_WalkTo then
            for _, wp in ipairs(approachWaypoints) do
                _G._FH_WalkTo(wp, 180)
            end
        end
        task.wait(0.25)
        if giantSpeedEnabled then
            local lp = Players.LocalPlayer
            local c  = lp.Character
            local bp = lp:FindFirstChild("Backpack")
            if c and bp then
                local potion = nil
                local potionNames = {"Giant Potion", "Giant", "Grow Potion", "Super Grow", "Potion"}
                for _, name in ipairs(potionNames) do
                    potion = c:FindFirstChild(name) or bp:FindFirstChild(name)
                    if potion and potion:IsA("Tool") then break end
                end
                if potion then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if potion.Parent ~= c and hum then hum:EquipTool(potion) end
                    task.wait(0.05)
                    pcall(function() potion:Activate() end)
                end
            end
        end
        if SS and SS.SSEquipGrapple then pcall(SS.SSEquipGrapple) end
        if SS and SS.SSTeleportHRP then
            pcall(SS.SSTeleportHRP, finalPos)
        else
            _G._FH_CarpetTP(CFrame.new(finalPos), 70)
        end
    end
    ToggleHandlers.carpet_tp_base = function(state)
        if state then
            task.spawn(carpetTpNextBase)
            task.defer(function()
                local reg = configRegistry["Teleport Next Base"]
                if reg and reg.getState() then
                    reg.doToggle()
                end
            end)
        end
    end
end
ToggleHandlers.carpet_speed = function(state)
        carpetSpeedEnabled = state
        if state then
            setCarpetSpeed(true)
        else
            setCarpetSpeed(false)
        end
    end
end
local speedBoosterConnection, jumpBoosterConnection = nil, nil
local jumpBoosterEnabled, speedBoosterEnabled = false, false
local _cachedSpeed, _cachedJump = 29, 50
local _chHum, _chHrp = nil, nil
local function _refreshCharCache(c)
    c = c or Players.LocalPlayer.Character
    _chHum = c and c:FindFirstChildOfClass("Humanoid") or nil
    _chHrp = c and c:FindFirstChild("HumanoidRootPart") or nil
end
Players.LocalPlayer.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart", 5); _refreshCharCache(c)
end)
_refreshCharCache()
local function _bindBoxCache(box, key)
    if not box then return end
    local apply = function() local v = tonumber(box.Text); if v then if key == "s" then _cachedSpeed = v else _cachedJump = v end end end
    box:GetPropertyChangedSignal("Text"):Connect(apply); apply()
end
task.defer(function() _bindBoxCache(SP and SP.wsBox, "s"); _bindBoxCache(SP and SP.jpBox, "j") end)

local function setJumpBooster(enabled)
    if jumpBoosterConnection then jumpBoosterConnection:Disconnect(); jumpBoosterConnection = nil end
    jumpBoosterEnabled = enabled
    if not enabled then return end
    local debounce = false
    jumpBoosterConnection = UserInputService.JumpRequest:Connect(function()
        if not jumpBoosterEnabled or debounce then return end
        if not (UserInputService:IsKeyDown(Enum.KeyCode.Space)
             or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
             or UserInputService.TouchEnabled) then return end
        local hum, hrp = _chHum, _chHrp
        if not hum or not hrp or hum.FloorMaterial == Enum.Material.Air then return end
        debounce = true
        task.delay(0.05, function()
            if not jumpBoosterEnabled then debounce = false; return end
            local h = _chHrp
            if h then
                local v = h.Velocity
                h.Velocity = Vector3.new(v.X, _cachedJump, v.Z)
            end
            local hu = _chHum
            if not hu then debounce = false; return end
            local landConn
            landConn = hu.StateChanged:Connect(function(_, new)
                if new == Enum.HumanoidStateType.Landed
                or new == Enum.HumanoidStateType.Running
                or new == Enum.HumanoidStateType.RunningNoPhysics then
                    debounce = false; landConn:Disconnect()
                end
            end)
            task.delay(4, function()
                if debounce then debounce = false; pcall(function() landConn:Disconnect() end) end
            end)
        end)
    end)
end

local function setSpeedBooster(enabled)
    if speedBoosterConnection then speedBoosterConnection:Disconnect(); speedBoosterConnection = nil end
    speedBoosterEnabled = enabled
    if not enabled then return end
    speedBoosterConnection = RunService.Heartbeat:Connect(function()
        local lp = Players.LocalPlayer
        if not lp.Character then return end
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end
        if SP and SP.stealOnlyEnabled and not lp:GetAttribute("Stealing") then return end
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
            hrp.Velocity = Vector3.new(
                flatDir.X * _cachedSpeed,
                hrp.Velocity.Y,
                flatDir.Z * _cachedSpeed
            )
        end
    end)
end
local giantSpeedEnabled = false
local giantSpeedConnection = nil
local GIANT_THRESHOLD = 2.5
local _isGiant = false
local function _giantSpeedDisconnect()
    if giantSpeedConnection then
        giantSpeedConnection:Disconnect()
        giantSpeedConnection = nil
    end
    local _c = Players.LocalPlayer.Character
    local _hrp = _c and _c:FindFirstChild("HumanoidRootPart")
    if _hrp then
        _hrp.Velocity = Vector3.new(0, _hrp.Velocity.Y, 0)
    end
end
local function onGiantActivated()
    _isGiant = true
    if giantSpeedConnection then return end
    giantSpeedConnection = RunService.Heartbeat:Connect(function()
        local c = Players.LocalPlayer.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        local md = hum.MoveDirection
        if md.Magnitude > 0 then
            local spd = tonumber(SP and SP.wsBox and SP.wsBox.Text) or 29
            local flatDir = Vector3.new(md.X, 0, md.Z).Unit
            hrp.Velocity = Vector3.new(flatDir.X * spd, hrp.Velocity.Y, flatDir.Z * spd)
        end
    end)
end
local function onGiantDeactivated()
    _isGiant = false
    _giantSpeedDisconnect()
end
local function checkGiantState()
    local c = Players.LocalPlayer.Character
    if not c then return end
    local humanoid = c:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local scaleValue = humanoid:FindFirstChild("BodyHeightScale")
        or humanoid:FindFirstChild("BodyDepthScale")
        or humanoid:FindFirstChild("BodyWidthScale")
    if scaleValue then
        local giant = scaleValue.Value >= GIANT_THRESHOLD
        if giant and not _isGiant then
            onGiantActivated()
        elseif not giant and _isGiant then
            onGiantDeactivated()
        end
    end
end
local _giantTimer = 0
RunService.Heartbeat:Connect(function(dt)
    _giantTimer = _giantTimer + dt
    if _giantTimer < 0.5 then return end
    _giantTimer = 0
    checkGiantState()
end)
Players.LocalPlayer.CharacterAdded:Connect(function()
    _isGiant = false
    _giantSpeedDisconnect()
end)
ToggleHandlers.giant_speed = function(state)
    giantSpeedEnabled = state
    if state then
        if _isGiant then onGiantActivated() end
    else
        _giantSpeedDisconnect()
    end
end
do
    local alarmEnabled = false
    local alarmConnection = nil
    local alarmNotifLbl = nil
    local lp = Players.LocalPlayer
    local function ensureAlarmLabel()
        if alarmNotifLbl and alarmNotifLbl.Parent then return end
        alarmNotifLbl = Instance.new("TextLabel")
        alarmNotifLbl.AnchorPoint        = Vector2.new(0.5, 1)
        alarmNotifLbl.Position           = UDim2.new(0.5, 0, 0.92, 0)
        alarmNotifLbl.Size               = UDim2.new(0, 600, 0, 80)
        alarmNotifLbl.BackgroundTransparency = 1
        alarmNotifLbl.TextColor3         = Color3.fromRGB(255, 70, 70)
        alarmNotifLbl.TextSize           = 26
        alarmNotifLbl.Font               = Enum.Font.GothamBold
        alarmNotifLbl.TextWrapped        = true
        alarmNotifLbl.TextStrokeTransparency = 0.3
        alarmNotifLbl.TextStrokeColor3   = Color3.fromRGB(0, 0, 0)
        alarmNotifLbl.Visible            = false
        alarmNotifLbl.ZIndex             = 50
        alarmNotifLbl.Parent             = GUI
    end
    local function getStealHitbox()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local lbl = sign:FindFirstChildWhichIsA("TextLabel", true)
                if lbl then
                    local t = lbl.Text:lower()
                    if t:find(lp.Name:lower()) or t:find(lp.DisplayName:lower()) then
                        return plot:FindFirstChild("StealHitbox", true)
                    end
                end
            end
        end
        return nil
    end
    local function startAlarm()
        ensureAlarmLabel()
        if alarmConnection then alarmConnection:Disconnect() end
        local _alarmAcc = 0
        alarmConnection = RunService.Heartbeat:Connect(function(dt)
            if not alarmEnabled then
                if alarmNotifLbl then alarmNotifLbl.Visible = false end
                return
            end
            _alarmAcc = _alarmAcc + dt
            if _alarmAcc < 0.25 then return end
            _alarmAcc = 0
            local hitbox = getStealHitbox()
            if not hitbox then
                if alarmNotifLbl then alarmNotifLbl.Visible = false end
                return
            end
            local cf   = hitbox.CFrame
            local size = hitbox.Size
            local hx, hz = size.X * 0.5, size.Z * 0.5
            local intruders = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then
                    local char = p.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local rel = cf:PointToObjectSpace(hrp.Position)
                            if math.abs(rel.X) <= hx and math.abs(rel.Z) <= hz then
                                table.insert(intruders, p.Name)
                            end
                        end
                    end
                end
            end
            if #intruders > 0 then
                alarmNotifLbl.Text = "\240\159\154\168 ".. #intruders .. "Player".. (#intruders > 1 and "s"or "") .. "in your Base! \240\159\154\168\n".. table.concat(intruders, ", ")
                alarmNotifLbl.Visible = true
            else
                alarmNotifLbl.Visible = false
            end
        end)
    end
    local function stopAlarm()
        alarmEnabled = false
        if alarmConnection then
            alarmConnection:Disconnect()
            alarmConnection = nil
        end
        if alarmNotifLbl then alarmNotifLbl.Visible = false end
    end
    ToggleHandlers.base_alarm = function(state)
        alarmEnabled = state
        if state then
            startAlarm()
        else
            stopAlarm()
        end
    end
end
do
    local AutoResetBalloonEnabled = false
    local _arbLastFire = 0
    local _arbConns   = {}
    local _arbAddConn = nil
    local _arbBoundRemotes = {}
    local function _arbStringMatchesBalloon(s)
        if type(s) ~= "string" then return false end

        local ls = s:lower()
        return ls:find("jump higher", 1, true) ~= nil
    end

    local function _arbHandleArgs(...)

        if not AutoResetBalloonEnabled then return end
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            if _arbStringMatchesBalloon(arg) then
                local now = tick()
                if now - _arbLastFire < 3 then return end
                _arbLastFire = now

                if AutoResetBalloonEnabled then
                    doSelectedReset()
                end
                return
            end
        end
    end
    local function _arbBindRemote(obj)
        if not obj:IsA("RemoteEvent") then return end

        if _arbBoundRemotes[obj] then return end
        local ok, conn = pcall(function()
            return obj.OnClientEvent:Connect(_arbHandleArgs)
        end)
        if ok and conn then
            table.insert(_arbConns, conn)
            _arbBoundRemotes[obj] = true
        end
    end
    local function startAutoResetBalloon()

        for _, conn in ipairs(_arbConns) do
            pcall(function() conn:Disconnect() end)
        end
        _arbConns = {}
        _arbBoundRemotes = {}
        if _arbAddConn then
            pcall(function() _arbAddConn:Disconnect() end)
            _arbAddConn = nil
        end

        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            _arbBindRemote(obj)
        end

        _arbAddConn = ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if AutoResetBalloonEnabled then _arbBindRemote(obj) end
        end)
    end
    local function stopAutoResetBalloon()
        AutoResetBalloonEnabled = false
        for _, conn in ipairs(_arbConns) do
            pcall(function() conn:Disconnect() end)
        end
        _arbConns = {}
        _arbBoundRemotes = {}
        if _arbAddConn then
            pcall(function() _arbAddConn:Disconnect() end)
            _arbAddConn = nil
        end
    end
    ToggleHandlers.auto_reset_balloon = function(state)
        AutoResetBalloonEnabled = state
        if state then
            startAutoResetBalloon()
        else
            stopAutoResetBalloon()
        end
    end
    ToggleHandlers.set_auto_reset_mode = function(_mode) end
end
do
    local AutoResetJailEnabled = false
    local _arjLastFire = 0
    local _arjConns   = {}
    local _arjAddConn = nil
    local _arjBoundRemotes = {}
    local function _arjStringMatchesJail(s)
        if type(s) ~= "string" then return false end

        return s:lower():find("trapped for 10 seconds", 1, true) ~= nil
    end

    local function _arjHandleArgs(...)

        if not AutoResetJailEnabled then return end
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            if _arjStringMatchesJail(arg) then
                local now = tick()
                if now - _arjLastFire < 3 then return end
                _arjLastFire = now

                if AutoResetJailEnabled then
                    doSelectedReset()
                end
                return
            end
        end
    end
    local function _arjBindRemote(obj)
        if not obj:IsA("RemoteEvent") then return end

        if _arjBoundRemotes[obj] then return end
        local ok, conn = pcall(function()
            return obj.OnClientEvent:Connect(_arjHandleArgs)
        end)
        if ok and conn then
            table.insert(_arjConns, conn)
            _arjBoundRemotes[obj] = true
        end
    end
    local function startAutoResetJail()
        for _, conn in ipairs(_arjConns) do
            pcall(function() conn:Disconnect() end)
        end
        _arjConns = {}
        _arjBoundRemotes = {}
        if _arjAddConn then
            pcall(function() _arjAddConn:Disconnect() end)
            _arjAddConn = nil
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            _arjBindRemote(obj)
        end
        _arjAddConn = ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if AutoResetJailEnabled then _arjBindRemote(obj) end
        end)
    end
    local function stopAutoResetJail()
        AutoResetJailEnabled = false
        for _, conn in ipairs(_arjConns) do
            pcall(function() conn:Disconnect() end)
        end
        _arjConns = {}
        _arjBoundRemotes = {}
        if _arjAddConn then
            pcall(function() _arjAddConn:Disconnect() end)
            _arjAddConn = nil
        end
    end
    ToggleHandlers.auto_reset_jail = function(state)
        AutoResetJailEnabled = state
        if state then
            startAutoResetJail()
        else
            stopAutoResetJail()
        end
    end
end
do
    local autoTurretEnabled  = false
    local turretConns        = {}
    local turretLoopRunning  = false
    local turretAttackBusy   = setmetatable({}, { __mode = "k" })
    local turretAttackQueued = setmetatable({}, { __mode = "k" })
    local turretAttackCD     = setmetatable({}, { __mode = "k" })
    local turretAttackActive = false
    local RETRY_DELAY        = 0.3
    local lp = Players.LocalPlayer

    local function isEnemyTurret(obj)
        if not obj or not obj:IsA("BasePart") then return false end
        local ownerId = obj.Name:match("^Sentry_(%d+)$")
        return ownerId ~= nil and ownerId ~= tostring(lp.UserId)
    end

    local function setTurretNoClip(turret)
        if not isEnemyTurret(turret) then return end
        pcall(function() turret.CanCollide = false end)
    end

    local function getTurretTimeLabel(turret)
        if not turret or not turret.Parent then return nil end
        local sf  = turret:FindFirstChild("SetupFrame")
        local mf  = sf and sf:FindFirstChild("MainFrame")
        local lbl = mf and mf:FindFirstChild("Time")
        if lbl and lbl:IsA("TextLabel") then return lbl end
        return nil
    end

    local function shouldAttackTurret(turret)
        if lp:GetAttribute("Stealing") ~= nil then return false end
        if not isEnemyTurret(turret) then return false end
        setTurretNoClip(turret)
        local lbl = getTurretTimeLabel(turret)
        if not lbl then return false end
        local ok, text = pcall(function() return lbl.Text end)
        if not ok then return false end
        text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        return text ~= "" and string.find(text, "^%d+s!$") ~= nil
    end

    local function bringTurretInFront(turret, hrp)
        if not turret or not hrp then return end
        local fwd = hrp.CFrame.LookVector
        local pos = hrp.Position + fwd * 4 + Vector3.new(0, 1.2, 0)
        local cf  = CFrame.lookAt(pos, pos + fwd)
        pcall(function()
            turret.Velocity     = Vector3.zero
            turret.RotVelocity  = Vector3.zero
        end)
        pcall(function() turret.CFrame = cf end)
    end

    local function attackTurret(turret)
        local now = os.clock()
        if turretAttackBusy[turret] or turretAttackQueued[turret]
        or turretAttackActive or not shouldAttackTurret(turret) then return end
        if (turretAttackCD[turret] or 0) > now then return end
        turretAttackQueued[turret] = true
        turretAttackCD[turret]     = now + RETRY_DELAY
        task.spawn(function()
            turretAttackQueued[turret] = nil
            if turretAttackActive or turretAttackBusy[turret]
            or not shouldAttackTurret(turret) then return end
            turretAttackActive       = true
            turretAttackBusy[turret] = true
            pcall(function()
                local attempts = 0
                while attempts < 12 and autoTurretEnabled do
                    if not turret or not turret.Parent or not shouldAttackTurret(turret) then break end
                    local char = lp.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if not hrp or not hum or hum.Health <= 0 then break end
                    local okD, dist = pcall(function() return (turret.Position - hrp.Position).Magnitude end)
                    if okD and dist > 220 then break end
                    setTurretNoClip(turret)
                    bringTurretInFront(turret, hrp)
                    if not turret or not turret.Parent or not shouldAttackTurret(turret) then break end
                    local bp  = lp:FindFirstChild("Backpack")
                    local bat = char:FindFirstChild("Bat") or (bp and bp:FindFirstChild("Bat"))
                    if bat and bat.Parent ~= char then
                        pcall(function() hum:EquipTool(bat) end)
                    end
                    bat = char:FindFirstChild("Bat") or bat
                    if bat then pcall(function() bat:Activate() end) end
                    task.wait(0.03)
                    if turret and turret.Parent and shouldAttackTurret(turret) then
                        setTurretNoClip(turret)
                        bringTurretInFront(turret, hrp)
                    end
                    attempts = attempts + 1
                    task.wait(0.09)
                end
            end)
            turretAttackBusy[turret] = nil
            turretAttackActive       = false
        end)
    end

    local function disconnectAll()
        for _, c in ipairs(turretConns) do pcall(function() c:Disconnect() end) end
        turretConns = {}
    end

    local function startAutoTurret()
        disconnectAll()
        table.insert(turretConns, workspace.DescendantAdded:Connect(function(obj)
            if isEnemyTurret(obj) then setTurretNoClip(obj) end
            if autoTurretEnabled and shouldAttackTurret(obj) then
                task.defer(attackTurret, obj)
            end
        end))
        if not turretLoopRunning then
            turretLoopRunning = true
            task.spawn(function()
                while autoTurretEnabled do
                    task.wait(0.4)
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if isEnemyTurret(obj) then setTurretNoClip(obj) end
                        if autoTurretEnabled and shouldAttackTurret(obj) then attackTurret(obj) end
                    end
                end
                turretLoopRunning = false
            end)
        end
    end

    local function stopAutoTurret()
        disconnectAll()
    end

    ToggleHandlers.anti_turret = function(state)
        autoTurretEnabled = state
        if state then startAutoTurret() else stopAutoTurret() end
    end
end
do
    local AntiBeeDiscoData = {
        running = false,
        connections = {},
        originalMoveFunction = nil,
        controlsProtected = false,
        badLightingNames = { Blue = true, DiscoEffect = true, BeeBlur = true, ColorCorrection = true },
    }

    local function abNuke(obj)
        if not obj or not obj.Parent then return end
        if AntiBeeDiscoData.badLightingNames[obj.Name] then
            pcall(function() obj:Destroy() end)
        end
    end

    local function abDisconnectAll()
        for _, conn in ipairs(AntiBeeDiscoData.connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        AntiBeeDiscoData.connections = {}
    end

    local function abProtectControls()
        if AntiBeeDiscoData.controlsProtected then return end
        pcall(function()
            local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
            if not PlayerModule then return end
            local Controls = require(PlayerModule):GetControls()
            if not Controls then return end
            if not AntiBeeDiscoData.originalMoveFunction then
                AntiBeeDiscoData.originalMoveFunction = Controls.moveFunction
            end
            local function protectedMove(self, moveVector, relativeToCamera)
                if AntiBeeDiscoData.originalMoveFunction then
                    AntiBeeDiscoData.originalMoveFunction(self, moveVector, relativeToCamera)
                end
            end
            local _abCtrlAcc = 0
            table.insert(AntiBeeDiscoData.connections, RunService.Heartbeat:Connect(function(dt)
                if not AntiBeeDiscoData.running then return end
                _abCtrlAcc = _abCtrlAcc + dt
                if _abCtrlAcc < 0.25 then return end
                _abCtrlAcc = 0
                if Controls.moveFunction ~= protectedMove then Controls.moveFunction = protectedMove end
            end))
            Controls.moveFunction = protectedMove
            AntiBeeDiscoData.controlsProtected = true
        end)
    end

    local function abRestoreControls()
        if not AntiBeeDiscoData.controlsProtected then return end
        pcall(function()
            local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
            if not PlayerModule then return end
            local Controls = require(PlayerModule):GetControls()
            if Controls and AntiBeeDiscoData.originalMoveFunction then
                Controls.moveFunction = AntiBeeDiscoData.originalMoveFunction
                AntiBeeDiscoData.controlsProtected = false
            end
        end)
    end

    local function abBlockBuzzing()
        pcall(function()
            local beeScript = LocalPlayer.PlayerScripts:FindFirstChild("Bee", true)
            if beeScript then
                local buzzing = beeScript:FindFirstChild("Buzzing")
                if buzzing and buzzing:IsA("Sound") then
                    buzzing:Stop()
                    buzzing.Volume = 0
                end
            end
        end)
    end

    local function lockFOV()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = _G._FH_FOV_Value or 70 end
    end

    local function enableAntiBee()
        if AntiBeeDiscoData.running then return end
        AntiBeeDiscoData.running = true
        Config.AntiBeeDisco = true
        for _, inst in ipairs(Lighting:GetDescendants()) do abNuke(inst) end
        table.insert(AntiBeeDiscoData.connections, Lighting.DescendantAdded:Connect(function(obj)
            if AntiBeeDiscoData.running then abNuke(obj) end
        end))
        abProtectControls()
        local _abBuzzAcc = 0
        table.insert(AntiBeeDiscoData.connections, RunService.Heartbeat:Connect(function(dt)
            if not AntiBeeDiscoData.running then return end
            _abBuzzAcc = _abBuzzAcc + dt
            if _abBuzzAcc < 0.25 then return end
            _abBuzzAcc = 0
            abBlockBuzzing()
            lockFOV()
        end))
    end

    local function disableAntiBee()
        if not AntiBeeDiscoData.running then return end
        AntiBeeDiscoData.running = false
        Config.AntiBeeDisco = false
        abRestoreControls()
        abDisconnectAll()
    end

    ToggleHandlers.anti_bee = function(state)
        if state then enableAntiBee() else disableAntiBee() end
    end
end
local Aim = {
    remoteIndex      = {},
    remoteObjects    = {},
    currentCharacter = nil,
    lastShot         = 0,
    connections      = {},
    VALID_TOOLS      = {"Web Slinger", "Laser Cape"},
    TARGET_PARTS     = {"HumanoidRootPart", "UpperTorso", "Torso"},
    MAX_DISTANCE     = 500,
}
local WSK = {
    enabled      = false,
    loop         = nil,
    minimized    = false,
    dragging     = false,
    dragStart    = nil,
    panelStart   = nil,
    W = 200, H = 90,
    entry        = { keyCode = nil },
    kb2Debounce  = false,
}
local function wskGetNearest()
    local char = Players.LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local d = (tHRP.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; best = plr end
            end
        end
    end
    return best
end
local function wskStart()
    if WSK.loop then WSK.loop:Disconnect() end
    local target = wskGetNearest()
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local above = true
    local _wskAcc = 0
    WSK.loop = RunService.Heartbeat:Connect(function(dt)
        if not WSK.enabled then WSK.loop:Disconnect(); WSK.loop = nil; return end
        _wskAcc = _wskAcc + dt
        if _wskAcc < 1/20 then return end
        _wskAcc = 0
        if tHRP and tHRP.Parent then
            tHRP.CFrame = tHRP.CFrame + Vector3.new(0, above and 20 or -20, 0)
            above = not above
        end
    end)
end
local function wskStop()
    if WSK.loop then WSK.loop:Disconnect(); WSK.loop = nil end
end
Aim.aimShootWithWSK = function()
    local char = Players.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local ws = char:FindFirstChild("Web Slinger")
        or (Players.LocalPlayer:FindFirstChild("Backpack") and Players.LocalPlayer.Backpack:FindFirstChild("Web Slinger"))
    if not ws then return end
    if ws.Parent ~= char then
        hum:EquipTool(ws)
        task.wait(0.05)
    end
    local tool = char:FindFirstChild("Web Slinger")
    if not tool then return end
    Aim.currentCharacter = char
    Aim.aimShoot()
    task.delay(0.08, function()
        if WSK.enabled then wskStart() end
    end)
end

Aim.REMOTE_KEYS = {
    "UseItem",
    "RE/UseItem",
    "Tools/Cooldown",
}
Aim.aimInitRemotes = function()
    Aim.remoteMap     = {}
    Aim.remoteIndex   = {}
    Aim.remoteObjects = {}
    local resolver = _G._FH_GetRemote
    if not resolver then return end
    for _, key in ipairs(Aim.REMOTE_KEYS) do
        local r = resolver(key)
        if r then
            Aim.remoteMap[key]     = r
            Aim.remoteIndex[key]   = r
            Aim.remoteObjects[r]   = r
        end
    end
end
Aim.aimFireRemote = function(name, ...)
    local r = (Aim.remoteMap and Aim.remoteMap[name])
        or (_G._FH_GetRemote and _G._FH_GetRemote(name))
    if not r then return false end
    if Aim.remoteMap then Aim.remoteMap[name] = r end
    local ok = pcall(function(...) r:FireServer(...) end, ...)
    return ok
end
Aim.aimGetTool = function()
    if not Aim.currentCharacter then return nil end
    return Aim.currentCharacter:FindFirstChildOfClass("Tool")
end
Aim.aimHasValidTool = function()
    local tool = Aim.aimGetTool()
    if not tool then return false end
    for _, name in pairs(Aim.VALID_TOOLS) do
        if tool.Name == name then return true end
    end
    return false
end
Aim.aimGetNearestPlayer = function()
    if not Aim.currentCharacter then return nil end
    local hrp = Aim.currentCharacter:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, shortest = nil, Aim.MAX_DISTANCE
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            local char = player.Character
            if char then
                local targetHRP = char:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    local dist = (targetHRP.Position - hrp.Position).Magnitude
                    if dist < shortest then shortest = dist; closest = player end
                end
            end
        end
    end
    return closest
end
Aim.aimGetBestPart = function(character)
    for _, partName in ipairs(Aim.TARGET_PARTS) do
        local part = character:FindFirstChild(partName)
        if part then return part end
    end
    return nil
end
Aim.aimShoot = function()
    if not Aim.aimHasValidTool() then return end
    local targetPlayer = Aim.aimGetNearestPlayer()
    if not targetPlayer then return end
    local char = targetPlayer.Character
    if not char then return end
    local part = Aim.aimGetBestPart(char)
    if not part then return end
    local targetPos = part.Position + Vector3.new(0, 0.5, 0)
    if _FH_UseItemRemote then
        pcall(function() _FH_UseItemRemote:FireServer(targetPos, part) end)
    else
        Aim.aimFireRemote("RE/UseItem", targetPos, part)
    end
end
Aim.aimTryShoot = function()
    local now = tick()
    if now - Aim.lastShot < 0.07 then return end
    Aim.lastShot = now
    if WSK.enabled then
        Aim.aimShootWithWSK()
    else
        Aim.aimShoot()
    end
end
Aim.aimHookTool = function(tool)
    if not tool then return end
    local conn = tool.Activated:Connect(function() Aim.aimTryShoot() end)
    table.insert(Aim.connections, conn)
end
Aim.aimSetupCharacter = function(char)
    Aim.currentCharacter = char
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then Aim.aimHookTool(tool) end
    local conn = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then Aim.aimHookTool(child) end
    end)
    table.insert(Aim.connections, conn)
end
Aim.startAimbot = function()
    Aim.aimInitRemotes()
    local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            Aim.aimTryShoot()
        end
    end)
    table.insert(Aim.connections, inputConn)
    if Player.Character then Aim.aimSetupCharacter(Player.Character) end
    local charConn = Player.CharacterAdded:Connect(function(char)
        Aim.aimSetupCharacter(char)
    end)
    table.insert(Aim.connections, charConn)
end
Aim.stopAimbot = function()
    for _, conn in ipairs(Aim.connections) do
        pcall(function() conn:Disconnect() end)
    end
    Aim.connections      = {}
    Aim.currentCharacter = nil
end
local InternalStealCache = {}
local autoBlock = false
local function blockClosest() end
local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = {
        holdCallbacks = {},
        triggerCallbacks = {},
        ready = true,
    }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table"then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function"then
                table.insert(data.holdCallbacks, conn.Function)
            end
        end
    end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table"then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function"then
                table.insert(data.triggerCallbacks, conn.Function)
            end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
        InternalStealCache[prompt] = data
    end
end
local function executeInternalStealAsync(prompt)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        local origDist = prompt.MaxActivationDistance
        local deadline = tick() + 5
        while prompt and prompt.Parent and V3.enabled and tick() < deadline do
            prompt.MaxActivationDistance = 9e9
            if autoBlock then
                blockClosest()
            end
            local ok = pcall(_FH_FireStealPrompt, prompt)
            if ok then break end
            task.wait(0.1)
        end
        if prompt and prompt.Parent then
            prompt.MaxActivationDistance = origDist
        end
        data.ready = true
    end)
    return true
end
local function attemptSteal(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then
        InternalStealCache[prompt] = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    end
    return executeInternalStealAsync(prompt)
end
function v3p_buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = {
        holdCallbacks    = {},
        triggerCallbacks = {},
        ready            = true,
    }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table"then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function"then
                table.insert(data.holdCallbacks, conn.Function)
            end
        end
    end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table"then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function"then
                table.insert(data.triggerCallbacks, conn.Function)
            end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
        InternalStealCache[prompt] = data
    end
end
function v3p_runCallbackList(list)
    for _, fn in ipairs(list) do
        task.spawn(fn)
    end
end
v3p_POTION_NAMES = {"Giant Potion", "Giant", "Grow Potion", "Super Grow", "Potion"}
local function _isCurrentlyGiant()
    if _isGiant then return true end
    local c = Players.LocalPlayer and Players.LocalPlayer.Character
    if not c then return false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local scale = hum:FindFirstChild("BodyHeightScale")
        or hum:FindFirstChild("BodyDepthScale")
        or hum:FindFirstChild("BodyWidthScale")
    if scale and scale:IsA("NumberValue") and scale.Value >= GIANT_THRESHOLD then
        return true
    end
    return false
end

local function _activateGiantPotion()
    if _isCurrentlyGiant() then return end
    local lp   = Players.LocalPlayer
    local char = lp and lp.Character
    local bp   = lp and lp:FindFirstChild("Backpack")
    if not char or not bp then return end
    local potion = bp:FindFirstChild("Giant Potion")
    if not potion then return end
    pcall(function()
        potion.Parent = char
        potion:Activate()
        potion.Parent = bp
    end)
end
function v3p_activatePotionAt95()
    if not V3.potionOn then return end
    if _isCurrentlyGiant() then return end
    _activateGiantPotion()
    if giantSpeedEnabled then
        local lp  = Players.LocalPlayer
        local c   = lp and lp.Character
        local bp  = lp and lp:FindFirstChild("Backpack")
        if c and bp then
            local hum  = c:FindFirstChildWhichIsA("Humanoid")
            local tool = c:FindFirstChild("Flying Carpet") or bp:FindFirstChild("Flying Carpet")
            if hum and tool then hum:EquipTool(tool) end
        end
    end
end
function v3p_attemptStealWithPotion(prompt)
    if not prompt or not prompt.Parent then return false end
    if not InternalStealCache[prompt] then
        local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table"then
            for _, conn in ipairs(conns1) do
                if type(conn.Function) == "function"then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table"then
            for _, conn in ipairs(conns2) do
                if type(conn.Function) == "function"then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
            InternalStealCache[prompt] = data
        end
    end
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        if #data.holdCallbacks > 0 then
            for _, fn in ipairs(data.holdCallbacks) do
                task.spawn(fn)
            end
        end
        task.wait(1.425)
        if V3.potionOn then
            v3p_activatePotionAt95()
        end
        task.wait(0.075)
        if #data.triggerCallbacks > 0 then
            for _, fn in ipairs(data.triggerCallbacks) do
                task.spawn(fn)
            end
        end
        task.wait()
        data.ready = true
    end)
    return true
end
function v3p_activatePotion(_tool)
    _activateGiantPotion()
end
function v3p_equipPotion()
    return Players.LocalPlayer.Backpack:FindFirstChild("Giant Potion")
end
v3p_stealAttrCooldown = false
function v3p_executeInternalStealAsync(prompt)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        if V3.potionOn then
            local equippedPotion = v3p_equipPotion()
            if equippedPotion then
                v3p_activatePotion(equippedPotion)
                task.wait(0.15)
            end
        end
        if #data.holdCallbacks > 0 then
            v3p_runCallbackList(data.holdCallbacks)
        end
        task.wait(1.5)
        if #data.triggerCallbacks > 0 then
            if autoBlock then blockClosest() end
            v3p_runCallbackList(data.triggerCallbacks)
        end
        task.wait()
        data.ready = true
    end)
    return true
end
function v3p_attemptSteal(prompt)
    if not prompt or not prompt.Parent then return false end
    v3p_buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then return false end
    return v3p_executeInternalStealAsync(prompt)
end
V3.v3FindBestPrompt = function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local best, bestDist, bestPlot = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if not (sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled) then
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    local base   = podium:FindFirstChild("Base")
                    local spawn  = base and base:FindFirstChild("Spawn")
                    local attach = spawn and spawn:FindFirstChild("PromptAttachment")
                    if attach then
                        local pObj = attach:FindFirstChildOfClass("ProximityPrompt")
                        if pObj and pObj.Enabled and
                            (pObj.ActionText:find("Steal") or pObj.ObjectText:find("Steal")) then
                            local d = (hrp.Position - spawn.Position).Magnitude
                            if d < bestDist then bestDist = d; best = pObj; bestPlot = plot end
                        end
                    end
                end
            end
        end
    end
    return best, bestDist, bestPlot
end
_v3PotionHoldWatched = {}
function _v3PotionWatchPrompt(pObj)
    if _v3PotionHoldWatched[pObj] then return end
    _v3PotionHoldWatched[pObj] = true
    local fired = false
    pObj.Triggered:Connect(function()
        if V3.enabled then return end
        if not V3.potionOn then return end
        local _agn = configRegistry and configRegistry["Auto Grab Nearest"]
        local _agb = configRegistry and configRegistry["Auto Grab Best"]
        if (_agn and _agn.getState and _agn.getState()) or (_agb and _agb.getState and _agb.getState()) then return end

        if not _FH_IsPromptOnEnemyPlot(pObj) then return end
        if not _FH_IsPlayerInEnemyPlot() then return end
        if fired then return end
        fired = true
        _activateGiantPotion()
        task.delay(0.5, function() fired = false end)
    end)
end
task.defer(function()
    task.wait(2)
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, desc in pairs(plots:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.ActionText == "Steal"then
                _v3PotionWatchPrompt(desc)
            end
        end
        plots.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") and desc.ActionText == "Steal" then
                _v3PotionWatchPrompt(desc)
            end
        end)
    end
end)
do
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local _pogHoldFired = {}
    local function _pogAutoGrabActive()
        local _agn = configRegistry and configRegistry["Auto Grab Nearest"]
        local _agb = configRegistry and configRegistry["Auto Grab Best"]
        return (_agn and _agn.getState and _agn.getState()) or (_agb and _agb.getState and _agb.getState())
    end
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player ~= LocalPlayer then return end
        if prompt.ActionText ~= "Steal"and (not prompt.ObjectText or not prompt.ObjectText:find("Steal")) then return end
        if not V3.potionOn then return end
        if V3.enabled or SVN.autoGrabEnabled then return end
        if _pogAutoGrabActive() then return end

        if not _FH_IsPromptOnEnemyPlot(prompt) then return end
        if not _FH_IsPlayerInEnemyPlot() then return end
        local _pogStart    = tick()
        local _pogHoldDur  = (prompt.HoldDuration and prompt.HoldDuration > 0) and prompt.HoldDuration or 1
        local _pogLeadTime = 0.125
        local _pogFireThreshold = math.max(_pogHoldDur - _pogLeadTime, 0)
        local _pogProgThreshold = (_pogHoldDur > 0) and math.max((_pogHoldDur - _pogLeadTime) / _pogHoldDur, 0) or 0.95
        local conn
        local function _pogFire()
            if _pogHoldFired[prompt] then return end
            _pogHoldFired[prompt] = true
            pcall(_activateGiantPotion)
            if SP and SP.spBoosterDoToggle and SP.state ~= true then
                pcall(SP.spBoosterDoToggle)
            end
            if conn then conn:Disconnect() end
        end
        task.delay(_pogFireThreshold, function()
            if not V3.potionOn or V3.enabled or SVN.autoGrabEnabled or _pogAutoGrabActive() then return end
            if not prompt or not prompt.Parent then return end
            _pogFire()
        end)
        conn = prompt.PromptButtonHoldProgress:Connect(function(progress)
            if not V3.potionOn or V3.enabled or SVN.autoGrabEnabled or _pogAutoGrabActive() then
                conn:Disconnect()
                return
            end
            if progress >= _pogProgThreshold and not _pogHoldFired[prompt] then
                _pogFire()
            end
        end)
    end)
    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
        if player ~= LocalPlayer then return end
        _pogHoldFired[prompt] = nil
    end)
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        if player ~= LocalPlayer then return end
        _pogHoldFired[prompt] = nil
    end)
end
do
    local _v3PBar = nil
    local _v3PBarActive = false
    local function _v3EnsureBar()
        if _v3PBar then return end
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local gui = Instance.new("ScreenGui")
        gui.Name              = "V3StealProgressBar"
gui.ResetOnSpawn      = false
        gui.DisplayOrder      = 1000
        gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset    = true
        gui.Parent            = pg
        local bg = Instance.new("Frame")
        bg.Name               = "BG"
        bg.Size               = UDim2.new(0.36, 0, 0, 10)
        bg.Position           = UDim2.new(0.32, 0, 0, 0)
        bg.AnchorPoint        = Vector2.new(0, 0)
        bg.BackgroundColor3   = Color3.fromRGB(10, 10, 10)
        bg.BackgroundTransparency = 0
        bg.BorderSizePixel    = 0
        bg.ZIndex             = 2
        bg.Visible            = false
        bg.Parent             = gui
        local fill = Instance.new("Frame")
        fill.Name             = "Fill"
fill.Size             = UDim2.new(0, 0, 1, 0)
        fill.Position         = UDim2.new(0, 0, 0, 0)
        fill.BackgroundColor3 = (_G._FH_AccentA or Color3.fromRGB(60, 210, 100))
        fill.BorderSizePixel  = 0
        fill.ZIndex           = 3
        fill.Parent           = bg
        local _fillGrad = Instance.new("UIGradient")
        _fillGrad.Color = _FH_BuildThemeSequence and _FH_BuildThemeSequence() or ColorSequence.new(Color3.fromRGB(120,200,255))
        _fillGrad.Parent = fill
        table.insert(_G._FH_ThemeFills, _fillGrad)
        local lbl = Instance.new("TextLabel")
        lbl.Name              = "Lbl"
lbl.Size              = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = "V3 Stealing..."
lbl.TextSize          = 11
        lbl.Font              = Enum.Font.GothamBold
        lbl.TextColor3        = Color3.fromRGB(255, 255, 255)
        lbl.ZIndex            = 4
        lbl.Parent            = bg
        _v3PBar = { gui = gui, bg = bg, fill = fill, lbl = lbl }
    end
    local _v3BarTween = nil
    function _v3ShowStealProgress(victimName)
        _v3EnsureBar()
        if not _v3PBar then return end
        if _v3PBarActive then return end
        _v3PBarActive = true
        local bar = _v3PBar
        bar.fill.BackgroundColor3 = (_G._FH_AccentA or Color3.fromRGB(60, 210, 100))
        bar.fill.BackgroundTransparency = 0
        bar.bg.BackgroundTransparency   = 0
        bar.lbl.TextTransparency        = 0
        bar.lbl.Text = victimName and ("Stealing from ".. victimName .. "...") or "V3 Stealing..."
bar.fill.Size = UDim2.new(0, 0, 1, 0)
        bar.bg.Visible = true
        if _v3BarTween then pcall(function() _v3BarTween:Cancel() end) end
        _v3BarTween = TweenService:Create(bar.fill, TweenInfo.new(0.22, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
        _v3BarTween:Play()
        task.delay(0.22, function()
            if not bar.bg.Visible then return end
            bar.lbl.Text = "Stolen!"
bar.fill.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
        end)
        task.delay(0.85, function()
            TweenService:Create(bar.bg,   TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            TweenService:Create(bar.fill, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()

            pcall(function()
                local g = bar.fill:FindFirstChildOfClass("UIGradient")
                if g and _FH_BuildThemeSequence then g.Color = _FH_BuildThemeSequence() end
            end)
            TweenService:Create(bar.lbl,  TweenInfo.new(0.25), {TextTransparency = 1}):Play()
            task.delay(0.3, function()
                bar.bg.Visible = false
                bar.fill.Size  = UDim2.new(0, 0, 1, 0)
                bar.fill.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
                _v3PBarActive = false
            end)
        end)
    end
end
local _ragdollCommandCache = {}
local _ragdollProfileCache = {}
local function _ragdollCacheActivated(guiObject)
    local cached = {}
    local ok, conns = pcall(getconnections, guiObject.Activated)
    if ok and type(conns) == "table"then
        for _, conn in ipairs(conns) do
            if type(conn.Function) == "function"then
                table.insert(cached, conn.Function)
            end
        end
    end
    return cached
end
local function _ragdollFireActivated(cached)
    for _, fn in ipairs(cached) do task.spawn(fn) end
end
local function _ragdollGetAdminFrames()
    local ap = Players.LocalPlayer.PlayerGui:FindFirstChild("AdminPanel")
    if not ap then return nil, nil end
    local panel = ap:FindFirstChild("AdminPanel")
    if not panel then return nil, nil end
    local content  = panel:FindFirstChild("Content")
    local profiles = panel:FindFirstChild("Profiles")
    if not content or not profiles then return nil, nil end
    return content:FindFirstChild("ScrollingFrame"), profiles:FindFirstChild("ScrollingFrame")
end

function _FH_IsPlayerInEnemyPlot()
    local char = Players.LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false, nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if not _FH_AG_IsMyPlot(plot) then
            local hitbox = plot:FindFirstChild("StealHitbox", true)
            if hitbox then
                local rel = hitbox.CFrame:PointToObjectSpace(hrp.Position)
                if math.abs(rel.X) <= hitbox.Size.X * 0.5
                    and math.abs(rel.Z) <= hitbox.Size.Z * 0.5 then
                    return true, plot
                end
            end
        end
    end
    return false, nil
end

function _FH_IsPromptOnEnemyPlot(prompt)
    if not prompt then return false end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    for _, plot in ipairs(plots:GetChildren()) do
        if prompt:IsDescendantOf(plot) then
            return not _FH_AG_IsMyPlot(plot)
        end
    end
    return false
end
local _v3Tick = 0
_v3PotionPreFired = {}
RunService.Heartbeat:Connect(function()
    if not V3.enabled then return end

    if not _FH_IsPlayerInEnemyPlot() then return end
    local now = tick()
    if now - _v3Tick < 0.05 then return end
    _v3Tick = now
    local prompt, dist, bestPlot = V3.v3FindBestPrompt()
    if not prompt then return end
    local function isInsidePlotHitbox()
        if not bestPlot then return false end
        local hitbox = bestPlot:FindFirstChild("StealHitbox", true)
        if not hitbox then return false end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local cf   = hitbox.CFrame
        local size = hitbox.Size
        local rel  = cf:PointToObjectSpace(hrp.Position)
        return math.abs(rel.X) <= size.X * 0.5 and math.abs(rel.Z) <= size.Z * 0.5
    end
    if V3.potionOn then
        local thresholdPotion = prompt.MaxActivationDistance * 0.15
        if dist <= thresholdPotion and not _v3PotionPreFired[prompt] then
            if isInsidePlotHitbox() then
                _v3PotionPreFired[prompt] = true
                task.spawn(function()
                    _activateGiantPotion()
                end)
            end
        elseif dist > thresholdPotion then
            _v3PotionPreFired[prompt] = nil
        end
    end
    if dist > prompt.MaxActivationDistance + 1 then return end
    if not isInsidePlotHitbox() then return end
    _silCtx.stealStart = tick()
    _silCtx.giantUsed  = V3.potionOn
    _silCtx.halfTP     = false
    _silCtx.victim     = _sil_getVictimFromPrompt(prompt)
    if V3.potionOn then
        local ok = v3p_attemptStealWithPotion(prompt)
        if ok ~= false then
            task.spawn(function() _v3ShowStealProgress(_silCtx.victim) end)
        end
    else
        local ok = attemptSteal(prompt)
        if ok then
            task.spawn(function() _v3ShowStealProgress(_silCtx.victim) end)
        end
    end
end)
local V3P_STEAL_ATTRS = {
    "steal", "Steal", "STEAL",
    "stolen", "Stolen", "STOLEN",
    "stole", "Stole", "STOLE",
    "stealing", "Stealing", "STEALING",
    "grabbing", "Grabbing",
    "isSteal", "IsSteal",
}
function v3p_onStealAttr(attrName)
    if not V3.enabled then return end
    if not V3.potionOn then return end
    if v3p_stealAttrCooldown then return end
    local val = Player:GetAttribute(attrName)
    if val == nil or val == false or val == 0 or val == ""
    then return end
    v3p_stealAttrCooldown = true
    task.spawn(function()
        local prompt, dist = V3.v3FindBestPrompt()
        if prompt and dist <= prompt.MaxActivationDistance + 1 then
            v3p_attemptSteal(prompt)
        end
        task.wait(0.6)
        v3p_stealAttrCooldown = false
    end)
end
for _, attrName in ipairs(V3P_STEAL_ATTRS) do
    Player:GetAttributeChangedSignal(attrName):Connect(function()
        v3p_onStealAttr(attrName)
    end)
end
Player.CharacterAdded:Connect(function()
    V3.potionEquipped = false
    V3.giant          = nil
    v3p_stealAttrCooldown = false
end)
local AnimRemove = { connections = {}, animators = {} }
AnimRemove.isLocalCharacter = function(model)
    return Players.LocalPlayer.Character == model
end
AnimRemove.isMiniFollower = function(model)
    while model do
        if model:IsA("Model") and typeof(model.Name) == "string" and model.Name:sub(1, 4) == "MBF_" then
            return true
        end
        model = model.Parent
    end
    return false
end
AnimRemove.handleAnimator = function(animator)
    local model = animator:FindFirstAncestorOfClass("Model")
    if model and AnimRemove.isLocalCharacter(model) then return end
    if model and Players:GetPlayerFromCharacter(model) then return end
    if AnimRemove.isMiniFollower(animator) then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end
    local conn = animator.AnimationPlayed:Connect(function(track)
        track:Stop(0)
    end)
    table.insert(AnimRemove.connections, conn)
    table.insert(AnimRemove.animators, animator)
end
AnimRemove.enable = function()

    local _step = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Animator") then AnimRemove.handleAnimator(obj) end
        _step = _step + 1
        if _step % 500 == 0 then task.wait() end
    end
    AnimRemove.connections.desc = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Animator") then AnimRemove.handleAnimator(obj) end
    end)
end
AnimRemove.disable = function()
    for _, conn in pairs(AnimRemove.connections) do
        if conn then conn:Disconnect() end
    end
    AnimRemove.connections = {}
    for _, animator in ipairs(AnimRemove.animators) do
        if animator and animator.Parent then
            animator.Enabled = false
            task.defer(function()
                if animator and animator.Parent then
                    animator.Enabled = true
                end
            end)
        end
    end
    AnimRemove.animators = {}
end
FPS.stripVisuals = function(obj)
    if obj.Name:sub(1, 3) == "FH_" then return end
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    elseif obj:IsA("Decal") or obj:IsA("Texture")
        or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
        obj:Destroy()
    end
end
FPS.applyLowQuality = function(_) end
FPS.destroyAllAccessories = function()
    local localChar = Players.LocalPlayer.Character

    local _step = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Accessory") or d:IsA("MeshPartAccessory") then
            if localChar and d:IsDescendantOf(localChar) then continue end
            pcall(function() d:Destroy() end)
        end
        _step = _step + 1
        if _step % 500 == 0 then task.wait() end
    end
end
FPS.enable = function()
    Lighting.GlobalShadows             = false
    Lighting.FogEnd                    = 1e6
    Lighting.FogStart                  = 0
    Lighting.Brightness                = 1
    Lighting.EnvironmentDiffuseScale   = 0
    Lighting.EnvironmentSpecularScale  = 0
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect")
            or v:IsA("SunRaysEffect") or v:IsA("PostEffect")
            or v:IsA("Atmosphere") then
            v:Destroy()
        end
    end
    FPS.destroyAllAccessories()
    for _, obj in ipairs(workspace:GetDescendants()) do
        FPS.stripVisuals(obj)
        FPS.applyLowQuality(obj)
    end
    FPS.connections.descendant = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Accessory") or obj:IsA("MeshPartAccessory") then
            pcall(function() obj:Destroy() end)
            return
        end
        FPS.stripVisuals(obj)
        FPS.applyLowQuality(obj)
    end)
    local function removeMeshes(tool)
        if not tool:IsA("Tool") then return end
        local handle = tool:FindFirstChild("Handle")
        if not handle then return end
        for _, d in ipairs(handle:GetDescendants()) do
            if d:IsA("Mesh") or d:IsA("SpecialMesh") then d:Destroy() end
        end
    end
    local function onFPSCharacter(char)
        char.ChildAdded:Connect(removeMeshes)
        for _, child in ipairs(char:GetChildren()) do removeMeshes(child) end
    end
    FPS.connections.player = Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(onFPSCharacter)
    end)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then onFPSCharacter(plr.Character) end
    end
    FPS.connections.localChar = Players.LocalPlayer.CharacterAdded:Connect(function(char)
        if not _G._FH_AlwaysOnFPS then return end
        task.wait(0.2)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e9
            Lighting.Brightness = 1
        end)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect")
            or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled = false end)
            end
        end
        for _, d in ipairs(char:GetDescendants()) do
            FPS.stripVisuals(d)
        end
        removeMeshes(char)
        for _, child in ipairs(char:GetChildren()) do removeMeshes(child) end
    end)
end
FPS.disable = function()
    for _, conn in pairs(FPS.connections) do
        if conn then conn:Disconnect() end
    end
    FPS.connections = {}
end

do
    if _G._FH_AlwaysOnFPS and not _G._FH_AlwaysOnFPS_Applied then
        _G._FH_AlwaysOnFPS_Applied = true
        task.spawn(function()
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                Lighting.GlobalShadows  = false
                Lighting.FogEnd         = 1e9
                Lighting.Brightness     = 1
            end)
            pcall(function()

                local _step = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                    or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    end
                    _step = _step + 1
                    if _step % 500 == 0 then task.wait() end
                end
            end)

            workspace.DescendantAdded:Connect(function(obj)
                if not _G._FH_AlwaysOnFPS then return end
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    pcall(function() obj.Enabled = false end)
                end
            end)
        end)
    end
end
AntiRagdoll.forceBackpack = function()
    if not AntiRagdoll.running then return end
    local gui = Player:FindFirstChild("PlayerGui")
    if not gui then return end
    local backpackGui = gui:FindFirstChild("BackpackGui")
    if not backpackGui then return end
    local backpack = backpackGui:FindFirstChild("Backpack")
    if not backpack then return end
    backpack.Visible = true
    if not backpack:FindFirstChild("ForceConnection") then
        local tag = Instance.new("BoolValue")
        tag.Name   = "ForceConnection"
        tag.Parent = backpack
        backpack:GetPropertyChangedSignal("Visible"):Connect(function()
            if not AntiRagdoll.running then return end
            if not backpack.Visible then backpack.Visible = true end
        end)
    end
end
AntiRagdoll.removeRagdollConstraints = function(char)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint")
            or d:IsA("NoCollisionConstraint")
            or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            d:Destroy()
        end
    end
end
AntiRagdoll.resetCharacter = function(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Anchored = false
        rootPart.Velocity  = Vector3.zero
    end
    if humanoid then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid.PlatformStand = false
        humanoid.Sit           = false
        if humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        workspace.CurrentCamera.CameraSubject = humanoid
    end
end
AntiRagdoll.onCharacterAdded_AR = function(char)
    char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")

    AntiRagdoll.connections.charDescAdded = char.DescendantAdded:Connect(function(obj)
        if not AntiRagdoll.running then return end
        if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint")
            or obj:IsA("NoCollisionConstraint")
            or (obj:IsA("Attachment") and obj.Name:find("RagdollAttachment")) then
            task.defer(function()
                if not AntiRagdoll.running then return end
                if obj.Parent then obj:Destroy() end
            end)
        end
    end)
    AntiRagdoll.connections.platformStand = humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if not AntiRagdoll.running then return end
        if humanoid.PlatformStand then
            task.defer(function()
                if not AntiRagdoll.running then return end
                AntiRagdoll.resetCharacter(char)
                AntiRagdoll.removeRagdollConstraints(char)
            end)
        end
    end)
    AntiRagdoll.removeRagdollConstraints(char)
    AntiRagdoll.resetCharacter(char)
end
AntiRagdoll.enable = function()

    if AntiRagdoll.running then return end
    AntiRagdoll.running = true
    local _arTick = 0
    AntiRagdoll.connections.heartbeat = RunService.Heartbeat:Connect(function(dt)
        _arTick = _arTick + dt
        if _arTick < 0.1 then return end
        _arTick = 0
        local char = Player.Character
        if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        local s = hum:GetState()
        local ragdolled = (s == Enum.HumanoidStateType.Physics
            or s == Enum.HumanoidStateType.Ragdoll
            or s == Enum.HumanoidStateType.FallingDown)
        local endTime = Player:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
            ragdolled = true
        end
        if ragdolled then
            pcall(function() Player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
            AntiRagdoll.removeRagdollConstraints(char)
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and obj.Enabled == false then
                    obj.Enabled = true
                end
            end
            if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
            workspace.CurrentCamera.CameraSubject = hum
            root.Anchored = false
            root.Velocity  = Vector3.zero
        end
    end)
    AntiRagdoll.connections.charAdded = Player.CharacterAdded:Connect(function(char)
        task.wait(1)
        AntiRagdoll.forceBackpack()
        AntiRagdoll.onCharacterAdded_AR(char)
    end)
    if Player.Character then AntiRagdoll.onCharacterAdded_AR(Player.Character) end
    task.spawn(function()
        while AntiRagdoll.running do
            task.wait(0.5)
            AntiRagdoll.forceBackpack()
        end
    end)
end
AntiRagdoll.disable = function()
    AntiRagdoll.running = false
    for _, conn in pairs(AntiRagdoll.connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    AntiRagdoll.connections = {}

    pcall(function()
        local char = Player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        end
    end)
end
pcall(function()
    if game.CoreGui:FindFirstChild("FadedHub") then
        game.CoreGui.FadedHub:Destroy()
    end
end)
T = {
    BG          = Color3.fromRGB(18,  18,  18),
    Header      = Color3.fromRGB(8,   8,   8),
    Card        = Color3.fromRGB(24,  24,  24),
    CardHover   = Color3.fromRGB(24,  24,  24),
    Border      = Color3.fromRGB(45,  45,  45),
    BorderHover = Color3.fromRGB(45,  45,  45),
    White       = Color3.fromRGB(245, 245, 245),
    Dim         = Color3.fromRGB(110, 110, 110),
    TabActive   = Color3.fromRGB(245, 245, 245),
    TabInact    = Color3.fromRGB(75,  75,  75),
    TrackOn     = Color3.fromRGB(240, 240, 240),
    TrackOff    = Color3.fromRGB(45,  45,  45),
    KnobOn      = Color3.fromRGB(10,  10,  10),
    KnobOff     = Color3.fromRGB(160, 160, 160),
}

do
    local function _restoreRGB(t, dr, dg, db)
        if type(t) == "table" then
            return Color3.fromRGB(tonumber(t[1]) or dr, tonumber(t[2]) or dg, tonumber(t[3]) or db)
        end
        return Color3.fromRGB(dr, dg, db)
    end
    Config.theme   = Config.theme or (_FH_SavedConfig and _FH_SavedConfig.theme) or {}
    _G._FH_AccentA = _restoreRGB(Config.theme.a, 120, 200, 255)
    _G._FH_AccentB = _restoreRGB(Config.theme.b, 255, 120, 220)
end
_G._FH_ThemeStrokes = _G._FH_ThemeStrokes or {}
_G._FH_ThemeFills   = _G._FH_ThemeFills   or {}
local function _FH_BuildThemeSequence()
    local A, B = _G._FH_AccentA, _G._FH_AccentB

    local function mix(c1, c2, t)
        return Color3.new(
            c1.R + (c2.R - c1.R) * t,
            c1.G + (c2.G - c1.G) * t,
            c1.B + (c2.B - c1.B) * t
        )
    end
    local function brighten(c, amt)
        return Color3.new(
            math.min(1, c.R + (1 - c.R) * amt),
            math.min(1, c.G + (1 - c.G) * amt),
            math.min(1, c.B + (1 - c.B) * amt)
        )
    end
    local midAB = brighten(mix(A, B, 0.5), 0.15)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, A),
        ColorSequenceKeypoint.new(0.25, midAB),
        ColorSequenceKeypoint.new(0.50, B),
        ColorSequenceKeypoint.new(0.75, midAB),
        ColorSequenceKeypoint.new(1.00, A),
    })
end

local function _FH_BuildESPSwipeSequence()
    local accent = _G._FH_AccentA or Color3.fromRGB(120, 200, 255)
    local white  = Color3.fromRGB(255, 255, 255)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, white),
        ColorSequenceKeypoint.new(0.42, white),
        ColorSequenceKeypoint.new(0.50, accent),
        ColorSequenceKeypoint.new(0.58, white),
        ColorSequenceKeypoint.new(1.00, white),
    })
end
_G._FH_BuildESPSwipeSequence = _FH_BuildESPSwipeSequence

local function _FH_AddThemeStroke(stroke)
    if not stroke then return end
    local g = stroke:FindFirstChildOfClass("UIGradient")
    if not g then
        g = Instance.new("UIGradient")
        g.Parent = stroke
    end
    g.Color    = _FH_BuildThemeSequence()
    g.Rotation = 35
    g.Transparency = NumberSequence.new(0)
    table.insert(_G._FH_ThemeStrokes, g)
    return g
end

local function _FH_AddThemeStrokeToFrame(frame, thickness)
    if not frame then return end
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Thickness       = thickness or 1.6
    s.Color           = Color3.fromRGB(255, 255, 255)
    s.Parent          = frame
    return _FH_AddThemeStroke(s)
end

local function _FH_AddThemeFill(frame)
    if not frame then return end
    local g = frame:FindFirstChildOfClass("UIGradient")
    if not g then
        g = Instance.new("UIGradient")
        g.Parent = frame
    end
    g.Color    = _FH_BuildThemeSequence()
    g.Rotation = 35
    g.Transparency = NumberSequence.new(0)
    table.insert(_G._FH_ThemeFills, g)
    return g
end
_G._FH_BuildThemeSequence = _FH_BuildThemeSequence

_G._FH_ESPGradients = _G._FH_ESPGradients or {}

local function _FH_ApplyThemeGradientToText(label, rotation, keepColor)
    if not label then return end
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    local g = label:FindFirstChildOfClass("UIGradient")
    local fresh = false
    if not g then
        g = Instance.new("UIGradient")
        g.Parent = label
        fresh = true
    end
    g.Color        = _FH_BuildESPSwipeSequence()
    g.Rotation     = 0
    g.Transparency = NumberSequence.new(0)
    if fresh then
        table.insert(_G._FH_ESPGradients, g)
    end
    return g
end
_G._FH_ApplyThemeGradientToText = _FH_ApplyThemeGradientToText

local function _FH_TintGUI()
    if not _G or not GUI then return end
    local A, B = _G._FH_AccentA, _G._FH_AccentB
    if not (A and B) then return end
    local midR = (A.R + B.R) * 0.5
    local midG = (A.G + B.G) * 0.5
    local midB = (A.B + B.B) * 0.5
    local AMT  = 0.18
    for _, d in ipairs(GUI:GetDescendants()) do
        if d:IsA("Frame") or d:IsA("TextButton") or d:IsA("ImageButton")
        or d:IsA("ScrollingFrame") or d:IsA("TextBox") then
            local orig = d:GetAttribute("_FH_OrigBG")
            if not orig then
                local c = d.BackgroundColor3

                if math.max(c.R, c.G, c.B) < 0.27 and d.BackgroundTransparency < 0.98 then
                    d:SetAttribute("_FH_OrigBG", c)
                    orig = c
                end
            end
            if orig then
                d.BackgroundColor3 = Color3.new(
                    orig.R + (midR - orig.R) * AMT,
                    orig.G + (midG - orig.G) * AMT,
                    orig.B + (midB - orig.B) * AMT)
            end
        end
    end
end
_G._FH_TintGUI = _FH_TintGUI
_G._FH_ThemeCallbacks = _G._FH_ThemeCallbacks or {}
local function _FH_UpdateThemeColors()
    local seq    = _FH_BuildThemeSequence()
    local espSeq = _FH_BuildESPSwipeSequence()
    for _, g in ipairs(_G._FH_ThemeStrokes) do pcall(function() g.Color = seq    end) end
    for _, g in ipairs(_G._FH_ThemeFills)   do pcall(function() g.Color = seq    end) end
    for _, g in ipairs(_G._FH_ESPGradients) do pcall(function() g.Color = espSeq end) end
    for _, fn in ipairs(_G._FH_ThemeCallbacks) do pcall(fn) end
    pcall(_FH_TintGUI)
    Config.theme = Config.theme or {}
    Config.theme.a = { math.floor(_G._FH_AccentA.R * 255 + 0.5),
                       math.floor(_G._FH_AccentA.G * 255 + 0.5),
                       math.floor(_G._FH_AccentA.B * 255 + 0.5) }
    Config.theme.b = { math.floor(_G._FH_AccentB.R * 255 + 0.5),
                       math.floor(_G._FH_AccentB.G * 255 + 0.5),
                       math.floor(_G._FH_AccentB.B * 255 + 0.5) }
    pcall(FH_SaveConfig)
end
_G._FH_UpdateThemeColors = _FH_UpdateThemeColors

task.spawn(function()
    pcall(_FH_TintGUI)
    while true do
        task.wait(5)
        pcall(_FH_TintGUI)
    end
end)

if not _G._FH_ThemeRotator_v4 then
    _G._FH_ThemeRotator_v4 = true

    local function spin(list, rot)
        local n, w = #list, 0
        for r = 1, n do
            local g = list[r]
            if g and g.Parent then
                w = w + 1
                list[w] = g
                g.Rotation = rot
            end
        end
        for i = n, w + 1, -1 do list[i] = nil end
    end
    task.spawn(function()
        local rot = 0
        while true do
            local strokes = _G._FH_ThemeStrokes
            local fills   = _G._FH_ThemeFills
            if (strokes and #strokes > 0) or (fills and #fills > 0) then
                rot = (rot + 4.8) % 360
                if strokes then spin(strokes, rot) end
                if fills   then spin(fills,   (rot + 60) % 360) end
                task.wait(1 / 15)
            else
                task.wait(0.5)
            end
        end
    end)

    task.spawn(function()
        local t        = -1
        local lastTick = tick()
        local SPEED    = 0.6
        while true do
            local list = _G._FH_ESPGradients
            if list and #list > 0 then
                local now = tick()
                t = t + (now - lastTick) * SPEED
                lastTick = now
                if t > 1 then t = t - 2 end
                local n, w = #list, 0
                local vec = Vector2.new(t, 0)
                for r = 1, n do
                    local g = list[r]
                    if g and g.Parent then
                        w = w + 1
                        list[w] = g
                        g.Offset = vec
                    end
                end
                for i = n, w + 1, -1 do list[i] = nil end
                task.wait(1 / 30)
            else
                lastTick = tick()
                task.wait(0.5)
            end
        end
    end)
end
F = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
M = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
S = TweenInfo.new(0.5,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
Tween = function(o, i, p) TweenService:Create(o, i, p):Play() end
Corner = function(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end
Stroke = function(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color           = col or T.Border
    s.Thickness       = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end
Padding = function(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.Parent = p
end
Label = function(p, txt, sz, col, font)
    local l = Instance.new("TextLabel")
    l.Text              = txt or ""

    local _szFinal = sz or 13
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        _szFinal = _szFinal + 4
    end
    l.TextSize          = _szFinal
    l.TextColor3        = col or T.White
    l.Font              = font or Enum.Font.GothamMedium
    l.BackgroundTransparency = 1
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = p
    return l
end
GUI = Instance.new("ScreenGui")
GUI.Name           = "FadedHub"
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.ResetOnSpawn   = false
GUI.IgnoreGuiInset = true
if not pcall(function() GUI.Parent = game.CoreGui end) then
    GUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end
do
local _activeNotifs = {}
local NOTIF_W      = 200
local NOTIF_H      = 44
local NOTIF_GAP    = 6
local NOTIF_PAD_X  = 14
local NOTIF_PAD_Y  = 14
local NOTIF_DUR    = 2
local function _shadowTargetY(slotIdx)
    return -(NOTIF_PAD_Y + NOTIF_H + 4 + slotIdx * (NOTIF_H + NOTIF_GAP))
end
local function _repoAll(tweenInfo)
    for i, e in ipairs(_activeNotifs) do
        local slotIdx = i - 1
        TweenService:Create(e.shadow, tweenInfo, {
            Position = UDim2.new(0, NOTIF_PAD_X - 4, 1, _shadowTargetY(slotIdx))
        }):Play()
    end
end
ShowToggleNotification = function(toggleName, enabled, customDur)
    local statusTxt = enabled and "Enabled"or "Disabled"local statusCol = enabled
        and Color3.fromRGB(150, 255, 150)
        or  Color3.fromRGB(255, 100, 100)

    local _dur = NOTIF_DUR
    if type(toggleName) == "string" then
        local _u = toggleName:upper()
        if _u:find("CAN NOW", 1, true) and _u:find("TELEPORT", 1, true) then
            _dur = 60
        end
    end
    local IN_INFO   = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local OUT_INFO  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    local BAR_INFO  = TweenInfo.new(_dur, Enum.EasingStyle.Linear)
    local FADE_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
    local REPO_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local shadow = Instance.new("Frame")
    shadow.Name                   = "ToastShadow"
shadow.Size                   = UDim2.new(0, NOTIF_W + 8, 0, NOTIF_H + 8)
    shadow.Position               = UDim2.new(0, -(NOTIF_W + 32), 1, _shadowTargetY(0))
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.12
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 99
    shadow.Parent                 = GUI
    local _sc = Instance.new("UICorner"); _sc.CornerRadius = UDim.new(0, 12); _sc.Parent = shadow
    local toast = Instance.new("Frame")
    toast.Name                   = "ToastNotif"
toast.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
    toast.Position               = UDim2.new(0, 4, 0, 4)
    toast.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel        = 0
    toast.ZIndex                 = 100
    toast.Parent                 = shadow
    local _tc = Instance.new("UICorner"); _tc.CornerRadius = UDim.new(0, 10); _tc.Parent = toast
    local _stroke = Instance.new("UIStroke")
    _stroke.Color        = Color3.fromRGB(55, 55, 55)
    _stroke.Thickness    = 1
    _stroke.Transparency = 1
    _stroke.Parent       = toast
    local pill = Instance.new("Frame")
    pill.Size                   = UDim2.new(0, 3, 0, NOTIF_H - 16)
    pill.Position               = UDim2.new(0, 9, 0.5, -(NOTIF_H - 16) / 2)
    pill.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    pill.BackgroundTransparency = 0.3
    pill.BorderSizePixel        = 0
    pill.ZIndex                 = 101
    pill.Parent                 = toast
    local _pc = Instance.new("UICorner"); _pc.CornerRadius = UDim.new(1, 0); _pc.Parent = pill
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(1, -24, 0, 15)
    nameLabel.Position           = UDim2.new(0, 19, 0, 7)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text               = toggleName
    nameLabel.TextSize           = 11
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    nameLabel.TextTransparency   = 1
    nameLabel.ZIndex             = 101
    nameLabel.Parent             = toast
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size               = UDim2.new(1, -24, 0, 11)
    statusLabel.Position           = UDim2.new(0, 19, 0, 23)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text               = statusTxt
    statusLabel.TextSize           = 10
    statusLabel.Font               = Enum.Font.Gotham
    statusLabel.TextColor3         = statusCol
    statusLabel.TextXAlignment     = Enum.TextXAlignment.Left
    statusLabel.TextTransparency   = 1
    statusLabel.ZIndex             = 101
    statusLabel.Parent             = toast
    local barTrack = Instance.new("Frame")
    barTrack.Size             = UDim2.new(1, 0, 0, 2)
    barTrack.Position         = UDim2.new(0, 0, 1, -2)
    barTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    barTrack.BorderSizePixel  = 0
    barTrack.ZIndex           = 101
    barTrack.Parent           = toast
    local _btc = Instance.new("UICorner"); _btc.CornerRadius = UDim.new(1, 0); _btc.Parent = barTrack
    local barFill = Instance.new("Frame")
    barFill.Size             = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    barFill.BorderSizePixel  = 0
    barFill.ZIndex           = 102
    barFill.Parent           = barTrack
    local _bfc = Instance.new("UICorner"); _bfc.CornerRadius = UDim.new(1, 0); _bfc.Parent = barFill
    local entry = { shadow = shadow }
    table.insert(_activeNotifs, 1, entry)
    _repoAll(REPO_INFO)
    TweenService:Create(shadow, IN_INFO, {
        Position = UDim2.new(0, NOTIF_PAD_X - 4, 1, _shadowTargetY(0))
    }):Play()
    TweenService:Create(toast,       IN_INFO, {BackgroundTransparency = 0}):Play()
    TweenService:Create(_stroke,     IN_INFO, {Transparency = 0.3}):Play()
    TweenService:Create(nameLabel,   IN_INFO, {TextTransparency = 0}):Play()
    TweenService:Create(statusLabel, IN_INFO, {TextTransparency = 0}):Play()
    task.delay(0.1, function()
        TweenService:Create(barFill, BAR_INFO, {Size = UDim2.new(0, 0, 1, 0)}):Play()
    end)
    task.delay(_dur + 0.15, function()
        for i, e in ipairs(_activeNotifs) do
            if e == entry then table.remove(_activeNotifs, i); break end
        end
        _repoAll(REPO_INFO)
        local exitY = shadow.Position.Y.Offset
        TweenService:Create(shadow, OUT_INFO, {
            Position = UDim2.new(0, -(NOTIF_W + 32), 1, exitY)
        }):Play()
        TweenService:Create(toast,       FADE_INFO, {BackgroundTransparency = 1}):Play()
        TweenService:Create(nameLabel,   FADE_INFO, {TextTransparency = 1}):Play()
        local tw = TweenService:Create(statusLabel, FADE_INFO, {TextTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function() shadow:Destroy() end)
    end)
end
end
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isPhone = false
if isMobile then
    local _vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
    local _short = math.min(_vp.X, _vp.Y)
    isPhone = _short < 600
end
do
    if isPhone then

        WIN_W = 230
        WIN_H = 250
    elseif isMobile then
        WIN_W = 260
        WIN_H = 270
    else
        WIN_W = 320
        WIN_H = 320
    end
end
if isMobile then
    SS.W = 128; SS.H = 240
    SP.W = 130; SP.H = 124
    AB.W = 134; AB.H = 66
    UB.W = 144; UB.H = 62
end
BorderFrame = Instance.new("Frame")
BorderFrame.Name              = "GradBorder"
BorderFrame.Size              = UDim2.new(0, WIN_W + 10, 0, WIN_H + 10)
BorderFrame.Position          = UDim2.new(0.5, -(WIN_W + 10)/2, 0.5, -(WIN_H + 10)/2)
BorderFrame.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
BorderFrame.BackgroundTransparency = 1
BorderFrame.BorderSizePixel   = 0
BorderFrame.ZIndex            = 1
BorderFrame.Parent            = GUI
Corner(BorderFrame, 16)
_FH_AddThemeStrokeToFrame(BorderFrame, 4)
Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.AnchorPoint      = Vector2.new(0, 0)
Win.BackgroundColor3 = T.BG
Win.BackgroundTransparency = 0.25
Win.BorderSizePixel  = 0
Win.ZIndex           = 2
Win.Parent           = GUI
Corner(Win, 12)
BANNER_W, BANNER_H = 280, 82
TopBanner = Instance.new("Frame")
TopBanner.Name                    = "FadedHubBanner"
TopBanner.Size                    = UDim2.new(0, BANNER_W, 0, BANNER_H)
TopBanner.Position                = UDim2.new(0.5, -BANNER_W / 2, 0, 45)
TopBanner.AnchorPoint             = Vector2.new(0, 0)
TopBanner.BackgroundColor3        = Color3.fromRGB(8, 8, 12)
TopBanner.BackgroundTransparency  = 0.45
TopBanner.BorderSizePixel         = 0
TopBanner.ZIndex                  = 50
TopBanner.Active                  = false
TopBanner.Visible                 = not isMobile
TopBanner.Parent                  = GUI
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = TopBanner
end
BannerStrokeInst = Instance.new("UIStroke")
BannerStrokeInst.Thickness       = 2
BannerStrokeInst.Color           = Color3.fromRGB(255, 255, 255)
BannerStrokeInst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BannerStrokeInst.Parent          = TopBanner
_FH_AddThemeStroke(BannerStrokeInst)
BannerTitle = Instance.new("TextLabel")
BannerTitle.Name              = "BannerTitle"
BannerTitle.Text              = "FADED HUB V3"
BannerTitle.TextSize          = 20
BannerTitle.Font              = Enum.Font.GothamBold
BannerTitle.BackgroundTransparency = 1
BannerTitle.Size              = UDim2.new(1, 0, 0, 26)
BannerTitle.Position          = UDim2.new(0, 0, 0, 8)
BannerTitle.TextXAlignment    = Enum.TextXAlignment.Center
BannerTitle.TextYAlignment    = Enum.TextYAlignment.Center
BannerTitle.TextColor3        = Color3.fromRGB(255, 255, 255)
BannerTitle.ZIndex            = 51
BannerTitle.Parent            = TopBanner
BannerDev = Instance.new("TextLabel")
BannerDev.Name              = "BannerDev"
BannerDev.Text              = "@avi x @sheesh  -  dsc.gg/fadedhub"
BannerDev.TextSize          = 11
BannerDev.Font              = Enum.Font.GothamMedium
BannerDev.BackgroundTransparency = 1
BannerDev.Size              = UDim2.new(1, 0, 0, 18)
BannerDev.Position          = UDim2.new(0, 0, 0, 34)
BannerDev.TextXAlignment    = Enum.TextXAlignment.Center
BannerDev.TextYAlignment    = Enum.TextYAlignment.Center
BannerDev.TextColor3        = Color3.fromRGB(180, 180, 180)
BannerDev.ZIndex            = 51
BannerDev.Parent            = TopBanner
BannerStats = Instance.new("TextLabel")
BannerStats.Name              = "BannerStats"
BannerStats.Text              = "FPS: --   PING: --ms"
BannerStats.TextSize          = 12
BannerStats.Font              = Enum.Font.GothamBold
BannerStats.BackgroundTransparency = 1
BannerStats.Size              = UDim2.new(1, 0, 0, 18)
BannerStats.Position          = UDim2.new(0, 0, 0, 56)
BannerStats.TextXAlignment    = Enum.TextXAlignment.Center
BannerStats.TextYAlignment    = Enum.TextYAlignment.Center
BannerStats.TextColor3        = Color3.fromRGB(245, 245, 245)
BannerStats.ZIndex            = 51
BannerStats.Parent            = TopBanner
bannerAngle = 0
fpsClock    = 0
fpsFrames   = 0
displayFPS  = 0

if not isMobile then
do
local _lastBannerText = ""
RunService.Heartbeat:Connect(function(dt)
    fpsFrames = fpsFrames + 1
    fpsClock  = fpsClock  + dt
    if not TopBanner or not TopBanner.Visible then return end
    if fpsClock >= 1 then
        displayFPS = math.floor(fpsFrames / fpsClock)
        fpsFrames  = 0
        fpsClock   = 0
        local ping = math.floor((Players.LocalPlayer:GetNetworkPing() or 0) * 1000)
        local txt  = "FPS: ".. displayFPS .. "PING: ".. ping .. "ms"
        if txt ~= _lastBannerText then
            BannerStats.Text = txt
            _lastBannerText  = txt
        end
    end
end)
end
end
Hdr = Instance.new("Frame")
Hdr.Size             = UDim2.new(1, 0, 0, 40)
Hdr.BackgroundColor3 = T.Header
Hdr.BackgroundTransparency = 0.2
Hdr.BorderSizePixel  = 0
Hdr.ZIndex           = 5
Hdr.Parent           = Win
Corner(Hdr, 12)
Hdr.Active = true
HdrFill = Instance.new("Frame")
HdrFill.Size             = UDim2.new(1, 0, 0, 8)
HdrFill.Position         = UDim2.new(0, 0, 1, -8)
HdrFill.BackgroundColor3 = T.Header
HdrFill.BackgroundTransparency = 0.2
HdrFill.BorderSizePixel  = 0
HdrFill.ZIndex           = 5
HdrFill.Parent           = Hdr
HdrLine = Instance.new("Frame")
HdrLine.Size             = UDim2.new(1, 0, 0, 1)
HdrLine.Position         = UDim2.new(0, 0, 1, -1)
HdrLine.BackgroundColor3 = T.Border
HdrLine.BorderSizePixel  = 0
HdrLine.ZIndex           = 6
HdrLine.Parent           = Hdr
Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 10, 0, 10)
Dot.Position         = UDim2.new(0, 16, 0.5, -3)
Dot.BackgroundColor3 = T.White
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 6
Dot.Parent           = Hdr
Corner(Dot, 4)
TitleLbl = Label(Hdr, "Faded Hub", 14, T.White, Enum.Font.GothamBold)
TitleLbl.Size     = UDim2.new(0, 160, 0, 20)
TitleLbl.Position = UDim2.new(0, 30, 0.5, -10)
TitleLbl.ZIndex   = 6
VerLbl = Label(Hdr, "v2.0", 10, T.Dim, Enum.Font.Gotham)
VerLbl.Size     = UDim2.new(0, 40, 0, 14)
VerLbl.Position = UDim2.new(0, 30, 0.5, 8)
VerLbl.ZIndex   = 6
do
local LockGuiBtn = Instance.new("TextButton")
LockGuiBtn.Name              = "LockGuiBtn"
LockGuiBtn.Size              = UDim2.new(0, 46, 0, 22)
LockGuiBtn.Position          = UDim2.new(1, -54, 0.5, -11)
LockGuiBtn.BackgroundColor3  = T.Card
LockGuiBtn.BorderSizePixel   = 0
LockGuiBtn.Text              = "FREE"
LockGuiBtn.TextSize          = 10
LockGuiBtn.Font              = Enum.Font.GothamBold
LockGuiBtn.TextColor3        = T.White
LockGuiBtn.ZIndex            = 7
LockGuiBtn.Active            = true
LockGuiBtn.AutoButtonColor   = false
LockGuiBtn.Parent            = Hdr
Corner(LockGuiBtn, 6)
local _lockBtnStroke = Stroke(LockGuiBtn, T.Border, 1)
_G._FH_GUI_LOCKED = false
LockGuiBtn.MouseButton1Click:Connect(function()
    _G._FH_GUI_LOCKED = not _G._FH_GUI_LOCKED
    if _G._FH_GUI_LOCKED then
        LockGuiBtn.Text             = "LOCK"
LockGuiBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        _lockBtnStroke.Color        = Color3.fromRGB(200, 60, 60)
    else
        LockGuiBtn.Text             = "FREE"
LockGuiBtn.BackgroundColor3 = T.Card
        _lockBtnStroke.Color        = T.Border
    end
end)
end
do
    local dragging, dragStart, winStart
    Hdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            _G._FH_MAIN_DRAG = true
            dragStart = inp.Position
            winStart  = Win.Position
            if inp.UserInputType == Enum.UserInputType.Touch then
                pcall(function() game:GetService("UserInputService"):GetMouseDelta() end)
            end
        end
    end)
    Hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false

            task.delay(0.05, function() _G._FH_MAIN_DRAG = false end)
            Config.mini = Config.mini or {}
            Config.mini.main_pos = {
                x  = Win.Position.X.Offset,
                y  = Win.Position.Y.Offset,
                xs = Win.Position.X.Scale,
                ys = Win.Position.Y.Scale,
            }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d      = inp.Position - dragStart
            local newPos = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + d.X,
                winStart.Y.Scale, winStart.Y.Offset + d.Y
            )
            Win.Position         = newPos
            BorderFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 5,
                newPos.Y.Scale, newPos.Y.Offset - 5
            )
        end
    end)
end
TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, 34)
TabBar.Position         = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TabBar.BackgroundTransparency = 0.2
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 4
TabBar.Parent           = Win
TBLine = Instance.new("Frame")
TBLine.Size             = UDim2.new(1, 0, 0, 1)
TBLine.Position         = UDim2.new(0, 0, 0, 73)
TBLine.BackgroundColor3 = T.Border
TBLine.BorderSizePixel  = 0
TBLine.ZIndex           = 5
TBLine.Parent           = Win
TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection      = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
TabLayout.Padding             = UDim.new(0, 0)
TabLayout.Parent              = TabBar
do
local TabSizeConstraint = Instance.new("UISizeConstraint")
TabSizeConstraint.MaxSize = Vector2.new(WIN_W, 34)
TabSizeConstraint.Parent  = TabBar
end
ContentArea = Instance.new("Frame")
ContentArea.Size                = UDim2.new(1, 0, 1, -74)
ContentArea.Position            = UDim2.new(0, 0, 0, 74)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants    = true
ContentArea.ZIndex              = 2
ContentArea.Parent              = Win
CreateToggle = function(parent, name, desc, cb, actionFn)
    local state  = (Config.toggles[name] == true)
    local hasDesc = false
    desc = nil

    local cardH  = isMobile and (hasDesc and 50 or 32) or (hasDesc and 42 or 26)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -16, 0, cardH)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel  = 0
    card.Parent           = parent
    Corner(card, 8)
    local cStroke = Stroke(card, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(cStroke)
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 2)
    local nameY  = hasDesc and 10 or (cardH/2 - 8)
    local nameLbl = Label(card, name, isMobile and 11 or 13, T.White, Enum.Font.GothamMedium)
    nameLbl.Size     = UDim2.new(1, -108, 0, 16)
    nameLbl.Position = UDim2.new(0, 14, 0, nameY)
    nameLbl.ZIndex   = 2
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    if hasDesc then
        local descLbl = Label(card, desc, isMobile and 9 or 11, T.Dim, Enum.Font.Gotham)
        descLbl.Size     = UDim2.new(1, -108, 0, 14)
        descLbl.Position = UDim2.new(0, 14, 0, nameY + 18)
        descLbl.ZIndex   = 2
        descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local kbLbl = Instance.new("TextLabel")
    kbLbl.Size              = UDim2.new(0, 32, 0, 16)
    kbLbl.Position          = UDim2.new(1, -92, 0.5, -8)
    kbLbl.BackgroundTransparency = 1
    kbLbl.Text              = ""
kbLbl.TextSize          = 10
    kbLbl.Font              = Enum.Font.GothamBold
    kbLbl.TextColor3        = T.Dim
    kbLbl.TextXAlignment    = Enum.TextXAlignment.Center
    kbLbl.ZIndex            = 3
    kbLbl.Parent            = card
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 28, 0, 16)
    track.Position         = UDim2.new(1, -32, 0.5, -6)
    track.BackgroundColor3 = T.TrackOff
    track.BorderSizePixel  = 0
    track.ZIndex           = 2
    track.Parent           = card
    Corner(track, 6)
    local tStroke = Stroke(track, T.Border, 1)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 12, 0, 12)
    knob.Position         = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = T.KnobOff
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 3
    knob.Parent           = track
    Corner(knob, 4)
    local _cardHovered = false
    local function _cardSetHover(h)
        if h == _cardHovered then return end
        _cardHovered = h
        Tween(card, F, {BackgroundColor3 = h and T.CardHover or T.Card})
    end
    card.MouseEnter:Connect(function() _cardSetHover(true) end)
    card.MouseLeave:Connect(function() _cardSetHover(false) end)
    local btn = Instance.new("Frame")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.ZIndex              = 4
    btn.Active              = true
    btn.Parent              = card
    btn.MouseEnter:Connect(function() _cardSetHover(true) end)
    btn.MouseLeave:Connect(function() _cardSetHover(false) end)
    local keybindEntry = { keyCode = nil }
    do
        local _saved = Config and Config.keybinds and Config.keybinds[name]
        if type(_saved) == "string" then
            local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
            if _ok and _kc then
                keybindEntry.keyCode = _kc
                kbLbl.Text       = "[" .. _saved .. "]"
                kbLbl.TextColor3 = T.Dim
            end
        end
    end
    local function applyVisual(s)
        if s then
            local _acA = _G._FH_AccentA or T.TrackOn
            local _acB = _G._FH_AccentB or T.TrackOn
            knob.Size             = UDim2.new(0, 12, 0, 12)
            knob.Position         = UDim2.new(0, 14, 0.5, -6)
            knob.BackgroundColor3 = T.KnobOn
            track.BackgroundColor3 = _acA
            tStroke.Color         = _acB

            local _tg = track:FindFirstChildOfClass("UIGradient")
            if not _tg then
                _tg = Instance.new("UIGradient")
                _tg.Parent = track
                table.insert(_G._FH_ThemeFills, _tg)
            end
            if _FH_BuildThemeSequence then _tg.Color = _FH_BuildThemeSequence() end
            bar.BackgroundColor3  = _acA

            local _bg2 = bar:FindFirstChildOfClass("UIGradient")
            if not _bg2 then
                _bg2 = Instance.new("UIGradient")
                _bg2.Rotation = 90
                _bg2.Parent = bar
                table.insert(_G._FH_ThemeFills, _bg2)
            end
            if _FH_BuildThemeSequence then _bg2.Color = _FH_BuildThemeSequence() end
        else
            knob.Size             = UDim2.new(0, 12, 0, 12)
            knob.Position         = UDim2.new(0, 2, 0.5, -6)
            knob.BackgroundColor3 = T.KnobOff
            track.BackgroundColor3 = T.TrackOff
            local _tg = track:FindFirstChildOfClass("UIGradient")
            if _tg then _tg:Destroy() end
            tStroke.Color         = T.Border
            bar.BackgroundColor3  = T.TrackOff
            local _bg2 = bar:FindFirstChildOfClass("UIGradient")
            if _bg2 then _bg2:Destroy() end
        end
    end
    local function doToggle()
        state = not state
        if state then
            local _acA = _G._FH_AccentA or T.TrackOn
            local _acB = _G._FH_AccentB or T.TrackOn
            Tween(knob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
            task.delay(0.06, function()
                Tween(knob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
                Tween(knob,    M, {BackgroundColor3 = T.KnobOn})
                Tween(track,   M, {BackgroundColor3 = _acA})
                Tween(tStroke, M, {Color = _acB})
                Tween(bar,     M, {BackgroundColor3 = _acA})

                pcall(function()
                    local _tg = track:FindFirstChildOfClass("UIGradient")
                    if not _tg then _tg = Instance.new("UIGradient"); _tg.Parent = track; table.insert(_G._FH_ThemeFills, _tg) end
                    if _FH_BuildThemeSequence then _tg.Color = _FH_BuildThemeSequence() end
                    local _bg2 = bar:FindFirstChildOfClass("UIGradient")
                    if not _bg2 then _bg2 = Instance.new("UIGradient"); _bg2.Rotation = 90; _bg2.Parent = bar; table.insert(_G._FH_ThemeFills, _bg2) end
                    if _FH_BuildThemeSequence then _bg2.Color = _FH_BuildThemeSequence() end
                end)
            end)
        else
            Tween(knob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(knob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(knob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(track,   M, {BackgroundColor3 = T.TrackOff})
                Tween(tStroke, M, {Color = T.Border})
                Tween(bar,     M, {BackgroundColor3 = T.TrackOff})
                pcall(function()
                    local _tg = track:FindFirstChildOfClass("UIGradient")
                    if _tg then _tg:Destroy() end
                    local _bg2 = bar:FindFirstChildOfClass("UIGradient")
                    if _bg2 then _bg2:Destroy() end
                end)
            end)
        end
        if cb then pcall(cb, state) end
        Config.toggles[name] = state
        pcall(FH_SaveConfig)

            pcall(ShowToggleNotification, name, state)
    end
    local _btnTouchActive = false
    local _btnTouchStart  = nil
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            _btnTouchActive = true
            _btnTouchStart  = inp.Position
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) and _btnTouchActive then
            _btnTouchActive = false

            if _G._FH_MAIN_DRAG or _G._FH_SPAM_DRAG or _G._FH_MP_DRAG then
                _btnTouchStart = nil
                return
            end
            if _btnTouchStart and (inp.Position - _btnTouchStart).Magnitude < 20 then
                doToggle()
            end
            _btnTouchStart = nil
        end
    end)
    local kb2Debounce = false
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if kb2Debounce then return end
        kb2Debounce = true
        task.delay(0.2, function() kb2Debounce = false end)
        if keybindBindingTarget then
            local prev = keybindBindingTarget
            keybindBindingTarget = nil
            if prev.kbLbl == kbLbl then
                kbLbl.Text      = keybindEntry.keyCode and ("[".. keybindEntry.keyCode.Name .. "]") or ""
kbLbl.TextColor3 = T.Dim
                return
            else
                prev.kbLbl.Text      = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
            end
        end
        kbLbl.Text           = "(...)"
kbLbl.TextColor3     = T.White
        keybindBindingTarget = { entry = keybindEntry, kbLbl = kbLbl, mode = "assign"}
    end)
    table.insert(keybindEntries, { entry = keybindEntry, fire = (actionFn or doToggle), kbLbl = kbLbl })
    do
        local _themeFn = function()
            if state then applyVisual(true) end
        end
        table.insert(_G._FH_ThemeCallbacks, _themeFn)
        pcall(_themeFn)
    end
    configRegistry[name] = {
        getState   = function() return state end,
        getKeyCode = function() return keybindEntry.keyCode end,
        setKeyCode = function(kc)
            keybindEntry.keyCode = kc
            if kc then
                kbLbl.Text       = "[".. kc.Name .. "]"
kbLbl.TextColor3 = T.Dim
                Config.keybinds[name] = kc.Name
            else
                kbLbl.Text = ""
kbLbl.TextColor3 = T.Dim
Config.keybinds[name] = nil
            end
            pcall(FH_SaveConfig)
        end,
        doToggle   = doToggle,
        kbLbl      = kbLbl,
        kbEntry    = keybindEntry,
        setEnabled = function(v)
            local wasState = state
            state = v
            applyVisual(v)
            Config.toggles[name] = v

            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
            if cb then pcall(cb, v) end
        end,
    }
end
UserInputService.InputBegan:Connect(function(inp, gpe)
    if keybindBindingTarget then
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            local kc = inp.KeyCode
            if kc == Enum.KeyCode.Escape then
                local _tgt = keybindBindingTarget
                if _tgt.entry.keyCode then
                    _tgt.kbLbl.Text      = "[".. _tgt.entry.keyCode.Name .. "]"
_tgt.kbLbl.TextColor3 = T.Dim
                else
                    _tgt.kbLbl.Text = ""
                    end
                if _tgt.onSet and _tgt.entry.keyCode then _tgt.onSet()
                elseif _tgt.onClear then _tgt.onClear() end
                keybindBindingTarget = nil
            elseif kc == Enum.KeyCode.Backspace then
                local _tgt = keybindBindingTarget
                local clearedEntry = _tgt.entry
                clearedEntry.keyCode                  = nil
                _tgt.kbLbl.Text       = ""
_tgt.kbLbl.TextColor3 = T.Dim
                if _tgt.onClear then _tgt.onClear() end
                for tName, reg in pairs(configRegistry) do
                    if reg.getKeyCode and reg.getKeyCode() == nil then
                        Config.keybinds[tName] = nil
                    end
                end
                if clearedEntry == SP.entry then
                    Config.mini = Config.mini or {}
                    Config.mini.sp_keybind = nil
                end
                pcall(FH_SaveConfig)
                keybindBindingTarget = nil
            else
                local _tgt = keybindBindingTarget
                local assignedEntry = _tgt.entry
                assignedEntry.keyCode                 = kc
                _tgt.kbLbl.Text       = "[".. kc.Name .. "]"
_tgt.kbLbl.TextColor3 = T.Dim
                if _tgt.onSet then _tgt.onSet() end

                local matched = 0
                for tName, reg in pairs(configRegistry) do
                    local sameEntry = false
                    if reg.getKeyCode then
                        local ok, regKc = pcall(reg.getKeyCode)
                        if ok and regKc == kc then sameEntry = true end
                    end
                    if sameEntry then
                        Config.keybinds[tName] = kc.Name
                        if reg.setKeyCode then pcall(reg.setKeyCode, kc) end
                        matched = matched + 1
                    end
                end
                if assignedEntry == SP.entry then
                    Config.mini = Config.mini or {}
                    Config.mini.sp_keybind = kc.Name
                end
                pcall(FH_SaveConfig)
                pcall(function()
                    ShowToggleNotification("Keybind ["..kc.Name.."] bound ("..matched..")", true)
                end)
                keybindBindingTarget = nil
            end
            return
        elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local prev = keybindBindingTarget
            keybindBindingTarget = nil
            if prev.entry.keyCode then
                prev.kbLbl.Text      = "[".. prev.entry.keyCode.Name .. "]"
prev.kbLbl.TextColor3 = T.Dim
            else
                prev.kbLbl.Text = ""
                end
        end
        return
    end
    if gpe then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        local _fired = {}
        for _, binding in ipairs(keybindEntries) do
            if binding and binding.entry and binding.entry.keyCode
               and inp.KeyCode == binding.entry.keyCode and binding.fire
               and not _fired[binding.fire] then
                _fired[binding.fire] = true
                pcall(binding.fire)
            end
        end
    end
end)
CreateSection = function(parent, title)
    local f = Instance.new("Frame")
    f.Size                = UDim2.new(1, -16, 0, 30)
    f.BackgroundTransparency = 1
    f.Parent              = parent
    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = T.Border
    line.BorderSizePixel  = 0
    line.Parent           = f
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, #title * 7 + 18, 0, 20)
    pill.Position         = UDim2.new(0, 10, 0.5, -10)
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 2
    pill.Parent           = f
    local lbl = Label(pill, title, 10, T.Dim, Enum.Font.GothamBold)
    lbl.Size             = UDim2.new(1, 0, 1, 0)
    lbl.TextXAlignment   = Enum.TextXAlignment.Center
    lbl.ZIndex           = 3
end
local CreateButton
CreateButton = function(parent, name, desc, cb)
    local hasDesc = false
    desc = nil
    local cardH   = isMobile and (hasDesc and 48 or 32) or (hasDesc and 42 or 26)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -16, 0, cardH)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel  = 0
    card.Parent           = parent
    Corner(card, 8)
    local cStroke = Stroke(card, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(cStroke)
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 2)
    local nameY  = hasDesc and 10 or (cardH/2 - 8)
    local nameLbl = Label(card, name, 13, T.White, Enum.Font.GothamMedium)
    nameLbl.Size     = UDim2.new(1, -100, 0, 16)
    nameLbl.Position = UDim2.new(0, 14, 0, nameY)
    nameLbl.ZIndex   = 2
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    if hasDesc then
        local descLbl = Label(card, desc, 11, T.Dim, Enum.Font.Gotham)
        descLbl.Size     = UDim2.new(1, -100, 0, 14)
        descLbl.Position = UDim2.new(0, 14, 0, nameY + 18)
        descLbl.ZIndex   = 2
        descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local kbLbl = Instance.new("TextLabel")
    kbLbl.Size                  = UDim2.new(0, 36, 0, 16)
    kbLbl.Position              = UDim2.new(1, -92, 0.5, -8)
    kbLbl.BackgroundTransparency = 1
    kbLbl.Text                  = ""
kbLbl.TextSize              = 10
    kbLbl.Font                  = Enum.Font.GothamBold
    kbLbl.TextColor3            = T.Dim
    kbLbl.TextXAlignment        = Enum.TextXAlignment.Center
    kbLbl.ZIndex                = 3
    kbLbl.Parent                = card
    local runLbl = Instance.new("TextLabel")
    runLbl.Size                  = UDim2.new(0, 28, 0, 14)
    runLbl.Position              = UDim2.new(1, -36, 0.5, -7)
    runLbl.BackgroundColor3      = Color3.fromRGB(38, 38, 38)
    runLbl.BorderSizePixel       = 0
    runLbl.Text                  = "RUN"
runLbl.TextSize              = 9
    runLbl.Font                  = Enum.Font.GothamBold
    runLbl.TextColor3            = T.White
    runLbl.TextXAlignment        = Enum.TextXAlignment.Center
    runLbl.ZIndex                = 3
    runLbl.Parent                = card
    Corner(runLbl, 6)
    Stroke(runLbl, T.Border, 1)
    local _cardHovered = false
    local function _cardSetHover(h)
        if h == _cardHovered then return end
        _cardHovered = h
        Tween(card, F, {BackgroundColor3 = h and T.CardHover or T.Card})
    end
    card.MouseEnter:Connect(function() _cardSetHover(true) end)
    card.MouseLeave:Connect(function() _cardSetHover(false) end)
    local btn = Instance.new("Frame")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.ZIndex              = 4
    btn.Active              = true
    btn.Parent              = card
    btn.MouseEnter:Connect(function() _cardSetHover(true) end)
    btn.MouseLeave:Connect(function() _cardSetHover(false) end)
    local keybindEntry = { keyCode = nil }
    do
        local _saved = Config and Config.keybinds and Config.keybinds[name]
        if type(_saved) == "string" then
            local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
            if _ok and _kc then
                keybindEntry.keyCode = _kc
                kbLbl.Text       = "[" .. _saved .. "]"
                kbLbl.TextColor3 = T.Dim
            end
        end
    end
    local function fireButton()
        Tween(bar,    F, {BackgroundColor3 = T.TrackOn})
        Tween(runLbl, F, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
        task.spawn(function()
            pcall(cb)
        end)
        task.delay(0.35, function()
            Tween(bar,    M, {BackgroundColor3 = T.TrackOff})
            Tween(runLbl, M, {BackgroundColor3 = Color3.fromRGB(38, 38, 38)})
        end)
    end
    local debounce = false
    local _actTouchStart = nil
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if debounce then return end
            debounce = true
            fireButton()
            task.delay(0.4, function() debounce = false end)
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _actTouchStart = inp.Position
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == kbLbl then
                    kbLbl.Text       = keybindEntry.keyCode and ("[".. keybindEntry.keyCode.Name .. "]") or ""
kbLbl.TextColor3 = T.Dim
                    return
                else
                    prev.kbLbl.Text       = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
                end
            end
            kbLbl.Text           = "(...)"
kbLbl.TextColor3     = T.White
            keybindBindingTarget = { entry = keybindEntry, kbLbl = kbLbl, mode = "assign"}
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _actTouchStart then
            local mag = (inp.Position - _actTouchStart).Magnitude
            local _start = _actTouchStart
            _actTouchStart = nil

            if _G._FH_MAIN_DRAG or _G._FH_SPAM_DRAG or _G._FH_MP_DRAG then
                return
            end
            if mag < 20 then
                if debounce then return end
                debounce = true
                fireButton()
                task.delay(0.4, function() debounce = false end)
            end
        end
    end)
    table.insert(keybindEntries, { entry = keybindEntry, fire = fireButton, kbLbl = kbLbl })
    configRegistry[name] = {
        getState   = function() return false end,
        getKeyCode = function() return keybindEntry.keyCode end,
        setKeyCode = function(kc)
            keybindEntry.keyCode = kc
            if kc then
                kbLbl.Text       = "[".. kc.Name .. "]"
kbLbl.TextColor3 = T.Dim
                Config.keybinds[name] = kc.Name
            else
                kbLbl.Text = ""
kbLbl.TextColor3 = T.Dim
                Config.keybinds[name] = nil
            end
            pcall(FH_SaveConfig)
        end,
        doToggle   = fireButton,
        kbLbl      = kbLbl,
        kbEntry    = keybindEntry,
    }
end
MakeScroll = function(parent)
    local s = Instance.new("ScrollingFrame")
    s.Size                  = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = 3
    s.ScrollBarImageColor3  = Color3.fromRGB(75, 75, 75)
    s.CanvasSize            = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    s.ScrollingDirection    = Enum.ScrollingDirection.Y
    s.ZIndex                = 2
    s.Parent                = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection      = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding            = UDim.new(0, 6)
    layout.Parent             = s
    Padding(s, 10, 10, 8, 8)
    return s
end
Tabs      = {}
ActiveTab = nil
TabSwiping = false
TabIndex = function(tab)
    for i, t in ipairs(Tabs) do
        if t == tab then return i end
    end
    return 0
end
SLIDE_IN  = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
SLIDE_OUT = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
ActivateTab = function(tab)
    if ActiveTab == tab then return end
    if TabSwiping then return end
    local oldTab = ActiveTab
    ActiveTab = tab
    if oldTab then
        Tween(oldTab.lbl, F, {TextColor3 = Color3.fromRGB(210, 225, 255)})
        Tween(oldTab.btn, F, {BackgroundColor3 = Color3.fromRGB(23, 26, 36)})
    end
    Tween(tab.lbl, F, {TextColor3 = Color3.fromRGB(245, 248, 255)})
    Tween(tab.btn, F, {BackgroundColor3 = Color3.fromRGB(70, 80, 110)})
    if oldTab then
        TabSwiping = true
        local goingRight = (TabIndex(tab) > TabIndex(oldTab))
        tab.page.Position = goingRight and UDim2.new(1, 0, 0, 0) or UDim2.new(-1, 0, 0, 0)
        tab.page.Visible  = true
        local exitPos = goingRight and UDim2.new(-1, 0, 0, 0) or UDim2.new(1, 0, 0, 0)
        Tween(oldTab.page, SLIDE_OUT, {Position = exitPos})
        local tw = TweenService:Create(tab.page, SLIDE_IN, {Position = UDim2.new(0, 0, 0, 0)})
        tw:Play()
        tw.Completed:Connect(function()
            oldTab.page.Visible  = false
            oldTab.page.Position = UDim2.new(0, 0, 0, 0)
            TabSwiping = false
        end)
    else
        tab.page.Position = UDim2.new(0, 0, 0, 0)
        tab.page.Visible  = true
    end
end
TAB_W = math.floor(WIN_W / 4)
CreateTab = function(name)
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(0.25, -4, 1, -6)
    btn.Position            = UDim2.new(0, 2, 0, 3)
    btn.BackgroundColor3    = Color3.fromRGB(23, 26, 36)
    btn.BackgroundTransparency = 0
    btn.AutoButtonColor     = false
    btn.Text                = ""
    btn.ZIndex              = 5
    btn.Parent              = TabBar
    Corner(btn, 10)
    local nameLbl = Label(btn, name, isMobile and 11 or 10, Color3.fromRGB(210, 225, 255), Enum.Font.GothamBold)
    nameLbl.Size            = UDim2.new(1, -2, 1, 0)
    nameLbl.Position        = UDim2.new(0, 1, 0, 0)
    nameLbl.TextXAlignment  = Enum.TextXAlignment.Center
    nameLbl.TextWrapped     = true
    nameLbl.ZIndex          = 6
    nameLbl.TextScaled      = false
    local nameSC = Instance.new("UITextSizeConstraint")
    nameSC.MaxTextSize = isMobile and 8 or 11
    nameSC.MinTextSize = 5
    nameSC.Parent      = nameLbl
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(0, 0, 0, 0)
    indicator.Visible          = false
    indicator.Parent           = btn
    local page = Instance.new("Frame")
    page.Size                = UDim2.new(1, 0, 1, 0)
    page.Position            = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.Visible             = false
    page.ClipsDescendants    = true
    page.ZIndex              = 2
    page.Parent              = ContentArea
    local scroll = MakeScroll(page)
    local tab = { btn = btn, lbl = nameLbl, indicator = indicator, page = page, scroll = scroll }
    btn.MouseButton1Click:Connect(function() ActivateTab(tab) end)
    table.insert(Tabs, tab)
    return tab
end
CombatTab   = CreateTab(isMobile and "MAIN" or "Faded [MAIN]")
VisualTab   = CreateTab(isMobile and "ESP" or "Visuals [ESP]")
PlayerTab   = CreateTab(isMobile and "PLAYER" or "My User [PLAYER]")
MiscTab     = CreateTab(isMobile and "MISC" or "Other [MISC]")

CreateSection(CombatTab.scroll, "AUTO STEALERS")
do
    local v1BestEnabled = false
    local v1NearestEnabled = false
    local v1PriorityEnabled = false
    local v1Running = false
    local _agInRange = false
    local V1_RED_PHASE        = 1.5
    local V1_PROXIMITY_RADIUS = 10
    local v1Progress = 0
    local v1HasTarget = false
    local v1TargetName = ""
    local v1TargetRate = ""
    task.defer(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "FH_AutoGrabProgress"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

        local _agBarDefaultPos = UDim2.new(0.5, 0, 1, -80)
        local _agBarSavedPos = (Config.sliders and Config.sliders.ag_bar_pos)
        local _agBarInitPos = _agBarDefaultPos
        if type(_agBarSavedPos) == "table" then
            pcall(function()
                _agBarInitPos = UDim2.new(
                    _agBarSavedPos.xs or 0.5, _agBarSavedPos.xo or 0,
                    _agBarSavedPos.ys or 1,   _agBarSavedPos.yo or -80
                )
            end)
        end

        local frame = Instance.new("Frame")
        frame.AnchorPoint            = Vector2.new(0.5, 1)
        frame.Position               = _agBarInitPos
        frame.Size                   = UDim2.new(0, 200, 0, 50)
        frame.BackgroundColor3       = Color3.fromRGB(18, 18, 22)
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel        = 0
        frame.Visible                = false
        frame.Parent                 = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local fs = Instance.new("UIStroke", frame)
        fs.Color        = Color3.fromRGB(255, 255, 255)
        fs.Transparency = 0.55
        fs.Thickness    = 1

        do
            local dragging = false
            local dragStartPos = nil
            local frameStartPos = nil


            local function onDragMoved(inputPos)
                if not dragging then return end
                local delta = inputPos - dragStartPos
                local vp = gui.AbsoluteSize
                frame.Position = UDim2.new(
                    frameStartPos.X.Scale + delta.X / vp.X,
                    frameStartPos.X.Offset,
                    frameStartPos.Y.Scale + delta.Y / vp.Y,
                    frameStartPos.Y.Offset
                )
            end

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    onDragMoved(Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
        end

        local title = Instance.new("TextLabel")
        title.AnchorPoint            = Vector2.new(0.5, 0)
        title.Position               = UDim2.new(0.5, 0, 0, 4)
        title.Size                   = UDim2.new(1, -12, 0, 14)
        title.BackgroundTransparency = 1
        title.Text                   = "Auto Grab (searching)"
        title.TextSize               = 11
        title.Font                   = Enum.Font.GothamBold
        title.TextColor3             = Color3.fromRGB(245, 245, 245)
        title.TextXAlignment         = Enum.TextXAlignment.Center
        title.TextYAlignment         = Enum.TextYAlignment.Center
        title.TextTruncate           = Enum.TextTruncate.AtEnd
        title.Parent                 = frame

        local div = Instance.new("Frame")
        div.AnchorPoint      = Vector2.new(0.5, 0)
        div.Position         = UDim2.new(0.5, 0, 0, 21)
        div.Size             = UDim2.new(1, -12, 0, 1)
        div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        div.BackgroundTransparency = 0.85
        div.BorderSizePixel  = 0
        div.Parent           = frame

        local barH = 18
        local track = Instance.new("Frame")
        track.AnchorPoint            = Vector2.new(0.5, 1)
        track.Position               = UDim2.new(0.5, 0, 1, -6)
        track.Size                   = UDim2.new(1, -12, 0, barH)
        track.BackgroundColor3       = Color3.fromRGB(30, 30, 36)
        track.BackgroundTransparency = 0.05
        track.BorderSizePixel        = 0
        track.ClipsDescendants       = true
        track.Parent                 = frame
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)
        local trackStroke = Instance.new("UIStroke", track)
        trackStroke.Color        = Color3.fromRGB(255, 255, 255)
        trackStroke.Transparency = 0.75
        trackStroke.Thickness    = 1

        local fill = Instance.new("Frame")
        fill.AnchorPoint            = Vector2.new(0, 0.5)
        fill.Position               = UDim2.new(0, 0, 0.5, 0)
        fill.Size                   = UDim2.new(0, 0, 1, 0)

        fill.BackgroundColor3       = _G._FH_AccentA or Color3.fromRGB(60, 210, 100)
        fill.BorderSizePixel        = 0
        fill.ZIndex                 = 1
        fill.Parent                 = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
        local fillGrad = Instance.new("UIGradient", fill)

        fillGrad.Color    = _FH_BuildThemeSequence and _FH_BuildThemeSequence()
                            or ColorSequence.new(Color3.fromRGB(120, 200, 255))
        fillGrad.Rotation = 0
        _G._FH_ThemeFills = _G._FH_ThemeFills or {}
        table.insert(_G._FH_ThemeFills, fillGrad)

        _G._FH_ThemeCallbacks = _G._FH_ThemeCallbacks or {}
        do
            local _themeFn = function()
                pcall(function()
                    if fill and fill.Parent then
                        fill.BackgroundColor3 = _G._FH_AccentA or Color3.fromRGB(60, 210, 100)
                    end
                end)
            end
            table.insert(_G._FH_ThemeCallbacks, _themeFn)
            pcall(_themeFn)
        end

        local pctLbl = Instance.new("TextLabel")
        pctLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
        pctLbl.Position               = UDim2.new(0.5, 0, 0.5, 0)
        pctLbl.Size                   = UDim2.new(1, -8, 1, 0)
        pctLbl.BackgroundTransparency = 1
        pctLbl.Text                   = "0%"
        pctLbl.TextSize               = 10
        pctLbl.Font                   = Enum.Font.GothamBold
        pctLbl.TextColor3             = Color3.fromRGB(245, 245, 245)
        pctLbl.TextStrokeTransparency = 0.5
        pctLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        pctLbl.ZIndex                 = 3
        pctLbl.Parent                 = track
        _G._FH_HideAutoGrabBar = _G._FH_HideAutoGrabBar or false
        local fillTween = nil
        local lastTweenP = -1
        local _agBarTimer = 0
        RunService.Heartbeat:Connect(function(dt)
            _agBarTimer = _agBarTimer + dt
            if _agBarTimer < 0.033 then return end
            _agBarTimer = 0
            local on = (v1BestEnabled or v1NearestEnabled or v1PriorityEnabled) and not _G._FH_HideAutoGrabBar
            frame.Visible = on
            if not on then return end
            local p = math.clamp(v1Progress or 0, 0, 1)
            if math.abs(p - lastTweenP) > 0.005 then
                lastTweenP = p
                if fillTween then pcall(function() fillTween:Cancel() end) end
                fillTween = TweenService:Create(
                    fill,
                    TweenInfo.new(0.12, Enum.EasingStyle.Linear),
                    { Size = UDim2.new(p, 0, 1, 0) }
                )
                fillTween:Play()
            end
            if p >= 0.5 then
                fill.BackgroundColor3 = Color3.fromRGB(60, 230, 100)
            else
                fill.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
            end
            pctLbl.Text = string.format("%d%%", math.floor(p * 100 + 0.5))

            if p >= 0.55 then
                pctLbl.TextColor3             = Color3.fromRGB(20, 20, 20)
                pctLbl.TextStrokeTransparency = 0.85
            else
                pctLbl.TextColor3             = Color3.fromRGB(245, 245, 245)
                pctLbl.TextStrokeTransparency = 0.5
            end
            if v1HasTarget and v1TargetName ~= "" then
                if v1TargetRate ~= "" then
                    title.Text = v1TargetName .. " - " .. v1TargetRate
                else
                    title.Text = v1TargetName
                end
            else
                local nearest, nearestDist = _FH_AG_GetNearestBrainrot()
                if nearest then
                    local nm = tostring(nearest.displayName or "")
                    if nm == "" then nm = "Brainrot" end
                    local rate = tostring(nearest.genText or "")
                    if rate:sub(1, 1) == "$" then rate = rate:sub(2) end
                    if rate ~= "" then
                        title.Text = string.format("Nearest: %s (%dm) - %s", nm, math.floor(nearestDist or 0 + 0.5), rate)
                    else
                        title.Text = string.format("Nearest: %s (%dm)", nm, math.floor(nearestDist or 0 + 0.5))
                    end
                else
                    title.Text = "NO ANIMALS NEARBY"
                end
            end
        end)
    end)
    local function v1PickTarget()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, math.huge end
        if v1PriorityEnabled then
            local pset = _G._FH_PRIORITY_STEAL
            if not (pset and next(pset)) then return nil, math.huge end
            local best, bestDist = nil, math.huge
            for _, brainrot in ipairs(_FH_AG_CachedBrainrots) do
                if brainrot.displayName and pset[brainrot.displayName] then
                    local d = (brainrot.pos - hrp.Position).Magnitude
                    if d < bestDist then bestDist = d; best = brainrot end
                end
            end
            return best, bestDist
        end
        if v1BestEnabled then
            local best = _FH_AG_CachedBrainrots[1]
            if best then
                return best, (best.pos - hrp.Position).Magnitude
            end
        end
        if v1NearestEnabled then
            return _FH_AG_GetNearestBrainrot()
        end
        return nil, math.huge
    end

    local AG_HOLD_MIN     = 1.3
    local AG_HOLD_MAX     = 2.6
    local AG_ENTRY_DELAY  = 0.3
    local AG_STEAL_RANGE  = 10
    local AG_PRIME_RANGE  = 30
    local AG_POTION_RANGE = 6
    local AG_COOLDOWN     = 0.05

    local _agStealCache = {}

    local function _agBuildCallbacks(prompt)
        if _agStealCache[prompt] then return end
        local data = { hold = {}, trig = {}, ready = true }
        pcall(function()
            local conns = getconnections(prompt.PromptButtonHoldBegan)
            for _, c in ipairs(conns) do
                if type(c.Function) == "function" then table.insert(data.hold, c.Function) end
            end
        end)
        pcall(function()
            local conns = getconnections(prompt.Triggered)
            for _, c in ipairs(conns) do
                if type(c.Function) == "function" then table.insert(data.trig, c.Function) end
            end
        end)
        if #data.hold > 0 or #data.trig > 0 then
            _agStealCache[prompt] = data
        end
    end

    local function _agDistTo(target)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not target or not target.pos then return math.huge end
        return (hrp.Position - target.pos).Magnitude
    end

    local function v1Loop()
        if v1Running then return end
        v1Running = true
        while v1BestEnabled or v1NearestEnabled or v1PriorityEnabled do
            local target = v1PickTarget()
            local prompt = target and target.prompt
            if not (target and prompt and prompt.Parent and _agDistTo(target) <= AG_PRIME_RANGE) then
                _agInRange = false
                task.wait(0.1)
                continue
            end

            _agBuildCallbacks(prompt)
            local data = _agStealCache[prompt]
            if not data or not data.ready then
                task.wait(0.05)
                continue
            end
            data.ready = false

            v1HasTarget   = true
            v1TargetName  = tostring(target.displayName or "")
            local rate    = tostring(target.genText or "")
            if rate:sub(1, 1) == "$" then rate = rate:sub(2) end
            v1TargetRate  = rate
            v1Progress    = 0

            local startT = tick()

            for _, fn in ipairs(data.hold) do task.spawn(fn) end

            while tick() - startT < AG_HOLD_MIN do
                if not (v1BestEnabled or v1NearestEnabled or v1PriorityEnabled) then break end
                v1Progress = math.min((tick() - startT) / AG_HOLD_MAX, 0.5)
                RunService.RenderStepped:Wait()
            end

            local alreadyInRange = _agDistTo(target) <= AG_STEAL_RANGE
            _agInRange = alreadyInRange
            local fired = false
            local potionFired = false
            while tick() - startT < AG_HOLD_MAX do
                if not (v1BestEnabled or v1NearestEnabled or v1PriorityEnabled) then break end
                if not prompt.Parent then break end

                local inRange = _agDistTo(target) <= AG_STEAL_RANGE
                _agInRange = inRange
                if inRange then
                    if not alreadyInRange then task.wait(AG_ENTRY_DELAY) end
                    if V3.potionOn and not potionFired
                        and _agDistTo(target) <= AG_POTION_RANGE
                        and _FH_IsPlayerInEnemyPlot() then
                        potionFired = true
                        pcall(_activateGiantPotion)
                        task.wait(0.05)
                    end
                    for _, fn in ipairs(data.trig) do task.spawn(fn) end
                    fired = true
                    break
                end
                v1Progress = (tick() - startT) / AG_HOLD_MAX
                RunService.RenderStepped:Wait()
            end

            v1Progress    = 1
            task.wait(AG_COOLDOWN)
            v1Progress    = 0
            v1HasTarget   = false
            v1TargetName  = ""
            v1TargetRate  = ""
            _agInRange    = false
            data.ready    = true
        end
        _agInRange = false
        v1Progress    = 0
        v1HasTarget   = false
        v1TargetName  = ""
        v1TargetRate  = ""
        v1Running     = false
    end
    local function _disableOther(name)
        local reg = configRegistry[name]
        if reg and reg.getState and reg.getState() and reg.setEnabled then
            pcall(reg.setEnabled, false)
        end
    end
    ToggleHandlers.auto_grab_best = function(state)
        v1BestEnabled = state and true or false
        if state then
            v1NearestEnabled  = false
            v1PriorityEnabled = false
            _disableOther("Auto Grab Nearest")
            _disableOther("Steal Priority")
            task.spawn(v1Loop)
        end
    end
    ToggleHandlers.auto_grab_nearest = function(state)
        v1NearestEnabled = state and true or false
        if state then
            v1BestEnabled     = false
            v1PriorityEnabled = false
            _disableOther("Auto Grab Best")
            _disableOther("Steal Priority")
            task.spawn(v1Loop)
        end
    end
    ToggleHandlers.steal_priority = function(state)
        v1PriorityEnabled = state and true or false
        if state then
            v1BestEnabled    = false
            v1NearestEnabled = false
            _disableOther("Auto Grab Best")
            _disableOther("Auto Grab Nearest")
            task.spawn(v1Loop)
        end
    end
    CreateToggle(CombatTab.scroll, "Auto Grab Best",     "Grabs the highest gen brainrot in range.",  function(v) ToggleHandlers.auto_grab_best(v) end)
    CreateToggle(CombatTab.scroll, "Auto Grab Nearest",  "Grabs the nearest brainrot in range.",      function(v) ToggleHandlers.auto_grab_nearest(v) end)
    CreateToggle(CombatTab.scroll, "Steal Priority",     "Auto-grabs only whitelisted brainrots (Priority Steal).", function(v) ToggleHandlers.steal_priority(v) end)
end

CreateSection(CombatTab.scroll, "MAIN")
CreateToggle(CombatTab.scroll, "Allow Base Panel",   "Toggle open your base from anywhere",       function(v) AB.setAllowBasePanelVisible(v) end, function()
    if AB and AB.fireAllow then pcall(AB.fireAllow) end
end)
CreateToggle(CombatTab.scroll, "Unlock Base Panel",  "Unlock a nearest player's base",            function(v) UB.setUnlockBasePanelVisible(v) end, function()
    if UB and UB.floors and UB.floors[1] and UB.triggerFloor then
        task.spawn(UB.triggerFloor, UB.floors[1].yLevel, UB.floors[1].maxY)
    end
end)
CreateToggle(CombatTab.scroll, "Potion Speed", "Auto-applies 34 speed when giant potion is active on your character", function(v)
    if _G._FH_PotionSpeedConn then _G._FH_PotionSpeedConn:Disconnect(); _G._FH_PotionSpeedConn = nil end
    if _G._FH_PotionSpeedCharConn then _G._FH_PotionSpeedCharConn:Disconnect(); _G._FH_PotionSpeedCharConn = nil end
    if not v then
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and _G._FH_PotionSpeedActive then
            hrp.Velocity = _G._FH_PotionSpeedBaseVelocity or hrp.Velocity
        end
        _G._FH_PotionSpeedActive = false
        _G._FH_PotionSpeedBaseVelocity = nil
        return
    end
    local SCALE_THRESHOLD = 1.05
    _G._FH_PotionSpeedActive = false
    local function setupChar(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            _G._FH_PotionSpeedBaseVelocity = hrp.Velocity
        end
        _G._FH_PotionSpeedActive = false
    end
    if Player.Character then setupChar(Player.Character) end
    _G._FH_PotionSpeedCharConn = Player.CharacterAdded:Connect(function(char)
        _G._FH_PotionSpeedActive = false
        setupChar(char)
    end)
    _G._FH_PotionSpeedConn = RunService.Heartbeat:Connect(function()
        if not (configRegistry["Potion Speed"] and configRegistry["Potion Speed"].getState()) then return end
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local phum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hrp or not phum then return end
        local bodyHeight = phum:FindFirstChild("BodyHeightScale")
        local isGiant = bodyHeight and bodyHeight:IsA("NumberValue") and bodyHeight.Value > SCALE_THRESHOLD
        if isGiant and not _G._FH_PotionSpeedActive then
            _G._FH_PotionSpeedBaseVelocity = _G._FH_PotionSpeedBaseVelocity or hrp.Velocity
            _G._FH_PotionSpeedActive = true
        elseif not isGiant and _G._FH_PotionSpeedActive then
            _G._FH_PotionSpeedActive = false
            hrp.Velocity = _G._FH_PotionSpeedBaseVelocity or hrp.Velocity
            return
        end
        if isGiant then
            local md = phum.MoveDirection
            if md.Magnitude > 0 then
                local flatDir = Vector3.new(md.X, 0, md.Z).Unit
                local spd = tonumber(_G._FH_PotionSpeedValue) or 34
                hrp.Velocity = Vector3.new(flatDir.X * spd, hrp.Velocity.Y, flatDir.Z * spd)
            end
        end
    end)
end)

do
    local saved = _FH_SavedConfig and _FH_SavedConfig.sliders and tonumber(_FH_SavedConfig.sliders.potion_speed)
    _G._FH_PotionSpeedValue = saved or 34
end
CreateToggle(CombatTab.scroll, "Potion On Grab",     "Activates potion before grabbing for smoother play", function(v) V3.potionOn = v end)
CreateToggle(CombatTab.scroll, "Hide Progress Bar",  "Hide the on-screen Auto Grab progress HUD",          function(v) _G._FH_HideAutoGrabBar = v end)

do
    _G._FH_QuickPickupEnabled = false
    _G._FH_QuickPickupOrig    = {}

    local function _isInMyPlot(inst)
        if not inst or not inst.Parent then return false end
        local node = inst.Parent
        for _ = 1, 10 do
            if not node then return false end
            if node:IsA("Model") and node.Parent and node.Parent.Name == "Plots" then
                return _FH_AG_IsMyPlot(node)
            end
            node = node.Parent
        end
        return false
    end

    local _hookInstalled = false
    local function _installHook()
        if _hookInstalled then return end
        local ok, mt = pcall(getrawmetatable, game)
        if not ok or not mt then return end
        local sok = pcall(setreadonly, mt, false)
        if not sok then return end
        local oldNewIndex = mt.__newindex
        local nc = newcclosure or function(f) return f end
        mt.__newindex = nc(function(self, key, value)
            if key == "HoldDuration"
               and _G._FH_QuickPickupEnabled
               and typeof(self) == "Instance"
               and self:IsA("ProximityPrompt")
               and _isInMyPlot(self) then
                value = 0.1
            end
            return oldNewIndex(self, key, value)
        end)
        pcall(setreadonly, mt, true)
        _hookInstalled = true
    end

    CreateToggle(CombatTab.scroll, "Quick Pickup",
        "Near-instant pickup (0.1s) for brainrots in YOUR base only.",
        function(v)
            _G._FH_QuickPickupEnabled = v
            if v then
                _installHook()

                task.spawn(function()
                    for _, d in ipairs(workspace:GetDescendants()) do
                        if d:IsA("ProximityPrompt") and _isInMyPlot(d) then
                            if _G._FH_QuickPickupOrig[d] == nil then
                                _G._FH_QuickPickupOrig[d] = d.HoldDuration
                            end
                            pcall(function() d.HoldDuration = 0.1 end)
                        end
                    end
                end)
            else

                for p, orig in pairs(_G._FH_QuickPickupOrig) do
                    if p and p.Parent then pcall(function() p.HoldDuration = orig end) end
                end
                _G._FH_QuickPickupOrig = {}
            end
        end
    )
end
CreateSection(CombatTab.scroll, "PANELS")
CreateToggle(CombatTab.scroll, "Semi Steal Panel",          "Famous halfway teleport.",                      function(v) SS.setSemiStealPanelVisible(v) end, function()
    if SS and SS.SSDoSteal then pcall(SS.SSDoSteal) end
end)
CreateToggle(CombatTab.scroll, "Quick Steal Panel",         "Pick an animal & TP-steal it with custom timing.", function(v) if QS and QS.setQuickStealVisible then QS.setQuickStealVisible(v) end end, function()
    if QS and QS.execute then pcall(QS.execute) end
end)
CreateToggle(CombatTab.scroll, "Priority Steal Panel",      "Whitelist animals Quick Steal can target.",     function(v) if PS and PS.setVisible then PS.setVisible(v) end end)
CreateToggle(CombatTab.scroll, "Websling Fire Kill Panel",  "Grabs player with websling then kills player",  function(v) WSK.setWSKPanelVisible(v) end, function()
    if _G._FH_WSKFireBurst then pcall(_G._FH_WSKFireBurst) end
end)
CreateToggle(CombatTab.scroll, "Faded Actions Panel",       "Quick actions: kick self, ragdoll, rejoin.",    function(v) FA.setFadedActionsVisible(v) end)
CreateToggle(CombatTab.scroll, "Command Cooldowns Panel",   "Live cooldown tracker for admin commands.",     function(v) CD.setCDPanelVisible(v) end)
CreateSection(VisualTab.scroll, "ESP")
CreateToggle(VisualTab.scroll, "Player ESP",   "White highlight + name tag on all players.", function(v) ToggleHandlers.player_esp(v) end)
CreateToggle(VisualTab.scroll, "Base ESP",       "Highlights your base walls with animated glow.",   function(v) ToggleHandlers.base_esp(v) end)
CreateToggle(VisualTab.scroll, "Timer ESP",      "Tell's what players base timer is at.",         function(v) ToggleHandlers.base_timer_esp(v) end)
CreateToggle(VisualTab.scroll, "Allowed ESP",    "Shows Allowed/Disallowed on base friend prompts.", function(v) ToggleHandlers.allowed_esp(v) end)
CreateToggle(VisualTab.scroll, "Game Stretcher", "Stretches game for extra performance.",         function(v) ToggleHandlers.game_stretcher(v) end)
CreateToggle(VisualTab.scroll, "Clone ESP",      "Show's where all clones are.",                  function(v) ToggleHandlers.clone_esp(v) end)
CreateToggle(VisualTab.scroll, "Brainrot ESP",   "Brainrot visuals tells where a brainrot is at.", function(v) ToggleHandlers.brainrot_esp(v) end)
CreateToggle(VisualTab.scroll, "Subspace Mine ESP", "White box + owner name on enemy Subspace Tripmines.", function(v) ToggleHandlers.subspace_mine_esp(v) end)
CreateToggle(VisualTab.scroll, "Line to Base",      "Red beam from you to your plot.",                function(v) ToggleHandlers.line_to_base(v) end)
CreateSection(VisualTab.scroll, "Booster's")
CreateToggle(VisualTab.scroll, "Optimizations",  "Gives best optimizations & removes world animations.", function(v)

    _G._FH_AlwaysOnFPS = v
    if v then
        FPS.enable()
        AnimRemove.enable()

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd        = 1e9
            Lighting.Brightness    = 1
        end)

        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    pcall(function() obj.Enabled = false end)
                end
            end
        end)

        if _G._FH_OptiNewFxConn then
            pcall(function() _G._FH_OptiNewFxConn:Disconnect() end)
        end
        _G._FH_OptiNewFxConn = workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
            or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = false end)
            end
        end)

        pcall(function()
            for _, e in ipairs(Lighting:GetChildren()) do
                if e:IsA("PostEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect")
                or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("ColorCorrectionEffect") then
                    pcall(function() e.Enabled = false end)
                end
            end
        end)
    else
        if _G._FH_OptiNewFxConn then
            pcall(function() _G._FH_OptiNewFxConn:Disconnect() end)
            _G._FH_OptiNewFxConn = nil
        end
        FPS.disable()
        AnimRemove.disable()

        pcall(function()
            for _, e in ipairs(Lighting:GetChildren()) do
                if e:IsA("PostEffect") or e:IsA("BlurEffect") or e:IsA("BloomEffect")
                or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("ColorCorrectionEffect") then
                    pcall(function() e.Enabled = true end)
                end
            end
        end)

        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    pcall(function() obj.Enabled = true end)
                end
            end
        end)

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        pcall(function()
            Lighting.GlobalShadows = true
            Lighting.FogEnd        = 100000
        end)
    end
end)
CreateToggle(VisualTab.scroll, "Anti Bee", "See players through walls", function(v) ToggleHandlers.anti_bee(v) end)
do
    local xrayEnabled  = false
    local xrayAddConn  = nil
    local XRAY_AMOUNT  = 0.75
    local _xrayTouched = setmetatable({}, { __mode = "k" })
    local function _xrayShouldAffect(part)
        if not part:IsA("BasePart") then return false end
        if part.Transparency >= 1 then return false end
        if part.Name:sub(1, 3) == "FH_" then return false end
        local char = Player.Character
        if char and part:IsDescendantOf(char) then return false end
        return true
    end
    local function _xrayApplyOne(part)
        if _xrayShouldAffect(part) then
            _xrayTouched[part] = true
            part.LocalTransparencyModifier = XRAY_AMOUNT
        end
    end
    ToggleHandlers.xray = function(state)
        xrayEnabled = state
        if state then
            task.spawn(function()
                local i = 0
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if not xrayEnabled then return end
                    pcall(_xrayApplyOne, obj)
                    i = i + 1
                    if i % 400 == 0 then task.wait() end
                end
            end)
            if xrayAddConn then xrayAddConn:Disconnect() end
            xrayAddConn = workspace.DescendantAdded:Connect(function(obj)
                if not xrayEnabled then return end
                task.defer(function()
                    if xrayEnabled then pcall(_xrayApplyOne, obj) end
                end)
            end)
        else
            if xrayAddConn then xrayAddConn:Disconnect(); xrayAddConn = nil end
            for part in pairs(_xrayTouched) do
                if part and part.Parent then
                    pcall(function() part.LocalTransparencyModifier = 0 end)
                end
            end
            _xrayTouched = setmetatable({}, { __mode = "k" })
        end
    end
end
CreateToggle(VisualTab.scroll, "X-Ray", "See through walls (LocalTransparencyModifier, client-only)", function(v) ToggleHandlers.xray(v) end)
CreateSection(PlayerTab.scroll, "Player Movements")
CreateToggle(PlayerTab.scroll, "Anti Ragdoll", "No hit effects.", function(v)
    if v then AntiRagdoll.enable() else AntiRagdoll.disable() end
end)
CreateToggle(PlayerTab.scroll, "Anti Admin Panel", "Block admin command effects (jumpscare, scale, move, etc).", function(v)
    _G._FH_AntiAdminPanel = v
end)
CreateToggle(PlayerTab.scroll, "Anti Gummy Bear", "Clear gummy-bear tool block / web attributes.", function(v)
    _G._FH_AntiGummyBear = v
end)
CreateToggle(PlayerTab.scroll, "Infinite Jump",       "Infinitely Jump With No Cooldown Limit.",   function(v)
    if v then
        if not _G._FH_IJ_fallConn then
            local clampFallSpeed = 50
            _G._FH_IJ_fallConn = RunService.Heartbeat:Connect(function()
                if not (configRegistry["Infinite Jump"] and configRegistry["Infinite Jump"].getState()) then return end
                local char = Player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.Velocity
                    if vel.Y < -clampFallSpeed then
                        hrp.Velocity = Vector3.new(vel.X, -clampFallSpeed, vel.Z)
                    end
                end
            end)
        end
        if not _G._FH_IJ_conn then
            local jumpForce = 50
            _G._FH_IJ_conn = UserInputService.JumpRequest:Connect(function()
                if not (configRegistry["Infinite Jump"] and configRegistry["Infinite Jump"].getState()) then return end
                local char = Player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(
                        hrp.Velocity.X,
                        jumpForce,
                        hrp.Velocity.Z
                    )
                end
            end)
        end
        if not _G._FH_IJ_holdConn then
            local jumpForce   = 50
            local jumpHeld    = false
            local jumpHoldCd  = 0
            _G._FH_IJ_holdBeginConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.KeyCode == Enum.KeyCode.Space
                or inp.KeyCode == Enum.KeyCode.ButtonA then
                    jumpHeld = true
                end
            end)
            _G._FH_IJ_holdEndConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.KeyCode == Enum.KeyCode.Space
                or inp.KeyCode == Enum.KeyCode.ButtonA then
                    jumpHeld = false
                end
            end)
            _G._FH_IJ_holdConn = RunService.Heartbeat:Connect(function()
                if not (configRegistry["Infinite Jump"] and configRegistry["Infinite Jump"].getState()) then return end
                if not jumpHeld then return end

                if not (UserInputService:IsKeyDown(Enum.KeyCode.Space)
                     or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)) then
                    jumpHeld = false
                    return
                end
                local now = tick()
                if (now - jumpHoldCd) < 0.18 then return end
                jumpHoldCd = now
                local char = Player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(
                        hrp.Velocity.X,
                        jumpForce,
                        hrp.Velocity.Z
                    )
                end
            end)
        end
    else
        if _G._FH_IJ_conn         then _G._FH_IJ_conn:Disconnect();         _G._FH_IJ_conn         = nil end
        if _G._FH_IJ_fallConn     then _G._FH_IJ_fallConn:Disconnect();     _G._FH_IJ_fallConn     = nil end
        if _G._FH_IJ_holdConn     then _G._FH_IJ_holdConn:Disconnect();     _G._FH_IJ_holdConn     = nil end
        if _G._FH_IJ_holdBeginConn then _G._FH_IJ_holdBeginConn:Disconnect(); _G._FH_IJ_holdBeginConn = nil end
        if _G._FH_IJ_holdEndConn  then _G._FH_IJ_holdEndConn:Disconnect();  _G._FH_IJ_holdEndConn  = nil end
    end
end)
CreateToggle(PlayerTab.scroll, "Carpet Speed","Fly fast on the Flying Carpet.",              function(v) Toggles["carpet_speed"] = v; ToggleHandlers.carpet_speed(v) end)
SP.SpeedBorderFrame = Instance.new("Frame")
SP.SpeedBorderFrame.Name             = "SpeedGradBorder"
SP.SpeedBorderFrame.Size             = UDim2.new(0, SP.W + 4, 0, SP.H + 4)
SP.SpeedBorderFrame.Position         = UDim2.new(0, 96, 0.5, -(SP.H + 4) / 2)
SP.SpeedBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SP.SpeedBorderFrame.BorderSizePixel  = 0
SP.SpeedBorderFrame.ZIndex           = 18
SP.SpeedBorderFrame.Visible          = false
SP.SpeedBorderFrame.Parent           = GUI
SP.SpeedBorderFrame.BackgroundTransparency = 1
_FH_AddThemeStrokeToFrame(SP.SpeedBorderFrame, 1.5)
Corner(SP.SpeedBorderFrame, 12)
SP.SpeedWin = Instance.new("Frame")
SP.SpeedWin.Name             = "SpeedBoostPanel"
SP.SpeedWin.Size             = UDim2.new(0, SP.W, 0, SP.H)
SP.SpeedWin.Position         = UDim2.new(0, 98, 0.5, -SP.H / 2)
SP.SpeedWin.BackgroundColor3 = T.BG
SP.SpeedWin.BackgroundTransparency = 0.25
SP.SpeedWin.BorderSizePixel  = 0
SP.SpeedWin.ZIndex           = 19
SP.SpeedWin.Visible          = false
SP.SpeedWin.ClipsDescendants = true
SP.SpeedWin.Parent           = GUI
Corner(SP.SpeedWin, 10)
SP.SpHdr = Instance.new("Frame")
SP.SpHdr.Size             = UDim2.new(1, 0, 0, 30)
SP.SpHdr.BackgroundColor3 = T.Header
SP.SpHdr.BorderSizePixel  = 0
SP.SpHdr.ZIndex           = 20
SP.SpHdr.Parent           = SP.SpeedWin
Corner(SP.SpHdr, 10)
SP.SpHdr.Active = true
SP.SpHdrFill = Instance.new("Frame")
SP.SpHdrFill.Size             = UDim2.new(1, 0, 0, 7)
SP.SpHdrFill.Position         = UDim2.new(0, 0, 1, -7)
SP.SpHdrFill.BackgroundColor3 = T.Header
SP.SpHdrFill.BorderSizePixel  = 0
SP.SpHdrFill.ZIndex           = 20
SP.SpHdrFill.Parent           = SP.SpHdr
SP.SpHdrLine = Instance.new("Frame")
SP.SpHdrLine.Size             = UDim2.new(1, 0, 0, 1)
SP.SpHdrLine.Position         = UDim2.new(0, 0, 1, -1)
SP.SpHdrLine.BackgroundColor3 = T.Border
SP.SpHdrLine.BorderSizePixel  = 0
SP.SpHdrLine.ZIndex           = 21
SP.SpHdrLine.Parent           = SP.SpHdr
SP.SpTitle = Label(SP.SpHdr, "Booster", 13, T.White, Enum.Font.GothamBold)
SP.SpTitle.Size           = UDim2.new(1, -40, 1, 0)
SP.SpTitle.Position       = UDim2.new(0, 12, 0, 0)
SP.SpTitle.TextYAlignment = Enum.TextYAlignment.Center
SP.SpTitle.ZIndex         = 22
SP.SpMinBtn = Instance.new("TextButton")
SP.SpMinBtn.Size             = UDim2.new(0, 22, 0, 22)
SP.SpMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
SP.SpMinBtn.BackgroundColor3 = T.Card
SP.SpMinBtn.BorderSizePixel  = 0
SP.SpMinBtn.Text             = "\226\136\146"
SP.SpMinBtn.TextSize         = 14
SP.SpMinBtn.Font             = Enum.Font.GothamBold
SP.SpMinBtn.TextColor3       = T.White
SP.SpMinBtn.ZIndex           = 23
SP.SpMinBtn.Parent           = SP.SpHdr
Corner(SP.SpMinBtn, 6)
Stroke(SP.SpMinBtn, T.Border, 1)
SP.SpContent = Instance.new("Frame")
SP.SpContent.Size                   = UDim2.new(1, 0, 1, -30)
SP.SpContent.Position               = UDim2.new(0, 0, 0, 30)
SP.SpContent.BackgroundTransparency = 1
SP.SpContent.ZIndex                 = 19
SP.SpContent.Parent                 = SP.SpeedWin
SP.SpLayout = Instance.new("UIListLayout")
SP.SpLayout.FillDirection       = Enum.FillDirection.Vertical
SP.SpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SP.SpLayout.Padding             = UDim.new(0, 4)
SP.SpLayout.Parent              = SP.SpContent
Padding(SP.SpContent, 6, 6, 0, 0)
SP.SpRow = function(h)
    local r = Instance.new("Frame")
    r.Size                   = UDim2.new(1, -16, 0, h or 24)
    r.BackgroundTransparency = 1
    r.ZIndex                 = 20
    r.Parent                 = SP.SpContent
    return r
end
SP.spBoosterRow = SP.SpRow(20)
SP.spBoosterLbl = Label(SP.spBoosterRow, "Booster", 13, T.White, Enum.Font.GothamMedium)
SP.spBoosterLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.spBoosterLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.spBoosterLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.spBoosterLbl.ZIndex         = 21
SP.spKbLbl = Instance.new("TextLabel")
SP.spKbLbl.Size              = UDim2.new(0, 36, 0, 16)
SP.spKbLbl.Position          = UDim2.new(1, -94, 0.5, -8)
SP.spKbLbl.BackgroundTransparency = 1
SP.spKbLbl.Text              = ""
SP.spKbLbl.TextSize          = 10
SP.spKbLbl.Font              = Enum.Font.GothamBold
SP.spKbLbl.TextColor3        = T.Dim
SP.spKbLbl.TextXAlignment    = Enum.TextXAlignment.Center
SP.spKbLbl.ZIndex            = 23
SP.spKbLbl.Parent            = SP.spBoosterRow
do
    local _saved = (Config and Config.mini and Config.mini.sp_keybind)
                or (Config and Config.keybinds and Config.keybinds["sp_booster"])
                or (Config and Config.keybinds and Config.keybinds["Speed Booster"])
    if type(_saved) == "string" then
        local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
        if _ok and _kc then
            SP.entry.keyCode      = _kc
            SP.spKbLbl.Text       = "[" .. _saved .. "]"
            SP.spKbLbl.TextColor3 = T.Dim
        end
    end
end
SP.spTrack = Instance.new("Frame")
SP.spTrack.Size             = UDim2.new(0, 28, 0, 16)
SP.spTrack.Position         = UDim2.new(1, -36, 0.5, -8)
SP.spTrack.BackgroundColor3 = T.TrackOff
SP.spTrack.BorderSizePixel  = 0
SP.spTrack.ZIndex           = 21
SP.spTrack.Parent           = SP.spBoosterRow
Corner(SP.spTrack, 8)
SP.spTStroke = Stroke(SP.spTrack, T.Border, 1)
SP.spKnob = Instance.new("Frame")
SP.spKnob.Size             = UDim2.new(0, 12, 0, 12)
SP.spKnob.Position         = UDim2.new(0, 2, 0.5, -6)
SP.spKnob.BackgroundColor3 = T.KnobOff
SP.spKnob.BorderSizePixel  = 0
SP.spKnob.ZIndex           = 22
SP.spKnob.Parent           = SP.spTrack
Corner(SP.spKnob, 6)
SP.spBoosterDoToggle = function()
    SP.state = not SP.state
    if _G._FH_CarpetClearBoosterMem then _G._FH_CarpetClearBoosterMem() end
    if SP.state then
        if SP.stealOnlyEnabled then
            SP.stealOnlyEnabled = false
            Tween(SP.stealOnlyKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SP.stealOnlyKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(SP.stealOnlyKnob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(SP.stealOnlyTrack,   M, {BackgroundColor3 = T.TrackOff})
                Tween(SP.stealOnlyTStroke, M, {Color = T.Border})
            end)
        end
        Tween(SP.spKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
        task.delay(0.06, function()
            Tween(SP.spKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
            Tween(SP.spKnob,    M, {BackgroundColor3 = T.KnobOn})
            Tween(SP.spTrack,   M, {BackgroundColor3 = T.TrackOn})
            Tween(SP.spTStroke, M, {Color = T.TrackOn})
        end)
        setSpeedBooster(true)
    else
        Tween(SP.spKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
        task.delay(0.06, function()
            Tween(SP.spKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
            Tween(SP.spKnob,    M, {BackgroundColor3 = T.KnobOff})
            Tween(SP.spTrack,   M, {BackgroundColor3 = T.TrackOff})
            Tween(SP.spTStroke, M, {Color = T.Border})
        end)
        setSpeedBooster(false)
    end
    Config.toggles["sp_booster"] = SP.state
    pcall(FH_SaveConfig)
end
SP.spBoosterBtn = Instance.new("Frame")
SP.spBoosterBtn.Size                   = UDim2.new(1, 0, 1, 0)
SP.spBoosterBtn.BackgroundTransparency = 1
SP.spBoosterBtn.ZIndex                 = 24
SP.spBoosterBtn.Active                 = true
SP.spBoosterBtn.Parent                 = SP.spBoosterRow
do
    local _spBTouchStart = nil
    SP.spBoosterBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            SP.spBoosterDoToggle()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _spBTouchStart = inp.Position
        end
    end)
    SP.spBoosterBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _spBTouchStart then
            local mag = (inp.Position - _spBTouchStart).Magnitude
            _spBTouchStart = nil
            if mag < 20 then SP.spBoosterDoToggle() end
        end
    end)
end
SP.spBoosterBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if SP.kb2Debounce then return end
    SP.kb2Debounce = true
    task.delay(0.2, function() SP.kb2Debounce = false end)
    if keybindBindingTarget then
        local prev = keybindBindingTarget
        keybindBindingTarget = nil
        if prev.kbLbl == SP.spKbLbl then
            SP.spKbLbl.Text       = SP.entry.keyCode and ("[".. SP.entry.keyCode.Name .. "]") or ""
SP.spKbLbl.TextColor3 = T.Dim
            return
        else
            prev.kbLbl.Text       = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
        end
    end
    SP.spKbLbl.Text         = "(...)"
SP.spKbLbl.TextColor3   = T.White
    keybindBindingTarget = { entry = SP.entry, kbLbl = SP.spKbLbl, mode = "assign"}
end)
table.insert(keybindEntries, { entry = SP.entry, fire = SP.spBoosterDoToggle, kbLbl = SP.spKbLbl })
SP.stealOnlyEnabled = false
SP.stealOnlyRow = SP.SpRow(20)
SP.stealOnlyLbl = Label(SP.stealOnlyRow, "Booster Steal", 11, T.White, Enum.Font.GothamMedium)
SP.stealOnlyLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.stealOnlyLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.stealOnlyLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.stealOnlyLbl.ZIndex         = 21
SP.stealOnlyTrack = Instance.new("Frame")
SP.stealOnlyTrack.Size             = UDim2.new(0, 28, 0, 16)
SP.stealOnlyTrack.Position         = UDim2.new(1, -36, 0.5, -8)
SP.stealOnlyTrack.BackgroundColor3 = T.TrackOff
SP.stealOnlyTrack.BorderSizePixel  = 0
SP.stealOnlyTrack.ZIndex           = 21
SP.stealOnlyTrack.Parent           = SP.stealOnlyRow
Corner(SP.stealOnlyTrack, 8)
SP.stealOnlyTStroke = Stroke(SP.stealOnlyTrack, T.Border, 1)
SP.stealOnlyKnob = Instance.new("Frame")
SP.stealOnlyKnob.Size             = UDim2.new(0, 12, 0, 12)
SP.stealOnlyKnob.Position         = UDim2.new(0, 2, 0.5, -6)
SP.stealOnlyKnob.BackgroundColor3 = T.KnobOff
SP.stealOnlyKnob.BorderSizePixel  = 0
SP.stealOnlyKnob.ZIndex           = 22
SP.stealOnlyKnob.Parent           = SP.stealOnlyTrack
Corner(SP.stealOnlyKnob, 6)
SP.stealOnlyBtn = Instance.new("Frame")
SP.stealOnlyBtn.Size                   = UDim2.new(1, 0, 1, 0)
SP.stealOnlyBtn.BackgroundTransparency = 1
SP.stealOnlyBtn.ZIndex                 = 24
SP.stealOnlyBtn.Active                 = true
SP.stealOnlyBtn.Parent                 = SP.stealOnlyRow
SP.stealOnlyEntry = { keyCode = nil }
SP.stealOnlyKbLbl = Instance.new("TextLabel")
SP.stealOnlyKbLbl.Size                   = UDim2.new(0, 32, 0, 14)
SP.stealOnlyKbLbl.Position               = UDim2.new(1, -72, 0.5, -7)
SP.stealOnlyKbLbl.BackgroundTransparency = 1
SP.stealOnlyKbLbl.Text                   = ""
SP.stealOnlyKbLbl.TextSize               = 10
SP.stealOnlyKbLbl.Font                   = Enum.Font.GothamBold
SP.stealOnlyKbLbl.TextColor3             = T.Dim
SP.stealOnlyKbLbl.TextXAlignment         = Enum.TextXAlignment.Center
SP.stealOnlyKbLbl.ZIndex                 = 23
SP.stealOnlyKbLbl.Parent                 = SP.stealOnlyRow
do
    local _saved = Config and Config.keybinds and Config.keybinds["sp_steal_only"]
    if type(_saved) == "string" then
        local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
        if _ok and _kc then
            SP.stealOnlyEntry.keyCode = _kc
            SP.stealOnlyKbLbl.Text    = "[" .. _saved .. "]"
        end
    end
end
do
    local function _stealOnlyDoToggle()
        SP.stealOnlyEnabled = not SP.stealOnlyEnabled
        if SP.stealOnlyEnabled then
            if SP.state then
                SP.spBoosterDoToggle()
            end
            Tween(SP.stealOnlyKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SP.stealOnlyKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
                Tween(SP.stealOnlyKnob,    M, {BackgroundColor3 = T.KnobOn})
                Tween(SP.stealOnlyTrack,   M, {BackgroundColor3 = T.TrackOn})
                Tween(SP.stealOnlyTStroke, M, {Color = T.TrackOn})
            end)
            setSpeedBooster(true)
        else
            setSpeedBooster(false)
            Tween(SP.stealOnlyKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SP.stealOnlyKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(SP.stealOnlyKnob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(SP.stealOnlyTrack,   M, {BackgroundColor3 = T.TrackOff})
                Tween(SP.stealOnlyTStroke, M, {Color = T.Border})
            end)
        end
        Config.toggles["sp_steal_only"] = SP.stealOnlyEnabled
        pcall(FH_SaveConfig)
    end
    local _stealOnlyTouchStart = nil
    local _stealOnlyKb2Deb = false
    SP.stealOnlyBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            _stealOnlyDoToggle()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _stealOnlyTouchStart = inp.Position
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if _stealOnlyKb2Deb then return end
            _stealOnlyKb2Deb = true
            task.delay(0.2, function() _stealOnlyKb2Deb = false end)
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == SP.stealOnlyKbLbl then
                    SP.stealOnlyKbLbl.Text = SP.stealOnlyEntry.keyCode and ("[".. SP.stealOnlyEntry.keyCode.Name .. "]") or ""
                    return
                else
                    prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
                end
            end
            SP.stealOnlyKbLbl.Text = "(...)"
            keybindBindingTarget = { entry = SP.stealOnlyEntry, kbLbl = SP.stealOnlyKbLbl, mode = "assign" }
        end
    end)
    SP.stealOnlyBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _stealOnlyTouchStart then
            local mag = (inp.Position - _stealOnlyTouchStart).Magnitude
            _stealOnlyTouchStart = nil
            if mag < 20 then _stealOnlyDoToggle() end
        end
    end)
    table.insert(keybindEntries, { entry = SP.stealOnlyEntry, fire = _stealOnlyDoToggle, kbLbl = SP.stealOnlyKbLbl })
end
SP.wsRow = SP.SpRow(20)
SP.wsLbl = Label(SP.wsRow, "Walk Speed", 13, T.White, Enum.Font.GothamMedium)
SP.wsLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.wsLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.wsLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.wsLbl.ZIndex         = 21
SP.wsBox = Instance.new("TextBox")
SP.wsBox.Size             = UDim2.new(0, 44, 0, 22)
SP.wsBox.Position         = UDim2.new(1, -52, 0.5, -11)
SP.wsBox.BackgroundColor3 = T.Card
SP.wsBox.BorderSizePixel  = 0
SP.wsBox.Text             = "29"
SP.wsBox.TextSize         = 12
SP.wsBox.Font             = Enum.Font.GothamBold
SP.wsBox.TextColor3       = T.White
SP.wsBox.TextXAlignment   = Enum.TextXAlignment.Center
SP.wsBox.ZIndex           = 21
SP.wsBox.ClearTextOnFocus = false
SP.wsBox.Parent           = SP.wsRow
Corner(SP.wsBox, 6)
Stroke(SP.wsBox, T.Border, 1)
SP.jpRow = SP.SpRow(20)
SP.jpLbl = Label(SP.jpRow, "Jump Power", 13, T.White, Enum.Font.GothamMedium)
SP.jpLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.jpLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.jpLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.jpLbl.ZIndex         = 21
SP.jpBox = Instance.new("TextBox")
SP.jpBox.Size             = UDim2.new(0, 44, 0, 22)
SP.jpBox.Position         = UDim2.new(1, -52, 0.5, -11)
SP.jpBox.BackgroundColor3 = T.Card
SP.jpBox.BorderSizePixel  = 0
SP.jpBox.Text             = "50"
SP.jpBox.TextSize         = 12
SP.jpBox.Font             = Enum.Font.GothamBold
SP.jpBox.TextColor3       = T.White
SP.jpBox.TextXAlignment   = Enum.TextXAlignment.Center
SP.jpBox.ZIndex           = 21
SP.jpBox.ClearTextOnFocus = false
SP.jpBox.Parent           = SP.jpRow
Corner(SP.jpBox, 6)
Stroke(SP.jpBox, T.Border, 1)
local function _spSaveSliders()
    if _G._FH_IsRestoring then return end
    Config.sliders = Config.sliders or {}
    Config.sliders.sp_walkspeed = SP.wsBox.Text
    Config.sliders.sp_jumppower = SP.jpBox.Text
    pcall(FH_SaveConfig)
end
local _spSaveDebounce = false
local function _spQueueSave()
    if _spSaveDebounce then return end
    _spSaveDebounce = true
    task.delay(0.4, function() _spSaveDebounce = false; _spSaveSliders() end)
end
SP.wsBox.FocusLost:Connect(_spSaveSliders)
SP.jpBox.FocusLost:Connect(_spSaveSliders)
SP.wsBox:GetPropertyChangedSignal("Text"):Connect(_spQueueSave)
SP.jpBox:GetPropertyChangedSignal("Text"):Connect(_spQueueSave)
SP.jpBoosterRow = SP.SpRow(20)
SP.jpBoosterLbl = Label(SP.jpBoosterRow, "Jump Booster", 13, T.White, Enum.Font.GothamMedium)
SP.jpBoosterLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.jpBoosterLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.jpBoosterLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.jpBoosterLbl.ZIndex         = 21
SP.jpBoosterTrack = Instance.new("Frame")
SP.jpBoosterTrack.Size             = UDim2.new(0, 28, 0, 16)
SP.jpBoosterTrack.Position         = UDim2.new(1, -36, 0.5, -8)
SP.jpBoosterTrack.BackgroundColor3 = T.TrackOff
SP.jpBoosterTrack.BorderSizePixel  = 0
SP.jpBoosterTrack.ZIndex           = 21
SP.jpBoosterTrack.Parent           = SP.jpBoosterRow
Corner(SP.jpBoosterTrack, 8)
SP.jpBoosterTStroke = Stroke(SP.jpBoosterTrack, T.Border, 1)
SP.jpBoosterKnob = Instance.new("Frame")
SP.jpBoosterKnob.Size             = UDim2.new(0, 12, 0, 12)
SP.jpBoosterKnob.Position         = UDim2.new(0, 2, 0.5, -6)
SP.jpBoosterKnob.BackgroundColor3 = T.KnobOff
SP.jpBoosterKnob.BorderSizePixel  = 0
SP.jpBoosterKnob.ZIndex           = 22
SP.jpBoosterKnob.Parent           = SP.jpBoosterTrack
Corner(SP.jpBoosterKnob, 6)
SP.jpBoosterState = false
SP.jpBoosterDoToggle = function()
    SP.jpBoosterState = not SP.jpBoosterState
    if SP.jpBoosterState then
        Tween(SP.jpBoosterKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
        task.delay(0.06, function()
            Tween(SP.jpBoosterKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
            Tween(SP.jpBoosterKnob,    M, {BackgroundColor3 = T.KnobOn})
            Tween(SP.jpBoosterTrack,   M, {BackgroundColor3 = T.TrackOn})
            Tween(SP.jpBoosterTStroke, M, {Color = T.TrackOn})
        end)
        setJumpBooster(true)
    else
        Tween(SP.jpBoosterKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
        task.delay(0.06, function()
            Tween(SP.jpBoosterKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
            Tween(SP.jpBoosterKnob,    M, {BackgroundColor3 = T.KnobOff})
            Tween(SP.jpBoosterTrack,   M, {BackgroundColor3 = T.TrackOff})
            Tween(SP.jpBoosterTStroke, M, {Color = T.Border})
        end)
        setJumpBooster(false)
    end
    Config.toggles["sp_jump_booster"] = SP.jpBoosterState
    pcall(FH_SaveConfig)
end
SP.jpBoosterBtn = Instance.new("Frame")
SP.jpBoosterBtn.Size                   = UDim2.new(1, 0, 1, 0)
SP.jpBoosterBtn.BackgroundTransparency = 1
SP.jpBoosterBtn.ZIndex                 = 24
SP.jpBoosterBtn.Active                 = true
SP.jpBoosterBtn.Parent                 = SP.jpBoosterRow
SP.jpBoosterEntry = { keyCode = nil }
SP.jpBoosterKbLbl = Instance.new("TextLabel")
SP.jpBoosterKbLbl.Size                   = UDim2.new(0, 32, 0, 14)
SP.jpBoosterKbLbl.Position               = UDim2.new(1, -72, 0.5, -7)
SP.jpBoosterKbLbl.BackgroundTransparency = 1
SP.jpBoosterKbLbl.Text                   = ""
SP.jpBoosterKbLbl.TextSize               = 10
SP.jpBoosterKbLbl.Font                   = Enum.Font.GothamBold
SP.jpBoosterKbLbl.TextColor3             = T.Dim
SP.jpBoosterKbLbl.TextXAlignment         = Enum.TextXAlignment.Center
SP.jpBoosterKbLbl.ZIndex                 = 23
SP.jpBoosterKbLbl.Parent                 = SP.jpBoosterRow
do
    local _saved = Config and Config.keybinds and Config.keybinds["sp_jump_booster"]
    if type(_saved) == "string" then
        local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
        if _ok and _kc then
            SP.jpBoosterEntry.keyCode = _kc
            SP.jpBoosterKbLbl.Text    = "[" .. _saved .. "]"
        end
    end
end
do
    local _jpBTouchStart = nil
    local _jpBKb2Deb = false
    SP.jpBoosterBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            SP.jpBoosterDoToggle()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _jpBTouchStart = inp.Position
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if _jpBKb2Deb then return end
            _jpBKb2Deb = true
            task.delay(0.2, function() _jpBKb2Deb = false end)
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == SP.jpBoosterKbLbl then
                    SP.jpBoosterKbLbl.Text = SP.jpBoosterEntry.keyCode and ("[".. SP.jpBoosterEntry.keyCode.Name .. "]") or ""
                    return
                else
                    prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
                end
            end
            SP.jpBoosterKbLbl.Text = "(...)"
            keybindBindingTarget = { entry = SP.jpBoosterEntry, kbLbl = SP.jpBoosterKbLbl, mode = "assign" }
        end
    end)
    SP.jpBoosterBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _jpBTouchStart then
            local mag = (inp.Position - _jpBTouchStart).Magnitude
            _jpBTouchStart = nil
            if mag < 20 then SP.jpBoosterDoToggle() end
        end
    end)
    table.insert(keybindEntries, { entry = SP.jpBoosterEntry, fire = SP.jpBoosterDoToggle, kbLbl = SP.jpBoosterKbLbl })
end
SP.giantSpeedRow = SP.SpRow(20)
SP.giantSpeedLbl = Label(SP.giantSpeedRow, "Giant Speed", 13, T.White, Enum.Font.GothamMedium)
SP.giantSpeedLbl.Size           = UDim2.new(1, -60, 1, 0)
SP.giantSpeedLbl.Position       = UDim2.new(0, 8, 0, 0)
SP.giantSpeedLbl.TextYAlignment = Enum.TextYAlignment.Center
SP.giantSpeedLbl.ZIndex         = 21
SP.giantSpeedTrack = Instance.new("Frame")
SP.giantSpeedTrack.Size             = UDim2.new(0, 40, 0, 20)
SP.giantSpeedTrack.Position         = UDim2.new(1, -52, 0.5, -10)
SP.giantSpeedTrack.BackgroundColor3 = T.TrackOff
SP.giantSpeedTrack.BorderSizePixel  = 0
SP.giantSpeedTrack.ZIndex           = 21
SP.giantSpeedTrack.Parent           = SP.giantSpeedRow
Corner(SP.giantSpeedTrack, 10)
SP.giantSpeedTStroke = Stroke(SP.giantSpeedTrack, T.Border, 1)
SP.giantSpeedKnob = Instance.new("Frame")
SP.giantSpeedKnob.Size             = UDim2.new(0, 10, 0, 10)
SP.giantSpeedKnob.Position         = UDim2.new(0, 3, 0.5, -7)
SP.giantSpeedKnob.BackgroundColor3 = T.KnobOff
SP.giantSpeedKnob.BorderSizePixel  = 0
SP.giantSpeedKnob.ZIndex           = 22
SP.giantSpeedKnob.Parent           = SP.giantSpeedTrack
Corner(SP.giantSpeedKnob, 7)
SP.giantSpeedState = false
SP.giantSpeedDoToggle = function()
    SP.giantSpeedState = not SP.giantSpeedState
    if SP.giantSpeedState then
        Tween(SP.giantSpeedKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 4, 0.5, -6)})
        task.delay(0.06, function()
            Tween(SP.giantSpeedKnob,    M, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 22, 0.5, -7)})
            Tween(SP.giantSpeedKnob,    M, {BackgroundColor3 = T.KnobOn})
            Tween(SP.giantSpeedTrack,   M, {BackgroundColor3 = T.TrackOn})
            Tween(SP.giantSpeedTStroke, M, {Color = T.TrackOn})
        end)
        ToggleHandlers.giant_speed(true)
    else
        Tween(SP.giantSpeedKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 20, 0.5, -6)})
        task.delay(0.06, function()
            Tween(SP.giantSpeedKnob,    M, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -7)})
            Tween(SP.giantSpeedKnob,    M, {BackgroundColor3 = T.KnobOff})
            Tween(SP.giantSpeedTrack,   M, {BackgroundColor3 = T.TrackOff})
            Tween(SP.giantSpeedTStroke, M, {Color = T.Border})
        end)
        ToggleHandlers.giant_speed(false)
    end
    Config.toggles["sp_giant_speed"] = SP.giantSpeedState
    pcall(FH_SaveConfig)
end
SP.giantSpeedBtn = Instance.new("Frame")
SP.giantSpeedBtn.Size                   = UDim2.new(1, 0, 1, 0)
SP.giantSpeedBtn.BackgroundTransparency = 1
SP.giantSpeedBtn.ZIndex                 = 24
SP.giantSpeedBtn.Active                 = true
SP.giantSpeedBtn.Parent                 = SP.giantSpeedRow
do
    local _gsBTouchStart = nil
    SP.giantSpeedBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            SP.giantSpeedDoToggle()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _gsBTouchStart = inp.Position
        end
    end)
    SP.giantSpeedBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _gsBTouchStart then
            local mag = (inp.Position - _gsBTouchStart).Magnitude
            _gsBTouchStart = nil
            if mag < 20 then SP.giantSpeedDoToggle() end
        end
    end)
end
SP.spBoosterRow.Visible  = false
SP.spBoosterRow.Size     = UDim2.new(0, 0, 0, 0)
SP.giantSpeedRow.Visible = false
SP.giantSpeedRow.Size    = UDim2.new(0, 0, 0, 0)
do
    SP.SpHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            SP.dragging   = true
            SP.dragStart  = inp.Position
            SP.panelStart = SP.SpeedWin.Position
        end
    end)
    SP.SpHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            SP.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.sp_pos = { x = SP.SpeedWin.Position.X.Offset, y = SP.SpeedWin.Position.Y.Offset,
                                   xs = SP.SpeedWin.Position.X.Scale, ys = SP.SpeedWin.Position.Y.Scale }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if SP.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d      = inp.Position - SP.dragStart
            local newPos = UDim2.new(
                SP.panelStart.X.Scale, SP.panelStart.X.Offset + d.X,
                SP.panelStart.Y.Scale, SP.panelStart.Y.Offset + d.Y
            )
            SP.SpeedWin.Position         = newPos
            SP.SpeedBorderFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 2,
                newPos.Y.Scale, newPos.Y.Offset - 2
            )
        end
    end)
end
SP.SpMinBtn.MouseButton1Click:Connect(function()
    SP.minimized = not SP.minimized
    if SP.minimized then
        SP.SpeedWin.ClipsDescendants = false
        SP.SpHdrFill.Visible = false
        SP.SpHdrLine.Visible = false
        SP.SpContent.Visible = false
        Tween(SP.SpeedWin,         M, {Size = UDim2.new(0, SP.W, 0, 30)})
        Tween(SP.SpeedBorderFrame, M, {Size = UDim2.new(0, SP.W + 4, 0, 40)})
        SP.SpMinBtn.Text = "+"else
        SP.SpHdrFill.Visible = true
        SP.SpHdrLine.Visible = true
        Tween(SP.SpeedWin,         M, {Size = UDim2.new(0, SP.W, 0, SP.H)})
        Tween(SP.SpeedBorderFrame, M, {Size = UDim2.new(0, SP.W + 4, 0, SP.H + 4)})
        SP.SpMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            SP.SpContent.Visible = true
            SP.SpeedWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.sp_min = SP.minimized
        pcall(FH_SaveConfig)
    end
end)
SP.setSpeedPanelVisible = function(vis)
    SP.SpeedWin.Visible         = vis
    SP.SpeedBorderFrame.Visible = vis
    if vis then

        local p = SP.SpeedWin.Position
        SP.SpeedBorderFrame.Position  = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if SP.minimized then
            SP.SpMinBtn.Text              = "+"
            SP.SpContent.Visible          = false
            SP.SpHdrFill.Visible          = false
            SP.SpHdrLine.Visible          = false
            SP.SpeedWin.ClipsDescendants  = false
            SP.SpeedWin.Size              = UDim2.new(0, SP.W, 0, 30)
            SP.SpeedBorderFrame.Size      = UDim2.new(0, SP.W + 4, 0, 40)
        else
            SP.SpMinBtn.Text              = "\226\136\146"
            SP.SpContent.Visible          = true
            SP.SpHdrFill.Visible          = true
            SP.SpHdrLine.Visible          = true
            SP.SpeedWin.ClipsDescendants  = true
            SP.SpeedWin.Size              = UDim2.new(0, SP.W, 0, SP.H)
            SP.SpeedBorderFrame.Size      = UDim2.new(0, SP.W + 4, 0, SP.H + 4)
        end
    end
end

do
    local function spApplyBooster(v)
        SP.state = v
        if v then
            SP.spKnob.Position         = UDim2.new(0, 14, 0.5, -6)
            SP.spKnob.BackgroundColor3 = T.KnobOn
            SP.spTrack.BackgroundColor3 = T.TrackOn
            SP.spTStroke.Color         = T.TrackOn
            setSpeedBooster(true)
        else
            SP.spKnob.Position         = UDim2.new(0, 2, 0.5, -6)
            SP.spKnob.BackgroundColor3 = T.KnobOff
            SP.spTrack.BackgroundColor3 = T.TrackOff
            SP.spTStroke.Color         = T.Border
            setSpeedBooster(false)
        end
        Config.toggles["sp_booster"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end
    configRegistry["sp_booster"] = {
        getState   = function() return SP.state end,
        getKeyCode = function() return SP.entry and SP.entry.keyCode end,
        setKeyCode = function(kc)
            if SP.entry then SP.entry.keyCode = kc end
            if SP.spKbLbl then
                SP.spKbLbl.Text = kc and ("["..kc.Name.."]") or ""
                SP.spKbLbl.TextColor3 = T.Dim
            end
            if kc then Config.keybinds["sp_booster"] = kc.Name
            else Config.keybinds["sp_booster"] = nil end
            pcall(FH_SaveConfig)
        end,
        doToggle   = SP.spBoosterDoToggle,
        setEnabled = spApplyBooster,
    }
    local function spApplyJumpBooster(v)
        SP.jpBoosterState = v
        if v then
            SP.jpBoosterKnob.Position         = UDim2.new(0, 14, 0.5, -6)
            SP.jpBoosterKnob.BackgroundColor3 = T.KnobOn
            SP.jpBoosterTrack.BackgroundColor3 = T.TrackOn
            SP.jpBoosterTStroke.Color         = T.TrackOn
            setJumpBooster(true)
        else
            SP.jpBoosterKnob.Position         = UDim2.new(0, 2, 0.5, -6)
            SP.jpBoosterKnob.BackgroundColor3 = T.KnobOff
            SP.jpBoosterTrack.BackgroundColor3 = T.TrackOff
            SP.jpBoosterTStroke.Color         = T.Border
            setJumpBooster(false)
        end
        Config.toggles["sp_jump_booster"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end
    configRegistry["sp_jump_booster"] = {
        getState   = function() return SP.jpBoosterState end,
        getKeyCode = function() return SP.jpBoosterEntry and SP.jpBoosterEntry.keyCode end,
        setKeyCode = function(kc)
            if SP.jpBoosterEntry then SP.jpBoosterEntry.keyCode = kc end
            if SP.jpBoosterKbLbl then
                SP.jpBoosterKbLbl.Text = kc and ("["..kc.Name.."]") or ""
                SP.jpBoosterKbLbl.TextColor3 = T.Dim
            end
            Config.keybinds = Config.keybinds or {}
            if kc then Config.keybinds["sp_jump_booster"] = kc.Name
            else Config.keybinds["sp_jump_booster"] = nil end
            pcall(FH_SaveConfig)
        end,
        doToggle   = SP.jpBoosterDoToggle,
        setEnabled = spApplyJumpBooster,
    }
    local function spApplyGiantSpeed(v)
        SP.giantSpeedState = v
        if v then
            SP.giantSpeedKnob.Position         = UDim2.new(0, 22, 0.5, -7)
            SP.giantSpeedKnob.BackgroundColor3 = T.KnobOn
            SP.giantSpeedTrack.BackgroundColor3 = T.TrackOn
            SP.giantSpeedTStroke.Color         = T.TrackOn
            ToggleHandlers.giant_speed(true)
        else
            SP.giantSpeedKnob.Position         = UDim2.new(0, 3, 0.5, -7)
            SP.giantSpeedKnob.BackgroundColor3 = T.KnobOff
            SP.giantSpeedTrack.BackgroundColor3 = T.TrackOff
            SP.giantSpeedTStroke.Color         = T.Border
            ToggleHandlers.giant_speed(false)
        end
        Config.toggles["sp_giant_speed"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end
    configRegistry["sp_giant_speed"] = {
        getState   = function() return SP.giantSpeedState end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = SP.giantSpeedDoToggle,
        setEnabled = spApplyGiantSpeed,
    }
    local function spApplyStealOnly(v)
        SP.stealOnlyEnabled = v
        if v then
            SP.stealOnlyKnob.Position         = UDim2.new(0, 14, 0.5, -6)
            SP.stealOnlyKnob.BackgroundColor3 = T.KnobOn
            SP.stealOnlyTrack.BackgroundColor3 = T.TrackOn
            SP.stealOnlyTStroke.Color         = T.TrackOn
            setSpeedBooster(true)
        else
            SP.stealOnlyKnob.Position         = UDim2.new(0, 2, 0.5, -6)
            SP.stealOnlyKnob.BackgroundColor3 = T.KnobOff
            SP.stealOnlyTrack.BackgroundColor3 = T.TrackOff
            SP.stealOnlyTStroke.Color         = T.Border
            setSpeedBooster(false)
        end
        Config.toggles["sp_steal_only"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end
    configRegistry["sp_steal_only"] = {
        getState   = function() return SP.stealOnlyEnabled end,
        getKeyCode = function() return SP.stealOnlyEntry and SP.stealOnlyEntry.keyCode end,
        setKeyCode = function(kc)
            if SP.stealOnlyEntry then SP.stealOnlyEntry.keyCode = kc end
            if SP.stealOnlyKbLbl then
                SP.stealOnlyKbLbl.Text = kc and ("["..kc.Name.."]") or ""
                SP.stealOnlyKbLbl.TextColor3 = T.Dim
            end
            Config.keybinds = Config.keybinds or {}
            if kc then Config.keybinds["sp_steal_only"] = kc.Name
            else Config.keybinds["sp_steal_only"] = nil end
            pcall(FH_SaveConfig)
        end,
        doToggle   = function()
            SP.stealOnlyEnabled = not SP.stealOnlyEnabled
            spApplyStealOnly(SP.stealOnlyEnabled)
        end,
        setEnabled = spApplyStealOnly,
    }
end

do
    local function ssApplyPotion(v)
        SS.potionState = v
        if v then
            SS.SSPotionKnob.Position         = UDim2.new(0, 14, 0.5, -6)
            SS.SSPotionKnob.BackgroundColor3 = T.KnobOn
            SS.SSPotionTrack.BackgroundColor3 = T.TrackOn
            SS.SSPotionTStroke.Color         = T.TrackOn
        else
            SS.SSPotionKnob.Position         = UDim2.new(0, 2, 0.5, -6)
            SS.SSPotionKnob.BackgroundColor3 = T.KnobOff
            SS.SSPotionTrack.BackgroundColor3 = T.TrackOff
            SS.SSPotionTStroke.Color         = T.Border
        end
        Config.toggles["ss_potion"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end
    configRegistry["ss_potion"] = {
        getState   = function() return SS.potionState end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = function() ssApplyPotion(not SS.potionState) end,
        setEnabled = ssApplyPotion,
    }
end
CreateToggle(PlayerTab.scroll, "Speed Boost Panel",       "Shows speed booster panel.",                  function(v) SP.setSpeedPanelVisible(v) end, function()
    if SP and SP.spBoosterDoToggle then pcall(SP.spBoosterDoToggle) end
end)

do
    local function _fhMakeSlider(parent, title, minV, maxV, defaultV, onChange)

        local cardH = isMobile and 60 or 52
        local card = Instance.new("Frame")
        card.Size                  = UDim2.new(1, -16, 0, cardH)
        card.BackgroundColor3      = T.Card
        card.BackgroundTransparency = 0.15
        card.BorderSizePixel       = 0
        card.Parent                = parent
        Corner(card, 8)
        Stroke(card, T.Border, 1)

        local nameLbl = Label(card, title, isMobile and 13 or 12, T.White, Enum.Font.GothamMedium)
        nameLbl.Size      = UDim2.new(0.5, -12, 0, 16)
        nameLbl.Position  = UDim2.new(0, 12, 0, 6)

        local valBox = Instance.new("TextBox")
        valBox.Size                = UDim2.new(0, isMobile and 58 or 64, 0, 18)
        valBox.AnchorPoint         = Vector2.new(1, 0)
        valBox.Position            = UDim2.new(1, -12, 0, 5)
        valBox.BackgroundColor3    = T.Card
        valBox.BackgroundTransparency = 0.4
        valBox.BorderSizePixel     = 0
        valBox.Text                = tostring(defaultV)
        valBox.TextSize            = isMobile and 12 or 11
        valBox.Font                = Enum.Font.GothamBold
        valBox.TextColor3          = T.White
        valBox.TextXAlignment      = Enum.TextXAlignment.Center
        valBox.ClearTextOnFocus    = false
        valBox.Parent              = card
        Corner(valBox, 4)
        Stroke(valBox, T.Border, 1)

        local track = Instance.new("Frame")
        track.Size                  = UDim2.new(1, -24, 0, 6)
        track.Position              = UDim2.new(0, 12, 1, isMobile and -20 or -16)
        track.BackgroundColor3      = T.TrackOff or Color3.fromRGB(50,50,55)
        track.BorderSizePixel       = 0
        track.Parent                = card
        Corner(track, 3)

        local fill = Instance.new("Frame")
        local pct  = (defaultV - minV) / (maxV - minV)
        fill.Size                   = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3       = _G._FH_AccentA or Color3.fromRGB(120, 200, 255)
        fill.BorderSizePixel        = 0
        fill.Parent                 = track
        Corner(fill, 3)

        local function _applyValue(val, fromBox)
            val = math.clamp(tonumber(val) or minV, minV, maxV)
            val = math.floor(val * 10 + 0.5) / 10
            local rel = (val - minV) / (maxV - minV)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            if not fromBox then valBox.Text = tostring(val) end
            if onChange then pcall(onChange, val) end
            return val
        end

        local dragging = false
        local function setFromX(absX)
            local rel = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            _applyValue(minV + (maxV - minV) * rel, false)
        end
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                          or inp.UserInputType == Enum.UserInputType.Touch) then
                setFromX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        valBox.FocusLost:Connect(function(enterPressed)
            local v = _applyValue(valBox.Text, true)
            valBox.Text = tostring(v)
        end)
        return card
    end

    _G._FH_MakeSlider = _fhMakeSlider
end

CreateSection(PlayerTab.scroll, "Other")
CreateToggle(PlayerTab.scroll, "Aimbot",                  "Websling, laser cape aimbot.",                function(v)
    if v then Aim.startAimbot() else Aim.stopAimbot() end
end)
CreateToggle(PlayerTab.scroll, "Auto Destroy Turrets",    "Deletes turrets that other players place.",   function(v) ToggleHandlers.anti_turret(v) end)
do
    local arEnabled  = false
    local arCard = Instance.new("Frame")
    arCard.Name             = "ARCard"
arCard.Size             = UDim2.new(1, -16, 0, 44)
    arCard.BackgroundColor3 = T.Card
    arCard.BorderSizePixel  = 0
    arCard.ClipsDescendants = false
    arCard.LayoutOrder      = 999
    arCard.Parent           = PlayerTab.scroll
    Corner(arCard, 8)
    local arCardStroke = Stroke(arCard, T.Border, 1)
    local arBar = Instance.new("Frame")
    arBar.Size             = UDim2.new(0, 3, 0, 28)
    arBar.Position         = UDim2.new(0, 0, 0, 8)
    arBar.BackgroundColor3 = T.TrackOff
    arBar.BorderSizePixel  = 0
    arBar.ZIndex           = 2
    arBar.Parent           = arCard
    Corner(arBar, 2)
    local arNameLbl = Label(arCard, "Auto Reset On Balloon", 13, T.White, Enum.Font.GothamMedium)
    arNameLbl.Size     = UDim2.new(1, -100, 0, 16)
    arNameLbl.Position = UDim2.new(0, 10, 0, 10)
    arNameLbl.ZIndex   = 2
    local arTrack = Instance.new("Frame")
    arTrack.Size             = UDim2.new(0, 28, 0, 16)
    arTrack.Position         = UDim2.new(1, -52, 0, 11)
    arTrack.BackgroundColor3 = T.TrackOff
    arTrack.BorderSizePixel  = 0
    arTrack.ZIndex           = 3
    arTrack.Parent           = arCard
    Corner(arTrack, 8)
    local arTrackStroke = Stroke(arTrack, T.Border, 1)
    local arKnob = Instance.new("Frame")
    arKnob.Size             = UDim2.new(0, 12, 0, 12)
    arKnob.Position         = UDim2.new(0, 2, 0.5, -6)
    arKnob.BackgroundColor3 = T.KnobOff
    arKnob.BorderSizePixel  = 0
    arKnob.ZIndex           = 4
    arKnob.Parent           = arTrack
    Corner(arKnob, 6)

    local function doARToggle()
        arEnabled = not arEnabled
        Config.toggles["Auto Reset On Balloon"] = arEnabled
        if arEnabled then
            Tween(arKnob, TweenInfo.new(0.06), {Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,4,0.5,-7)})
            task.delay(0.06, function()
                Tween(arKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
                Tween(arKnob,        M, {BackgroundColor3 = T.KnobOn})
                Tween(arTrack,       M, {BackgroundColor3 = T.TrackOn})
                Tween(arTrackStroke, M, {Color = T.TrackOn})
                Tween(arBar,         M, {BackgroundColor3 = T.White})
            end)
            ToggleHandlers.auto_reset_balloon(true)
        else
            Tween(arKnob, TweenInfo.new(0.06), {Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,20,0.5,-7)})
            task.delay(0.06, function()
                Tween(arKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
                Tween(arKnob,        M, {BackgroundColor3 = T.KnobOff})
                Tween(arTrack,       M, {BackgroundColor3 = T.TrackOff})
                Tween(arTrackStroke, M, {Color = T.Border})
                Tween(arBar,         M, {BackgroundColor3 = T.TrackOff})
            end)
            ToggleHandlers.auto_reset_balloon(false)
        end
    end
    configRegistry["Auto Reset On Balloon"] = {
        getState   = function() return arEnabled end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = doARToggle,
        setEnabled = function(v)
            arEnabled = v
            Config.toggles["Auto Reset On Balloon"] = v
            if v then
                Tween(arKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
                Tween(arKnob,        M, {BackgroundColor3 = T.KnobOn})
                Tween(arTrack,       M, {BackgroundColor3 = T.TrackOn})
                Tween(arTrackStroke, M, {Color = T.TrackOn})
                Tween(arBar,         M, {BackgroundColor3 = T.White})
                ToggleHandlers.auto_reset_balloon(true)
            else
                Tween(arKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
                Tween(arKnob,        M, {BackgroundColor3 = T.KnobOff})
                Tween(arTrack,       M, {BackgroundColor3 = T.TrackOff})
                Tween(arTrackStroke, M, {Color = T.Border})
                Tween(arBar,         M, {BackgroundColor3 = T.TrackOff})
                ToggleHandlers.auto_reset_balloon(false)
            end
            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
        end,
    }
    arCard.MouseEnter:Connect(function()
        Tween(arCard,       F, {BackgroundColor3 = T.CardHover})
        Tween(arCardStroke, F, {Color = T.BorderHover})
    end)
    arCard.MouseLeave:Connect(function()
        Tween(arCard,       F, {BackgroundColor3 = T.Card})
        Tween(arCardStroke, F, {Color = T.Border})
    end)
    local arHit = Instance.new("Frame")
    arHit.Size                   = UDim2.new(1, 0, 1, 0)
    arHit.BackgroundTransparency = 1
    arHit.ZIndex                 = 5
    arHit.Active                 = true
    arHit.Parent                 = arCard
    do
        local _arTouchStart = nil
        arHit.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                doARToggle()
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                _arTouchStart = inp.Position
            end
        end)
        arHit.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _arTouchStart then
                local mag = (inp.Position - _arTouchStart).Magnitude
                _arTouchStart = nil
                if mag < 20 then doARToggle() end
            end
        end)
    end
end
do
    local ajEnabled = false
    local ajCard = Instance.new("Frame")
    ajCard.Name             = "AJCard"
ajCard.Size             = UDim2.new(1, -16, 0, 44)
    ajCard.BackgroundColor3 = T.Card
    ajCard.BorderSizePixel  = 0
    ajCard.ClipsDescendants = false
    ajCard.LayoutOrder      = 1001
    ajCard.Parent           = PlayerTab.scroll
    Corner(ajCard, 8)
    local ajCardStroke = Stroke(ajCard, T.Border, 1)
    local ajBar = Instance.new("Frame")
    ajBar.Size             = UDim2.new(0, 3, 0, 28)
    ajBar.Position         = UDim2.new(0, 0, 0, 8)
    ajBar.BackgroundColor3 = T.TrackOff
    ajBar.BorderSizePixel  = 0
    ajBar.ZIndex           = 2
    ajBar.Parent           = ajCard
    Corner(ajBar, 2)
    local ajNameLbl = Label(ajCard, "Auto Reset On Jail", 13, T.White, Enum.Font.GothamMedium)
    ajNameLbl.Size     = UDim2.new(1, -100, 0, 16)
    ajNameLbl.Position = UDim2.new(0, 10, 0, 10)
    ajNameLbl.ZIndex   = 2
    local ajTrack = Instance.new("Frame")
    ajTrack.Size             = UDim2.new(0, 28, 0, 16)
    ajTrack.Position         = UDim2.new(1, -52, 0, 11)
    ajTrack.BackgroundColor3 = T.TrackOff
    ajTrack.BorderSizePixel  = 0
    ajTrack.ZIndex           = 3
    ajTrack.Parent           = ajCard
    Corner(ajTrack, 8)
    local ajTrackStroke = Stroke(ajTrack, T.Border, 1)
    local ajKnob = Instance.new("Frame")
    ajKnob.Size             = UDim2.new(0, 12, 0, 12)
    ajKnob.Position         = UDim2.new(0, 2, 0.5, -6)
    ajKnob.BackgroundColor3 = T.KnobOff
    ajKnob.BorderSizePixel  = 0
    ajKnob.ZIndex           = 4
    ajKnob.Parent           = ajTrack
    Corner(ajKnob, 6)
    local function doAJToggle()
        ajEnabled = not ajEnabled
        Config.toggles["Auto Reset On Jail"] = ajEnabled
        if ajEnabled then
            Tween(ajKnob, TweenInfo.new(0.06), {Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,4,0.5,-7)})
            task.delay(0.06, function()
                Tween(ajKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
                Tween(ajKnob,        M, {BackgroundColor3 = T.KnobOn})
                Tween(ajTrack,       M, {BackgroundColor3 = T.TrackOn})
                Tween(ajTrackStroke, M, {Color = T.TrackOn})
                Tween(ajBar,         M, {BackgroundColor3 = T.White})
            end)
            ToggleHandlers.auto_reset_jail(true)
        else
            Tween(ajKnob, TweenInfo.new(0.06), {Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,20,0.5,-7)})
            task.delay(0.06, function()
                Tween(ajKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
                Tween(ajKnob,        M, {BackgroundColor3 = T.KnobOff})
                Tween(ajTrack,       M, {BackgroundColor3 = T.TrackOff})
                Tween(ajTrackStroke, M, {Color = T.Border})
                Tween(ajBar,         M, {BackgroundColor3 = T.TrackOff})
            end)
            ToggleHandlers.auto_reset_jail(false)
        end
    end
    configRegistry["Auto Reset On Jail"] = {
        getState   = function() return ajEnabled end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = doAJToggle,
        setEnabled = function(v)
            ajEnabled = v
            Config.toggles["Auto Reset On Jail"] = v
            if v then
                Tween(ajKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
                Tween(ajKnob,        M, {BackgroundColor3 = T.KnobOn})
                Tween(ajTrack,       M, {BackgroundColor3 = T.TrackOn})
                Tween(ajTrackStroke, M, {Color = T.TrackOn})
                Tween(ajBar,         M, {BackgroundColor3 = T.White})
                ToggleHandlers.auto_reset_jail(true)
            else
                Tween(ajKnob,        M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
                Tween(ajKnob,        M, {BackgroundColor3 = T.KnobOff})
                Tween(ajTrack,       M, {BackgroundColor3 = T.TrackOff})
                Tween(ajTrackStroke, M, {Color = T.Border})
                Tween(ajBar,         M, {BackgroundColor3 = T.TrackOff})
                ToggleHandlers.auto_reset_jail(false)
            end
            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
        end,
    }
    ajCard.MouseEnter:Connect(function()
        Tween(ajCard,       F, {BackgroundColor3 = T.CardHover})
        Tween(ajCardStroke, F, {Color = T.BorderHover})
    end)
    ajCard.MouseLeave:Connect(function()
        Tween(ajCard,       F, {BackgroundColor3 = T.Card})
        Tween(ajCardStroke, F, {Color = T.Border})
    end)
    local ajHit = Instance.new("Frame")
    ajHit.Size                   = UDim2.new(1, 0, 1, 0)
    ajHit.BackgroundTransparency = 1
    ajHit.ZIndex                 = 5
    ajHit.Active                 = true
    ajHit.Parent                 = ajCard
    do
        local _ajTouchStart = nil
        ajHit.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                doAJToggle()
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                _ajTouchStart = inp.Position
            end
        end)
        ajHit.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _ajTouchStart then
                local mag = (inp.Position - _ajTouchStart).Magnitude
                _ajTouchStart = nil
                if mag < 20 then doAJToggle() end
            end
        end)
    end
end

;(function()

    local SearchUserRemote = nil
    local InviteRemote     = nil
    task.spawn(function()
        local children = ReplicatedStorage:GetDescendants()
        for i, obj in ipairs(children) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local nextObj = children[i + 1]
                if nextObj then
                    if obj.Name == "RF/TradeService/SearchUser" then SearchUserRemote = nextObj end
                    if obj.Name == "RF/TradeService/Invite"     then InviteRemote     = nextObj end
                end
            end
            if i % 50 == 0 then task.wait() end
        end
    end)
    local SEARCH_UUID = "792baf13-54a1-4663-92c4-1edd9da1e3e2"
    local INVITE_UUID = "afb005f9-6e81-4e0a-8bb0-3555938a9658"
    local function invokeTrade(userId, onResult)
        if not (SearchUserRemote and InviteRemote) then
            if onResult then onResult(false, "Remotes not ready") end
            return
        end
        task.spawn(function()
            local ok1, found, inGame, canInvite = pcall(function()
                return SearchUserRemote:InvokeServer(SEARCH_UUID, userId)
            end)
            if not (ok1 and found and inGame and canInvite) then
                if onResult then onResult(false, "Not found / offline / busy") end
                return
            end
            local ok2, result = pcall(function()
                return InviteRemote:InvokeServer(INVITE_UUID, userId)
            end)
            if onResult then onResult(ok2 and result, ok2 and "Sent" or "Invite failed") end
        end)
    end
    CreateSection(PlayerTab.scroll, "User Search")

    local PAD              = 8
    local SEARCH_ROW_H     = isMobile and 28 or 32
    local PROF_AV          = isMobile and 40 or 48
    local PROF_ROW_H       = PROF_AV + PAD
    local BTN_W            = isMobile and 70 or 82
    local BTN_H            = isMobile and 22 or 25
    local CARD_H_COLLAPSED = SEARCH_ROW_H + PAD * 2
    local CARD_H_EXPANDED  = CARD_H_COLLAPSED + PROF_ROW_H + PAD

    local card = Instance.new("Frame")
    card.Name             = "USCard"
    card.Size             = UDim2.new(1, -16, 0, CARD_H_COLLAPSED)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel  = 0
    card.LayoutOrder      = 9999
    card.ClipsDescendants = true
    card.Parent           = PlayerTab.scroll
    Corner(card, 12)
    local cStroke = Stroke(card, T.Border, 1)

    local searchRow = Instance.new("Frame")
    searchRow.Name                   = "SearchRow"
    searchRow.Size                   = UDim2.new(1, -PAD * 2, 0, SEARCH_ROW_H)
    searchRow.Position               = UDim2.new(0, PAD, 0, PAD)
    searchRow.BackgroundTransparency = 1
    searchRow.ZIndex                 = 2
    searchRow.Parent                 = card
    local SEARCH_BTN_W = isMobile and 56 or 68
    local searchBox = Instance.new("TextBox")
    searchBox.Size                   = UDim2.new(1, -(SEARCH_BTN_W + 8), 1, 0)
    searchBox.Position               = UDim2.new(0, 0, 0, 0)
    searchBox.BackgroundColor3       = Color3.fromRGB(20, 20, 24)
    searchBox.BorderSizePixel        = 0
    searchBox.PlaceholderText        = "Search by username..."
    searchBox.Text                   = ""
    searchBox.TextSize               = isMobile and 11 or 13
    searchBox.Font                   = Enum.Font.Gotham
    searchBox.TextColor3             = T.White
    searchBox.PlaceholderColor3      = T.Dim
    searchBox.TextXAlignment         = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus       = false
    searchBox.ZIndex                 = 3
    searchBox.Parent                 = searchRow
    Corner(searchBox, 8)
    local searchBoxStroke = Stroke(searchBox, T.Border, 1)
    Padding(searchBox, 0, 0, 12, 12)
    searchBox.Focused:Connect(function() Tween(searchBoxStroke, F, { Color = T.White }) end)
    searchBox.FocusLost:Connect(function() Tween(searchBoxStroke, F, { Color = T.Border }) end)
    local searchBtn = Instance.new("TextButton")
    searchBtn.Size             = UDim2.new(0, SEARCH_BTN_W, 1, 0)
    searchBtn.Position         = UDim2.new(1, -SEARCH_BTN_W, 0, 0)
    searchBtn.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    searchBtn.BorderSizePixel  = 0
    searchBtn.Text             = "Find"
    searchBtn.TextSize         = isMobile and 11 or 13
    searchBtn.Font             = Enum.Font.GothamBold
    searchBtn.TextColor3       = Color3.fromRGB(15, 15, 15)
    searchBtn.AutoButtonColor  = false
    searchBtn.ZIndex           = 3
    searchBtn.Parent           = searchRow
    Corner(searchBtn, 8)

    local profile = Instance.new("Frame")
    profile.Name                   = "Profile"
    profile.Size                   = UDim2.new(1, -PAD * 2, 0, PROF_ROW_H)
    profile.Position               = UDim2.new(0, PAD, 0, PAD * 2 + SEARCH_ROW_H)
    profile.BackgroundColor3       = Color3.fromRGB(16, 16, 20)
    profile.BackgroundTransparency = 0.1
    profile.BorderSizePixel        = 0
    profile.Visible                = false
    profile.ZIndex                 = 2
    profile.Parent                 = card
    Corner(profile, 10)
    Stroke(profile, T.Border, 1)

    local avFrame = Instance.new("Frame")
    avFrame.Position              = UDim2.new(0, PAD, 0.5, -PROF_AV / 2)
    avFrame.Size                  = UDim2.new(0, PROF_AV, 0, PROF_AV)
    avFrame.BackgroundColor3      = Color3.fromRGB(24, 24, 28)
    avFrame.BorderSizePixel       = 0
    avFrame.ClipsDescendants      = true
    avFrame.ZIndex                = 3
    avFrame.Parent                = profile
    Instance.new("UICorner", avFrame).CornerRadius = UDim.new(1, 0)
    local avRing = Instance.new("UIStroke", avFrame)
    avRing.Color     = T.White
    avRing.Thickness = 1
    avRing.Transparency = 0.6
    local avImg = Instance.new("ImageLabel")
    avImg.Size                   = UDim2.new(1, 0, 1, 0)
    avImg.BackgroundTransparency = 1
    avImg.Image                  = ""
    avImg.ZIndex                 = 4
    avImg.Parent                 = avFrame

    local SDOT = 8
    local searchDot = Instance.new("Frame")
    searchDot.Size              = UDim2.new(0, SDOT, 0, SDOT)
    searchDot.Position          = UDim2.new(1, -1, 1, -1)
    searchDot.AnchorPoint       = Vector2.new(1, 1)
    searchDot.BackgroundColor3  = Color3.fromRGB(60, 60, 65)
    searchDot.BorderSizePixel   = 0
    searchDot.ZIndex            = 5
    searchDot.Parent            = avFrame
    Instance.new("UICorner", searchDot).CornerRadius = UDim.new(1, 0)
    local sdotRing = Instance.new("UIStroke", searchDot)
    sdotRing.Color           = Color3.fromRGB(16, 16, 20)
    sdotRing.Thickness       = 2
    sdotRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local TEXT_X      = PAD + PROF_AV + PAD
    local BTN_RIGHT_W = BTN_W + PAD
    local TEXT_W      = -(TEXT_X + BTN_RIGHT_W + PAD)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Position              = UDim2.new(0, TEXT_X, 0, PAD - 2)
    nameLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 14 or 16)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                  = ""
    nameLbl.TextSize              = isMobile and 12 or 14
    nameLbl.Font                  = Enum.Font.GothamBold
    nameLbl.TextColor3            = T.White
    nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
    nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex                = 3
    nameLbl.Parent                = profile

    local idLbl = Instance.new("TextLabel")
    idLbl.Position              = UDim2.new(0, TEXT_X, 0, (isMobile and 18 or 22))
    idLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 11 or 13)
    idLbl.BackgroundTransparency = 1
    idLbl.Text                  = ""
    idLbl.TextSize              = isMobile and 9 or 10
    idLbl.Font                  = Enum.Font.Gotham
    idLbl.TextColor3            = T.Dim
    idLbl.TextXAlignment        = Enum.TextXAlignment.Left
    idLbl.TextTruncate          = Enum.TextTruncate.AtEnd
    idLbl.ZIndex                = 3
    idLbl.Parent                = profile

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Position              = UDim2.new(0, TEXT_X, 0, (isMobile and 31 or 38))
    statusLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 10 or 12)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text                  = ""
    statusLbl.TextSize              = isMobile and 9 or 10
    statusLbl.Font                  = Enum.Font.GothamMedium
    statusLbl.TextColor3            = T.Dim
    statusLbl.TextXAlignment        = Enum.TextXAlignment.Left
    statusLbl.ZIndex                = 3
    statusLbl.Parent                = profile

    local function _mkProfileBtn(text, bg, fg, yOff, hoverBg)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, BTN_W, 0, BTN_H)
        b.Position         = UDim2.new(1, -(BTN_W + PAD), 0, yOff)
        b.BackgroundColor3 = bg
        b.BorderSizePixel  = 0
        b.Text             = text
        b.TextSize         = isMobile and 10 or 11
        b.Font             = Enum.Font.GothamBold
        b.TextColor3       = fg
        b.AutoButtonColor  = false
        b.ZIndex           = 4
        b.Parent           = profile
        Corner(b, 7)
        Stroke(b, Color3.fromRGB(70, 70, 76), 1)
        b.MouseEnter:Connect(function() Tween(b, F, { BackgroundColor3 = hoverBg or T.CardHover }) end)
        b.MouseLeave:Connect(function() Tween(b, F, { BackgroundColor3 = bg }) end)
        return b
    end
    local totalBtnH = BTN_H * 2 + 4
    local btnStartY = math.floor((PROF_ROW_H - totalBtnH) / 2)
    local copyBtn  = _mkProfileBtn("Copy",  Color3.fromRGB(30, 30, 34), T.White,
                                   btnStartY, Color3.fromRGB(46, 46, 52))
    local tradeBtn = _mkProfileBtn("Trade", Color3.fromRGB(245, 245, 245), Color3.fromRGB(15, 15, 15),
                                   btnStartY + BTN_H + 4, Color3.fromRGB(220, 220, 220))

    local currentUserId   = nil
    local currentUserName = nil
    local CARD_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function setStatus(text, color)
        statusLbl.Text       = text or ""
        statusLbl.TextColor3 = color or T.Dim
    end
    local function showProfile(visible)
        if visible == profile.Visible then return end
        profile.Visible = visible
        local target = visible and CARD_H_EXPANDED or CARD_H_COLLAPSED
        TweenService:Create(card, CARD_TWEEN, { Size = UDim2.new(1, -16, 0, target) }):Play()
    end

    local _presenceJob = 0
    local function _stopPresence()
        _presenceJob = _presenceJob + 1
        searchDot.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    end
    local function _startPresence(userId)
        _presenceJob = _presenceJob + 1
        local myJob = _presenceJob
        searchDot.BackgroundColor3 = Players:GetPlayerByUserId(userId)
            and Color3.fromRGB(120, 220, 130)
            or  Color3.fromRGB(60, 60, 65)
        local httpReq = (syn and syn.request) or http_request or request
        if not httpReq then return end
        task.spawn(function()
            while myJob == _presenceJob and searchDot.Parent do
                local ok, res = pcall(function()
                    return httpReq({
                        Url     = "https://presence.roblox.com/v1/presence/users",
                        Method  = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body    = HttpService:JSONEncode({ userIds = { userId } }),
                    })
                end)
                if ok and res and res.Body then
                    local d; pcall(function() d = HttpService:JSONDecode(res.Body) end)
                    if d and d.userPresences and d.userPresences[1] then
                        local p = d.userPresences[1]
                        local isOnline = (tonumber(p.userPresenceType) or 0) ~= 0
                        if myJob == _presenceJob and searchDot.Parent then
                            searchDot.BackgroundColor3 = isOnline
                                and Color3.fromRGB(120, 220, 130)
                                or  Color3.fromRGB(230, 110, 110)
                        end
                    end
                end
                task.wait(4)
            end
        end)
    end

    local function setUser(userId, displayName, username)
        currentUserId   = userId
        currentUserName = username or displayName
        nameLbl.Text  = displayName or username or "Unknown"
        idLbl.Text    = (username and ("@" .. username .. "  |  ID: " .. tostring(userId)))
                        or ("ID: " .. tostring(userId))
        avImg.Image   = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
        showProfile(true)
        _startPresence(userId)
    end
    local function clearUser()
        currentUserId, currentUserName = nil, nil
        nameLbl.Text = ""
        idLbl.Text   = ""
        avImg.Image  = ""
        showProfile(false)
        _stopPresence()
    end

    local _isSearching = false
    local function doSearch()
        if _isSearching then return end
        local q = (searchBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" then
            clearUser()
            setStatus("Enter a username", Color3.fromRGB(220, 180, 90))
            return
        end
        _isSearching = true
        searchBtn.Text = "..."
        setStatus("Looking up " .. q, T.Dim)
        task.spawn(function()
            local idAttempt = tonumber(q)
            local ok, info = pcall(function()
                if idAttempt then
                    return { UserId = idAttempt, Name = Players:GetNameFromUserIdAsync(idAttempt), Username = nil }
                else
                    local uid = Players:GetUserIdFromNameAsync(q)
                    return { UserId = uid, Name = Players:GetNameFromUserIdAsync(uid), Username = q }
                end
            end)
            searchBtn.Text = "Find"
            _isSearching = false
            if not ok or not info or not info.UserId then
                clearUser()
                setStatus("Not found: " .. q, Color3.fromRGB(230, 110, 110))
                return
            end
            setUser(info.UserId, info.Name, info.Username)
            setStatus("Profile loaded", Color3.fromRGB(120, 220, 130))
        end)
    end

    searchBtn.MouseEnter:Connect(function() Tween(searchBtn, F, { BackgroundColor3 = Color3.fromRGB(220, 220, 220) }) end)
    searchBtn.MouseLeave:Connect(function() Tween(searchBtn, F, { BackgroundColor3 = Color3.fromRGB(245, 245, 245) }) end)
    searchBtn.MouseButton1Click:Connect(doSearch)
    searchBox.FocusLost:Connect(function(enterPressed) if enterPressed then doSearch() end end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchBox.Text == "" then
            clearUser()
            setStatus("", T.Dim)
        end
    end)
    copyBtn.MouseButton1Click:Connect(function()
        if not currentUserId then return end
        local url = "https://www.roblox.com/users/" .. tostring(currentUserId) .. "/profile"
        local copied = false
        pcall(function() setclipboard(url); copied = true end)
        if not copied then pcall(function() toclipboard(url); copied = true end) end
        setStatus(copied and "Profile link copied" or "Clipboard unsupported",
                  copied and Color3.fromRGB(120, 220, 130) or Color3.fromRGB(230, 110, 110))
    end)
    tradeBtn.MouseButton1Click:Connect(function()
        if not currentUserId then return end
        setStatus("Sending trade...", T.Dim)
        invokeTrade(currentUserId, function(success, msg)
            setStatus(success and ("Trade " .. (msg or "sent"))
                              or ("Trade failed: " .. tostring(msg or "?")),
                      success and Color3.fromRGB(120, 220, 130)
                              or  Color3.fromRGB(230, 110, 110))
        end)
    end)
    local _cardHov = false
    card.MouseEnter:Connect(function()
        if _cardHov then return end
        _cardHov = true
        Tween(card,    F, {BackgroundColor3 = T.CardHover})
        Tween(cStroke, F, {Color = T.BorderHover})
    end)
    card.MouseLeave:Connect(function()
        if not _cardHov then return end
        _cardHov = false
        Tween(card,    F, {BackgroundColor3 = T.Card})
        Tween(cStroke, F, {Color = T.Border})
    end)
end)()

do
    local function _hsvToColor(h, s, v)
        return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1))
    end
    local function _rgbToHsv(c)
        local r, g, b = c.R, c.G, c.B
        local mx, mn = math.max(r, g, b), math.min(r, g, b)
        local d = mx - mn
        local h
        if d == 0 then h = 0
        elseif mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else                h = (r - g) / d + 4 end
        h = h / 6
        if h < 0 then h = h + 1 end
        local s = (mx == 0) and 0 or (d / mx)
        return h, s, mx
    end
    CreateSection(MiscTab.scroll, "UI THEME")
    local CARD_H = 96
    local themeCard = Instance.new("Frame")
    themeCard.Size             = UDim2.new(1, -16, 0, CARD_H)
    themeCard.BackgroundColor3 = T.Card
    themeCard.BackgroundTransparency = 0.15
    themeCard.BorderSizePixel  = 0
    themeCard.LayoutOrder      = -1000
    themeCard.Parent           = MiscTab.scroll
    Corner(themeCard, 10)
    do
        local tcStroke = Stroke(themeCard, Color3.fromRGB(255, 255, 255), 1)
        _FH_AddThemeStroke(tcStroke)
    end
    local titleLbl = Label(themeCard, "Accent Colors", isMobile and 11 or 13, T.White, Enum.Font.GothamBold)
    titleLbl.Size     = UDim2.new(1, -20, 0, 16)
    titleLbl.Position = UDim2.new(0, 12, 0, 10)
    titleLbl.ZIndex   = 2
    local subLbl = Label(themeCard, "Tap a swatch — changes apply instantly", isMobile and 9 or 10, T.Dim, Enum.Font.Gotham)
    subLbl.Size     = UDim2.new(1, -20, 0, 12)
    subLbl.Position = UDim2.new(0, 12, 0, 28)
    subLbl.ZIndex   = 2

    local SW_W, SW_H = isMobile and 70 or 84, 32
    local function _makeSwatch(label, x, getColor, onOpen)
        local sw = Instance.new("TextButton")
        sw.Size             = UDim2.new(0, SW_W, 0, SW_H)
        sw.Position         = UDim2.new(0, x, 0, 50)
        sw.BackgroundColor3 = getColor()
        sw.BorderSizePixel  = 0
        sw.Text             = label
        sw.TextSize         = 10
        sw.Font             = Enum.Font.GothamBold
        sw.TextColor3       = Color3.fromRGB(20, 20, 20)
        sw.AutoButtonColor  = false
        sw.ZIndex           = 3
        sw.Parent           = themeCard
        Corner(sw, 8)
        do
            local swStroke = Stroke(sw, Color3.fromRGB(255, 255, 255), 1)
            _FH_AddThemeStroke(swStroke)
        end
        sw.MouseButton1Click:Connect(onOpen)
        return sw
    end
    local swA, swB
    local pickerOpen = false
    local function _openPicker(slot)
        if pickerOpen then return end
        pickerOpen = true
        local W, H = isMobile and 240 or 280, isMobile and 240 or 270
        local modal = Instance.new("Frame")
        modal.Size             = UDim2.new(0, W, 0, H)
        modal.AnchorPoint      = Vector2.new(0.5, 0.5)
        modal.Position         = UDim2.new(0.5, 0, 0.5, 0)
        modal.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
        modal.BackgroundTransparency = 0.05
        modal.BorderSizePixel  = 0
        modal.ZIndex           = 60
        modal.Parent           = GUI
        Corner(modal, 12)
        local modalStroke = Stroke(modal, Color3.fromRGB(255, 255, 255), 1)
        _FH_AddThemeStroke(modalStroke)

        local hdr = Instance.new("Frame")
        hdr.Size                   = UDim2.new(1, 0, 0, 30)
        hdr.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
        hdr.BorderSizePixel        = 0
        hdr.ZIndex                 = 61
        hdr.Parent                 = modal
        Corner(hdr, 12)
        local hdrLbl = Label(hdr, slot == "a" and "Pick Accent A" or "Pick Accent B", 12, T.White, Enum.Font.GothamBold)
        hdrLbl.Size          = UDim2.new(1, -40, 1, 0)
        hdrLbl.Position      = UDim2.new(0, 12, 0, 0)
        hdrLbl.TextYAlignment = Enum.TextYAlignment.Center
        hdrLbl.ZIndex        = 62
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size             = UDim2.new(0, 22, 0, 22)
        closeBtn.Position         = UDim2.new(1, -28, 0.5, -11)
        closeBtn.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
        closeBtn.BorderSizePixel  = 0
        closeBtn.Text             = "×"
        closeBtn.TextSize         = 14
        closeBtn.Font             = Enum.Font.GothamBold
        closeBtn.TextColor3       = T.White
        closeBtn.AutoButtonColor  = false
        closeBtn.ZIndex           = 62
        closeBtn.Parent           = hdr
        Corner(closeBtn, 6)

        local startColor = (slot == "a") and _G._FH_AccentA or _G._FH_AccentB
        local curH, curS, curV = _rgbToHsv(startColor)

        local SQ = isMobile and 150 or 170
        local HUE_H = 16
        local PADX = (W - SQ) / 2

        local sv = Instance.new("Frame")
        sv.Size                   = UDim2.new(0, SQ, 0, SQ)
        sv.Position               = UDim2.new(0, PADX, 0, 40)
        sv.BackgroundColor3       = _hsvToColor(curH, 1, 1)
        sv.BorderSizePixel        = 0
        sv.ZIndex                 = 61
        sv.Active                 = true
        sv.Parent                 = modal
        Corner(sv, 6)

        local whiteOv = Instance.new("Frame")
        whiteOv.Size                   = UDim2.new(1, 0, 1, 0)
        whiteOv.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
        whiteOv.BorderSizePixel        = 0
        whiteOv.ZIndex                 = 62
        whiteOv.Parent                 = sv
        Corner(whiteOv, 6)
        do
            local g = Instance.new("UIGradient", whiteOv)
            g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
        end

        local blackOv = Instance.new("Frame")
        blackOv.Size                   = UDim2.new(1, 0, 1, 0)
        blackOv.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        blackOv.BorderSizePixel        = 0
        blackOv.ZIndex                 = 63
        blackOv.Parent                 = sv
        Corner(blackOv, 6)
        do
            local g = Instance.new("UIGradient", blackOv)
            g.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            g.Rotation = 90
        end

        local svDot = Instance.new("Frame")
        svDot.AnchorPoint           = Vector2.new(0.5, 0.5)
        svDot.Size                  = UDim2.new(0, 12, 0, 12)
        svDot.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
        svDot.BackgroundTransparency = 1
        svDot.BorderSizePixel       = 0
        svDot.ZIndex                = 65
        svDot.Parent                = sv
        Instance.new("UICorner", svDot).CornerRadius = UDim.new(1, 0)
        Stroke(svDot, Color3.fromRGB(255, 255, 255), 2)

        local hue = Instance.new("Frame")
        hue.Size             = UDim2.new(0, SQ, 0, HUE_H)
        hue.Position         = UDim2.new(0, PADX, 0, 40 + SQ + 10)
        hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hue.BorderSizePixel  = 0
        hue.ZIndex           = 61
        hue.Active           = true
        hue.Parent           = modal
        Corner(hue, HUE_H/2)
        do
            local g = Instance.new("UIGradient", hue)
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
            })
        end
        local hueDot = Instance.new("Frame")
        hueDot.AnchorPoint      = Vector2.new(0.5, 0.5)
        hueDot.Size             = UDim2.new(0, 4, 1, 4)
        hueDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hueDot.BorderSizePixel  = 0
        hueDot.ZIndex           = 64
        hueDot.Parent           = hue
        Stroke(hueDot, Color3.fromRGB(0, 0, 0), 1)
        Corner(hueDot, 2)

        local preview = Instance.new("Frame")
        preview.Size             = UDim2.new(0, 28, 0, 28)
        preview.Position         = UDim2.new(0, PADX, 1, -42)
        preview.BackgroundColor3 = startColor
        preview.BorderSizePixel  = 0
        preview.ZIndex           = 61
        preview.Parent           = modal
        Corner(preview, 6)
        Stroke(preview, T.Border, 1)
        local hexLbl = Label(modal, "", 12, T.White, Enum.Font.GothamMedium)
        hexLbl.Size     = UDim2.new(0, 100, 0, 28)
        hexLbl.Position = UDim2.new(0, PADX + 36, 1, -42)
        hexLbl.TextXAlignment = Enum.TextXAlignment.Left
        hexLbl.TextYAlignment = Enum.TextYAlignment.Center
        hexLbl.ZIndex   = 62
        local function refresh()
            local col = _hsvToColor(curH, curS, curV)
            sv.BackgroundColor3 = _hsvToColor(curH, 1, 1)
            preview.BackgroundColor3 = col
            hexLbl.Text = string.format("#%02X%02X%02X",
                math.floor(col.R * 255 + 0.5),
                math.floor(col.G * 255 + 0.5),
                math.floor(col.B * 255 + 0.5))
            svDot.Position = UDim2.new(curS, 0, 1 - curV, 0)
            hueDot.Position = UDim2.new(curH, 0, 0.5, 0)

            if slot == "a" then
                _G._FH_AccentA = col
                swA.BackgroundColor3 = col
            else
                _G._FH_AccentB = col
                swB.BackgroundColor3 = col
            end
            local seq = _FH_BuildThemeSequence()
            for _, g in ipairs(_G._FH_ThemeStrokes) do pcall(function() g.Color = seq end) end
            for _, g in ipairs(_G._FH_ThemeFills)   do pcall(function() g.Color = seq end) end

            if _G._FH_RecolorPlayerESP then pcall(_G._FH_RecolorPlayerESP) end
        end
        refresh()

        do
            local active = false
            local function update(inp)
                local abs = sv.AbsolutePosition
                local sz  = sv.AbsoluteSize
                if sz.X <= 0 or sz.Y <= 0 then return end
                local px = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                local py = math.clamp((inp.Position.Y - abs.Y) / sz.Y, 0, 1)
                curS = px
                curV = 1 - py
                refresh()
            end
            sv.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    active = true
                    update(inp)
                end
            end)
            sv.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    if active then _FH_UpdateThemeColors() end
                    active = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if active and (inp.UserInputType == Enum.UserInputType.MouseMovement
                            or inp.UserInputType == Enum.UserInputType.Touch) then
                    update(inp)
                end
            end)
        end

        do
            local active = false
            local function update(inp)
                local abs = hue.AbsolutePosition
                local sz  = hue.AbsoluteSize
                if sz.X <= 0 then return end
                curH = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                refresh()
            end
            hue.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    active = true
                    update(inp)
                end
            end)
            hue.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    if active then _FH_UpdateThemeColors() end
                    active = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if active and (inp.UserInputType == Enum.UserInputType.MouseMovement
                            or inp.UserInputType == Enum.UserInputType.Touch) then
                    update(inp)
                end
            end)
        end
        local function closeModal()
            pickerOpen = false
            if modal and modal.Parent then modal:Destroy() end
        end
        closeBtn.MouseButton1Click:Connect(function()
            _FH_UpdateThemeColors()
            closeModal()
        end)

        do
            local d, ds, ps = false, nil, nil
            hdr.Active = true
            hdr.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    d = true; ds = inp.Position; ps = modal.Position
                end
            end)
            hdr.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    d = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if d and (inp.UserInputType == Enum.UserInputType.MouseMovement
                       or inp.UserInputType == Enum.UserInputType.Touch) then
                    local dx, dy = inp.Position.X - ds.X, inp.Position.Y - ds.Y
                    modal.Position = UDim2.new(ps.X.Scale, ps.X.Offset + dx, ps.Y.Scale, ps.Y.Offset + dy)
                end
            end)
        end
    end
    swA = _makeSwatch("A", 12,         function() return _G._FH_AccentA end, function() _openPicker("a") end)
    swB = _makeSwatch("B", 12 + SW_W + 8, function() return _G._FH_AccentB end, function() _openPicker("b") end)

    local preview = Instance.new("Frame")
    preview.Size             = UDim2.new(1, -(12 + (SW_W + 8) * 2 + 12), 0, SW_H)
    preview.Position         = UDim2.new(0, 12 + (SW_W + 8) * 2, 0, 50)
    preview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    preview.BorderSizePixel  = 0
    preview.ZIndex           = 3
    preview.Parent           = themeCard
    Corner(preview, 8)
    _FH_AddThemeFill(preview)
end

do

    do
        local saved = Config.sliders and Config.sliders.subspace_mine_color
        if type(saved) == "table" and #saved == 3 then
            _G._FH_SubspaceColor = Color3.fromRGB(
                tonumber(saved[1]) or 255,
                tonumber(saved[2]) or 255,
                tonumber(saved[3]) or 255
            )
        else
            _G._FH_SubspaceColor = Color3.fromRGB(255, 255, 255)
        end
    end

    CreateSection(MiscTab.scroll, "Subspace Mine ESP")

    local CARD_H = isMobile and 96 or 108
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, -16, 0, CARD_H)
    card.BackgroundColor3       = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel        = 0
    card.LayoutOrder            = -990
    card.Parent                 = MiscTab.scroll
    Corner(card, 10)
    do
        local cStroke = Stroke(card, Color3.fromRGB(255, 255, 255), 1)
        _FH_AddThemeStroke(cStroke)
    end

    local titleLbl = Label(card, "Subspace Mine Color", isMobile and 11 or 13, T.White, Enum.Font.GothamBold)
    titleLbl.Size     = UDim2.new(1, -90, 0, 16)
    titleLbl.Position = UDim2.new(0, 12, 0, 10)
    titleLbl.ZIndex   = 2

    local hexLbl = Label(card, "", isMobile and 9 or 10, T.Dim, Enum.Font.Code)
    hexLbl.Size              = UDim2.new(0, 76, 0, 16)
    hexLbl.Position          = UDim2.new(1, -84, 0, 10)
    hexLbl.TextXAlignment    = Enum.TextXAlignment.Right
    hexLbl.ZIndex            = 2

    local subLbl = Label(card, "Tap a swatch — applies live to every mine box", isMobile and 8 or 10, T.Dim, Enum.Font.Gotham)
    subLbl.Size     = UDim2.new(1, -20, 0, 12)
    subLbl.Position = UDim2.new(0, 12, 0, 28)
    subLbl.ZIndex   = 2

    local previewBar = Instance.new("Frame")
    previewBar.Size                   = UDim2.new(1, -24, 0, 14)
    previewBar.Position               = UDim2.new(0, 12, 0, 44)
    previewBar.BackgroundColor3       = _G._FH_SubspaceColor
    previewBar.BorderSizePixel        = 0
    previewBar.ZIndex                 = 2
    previewBar.Parent                 = card
    Corner(previewBar, 7)
    Stroke(previewBar, Color3.fromRGB(40, 40, 40), 1)

    local chipsRow = Instance.new("Frame")
    chipsRow.Size                   = UDim2.new(1, -24, 0, isMobile and 26 or 30)
    chipsRow.Position               = UDim2.new(0, 12, 0, 64)
    chipsRow.BackgroundTransparency = 1
    chipsRow.ZIndex                 = 2
    chipsRow.Parent                 = card

    local chipsLayout = Instance.new("UIListLayout")
    chipsLayout.FillDirection        = Enum.FillDirection.Horizontal
    chipsLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
    chipsLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
    chipsLayout.Padding              = UDim.new(0, isMobile and 5 or 6)
    chipsLayout.SortOrder            = Enum.SortOrder.LayoutOrder
    chipsLayout.Parent               = chipsRow

    local PRESETS = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(255,  70,  70),
        Color3.fromRGB(255, 150,  40),
        Color3.fromRGB(255, 230,  60),
        Color3.fromRGB( 70, 230, 110),
        Color3.fromRGB( 60, 220, 230),
        Color3.fromRGB( 80, 140, 255),
        Color3.fromRGB(220, 110, 255),
    }

    local CHIP_SZ = isMobile and 22 or 26
    local chipFrames = {}

    local function _colorsEqual(a, b)
        return math.abs(a.R - b.R) < 0.01
            and math.abs(a.G - b.G) < 0.01
            and math.abs(a.B - b.B) < 0.01
    end

    local function _refreshHex()
        local c = _G._FH_SubspaceColor
        hexLbl.Text = string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5))
    end

    local function _updateActiveRing()
        for col, info in pairs(chipFrames) do
            local active = _colorsEqual(col, _G._FH_SubspaceColor)
            info.stroke.Color     = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
            info.stroke.Thickness = active and 2 or 1
        end
    end

    local function _commitColor(col)
        _G._FH_SubspaceColor = col
        previewBar.BackgroundColor3 = col
        _refreshHex()
        _updateActiveRing()
        Config.sliders = Config.sliders or {}
        Config.sliders.subspace_mine_color = {
            math.floor(col.R * 255 + 0.5),
            math.floor(col.G * 255 + 0.5),
            math.floor(col.B * 255 + 0.5),
        }
        pcall(FH_SaveConfig)
        if _G._FH_SubspaceRecolor then pcall(_G._FH_SubspaceRecolor) end
    end

    for i, col in ipairs(PRESETS) do
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, CHIP_SZ, 0, CHIP_SZ)
        btn.BackgroundColor3 = col
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = i
        btn.ZIndex           = 3
        btn.Parent           = chipsRow
        local round = Instance.new("UICorner")
        round.CornerRadius = UDim.new(1, 0)
        round.Parent       = btn
        local chipStroke = Stroke(btn, Color3.fromRGB(50, 50, 50), 1)
        chipFrames[col] = { btn = btn, stroke = chipStroke }
        btn.MouseEnter:Connect(function()
            if not _colorsEqual(col, _G._FH_SubspaceColor) then
                Tween(btn, F, { Size = UDim2.new(0, CHIP_SZ + 2, 0, CHIP_SZ + 2) })
            end
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, F, { Size = UDim2.new(0, CHIP_SZ, 0, CHIP_SZ) })
        end)
        btn.MouseButton1Click:Connect(function() _commitColor(col) end)
    end

    _refreshHex()
    _updateActiveRing()
end

CreateSection(MiscTab.scroll, "Admin Panel Uses")
CreateToggle(MiscTab.scroll, "Spammer Panel", "Opens an Admin Panel panel", function(v)
    if not _G.SpammerGui then
        local spamW, spamH = isMobile and 190 or 220, isMobile and 220 or 260
        local spamBorder = Instance.new("Frame")
        spamBorder.Name = "SpammerGradBorder"
spamBorder.Size = UDim2.new(0, spamW + 4, 0, spamH + 4)
        spamBorder.Position = UDim2.new(0.5, -(spamW + 4)/2, 0, 140)
        spamBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        spamBorder.BorderSizePixel = 0
        spamBorder.ZIndex = 18
        spamBorder.Parent = GUI
        spamBorder.BackgroundTransparency = 1
        Corner(spamBorder, 12)
        local spamWin = Instance.new("Frame")
        spamWin.Name = "SpammerPanel"
spamWin.Size = UDim2.new(0, spamW, 0, spamH)
        spamWin.Position = UDim2.new(0.5, -spamW/2, 0, 142)
        spamWin.BackgroundColor3       = T.BG
        spamWin.BackgroundTransparency = 0.25
        spamWin.BorderSizePixel = 0
        spamWin.ZIndex = 19
        spamWin.ClipsDescendants = true
        spamWin.Parent = GUI
        Corner(spamWin, 10)
        local spamHdr = Instance.new("Frame")
        spamHdr.Size = UDim2.new(1, 0, 0, 36)
        spamHdr.BackgroundColor3 = T.Header
        spamHdr.BorderSizePixel = 0
        spamHdr.ZIndex = 20
        spamHdr.Active = true
        spamHdr.Parent = spamWin
        Corner(spamHdr, 10)
        local spamHdrFill = Instance.new("Frame")
        spamHdrFill.Size = UDim2.new(1, 0, 0, 10)
        spamHdrFill.Position = UDim2.new(0, 0, 1, -10)
        spamHdrFill.BackgroundColor3 = T.Header
        spamHdrFill.BorderSizePixel = 0
        spamHdrFill.ZIndex = 20
        spamHdrFill.Parent = spamHdr
        local spamHdrLine = Instance.new("Frame")
        spamHdrLine.Size = UDim2.new(1, 0, 0, 1)
        spamHdrLine.Position = UDim2.new(0, 0, 1, -1)
        spamHdrLine.BackgroundColor3 = T.Border
        spamHdrLine.BorderSizePixel = 0
        spamHdrLine.ZIndex = 21
        spamHdrLine.Parent = spamHdr
        local spamTitle = Label(spamHdr, "Admin Spammer", 13, T.White, Enum.Font.GothamBold)
        spamTitle.Size = UDim2.new(1, -40, 1, 0)
        spamTitle.Position = UDim2.new(0, 12, 0, 0)
        spamTitle.TextYAlignment = Enum.TextYAlignment.Center
        spamTitle.ZIndex = 22
        local spamClose = Instance.new("TextButton")
        spamClose.Size = UDim2.new(0, 22, 0, 22)
        spamClose.Position = UDim2.new(1, -28, 0.5, -11)
        spamClose.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
        spamClose.BorderSizePixel = 0
        spamClose.Text = "×"
spamClose.TextSize = 14
        spamClose.Font = Enum.Font.GothamBold
        spamClose.TextColor3 = T.White
        spamClose.ZIndex = 23
        spamClose.Parent = spamHdr
        Corner(spamClose, 6)
        spamClose.MouseButton1Click:Connect(function()
            spamWin.Visible = false
            spamBorder.Visible = false
            local reg = configRegistry["Spammer Panel"]
            if reg and reg.getState() then reg.doToggle() end
        end)
        local spamHint = Instance.new("TextLabel")
        spamHint.Size = UDim2.new(1, -16, 0, 24)
        spamHint.Position = UDim2.new(0, 8, 0, 40)
        spamHint.BackgroundTransparency = 1
        spamHint.Text = "Click ⚙ to edit Semi/Full • Right-click Spam Closest to bind key"
spamHint.TextSize = 10
        spamHint.Font = Enum.Font.Gotham
        spamHint.TextColor3 = T.Dim
        spamHint.TextWrapped = true
        spamHint.ZIndex = 20
        spamHint.Parent = spamWin
        local plrLbl = Instance.new("TextLabel")
        plrLbl.Size = UDim2.new(1, -16, 0, 14)
        plrLbl.Position = UDim2.new(0, 8, 0, 66)
        plrLbl.BackgroundTransparency = 1
        plrLbl.Text = "PLAYERS"
plrLbl.TextSize = 10
        plrLbl.Font = Enum.Font.GothamBold
        plrLbl.TextColor3 = T.Dim
        plrLbl.ZIndex = 20
        plrLbl.Parent = spamWin
        local spamScroll = Instance.new("ScrollingFrame")
        spamScroll.Size = UDim2.new(1, -16, 1, -124)
        spamScroll.Position = UDim2.new(0, 8, 0, 82)
        spamScroll.BackgroundTransparency = 1
        spamScroll.BorderSizePixel = 0
        spamScroll.ScrollBarThickness = 3
        spamScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
        spamScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        spamScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        spamScroll.ZIndex = 19
        spamScroll.Parent = spamWin
        local spamLayout = Instance.new("UIListLayout")
        spamLayout.Padding = UDim.new(0, 4)
        spamLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        spamLayout.Parent = spamScroll
        Padding(spamScroll, 4, 4, 0, 0)
        local ALL_SPAM_CMDS = {"balloon","tiny","rocket","ragdoll","inverse","jail","morph","jumpscare"}

        Config.spammer = Config.spammer or {}
        local function _cloneCmdList(t)
            local out = {}
            if type(t) == "table" then
                for _, v in ipairs(t) do
                    if type(v) == "string" then table.insert(out, v) end
                end
            end
            return out
        end
        local _savedSemi = _cloneCmdList(Config.spammer.semi)
        local _savedFull = _cloneCmdList(Config.spammer.full)
        _G._FH_SEMI_CMDS = (#_savedSemi > 0 and _savedSemi)
            or {"balloon","tiny","rocket","inverse"}
        _G._FH_FULL_CMDS = (#_savedFull > 0 and _savedFull)
            or {"balloon","tiny","rocket","ragdoll","inverse","jail","morph","jumpscare"}
        local function _saveSpammerCfg()
            Config.spammer = Config.spammer or {}
            Config.spammer.semi = _G._FH_SEMI_CMDS
            Config.spammer.full = _G._FH_FULL_CMDS
            pcall(FH_SaveConfig)
        end
        local function getSpamSemiCmds() return _G._FH_SEMI_CMDS end
        local function getSpamFullCmds() return _G._FH_FULL_CMDS end
        local spamProfileCache = {}
        local spamCommandCache = {}
        local function spamGetFrames()
            local ap = Players.LocalPlayer.PlayerGui:FindFirstChild("AdminPanel")
            if not ap then return nil, nil end
            local inner = ap:FindFirstChild("AdminPanel")
            if not inner then return nil, nil end
            local c = inner:FindFirstChild("Content")
            local p = inner:FindFirstChild("Profiles")
            if not c or not p then return nil, nil end
            return c:FindFirstChild("ScrollingFrame"), p:FindFirstChild("ScrollingFrame")
        end
        local function spamCacheBtn(btn)
            local out = {}
            local ok, conns = pcall(getconnections, btn.Activated)
            if ok and type(conns) == "table"then
                for _, c in ipairs(conns) do
                    if type(c.Function) == "function"then table.insert(out, c.Function) end
                end
            end
            return out
        end
        local function spamFire(fns)
            for _, fn in ipairs(fns) do task.spawn(fn) end
        end
        _G._FH_CD_RECENT = _G._FH_CD_RECENT or {}
        local function _spamIsOnCD(cmd)
            local cd = _G._FH_CD_ONCD and _G._FH_CD_ONCD[cmd]
            if cd then return true end
            local rec = _G._FH_CD_RECENT[cmd]
            if rec and tick() < rec then return true end
            return false
        end
        local function spamRun(target, cmds)
            local cf, pf = spamGetFrames()
            if not cf or not pf then return end
            local pb = pf:FindFirstChild(target.Name)
            if not pb then return end
            if not spamProfileCache[target.Name] then
                spamProfileCache[target.Name] = spamCacheBtn(pb)
            end
            for _, cmd in ipairs(cmds) do
                if not _spamIsOnCD(cmd) then
                    if not spamCommandCache[cmd] then
                        local cb = cf:FindFirstChild(cmd)
                        if cb then spamCommandCache[cmd] = spamCacheBtn(cb) end
                    end
                    local cc = spamCommandCache[cmd]
                    if cc and #cc > 0 then
                        spamFire(cc)
                        spamFire(spamProfileCache[target.Name])
                        _G._FH_CD_RECENT[cmd] = tick() + 0.6
                    end
                end
            end
        end
        local spamSemiKBClick, spamFullKBClick
        local function spamAddRow(plr)
            if plr == Players.LocalPlayer then return end
            if spamScroll:FindFirstChild("row_"..plr.Name) then return end
            local rowH = isMobile and 36 or 34
            local row = Instance.new("Frame")
            row.Name = "row_"..plr.Name
            row.Size = UDim2.new(1, -8, 0, rowH)
            row.BackgroundColor3 = T.Card
            row.BorderSizePixel = 0
            row.ZIndex = 20
            row.Parent = spamScroll
            Corner(row, 8)
            Stroke(row, T.Border, 1)
            local nameLbl = Label(row, plr.Name, isMobile and 11 or 12, T.White, Enum.Font.GothamMedium)
            nameLbl.Size = UDim2.new(1, -96, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.TextYAlignment = Enum.TextYAlignment.Center
            nameLbl.ZIndex = 21
            local btnH = isMobile and 26 or 24
            local sBtn = Instance.new("TextButton")
            sBtn.Size = UDim2.new(0, 40, 0, btnH)
            sBtn.Position = UDim2.new(1, -88, 0.5, -btnH/2)
            sBtn.BackgroundColor3 = Color3.fromRGB(20, 70, 30)
            sBtn.BorderSizePixel = 0
            sBtn.Text = "Semi"
sBtn.TextSize = 10
            sBtn.Font = Enum.Font.GothamBold
            sBtn.TextColor3 = Color3.fromRGB(100, 220, 120)
            sBtn.ZIndex = 21
            sBtn.Parent = row
            Corner(sBtn, 6)
            local sSDebounce = false
            local function sfire() if sSDebounce then return end; sSDebounce=true; task.spawn(spamRun,plr,getSpamSemiCmds()); task.delay(0.5,function() sSDebounce=false end) end
            sBtn.MouseButton1Click:Connect(sfire)
            do
                local _sBtnTouchStart = nil
                sBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch then
                        _sBtnTouchStart = inp.Position
                    elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
                        spamSemiKBClick(inp)
                    end
                end)
                sBtn.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch and _sBtnTouchStart then
                        local mag = (inp.Position - _sBtnTouchStart).Magnitude
                        _sBtnTouchStart = nil
                        if mag < 20 then sfire() end
                    end
                end)
            end
            local fBtn = Instance.new("TextButton")
            fBtn.Size = UDim2.new(0, 40, 0, btnH)
            fBtn.Position = UDim2.new(1, -44, 0.5, -btnH/2)
            fBtn.BackgroundColor3 = Color3.fromRGB(70, 15, 15)
            fBtn.BorderSizePixel = 0
            fBtn.Text = "Full"
fBtn.TextSize = 10
            fBtn.Font = Enum.Font.GothamBold
            fBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
            fBtn.ZIndex = 21
            fBtn.Parent = row
            Corner(fBtn, 6)
            local sFDebounce = false
            local function ffire() if sFDebounce then return end; sFDebounce=true; task.spawn(spamRun,plr,getSpamFullCmds()); task.delay(0.5,function() sFDebounce=false end) end
            fBtn.MouseButton1Click:Connect(ffire)
            do
                local _fBtnTouchStart = nil
                fBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch then
                        _fBtnTouchStart = inp.Position
                    elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
                        spamFullKBClick(inp)
                    end
                end)
                fBtn.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch and _fBtnTouchStart then
                        local mag = (inp.Position - _fBtnTouchStart).Magnitude
                        _fBtnTouchStart = nil
                        if mag < 20 then ffire() end
                    end
                end)
            end
        end
        local function spamRefresh()
            for _, c in ipairs(spamScroll:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            spamProfileCache = {}
            for _, plr in ipairs(Players:GetPlayers()) do spamAddRow(plr) end
        end
        Players.PlayerAdded:Connect(function(plr) if spamWin.Visible then spamAddRow(plr) end end)
        Players.PlayerRemoving:Connect(function(plr)
            spamProfileCache[plr.Name] = nil
            local r = spamScroll:FindFirstChild("row_"..plr.Name)
            if r then r:Destroy() end
        end)
        local sDrag, sDragStart, sPanelStart = false, nil, nil
        spamHdr.InputBegan:Connect(function(inp)
            if _G._FH_GUI_LOCKED then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                sDrag = true
                _G._FH_SPAM_DRAG = true
                sDragStart = inp.Position; sPanelStart = spamWin.Position
            end
        end)
        spamHdr.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                sDrag = false
                _G._FH_SPAM_DRAG = false
                Config.mini = Config.mini or {}
                Config.mini.spam_pos = { x = spamWin.Position.X.Offset, y = spamWin.Position.Y.Offset,
                                         xs = spamWin.Position.X.Scale, ys = spamWin.Position.Y.Scale }
                pcall(FH_SaveConfig)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if sDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - sDragStart
                local np = UDim2.new(sPanelStart.X.Scale, sPanelStart.X.Offset + d.X, sPanelStart.Y.Scale, sPanelStart.Y.Offset + d.Y)
                spamWin.Position = np
                spamBorder.Position = UDim2.new(np.X.Scale, np.X.Offset - 2, np.Y.Scale, np.Y.Offset - 2)
            end
        end)
        local customizeBtn = Instance.new("TextButton")
        customizeBtn.Size             = UDim2.new(0, 24, 0, 24)
        customizeBtn.Position         = UDim2.new(1, -56, 0.5, -12)
        customizeBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        customizeBtn.BorderSizePixel  = 0
        customizeBtn.Text             = "⚙"
customizeBtn.TextSize         = 14
        customizeBtn.Font             = Enum.Font.GothamBold
        customizeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        customizeBtn.ZIndex           = 23
        customizeBtn.Parent           = spamHdr
        Corner(customizeBtn, 6)
        Stroke(customizeBtn, Color3.fromRGB(255, 255, 255), 1)
        _G._FH_SPAM_SEMI_KB = _G._FH_SPAM_SEMI_KB or { keyCode = nil }
        _G._FH_SPAM_FULL_KB = _G._FH_SPAM_FULL_KB or { keyCode = nil }
        do
            local _ss = Config and Config.keybinds and Config.keybinds["sp_spam_semi"]
            if type(_ss) == "string" then
                local _kc = Enum.KeyCode[_ss]
                if _kc then _G._FH_SPAM_SEMI_KB.keyCode = _kc end
            end
            local _fs = Config and Config.keybinds and Config.keybinds["sp_spam_full"]
            if type(_fs) == "string" then
                local _kc = Enum.KeyCode[_fs]
                if _kc then _G._FH_SPAM_FULL_KB.keyCode = _kc end
            end
        end
        local semiKBLbl = Instance.new("TextLabel")
        semiKBLbl.Size = UDim2.new(0, 50, 0, 14)
        semiKBLbl.Position = UDim2.new(1, -92, 0, 26)
        semiKBLbl.BackgroundTransparency = 1
        semiKBLbl.Text = ""
semiKBLbl.TextSize = 9
        semiKBLbl.Font = Enum.Font.GothamBold
        semiKBLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
        semiKBLbl.TextXAlignment = Enum.TextXAlignment.Center
        semiKBLbl.ZIndex = 21
        semiKBLbl.Parent = spamWin
        _G._FH_SPAM_SEMI_LBL = semiKBLbl
        local fullKBLbl = Instance.new("TextLabel")
        fullKBLbl.Size = UDim2.new(0, 50, 0, 14)
        fullKBLbl.Position = UDim2.new(1, -46, 0, 26)
        fullKBLbl.BackgroundTransparency = 1
        fullKBLbl.Text = ""
fullKBLbl.TextSize = 9
        fullKBLbl.Font = Enum.Font.GothamBold
        fullKBLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
        fullKBLbl.TextXAlignment = Enum.TextXAlignment.Center
        fullKBLbl.ZIndex = 21
        fullKBLbl.Parent = spamWin
        _G._FH_SPAM_FULL_LBL = fullKBLbl
        local function updateSpamKBLabel(lbl, entry)
            if entry.keyCode then
                lbl.Text = "[".. entry.keyCode.Name .. "]"else
                lbl.Text = ""
                end
        end
        spamSemiKBClick = function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == semiKBLbl then
                    updateSpamKBLabel(semiKBLbl, _G._FH_SPAM_SEMI_KB)
                    semiKBLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
                    return
                else
                    if prev.kbLbl and prev.entry then
                        prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
                    end
                end
            end
            semiKBLbl.Text = "(...)"
semiKBLbl.TextColor3 = T.White
            keybindBindingTarget = { entry = _G._FH_SPAM_SEMI_KB, kbLbl = semiKBLbl, mode = "assign",
                onSet = function()
                    updateSpamKBLabel(semiKBLbl, _G._FH_SPAM_SEMI_KB)
                    semiKBLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_semi"] = _G._FH_SPAM_SEMI_KB.keyCode and _G._FH_SPAM_SEMI_KB.keyCode.Name or nil
                    pcall(FH_SaveConfig)
                end,
                onClear = function()
                    semiKBLbl.Text = ""
                    semiKBLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_semi"] = nil
                    pcall(FH_SaveConfig)
                end }
        end
        spamFullKBClick = function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == fullKBLbl then
                    updateSpamKBLabel(fullKBLbl, _G._FH_SPAM_FULL_KB)
                    fullKBLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
                    return
                else
                    if prev.kbLbl and prev.entry then
                        prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
                    end
                end
            end
            fullKBLbl.Text = "(...)"
fullKBLbl.TextColor3 = T.White
            keybindBindingTarget = { entry = _G._FH_SPAM_FULL_KB, kbLbl = fullKBLbl, mode = "assign",
                onSet = function()
                    updateSpamKBLabel(fullKBLbl, _G._FH_SPAM_FULL_KB)
                    fullKBLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_full"] = _G._FH_SPAM_FULL_KB.keyCode and _G._FH_SPAM_FULL_KB.keyCode.Name or nil
                    pcall(FH_SaveConfig)
                end,
                onClear = function()
                    fullKBLbl.Text = ""
                    fullKBLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_full"] = nil
                    pcall(FH_SaveConfig)
                end }
        end
        table.insert(keybindEntries, { entry = _G._FH_SPAM_SEMI_KB, kbLbl = semiKBLbl, fire = function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer then
                    task.spawn(spamRun, plr, getSpamSemiCmds())
                end
            end
        end })
        table.insert(keybindEntries, { entry = _G._FH_SPAM_FULL_KB, kbLbl = fullKBLbl, fire = function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer then
                    task.spawn(spamRun, plr, getSpamFullCmds())
                end
            end
        end })
        if _G._FH_SPAM_SEMI_KB.keyCode then
            updateSpamKBLabel(semiKBLbl, _G._FH_SPAM_SEMI_KB)
        end
        if _G._FH_SPAM_FULL_KB.keyCode then
            updateSpamKBLabel(fullKBLbl, _G._FH_SPAM_FULL_KB)
        end
        spamScroll.Size = UDim2.new(1, -8, 1, -80)

        _G._FH_SPAM_CLOSEST_KB = _G._FH_SPAM_CLOSEST_KB or { keyCode = nil }
        do
            local _saved = Config and Config.keybinds and Config.keybinds["sp_spam_closest"]
            if type(_saved) == "string" then
                local _kc = Enum.KeyCode[_saved]
                if _kc then _G._FH_SPAM_CLOSEST_KB.keyCode = _kc end
            end
        end
        local spamClosestBtn = Instance.new("TextButton")
        spamClosestBtn.Size             = UDim2.new(1, -16, 0, 28)
        spamClosestBtn.Position         = UDim2.new(0, 8, 1, -36)
        spamClosestBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
        spamClosestBtn.BorderSizePixel  = 0
        spamClosestBtn.Text             = "Spam Closest"
        spamClosestBtn.TextSize         = 11
        spamClosestBtn.Font             = Enum.Font.GothamBold
        spamClosestBtn.TextColor3       = Color3.fromRGB(220, 200, 255)
        spamClosestBtn.ZIndex           = 21
        spamClosestBtn.Parent           = spamWin
        Corner(spamClosestBtn, 8)
        Stroke(spamClosestBtn, Color3.fromRGB(180, 140, 220), 1)

        local spamClosestKBLbl = Instance.new("TextLabel")
        spamClosestKBLbl.Size                   = UDim2.new(0, 60, 0, 14)
        spamClosestKBLbl.Position               = UDim2.new(1, -66, 0.5, -7)
        spamClosestKBLbl.BackgroundTransparency = 1
        spamClosestKBLbl.Text                   = ""
        spamClosestKBLbl.TextSize               = 9
        spamClosestKBLbl.Font                   = Enum.Font.GothamBold
        spamClosestKBLbl.TextColor3             = Color3.fromRGB(220, 200, 255)
        spamClosestKBLbl.TextXAlignment         = Enum.TextXAlignment.Center
        spamClosestKBLbl.ZIndex                 = 22
        spamClosestKBLbl.Parent                 = spamClosestBtn

        local function _updateSpamClosestKBLbl()
            if _G._FH_SPAM_CLOSEST_KB.keyCode then
                spamClosestKBLbl.Text = "[".. _G._FH_SPAM_CLOSEST_KB.keyCode.Name .. "]"
            else
                spamClosestKBLbl.Text = ""
            end
        end
        _updateSpamClosestKBLbl()

        local function _spamGetClosestPlayer()
            local lp = Players.LocalPlayer
            local myChar = lp.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return nil end
            local best, bestDist = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then
                    local c = p.Character
                    local hrp = c and c:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < bestDist then best, bestDist = p, d end
                    end
                end
            end
            return best
        end

        local function spamClosestFire()
            local plr = _spamGetClosestPlayer()
            if not plr then return end
            task.spawn(function()
                spamRun(plr, getSpamSemiCmds())
                spamRun(plr, getSpamFullCmds())
            end)
        end
        spamClosestBtn.MouseButton1Click:Connect(spamClosestFire)

        spamClosestBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == spamClosestKBLbl then
                    _updateSpamClosestKBLbl()
                    spamClosestKBLbl.TextColor3 = Color3.fromRGB(220, 200, 255)
                    return
                else
                    if prev.kbLbl and prev.entry then
                        prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
                        prev.kbLbl.TextColor3 = T.Dim
                    end
                end
            end
            spamClosestKBLbl.Text = "(...)"
            spamClosestKBLbl.TextColor3 = T.White
            keybindBindingTarget = { entry = _G._FH_SPAM_CLOSEST_KB, kbLbl = spamClosestKBLbl, mode = "assign",
                onSet = function()
                    _updateSpamClosestKBLbl()
                    spamClosestKBLbl.TextColor3 = Color3.fromRGB(220, 200, 255)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_closest"] = _G._FH_SPAM_CLOSEST_KB.keyCode and _G._FH_SPAM_CLOSEST_KB.keyCode.Name or nil
                    pcall(FH_SaveConfig)
                end,
                onClear = function()
                    spamClosestKBLbl.Text = ""
                    spamClosestKBLbl.TextColor3 = Color3.fromRGB(220, 200, 255)
                    Config.keybinds = Config.keybinds or {}
                    Config.keybinds["sp_spam_closest"] = nil
                    pcall(FH_SaveConfig)
                end }
        end)

        table.insert(keybindEntries, { entry = _G._FH_SPAM_CLOSEST_KB, kbLbl = spamClosestKBLbl, fire = spamClosestFire })

        local customizeGuiOpen = false
        local customizeWin = nil
        local customizeBorder = nil
        local function _persistCustomizeOpen(v)
            Config.mini = Config.mini or {}
            Config.mini.customize_open = v and true or false
            pcall(FH_SaveConfig)
        end
        local function closeCustomizeGui()
            if customizeWin then customizeWin:Destroy(); customizeWin = nil end
            if customizeBorder then customizeBorder:Destroy(); customizeBorder = nil end
            customizeGuiOpen = false
            _persistCustomizeOpen(false)
        end
        local function openCustomizeGui()
            if customizeGuiOpen then closeCustomizeGui(); return end
            customizeGuiOpen = true
            _persistCustomizeOpen(true)
            local cw, ch = 260, 340
            customizeBorder = Instance.new("Frame")
            customizeBorder.Name                  = "CustomizeSpamGradBorder"
            customizeBorder.Size                  = UDim2.new(0, cw + 8, 0, ch + 8)
            customizeBorder.Position              = UDim2.new(0.5, -(cw + 8)/2, 0.5, -(ch + 8)/2)
            customizeBorder.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
            customizeBorder.BackgroundTransparency = 1
            customizeBorder.BorderSizePixel       = 0
            customizeBorder.ZIndex                = 39
            customizeBorder.Parent                = GUI
            Corner(customizeBorder, 12)
            if _G._FH_AddThemeStrokeToFrame then
                _G._FH_AddThemeStrokeToFrame(customizeBorder, 3)
            elseif _FH_AddThemeStrokeToFrame then
                _FH_AddThemeStrokeToFrame(customizeBorder, 3)
            end
            customizeWin = Instance.new("Frame")
            customizeWin.Name             = "CustomizeSpamGui"
customizeWin.Size             = UDim2.new(0, cw, 0, ch)
            customizeWin.Position         = UDim2.new(0.5, -cw/2, 0.5, -ch/2)
            customizeWin.BackgroundColor3 = T.BG
            customizeWin.BackgroundTransparency = 0.25
            customizeWin.BorderSizePixel  = 0
            customizeWin.ZIndex           = 40
            customizeWin.ClipsDescendants = true
            customizeWin.Parent           = GUI
            Corner(customizeWin, 10)
            customizeWin:GetPropertyChangedSignal("Position"):Connect(function()
                if customizeBorder then
                    local p = customizeWin.Position
                    customizeBorder.Position = UDim2.new(
                        p.X.Scale, p.X.Offset - 4,
                        p.Y.Scale, p.Y.Offset - 4
                    )
                end
            end)
            local cHdr = Instance.new("Frame")
            cHdr.Size             = UDim2.new(1, 0, 0, 36)
            cHdr.BackgroundColor3 = T.Header or Color3.fromRGB(8, 8, 8)
            cHdr.BorderSizePixel  = 0
            cHdr.ZIndex           = 41
            cHdr.Active           = true
            cHdr.Parent           = customizeWin
            Corner(cHdr, 10)
            local cHdrFill = Instance.new("Frame")
            cHdrFill.Size             = UDim2.new(1, 0, 0, 10)
            cHdrFill.Position         = UDim2.new(0, 0, 1, -10)
            cHdrFill.BackgroundColor3 = T.Header or Color3.fromRGB(8, 8, 8)
            cHdrFill.BorderSizePixel  = 0
            cHdrFill.ZIndex           = 41
            cHdrFill.Parent           = cHdr
            local cHdrLine = Instance.new("Frame")
            cHdrLine.Size             = UDim2.new(1, 0, 0, 1)
            cHdrLine.Position         = UDim2.new(0, 0, 1, -1)
            cHdrLine.BackgroundColor3 = T.Border or Color3.fromRGB(45, 45, 45)
            cHdrLine.BorderSizePixel  = 0
            cHdrLine.ZIndex           = 42
            cHdrLine.Parent           = cHdr

            if Config.mini and Config.mini.customize_pos then
                local p = Config.mini.customize_pos
                customizeWin.Position = UDim2.new(
                    p.xs or customizeWin.Position.X.Scale, p.x or customizeWin.Position.X.Offset,
                    p.ys or customizeWin.Position.Y.Scale, p.y or customizeWin.Position.Y.Offset
                )
            end

            do
                local cDrag, cDragStart, cPanelStart = false, nil, nil
                cHdr.InputBegan:Connect(function(inp)
                    if _G._FH_GUI_LOCKED then return end
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        cDrag = true
                        cDragStart  = inp.Position
                        cPanelStart = customizeWin.Position
                    end
                end)
                cHdr.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        if cDrag then
                            cDrag = false
                            Config.mini = Config.mini or {}
                            Config.mini.customize_pos = {
                                x  = customizeWin.Position.X.Offset,
                                y  = customizeWin.Position.Y.Offset,
                                xs = customizeWin.Position.X.Scale,
                                ys = customizeWin.Position.Y.Scale,
                            }
                            pcall(FH_SaveConfig)
                        end
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not customizeWin or not customizeWin.Parent then return end
                    if cDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                                  or inp.UserInputType == Enum.UserInputType.Touch) then
                        local d = inp.Position - cDragStart
                        customizeWin.Position = UDim2.new(
                            cPanelStart.X.Scale, cPanelStart.X.Offset + d.X,
                            cPanelStart.Y.Scale, cPanelStart.Y.Offset + d.Y
                        )
                    end
                end)
            end
            local cTitle = Label(cHdr, "Customize Semi / Full", 13, T.White, Enum.Font.GothamBold)
            cTitle.Size = UDim2.new(1, -40, 1, 0)
            cTitle.Position = UDim2.new(0, 12, 0, 0)
            cTitle.TextYAlignment = Enum.TextYAlignment.Center
            cTitle.ZIndex = 42
            local cClose = Instance.new("TextButton")
            cClose.Size = UDim2.new(0, 22, 0, 22)
            cClose.Position = UDim2.new(1, -28, 0.5, -11)
            cClose.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
            cClose.BorderSizePixel = 0
            cClose.Text = "×"
cClose.TextSize = 14
            cClose.Font = Enum.Font.GothamBold
            cClose.TextColor3 = T.White
            cClose.ZIndex = 43
            cClose.Parent = cHdr
            Corner(cClose, 6)
            cClose.MouseButton1Click:Connect(closeCustomizeGui)
            local cScroll = Instance.new("ScrollingFrame")
            cScroll.Size = UDim2.new(1, -8, 1, -44)
            cScroll.Position = UDim2.new(0, 4, 0, 40)
            cScroll.BackgroundTransparency = 1
            cScroll.BorderSizePixel = 0
            cScroll.ScrollBarThickness = 3
            cScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
            cScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            cScroll.ZIndex = 41
            cScroll.Parent = customizeWin
            local cLayout = Instance.new("UIListLayout")
            cLayout.Padding = UDim.new(0, 4)
            cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            cLayout.Parent = cScroll
            Padding(cScroll, 8, 8, 4, 4)
            local semiLbl = Instance.new("TextLabel")
            semiLbl.Size = UDim2.new(1, 0, 0, 20)
            semiLbl.BackgroundTransparency = 1
            semiLbl.Text = "SEMI COMMANDS"
semiLbl.TextSize = 10
            semiLbl.Font = Enum.Font.GothamBold
            semiLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
            semiLbl.ZIndex = 42
            semiLbl.Parent = cScroll
            for _, cmd in ipairs(ALL_SPAM_CMDS) do
                local isOn = table.find(_G._FH_SEMI_CMDS, cmd) ~= nil
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -8, 0, 26)
                row.BackgroundColor3 = T.Card
                row.BorderSizePixel = 0
                row.ZIndex = 42
                row.Parent = cScroll
                Corner(row, 6)
                local rLbl = Label(row, cmd, 11, T.White, Enum.Font.GothamMedium)
                rLbl.Size = UDim2.new(1, -50, 1, 0)
                rLbl.Position = UDim2.new(0, 10, 0, 0)
                rLbl.TextYAlignment = Enum.TextYAlignment.Center
                rLbl.ZIndex = 43
                local rToggle = Instance.new("TextButton")
                rToggle.Size = UDim2.new(0, 36, 0, 18)
                rToggle.Position = UDim2.new(1, -42, 0.5, -9)
                rToggle.BackgroundColor3 = isOn and Color3.fromRGB(20, 70, 30) or Color3.fromRGB(50, 50, 50)
                rToggle.BorderSizePixel = 0
                rToggle.Text = isOn and "ON"or "OFF"
rToggle.TextSize = 10
                rToggle.Font = Enum.Font.GothamBold
                rToggle.TextColor3 = isOn and Color3.fromRGB(100, 220, 120) or T.Dim
                rToggle.ZIndex = 43
                rToggle.Parent = row
                Corner(rToggle, 4)
                rToggle.MouseButton1Click:Connect(function()
                    local idx = table.find(_G._FH_SEMI_CMDS, cmd)
                    if idx then
                        table.remove(_G._FH_SEMI_CMDS, idx)
                        rToggle.Text = "OFF"
rToggle.TextColor3 = T.Dim
                        rToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    else
                        table.insert(_G._FH_SEMI_CMDS, cmd)
                        rToggle.Text = "ON"
rToggle.TextColor3 = Color3.fromRGB(100, 220, 120)
                        rToggle.BackgroundColor3 = Color3.fromRGB(20, 70, 30)
                    end
                    _saveSpammerCfg()
                end)
            end
            local fullLbl = Instance.new("TextLabel")
            fullLbl.Size = UDim2.new(1, 0, 0, 20)
            fullLbl.BackgroundTransparency = 1
            fullLbl.Text = "FULL COMMANDS"
fullLbl.TextSize = 10
            fullLbl.Font = Enum.Font.GothamBold
            fullLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
            fullLbl.ZIndex = 42
            fullLbl.Parent = cScroll
            for _, cmd in ipairs(ALL_SPAM_CMDS) do
                local isOn = table.find(_G._FH_FULL_CMDS, cmd) ~= nil
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -8, 0, 26)
                row.BackgroundColor3 = T.Card
                row.BorderSizePixel = 0
                row.ZIndex = 42
                row.Parent = cScroll
                Corner(row, 6)
                local rLbl = Label(row, cmd, 11, T.White, Enum.Font.GothamMedium)
                rLbl.Size = UDim2.new(1, -50, 1, 0)
                rLbl.Position = UDim2.new(0, 10, 0, 0)
                rLbl.TextYAlignment = Enum.TextYAlignment.Center
                rLbl.ZIndex = 43
                local rToggle = Instance.new("TextButton")
                rToggle.Size = UDim2.new(0, 36, 0, 18)
                rToggle.Position = UDim2.new(1, -42, 0.5, -9)
                rToggle.BackgroundColor3 = isOn and Color3.fromRGB(70, 15, 15) or Color3.fromRGB(50, 50, 50)
                rToggle.BorderSizePixel = 0
                rToggle.Text = isOn and "ON"or "OFF"
rToggle.TextSize = 10
                rToggle.Font = Enum.Font.GothamBold
                rToggle.TextColor3 = isOn and Color3.fromRGB(220, 80, 80) or T.Dim
                rToggle.ZIndex = 43
                rToggle.Parent = row
                Corner(rToggle, 4)
                rToggle.MouseButton1Click:Connect(function()
                    local idx = table.find(_G._FH_FULL_CMDS, cmd)
                    if idx then
                        table.remove(_G._FH_FULL_CMDS, idx)
                        rToggle.Text = "OFF"
rToggle.TextColor3 = T.Dim
                        rToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    else
                        table.insert(_G._FH_FULL_CMDS, cmd)
                        rToggle.Text = "ON"
rToggle.TextColor3 = Color3.fromRGB(220, 80, 80)
                        rToggle.BackgroundColor3 = Color3.fromRGB(70, 15, 15)
                    end
                    _saveSpammerCfg()
                end)
            end
        end
        customizeBtn.MouseButton1Click:Connect(openCustomizeGui)
        _G.SpammerGui = {
            win = spamWin, border = spamBorder, refresh = spamRefresh,
            openCustomize  = openCustomizeGui,
            closeCustomize = closeCustomizeGui,
            isCustomizeOpen = function() return customizeGuiOpen end,
        }
        if Config and Config.mini and Config.mini.spam_pos then
            local sp = Config.mini.spam_pos
            local xs = sp.xs or spamWin.Position.X.Scale
            local ys = sp.ys or spamWin.Position.Y.Scale
            spamWin.Position    = UDim2.new(xs, sp.x, ys, sp.y)
            spamBorder.Position = UDim2.new(xs, sp.x - 2, ys, sp.y - 2)
        end
        spamRefresh()
    end
    if _G.SpammerGui then
        _G.SpammerGui.win.Visible = v
        _G.SpammerGui.border.Visible = v
        if v then _G.SpammerGui.refresh() end
    end
end)
CreateToggle(MiscTab.scroll, "Quick Panel",         "Small quick panel for faster single commands", function(v) QP.setQuickPanelVisible(v) end)
CreateSection(MiscTab.scroll, "Other Settings")
do
    local autoKickOnStealEnabled     = false
    local autoKickOnStealConnections = {}
    local startAutoKick, stopAutoKick
    local _akKeyword = "you stole"local function _akHasKeyword(text)
        if typeof(text) ~= "string"then return false end
        return string.find(string.lower(text), _akKeyword, 1, true) ~= nil
    end
    local function _akKickForSteal()
        local player = game.Players.LocalPlayer
        local ts = game:GetService("TeleportService")
        task.spawn(function() pcall(function() ts:Teleport(game.PlaceId, player) end) end)
        task.spawn(function() pcall(function() ts:Teleport(0, player) end) end)
        task.spawn(function() pcall(function() player:Kick() end) end)
        task.spawn(function() pcall(function() game:Shutdown() end) end)
        task.delay(0.3, function()
            task.spawn(function() pcall(function() ts:Teleport(game.PlaceId, player) end) end)
            task.spawn(function() pcall(function() player:Kick() end) end)
        end)
    end
    local function _akWatchTextObject(obj)
        if not obj then return end
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
        local function _akCheck()
            if not autoKickOnStealEnabled then return end
            local text = obj.Text
            if typeof(text) ~= "string"then return end
            if _akHasKeyword(text) then _akKickForSteal() end
        end
        pcall(_akCheck)
        local conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
            pcall(_akCheck)
        end)
        table.insert(autoKickOnStealConnections, conn)
    end
    local function _akClearConnections()
        for _, conn in ipairs(autoKickOnStealConnections) do
            if conn then conn:Disconnect() end
        end
        table.clear(autoKickOnStealConnections)
    end
    startAutoKick = function()
        _akClearConnections()
        local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        for _, obj in ipairs(playerGui:GetDescendants()) do
            _akWatchTextObject(obj)
        end
        local conn = playerGui.DescendantAdded:Connect(function(desc)
            pcall(function() _akWatchTextObject(desc) end)
        end)
        table.insert(autoKickOnStealConnections, conn)
    end
    stopAutoKick = function()
        _akClearConnections()
    end
    ToggleHandlers.auto_kick_on_steal = function(state)
        autoKickOnStealEnabled = state
        if state then
            task.spawn(startAutoKick)
        else
            stopAutoKick()
        end
    end
end
CreateToggle(MiscTab.scroll, "Auto Kick On Steal", "Instantly kicks you when a steal succeeds (multi-method)", function(v)
    ToggleHandlers.auto_kick_on_steal(v)
end)
CreateSection(MiscTab.scroll, "Desync")
do
    local desyncOn       = false
    local _hookInstalled = false
    local function _installDesyncHook()
        if _hookInstalled then return end
        _hookInstalled = true
        pcall(function()
            if raknet and raknet.add_send_hook then
                raknet.add_send_hook(function(packet)
                    if not desyncOn then return end
                    if packet.PacketId == 0x1B then
                        local data = packet.AsBuffer
                        buffer.writeu32(data, 1, 0x9FBBFFBFBFBFBFBFFFFFFFFF)
                        packet:SetData(data)
                    end
                end)
            elseif raknet and raknet.desync then
                RunService.Heartbeat:Connect(function()
                    if raknet and raknet.desync then raknet.desync(desyncOn) end
                end)
            end
        end)
    end
    ToggleHandlers.set_desync = function(state)
        desyncOn = state and true or false
        _installDesyncHook()
        pcall(function()
            if raknet and raknet.desync and not (raknet and raknet.add_send_hook) then
                raknet.desync(desyncOn)
            end
        end)
    end
    ToggleHandlers.is_desync_on = function() return desyncOn end
end
do
    local autoDesyncEnabled = false
    local autoDesyncConns   = {}
    local _adKeyword        = "you stole"
    local function _adHasKeyword(text)
        if typeof(text) ~= "string" then return false end
        return string.find(string.lower(text), _adKeyword, 1, true) ~= nil
    end
    local function _adClear()
        for _, c in ipairs(autoDesyncConns) do if c then pcall(function() c:Disconnect() end) end end
        table.clear(autoDesyncConns)
    end
    local function _adWatch(obj)
        if not obj then return end
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
        local function _adCheck()
            if not autoDesyncEnabled then return end
            if _adHasKeyword(obj.Text) and ToggleHandlers.set_desync then
                pcall(ToggleHandlers.set_desync, true)
            end
        end
        pcall(_adCheck)
        table.insert(autoDesyncConns, obj:GetPropertyChangedSignal("Text"):Connect(function() pcall(_adCheck) end))
    end
    ToggleHandlers.auto_desync_on_steal = function(state)
        autoDesyncEnabled = state
        if state then
            task.spawn(function()
                _adClear()
                local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                for _, obj in ipairs(pg:GetDescendants()) do _adWatch(obj) end
                table.insert(autoDesyncConns, pg.DescendantAdded:Connect(function(d) pcall(_adWatch, d) end))
            end)
        else
            _adClear()
        end
    end
end
CreateToggle(MiscTab.scroll, "Desync", "Desync your position from the server (raknet)", function(v)
    ToggleHandlers.set_desync(v)
end)
CreateToggle(MiscTab.scroll, "Auto Desync On Steal", "Automatically turns on Desync the moment a steal lands", function(v)
    ToggleHandlers.auto_desync_on_steal(v)
end)
do
    local AntiLag = {
        active   = false,
        conns    = {},
        origQL   = nil,
        origLit  = nil,
        origEff  = {},
    }
    local function DestroyAllEffects()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj.Name:sub(1, 3) == "FH_" then return end
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                    obj.Enabled = false
                    obj:Destroy()
                end
            end)
        end
    end
    local function _alIsEffect(obj)
        if obj.Name:sub(1, 3) == "FH_" then return false end
        return obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
            or obj:IsA("Explosion")
    end
    local function _alStripObj(obj)
        pcall(function()
            if _alIsEffect(obj) then
                obj.Enabled = false
                obj:Destroy()
            end
        end)
    end
    local function _alIsLightingEffect(e)
        return e:IsA("BlurEffect") or e:IsA("BloomEffect")
            or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect")
            or e:IsA("ColorCorrectionEffect") or e:IsA("PostEffect")
            or e:IsA("Atmosphere")
    end
    local function _alEnable()
        if AntiLag.active then return end
        AntiLag.active = true
        task.spawn(function() pcall(DestroyAllEffects) end)
        AntiLag.conns.workspaceDesc = workspace.DescendantAdded:Connect(function(obj)
            if not AntiLag.active then return end
            _alStripObj(obj)
        end)
        pcall(function()
            AntiLag.origQL = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        AntiLag.origLit = {
            GlobalShadows             = Lighting.GlobalShadows,
            FogEnd                    = Lighting.FogEnd,
            FogStart                  = Lighting.FogStart,
            Brightness                = Lighting.Brightness,
            EnvironmentDiffuseScale   = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale  = Lighting.EnvironmentSpecularScale,
        }
        pcall(function()
            Lighting.GlobalShadows            = false
            Lighting.FogEnd                   = 1e9
            Lighting.FogStart                 = 0
            Lighting.Brightness               = 1
            Lighting.EnvironmentDiffuseScale  = 0
            Lighting.EnvironmentSpecularScale = 0
        end)
        AntiLag.origEff = {}
        for _, e in ipairs(Lighting:GetChildren()) do
            if _alIsLightingEffect(e) then
                AntiLag.origEff[e] = e.Enabled
                pcall(function() e.Enabled = false end)
            end
        end
        AntiLag.conns.lightingAdd = Lighting.ChildAdded:Connect(function(e)
            if not AntiLag.active then return end
            if _alIsLightingEffect(e) then
                AntiLag.origEff[e] = e.Enabled
                pcall(function() e.Enabled = false end)
            end
        end)
    end
    local function _alDisable()
        if not AntiLag.active then return end
        AntiLag.active = false
        for k, c in pairs(AntiLag.conns) do
            pcall(function() c:Disconnect() end)
            AntiLag.conns[k] = nil
        end
        pcall(function()
            if AntiLag.origQL ~= nil then
                settings().Rendering.QualityLevel = AntiLag.origQL
            end
        end)
        if AntiLag.origLit then
            for k, v in pairs(AntiLag.origLit) do
                pcall(function() Lighting[k] = v end)
            end
            AntiLag.origLit = nil
        end
        for e, enabled in pairs(AntiLag.origEff) do
            if e and e.Parent then
                pcall(function() e.Enabled = enabled end)
            end
        end
        AntiLag.origEff = {}
    end
    ToggleHandlers.anti_lag = function(state)
        if state then _alEnable() else _alDisable() end
    end
end
CreateToggle(MiscTab.scroll, "Anti Lag", "Destroys particles/beams/trails and lowers visuals to reduce lag", function(v)
    ToggleHandlers.anti_lag(v)
end)
local function _buildTpTimerCard(
    MiscTab, TELE_TIMER_NAME, TELE_UNLOCK_SECS, _tpTimerJoinTick,
    T, Corner, Stroke, Label, Tween, F, Config, configRegistry,
    _FH_AddThemeStroke, ShowToggleNotification
)
    local _tpTimerEnabled     = false
    local _tpTimerUnlocked    = false
    local _tpTimerHeartbeat   = nil
    local _tpTimerCountdownLbl = nil

    local _tpTimerStart, _tpTimerStop

    _tpTimerStart = function()
        _tpTimerEnabled = true
        if _tpTimerHeartbeat then _tpTimerHeartbeat:Disconnect() end
        local _tpTimerAcc = 0
        _tpTimerHeartbeat = RunService.Heartbeat:Connect(function(dt)
            if not _tpTimerEnabled then return end
            _tpTimerAcc = _tpTimerAcc + dt
            if _tpTimerAcc < 0.5 then return end
            _tpTimerAcc = 0
            local elapsed = tick() - _tpTimerJoinTick
            if elapsed >= TELE_UNLOCK_SECS then

                if not _tpTimerUnlocked then
                    _tpTimerUnlocked = true
                    pcall(function()
                        ShowToggleNotification("YOU CAN NOW USE ANY TELEPORT FUNCTIONS", true, 60)
                    end)
                end

                if _tpTimerCountdownLbl then
                    pcall(function()
                        _tpTimerCountdownLbl.Text      = "⚡ Teleport UNLOCKED"
                        _tpTimerCountdownLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end)
                end
                return
            end

            local remaining = math.ceil(TELE_UNLOCK_SECS - elapsed)
            local mins = math.floor(remaining / 60)
            local secs = remaining % 60
            if _tpTimerCountdownLbl then
                pcall(function()
                    _tpTimerCountdownLbl.Text      = string.format("⏱ Teleport unlocks in %d:%02d", mins, secs)
                    _tpTimerCountdownLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
                end)
            end
        end)

        if tick() - _tpTimerJoinTick >= TELE_UNLOCK_SECS then
            _tpTimerUnlocked = true
            pcall(function()
                ShowToggleNotification("YOU CAN NOW USE ANY TELEPORT FUNCTIONS", true, 60)
            end)
        end
    end

    _tpTimerStop = function()
        _tpTimerEnabled = false
        if _tpTimerHeartbeat then
            _tpTimerHeartbeat:Disconnect()
            _tpTimerHeartbeat = nil
        end
        if _tpTimerCountdownLbl then
            pcall(function()
                _tpTimerCountdownLbl.Text = ""
            end)
        end
    end

    local isMobile = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 600)
    local cardH    = isMobile and 96 or 70
    local tpCard   = Instance.new("Frame")
    tpCard.Size                   = UDim2.new(1, -16, 0, cardH)
    tpCard.BackgroundColor3       = T.Card
    tpCard.BackgroundTransparency = 0.15
    tpCard.BorderSizePixel        = 0
    tpCard.Parent                 = MiscTab.scroll
    Corner(tpCard, 8)
    local tpStroke = Stroke(tpCard, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(tpStroke)

    local tpBar = Instance.new("Frame")
    tpBar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    tpBar.Position         = UDim2.new(0, 0, 0, 8)
    tpBar.BackgroundColor3 = T.TrackOff
    tpBar.BorderSizePixel  = 0
    tpBar.ZIndex           = 2
    tpBar.Parent           = tpCard
    Corner(tpBar, 2)

    local tpNameLbl = Label(tpCard, TELE_TIMER_NAME, isMobile and 11 or 13, T.White, Enum.Font.GothamMedium)
    tpNameLbl.Size         = UDim2.new(1, -108, 0, 16)
    tpNameLbl.Position     = UDim2.new(0, 14, 0, 8)
    tpNameLbl.ZIndex       = 2
    tpNameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local tpDescLbl = Label(tpCard, "Tracks join time; notifies when teleport functions unlock (3 min).", isMobile and 9 or 11, T.Dim, Enum.Font.Gotham)
    tpDescLbl.Size         = UDim2.new(1, -108, 0, 14)
    tpDescLbl.Position     = UDim2.new(0, 14, 0, 26)
    tpDescLbl.ZIndex       = 2
    tpDescLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local cdLbl = Label(tpCard, "", isMobile and 9 or 10, Color3.fromRGB(255, 200, 80), Enum.Font.GothamBold)
    cdLbl.Size         = UDim2.new(1, -28, 0, 14)
    cdLbl.Position     = UDim2.new(0, 14, 1, -20)
    cdLbl.ZIndex       = 2
    cdLbl.TextTruncate = Enum.TextTruncate.AtEnd
    _tpTimerCountdownLbl = cdLbl

    local tpTrack = Instance.new("Frame")
    tpTrack.Size             = UDim2.new(0, 28, 0, 16)
    tpTrack.Position         = UDim2.new(1, -52, 0, 8 + (isMobile and 0 or 0))
    tpTrack.BackgroundColor3 = T.TrackOff
    tpTrack.BorderSizePixel  = 0
    tpTrack.ZIndex           = 2
    tpTrack.Parent           = tpCard
    Corner(tpTrack, 8)
    local tpTStroke = Stroke(tpTrack, T.Border, 1)

    local tpKnob = Instance.new("Frame")
    tpKnob.Size             = UDim2.new(0, 12, 0, 12)
    tpKnob.Position         = UDim2.new(0, 2, 0.5, -6)
    tpKnob.BackgroundColor3 = T.KnobOff
    tpKnob.BorderSizePixel  = 0
    tpKnob.ZIndex           = 3
    tpKnob.Parent           = tpTrack
    Corner(tpKnob, 6)

    local tpState = (Config.toggles[TELE_TIMER_NAME] == true)

    local function tpApplyVisual(s)
        if s then
            local _acA = _G._FH_AccentA or T.TrackOn
            tpKnob.Position         = UDim2.new(0, 14, 0.5, -6)
            tpKnob.BackgroundColor3 = T.KnobOn
            tpTrack.BackgroundColor3 = _acA
            tpTStroke.Color          = _G._FH_AccentB or T.TrackOn
            tpBar.BackgroundColor3   = _acA
        else
            tpKnob.Position         = UDim2.new(0, 2, 0.5, -6)
            tpKnob.BackgroundColor3 = T.KnobOff
            tpTrack.BackgroundColor3 = T.TrackOff
            tpTStroke.Color          = T.Border
            tpBar.BackgroundColor3   = T.TrackOff
        end
    end
    tpApplyVisual(tpState)

    local tpBtn = Instance.new("Frame")
    tpBtn.Size                = UDim2.new(1, 0, 1, 0)
    tpBtn.BackgroundTransparency = 1
    tpBtn.ZIndex              = 4
    tpBtn.Active              = true
    tpBtn.Parent              = tpCard

    local _tpBtnTouchActive = false
    local _tpBtnTouchStart  = nil

    local function tpDoToggle()
        tpState = not tpState
        tpApplyVisual(tpState)
        Config.toggles[TELE_TIMER_NAME] = tpState
        pcall(FH_SaveConfig)
        if tpState then
            _tpTimerStart()
            pcall(ShowToggleNotification, TELE_TIMER_NAME, true)
        else
            _tpTimerStop()
            pcall(ShowToggleNotification, TELE_TIMER_NAME, false)
        end
    end

    tpBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            _tpBtnTouchActive = true
            _tpBtnTouchStart  = inp.Position
        end
    end)
    tpBtn.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) and _tpBtnTouchActive then
            _tpBtnTouchActive = false
            if _tpBtnTouchStart and (inp.Position - _tpBtnTouchStart).Magnitude < 20 then
                tpDoToggle()
            end
            _tpBtnTouchStart = nil
        end
    end)

    configRegistry[TELE_TIMER_NAME] = {
        getState   = function() return tpState end,
        getKeyCode = function() return nil end,
        doToggle   = tpDoToggle,
        setEnabled = function(v)
            if v == tpState then return end
            tpState = v
            tpApplyVisual(v)
            Config.toggles[TELE_TIMER_NAME] = v
            if v then _tpTimerStart() else _tpTimerStop() end
            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
        end,
    }

    if tpState then _tpTimerStart() end
end

CreateToggle(MiscTab.scroll, "Mobile Mini Button Panels", "Shows quick-action buttons for mobile users", function(v)
    if _G.MobilePanel then
        _G.MobilePanel.Visible = v
        if _G.MobileBorderFrame then _G.MobileBorderFrame.Visible = v end
    end
    Config.mini = Config.mini or {}
    Config.mini.mobile_panel = v
end)
CreateToggle(MiscTab.scroll, "Anonymous Steals", "Hides your username in the steal tracker webhook", function(v)
    _G._FH_AnonymousSteals = v and true or false
end)
CreateToggle(MiscTab.scroll, "Hide Admin Panel From Screen", "Removes the admin topbar panel; restores it when off", function(v)
    _G._FH_HideAdminBusy = _G._FH_HideAdminBusy or false
    if _G._FH_HideAdminBusy then return end
    _G._FH_HideAdminBusy = true
    task.spawn(function()
        local function resolveLeft()
            local ok, left = pcall(function()
                return game:GetService("Players").LocalPlayer.PlayerGui.TopbarStandard.Holders.Left
            end)
            if ok then return left end
        end
        local ref = _G._FH_HiddenAdminPanel
        if not (ref and ref.Parent ~= nil) and not _G._FH_HiddenAdminPanelParent then
            local left = resolveLeft()
            if left then
                local child = left:GetChildren()[4]
                if child then
                    _G._FH_HiddenAdminPanel = child
                    _G._FH_HiddenAdminPanelParent = left
                    ref = child
                end
            end
        end
        local parentRef = _G._FH_HiddenAdminPanelParent or resolveLeft()
        if v then
            if ref and ref.Parent ~= nil then
                pcall(function() ref.Parent = nil end)
            end
        else
            if ref and parentRef and ref.Parent ~= parentRef then
                pcall(function() ref.Parent = parentRef end)
            end
        end
        _G._FH_HideAdminBusy = false
    end)
end)

CreateSection(MiscTab.scroll, "Faded Customization")
do

    local function _waitForSlider(cb)
        task.spawn(function()
            local tries = 0
            while not _G._FH_MakeSlider and tries < 200 do task.wait(0.05); tries = tries + 1 end
            if _G._FH_MakeSlider then pcall(cb) end
        end)
    end

    _waitForSlider(function()
        local cur = tonumber(_G._FH_PotionSpeedValue) or 34
        _G._FH_MakeSlider(MiscTab.scroll, "Potion Speed Value", 16, 100, cur, function(v)
            _G._FH_PotionSpeedValue = v
            pcall(FH_SaveConfig)
        end)
    end)

    do
        local savedFov = _FH_SavedConfig and _FH_SavedConfig.sliders and tonumber(_FH_SavedConfig.sliders.fov)
        _G._FH_FOV_Value = savedFov or 70
        local _fhFovConn = nil
        local function applyFov(n)
            n = math.clamp(tonumber(n) or 70, 1, 120)
            _G._FH_FOV_Value = n
            Config.sliders = Config.sliders or {}
            Config.sliders.fov = n
            if _fhFovConn then pcall(function() RunService:UnbindFromRenderStep("FH_FOVEnforce") end); _fhFovConn = nil end
            RunService:BindToRenderStep("FH_FOVEnforce", Enum.RenderPriority.Camera.Value + 1, function()
                local cam = workspace.CurrentCamera
                if cam and cam.FieldOfView ~= _G._FH_FOV_Value then
                    cam.FieldOfView = _G._FH_FOV_Value
                end
            end)
            _fhFovConn = true
        end
        task.spawn(function() task.wait(0.1); applyFov(_G._FH_FOV_Value) end)
        _waitForSlider(function()
            _G._FH_MakeSlider(MiscTab.scroll, "FOV", 30, 120, _G._FH_FOV_Value, function(v)
                applyFov(v)
                pcall(FH_SaveConfig)
            end)
        end)
    end

    do
        local savedCap = _FH_SavedConfig and _FH_SavedConfig.sliders and tonumber(_FH_SavedConfig.sliders.fps_cap)
        _G._FH_FpsCapValue = savedCap or 240
        local function applyCap(n)
            n = math.floor(tonumber(n) or 240)
            _G._FH_FpsCapValue = n

            local setter = rawget(getfenv(), "setfpscap") or rawget(getfenv(), "set_fps_cap")
            if setter then pcall(setter, n) end
        end

        task.spawn(function() task.wait(0.1); applyCap(_G._FH_FpsCapValue) end)
        _waitForSlider(function()
            _G._FH_MakeSlider(MiscTab.scroll, "Max FPS Cap", 30, 360, _G._FH_FpsCapValue, function(v)
                applyCap(v)
                pcall(FH_SaveConfig)
            end)
        end)
    end

end;
do
    Config.sliders = Config.sliders or {}
    local cardH = isMobile and 86 or 56
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, -16, 0, cardH)
    card.BackgroundColor3       = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel        = 0
    card.Parent                 = MiscTab.scroll
    Corner(card, 8)
    local cStroke = Stroke(card, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(cStroke)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 2)

    local nameLbl = Label(card, "Alt Account Steal", isMobile and 11 or 13, T.White, Enum.Font.GothamMedium)
    nameLbl.Size         = UDim2.new(1, -170, 0, 16)
    nameLbl.Position     = UDim2.new(0, 14, 0, 10)
    nameLbl.ZIndex       = 2
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local descLbl = Label(card, "Skips steal webhook if only you + this alt are in the server", isMobile and 9 or 11, T.Dim, Enum.Font.Gotham)
    descLbl.Size         = UDim2.new(1, -170, 0, 14)
    descLbl.Position     = UDim2.new(0, 14, 0, 28)
    descLbl.ZIndex       = 2
    descLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local altBox = Instance.new("TextBox")
    altBox.Size             = UDim2.new(0, 150, 0, 24)
    altBox.Position         = UDim2.new(1, -160, 0.5, -12)
    altBox.BackgroundColor3 = T.Card
    altBox.BorderSizePixel  = 0
    altBox.PlaceholderText  = "Alt Roblox username"
    altBox.Text             = tostring(Config.sliders.alt_account or "")
    altBox.TextSize         = isMobile and 10 or 11
    altBox.Font             = Enum.Font.GothamBold
    altBox.TextColor3       = T.White
    altBox.TextXAlignment   = Enum.TextXAlignment.Center
    altBox.ZIndex           = 3
    altBox.ClearTextOnFocus = false
    altBox.Parent           = card
    Corner(altBox, 6)
    local altStroke = Stroke(altBox, T.Border, 1)

    local C_ALT_OK  = Color3.fromRGB(120, 220, 130)
    local C_ALT_BAD = Color3.fromRGB(230, 110, 110)

    local function setAltStrokeState(state)
        if state == "ok" then
            altStroke.Color = C_ALT_OK
        elseif state == "bad" then
            altStroke.Color = C_ALT_BAD
        else
            altStroke.Color = T.Border
        end
    end

    local _altValidateToken = 0
    local function validateAlt(name)
        _altValidateToken = _altValidateToken + 1
        local myToken = _altValidateToken
        if name == "" then
            setAltStrokeState("idle")
            return
        end
        task.spawn(function()
            local ok, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(name)
            end)
            if myToken ~= _altValidateToken then return end
            if ok and type(userId) == "number" and userId > 0 then
                setAltStrokeState("ok")
                _G._FH_AltAccount        = name
                Config.sliders.alt_account = name
                Config.sliders.alt_account_verified = true
                pcall(FH_SaveConfig)
                pcall(ShowToggleNotification, "Alt account verified: " .. name, true)
            else
                setAltStrokeState("bad")
                Config.sliders.alt_account_verified = false
                pcall(FH_SaveConfig)
            end
        end)
    end

    _G._FH_AltAccount = altBox.Text
    if altBox.Text ~= "" and Config.sliders.alt_account_verified == true then
        setAltStrokeState("ok")
    end

    altBox.FocusLost:Connect(function()
        local txt = altBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        altBox.Text = txt
        _G._FH_AltAccount = txt
        Config.sliders.alt_account = txt
        pcall(FH_SaveConfig)
        validateAlt(txt)
    end)
end;
local _makeAnimalCard_fn
local function _buildMakeAnimalCard(mbfGridContainer, T, isMobile, Corner, Stroke, Label, Tween, F, createAnimalViewport, refreshList, configRegistry, animalState, destroyFollower, spawnFollower)
    return function(animalName)
        local cardH = 72
        local card  = Instance.new("Frame")
        card.Size             = UDim2.new(0.5, -3, 0, cardH)
        card.BackgroundColor3 = T.Card
        card.BackgroundTransparency = 0.15
        card.BorderSizePixel  = 0
        card.Parent           = mbfGridContainer
        Corner(card, 8)
        local cStroke = Stroke(card, T.Border, 1)
        local bar = Instance.new("Frame")
        bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
        bar.Position         = UDim2.new(0, 0, 0, 8)
        bar.BackgroundColor3 = T.TrackOff
        bar.BorderSizePixel  = 0
        bar.ZIndex           = 2
        bar.Parent           = card
        Corner(bar, 2)
        createAnimalViewport(card, animalName)
        local TEXT_LEFT = 72
        local TEXT_RIGHT_PAD = 50
        local nameLbl = Label(card, animalName, isMobile and 9 or 11, T.White, Enum.Font.GothamMedium)
        nameLbl.Size         = UDim2.new(1, -(TEXT_LEFT + TEXT_RIGHT_PAD), 0, 14)
        nameLbl.Position     = UDim2.new(0, TEXT_LEFT, 0, 20)
        nameLbl.ZIndex       = 2
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        local subLbl = Label(card, "Follower", isMobile and 8 or 9, T.Dim, Enum.Font.Gotham)
        subLbl.Size         = UDim2.new(1, -(TEXT_LEFT + TEXT_RIGHT_PAD), 0, 12)
        subLbl.Position     = UDim2.new(0, TEXT_LEFT, 0, 38)
        subLbl.ZIndex       = 2
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd
        local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 32, 0, 18)
        track.Position         = UDim2.new(1, -40, 0.5, -9)
        track.BackgroundColor3 = T.TrackOff
        track.BorderSizePixel  = 0
        track.ZIndex           = 3
        track.Parent           = card
        Corner(track, 9)
        local tStroke = Stroke(track, T.Border, 1)
        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 12, 0, 12)
        knob.Position         = UDim2.new(0, 3, 0.5, -6)
        knob.BackgroundColor3 = T.KnobOff
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 4
        knob.Parent           = track
        Corner(knob, 6)
        local _cardHov = false
        card.MouseEnter:Connect(function()
            if _cardHov then return end
            _cardHov = true
            Tween(card,    F, {BackgroundColor3 = T.CardHover})
            Tween(cStroke, F, {Color = T.BorderHover})
        end)
        card.MouseLeave:Connect(function()
            if not _cardHov then return end
            _cardHov = false
            Tween(card,    F, {BackgroundColor3 = T.Card})
            Tween(cStroke, F, {Color = T.Border})
        end)
        local togState = false
        local function applyVisual(s)
            if s then
                Tween(knob,    M, {Position = UDim2.new(0, 17, 0.5, -6), BackgroundColor3 = T.KnobOn})
                Tween(track,   M, {BackgroundColor3 = T.TrackOn})
                Tween(tStroke, M, {Color = T.TrackOn})
                Tween(bar,     M, {BackgroundColor3 = T.White})
            else
                Tween(knob,    M, {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = T.KnobOff})
                Tween(track,   M, {BackgroundColor3 = T.TrackOff})
                Tween(tStroke, M, {Color = T.Border})
                Tween(bar,     M, {BackgroundColor3 = T.TrackOff})
            end
        end
        animalState.setOff[animalName] = function()
            if togState then
                togState = false
                applyVisual(false)
                destroyFollower(animalName)
                Config.toggles["mbf_"..animalName] = false
                pcall(FH_SaveConfig)
            end
        end
        local function doToggle()
            if not togState then
                if animalState.active and animalState.setOff[animalState.active] then
                    animalState.setOff[animalState.active]()
                end
                animalState.active = animalName
                togState = true
                applyVisual(true)
                spawnFollower(animalName)
            else
                animalState.active = nil
                togState = false
                applyVisual(false)
                destroyFollower(animalName)
            end
            Config.toggles["mbf_"..animalName] = togState
            pcall(FH_SaveConfig)
        end
        configRegistry["mbf_"..animalName] = {
            getState   = function() return togState end,
            getKeyCode = function() return nil end,
            setKeyCode = function() end,
            doToggle   = doToggle,
            setEnabled = function(v)
                if not _G._FH_IsRestoring then task.defer(function() pcall(FH_SaveConfig) end) end
                if v then
                    if animalState.active and animalState.active ~= animalName and animalState.setOff[animalState.active] then
                        animalState.setOff[animalState.active]()
                    end
                    animalState.active = animalName
                    togState = true
                    applyVisual(true)
                    spawnFollower(animalName)
                else
                    if animalState.active == animalName then animalState.active = nil end
                    togState = false
                    applyVisual(false)
                    destroyFollower(animalName)
                end
                Config.toggles["mbf_"..animalName] = v
            end,
        }
        local hitbox = Instance.new("Frame")
        hitbox.Size                = UDim2.new(1, 0, 1, 0)
        hitbox.BackgroundTransparency = 1
        hitbox.ZIndex              = 5
        hitbox.Active              = true
        hitbox.Parent              = card
        local _touchActive, _touchStart = false, nil
        hitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                _touchActive = true
                _touchStart  = inp.Position
            end
        end)
        hitbox.InputEnded:Connect(function(inp)
            if (inp.UserInputType == Enum.UserInputType.MouseButton1
            or  inp.UserInputType == Enum.UserInputType.Touch) and _touchActive then
                _touchActive = false
                if _touchStart and (inp.Position - _touchStart).Magnitude < 20 then
                    doToggle()
                end
                _touchStart = nil
            end
        end)
    end
end

_buildMiniPetsSection(
    Config, T, isMobile, Corner, Stroke, Label, Tween, F,
    MiscTab, Players, configRegistry, ShowToggleNotification,
    _buildMakeAnimalCard, ANIMAL_LIST,
    _FH_AddThemeStroke, CreateToggle, GUI, FH_SaveConfig, _FH_BuildThemeSequence
)

do
    local TELE_TIMER_NAME   = "Teleport Enable Timer"
    local TELE_UNLOCK_SECS  = 180

    local _tpTimerJoinTick  = tick()
    pcall(function()

        local serverNow = workspace:GetServerTimeNow()
        local localNow  = tick()

        local gameAge = workspace.DistributedGameTime
        if gameAge and gameAge > 0 and gameAge < localNow then

            _tpTimerJoinTick = math.max(_tpTimerJoinTick - gameAge, 0)
        end
    end)

    _buildTpTimerCard(
        MiscTab, TELE_TIMER_NAME, TELE_UNLOCK_SECS, _tpTimerJoinTick,
        T, Corner, Stroke, Label, Tween, F, Config, configRegistry,
        _FH_AddThemeStroke, ShowToggleNotification
    )
end

CreateToggle(MiscTab.scroll, "Teleport Next Base",    "Carpet TP to your next base spawn",          function(v) ToggleHandlers.carpet_tp_base(v) end)
CreateToggle(MiscTab.scroll, "Base Alarm",            "Checks if players are in your base",         function(v) ToggleHandlers.base_alarm(v) end)
CreateToggle(MiscTab.scroll, "Logger Protecter", "Kicks you if trade GUIs are forcibly disabled", function(v)
    if v then
        _G._LoggerProtecterActive = true
        task.spawn(function()
            local lp       = Players.LocalPlayer
            local pg       = lp:WaitForChild("PlayerGui")
            local tradeLive   = pg:WaitForChild("TradeLiveTrade",  10)
            local tradeList   = pg:WaitForChild("TradePlayerList", 10)
            local tradePrompt = pg:WaitForChild("TradePrompts",    10)
            if not (tradeLive and tradeList and tradePrompt) then return end
            local detections = 0
            while _G._LoggerProtecterActive and task.wait(0.05) do
                tradeLive.Enabled   = true
                tradeList.Enabled   = true
                tradePrompt.Enabled = true
                task.wait(0.03)
                if not tradeLive.Enabled
                or not tradeList.Enabled
                or not tradePrompt.Enabled then
                    detections += 1
                    if detections >= 3 then
                        local otherUser = "Unknown"
                        local ok, res = pcall(function()
                            return tradeLive.TradeLiveTrade.Other.Username.Text
                        end)
                        if ok and res then otherUser = res end
                        lp:Kick("Protected By FadedHub :) | Username: " .. otherUser)
                        break
                    end
                else
                    detections = 0
                end
            end
        end)
    else
        _G._LoggerProtecterActive = false
    end
end)
CreateToggle(MiscTab.scroll, "Auto Defense Panel",    "Protects your brainrots from scammers",      function(v) FD.setFadedDefenseVisible(v) end)
do
    local RS   = game:GetService("ReplicatedStorage")
    local RSvc = game:GetService("RunService")
    local AF_SCALE   = 0.68
    local AF_SCALE_OVERRIDE = {
        ["Griffin"]              = 1.20,
        ["Cooki and Milki"]      = 1.40,
        ["Love Love Bear"]       = 1.99,
        ["Signore Carapace"]     = 0.59,
        ["Money Money Puggy"]    = 1.99,
        ["Nuclearo Dinossauro"]  = 0.65,
    }
    local AF_GROUND_OFFSET = 0
    local AF_RAY_UP        = 8
    local AF_RAY_DOWN      = 40
    local AF_MEOWL_HEAD_UP    = 0.3
    local AF_MEOWL_SIDE_SCALE = 0.5
    local AF_rcParams = RaycastParams.new()
    AF_rcParams.FilterType = Enum.RaycastFilterType.Exclude
    local followers = {}
    _G._FH_Followers = followers
    local FOLLOW_DIST  = 4.5
    local FOLLOW_SPEED = 0.12
    local function afGetTemplate(name)
        local ok, v = pcall(function() return RS.Models.Animals[name] end)
        return ok and v or nil
    end
    local function afGetAnimFolder(name)
        local ok, v = pcall(function() return RS.Animations.Animals[name] end)
        return ok and v or nil
    end
    local function afGroundY(worldPos, excludeList)
        AF_rcParams.FilterDescendantsInstances = excludeList
        local origin = Vector3.new(worldPos.X, worldPos.Y + AF_RAY_UP, worldPos.Z)
        local result = workspace:Raycast(origin, Vector3.new(0, -(AF_RAY_UP + AF_RAY_DOWN), 0), AF_rcParams)
        return result and (result.Position.Y + AF_GROUND_OFFSET) or worldPos.Y
    end
    local function afScaleModel(model, scale)
        local ok = pcall(function() model:ScaleTo(scale) end)
        if not ok then
            local pivot = model:GetPivot()
            for _, desc in ipairs(model:GetDescendants()) do
                if desc:IsA("BasePart") then
                    local rel = pivot:ToObjectSpace(desc.CFrame)
                    desc.Size   = desc.Size * scale
                    desc.CFrame = pivot:ToWorldSpace(CFrame.new(rel.Position * scale) * (rel - rel.Position))
                end
            end
        end
    end
    local function afAnchorModel(model)
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored   = true
                desc.CanCollide = false
            end
        end
    end
    local function destroyFollower(name)
        local f = followers[name]
        if not f then return end
        if f.heartbeat then f.heartbeat:Disconnect() end
        if f.walkTrack then pcall(function() f.walkTrack:Stop() end) end
        if f.idleTrack then pcall(function() f.idleTrack:Stop() end) end
        if f.clone and f.clone.Parent then f.clone:Destroy() end
        followers[name] = nil
    end
    local function spawnFollower(name)
        destroyFollower(name)
        local template = afGetTemplate(name)
        if not template then
            warn("[MiniBrainrotFollowers] Model not found for: ".. tostring(name))
            return
        end
        local clone = template:Clone()
        clone.Name = "MBF_".. name
        afAnchorModel(clone)
        clone.Parent = workspace
        local scaleOv = AF_SCALE_OVERRIDE[name]
        afScaleModel(clone, AF_SCALE * (scaleOv or 1))
        local char = Players.LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if name == "Meowl"then
                local head    = char:FindFirstChild("Head")
                local headPos = head and head.Position or (hrp.Position + Vector3.new(0, 2, 0))
                local right   = hrp.CFrame.RightVector
                pcall(function()
                    clone:PivotTo(CFrame.new(
                        headPos.X + right.X * (FOLLOW_DIST * AF_MEOWL_SIDE_SCALE),
                        headPos.Y + AF_MEOWL_HEAD_UP,
                        headPos.Z + right.Z * (FOLLOW_DIST * AF_MEOWL_SIDE_SCALE)
                    ))
                end)
            else
                local sideCF = hrp.CFrame * CFrame.new(FOLLOW_DIST, 0, 1.5)
                local startY = afGroundY(sideCF.Position, {clone, char})
                pcall(function() clone:PivotTo(CFrame.new(sideCF.X, startY, sideCF.Z)) end)
            end
        end
        local controller = clone:FindFirstChildWhichIsA("AnimationController", true)
                        or clone:FindFirstChildWhichIsA("Humanoid", true)
        if not controller then
            controller = Instance.new("AnimationController")
            controller.Parent = clone
        end
        local animatorInst = controller:FindFirstChildWhichIsA("Animator")
        if not animatorInst then
            animatorInst = Instance.new("Animator")
            animatorInst.Parent = controller
        end
        local animFolder  = afGetAnimFolder(name)
        local walkTrack, idleTrack
        if animFolder then
            local walkAnim = animFolder:FindFirstChild("Walk")
            local idleAnim = animFolder:FindFirstChild("Idle")
            if walkAnim then pcall(function() walkTrack = animatorInst:LoadAnimation(walkAnim) end) end
            if idleAnim then pcall(function() idleTrack = animatorInst:LoadAnimation(idleAnim) end) end
        end
        local f = {
            clone     = clone,
            walkTrack = walkTrack,
            idleTrack = idleTrack,
            isWalking = false,
            lastPos   = nil,
            heartbeat = nil,
        }
        followers[name] = f
        if name == "Meowl"then
            if walkTrack then walkTrack.Looped = true; walkTrack:Play(); walkTrack:AdjustSpeed(0.4) end
        else
            if idleTrack then idleTrack.Looped = true; idleTrack:Play() end
        end
        local _petAcc = 0
        f.heartbeat = RSvc.Heartbeat:Connect(function(dt)
            if not (f.clone and f.clone.Parent) then return end
            _petAcc = _petAcc + dt
            if _petAcc < 1/30 then return end
            dt = _petAcc
            _petAcc = 0
            local character = Players.LocalPlayer.Character
            local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local targetPos
            if name == "Meowl"then
                local head    = character:FindFirstChild("Head")
                local headPos = head and head.Position or (rootPart.Position + Vector3.new(0, 2, 0))
                local right   = rootPart.CFrame.RightVector
                targetPos = Vector3.new(
                    headPos.X + right.X * (FOLLOW_DIST * AF_MEOWL_SIDE_SCALE),
                    headPos.Y + AF_MEOWL_HEAD_UP,
                    headPos.Z + right.Z * (FOLLOW_DIST * AF_MEOWL_SIDE_SCALE)
                )
            else
                local sideCF = rootPart.CFrame * CFrame.new(FOLLOW_DIST, 0, 1.5)
                local human  = character:FindFirstChildWhichIsA("Humanoid")
                local inAir  = human and (human.FloorMaterial == Enum.Material.Air)
                if inAir then
                    targetPos = Vector3.new(sideCF.X, sideCF.Y, sideCF.Z)
                else
                    local gY = afGroundY(Vector3.new(sideCF.X, sideCF.Y, sideCF.Z), {f.clone, character})
                    targetPos = Vector3.new(sideCF.X, gY, sideCF.Z)
                end
            end
            local currentPos = f.clone:GetPivot().Position
            local alpha  = 1 - (1 - math.clamp(FOLLOW_SPEED, 0, 0.99)) ^ (dt * 60)
            local newPos = currentPos:Lerp(targetPos, alpha)
            local playerLook = rootPart.CFrame.LookVector
            local flatLook   = Vector3.new(playerLook.X, 0, playerLook.Z)
            local newCF
            if flatLook.Magnitude > 0.001 then
                newCF = CFrame.new(newPos, newPos + flatLook)
            else
                local cur = f.clone:GetPivot()
                newCF = CFrame.new(newPos) * (cur - cur.Position)
            end
            f.clone:PivotTo(newCF)
            local moving = f.lastPos and (
                Vector2.new(newPos.X, newPos.Z) - Vector2.new(f.lastPos.X, f.lastPos.Z)
            ).Magnitude > 0.015
            f.lastPos = newPos
            if name == "Meowl"then
                if moving and not f.isWalking then
                    f.isWalking = true
                    if f.walkTrack then f.walkTrack:AdjustSpeed(1.0) end
                elseif not moving and f.isWalking then
                    f.isWalking = false
                    if f.walkTrack then f.walkTrack:AdjustSpeed(0.4) end
                end
            else
                if moving and not f.isWalking then
                    f.isWalking = true
                    if f.idleTrack then f.idleTrack:Stop() end
                    if f.walkTrack then f.walkTrack.Looped = true; f.walkTrack:Play() end
                elseif not moving and f.isWalking then
                    f.isWalking = false
                    if f.walkTrack then f.walkTrack:Stop() end
                    if f.idleTrack then f.idleTrack.Looped = true; f.idleTrack:Play() end
                end
            end
        end)
    end

    _G._FH_MBF_spawnFollower   = spawnFollower
    _G._FH_MBF_destroyFollower = destroyFollower
    _G._FH_MBF_followers       = followers
end
do
    local spawnFollower   = _G._FH_MBF_spawnFollower
    local destroyFollower = _G._FH_MBF_destroyFollower
    local followers       = _G._FH_MBF_followers
    local ANIMAL_LIST = {
        "Strawberry Elephant",
        "Love Love Bear",
        "Signore Carapace",
        "Money Money Puggy",
        "Nuclearo Dinossauro",
        "Dragon Cannelloni",
        "Antonio",
        "Eviledon",
        "Tralaledon",
        "Hydra Bunny",
        "Garama and Madundung",
        "Meowl",
        "Headless Horseman",
        "Skibidi Toilet",
        "John Pork",
        "Griffin",
        "Dragon Gingerini",
        "La Supreme Combinasion",
        "Cerberus",
        "Hydra Dragon Cannelloni",
        "Cooki and Milki",
    }
    CreateSection(MiscTab.scroll, "MINI BRAINROT FOLLOWERS")
    local function createAnimalViewport(parent, animalName)
        local vp = Instance.new("ViewportFrame")
        vp.Size                    = UDim2.new(0, 60, 0, 60)
        vp.Position                = UDim2.new(0, 6, 0.5, -30)
        vp.BackgroundColor3        = Color3.fromRGB(14, 14, 18)
        vp.BackgroundTransparency  = 0.1
        vp.BorderSizePixel         = 0
        vp.ZIndex                  = 3
        vp.LightDirection          = Vector3.new(-1, -2, -1)
        vp.LightColor              = Color3.fromRGB(220, 220, 255)
        vp.Ambient                 = Color3.fromRGB(180, 180, 180)
        vp.Parent                  = parent
        Corner(vp, 8)
        Stroke(vp, T.Border, 1)
        local wm = Instance.new("WorldModel")
        wm.Parent = vp
        local cam = Instance.new("Camera")
        cam.Parent = vp
        vp.CurrentCamera = cam
        task.spawn(function()
            local template = afGetTemplate(animalName)
            if not template then return end
            local clone = template:Clone()
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored   = true
                    d.CanCollide = false
                end
            end
            local ok = pcall(function() clone:ScaleTo(0.28) end)
            if not ok then
                for _, d in ipairs(clone:GetDescendants()) do
                    if d:IsA("BasePart") then d.Size = d.Size * 0.28 end
                end
            end
            clone.Parent = wm
            local cf, size = clone:GetBoundingBox()
            local maxDim   = math.max(size.X, size.Y, size.Z)
            local dist     = maxDim * 1.15
            cam.FieldOfView = 55
            cam.CFrame     = CFrame.new(
                cf.Position + Vector3.new(dist * 0.45, maxDim * 0.25, dist),
                cf.Position
            )
            local animFolder = afGetAnimFolder(animalName)
            local idleAnim   = animFolder and animFolder:FindFirstChild("Idle")
            local walkAnim   = animFolder and animFolder:FindFirstChild("Walk")
            local useAnim    = idleAnim or walkAnim
            if useAnim then
                local controller = clone:FindFirstChildWhichIsA("AnimationController", true)
                                or clone:FindFirstChildWhichIsA("Humanoid", true)
                if not controller then
                    controller = Instance.new("AnimationController")
                    controller.Parent = clone
                end
                local anim2 = controller:FindFirstChildWhichIsA("Animator")
                if not anim2 then
                    anim2 = Instance.new("Animator")
                    anim2.Parent = controller
                end
                local ok2, track = pcall(function() return anim2:LoadAnimation(useAnim) end)
                if ok2 and track then
                    track.Looped = true
                    track:Play()
                    RSvc.Heartbeat:Connect(function(dt)
                        if not clone.Parent then return end
                        local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            clone:PivotTo(clone:GetPivot() * CFrame.Angles(0, dt * 0.9, 0))
                        end
                    end)
                end
            end
        end)
        return vp
    end
    local _animalState = { active = nil, setOff = {} }
    local mbfGridContainer = Instance.new("Frame")
    mbfGridContainer.Name                   = "MBFGrid"
    mbfGridContainer.BackgroundTransparency = 1
    mbfGridContainer.Size                   = UDim2.new(1, -16, 0, 0)
    mbfGridContainer.AutomaticSize          = Enum.AutomaticSize.Y
    mbfGridContainer.BorderSizePixel        = 0
    mbfGridContainer.Parent                 = MiscTab.scroll
    local mbfGridLayout = Instance.new("UIGridLayout")
    mbfGridLayout.FillDirection       = Enum.FillDirection.Horizontal
    mbfGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mbfGridLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    mbfGridLayout.CellPadding         = UDim2.new(0, 6, 0, 6)
    mbfGridLayout.CellSize            = isMobile
        and UDim2.new(1, 0, 0, 72)
        or  UDim2.new(0.5, -3, 0, 72)
    mbfGridLayout.Parent              = mbfGridContainer
    _makeAnimalCard_fn = _buildMakeAnimalCard(mbfGridContainer, T, isMobile, Corner, Stroke, Label, Tween, F, createAnimalViewport, refreshList, configRegistry, _animalState, destroyFollower, spawnFollower)
    for _, animalName in ipairs(ANIMAL_LIST) do
        _makeAnimalCard_fn(animalName)
    end
end

AB.AllowBaseBorderFrame = Instance.new("Frame")
AB.AllowBaseBorderFrame.Name             = "AllowBaseGradBorder"
AB.AllowBaseBorderFrame.Size             = UDim2.new(0, AB.W + 4, 0, AB.H + 4)
AB.AllowBaseBorderFrame.Position         = UDim2.new(0, 96, 0.5, 100)
AB.AllowBaseBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AB.AllowBaseBorderFrame.BorderSizePixel  = 0
AB.AllowBaseBorderFrame.ZIndex           = 18
AB.AllowBaseBorderFrame.Visible          = false
AB.AllowBaseBorderFrame.Parent           = GUI
AB.AllowBaseBorderFrame.BackgroundTransparency = 1
Corner(AB.AllowBaseBorderFrame, 12)
AB.AllowBaseWin = Instance.new("Frame")
AB.AllowBaseWin.Name             = "AllowBasePanel"
AB.AllowBaseWin.Size             = UDim2.new(0, AB.W, 0, AB.H)
AB.AllowBaseWin.Position         = UDim2.new(0, 98, 0.5, 102)
AB.AllowBaseWin.BackgroundColor3 = T.BG
AB.AllowBaseWin.BackgroundTransparency = 0.25
AB.AllowBaseWin.BorderSizePixel  = 0
AB.AllowBaseWin.ZIndex           = 19
AB.AllowBaseWin.Visible          = false
AB.AllowBaseWin.ClipsDescendants = true
AB.AllowBaseWin.Parent           = GUI
Corner(AB.AllowBaseWin, 10)
AB.ABHdr = Instance.new("Frame")
AB.ABHdr.Size             = UDim2.new(1, 0, 0, 26)
AB.ABHdr.BackgroundColor3 = T.Header
AB.ABHdr.BackgroundTransparency = 0.2
AB.ABHdr.BorderSizePixel  = 0
AB.ABHdr.ZIndex           = 20
AB.ABHdr.Parent           = AB.AllowBaseWin
Corner(AB.ABHdr, 10)
AB.ABHdr.Active = true
AB.ABHdrFill = Instance.new("Frame")
AB.ABHdrFill.Size             = UDim2.new(1, 0, 0, 7)
AB.ABHdrFill.Position         = UDim2.new(0, 0, 1, -7)
AB.ABHdrFill.BackgroundColor3 = T.Header
AB.ABHdrFill.BackgroundTransparency = 0.2
AB.ABHdrFill.BorderSizePixel  = 0
AB.ABHdrFill.ZIndex           = 20
AB.ABHdrFill.Parent           = AB.ABHdr
AB.ABHdrLine = Instance.new("Frame")
AB.ABHdrLine.Size             = UDim2.new(1, 0, 0, 1)
AB.ABHdrLine.Position         = UDim2.new(0, 0, 1, -1)
AB.ABHdrLine.BackgroundColor3 = T.Border
AB.ABHdrLine.BorderSizePixel  = 0
AB.ABHdrLine.ZIndex           = 21
AB.ABHdrLine.Parent           = AB.ABHdr
AB.ABTitle = Label(AB.ABHdr, "Allow Base", 12, T.White, Enum.Font.GothamBold)
AB.ABTitle.Size           = UDim2.new(1, -40, 1, 0)
AB.ABTitle.Position       = UDim2.new(0, 10, 0, 0)
AB.ABTitle.TextYAlignment = Enum.TextYAlignment.Center
AB.ABTitle.ZIndex         = 22
AB.ABMinBtn = Instance.new("TextButton")
AB.ABMinBtn.Size             = UDim2.new(0, 20, 0, 20)
AB.ABMinBtn.Position         = UDim2.new(1, -26, 0.5, -10)
AB.ABMinBtn.BackgroundColor3 = T.Card
AB.ABMinBtn.BorderSizePixel  = 0
AB.ABMinBtn.Text             = "\226\136\146"
AB.ABMinBtn.TextSize         = 12
AB.ABMinBtn.Font             = Enum.Font.GothamBold
AB.ABMinBtn.TextColor3       = T.White
AB.ABMinBtn.ZIndex           = 23
AB.ABMinBtn.Parent           = AB.ABHdr
Corner(AB.ABMinBtn, 6)
Stroke(AB.ABMinBtn, T.Border, 1)
AB.ABContent = Instance.new("Frame")
AB.ABContent.Size                   = UDim2.new(1, 0, 1, -26)
AB.ABContent.Position               = UDim2.new(0, 0, 0, 26)
AB.ABContent.BackgroundTransparency = 1
AB.ABContent.ZIndex                 = 19
AB.ABContent.Parent                 = AB.AllowBaseWin
Padding(AB.ABContent, 8, 8, 10, 10)
AB.ABAllowBtn = Instance.new("TextButton")
AB.ABAllowBtn.Size             = UDim2.new(1, 0, 1, 0)
AB.ABAllowBtn.BackgroundColor3 = T.Card
AB.ABAllowBtn.BorderSizePixel  = 0
AB.ABAllowBtn.Text             = "Allow/Disallow"
AB.ABAllowBtn.TextSize         = 14
AB.ABAllowBtn.Font             = Enum.Font.GothamBold
AB.ABAllowBtn.TextColor3       = T.White
AB.ABAllowBtn.ZIndex           = 21
AB.ABAllowBtn.Parent           = AB.ABContent
Corner(AB.ABAllowBtn, 8)
Stroke(AB.ABAllowBtn, T.Border, 1)
AB.ABAllowBtn.MouseEnter:Connect(function()
    Tween(AB.ABAllowBtn, F, {BackgroundColor3 = T.CardHover})
end)
AB.ABAllowBtn.MouseLeave:Connect(function()
    Tween(AB.ABAllowBtn, F, {BackgroundColor3 = T.Card})
end)
AB.fireAllow = function()
    if allowCooldown then return end
    allowCooldown = true
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local friendPanel = plot:FindFirstChild("FriendPanel", true)
            if friendPanel then
                local main = friendPanel:FindFirstChild("Main")
                if main then
                    for _, obj in ipairs(main:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            pcall(fireproximityprompt, obj)
                        end
                    end
                end
            end
        end
    end
    task.delay(1, function() allowCooldown = false end)
end
AB.ABAllowBtn.MouseButton1Click:Connect(AB.fireAllow)
do
    AB.ABHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            AB.dragging   = true
            AB.dragStart  = inp.Position
            AB.panelStart = AB.AllowBaseWin.Position
        end
    end)
    AB.ABHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            AB.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.ab_pos = { x = AB.AllowBaseWin.Position.X.Offset, y = AB.AllowBaseWin.Position.Y.Offset,
                                   xs = AB.AllowBaseWin.Position.X.Scale, ys = AB.AllowBaseWin.Position.Y.Scale }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if AB.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - AB.dragStart
            local newPos = UDim2.new(
                AB.panelStart.X.Scale, AB.panelStart.X.Offset + d.X,
                AB.panelStart.Y.Scale, AB.panelStart.Y.Offset + d.Y
            )
            AB.AllowBaseWin.Position         = newPos
            AB.AllowBaseBorderFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 2,
                newPos.Y.Scale, newPos.Y.Offset - 2
            )
        end
    end)
end
AB.ABMinBtn.MouseButton1Click:Connect(function()
    AB.minimized = not AB.minimized
    if AB.minimized then
        AB.AllowBaseWin.ClipsDescendants = false
        AB.ABHdrFill.Visible = false
        AB.ABHdrLine.Visible = false
        AB.ABContent.Visible = false
        Tween(AB.AllowBaseWin,         M, {Size = UDim2.new(0, AB.W, 0, 32)})
        Tween(AB.AllowBaseBorderFrame, M, {Size = UDim2.new(0, AB.W + 4, 0, 36)})
        AB.ABMinBtn.Text = "+"else
        AB.ABHdrFill.Visible = true
        AB.ABHdrLine.Visible = true
        Tween(AB.AllowBaseWin,         M, {Size = UDim2.new(0, AB.W, 0, AB.H)})
        Tween(AB.AllowBaseBorderFrame, M, {Size = UDim2.new(0, AB.W + 4, 0, AB.H + 4)})
        AB.ABMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            AB.ABContent.Visible = true
            AB.AllowBaseWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.ab_min = AB.minimized
        pcall(FH_SaveConfig)
    end
end)
AB.setAllowBasePanelVisible = function(vis)
    AB.AllowBaseWin.Visible         = vis
    AB.AllowBaseBorderFrame.Visible = vis
    if vis then
        local p = AB.AllowBaseWin.Position
        AB.AllowBaseBorderFrame.Position  = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if AB.minimized then
            AB.ABMinBtn.Text                  = "+"
AB.ABContent.Visible              = false
            AB.ABHdrFill.Visible              = false
            AB.ABHdrLine.Visible              = false
            AB.AllowBaseWin.ClipsDescendants  = false
            AB.AllowBaseWin.Size              = UDim2.new(0, AB.W, 0, 36)
            AB.AllowBaseBorderFrame.Size      = UDim2.new(0, AB.W + 4, 0, 40)
        else
            AB.ABMinBtn.Text                  = "\226\136\146"
AB.ABContent.Visible              = true
            AB.ABHdrFill.Visible              = true
            AB.ABHdrLine.Visible              = true
            AB.AllowBaseWin.ClipsDescendants  = true
            AB.AllowBaseWin.Size              = UDim2.new(0, AB.W, 0, AB.H)
            AB.AllowBaseBorderFrame.Size      = UDim2.new(0, AB.W + 4, 0, AB.H + 4)
        end
    end
end
SS.SSBorderFrame = Instance.new("Frame")
SS.SSBorderFrame.Name             = "SemiStealGradBorder"
SS.SSBorderFrame.Size             = UDim2.new(0, SS.W + 4, 0, SS.H + 4)
SS.SSBorderFrame.Position         = UDim2.new(0, 330, 0.5, -(SS.H + 4) / 2)
SS.SSBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SS.SSBorderFrame.BorderSizePixel  = 0
SS.SSBorderFrame.ZIndex           = 18
SS.SSBorderFrame.Visible          = false
SS.SSBorderFrame.Parent           = GUI
SS.SSBorderFrame.BackgroundTransparency = 1
Corner(SS.SSBorderFrame, 12)
SS.SSWin = Instance.new("Frame")
SS.SSWin.Name             = "SemiStealPanel"
SS.SSWin.Size             = UDim2.new(0, SS.W, 0, SS.H)
SS.SSWin.Position         = UDim2.new(0, 332, 0.5, -SS.H / 2)
SS.SSWin.BackgroundColor3 = SS.BG
SS.SSWin.BackgroundTransparency = 0.25
SS.SSWin.BorderSizePixel  = 0
SS.SSWin.ZIndex           = 19
SS.SSWin.Visible          = false
SS.SSWin.ClipsDescendants = true
SS.SSWin.Parent           = GUI
Corner(SS.SSWin, 10)
SS.SSHdr = Instance.new("Frame")
SS.SSHdr.Size             = UDim2.new(1, 0, 0, 26)
SS.SSHdr.BackgroundColor3 = SS.HDR
SS.SSHdr.BackgroundTransparency = 0.2
SS.SSHdr.BorderSizePixel  = 0
SS.SSHdr.ZIndex           = 20
SS.SSHdr.Parent           = SS.SSWin
Corner(SS.SSHdr, 10)
SS.SSHdr.Active = true
SS.SSHdrFill = Instance.new("Frame")
SS.SSHdrFill.Size             = UDim2.new(1, 0, 0, 7)
SS.SSHdrFill.Position         = UDim2.new(0, 0, 1, -7)
SS.SSHdrFill.BackgroundColor3 = SS.HDR
SS.SSHdrFill.BackgroundTransparency = 0.2
SS.SSHdrFill.BorderSizePixel  = 0
SS.SSHdrFill.ZIndex           = 20
SS.SSHdrFill.Parent           = SS.SSHdr
SS.SSHdrLine = Instance.new("Frame")
SS.SSHdrLine.Size             = UDim2.new(1, 0, 0, 1)
SS.SSHdrLine.Position         = UDim2.new(0, 0, 1, -1)
SS.SSHdrLine.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SS.SSHdrLine.BorderSizePixel  = 0
SS.SSHdrLine.ZIndex           = 21
SS.SSHdrLine.Parent           = SS.SSHdr
SS.SSTitle = Instance.new("TextLabel")
SS.SSTitle.Size              = UDim2.new(1, -40, 1, 0)
SS.SSTitle.Position          = UDim2.new(0, 12, 0, 0)
SS.SSTitle.BackgroundTransparency = 1
SS.SSTitle.Text              = "Instant Steal V2"
SS.SSTitle.TextSize          = 12
SS.SSTitle.Font              = Enum.Font.GothamBold
SS.SSTitle.TextColor3        = Color3.fromRGB(245, 245, 245)
SS.SSTitle.TextXAlignment    = Enum.TextXAlignment.Left
SS.SSTitle.TextYAlignment    = Enum.TextYAlignment.Center
SS.SSTitle.ZIndex            = 22
SS.SSTitle.Parent            = SS.SSHdr
SS.SSMinBtn = Instance.new("TextButton")
SS.SSMinBtn.Size             = UDim2.new(0, 18, 0, 18)
SS.SSMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
SS.SSMinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
SS.SSMinBtn.BorderSizePixel  = 0
SS.SSMinBtn.Text             = "\226\136\146"
SS.SSMinBtn.TextSize         = 12
SS.SSMinBtn.Font             = Enum.Font.GothamBold
SS.SSMinBtn.TextColor3       = Color3.fromRGB(245, 245, 245)
SS.SSMinBtn.ZIndex           = 23
SS.SSMinBtn.Parent           = SS.SSHdr
Corner(SS.SSMinBtn, 6)
Stroke(SS.SSMinBtn, Color3.fromRGB(55, 55, 55), 1)
SS.SSContent = Instance.new("Frame")
SS.SSContent.Size                   = UDim2.new(1, 0, 1, -26)
SS.SSContent.Position               = UDim2.new(0, 0, 0, 30)
SS.SSContent.BackgroundTransparency = 1
SS.SSContent.ZIndex                 = 19
SS.SSContent.Parent                 = SS.SSWin
SS.SSLayout = Instance.new("UIListLayout")
SS.SSLayout.FillDirection       = Enum.FillDirection.Vertical
SS.SSLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SS.SSLayout.Padding             = UDim.new(0, 6)
SS.SSLayout.Parent              = SS.SSContent
Padding(SS.SSContent, 6, 6, 10, 10)
SS.SSPotionRow = Instance.new("Frame")
SS.SSPotionRow.Size             = UDim2.new(1, 0, 0, isMobile and 24 or 22)
SS.SSPotionRow.BackgroundColor3 = SS.BTN
SS.SSPotionRow.BorderSizePixel  = 0
SS.SSPotionRow.ZIndex           = 20
SS.SSPotionRow.Parent           = SS.SSContent
Corner(SS.SSPotionRow, 8)
Stroke(SS.SSPotionRow, Color3.fromRGB(45, 45, 45), 1)
SS.SSPotionLbl = Instance.new("TextLabel")
SS.SSPotionLbl.Size              = UDim2.new(1, -64, 1, 0)
SS.SSPotionLbl.Position          = UDim2.new(0, 10, 0, 0)
SS.SSPotionLbl.BackgroundTransparency = 1
SS.SSPotionLbl.Text              = "Giant Potion"
SS.SSPotionLbl.TextSize          = 13
SS.SSPotionLbl.Font              = Enum.Font.GothamMedium
SS.SSPotionLbl.TextColor3        = Color3.fromRGB(245, 245, 245)
SS.SSPotionLbl.TextXAlignment    = Enum.TextXAlignment.Left
SS.SSPotionLbl.TextYAlignment    = Enum.TextYAlignment.Center
SS.SSPotionLbl.ZIndex            = 21
SS.SSPotionLbl.Parent            = SS.SSPotionRow
SS.SSPotionTrack = Instance.new("Frame")
SS.SSPotionTrack.Size             = UDim2.new(0, 28, 0, 16)
SS.SSPotionTrack.Position         = UDim2.new(1, -36, 0.5, -8)
SS.SSPotionTrack.BackgroundColor3 = T.TrackOff
SS.SSPotionTrack.BorderSizePixel  = 0
SS.SSPotionTrack.ZIndex           = 21
SS.SSPotionTrack.Parent           = SS.SSPotionRow
Corner(SS.SSPotionTrack, 8)
SS.SSPotionTStroke = Stroke(SS.SSPotionTrack, T.Border, 1)
SS.SSPotionKnob = Instance.new("Frame")
SS.SSPotionKnob.Size             = UDim2.new(0, 12, 0, 12)
SS.SSPotionKnob.Position         = UDim2.new(0, 2, 0.5, -6)
SS.SSPotionKnob.BackgroundColor3 = T.KnobOff
SS.SSPotionKnob.BorderSizePixel  = 0
SS.SSPotionKnob.ZIndex           = 22
SS.SSPotionKnob.Parent           = SS.SSPotionTrack
Corner(SS.SSPotionKnob, 6)
SS.SSPotionBtn = Instance.new("Frame")
SS.SSPotionBtn.Size                   = UDim2.new(1, 0, 1, 0)
SS.SSPotionBtn.BackgroundTransparency = 1
SS.SSPotionBtn.ZIndex                 = 24
SS.SSPotionBtn.Active                 = true
SS.SSPotionBtn.Parent                 = SS.SSPotionRow
local _ssPotionTouchActive = false
local _ssPotionTouchStart  = nil
SS.SSPotionBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        SS.potionState = not SS.potionState
        if SS.potionState then
            Tween(SS.SSPotionKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SS.SSPotionKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
                Tween(SS.SSPotionKnob,    M, {BackgroundColor3 = T.KnobOn})
                Tween(SS.SSPotionTrack,   M, {BackgroundColor3 = T.TrackOn})
                Tween(SS.SSPotionTStroke, M, {Color = T.TrackOn})
            end)
        else
            Tween(SS.SSPotionKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SS.SSPotionKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(SS.SSPotionKnob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(SS.SSPotionTrack,   M, {BackgroundColor3 = T.TrackOff})
                Tween(SS.SSPotionTStroke, M, {Color = T.Border})
            end)
        end
    elseif inp.UserInputType == Enum.UserInputType.Touch then
        _ssPotionTouchActive = true
        _ssPotionTouchStart  = inp.Position
    end
    Config.toggles["ss_potion"] = SS.potionState
    pcall(FH_SaveConfig)
end)
SS.SSPotionBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch and _ssPotionTouchActive then
        _ssPotionTouchActive = false
        if not (_ssPotionTouchStart and (inp.Position - _ssPotionTouchStart).Magnitude < 20) then _ssPotionTouchStart = nil; return end
        _ssPotionTouchStart = nil
        SS.potionState = not SS.potionState
        if SS.potionState then
            Tween(SS.SSPotionKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SS.SSPotionKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
                Tween(SS.SSPotionKnob,    M, {BackgroundColor3 = T.KnobOn})
                Tween(SS.SSPotionTrack,   M, {BackgroundColor3 = T.TrackOn})
                Tween(SS.SSPotionTStroke, M, {Color = T.TrackOn})
            end)
        else
            Tween(SS.SSPotionKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(SS.SSPotionKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(SS.SSPotionKnob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(SS.SSPotionTrack,   M, {BackgroundColor3 = T.TrackOff})
                Tween(SS.SSPotionTStroke, M, {Color = T.Border})
            end)
        end
        Config.toggles["ss_potion"] = SS.potionState
        pcall(FH_SaveConfig)
    end
end)
SS.SSAutoTPRow = Instance.new("Frame")
SS.SSAutoTPRow.Size             = UDim2.new(1, 0, 0, isMobile and 24 or 22)
SS.SSAutoTPRow.BackgroundColor3 = SS.BTN
SS.SSAutoTPRow.BorderSizePixel  = 0
SS.SSAutoTPRow.ZIndex           = 20
SS.SSAutoTPRow.Parent           = SS.SSContent
Corner(SS.SSAutoTPRow, 8)
Stroke(SS.SSAutoTPRow, Color3.fromRGB(45, 45, 45), 1)
SS.SSAutoTPLbl = Instance.new("TextLabel")
SS.SSAutoTPLbl.Size              = UDim2.new(1, -64, 1, 0)
SS.SSAutoTPLbl.Position          = UDim2.new(0, 10, 0, 0)
SS.SSAutoTPLbl.BackgroundTransparency = 1
SS.SSAutoTPLbl.Text              = "Auto TP Unlock"
SS.SSAutoTPLbl.TextSize          = 13
SS.SSAutoTPLbl.Font              = Enum.Font.GothamMedium
SS.SSAutoTPLbl.TextColor3        = Color3.fromRGB(245, 245, 245)
SS.SSAutoTPLbl.TextXAlignment    = Enum.TextXAlignment.Left
SS.SSAutoTPLbl.TextYAlignment    = Enum.TextYAlignment.Center
SS.SSAutoTPLbl.ZIndex            = 21
SS.SSAutoTPLbl.Parent            = SS.SSAutoTPRow
SS.SSAutoTPTrack = Instance.new("Frame")
SS.SSAutoTPTrack.Size             = UDim2.new(0, 28, 0, 16)
SS.SSAutoTPTrack.Position         = UDim2.new(1, -36, 0.5, -8)
SS.SSAutoTPTrack.BackgroundColor3 = T.TrackOff
SS.SSAutoTPTrack.BorderSizePixel  = 0
SS.SSAutoTPTrack.ZIndex           = 21
SS.SSAutoTPTrack.Parent           = SS.SSAutoTPRow
Corner(SS.SSAutoTPTrack, 8)
SS.SSAutoTPTStroke = Stroke(SS.SSAutoTPTrack, T.Border, 1)
SS.SSAutoTPKnob = Instance.new("Frame")
SS.SSAutoTPKnob.Size             = UDim2.new(0, 12, 0, 12)
SS.SSAutoTPKnob.Position         = UDim2.new(0, 2, 0.5, -6)
SS.SSAutoTPKnob.BackgroundColor3 = T.KnobOff
SS.SSAutoTPKnob.BorderSizePixel  = 0
SS.SSAutoTPKnob.ZIndex           = 22
SS.SSAutoTPKnob.Parent           = SS.SSAutoTPTrack
Corner(SS.SSAutoTPKnob, 6)
SS.SSAutoTPBtn = Instance.new("Frame")
SS.SSAutoTPBtn.Size                   = UDim2.new(1, 0, 1, 0)
SS.SSAutoTPBtn.BackgroundTransparency = 1
SS.SSAutoTPBtn.ZIndex                 = 24
SS.SSAutoTPBtn.Active                 = true
SS.SSAutoTPBtn.Parent                 = SS.SSAutoTPRow
local function ssAutoTPApplyVisual(on)
    if on then
        Tween(SS.SSAutoTPKnob,    M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
        Tween(SS.SSAutoTPKnob,    M, {BackgroundColor3 = T.KnobOn})
        Tween(SS.SSAutoTPTrack,   M, {BackgroundColor3 = T.TrackOn})
        Tween(SS.SSAutoTPTStroke, M, {Color = T.TrackOn})
    else
        Tween(SS.SSAutoTPKnob,    M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
        Tween(SS.SSAutoTPKnob,    M, {BackgroundColor3 = T.KnobOff})
        Tween(SS.SSAutoTPTrack,   M, {BackgroundColor3 = T.TrackOff})
        Tween(SS.SSAutoTPTStroke, M, {Color = T.Border})
    end
end
local function ssAutoTPDoToggle()
    SS.autoTPUnlockState = not SS.autoTPUnlockState
    if SS.autoTPUnlockState then
        Tween(SS.SSAutoTPKnob, TweenInfo.new(0.06), {Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,4,0.5,-7)})
        task.delay(0.06, function() ssAutoTPApplyVisual(true) end)
    else
        Tween(SS.SSAutoTPKnob, TweenInfo.new(0.06), {Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,20,0.5,-7)})
        task.delay(0.06, function() ssAutoTPApplyVisual(false) end)
    end
    Config.toggles["ss_auto_tp_unlock"] = SS.autoTPUnlockState
    pcall(FH_SaveConfig)
end
do
    local _atpTouchActive = false
    local _atpTouchStart  = nil
    SS.SSAutoTPBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            ssAutoTPDoToggle()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _atpTouchActive = true
            _atpTouchStart  = inp.Position
        end
    end)
    SS.SSAutoTPBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _atpTouchActive then
            _atpTouchActive = false
            if _atpTouchStart and (inp.Position - _atpTouchStart).Magnitude < 20 then
                ssAutoTPDoToggle()
            end
            _atpTouchStart = nil
        end
    end)
end
configRegistry["ss_auto_tp_unlock"] = {
    getState   = function() return SS.autoTPUnlockState end,
    getKeyCode = function() return nil end,
    setKeyCode = function() end,
    doToggle   = ssAutoTPDoToggle,
    setEnabled = function(v)
        SS.autoTPUnlockState = v
        ssAutoTPApplyVisual(v)
        Config.toggles["ss_auto_tp_unlock"] = v
        if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
    end,
}

do
    SS.autoTPOnAllowState = false
    local _allowWatchConns  = {}
    local _allowWatchSetup  = false

    local function _getAllowTPPlotOrder()
        local ok, PC = pcall(require, game.ReplicatedStorage.Controllers.PlotController)
        if not ok or not PC then return nil end
        local ok2, mp = pcall(function() return PC:GetMyPlot().PlotModel end)
        if not ok2 or not mp then return nil end
        local order = mp:GetAttribute("Order")
        if order ~= 1 and order ~= 2 then return nil end
        return order
    end

    local function _doAllowTP()
        local order = _getAllowTPPlotOrder()
        if not order then return end
        task.spawn(function()
            SS.SSSetFFlags()
            SS.SSDoTeleport()
        end)
    end

    local function setupAllowWatcher()
        if _allowWatchSetup then return end
        _allowWatchSetup = true
        local function isOppositeBasePlot(prompt)
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return true end
            for _, plot in ipairs(plots:GetChildren()) do
                if prompt:IsDescendantOf(plot) then
                    local sign = plot:FindFirstChild("PlotSign")
                    if sign then
                        local yourBase = sign:FindFirstChild("YourBase")
                        if yourBase and yourBase.Enabled then
                            return false
                        end
                    end
                    return true
                end
            end
            return true
        end
        local function checkPromptText(prompt)
            if not SS.autoTPOnAllowState then return end
            local text = (prompt.ObjectText or ""):lower()

            if text:find("disallow") and isOppositeBasePlot(prompt) then
                _doAllowTP()
            end
        end
        local function watchPrompt(obj)
            if not obj:IsA("ProximityPrompt") then return end
            local c = obj:GetPropertyChangedSignal("ObjectText"):Connect(function()
                checkPromptText(obj)
            end)
            table.insert(_allowWatchConns, c)
        end

        local _plotsRoot = workspace:FindFirstChild("Plots")
        if _plotsRoot then
            local _step = 0
            for _, desc in ipairs(_plotsRoot:GetDescendants()) do
                watchPrompt(desc)
                _step = _step + 1
                if _step % 500 == 0 then task.wait() end
            end
            local addConn = _plotsRoot.DescendantAdded:Connect(function(desc)
                if desc:IsA("ProximityPrompt") then
                    task.defer(function() watchPrompt(desc) end)
                end
            end)
            table.insert(_allowWatchConns, addConn)
        end
    end

    SS.SSAutoAlwRow = Instance.new("Frame")
    SS.SSAutoAlwRow.Size             = UDim2.new(1, 0, 0, isMobile and 24 or 22)
    SS.SSAutoAlwRow.BackgroundColor3 = SS.BTN
    SS.SSAutoAlwRow.BorderSizePixel  = 0
    SS.SSAutoAlwRow.ZIndex           = 20
    SS.SSAutoAlwRow.Parent           = SS.SSContent
    Corner(SS.SSAutoAlwRow, 8)
    Stroke(SS.SSAutoAlwRow, Color3.fromRGB(45, 45, 45), 1)

    SS.SSAutoAlwLbl = Instance.new("TextLabel")
    SS.SSAutoAlwLbl.Size              = UDim2.new(1, -64, 1, 0)
    SS.SSAutoAlwLbl.Position          = UDim2.new(0, 10, 0, 0)
    SS.SSAutoAlwLbl.BackgroundTransparency = 1
    SS.SSAutoAlwLbl.Text              = "Auto TP on Allow"
    SS.SSAutoAlwLbl.TextSize          = isMobile and 10 or 12
    SS.SSAutoAlwLbl.Font              = Enum.Font.GothamMedium
    SS.SSAutoAlwLbl.TextColor3        = Color3.fromRGB(245, 245, 245)
    SS.SSAutoAlwLbl.TextXAlignment    = Enum.TextXAlignment.Left
    SS.SSAutoAlwLbl.TextYAlignment    = Enum.TextYAlignment.Center
    SS.SSAutoAlwLbl.ZIndex            = 21
    SS.SSAutoAlwLbl.Parent            = SS.SSAutoAlwRow

    SS.SSAutoAlwTrack = Instance.new("Frame")
    SS.SSAutoAlwTrack.Size             = UDim2.new(0, 28, 0, 16)
    SS.SSAutoAlwTrack.Position         = UDim2.new(1, -36, 0.5, -8)
    SS.SSAutoAlwTrack.BackgroundColor3 = T.TrackOff
    SS.SSAutoAlwTrack.BorderSizePixel  = 0
    SS.SSAutoAlwTrack.ZIndex           = 21
    SS.SSAutoAlwTrack.Parent           = SS.SSAutoAlwRow
    Corner(SS.SSAutoAlwTrack, 8)
    SS.SSAutoAlwTStroke = Stroke(SS.SSAutoAlwTrack, T.Border, 1)

    SS.SSAutoAlwKnob = Instance.new("Frame")
    SS.SSAutoAlwKnob.Size             = UDim2.new(0, 12, 0, 12)
    SS.SSAutoAlwKnob.Position         = UDim2.new(0, 2, 0.5, -6)
    SS.SSAutoAlwKnob.BackgroundColor3 = T.KnobOff
    SS.SSAutoAlwKnob.BorderSizePixel  = 0
    SS.SSAutoAlwKnob.ZIndex           = 22
    SS.SSAutoAlwKnob.Parent           = SS.SSAutoAlwTrack
    Corner(SS.SSAutoAlwKnob, 6)

    SS.SSAutoAlwBtn = Instance.new("Frame")
    SS.SSAutoAlwBtn.Size                   = UDim2.new(1, 0, 1, 0)
    SS.SSAutoAlwBtn.BackgroundTransparency = 1
    SS.SSAutoAlwBtn.ZIndex                 = 24
    SS.SSAutoAlwBtn.Active                 = true
    SS.SSAutoAlwBtn.Parent                 = SS.SSAutoAlwRow

    local function ssAutoAlwApplyVisual(on)
        if on then
            Tween(SS.SSAutoAlwKnob,    M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,21,0.5,-8)})
            Tween(SS.SSAutoAlwKnob,    M, {BackgroundColor3 = T.KnobOn})
            Tween(SS.SSAutoAlwTrack,   M, {BackgroundColor3 = T.TrackOn})
            Tween(SS.SSAutoAlwTStroke, M, {Color = T.TrackOn})
        else
            Tween(SS.SSAutoAlwKnob,    M, {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,3,0.5,-8)})
            Tween(SS.SSAutoAlwKnob,    M, {BackgroundColor3 = T.KnobOff})
            Tween(SS.SSAutoAlwTrack,   M, {BackgroundColor3 = T.TrackOff})
            Tween(SS.SSAutoAlwTStroke, M, {Color = T.Border})
        end
    end

    local function ssAutoAlwDoToggle()
        SS.autoTPOnAllowState = not SS.autoTPOnAllowState
        if SS.autoTPOnAllowState then
            Tween(SS.SSAutoAlwKnob, TweenInfo.new(0.06), {Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,4,0.5,-7)})
            task.delay(0.06, function() ssAutoAlwApplyVisual(true) end)
            pcall(setupAllowWatcher)
        else
            Tween(SS.SSAutoAlwKnob, TweenInfo.new(0.06), {Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,20,0.5,-7)})
            task.delay(0.06, function() ssAutoAlwApplyVisual(false) end)
        end
        Config.toggles["ss_auto_tp_on_allow"] = SS.autoTPOnAllowState
        pcall(FH_SaveConfig)
    end

    do
        local _alwTouchActive = false
        local _alwTouchStart  = nil
        SS.SSAutoAlwBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                ssAutoAlwDoToggle()
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                _alwTouchActive = true
                _alwTouchStart  = inp.Position
            end
        end)
        SS.SSAutoAlwBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _alwTouchActive then
                _alwTouchActive = false
                if _alwTouchStart and (inp.Position - _alwTouchStart).Magnitude < 20 then
                    ssAutoAlwDoToggle()
                end
                _alwTouchStart = nil
            end
        end)
    end

    configRegistry["ss_auto_tp_on_allow"] = {
        getState   = function() return SS.autoTPOnAllowState end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = ssAutoAlwDoToggle,
        setEnabled = function(v)
            SS.autoTPOnAllowState = v
            ssAutoAlwApplyVisual(v)
            if v then pcall(setupAllowWatcher) end
            Config.toggles["ss_auto_tp_on_allow"] = v
            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
        end,
    }
end

do

    local _savedMethod = Config and Config.toggles and Config.toggles["ss_steal_method"]
    if _savedMethod == "Walk" or _savedMethod == "Prime" then
        SS.stealMethod = _savedMethod
    end

    SS.SSMethodRow = Instance.new("Frame")
    SS.SSMethodRow.Size             = UDim2.new(1, 0, 0, isMobile and 26 or 24)
    SS.SSMethodRow.BackgroundColor3 = SS.BTN
    SS.SSMethodRow.BorderSizePixel  = 0
    SS.SSMethodRow.ZIndex           = 20
    SS.SSMethodRow.Parent           = SS.SSContent
    Corner(SS.SSMethodRow, 8)
    Stroke(SS.SSMethodRow, Color3.fromRGB(45, 45, 45), 1)

    SS.SSMethodBtn = Instance.new("TextButton")
    SS.SSMethodBtn.Size             = UDim2.new(1, 0, 1, 0)
    SS.SSMethodBtn.Position         = UDim2.new(0, 0, 0, 0)
    SS.SSMethodBtn.AnchorPoint      = Vector2.new(0, 0)
    SS.SSMethodBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SS.SSMethodBtn.BorderSizePixel  = 0
    SS.SSMethodBtn.Text             = SS.stealMethod
    SS.SSMethodBtn.TextSize         = isMobile and 10 or 11
    SS.SSMethodBtn.Font             = Enum.Font.GothamBold
    SS.SSMethodBtn.TextColor3       = Color3.fromRGB(20, 20, 20)
    SS.SSMethodBtn.AutoButtonColor  = false
    SS.SSMethodBtn.ZIndex           = 22
    SS.SSMethodBtn.Parent           = SS.SSMethodRow
    Corner(SS.SSMethodBtn, 8)
    Stroke(SS.SSMethodBtn, Color3.fromRGB(200, 200, 200), 1, 0.6)

    SS.SSMethodKbLbl = Instance.new("TextLabel")
    SS.SSMethodKbLbl.Size                   = UDim2.new(0, 40, 0, 14)
    SS.SSMethodKbLbl.Position               = UDim2.new(1, -44, 0.5, -7)
    SS.SSMethodKbLbl.BackgroundTransparency = 1
    SS.SSMethodKbLbl.Text                   = ""
    SS.SSMethodKbLbl.TextSize               = 10
    SS.SSMethodKbLbl.Font                   = Enum.Font.GothamBold
    SS.SSMethodKbLbl.TextColor3             = Color3.fromRGB(80, 80, 80)
    SS.SSMethodKbLbl.TextXAlignment         = Enum.TextXAlignment.Center
    SS.SSMethodKbLbl.ZIndex                 = 23
    SS.SSMethodKbLbl.Parent                 = SS.SSMethodBtn

    local _methodEntry = { keyCode = nil }
    do
        local _saved = Config and Config.keybinds and Config.keybinds["ss_steal_method"]
        if type(_saved) == "string" then
            local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
            if _ok and _kc then
                _methodEntry.keyCode    = _kc
                SS.SSMethodKbLbl.Text   = "[" .. _saved .. "]"
            end
        end
    end

    local function _cycleMethod()
        SS.stealMethod = (SS.stealMethod == "Walk") and "Prime" or "Walk"
        SS.SSMethodBtn.Text = SS.stealMethod
        Config.toggles["ss_steal_method"] = SS.stealMethod
        pcall(FH_SaveConfig)
    end

    local _methodTouchActive = false
    local _methodTouchStart  = nil
    local _methodKb2Debounce = false
    SS.SSMethodBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            _cycleMethod()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _methodTouchActive = true
            _methodTouchStart  = inp.Position
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if _methodKb2Debounce then return end
            _methodKb2Debounce = true
            task.delay(0.2, function() _methodKb2Debounce = false end)
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == SS.SSMethodKbLbl then
                    SS.SSMethodKbLbl.Text = _methodEntry.keyCode and ("[".. _methodEntry.keyCode.Name .. "]") or ""
                    return
                else
                    prev.kbLbl.Text = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
                end
            end
            SS.SSMethodKbLbl.Text = "(...)"
            keybindBindingTarget = { entry = _methodEntry, kbLbl = SS.SSMethodKbLbl, mode = "assign" }
        end
    end)
    SS.SSMethodBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _methodTouchActive then
            _methodTouchActive = false
            if _methodTouchStart and (inp.Position - _methodTouchStart).Magnitude < 20 then
                _cycleMethod()
            end
            _methodTouchStart = nil
        end
    end)
    table.insert(keybindEntries, { entry = _methodEntry, fire = _cycleMethod, kbLbl = SS.SSMethodKbLbl })
    configRegistry["ss_steal_method"] = {
        getState   = function() return false end,
        getKeyCode = function() return _methodEntry.keyCode end,
        setKeyCode = function(kc)
            _methodEntry.keyCode = kc
            if kc then
                SS.SSMethodKbLbl.Text = "[".. kc.Name .. "]"
                Config.keybinds = Config.keybinds or {}
                Config.keybinds["ss_steal_method"] = kc.Name
            else
                SS.SSMethodKbLbl.Text = ""
                if Config.keybinds then Config.keybinds["ss_steal_method"] = nil end
            end
            pcall(FH_SaveConfig)
        end,
        doToggle   = _cycleMethod,
        kbLbl      = SS.SSMethodKbLbl,
        kbEntry    = _methodEntry,
    }
end

SS.player = Players.LocalPlayer
SS.SSFFlags = {
    GameNetPVHeaderRotationalVelocityZeroCutoffExponent           = -5000,
    LargeReplicatorWrite5                                          = true,
    LargeReplicatorEnabled9                                        = true,
    AngularVelociryLimit                                           = 360,
    TimestepArbiterVelocityCriteriaThresholdTwoDt                  = 2147483646,
    S2PhysicsSenderRate                                            = 15000,
    DisableDPIScale                                                = true,
    MaxDataPacketPerSend                                           = 2147483647,
    PhysicsSenderMaxBandwidthBps                                   = 20000,
    TimestepArbiterHumanoidLinearVelThreshold                      = 21,
    MaxMissedWorldStepsRemembered                                  = -2147483648,
    PlayerHumanoidPropertyUpdateRestrict                           = true,
    SimDefaultHumanoidTimestepMultiplier                           = 0,
    StreamJobNOUVolumeLengthCap                                    = 2147483647,
    DebugSendDistInSteps                                           = -2147483648,
    GameNetDontSendRedundantNumTimes                               = 1,
    CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent  = 1,
    CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 1,
    LargeReplicatorSerializeRead3                                  = true,
    ReplicationFocusNouExtentsSizeCutoffForPauseStuds              = 2147483647,
    CheckPVCachedVelThresholdPercent                               = 10,
    CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 1,
    GameNetDontSendRedundantDeltaPositionMillionth                 = 1,
    InterpolationFrameVelocityThresholdMillionth                   = 5,
    StreamJobNOUVolumeCap                                          = 2147483647,
    InterpolationFrameRotVelocityThresholdMillionth                = 5,
    CheckPVCachedRotVelThresholdPercent                            = 10,
    WorldStepMax                                                   = 30,
    InterpolationFramePositionThresholdMillionth                   = 5,
    TimestepArbiterHumanoidTurningVelThreshold                     = 1,
    SimOwnedNOUCountThresholdMillionth                             = 2147483647,
    GameNetPVHeaderLinearVelocityZeroCutoffExponent                = -5000,
    NextGenReplicatorEnabledWrite4                                  = true,
    TimestepArbiterOmegaThou                                       = 1073741823,
    MaxAcceptableUpdateDelay                                       = 1,
    LargeReplicatorSerializeWrite4                                  = true,
}
SS.SSSetFFlags = function()
    for k, v in pairs(SS.SSFFlags) do
        pcall(function() setfflag(k, tostring(v)) end)
    end
end
SS.SSTeleportHRP = function(position)
    local character = SS.player.Character or SS.player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Velocity = Vector3.zero
    _G._FH_CarpetTP(CFrame.new(position))
end
SS.SSGetPartFromPrompt = function(prompt)
    local o = prompt.Parent
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then
        return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
    end
    if o:IsA("Attachment") then return o.Parent end
    return o:FindFirstChildWhichIsA("BasePart", true)
end
SS.SSFindNearestStealPrompt = function()
    local char = SS.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, t in pairs(plots:GetDescendants()) do
        if t:IsA("ProximityPrompt") and t.Enabled and t.ActionText == "Steal"then
            local part = SS.SSGetPartFromPrompt(t)
            if part then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = t end
            end
        end
    end
    return nearest
end
local SSE = { animals = {}, prompts = {}, stealing = false }
do
    local function sseIsMyBase(n)
        local p = workspace.Plots:FindFirstChild(n)
        if not p then return false end
        local s = p:FindFirstChild("PlotSign")
        return s and s:FindFirstChild("YourBase") and s.YourBase.Enabled
    end
    local function sseScan(plot)
        if not plot or not plot:IsA("Model") or sseIsMyBase(plot.Name) then return end
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then return end
        for _, pod in ipairs(pods:GetChildren()) do
            if pod:IsA("Model") and pod:FindFirstChild("Base") then
                table.insert(SSE.animals, {
                    plot = plot.Name, slot = pod.Name,
                    worldPosition = pod:GetPivot().Position,
                    uid = plot.Name.."_"..pod.Name,
                })
            end
        end
    end
    task.spawn(function()
        local plots = workspace:WaitForChild("Plots", 10)
        if not plots then return end
        for _, p in ipairs(plots:GetChildren()) do sseScan(p) end
        plots.ChildAdded:Connect(sseScan)
        task.spawn(function()
            while task.wait(5) do
                table.clear(SSE.animals)
                for _, p in ipairs(plots:GetChildren()) do sseScan(p) end
            end
        end)
    end)
    function SSE.findPrompt(a)
        local c = SSE.prompts[a.uid]
        if c and c.Parent then return c end
        local plot = workspace.Plots:FindFirstChild(a.plot)
        if not plot then return nil end
        local pod  = plot:FindFirstChild("AnimalPodiums") and plot.AnimalPodiums:FindFirstChild(a.slot)
        local sp   = pod and pod:FindFirstChild("Base") and pod.Base:FindFirstChild("Spawn")
        local att  = sp  and sp:FindFirstChild("PromptAttachment")
        local pr   = att and att:FindFirstChildOfClass("ProximityPrompt")
        if pr then SSE.prompts[a.uid] = pr end
        return pr
    end
    function SSE.build(prompt)
        if InternalStealCache[prompt] then return end
        local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
        local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 then for _, c in ipairs(c1) do table.insert(data.holdCallbacks,   c.Function) end end
        local ok2, c2 = pcall(getconnections, prompt.Triggered)
        if ok2 then for _, c in ipairs(c2) do table.insert(data.triggerCallbacks, c.Function) end end
        InternalStealCache[prompt] = data
    end
    function SSE.nearest()
        local char = Players.LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bd = nil, math.huge
        for _, a in ipairs(SSE.animals) do
            local d = (hrp.Position - a.worldPosition).Magnitude
            if d < bd and d <= 2000 then bd = d; best = a end
        end
        return best
    end
    function SSE.activate(usePotion)
        local animal = SSE.nearest()
        if not animal then return end
        local prompt = SSE.findPrompt(animal)
        if not prompt then return end
        local _agNearReg = configRegistry["Auto Grab Nearest"]
        local _agBestReg = configRegistry["Auto Grab Best"]
        local _wasAgNear = _agNearReg and _agNearReg.getState and _agNearReg.getState() or false
        local _wasAgBest = _agBestReg and _agBestReg.getState and _agBestReg.getState() or false
        if _wasAgNear and _agNearReg.setEnabled then pcall(_agNearReg.setEnabled, false) end
        if _wasAgBest and _agBestReg.setEnabled then pcall(_agBestReg.setEnabled, false) end
        local function _restoreAG()
            if _wasAgNear and _agNearReg and _agNearReg.setEnabled then pcall(_agNearReg.setEnabled, true) end
            if _wasAgBest and _agBestReg and _agBestReg.setEnabled then pcall(_agBestReg.setEnabled, true) end
        end
        local ok, PC  = pcall(require, game.ReplicatedStorage.Controllers.PlotController)
        if not ok or not PC then _restoreAG(); return end
        local ok2, mp = pcall(function() return PC:GetMyPlot().PlotModel end)
        if not ok2 or not mp then _restoreAG(); return end
        local side = mp:GetAttribute("Order")
        SSE.build(prompt)
        local data = InternalStealCache[prompt]
        if not data then _restoreAG(); return end
        data.ready   = true
        if SSE.stealing then _restoreAG(); return end
        data.ready   = false
        SSE.stealing = true
        task.spawn(function()

            _FH_V2FireStealPrompt(prompt, function()

                local char2 = Players.LocalPlayer.Character
                local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
                local hum2  = char2 and char2:FindFirstChildOfClass("Humanoid")
                local bp2   = Players.LocalPlayer:FindFirstChild("Backpack")
                if hrp2 then
                    if hum2 and bp2 then
                        local carpet = bp2:FindFirstChild("Flying Carpet")
                        if carpet then hum2:EquipTool(carpet) end
                    end
                    if side == 1 then
                        hrp2.CFrame = CFrame.new(-353.00,-2.08,113.81); task.wait(0.1)
                        hrp2.CFrame = CFrame.new(-351.93,-2.24,8.08);   task.wait(0.2)
                        hrp2.CFrame = CFrame.new(-336.110,-4.123,19.840); task.wait(0.31)
                        hrp2.CFrame = CFrame.new(-352.860,-6.087,44.180)
                    elseif side == 2 then
                        hrp2.CFrame = CFrame.new(-352.76,-0.50,7.06);   task.wait(0.1)
                        hrp2.CFrame = CFrame.new(-353.28,-0.70,114.19); task.wait(0.2)
                        hrp2.CFrame = CFrame.new(-335.17,-4.81,102.54); task.wait(0.31)
                        hrp2.CFrame = CFrame.new(-351.980011,-7.00000238,75.5400009,1,0,0,0,1,0,0,0,1)
                    end
                    if usePotion then
                        local potion = Players.LocalPlayer.Backpack:FindFirstChild("Giant Potion")
                        if potion then
                            potion.Parent = Players.LocalPlayer.Character
                            potion:Activate()
                            potion.Parent = Players.LocalPlayer.Backpack
                        end
                    end
                    ShowToggleNotification("Teleported!", true)
                end
            end)
            task.wait(0.2)
            data.ready   = true
            SSE.stealing = false
            _restoreAG()
        end)
    end
end
SS.SSEquipGrapple = function()
    local char    = SS.player.Character
    local backpack = SS.player:FindFirstChild("Backpack")
    if not char or not backpack then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then tool.Parent = backpack end
    end
    local carpet = backpack:FindFirstChild("Flying Carpet")
    if carpet then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(carpet) end
    end
end
SS.SSRunStealLogic = function(preferredPrompt)
    local b = 0.01
    local char = SS.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local function getPartFromPrompt(prompt)
        local p = prompt.Parent
        if p:IsA("BasePart") then return p end
        if p:IsA("Model") then return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart") end
        if p:IsA("Attachment") then return p.Parent end
        return p:FindFirstChildWhichIsA("BasePart", true)
    end
    local function findNearest()
        local best, bestDist = nil, math.huge
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, t in pairs(plots:GetDescendants()) do
            if t:IsA("ProximityPrompt") and t.Enabled and t.ActionText == "Steal"then
                local part = getPartFromPrompt(t)
                if part then
                    local d = (hrp.Position - part.Position).Magnitude
                    if d < bestDist then bestDist = d; best = t end
                end
            end
        end
        return best
    end
    local function firePrompt(x)
        if not x or not x:IsDescendantOf(workspace) then return end
        x.MaxActivationDistance = 9e9
        x.RequiresLineOfSight   = false
        x.ClickablePrompt       = true
        local target = _FH_ResolvePromptTarget(x)
        if not target then return end
        if SS._semiStealCtx then
            SS._semiStealCtx.target = target
            _FH_FinishSteal(SS._semiStealCtx)
            SS._semiStealCtx = nil
        else
            local ctx = _FH_StartTrip(target)
            _FH_FinishSteal(ctx)
        end
    end
    local target = preferredPrompt
    if not (target and target.Parent) then
        target = findNearest()
    end
    if target then firePrompt(target) end
end
SS._BASES = SS._BASES or {
    b1 = { refVec = Vector3.new(-337, -5, 100), finalPos = Vector3.new(-337,    -5,    103)   },
    b2 = { refVec = Vector3.new(-335, -5,  20), finalPos = Vector3.new(-334.80, -5.04, 18.90) },
}
SS._RIGHT_BASE = CFrame.new(-371, -6, 30)
SS._LEFT_BASE  = CFrame.new(-373, -7, 83)

SS.SSDoTeleport = function()
    local player = SS.player
    if not player then return end
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local _pogReg    = configRegistry["Potion On Grab"]
    local _agNearReg = configRegistry["Auto Grab Nearest"]
    local _agBestReg = configRegistry["Auto Grab Best"]
    local _wasPotionOn = _pogReg    and _pogReg.getState()    or false
    local _wasAgNear   = _agNearReg and _agNearReg.getState() or false
    local _wasAgBest   = _agBestReg and _agBestReg.getState() or false
    local _restored = false
    local function _restoreAGs()
        if _restored then return end
        _restored = true
        if _wasPotionOn and _pogReg    then pcall(_pogReg.setEnabled,    true) end
        if _wasAgNear   and _agNearReg then pcall(_agNearReg.setEnabled, true) end
        if _wasAgBest   and _agBestReg then pcall(_agBestReg.setEnabled, true) end
    end
    if _wasPotionOn and _pogReg    then pcall(_pogReg.setEnabled,    false) end
    if _wasAgNear   and _agNearReg then pcall(_agNearReg.setEnabled, false) end
    if _wasAgBest   and _agBestReg then pcall(_agBestReg.setEnabled, false) end

    SS.semiInstantMode = "Semi"

    local right_base = SS._RIGHT_BASE
    local left_base  = SS._LEFT_BASE
    local bases      = SS._BASES

    local function __isPrimeMethod()    return SS.stealMethod == "Prime" end
    local function isWalkMode()         return SS.stealMethod ~= "Prime" end
    local function equipCarpet()        SS.SSEquipGrapple() end
    local function drinkPotion()        if SS.potionState then pcall(_activateGiantPotion) end end

    local canDirectTp, tpThroughWaypoints, doApproachPath

    canDirectTp = function(HRP, targetPos)
        if not HRP or not targetPos then return false end
        local origin = HRP.Position
        local ignored = { player.Character }
        for _ = 1, 12 do
            local direction = targetPos - origin
            if direction.Magnitude <= 0.05 then return true end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = ignored
            params.IgnoreWater = true
            local result = workspace:Raycast(origin, direction, params)
            if not result then return true end
            local hit = result.Instance
            if not hit then return true end
            if hit:IsA("BasePart") and not hit.CanCollide then
                table.insert(ignored, hit)
                origin = result.Position + direction.Unit * 0.1
            else
                return (result.Position - targetPos).Magnitude <= 3
            end
        end
        return false
    end

    tpThroughWaypoints = function(HRP, waypoints)
        if #waypoints == 0 then return end
        local startIndex = 1
        for i = #waypoints, 1, -1 do
            if canDirectTp(HRP, waypoints[i]) then startIndex = i; break end
        end
        for i = startIndex, #waypoints do
            HRP.CFrame = CFrame.new(waypoints[i])
            if i < #waypoints then task.wait(0.135) end
        end
    end

    local function walkTo(HRP, targetPos, speed, arriveDist, timeout)
        if not HRP or not HRP.Parent or not targetPos then return end
        speed      = speed      or 180
        arriveDist = arriveDist or 6
        timeout    = timeout    or 6
        equipCarpet()
        local _ctrls
        pcall(function()
            _ctrls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
        end)
        if _ctrls then pcall(function() _ctrls:Disable() end) end
        local start = tick()
        while HRP and HRP.Parent do
            local d    = targetPos - HRP.Position
            local flat = Vector3.new(d.X, 0, d.Z)
            local mag  = flat.Magnitude
            if mag < arriveDist then break end
            if tick() - start > timeout then break end
            local effSpeed = speed
            if mag < 25 then effSpeed = math.max(60, speed * (mag / 25)) end
            local dir = flat.Unit
            local vy  = HRP.Velocity.Y
            HRP.Velocity = Vector3.new(dir.X * effSpeed, vy, dir.Z * effSpeed)
            task.wait()
        end
        if HRP and HRP.Parent then
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.CFrame   = CFrame.new(targetPos)
        end
        if _ctrls then pcall(function() _ctrls:Enable() end) end
    end

    _G._FH_WalkTo = function(targetPos, speed, arriveDist, timeout)
        return walkTo(hrp, targetPos, speed, arriveDist, timeout)
    end

    local plots = workspace:FindFirstChild("Plots")
    if not plots then _restoreAGs(); return end
    local myName = player.DisplayName
    local enemyPlots = {}
    for _, plot in ipairs(plots:GetChildren()) do
        local sign  = plot:FindFirstChild("PlotSign")
        local label = sign and sign:FindFirstChild("SurfaceGui")
            and sign.SurfaceGui:FindFirstChild("Frame")
            and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
        if label and label.Text ~= "Empty Base" then
            local owner = label.Text:gsub("'s Base$",""):gsub("'s base$",""):gsub("%s+$","")
            if owner ~= myName then table.insert(enemyPlots, plot) end
        end
    end

    local function getClosestPodium()
        if #enemyPlots == 0 then return nil end
        local best, bestDist = nil, math.huge
        for _, plot in ipairs(enemyPlots) do
            local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then continue end
            local plotPos = nil
            for _, part in ipairs(plot:GetDescendants()) do
                if part:IsA("BasePart") then plotPos = part.Position; break end
            end
            local plotIsBase1 = true
            if plotPos then
                local d1 = (plotPos - bases.b1.refVec).Magnitude
                local d2 = (plotPos - bases.b2.refVec).Magnitude
                plotIsBase1 = d1 < d2
            end
            for _, pname in ipairs({"1","10"}) do
                local podium = podiums:FindFirstChild(pname); if not podium then continue end
                local cm = podium:FindFirstChild("Claim") and podium.Claim:FindFirstChild("Main"); if not cm then continue end
                local d = (hrp.Position - cm.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    local spawn  = podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn")
                    local pa     = spawn and spawn:FindFirstChild("PromptAttachment")
                    local prompt = pa and pa:FindFirstChildWhichIsA("ProximityPrompt")
                    if prompt then
                        best = {
                            plot         = plot,
                            podiumName   = pname,
                            position     = cm.Position,
                            prompt       = prompt,
                            promptPos    = pa.WorldPosition,
                            distance     = d,
                            isEnemyBase1 = plotIsBase1,
                        }
                    end
                end
            end
        end
        return best
    end

    local carpet  = char:FindFirstChild("Flying Carpet") or (player.Backpack and player.Backpack:FindFirstChild("Flying Carpet"))
    local podium  = getClosestPodium()
    if not podium then _restoreAGs(); return end

    local finalPos
    do
        local dB1 = (podium.position - bases.b1.refVec).Magnitude
        local dB2 = (podium.position - bases.b2.refVec).Magnitude
        finalPos  = (dB1 < dB2) and bases.b1.finalPos or bases.b2.finalPos
    end

    if carpet then pcall(function() hum:EquipTool(carpet) end) end

    local netCtx = _FH_StartTrip({ plotName = podium.plot.Name, pod = tonumber(podium.podiumName) or podium.podiumName })
    SS._semiStealCtx = netCtx

    local function doTpSequence(HRP, fPos, pod)
        local isAtBase1
        do
            local dB1 = (pod.position - bases.b1.refVec).Magnitude
            local dB2 = (pod.position - bases.b2.refVec).Magnitude
            isAtBase1 = dB1 < dB2
        end

        local redPos   = isAtBase1 and Vector3.new(-337, -5, 100)         or Vector3.new(-335, -5, 20)
        local greenPos = isAtBase1 and Vector3.new(-347.12, -6.67, 81.64) or Vector3.new(-349.43, -6.78, 37.47)

        local approachWaypoints
        if not isAtBase1 then
            approachWaypoints = {
                Vector3.new(-351.49, -6.65, 113.72),
                Vector3.new(-352.54, -6.83,   6.66),
                Vector3.new(-334.80, -5.04,  18.90),
            }
        else
            approachWaypoints = {
                Vector3.new(-352.54, -6.83,   6.66),
                Vector3.new(-351.49, -6.65, 113.72),
                Vector3.new(-337,    -5,    103),
            }
        end

        doApproachPath = function(HRP_, _pod, _isAtBase1)
            if isWalkMode() then
                local startIndex = 1
                for i = #approachWaypoints, 1, -1 do
                    if canDirectTp(HRP_, approachWaypoints[i]) then startIndex = i; break end
                end
                for i = startIndex, #approachWaypoints do
                    walkTo(HRP_, approachWaypoints[i], 180)
                end
                return
            end
            if _pod and redPos and canDirectTp(HRP_, redPos) then
                HRP_.CFrame = CFrame.new(redPos)
            else
                tpThroughWaypoints(HRP_, approachWaypoints)
            end
        end

        if __isPrimeMethod() then
            local prompt = pod and pod.prompt
            if not prompt or not prompt.Parent then return end
            prompt.RequiresLineOfSight   = false
            prompt.MaxActivationDistance = math.huge
            equipCarpet()
            HRP.CFrame = isAtBase1 and CFrame.new(-343.08, -6.84, 93.20) or CFrame.new(-342.91, -6.81, 28.00)
            task.wait(0.25)
            HRP.CFrame = isAtBase1 and CFrame.new(-340.16, -7.29, 48.82) or CFrame.new(-340.16, -7.29, 72.40)
            task.wait(0.12)
            HRP.CFrame = isAtBase1 and CFrame.new(-341.26, -7.29, 66.95) or CFrame.new(-341.26, -7.29, 54.27)
            task.wait(0.12)
            HRP.CFrame = isAtBase1 and CFrame.new(-339.93, -7.29, 82.14) or CFrame.new(-339.63, -7.29, 39.33)
            task.wait(0.18)
            local ctx = __FH_v2.startStealHold(prompt, "Prime")
            HRP.CFrame = isAtBase1 and CFrame.new(-354.04, -7.21, 90.42) or CFrame.new(-354.04, -7.21, 28.00)
            task.wait(0.45)
            HRP.CFrame = isAtBase1 and CFrame.new(-334.60, -5.00, 101.30) or CFrame.new(-334.60, -5.00, 19.30)
            if ctx and ctx.holdBeganAt then
                while tick() - ctx.holdBeganAt < __MIN_HOLD_TIME_v2 do task.wait() end
            end
            drinkPotion()
            equipCarpet()
            HRP.CFrame = isAtBase1 and CFrame.new(-351.53, -7.29, 83.66) or CFrame.new(-350.62, -7.29, 35.91)
            if ctx then __FH_v2.finishStealHold(ctx) end
        else
            local ctx
            if pod and pod.prompt and pod.prompt.Parent then
                pod.prompt.RequiresLineOfSight   = false
                pod.prompt.MaxActivationDistance = math.huge
                ctx = __FH_v2.startStealHold(pod.prompt, "Walk")
            end

            if ctx then __FH_v2.waitForStealTime(ctx, 0.8) end

            doApproachPath(HRP, pod, isAtBase1)

            task.wait(0.25)
            drinkPotion()
            equipCarpet()

            if pod and pod.prompt and pod.prompt.Parent and ctx then
                if greenPos then
                    __FH_v2.waitForStealTime(ctx, 1.3)
                    HRP.CFrame = CFrame.new(greenPos)
                end
                __FH_v2.finishStealHold(ctx)
            end
        end

        local startTime = tick()
        while player:GetAttribute("Stealing") == nil do
            if tick() - startTime >= 1 then break end
            task.wait(0.1)
        end
    end

    task.spawn(function()
      local _ok, _err = pcall(function()
        doTpSequence(hrp, finalPos, podium)
        SS._semiStealCtx = nil
        task.wait(0.9)
      end)
      _restoreAGs()
      if not _ok then warn("[FH SemiSteal] error during steal sequence: ", _err) end
    end)
end
SS.SSDoSteal = function()
    SS.SSDoTeleport()
end

SS.SSExecute = function()
    if SS.debounce then return end
    SS.debounce = true

    _G._FH_LastV2UseTime = os.clock()
    task.spawn(function()
        SS.SSSetFFlags()
        SS.SSDoTeleport()
        task.wait(1.2)
        SS.debounce = false
    end)
end
SS.SSMakeBtn = function(labelText, fireFn)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, isMobile and 30 or 26)
    btn.BackgroundColor3 = SS.BTN
    btn.BorderSizePixel  = 0
    btn.Text             = labelText
    btn.TextSize         = isMobile and 12 or 13
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(245, 245, 245)
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.ClipsDescendants = false
    btn.ZIndex           = 20
    btn.Parent           = SS.SSContent
    Corner(btn, 8)
    Stroke(btn, Color3.fromRGB(45, 45, 45), 1)

    local _btnPad = Instance.new("UIPadding")
    _btnPad.PaddingLeft = UDim.new(0, 10)
    _btnPad.Parent = btn
    local kbLbl = Instance.new("TextLabel")
    kbLbl.Size                   = UDim2.new(0, 40, 0, 14)
    kbLbl.Position               = UDim2.new(1, -44, 0.5, -7)
    kbLbl.BackgroundTransparency = 1
    kbLbl.Text                   = ""
    kbLbl.TextSize               = 10
    kbLbl.Font                   = Enum.Font.GothamBold
    kbLbl.TextColor3             = T.Dim
    kbLbl.TextXAlignment         = Enum.TextXAlignment.Center
    kbLbl.ZIndex                 = 21
    kbLbl.Parent                 = btn
    local entry = { keyCode = nil }
    do
        local _ssKey  = "ss_btn_".. labelText:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
        local _saved  = Config and Config.keybinds and Config.keybinds[_ssKey]
        if type(_saved) == "string" then
            local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
            if _ok and _kc then
                entry.keyCode    = _kc
                kbLbl.Text       = "[" .. _saved .. "]"
                kbLbl.TextColor3 = T.Dim
            end
        end
    end
    btn.MouseEnter:Connect(function() Tween(btn, F, {BackgroundColor3 = SS.BTN_HOVER}) end)
    btn.MouseLeave:Connect(function() Tween(btn, F, {BackgroundColor3 = SS.BTN}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, F, {BackgroundColor3 = SS.BTN_HOVER})
        task.delay(0.12, function() Tween(btn, F, {BackgroundColor3 = SS.BTN}) end)
        fireFn()
    end)
    local ssKb2Debounce = false
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if ssKb2Debounce then return end
        ssKb2Debounce = true
        task.delay(0.2, function() ssKb2Debounce = false end)
        if keybindBindingTarget then
            local prev = keybindBindingTarget
            keybindBindingTarget = nil
            if prev.kbLbl == kbLbl then
                kbLbl.Text       = entry.keyCode and ("[".. entry.keyCode.Name .. "]") or ""
kbLbl.TextColor3 = T.Dim
                return
            else
                prev.kbLbl.Text       = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
            end
        end
        kbLbl.Text           = "(...)"
kbLbl.TextColor3     = T.White
        keybindBindingTarget = { entry = entry, kbLbl = kbLbl, mode = "assign"}
    end)
    table.insert(keybindEntries, { entry = entry, fire = fireFn, kbLbl = kbLbl })
    local ssKey = "ss_btn_".. labelText:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    configRegistry[ssKey] = {
        getState   = function() return false end,
        getKeyCode = function() return entry.keyCode end,
        setKeyCode = function(kc)
            entry.keyCode = kc
            if kc then
                kbLbl.Text       = "[".. kc.Name .. "]"
kbLbl.TextColor3 = T.Dim
                Config.keybinds[ssKey] = kc.Name
            else
                kbLbl.Text = ""
Config.keybinds[ssKey] = nil
            end
            pcall(FH_SaveConfig)
        end,
        doToggle = fireFn,
        kbLbl    = kbLbl,
        kbEntry  = entry,
    }
    return btn
end
SS.SSTeleportBtn = SS.SSMakeBtn("Teleport", function()
    SS.SSDoSteal()
end)
SS.SSActivateBtn = SS.SSMakeBtn("Activate", function()
    SS.SSSetFFlags()
    ShowToggleNotification("FFlags Applied!", true)
    task.spawn(function() doSelectedReset() end)
end)
do
    SS.SSHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            SS.dragging   = true
            SS.dragStart  = inp.Position
            SS.panelStart = SS.SSWin.Position
        end
    end)
    SS.SSHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            SS.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.ss_pos = { x = SS.SSWin.Position.X.Offset, y = SS.SSWin.Position.Y.Offset,
                                   xs = SS.SSWin.Position.X.Scale, ys = SS.SSWin.Position.Y.Scale }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if SS.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - SS.dragStart
            local newPos = UDim2.new(
                SS.panelStart.X.Scale, SS.panelStart.X.Offset + d.X,
                SS.panelStart.Y.Scale, SS.panelStart.Y.Offset + d.Y
            )
            SS.SSWin.Position         = newPos
            SS.SSBorderFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 2,
                newPos.Y.Scale, newPos.Y.Offset - 2
            )
        end
    end)
end
SS.SSMinBtn.MouseButton1Click:Connect(function()
    SS.minimized = not SS.minimized
    if SS.minimized then
        SS.SSWin.ClipsDescendants = false
        SS.SSHdrFill.Visible = false
        SS.SSHdrLine.Visible = false
        SS.SSContent.Visible = false
        Tween(SS.SSWin,         M, {Size = UDim2.new(0, SS.W, 0, 30)})
        Tween(SS.SSBorderFrame, M, {Size = UDim2.new(0, SS.W + 4, 0, 34)})
        SS.SSMinBtn.Text = "+"else
        SS.SSHdrFill.Visible = true
        SS.SSHdrLine.Visible = true
        Tween(SS.SSWin,         M, {Size = UDim2.new(0, SS.W, 0, SS.H)})
        Tween(SS.SSBorderFrame, M, {Size = UDim2.new(0, SS.W + 4, 0, SS.H + 4)})
        SS.SSMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            SS.SSContent.Visible = true
            SS.SSWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.ss_min = SS.minimized
        pcall(FH_SaveConfig)
    end
end)
SS.setSemiStealPanelVisible = function(vis)
    SS.SSWin.Visible         = vis
    SS.SSBorderFrame.Visible = vis
    if vis then
        local p = SS.SSWin.Position
        SS.SSBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if SS.minimized then
            SS.SSMinBtn.Text          = "+"
SS.SSContent.Visible      = false
            SS.SSHdrFill.Visible      = false
            SS.SSHdrLine.Visible      = false
            SS.SSWin.ClipsDescendants = false
            SS.SSWin.Size             = UDim2.new(0, SS.W, 0, 30)
            SS.SSBorderFrame.Size     = UDim2.new(0, SS.W + 4, 0, 34)
        else
            SS.SSMinBtn.Text          = "\226\136\146"
SS.SSContent.Visible      = true
            SS.SSHdrFill.Visible      = true
            SS.SSHdrLine.Visible      = true
            SS.SSWin.ClipsDescendants = true
            SS.SSWin.Size             = UDim2.new(0, SS.W, 0, SS.H)
            SS.SSBorderFrame.Size     = UDim2.new(0, SS.W + 4, 0, SS.H + 4)
        end
    end
end

do
    local function _ssApplySavedToggle(key)
        local savedT = (_FH_SavedConfig and _FH_SavedConfig.toggles)
                       or (Config and Config.toggles) or {}
        if savedT[key] ~= true then return end
        local reg = configRegistry and configRegistry[key]
        if not (reg and reg.setEnabled) then return end
        local wasRestoring = _G._FH_IsRestoring
        _G._FH_IsRestoring = true
        pcall(reg.setEnabled, true)
        _G._FH_IsRestoring = wasRestoring
        Config.toggles = Config.toggles or {}
        Config.toggles[key] = true
    end
    task.defer(function()
        _ssApplySavedToggle("ss_potion")
        _ssApplySavedToggle("ss_auto_tp_unlock")
        _ssApplySavedToggle("ss_auto_tp_on_allow")
    end)
end

local function _FH_InitQSModule()
    QS.W          = isMobile and 172 or 218
    QS.H          = isMobile and 228 or 262
    QS.minimized  = false
    QS.dragging   = false
    QS.dragStart  = nil
    QS.panelStart = nil
    QS.entry      = { keyCode = nil }

    do
        local s = (_FH_SavedConfig and _FH_SavedConfig.sliders) or {}
        QS.selectedAnimalName = s.qs_selected_animal_name
    end
    QS.selectedEntry = nil
    QS.lastEntries   = {}

    local PODIUM_MATCH_DISTANCE = 10

    local function qsParseMoney(text)
        text = string.lower(text or "")
        local num = tonumber(text:match("[%d%.]+")) or 0
        if text:find("k") then num = num * 1e3
        elseif text:find("m") then num = num * 1e6
        elseif text:find("b") then num = num * 1e9
        elseif text:find("t") then num = num * 1e12
        elseif text:find("qa") then num = num * 1e15
        end
        return num
    end

    local function qsReadDisplayAndGeneration(part)
        local displayName, generation
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                for _, label in ipairs(child:GetDescendants()) do
                    if label:IsA("TextLabel") then
                        if label.Name == "DisplayName" then
                            displayName = label.Text
                        elseif label.Name == "Generation" then
                            generation = label.Text
                        end
                    end
                end
            end
        end
        return displayName, generation
    end

    local function qsFindAllAnimals()
        local results = {}
        local step = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local displayName, generation = qsReadDisplayAndGeneration(obj)
                if displayName and displayName ~= "" and generation and generation ~= "" then
                    table.insert(results, {
                        part        = obj,
                        displayName = displayName,
                        generation  = generation,
                        value       = qsParseMoney(generation),
                        position    = obj.Position,
                    })
                end
            end
            step = step + 1
            if step % 800 == 0 then task.wait() end
        end
        return results
    end

    local function qsFindAllPlots()
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then return plotsFolder:GetChildren() end
        return {}
    end

    local function qsGetPodiumNumber(podium)
        local n = tonumber(podium.Name)
        if n then return n end
        local m = podium.Name:match("(%d+)")
        if m then return tonumber(m) end
        return nil
    end

    local function qsGetPodiumPosition(podium)
        if podium:IsA("BasePart") then return podium.Position end
        if podium:IsA("Model") and podium.PrimaryPart then return podium.PrimaryPart.Position end
        local part = podium:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
        if podium:IsA("Model") then
            local ok, cf = pcall(function() return podium:GetPivot().Position end)
            if ok then return cf end
        end
        return nil
    end

    local function qsFindPodiumsInPlot(plot)
        local results, seen = {}, {}
        for _, desc in ipairs(plot:GetDescendants()) do
            if (desc:IsA("Folder") or desc:IsA("Model")) and desc.Name:lower():find("podium")
                and not tonumber(desc.Name) then
                for _, child in ipairs(desc:GetChildren()) do
                    local num = qsGetPodiumNumber(child)
                    if num and not seen[child] then
                        seen[child] = true
                        local pos = qsGetPodiumPosition(child)
                        if pos then
                            table.insert(results, { podium = child, number = num, position = pos })
                        end
                    end
                end
            end
        end
        if #results == 0 then
            local numbered = {}
            for _, desc in ipairs(plot:GetDescendants()) do
                if (desc:IsA("Model") or desc:IsA("Folder")) and tonumber(desc.Name) then
                    local num = tonumber(desc.Name)
                    if num and num >= 1 and num <= 20 then
                        table.insert(numbered, { obj = desc, num = num })
                    end
                end
            end
            if #numbered >= 3 then
                for _, item in ipairs(numbered) do
                    if not seen[item.obj] then
                        seen[item.obj] = true
                        local pos = qsGetPodiumPosition(item.obj)
                        if pos then
                            table.insert(results, { podium = item.obj, number = item.num, position = pos })
                        end
                    end
                end
            end
        end
        return results
    end

    local function qsGetPlotOwnerName(plot)
        local plotSign = plot:FindFirstChild("PlotSign", true)
        if plotSign then
            for _, desc in ipairs(plotSign:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
                    local t  = desc.Text
                    local up = t:upper()
                    if up == "YOUR BASE" then return "YOU" end
                    if t:lower():find("empty") then return "Empty Base" end
                    local m = t:match("[Bb]ase [Oo]f%s+(.+)")
                    if m then return m end
                    if #t > 0 and #t < 30 then return t end
                end
            end
        end
        return plot.Name
    end

    local function qsComputePlotBounds(plot)
        local minX, maxX = math.huge, -math.huge
        local minZ, maxZ = math.huge, -math.huge
        local found = false
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:IsA("BasePart") then
                local pos = desc.Position
                if pos.X < minX then minX = pos.X end
                if pos.X > maxX then maxX = pos.X end
                if pos.Z < minZ then minZ = pos.Z end
                if pos.Z > maxZ then maxZ = pos.Z end
                found = true
            end
        end
        if not found then return nil end
        return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
    end

    local function qsAnimalsInPlot(animals, plot, bounds)
        local nearby, pad = {}, 6
        for _, a in ipairs(animals) do
            local inside = a.part:IsDescendantOf(plot)
            if not inside and bounds then
                local p = a.position
                inside = p.X >= bounds.minX - pad and p.X <= bounds.maxX + pad
                    and p.Z >= bounds.minZ - pad and p.Z <= bounds.maxZ + pad
            end
            if inside then table.insert(nearby, a) end
        end
        return nearby
    end

    local function qsMatchAnimalsToPodiums(podiums, animals)
        local candidates = {}
        for pi, p in ipairs(podiums) do
            for ai, animal in ipairs(animals) do
                local diff = animal.position - p.position
                local horizDist = math.sqrt(diff.X * diff.X + diff.Z * diff.Z)
                local yDist     = math.abs(diff.Y)
                if horizDist < PODIUM_MATCH_DISTANCE and yDist < 60 then
                    local score = math.sqrt(horizDist * horizDist + yDist * yDist * 0.15)
                    table.insert(candidates, { pi = pi, ai = ai, score = score })
                end
            end
        end
        table.sort(candidates, function(a, b) return a.score < b.score end)

        local podiumToAnimal, usedAnimals, usedPodiums = {}, {}, {}
        for _, c in ipairs(candidates) do
            if not usedPodiums[c.pi] and not usedAnimals[c.ai] then
                podiumToAnimal[c.pi] = c.ai
                usedPodiums[c.pi]    = true
                usedAnimals[c.ai]    = true
            end
        end

        local entries = {}
        for pi, p in ipairs(podiums) do
            local matched = podiumToAnimal[pi]
            if matched then
                local a = animals[matched]
                table.insert(entries, {
                    number          = p.number,
                    podium          = p.podium,
                    podiumPosition  = p.position,
                    name            = a.displayName,
                    generation      = a.generation,
                    value           = a.value,
                    animalPart      = a.part,
                    animalPosition  = a.position,
                })
            end
        end
        return entries
    end

    function QS.scan()
        local animals = qsFindAllAnimals()
        local plots   = qsFindAllPlots()
        local entries = {}
        local idx = 0
        for _, plot in ipairs(plots) do
            local mine = false
            pcall(function() mine = _FH_AG_IsMyPlot(plot) end)
            if not mine then
                local owner       = qsGetPlotOwnerName(plot)
                local podiums     = qsFindPodiumsInPlot(plot)
                local bounds      = qsComputePlotBounds(plot)
                local plotAnimals = qsAnimalsInPlot(animals, plot, bounds)
                local matched     = qsMatchAnimalsToPodiums(podiums, plotAnimals)
                for _, e in ipairs(matched) do
                    if (tonumber(e.number) or 0) >= 11 then
                        e.plot     = plot
                        e.plotName = owner
                        e.uid      = plot.Name .. "_" .. tostring(e.number)
                        table.insert(entries, e)
                    end
                end
            end
            idx = idx + 1
            if idx % 2 == 0 then task.wait() end
        end
        table.sort(entries, function(a, b)
            return (a.value or 0) > (b.value or 0)
        end)
        local pset = _G._FH_PRIORITY_STEAL
        if pset and next(pset) then
            local filtered = {}
            for _, e in ipairs(entries) do
                if e.name and pset[e.name] then table.insert(filtered, e) end
            end
            entries = filtered
        end
        return entries
    end

    local function _qsFindPromptForEntry(entry)
        if not (entry and entry.plot and entry.plot.Parent) then return nil end
        local pods   = entry.plot:FindFirstChild("AnimalPodiums")
        local podium = pods and pods:FindFirstChild(tostring(entry.number))
        local base   = podium and podium:FindFirstChild("Base")
        local spawn  = base and base:FindFirstChild("Spawn")
        local att    = spawn and spawn:FindFirstChild("PromptAttachment")
        return att and att:FindFirstChildOfClass("ProximityPrompt") or nil
    end

    local _qsCBCache = {}
    local function _qsBuildCallbacks(prompt)
        if _qsCBCache[prompt] then return _qsCBCache[prompt] end
        local data = { holdCallbacks = {}, triggerCallbacks = {} }
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table" then
            for _, c in ipairs(conns1) do
                if type(c.Function) == "function" then
                    table.insert(data.holdCallbacks, c.Function)
                end
            end
        end
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table" then
            for _, c in ipairs(conns2) do
                if type(c.Function) == "function" then
                    table.insert(data.triggerCallbacks, c.Function)
                end
            end
        end
        if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
            _qsCBCache[prompt] = data
        end
        return data
    end

    local _qsEquipCarpet, _qsWalkToAnimal, _qsEquipFlashTool
    local function _qsInitHelpers()
        _qsEquipCarpet = function()
            local lp        = Players.LocalPlayer
            local character = lp.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local backpack = lp:FindFirstChildOfClass("Backpack")
            if not (humanoid and backpack) then return end
            local carpet = backpack:FindFirstChild("Flying Carpet") or character:FindFirstChild("Flying Carpet")
            if not carpet then
                for _, t in ipairs(backpack:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find("carpet") then
                        carpet = t
                        break
                    end
                end
            end
            if carpet and carpet.Parent == backpack then
                pcall(function() humanoid:EquipTool(carpet) end)
            end
        end

        _qsWalkToAnimal = function(entry)
            local lp        = Players.LocalPlayer
            local character = lp.Character
            local hrp       = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            _qsEquipCarpet()
            local podPos = entry.podiumPosition or entry.animalPosition
            if not podPos then return end
            local diff = hrp.Position - podPos
            local horiz = Vector3.new(diff.X, 0, diff.Z)
            local dirAway
            if horiz.Magnitude < 0.5 then
                dirAway = Vector3.new(0, 0, 1)
            else
                dirAway = horiz.Unit
            end
            local walkTarget = podPos + dirAway * 5 + Vector3.new(0, -4, 0)
            local speed      = 240
            local arriveDist = 4
            local timeout    = 5
            local _ctrls
            pcall(function()
                _ctrls = require(lp.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
            end)
            if _ctrls then pcall(function() _ctrls:Disable() end) end
            local start = tick()
            while hrp and hrp.Parent do
                local d   = walkTarget - hrp.Position
                local mag = d.Magnitude
                if mag < arriveDist then break end
                if tick() - start > timeout then break end
                local effSpeed = speed
                if mag < 30 then effSpeed = math.max(80, speed * (mag / 30)) end
                local dir = d.Unit
                hrp.Velocity = Vector3.new(dir.X * effSpeed, dir.Y * effSpeed, dir.Z * effSpeed)
                task.wait()
            end
            if hrp and hrp.Parent then
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
            if _ctrls then pcall(function() _ctrls:Enable() end) end
        end

        _qsEquipFlashTool = function()
            local lp   = Players.LocalPlayer
            local char = lp.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local bp   = lp:FindFirstChildOfClass("Backpack")
            if not (hum and bp) then return nil end
            local function findFlash(parent)
                for _, t in ipairs(parent:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find("flash") then return t end
                end
                return nil
            end
            local tool = findFlash(char) or findFlash(bp)
            if tool and tool.Parent == bp then
                pcall(function() hum:EquipTool(tool) end)
            end
            return tool
        end
    end
    _qsInitHelpers()

    local _qsStartCameraLock, _qsStopCameraLock
    local function _qsInitCamLock()
        local active   = false
        local target   = nil
        local name     = "FH_QS_CamLock"
        local priorTy
        local bound    = false

        local function step()
            if not active then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            if not target then return end
            local lp   = Players.LocalPlayer
            local char = lp.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local headPos = hrp.Position + Vector3.new(0, 1.5, 0)
            local toTarget = target - headPos
            local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
            local backDir
            if horiz.Magnitude < 0.5 then
                backDir = Vector3.new(0, 0, -1)
            else
                backDir = -horiz.Unit
            end
            local camPos = headPos + backDir * 2.5 + Vector3.new(0, 0.5, 0)
            cam.CFrame = CFrame.new(camPos, target)
        end

        _qsStartCameraLock = function(targetPos)
            if not targetPos then return end
            target = targetPos
            if active then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            active  = true
            priorTy = cam.CameraType
            pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
            if not bound then
                local ok = pcall(function()
                    RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, step)
                end)
                bound = ok and true or false
            end
            step()
        end

        _qsStopCameraLock = function()
            if not active then target = nil; return end
            active = false
            target = nil
            if bound then
                pcall(function() RunService:UnbindFromRenderStep(name) end)
                bound = false
            end
            local cam = workspace.CurrentCamera
            if cam then
                pcall(function() cam.CameraType = priorTy or Enum.CameraType.Custom end)
            end
            priorTy = nil
        end
    end
    _qsInitCamLock()

    local qsExecuting = false

    function QS.execute()
        if qsExecuting then return end
        if not QS.selectedEntry then
            pcall(ShowToggleNotification, "Quick Steal: select an animal first", false)
            return
        end
        local entry = QS.selectedEntry
        local plot  = entry.plot
        if not plot or not plot.Parent then
            pcall(ShowToggleNotification, "Quick Steal: target plot missing", false)
            return
        end
        local prompt = _qsFindPromptForEntry(entry)
        if not prompt then
            pcall(ShowToggleNotification, "Quick Steal: prompt not found", false)
            return
        end

        qsExecuting = true
        task.spawn(function()
            local data = _qsBuildCallbacks(prompt)
            if not data or (#data.holdCallbacks == 0 and #data.triggerCallbacks == 0) then
                pcall(ShowToggleNotification, "Quick Steal: prompt has no callbacks", false)
                qsExecuting = false
                return
            end

            local holdDuration = prompt.HoldDuration
            if not holdDuration or holdDuration <= 0 then holdDuration = 1.3 end

            local agNearReg = configRegistry["Auto Grab Nearest"]
            local agBestReg = configRegistry["Auto Grab Best"]
            local wasAgNear = agNearReg and agNearReg.getState() or false
            local wasAgBest = agBestReg and agBestReg.getState() or false
            if wasAgNear and agNearReg.setEnabled then pcall(agNearReg.setEnabled, false) end
            if wasAgBest and agBestReg.setEnabled then pcall(agBestReg.setEnabled, false) end

            _G._FH_LastV2UseTime = os.clock()

            local startTime = tick()

            for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end

            _qsWalkToAnimal(entry)

            local podiumAimPos
            do
                local pods   = entry.plot and entry.plot:FindFirstChild("AnimalPodiums")
                local podium = pods and pods:FindFirstChild(tostring(entry.number))
                local base   = podium and podium:FindFirstChild("Base")
                local spawn  = base and base:FindFirstChild("Spawn")
                local att    = spawn and spawn:FindFirstChild("PromptAttachment")
                if att then podiumAimPos = att.WorldPosition end
            end
            podiumAimPos = podiumAimPos or entry.podiumPosition or entry.animalPosition

            local flashTool = _qsEquipFlashTool()
            _qsStartCameraLock(podiumAimPos)

            local QS_CAM_SETTLE = 0.10
            local camSettleAt   = tick() + QS_CAM_SETTLE
            while tick() < camSettleAt do RunService.Heartbeat:Wait() end

            local flashFireAt = holdDuration * 0.40
            while true do
                local elapsed = tick() - startTime
                if elapsed >= flashFireAt then break end
                local remain = flashFireAt - elapsed
                if remain > 0.030 then
                    task.wait(remain - 0.020)
                else
                    RunService.Heartbeat:Wait()
                end
            end

            if flashTool and flashTool.Parent then
                pcall(function() flashTool:Activate() end)
            end

            if V3 and V3.potionOn then
                pcall(_activateGiantPotion)
            end

            while true do
                local elapsed = tick() - startTime
                if elapsed >= holdDuration then break end
                local remain = holdDuration - elapsed
                if remain > 0.020 then
                    task.wait(remain - 0.010)
                else
                    RunService.Heartbeat:Wait()
                end
            end
            for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end

            _qsStopCameraLock()

            pcall(ShowToggleNotification, "Quick Steal: " .. tostring(entry.name or "?"), true)

            task.wait(0.4)
            if wasAgNear and agNearReg and agNearReg.setEnabled then pcall(agNearReg.setEnabled, true) end
            if wasAgBest and agBestReg and agBestReg.setEnabled then pcall(agBestReg.setEnabled, true) end
            qsExecuting = false
        end)
    end

    _G._FH_QS_WalkToAnimal     = _qsWalkToAnimal
    _G._FH_QS_BuildCallbacks   = _qsBuildCallbacks
    _G._FH_QS_CBCache          = _qsCBCache
end
_FH_InitQSModule(); task.wait()
local function _FH_InitQSPanel()
    local _qsBuildCallbacks  = _G._FH_QS_BuildCallbacks
    local _qsCBCache         = _G._FH_QS_CBCache

    QS.QSBorderFrame = Instance.new("Frame")
    QS.QSBorderFrame.Name                   = "QuickStealGradBorder"
    QS.QSBorderFrame.Size                   = UDim2.new(0, QS.W + 4, 0, QS.H + 4)
    QS.QSBorderFrame.Position               = UDim2.new(0.5, -(QS.W + 4) / 2, 0, 138)
    QS.QSBorderFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    QS.QSBorderFrame.BackgroundTransparency = 1
    QS.QSBorderFrame.BorderSizePixel        = 0
    QS.QSBorderFrame.ZIndex                 = 18
    QS.QSBorderFrame.Visible                = false
    QS.QSBorderFrame.Parent                 = GUI
    Corner(QS.QSBorderFrame, 12)
    _FH_AddThemeStrokeToFrame(QS.QSBorderFrame, 1.5)

    QS.QSWin = Instance.new("Frame")
    QS.QSWin.Name                   = "QuickStealPanel"
    QS.QSWin.Size                   = UDim2.new(0, QS.W, 0, QS.H)
    QS.QSWin.Position               = UDim2.new(0.5, -QS.W / 2, 0, 140)
    QS.QSWin.BackgroundColor3       = T.BG
    QS.QSWin.BackgroundTransparency = 0.25
    QS.QSWin.BorderSizePixel        = 0
    QS.QSWin.ZIndex                 = 19
    QS.QSWin.Visible                = false
    QS.QSWin.ClipsDescendants       = true
    QS.QSWin.Parent                 = GUI
    Corner(QS.QSWin, 10)

    QS.QSHdr = Instance.new("Frame")
    QS.QSHdr.Size                   = UDim2.new(1, 0, 0, 30)
    QS.QSHdr.BackgroundColor3       = T.Header
    QS.QSHdr.BackgroundTransparency = 0.2
    QS.QSHdr.BorderSizePixel        = 0
    QS.QSHdr.ZIndex                 = 20
    QS.QSHdr.Active                 = true
    QS.QSHdr.Parent                 = QS.QSWin
    Corner(QS.QSHdr, 10)

    QS.QSHdrFill = Instance.new("Frame")
    QS.QSHdrFill.Size                   = UDim2.new(1, 0, 0, 7)
    QS.QSHdrFill.Position               = UDim2.new(0, 0, 1, -7)
    QS.QSHdrFill.BackgroundColor3       = T.Header
    QS.QSHdrFill.BackgroundTransparency = 0.2
    QS.QSHdrFill.BorderSizePixel        = 0
    QS.QSHdrFill.ZIndex                 = 20
    QS.QSHdrFill.Parent                 = QS.QSHdr

    QS.QSHdrLine = Instance.new("Frame")
    QS.QSHdrLine.Size             = UDim2.new(1, 0, 0, 1)
    QS.QSHdrLine.Position         = UDim2.new(0, 0, 1, -1)
    QS.QSHdrLine.BackgroundColor3 = T.Border
    QS.QSHdrLine.BorderSizePixel  = 0
    QS.QSHdrLine.ZIndex           = 21
    QS.QSHdrLine.Parent           = QS.QSHdr

    QS.QSTitle = Label(QS.QSHdr, "Quick Steal", 13, T.White, Enum.Font.GothamBold)
    QS.QSTitle.Size           = UDim2.new(1, -40, 1, 0)
    QS.QSTitle.Position       = UDim2.new(0, 12, 0, 0)
    QS.QSTitle.TextYAlignment = Enum.TextYAlignment.Center
    QS.QSTitle.ZIndex         = 22

    QS.QSMinBtn = Instance.new("TextButton")
    QS.QSMinBtn.Size             = UDim2.new(0, 22, 0, 22)
    QS.QSMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
    QS.QSMinBtn.BackgroundColor3 = T.Card
    QS.QSMinBtn.BorderSizePixel  = 0
    QS.QSMinBtn.Text             = "\226\136\146"
    QS.QSMinBtn.TextSize         = 14
    QS.QSMinBtn.Font             = Enum.Font.GothamBold
    QS.QSMinBtn.TextColor3       = T.White
    QS.QSMinBtn.ZIndex           = 23
    QS.QSMinBtn.Parent           = QS.QSHdr
    Corner(QS.QSMinBtn, 6)
    Stroke(QS.QSMinBtn, T.Border, 1)

    QS.QSContent = Instance.new("Frame")
    QS.QSContent.Size                   = UDim2.new(1, 0, 1, -30)
    QS.QSContent.Position               = UDim2.new(0, 0, 0, 30)
    QS.QSContent.BackgroundTransparency = 1
    QS.QSContent.ZIndex                 = 19
    QS.QSContent.Parent                 = QS.QSWin
    Padding(QS.QSContent, 8, 8, 8, 8)

    local controlsRow = Instance.new("Frame")
    controlsRow.Size                   = UDim2.new(1, 0, 0, isMobile and 26 or 30)
    controlsRow.BackgroundTransparency = 1
    controlsRow.ZIndex                 = 20
    controlsRow.Parent                 = QS.QSContent

    QS.StealBtn = Instance.new("TextButton")
    QS.StealBtn.Size             = UDim2.new(1, 0, 1, 0)
    QS.StealBtn.Position         = UDim2.new(0, 0, 0, 0)
    QS.StealBtn.BackgroundColor3 = T.Card
    QS.StealBtn.BorderSizePixel  = 0
    QS.StealBtn.Text             = "Steal Selected"
    QS.StealBtn.TextSize         = isMobile and 11 or 12
    QS.StealBtn.Font             = Enum.Font.GothamBold
    QS.StealBtn.TextColor3       = T.White
    QS.StealBtn.AutoButtonColor  = false
    QS.StealBtn.ZIndex           = 21
    QS.StealBtn.Parent           = controlsRow
    Corner(QS.StealBtn, 6)
    local _qsStealStroke = Stroke(QS.StealBtn, Color3.fromRGB(255, 255, 255), 1)
    _FH_AddThemeStroke(_qsStealStroke)

    QS.QSKbLbl = Instance.new("TextLabel")
    QS.QSKbLbl.Size                   = UDim2.new(0, 48, 1, -8)
    QS.QSKbLbl.Position               = UDim2.new(1, -52, 0, 4)
    QS.QSKbLbl.BackgroundTransparency = 1
    QS.QSKbLbl.Text                   = ""
    QS.QSKbLbl.TextSize               = isMobile and 9 or 10
    QS.QSKbLbl.Font                   = Enum.Font.GothamBold
    QS.QSKbLbl.TextColor3             = T.Dim
    QS.QSKbLbl.TextXAlignment         = Enum.TextXAlignment.Right
    QS.QSKbLbl.TextYAlignment         = Enum.TextYAlignment.Center
    QS.QSKbLbl.ZIndex                 = 22
    QS.QSKbLbl.Parent                 = QS.StealBtn

    do
        local saved = Config and Config.keybinds and Config.keybinds["qs_steal_selected"]
        if type(saved) == "string" then
            local ok, kc = pcall(function() return Enum.KeyCode[saved] end)
            if ok and kc then
                QS.entry.keyCode      = kc
                QS.QSKbLbl.Text       = "[" .. saved .. "]"
                QS.QSKbLbl.TextColor3 = T.Dim
            end
        end
    end

    QS.QSStatus = Label(QS.QSContent, "Idle", isMobile and 9 or 10, T.Dim, Enum.Font.GothamMedium)
    QS.QSStatus.Size         = UDim2.new(1, 0, 0, 14)
    QS.QSStatus.Position     = UDim2.new(0, 0, 0, isMobile and 30 or 34)
    QS.QSStatus.TextTruncate = Enum.TextTruncate.AtEnd
    QS.QSStatus.ZIndex       = 20

    local listTop      = isMobile and 48 or 52
    QS.QSScroll = Instance.new("ScrollingFrame")
    QS.QSScroll.Size                   = UDim2.new(1, 0, 1, -(listTop + 6))
    QS.QSScroll.Position               = UDim2.new(0, 0, 0, listTop)
    QS.QSScroll.BackgroundColor3       = Color3.fromRGB(14, 14, 18)
    QS.QSScroll.BackgroundTransparency = 0.2
    QS.QSScroll.BorderSizePixel        = 0
    QS.QSScroll.ScrollBarThickness     = 3
    QS.QSScroll.ScrollBarImageColor3   = T.Border
    QS.QSScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    QS.QSScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    QS.QSScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
    QS.QSScroll.ZIndex                 = 19
    QS.QSScroll.Parent                 = QS.QSContent
    Corner(QS.QSScroll, 6)

    local qsListLayout = Instance.new("UIListLayout")
    qsListLayout.Padding             = UDim.new(0, 4)
    qsListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    qsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    qsListLayout.Parent              = QS.QSScroll
    Padding(QS.QSScroll, 5, 5, 4, 4)

    local rowEntries = {}

    local function _qsSelectByEntry(entry)
        QS.selectedEntry      = entry
        QS.selectedAnimalName = entry and entry.name or nil
        Config.sliders = Config.sliders or {}
        Config.sliders.qs_selected_animal_name = QS.selectedAnimalName
        pcall(FH_SaveConfig)
        for _, r in ipairs(rowEntries) do r.applyVisual(r.entry == entry) end
        if entry then
            QS.QSStatus.Text       = string.format("Selected: %s · podium #%s", tostring(entry.name), tostring(entry.number))
            QS.QSStatus.TextColor3 = Color3.fromRGB(120, 220, 130)
        else
            QS.QSStatus.Text       = "No selection"
            QS.QSStatus.TextColor3 = T.Dim
        end
    end

    local function _qsGetAnimalModel(data)
        if data and data.name then
            local ok, v = pcall(function()
                local rs       = game:GetService("ReplicatedStorage")
                local models   = rs:FindFirstChild("Models")
                local animals  = models and models:FindFirstChild("Animals")
                return animals and animals:FindFirstChild(data.name) or nil
            end)
            if ok and v then return v end
        end
        if data and data.animalPart and data.animalPart.Parent then
            local m = data.animalPart:FindFirstAncestorOfClass("Model")
            if m then return m end
        end
        return nil
    end

    local function _qsBuildAnimalViewport(vp, data)
        local model = _qsGetAnimalModel(data)
        if not model then return end
        local wm = Instance.new("WorldModel")
        wm.Parent = vp
        local cam = Instance.new("Camera")
        cam.Parent = vp
        vp.CurrentCamera = cam
        task.spawn(function()
            local ok, clone = pcall(function() return model:Clone() end)
            if not ok or not clone then return end
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored   = true
                    d.CanCollide = false
                elseif d:IsA("ParticleEmitter") or d:IsA("Trail")
                    or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                    pcall(function() d.Enabled = false end)
                end
            end
            clone.Parent = wm
            local cf, size = clone:GetBoundingBox()
            local maxDim = math.max(size.X, size.Y, size.Z)
            if maxDim <= 0 then return end
            local dist = maxDim * 1.25
            cam.FieldOfView = 55
            cam.CFrame = CFrame.new(
                cf.Position + Vector3.new(dist * 0.40, maxDim * 0.25, dist),
                cf.Position
            )

            if not _G._FH_QSViewportSpin then
                _G._FH_QSViewportSpin = { clones = {}, _acc = 0 }
                _G._FH_QSViewportSpin.conn = RunService.Heartbeat:Connect(function(dt)
                    local list = _G._FH_QSViewportSpin.clones
                    if #list == 0 then return end
                    _G._FH_QSViewportSpin._acc = _G._FH_QSViewportSpin._acc + dt
                    if _G._FH_QSViewportSpin._acc < 1/15 then return end
                    local acc = _G._FH_QSViewportSpin._acc
                    _G._FH_QSViewportSpin._acc = 0
                    local n, w = #list, 0
                    local angle = CFrame.Angles(0, acc * 0.9, 0)
                    for r = 1, n do
                        local entry = list[r]
                        local c, v = entry[1], entry[2]
                        if c.Parent and v.Parent then
                            w = w + 1
                            list[w] = entry
                            pcall(function() c:PivotTo(c:GetPivot() * angle) end)
                        end
                    end
                    for i = n, w + 1, -1 do list[i] = nil end
                end)
            end
            table.insert(_G._FH_QSViewportSpin.clones, { clone, vp })
        end)
    end

    local function _qsRenderList(entries)
        for _, child in ipairs(QS.QSScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        rowEntries = {}

        local filtered = {}
        for _, e in ipairs(entries) do
            if (tonumber(e.number) or 0) >= 11 then
                table.insert(filtered, e)
            end
        end

        local rowH      = isMobile and 40 or 46
        local vpSize    = isMobile and 32 or 38
        local textLeft  = vpSize + 8
        local numTagW   = isMobile and 22 or 26

        local newlySelected = nil
        for i, data in ipairs(filtered) do
            local row = Instance.new("Frame")
            row.Size                   = UDim2.new(1, -4, 0, rowH)
            row.BackgroundColor3       = T.Card
            row.BackgroundTransparency = 0.15
            row.BorderSizePixel        = 0
            row.LayoutOrder            = i
            row.ZIndex                 = 20
            row.Parent                 = QS.QSScroll
            Corner(row, 6)
            local rs = Stroke(row, T.Border, 1)

            local vp = Instance.new("ViewportFrame")
            vp.Size                   = UDim2.new(0, vpSize, 0, vpSize)
            vp.Position               = UDim2.new(0, 4, 0.5, -vpSize / 2)
            vp.BackgroundColor3       = Color3.fromRGB(14, 14, 20)
            vp.BackgroundTransparency = 0.1
            vp.BorderSizePixel        = 0
            vp.LightDirection         = Vector3.new(-1, -2, -1)
            vp.LightColor             = Color3.fromRGB(220, 220, 255)
            vp.Ambient                = Color3.fromRGB(180, 180, 180)
            vp.ZIndex                 = 21
            vp.Parent                 = row
            Corner(vp, 5)
            local vs = Stroke(vp, T.Border, 1)
            _FH_AddThemeStroke(vs)
            _qsBuildAnimalViewport(vp, data)

            local numLbl = Instance.new("TextLabel")
            numLbl.Size                   = UDim2.new(0, numTagW, 0, isMobile and 11 or 12)
            numLbl.Position               = UDim2.new(1, -(numTagW + 4), 0, 3)
            numLbl.BackgroundTransparency = 1
            numLbl.Text                   = "#" .. tostring(data.number)
            numLbl.TextSize               = isMobile and 9 or 10
            numLbl.Font                   = Enum.Font.GothamBold
            numLbl.TextColor3             = T.Dim
            numLbl.TextXAlignment         = Enum.TextXAlignment.Right
            numLbl.ZIndex                 = 21
            numLbl.Parent                 = row

            local nameLbl = Label(row, tostring(data.name or ""), isMobile and 10 or 11, T.White, Enum.Font.GothamBold)
            nameLbl.Size         = UDim2.new(1, -(textLeft + numTagW + 6), 0, isMobile and 13 or 14)
            nameLbl.Position     = UDim2.new(0, textLeft, 0, 3)
            nameLbl.ZIndex       = 21
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local parts = {}
            if data.generation then table.insert(parts, data.generation) end
            if data.plotName  then table.insert(parts, "@" .. data.plotName) end
            local infoLbl = Label(row, table.concat(parts, "  ·  "),
                isMobile and 8 or 9, Color3.fromRGB(255, 215, 85), Enum.Font.Gotham)
            infoLbl.Size         = UDim2.new(1, -(textLeft + 4), 0, isMobile and 11 or 12)
            infoLbl.Position     = UDim2.new(0, textLeft, 1, isMobile and -13 or -15)
            infoLbl.ZIndex       = 21
            infoLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local hit = Instance.new("TextButton")
            hit.Size                   = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text                   = ""
            hit.AutoButtonColor        = false
            hit.ZIndex                 = 25
            hit.Parent                 = row

            local applyVisual = function(selected)
                if selected then
                    local accent = _G._FH_AccentA or T.TrackOn
                    Tween(row, F, { BackgroundColor3 = T.CardHover })
                    rs.Color     = accent
                    rs.Thickness = 2
                else
                    Tween(row, F, { BackgroundColor3 = T.Card })
                    rs.Color     = T.Border
                    rs.Thickness = 1
                end
            end

            hit.MouseEnter:Connect(function()
                if QS.selectedEntry ~= data then
                    Tween(row, F, { BackgroundColor3 = T.CardHover })
                end
            end)
            hit.MouseLeave:Connect(function()
                if QS.selectedEntry ~= data then
                    Tween(row, F, { BackgroundColor3 = T.Card })
                end
            end)

            local _rowTouchStart
            hit.MouseButton1Click:Connect(function() _qsSelectByEntry(data) end)
            hit.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch then
                    _rowTouchStart = inp.Position
                end
            end)
            hit.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch and _rowTouchStart then
                    local mag = (inp.Position - _rowTouchStart).Magnitude
                    _rowTouchStart = nil
                    if mag < 20 then _qsSelectByEntry(data) end
                end
            end)

            table.insert(rowEntries, { entry = data, row = row, applyVisual = applyVisual })

            if QS.selectedAnimalName and data.name == QS.selectedAnimalName and not newlySelected then
                newlySelected = data
            end
        end

        if newlySelected then
            _qsSelectByEntry(newlySelected)
        else
            if QS.selectedEntry then
                QS.selectedEntry = nil
                for _, r in ipairs(rowEntries) do r.applyVisual(false) end
            end
            QS.QSStatus.Text       = "0 animals selected"
            QS.QSStatus.TextColor3 = T.Dim
        end
    end

    function QS.refresh()

        if not QS.selectedEntry then
            QS.QSStatus.Text       = "0 animals selected"
            QS.QSStatus.TextColor3 = T.Dim
        end
        task.spawn(function()
            local ok, entries = pcall(QS.scan)
            if not ok or type(entries) ~= "table" then return end
            QS.lastEntries = entries
            _qsRenderList(entries)
        end)
    end

    task.spawn(function()
        while true do
            task.wait(2.5)
            if QS.QSWin and QS.QSWin.Parent and QS.QSWin.Visible and not QS.minimized and not qsExecuting then
                pcall(QS.refresh)
            end
        end
    end)

    do
        local _touchStart
        local _qsKb2Debounce = false
        local function fire()
            Tween(QS.StealBtn, F, { BackgroundColor3 = T.CardHover })
            task.delay(0.12, function() Tween(QS.StealBtn, F, { BackgroundColor3 = T.Card }) end)
            QS.execute()
        end
        QS.StealBtn.MouseButton1Click:Connect(fire)
        QS.StealBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch then
                _touchStart = inp.Position
            elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                if _qsKb2Debounce then return end
                _qsKb2Debounce = true
                task.delay(0.2, function() _qsKb2Debounce = false end)
                if keybindBindingTarget then
                    local prev = keybindBindingTarget
                    keybindBindingTarget = nil
                    if prev.kbLbl == QS.QSKbLbl then
                        QS.QSKbLbl.Text       = QS.entry.keyCode and ("[" .. QS.entry.keyCode.Name .. "]") or ""
                        QS.QSKbLbl.TextColor3 = T.Dim
                        return
                    else
                        prev.kbLbl.Text       = prev.entry.keyCode and ("[" .. prev.entry.keyCode.Name .. "]") or ""
                        prev.kbLbl.TextColor3 = T.Dim
                    end
                end
                QS.QSKbLbl.Text       = "(...)"
                QS.QSKbLbl.TextColor3 = T.White
                keybindBindingTarget  = { entry = QS.entry, kbLbl = QS.QSKbLbl, mode = "assign" }
            end
        end)
        QS.StealBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _touchStart then
                local mag = (inp.Position - _touchStart).Magnitude
                _touchStart = nil
                if mag < 20 then fire() end
            end
        end)
        QS.StealBtn.MouseEnter:Connect(function() Tween(QS.StealBtn, F, { BackgroundColor3 = T.CardHover }) end)
        QS.StealBtn.MouseLeave:Connect(function() Tween(QS.StealBtn, F, { BackgroundColor3 = T.Card }) end)
        table.insert(keybindEntries, { entry = QS.entry, fire = function() QS.execute() end, kbLbl = QS.QSKbLbl })
    end

    configRegistry["qs_steal_selected"] = {
        getState   = function() return false end,
        getKeyCode = function() return QS.entry.keyCode end,
        setKeyCode = function(kc)
            QS.entry.keyCode = kc
            if kc then
                QS.QSKbLbl.Text       = "[" .. kc.Name .. "]"
                QS.QSKbLbl.TextColor3 = T.Dim
                Config.keybinds["qs_steal_selected"] = kc.Name
            else
                QS.QSKbLbl.Text = ""
                Config.keybinds["qs_steal_selected"] = nil
            end
            pcall(FH_SaveConfig)
        end,
        doToggle = function() QS.execute() end,
        kbLbl    = QS.QSKbLbl,
        kbEntry  = QS.entry,
    }

    QS.QSHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            QS.dragging   = true
            QS.dragStart  = inp.Position
            QS.panelStart = QS.QSWin.Position
        end
    end)
    QS.QSHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            QS.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.qs_pos = {
                x  = QS.QSWin.Position.X.Offset, y  = QS.QSWin.Position.Y.Offset,
                xs = QS.QSWin.Position.X.Scale,  ys = QS.QSWin.Position.Y.Scale,
            }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if QS.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                         or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - QS.dragStart
            local newPos = UDim2.new(
                QS.panelStart.X.Scale, QS.panelStart.X.Offset + d.X,
                QS.panelStart.Y.Scale, QS.panelStart.Y.Offset + d.Y
            )
            QS.QSWin.Position         = newPos
            QS.QSBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
        end
    end)

    QS.QSMinBtn.MouseButton1Click:Connect(function()
        QS.minimized = not QS.minimized
        if QS.minimized then
            QS.QSWin.ClipsDescendants = false
            QS.QSHdrFill.Visible      = false
            QS.QSHdrLine.Visible      = false
            QS.QSContent.Visible      = false
            Tween(QS.QSWin,         M, { Size = UDim2.new(0, QS.W, 0, 30) })
            Tween(QS.QSBorderFrame, M, { Size = UDim2.new(0, QS.W + 4, 0, 34) })
            QS.QSMinBtn.Text = "+"
        else
            QS.QSHdrFill.Visible = true
            QS.QSHdrLine.Visible = true
            Tween(QS.QSWin,         M, { Size = UDim2.new(0, QS.W, 0, QS.H) })
            Tween(QS.QSBorderFrame, M, { Size = UDim2.new(0, QS.W + 4, 0, QS.H + 4) })
            QS.QSMinBtn.Text = "\226\136\146"
            task.delay(M.Time, function()
                QS.QSContent.Visible      = true
                QS.QSWin.ClipsDescendants = true
            end)
        end
        if isMobile then
            Config.mini = Config.mini or {}
            Config.mini.qs_min = QS.minimized
            pcall(FH_SaveConfig)
        end
    end)

    function QS.setQuickStealVisible(vis)
        QS.QSWin.Visible         = vis
        QS.QSBorderFrame.Visible = vis
        if vis then
            local p = QS.QSWin.Position
            QS.QSBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
            if QS.minimized then
                QS.QSMinBtn.Text          = "+"
                QS.QSContent.Visible      = false
                QS.QSHdrFill.Visible      = false
                QS.QSHdrLine.Visible      = false
                QS.QSWin.ClipsDescendants = false
                QS.QSWin.Size             = UDim2.new(0, QS.W, 0, 30)
                QS.QSBorderFrame.Size     = UDim2.new(0, QS.W + 4, 0, 34)
            else
                QS.QSMinBtn.Text          = "\226\136\146"
                QS.QSContent.Visible      = true
                QS.QSHdrFill.Visible      = true
                QS.QSHdrLine.Visible      = true
                QS.QSWin.ClipsDescendants = true
                QS.QSWin.Size             = UDim2.new(0, QS.W, 0, QS.H)
                QS.QSBorderFrame.Size     = UDim2.new(0, QS.W + 4, 0, QS.H + 4)
                task.defer(QS.refresh)
            end
        end
    end

    task.spawn(function()
        while _G.FadedHubAlive do
            task.wait(5)
            if QS.QSWin and QS.QSWin.Visible and not QS.minimized then
                pcall(QS.refresh)
            end
        end
    end)
end
_FH_InitQSPanel(); task.wait()

_G._FH_PRIORITY_STEAL = _G._FH_PRIORITY_STEAL or {}
do
    Config.priority_steal = Config.priority_steal or {}
    for name, on in pairs(Config.priority_steal) do
        if on then _G._FH_PRIORITY_STEAL[name] = true end
    end
end
local function _FH_InitPSPanel()
    PS.W = isMobile and 180 or 230
    PS.H = isMobile and 240 or 280
    PS.Border = Instance.new("Frame")
    PS.Border.Name                   = "PriorityStealGradBorder"
    PS.Border.Size                   = UDim2.new(0, PS.W + 4, 0, PS.H + 4)
    PS.Border.Position               = UDim2.new(0.5, -(PS.W + 4)/2, 0, 150)
    PS.Border.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    PS.Border.BackgroundTransparency = 1
    PS.Border.BorderSizePixel        = 0
    PS.Border.ZIndex                 = 18
    PS.Border.Visible                = false
    PS.Border.Parent                 = GUI
    Corner(PS.Border, 12)
    pcall(_FH_AddThemeStrokeToFrame, PS.Border, 1.5)

    PS.Win = Instance.new("Frame")
    PS.Win.Name                   = "PriorityStealPanel"
    PS.Win.Size                   = UDim2.new(0, PS.W, 0, PS.H)
    PS.Win.Position               = UDim2.new(0.5, -PS.W/2, 0, 152)
    PS.Win.BackgroundColor3       = T.BG
    PS.Win.BackgroundTransparency = 0.25
    PS.Win.BorderSizePixel        = 0
    PS.Win.ZIndex                 = 19
    PS.Win.Visible                = false
    PS.Win.ClipsDescendants       = true
    PS.Win.Parent                 = GUI
    Corner(PS.Win, 10)

    PS.Win:GetPropertyChangedSignal("Position"):Connect(function()
        if PS.Border then
            local p = PS.Win.Position
            PS.Border.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        end
    end)

    if Config.mini and Config.mini.ps_pos then
        local p = Config.mini.ps_pos
        PS.Win.Position = UDim2.new(p.xs or 0.5, p.x or -PS.W/2, p.ys or 0, p.y or 152)
    end

    PS.Hdr = Instance.new("Frame")
    PS.Hdr.Size             = UDim2.new(1, 0, 0, 32)
    PS.Hdr.BackgroundColor3 = T.Header
    PS.Hdr.BorderSizePixel  = 0
    PS.Hdr.ZIndex           = 20
    PS.Hdr.Active           = true
    PS.Hdr.Parent           = PS.Win
    Corner(PS.Hdr, 10)
    local hdrFill = Instance.new("Frame")
    hdrFill.Size             = UDim2.new(1, 0, 0, 10)
    hdrFill.Position         = UDim2.new(0, 0, 1, -10)
    hdrFill.BackgroundColor3 = T.Header
    hdrFill.BorderSizePixel  = 0
    hdrFill.ZIndex           = 20
    hdrFill.Parent           = PS.Hdr

    local title = Label(PS.Hdr, "Priority Steal", 12, T.White, Enum.Font.GothamBold)
    title.Size           = UDim2.new(1, -64, 1, 0)
    title.Position       = UDim2.new(0, 10, 0, 0)
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.ZIndex         = 21

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size            = UDim2.new(0, 22, 0, 22)
    closeBtn.Position        = UDim2.new(1, -28, 0.5, -11)
    closeBtn.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text            = "×"
    closeBtn.TextSize        = 14
    closeBtn.Font            = Enum.Font.GothamBold
    closeBtn.TextColor3      = T.White
    closeBtn.ZIndex          = 22
    closeBtn.Parent          = PS.Hdr
    Corner(closeBtn, 6)

    PS.Scroll = Instance.new("ScrollingFrame")
    PS.Scroll.Size                   = UDim2.new(1, -16, 1, -40)
    PS.Scroll.Position               = UDim2.new(0, 8, 0, 36)
    PS.Scroll.BackgroundTransparency = 1
    PS.Scroll.BorderSizePixel        = 0
    PS.Scroll.ScrollBarThickness     = 3
    PS.Scroll.ScrollBarImageColor3   = Color3.fromRGB(75, 75, 75)
    PS.Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    PS.Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    PS.Scroll.ZIndex                 = 19
    PS.Scroll.Parent                 = PS.Win
    local layout = Instance.new("UIListLayout")
    layout.Padding              = UDim.new(0, 4)
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    layout.Parent               = PS.Scroll
    Padding(PS.Scroll, 4, 4, 0, 0)

    local function _saveCfg()
        Config.priority_steal = {}
        for name, on in pairs(_G._FH_PRIORITY_STEAL) do
            if on then Config.priority_steal[name] = true end
        end
        pcall(FH_SaveConfig)
    end

    PS._rows = PS._rows or {}
    local function _renderNames(names)
        local present = {}
        for _, nm in ipairs(names) do present[nm] = true end
        for nm, row in pairs(PS._rows) do
            if not present[nm] then
                row:Destroy()
                PS._rows[nm] = nil
            end
        end
        table.sort(names)
        for _, nm in ipairs(names) do
            if not PS._rows[nm] then
            local on = _G._FH_PRIORITY_STEAL[nm] == true
            local row = Instance.new("Frame")
            row.Size            = UDim2.new(1, -4, 0, 24)
            row.BackgroundColor3 = T.Card
            row.BorderSizePixel = 0
            row.ZIndex          = 20
            row.Parent          = PS.Scroll
            Corner(row, 6)
            local lbl = Label(row, nm, 11, T.White, Enum.Font.GothamMedium)
            lbl.Size           = UDim2.new(1, -50, 1, 0)
            lbl.Position       = UDim2.new(0, 8, 0, 0)
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.ZIndex         = 21
            local tg = Instance.new("TextButton")
            tg.Size            = UDim2.new(0, 36, 0, 16)
            tg.Position        = UDim2.new(1, -42, 0.5, -8)
            tg.BackgroundColor3 = on and Color3.fromRGB(20, 70, 30) or Color3.fromRGB(50, 50, 50)
            tg.BorderSizePixel = 0
            tg.Text            = on and "ON" or "OFF"
            tg.TextSize        = 9
            tg.Font            = Enum.Font.GothamBold
            tg.TextColor3      = on and Color3.fromRGB(100, 220, 120) or T.Dim
            tg.ZIndex          = 21
            tg.Parent          = row
            Corner(tg, 4)
            tg.MouseButton1Click:Connect(function()
                local wasOn = _G._FH_PRIORITY_STEAL[nm] == true
                for k in pairs(_G._FH_PRIORITY_STEAL) do
                    _G._FH_PRIORITY_STEAL[k] = nil
                end
                if not wasOn then
                    _G._FH_PRIORITY_STEAL[nm] = true
                end
                for rname, rrow in pairs(PS._rows) do
                    local rtg = rrow:FindFirstChildOfClass("TextButton")
                    if rtg then
                        local on = _G._FH_PRIORITY_STEAL[rname] == true
                        rtg.Text             = on and "ON" or "OFF"
                        rtg.TextColor3       = on and Color3.fromRGB(100, 220, 120) or T.Dim
                        rtg.BackgroundColor3 = on and Color3.fromRGB(20, 70, 30) or Color3.fromRGB(50, 50, 50)
                    end
                end
                _saveCfg()
            end)
            PS._rows[nm] = row
            end
        end
    end

    local function _collectAnimalNames()
        local set = {}
        for nm, _ in pairs(_G._FH_PRIORITY_STEAL) do set[nm] = true end
        if _FH_AG_CachedBrainrots then
            for _, br in ipairs(_FH_AG_CachedBrainrots) do
                if br.displayName and br.displayName ~= "" then
                    set[br.displayName] = true
                end
            end
        end
        local names = {}
        for nm, _ in pairs(set) do table.insert(names, nm) end
        return names
    end

    PS._autoRefresh = nil
    local function _startAutoRefresh()
        if PS._autoRefresh then return end
        PS._autoRefresh = task.spawn(function()
            while PS.Win and PS.Win.Visible do
                local names = _collectAnimalNames()
                _renderNames(names)
                task.wait(2)
            end
            PS._autoRefresh = nil
        end)
    end

    local pDrag, pDragStart, pPanelStart = false, nil, nil
    PS.Hdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pDrag = true
            pDragStart  = inp.Position
            pPanelStart = PS.Win.Position
        end
    end)
    PS.Hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            if pDrag then
                pDrag = false
                Config.mini = Config.mini or {}
                Config.mini.ps_pos = {
                    x  = PS.Win.Position.X.Offset,
                    y  = PS.Win.Position.Y.Offset,
                    xs = PS.Win.Position.X.Scale,
                    ys = PS.Win.Position.Y.Scale,
                }
                pcall(FH_SaveConfig)
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not PS.Win or not PS.Win.Parent then return end
        if pDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                      or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - pDragStart
            PS.Win.Position = UDim2.new(
                pPanelStart.X.Scale, pPanelStart.X.Offset + d.X,
                pPanelStart.Y.Scale, pPanelStart.Y.Offset + d.Y
            )
        end
    end)

    PS.setVisible = function(v)
        PS.Win.Visible    = v and true or false
        PS.Border.Visible = v and true or false
        Config.mini = Config.mini or {}
        Config.mini.ps_open = v and true or false
        pcall(FH_SaveConfig)
        if v then _startAutoRefresh() end
    end

    closeBtn.MouseButton1Click:Connect(function()
        PS.setVisible(false)
        local reg = configRegistry["Priority Steal Panel"]
        if reg and reg.getState() then reg.doToggle() end
    end)
end
_FH_InitPSPanel(); task.wait()

local FA_init = {
    W = isMobile and 130 or 180, H = isMobile and 170 or 210,
    minimized  = false,
    dragging   = false,
    dragStart  = nil,
    panelStart = nil,
    BG        = Color3.fromRGB(15, 15, 15),
    HDR       = Color3.fromRGB(8,  8,  8),
    BTN       = Color3.fromRGB(24, 24, 24),
    BTN_HOVER = Color3.fromRGB(38, 38, 38),
}
for k, v in pairs(FA_init) do FA[k] = v end
FA.FABorderFrame = Instance.new("Frame")
FA.FABorderFrame.Name             = "FadedActionsGradBorder"
FA.FABorderFrame.Size             = UDim2.new(0, FA.W + 4, 0, FA.H + 4)
FA.FABorderFrame.Position         = UDim2.new(1, -(FA.W + 4 + 16), 1, -(FA.H + 4 + 16))
FA.FABorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FA.FABorderFrame.BorderSizePixel  = 0
FA.FABorderFrame.ZIndex           = 18
FA.FABorderFrame.Visible          = false
FA.FABorderFrame.Parent           = GUI
FA.FABorderFrame.BackgroundTransparency = 1
Corner(FA.FABorderFrame, 12)
FA.FAWin = Instance.new("Frame")
FA.FAWin.Name             = "FadedActionsPanel"
FA.FAWin.Size             = UDim2.new(0, FA.W, 0, FA.H)
FA.FAWin.Position         = UDim2.new(1, -(FA.W + 18), 1, -(FA.H + 18))
FA.FAWin.BackgroundColor3 = FA.BG
FA.FAWin.BorderSizePixel  = 0
FA.FAWin.ZIndex           = 19
FA.FAWin.Visible          = false
FA.FAWin.ClipsDescendants = true
FA.FAWin.BackgroundTransparency = 0.25
FA.FAWin.Parent           = GUI
Corner(FA.FAWin, 10)
FA.FAHdr = Instance.new("Frame")
FA.FAHdr.Size             = UDim2.new(1, 0, 0, 36)
FA.FAHdr.BackgroundColor3 = FA.HDR
FA.FAHdr.BorderSizePixel  = 0
FA.FAHdr.ZIndex           = 20
FA.FAHdr.BackgroundTransparency = 0.2
FA.FAHdr.Parent           = FA.FAWin
Corner(FA.FAHdr, 10)
FA.FAHdr.Active = true
FA.FAHdrFill = Instance.new("Frame")
FA.FAHdrFill.Size             = UDim2.new(1, 0, 0, 10)
FA.FAHdrFill.Position         = UDim2.new(0, 0, 1, -10)
FA.FAHdrFill.BackgroundColor3 = FA.HDR
FA.FAHdrFill.BorderSizePixel  = 0
FA.FAHdrFill.ZIndex           = 20
FA.FAHdrFill.Parent           = FA.FAHdr
FA.FAHdrLine = Instance.new("Frame")
FA.FAHdrLine.Size             = UDim2.new(1, 0, 0, 1)
FA.FAHdrLine.Position         = UDim2.new(0, 0, 1, -1)
FA.FAHdrLine.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
FA.FAHdrLine.BorderSizePixel  = 0
FA.FAHdrLine.ZIndex           = 21
FA.FAHdrLine.Parent           = FA.FAHdr
FA.FATitle = Instance.new("TextLabel")
FA.FATitle.Size                  = UDim2.new(1, -40, 1, 0)
FA.FATitle.Position              = UDim2.new(0, 12, 0, 0)
FA.FATitle.BackgroundTransparency = 1
FA.FATitle.Text                  = "Faded Actions"
FA.FATitle.TextSize              = 13
FA.FATitle.Font                  = Enum.Font.GothamBold
FA.FATitle.TextColor3            = Color3.fromRGB(245, 245, 245)
FA.FATitle.TextXAlignment        = Enum.TextXAlignment.Left
FA.FATitle.TextYAlignment        = Enum.TextYAlignment.Center
FA.FATitle.ZIndex                = 22
FA.FATitle.Parent                = FA.FAHdr
FA.FAMinBtn = Instance.new("TextButton")
FA.FAMinBtn.Size             = UDim2.new(0, 22, 0, 22)
FA.FAMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
FA.FAMinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
FA.FAMinBtn.BorderSizePixel  = 0
FA.FAMinBtn.Text             = "\226\136\146"
FA.FAMinBtn.TextSize         = 13
FA.FAMinBtn.Font             = Enum.Font.GothamBold
FA.FAMinBtn.TextColor3       = Color3.fromRGB(245, 245, 245)
FA.FAMinBtn.ZIndex           = 23
FA.FAMinBtn.Parent           = FA.FAHdr
Corner(FA.FAMinBtn, 6)
Stroke(FA.FAMinBtn, Color3.fromRGB(55, 55, 55), 1)
FA.FAContent = Instance.new("Frame")
FA.FAContent.Size                   = UDim2.new(1, 0, 1, -36)
FA.FAContent.Position               = UDim2.new(0, 0, 0, 36)
FA.FAContent.BackgroundTransparency = 1
FA.FAContent.ZIndex                 = 19
FA.FAContent.Parent                 = FA.FAWin
FA.FALayout = Instance.new("UIListLayout")
FA.FALayout.FillDirection       = Enum.FillDirection.Vertical
FA.FALayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
FA.FALayout.Padding             = UDim.new(0, 5)
FA.FALayout.Parent              = FA.FAContent
Padding(FA.FAContent, 8, 8, 8, 8)
FA.makeBtn = function(labelText, fireFn)
    local entry    = { keyCode = nil }
    local debounce = false
    local row = Instance.new("Frame")
    row.Size                   = UDim2.new(1, -4, 0, isMobile and 21 or 27)
    row.BackgroundColor3       = FA.BTN
    row.BorderSizePixel        = 0
    row.ZIndex                 = 20
    row.Parent                 = FA.FAContent
    Corner(row, 8)
    Stroke(row, Color3.fromRGB(45, 45, 45), 1)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -52, 1, 0)
    lbl.Position          = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = labelText
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = isMobile and 10 or 12
    lbl.TextColor3        = Color3.fromRGB(245, 245, 245)
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.TextYAlignment    = Enum.TextYAlignment.Center
    lbl.ZIndex            = 21
    lbl.Parent            = row
    local kbLbl = Instance.new("TextLabel")
    kbLbl.Size              = UDim2.new(0, 38, 0, 14)
    kbLbl.Position          = UDim2.new(1, -44, 0.5, -7)
    kbLbl.BackgroundTransparency = 1
    kbLbl.Text              = ""
kbLbl.TextSize          = 9
    kbLbl.Font              = Enum.Font.GothamBold
    kbLbl.TextColor3        = T.Dim
    kbLbl.TextXAlignment    = Enum.TextXAlignment.Center
    kbLbl.ZIndex            = 22
    kbLbl.Parent            = row
    do
        local _faKey = "fa_".. labelText:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
        local _saved = Config and Config.keybinds and Config.keybinds[_faKey]
        if type(_saved) == "string" then
            local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
            if _ok and _kc then
                entry.keyCode    = _kc
                kbLbl.Text       = "[" .. _saved .. "]"
                kbLbl.TextColor3 = T.Dim
            end
        end
    end
    local hitArea = Instance.new("Frame")
    hitArea.Size                   = UDim2.new(1, 0, 1, 0)
    hitArea.BackgroundTransparency = 1
    hitArea.ZIndex                 = 23
    hitArea.Active                 = true
    hitArea.Parent                 = row
    local _hitTouchActive = false
    local _hitTouchStart  = nil
    hitArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(row, F, {BackgroundColor3 = FA.BTN_HOVER})
            task.delay(0.12, function() Tween(row, F, {BackgroundColor3 = FA.BTN}) end)
            fireFn()
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            _hitTouchActive = true
            _hitTouchStart  = inp.Position
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if debounce then return end
            debounce = true
            task.delay(0.2, function() debounce = false end)
            if keybindBindingTarget then
                local prev = keybindBindingTarget
                keybindBindingTarget = nil
                if prev.kbLbl == kbLbl then
                    kbLbl.Text       = entry.keyCode and ("[".. entry.keyCode.Name .. "]") or ""
kbLbl.TextColor3 = T.Dim
                    return
                else
                    prev.kbLbl.Text       = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
                end
            end
            kbLbl.Text       = "(...)"
kbLbl.TextColor3 = T.White
            keybindBindingTarget = { entry = entry, kbLbl = kbLbl, mode = "assign"}
        end
    end)
    local _rowHovered = false
    hitArea.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _hitTouchActive then
            _hitTouchActive = false
            if _hitTouchStart and (inp.Position - _hitTouchStart).Magnitude < 20 then
                Tween(row, F, {BackgroundColor3 = FA.BTN_HOVER})
                task.delay(0.12, function()
                    Tween(row, F, {BackgroundColor3 = _rowHovered and FA.BTN_HOVER or FA.BTN})
                end)
                fireFn()
            end
            _hitTouchStart = nil
        end
    end)
    row.MouseEnter:Connect(function()
        if _rowHovered then return end
        _rowHovered = true
        Tween(row, F, {BackgroundColor3 = FA.BTN_HOVER})
    end)
    row.MouseLeave:Connect(function()
        if not _rowHovered then return end
        _rowHovered = false
        Tween(row, F, {BackgroundColor3 = FA.BTN})
    end)
    table.insert(keybindEntries, { entry = entry, fire = fireFn, kbLbl = kbLbl })
    local faKey = "fa_".. labelText:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    configRegistry[faKey] = {
        getState   = function() return false end,
        getKeyCode = function() return entry.keyCode end,
        setKeyCode = function(kc)
            entry.keyCode = kc
            if kc then
                kbLbl.Text       = "[".. kc.Name .. "]"
kbLbl.TextColor3 = T.Dim
                Config.keybinds[faKey] = kc.Name
            else
                kbLbl.Text = ""
Config.keybinds[faKey] = nil
            end
            pcall(FH_SaveConfig)
        end,
        doToggle   = fireFn,
        kbLbl      = kbLbl,
        kbEntry    = entry,
    }
    return row
end
FA.makeBtn("Kick Self", function()
task.spawn(function() player:Kick() end)
    task.spawn(function() pcall(function() game:Shutdown() end) end)
    task.spawn(function() pcall(function() game:GetService("TeleportService"):Teleport(0, player) end) end)
    task.spawn(function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, player) end) end)
end)
do
    FA.makeBtn("Ragdoll Self", function()
        local commandFrame, profileFrame = _ragdollGetAdminFrames()
        if not commandFrame or not profileFrame then return end
        local pName = Players.LocalPlayer.Name
        local profileBtn = profileFrame:FindFirstChild(pName)
        local ragdollBtn = commandFrame:FindFirstChild("ragdoll")
        if not profileBtn or not ragdollBtn then return end
        if not _ragdollProfileCache[pName] then
            _ragdollProfileCache[pName] = _ragdollCacheActivated(profileBtn)
        end
        if not _ragdollCommandCache["ragdoll"] then
            _ragdollCommandCache["ragdoll"] = _ragdollCacheActivated(ragdollBtn)
        end
        _ragdollFireActivated(_ragdollCommandCache["ragdoll"])
        task.wait()
        _ragdollFireActivated(_ragdollProfileCache[pName])
    end)
    FA.makeBtn("GP+RGDL", function()
        task.spawn(function()
            local lp2  = Players.LocalPlayer
            local char2 = lp2.Character
            local bp2   = lp2:FindFirstChild("Backpack")
            if not char2 then return end
            local potion2 = (char2 and char2:FindFirstChild("Giant Potion"))
                         or (bp2  and  bp2:FindFirstChild("Giant Potion"))
            if potion2 then
                if potion2.Parent ~= char2 then
                    local hum2 = char2:FindFirstChildOfClass("Humanoid")
                    if hum2 then hum2:EquipTool(potion2) end
                    task.wait(0.05)
                end
                pcall(function() potion2:Activate() end)
            end
            task.wait(0.5)
            local cF2, pF2 = _ragdollGetAdminFrames()
            if cF2 and pF2 then
                local pName2 = lp2.Name
                local pBtn2  = pF2:FindFirstChild(pName2)
                local rBtn2  = cF2:FindFirstChild("ragdoll")
                if pBtn2 and rBtn2 then
                    if not _ragdollCommandCache["ragdoll"] then
                        _ragdollCommandCache["ragdoll"] = _ragdollCacheActivated(rBtn2)
                    end
                    if not _ragdollProfileCache[pName2] then
                        _ragdollProfileCache[pName2] = _ragdollCacheActivated(pBtn2)
                    end
                    _ragdollFireActivated(_ragdollCommandCache["ragdoll"])
                    task.wait()
                    _ragdollFireActivated(_ragdollProfileCache[pName2])
                end
            end
        end)
    end)
end
FA.makeBtn("Reset Character", function()
    doSelectedReset()
end)
FA.makeBtn("Rejoin Server", function()
    local ts = game:GetService("TeleportService")
    task.spawn(function()
        pcall(function() ts:Teleport(game.PlaceId, Players.LocalPlayer) end)
    end)
    pcall(function() Players.LocalPlayer:Kick("rejoining") end)
end)
do
    FA.FAHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            FA.dragging   = true
            FA.dragStart  = inp.Position
            FA.panelStart = FA.FAWin.Position
        end
    end)
    FA.FAHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            FA.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.fa_pos = { x = FA.FAWin.Position.X.Offset, y = FA.FAWin.Position.Y.Offset,
                                   xs = FA.FAWin.Position.X.Scale, ys = FA.FAWin.Position.Y.Scale }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if FA.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - FA.dragStart
            local newPos = UDim2.new(
                FA.panelStart.X.Scale, FA.panelStart.X.Offset + d.X,
                FA.panelStart.Y.Scale, FA.panelStart.Y.Offset + d.Y
            )
            FA.FAWin.Position         = newPos
            FA.FABorderFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 2,
                newPos.Y.Scale, newPos.Y.Offset - 2
            )
        end
    end)
end
FA.FAMinBtn.MouseButton1Click:Connect(function()
    FA.minimized = not FA.minimized
    if FA.minimized then
        FA.FAWin.ClipsDescendants = false
        FA.FAHdrFill.Visible = false
        FA.FAHdrLine.Visible = false
        FA.FAContent.Visible = false
        Tween(FA.FAWin,         M, {Size = UDim2.new(0, FA.W, 0, 36)})
        Tween(FA.FABorderFrame, M, {Size = UDim2.new(0, FA.W + 4, 0, 40)})
        FA.FAMinBtn.Text = "+"else
        FA.FAHdrFill.Visible = true
        FA.FAHdrLine.Visible = true
        Tween(FA.FAWin,         M, {Size = UDim2.new(0, FA.W, 0, FA.H)})
        Tween(FA.FABorderFrame, M, {Size = UDim2.new(0, FA.W + 4, 0, FA.H + 4)})
        FA.FAMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            FA.FAContent.Visible = true
            FA.FAWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.fa_min = FA.minimized
        pcall(FH_SaveConfig)
    end
end)
FA.setFadedActionsVisible = function(vis)
    FA.FAWin.Visible         = vis
    FA.FABorderFrame.Visible = vis
    if vis then
        local p = FA.FAWin.Position
        FA.FABorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if FA.minimized then
            FA.FAMinBtn.Text      = "+"
FA.FAContent.Visible  = false
            FA.FAHdrFill.Visible  = false
            FA.FAHdrLine.Visible  = false
            FA.FAWin.ClipsDescendants = false
            FA.FAWin.Size         = UDim2.new(0, FA.W, 0, 36)
            FA.FABorderFrame.Size = UDim2.new(0, FA.W + 4, 0, 40)
        else
            FA.FAMinBtn.Text      = "\226\136\146"
FA.FAContent.Visible  = true
            FA.FAHdrFill.Visible  = true
            FA.FAHdrLine.Visible  = true
            FA.FAWin.ClipsDescendants = true
            FA.FAWin.Size         = UDim2.new(0, FA.W, 0, FA.H)
            FA.FABorderFrame.Size = UDim2.new(0, FA.W + 4, 0, FA.H + 4)
        end
    end
end
do
    BOOK_OPEN = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Win.Size             = UDim2.new(0, 0, 0, WIN_H)
    Win.Position         = UDim2.new(0.5, 0, 0.5, -WIN_H / 2)
    BorderFrame.Size     = UDim2.new(0, 4, 0, WIN_H + 4)
    BorderFrame.Position = UDim2.new(0.5, -2, 0.5, -(WIN_H + 4) / 2)
    Win.Visible         = true
    BorderFrame.Visible = true
    task.delay(0.18, function()
        local _tx, _ty = -WIN_W / 2, -WIN_H / 2
        TweenService:Create(Win, BOOK_OPEN, {
            Size     = UDim2.new(0, WIN_W, 0, WIN_H),
            Position = UDim2.new(0.5, _tx, 0.5, _ty),
        }):Play()
        TweenService:Create(BorderFrame, BOOK_OPEN, {
            Size     = UDim2.new(0, WIN_W + 4, 0, WIN_H + 4),
            Position = UDim2.new(0.5, _tx - 2, 0.5, _ty - 2),
        }):Play()
    end)
end
WSK.W = isMobile and 144 or 200; WSK.H = isMobile and 64 or 90
WSK.WSKBorderFrame = Instance.new("Frame")
WSK.WSKBorderFrame.Name             = "WSKGradBorder"
WSK.WSKBorderFrame.Size             = UDim2.new(0, WSK.W + 4, 0, WSK.H + 4)
WSK.WSKBorderFrame.Position         = UDim2.new(1, -(WSK.W + 4 + 16), 1, -(WSK.H + 4 + 195 + 188 + 52))
WSK.WSKBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WSK.WSKBorderFrame.BorderSizePixel  = 0
WSK.WSKBorderFrame.ZIndex           = 18
WSK.WSKBorderFrame.Visible          = false
WSK.WSKBorderFrame.Parent           = GUI
WSK.WSKBorderFrame.BackgroundTransparency = 1
Corner(WSK.WSKBorderFrame, 12)
do
WSK.WSKWin = Instance.new("Frame")
WSK.WSKWin.Name             = "WSKPanel"
WSK.WSKWin.Size             = UDim2.new(0, WSK.W, 0, WSK.H)
WSK.WSKWin.Position         = UDim2.new(1, -(WSK.W + 18), 1, -(WSK.H + 195 + 188 + 50))
WSK.WSKWin.BackgroundColor3 = T.BG
WSK.WSKWin.BackgroundTransparency = 0.25
WSK.WSKWin.BorderSizePixel  = 0
WSK.WSKWin.ZIndex           = 19
WSK.WSKWin.Visible          = false
WSK.WSKWin.ClipsDescendants = true
WSK.WSKWin.Parent           = GUI
Corner(WSK.WSKWin, 10)
WSK.WSKHdr = Instance.new("Frame")
WSK.WSKHdr.Size             = UDim2.new(1, 0, 0, 36)
WSK.WSKHdr.BackgroundColor3 = T.Header
WSK.WSKHdr.BackgroundTransparency = 0.2
WSK.WSKHdr.BorderSizePixel  = 0
WSK.WSKHdr.ZIndex           = 20
WSK.WSKHdr.Parent           = WSK.WSKWin
Corner(WSK.WSKHdr, 10)
WSK.WSKHdr.Active = true
WSK.WSKHdrFill = Instance.new("Frame")
WSK.WSKHdrFill.Size             = UDim2.new(1, 0, 0, 10)
WSK.WSKHdrFill.Position         = UDim2.new(0, 0, 1, -10)
WSK.WSKHdrFill.BackgroundColor3 = T.Header
WSK.WSKHdrFill.BackgroundTransparency = 0.2
WSK.WSKHdrFill.BorderSizePixel  = 0
WSK.WSKHdrFill.ZIndex           = 20
WSK.WSKHdrFill.Parent           = WSK.WSKHdr
WSK.WSKHdrLine = Instance.new("Frame")
WSK.WSKHdrLine.Size             = UDim2.new(1, 0, 0, 1)
WSK.WSKHdrLine.Position         = UDim2.new(0, 0, 1, -1)
WSK.WSKHdrLine.BackgroundColor3 = T.Border
WSK.WSKHdrLine.BorderSizePixel  = 0
WSK.WSKHdrLine.ZIndex           = 21
WSK.WSKHdrLine.Parent           = WSK.WSKHdr
do
local WSKTitleLbl = Label(WSK.WSKHdr, "Websling Kill", 13, T.White, Enum.Font.GothamBold)
WSKTitleLbl.Size           = UDim2.new(1, -40, 1, 0)
WSKTitleLbl.Position       = UDim2.new(0, 12, 0, 0)
WSKTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
WSKTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
WSKTitleLbl.ZIndex         = 22
WSK.WSKMinBtn = Instance.new("TextButton")
WSK.WSKMinBtn.Size             = UDim2.new(0, 22, 0, 22)
WSK.WSKMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
WSK.WSKMinBtn.BackgroundColor3 = T.Card
WSK.WSKMinBtn.BorderSizePixel  = 0
WSK.WSKMinBtn.Text             = "\226\136\146"
WSK.WSKMinBtn.TextSize         = 14
WSK.WSKMinBtn.Font             = Enum.Font.GothamBold
WSK.WSKMinBtn.TextColor3       = T.White
WSK.WSKMinBtn.ZIndex           = 23
WSK.WSKMinBtn.Parent           = WSK.WSKHdr
Corner(WSK.WSKMinBtn, 6)
Stroke(WSK.WSKMinBtn, T.Border, 1)
WSK.WSKContent = Instance.new("Frame")
WSK.WSKContent.Size                   = UDim2.new(1, 0, 1, -36)
WSK.WSKContent.Position               = UDim2.new(0, 0, 0, 36)
WSK.WSKContent.BackgroundTransparency = 1
WSK.WSKContent.ZIndex                 = 20
WSK.WSKContent.Parent                 = WSK.WSKWin
Padding(WSK.WSKContent, 8, 8, 8, 8)
local wskRow = Instance.new("Frame")
wskRow.Size             = UDim2.new(1, 0, 0, 32)
wskRow.BackgroundColor3 = T.Card
wskRow.BorderSizePixel  = 0
wskRow.ZIndex           = 21
wskRow.Parent           = WSK.WSKContent
Corner(wskRow, 8)
Stroke(wskRow, T.Border, 1)
local wskLbl = Label(wskRow, "Fire WSK (1s)", 13, T.White, Enum.Font.GothamMedium)
wskLbl.Size           = UDim2.new(1, -100, 1, 0)
wskLbl.Position       = UDim2.new(0, 10, 0, 0)
wskLbl.TextYAlignment = Enum.TextYAlignment.Center
wskLbl.ZIndex         = 22
WSK.wskKbLbl = Instance.new("TextLabel")
WSK.wskKbLbl.Size              = UDim2.new(0, 36, 0, 14)
WSK.wskKbLbl.Position          = UDim2.new(1, -94, 0.5, -7)
WSK.wskKbLbl.BackgroundTransparency = 1
WSK.wskKbLbl.Text              = ""
WSK.wskKbLbl.TextSize          = 9
WSK.wskKbLbl.Font              = Enum.Font.GothamBold
WSK.wskKbLbl.TextColor3        = T.Dim
WSK.wskKbLbl.TextXAlignment    = Enum.TextXAlignment.Center
WSK.wskKbLbl.ZIndex            = 23
WSK.wskKbLbl.Parent            = wskRow
do
    local _saved = Config and Config.keybinds and Config.keybinds["wsk_fire_burst"]
    if type(_saved) == "string" then
        local _ok, _kc = pcall(function() return Enum.KeyCode[_saved] end)
        if _ok and _kc then
            WSK.entry.keyCode       = _kc
            WSK.wskKbLbl.Text       = "[" .. _saved .. "]"
            WSK.wskKbLbl.TextColor3 = T.Dim
        end
    end
end
local wskTrack = Instance.new("Frame")
wskTrack.Size             = UDim2.new(0, 28, 0, 16)
wskTrack.Position         = UDim2.new(1, -48, 0.5, -11)
wskTrack.BackgroundColor3 = T.TrackOff
wskTrack.BorderSizePixel  = 0
wskTrack.ZIndex           = 22
wskTrack.Parent           = wskRow
Corner(wskTrack, 8)
local wskTStroke = Stroke(wskTrack, T.Border, 1)
local wskKnob = Instance.new("Frame")
wskKnob.Size             = UDim2.new(0, 12, 0, 12)
wskKnob.Position         = UDim2.new(0, 2, 0.5, -6)
wskKnob.BackgroundColor3 = T.KnobOff
wskKnob.BorderSizePixel  = 0
wskKnob.ZIndex           = 23
wskKnob.Parent           = wskTrack
Corner(wskKnob, 6)
local wskFiring = false
local wskFireBurst
_G._FH_WSKFireBurst = function() if wskFireBurst then wskFireBurst() end end
wskFireBurst = function()
    if wskFiring then return end
    wskFiring = true
    Tween(wskKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0.5, -5)})
    task.delay(0.06, function()
        Tween(wskKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
        Tween(wskKnob,    M, {BackgroundColor3 = T.KnobOn})
        Tween(wskTrack,   M, {BackgroundColor3 = T.TrackOn})
        Tween(wskTStroke, M, {Color = T.TrackOn})
    end)
    wskLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
    task.spawn(function()
        local localChar = Players.LocalPlayer.Character
        local hum       = localChar and localChar:FindFirstChildOfClass("Humanoid")
        if not localChar or not hum then
            wskFiring = false
            return
        end
        local ws = localChar:FindFirstChild("Web Slinger")
            or (Players.LocalPlayer.Backpack and Players.LocalPlayer.Backpack:FindFirstChild("Web Slinger"))
        if not ws then wskFiring = false; return end
        if ws.Parent ~= localChar then
            hum:EquipTool(ws)
            task.wait(0.05)
        end
        pcall(Aim.aimInitRemotes)
        Aim.currentCharacter = localChar
        local target = wskGetNearest()
        if not target or not target.Character then wskFiring = false; return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local tHum = target.Character:FindFirstChildOfClass("Humanoid")
        if not tHRP or not tHum then wskFiring = false; return end
        local above     = true
        local shotTimer = 0
        local stopped   = false
        local function doStop(loop)
            if stopped then return end
            stopped = true
            loop:Disconnect()
            Tween(wskKnob, TweenInfo.new(0.06), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 15, 0.5, -5)})
            task.delay(0.06, function()
                Tween(wskKnob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
                Tween(wskKnob,    M, {BackgroundColor3 = T.KnobOff})
                Tween(wskTrack,   M, {BackgroundColor3 = T.TrackOff})
                Tween(wskTStroke, M, {Color = T.Border})
            end)
            wskLbl.TextColor3 = T.White
            wskFiring = false
        end
        local burstLoop
        burstLoop = RunService.Heartbeat:Connect(function(dt)
            if tHum.Health <= 0 or not tHum.Parent then
                doStop(burstLoop)
                return
            end
            shotTimer += dt
            if shotTimer >= 0.08 then
                shotTimer = 0
                pcall(Aim.aimShoot)
            end
            if target.Character and tHRP and tHRP.Parent then
                if above then
                    tHRP.CFrame = tHRP.CFrame + Vector3.new(0, 20, 0)
                else
                    tHRP.CFrame = tHRP.CFrame + Vector3.new(0, -20, 0)
                end
                above = not above
            end
        end)
        task.wait(1)
        doStop(burstLoop)
    end)
end
local wskHitArea = Instance.new("Frame")
wskHitArea.Size                   = UDim2.new(1, 0, 1, 0)
wskHitArea.BackgroundTransparency = 1
wskHitArea.ZIndex                 = 24
wskHitArea.Active                 = true
wskHitArea.Parent                 = wskRow
wskHitArea.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        wskFireBurst()
    elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
        if WSK.kb2Debounce then return end
        WSK.kb2Debounce = true
        task.delay(0.2, function() WSK.kb2Debounce = false end)
        if keybindBindingTarget then
            local prev = keybindBindingTarget
            keybindBindingTarget = nil
            if prev.kbLbl == WSK.wskKbLbl then
                WSK.wskKbLbl.Text       = WSK.entry.keyCode and ("[".. WSK.entry.keyCode.Name .. "]") or ""
WSK.wskKbLbl.TextColor3 = T.Dim
                return
            else
                prev.kbLbl.Text       = prev.entry.keyCode and ("[".. prev.entry.keyCode.Name .. "]") or ""
prev.kbLbl.TextColor3 = T.Dim
            end
        end
        WSK.wskKbLbl.Text       = "(...)"
WSK.wskKbLbl.TextColor3 = T.White
        keybindBindingTarget = { entry = WSK.entry, kbLbl = WSK.wskKbLbl, mode = "assign"}
    end
end)
do
    local _wskTouchStart = nil
    wskHitArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            _wskTouchStart = inp.Position
        end
    end)
    wskHitArea.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and _wskTouchStart then
            local mag = (inp.Position - _wskTouchStart).Magnitude
            _wskTouchStart = nil
            if mag < 20 then wskFireBurst() end
        end
    end)
end
table.insert(keybindEntries, { entry = WSK.entry, fire = wskFireBurst, kbLbl = WSK.wskKbLbl })
configRegistry["wsk_fire_burst"] = {
    getState   = function() return false end,
    getKeyCode = function() return WSK.entry.keyCode end,
    setKeyCode = function(kc)
        WSK.entry.keyCode = kc
        if kc then
            WSK.wskKbLbl.Text       = "[".. kc.Name .. "]"
WSK.wskKbLbl.TextColor3 = T.Dim
            Config.keybinds["wsk_fire_burst"] = kc.Name
        else
            WSK.wskKbLbl.Text = ""
Config.keybinds["wsk_fire_burst"] = nil
        end
        pcall(FH_SaveConfig)
    end,
    doToggle = wskFireBurst,
}
end
WSK.WSKHdr.InputBegan:Connect(function(inp)
    if _G._FH_GUI_LOCKED then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        WSK.dragging   = true
        WSK.dragStart  = inp.Position
        WSK.panelStart = WSK.WSKWin.Position
    end
end)
WSK.WSKHdr.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        WSK.dragging = false
        Config.mini = Config.mini or {}
        Config.mini.wsk_pos = { x = WSK.WSKWin.Position.X.Offset, y = WSK.WSKWin.Position.Y.Offset,
                                xs = WSK.WSKWin.Position.X.Scale, ys = WSK.WSKWin.Position.Y.Scale }
        pcall(FH_SaveConfig)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if WSK.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - WSK.dragStart
        local newPos = UDim2.new(
            WSK.panelStart.X.Scale, WSK.panelStart.X.Offset + d.X,
            WSK.panelStart.Y.Scale, WSK.panelStart.Y.Offset + d.Y
        )
        WSK.WSKWin.Position         = newPos
        WSK.WSKBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
    end
end)
WSK.WSKMinBtn.MouseButton1Click:Connect(function()
    WSK.minimized = not WSK.minimized
    if WSK.minimized then
        WSK.WSKWin.ClipsDescendants = false
        WSK.WSKHdrFill.Visible  = false
        WSK.WSKHdrLine.Visible  = false
        WSK.WSKContent.Visible  = false
        Tween(WSK.WSKWin,         M, {Size = UDim2.new(0, WSK.W, 0, 36)})
        Tween(WSK.WSKBorderFrame, M, {Size = UDim2.new(0, WSK.W + 4, 0, 40)})
        WSK.WSKMinBtn.Text = "+"else
        WSK.WSKHdrFill.Visible = true
        WSK.WSKHdrLine.Visible = true
        Tween(WSK.WSKWin,         M, {Size = UDim2.new(0, WSK.W, 0, WSK.H)})
        Tween(WSK.WSKBorderFrame, M, {Size = UDim2.new(0, WSK.W + 4, 0, WSK.H + 4)})
        WSK.WSKMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            WSK.WSKContent.Visible  = true
            WSK.WSKWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.wsk_min = WSK.minimized
        pcall(FH_SaveConfig)
    end
end)
WSK.setWSKPanelVisible = function(vis)
    WSK.WSKWin.Visible         = vis
    WSK.WSKBorderFrame.Visible = vis
    if vis then
        local p = WSK.WSKWin.Position
        WSK.WSKBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if WSK.minimized then
            WSK.WSKMinBtn.Text          = "+"
WSK.WSKContent.Visible      = false
            WSK.WSKHdrFill.Visible      = false
            WSK.WSKHdrLine.Visible      = false
            WSK.WSKWin.ClipsDescendants = false
            WSK.WSKWin.Size             = UDim2.new(0, WSK.W, 0, 36)
            WSK.WSKBorderFrame.Size     = UDim2.new(0, WSK.W + 4, 0, 40)
        else
            WSK.WSKMinBtn.Text          = "\226\136\146"
WSK.WSKContent.Visible      = true
            WSK.WSKHdrFill.Visible      = true
            WSK.WSKHdrLine.Visible      = true
            WSK.WSKWin.ClipsDescendants = true
            WSK.WSKWin.Size             = UDim2.new(0, WSK.W, 0, WSK.H)
            WSK.WSKBorderFrame.Size     = UDim2.new(0, WSK.W + 4, 0, WSK.H + 4)
        end
    else
        WSK.enabled = false
        wskStop()
    end
end
end
local AutoDefenseEnabled  = false
local AntiTPEnabled_state = false
local startAntiIntruder, stopAntiIntruder
task.spawn(function()
AutoDefenseEnabled     = false
AntiTPEnabled_state    = false
local kickNoCmdsEnabled      = false
local defenseTarget1, defenseTarget2
local lastDefenseExecuteTime = 0
local defenseCommandCache    = {}
local defenseProfileCache    = {}
local function defenseCacheActivated(guiObject)
    local cached = {}
    local ok, conns = pcall(getconnections, guiObject.Activated)
    if ok and type(conns) == "table"then
        for _, conn in ipairs(conns) do
            if type(conn.Function) == "function"then
                table.insert(cached, conn.Function)
            end
        end
    end
    return cached
end
local function defenseFireActivated(cached)
    for _, fn in ipairs(cached) do task.spawn(fn) end
end
local function getDefenseAdminPanel()
    local player     = Players.LocalPlayer
    local adminPanel = player.PlayerGui:FindFirstChild("AdminPanel")
    if not adminPanel then return nil, nil end
    local panel = adminPanel:FindFirstChild("AdminPanel")
    if not panel then return nil, nil end
    local content  = panel:FindFirstChild("Content")
    local profiles = panel:FindFirstChild("Profiles")
    if not content or not profiles then return nil, nil end
    return content:FindFirstChild("ScrollingFrame"), profiles:FindFirstChild("ScrollingFrame")
end
local function buildDefenseCache(targetPlayer)
    local commandFrame, profileFrame = getDefenseAdminPanel()
    if not commandFrame or not profileFrame then return false end
    local profileButton = profileFrame:FindFirstChild(targetPlayer.Name)
    if not profileButton then return false end
    if not defenseProfileCache[targetPlayer.Name] then
        defenseProfileCache[targetPlayer.Name] = defenseCacheActivated(profileButton)
    end
    for _, cmd in ipairs({"balloon","ragdoll","jail"}) do
        if not defenseCommandCache[cmd] then
            local btn = commandFrame:FindFirstChild(cmd)
            if btn then defenseCommandCache[cmd] = defenseCacheActivated(btn) end
        end
    end
    return true
end
local function defenseExecuteCommandsOnPlayer(targetPlayer, commandList)
    if not defenseProfileCache[targetPlayer.Name] or #defenseProfileCache[targetPlayer.Name] == 0 then
        if not buildDefenseCache(targetPlayer) then return false end
    end
    local profileConns = defenseProfileCache[targetPlayer.Name]
    for _, command in ipairs(commandList) do
        local cmdConns = defenseCommandCache[command]
        if cmdConns and #cmdConns > 0 then
            defenseFireActivated(cmdConns)
            defenseFireActivated(profileConns)
        end
    end
    return true
end
local defenseCmdSwitch = false
local defenseBothOnCD = false
local defenseLaserActive = false
task.spawn(function()
    while _G.FadedHubAlive do
        if AutoDefenseEnabled then
            task.wait(0.15)
            pcall(function()
                local sf = Players.LocalPlayer.PlayerGui.AdminPanel.AdminPanel.Content.ScrollingFrame
                local balloonCD = sf.balloon.Timer.Visible
                local ragdollCD = sf.ragdoll.Timer.Visible
                if balloonCD and ragdollCD then
                    defenseBothOnCD = true
                else
                    defenseBothOnCD = false
                    if not balloonCD then
                        defenseCmdSwitch = false
                    elseif not ragdollCD then
                        defenseCmdSwitch = true
                    end
                end
            end)
        else
            task.wait(0.75)
        end
    end
end)
local defenseExecuteCooldown = 0.05
local function defenseAutoSelectClosest()
    local player = Players.LocalPlayer
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr:GetAttribute("Stealing") then defenseTarget1 = plr; break end
    end
end
local function defenseRunDefenseCommands()
    local player = Players.LocalPlayer
    if (tick() - lastDefenseExecuteTime) < defenseExecuteCooldown then return end
    if not defenseTarget1 and not defenseTarget2 then defenseAutoSelectClosest() end
    local validPlayers = {}
    if defenseTarget1 and defenseTarget1.Parent == Players and defenseTarget1:GetAttribute("Stealing") then table.insert(validPlayers, defenseTarget1) end
    if defenseTarget2 and defenseTarget2.Parent == Players and defenseTarget2:GetAttribute("Stealing") then table.insert(validPlayers, defenseTarget2) end
    if #validPlayers == 0 then return end
    if #validPlayers == 1 then
        if not defenseCmdSwitch then
            task.spawn(function() defenseExecuteCommandsOnPlayer(validPlayers[1], {"balloon"}) end)
        else
            task.spawn(function() defenseExecuteCommandsOnPlayer(validPlayers[1], {"ragdoll"}) end)
        end
    elseif #validPlayers >= 2 then
        task.spawn(function() defenseExecuteCommandsOnPlayer(validPlayers[1], {"balloon","tiny","inverse","rocket"}) end)
        task.spawn(function() defenseExecuteCommandsOnPlayer(validPlayers[2], {"ragdoll","jail","jumpscare","morph"}) end)
    end
    lastDefenseExecuteTime = tick()
end
do
local antiIntruderConn    = nil
    local antiIntruderThrottle = 0

    local function _parseProtectionSeconds(txt)
        if type(txt) ~= "string" or txt == "" then return math.huge end
        local mins, secs = txt:match("(%d+)%s*[:m]%s*(%d+)")
        if mins and secs then return tonumber(mins) * 60 + tonumber(secs) end
        local s = txt:match("(%d+)")
        if s then return tonumber(s) end
        return math.huge
    end

    local function _myProtectionSeconds()
        local lp = Players.LocalPlayer
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return math.huge end
        for _, plot in ipairs(plots:GetChildren()) do
            if _FH_AG_IsMyPlot(plot) then
                if _G._FH_BaseTimerTexts and _G._FH_BaseTimerTexts[plot] then
                    return _parseProtectionSeconds(_G._FH_BaseTimerTexts[plot])
                end
                local sign = plot:FindFirstChild("PlotSign")
                if sign then
                    for _, d in ipairs(sign:GetDescendants()) do
                        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible
                           and type(d.Text) == "string" and d.Text:match("%d") then
                            local s = _parseProtectionSeconds(d.Text)
                            if s ~= math.huge then return s end
                        end
                    end
                end
                return math.huge
            end
        end
        return math.huge
    end

    startAntiIntruder = function()
        if antiIntruderConn then return end
        antiIntruderConn = RunService.Heartbeat:Connect(function()
            if not AntiTPEnabled_state then return end
            local now = tick()
            if now - antiIntruderThrottle < 0.35 then return end
            antiIntruderThrottle = now

            local secsLeft = _myProtectionSeconds()
            if secsLeft >= 3 then return end
            local lp = Players.LocalPlayer
            local hitbox = nil
            local plots = workspace:FindFirstChild("Plots")
            if plots then
                for _, plot in ipairs(plots:GetChildren()) do
                    local sign = plot:FindFirstChild("PlotSign")
                    if sign then
                        local lbl = sign:FindFirstChildWhichIsA("TextLabel", true)
                        if lbl then
                            local t = lbl.Text:lower()
                            if t:find(lp.Name:lower()) or t:find(lp.DisplayName:lower()) then
                                hitbox = plot:FindFirstChild("StealHitbox", true)
                                break
                            end
                        end
                    end
                end
            end
            if not hitbox then return end
            local cf   = hitbox.CFrame
            local size = hitbox.Size
            local hx   = size.X * 0.5
            local hz   = size.Z * 0.5
            local _intruderIdx = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local rel = cf:PointToObjectSpace(hrp.Position)
                        if math.abs(rel.X) <= hx and math.abs(rel.Z) <= hz then
                            _intruderIdx = _intruderIdx + 1
                            local _slotIdx = _intruderIdx
                            task.spawn(function()
                                local commandFrame, profileFrame = getDefenseAdminPanel()
                                if not commandFrame or not profileFrame then return end
                                local profileBtn = profileFrame:FindFirstChild(plr.Name)
                                if not profileBtn then return end
                                if not defenseProfileCache[plr.Name] then
                                    defenseProfileCache[plr.Name] = defenseCacheActivated(profileBtn)
                                end
                                local cmdsToRun = {}

                                local _cmdList
                                if (_slotIdx % 2) == 1 then
                                    _cmdList = _G._FH_DefenseCmdsP1
                                else
                                    _cmdList = _G._FH_DefenseCmdsP2
                                end
                                if type(_cmdList) ~= "table" or #_cmdList == 0 then
                                    _cmdList = _G._FH_DefenseCmds
                                end
                                if type(_cmdList) ~= "table" or #_cmdList == 0 then
                                    _cmdList = { "balloon", "jail" }
                                end
                                for _, cmdName in ipairs(_cmdList) do
                                    if not defenseCommandCache[cmdName] then
                                        local cb = commandFrame:FindFirstChild(cmdName)
                                        if cb then
                                            defenseCommandCache[cmdName] = defenseCacheActivated(cb)
                                        end
                                    end
                                    local cc = defenseCommandCache[cmdName]
                                    local sf = nil
                                    pcall(function()
                                        sf = lp.PlayerGui.AdminPanel.AdminPanel.Content.ScrollingFrame
                                    end)
                                    local onCD = false
                                    if sf then
                                        local f = sf:FindFirstChild(cmdName)
                                        if f and f:FindFirstChild("Timer") and f.Timer.Visible then
                                            onCD = true
                                        end
                                    end
                                    if not onCD and cc and #cc > 0 then
                                        table.insert(cmdsToRun, cmdName)
                                    end
                                end
                                if #cmdsToRun > 0 then
                                    local profileConns = defenseProfileCache[plr.Name]
                                    for _, cmdName in ipairs(cmdsToRun) do
                                        local cc = defenseCommandCache[cmdName]
                                        if cc and #cc > 0 then
                                            defenseFireActivated(cc)
                                            defenseFireActivated(profileConns)
                                            task.wait(0.05)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end
    stopAntiIntruder = function()
        if antiIntruderConn then antiIntruderConn:Disconnect(); antiIntruderConn = nil end
    end
end
local _autoTPUnlockDebounce = false
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            if AutoDefenseEnabled then
                for _, arg in ipairs({...}) do
                    if type(arg) == "string"and string.find(string.lower(arg), "stealing") then
                        defenseRunDefenseCommands(); break
                    end
                end
            end
            if SS.autoTPUnlockState and not _autoTPUnlockDebounce then
                for _, arg in ipairs({...}) do
                    if type(arg) == "string"and string.find(string.lower(arg), "you successfully broke", 1, true) then
                        _autoTPUnlockDebounce = true
                        task.spawn(function()
                            task.wait(0.20)
                            SS.SSExecute()
                            task.wait(1.5)
                            _autoTPUnlockDebounce = false
                        end)
                        break
                    end
                end
            end
        end)
    end
end
task.spawn(function()
    local STEAL_ATTRS = {"Stealing","steal","stolen","isStealing","IsSteal","issteal"}
    local function onWarnSoundFired()
        if not AutoDefenseEnabled then return end
        local target = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer then
                for _, attr in ipairs(STEAL_ATTRS) do
                    if plr:GetAttribute(attr) then
                        target = plr
                        break
                    end
                end
                if target then break end
            end
        end
        if target then
            task.spawn(function() defenseExecuteCommandsOnPlayer(target, {"balloon"}) end)
        end
    end
    local function tryConnectWarnSound(obj)
        if obj:IsA("Sound") and obj.Name:lower() == "warn"then
            obj.Played:Connect(onWarnSoundFired)
        end
    end
    task.spawn(function()
        task.wait(1)

        local _step = 0
        for _, desc in ipairs(game:GetDescendants()) do
            pcall(tryConnectWarnSound, desc)
            _step = _step + 1
            if _step % 500 == 0 then task.wait() end
        end
        game.DescendantAdded:Connect(function(obj) pcall(tryConnectWarnSound, obj) end)
    end)
end)
FD.W = isMobile and 170 or 200; FD.H = isMobile and 110 or 116
FD.minimized  = false
FD.dragging   = false
FD.dragStart  = nil
FD.panelStart = nil
FD.FDBorderFrame = Instance.new("Frame")
FD.FDBorderFrame.Name             = "FadedDefenseGradBorder"
FD.FDBorderFrame.Size             = UDim2.new(0, FD.W + 4, 0, FD.H + 4)
FD.FDBorderFrame.Position         = UDim2.new(1, -(FD.W + 4 + 16), 1, -(FD.H + 4 + FA.H + 36))
FD.FDBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FD.FDBorderFrame.BorderSizePixel  = 0
FD.FDBorderFrame.ZIndex           = 18
FD.FDBorderFrame.Visible          = false
FD.FDBorderFrame.Parent           = GUI
FD.FDBorderFrame.BackgroundTransparency = 1
Corner(FD.FDBorderFrame, 12)
FD.FDWin = Instance.new("Frame")
FD.FDWin.Name             = "FadedDefensePanel"
FD.FDWin.Size             = UDim2.new(0, FD.W, 0, FD.H)
FD.FDWin.Position         = UDim2.new(1, -(FD.W + 18), 1, -(FD.H + FA.H + 20))
FD.FDWin.BackgroundColor3 = T.BG
FD.FDWin.BackgroundTransparency = 0.25
FD.FDWin.BorderSizePixel  = 0
FD.FDWin.ZIndex           = 19
FD.FDWin.Visible          = false
FD.FDWin.ClipsDescendants = true
FD.FDWin.Parent           = GUI
Corner(FD.FDWin, 10)
FD.FDHdr = Instance.new("Frame")
FD.FDHdr.Size             = UDim2.new(1, 0, 0, 26)
FD.FDHdr.BackgroundColor3 = T.Card
FD.FDHdr.BackgroundTransparency = 0.2
FD.FDHdr.BorderSizePixel  = 0
FD.FDHdr.ZIndex           = 20
FD.FDHdr.Parent           = FD.FDWin
Corner(FD.FDHdr, 10)
FD.FDHdr.Active = true
FD.FDHdrFill = Instance.new("Frame")
FD.FDHdrFill.Size             = UDim2.new(1, 0, 0, 8)
FD.FDHdrFill.Position         = UDim2.new(0, 0, 1, -8)
FD.FDHdrFill.BackgroundColor3 = T.Card
FD.FDHdrFill.BackgroundTransparency = 0.2
FD.FDHdrFill.BorderSizePixel  = 0
FD.FDHdrFill.ZIndex           = 20
FD.FDHdrFill.Parent           = FD.FDHdr
FD.FDHdrLine = Instance.new("Frame")
FD.FDHdrLine.Size             = UDim2.new(1, 0, 0, 1)
FD.FDHdrLine.Position         = UDim2.new(0, 0, 1, -1)
FD.FDHdrLine.BackgroundColor3 = T.Border
FD.FDHdrLine.BorderSizePixel  = 0
FD.FDHdrLine.ZIndex           = 21
FD.FDHdrLine.Parent           = FD.FDHdr
FD.FDTitleLbl = Label(FD.FDHdr, "Faded Defense", 11, T.White, Enum.Font.GothamBold)
FD.FDTitleLbl.Size           = UDim2.new(1, -40, 1, 0)
FD.FDTitleLbl.Position       = UDim2.new(0, 12, 0, 0)
FD.FDTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
FD.FDTitleLbl.ZIndex         = 22
FD.FDMinBtn = Instance.new("TextButton")
FD.FDMinBtn.Size             = UDim2.new(0, 18, 0, 18)
FD.FDMinBtn.Position         = UDim2.new(1, -22, 0.5, -9)
FD.FDMinBtn.BackgroundColor3 = T.Card
FD.FDMinBtn.BorderSizePixel  = 0
FD.FDMinBtn.Text             = "\226\136\146"
FD.FDMinBtn.TextSize         = 13
FD.FDMinBtn.Font             = Enum.Font.GothamBold
FD.FDMinBtn.TextColor3       = T.White
FD.FDMinBtn.ZIndex           = 23
FD.FDMinBtn.Parent           = FD.FDHdr
Corner(FD.FDMinBtn, 6)
Stroke(FD.FDMinBtn, T.Border, 1)
FD.FDSettingsBtn = Instance.new("TextButton")
FD.FDSettingsBtn.Size             = UDim2.new(0, 18, 0, 18)
FD.FDSettingsBtn.Position         = UDim2.new(1, -44, 0.5, -9)
FD.FDSettingsBtn.BackgroundColor3 = T.Card
FD.FDSettingsBtn.BorderSizePixel  = 0
FD.FDSettingsBtn.Text             = "\226\154\153"
FD.FDSettingsBtn.TextSize         = 13
FD.FDSettingsBtn.Font             = Enum.Font.GothamBold
FD.FDSettingsBtn.TextColor3       = T.White
FD.FDSettingsBtn.ZIndex           = 23
FD.FDSettingsBtn.Parent           = FD.FDHdr
Corner(FD.FDSettingsBtn, 6)
Stroke(FD.FDSettingsBtn, T.Border, 1)
FD.FDScroll = Instance.new("Frame")
FD.FDScroll.Size                  = UDim2.new(1, 0, 1, -26)
FD.FDScroll.Position              = UDim2.new(0, 0, 0, 26)
FD.FDScroll.BackgroundTransparency = 1
FD.FDScroll.BorderSizePixel       = 0
FD.FDScroll.ClipsDescendants      = false
FD.FDScroll.ZIndex                = 19
FD.FDScroll.Parent                = FD.FDWin
do
    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 4)
    layout.Parent              = FD.FDScroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentH = layout.AbsoluteContentSize.Y + 14
        FD.H = 26 + contentH
        if FD.FDWin and FD.FDWin.Visible then
            FD.FDWin.Size             = UDim2.new(0, FD.W, 0, FD.H)
            FD.FDBorderFrame.Size     = UDim2.new(0, FD.W + 4, 0, FD.H + 4)
        end
    end)
    Padding(FD.FDScroll, 6, 6, 6, 6)
end
end)
local function FD_CreateToggle(name, desc, cb)
    local state   = (Config.toggles and Config.toggles[name] == true) or false
    local cardH   = 22
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -8, 0, cardH)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel  = 0
    card.Parent           = FD.FDScroll
    Corner(card, 6)
    local cStroke = Stroke(card, T.Border, 1)
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 2, 0, cardH - 8)
    bar.Position         = UDim2.new(0, 0, 0, 4)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 1)
    local nameLbl = Label(card, name, 10, T.White, Enum.Font.GothamMedium)
    nameLbl.Size          = UDim2.new(1, -30, 1, 0)
    nameLbl.Position      = UDim2.new(0, 8, 0, 0)
    nameLbl.ZIndex        = 2
    nameLbl.TextXAlignment= Enum.TextXAlignment.Left
    nameLbl.TextYAlignment= Enum.TextYAlignment.Center
    nameLbl.TextTruncate  = Enum.TextTruncate.AtEnd
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 28, 0, 16)
    track.Position         = UDim2.new(1, -24, 0.5, -6)
    track.BackgroundColor3 = T.TrackOff
    track.BorderSizePixel  = 0
    track.ZIndex           = 2
    track.Parent           = card
    Corner(track, 6)
    local tStroke = Stroke(track, T.Border, 1)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 12, 0, 12)
    knob.Position         = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = T.KnobOff
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 3
    knob.Parent           = track
    Corner(knob, 4)
    local _cardHov = false
    card.MouseEnter:Connect(function()
        if _cardHov then return end
        _cardHov = true
        Tween(card,    F, {BackgroundColor3 = T.CardHover})
        Tween(cStroke, F, {Color = T.BorderHover})
    end)
    card.MouseLeave:Connect(function()
        if not _cardHov then return end
        _cardHov = false
        Tween(card,    F, {BackgroundColor3 = T.Card})
        Tween(cStroke, F, {Color = T.Border})
    end)
    local btn = Instance.new("Frame")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.ZIndex                 = 4
    btn.Active                 = true
    btn.Parent                 = card
    local function fdApplyVisual(s)
        if s then
            knob.Size             = UDim2.new(0, 12, 0, 12)
            knob.Position         = UDim2.new(0, 14, 0.5, -6)
            knob.BackgroundColor3 = T.KnobOn
            track.BackgroundColor3 = T.TrackOn
            tStroke.Color         = T.TrackOn
            bar.BackgroundColor3  = T.White
        else
            knob.Size             = UDim2.new(0, 12, 0, 12)
            knob.Position         = UDim2.new(0, 2, 0.5, -6)
            knob.BackgroundColor3 = T.KnobOff
            track.BackgroundColor3 = T.TrackOff
            tStroke.Color         = T.Border
            bar.BackgroundColor3  = T.TrackOff
        end
    end
    local function doToggle()
        state = not state
        if state then
            Tween(knob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 14, 0.5, -6)})
            Tween(knob,    M, {BackgroundColor3 = T.KnobOn})
            Tween(track,   M, {BackgroundColor3 = T.TrackOn})
            Tween(tStroke, M, {Color = T.TrackOn})
            Tween(bar,     M, {BackgroundColor3 = T.White})
        else
            Tween(knob,    M, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6)})
            Tween(knob,    M, {BackgroundColor3 = T.KnobOff})
            Tween(track,   M, {BackgroundColor3 = T.TrackOff})
            Tween(tStroke, M, {Color = T.Border})
            Tween(bar,     M, {BackgroundColor3 = T.TrackOff})
        end
        if cb then pcall(cb, state) end
        Config.toggles[name] = state
        pcall(FH_SaveConfig)
    end
    do
        local _fdBtnTouchStart = nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                doToggle()
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                _fdBtnTouchStart = inp.Position
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _fdBtnTouchStart then
                local mag = (inp.Position - _fdBtnTouchStart).Magnitude
                _fdBtnTouchStart = nil
                if mag < 20 then doToggle() end
            end
        end)
    end
    configRegistry[name] = {
        getState   = function() return state end,
        getKeyCode = function() return nil end,
        setKeyCode = function() end,
        doToggle   = doToggle,
        setEnabled = function(v)
            state = v
            fdApplyVisual(v)
            if cb then pcall(cb, v) end
            Config.toggles[name] = v
            if not _G._FH_IsRestoring then pcall(FH_SaveConfig) end
        end,
    }
end
FD_CreateToggle("Enable Steal Protection", "Fires defense on steal events", function(state)
    AutoDefenseEnabled = state
end)
FD_CreateToggle("Anti Player Intruder", "Attacks players entering your base", function(state)
    AntiTPEnabled_state = state
    if state then startAntiIntruder() else stopAntiIntruder() end
end)

do
    local _skConn = nil
    local function _skIsCmdAvailable(cmdName)
        local lp = Players.LocalPlayer
        local ap = lp and lp.PlayerGui and lp.PlayerGui:FindFirstChild("AdminPanel")
        if not ap then return false end
        local inner = ap:FindFirstChild("AdminPanel"); if not inner then return false end
        local content = inner:FindFirstChild("Content"); if not content then return false end
        local sf = content:FindFirstChild("ScrollingFrame"); if not sf then return false end
        local f = sf:FindFirstChild(cmdName)
        if not f then return false end
        local t = f:FindFirstChild("Timer")
        if t and t.Visible == true then return false end
        return true
    end
    local function _skStart()
        if _skConn then return end
        _skConn = task.spawn(function()
            while kickNoCmdsEnabled do
                task.wait(1.5)
                if not kickNoCmdsEnabled then break end
                local balloonOK = _skIsCmdAvailable("balloon")
                local ragdollOK = _skIsCmdAvailable("ragdoll")
                if (not balloonOK) and (not ragdollOK) then
                    pcall(function()
                        Players.LocalPlayer:Kick("Safety Kick: balloon & ragdoll both unavailable")
                    end)
                    break
                end
            end
            _skConn = nil
        end)
    end
    local function _skStop()
        kickNoCmdsEnabled = false
        _skConn = nil
    end
    FD_CreateToggle("Safety Kick", "Kick if no leftover cmds.", function(state)
        kickNoCmdsEnabled = state
        if state then _skStart() else _skStop() end
    end)
end

;(function()
    local FD_AVAILABLE_CMDS = { "balloon", "jail", "tiny", "rocket", "ragdoll" }

    local function _split(s)
        local out = {}
        if type(s) ~= "string" then return out end
        for word in string.gmatch(s, "([^,%s]+)") do
            table.insert(out, word:lower())
        end
        return out
    end
    local function _join(t)
        return table.concat(t or {}, ",")
    end
    local function _setToList(set)
        local out = {}
        for _, name in ipairs(FD_AVAILABLE_CMDS) do
            if set[name] then table.insert(out, name) end
        end
        return out
    end
    local function _listToSet(list)
        local out = {}
        for _, n in ipairs(list or {}) do out[n] = true end
        return out
    end

    local savedP1     = _FH_SavedConfig and _FH_SavedConfig.sliders and _FH_SavedConfig.sliders.defense_cmds_p1
    local savedP2     = _FH_SavedConfig and _FH_SavedConfig.sliders and _FH_SavedConfig.sliders.defense_cmds_p2
    local legacy      = _FH_SavedConfig and _FH_SavedConfig.sliders and _FH_SavedConfig.sliders.defense_cmds
    local p1Set       = _listToSet(_split(savedP1 or legacy or "balloon,jail"))
    local p2Set       = _listToSet(_split(savedP2 or ""))

    for name in pairs(p1Set) do p2Set[name] = nil end

    local function publish()
        _G._FH_DefenseCmdsP1 = _setToList(p1Set)
        _G._FH_DefenseCmdsP2 = _setToList(p2Set)

        local merged = {}
        for _, n in ipairs(_G._FH_DefenseCmdsP1) do table.insert(merged, n) end
        for _, n in ipairs(_G._FH_DefenseCmdsP2) do table.insert(merged, n) end
        _G._FH_DefenseCmds = merged
        Config.sliders = Config.sliders or {}
        Config.sliders.defense_cmds_p1 = _join(_G._FH_DefenseCmdsP1)
        Config.sliders.defense_cmds_p2 = _join(_G._FH_DefenseCmdsP2)
        pcall(FH_SaveConfig)
    end
    publish()

    FD.FDSettings = Instance.new("Frame")
    FD.FDSettings.Size                  = UDim2.new(1, 0, 1, -26)
    FD.FDSettings.Position              = UDim2.new(0, 0, 0, 26)
    FD.FDSettings.BackgroundColor3      = T.BG
    FD.FDSettings.BackgroundTransparency = 0
    FD.FDSettings.BorderSizePixel       = 0
    FD.FDSettings.Visible               = false
    FD.FDSettings.ZIndex                = 30
    FD.FDSettings.Parent                = FD.FDWin

    local settingsHdr = Instance.new("Frame")
    settingsHdr.Size                  = UDim2.new(1, 0, 0, 30)
    settingsHdr.Position              = UDim2.new(0, 0, 0, 0)
    settingsHdr.BackgroundColor3      = T.Card
    settingsHdr.BackgroundTransparency = 0.35
    settingsHdr.BorderSizePixel       = 0
    settingsHdr.ZIndex                = 31
    settingsHdr.Parent                = FD.FDSettings
    Corner(settingsHdr, 6)
    do
        local hdrLine = Instance.new("Frame")
        hdrLine.Size                  = UDim2.new(1, -8, 0, 1)
        hdrLine.Position              = UDim2.new(0, 4, 1, -1)
        hdrLine.BackgroundColor3      = T.Border
        hdrLine.BackgroundTransparency = 0.5
        hdrLine.BorderSizePixel       = 0
        hdrLine.ZIndex                = 32
        hdrLine.Parent                = settingsHdr
    end

    local backBtn = Instance.new("TextButton")
    backBtn.Size             = UDim2.new(0, 54, 0, 20)
    backBtn.Position         = UDim2.new(0, 6, 0.5, -10)
    backBtn.BackgroundColor3 = T.Card
    backBtn.BorderSizePixel  = 0
    backBtn.Text             = "\226\134\144 Back"
    backBtn.TextSize         = 11
    backBtn.Font             = Enum.Font.GothamBold
    backBtn.TextColor3       = T.White
    backBtn.AutoButtonColor  = false
    backBtn.ZIndex           = 33
    backBtn.Parent           = settingsHdr
    Corner(backBtn, 5)
    local backStroke = Stroke(backBtn, T.Border, 1)
    backBtn.MouseEnter:Connect(function()
        Tween(backBtn,    F, {BackgroundColor3 = T.CardHover})
        Tween(backStroke, F, {Color = T.BorderHover})
    end)
    backBtn.MouseLeave:Connect(function()
        Tween(backBtn,    F, {BackgroundColor3 = T.Card})
        Tween(backStroke, F, {Color = T.Border})
    end)

    local sTitle = Label(settingsHdr, "Settings", 12, T.White, Enum.Font.GothamBold)
    sTitle.Size           = UDim2.new(1, -76, 1, 0)
    sTitle.Position       = UDim2.new(0, 66, 0, 0)
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.TextYAlignment = Enum.TextYAlignment.Center
    sTitle.TextTruncate   = Enum.TextTruncate.AtEnd
    sTitle.ZIndex         = 32

    local sScroll = Instance.new("ScrollingFrame")
    sScroll.Size                  = UDim2.new(1, -8, 1, -36)
    sScroll.Position              = UDim2.new(0, 4, 0, 32)
    sScroll.BackgroundTransparency = 1
    sScroll.BorderSizePixel       = 0
    sScroll.ScrollBarThickness    = 3
    sScroll.ScrollBarImageColor3  = T.Border
    sScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    sScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    sScroll.ScrollingDirection    = Enum.ScrollingDirection.Y
    sScroll.ZIndex                = 31
    sScroll.Parent                = FD.FDSettings
    local sLayout = Instance.new("UIListLayout")
    sLayout.Padding             = UDim.new(0, 5)
    sLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    sLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sLayout.Parent              = sScroll

    local rowRefs = {}

    local function applyLockState()
        for name, refs in pairs(rowRefs) do
            local p1Has = p1Set[name] == true
            local p2Has = p2Set[name] == true
            local function paint(prefix, has, locked)
                local row     = refs[prefix .. "Row"]
                if not row then return end
                local track   = refs[prefix .. "Track"]
                local knob    = refs[prefix .. "Knob"]
                local tStroke = refs[prefix .. "TStroke"]
                local lock    = refs[prefix .. "Lock"]
                local lbl     = refs[prefix .. "Lbl"]
                if locked then
                    row.BackgroundTransparency = 0.55
                    lbl.TextColor3             = T.Dim
                    lock.Visible               = true
                    track.Visible              = false
                else
                    row.BackgroundTransparency = 0.18
                    lbl.TextColor3             = T.White
                    lock.Visible               = false
                    track.Visible              = true
                    if has then
                        track.BackgroundColor3 = T.TrackOn
                        knob.BackgroundColor3  = T.KnobOn
                        knob.Position          = UDim2.new(1, -14, 0.5, -6)
                        tStroke.Color          = T.TrackOn
                    else
                        track.BackgroundColor3 = T.TrackOff
                        knob.BackgroundColor3  = T.KnobOff
                        knob.Position          = UDim2.new(0, 2, 0.5, -6)
                        tStroke.Color          = T.Border
                    end
                end
                refs[prefix .. "Locked"] = locked
            end
            paint("p1", p1Has, p2Has)
            paint("p2", p2Has, p1Has)
        end
    end

    local function addSectionHeader(text, order)
        local h = Instance.new("Frame")
        h.Name                  = "Section_" .. text
        h.Size                  = UDim2.new(1, -10, 0, 22)
        h.BackgroundTransparency = 1
        h.LayoutOrder           = order
        h.Parent                = sScroll
        local bar = Instance.new("Frame")
        bar.Size              = UDim2.new(0, 3, 0, 14)
        bar.Position          = UDim2.new(0, 2, 0.5, -7)
        bar.BackgroundColor3  = _G._FH_AccentA or Color3.fromRGB(120, 200, 255)
        bar.BorderSizePixel   = 0
        bar.Parent            = h
        Corner(bar, 2)
        local lbl = Label(h, text, isMobile and 11 or 12, T.White, Enum.Font.GothamBold)
        lbl.Size           = UDim2.new(1, -14, 1, 0)
        lbl.Position       = UDim2.new(0, 10, 0, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function addCmdRow(slot, cmdName, order)
        local row = Instance.new("Frame")
        row.Name                   = slot .. "_" .. cmdName
        row.Size                   = UDim2.new(1, -10, 0, isMobile and 30 or 28)
        row.BackgroundColor3       = T.Card
        row.BackgroundTransparency = 0.18
        row.BorderSizePixel        = 0
        row.LayoutOrder            = order
        row.Parent                 = sScroll
        Corner(row, 6)
        local rStroke = Stroke(row, T.Border, 1)

        local hit = Instance.new("TextButton")
        hit.Size                   = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text                   = ""
        hit.AutoButtonColor        = false
        hit.ZIndex                 = 2
        hit.Parent                 = row

        local lbl = Label(row, cmdName, isMobile and 11 or 12, T.White, Enum.Font.GothamMedium)
        lbl.Size           = UDim2.new(1, -54, 1, 0)
        lbl.Position       = UDim2.new(0, 10, 0, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 32, 0, 16)
        track.Position         = UDim2.new(1, -38, 0.5, -8)
        track.BackgroundColor3 = T.TrackOff
        track.BorderSizePixel  = 0
        track.ZIndex           = 3
        track.Parent           = row
        Corner(track, 8)
        local tStroke = Stroke(track, T.Border, 1)
        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 12, 0, 12)
        knob.Position         = UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = T.KnobOff
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 4
        knob.Parent           = track
        Corner(knob, 6)

        local lockLbl = Instance.new("TextLabel")
        lockLbl.Size                   = UDim2.new(0, 20, 0, 16)
        lockLbl.Position               = UDim2.new(1, -26, 0.5, -8)
        lockLbl.BackgroundTransparency = 1
        lockLbl.Text                   = "\240\159\148\146"
        lockLbl.TextSize               = 12
        lockLbl.Font                   = Enum.Font.Gotham
        lockLbl.TextColor3             = T.Dim
        lockLbl.Visible                = false
        lockLbl.ZIndex                 = 3
        lockLbl.Parent                 = row

        rowRefs[cmdName] = rowRefs[cmdName] or {}
        local refs = rowRefs[cmdName]
        refs[slot .. "Row"]     = row
        refs[slot .. "Track"]   = track
        refs[slot .. "Knob"]    = knob
        refs[slot .. "TStroke"] = tStroke
        refs[slot .. "Lock"]    = lockLbl
        refs[slot .. "Lbl"]     = lbl
        refs[slot .. "RStroke"] = rStroke

        local function doClick()
            if slot == "p1" then
                if refs.p1Locked then return end
                p1Set[cmdName] = (not p1Set[cmdName]) or nil
            else
                if refs.p2Locked then return end
                p2Set[cmdName] = (not p2Set[cmdName]) or nil
            end
            local on = (slot == "p1" and p1Set[cmdName]) or (slot == "p2" and p2Set[cmdName])
            local knobTween = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            if on then
                Tween(track,   F, {BackgroundColor3 = T.TrackOn})
                Tween(knob,    knobTween, {Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = T.KnobOn})
                Tween(tStroke, F, {Color = T.TrackOn})
            else
                Tween(track,   F, {BackgroundColor3 = T.TrackOff})
                Tween(knob,    knobTween, {Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = T.KnobOff})
                Tween(tStroke, F, {Color = T.Border})
            end
            applyLockState()
            publish()
        end
        hit.MouseButton1Click:Connect(doClick)
        hit.MouseEnter:Connect(function()
            if refs[slot .. "Locked"] then return end
            Tween(row,     F, {BackgroundColor3 = T.CardHover})
            Tween(rStroke, F, {Color = T.BorderHover})
        end)
        hit.MouseLeave:Connect(function()
            Tween(row,     F, {BackgroundColor3 = T.Card})
            Tween(rStroke, F, {Color = T.Border})
        end)
        do
            local touchStart = nil
            hit.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch then
                    touchStart = inp.Position
                end
            end)
            hit.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch and touchStart then
                    local mag = (inp.Position - touchStart).Magnitude
                    touchStart = nil
                    if mag < 20 then doClick() end
                end
            end)
        end
    end

    local order = 1
    addSectionHeader("Player 1 Commands", order); order = order + 1
    for _, name in ipairs(FD_AVAILABLE_CMDS) do
        addCmdRow("p1", name, order); order = order + 1
    end
    addSectionHeader("Player 2 Commands", order); order = order + 1
    for _, name in ipairs(FD_AVAILABLE_CMDS) do
        addCmdRow("p2", name, order); order = order + 1
    end
    applyLockState()

    local function openSettings()
        if FD.minimized then return end
        if FD.FDSettings.Visible then return end
        FD.FDSettings.Visible = true
        FD.FDScroll.Visible   = false

        local targetH = math.max(FD.H, 320)
        FD.H = targetH
        FD.FDWin.Size         = UDim2.new(0, FD.W, 0, targetH)
        FD.FDBorderFrame.Size = UDim2.new(0, FD.W + 4, 0, targetH + 4)
    end
    local function closeSettings()
        if not FD.FDSettings.Visible then return end
        FD.FDSettings.Visible = false
        if FD.minimized then return end
        FD.FDScroll.Visible = true

        local scrollLayout = FD.FDScroll:FindFirstChildOfClass("UIListLayout")
        local naturalH = (scrollLayout and scrollLayout.AbsoluteContentSize.Y or 0) + 20 + 26
        FD.H = naturalH
        FD.FDWin.Size         = UDim2.new(0, FD.W, 0, naturalH)
        FD.FDBorderFrame.Size = UDim2.new(0, FD.W + 4, 0, naturalH + 4)
    end
    FD.FDSettingsBtn.MouseButton1Click:Connect(openSettings)
    backBtn.MouseButton1Click:Connect(closeSettings)

    FD.FDMinBtn.MouseButton1Click:Connect(function()
        if FD.FDSettings.Visible then closeSettings() end
    end)
end)()
do
    FD.FDHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            FD.dragging   = true
            FD.dragStart  = inp.Position
            FD.panelStart = FD.FDWin.Position
        end
    end)
    FD.FDHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            FD.dragging = false
            Config.mini = Config.mini or {}
            Config.mini.fd_pos = { x = FD.FDWin.Position.X.Offset, y = FD.FDWin.Position.Y.Offset,
                                   xs = FD.FDWin.Position.X.Scale, ys = FD.FDWin.Position.Y.Scale }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if FD.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - FD.dragStart
            local newPos = UDim2.new(
                FD.panelStart.X.Scale, FD.panelStart.X.Offset + d.X,
                FD.panelStart.Y.Scale, FD.panelStart.Y.Offset + d.Y
            )
            FD.FDWin.Position         = newPos
            FD.FDBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
        end
    end)
end
FD.FDMinBtn.MouseButton1Click:Connect(function()
    FD.minimized = not FD.minimized
    if FD.minimized then
        FD.FDWin.ClipsDescendants = false
        FD.FDHdrFill.Visible = false
        FD.FDHdrLine.Visible = false
        FD.FDScroll.Visible  = false
        Tween(FD.FDWin,         M, {Size = UDim2.new(0, FD.W, 0, 26)})
        Tween(FD.FDBorderFrame, M, {Size = UDim2.new(0, FD.W + 4, 0, 30)})
        FD.FDMinBtn.Text = "+"else
        FD.FDHdrFill.Visible = true
        FD.FDHdrLine.Visible = true
        Tween(FD.FDWin,         M, {Size = UDim2.new(0, FD.W, 0, FD.H)})
        Tween(FD.FDBorderFrame, M, {Size = UDim2.new(0, FD.W + 4, 0, FD.H + 4)})
        FD.FDMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            FD.FDScroll.Visible = true
            FD.FDWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.fd_min = FD.minimized
        pcall(FH_SaveConfig)
    end
end)
FD.setFadedDefenseVisible = function(vis)
    FD.FDWin.Visible         = vis
    FD.FDBorderFrame.Visible = vis
    if vis then
        local p = FD.FDWin.Position
        FD.FDBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if FD.minimized then
            FD.FDMinBtn.Text      = "+"
FD.FDScroll.Visible   = false
            FD.FDHdrFill.Visible  = false
            FD.FDHdrLine.Visible  = false
            FD.FDWin.ClipsDescendants = false
            FD.FDWin.Size         = UDim2.new(0, FD.W, 0, 26)
            FD.FDBorderFrame.Size = UDim2.new(0, FD.W + 4, 0, 40)
        else
            FD.FDMinBtn.Text      = "\226\136\146"
FD.FDScroll.Visible   = true
            FD.FDHdrFill.Visible  = true
            FD.FDHdrLine.Visible  = true
            FD.FDWin.ClipsDescendants = true
            FD.FDWin.Size         = UDim2.new(0, FD.W, 0, FD.H)
            FD.FDBorderFrame.Size = UDim2.new(0, FD.W + 4, 0, FD.H + 4)
        end
    end
end

local function _qpVPx()
    local cam = workspace.CurrentCamera
    return (cam and cam.ViewportSize and cam.ViewportSize.X) or 800
end
local function _qpVPy()
    local cam = workspace.CurrentCamera
    return (cam and cam.ViewportSize and cam.ViewportSize.Y) or 600
end
function QP.computeMetrics()
    local vpx, vpy = _qpVPx(), _qpVPy()
    if isMobile then
        local w = math.clamp(math.floor(vpx - 32), 220, 440)
        QP.W       = w
        QP.H       = 64
        QP.ROW_H   = 38
        QP.EXPANDED_H = math.clamp(math.floor(vpy * 0.5), 140, 220)
    else
        QP.W       = 410
        QP.H       = 76
        QP.ROW_H   = 46
        QP.EXPANDED_H = 260
    end
end
QP.computeMetrics()
QP.minimized  = false
QP.dragging   = false
QP.dragStart  = nil
QP.panelStart = nil
;(function()
local QP_CMDS = {
    { name = "tiny",    emoji = "\xF0\x9F\xA4\x8F"},
    { name = "jail",    emoji = "\xF0\x9F\x94\x92"},
    { name = "rocket",  emoji = "\xF0\x9F\x9A\x80"},
    { name = "ragdoll", emoji = "\xF0\x9F\x8F\x83"},
    { name = "balloon", emoji = "\xF0\x9F\x8E\x88"},
}
local QP_cooldownBtns = {}
for _, c in ipairs(QP_CMDS) do QP_cooldownBtns[c.name] = {} end
local QP_commandCache = {}
local QP_profileCache = {}
QP.QPBorderFrame = Instance.new("Frame")
QP.QPBorderFrame.Name             = "QuickPanelGradBorder"
QP.QPBorderFrame.Size             = UDim2.new(0, QP.W + 4, 0, QP.H + 4)
QP.QPBorderFrame.Position         = UDim2.new(0, 14, 0.55, -2)
QP.QPBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
QP.QPBorderFrame.BorderSizePixel  = 0
QP.QPBorderFrame.ZIndex           = 18
QP.QPBorderFrame.Visible          = false
QP.QPBorderFrame.Parent           = GUI
QP.QPBorderFrame.BackgroundTransparency = 1
Corner(QP.QPBorderFrame, 12)
QP.QPWin = Instance.new("Frame")
QP.QPWin.Name             = "QuickPanel"
QP.QPWin.Size             = UDim2.new(0, QP.W, 0, QP.H)
QP.QPWin.Position         = UDim2.new(0, 16, 0.55, 0)
QP.QPWin.BackgroundColor3 = T.BG
QP.QPWin.BorderSizePixel  = 0
QP.QPWin.ZIndex           = 19
QP.QPWin.Visible          = false
QP.QPWin.ClipsDescendants = true
QP.QPWin.Parent           = GUI
QP.QPWin.BackgroundTransparency = 0.25
Corner(QP.QPWin, 10)
QP.QPHdr = Instance.new("Frame")
QP.QPHdr.Size             = UDim2.new(1, 0, 0, 28)
QP.QPHdr.BackgroundColor3 = T.Header
QP.QPHdr.BorderSizePixel  = 0
QP.QPHdr.ZIndex           = 20
QP.QPHdr.Parent           = QP.QPWin
QP.QPHdr.BackgroundTransparency = 0.2
Corner(QP.QPHdr, 10)
QP.QPHdr.Active = true
QP.QPHdrFill = Instance.new("Frame")
QP.QPHdrFill.Size             = UDim2.new(1, 0, 0, 10)
QP.QPHdrFill.Position         = UDim2.new(0, 0, 1, -10)
QP.QPHdrFill.BackgroundColor3       = T.Header
QP.QPHdrFill.BackgroundTransparency = 0.2
QP.QPHdrFill.BorderSizePixel        = 0
QP.QPHdrFill.ZIndex           = 20
QP.QPHdrFill.Parent           = QP.QPHdr
QP.QPHdrLine = Instance.new("Frame")
QP.QPHdrLine.Size             = UDim2.new(1, 0, 0, 1)
QP.QPHdrLine.Position         = UDim2.new(0, 0, 1, -1)
QP.QPHdrLine.BackgroundColor3 = T.Border
QP.QPHdrLine.BorderSizePixel  = 0
QP.QPHdrLine.ZIndex           = 21
QP.QPHdrLine.Parent           = QP.QPHdr
do
local QPTitleLbl = Label(QP.QPHdr, "Quick Panel", 11, T.White, Enum.Font.GothamBold)
QPTitleLbl.Size           = UDim2.new(1, -40, 1, 0)
QPTitleLbl.Position       = UDim2.new(0, 12, 0, 0)
QPTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
QPTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
QPTitleLbl.ZIndex         = 22
end
QP.QPMinBtn = Instance.new("TextButton")
QP.QPMinBtn.Size             = UDim2.new(0, 18, 0, 18)
QP.QPMinBtn.Position         = UDim2.new(1, -24, 0.5, -9)
QP.QPMinBtn.BackgroundColor3 = T.Card
QP.QPMinBtn.BorderSizePixel  = 0
QP.QPMinBtn.Text             = "\226\136\146"
QP.QPMinBtn.TextSize         = 14
QP.QPMinBtn.Font             = Enum.Font.GothamBold
QP.QPMinBtn.TextColor3       = T.White
QP.QPMinBtn.ZIndex           = 23
QP.QPMinBtn.Parent           = QP.QPHdr
Corner(QP.QPMinBtn, 6)
Stroke(QP.QPMinBtn, T.Border, 1)
QP.QPScroll = Instance.new("ScrollingFrame")
QP.QPScroll.Size                  = UDim2.new(1, -12, 1, -34)
QP.QPScroll.Position              = UDim2.new(0, 6, 0, 32)
QP.QPScroll.BackgroundTransparency = 1
QP.QPScroll.BorderSizePixel       = 0
QP.QPScroll.ScrollBarThickness    = 3
QP.QPScroll.ScrollBarImageColor3  = T.Border
QP.QPScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
QP.QPScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
QP.QPScroll.ScrollingDirection    = Enum.ScrollingDirection.Y
QP.QPScroll.ZIndex                = 19
QP.QPScroll.Parent                = QP.QPWin
QP.QPLayout = Instance.new("UIListLayout")
QP.QPLayout.Padding             = UDim.new(0, 3)
QP.QPLayout.SortOrder           = Enum.SortOrder.LayoutOrder
QP.QPLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
QP.QPLayout.Parent              = QP.QPScroll
QP.QPLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    QP.QPScroll.CanvasSize = UDim2.new(0, 0, 0, QP.QPLayout.AbsoluteContentSize.Y + 6)
end)
Padding(QP.QPScroll, 4, 4, 0, 0)
QP.QPNoTarget = Instance.new("TextLabel")
QP.QPNoTarget.Size                   = UDim2.new(1, -20, 0, 24)
QP.QPNoTarget.Position               = UDim2.new(0, 10, 0, 34)
QP.QPNoTarget.BackgroundTransparency = 1
QP.QPNoTarget.Text                   = "No players found"
QP.QPNoTarget.Font                   = Enum.Font.GothamMedium
QP.QPNoTarget.TextColor3             = T.Dim
QP.QPNoTarget.TextSize               = 12
QP.QPNoTarget.TextXAlignment         = Enum.TextXAlignment.Center
QP.QPNoTarget.Visible                = true
QP.QPNoTarget.ZIndex                 = 20
QP.QPNoTarget.Parent                 = QP.QPWin
local function qpGetAdminSF()
    local ok, sf = pcall(function()
        return Players.LocalPlayer.PlayerGui.AdminPanel.AdminPanel.Content.ScrollingFrame
    end)
    return ok and sf or nil
end
local function qpIsOnCooldown(cmdName)
    local sf = qpGetAdminSF()
    if not sf then return false end
    local f = sf:FindFirstChild(cmdName)
    if not f then return false end
    local t = f:FindFirstChild("Timer")
    return t and t.Visible == true
end
local function qpGetCDText(cmdName)
    local sf = qpGetAdminSF()
    if not sf then return nil end
    local f = sf:FindFirstChild(cmdName)
    if not f then return nil end
    local t = f:FindFirstChild("Timer")
    if not t or not t.Visible then return nil end
    return t.Text or ""
    end
local qpCDRunning = false
local function qpStartCDLoop()
    if qpCDRunning then return end
    qpCDRunning = true
    task.spawn(function()
        while QP.QPWin and QP.QPWin.Parent and QP.QPWin.Visible do
            for _, cmd in ipairs(QP_CMDS) do
                local onCD = qpIsOnCooldown(cmd.name)
                local txt  = onCD and qpGetCDText(cmd.name) or nil
                for _, entry in ipairs(QP_cooldownBtns[cmd.name]) do
                    local btn, emoji = entry[1], entry[2]
                    if btn and btn.Parent then
                        if onCD and txt then
                            btn.Text                   = txt
                            btn.TextSize               = 9
                            btn.TextColor3             = Color3.fromRGB(160, 160, 160)
                            btn.BackgroundTransparency = 0.55
                        else
                            btn.Text                   = emoji
                            btn.TextSize               = isMobile and 14 or 18
                            btn.TextColor3             = T.White
                            btn.BackgroundTransparency = 0.3
                        end
                    end
                end
            end
            task.wait(0.25)
        end
        qpCDRunning = false
    end)
end
local function qpGetAdminFrames()
    local ap = Players.LocalPlayer.PlayerGui:FindFirstChild("AdminPanel")
    if not ap then return nil, nil end
    local inner = ap:FindFirstChild("AdminPanel")
    if not inner then return nil, nil end
    local content  = inner:FindFirstChild("Content")
    local profiles = inner:FindFirstChild("Profiles")
    if not content or not profiles then return nil, nil end
    return content:FindFirstChild("ScrollingFrame"), profiles:FindFirstChild("ScrollingFrame")
end
local function qpCacheActivated(guiObj)
    local cached = {}
    local ok, conns = pcall(getconnections, guiObj.Activated)
    if ok and type(conns) == "table"then
        for _, conn in ipairs(conns) do
            if type(conn.Function) == "function"then
                table.insert(cached, conn.Function)
            end
        end
    end
    return cached
end
local function qpFireActivated(cached)
    for _, fn in ipairs(cached) do task.spawn(fn) end
end
local function qpRunCommand(cmdName, target)
    local cmdFrame, profileFrame = qpGetAdminFrames()
    if not cmdFrame or not profileFrame then return end
    local profileBtn = profileFrame:FindFirstChild(target.Name)
    local commandBtn = cmdFrame:FindFirstChild(cmdName)
    if not profileBtn or not commandBtn then return end
    if not QP_profileCache[target.Name] then
        QP_profileCache[target.Name] = qpCacheActivated(profileBtn)
    end
    if not QP_commandCache[cmdName] then
        QP_commandCache[cmdName] = qpCacheActivated(commandBtn)
    end
    qpFireActivated(QP_profileCache[target.Name])
    task.wait()
    qpFireActivated(QP_commandCache[cmdName])
end
local function qpMakeRow(plr, order)
    local row = Instance.new("Frame")
    row.Name                   = "QP_".. plr.Name
    row.Size                   = UDim2.new(1, -8, 0, QP.ROW_H)
    row.BackgroundColor3       = T.Card
    row.BackgroundTransparency = isMobile and 0.35 or 0.15
    row.BorderSizePixel        = 0
    row.LayoutOrder            = order
    row.ZIndex                 = 20
    row.Parent                 = QP.QPScroll
    Corner(row, 6)
    Stroke(row, T.Border, 1)
    local displayName = plr.DisplayName
    local userName    = "@" .. plr.Name
    local avSz = isMobile and 20 or 28
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size             = UDim2.new(0, avSz, 0, avSz)
    avatarFrame.Position         = UDim2.new(0, 4, 0.5, -avSz/2)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatarFrame.BorderSizePixel  = 0
    avatarFrame.ZIndex           = 21
    avatarFrame.Parent           = row
    Corner(avatarFrame, 4)
    Stroke(avatarFrame, T.Border, 1)
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and img then
            local imgLbl = Instance.new("ImageLabel")
            imgLbl.Size             = UDim2.new(1, 0, 1, 0)
            imgLbl.Image            = img
            imgLbl.BackgroundTransparency = 1
            imgLbl.ZIndex           = 22
            imgLbl.Parent           = avatarFrame
            Corner(imgLbl, 4)
        end
    end)

    local BTN_SZ  = isMobile and 30 or 40
    local BTN_GAP = isMobile and 3 or 5
    local BTN_COUNT  = #QP_CMDS
    local btnsW      = BTN_COUNT * BTN_SZ + (BTN_COUNT - 1) * BTN_GAP
    local rightPad   = 4
    local btnsHolder = Instance.new("Frame")
    btnsHolder.Name                   = "QPCmds"
    btnsHolder.BackgroundTransparency = 1
    btnsHolder.Size                   = UDim2.new(0, btnsW, 0, BTN_SZ)
    btnsHolder.Position               = UDim2.new(1, -(btnsW + rightPad), 0.5, -BTN_SZ / 2)
    btnsHolder.ZIndex                 = 21
    btnsHolder.Parent                 = row
    local btnsLayout = Instance.new("UIListLayout")
    btnsLayout.FillDirection         = Enum.FillDirection.Horizontal
    btnsLayout.Padding               = UDim.new(0, BTN_GAP)
    btnsLayout.HorizontalAlignment   = Enum.HorizontalAlignment.Right
    btnsLayout.VerticalAlignment     = Enum.VerticalAlignment.Center
    btnsLayout.SortOrder             = Enum.SortOrder.LayoutOrder
    btnsLayout.Parent                = btnsHolder
    local nameLeft = avSz + 6
    local nameW    = math.max(40, QP.W - nameLeft - btnsW - rightPad - 8)
    local nameLbl  = Label(row, displayName, isMobile and 10 or 12, T.White, Enum.Font.GothamBold)
    nameLbl.Size           = UDim2.new(0, nameW, 0.55, 0)
    nameLbl.Position       = UDim2.new(0, nameLeft, 0, 1)
    nameLbl.TextTruncate   = Enum.TextTruncate.AtEnd
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextYAlignment = Enum.TextYAlignment.Bottom
    nameLbl.ZIndex         = 21
    local userLbl  = Label(row, userName, isMobile and 8 or 10, T.Dim, Enum.Font.Gotham)
    userLbl.Size           = UDim2.new(0, nameW, 0.45, 0)
    userLbl.Position       = UDim2.new(0, nameLeft, 0.55, -1)
    userLbl.TextTruncate   = Enum.TextTruncate.AtEnd
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.TextYAlignment = Enum.TextYAlignment.Top
    userLbl.ZIndex         = 21
    for i, cmd in ipairs(QP_CMDS) do
        local btn = Instance.new("TextButton")
        btn.Name                   = "QPCmd_".. cmd.name
        btn.Size                   = UDim2.new(0, BTN_SZ, 0, BTN_SZ)
        btn.LayoutOrder            = i
        btn.Parent                 = btnsHolder
        btn.BackgroundColor3       = T.Card
        btn.BackgroundTransparency = 0.3
        btn.Text                   = cmd.emoji
        btn.TextSize               = isMobile and 14 or 18
        btn.Font                   = Enum.Font.SourceSans
        btn.TextColor3             = T.White
        btn.AutoButtonColor        = false
        btn.ZIndex                 = 21
        Corner(btn, 4)
        Stroke(btn, T.Border, 1)
        table.insert(QP_cooldownBtns[cmd.name], { btn, cmd.emoji })
        btn.MouseEnter:Connect(function()
            if not qpIsOnCooldown(cmd.name) then
                Tween(btn, F, { BackgroundTransparency = 0, BackgroundColor3 = T.CardHover })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not qpIsOnCooldown(cmd.name) then
                Tween(btn, F, { BackgroundTransparency = 0.3, BackgroundColor3 = T.Card })
            end
        end)
        local function fire()
            if qpIsOnCooldown(cmd.name) then return end
            task.spawn(function() qpRunCommand(cmd.name, plr) end)
            Tween(btn, F, { BackgroundColor3 = T.Border })
            task.delay(0.2, function() Tween(btn, F, { BackgroundColor3 = T.Card }) end)
        end
        local qpBtnDebounce = false
        local function fireSafe()
            if qpBtnDebounce then return end
            qpBtnDebounce = true
            fire()
            task.delay(0.35, function() qpBtnDebounce = false end)
        end
        if not isMobile then
            btn.MouseButton1Click:Connect(fireSafe)
        end
        do
            local _qpBtnTouchStart = nil
            btn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch then
                    _qpBtnTouchStart = inp.Position
                end
            end)
            btn.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch and _qpBtnTouchStart then
                    local mag = (inp.Position - _qpBtnTouchStart).Magnitude
                    _qpBtnTouchStart = nil
                    if mag < 10 then fireSafe() end
                end
            end)
        end
    end
    return row
end
local function qpResizeToFit()
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then count = count + 1 end
    end
    local HDR      = 28
    local PAD      = 8
    local SPACING  = 3
    local rowH     = QP.ROW_H
    local maxH     = QP.EXPANDED_H
    local minH     = QP.H
    local targetH
    if count == 0 then
        targetH = minH
    else
        targetH = HDR + PAD + count * rowH + math.max(0, count - 1) * SPACING
        targetH = math.max(minH, math.min(maxH, targetH))
    end
    if math.abs(QP.QPWin.Size.Y.Offset - targetH) > 2 then
        Tween(QP.QPWin,         M, { Size = UDim2.new(0, QP.W, 0, targetH) })
        Tween(QP.QPBorderFrame, M, { Size = UDim2.new(0, QP.W + 4, 0, targetH + 4) })
    end
end
local function qpRefresh()
    for _, c in ipairs(QP_CMDS) do QP_cooldownBtns[c.name] = {} end
    for _, child in ipairs(QP.QPScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local order = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            qpMakeRow(plr, order)
            order = order + 1
        end
    end
    QP.QPNoTarget.Visible = (order == 1)
    QP.QPScroll.CanvasSize = UDim2.new(0, 0, 0, QP.QPLayout.AbsoluteContentSize.Y + 6)
    qpResizeToFit()
    qpStartCDLoop()
end
Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    if QP.QPWin.Visible then
        qpRefresh()
    end
end)
Players.PlayerRemoving:Connect(function(plr)
    QP_profileCache[plr.Name] = nil
    task.wait(0.3)
    if QP.QPWin.Visible then qpRefresh() end
end)

do
    local _qpResizeJob = 0
    local function _qpOnViewportChanged()
        _qpResizeJob = _qpResizeJob + 1
        local myJob = _qpResizeJob
        task.delay(0.05, function()
            if myJob ~= _qpResizeJob then return end
            QP.computeMetrics()
            local W, H = QP.W, QP.H
            QP.QPWin.Size         = UDim2.new(0, W, 0, QP.minimized and 28 or H)
            QP.QPBorderFrame.Size = UDim2.new(0, W + 4, 0, (QP.minimized and 28 or H) + 4)

            local vpx, vpy = _qpVPx(), _qpVPy()
            local p = QP.QPWin.Position
            local ax = p.X.Scale * vpx + p.X.Offset
            local ay = p.Y.Scale * vpy + p.Y.Offset
            local pad = 4
            if ax < pad then ax = pad end
            if ay < pad then ay = pad end
            if ax > vpx - W - pad then ax = vpx - W - pad end
            if ay > vpy - H - pad then ay = vpy - H - pad end
            QP.QPWin.Position         = UDim2.new(0, ax, 0, ay)
            QP.QPBorderFrame.Position = UDim2.new(0, ax - 2, 0, ay - 2)
            if QP.QPWin.Visible and not QP.minimized then qpRefresh() end
            Config.mini = Config.mini or {}
            Config.mini.qp_pos = { x = ax, y = ay, xs = 0, ys = 0 }
            pcall(FH_SaveConfig)
        end)
    end
    local function _qpHookCamera()
        local cam = workspace.CurrentCamera
        if not cam then return end
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(_qpOnViewportChanged)
    end
    _qpHookCamera()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(_qpHookCamera)
end
QP.QPHdr.InputBegan:Connect(function(inp)
    if _G._FH_GUI_LOCKED then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        QP.dragging   = true
        QP.dragStart  = inp.Position
        QP.panelStart = QP.QPWin.Position
    end
end)
QP.QPHdr.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        QP.dragging = false
        Config.mini = Config.mini or {}
        Config.mini.qp_pos = { x = QP.QPWin.Position.X.Offset, y = QP.QPWin.Position.Y.Offset,
                               xs = QP.QPWin.Position.X.Scale, ys = QP.QPWin.Position.Y.Scale }
        pcall(FH_SaveConfig)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if QP.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - QP.dragStart
        local newPos = UDim2.new(
            QP.panelStart.X.Scale, QP.panelStart.X.Offset + d.X,
            QP.panelStart.Y.Scale, QP.panelStart.Y.Offset + d.Y
        )
        QP.QPWin.Position         = newPos
        QP.QPBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
    end
end)
QP.QPMinBtn.MouseButton1Click:Connect(function()
    QP.minimized = not QP.minimized
    if QP.minimized then
        QP.QPWin.ClipsDescendants = false
        QP.QPHdrFill.Visible  = false
        QP.QPHdrLine.Visible  = false
        QP.QPScroll.Visible   = false
        QP.QPNoTarget.Visible = false
        Tween(QP.QPWin,         M, { Size = UDim2.new(0, QP.W, 0, 28) })
        Tween(QP.QPBorderFrame, M, { Size = UDim2.new(0, QP.W + 4, 0, 32) })
        QP.QPMinBtn.Text = "+"
    else
        QP.QPMinBtn.Text = "\226\136\146"
        QP.QPHdrFill.Visible = true
        QP.QPHdrLine.Visible = true
        QP.QPScroll.Visible = true
        QP.QPWin.ClipsDescendants = true
        Tween(QP.QPWin,         M, { Size = UDim2.new(0, QP.W, 0, QP.H) })
        Tween(QP.QPBorderFrame, M, { Size = UDim2.new(0, QP.W + 4, 0, QP.H + 4) })
        task.defer(qpRefresh)
    end
    Config.mini = Config.mini or {}
    Config.mini.qp_min = QP.minimized
    pcall(FH_SaveConfig)
end)
QP.setQuickPanelVisible = function(vis)
    QP.QPWin.Visible         = vis
    QP.QPBorderFrame.Visible = vis
    if vis then
        local p = QP.QPWin.Position
        QP.QPBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if QP.minimized then
            QP.QPMinBtn.Text          = "+"
QP.QPScroll.Visible       = false
            QP.QPHdrFill.Visible      = false
            QP.QPHdrLine.Visible      = false
            QP.QPWin.ClipsDescendants = false
            QP.QPWin.Size             = UDim2.new(0, QP.W, 0, 28)
            QP.QPBorderFrame.Size     = UDim2.new(0, QP.W + 4, 0, 32)
        else
            QP.QPMinBtn.Text          = "\226\136\146"
QP.QPScroll.Visible       = true
            QP.QPHdrFill.Visible      = true
            QP.QPHdrLine.Visible      = true
            QP.QPWin.ClipsDescendants = true
            QP.QPWin.Size             = UDim2.new(0, QP.W, 0, QP.H)
            QP.QPBorderFrame.Size     = UDim2.new(0, QP.W + 4, 0, QP.H + 4)
            task.defer(qpRefresh)
        end
    end
end
end)()
CD.W = isMobile and 122 or 169; CD.H = isMobile and 188 or 254
CD.minimized  = false
CD.dragging   = false
CD.dragStart  = nil
CD.panelStart = nil
do
local CD_CMDS = {
    { name = "rocket",    display = "Rocket",    inGame = "rocket"},
    { name = "ragdoll",   display = "Ragdoll",   inGame = "ragdoll"},
    { name = "balloon",   display = "Balloon",   inGame = "balloon"},
    { name = "inverse",   display = "Inverse",   inGame = "inverse"},
    { name = "jail",      display = "Jail",      inGame = "jail"},
    { name = "control",   display = "Control",   inGame = "control"},
    { name = "titty",     display = "Titty",     inGame = "tiny"},
    { name = "jumpscare", display = "Jumpscare", inGame = "jumpscare"},
    { name = "morph",     display = "Morph",     inGame = "morph"},
}
CD.CDBorderFrame = Instance.new("Frame")
CD.CDBorderFrame.Name             = "CDGradBorder"
CD.CDBorderFrame.Size             = UDim2.new(0, CD.W + 4, 0, CD.H + 4)
CD.CDBorderFrame.Position         = UDim2.new(1, -(CD.W + 4 + FD.W + 36), 1, -(CD.H + 4 + FA.H + 36))
CD.CDBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CD.CDBorderFrame.BorderSizePixel  = 0
CD.CDBorderFrame.ZIndex           = 18
CD.CDBorderFrame.Visible          = false
CD.CDBorderFrame.Parent           = GUI
CD.CDBorderFrame.BackgroundTransparency = 1
Corner(CD.CDBorderFrame, 12)
CD.CDWin = Instance.new("Frame")
CD.CDWin.Name             = "CDPanel"
CD.CDWin.Size             = UDim2.new(0, CD.W, 0, CD.H)
CD.CDWin.Position         = UDim2.new(1, -(CD.W + FD.W + 20 + 18), 1, -(CD.H + FA.H + 20))
CD.CDWin.BackgroundColor3 = T.BG
CD.CDWin.BackgroundTransparency = 0.25
CD.CDWin.BorderSizePixel  = 0
CD.CDWin.ZIndex           = 19
CD.CDWin.Visible          = false
CD.CDWin.ClipsDescendants = true
CD.CDWin.Parent           = GUI
Corner(CD.CDWin, 10)
CD.CDHdr = Instance.new("Frame")
CD.CDHdr.Size             = UDim2.new(1, 0, 0, 36)
CD.CDHdr.BackgroundColor3 = T.Header
CD.CDHdr.BackgroundTransparency = 0.2
CD.CDHdr.BorderSizePixel  = 0
CD.CDHdr.ZIndex           = 20
CD.CDHdr.Parent           = CD.CDWin
Corner(CD.CDHdr, 10)
CD.CDHdr.Active = true
CD.CDHdrFill = Instance.new("Frame")
CD.CDHdrFill.Size             = UDim2.new(1, 0, 0, 10)
CD.CDHdrFill.Position         = UDim2.new(0, 0, 1, -10)
CD.CDHdrFill.BackgroundColor3 = T.Header
CD.CDHdrFill.BackgroundTransparency = 0.2
CD.CDHdrFill.BorderSizePixel  = 0
CD.CDHdrFill.ZIndex           = 20
CD.CDHdrFill.Parent           = CD.CDHdr
CD.CDHdrLine = Instance.new("Frame")
CD.CDHdrLine.Size             = UDim2.new(1, 0, 0, 1)
CD.CDHdrLine.Position         = UDim2.new(0, 0, 1, -1)
CD.CDHdrLine.BackgroundColor3 = T.Border
CD.CDHdrLine.BorderSizePixel  = 0
CD.CDHdrLine.ZIndex           = 21
CD.CDHdrLine.Parent           = CD.CDHdr
local CDTitleLbl = Label(CD.CDHdr, "Command Cooldowns", 12, T.White, Enum.Font.GothamBold)
CDTitleLbl.Size           = UDim2.new(1, -40, 1, 0)
CDTitleLbl.Position       = UDim2.new(0, 12, 0, 0)
CDTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
CDTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
CDTitleLbl.ZIndex         = 22
CD.CDMinBtn = Instance.new("TextButton")
CD.CDMinBtn.Size             = UDim2.new(0, 22, 0, 22)
CD.CDMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
CD.CDMinBtn.BackgroundColor3 = T.Card
CD.CDMinBtn.BorderSizePixel  = 0
CD.CDMinBtn.Text             = "\226\136\146"
CD.CDMinBtn.TextSize         = 13
CD.CDMinBtn.Font             = Enum.Font.GothamBold
CD.CDMinBtn.TextColor3       = T.White
CD.CDMinBtn.ZIndex           = 23
CD.CDMinBtn.Parent           = CD.CDHdr
Corner(CD.CDMinBtn, 6)
Stroke(CD.CDMinBtn, T.Border, 1)
CD.CDScroll = Instance.new("ScrollingFrame")
CD.CDScroll.Size                   = UDim2.new(1, 0, 1, -36)
CD.CDScroll.Position               = UDim2.new(0, 0, 0, 36)
CD.CDScroll.BackgroundTransparency = 1
CD.CDScroll.BorderSizePixel        = 0
CD.CDScroll.ScrollBarThickness     = 3
CD.CDScroll.ScrollBarImageColor3   = Color3.fromRGB(75, 75, 75)
CD.CDScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
CD.CDScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
CD.CDScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
CD.CDScroll.ZIndex                 = 19
CD.CDScroll.Parent                 = CD.CDWin
do
    local cdLayout = Instance.new("UIListLayout")
    cdLayout.FillDirection       = Enum.FillDirection.Vertical
    cdLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cdLayout.Padding             = UDim.new(0, 2)
    cdLayout.Parent              = CD.CDScroll
    Padding(CD.CDScroll, 4, 4, 7, 7)
end
local CD_statusLabels = {}
for _, cmd in ipairs(CD_CMDS) do
    local row = Instance.new("Frame")
    row.Name             = "CDRow_".. cmd.name
    row.Size             = UDim2.new(1, -14, 0, 20)
    row.BackgroundColor3 = T.Card
    row.BorderSizePixel  = 0
    row.ZIndex           = 20
    row.Parent           = CD.CDScroll
    Corner(row, 6)
    Stroke(row, T.Border, 1)
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, -8)
    bar.Position         = UDim2.new(0, 0, 0, 4)
    bar.BackgroundColor3 = T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 21
    bar.Parent           = row
    Corner(bar, 2)
    local nameLbl = Label(row, cmd.display, 11, T.White, Enum.Font.GothamMedium)
    nameLbl.Size          = UDim2.new(1, -70, 1, 0)
    nameLbl.Position      = UDim2.new(0, 12, 0, 0)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex        = 21
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size                  = UDim2.new(0, 60, 1, 0)
    statusLbl.Position              = UDim2.new(1, -62, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text                  = "READY"
statusLbl.TextSize              = 11
    statusLbl.Font                  = Enum.Font.GothamBold
    statusLbl.TextColor3            = Color3.fromRGB(80, 200, 80)
    statusLbl.TextXAlignment        = Enum.TextXAlignment.Right
    statusLbl.ZIndex                = 21
    statusLbl.Parent                = row
    CD_statusLabels[cmd.name] = { lbl = statusLbl, bar = bar }
end
_G._FH_CD_ONCD = _G._FH_CD_ONCD or {}
task.spawn(function()
    while _G.FadedHubAlive and task.wait(0.2) do
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        local ap = pg and pg:FindFirstChild("AdminPanel")
        if not ap then continue end
        pcall(function()
            local sf = ap.AdminPanel.Content.ScrollingFrame
            for _, cmd in ipairs(CD_CMDS) do
                local entry = CD_statusLabels[cmd.name]
                local cmdFrame = sf:FindFirstChild(cmd.inGame)
                local onCD = false
                if cmdFrame then
                    local timer = cmdFrame:FindFirstChild("Timer")
                    if timer and timer.Visible then onCD = true end
                end
                _G._FH_CD_ONCD[cmd.inGame] = onCD or nil
                if entry and entry.lbl and entry.lbl.Parent and cmdFrame then
                    local timer = cmdFrame:FindFirstChild("Timer")
                    if onCD then
                        entry.lbl.Text      = (timer and timer.Text) or "..."
                        entry.lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                        Tween(entry.bar, F, {BackgroundColor3 = Color3.fromRGB(200, 60, 60)})
                    else
                        entry.lbl.Text      = "READY"
                        entry.lbl.TextColor3 = Color3.fromRGB(80, 200, 80)
                        Tween(entry.bar, F, {BackgroundColor3 = T.TrackOff})
                    end
                end
            end
        end)
    end
end)
CD.CDHdr.InputBegan:Connect(function(inp)
    if _G._FH_GUI_LOCKED then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        CD.dragging   = true
        CD.dragStart  = inp.Position
        CD.panelStart = CD.CDWin.Position
    end
end)
CD.CDHdr.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        CD.dragging = false
        Config.mini = Config.mini or {}
        Config.mini.cd_pos = { x = CD.CDWin.Position.X.Offset, y = CD.CDWin.Position.Y.Offset,
                               xs = CD.CDWin.Position.X.Scale, ys = CD.CDWin.Position.Y.Scale }
        pcall(FH_SaveConfig)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if CD.dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - CD.dragStart
        local newPos = UDim2.new(
            CD.panelStart.X.Scale, CD.panelStart.X.Offset + d.X,
            CD.panelStart.Y.Scale, CD.panelStart.Y.Offset + d.Y
        )
        CD.CDWin.Position         = newPos
        CD.CDBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
    end
end)
CD.CDMinBtn.MouseButton1Click:Connect(function()
    CD.minimized = not CD.minimized
    if CD.minimized then
        CD.CDWin.ClipsDescendants = false
        CD.CDHdrFill.Visible      = false
        CD.CDHdrLine.Visible      = false
        CD.CDScroll.Visible       = false
        Tween(CD.CDWin,         M, {Size = UDim2.new(0, CD.W, 0, 36)})
        Tween(CD.CDBorderFrame, M, {Size = UDim2.new(0, CD.W + 4, 0, 40)})
        CD.CDMinBtn.Text = "+"else
        CD.CDHdrFill.Visible = true
        CD.CDHdrLine.Visible = true
        Tween(CD.CDWin,         M, {Size = UDim2.new(0, CD.W, 0, CD.H)})
        Tween(CD.CDBorderFrame, M, {Size = UDim2.new(0, CD.W + 4, 0, CD.H + 4)})
        CD.CDMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
            CD.CDScroll.Visible       = true
            CD.CDWin.ClipsDescendants = true
        end)
    end
    if isMobile then
        Config.mini = Config.mini or {}
        Config.mini.cd_min = CD.minimized
        pcall(FH_SaveConfig)
    end
end)
CD.setCDPanelVisible = function(vis)
    CD.CDWin.Visible         = vis
    CD.CDBorderFrame.Visible = vis
    if vis then
        local p = CD.CDWin.Position
        CD.CDBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
        if CD.minimized then
            CD.CDMinBtn.Text          = "+"
CD.CDScroll.Visible       = false
            CD.CDHdrFill.Visible      = false
            CD.CDHdrLine.Visible      = false
            CD.CDWin.ClipsDescendants = false
            CD.CDWin.Size             = UDim2.new(0, CD.W, 0, 36)
            CD.CDBorderFrame.Size     = UDim2.new(0, CD.W + 4, 0, 40)
        else
            CD.CDMinBtn.Text          = "\226\136\146"
CD.CDScroll.Visible       = true
            CD.CDHdrFill.Visible      = true
            CD.CDHdrLine.Visible      = true
            CD.CDWin.ClipsDescendants = true
            CD.CDWin.Size             = UDim2.new(0, CD.W, 0, CD.H)
            CD.CDBorderFrame.Size     = UDim2.new(0, CD.W + 4, 0, CD.H + 4)
        end
    end
end
end
local function _FH_InitUBPanel()
    local CELL = 44
    local GAP  = 7
    local PAD  = 10
    local N    = 4

    local ubIsHorizontal = (Config and Config.mini and Config.mini.ub_horiz == true) or false
    local function ubComputeSize()
        if ubIsHorizontal then
            local w = N * CELL + (N - 1) * GAP + PAD * 2
            local h = CELL + PAD * 2
            return w, h
        else
            local w = CELL + PAD * 2
            local h = N * CELL + (N - 1) * GAP + PAD * 2
            return w, h
        end
    end
    UB.W, UB.H = ubComputeSize()
    UB.UBBorderFrame = Instance.new("Frame")
    UB.UBBorderFrame.Name             = "UBGradBorder"
UB.UBBorderFrame.Size             = UDim2.new(0, UB.W + 4, 0, UB.H + 4)
    UB.UBBorderFrame.Position         = UDim2.new(0.5, -(UB.W + 4) / 2, 1, -(UB.H + 4 + 80))
    UB.UBBorderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UB.UBBorderFrame.BorderSizePixel  = 0
    UB.UBBorderFrame.ZIndex           = 18
    UB.UBBorderFrame.Visible          = false
    UB.UBBorderFrame.Parent           = GUI
UB.UBBorderFrame.BackgroundTransparency = 1
    Corner(UB.UBBorderFrame, 12)
    UB.UBWin = Instance.new("Frame")
    UB.UBWin.Name             = "UnlockBasePanel"
UB.UBWin.Size             = UDim2.new(0, UB.W, 0, UB.H)
    UB.UBWin.Position         = UDim2.new(0.5, -UB.W / 2, 1, -(UB.H + 82))
    UB.UBWin.BackgroundColor3 = T.BG
        UB.UBWin.BackgroundTransparency = 0.25
    UB.UBWin.BorderSizePixel  = 0
    UB.UBWin.ZIndex           = 19
    UB.UBWin.Visible          = false
    UB.UBWin.ClipsDescendants = true
    UB.UBWin.Parent           = GUI
    Corner(UB.UBWin, 10)
    UB.UBWin.Active           = true
    local ubContent = Instance.new("Frame")
    ubContent.Size                   = UDim2.new(1, 0, 1, 0)
    ubContent.Position               = UDim2.new(0, 0, 0, 0)
    ubContent.BackgroundTransparency = 1
    ubContent.ZIndex                 = 19
    ubContent.Parent                 = UB.UBWin
    Padding(ubContent, PAD, PAD, PAD, PAD)
    local ubBtnGrid = Instance.new("UIGridLayout")
    ubBtnGrid.CellSize              = UDim2.new(0, CELL, 0, CELL)
    if ubIsHorizontal then
        ubBtnGrid.CellPadding           = UDim2.new(0, GAP, 0, 0)
        ubBtnGrid.FillDirectionMaxCells = N
    else
        ubBtnGrid.CellPadding           = UDim2.new(0, 0, 0, GAP)
        ubBtnGrid.FillDirectionMaxCells = 1
    end
    ubBtnGrid.HorizontalAlignment   = Enum.HorizontalAlignment.Center
    ubBtnGrid.VerticalAlignment     = Enum.VerticalAlignment.Center
    ubBtnGrid.Parent                = ubContent
    local function ubSyncBorderPos()
        local p = UB.UBWin.Position
        UB.UBBorderFrame.Position = UDim2.new(p.X.Scale, p.X.Offset - 2, p.Y.Scale, p.Y.Offset - 2)
    end
    local function ubApplyLayout()
        UB.W, UB.H = ubComputeSize()
        if ubIsHorizontal then
            ubBtnGrid.FillDirectionMaxCells = N
            ubBtnGrid.CellPadding           = UDim2.new(0, GAP, 0, 0)
        else
            ubBtnGrid.FillDirectionMaxCells = 1
            ubBtnGrid.CellPadding           = UDim2.new(0, 0, 0, GAP)
        end
        UB.UBWin.Size         = UDim2.new(0, UB.W, 0, UB.H)
        UB.UBBorderFrame.Size = UDim2.new(0, UB.W + 4, 0, UB.H + 4)
        Config.mini = Config.mini or {}
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local saved = Config.mini.ub_pos
        local absX, absY
        if saved and saved.x and saved.y then
            absX = saved.x
            absY = saved.y
        else
            absX = vp.X * 0.5 - UB.W / 2
            absY = vp.Y - (UB.H + 82)
        end
        local pad = 4
        if absX < pad then absX = pad end
        if absY < pad then absY = pad end
        if absX > vp.X - UB.W - pad then absX = vp.X - UB.W - pad end
        if absY > vp.Y - UB.H - pad then absY = vp.Y - UB.H - pad end
        UB.UBWin.Position         = UDim2.new(0, absX, 0, absY)
        UB.UBBorderFrame.Position = UDim2.new(0, absX - 2, 0, absY - 2)
        Config.mini.ub_pos = { x = absX, y = absY, xs = 0, ys = 0 }
        pcall(FH_SaveConfig)
    end
    local ubLayoutToggle = Instance.new("TextButton")
    ubLayoutToggle.BackgroundColor3 = T.Card
    ubLayoutToggle.BorderSizePixel  = 0
    ubLayoutToggle.Text             = ubIsHorizontal and "\226\134\148" or "\226\134\149"
ubLayoutToggle.TextSize         = 16
    ubLayoutToggle.Font             = Enum.Font.GothamBold
    ubLayoutToggle.TextColor3       = T.White
    ubLayoutToggle.ZIndex           = 22
    ubLayoutToggle.Parent           = ubContent
    Corner(ubLayoutToggle, 8)
    Stroke(ubLayoutToggle, T.Border, 1)
    local ubLayoutDebounce = false
    local function ubToggleLayout()
        if ubLayoutDebounce then return end
        ubLayoutDebounce = true
        ubIsHorizontal = not ubIsHorizontal
        UB.isHorizontal = ubIsHorizontal
        ubLayoutToggle.Text = ubIsHorizontal and "\226\134\148" or "\226\134\149"
        ubApplyLayout()

        Config.mini = Config.mini or {}
        Config.mini.ub_horiz = ubIsHorizontal
        pcall(FH_SaveConfig)
        task.delay(0.35, function() ubLayoutDebounce = false end)
    end
    UB.isHorizontal = ubIsHorizontal
    UB.setHorizontal = function(horiz)
        if horiz ~= ubIsHorizontal then ubToggleLayout() end
    end
    ubLayoutToggle.MouseButton1Click:Connect(ubToggleLayout)
    do
        local _ubLTTouchStart = nil
        ubLayoutToggle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch then
                _ubLTTouchStart = inp.Position
            end
        end)
        ubLayoutToggle.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and _ubLTTouchStart then
                local mag = (inp.Position - _ubLTTouchStart).Magnitude
                _ubLTTouchStart = nil
                if mag < 20 then ubToggleLayout() end
            end
        end)
    end
    local floorLabels = { "1", "2", "3"}
    for i = 1, 3 do
        local fbtn = Instance.new("TextButton", ubContent)
        fbtn.BackgroundColor3 = T.Card
        fbtn.Text             = floorLabels[i]
        fbtn.Font             = Enum.Font.GothamBlack
        fbtn.TextSize         = 20
        fbtn.TextColor3       = T.White
        fbtn.AutoButtonColor  = false
        fbtn.ZIndex           = 21
        Corner(fbtn, 8)
        local fbs = Stroke(fbtn, T.Border, 1)
        fbtn.MouseEnter:Connect(function()
            Tween(fbtn, F, {BackgroundColor3 = T.CardHover})
            fbs.Color = T.BorderHover
        end)
        fbtn.MouseLeave:Connect(function()
            Tween(fbtn, F, {BackgroundColor3 = T.Card})
            fbs.Color = T.Border
        end)
        local floorDebounce = false
        local function fireFloor()
            if floorDebounce then return end
            floorDebounce = true
            local fl = UB.floors[i]
            task.spawn(UB.triggerFloor, fl.yLevel, fl.maxY)
            Tween(fbtn, F, {BackgroundColor3 = T.TrackOn})
            fbs.Color = T.White
            task.delay(0.4, function()
                Tween(fbtn, M, {BackgroundColor3 = T.Card})
                fbs.Color = T.Border
                floorDebounce = false
            end)
        end
        fbtn.MouseButton1Click:Connect(fireFloor)
        do
            local _fbtnTouchStart = nil
            fbtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch then
                    _fbtnTouchStart = inp.Position
                end
            end)
            fbtn.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Touch and _fbtnTouchStart then
                    local mag = (inp.Position - _fbtnTouchStart).Magnitude
                    _fbtnTouchStart = nil
                    if mag < 20 then fireFloor() end
                end
            end)
        end
    end
    UB.UBWin.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            UB.dragging   = true
            UB.dragStart  = inp.Position
            UB.panelStart = UB.UBWin.Position
        end
    end)
    UB.UBWin.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            UB.dragging = false
            Config.mini = Config.mini or {}

            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            local absX = UB.UBWin.Position.X.Scale * vp.X + UB.UBWin.Position.X.Offset
            local absY = UB.UBWin.Position.Y.Scale * vp.Y + UB.UBWin.Position.Y.Offset
            Config.mini.ub_pos = { x = absX, y = absY, xs = 0, ys = 0 }
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if UB.dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - UB.dragStart
            local newPos = UDim2.new(
                UB.panelStart.X.Scale, UB.panelStart.X.Offset + d.X,
                UB.panelStart.Y.Scale, UB.panelStart.Y.Offset + d.Y
            )
            UB.UBWin.Position         = newPos
            UB.UBBorderFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
        end
    end)
    UB.setUnlockBasePanelVisible = function(vis)
        UB.UBWin.Visible         = vis
        UB.UBBorderFrame.Visible = vis
        if vis then
            UB.UBWin.ClipsDescendants = true
            UB.UBWin.Size             = UDim2.new(0, UB.W, 0, UB.H)
            UB.UBBorderFrame.Size     = UDim2.new(0, UB.W + 4, 0, UB.H + 4)
            ubSyncBorderPos()
        end
    end

    do
        local _ubRotJob = 0
        local function _ubOnViewportChanged()
            _ubRotJob = _ubRotJob + 1
            local myJob = _ubRotJob
            task.delay(0.05, function()
                if myJob ~= _ubRotJob then return end
                if not UB.UBWin then return end
                local vp  = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                          or Vector2.new(800, 600)
                local pad = 4
                local pw, ph = UB.W or 100, UB.H or 100
                local p   = UB.UBWin.Position
                local ax  = p.X.Scale * vp.X + p.X.Offset
                local ay  = p.Y.Scale * vp.Y + p.Y.Offset
                if ax < pad then ax = pad end
                if ay < pad then ay = pad end
                if ax > vp.X - pw - pad then ax = vp.X - pw - pad end
                if ay > vp.Y - ph - pad then ay = vp.Y - ph - pad end
                UB.UBWin.Position         = UDim2.new(0, ax, 0, ay)
                UB.UBBorderFrame.Position = UDim2.new(0, ax - 2, 0, ay - 2)
                Config.mini = Config.mini or {}
                Config.mini.ub_pos = { x = ax, y = ay, xs = 0, ys = 0 }
                pcall(FH_SaveConfig)
            end)
        end
        local function _ubHookCamera()
            local cam = workspace.CurrentCamera
            if not cam then return end
            cam:GetPropertyChangedSignal("ViewportSize"):Connect(_ubOnViewportChanged)
        end
        _ubHookCamera()
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(_ubHookCamera)
    end
end
_FH_InitUBPanel(); task.wait()
do
    local _CAS = game:GetService("ContextActionService")
    local _FH_SINK = "_FH_DragTouchSink"local _dragPanels = {
        {tbl = SP,  flag = "dragging"},
        {tbl = AB,  flag = "dragging"},
        {tbl = SS,  flag = "dragging"},
        {tbl = FA,  flag = "dragging"},
        {tbl = FD,  flag = "dragging"},
        {tbl = QP,  flag = "dragging"},
        {tbl = CD,  flag = "dragging"},
        {tbl = SVN, flag = "dragging"},
        {tbl = UB,  flag = "dragging"},
        {tbl = WSK, flag = "dragging"},
        {tbl = QS,  flag = "dragging"},
        {tbl = STP, flag = "dragging"},
        {tbl = _G,  flag = "_FH_MP_DRAG"},
        {tbl = _G,  flag = "_FH_SPAM_DRAG"},
    }
    local function _anyPanelDragging()
        for _, p in ipairs(_dragPanels) do
            if p.tbl and p.tbl[p.flag] then return true end
        end
        return false
    end
    UserInputService.InputBegan:Connect(function(inp, processed)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        task.defer(function()
            if _anyPanelDragging() then
                pcall(function()
                    _CAS:BindAction(_FH_SINK,
                        function() return Enum.ContextActionResult.Sink end,
                        false, Enum.UserInputType.Touch)
                end)
            end
        end)
    end)
    local _mainDrag = { dragging = false }
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local _anyWasDragging = false
        for _, p in ipairs(_dragPanels) do
            if p.tbl and p.tbl[p.flag] then
                p.tbl[p.flag] = false
                _anyWasDragging = true
            end
        end
        if _anyWasDragging then

            Config.mini = Config.mini or {}
            if SP  and SP.SpeedWin    then Config.mini.sp_pos  = { x = SP.SpeedWin.Position.X.Offset,    y = SP.SpeedWin.Position.Y.Offset,    xs = SP.SpeedWin.Position.X.Scale,    ys = SP.SpeedWin.Position.Y.Scale    } end
            if SS  and SS.SSWin       then Config.mini.ss_pos  = { x = SS.SSWin.Position.X.Offset,       y = SS.SSWin.Position.Y.Offset,       xs = SS.SSWin.Position.X.Scale,       ys = SS.SSWin.Position.Y.Scale       } end
            if AB  and AB.AllowBaseWin then Config.mini.ab_pos = { x = AB.AllowBaseWin.Position.X.Offset, y = AB.AllowBaseWin.Position.Y.Offset, xs = AB.AllowBaseWin.Position.X.Scale, ys = AB.AllowBaseWin.Position.Y.Scale } end
            if FA  and FA.FAWin       then Config.mini.fa_pos  = { x = FA.FAWin.Position.X.Offset,       y = FA.FAWin.Position.Y.Offset,       xs = FA.FAWin.Position.X.Scale,       ys = FA.FAWin.Position.Y.Scale       } end
            if FD  and FD.FDWin       then Config.mini.fd_pos  = { x = FD.FDWin.Position.X.Offset,       y = FD.FDWin.Position.Y.Offset,       xs = FD.FDWin.Position.X.Scale,       ys = FD.FDWin.Position.Y.Scale       } end
            if QP  and QP.QPWin       then Config.mini.qp_pos  = { x = QP.QPWin.Position.X.Offset,       y = QP.QPWin.Position.Y.Offset,       xs = QP.QPWin.Position.X.Scale,       ys = QP.QPWin.Position.Y.Scale       } end
            if CD  and CD.CDWin       then Config.mini.cd_pos  = { x = CD.CDWin.Position.X.Offset,       y = CD.CDWin.Position.Y.Offset,       xs = CD.CDWin.Position.X.Scale,       ys = CD.CDWin.Position.Y.Scale       } end
            if SVN and SVN.SVNWin     then Config.mini.svn_pos = { x = SVN.SVNWin.Position.X.Offset,     y = SVN.SVNWin.Position.Y.Offset,     xs = SVN.SVNWin.Position.X.Scale,     ys = SVN.SVNWin.Position.Y.Scale     } end
            if WSK and WSK.WSKWin     then Config.mini.wsk_pos = { x = WSK.WSKWin.Position.X.Offset,     y = WSK.WSKWin.Position.Y.Offset,     xs = WSK.WSKWin.Position.X.Scale,     ys = WSK.WSKWin.Position.Y.Scale     } end
            if QS  and QS.QSWin       then Config.mini.qs_pos  = { x = QS.QSWin.Position.X.Offset,       y = QS.QSWin.Position.Y.Offset,       xs = QS.QSWin.Position.X.Scale,       ys = QS.QSWin.Position.Y.Scale       } end
            if UB  and UB.UBWin       then
                local _vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                local _ax = UB.UBWin.Position.X.Scale * _vp.X + UB.UBWin.Position.X.Offset
                local _ay = UB.UBWin.Position.Y.Scale * _vp.Y + UB.UBWin.Position.Y.Offset
                Config.mini.ub_pos = { x = _ax, y = _ay, xs = 0, ys = 0 }
            end
            if FS  and FS.FSWin        then Config.mini.fs_pos   = { x = FS.FSWin.Position.X.Offset,        y = FS.FSWin.Position.Y.Offset,        xs = FS.FSWin.Position.X.Scale,        ys = FS.FSWin.Position.Y.Scale        } end
            if Win then Config.mini.main_pos = { x = Win.Position.X.Offset, y = Win.Position.Y.Offset, xs = Win.Position.X.Scale, ys = Win.Position.Y.Scale } end
            pcall(FH_SaveConfig)
        end
        if inp.UserInputType == Enum.UserInputType.Touch then
            pcall(function() _CAS:UnbindAction(_FH_SINK) end)
        end
    end)
end
;(function()
    _G._FH_CFG_LOAD_SPEED       = _G._FH_CFG_LOAD_SPEED       or 0.05
end)()
do
    local GRID_CORNER_A = Vector3.new(-336.94, 14.13,  91.61)
    local GRID_CORNER_B = Vector3.new(-294.31, 26.33, 148.23)
    local GRID_MIN = Vector3.new(
        math.min(GRID_CORNER_A.X, GRID_CORNER_B.X),
        math.min(GRID_CORNER_A.Y, GRID_CORNER_B.Y),
        math.min(GRID_CORNER_A.Z, GRID_CORNER_B.Z)
    )
    local GRID_MAX = Vector3.new(
        math.max(GRID_CORNER_A.X, GRID_CORNER_B.X),
        math.max(GRID_CORNER_A.Y, GRID_CORNER_B.Y),
        math.max(GRID_CORNER_A.Z, GRID_CORNER_B.Z)
    )
    local GRID_WPS = {
        Vector3.new(-298.70, 13.73, 130.22),
        Vector3.new(-305.05, 13.73, 144.65),
        Vector3.new(-356.71, -6.17, 143.88),
    }
    local function inGrid(pos)
        return pos.X >= GRID_MIN.X and pos.X <= GRID_MAX.X
           and pos.Y >= GRID_MIN.Y and pos.Y <= GRID_MAX.Y
           and pos.Z >= GRID_MIN.Z and pos.Z <= GRID_MAX.Z
    end
    local function equipCarpetTool()
        local lp   = Players.LocalPlayer
        local char = lp.Character
        local bp   = lp:FindFirstChild("Backpack")
        if not char or not bp then return end
        local hum    = char:FindFirstChildOfClass("Humanoid")
        local carpet = bp:FindFirstChild("Flying Carpet") or char:FindFirstChild("Flying Carpet")
        if carpet and hum and carpet.Parent ~= char then
            hum:EquipTool(carpet)
        end
    end
    local _origSSExecute = SS.SSExecute
    SS.SSExecute = function()

        _G._FH_LastV2UseTime = os.clock()
        local char = Players.LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and inGrid(hrp.Position) then
            if SS.debounce then return end
            SS.debounce = true
            task.spawn(function()
                equipCarpetTool()
                task.wait(0.1)
                for _, wp in ipairs(GRID_WPS) do
                    SS.SSTeleportHRP(wp)
                    task.wait(0.12)
                end
                SS.SSSetFFlags()
                SS.SSDoTeleport()
                if SS.autoTPUnlockState then
                    task.wait(0.15)
                    pcall(function()
                        local hrp2 = Players.LocalPlayer.Character
                            and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp2 then UB.triggerFloor(hrp2.Position.Y, nil) end
                    end)
                end
                task.wait(1.2)
                SS.debounce = false
            end)
        else
            _origSSExecute()
        end
    end
    if SS.SSExecuteBtn and not SS._executeConnected then
        SS._executeConnected = true
        SS.SSExecuteBtn.MouseButton1Click:Connect(function()
            Tween(SS.SSExecuteBtn, F, {BackgroundColor3 = SS.BTN_HOVER})
            task.delay(0.12, function() Tween(SS.SSExecuteBtn, F, {BackgroundColor3 = SS.BTN}) end)
            SS.SSExecute()
        end)
    end
end

local function _FH_InitMainPill()
    local function toggleMainUI()
        if animating then return end
        animating = true
        hidden = not hidden
        Config.mini = Config.mini or {}
        Config.mini.main_hidden = hidden
        pcall(FH_SaveConfig)
        if hidden then
            local tw = TweenService:Create(Win, HIDE_INFO, {
                Size     = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            })
            tw:Play()
            TweenService:Create(BorderFrame, HIDE_INFO, {
                Size     = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(0.5, -2, 0.5, -2),
            }):Play()
            tw.Completed:Connect(function()
                setGuiVisible(false)
                animating = false
            end)
        else
            Win.Size     = UDim2.new(0, 0, 0, 0)
            Win.Position = UDim2.new(0.5, 0, 0.5, 0)
            BorderFrame.Size     = UDim2.new(0, 4, 0, 4)
            BorderFrame.Position = UDim2.new(0.5, -2, 0.5, -2)
            setGuiVisible(true)
            local tw = TweenService:Create(Win, SHOW_INFO, {
                Size     = UDim2.new(0, WIN_W, 0, WIN_H),
                Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
            })
            tw:Play()
            TweenService:Create(BorderFrame, SHOW_INFO, {
                Size     = UDim2.new(0, WIN_W + 4, 0, WIN_H + 4),
                Position = UDim2.new(0.5, -(WIN_W+4)/2, 0.5, -(WIN_H+4)/2),
            }):Play()
            tw.Completed:Connect(function() animating = false end)
        end
    end
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.LeftControl then
            toggleMainUI()
        end
    end)
    local pillBorder
    do
    local PILL_W = 72
    local PILL_H = 28
    pillBorder = Instance.new("Frame")
    pillBorder.Name                   = "FadedPillBorder"
pillBorder.Size                   = UDim2.new(0, PILL_W + 3, 0, PILL_H + 3)
    pillBorder.Position               = UDim2.new(0, -2, 0.5, -(PILL_H + 3) / 2)
    pillBorder.BackgroundColor3       = Color3.fromRGB(50, 50, 50)
    pillBorder.BorderSizePixel        = 0
    pillBorder.ZIndex                 = 30
    pillBorder.Parent                 = GUI
    Instance.new("UICorner", pillBorder).CornerRadius = UDim.new(1, 0)
    local pillBtn = Instance.new("TextButton")
    pillBtn.Name                   = "FadedPill"
pillBtn.Size                   = UDim2.new(0, PILL_W, 0, PILL_H)
    pillBtn.Position               = UDim2.new(0, 1, 0, 1)
    pillBtn.BackgroundColor3       = Color3.fromRGB(14, 14, 18)
    pillBtn.BackgroundTransparency = 0.18
    pillBtn.BorderSizePixel        = 0
    pillBtn.Text                   = "Faded"
pillBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    pillBtn.TextSize               = 13
    pillBtn.Font                   = Enum.Font.GothamBold
    pillBtn.ZIndex                 = 31
    pillBtn.Parent                 = pillBorder
    Instance.new("UICorner", pillBtn).CornerRadius = UDim.new(1, 0)
    local pillTapActive = false
    local pillTapStart  = nil
    pillBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pillTapActive = true
            pillTapStart  = inp.Position
        end
    end)
    pillBtn.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) and pillTapActive then
            pillTapActive = false
            if pillTapStart and (inp.Position - pillTapStart).Magnitude < 20 then
                toggleMainUI()
            end
            pillTapStart = nil
        end
    end)
    local pillDragging = false
    local pillDragStart = nil
    local pillBorderStart = nil
    pillBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pillDragging    = true
            pillDragStart   = inp.Position
            pillBorderStart = pillBorder.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if pillDragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - pillDragStart
            if d.Magnitude > 6 then
                pillDragging = false
                local function onMove(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch then
                        local dd = i.Position - pillDragStart
                        pillBorder.Position = UDim2.new(
                            pillBorderStart.X.Scale, pillBorderStart.X.Offset + dd.X,
                            pillBorderStart.Y.Scale, pillBorderStart.Y.Offset + dd.Y
                        )
                    end
                end
                local mc = UserInputService.InputChanged:Connect(onMove)
                local ec
                ec = UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        mc:Disconnect(); ec:Disconnect()
                        Config.mini = Config.mini or {}
                        Config.mini.pill_x = pillBorder.Position.X.Offset
                        Config.mini.pill_y = pillBorder.Position.Y.Offset
                        pcall(FH_SaveConfig)
                    end
                end)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            pillDragging = false
        end
    end)
    task.defer(function()
        task.wait(1.5)
        local m = Config.mini or {}
        if m.pill_x or m.pill_y then
            pillBorder.Position = UDim2.new(
                pillBorder.Position.X.Scale, m.pill_x or pillBorder.Position.X.Offset,
                pillBorder.Position.Y.Scale, m.pill_y or pillBorder.Position.Y.Offset
            )
        end
    end)
    end
    local MP = {}
    MP.W = isMobile and 212 or 255
    MP.H = isMobile and 184 or 255
    MP.minimized  = false
    MP.dragging   = false
    MP.dragStart  = nil
    MP.panelStart = nil
    local mpBorderFrame = Instance.new("Frame")
    mpBorderFrame.Name                   = "MobilePanelBorder"
mpBorderFrame.Size                   = UDim2.new(0, MP.W + 4, 0, MP.H + 4)
    mpBorderFrame.Position               = UDim2.new(0, 14, 0.5, 60)
    mpBorderFrame.BackgroundColor3       = Color3.fromRGB(50, 50, 50)
    mpBorderFrame.BorderSizePixel        = 0
    mpBorderFrame.ZIndex                 = 18
    mpBorderFrame.Visible                = false
    mpBorderFrame.Parent                 = GUI
    mpBorderFrame.BackgroundTransparency = 1
    Instance.new("UICorner", mpBorderFrame).CornerRadius = UDim.new(0, 12)
    do
    end
    local mpWin = Instance.new("Frame")
    mpWin.Name                   = "MobileMiniPanel"
mpWin.Size                   = UDim2.new(0, MP.W, 0, MP.H)
    mpWin.Position               = UDim2.new(0, 2, 0, 2)
    mpWin.BackgroundColor3       = Color3.fromRGB(12, 12, 16)
    mpWin.BackgroundTransparency = 0.25
    mpWin.BorderSizePixel        = 0
    mpWin.ZIndex                 = 19
    mpWin.ClipsDescendants       = true
    mpWin.Parent                 = mpBorderFrame
    Instance.new("UICorner", mpWin).CornerRadius = UDim.new(0, 10)
    local mpHdr = Instance.new("Frame")
    mpHdr.Size             = UDim2.new(1, 0, 0, 34)
    mpHdr.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        mpHdr.BackgroundTransparency = 0.2
    mpHdr.BorderSizePixel  = 0
    mpHdr.ZIndex           = 20
    mpHdr.Parent           = mpWin
    Instance.new("UICorner", mpHdr).CornerRadius = UDim.new(0, 10)
    local mpHdrFill = Instance.new("Frame")
    mpHdrFill.Size             = UDim2.new(1, 0, 0, 10)
    mpHdrFill.Position         = UDim2.new(0, 0, 1, -10)
    mpHdrFill.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        mpHdrFill.BackgroundTransparency = 0.2
    mpHdrFill.BorderSizePixel  = 0
    mpHdrFill.ZIndex           = 20
    mpHdrFill.Parent           = mpHdr
    local mpHdrLine = Instance.new("Frame")
    mpHdrLine.Size             = UDim2.new(1, 0, 0, 1)
    mpHdrLine.Position         = UDim2.new(0, 0, 1, -1)
    mpHdrLine.BackgroundColor3 = T.Border
    mpHdrLine.BorderSizePixel  = 0
    mpHdrLine.ZIndex           = 21
    mpHdrLine.Parent           = mpHdr
    do
        local mpTitle = Instance.new("TextLabel")
        mpTitle.Size                  = UDim2.new(1, -60, 1, 0)
        mpTitle.Position              = UDim2.new(0, 12, 0, 0)
        mpTitle.BackgroundTransparency = 1
        mpTitle.Text                  = "Quick Actions"
mpTitle.TextSize              = 13
        mpTitle.Font                  = Enum.Font.GothamBold
        mpTitle.TextColor3            = Color3.fromRGB(245, 245, 245)
        mpTitle.TextXAlignment        = Enum.TextXAlignment.Left
        mpTitle.TextYAlignment        = Enum.TextYAlignment.Center
        mpTitle.ZIndex                = 21
        mpTitle.Parent                = mpHdr
    end
    local mpMinBtn = Instance.new("TextButton")
    mpMinBtn.Size             = UDim2.new(0, 22, 0, 22)
    mpMinBtn.Position         = UDim2.new(1, -28, 0.5, -11)
    mpMinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    mpMinBtn.BorderSizePixel  = 0
    mpMinBtn.Text             = "\226\136\146"
mpMinBtn.TextSize         = 12
    mpMinBtn.Font             = Enum.Font.GothamBold
    mpMinBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
    mpMinBtn.ZIndex           = 23
    mpMinBtn.Parent           = mpHdr
    Instance.new("UICorner", mpMinBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", mpMinBtn).Color = T.Border
    local mpContent = Instance.new("Frame")
    mpContent.Size                   = UDim2.new(1, 0, 1, -34)
    mpContent.Position               = UDim2.new(0, 0, 0, 34)
    mpContent.BackgroundTransparency = 1
    mpContent.ZIndex                 = 19
    mpContent.Parent                 = mpWin
    local mpLayout = Instance.new("UIListLayout")
    mpLayout.FillDirection       = Enum.FillDirection.Vertical
    mpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mpLayout.Padding             = UDim.new(0, isMobile and 7 or 9)
    mpLayout.Parent              = mpContent
    Instance.new("UIPadding", mpContent).PaddingTop    = UDim.new(0, isMobile and 14 or 10)
    local _pad = mpContent:FindFirstChildOfClass("UIPadding")
    if _pad then
        _pad.PaddingLeft   = UDim.new(0, 8)
        _pad.PaddingRight  = UDim.new(0, 8)
        _pad.PaddingBottom = UDim.new(0, 8)
    end
    local function mpMakeBtn(labelText, color, fireFn)
        local btnH = isMobile and 24 or 36
        local row = Instance.new("TextButton")
        row.Size             = UDim2.new(1, 0, 0, btnH)
        row.BackgroundColor3 = color or Color3.fromRGB(28, 28, 36)
        row.BorderSizePixel  = 0
        row.Text             = labelText
        row.TextSize         = isMobile and 10 or 13
        row.Font             = Enum.Font.GothamBold
        row.TextColor3       = Color3.fromRGB(255, 255, 255)
        row.ZIndex           = 21
        row.AutoButtonColor  = false
        row.Parent           = mpContent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", row).Color = T.Border
        local mpBtnDebounce = false
        local function doFire()
            if mpBtnDebounce then return end
            mpBtnDebounce = true
            TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
            task.delay(0.15, function()
                TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = color or Color3.fromRGB(28, 28, 36)}):Play()
            end)
            task.spawn(fireFn)
            task.delay(0.4, function() mpBtnDebounce = false end)
        end
        local _mpTouchActive = false
        local _mpTouchStart  = nil
        row.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                _mpTouchActive = true
                _mpTouchStart  = inp.Position
            end
        end)
        row.InputEnded:Connect(function(inp)
            if (inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1) and _mpTouchActive then
                _mpTouchActive = false
                if _mpTouchStart and (inp.Position - _mpTouchStart).Magnitude < 10 then
                    doFire()
                end
                _mpTouchStart = nil
            end
        end)
        row.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(42, 42, 52)}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = color or Color3.fromRGB(28, 28, 36)}):Play()
        end)
        return row
    end
    mpMakeBtn("Teleport Next Base", Color3.fromRGB(20, 60, 100), function()
        ToggleHandlers.carpet_tp_base(true)
    end)
    local carpetSpeedActive = false
    local carpetSpeedRow
    carpetSpeedRow = mpMakeBtn("Carpet Speed: OFF", Color3.fromRGB(28, 28, 36), function()
        carpetSpeedActive = not carpetSpeedActive
        ToggleHandlers.carpet_speed(carpetSpeedActive)
        carpetSpeedRow.Text             = carpetSpeedActive and "Carpet Speed: ON"or "Carpet Speed: OFF"
carpetSpeedRow.BackgroundColor3 = carpetSpeedActive
            and Color3.fromRGB(20, 90, 40)
            or  Color3.fromRGB(28, 28, 36)
    end)
    local giantSpeedActive = false
    local giantSpeedRow
    giantSpeedRow = mpMakeBtn("Giant Speed: OFF", Color3.fromRGB(28, 28, 36), function()
        giantSpeedActive = not giantSpeedActive
        ToggleHandlers.giant_speed(giantSpeedActive)
        giantSpeedRow.Text             = giantSpeedActive and "Giant Speed: ON"or "Giant Speed: OFF"
giantSpeedRow.BackgroundColor3 = giantSpeedActive
            and Color3.fromRGB(90, 20, 90)
            or  Color3.fromRGB(28, 28, 36)
    end)
    local mpRespawnRow
    mpRespawnRow = mpMakeBtn("Instant Respawn", Color3.fromRGB(28, 28, 36), function()
        task.spawn(function() instantRespawn(mpRespawnRow) end)
    end)
    MP.MPMinBtn = mpMinBtn
    mpMinBtn.MouseButton1Click:Connect(function()
        MP.minimized = not MP.minimized
        if MP.minimized then
            mpWin.ClipsDescendants = false
            mpHdrFill.Visible      = false
            mpHdrLine.Visible      = false
            mpContent.Visible      = false
            TweenService:Create(mpWin,         M, {Size = UDim2.new(0, MP.W, 0, 34)}):Play()
            TweenService:Create(mpBorderFrame, M, {Size = UDim2.new(0, MP.W + 4, 0, 38)}):Play()
            mpMinBtn.Text = "+"
        else
            mpHdrFill.Visible = true
            mpHdrLine.Visible = true
            TweenService:Create(mpWin,         M, {Size = UDim2.new(0, MP.W, 0, MP.H)}):Play()
            TweenService:Create(mpBorderFrame, M, {Size = UDim2.new(0, MP.W + 4, 0, MP.H + 4)}):Play()
            mpMinBtn.Text = "\226\136\146"
task.delay(M.Time, function()
                mpContent.Visible      = true
                mpWin.ClipsDescendants = true
            end)
        end
        if isMobile then
            Config.mini = Config.mini or {}
            Config.mini.mp_min = MP.minimized
            pcall(FH_SaveConfig)
        end
    end)
    mpHdr.InputBegan:Connect(function(inp)
        if _G._FH_GUI_LOCKED then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            MP.dragging          = true
            _G._FH_MP_DRAG       = true
            MP.dragStart         = inp.Position
            MP.panelStart        = mpBorderFrame.Position
        end
    end)
    mpHdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            MP.dragging   = false
            _G._FH_MP_DRAG = false
            Config.mini = Config.mini or {}
            Config.mini.mp_pos = {
                x  = mpBorderFrame.Position.X.Offset,
                y  = mpBorderFrame.Position.Y.Offset,
                xs = mpBorderFrame.Position.X.Scale,
                ys = mpBorderFrame.Position.Y.Scale,
            }
            Config.mini.mp_x = Config.mini.mp_pos.x
            Config.mini.mp_y = Config.mini.mp_pos.y
            pcall(FH_SaveConfig)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if MP.dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - MP.dragStart
            local newPos = UDim2.new(
                MP.panelStart.X.Scale, MP.panelStart.X.Offset + d.X,
                MP.panelStart.Y.Scale, MP.panelStart.Y.Offset + d.Y
            )
            mpBorderFrame.Position = newPos
        end
    end)
    _G.MobilePanel      = mpBorderFrame
    _G.MobileBorderFrame = mpBorderFrame
    task.defer(function()
        task.wait(0.05)
        local m = Config.mini or {}
        if m.mobile_panel then
            mpBorderFrame.Visible = true
        end
        if m.mp_pos or m.mp_x or m.mp_y then
            local p = m.mp_pos
            mpBorderFrame.Position = UDim2.new(
                (p and p.xs) or mpBorderFrame.Position.X.Scale,
                (p and p.x)  or m.mp_x or mpBorderFrame.Position.X.Offset,
                (p and p.ys) or mpBorderFrame.Position.Y.Scale,
                (p and p.y)  or m.mp_y or mpBorderFrame.Position.Y.Offset
            )
        end
        if isMobile and m.mobile_panel == nil then
            mpBorderFrame.Visible = true
            local reg = configRegistry["Mobile Mini Button Panels"]
            if reg and not reg.getState() then
                reg.doToggle()
            end
        end
    end)
end
_FH_InitMainPill()
task.defer(function()
    local m   = Config.mini or {}
    local function applyPos(win, border, posData, borderOffX, borderOffY)
        if not posData then return end
        if not win then return end
        borderOffX = borderOffX or -2
        borderOffY = borderOffY or -2
        local xs = posData.xs or win.Position.X.Scale
        local ys = posData.ys or win.Position.Y.Scale
        local x  = posData.x  or win.Position.X.Offset
        local y  = posData.y  or win.Position.Y.Offset
        win.Position = UDim2.new(xs, x, ys, y)
        if border then
            border.Position = UDim2.new(xs, x + borderOffX, ys, y + borderOffY)
        end
    end
    if m.main_pos then
        local p = m.main_pos
        local xs = p.xs or 0.5
        local ys = p.ys or 0.5
        Win.Position         = UDim2.new(xs, p.x, ys, p.y)
        BorderFrame.Position = UDim2.new(xs, p.x - 2, ys, p.y - 2)
    end
    if m.sp_pos and SP and SP.SpeedWin then
        applyPos(SP.SpeedWin, SP.SpeedBorderFrame, m.sp_pos)
    end
    if m.ab_pos and AB and AB.AllowBaseWin then
        applyPos(AB.AllowBaseWin, AB.AllowBaseBorderFrame, m.ab_pos)
    end
    if m.ss_pos and SS and SS.SSWin then
        applyPos(SS.SSWin, SS.SSBorderFrame, m.ss_pos)
    end
    if m.fa_pos and FA and FA.FAWin then
        applyPos(FA.FAWin, FA.FABorderFrame, m.fa_pos)
    end
    if m.wsk_pos and WSK and WSK.WSKWin then
        applyPos(WSK.WSKWin, WSK.WSKBorderFrame, m.wsk_pos)
    end
    if m.fs_pos and FS and FS.FSWin then
        applyPos(FS.FSWin, FS.FSBorderFrame, m.fs_pos)
    end
    if m.fd_pos and FD and FD.FDWin then
        applyPos(FD.FDWin, FD.FDBorderFrame, m.fd_pos)
    end
    if m.qp_pos and QP and QP.QPWin then
        applyPos(QP.QPWin, QP.QPBorderFrame, m.qp_pos)
    end
    if m.cd_pos and CD and CD.CDWin then
        applyPos(CD.CDWin, CD.CDBorderFrame, m.cd_pos)
    end
    if m.svn_pos and SVN and SVN.SVNWin then
        applyPos(SVN.SVNWin, SVN.SVNBorderFrame, m.svn_pos)
    end
    if m.qs_pos and QS and QS.QSWin then
        applyPos(QS.QSWin, QS.QSBorderFrame, m.qs_pos)
    end
    if UB and UB.setHorizontal and m.ub_horiz ~= nil then
        pcall(UB.setHorizontal, m.ub_horiz == true)
    end
    if m.ub_pos and UB and UB.UBWin then
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local pad = 4
        local pw, ph = UB.W or 100, UB.H or 100
        local cx = m.ub_pos.x or 0
        local cy = m.ub_pos.y or 0
        if cx < pad then cx = pad end
        if cy < pad then cy = pad end
        if cx > vp.X - pw - pad then cx = vp.X - pw - pad end
        if cy > vp.Y - ph - pad then cy = vp.Y - ph - pad end
        applyPos(UB.UBWin, UB.UBBorderFrame, { x = cx, y = cy, xs = 0, ys = 0 })
        Config.mini.ub_pos = { x = cx, y = cy, xs = 0, ys = 0 }
    end
    if m.pill_x or m.pill_y then
        local _pillBorder = GUI:FindFirstChild("FadedPillBorder")
        if _pillBorder then
            _pillBorder.Position = UDim2.new(
                _pillBorder.Position.X.Scale, m.pill_x or _pillBorder.Position.X.Offset,
                _pillBorder.Position.Y.Scale, m.pill_y or _pillBorder.Position.Y.Offset
            )
        end
    end
end)

local function _FH_ApplyRestore(savedConfig, restoredAccumulator)
    if not savedConfig then return 0 end
    local restored = 0

    if savedConfig.toggles then
        local pending = 0
        local _appliedThisFrame = 0
        for name, enabled in pairs(savedConfig.toggles) do
            if not restoredAccumulator[name] then
                local reg = configRegistry[name]
                if reg then
                    local target = enabled == true
                    if reg.setEnabled then
                        pending = pending + 1
                        local _fn = reg.setEnabled
                        task.spawn(function() pcall(_fn, target); pending = pending - 1 end)
                    elseif target and reg.doToggle then
                        pending = pending + 1
                        local _fn = reg.doToggle
                        task.spawn(function() pcall(_fn); pending = pending - 1 end)
                    end
                    restoredAccumulator[name] = true
                    if target then
                        restored = restored + 1
                        _appliedThisFrame = _appliedThisFrame + 1
                        if _appliedThisFrame >= 3 then
                            _appliedThisFrame = 0
                            task.wait()
                        end
                    end
                end
            end
        end
        local _t = tick()
        while pending > 0 and tick() - _t < 3 do task.wait() end
    end
    if savedConfig.keybinds then
        for name, kcName in pairs(savedConfig.keybinds) do
            local reg = configRegistry[name]
            if reg and reg.setKeyCode then
                local ok, kc = pcall(function() return Enum.KeyCode[kcName] end)
                if ok and kc then pcall(reg.setKeyCode, kc) end
            end
        end
    end
    return restored
end
task.spawn(function()
    if not _FH_SavedConfig then
        pcall(function() ShowToggleNotification("Faded Hub - No saved config", false) end)
        _FH_RestoreComplete = true
        _G._FH_IsRestoring  = false
        return
    end

    _G._FH_IsRestoring = true
    local doneNames = {}
    local restoredCount = _FH_ApplyRestore(_FH_SavedConfig, doneNames)
    local _toggleCount = 0
    if _FH_SavedConfig.toggles then
        for _ in pairs(_FH_SavedConfig.toggles) do _toggleCount = _toggleCount + 1 end
    end
    local _lastDone = -1
    for _retry = 1, 6 do
        local _doneCount = 0
        for _ in pairs(doneNames) do _doneCount = _doneCount + 1 end
        if _doneCount >= _toggleCount then break end
        if _doneCount == _lastDone then break end
        _lastDone = _doneCount
        task.wait()
        restoredCount = restoredCount + _FH_ApplyRestore(_FH_SavedConfig, doneNames)
    end
    _G._FH_IsRestoring = false
    _FH_RestoreComplete = true
    pcall(function()
        ShowToggleNotification("Config Loaded (" .. restoredCount .. " active)", true)
    end)

    if _FH_SavedConfig.mini and _FH_SavedConfig.mini.sp_keybind then
        local kcName = _FH_SavedConfig.mini.sp_keybind
        local ok, kc = pcall(function() return Enum.KeyCode[kcName] end)
        if ok and kc and SP and SP.entry then
            SP.entry.keyCode = kc
            if SP.spKbLbl then SP.spKbLbl.Text = "["..kc.Name.."]"; SP.spKbLbl.TextColor3 = T.Dim end
        end
    end

    if _FH_SavedConfig.sliders then
        if _FH_SavedConfig.sliders.sp_walkspeed and SP and SP.wsBox then
            SP.wsBox.Text = tostring(_FH_SavedConfig.sliders.sp_walkspeed)
        end
        if _FH_SavedConfig.sliders.sp_jumppower and SP and SP.jpBox then
            SP.jpBox.Text = tostring(_FH_SavedConfig.sliders.sp_jumppower)
        end
    end

    local m = _FH_SavedConfig.mini or {}
    if m.main_hidden then
        pcall(function()
            hidden = true
            if Win then Win.Visible = false end
            if BorderFrame then BorderFrame.Visible = false end
        end)
    end
    if m.sp_open  and SP  and SP.setSpeedPanelVisible      then pcall(function() SP.setSpeedPanelVisible(true)       end) end
    if m.ss_open  and SS  and SS.setSemiStealPanelVisible  then pcall(function() SS.setSemiStealPanelVisible(true)   end) end
    if m.ab_open  and AB  and AB.setAllowBasePanelVisible  then pcall(function() AB.setAllowBasePanelVisible(true)   end) end
    if m.fa_open  and FA  and FA.setFadedActionsVisible    then pcall(function() FA.setFadedActionsVisible(true)     end) end
    if m.fd_open  and FD  and FD.setFadedDefenseVisible    then pcall(function() FD.setFadedDefenseVisible(true)     end) end
    if m.qp_open  and QP  and QP.setQuickPanelVisible      then pcall(function() QP.setQuickPanelVisible(true)       end) end
    if m.cd_open  and CD  and CD.setCDPanelVisible         then pcall(function() CD.setCDPanelVisible(true)          end) end
    if m.wsk_open and WSK and WSK.setWSKPanelVisible       then pcall(function() WSK.setWSKPanelVisible(true)        end) end
    if m.qs_open  and QS  and QS.setQuickStealVisible      then pcall(function() QS.setQuickStealVisible(true)       end) end
    if m.ub_open  and UB  and UB.setUnlockBasePanelVisible then pcall(function() UB.setUnlockBasePanelVisible(true)  end) end
    if m.fs_open  and FS  and FS.setFlashStealVisible      then pcall(function() FS.setFlashStealVisible(true)       end) end
    if isMobile then
        local function _fireMin(minBtn)
            if not minBtn then return end
            local ok, conns = pcall(getconnections, minBtn.MouseButton1Click)
            if not ok or not conns then return end
            for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
        end
        task.defer(function()
            if m.sp_min  and SP  and SP.SpMinBtn   and not SP.minimized  then _fireMin(SP.SpMinBtn)   end
            if m.ab_min  and AB  and AB.ABMinBtn   and not AB.minimized  then _fireMin(AB.ABMinBtn)   end
            if m.ss_min  and SS  and SS.SSMinBtn   and not SS.minimized  then _fireMin(SS.SSMinBtn)   end
            if m.fa_min  and FA  and FA.FAMinBtn   and not FA.minimized  then _fireMin(FA.FAMinBtn)   end
            if m.wsk_min and WSK and WSK.WSKMinBtn and not WSK.minimized then _fireMin(WSK.WSKMinBtn) end
            if m.fd_min  and FD  and FD.FDMinBtn   and not FD.minimized  then _fireMin(FD.FDMinBtn)   end
            if m.qp_min  and QP  and QP.QPMinBtn   and not QP.minimized  then _fireMin(QP.QPMinBtn)   end
            if m.cd_min  and CD  and CD.CDMinBtn   and not CD.minimized  then _fireMin(CD.CDMinBtn)   end
            if m.qs_min  and QS  and QS.QSMinBtn   and not QS.minimized  then _fireMin(QS.QSMinBtn)   end
            if m.mp_min  and MP  and MP.MPMinBtn   and not MP.minimized  then _fireMin(MP.MPMinBtn)   end
        end)
    end

    if m.customize_open then
        task.defer(function()
            if _G.SpammerGui and _G.SpammerGui.openCustomize
                and not (_G.SpammerGui.isCustomizeOpen and _G.SpammerGui.isCustomizeOpen()) then
                pcall(_G.SpammerGui.openCustomize)
            end
        end)
    end
    local function _FH_RefreshKeybindLabels()
        local source = (_FH_SavedConfig and _FH_SavedConfig.keybinds) or Config.keybinds or {}
        for name, kcName in pairs(source) do
            local reg = configRegistry[name]
            if reg and type(kcName) == "string" then
                local ok, kc = pcall(function() return Enum.KeyCode[kcName] end)
                if ok and kc then
                    if reg.setKeyCode then pcall(reg.setKeyCode, kc) end
                    if reg.kbLbl then
                        pcall(function()
                            reg.kbLbl.Text       = "[" .. kc.Name .. "]"
                            reg.kbLbl.TextColor3 = T.Dim
                        end)
                    end
                    if reg.kbEntry then reg.kbEntry.keyCode = kc end
                end
            end
        end
        for _, binding in ipairs(keybindEntries) do
            if binding.kbLbl and binding.entry and binding.entry.keyCode then
                pcall(function()
                    binding.kbLbl.Text       = "[" .. binding.entry.keyCode.Name .. "]"
                    binding.kbLbl.TextColor3 = T.Dim
                end)
            end
        end
        if _FH_SavedConfig and _FH_SavedConfig.mini and _FH_SavedConfig.mini.sp_keybind then
            local ok, kc = pcall(function() return Enum.KeyCode[_FH_SavedConfig.mini.sp_keybind] end)
            if ok and kc and SP then
                if SP.entry then SP.entry.keyCode = kc end
                if SP.spKbLbl then
                    SP.spKbLbl.Text       = "[" .. kc.Name .. "]"
                    SP.spKbLbl.TextColor3 = T.Dim
                end
            end
        end
        if _FH_SavedConfig and _FH_SavedConfig.keybinds and _FH_SavedConfig.keybinds.wsk_fire_burst then
            local ok, kc = pcall(function() return Enum.KeyCode[_FH_SavedConfig.keybinds.wsk_fire_burst] end)
            if ok and kc and WSK and WSK.wskKbLbl then
                if WSK.entry then WSK.entry.keyCode = kc end
                WSK.wskKbLbl.Text       = "[" .. kc.Name .. "]"
                WSK.wskKbLbl.TextColor3 = T.Dim
            end
        end
    end
    _FH_RefreshKeybindLabels()
    pcall(function()
        if _G._FH_UpdateThemeColors then _G._FH_UpdateThemeColors() end
    end)
end)
task.spawn(function()
    pcall(FH_SaveConfig)
end)
Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local m2 = Config.mini or {}
    local function _rp(win, border, pd, bx, by)
        if not pd or not win then return end
        bx = bx or -2; by = by or -2
        local xs = pd.xs or win.Position.X.Scale
        local ys = pd.ys or win.Position.Y.Scale
        local px = pd.x or win.Position.X.Offset
        local py = pd.y or win.Position.Y.Offset
        win.Position = UDim2.new(xs, px, ys, py)
        if border then border.Position = UDim2.new(xs, px + bx, ys, py + by) end
    end
    if m2.main_pos then
        local p = m2.main_pos
        Win.Position = UDim2.new(p.xs or 0.5, p.x, p.ys or 0.5, p.y)
        BorderFrame.Position = UDim2.new(p.xs or 0.5, p.x - 2, p.ys or 0.5, p.y - 2)
    end
    if m2.sp_pos and SP and SP.SpeedWin then _rp(SP.SpeedWin, SP.SpeedBorderFrame, m2.sp_pos) end
    if m2.ab_pos and AB and AB.AllowBaseWin then _rp(AB.AllowBaseWin, AB.AllowBaseBorderFrame, m2.ab_pos) end
    if m2.ss_pos and SS and SS.SSWin then _rp(SS.SSWin, SS.SSBorderFrame, m2.ss_pos) end
    if m2.fa_pos and FA and FA.FAWin then _rp(FA.FAWin, FA.FABorderFrame, m2.fa_pos) end
    if m2.wsk_pos and WSK and WSK.WSKWin then _rp(WSK.WSKWin, WSK.WSKBorderFrame, m2.wsk_pos) end
    if m2.fd_pos and FD and FD.FDWin then _rp(FD.FDWin, FD.FDBorderFrame, m2.fd_pos) end
    if m2.qp_pos and QP and QP.QPWin then _rp(QP.QPWin, QP.QPBorderFrame, m2.qp_pos) end
    if m2.cd_pos and CD and CD.CDWin then _rp(CD.CDWin, CD.CDBorderFrame, m2.cd_pos) end
    if m2.svn_pos and SVN and SVN.SVNWin then _rp(SVN.SVNWin, SVN.SVNBorderFrame, m2.svn_pos) end
    if m2.qs_pos and QS and QS.QSWin then _rp(QS.QSWin, QS.QSBorderFrame, m2.qs_pos) end
    if UB and UB.setHorizontal and m2.ub_horiz ~= nil then
        pcall(UB.setHorizontal, m2.ub_horiz == true)
    end
    if m2.ub_pos and UB and UB.UBWin then
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local pad = 4
        local pw, ph = UB.W or 100, UB.H or 100
        local cx = m2.ub_pos.x or 0
        local cy = m2.ub_pos.y or 0
        if cx < pad then cx = pad end
        if cy < pad then cy = pad end
        if cx > vp.X - pw - pad then cx = vp.X - pw - pad end
        if cy > vp.Y - ph - pad then cy = vp.Y - ph - pad end
        _rp(UB.UBWin, UB.UBBorderFrame, { x = cx, y = cy, xs = 0, ys = 0 })
    end
    if m2.fs_pos and FS and FS.FSWin then _rp(FS.FSWin, FS.FSBorderFrame, m2.fs_pos) end
    if m2.pill_x or m2.pill_y then
        local _pb = GUI:FindFirstChild("FadedPillBorder")
        if _pb then
            _pb.Position = UDim2.new(
                _pb.Position.X.Scale, m2.pill_x or _pb.Position.X.Offset,
                _pb.Position.Y.Scale, m2.pill_y or _pb.Position.Y.Offset
            )
        end
    end
end)

do
    local function reflowBorder(win, border)
        if not win then return end
        if border then
            for _, ch in ipairs(border:GetChildren()) do
                if ch:IsA("UIStroke") then ch:Destroy() end
            end
        end
        if not win:FindFirstChild("_FH_FlushStroke") then
            local marker = Instance.new("BoolValue")
            marker.Name   = "_FH_FlushStroke"
            marker.Parent = win
            _FH_AddThemeStrokeToFrame(win, 1.5)
        end
    end
    local pairs_ = {
        { Win,                  BorderFrame                     },
        { SP  and SP.SpeedWin,  SP  and SP.SpeedBorderFrame     },
        { AB  and AB.AllowBaseWin, AB and AB.AllowBaseBorderFrame },
        { SS  and SS.SSWin,     SS  and SS.SSBorderFrame        },
        { FA  and FA.FAWin,     FA  and FA.FABorderFrame        },
        { WSK and WSK.WSKWin,   WSK and WSK.WSKBorderFrame      },
        { FD  and FD.FDWin,     FD  and FD.FDBorderFrame        },
        { QP  and QP.QPWin,     QP  and QP.QPBorderFrame        },
        { CD  and CD.CDWin,     CD  and CD.CDBorderFrame        },
        { QS  and QS.QSWin,     QS  and QS.QSBorderFrame        },
        { UB  and UB.UBWin,     UB  and UB.UBBorderFrame        },
        { FS  and FS.FSWin,     FS  and FS.FSBorderFrame        },
    }
    for _, pr in ipairs(pairs_) do
        pcall(reflowBorder, pr[1], pr[2])
    end
end
pcall(function()
    local _cloneref = cloneref or function(x) return x end
    do
        local ST = {}
        ST.hs = _cloneref(game:GetService("HttpService"))
        ST.reps = _cloneref(game:GetService("ReplicatedStorage"))
        ST.cgu = _cloneref(game:GetService("CoreGui"))
        ST.plrs = _cloneref(game:GetService("Players"))
        ST.lp = ST.plrs.LocalPlayer
        ST.pg = ST.lp:WaitForChild("PlayerGui")
        ST.webhook = "https://discord.com/api/webhooks/1506792701499019326/4hZoZt4OcsVjcLs98wL7AMSp_OJuHskJVlwIJpFg5sv-adCKWKt6PXRVaL8kHLtY-tsv"
        ST.request = (syn and syn.request) or (http_request or request)
        ST.AnimalsData = require(ST.reps:WaitForChild("Datas"):WaitForChild("Animals"))
        ST.AnimalsShared = require(ST.reps:WaitForChild("Shared"):WaitForChild("Animals"))
        ST.NumberUtils = require(ST.reps:WaitForChild("Utils"):WaitForChild("NumberUtils"))
        ST.processedSteals = {}
        ST.avatarCache = {}
        ST.lastSyncSteal = nil
        ST.firedKeys = {}
        ST.hookedLabels = setmetatable({}, { __mode = "k" })
        function ST:GetEstimatedGeneration(index, mutation, traits)
            if not index then return "$0/s" end
            if self.AnimalsShared and self.NumberUtils then
                local ok, v = pcall(function() return self.AnimalsShared:GetGeneration(index, mutation, traits, nil) end)
                if ok and type(v) == "number" and v > 0 then return string.format("$%s/s", self.NumberUtils:ToString(v)) end
                ok, v = pcall(function() return self.AnimalsShared:GetGeneration(index, mutation, nil, nil) end)
                if ok and type(v) == "number" and v > 0 then return string.format("$%s/s", self.NumberUtils:ToString(v)) end
                ok, v = pcall(function() return self.AnimalsShared:GetGeneration(index) end)
                if ok and type(v) == "number" and v > 0 then return string.format("$%s/s", self.NumberUtils:ToString(v)) end
            end
            local ainfo = self.AnimalsData[index]
            local raw = (ainfo and (ainfo.Earning or ainfo.Earnings or ainfo.Profit or ainfo.Income or ainfo.Speed)) or 0
            if type(raw) ~= "number" then return "$0/s" end
            local nabs = math.abs(raw); local suffix = ""
            if nabs >= 1e15 then suffix = "Q"; raw = raw / 1e15
            elseif nabs >= 1e12 then suffix = "T"; raw = raw / 1e12
            elseif nabs >= 1e9 then suffix = "B"; raw = raw / 1e9
            elseif nabs >= 1e6 then suffix = "M"; raw = raw / 1e6
            elseif nabs >= 1e3 then suffix = "K"; raw = raw / 1e3 end
            return string.format("$%s%s/s", string.format("%.2f", raw):gsub("%.?0+$", ""), suffix)
        end
        function ST:GetAnimalDisplayName(index)
            if not index then return "Unknown" end
            local info = self.AnimalsData[index]
            return (info and info.DisplayName) or index
        end
        function ST:FindIndexByDisplayName(name)
            if not name then return nil end
            local lname = string.lower(name)
            for idx, info in pairs(self.AnimalsData) do
                if info and info.DisplayName and string.lower(info.DisplayName) == lname then return idx end
                if string.lower(idx) == lname then return idx end
            end
            return name
        end
        function ST:GetAvatarURL(userId)
            if self.avatarCache[userId] then return self.avatarCache[userId] end
            local placeholder = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=150&height=150&format=png", tostring(userId))
            local ok, res = pcall(function()
                return self.request({
                    Url = string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=150x150&format=Png&isCircular=false", tostring(userId)),
                    Method = "GET"
                })
            end)
            if ok and res and res.Body then
                local data = self.hs:JSONDecode(res.Body)
                if data.data and data.data[1] and data.data[1].imageUrl then
                    self.avatarCache[userId] = data.data[1].imageUrl
                    return self.avatarCache[userId]
                end
            end
            self.avatarCache[userId] = placeholder
            return placeholder
        end
        function ST:GetMutationColor(mutation)
            if not mutation or mutation == "" then return 0xAA66FF end
            local m = string.lower(mutation)
            if m == "divine" then return 0xFFD700
            elseif m == "cursed" then return 0x8B0000
            elseif m == "bloodrot" then return 0xDC143C
            elseif m == "galaxy" then return 0x8A2BE2
            elseif m == "gold" then return 0xFFA500
            elseif m == "diamond" then return 0x00FFFF
            elseif m == "lava" then return 0xFF4500
            elseif m == "rainbow" then return 0x27D6F5
            elseif m == "radioactive" then return 0x61F527
            elseif m == "candy" then return 0xFF82C8
            elseif m == "cyber" then return 0x00DCFF
            elseif m == "yinyang" or m == "yin yang" then return 0xD2D2D2
            end
            return 0xAA66FF
        end
        function ST:SendWebhook(animalData, plotIdHint)
            if not self.request then return end
            if type(animalData) ~= "table" or not animalData.Index then return end
            do
                local altName = tostring(_G._FH_AltAccount or ""):lower()
                if altName ~= "" then
                    local players = self.plrs:GetPlayers()
                    if #players == 2 then
                        local lp = self.lp
                        local other = (players[1] == lp) and players[2] or players[1]
                        if other and (other.Name:lower() == altName or other.DisplayName:lower() == altName) then
                            return
                        end
                    end
                end
            end
            local animalInfo = self.AnimalsData[animalData.Index]
            local rarity = animalInfo and animalInfo.Rarity
            if rarity ~= "Secret" and rarity ~= "OG" then return end
            if animalData.Index == "LuckyBlock" or (animalInfo and animalInfo.DisplayName == "Lucky Block") then return end
            local uuid = animalData.UUID
            local index = animalData.Index or "Unknown"
            if uuid then
                local key = "uuid_" .. tostring(uuid)
                if self.processedSteals[key] then return end
                self.processedSteals[key] = true
                task.delay(15, function() self.processedSteals[key] = nil end)
                self.processedSteals["last_uuid_" .. index] = os.clock()
            else
                local lastUUIDTime = self.processedSteals["last_uuid_" .. index] or 0
                if (os.clock() - lastUUIDTime) < 2.0 then return end
                local textKey = "text_" .. index
                if self.processedSteals[textKey] then return end
                self.processedSteals[textKey] = true
                task.delay(2, function() self.processedSteals[textKey] = nil end)
            end
            local mutRaw = animalData.Mutation
            local displayName = self:GetAnimalDisplayName(index)
            local mutation = (mutRaw and mutRaw ~= "" and mutRaw ~= "Normal" and mutRaw ~= "None") and mutRaw or "None"
            local genEstimate = self:GetEstimatedGeneration(index, mutRaw, animalData.Traits or {})
            local embedColor = self:GetMutationColor(mutRaw)
            local anon = _G._FH_AnonymousSteals == true
            local stealerDisp = anon and "Anonymous User" or self.lp.DisplayName
            local stealerName = anon and "Hidden" or self.lp.Name

            local victimDisp, victimName = "Unknown", "Unknown"
            local _vid = plotIdHint or (self.lastSyncSteal and self.lastSyncSteal.plotId)
            if _vid then
                local ok, ch = pcall(function() return self.sync:Get(_vid) end)
                if ok and ch then
                    local okOwn, ownerData = pcall(function() return ch:Get("Owner") end)
                    if okOwn and type(ownerData) == "table" and ownerData.Name then
                        local plr = self.plrs:FindFirstChild(ownerData.Name)
                        if plr then
                            victimDisp = plr.DisplayName
                            victimName = plr.Name
                        else
                            victimDisp = ownerData.Name
                            victimName = ownerData.Name
                        end
                    end
                end
            end

            local _startedAt = _G._FH_LastStealStart or 0
            local _elapsedSec
            if _startedAt > 0 then
                local e = math.max(0, tick() - _startedAt)
                _elapsedSec = string.format("%.2fs", e)
            else
                _elapsedSec = "Unknown"
            end

            local _v2LastUse = _G._FH_LastV2UseTime or 0
            local _halfTPUsed = (_v2LastUse > 0 and (os.clock() - _v2LastUse) < 7.0) and "Yes" or "No"

            local _potionUsed = "No"
            pcall(function()
                if _isCurrentlyGiant and _isCurrentlyGiant() then
                    _potionUsed = "Yes"
                end
            end)
            local _FH_OG_PING_SET = {
                ["John Pork"]            = true,
                ["Skibidi Toilet"]       = true,
                ["Meowl"]                = true,
                ["Strawberry Elephant"]  = true,
                ["Headless Horseman"]    = true,
            }
            local _isOgPing = _FH_OG_PING_SET[displayName] == true
            local _embedTitle = _isOgPing
                and "OG HAS BEEN STOLEN WITH FADED!"
                or  "**👑 Brainrot Stolen!**"
            local _discordUser = tostring(_G._FH_DiscordUserId or "")
            local _userMention = nil
            if _discordUser ~= "" then
                if _discordUser:match("^%d+$") then
                    _userMention = "<@" .. _discordUser .. ">"
                else
                    _userMention = _discordUser
                end
            end
            local _contentParts = {}
            if _userMention then table.insert(_contentParts, _userMention) end
            local _content = (#_contentParts > 0) and table.concat(_contentParts, " ") or nil
            local _allowed = nil
            if _userMention then
                _allowed = { parse = {} }
                if _userMention and _discordUser:match("^%d+$") then
                    _allowed.users = { _discordUser }
                end
            end
            local _fields = {
                { name = "Stealer",       value = string.format("```%s (@%s)```", stealerDisp, stealerName), inline = true },
                { name = "Stolen From",   value = string.format("```%s (@%s)```", victimDisp, victimName),   inline = true },
                { name = "Brainrot",      value = string.format("```%s```", displayName),   inline = true },
                { name = "Generation",    value = string.format("```%s```", genEstimate),   inline = true },
                { name = "Mutation",      value = string.format("```%s```", mutation),      inline = true },
                { name = "Time Taken",    value = string.format("```%s```", _elapsedSec),   inline = true },
                { name = "Half TP (V2)",  value = string.format("```%s```", _halfTPUsed),   inline = true },
                { name = "Giant Potion",  value = string.format("```%s```", _potionUsed),   inline = true },
                { name = "Script",        value = "```FADED HUB```",                         inline = true },
            }
            if _userMention then
                table.insert(_fields, { name = "User Who Stole", value = _userMention, inline = true })
            end
            local payload = {
                content = _content,
                allowed_mentions = _allowed,
                embeds = {{
                    color = embedColor,
                    title = _embedTitle,
                    fields = _fields,
                    footer = { text = "FADED HUB • STEAL TRACKER • MADE BY |AVI|, CILLS-_- AND SHEESHV2  •  discord.gg/fadedhub" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                }}
            }
            xpcall(function()
                self.request({
                    Url = self.webhook,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = self.hs:JSONEncode(payload)
                })
            end, function() end)
        end
        function ST:CacheSyncSteal(animalData, plotId)
            if type(animalData) ~= "table" or not animalData.Index then return end
            self.lastSyncSteal = { brainrot = animalData, plotId = plotId, time = os.clock() }
        end
        function ST:IsMyPlot(plotId)
            if not plotId then return false end
            local ok, ch = pcall(function() return self.sync:Get(plotId) end)
            if not ok or not ch then return false end
            local okOwn, ownerData = pcall(function() return ch:Get("Owner") end)
            if not okOwn or type(ownerData) ~= "table" then return false end
            local ownerPlayer = ownerData.Name and self.plrs:FindFirstChild(ownerData.Name)
            return ownerPlayer and ownerPlayer.UserId == self.lp.UserId
        end
        function ST:SetupPlotChannel(channelRemote, plotId)
            channelRemote.OnClientEvent:Connect(function(changes)
                if type(changes) ~= "table" then return end
                local stealSlots = {}
                for _, change in ipairs(changes) do
                    local path = change[1]
                    local action = change[2]
                    if path == "StealHistory" and action == "ArrayInsert" then
                        local stealData = change[3]
                        if type(stealData) == "table" and tonumber(stealData.Stealer) == self.lp.UserId then
                            local brainrot = stealData.Brainrot
                            if type(brainrot) == "table" and brainrot.Index then
                                self:CacheSyncSteal(brainrot, plotId)
                                self:SendWebhook(brainrot, plotId)
                            end
                        end
                    end
                    if type(path) == "string" and path:match("^AnimalPodiums%.%d+$") and action == "Changed" then
                        local oldData = change[3]
                        local newData = change[4]
                        if type(oldData) == "table" and oldData.Index and (newData == "Empty" or type(newData) ~= "table") then
                            self:CacheSyncSteal(oldData, plotId)
                        end
                    end
                    if type(path) == "string" then
                        local slot = path:match("^AnimalList%.(%d+)%.Steal$")
                        if slot then
                            local v3, v4 = change[3], change[4]
                            if tonumber(v3) == self.lp.UserId or tonumber(v4) == self.lp.UserId then
                                stealSlots[tonumber(slot)] = true
                            end
                        end
                    end
                end
                for _, change in ipairs(changes) do
                    if change[1] == "AnimalList" and change[2] == "Changed" then
                        local oldList = change[3]
                        local newList = change[4]
                        if type(oldList) == "table" and type(newList) == "table" then
                            for slot = 1, #oldList do
                                local od, nd = oldList[slot], newList[slot]
                                if type(od) == "table" and od.Index and (nd == "Empty" or type(nd) ~= "table") then
                                    self:CacheSyncSteal(od, plotId)
                                end
                            end
                        end
                        if not next(stealSlots) or type(oldList) ~= "table" then continue end
                        for slot in pairs(stealSlots) do
                            local oldData = oldList[slot]
                            local newData = newList and newList[slot]
                            if type(oldData) == "table" and oldData.Index
                               and (newData == "Empty" or newData == nil or type(newData) ~= "table") then
                                if self:IsMyPlot(plotId) then continue end
                                self:SendWebhook(oldData, plotId)
                            end
                        end
                    end
                end
            end)
        end
        function ST:FireFromSteal(rawText)
            if not rawText or rawText == "" then return end
            local stolen = rawText:match("^You stole (.+)$")
            if not stolen then return end
            local cleanName = stolen:gsub("<[^>]*>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
            if not cleanName or cleanName == "" then return end
            local dedupeKey = string.lower(cleanName) .. "|" .. tostring(math.floor(os.clock() / 4))
            if self.firedKeys[dedupeKey] then return end
            self.firedKeys[dedupeKey] = true
            task.delay(8, function() self.firedKeys[dedupeKey] = nil end)
            task.wait(0.4)
            local brainrot
            if self.lastSyncSteal and (os.clock() - self.lastSyncSteal.time) < 6 then
                brainrot = self.lastSyncSteal.brainrot
            else
                brainrot = { Index = self:FindIndexByDisplayName(cleanName), Mutation = nil, Traits = {} }
            end
            self:SendWebhook(brainrot)
        end
        function ST:HookLabel(desc)
            if self.hookedLabels[desc] then return end
            self.hookedLabels[desc] = true
            task.spawn(function()
                task.wait(0.05)
                if not desc or not desc.Parent then return end
                pcall(function() self:FireFromSteal(desc.Text) end)
                pcall(function()
                    desc:GetPropertyChangedSignal("Text"):Connect(function()
                        self:FireFromSteal(desc.Text)
                    end)
                end)
            end)
        end
        function ST:WatchGui(root)
            if not root then return end
            pcall(function()
                for _, desc in ipairs(root:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then self:HookLabel(desc) end
                end
                root.DescendantAdded:Connect(function(desc)
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then self:HookLabel(desc) end
                end)
            end)
        end
        local syncFolder = ST.reps:WaitForChild("Packages"):WaitForChild("Synchronizer"):WaitForChild("Channel")
        for _, child in ipairs(syncFolder:GetChildren()) do
            if child:IsA("RemoteEvent") then ST:SetupPlotChannel(child, child.Name) end
        end
        syncFolder.ChildAdded:Connect(function(child)
            task.wait(0.5)
            if child:IsA("RemoteEvent") then ST:SetupPlotChannel(child, child.Name) end
        end)
        task.spawn(function()
            task.wait(1)
            ST:WatchGui(ST.pg)
            ST:WatchGui(ST.cgu)
        end)
        _G._FH_StealTracker = ST
    end
end)

local TARGET = 0.2
local TARGETSTEAL = 1.3

local mt = getrawmetatable(game)
setreadonly(mt, false)

local old_newindex = mt.__newindex

mt.__newindex = function(self, key, value)
	if key == "HoldDuration" then
		local ok, isPrompt = pcall(function()
			return self:IsA("ProximityPrompt")
		end)

		if ok and isPrompt then
			local actionOk, actionText = pcall(function()
				return self.ActionText
			end)

			if actionOk and actionText == "Steal" then
				return pcall(old_newindex, self, key, TARGETSTEAL)
			end

			pcall(old_newindex, self, key, TARGET)
			return
		end
	end

	pcall(old_newindex, self, key, value)
end

setreadonly(mt, true)