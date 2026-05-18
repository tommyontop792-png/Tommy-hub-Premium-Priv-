-- ============================================================
--  TOMMY HUB  |  Bounty Abuse v3
--  - Minimizable
--  - Sin Auto Z Sword
--  - Sky Launch (90,000 metros)
--  - Auto Z Melee + INF con Spawn Abuse Reset
--  - Server Hop avanzado (ServerBrowser + API fallback)
-- ============================================================

local Players             = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local TeleportService     = game:GetService("TeleportService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")

local lp      = Players.LocalPlayer
local _place  = game.PlaceId
local _id     = game.JobId

-- ── Estado global ──
getgenv().AbuseActive    = false
getgenv().SelectedSlot   = Enum.KeyCode.Three
getgenv().AutoZMelee     = false
getgenv().AutoSVHop      = false
getgenv().InfMeleeActive = false

local bountyInicial  = 0
local killsSesion    = 0
local sessionStart   = os.time()
local svHopStatus    = ""

-- ============================================================
--  SERVER HOP AVANZADO (ServerBrowser + API fallback)
-- ============================================================
getgenv().HopConfig = getgenv().HopConfig or {
    minPlayers  = 8,
    maxPlayers  = 11,
    minBounty   = nil,
    maxBounty   = nil,
    region      = nil,
    fallbackAny = true,
}

local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")

local function HopAdvanced()
    local hc = getgenv().HopConfig
    local allServers = {}
    local useInternal = false
    local foundData = false
    local pendingCount = 0

    if browser then
        for page = 1, 100 do
            if foundData then break end
            pendingCount = pendingCount + 1
            task.spawn(function()
                local ok, result = pcall(function()
                    return browser:InvokeServer(page)
                end)
                if ok and type(result) == "table" then
                    local valid = 0
                    for uuid, info in pairs(result) do
                        if type(info) == "table" and info.Count then
                            allServers[uuid] = info
                            valid = valid + 1
                        end
                    end
                    if valid > 0 and not foundData then
                        foundData = true
                        useInternal = true
                    end
                end
                pendingCount = pendingCount - 1
            end)
        end

        local waited = 0
        while pendingCount > 0 and waited < 6 do
            task.wait(0.2); waited += 0.2
            if foundData and waited > 1 then break end
        end
    end

    local apiServers = {}
    if not useInternal then
        pcall(function()
            local r = HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. _place
                .. "/servers/Public?sortOrder=Desc&limit=100"
            ))
            if r and r.data then
                for _, sv in ipairs(r.data) do table.insert(apiServers, sv) end
            end
        end)
        pcall(function()
            local r = HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. _place
                .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
            if r and r.data then
                for _, sv in ipairs(r.data) do table.insert(apiServers, sv) end
            end
        end)
        if #apiServers == 0 then
            TeleportService:Teleport(_place, lp)
            return false
        end
    end

    local seen, matched, anyValid = {}, {}, {}

    if useInternal then
        for uuid, info in pairs(allServers) do
            if uuid ~= _id then
                local count  = info.Count or 0
                local bounty = info.Bounty or 0
                local region = info.Region or ""
                local entry  = {uuid=uuid, count=count, maxP=12, bounty=bounty, region=region}
                table.insert(anyValid, entry)
                local ok = true
                if hc.minPlayers and count  < hc.minPlayers then ok = false end
                if hc.maxPlayers and count  > hc.maxPlayers then ok = false end
                if hc.minBounty  and bounty < hc.minBounty  then ok = false end
                if hc.maxBounty  and bounty > hc.maxBounty  then ok = false end
                if hc.region and hc.region ~= "" then
                    if not string.find(string.lower(region), string.lower(hc.region), 1, true) then
                        ok = false
                    end
                end
                if ok then table.insert(matched, entry) end
            end
        end
    else
        for _, sv in ipairs(apiServers) do
            if sv.id and sv.id ~= _id and not seen[sv.id]
               and sv.playing and sv.maxPlayers
               and sv.playing < sv.maxPlayers then
                seen[sv.id] = true
                local entry = {uuid=sv.id, count=sv.playing, maxP=sv.maxPlayers, bounty=0, region="?"}
                table.insert(anyValid, entry)
                local ok = true
                if hc.minPlayers and sv.playing < hc.minPlayers then ok = false end
                if hc.maxPlayers and sv.playing > hc.maxPlayers then ok = false end
                if ok then table.insert(matched, entry) end
            end
        end
    end

    if #matched == 0 then
        if not hc.fallbackAny or #anyValid == 0 then
            TeleportService:Teleport(_place, lp)
            return false
        end
        matched = anyValid
    end

    table.sort(matched, function(a, b) return a.count > b.count end)
    local topN   = math.min(10, #matched)
    local chosen = matched[math.random(1, topN)]

    if useInternal and browser then
        local ok, err = pcall(function()
            browser:InvokeServer("teleport", chosen.uuid)
        end)
        return ok
    else
        TeleportService:TeleportToPlaceInstance(_place, chosen.uuid, lp)
        return true
    end
end

-- ============================================================
--  COLORES
-- ============================================================
local C = {
    BG      = Color3.fromRGB(8,   8,  14),
    CARD    = Color3.fromRGB(14,  14, 24),
    CARD2   = Color3.fromRGB(18,  18, 30),
    ACCENT  = Color3.fromRGB(160,  0, 255),
    ACCENT2 = Color3.fromRGB(200, 80, 255),
    GREEN   = Color3.fromRGB(50,  220, 120),
    GOLD    = Color3.fromRGB(255, 200,  50),
    RED     = Color3.fromRGB(220,  60,  60),
    TEXT    = Color3.fromRGB(230, 230, 245),
    MUTED   = Color3.fromRGB(110, 110, 140),
    BORDER  = Color3.fromRGB(80,   0, 180),
    SKY     = Color3.fromRGB(50,  150, 255),
}

-- ============================================================
--  HELPERS GUI
-- ============================================================
local function corner(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8)
end
local function stroke(p, col, w)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.BORDER; s.Thickness = w or 1
    return s
end
local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end
local function grad(p, c0, c1, rot)
    local g = Instance.new("UIGradient", p)
    g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90
end

-- ============================================================
--  LÓGICA ABUSE
-- ============================================================
local function Press(key)
    VirtualInputManager:SendKeyEvent(true,  key, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function getHRP()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function ExecuteAbuse()
    if not getgenv().AbuseActive then return end
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 10)
    local hum  = char:WaitForChild("Humanoid", 10)
    if hrp and hum and hum.Health > 0 then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 500, 0)
        Press(getgenv().SelectedSlot)
        task.wait(0.08)
        Press(Enum.KeyCode.J)
        local targetPos = CFrame.new(923.2, 3e21, 32852.8)
        hrp.Anchored = true
        hrp.CFrame   = targetPos
        workspace.CurrentCamera.CFrame = targetPos
        task.wait(0.05)
        Press(Enum.KeyCode.Z)
        task.spawn(function()
            task.wait(0.03)
            hum.Health = 0
            killsSesion += 1
        end)
        local s = tick()
        while tick() - s < 0.6 do RunService.Heartbeat:Wait() end
    end
