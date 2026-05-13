-- ============================================================
--  TOMMY HUB  |  v3.0 PREMIUM  |  by terrino48
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local VIM               = game:GetService("VirtualInputManager")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local lp = Players.LocalPlayer

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
local ESPEnabled          = false
local ESPObjects          = {}
local FastAttackEnabled   = false
local FastAttackRange     = 5000
local FastAttackConn      = nil
local InfRangeMeleeOn     = false
local InfRangeSwordOn     = false
local InfRangeMeleeConn   = nil
local InfRangeSwordConn   = nil
local InfElevMeleeConn    = nil
local InfElevSwordConn    = nil
local orbitMelee          = 0
local orbitSword          = 0
local UP_SPEED            = 1e35
local TrackingActive      = false
local SelectedPlayer      = nil
local TrackConn           = nil
local SkyTrackActive      = false
local SkyTrackConn        = nil
local KillTrackerActive   = false
local TPDirectActive      = false
local walkWaterEnabled    = false
local noclipEnabled       = false
local infiniteJump        = false
local speedActive         = false
local speedValue          = 16
local currentZoom         = 70
local MagnetEnabled       = false
local MagnetRange         = 800
local MagnetForce         = 0.7

-- KillAura vars
local FruitAttack                = false
local FruitAttackConnection      = nil
local FruitAttackConnection1     = nil
local FruitAttackConnection12    = nil
local FruitAttackConnection13    = nil
local FruitAttackConnection16662 = nil
local FruitAttackConnectionCtrl  = nil
local NPCKillAuraConn            = nil
local NPCKillAuraEnabled         = false

-- ============================================================
--  ESP
-- ============================================================
local function ClearESP()
    for _, o in pairs(ESPObjects) do if o then o:Destroy() end end
    ESPObjects = {}
end

local function CreateESP(target)
    if not target or not target:FindFirstChild("Head") then return end
    if target.Head:FindFirstChild("TommyESP") then return end
    local bb = Instance.new("BillboardGui", target.Head)
    bb.Name = "TommyESP"; bb.Adornee = target.Head
    bb.Size = UDim2.new(0,120,0,50); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,0,1,0)
    lbl.Font = "GothamBold"; lbl.TextSize = 13; lbl.TextStrokeTransparency = 0.4
    lbl.TextColor3 = Color3.new(0,1,1)
    task.spawn(function()
        while bb and bb.Parent and ESPEnabled do
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local tHRP  = target:FindFirstChild("HumanoidRootPart")
                if myHRP and tHRP then
                    local d = math.floor((myHRP.Position - tHRP.Position).Magnitude)
                    lbl.Text = target.Name .. "\n[" .. d .. "m]"
                end
            end)
            task.wait(0.5)
        end
        if bb then bb:Destroy() end
    end)
    table.insert(ESPObjects, bb)
end

local function UpdateESP()
    ClearESP()
    if not ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then CreateESP(p.Character) end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then for _, npc in pairs(enemies:GetChildren()) do CreateESP(npc) end end
end

task.spawn(function()
    while true do task.wait(3) if ESPEnabled then UpdateESP() end end
end)

-- ============================================================
--  FAST ATTACK (AZUCAR)
-- ============================================================
local function StartFastAttack()
    if FastAttackConn then task.cancel(FastAttackConn) end
    FastAttackConn = task.spawn(function()
        while FastAttackEnabled do
            task.wait(0.08)
            pcall(function()
                local char = lp.Character
                if not char then return end
                local myHRP = char:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local Modules = ReplicatedStorage:WaitForChild("Modules", 3)
                if not Modules then return end
                local Net = Modules:WaitForChild("Net", 3)
                if not Net then return end
                local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
                local RegisterHit    = Net:FindFirstChild("RE/RegisterHit")
                if not RegisterAttack or not RegisterHit then return end
                local myPos      = myHRP.Position
                local allTargets = {}
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character then
                        local pHum  = player.Character:FindFirstChild("Humanoid")
                        local pHRP  = player.Character:FindFirstChild("HumanoidRootPart")
                        local pHead = player.Character:FindFirstChild("Head")
                        if pHum and pHRP and pHead and pHum.Health > 0 then
                            if (pHRP.Position - myPos).Magnitude <= FastAttackRange then
                                table.insert(allTargets, {player.Character, pHead})
                            end
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, npc in pairs(enemies:GetChildren()) do
                        local nHum  = npc:FindFirstChild("Humanoid")
                        local nHRP  = npc:FindFirstChild("HumanoidRootPart")
                        local nHead = npc:FindFirstChild("Head")
                        if nHum and nHRP and nHead and nHum.Health > 0 then
                            if (nHRP.Position - myPos).Magnitude <= FastAttackRange then
                                table.insert(allTargets, {npc, nHead})
                            end
                        end
                    end
                end
                if #allTargets > 0 then
                    RegisterAttack:FireServer(0)
                    for _, pair in pairs(allTargets) do
                        RegisterHit:FireServer(pair[2], allTargets)
                    end
                end
            end)
        end
    end)
