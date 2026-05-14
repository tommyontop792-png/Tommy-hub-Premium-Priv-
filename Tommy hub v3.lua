-- ============================================================
--  TOMMY HUB v4.0  |  Fusión Tommy + Azucar  |  by terrino48
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")

local lp     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
--  FLUENT UI (interfaz diferente a Rayfield)
-- ============================================================
local Fluent    = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
getgenv().SelectedPlayer    = nil
getgenv().TrackingActive    = false
getgenv().KillTrackerActive = false
getgenv().TPDirectActive    = false
getgenv().FastAttackEnabled = false
getgenv().FastAttackRange   = math.huge
getgenv().SkyTrackerActive  = false
getgenv().TrackerHeight     = 300
getgenv().InstaTPSkyHeight  = 300
getgenv().InstaTPSkyActive  = false
getgenv().WalkOnWater       = false
getgenv().NoclipEnabled     = false
getgenv().SpinEnabled       = false
getgenv().SpinSpeed         = 50
getgenv().MagnetEnabled     = false
getgenv().MagnetRange       = 800
getgenv().MagnetDistance    = 6
getgenv().PullForce         = 0.7
getgenv().OrbitActive       = false

_G.WalkSpeedValue   = 40
_G.WalkSpeedEnabled = false
_G.JumpPowerValue   = 50
_G.JumpPowerEnabled = false

-- ============================================================
--  LOCAL STATE
-- ============================================================
local skyConnection     = nil
local DashEnabled       = false
local DashConnection    = nil
local DashLenghDistance = 1
local autoV4            = false
local v4Connection      = nil
local GhostTpEnabled    = false
local GhostTpConnection = nil
local ghostFrameCounter = 0
local GHOST_RATIO       = 2
local GhostCFrame       = nil
local BlinkMode         = false
local XOffset, YOffset, ZOffset = 0, 1.5, 3.5
local flying            = false
local flySpeed          = 60
local bv, bg
local ESPEnabled        = false
local ESPObjects        = {}
local ESPColor          = Color3.new(0, 1, 1)
local TrackConn         = nil
local RegisterHit       = nil
local RegisterAttack    = nil
local FastAttackConn    = nil
local InfRangeMeleeOn   = false
local InfRangeSwordOn   = false
local InfRangeMeleeConn = nil
local InfRangeSwordConn = nil
local InfElevMeleeConn  = nil
local InfElevSwordConn  = nil
local orbitMelee        = 0
local orbitSword        = 0
local UP_SPEED          = 1e35
local speedActive       = false
local speedValue        = 16
local ZoomEnabled       = false
local extendedMaxZoom   = 500
local abilityLockout    = false
local frozenCFrame      = nil
local Unbreakable       = false
local UnbreakableConn   = nil
local AntiTP_Enabled    = false
local AntiTP_Threshold  = 10
local AntiTP_LastPos    = nil
local AntiTP_Connection = nil
local FakeLag_Enabled   = false
local FakeLag_Interval  = 0.1
local FakeLag_Duration  = 0.05
local Tracers_Enabled   = false
local Tracers_Color     = Color3.fromRGB(255, 165, 0)
local Tracers_Thickness = 1.5
local TracerLines       = {}
local Farm_OrbitActive  = false
local Farm_AboveActive  = false
local Farm_MagnetActive = false
local Farm_RaidActive   = false
local Farm_OrbitSpeed   = 5
local Farm_OrbitDist    = 15
local Farm_AboveHeight  = 12
local Farm_MagnetHeight = -4
local Farm_MagnetForce  = 0.15
local Farm_RaidSpeed    = 16
local FruitAttack       = false
local FruitAttackConn   = nil

-- ============================================================
--  CARGAR REMOTES
-- ============================================================
task.spawn(function()
    pcall(function()
        local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
        local Net     = Modules:WaitForChild("Net", 10)
        RegisterHit    = Net:WaitForChild("RE/RegisterHit",    10)
        RegisterAttack = Net:WaitForChild("RE/RegisterAttack", 10)
    end)
end)

-- ============================================================
--  ANTI AFK
-- ============================================================
task.spawn(function()
    while true do
        task.wait(55)
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
end)

-- ============================================================
--  ANTI KICK
-- ============================================================
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "Kick" then return end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ============================================================
--  UTILIDAD
-- ============================================================
local function TpTo(cframe)
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = cframe end
end

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

local function GetNearestNPC()
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closest, bestDist = nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= lp.Character then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local isPlayer  = Players:GetPlayerFromCharacter(v)
                local hasPrompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not isPlayer and not hasPrompt then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < bestDist then bestDist = d; closest = v end
                end
            end
        end
    end
    return closest
end

local function UpdatePlayerList()
    local n = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp then table.insert(n, v.Name) end
    end
    return #n == 0 and {"Ninguno"} or n
end

local function TeleportToAllPlayers()
    local plist = Players:GetPlayers()
    local char  = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    task.spawn(function()
        for _, target in pairs(plist) do
            if target ~= lp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                task.wait(0.5)
            end
        end
    end)
end

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
    lbl.TextColor3 = ESPColor
    task.spawn(function()
        while bb and bb.Parent and ESPEnabled do
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local tHRP  = target:FindFirstChild("HumanoidRootPart")
                if myHRP and tHRP then
                    local d = math.floor((myHRP.Position - tHRP.Position).Magnitude)
                    lbl.Text = target.Name .. "\n[" .. d .. "m]"
                    lbl.TextColor3 = ESPColor
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
--  TRACERS
-- ============================================================
local function CreateTracer(player)
    if player == lp then return end
    local line        = Drawing.new("Line")
    line.Visible      = false
    line.Color        = Tracers_Color
    line.Thickness    = Tracers_Thickness
    line.Transparency = 1
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Players:FindFirstChild(player.Name) then
            line:Remove(); conn:Disconnect(); TracerLines[player] = nil; return
        end
        if Tracers_Enabled
            and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        then
            local myPos,    myOn    = Camera:WorldToViewportPoint(lp.Character.HumanoidRootPart.Position)
            local enemyPos, enemyOn = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if myOn and enemyOn then
                line.From = Vector2.new(myPos.X, myPos.Y)
                line.To   = Vector2.new(enemyPos.X, enemyPos.Y)
                line.Color = Tracers_Color; line.Thickness = Tracers_Thickness; line.Visible = true
            else line.Visible = false end
        else line.Visible = false end
    end)
    TracerLines[player] = {line = line, conn = conn}