end

-- ── SKY LAUNCH: sube 90,000 metros ──
local function SkyLaunch()
    local hrp = getHRP()
    if not hrp then return end
    hrp.Anchored = false
    hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 90000, 0))
end

-- ============================================================
--  AUTO Z MELEE + INF CON SPAWN ABUSE RESET
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.12)
        if getgenv().AutoZMelee then
            pcall(function()
                local char = lp.Character
                local hum  = getHum()
                local hrp  = getHRP()
                if not (char and hum and hrp and hum.Health > 0) then return end

                -- Equipar melee
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (
                        tool.ToolTip == "Melee" or
                        tool.Name:lower():find("fist") or
                        tool.Name:lower():find("melee") or
                        tool.Name:lower():find("combat") or
                        tool.Name:lower():find("fighting")
                    ) then
                        hum:EquipTool(tool)
                        break
                    end
                end

                -- Haki Buso
                pcall(function()
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                end)

                -- Orbitar (abuse reset)
                local angle = math.random() * math.pi * 2
                hrp.CFrame = hrp.CFrame * CFrame.new(
                    math.cos(angle) * 3, 0, math.sin(angle) * 3
                )

                Press(Enum.KeyCode.Z)
                task.wait(0.3)

                -- Spawn abuse reset
                hum.Health = 0
                killsSesion += 1
            end)

            -- Esperar respawn
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.CharacterAdded:Wait()
                task.wait(0.5)
            end
        end
    end
end)