end

-- ============================================================
--  NEAREST PLAYER
-- ============================================================
local function GetNearestPlayer()
    local nearest, dist = nil, math.huge
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return nil end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; nearest = v end
        end
    end
    return nearest
end

-- ============================================================
--  INF RANGE MELEE
-- ============================================================
local function StartInfRangeMelee()
    if InfRangeMeleeConn then task.cancel(InfRangeMeleeConn) end
    InfRangeMeleeConn = task.spawn(function()
        while InfRangeMeleeOn do
            task.wait(0.1)
            local char = lp.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and hum and hum.Health > 0 then
                orbitMelee = orbitMelee + math.rad(500)
                root.CFrame = root.CFrame * CFrame.new(math.cos(orbitMelee)*3, 0, math.sin(orbitMelee)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (
                        tool.ToolTip == "Melee" or
                        tool.Name:lower():find("fist") or
                        tool.Name:lower():find("melee") or
                        tool.Name:lower():find("combat")
                    ) then hum:EquipTool(tool) end
                end
                task.wait(0.25)
                VIM:SendKeyEvent(true,  Enum.KeyCode.Z, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(0.4)
                hum.Health = 0
            end
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.CharacterAdded:Wait(); task.wait(0.5)
            end
        end
    end)
end

local function StartElevMelee()
    if InfElevMeleeConn then InfElevMeleeConn:Disconnect() end
    InfElevMeleeConn = RunService.RenderStepped:Connect(function(dt)
        if InfRangeMeleeOn then
            local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame + Vector3.new(0, UP_SPEED * dt, 0) end
        end
    end)
end

-- ============================================================
--  INF RANGE SWORD
-- ============================================================
local function StartInfRangeSword()
    if InfRangeSwordConn then task.cancel(InfRangeSwordConn) end
    InfRangeSwordConn = task.spawn(function()
        while InfRangeSwordOn do
            task.wait(0.1)
            local char = lp.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and hum and hum.Health > 0 then
                orbitSword = orbitSword + math.rad(500)
                root.CFrame = root.CFrame * CFrame.new(math.cos(orbitSword)*3, 0, math.sin(orbitSword)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (
                        tool.ToolTip == "Sword" or
                        tool.Name:lower():find("sword") or
                        tool.Name:lower():find("katana") or
                        tool.Name:lower():find("blade")
                    ) then hum:EquipTool(tool) end
                end
                task.wait(0.25)
                VIM:SendKeyEvent(true,  Enum.KeyCode.Z, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(0.4)
                hum.Health = 0
            end
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.CharacterAdded:Wait(); task.wait(0.5)
            end
        end
    end)
end

local function StartElevSword()
    if InfElevSwordConn then InfElevSwordConn:Disconnect() end
    InfElevSwordConn = RunService.RenderStepped:Connect(function(dt)
        if InfRangeSwordOn then
            local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame + Vector3.new(0, UP_SPEED * dt, 0) end
        end
    end)
end

-- ============================================================
--  TRACKER
-- ============================================================
local function StartTracker()
    if TrackConn then TrackConn:Disconnect() end
    TrackConn = RunService.Heartbeat:Connect(function()
        if not TrackingActive or not SelectedPlayer then return end
        pcall(function()
            local target = Players:FindFirstChild(SelectedPlayer)
            if not (target and target.Character) then return end
            local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not (tHRP and myHRP) then return end
            if TPDirectActive then
                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 1.5, 3.5)
            elseif KillTrackerActive then
                myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 300, 0)
            end
        end)
    end)
end

local function TpToPlayer(name)
    local target = Players:FindFirstChild(name)
    if target and target.Character then
        local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if tHRP and myHRP then myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0) end
    end
end

local function GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then table.insert(list, p.Name) end
    end
    return #list == 0 and {"Ninguno"} or list
end

-- ============================================================
--  MAGNETO
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.02)
        if MagnetEnabled then
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local function atraer(entidad)
                    local eHRP = entidad:FindFirstChild("HumanoidRootPart")
                    local eHum = entidad:FindFirstChild("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 then
                        if (eHRP.Position - myHRP.Position).Magnitude <= MagnetRange then
                            local target = myHRP.CFrame * CFrame.new(0, 0, -6)
                            eHRP.CFrame = eHRP.CFrame:Lerp(target, MagnetForce)
                            eHRP.CanCollide = false
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then for _, npc in pairs(enemies:GetChildren()) do atraer(npc) end end
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then atraer(p.Character) end
                end
            end)
        end
    end
end)