end

Players.PlayerAdded:Connect(function(p) CreateTracer(p) end)
Players.PlayerRemoving:Connect(function(p)
    if TracerLines[p] then TracerLines[p].line:Remove(); TracerLines[p].conn:Disconnect(); TracerLines[p] = nil end
end)
for _, p in pairs(Players:GetPlayers()) do CreateTracer(p) end

-- ============================================================
--  VUELO
-- ============================================================
local function StopFly()
    flying = false
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    pcall(function()
        if lp.Character then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            local anim = lp.Character:FindFirstChild("Animate")
            if anim then anim.Disabled = false end
        end
    end)
end

local function StartFly()
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    getgenv().InstaTPSkyActive = false
    StopFly(); flying = true
    local root = char.HumanoidRootPart
    local anim = char:FindFirstChild("Animate")
    if anim then anim.Disabled = true end
    bg = Instance.new("BodyGyro", root)
    bg.D = 100; bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame
    bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    task.spawn(function()
        while flying and char.Parent and root.Parent do
            local cam = workspace.CurrentCamera; local camCF = cam.CFrame
            local fwd   = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z).Unit
            local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
            local vel   = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + fwd   * flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - fwd   * flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + right * flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - right * flySpeed end
            local yVel = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then yVel =  flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then yVel = -flySpeed end
            bv.Velocity = Vector3.new(vel.X, yVel, vel.Z)
            bg.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z), 0)
            task.wait()
        end
        StopFly()
    end)
end

-- ============================================================
--  GHOST TP
-- ============================================================
local function StartGhostTP()
    if GhostTpConnection then GhostTpConnection:Disconnect() end
    ghostFrameCounter = 0
    pcall(function()
        if not GhostCFrame then
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            GhostCFrame = hrp and hrp.CFrame or CFrame.new(0,0,0)
        end
    end)
    GhostTpConnection = RunService.Heartbeat:Connect(function()
        if not GhostTpEnabled or not getgenv().SelectedPlayer then return end
        pcall(function()
            local char      = lp.Character
            local target    = Players:FindFirstChild(getgenv().SelectedPlayer)
            if not (char and target and target.Character) then return end
            local hrp       = char:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not (hrp and targetHRP) then return end
            ghostFrameCounter += 1
            local targetCF = targetHRP.CFrame * CFrame.new(XOffset, YOffset, ZOffset)
            if BlinkMode then
                hrp.CFrame = targetCF
            elseif ghostFrameCounter % GHOST_RATIO == 0 then
                hrp.CFrame = GhostCFrame or targetCF
            else
                hrp.CFrame = targetCF
            end
        end)
    end)
end

-- ============================================================
--  FAST ATTACK FUSIONADO (Lock-On + Freeze habilidad)
-- ============================================================
local function IsUsingAbility(char)
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChild("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:find("skill") or n:find("ability") or n:find("dash") or n:find("cast") or n:find("fruit") then return true end
        end
    end
    if hum:GetState() == Enum.HumanoidStateType.Physics then return true end
    return false
end

local function GetLockOnTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            if p.Character:FindFirstChildOfClass("Highlight") then return p.Character end
        end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do
            if npc:FindFirstChildOfClass("Highlight") then return npc end
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local using = IsUsingAbility(char)
    if using and not abilityLockout then abilityLockout = true; frozenCFrame = hrp.CFrame end
    if abilityLockout and using then hrp.CFrame = frozenCFrame end
    if not using and abilityLockout then abilityLockout = false; frozenCFrame = nil end
end)

local function AttackMultipleTargets(targets)
    if not RegisterHit or not RegisterAttack then return end
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then table.insert(allTargets, {char, head}) end
        end
        if #allTargets == 0 then return end
        RegisterAttack:FireServer(0)
        task.wait()
        RegisterHit:FireServer(allTargets[1][2], allTargets)
    end)
end

local function GetTargets()
    if abilityLockout then return {} end
    local lockTarget = GetLockOnTarget()
    if lockTarget then return {lockTarget} end
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local pHum = p.Character:FindFirstChild("Humanoid")
            local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if pHum and pHRP and pHum.Health > 0 then table.insert(targets, p.Character) end
        end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do
            local nHum = npc:FindFirstChild("Humanoid")
            local nHRP = npc:FindFirstChild("HumanoidRootPart")
            if nHum and nHRP and nHum.Health > 0 then table.insert(targets, npc) end
        end
    end
    return targets
end

local function StartFastAttack()
    if FastAttackConn then task.cancel(FastAttackConn); FastAttackConn = nil end
    FastAttackConn = task.spawn(function()
        while getgenv().FastAttackEnabled do
            local targets = GetTargets()
            if #targets > 0 then AttackMultipleTargets(targets) end
            task.wait(0.05)
        end
    end)
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
                orbitMelee += math.rad(500)
                root.CFrame = root.CFrame * CFrame.new(math.cos(orbitMelee)*3, 0, math.sin(orbitMelee)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.Name:lower():find("fist") or tool.Name:lower():find("melee") or tool.Name:lower():find("combat")) then
                        hum:EquipTool(tool)
                    end
                end
                task.wait(0.25)
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true,  Enum.KeyCode.Z, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(0.4)
                hum.Health = 0
            end
        end
    end)
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
                orbitSword += math.rad(500)
                root.CFrame = root.CFrame * CFrame.new(math.cos(orbitSword)*3, 0, math.sin(orbitSword)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.ToolTip == "Sword" or tool.Name:lower():find("sword") or tool.Name:lower():find("katana") or tool.Name:lower():find("blade")) then
                        hum:EquipTool(tool)
                    end
                end
                task.wait(0.25)
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true,  Enum.KeyCode.Z, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
                task.wait(0.4)
                hum.Health = 0
            end
        end
    end)
    if InfElevSwordConn then InfElevSwordConn:Disconnect() end
    InfElevSwordConn = RunService.RenderStepped:Connect(function(dt)
        if InfRangeSwordOn then
            local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame + Vector3.new(0, UP_SPEED * dt, 0) end
        end
    end)
