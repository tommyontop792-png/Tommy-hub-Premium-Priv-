local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local lp = Players.LocalPlayer

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
local ESPEnabled        = false
local ESPObjects        = {}
local FastAttackEnabled = false
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
local TrackingActive    = false
local SelectedPlayer    = nil
local TrackConn         = nil
local SkyTrackActive    = false
local KillTrackerActive = false
local TPDirectActive    = false
local walkWaterEnabled  = false
local noclipEnabled     = false
local infiniteJump      = false
local speedActive       = false
local speedValue        = 16
local MagnetEnabled     = false
local MagnetRange       = 800
local MagnetForce       = 0.7
local ZoomEnabled       = false
local extendedMaxZoom   = 500
local FlyEnabled        = false
local FlySpeed          = 60
local bv, bg            = nil, nil
local abilityLockout    = false
local frozenCFrame      = nil
local RegisterHit       = nil
local RegisterAttack    = nil

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
local VIM = game:GetService("VirtualInputManager")
task.spawn(function()
    while true do
        task.wait(60)
        pcall(function()
            VIM:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
end)

-- ============================================================
--  ANTI KICK
-- ============================================================
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if getnamecallmethod() == "Kick" then return end
    return old(self, ...)
end)
setreadonly(mt, true)

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
    bb.Size = UDim2.new(0,120,0,50)
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.Font = "GothamBold"
    lbl.TextSize = 13
    lbl.TextStrokeTransparency = 0.4
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
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do CreateESP(npc) end
    end
end

task.spawn(function()
    while true do task.wait(3) if ESPEnabled then UpdateESP() end end
end)

-- ============================================================
--  LOCK-ON (para Fast Attack)
-- ============================================================
local function IsUsingAbility(char)
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChild("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:find("skill") or n:find("ability") or n:find("dash")
            or n:find("cast") or n:find("fruit") then return true end
        end
    end
    if hum:GetState() == Enum.HumanoidStateType.Physics then return true end
    return false
end

local function GetLockOnTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            if p.Character:FindFirstChildOfClass("Highlight") then
                return p.Character
            end
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

-- Freeze durante habilidad
RunService.Heartbeat:Connect(function()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local using = IsUsingAbility(char)
    if using and not abilityLockout then
        abilityLockout = true
        frozenCFrame   = hrp.CFrame
    end
    if abilityLockout and using then
        hrp.CFrame = frozenCFrame
    end
    if not using and abilityLockout then
        abilityLockout = false
        frozenCFrame   = nil
    end
end)

-- ============================================================
--  FAST ATTACK FUSIONADO
-- ============================================================
local function GetTargets()
    if abilityLockout then return {} end
    local lockTarget = GetLockOnTarget()
    if lockTarget then return {lockTarget} end

    -- Fallback: todos en rango
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local pHum = p.Character:FindFirstChild("Humanoid")
            local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if pHum and pHRP and pHum.Health > 0 then
                table.insert(targets, p.Character)
            end
        end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do
            local nHum = npc:FindFirstChild("Humanoid")
            local nHRP = npc:FindFirstChild("HumanoidRootPart")
            if nHum and nHRP and nHum.Health > 0 then
                table.insert(targets, npc)
            end
        end
    end
    return targets
end

local function FireAttack(targets)
    if not RegisterHit or not RegisterAttack then return end
    if #targets == 0 then return end
    pcall(function()
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

local function StartFastAttack()
    if FastAttackConn then task.cancel(FastAttackConn) FastAttackConn = nil end
    FastAttackConn = task.spawn(function()
        while FastAttackEnabled do
            local targets = GetTargets()
            if #targets > 0 then FireAttack(targets) end
            task.wait(0.05)
        end
    end)
end

local function StopFastAttack()
    FastAttackEnabled = false
    if FastAttackConn then task.cancel(FastAttackConn) FastAttackConn = nil end
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
--  FLY V3
-- ============================================================
local function StopFly()
    FlyEnabled = false
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    pcall(function()
        if lp.Character then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            local anim = lp.Character:FindFirstChild("Animate")
            if anim then anim.Disabled = false end
        end
    end)
end

local function StartFly()
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    StopFly()
    FlyEnabled = true
    local root = char.HumanoidRootPart
    local anim = char:FindFirstChild("Animate")
    if anim then anim.Disabled = true end
    bg = Instance.new("BodyGyro", root)
    bg.D = 100; bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
    bg.CFrame = root.CFrame
    bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    task.spawn(function()
        while FlyEnabled and char.Parent and root.Parent do
            local cam   = workspace.CurrentCamera
            local camCF = cam.CFrame
            local fwd   = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
            local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
            local vel   = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + fwd   * FlySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - fwd   * FlySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + right * FlySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - right * FlySpeed end
            local yVel = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then yVel =  FlySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then yVel = -FlySpeed end
            bv.Velocity = Vector3.new(vel.X, yVel, vel.Z)
            bg.CFrame = CFrame.new(root.Position)
                * CFrame.Angles(0, math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z), 0)
            task.wait()
        end
        StopFly()
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
                            local targetPos = myHRP.CFrame * CFrame.new(0, 0, -6)
                            eHRP.CFrame = eHRP.CFrame:Lerp(targetPos, MagnetForce)
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
        if noclipEnabled then
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

RunService.RenderStepped:Connect(function()
    if ZoomEnabled then
        lp.CameraMaxZoomDistance = extendedMaxZoom
    else
        lp.CameraMaxZoomDistance = 128
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJump and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
--  RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Tommy Hub Premium",
    LoadingTitle = "Cargando Tommy Hub...",
    LoadingSubtitle = "v3.0 PREMIUM | terrino48",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TommyHubV3",
        FileName   = "Config"
    },
    Discord   = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
    KeySystem = false,
})