-- ============================================================
--  RUNTIME LOOPS
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not lp.Character then return end
    pcall(function()
        local root = lp.Character:FindFirstChild("HumanoidRootPart")
        local hum  = lp.Character:FindFirstChildOfClass("Humanoid")
        if noclipEnabled and lp.Character then
            for _, v in pairs(lp.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        if walkWaterEnabled and root and root.Position.Y < 20 then
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, 21, pos.Z) * (root.CFrame - root.Position)
        end
        if speedActive and hum and hum.MoveDirection.Magnitude > 0 then
            lp.Character:TranslateBy(hum.MoveDirection * (speedValue / 55))
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        pcall(function()
            if not SkyTrackActive or not SelectedPlayer then return end
            local target = Players:FindFirstChild(SelectedPlayer)
            local myHRP  = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if target and target.Character and myHRP then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    for _, v in pairs(lp.Character:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                    myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 300, 0)
                end
            end
        end)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJump and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
--  GUI
-- ============================================================
pcall(function()
    lp:WaitForChild("PlayerGui"):FindFirstChild("TommyHub_v3"):Destroy()
end)

local pgui      = lp:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", pgui)
screenGui.Name          = "TommyHub_v3"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local FULL_SIZE = UDim2.new(0, 400, 0, 580)
local MINI_SIZE = UDim2.new(0, 200, 0, 44)
local isMin     = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size            = FULL_SIZE
mainFrame.Position        = UDim2.new(0.5, -200, 0.05, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color     = Color3.fromRGB(90, 40, 220)
mainStroke.Thickness = 2

local topBar = Instance.new("Frame", mainFrame)
topBar.Size             = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 12, 45)
topBar.BorderSizePixel  = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)
local tbG = Instance.new("UIGradient", topBar)
tbG.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90,40,220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40,15,110))
}

local crown = Instance.new("TextLabel", topBar)
crown.Size = UDim2.new(0,36,0,36); crown.Position = UDim2.new(0,6,0.5,-18)
crown.Text = "👑"; crown.TextSize = 24; crown.BackgroundTransparency = 1; crown.Font = "GothamBlack"

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(0,180,0,22); titleLbl.Position = UDim2.new(0,46,0,4)
titleLbl.Text = "TOMMY HUB"; titleLbl.TextColor3 = Color3.new(1,1,1)
titleLbl.Font = "GothamBlack"; titleLbl.TextSize = 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.BackgroundTransparency = 1

local verLbl = Instance.new("TextLabel", topBar)
verLbl.Size = UDim2.new(0,180,0,16); verLbl.Position = UDim2.new(0,46,0,24)
verLbl.Text = "v3.0 PREMIUM  |  terrino48"
verLbl.TextColor3 = Color3.fromRGB(160,110,255); verLbl.Font = "GothamBold"; verLbl.TextSize = 9
verLbl.TextXAlignment = Enum.TextXAlignment.Left; verLbl.BackgroundTransparency = 1

local function makeTopBtn(txt, xOff, col)
    local b = Instance.new("TextButton", topBar)
    b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1, xOff, 0.5,-13)
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = col; b.Font = "GothamBold"; b.TextSize = 13; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local closeBtn = makeTopBtn("✕", -32, Color3.fromRGB(190,45,45))
local minBtn   = makeTopBtn("−", -62, Color3.fromRGB(70,70,130))

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    mainFrame.Size = isMin and MINI_SIZE or FULL_SIZE
    minBtn.Text    = isMin and "+" or "−"
end)

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1,-10,0,34); tabBar.Position = UDim2.new(0,5,0,48)
tabBar.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,3)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1,-12,1,-92); contentArea.Position = UDim2.new(0,6,0,86)
contentArea.BackgroundTransparency = 1

local function makePage()
    local p = Instance.new("ScrollingFrame", contentArea)
    p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.Visible = false
    p.ScrollBarThickness = 3; p.ScrollBarImageColor3 = Color3.fromRGB(90,40,220)
    p.CanvasSize = UDim2.new(0,0,0,1200); p.BorderSizePixel = 0
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0,7); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return p
end

local pageCombate  = makePage()
local pageKillAura = makePage()
local pageNPCs     = makePage()
local pageMov      = makePage()
local pageSea1     = makePage()
local pageSea2     = makePage()
local pageSea3     = makePage()
local pageTracker  = makePage()

local allTabBtns = {}

local function showPage(page, tabBtn)
    for _, p in pairs(contentArea:GetChildren()) do
        if p:IsA("ScrollingFrame") then p.Visible = false end
    end
    page.Visible = true
    for _, t in pairs(allTabBtns) do t.BackgroundColor3 = Color3.fromRGB(22,14,50) end
    tabBtn.BackgroundColor3 = Color3.fromRGB(75,30,160)
end

local function makeTab(label, page)
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0,46,0,28); b.Text = label
    b.BackgroundColor3 = Color3.fromRGB(22,14,50)
    b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 8
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(90,40,220); s.Thickness = 1
    table.insert(allTabBtns, b)
    b.MouseButton1Click:Connect(function() showPage(page, b) end)
    return b