end

-- ============================================================
--  MAGNETO
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.02)
        if getgenv().MagnetEnabled then
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local function Atraer(entidad)
                    local eHRP = entidad:FindFirstChild("HumanoidRootPart")
                    local eHum = entidad:FindFirstChild("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 then
                        if (eHRP.Position - myHRP.Position).Magnitude <= getgenv().MagnetRange then
                            local targetPos = myHRP.CFrame * CFrame.new(0, 0, -getgenv().MagnetDistance)
                            eHRP.CFrame = eHRP.CFrame:Lerp(targetPos, getgenv().PullForce)
                            eHRP.CanCollide = false
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then for _, npc in pairs(enemies:GetChildren()) do Atraer(npc) end end
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then Atraer(p.Character) end
                end
            end)
        end
    end
end)

-- ============================================================
--  ANTI TRACKER
-- ============================================================
local function StartAntiTracker()
    pcall(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then AntiTP_LastPos = hrp.CFrame end
    end)
    if AntiTP_Connection then AntiTP_Connection:Disconnect() end
    AntiTP_Connection = RunService.Heartbeat:Connect(function()
        if not AntiTP_Enabled then return end
        pcall(function()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if AntiTP_LastPos then
                local dist = (hrp.Position - AntiTP_LastPos.Position).Magnitude
                if dist > AntiTP_Threshold then hrp.CFrame = AntiTP_LastPos
                else AntiTP_LastPos = hrp.CFrame end
            else AntiTP_LastPos = hrp.CFrame end
        end)
    end)
end

-- ============================================================
--  FAKE LAG
-- ============================================================
task.spawn(function()
    while true do
        task.wait(FakeLag_Interval)
        if FakeLag_Enabled then
            local start = tick()
            while tick() - start < FakeLag_Duration do end
        end
    end
end)

-- ============================================================
--  TRACKER LOOPS
-- ============================================================
local function StartTracker()
    if TrackConn then TrackConn:Disconnect() end
    TrackConn = RunService.Heartbeat:Connect(function()
        if not getgenv().TrackingActive or not getgenv().SelectedPlayer then return end
        pcall(function()
            local target = Players:FindFirstChild(getgenv().SelectedPlayer)
            if not (target and target.Character) then return end
            local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not (tHRP and myHRP) then return end
            if getgenv().TPDirectActive then
                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 1.5, 3.5)
            elseif getgenv().KillTrackerActive then
                myHRP.CFrame = tHRP.CFrame + Vector3.new(0, getgenv().TrackerHeight, 0)
            end
        end)
    end)
end

-- Sky Tracker loop
task.spawn(function()
    while true do
        task.wait(0.01)
        pcall(function()
            if not getgenv().InstaTPSkyActive or not getgenv().SelectedPlayer then return end
            local target = Players:FindFirstChild(getgenv().SelectedPlayer)
            local myHRP  = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if target and target.Character and myHRP then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    for _, v in pairs(lp.Character:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                    myHRP.CFrame = tHRP.CFrame * CFrame.new(0, getgenv().InstaTPSkyHeight, 0)
                end
            end
        end)
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
        if getgenv().NoclipEnabled then
            for _, v in pairs(lp.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        if getgenv().WalkOnWater and root and root.Position.Y < 20 then
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, 21, pos.Z) * (root.CFrame - root.Position)
        end
        if speedActive and hum and hum.MoveDirection.Magnitude > 0 then
            lp.Character:TranslateBy(hum.MoveDirection * (speedValue / 55))
        end
        if getgenv().SpinEnabled and root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(getgenv().SpinSpeed), 0)
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    if ZoomEnabled then lp.CameraMaxZoomDistance = extendedMaxZoom
    else lp.CameraMaxZoomDistance = 128 end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Farm loops
task.spawn(function()
    while true do
        task.wait()
        if Farm_OrbitActive then
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local npc = GetNearestNPC()
                if not npc then return end
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if not npcHRP then return end
                local t = tick() * Farm_OrbitSpeed
                local target = npcHRP.Position + Vector3.new(math.cos(t)*Farm_OrbitDist, 3, math.sin(t)*Farm_OrbitDist)
                myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.lookAt(target, npcHRP.Position), 0.2)
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()
        if Farm_AboveActive then
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local npc = GetNearestNPC()
                if not npc then return end
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if not npcHRP then return end
                myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(npcHRP.Position + Vector3.new(0, Farm_AboveHeight, 0)), 0.15)
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.02)
        if Farm_MagnetActive then
            pcall(function()
                local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local belowMe = myHRP.Position + Vector3.new(0, Farm_MagnetHeight, 0)
                local npc = GetNearestNPC()
                if not npc then return end
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    npcHRP.CFrame = npcHRP.CFrame:Lerp(CFrame.new(belowMe), Farm_MagnetForce)
                    npcHRP.CanCollide = false
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if Farm_RaidActive then
            pcall(function()
                local char  = lp.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                local hum   = char and char:FindFirstChildOfClass("Humanoid")
                if not myHRP or not hum then return end
                local npc = GetNearestNPC()
                if not npc then return end
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if not npcHRP then return end
                hum.WalkSpeed = Farm_RaidSpeed
                hum:MoveTo(npcHRP.Position)
            end)
        end
    end
end)

