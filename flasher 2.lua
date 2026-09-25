-- script in discord.gg/rymogs

if not game:IsLoaded() then game.Loaded:Wait() end

local flashid = "rbxassetid://70883871260184"
local TP = 2.5
local PRIO = Enum.AnimationPriority.Action4

local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local hs = game:GetService("HttpService")
local ts = game:GetService("TweenService")

local lp = plrs.LocalPlayer
while not lp do
    task.wait()
    lp = plrs.LocalPlayer
end
if not lp.Character then lp.CharacterAdded:Wait() end
lp.Character:WaitForChild("Humanoid")

local F = "rymogsflash.json"
local cfg = { flash = false, spam = false, anti = false, w = 0.03, s = 0.2, px = 50, py = 130 }

if isfile and isfile(F) then
    local ok, d = pcall(function() return hs:JSONDecode(readfile(F)) end)
    if ok and type(d) == "table" then
        for k, v in pairs(d) do
            if cfg[k] ~= nil then cfg[k] = v end
        end
    end
end

if type(cfg.px) ~= "number" then cfg.px = 50 end
if type(cfg.py) ~= "number" then cfg.py = 130 end

local function save()
    pcall(function()
        if writefile then writefile(F, hs:JSONEncode(cfg)) end
    end)
end

-- Black and Grey Theme with Transparency Settings
local Theme = {
    Bg       = Color3.fromRGB(15, 15, 15),
    Panel    = Color3.fromRGB(25, 25, 25),
    Row      = Color3.fromRGB(35, 35, 35),
    Accent   = Color3.fromRGB(120, 120, 120),
    On       = Color3.fromRGB(180, 180, 180),
    Off      = Color3.fromRGB(30, 30, 30),
    Text     = Color3.fromRGB(240, 240, 240),
    Dim      = Color3.fromRGB(150, 150, 150),
}

local UI_TRANSPARENCY = 0.25 -- Adjustable transparency for panels/backgrounds

local function stroke(inst, col, thick, trans)
    local e = Instance.new("UIStroke")
    e.Color = col or Theme.Accent
    e.Thickness = thick or 1
    e.Transparency = trans or 0.5
    e.Parent = inst
    return e
end

local function tween(inst, props, t)
    ts:Create(inst, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad), props):Play()
end

local tracks = {}
local err, togup = "off", {}

local skinok = false

local function checkskin()
    local chr = lp.Character
    if not chr then return end
    for _, d in ipairs(chr:GetDescendants()) do
        if d:IsA("MeshPart") then
            local ok, v = pcall(function() return d.HasSkinnedMesh end)
            if ok and v then
                skinok = true
                return
            end
        end
    end
end

local function hasskin()
    return skinok
end

local function setstat()
end

local anims = {}
local pulseToken = 0
local pulsing = false
local heldAnim

local function killtracks(list)
    for _, t in ipairs(list) do
        pcall(function() t:AdjustWeight(0, 0) end)
        pcall(function() t:Stop(0) end)
        pcall(function() t:Destroy() end)
    end
end

local function cleartracks()
    killtracks(tracks)
    tracks = {}
end

local function fireflash()
    local chr = lp.Character
    if not chr then err = "no character" setstat() return false end
    local anm = chr:FindFirstChildWhichIsA("Animator", true)
    if not anm then err = "no animator" setstat() return false end
    if not heldAnim or heldAnim.Parent ~= anm then
        if heldAnim then pcall(function() heldAnim:Destroy() end) end
        heldAnim = Instance.new("Animation")
        heldAnim.Name = "RymogsFlash"
        heldAnim.AnimationId = flashid
        heldAnim.Parent = anm
        anims[1] = heldAnim
    end

    local t
    if anm.LoadAnimationCoreScript then
        local ok, res = pcall(function() return anm:LoadAnimationCoreScript(heldAnim) end)
        if ok then t = res else err = tostring(res) end
    end
    if not t then
        local ok, res = pcall(function() return anm:LoadAnimation(heldAnim) end)
        if ok then t = res else err = tostring(res) end
    end
    if not t then
        warn("[rymogs flash] load failed: " .. tostring(err))
        setstat()
        return false
    end

    local speed = cfg.spam and cfg.s or 0
    pcall(function()
        t.Looped = true
        t.Priority = PRIO
        t:Play(0, cfg.w, speed)
        t:AdjustSpeed(speed)
        t:AdjustWeight(cfg.w, 0)
        if not cfg.spam then
            t.TimePosition = TP
        end
    end)
    local old = tracks
    tracks = { t }
    if #old > 0 then
        task.defer(function()
            killtracks(old)
        end)
    end
    err = ""
    setstat()
    return true