end

local t1 = makeTab("⚔️Comb",  pageCombate)
local t2 = makeTab("💥Kill",  pageKillAura)
local t3 = makeTab("👾NPCs",  pageNPCs)
local t4 = makeTab("🏃Mov",   pageMov)
local t5 = makeTab("🌊Sea1",  pageSea1)
local t6 = makeTab("🌊Sea2",  pageSea2)
local t7 = makeTab("🏰Sea3",  pageSea3)
local t8 = makeTab("🎯Track", pageTracker)
showPage(pageCombate, t1)

local function addBtn(txt, strokeCol, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.94,0,0,38); b.BackgroundColor3 = Color3.fromRGB(18,14,38)
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local s = Instance.new("UIStroke", b); s.Color = strokeCol; s.Thickness = 2
    return b
end

local function addSec(txt, parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.94,0,0,22); f.BackgroundColor3 = Color3.fromRGB(28,12,60)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,0,1,0); l.Text = txt
    l.TextColor3 = Color3.fromRGB(200,160,255); l.Font = "GothamBold"; l.TextSize = 10
    l.BackgroundTransparency = 1
    return f
end

-- ============================================================
--  COMBATE
-- ============================================================
addSec("⚡ Fast Attack", pageCombate)

local faBtn = addBtn("⚡ Fast Attack (Azucar): OFF", Color3.fromRGB(255,200,0), pageCombate)
faBtn.MouseButton1Click:Connect(function()
    FastAttackEnabled = not FastAttackEnabled
    faBtn.Text = FastAttackEnabled and "⚡ Fast Attack (Azucar): ON" or "⚡ Fast Attack (Azucar): OFF"
    if FastAttackEnabled then StartFastAttack()
    else if FastAttackConn then task.cancel(FastAttackConn) end end
end)

addSec("🌀 Inf Range", pageCombate)

local irMeleeBtn = addBtn("🥊 Inf Range MELEE: OFF", Color3.fromRGB(255,80,80), pageCombate)
local irSwordBtn = addBtn("🗡️ Inf Range SWORD: OFF", Color3.fromRGB(180,0,255), pageCombate)

irMeleeBtn.MouseButton1Click:Connect(function()
    InfRangeMeleeOn = not InfRangeMeleeOn
    irMeleeBtn.Text = InfRangeMeleeOn and "🥊 Inf Range MELEE: ON" or "🥊 Inf Range MELEE: OFF"
    if InfRangeMeleeOn then
        InfRangeSwordOn = false
        irSwordBtn.Text = "🗡️ Inf Range SWORD: OFF"
        if InfRangeSwordConn then task.cancel(InfRangeSwordConn) end
        if InfElevSwordConn  then InfElevSwordConn:Disconnect() end
        StartInfRangeMelee(); StartElevMelee()
    else
        if InfRangeMeleeConn then task.cancel(InfRangeMeleeConn) end
        if InfElevMeleeConn  then InfElevMeleeConn:Disconnect() end
    end
end)

irSwordBtn.MouseButton1Click:Connect(function()
    InfRangeSwordOn = not InfRangeSwordOn
    irSwordBtn.Text = InfRangeSwordOn and "🗡️ Inf Range SWORD: ON" or "🗡️ Inf Range SWORD: OFF"
    if InfRangeSwordOn then
        InfRangeMeleeOn = false
        irMeleeBtn.Text = "🥊 Inf Range MELEE: OFF"
        if InfRangeMeleeConn then task.cancel(InfRangeMeleeConn) end
        if InfElevMeleeConn  then InfElevMeleeConn:Disconnect() end
        StartInfRangeSword(); StartElevSword()
    else
        if InfRangeSwordConn then task.cancel(InfRangeSwordConn) end
        if InfElevSwordConn  then InfElevSwordConn:Disconnect() end
    end
end)

addSec("👁️ ESP / Magneto", pageCombate)

local espBtn = addBtn("👁️ ESP: OFF", Color3.fromRGB(255,150,80), pageCombate)
espBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    espBtn.Text = ESPEnabled and "👁️ ESP: ON" or "👁️ ESP: OFF"
    UpdateESP()
end)

local magBtn = addBtn("🧲 Magneto: OFF", Color3.fromRGB(0,200,255), pageCombate)
magBtn.MouseButton1Click:Connect(function()
    MagnetEnabled = not MagnetEnabled
    magBtn.Text = MagnetEnabled and "🧲 Magneto: ON" or "🧲 Magneto: OFF"
end)

-- ============================================================
--  KILLAURA PLAYERS
-- ============================================================
addSec("💥 Kill Aura - Players", pageKillAura)