-- ============================================================
--  FLUENT UI — VENTANA PRINCIPAL
-- ============================================================
local Window = Fluent:CreateWindow({
    Title   = "Tommy Hub v4.0",
    SubTitle = "by terrino48",
    TabWidth = 160,
    Size     = UDim2.fromOffset(580, 460),
    Acrylic  = true,
    Theme    = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

-- ============================================================
--  TABS
-- ============================================================
local Tabs = {
    Combate  = Window:AddTab({ Title = "⚔️ Combate",    Icon = "sword" }),
    KillNPC  = Window:AddTab({ Title = "💀 Kill NPC",   Icon = "skull" }),
    Frutas   = Window:AddTab({ Title = "🍎 Frutas",     Icon = "star" }),
    Tracker  = Window:AddTab({ Title = "🎯 Tracker",    Icon = "crosshair" }),
    Movimiento = Window:AddTab({ Title = "🏃 Mov",      Icon = "zap" }),
    Defensa  = Window:AddTab({ Title = "🛡️ Defensa",   Icon = "shield" }),
    Farm     = Window:AddTab({ Title = "🌾 Farm",       Icon = "activity" }),
    Teleports = Window:AddTab({ Title = "🗺️ TPs",      Icon = "map-pin" }),
    Misc     = Window:AddTab({ Title = "⚙️ Misc",       Icon = "settings" }),
}

-- ============================================================
--  TAB: COMBATE
-- ============================================================
Tabs.Combate:AddParagraph({ Title = "Fast Attack", Content = "Lock-On automático. Pausa durante habilidades." })

Tabs.Combate:AddToggle("FastAttack", {
    Title   = "⚡ Fast Attack (Lock-On + Infinito)",
    Default = false,
    Callback = function(v)
        getgenv().FastAttackEnabled = v
        if v then
            task.spawn(function()
                local i = 0
                while (not RegisterHit or not RegisterAttack) and i < 20 do task.wait(0.5); i += 1 end
                if RegisterHit and RegisterAttack then StartFastAttack() end
            end)
        else
            if FastAttackConn then task.cancel(FastAttackConn); FastAttackConn = nil end
        end
    end,
})

Tabs.Combate:AddParagraph({ Title = "Inf Range Melee", Content = "Usa melee desde cualquier distancia." })

Tabs.Combate:AddToggle("InfMelee", {
    Title   = "👊 Inf Range Melee",
    Default = false,
    Callback = function(v)
        InfRangeMeleeOn = v
        if v then StartInfRangeMelee()
        else
            if InfRangeMeleeConn then task.cancel(InfRangeMeleeConn); InfRangeMeleeConn = nil end
            if InfElevMeleeConn  then InfElevMeleeConn:Disconnect();  InfElevMeleeConn  = nil end
        end
    end,
})

Tabs.Combate:AddToggle("InfSword", {
    Title   = "⚔️ Inf Range Sword",
    Default = false,
    Callback = function(v)
        InfRangeSwordOn = v
        if v then StartInfRangeSword()
        else
            if InfRangeSwordConn then task.cancel(InfRangeSwordConn); InfRangeSwordConn = nil end
            if InfElevSwordConn  then InfElevSwordConn:Disconnect();  InfElevSwordConn  = nil end
        end
    end,
})

Tabs.Combate:AddParagraph({ Title = "Ghost TP + Trackers", Content = "" })

Tabs.Combate:AddToggle("GhostTP", {
    Title   = "👻 Ghost TP (Invisible)",
    Default = false,
    Callback = function(v)
        GhostTpEnabled = v
        if v then StartGhostTP()
        else if GhostTpConnection then GhostTpConnection:Disconnect() end end
    end,
})

Tabs.Combate:AddToggle("BlinkMode", {
    Title   = "⚡ Blink Mode",
    Default = false,
    Callback = function(v) BlinkMode = v end,
})

Tabs.Combate:AddToggle("InstaTP", {
    Title   = "📌 Insta TP (Pegado al jugador)",
    Default = false,
    Callback = function(v)
        getgenv().TPDirectActive = v
        if v then getgenv().TrackingActive = true; StartTracker() end
    end,
})

Tabs.Combate:AddToggle("KillFlash", {
    Title   = "💀 Kill Flash (Encima)",
    Default = false,
    Callback = function(v)
        getgenv().KillTrackerActive = v
        if v then getgenv().TrackingActive = true; StartTracker() end
    end,
})

Tabs.Combate:AddToggle("AutoV4", {
    Title   = "⚡ Auto V4",
    Default = false,
    Callback = function(v)
        autoV4 = v
        if v then
            if v4Connection then task.cancel(v4Connection) end
            v4Connection = task.spawn(function()
                while autoV4 do
                    task.wait(0.5)
                    pcall(function()
                        local args = {true}
                        lp:WaitForChild("Backpack"):WaitForChild("Awakening"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
                    end)
                end
            end)
        else
            if v4Connection then task.cancel(v4Connection); v4Connection = nil end
        end
    end,
})

Tabs.Combate:AddToggle("Unbreakable", {
    Title   = "🛡️ Unbreakable",
    Default = false,
    Callback = function(v)
        Unbreakable = v
        if v then
            if UnbreakableConn then task.cancel(UnbreakableConn) end
            UnbreakableConn = task.spawn(function()
                while Unbreakable do
                    task.wait(0.1)
                    pcall(function()
                        if lp.Character:GetAttribute("Unbreakable") ~= true then
                            lp.Character:SetAttribute("UnbreakableAll", true)
                        end
                    end)
                end
            end)
        else
            if UnbreakableConn then task.cancel(UnbreakableConn); UnbreakableConn = nil end
            pcall(function() lp.Character:SetAttribute("UnbreakableAll", false) end)
        end
    end,
})

Tabs.Combate:AddToggle("AntiMover", {
    Title   = "🔒 Anti Mover",
    Default = false,
    Callback = function(v)
        if v then
            local function add(char)
                if not char:FindFirstChild("AntiMover") then
                    Instance.new("Folder", char).Name = "AntiMover"
                end
            end
            if lp.Character then add(lp.Character) end
            _G.AntiMoverConn = lp.CharacterAdded:Connect(add)
        else
            if _G.AntiMoverConn then _G.AntiMoverConn:Disconnect() end
            if lp.Character and lp.Character:FindFirstChild("AntiMover") then
                lp.Character.AntiMover:Destroy()
            end
        end
    end,
})

-- Magneto en Combate también
Tabs.Combate:AddParagraph({ Title = "Magneto", Content = "" })

Tabs.Combate:AddToggle("Magnet", {
    Title   = "🧲 Magneto",
    Default = false,
    Callback = function(v) getgenv().MagnetEnabled = v end,
})

Tabs.Combate:AddSlider("MagnetRange", {
    Title   = "Rango Magneto",
    Default = 800,
    Min = 100, Max = 5000, Rounding = 50,
    Callback = function(v) getgenv().MagnetRange = v end,
})

Tabs.Combate:AddSlider("MagnetDist", {
    Title   = "Distancia Magneto",
    Default = 6,
    Min = 1, Max = 50, Rounding = 1,
    Callback = function(v) getgenv().MagnetDistance = v end,
})

Tabs.Combate:AddSlider("MagnetForce", {
    Title   = "Fuerza Magneto",
    Default = 70,
    Min = 1, Max = 100, Rounding = 1,
    Callback = function(v) getgenv().PullForce = v / 100 end,
})

-- ============================================================
--  TAB: KILL NPC
-- ============================================================
Tabs.KillNPC:AddParagraph({ Title = "Fast Attack NPCs", Content = "Solo ataca enemigos en workspace.Enemies" })

Tabs.KillNPC:AddToggle("FANPCs", {
    Title   = "⚔️ Fast Attack (Solo NPCs)",
    Default = false,
    Callback = function(v)
        if v then
            task.spawn(function()
                while v do
                    task.wait(0.05)
                    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not myHRP then continue end
                    local targets = {}
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, npc in pairs(enemies:GetChildren()) do
                            local hum = npc:FindFirstChild("Humanoid")
                            local hrp = npc:FindFirstChild("HumanoidRootPart")
                            if hum and hrp and hum.Health > 0 then table.insert(targets, npc) end
                        end
                    end
                    if #targets > 0 then AttackMultipleTargets(targets) end
                end
            end)
        end
    end,
})

-- ============================================================
--  TAB: FRUTAS (Players)
-- ============================================================
Tabs.Frutas:AddParagraph({ Title = "Fruit Attack (Players)", Content = "Activa el ataque de frutas al jugador más cercano" })

local function MakeFruitToggle(tab, name, fruitPath, args_fn)
    tab:AddToggle("Fruit_"..name, {
        Title   = "🍎 " .. name,
        Default = false,
        Callback = function(v)
            FruitAttack = v
            if v then
                if FruitAttackConn then task.cancel(FruitAttackConn) end
                FruitAttackConn = task.spawn(function()
                    while FruitAttack do
                        task.wait(0.01)
                        pcall(function()
                            local target = GetNearestPlayer()
                            if not target or not target.Character then return end
                            local myHRP  = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            local tHRP   = target.Character:FindFirstChild("HumanoidRootPart")
                            if not myHRP or not tHRP then return end
                            local dir  = (tHRP.Position - myHRP.Position).Unit
                            local args = args_fn(dir, tHRP)
                            lp.Character:WaitForChild(fruitPath):WaitForChild("LeftClickRemote"):FireServer(unpack(args))
                        end)
                    end
                end)
            else
                FruitAttack = false
                if FruitAttackConn then task.cancel(FruitAttackConn); FruitAttackConn = nil end
            end
        end,
    })
end

MakeFruitToggle(Tabs.Frutas, "Kitsune",        "Kitsune-Kitsune",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1, true } end)
MakeFruitToggle(Tabs.Frutas, "Dragon",         "Dragon-Dragon",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1 } end)
MakeFruitToggle(Tabs.Frutas, "Tiger",          "Tiger-Tiger",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 3 } end)
MakeFruitToggle(Tabs.Frutas, "T-Rex",          "T-Rex-T-Rex",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1 } end)
MakeFruitToggle(Tabs.Frutas, "Control",        "Control-Control",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1, true } end)
MakeFruitToggle(Tabs.Frutas, "Pain",           "Pain-Pain",
    function(dir) return { vector.create(dir.X, 0, dir.Z), 1, true } end)