-- ============================================================
--  INF MELEE LOOP (sin morir, spamea Z continuamente)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().InfMeleeActive then
            pcall(function()
                local char = lp.Character
                local hum  = getHum()
                local hrp  = getHRP()
                if not (char and hum and hrp and hum.Health > 0) then return end

                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (
                        tool.ToolTip == "Melee" or
                        tool.Name:lower():find("fist") or
                        tool.Name:lower():find("melee") or
                        tool.Name:lower():find("combat") or
                        tool.Name:lower():find("fighting")
                    ) then
                        hum:EquipTool(tool)
                        break
                    end
                end

                pcall(function()
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                end)

                Press(Enum.KeyCode.Z)
                task.wait(0.2)

                -- Abuse reset (spawn)
                hum.Health = 0
                killsSesion += 1
            end)

            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.CharacterAdded:Wait()
                task.wait(0.5)
            end
        end
    end
end)

-- ============================================================
--  AUTO SERVER HOP al vaciar servidor
-- ============================================================
local function getEnemyCount()
    local count = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then count += 1 end
    end
    return count
end

Players.PlayerRemoving:Connect(function(p)
    if p == lp or not getgenv().AutoSVHop then return end
    task.wait(2)
    if getEnemyCount() == 0 then
        svHopStatus = "🔀 Saltando de SV..."
        task.wait(1.5)
        pcall(HopAdvanced)
    end
end)

pcall(function()
    TeleportService.LocalPlayerArrivedFromTeleport:Connect(function()
        task.wait(3)
        if getgenv().AbuseActive then
            task.spawn(ExecuteAbuse)
        end
    end)
end)

-- ============================================================
--  GUI
-- ============================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("TommyBountyUI"):Destroy() end)
pcall(function() lp:WaitForChild("PlayerGui"):FindFirstChild("TommyBountyUI"):Destroy() end)

local guiParent
if typeof(gethui) == "function" then
    guiParent = gethui()
else
    local ok = pcall(function()
        local t = Instance.new("ScreenGui"); t.Parent = game:GetService("CoreGui"); t:Destroy()
    end)
    guiParent = ok and game:GetService("CoreGui") or lp:WaitForChild("PlayerGui")
end

local sg = Instance.new("ScreenGui", guiParent)
sg.Name = "TommyBountyUI"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global; sg.DisplayOrder = 999

-- ── TAMAÑOS ──
local FULL = UDim2.fromOffset(224, 480)
local MINI = UDim2.fromOffset(224, 38)
local isMin = false

local main = Instance.new("Frame", sg)
main.Size              = FULL
main.Position          = UDim2.new(0, 14, 0.5, -240)
main.BackgroundColor3  = C.BG
main.BorderSizePixel   = 0
main.Active            = true
main.ClipsDescendants  = true
corner(main, 14)
local mainStroke = stroke(main, C.BORDER, 1.5)

-- ── TOP BAR ──
local topBar = Instance.new("Frame", main)
topBar.Size             = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(16, 0, 36)
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 10
corner(topBar, 14)
grad(topBar, Color3.fromRGB(120, 0, 220), Color3.fromRGB(60, 0, 130))

local tbFix = Instance.new("Frame", topBar)
tbFix.Size = UDim2.new(1,0,0,12); tbFix.Position = UDim2.new(0,0,1,-12)
tbFix.BackgroundColor3 = Color3.fromRGB(60, 0, 130); tbFix.BorderSizePixel = 0

local dot = Instance.new("Frame", topBar)
dot.Size = UDim2.fromOffset(8, 8); dot.Position = UDim2.new(0, 10, 0.5, -4)
dot.BackgroundColor3 = C.GREEN; dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(0, 145, 1, 0); titleLbl.Position = UDim2.new(0, 24, 0, 0)
titleLbl.Text = "TOMMY HUB  ·  BOUNTY v3"
titleLbl.TextColor3 = Color3.new(1,1,1); titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 11; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.BackgroundTransparency = 1

-- Botón minimizar
local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.fromOffset(24, 24); minBtn.Position = UDim2.new(1, -30, 0.5, -12)
minBtn.Text = "−"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 160)
minBtn.BorderSizePixel = 0; corner(minBtn, 6)

minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    tween(main, 0.2, {Size = isMin and MINI or FULL})
    minBtn.Text = isMin and "+" or "−"
end)