end

local function stopflash()
    pulseToken += 1
    pulsing = false
    cleartracks()
    if heldAnim then
        pcall(function() heldAnim:Destroy() end)
        heldAnim = nil
    end
    anims = {}
end

local function startflash()
    if pulsing then return end
    pulsing = true
    local token = pulseToken
    task.spawn(function()
        while cfg.flash and token == pulseToken do
            fireflash()
            task.wait(0.032)
        end
        if token == pulseToken then
            pulsing = false
        end
    end)
end

local function restart()
    if not cfg.flash then return end
    stopflash()
    startflash()
end

local function apply()
    if cfg.flash and not hasskin() then
        checkskin()
    end
    if cfg.flash and not hasskin() and not cfg.anti then
        cfg.flash = false
        if togup.flash then togup.flash() end
        save()
    end
    if not cfg.flash then
        stopflash()
        err = "off"
        setstat()
        return
    end
    if not pulsing then
        startflash()
    end
end

local map

local function donor()
    if map then return map end
    map = {}
    pcall(function()
        local r = plrs:CreateHumanoidModelFromDescription(
            Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        for _, d in ipairs(r:GetChildren()) do
            if d:IsA("MeshPart") then map[d.Name] = d.MeshId end
        end
        r:Destroy()
    end)
    return map
end

local orig = setmetatable({}, { __mode = "k" })
local antiConns = {}
local antiToken = 0

local function isFlashTrack(track)
    local id = ""
    pcall(function()
        local anim = track.Animation
        if anim then id = tostring(anim.AnimationId) end
    end)
    return id ~= "" and string.find(id, "70883871260184", 1, true) ~= nil
end

local function unskin(c)
    if not c then return end
    local mp = donor()
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("MeshPart") then
            pcall(function()
                local skinned = d.HasSkinnedMesh
                if skinned then
                    if orig[d] == nil then orig[d] = d.MeshId end
                    if mp[d.Name] then
                        d.MeshId = mp[d.Name]
                    end
                    d.HasSkinnedMesh = false
                end
            end)
        elseif d:IsA("WrapLayer") or d:IsA("WrapTarget") then
            pcall(function() d:Destroy() end)
        end
    end
end

local function stopOtherFlash(c, owner)
    if owner == lp then return end
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    local anm = hum and hum:FindFirstChildOfClass("Animator")
    if not anm then return end
    for _, track in ipairs(anm:GetPlayingAnimationTracks()) do
        if isFlashTrack(track) then
            pcall(function() track:Stop(0) end)
        end
    end
end

local function harden(player)
    local c = player and player.Character
    if not c then return end
    unskin(c)
    stopOtherFlash(c, player)
end

local function reskin()
    for d, id in pairs(orig) do
        pcall(function()
            d.MeshId = id
            d.HasSkinnedMesh = true
        end)
    end
    table.clear(orig)
end

local function stopAnti()
    antiToken += 1
    for i = 1, #antiConns do
        pcall(function() antiConns[i]:Disconnect() end)
    end
    table.clear(antiConns)
    reskin()
end

local function startAnti()
    stopAnti()
    cfg.anti = true
    local token = antiToken
    local function bind(player)
        if not player then return end
        antiConns[#antiConns + 1] = player.CharacterAdded:Connect(function(c)
            if not cfg.anti or token ~= antiToken then return end
            task.defer(harden, player)
            antiConns[#antiConns + 1] = c.DescendantAdded:Connect(function(d)
                if not cfg.anti or token ~= antiToken then return end
                if d:IsA("MeshPart") or d:IsA("WrapLayer") or d:IsA("WrapTarget") then
                    task.defer(unskin, c)
                elseif d:IsA("Animator") and player ~= lp then
                    antiConns[#antiConns + 1] = d.AnimationPlayed:Connect(function(track)
                        if cfg.anti and isFlashTrack(track) then
                            pcall(function() track:Stop(0) end)
                        end
                    end)
                end
            end)
        end)
        if player.Character then
            harden(player)
            local c = player.Character
            antiConns[#antiConns + 1] = c.DescendantAdded:Connect(function(d)
                if not cfg.anti or token ~= antiToken then return end
                if d:IsA("MeshPart") or d:IsA("WrapLayer") or d:IsA("WrapTarget") then
                    task.defer(unskin, c)
                end
            end)
            local hum = c:FindFirstChildOfClass("Humanoid")
            local anm = hum and hum:FindFirstChildOfClass("Animator")
            if anm and player ~= lp then
                antiConns[#antiConns + 1] = anm.AnimationPlayed:Connect(function(track)
                    if cfg.anti and isFlashTrack(track) then
                        pcall(function() track:Stop(0) end)
                    end
                end)
            end
        end
    end

    for _, player in ipairs(plrs:GetPlayers()) do
        bind(player)
    end
    antiConns[#antiConns + 1] = plrs.PlayerAdded:Connect(bind)

    task.spawn(function()
        while cfg.anti and token == antiToken do
            for _, player in ipairs(plrs:GetPlayers()) do
                harden(player)
            end
            task.wait(0.05)
        end
    end)
end

local function applyAnti()
    if cfg.anti then
        startAnti()
    else
        stopAnti()
    end
end

lp.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid")
    skinok = false
    checkskin()
    task.wait(1.5)
    checkskin()
    stopflash()
    apply()
end)

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local old = guiParent:FindFirstChild("RymogsFlasher")
    if old then old:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "RymogsFlasher"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = guiParent

local PW, PH = 228, 196

local m = Instance.new("Frame")
m.Name = "Panel"
m.Size = UDim2.new(0, PW, 0, PH)
m.Position = UDim2.new(0, cfg.px, 0, cfg.py)
m.BackgroundColor3 = Theme.Bg
m.BackgroundTransparency = UI_TRANSPARENCY
m.BorderSizePixel = 0
m.Parent = sg
stroke(m, Theme.Accent, 1, 0.5)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 28)
bar.BackgroundColor3 = Theme.Panel
bar.BackgroundTransparency = UI_TRANSPARENCY
bar.BorderSizePixel = 0
bar.Parent = m

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 0, 10)
barFill.Position = UDim2.new(0, 0, 1, -10)
barFill.BackgroundColor3 = Theme.Panel
barFill.BackgroundTransparency = UI_TRANSPARENCY
barFill.BorderSizePixel = 0
barFill.Parent = bar

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 6, 0, 6)
dot.Position = UDim2.new(0, 10, 0.5, -3)
dot.BackgroundColor3 = Theme.Accent
dot.BorderSizePixel = 0
dot.Parent = bar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -118, 1, 0)
title.Position = UDim2.new(0, 22, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Theme.Text
title.Text = "rymogs flasher"
title.Parent = bar

local brand = Instance.new("TextLabel")
brand.Size = UDim2.new(0, 92, 1, 0)
brand.Position = UDim2.new(1, -100, 0, 0)
brand.BackgroundTransparency = 1
brand.Font = Enum.Font.Gotham
brand.TextSize = 9
brand.TextXAlignment = Enum.TextXAlignment.Right
brand.TextColor3 = Theme.Dim
brand.Text = "discord.gg/rymogs"
brand.Parent = bar

local function savepos()
    cfg.px = math.floor(m.Position.X.Offset + 0.5)
    cfg.py = math.floor(m.Position.Y.Offset + 0.5)
    save()
end

do
    local ds, sp, dg
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dg = true ds = i.Position sp = m.Position
        end
    end)
    uis.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            m.Position = UDim2.new(0, sp.X.Offset + d.X, 0, sp.Y.Offset + d.Y)
        end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            if dg then savepos() end
            dg = false
        end
    end)