Tabs.Frutas:AddParagraph({ Title = "Fruit Attack (Solo NPCs)", Content = "" })

local function MakeFruitNPCToggle(tab, name, fruitPath, args_fn)
    tab:AddToggle("FruitNPC_"..name, {
        Title   = "💀 " .. name .. " [NPCs]",
        Default = false,
        Callback = function(v)
            if v then
                if _G["FNPCConn_"..name] then task.cancel(_G["FNPCConn_"..name]) end
                _G["FNPCConn_"..name] = task.spawn(function()
                    while v do
                        task.wait(0.01)
                        pcall(function()
                            local char = lp.Character
                            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                            if not hrp then return end
                            local enemies = workspace:FindFirstChild("Enemies")
                            if not enemies then return end
                            for _, npc in pairs(enemies:GetChildren()) do
                                local hum    = npc:FindFirstChild("Humanoid")
                                local npcHrp = npc:FindFirstChild("HumanoidRootPart")
                                if hum and npcHrp and hum.Health > 0 and (npcHrp.Position - hrp.Position).Magnitude <= 50 then
                                    local dir  = (npcHrp.Position - hrp.Position).Unit
                                    local args = args_fn(dir, npcHrp)
                                    char:WaitForChild(fruitPath):WaitForChild("LeftClickRemote"):FireServer(unpack(args))
                                end
                            end
                        end)
                    end
                end)
            else
                v = false
                if _G["FNPCConn_"..name] then task.cancel(_G["FNPCConn_"..name]); _G["FNPCConn_"..name] = nil end
            end
        end,
    })
end