-- ── DRAG ──
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(i)
        if dragging and (
            i.UserInputType == Enum.UserInputType.MouseMovement or
            i.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── SCROLL INTERNO ──
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size                = UDim2.new(1, 0, 1, -38)
scroll.Position            = UDim2.new(0, 0, 0, 38)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel     = 0
scroll.ScrollBarThickness  = 3
scroll.ScrollBarImageColor3 = C.ACCENT
scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection  = Enum.ScrollingDirection.Y
scroll.ClipsDescendants    = true

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function pad(p)
    local padding = Instance.new("UIPadding", p)
    padding.PaddingTop    = UDim.new(0, 6)
    padding.PaddingLeft   = UDim.new(0, 7)
    padding.PaddingRight  = UDim.new(0, 7)
    padding.PaddingBottom = UDim.new(0, 6)
end
pad(scroll)

-- ── HELPERS SCROLL ──
local rowOrder = 0
local function nextOrder() rowOrder += 1; return rowOrder end

local function makeSeparator(txt)
    local f = Instance.new("Frame", scroll)
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundColor3 = Color3.fromRGB(22, 0, 50)
    f.BorderSizePixel = 0; f.LayoutOrder = nextOrder()
    corner(f, 6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-10,1,0); l.Position = UDim2.new(0,8,0,0)
    l.Text = txt; l.TextColor3 = C.ACCENT2
    l.Font = Enum.Font.GothamBlack; l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.BackgroundTransparency = 1
end

local function makeStatCard(label, valueText, valueColor)
    local card = Instance.new("Frame", scroll)
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = C.CARD
    card.BorderSizePixel = 0; card.LayoutOrder = nextOrder()
    corner(card, 10); stroke(card, C.BORDER, 1)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1,-10,0,18); lbl.Position = UDim2.new(0,10,0,4)
    lbl.Text = label; lbl.TextColor3 = C.MUTED
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1

    local val = Instance.new("TextLabel", card)
    val.Size = UDim2.new(1,-10,0,22); val.Position = UDim2.new(0,10,0,22)
    val.Text = valueText; val.TextColor3 = valueColor or C.GOLD
    val.Font = Enum.Font.GothamBlack; val.TextSize = 16
    val.TextXAlignment = Enum.TextXAlignment.Left; val.BackgroundTransparency = 1

    return val
end

local function makeInfoRow(txtL, txtR)
    local card = Instance.new("Frame", scroll)
    card.Size = UDim2.new(1, 0, 0, 32)
    card.BackgroundColor3 = C.CARD2
    card.BorderSizePixel = 0; card.LayoutOrder = nextOrder()
    corner(card, 8); stroke(card, C.BORDER, 1)

    local left = Instance.new("TextLabel", card)
    left.Size = UDim2.new(0.5,0,1,0); left.Position = UDim2.new(0,10,0,0)
    left.Text = txtL; left.TextColor3 = C.RED
    left.Font = Enum.Font.GothamBold; left.TextSize = 11
    left.TextXAlignment = Enum.TextXAlignment.Left; left.BackgroundTransparency = 1

    local right = Instance.new("TextLabel", card)
    right.Size = UDim2.new(0.5,-10,1,0); right.Position = UDim2.new(0.5,0,0,0)
    right.Text = txtR; right.TextColor3 = C.MUTED
    right.Font = Enum.Font.Gotham; right.TextSize = 10
    right.TextXAlignment = Enum.TextXAlignment.Right; right.BackgroundTransparency = 1

    return left, right
end

local function makeToggle(label, icon, onCallback, offCallback)
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.CARD
    row.BorderSizePixel = 0; row.LayoutOrder = nextOrder()
    corner(row, 9); stroke(row, C.BORDER, 1)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-60,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.Text = icon.."  "..label
    lbl.TextColor3 = C.TEXT; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.fromOffset(42, 22); pill.Position = UDim2.new(1,-50,0.5,-11)
    pill.BackgroundColor3 = Color3.fromRGB(30,30,50); pill.BorderSizePixel = 0
    corner(pill, 11)

    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.fromOffset(16, 16); knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = C.MUTED; knob.BorderSizePixel = 0
    corner(knob, 8)

    local isOn = false
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        tween(pill,  0.18, {BackgroundColor3 = isOn and C.ACCENT or Color3.fromRGB(30,30,50)})
        tween(knob,  0.18, {
            Position         = isOn and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = isOn and C.GREEN or C.MUTED,
        })
        local rowStroke = row:FindFirstChildOfClass("UIStroke")
        if rowStroke then rowStroke.Color = isOn and C.GREEN or C.BORDER end
        if isOn then
            if onCallback then onCallback() end
        else
            if offCallback then offCallback() end
        end
    end)

    return function()
        if isOn then
            isOn = false
            tween(pill, 0.18, {BackgroundColor3 = Color3.fromRGB(30,30,50)})
            tween(knob, 0.18, {Position=UDim2.fromOffset(3,3), BackgroundColor3=C.MUTED})
            local rs = row:FindFirstChildOfClass("UIStroke")
            if rs then rs.Color = C.BORDER end
            if offCallback then offCallback() end
        end
    end