end

local function mktog(y, txt, key, fn)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(0, 8, 0, y)
    b.Size = UDim2.new(1, -16, 0, 24)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.TextColor3 = Theme.Text
    b.BackgroundTransparency = UI_TRANSPARENCY
    b.AutoButtonColor = false
    b.Parent = m

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 30, 0, 14)
    pill.Position = UDim2.new(1, -38, 0.5, -7)
    pill.BorderSizePixel = 0
    pill.Parent = b

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(0, 2, 0.5, -5)
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Theme.Text
    knob.Parent = pill

    local function up()
        local on = cfg[key]
        tween(b, { BackgroundColor3 = on and Color3.fromRGB(45, 45, 45) or Theme.Off })
        tween(pill, { BackgroundColor3 = on and Theme.On or Color3.fromRGB(50, 50, 50) })
        tween(knob, { Position = on and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) })
        b.Text = "  " .. txt
        b.TextXAlignment = Enum.TextXAlignment.Left
    end
    togup[key] = up
    b.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        up()
        save()
        apply()
        up()
        if fn then fn() end
    end)
    b.MouseEnter:Connect(function()
        tween(b, { BackgroundColor3 = cfg[key] and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40) })
    end)
    b.MouseLeave:Connect(up)
    up()
end

local function mksld(y, txt, key, mn, mx, st, ph)
    local row = Instance.new("Frame")
    row.Position = UDim2.new(0, 8, 0, y)
    row.Size = UDim2.new(1, -16, 0, 32)
    row.BackgroundColor3 = Theme.Off
    row.BackgroundTransparency = UI_TRANSPARENCY
    row.BorderSizePixel = 0
    row.Parent = m

    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 8, 0, 3)
    l.Size = UDim2.new(0, 90, 0, 12)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Theme.Dim
    l.Text = txt
    l.Parent = row

    local tb = Instance.new("TextBox")
    tb.Position = UDim2.new(1, -50, 0, 3)
    tb.Size = UDim2.new(0, 42, 0, 12)
    tb.BackgroundTransparency = 1
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 10
    tb.TextXAlignment = Enum.TextXAlignment.Right
    tb.TextColor3 = Theme.Text
    tb.ClearTextOnFocus = true
    tb.PlaceholderText = ph
    tb.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
    tb.Parent = row

    local b = Instance.new("Frame")
    b.Position = UDim2.new(0, 8, 0, 18)
    b.Size = UDim2.new(1, -16, 0, 5)
    b.BackgroundColor3 = Theme.Row
    b.BorderSizePixel = 0
    b.Parent = row

    local f = Instance.new("Frame")
    f.BackgroundColor3 = Theme.Accent
    f.BorderSizePixel = 0
    f.Parent = b

    local k = Instance.new("Frame")
    k.Size = UDim2.new(0, 10, 0, 10)
    k.BackgroundColor3 = Theme.Text
    k.BorderSizePixel = 0
    k.Parent = b

    local function refresh()
        local rel = (cfg[key] - mn) / (mx - mn)
        f.Size = UDim2.new(rel, 0, 1, 0)
        k.Position = UDim2.new(rel, -5, 0.5, -5)
        tb.Text = string.format("%.2f", cfg[key])
    end

    local function put(v)
        v = math.floor(v / st + 0.5) * st
        cfg[key] = math.clamp(v, mn, mx)
        refresh()
        save()
        apply()
    end

    local function set(x)
        local rel = math.clamp((x - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
        put(mn + rel * (mx - mn))
    end

    local sl
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            sl = true set(i.Position.X)
        end
    end)
    k.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            sl = true set(i.Position.X)
        end
    end)
    uis.InputChanged:Connect(function(i)
        if sl and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            set(i.Position.X)
        end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then sl = false end
    end)

    tb.FocusLost:Connect(function()
        local n = tonumber(tb.Text)
        if n then put(n) else refresh() end
    end)

    refresh()
end

mktog(34, "FLASH", "flash")
mktog(60, "SPAM", "spam", restart)
mktog(86, "ANTI FLASH", "anti", applyAnti)

mksld(116, "SIZE", "w", 0.01, 1, 0.01, "0.03")
mksld(152, "SPAM SPEED", "s", 0.05, 2, 0.05, "0.20")

checkskin()
task.wait(0.5)
checkskin()
apply()
applyAnti()
setstat()