MakeFruitNPCToggle(Tabs.Frutas, "Kitsune",  "Kitsune-Kitsune",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1, true } end)
MakeFruitNPCToggle(Tabs.Frutas, "Control",  "Control-Control",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1, true } end)
MakeFruitNPCToggle(Tabs.Frutas, "Pain",     "Pain-Pain",
    function(dir) return { vector.create(dir.X, 0, dir.Z), 1, true } end)
MakeFruitNPCToggle(Tabs.Frutas, "Dragon",   "Dragon-Dragon",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 1 } end)
MakeFruitNPCToggle(Tabs.Frutas, "Tiger",    "Tiger-Tiger",
    function(dir) return { vector.create(dir.X, dir.Y, dir.Z), 3 } end)

-- ============================================================
--  TAB: TRACKER
-- ============================================================
local playerNames = UpdatePlayerList()

local PlayerDropdown = Tabs.Tracker:AddDropdown("PlayerDrop", {
    Title   = "👤 Seleccionar Jugador",
    Values  = playerNames,
    Default = playerNames[1],
    Callback = function(v)
        getgenv().SelectedPlayer = v ~= "Ninguno" and v or nil
    end,
})

Tabs.Tracker:AddButton({
    Title = "🔄 Refrescar Lista",
    Callback = function()
        PlayerDropdown:SetValues(UpdatePlayerList())
    end,
})

Tabs.Tracker:AddToggle("SkyTracker", {
    Title   = "☁️ Sky Tracker",
    Default = false,
    Callback = function(v) getgenv().InstaTPSkyActive = v end,
})

Tabs.Tracker:AddSlider("SkyHeight", {
    Title   = "Altura Sky Tracker",
    Default = 300,
    Min = 50, Max = 1000, Rounding = 10,
    Callback = function(v) getgenv().InstaTPSkyHeight = v end,
})

Tabs.Tracker:AddToggle("KillTracker2", {
    Title   = "🗡️ Kill Tracker (Encima del jugador)",
    Default = false,
    Callback = function(v)
        getgenv().KillTrackerActive = v
        if v then getgenv().TrackingActive = true; StartTracker() end
    end,
})

Tabs.Tracker:AddSlider("TrackerH", {
    Title   = "Altura Kill Tracker",
    Default = 300,
    Min = 10, Max = 1000, Rounding = 10,
    Callback = function(v) getgenv().TrackerHeight = v end,
})

Tabs.Tracker:AddToggle("TPDirect2", {
    Title   = "🔁 TP Direct (Pegado al jugador)",
    Default = false,
    Callback = function(v)
        getgenv().TPDirectActive = v
        if v then getgenv().TrackingActive = true; StartTracker() end
    end,
})