end

local function makeBtn(txt, col, hov, callback)
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = col
    btn.Text = txt; btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.LayoutOrder = nextOrder()
    corner(btn, 9); stroke(btn, C.BORDER, 1)
    btn.MouseEnter:Connect(function() tween(btn, 0.12, {BackgroundColor3 = hov or col}) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.12, {BackgroundColor3 = col}) end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function makeRowBtns(t1, c1, cb1, t2, c2, cb2)
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1,0,0,36); row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    local l = Instance.new("UIListLayout", row)
    l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0,6)

    local b1 = Instance.new("TextButton", row)
    b1.Size = UDim2.new(0.5,-3,1,0); b1.Text = t1; b1.TextColor3 = Color3.new(1,1,1)
    b1.Font = Enum.Font.GothamBold; b1.TextSize = 11; b1.BackgroundColor3 = c1; b1.BorderSizePixel = 0
    corner(b1, 8); stroke(b1, C.BORDER, 1)
    if cb1 then b1.MouseButton1Click:Connect(cb1) end

    local b2 = Instance.new("TextButton", row)
    b2.Size = UDim2.new(0.5,-3,1,0); b2.Text = t2; b2.TextColor3 = C.ACCENT2
    b2.Font = Enum.Font.GothamBold; b2.TextSize = 11; b2.BackgroundColor3 = c2; b2.BorderSizePixel = 0
    corner(b2, 8); stroke(b2, C.ACCENT, 1)
    if cb2 then b2.MouseButton1Click:Connect(cb2) end

    return b1, b2
end

-- ============================================================
--  CONTENIDO DEL SCROLL
-- ============================================================

-- Badge
local badgeFrame = Instance.new("Frame", scroll)
badgeFrame.Size = UDim2.new(1,0,0,24)
badgeFrame.BackgroundColor3 = Color3.fromRGB(18, 0, 40)
badgeFrame.BorderSizePixel = 0; badgeFrame.LayoutOrder = nextOrder()
corner(badgeFrame, 6); stroke(badgeFrame, C.ACCENT, 1)
local badgeLbl = Instance.new("TextLabel", badgeFrame)
badgeLbl.Size = UDim2.new(1,0,1,0); badgeLbl.Text = "🏴‍☠️  PIRATA  ·  Bounty Abuse v3"
badgeLbl.TextColor3 = C.ACCENT2; badgeLbl.Font = Enum.Font.GothamBold
badgeLbl.TextSize = 10; badgeLbl.BackgroundTransparency = 1

-- Stats
makeSeparator("  📊  SESIÓN")
local bountyInicialVal = makeStatCard("💰  BOUNTY INICIAL",   "$0",  C.GOLD)
local ganadasVal       = makeStatCard("📈  GANADO EN SESIÓN", "+$0", C.GREEN)
local bountyActualVal  = makeStatCard("⭐  BOUNTY ACTUAL",    "$0",  C.GOLD)

local killsLbl, timerLbl = makeInfoRow("💀  Kills: 0", "⏱  0m 0s")

local svStatusLbl, _ = makeInfoRow("🔀  SV Hop: inactivo", "")
svStatusLbl.TextColor3 = C.MUTED

-- ── ABUSE ──
makeSeparator("  ⚡  ABUSE")

makeToggle("ABUSE SLOT 3", "⚡", function()
    getgenv().SelectedSlot = Enum.KeyCode.Three
    getgenv().AbuseActive  = true
    task.spawn(ExecuteAbuse)
end, function()
    getgenv().AbuseActive = false
end)

makeToggle("ABUSE SLOT 1", "⚡", function()
    getgenv().SelectedSlot = Enum.KeyCode.One
    getgenv().AbuseActive  = true
    task.spawn(ExecuteAbuse)
end, function()
    getgenv().AbuseActive = false
end)