-- ============================================================
--  TAB: COMBATE
-- ============================================================
local CombateTab = Window:CreateTab("⚔️ Combate", 4483362458)

CombateTab:CreateSection("Fast Attack")

CombateTab:CreateToggle({
    Name = "⚡ Fast Attack (Lock-On)",
    CurrentValue = false,
    Flag = "FastAttack",
    Callback = function(v)
        FastAttackEnabled = v
        if v then
            task.spawn(function()
                local i = 0
                while (not RegisterHit or not RegisterAttack) and i < 20 do
                    task.wait(0.5) i += 1
                end
                if RegisterHit and RegisterAttack then
                    StartFastAttack()
                    Rayfield:Notify({ Title = "Fast Attack", Content = "✅ Activado con Lock-On", Duration = 3, Image = 4483362458 })
                else
                    FastAttackEnabled = false
                    Rayfield:Notify({ Title = "Fast Attack", Content = "❌ Remotes no encontrados", Duration = 4, Image = 4483362458 })
                end
            end)
        else
            StopFastAttack()
        end
    end,
})

CombateTab:CreateSection("Inf Range Melee")

CombateTab:CreateToggle({
    Name = "👊 Inf Range Melee",
    CurrentValue = false,
    Flag = "InfMelee",
    Callback = function(v)
        InfRangeMeleeOn = v
        if v then
            StartInfRangeMelee()
            StartElevMelee()
            Rayfield:Notify({ Title = "Inf Range Melee", Content = "✅ Activado", Duration = 3, Image = 4483362458 })
        else
            if InfRangeMeleeConn then task.cancel(InfRangeMeleeConn) InfRangeMeleeConn = nil end
            if InfElevMeleeConn  then InfElevMeleeConn:Disconnect()  InfElevMeleeConn  = nil end
        end
    end,
})

CombateTab:CreateSection("Inf Range Sword")

CombateTab:CreateToggle({
    Name = "⚔️ Inf Range Sword",
    CurrentValue = false,
    Flag = "InfSword",
    Callback = function(v)
        InfRangeSwordOn = v
        if v then
            StartInfRangeSword()
            StartElevSword()
            Rayfield:Notify({ Title = "Inf Range Sword", Content = "✅ Activado", Duration = 3, Image = 4483362458 })
        else
            if InfRangeSwordConn then task.cancel(InfRangeSwordConn) InfRangeSwordConn = nil end
            if InfElevSwordConn  then InfElevSwordConn:Disconnect()  InfElevSwordConn  = nil end
        end
    end,
})