Tabs.Tracker:AddButton({
    Title = "⚡ Instant TP al Jugador",
    Callback = function()
        local target = getgenv().SelectedPlayer and Players:FindFirstChild(getgenv().SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
        end
    end,
})

Tabs.Tracker:AddToggle("AutoTP2", {
    Title   = "🔄 Auto TP (Seguir siempre)",
    Default = false,
    Callback = function(v)
        if v then
            task.spawn(function()
                while v do
                    local target = getgenv().SelectedPlayer and Players:FindFirstChild(getgenv().SelectedPlayer)
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

Tabs.Tracker:AddToggle("Spectate", {
    Title   = "👁️ Spectate Player",
    Default = false,
    Callback = function(v)
        if v and getgenv().SelectedPlayer then
            local target = Players:FindFirstChild(getgenv().SelectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = target.Character.Humanoid
            end
        else
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = lp.Character.Humanoid
            end
        end
    end,
})

-- ============================================================
--  TAB: MOVIMIENTO
-- ============================================================
Tabs.Movimiento:AddToggle("SpeedHack", {
    Title   = "🚀 Speed Hack",
    Default = false,
    Callback = function(v) speedActive = v end,
})

Tabs.Movimiento:AddSlider("SpeedVal", {
    Title   = "Velocidad",
    Default = 16,
    Min = 16, Max = 500, Rounding = 1,
    Callback = function(v) speedValue = v end,
})

Tabs.Movimiento:AddToggle("InfJump", {
    Title   = "⬆️ Infinite Jump",
    Default = false,
    Callback = function(v) _G.InfiniteJump = v end,
})

Tabs.Movimiento:AddToggle("NoClip", {
    Title   = "🔥 No Clip",
    Default = false,
    Callback = function(v) getgenv().NoclipEnabled = v end,
})

Tabs.Movimiento:AddToggle("WalkWater", {
    Title   = "💧 Walk on Water",
    Default = false,
    Callback = function(v) getgenv().WalkOnWater = v end,
})

Tabs.Movimiento:AddToggle("Spin", {
    Title   = "🌀 Spin",
    Default = false,
    Callback = function(v) getgenv().SpinEnabled = v end,
})

Tabs.Movimiento:AddSlider("SpinSpd", {
    Title   = "Velocidad Spin",
    Default = 50,
    Min = 1, Max = 200, Rounding = 1,
    Callback = function(v) getgenv().SpinSpeed = v end,
})

Tabs.Movimiento:AddParagraph({ Title = "✈️ Fly v3", Content = "WASD + Space/Shift" })

Tabs.Movimiento:AddToggle("Fly", {
    Title   = "✈️ Fly",
    Default = false,
    Callback = function(v)
        if v then StartFly() else StopFly() end
    end,
})

Tabs.Movimiento:AddSlider("FlySpd", {
    Title   = "Velocidad Vuelo",
    Default = 60,
    Min = 10, Max = 500, Rounding = 10,
    Callback = function(v) flySpeed = v end,
})

Tabs.Movimiento:AddParagraph({ Title = "Dash", Content = "" })

Tabs.Movimiento:AddToggle("DashToggle", {
    Title   = "💨 Dash Length",
    Default = false,
    Callback = function(v)
        DashEnabled = v
        if v then
            if DashConnection then task.cancel(DashConnection) end
            DashConnection = task.spawn(function()
                while DashEnabled do
                    task.wait(0.1)
                    local char = lp.Character
                    if char then
                        char:SetAttribute("DashLength",    DashLenghDistance)
                        char:SetAttribute("DashLengthAir", DashLenghDistance)
                    end
                end
            end)
        else
            if DashConnection then task.cancel(DashConnection); DashConnection = nil end
            pcall(function()
                lp.Character:SetAttribute("DashLength",    1)
                lp.Character:SetAttribute("DashLengthAir", 1)
            end)
        end
    end,
})

Tabs.Movimiento:AddDropdown("DashVal", {
    Title   = "Valor Dash",
    Values  = {"5", "35", "60", "90", "120", "180"},
    Default = "5",
    Callback = function(v) DashLenghDistance = tonumber(v) or 5 end,
})

Tabs.Movimiento:AddParagraph({ Title = "Cámara", Content = "" })

Tabs.Movimiento:AddToggle("ExtZoom", {
    Title   = "🔭 Extend Zoom",
    Default = false,
    Callback = function(v)
        ZoomEnabled = v
        lp.CameraMaxZoomDistance = v and extendedMaxZoom or 128
    end,
})

Tabs.Movimiento:AddSlider("ZoomVal", {
    Title   = "Zoom Máximo",
    Default = 500,
    Min = 128, Max = 2000, Rounding = 50,
    Callback = function(v)
        extendedMaxZoom = v
        if ZoomEnabled then lp.CameraMaxZoomDistance = v end
    end,
})

-- ============================================================
--  TAB: DEFENSA
-- ============================================================
Tabs.Defensa:AddParagraph({ Title = "Anti Tracker", Content = "Detecta TPs forzados y te regresa." })

Tabs.Defensa:AddToggle("AntiTracker", {
    Title   = "🛡️ Anti Tracker (Anti-TP)",
    Default = false,
    Callback = function(v)
        AntiTP_Enabled = v
        if v then StartAntiTracker()
        else
            if AntiTP_Connection then AntiTP_Connection:Disconnect(); AntiTP_Connection = nil end
            AntiTP_LastPos = nil
        end
    end,
})

Tabs.Defensa:AddSlider("AntiTPThresh", {
    Title   = "Umbral Detección (studs)",
    Default = 10,
    Min = 5, Max = 100, Rounding = 5,
    Callback = function(v) AntiTP_Threshold = v end,
})

Tabs.Defensa:AddParagraph({ Title = "Fake Lag", Content = "Simula lag para dificultar que te golpeen." })

Tabs.Defensa:AddToggle("FakeLag", {
    Title   = "⚡ Fake Lag",
    Default = false,
    Callback = function(v) FakeLag_Enabled = v end,
})

Tabs.Defensa:AddSlider("FakeLagDur", {
    Title   = "Duración Freeze (ms)",
    Default = 50,
    Min = 10, Max = 200, Rounding = 10,
    Callback = function(v) FakeLag_Duration = v / 1000 end,
})

Tabs.Defensa:AddSlider("FakeLagFreq", {
    Title   = "Frecuencia Pulsos (ms)",
    Default = 100,
    Min = 50, Max = 500, Rounding = 25,
    Callback = function(v) FakeLag_Interval = v / 1000 end,
})

Tabs.Defensa:AddParagraph({ Title = "Tracers", Content = "" })

Tabs.Defensa:AddToggle("Tracers", {
    Title   = "🔴 Tracers",
    Default = false,
    Callback = function(v) Tracers_Enabled = v end,
})

Tabs.Defensa:AddDropdown("TracerColor", {
    Title   = "Color Tracer",
    Values  = {"Orange","Cyan","Red","Green","Blue","Yellow","Pink","White","Purple"},
    Default = "Orange",
    Callback = function(v)
        local colors = {
            Orange = Color3.fromRGB(255,165,0), Cyan = Color3.fromRGB(0,255,255),
            Red    = Color3.fromRGB(255,0,0),   Green  = Color3.fromRGB(0,255,0),
            Blue   = Color3.fromRGB(0,0,255),   Yellow = Color3.fromRGB(255,255,0),
            Pink   = Color3.fromRGB(255,105,180),White = Color3.fromRGB(255,255,255),
            Purple = Color3.fromRGB(160,32,240),
        }
        Tracers_Color = colors[v] or Color3.fromRGB(255,165,0)
    end,
})

Tabs.Defensa:AddSlider("TracerThick", {
    Title   = "Grosor Tracer",
    Default = 15,
    Min = 5, Max = 50, Rounding = 1,
    Callback = function(v) Tracers_Thickness = v / 10 end,
})

Tabs.Defensa:AddParagraph({ Title = "ESP", Content = "" })

Tabs.Defensa:AddToggle("ESP", {
    Title   = "👁️ ESP (Nombre + Distancia)",
    Default = false,
    Callback = function(v)
        ESPEnabled = v
        if v then UpdateESP() else ClearESP() end
    end,
})

Tabs.Defensa:AddDropdown("ESPColor", {
    Title   = "Color ESP",
    Values  = {"Cyan","White","Red","Green","Blue","Yellow","Orange","Pink","Purple"},
    Default = "Cyan",
    Callback = function(v)
        local colors = {
            Cyan   = Color3.fromRGB(0,255,255),  White  = Color3.fromRGB(255,255,255),
            Red    = Color3.fromRGB(255,0,0),     Green  = Color3.fromRGB(0,255,0),
            Blue   = Color3.fromRGB(0,0,255),     Yellow = Color3.fromRGB(255,255,0),
            Orange = Color3.fromRGB(255,165,0),   Pink   = Color3.fromRGB(255,105,180),
            Purple = Color3.fromRGB(160,32,240),
        }
        ESPColor = colors[v] or Color3.fromRGB(0,255,255)
        if ESPEnabled then UpdateESP() end
    end,
})

-- ============================================================
--  TAB: FARM
-- ============================================================
Tabs.Farm:AddToggle("FarmOrbit", {
    Title   = "🔄 Orbitar NPC",
    Default = false,
    Callback = function(v) Farm_OrbitActive = v; if v then Farm_AboveActive = false end end,
})

Tabs.Farm:AddToggle("FarmAbove", {
    Title   = "⬆️ Quedarse Arriba del NPC",
    Default = false,
    Callback = function(v) Farm_AboveActive = v; if v then Farm_OrbitActive = false end end,
})

Tabs.Farm:AddSlider("FarmAboveH", {
    Title   = "Altura sobre NPC",
    Default = 12,
    Min = 5, Max = 50, Rounding = 1,
    Callback = function(v) Farm_AboveHeight = v end,
})

Tabs.Farm:AddSlider("FarmOrbitSpd", {
    Title   = "Velocidad Órbita",
    Default = 5,
    Min = 1, Max = 15, Rounding = 1,
    Callback = function(v) Farm_OrbitSpeed = v end,
})

Tabs.Farm:AddSlider("FarmOrbitDist", {
    Title   = "Distancia Órbita",
    Default = 15,
    Min = 5, Max = 60, Rounding = 1,
    Callback = function(v) Farm_OrbitDist = v end,
})

Tabs.Farm:AddToggle("FarmMagnet", {
    Title   = "🧲 Magneto NPC (Abajo de ti)",
    Default = false,
    Callback = function(v) Farm_MagnetActive = v end,
})

Tabs.Farm:AddSlider("FarmMagH", {
    Title   = "Offset Y Magneto",
    Default = -4,
    Min = -20, Max = 0, Rounding = 1,
    Callback = function(v) Farm_MagnetHeight = v end,
})

Tabs.Farm:AddSlider("FarmMagF", {
    Title   = "Fuerza Magneto Farm",
    Default = 15,
    Min = 1, Max = 30, Rounding = 1,
    Callback = function(v) Farm_MagnetForce = v / 100 end,
})

Tabs.Farm:AddToggle("FarmRaid", {
    Title   = "🚶 Raid Mode (Caminar al NPC)",
    Default = false,
    Callback = function(v)
        Farm_RaidActive = v
        if not v then
            pcall(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum and not speedActive then hum.WalkSpeed = 16 end
            end)
        end
    end,
})

Tabs.Farm:AddSlider("FarmRaidSpd", {
    Title   = "Velocidad Raid",
    Default = 16,
    Min = 8, Max = 100, Rounding = 2,
    Callback = function(v) Farm_RaidSpeed = v end,
})

Tabs.Farm:AddButton({
    Title = "🚪 Ir a Siguiente Sala",
    Callback = function()
        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local markers = {"Next","Gate","Portal","Door","Exit","Teleport"}
        for _, name in pairs(markers) do
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:find(name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    myHRP.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    return
                end
            end
        end
    end,
})

-- ============================================================
--  TAB: TELEPORTS
-- ============================================================
Tabs.Teleports:AddParagraph({ Title = "Sea 1", Content = "" })
Tabs.Teleports:AddButton({ Title = "🏝️ Tiki Outpost",       Callback = function() TpTo(CFrame.new(-16826,58,317))   end })
Tabs.Teleports:AddButton({ Title = "🏰 Castillo Embrujado", Callback = function() TpTo(CFrame.new(-9515,142,5533))  end })

Tabs.Teleports:AddParagraph({ Title = "Sea 2", Content = "" })
Tabs.Teleports:AddButton({ Title = "🌹 Reino de Rosa",       Callback = function() TpTo(CFrame.new(-401,335,642))    end })
Tabs.Teleports:AddButton({ Title = "⚓ Barco Maldito",       Callback = function() TpTo(CFrame.new(-6511,87,-140))   end })
Tabs.Teleports:AddButton({ Title = "🚢 Barco (Dentro)",      Callback = function() TpTo(CFrame.new(923,125,32852))   end })
Tabs.Teleports:AddButton({ Title = "🏝️ Isla Principal S2",  Callback = function() TpTo(CFrame.new(-2.6,19,1018))    end })

Tabs.Teleports:AddParagraph({ Title = "Sea 3", Content = "" })
Tabs.Teleports:AddButton({ Title = "🏰 Castillo S3",        Callback = function() TpTo(CFrame.new(-5085,316,-3156))  end })
Tabs.Teleports:AddButton({ Title = "🏛️ Mansión",            Callback = function() TpTo(CFrame.new(-12463,375,-7523)) end })
Tabs.Teleports:AddButton({ Title = "🌋 Isla Volcánica",     Callback = function() TpTo(CFrame.new(-7234,345,-4532))  end })

Tabs.Teleports:AddParagraph({ Title = "Utilidades", Content = "" })
Tabs.Teleports:AddButton({
    Title = "👥 TP a Todos (Secuencial)",
    Callback = TeleportToAllPlayers,
})
Tabs.Teleports:AddButton({
    Title = "🗑️ Remove Touch Interest",
    Callback = function()
        for _, d in pairs(game:GetDescendants()) do
            if d:IsA("TouchTransmitter") then d:Destroy() end
        end
    end,
})

-- ============================================================
--  TAB: MISC
-- ============================================================
Tabs.Misc:AddParagraph({ Title = "Protecciones Activas", Content = "✅ Anti AFK\n✅ Anti Kick\nActivados automáticamente al cargar" })
Tabs.Misc:AddParagraph({ Title = "Tommy Hub v4.0", Content = "Fusión Tommy Hub + Azucar Hub\nby terrino48\nInterfaz: Fluent UI" })

-- ============================================================
--  SAVE MANAGER + INTERFACE MANAGER
-- ============================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TommyHubV4")
SaveManager:SetFolder("TommyHubV4/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Misc)
SaveManager:BuildConfigSection(Tabs.Misc)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title   = "Tommy Hub v4.0",
    Content = "✅ Cargado | Anti AFK + Anti Kick activos\nFluent UI | Tommy + Azucar fusionados",
    Duration = 6,
})