-- INF + FIX CAM
makeRowBtns(
    "🌀  INF",
    Color3.fromRGB(30, 0, 60),
    function()
        getgenv().InfMeleeActive = not getgenv().InfMeleeActive
    end,
    "🔧  FIX CAM",
    Color3.fromRGB(20, 0, 40),
    function()
        getgenv().AbuseActive = false
        pcall(function()
            if lp.Character then
                local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
                if hrp then hrp.Anchored = false end
            end
        end)
    end
)

-- ── AUTO Z MELEE ──
makeSeparator("  🥊  AUTO Z MELEE")

makeToggle("Auto Z Melee + Spawn Reset", "🥊", function()
    getgenv().AutoZMelee = true
end, function()
    getgenv().AutoZMelee = false
end)

-- ── SKY LAUNCH ──
makeSeparator("  🚀  SKY LAUNCH")

makeBtn("🚀  LANZAR AL CIELO (90,000m)", Color3.fromRGB(20, 60, 120), Color3.fromRGB(50, 120, 220), function()
    task.spawn(SkyLaunch)
end)

-- ── SERVER HOP ──
makeSeparator("  🌐  SERVER HOP")

makeToggle("Auto SV Hop (al vaciar SV)", "🔀", function()
    getgenv().AutoSVHop = true
    svStatusLbl.Text = "🔀  SV Hop: activo"
    svStatusLbl.TextColor3 = C.GREEN
end, function()
    getgenv().AutoSVHop = false
    svStatusLbl.Text = "🔀  SV Hop: inactivo"
    svStatusLbl.TextColor3 = C.MUTED
end)

makeBtn("🔀  HOP MANUAL", Color3.fromRGB(30, 0, 70), Color3.fromRGB(70, 0, 150), function()
    svStatusLbl.Text = "🔀  Buscando servidor..."
    svStatusLbl.TextColor3 = C.ACCENT2
    task.spawn(function()
        task.wait(0.5)
        pcall(HopAdvanced)
    end)
end)

-- ── RE-EJECUTAR AL SPAWNEAR ──
lp.CharacterAdded:Connect(function()
    if getgenv().AbuseActive then
        task.wait(0.5)
        task.spawn(ExecuteAbuse)
    end
end)

-- ============================================================
--  ACTUALIZAR STATS EN TIEMPO REAL
-- ============================================================
task.spawn(function()
    local function getBounty()
        local ok, val = pcall(function()
            local ls = lp:FindFirstChild("leaderstats")
            if ls then
                local b = ls:FindFirstChild("Bounty")
                    or ls:FindFirstChild("Beli")
                    or ls:FindFirstChild("Money")
                if b then return b.Value end
            end
        end)
        return ok and val or nil
    end

    task.wait(2)
    local v = getBounty()
    if v then
        bountyInicial = v
        bountyInicialVal.Text = "$"..tostring(math.floor(v))
        bountyActualVal.Text  = "$"..tostring(math.floor(v))
    end

    while true do
        task.wait(1)

        local elapsed = os.time() - sessionStart
        timerLbl.Text = string.format("⏱  %dm %ds", math.floor(elapsed/60), elapsed%60)
        killsLbl.Text = "💀  Kills: "..killsSesion

        if svHopStatus ~= "" then
            svStatusLbl.Text = svHopStatus
            svStatusLbl.TextColor3 = C.ACCENT2
            svHopStatus = ""
        end

        local cur = getBounty()
        if cur then
            bountyActualVal.Text = "$"..tostring(math.floor(cur))
            local gan = cur - bountyInicial
            if gan >= 0 then
                ganadasVal.Text = "+"..tostring(math.floor(gan))
                ganadasVal.TextColor3 = C.GREEN
            else
                ganadasVal.Text = tostring(math.floor(gan))
                ganadasVal.TextColor3 = C.RED
            end
        end

        dot.BackgroundColor3 = getgenv().AbuseActive and C.RED or C.GREEN
    end
end)

-- ── GLOW ANIMADO ──
task.spawn(function()
    local t = 0
    while true do
        task.wait(0.05); t += 0.05
        if mainStroke then
            local r = 100 + math.floor(80*math.abs(math.sin(t)))
            mainStroke.Color = Color3.fromRGB(r, 0, 255)
        end
    end
end)

print("[Tommy Hub] Bounty Abuse v3 cargado ✓")