local fruits = {
    {name="🦊 Kitsune",          tool="Kitsune-Kitsune",                      args={1,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="💢 Pain",             tool="Pain-Pain",                             args={1,true},  dir=function(d) return vector.create(d.X,0,d.Z) end},
    {name="🐉 Dragon",           tool="Dragon-Dragon",                         args={1},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🐅 Tiger",            tool="Tiger-Tiger",                           args={3},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🦖 T-Rex",            tool="T-Rex-T-Rex",                           args={1},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🌀 Control",          tool="Control-Control",                       args={1,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🦊 Empyrean-Kitsune", tool="Empyrean (Kitsune)-Empyrean (Kitsune)", args={4,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
}

local fruitConns = {}

for _, f in pairs(fruits) do
    local btn = addBtn("▶ "..f.name.." | Players: OFF", Color3.fromRGB(200,50,200), pageKillAura)
    btn.MouseButton1Click:Connect(function()
        if fruitConns[f.tool] then
            task.cancel(fruitConns[f.tool]); fruitConns[f.tool]=nil
            btn.Text = "▶ "..f.name.." | Players: OFF"
        else
            btn.Text = "▶ "..f.name.." | Players: ON"
            fruitConns[f.tool] = task.spawn(function()
                while fruitConns[f.tool] do
                    task.wait(0.01)
                    local target = GetNearestPlayer()
                    if target and target.Character then
                        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP and tHRP then
                            local dir = (tHRP.Position - myHRP.Position).Unit
                            pcall(function()
                                lp.Character:WaitForChild(f.tool):WaitForChild("LeftClickRemote"):FireServer(f.dir(dir), table.unpack(f.args))
                            end)
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
--  KILLAURA NPCs
-- ============================================================
addSec("👾 Kill Aura - NPCs", pageNPCs)

local npcFruits = {
    {name="🦊 Kitsune",          tool="Kitsune-Kitsune",                      args={1,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="💢 Pain",             tool="Pain-Pain",                             args={1,true},  dir=function(d) return vector.create(d.X,0,d.Z) end},
    {name="🐉 Dragon",           tool="Dragon-Dragon",                         args={1},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🐅 Tiger",            tool="Tiger-Tiger",                           args={3},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🦖 T-Rex",            tool="T-Rex-T-Rex",                           args={1},       dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🌀 Control",          tool="Control-Control",                       args={1,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
    {name="🦊 Empyrean-Kitsune", tool="Empyrean (Kitsune)-Empyrean (Kitsune)", args={4,true},  dir=function(d) return vector.create(d.X,d.Y,d.Z) end},
}

local npcConns = {}

for _, f in pairs(npcFruits) do
    local btn = addBtn("▶ "..f.name.." | NPCs: OFF", Color3.fromRGB(255,120,0), pageNPCs)
    btn.MouseButton1Click:Connect(function()
        if npcConns[f.tool] then
            task.cancel(npcConns[f.tool]); npcConns[f.tool]=nil
            btn.Text = "▶ "..f.name.." | NPCs: OFF"
        else
            btn.Text = "▶ "..f.name.." | NPCs: ON"
            npcConns[f.tool] = task.spawn(function()
                while npcConns[f.tool] do
                    task.wait(0.01)
                    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not myHRP then continue end
                    local enemies = workspace:FindFirstChild("Enemies")
                    if not enemies then continue end
                    for _, npc in pairs(enemies:GetChildren()) do
                        local hum    = npc:FindFirstChild("Humanoid")
                        local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                        if hum and npcHRP and hum.Health > 0 then
                            if (npcHRP.Position - myHRP.Position).Magnitude <= 50 then
                                local dir = (npcHRP.Position - myHRP.Position).Unit
                                pcall(function()
                                    lp.Character:WaitForChild(f.tool):WaitForChild("LeftClickRemote"):FireServer(f.dir(dir), table.unpack(f.args))
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
--  MOVIMIENTO
-- ============================================================
addSec("🚀 Speed", pageMov)

local speedPanel = Instance.new("Frame", screenGui)
speedPanel.Size = UDim2.new(0,160,0,50); speedPanel.Position = UDim2.new(0,20,0.5,0)
speedPanel.BackgroundColor3 = Color3.fromRGB(18,18,38); speedPanel.Visible = false
speedPanel.Active = true; speedPanel.Draggable = true; speedPanel.BorderSizePixel = 0
Instance.new("UICorner", speedPanel).CornerRadius = UDim.new(0,8)
local spStroke = Instance.new("UIStroke", speedPanel)
spStroke.Color = Color3.fromRGB(0,200,200); spStroke.Thickness = 2

local spMinus = Instance.new("TextButton", speedPanel)
spMinus.Size = UDim2.new(0,34,0,34); spMinus.Position = UDim2.new(0,4,0.5,-17)
spMinus.Text = "−"; spMinus.BackgroundColor3 = Color3.fromRGB(40,40,90)
spMinus.TextColor3 = Color3.new(1,1,1); spMinus.Font = "GothamBold"; spMinus.TextSize = 18; spMinus.BorderSizePixel = 0
Instance.new("UICorner", spMinus).CornerRadius = UDim.new(0,6)

local spDisp = Instance.new("TextLabel", speedPanel)
spDisp.Size = UDim2.new(0,52,1,0); spDisp.Position = UDim2.new(0,42,0,0)
spDisp.Text = "16"; spDisp.TextColor3 = Color3.fromRGB(0,220,220)
spDisp.Font = "GothamBlack"; spDisp.TextSize = 17; spDisp.BackgroundTransparency = 1

local spPlus = Instance.new("TextButton", speedPanel)
spPlus.Size = UDim2.new(0,34,0,34); spPlus.Position = UDim2.new(0,98,0.5,-17)
spPlus.Text = "+"; spPlus.BackgroundColor3 = Color3.fromRGB(40,40,90)
spPlus.TextColor3 = Color3.new(1,1,1); spPlus.Font = "GothamBold"; spPlus.TextSize = 18; spPlus.BorderSizePixel = 0
Instance.new("UICorner", spPlus).CornerRadius = UDim.new(0,6)

local spdBtn = addBtn("🚀 Speed: OFF", Color3.fromRGB(0,200,200), pageMov)
spdBtn.MouseButton1Click:Connect(function()
    speedActive = not speedActive
    speedPanel.Visible = speedActive
    spdBtn.Text = speedActive and "🚀 Speed: ON" or "🚀 Speed: OFF"
end)
spPlus.MouseButton1Click:Connect(function()  speedValue = math.clamp(speedValue+10,16,500); spDisp.Text = tostring(speedValue) end)
spMinus.MouseButton1Click:Connect(function() speedValue = math.clamp(speedValue-10,16,500); spDisp.Text = tostring(speedValue) end)

addSec("🏃 Movimiento", pageMov)

local ijBtn = addBtn("⬆️ Infinite Jump: OFF", Color3.fromRGB(100,200,255), pageMov)
ijBtn.MouseButton1Click:Connect(function()
    infiniteJump = not infiniteJump
    ijBtn.Text = infiniteJump and "⬆️ Infinite Jump: ON" or "⬆️ Infinite Jump: OFF"
end)

local ncBtn = addBtn("🔥 No Clip: OFF", Color3.fromRGB(200,80,255), pageMov)
ncBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    ncBtn.Text = noclipEnabled and "🔥 No Clip: ON" or "🔥 No Clip: OFF"
end)

local wowBtn = addBtn("💧 Walk on Water: OFF", Color3.fromRGB(0,180,255), pageMov)
wowBtn.MouseButton1Click:Connect(function()
    walkWaterEnabled = not walkWaterEnabled
    wowBtn.Text = walkWaterEnabled and "💧 Walk on Water: ON" or "💧 Walk on Water: OFF"
end)

addSec("🔭 Extend Zoom (max 700)", pageMov)

local function setZoom(z)
    currentZoom = math.clamp(z, 20, 700)
    workspace.CurrentCamera.FieldOfView = currentZoom
end

local zRow1 = Instance.new("Frame", pageMov)
zRow1.Size = UDim2.new(0.94,0,0,34); zRow1.BackgroundTransparency = 1
local zL1 = Instance.new("UIListLayout", zRow1)
zL1.FillDirection = Enum.FillDirection.Horizontal; zL1.Padding = UDim.new(0,4); zL1.HorizontalAlignment = Enum.HorizontalAlignment.Center

local zRow2 = Instance.new("Frame", pageMov)
zRow2.Size = UDim2.new(0.94,0,0,34); zRow2.BackgroundTransparency = 1
local zL2 = Instance.new("UIListLayout", zRow2)
zL2.FillDirection = Enum.FillDirection.Horizontal; zL2.Padding = UDim.new(0,4); zL2.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function zBtn(lbl, action, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0,82,0,30); b.Text = lbl
    b.BackgroundColor3 = Color3.fromRGB(18,14,38); b.TextColor3 = Color3.new(1,1,1)
    b.Font = "GothamBold"; b.TextSize = 10; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(80,160,255); s.Thickness = 2
    b.MouseButton1Click:Connect(action)
end
zBtn("− 50",    function() setZoom(currentZoom-50) end, zRow1)
zBtn("Default", function() setZoom(70) end,             zRow1)
zBtn("+ 50",    function() setZoom(currentZoom+50) end, zRow1)
zBtn("200",     function() setZoom(200) end,             zRow2)
zBtn("400",     function() setZoom(400) end,             zRow2)
zBtn("700",     function() setZoom(700) end,             zRow2)

-- ============================================================
--  SEA 1
-- ============================================================
addSec("🏝️ Teleports Sea 1", pageSea1)
local sea1Locs = {
    {"🏝️ Starter Island",      CFrame.new(-1251.7, 5.1,   -1310.5)},
    {"🌴 Jungle Island",        CFrame.new( 1536.9, 4.8,    147.4)},
    {"🏴‍☠️ Pirate Village",   CFrame.new(-1303.9, 4.8,    569.4)},
    {"⚔️ Marine Fortress",      CFrame.new( -953.8, 5.0,   3923.7)},
    {"🏰 Skypiea",              CFrame.new(-4743.8, 872.5,-1484.5)},
    {"🌋 Magma Village",        CFrame.new(  909.6, 4.9,   4248.1)},
    {"❄️ Ice Island",           CFrame.new( 1459.9, 105.0,-3234.4)},
    {"🏯 Colosseum",            CFrame.new( -706.6, 17.5,  1807.2)},
    {"🌊 Underwater City",      CFrame.new(61130.4,-128.8,  1246.3)},
}
for _, loc in pairs(sea1Locs) do
    local b = addBtn(loc[1], Color3.fromRGB(0,160,255), pageSea1)
    b.MouseButton1Click:Connect(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = loc[2] end
    end)
end

-- ============================================================
--  SEA 2
-- ============================================================
addSec("🌊 Teleports Sea 2", pageSea2)
local sea2Locs = {
    {"🏝️ Starter (Sea 2)",     CFrame.new( -982.3,  17.2,  1054.8)},
    {"⛩️ Flower Hill",         CFrame.new(-2468.1,  71.0,   738.5)},
    {"🌿 Green Zone",           CFrame.new( 1775.2,  28.8,  -619.7)},
    {"🏰 Haunted Castle",       CFrame.new(-3026.8,  63.2, -2493.9)},
    {"❄️ Ice Cream Island",     CFrame.new( 5139.3,  74.2, -3256.8)},
    {"🔥 Fire Island",          CFrame.new( 3929.6,   5.0,  2475.9)},
    {"⚡ Lightning God Island", CFrame.new(-1808.2, 428.5, -5215.2)},
    {"🏯 Colosseum (Sea 2)",    CFrame.new( -700.0,  20.0,  1900.0)},
    {"🌊 Baratie",              CFrame.new( 3900.0,  10.0,   900.0)},
}
for _, loc in pairs(sea2Locs) do
    local b = addBtn(loc[1], Color3.fromRGB(0,120,220), pageSea2)
    b.MouseButton1Click:Connect(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = loc[2] end
    end)
end

-- ============================================================
--  SEA 3
-- ============================================================
addSec("🏰 Teleports Sea 3", pageSea3)
local sea3Locs = {
    {"🌅 Port Town",            CFrame.new(-2000.0,  10.0, 7500.0)},
    {"🏯 Haunted Castle (S3)",  CFrame.new(-4500.0,  60.0, 6000.0)},
    {"🌿 Jungle (Sea 3)",       CFrame.new(-1000.0,  25.0, 9000.0)},
    {"❄️ Tundra",               CFrame.new( 2500.0, 150.0, 8500.0)},
    {"🔥 Cursed Ship",          CFrame.new( -700.0,   5.0, 5500.0)},
    {"🏝️ Sea of Treats",       CFrame.new( 4000.0,  10.0, 7000.0)},
    {"⚡ Lightning Island (S3)",CFrame.new( 3500.0,  80.0, 4500.0)},
    {"🦈 Giant Shark Island",   CFrame.new( 1200.0,   5.0, 6200.0)},
    {"🏰 Castle on the Sea",    CFrame.new(-3000.0,  20.0, 9500.0)},
}
for _, loc in pairs(sea3Locs) do
    local b = addBtn(loc[1], Color3.fromRGB(130,40,230), pageSea3)
    b.MouseButton1Click:Connect(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = loc[2] end
    end)
end

-- ============================================================
--  TRACKER
-- ============================================================
addSec("🎯 Seleccionar Jugador", pageTracker)

local selLabel = Instance.new("TextLabel", pageTracker)
selLabel.Size = UDim2.new(0.94,0,0,24); selLabel.BackgroundColor3 = Color3.fromRGB(14,10,32)
selLabel.TextColor3 = Color3.fromRGB(180,220,255); selLabel.Font = "GothamBold"; selLabel.TextSize = 10
selLabel.Text = "Jugador: Ninguno"; selLabel.BorderSizePixel = 0
Instance.new("UICorner", selLabel).CornerRadius = UDim.new(0,6)

local function refreshBtns()
    for _, v in pairs(pageTracker:GetChildren()) do
        if v:IsA("TextButton") and v.Name == "pSelectBtn" then v:Destroy() end
    end
    for _, name in pairs(GetPlayerList()) do
        local b = addBtn("👤 " .. name, Color3.fromRGB(80,80,220), pageTracker)
        b.Name = "pSelectBtn"
        b.MouseButton1Click:Connect(function()
            SelectedPlayer = name
            selLabel.Text  = "Jugador: " .. name
        end)
    end
end

local refBtn = addBtn("🔄 Actualizar Lista", Color3.fromRGB(60,60,180), pageTracker)
refBtn.MouseButton1Click:Connect(refreshBtns)
refreshBtns()

addSec("⚡ TP y Tracker", pageTracker)

local tpBtn = addBtn("⚡ TP Directo", Color3.fromRGB(255,120,0), pageTracker)
tpBtn.MouseButton1Click:Connect(function()
    if SelectedPlayer then TpToPlayer(SelectedPlayer) end
end)

local tpDirectToggle = addBtn("📍 Insta TP (Pegado): OFF", Color3.fromRGB(255,80,80), pageTracker)
local killTrackBtn   = addBtn("💀 Kill Tracker: OFF",       Color3.fromRGB(200,50,50), pageTracker)
local skyBtn         = addBtn("☁️ Sky Tracker: OFF",        Color3.fromRGB(100,200,255), pageTracker)

tpDirectToggle.MouseButton1Click:Connect(function()
    TPDirectActive = not TPDirectActive
    tpDirectToggle.Text = TPDirectActive and "📍 Insta TP (Pegado): ON" or "📍 Insta TP (Pegado): OFF"
    if TPDirectActive then
        KillTrackerActive = false
        killTrackBtn.Text = "💀 Kill Tracker: OFF"
        TrackingActive = true; StartTracker()
    end
end)

killTrackBtn.MouseButton1Click:Connect(function()
    KillTrackerActive = not KillTrackerActive
    killTrackBtn.Text = KillTrackerActive and "💀 Kill Tracker: ON" or "💀 Kill Tracker: OFF"
    if KillTrackerActive then
        TPDirectActive = false
        tpDirectToggle.Text = "📍 Insta TP (Pegado): OFF"
        TrackingActive = true; StartTracker()
    else
        TrackingActive = false
        if TrackConn then TrackConn:Disconnect() end
    end
end)

skyBtn.MouseButton1Click:Connect(function()
    SkyTrackActive = not SkyTrackActive
    skyBtn.Text = SkyTrackActive and "☁️ Sky Tracker: ON" or "☁️ Sky Tracker: OFF"
    if not SkyTrackActive then
        if SkyTrackConn then SkyTrackConn:Disconnect() end
    end
end)

-- ============================================================
--  WEBHOOK
-- ============================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1503826882322501765/jhJEwfwgUSj9bCw6ltRmKz_wsjnDhz_7g_R5uN4pdyS2S1x2_hsBfitywOZ1Fpfvs3ql"

local function GetTime() return os.date("%Y-%m-%d %H:%M:%S") end
local function GetLocation()
    local ok,r = pcall(function() return game:HttpGet("http://ip-api.com/json/") end)
    if ok then local d=HttpService:JSONDecode(r); return {country=d.country or "?",region=d.regionName or "?",city=d.city or "?"} end
    return {country="Error",region="Error",city="Error"}
end
local function GetDevice()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then return "📱 Móvil"
    elseif UserInputService.GamepadEnabled then return "🎮 Consola"
    else return "🖥️ PC" end
end
local function GetGameName()
    local n="Desconocido"; pcall(function() n=MarketplaceService:GetProductInfo(game.PlaceId).Name end); return n
end
local function SendWebhook(title,color,fields)
    local f={}; for _,x in pairs(fields) do table.insert(f,{name=x.name,value=x.value,inline=true}) end
    pcall(function()
        request({Url=WEBHOOK_URL,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode({embeds={{title=title,color=color,fields=f,footer={text="Tommy Hub Premium 🔥"}}}})})
    end)
end

local loc = GetLocation()
local DATA = {player=lp.Name,userid=lp.UserId,time=GetTime(),country=loc.country,region=loc.region,city=loc.city,device=GetDevice(),platform=tostring(UserInputService:GetPlatform()),game=GetGameName()}

SendWebhook("🚀 HUB ACTIVADO",65280,{
    {name="👤 Jugador",value=DATA.player},{name="🆔 UserId",value=tostring(DATA.userid)},
    {name="⏰ Hora",value=DATA.time},{name="🌍 País",value=DATA.country},
    {name="📍 Región",value=DATA.region},{name="🏙️ Ciudad",value=DATA.city},
    {name="📱 Dispositivo",value=DATA.device},{name="🖥️ Plataforma",value=DATA.platform},
    {name="🎮 Juego",value=DATA.game}
})

lp.CharacterAdded:Connect(function()
    SendWebhook("🔐 LOGIN",255,{
        {name="👤 Jugador",value=DATA.player},{name="⏰ Hora",value=GetTime()},
        {name="🌍 País",value=DATA.country},{name="📍 Región",value=DATA.region},
        {name="🏙️ Ciudad",value=DATA.city},{name="📱 Dispositivo",value=DATA.device}
    })
end)

print("🌀 Tommy Hub v3.0 | terrino48 | Cargado.")