CombateTab:CreateSection("Magneto")

CombateTab:CreateToggle({
    Name = "🧲 Magneto",
    CurrentValue = false,
    Flag = "Magnet",
    Callback = function(v) MagnetEnabled = v end,
})

CombateTab:CreateSlider({
    Name = "📏 Rango Magneto",
    Range = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = 800,
    Flag = "MagnetRange",
    Callback = function(v) MagnetRange = v end,
})

CombateTab:CreateSlider({
    Name = "💪 Fuerza Magneto",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 7,
    Flag = "MagnetForce",
    Callback = function(v) MagnetForce = v / 10 end,
})

CombateTab:CreateSection("Visual")

CombateTab:CreateToggle({
    Name = "👁️ ESP (Nombres + Distancia)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        ESPEnabled = v
        UpdateESP()
    end,
})

-- ============================================================
--  TAB: MOVIMIENTO
-- ============================================================
local MovTab = Window:CreateTab("🏃 Movimiento", 4483362458)

MovTab:CreateSection("Velocidad")

MovTab:CreateToggle({
    Name = "🚀 Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(v) speedActive = v end,
})

MovTab:CreateSlider({
    Name = "⚡ Velocidad",
    Range = {16, 500},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(v) speedValue = v end,
})

MovTab:CreateSection("Movimiento Especial")

MovTab:CreateToggle({
    Name = "⬆️ Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v) infiniteJump = v end,
})

MovTab:CreateToggle({
    Name = "🔥 No Clip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(v) noclipEnabled = v end,
})

MovTab:CreateToggle({
    Name = "💧 Walk on Water",
    CurrentValue = false,
    Flag = "WalkWater",
    Callback = function(v) walkWaterEnabled = v end,
})

MovTab:CreateSection("✈️ Fly v3")

MovTab:CreateToggle({
    Name = "✈️ Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        FlyEnabled = v
        if v then
            StartFly()
            Rayfield:Notify({ Title = "Fly v3", Content = "WASD + Space/Shift", Duration = 3, Image = 4483362458 })
        else
            StopFly()
        end
    end,
})

MovTab:CreateSlider({
    Name = "💨 Velocidad Vuelo",
    Range = {10, 300},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 60,
    Flag = "FlySpeed",
    Callback = function(v) FlySpeed = v end,
})

MovTab:CreateSection("Cámara")

MovTab:CreateToggle({
    Name = "🔭 Extend Zoom",
    CurrentValue = false,
    Flag = "ExtZoom",
    Callback = function(v)
        ZoomEnabled = v
        lp.CameraMaxZoomDistance = v and extendedMaxZoom or 128
    end,
})

MovTab:CreateSlider({
    Name = "🔭 Zoom Máximo",
    Range = {128, 1000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "ZoomVal",
    Callback = function(v)
        extendedMaxZoom = v
        if ZoomEnabled then lp.CameraMaxZoomDistance = v end
    end,
})

-- ============================================================
--  TAB: TRACKER
-- ============================================================
local TrackerTab = Window:CreateTab("🎯 Tracker", 4483362458)

TrackerTab:CreateSection("Jugador Objetivo")

local playerList = GetPlayerList()
local selectedName = playerList[1]

TrackerTab:CreateDropdown({
    Name       = "👤 Seleccionar Jugador",
    Options    = playerList,
    CurrentOption = {playerList[1]},
    Flag       = "PlayerDrop",
    Callback   = function(opt)
        selectedName   = opt[1]
        SelectedPlayer = opt[1]
    end,
})

TrackerTab:CreateButton({
    Name = "🔄 Refrescar Lista",
    Callback = function()
        Rayfield:Notify({ Title = "Lista", Content = "Reinicia el script para actualizar jugadores", Duration = 3, Image = 4483362458 })
    end,
})

TrackerTab:CreateSection("Modos Tracker")

TrackerTab:CreateToggle({
    Name = "🗡️ Kill Tracker (Encima del jugador)",
    CurrentValue = false,
    Flag = "KillTracker",
    Callback = function(v)
        KillTrackerActive = v
        if v then
            TrackingActive = true
            SelectedPlayer = selectedName
            StartTracker()
        else
            TrackingActive = false
            if TrackConn then TrackConn:Disconnect() TrackConn = nil end
        end
    end,
})

TrackerTab:CreateToggle({
    Name = "🔁 TP Direct (Pegado al jugador)",
    CurrentValue = false,
    Flag = "TPDirect",
    Callback = function(v)
        TPDirectActive = v
        if v then
            TrackingActive = true
            SelectedPlayer = selectedName
            StartTracker()
        else
            TrackingActive = false
            if TrackConn then TrackConn:Disconnect() TrackConn = nil end
        end
    end,
})

TrackerTab:CreateToggle({
    Name = "☁️ Sky Tracker (Arriba del mapa)",
    CurrentValue = false,
    Flag = "SkyTrack",
    Callback = function(v)
        SkyTrackActive = v
        SelectedPlayer = selectedName
    end,
})

TrackerTab:CreateSection("Instant TP")

TrackerTab:CreateButton({
    Name = "⚡ Teleport al Jugador",
    Callback = function()
        local target = Players:FindFirstChild(selectedName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
            Rayfield:Notify({ Title = "Instant TP", Content = "✅ TP a " .. selectedName, Duration = 3, Image = 4483362458 })
        else
            Rayfield:Notify({ Title = "Instant TP", Content = "❌ Jugador no disponible", Duration = 3, Image = 4483362458 })
        end
    end,
})

TrackerTab:CreateToggle({
    Name = "🔄 Auto TP (Seguir constantemente)",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(v)
        if v then
            task.spawn(function()
                while Rayfield.Flags and Rayfield.Flags.AutoTP and Rayfield.Flags.AutoTP.CurrentValue do
                    local target = Players:FindFirstChild(selectedName)
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

-- ============================================================
--  TAB: SEA 2
-- ============================================================
local Sea2Tab = Window:CreateTab("🌊 Sea 2", 4483362458)
Sea2Tab:CreateSection("Teleports")

Sea2Tab:CreateButton({ Name = "🗺️ Barco Maldito",    Callback = function() lp.Character:PivotTo(CFrame.new(923,   126,  32852)) end })
Sea2Tab:CreateButton({ Name = "🏝️ Isla Principal",   Callback = function() lp.Character:PivotTo(CFrame.new(-2.6,  19,   1018))  end })
Sea2Tab:CreateButton({ Name = "⚓ Puerto Sea 2",      Callback = function() lp.Character:PivotTo(CFrame.new(979,   19,   1033))  end })

-- ============================================================
--  TAB: SEA 3
-- ============================================================
local Sea3Tab = Window:CreateTab("🏰 Sea 3", 4483362458)
Sea3Tab:CreateSection("Teleports")

Sea3Tab:CreateButton({ Name = "🏰 Castillo",          Callback = function() lp.Character:PivotTo(CFrame.new(-5085,  316, -3156)) end })
Sea3Tab:CreateButton({ Name = "🏛️ Mansión",           Callback = function() lp.Character:PivotTo(CFrame.new(-12463, 375, -7523)) end })
Sea3Tab:CreateButton({ Name = "🌋 Isla Volcánica",    Callback = function() lp.Character:PivotTo(CFrame.new(-7234,  345, -4532)) end })

-- ============================================================
--  TAB: MISC
-- ============================================================
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Protecciones")

MiscTab:CreateLabel("✅ Anti AFK — Activo automáticamente")
MiscTab:CreateLabel("✅ Anti Kick — Activo automáticamente")

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("👑 Tommy Hub v3.0 PREMIUM")
MiscTab:CreateLabel("🔧 by terrino48")

-- ============================================================
--  NOTIFICACIÓN
-- ============================================================
Rayfield:Notify({
    Title   = "Tommy Hub v3.0",
    Content = "✅ Cargado | Anti AFK + Anti Kick activos",
    Duration = 5,
    Image   = 4483362458,
})
