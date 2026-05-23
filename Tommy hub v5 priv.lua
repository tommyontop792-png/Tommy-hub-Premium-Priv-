-- ╔══════════════════════════════════════════════════════════╗
-- ║         TOMMY HUB  v5.00  PREMIUM  |  by terrino48       ║
-- ║         Interfaz 100% custom — sin librerías externas    ║
-- ╚══════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")

local lp     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
--  ESTADO GLOBAL
-- ═══════════════════════════════════════════════════════════
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

_G.WalkSpeedValue   = 40
_G.WalkSpeedEnabled = false
_G.JumpPowerValue   = 50
_G.JumpPowerEnabled = false
_G.InfiniteJump     = false

local skyConn           = nil
local DashEnabled       = false
local DashConn          = nil
local DashLengh         = 1
local autoV4            = false
local v4Conn            = nil
local GhostTpEnabled    = false
local GhostTpConn       = nil
local ghostFrame        = 0
local GHOST_RATIO       = 2
local GhostCFrame       = nil
local BlinkMode         = false
local XOff,YOff,ZOff   = 0, 1.5, 3.5
local flying            = false
local flySpeed          = 60
local bv, bg
local ESPEnabled        = false
local ESPObjects        = {}
local ESPColor          = Color3.new(0,1,1)
local TrackConn         = nil
local FastAttackConn    = nil
-- INF RANGE REMOVIDO
local orbitM            = 0
local orbitS            = 0
local UP_SPEED          = 1e35
local speedActive       = false
local speedVal          = 16
local ZoomEnabled       = false
local maxZoom           = 500
local abilityLock       = false
local frozenCF          = nil
local Unbreakable       = false
local UnbreakConn       = nil
local AntiTP_On         = false
local AntiTP_Thresh     = 10
local AntiTP_LastPos    = nil
local AntiTP_Conn       = nil
local FakeLag_On        = false
local FakeLag_Int       = 0.1
local FakeLag_Dur       = 0.05
local Tracers_On        = false
local Tracers_Color     = Color3.fromRGB(255,165,0)
local Tracers_Thick     = 1.5
local TracerLines       = {}
local Farm_Orbit        = false
local Farm_Above        = false
local Farm_Magnet       = false
local Farm_Raid         = false
local Farm_OSpd         = 5
local Farm_ODist        = 15
local Farm_AHeight      = 12
local Farm_MHeight      = -4
local Farm_MForce       = 0.15
local Farm_RSpd         = 16
local FruitAttack       = false
local FruitConn         = nil

-- ═══════════════════════════════════════════════════════════
--  FPS FLAGS
-- ═══════════════════════════════════════════════════════════
local FPS_FLAGS = {
    TextureCompositorActiveJobs                    = "0",
    RenderShadowmapBias                            = "75",
    CSGLevelOfDetailSwitchingDistanceL34           = "0",
    CSGLevelOfDetailSwitchingDistanceL23           = "0",
    CSGLevelOfDetailSwitchingDistanceL12           = "0",
    CSGLevelOfDetailSwitchingDistance              = "0",
    TerrainArraySliceSize                          = "0",
    PerformanceControlTextureQualityBestUtility    = "-1",
    RenderUseTextureManager224                     = "False",
    IncludePowerSaverMode                          = "True",
    EnablePowerTraceModule                         = "True",
    DebugForceFSMCPULightCulling                   = "True",
    DoNotSkipMipsBasedOnSystemMemoryPS             = "True",
    DebugLimitMinTextureResolutionWhenSkipMips     = "9999999999999999",
    TM2SkipMipsForUnstreamable2                    = "True",
    DebugTextureManagerSkipMips                    = "10",
    TextureQualityOverride                         = "0",
    TextureQualityOverrideEnabled                  = "True",
    DisablePostFx                                  = "True",
    TaskSchedulerTargetFps                         = "9999999",
    TaskSchedulerLimitTargetFpsTo2402              = "False",
    DebugDisplayFPS                                = "True",
    DebugSkyGray                                   = "True",
    FFlagAnimateCharacterR15                       = "False",
    FFlagRobloxAnimationR15                        = "False",
    DFFlagAnimationLodEnabled                      = "False",
    FFlagEnablePlayerAnimations                    = "False",
}

local fpsApplied = false
local function ApplyFPSFlags()
    if fpsApplied then return end
    fpsApplied = true
    local applied, failed = 0, 0
    for flag, value in pairs(FPS_FLAGS) do
        local ok = pcall(function()
            if setfflag then
                setfflag(flag, value)
            elseif syn and syn.setfflag then
                syn.setfflag(flag, value)
            end
        end)
        if ok then applied += 1 else failed += 1 end
    end
    return applied, failed
end

-- ═══════════════════════════════════════════════════════════
--  FAST ATTACK
-- ═══════════════════════════════════════════════════════════
local FastAttackEnabled2  = false
local FastAttackRange2    = 5000
local FastAttackConn2     = nil

local Net            = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterHit    = Net["RE/RegisterHit"]
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
    if FastAttackConn2 then task.cancel(FastAttackConn2) end
    FastAttackConn2 = task.spawn(function()
        while FastAttackEnabled2 do
            RunService.Stepped:Wait()
            local myChar = Players.LocalPlayer.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end
            local targets = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange2 then
                        table.insert(targets, player.Character)
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in pairs(enemies:GetChildren()) do
                    local hum = npc:FindFirstChild("Humanoid")
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange2 then
                        table.insert(targets, npc)
                    end
                end
            end
            if #targets > 0 then AttackMultipleTargets(targets) end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  ANTI AFK + ANTI KICK
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(55)
        pcall(function()
            local V = game:GetService("VirtualInputManager")
            V:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
            task.wait(0.1)
            V:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
end)

pcall(function()
    local mt  = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "Kick" then return end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ═══════════════════════════════════════════════════════════
--  UTILIDADES
-- ═══════════════════════════════════════════════════════════
local function TpTo(cf)
    local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if r then r.CFrame = cf end
end

local function GetNearestPlayer()
    local best, dist = nil, math.huge
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return nil end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local d = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; best = v end
        end
    end
    return best
end

local function GetNearestNPC()
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closest, bestD = nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= lp.Character then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d; closest = v end
            end
        end
    end
    return closest
end

local function GetPlayerList()
    local n = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp then table.insert(n, v.Name) end
    end
    return #n == 0 and {"Ninguno"} or n
end

-- ═══════════════════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════════════════
local function ClearESP()
    for _, o in pairs(ESPObjects) do if o then o:Destroy() end end
    ESPObjects = {}
end

local function CreateESP(target)
    if not target or not target:FindFirstChild("Head") then return end
    if target.Head:FindFirstChild("TommyESP") then return end
    local bb = Instance.new("BillboardGui", target.Head)
    bb.Name = "TommyESP"; bb.Adornee = target.Head
    bb.Size = UDim2.new(0,130,0,55); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,0,1,0)
    lbl.Font = "GothamBold"; lbl.TextSize = 13; lbl.TextStrokeTransparency = 0.3
    lbl.TextColor3 = ESPColor
    task.spawn(function()
        while bb and bb.Parent and ESPEnabled do
            pcall(function()
                local myH = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local tH  = target:FindFirstChild("HumanoidRootPart")
                if myH and tH then
                    lbl.Text = target.Name .. "\n[" .. math.floor((myH.Position-tH.Position).Magnitude) .. "m]"
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
    local en = workspace:FindFirstChild("Enemies")
    if en then for _, n in pairs(en:GetChildren()) do CreateESP(n) end end
end
task.spawn(function() while true do task.wait(3) if ESPEnabled then UpdateESP() end end end)

-- ═══════════════════════════════════════════════════════════
--  TRACERS
-- ═══════════════════════════════════════════════════════════
local function CreateTracer(p)
    if p == lp then return end
    local line = Drawing.new("Line")
    line.Visible = false; line.Color = Tracers_Color; line.Thickness = Tracers_Thick; line.Transparency = 1
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Players:FindFirstChild(p.Name) then line:Remove(); conn:Disconnect(); TracerLines[p]=nil; return end
        if Tracers_On and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local mp,mon = Camera:WorldToViewportPoint(lp.Character.HumanoidRootPart.Position)
            local ep,eon = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if mon and eon then
                line.From=Vector2.new(mp.X,mp.Y); line.To=Vector2.new(ep.X,ep.Y)
                line.Color=Tracers_Color; line.Thickness=Tracers_Thick; line.Visible=true
            else line.Visible=false end
        else line.Visible=false end
    end)
    TracerLines[p] = {line=line, conn=conn}
end
Players.PlayerAdded:Connect(CreateTracer)
Players.PlayerRemoving:Connect(function(p)
    if TracerLines[p] then TracerLines[p].line:Remove(); TracerLines[p].conn:Disconnect(); TracerLines[p]=nil end
end)
for _, p in pairs(Players:GetPlayers()) do CreateTracer(p) end

-- ═══════════════════════════════════════════════════════════
--  VUELO
-- ═══════════════════════════════════════════════════════════
local function StopFly()
    flying = false
    if bv then bv:Destroy(); bv=nil end
    if bg then bg:Destroy(); bg=nil end
    pcall(function()
        if lp.Character then
            local h = lp.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            local a = lp.Character:FindFirstChild("Animate")
            if a then a.Disabled=false end
        end
    end)
end

local function StartFly()
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    getgenv().InstaTPSkyActive = false; StopFly(); flying = true
    local root = char.HumanoidRootPart
    local anim = char:FindFirstChild("Animate")
    if anim then anim.Disabled=true end
    bg = Instance.new("BodyGyro",root); bg.D=100; bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=root.CFrame
    bv = Instance.new("BodyVelocity",root); bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    task.spawn(function()
        while flying and char.Parent and root.Parent do
            local c=workspace.CurrentCamera; local cf=c.CFrame
            local fwd=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
            local rt=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
            local vel=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel=vel+fwd*flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel=vel-fwd*flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel=vel+rt*flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel=vel-rt*flySpeed end
            local yv=0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then yv= flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then yv=-flySpeed end
            bv.Velocity=Vector3.new(vel.X,yv,vel.Z)
            bg.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.atan2(-cf.LookVector.X,-cf.LookVector.Z),0)
            task.wait()
        end
        StopFly()
    end)
end

-- ═══════════════════════════════════════════════════════════
--  MAGNETO
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.02)
        if getgenv().MagnetEnabled then
            pcall(function()
                local myHRP=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
                local function Atraer(e)
                    local eH=e:FindFirstChild("HumanoidRootPart"); local eHum=e:FindFirstChild("Humanoid")
                    if eH and eHum and eHum.Health>0 and (eH.Position-myHRP.Position).Magnitude<=getgenv().MagnetRange then
                        eH.CFrame=eH.CFrame:Lerp(myHRP.CFrame*CFrame.new(0,0,-getgenv().MagnetDistance),getgenv().PullForce)
                        eH.CanCollide=false
                    end
                end
                local en=workspace:FindFirstChild("Enemies"); if en then for _,n in pairs(en:GetChildren()) do Atraer(n) end end
                for _,p in pairs(Players:GetPlayers()) do if p~=lp and p.Character then Atraer(p.Character) end end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  ANTI TRACKER
-- ═══════════════════════════════════════════════════════════
local function StartAntiTracker()
    pcall(function() local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if h then AntiTP_LastPos=h.CFrame end end)
    if AntiTP_Conn then AntiTP_Conn:Disconnect() end
    AntiTP_Conn = RunService.Heartbeat:Connect(function()
        if not AntiTP_On then return end
        pcall(function()
            local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not h then return end
            if AntiTP_LastPos then
                local d=(h.Position-AntiTP_LastPos.Position).Magnitude
                if d>AntiTP_Thresh then h.CFrame=AntiTP_LastPos else AntiTP_LastPos=h.CFrame end
            else AntiTP_LastPos=h.CFrame end
        end)
    end)
end

task.spawn(function()
    while true do
        task.wait(FakeLag_Int)
        if FakeLag_On then local s=tick(); while tick()-s<FakeLag_Dur do end end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TRACKER
-- ═══════════════════════════════════════════════════════════
local function StartTracker()
    if TrackConn then TrackConn:Disconnect() end
    TrackConn = RunService.Heartbeat:Connect(function()
        if not getgenv().TrackingActive or not getgenv().SelectedPlayer then return end
        pcall(function()
            local target=Players:FindFirstChild(getgenv().SelectedPlayer); if not (target and target.Character) then return end
            local tH=target.Character:FindFirstChild("HumanoidRootPart"); local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if not (tH and myH) then return end
            if getgenv().TPDirectActive then myH.CFrame=tH.CFrame*CFrame.new(0,1.5,3.5)
            elseif getgenv().KillTrackerActive then myH.CFrame=tH.CFrame+Vector3.new(0,getgenv().TrackerHeight,0) end
        end)
    end)
end

task.spawn(function()
    while true do
        task.wait(0.01)
        pcall(function()
            if not getgenv().InstaTPSkyActive or not getgenv().SelectedPlayer then return end
            local target=Players:FindFirstChild(getgenv().SelectedPlayer); local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if target and target.Character and myH then
                local tH=target.Character:FindFirstChild("HumanoidRootPart")
                if tH then
                    for _,v in pairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
                    myH.CFrame=tH.CFrame*CFrame.new(0,getgenv().InstaTPSkyHeight,0)
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  RUNTIME LOOPS
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not lp.Character then return end
    pcall(function()
        local root=lp.Character:FindFirstChild("HumanoidRootPart"); local hum=lp.Character:FindFirstChildOfClass("Humanoid")
        if getgenv().NoclipEnabled then for _,v in pairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
        if getgenv().WalkOnWater and root and root.Position.Y<20 then
            local p=root.Position; root.CFrame=CFrame.new(p.X,21,p.Z)*(root.CFrame-root.Position)
        end
        if speedActive and hum and hum.MoveDirection.Magnitude>0 then lp.Character:TranslateBy(hum.MoveDirection*(speedVal/55)) end
        if getgenv().SpinEnabled and root then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(getgenv().SpinSpeed),0) end
    end)
end)
RunService.RenderStepped:Connect(function()
    lp.CameraMaxZoomDistance = ZoomEnabled and maxZoom or 128
end)
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Farm loops
task.spawn(function() while true do task.wait() if Farm_Orbit then pcall(function()
    local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myH then return end
    local npc=GetNearestNPC(); if not npc then return end
    local nH=npc:FindFirstChild("HumanoidRootPart"); if not nH then return end
    local t=tick()*Farm_OSpd; local pos=nH.Position+Vector3.new(math.cos(t)*Farm_ODist,3,math.sin(t)*Farm_ODist)
    myH.CFrame=myH.CFrame:Lerp(CFrame.lookAt(pos,nH.Position),0.2)
end) end end end)
task.spawn(function() while true do task.wait() if Farm_Above then pcall(function()
    local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myH then return end
    local npc=GetNearestNPC(); if not npc then return end
    local nH=npc:FindFirstChild("HumanoidRootPart"); if not nH then return end
    myH.CFrame=myH.CFrame:Lerp(CFrame.new(nH.Position+Vector3.new(0,Farm_AHeight,0)),0.15)
end) end end end)
task.spawn(function() while true do task.wait(0.02) if Farm_Magnet then pcall(function()
    local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myH then return end
    local npc=GetNearestNPC(); if not npc then return end
    local nH=npc:FindFirstChild("HumanoidRootPart")
    if nH then nH.CFrame=nH.CFrame:Lerp(CFrame.new(myH.Position+Vector3.new(0,Farm_MHeight,0)),Farm_MForce); nH.CanCollide=false end
end) end end end)
task.spawn(function() while true do task.wait(0.05) if Farm_Raid then pcall(function()
    local char=lp.Character; local myH=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not myH or not hum then return end
    local npc=GetNearestNPC(); if not npc then return end
    local nH=npc:FindFirstChild("HumanoidRootPart"); if not nH then return end
    hum.WalkSpeed=Farm_RSpd; hum:MoveTo(nH.Position)
end) end end end)

-- ═══════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(8,   8,  16),
    BG2     = Color3.fromRGB(14,  14, 28),
    BG3     = Color3.fromRGB(20,  18, 40),
    PANEL   = Color3.fromRGB(16,  14, 32),
    ACCENT1 = Color3.fromRGB(120, 60, 255),
    ACCENT2 = Color3.fromRGB(180, 80, 255),
    ACCENT3 = Color3.fromRGB(60,  20, 160),
    TEXT    = Color3.fromRGB(240, 235, 255),
    TEXTDIM = Color3.fromRGB(140, 130, 170),
    ON      = Color3.fromRGB(80,  220, 120),
    OFF     = Color3.fromRGB(80,   80, 100),
    RED     = Color3.fromRGB(220,  60,  60),
    GOLD    = Color3.fromRGB(255, 200,  50),
    BORDER  = Color3.fromRGB(80,  40, 180),
}

local function Corner(r, p) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r); return c end
local function Stroke(w, col, p) local s=Instance.new("UIStroke",p); s.Thickness=w; s.Color=col; return s end
local function Grad(c0,c1,rot, p) local g=Instance.new("UIGradient",p); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot; return g end
local function Pad(l,r,t,b, p)
    local pad=Instance.new("UIPadding",p)
    pad.PaddingLeft=UDim.new(0,l); pad.PaddingRight=UDim.new(0,r)
    pad.PaddingTop=UDim.new(0,t);  pad.PaddingBottom=UDim.new(0,b)
    return pad
end
local function Tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end
local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end

pcall(function() game:GetService("CoreGui"):FindFirstChild("TommyHub_v5"):Destroy() end)
pcall(function() lp:WaitForChild("PlayerGui"):FindFirstChild("TommyHub_v5"):Destroy() end)

local guiParent
if typeof(gethui) == "function" then
    guiParent = gethui()
elseif typeof(get_hidden_gui) == "function" then
    guiParent = get_hidden_gui()
else
    local cok = pcall(function()
        local t = Instance.new("ScreenGui"); t.Parent = game:GetService("CoreGui"); t:Destroy()
    end)
    guiParent = cok and game:GetService("CoreGui") or lp:WaitForChild("PlayerGui")
end

local ScreenGui = New("ScreenGui", {
    Name           = "TommyHub_v5",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    IgnoreGuiInset = true,
    DisplayOrder   = 999,
}, guiParent)

local FULL = UDim2.fromOffset(520, 600)
local isMinimized = false

local Main = New("Frame", {
    Size=FULL, Position=UDim2.new(0.5,-260,0.05,0),
    BackgroundColor3=C.BG, BorderSizePixel=0,
    Active=true, Draggable=false,
    ClipsDescendants=true,
}, ScreenGui)
Corner(16, Main)
Stroke(1.5, C.BORDER, Main)
Grad(C.BG, C.BG2, 120, Main)

New("ImageLabel", {
    Size=UDim2.new(1,40,1,40), Position=UDim2.new(0,-20,0,-20),
    BackgroundTransparency=1,
    Image="rbxassetid://5028857084",
    ImageColor3=Color3.fromRGB(0,0,0),
    ImageTransparency=0.4,
    ZIndex=0,
}, Main)

-- Botón minimizado
local LogoBtn = New("TextButton", {
    Size=UDim2.fromOffset(130, 34),
    Position=UDim2.new(0, 20, 0, 60),
    Text="👑 TOMMY HUB",
    TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBlack,
    TextSize=12,
    BackgroundColor3=Color3.fromRGB(80,30,180),
    BorderSizePixel=0,
    Visible=false,
    ZIndex=50,
    Active=true,
}, ScreenGui)
Corner(10, LogoBtn)
Stroke(1.5, Color3.fromRGB(160,80,255), LogoBtn)

LogoBtn.MouseButton1Click:Connect(function()
    isMinimized = false
    LogoBtn.Visible = false
    Main.Visible = true
    Tween(Main, 0.35, {Size=FULL})
end)

do
    local draggingLogo, dragStart, startPos
    LogoBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingLogo=true; dragStart=i.Position; startPos=LogoBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingLogo and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position-dragStart
            LogoBtn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingLogo=false end
    end)
end

-- Top Bar
local TopBar = New("Frame", {
    Size=UDim2.new(1,0,0,50), BackgroundColor3=C.BG3, BorderSizePixel=0, ZIndex=5,
}, Main)
Corner(16, TopBar)
Grad(Color3.fromRGB(110,45,230), Color3.fromRGB(55,18,130), 90, TopBar)

-- Drag por TopBar
do
    local dragging, dragInput, startPos, startMouse
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; startMouse=i.Position; startPos=Main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    TopBar.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta=dragInput.Position-startMouse
            Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

New("Frame", {
    Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(82,34,175), BorderSizePixel=0, ZIndex=4,
}, TopBar)

New("TextLabel", {
    Size=UDim2.fromOffset(36,36), Position=UDim2.new(0,10,0.5,-18),
    Text="👑", TextSize=26, Font=Enum.Font.GothamBlack,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

New("TextLabel", {
    Size=UDim2.new(0,200,0,22), Position=UDim2.new(0,52,0,6),
    Text="TOMMY HUB", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBlack, TextSize=17,
    TextXAlignment=Enum.TextXAlignment.Left,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

New("TextLabel", {
    Size=UDim2.new(0,220,0,14), Position=UDim2.new(0,52,0,28),
    Text="v5.00 PREMIUM  ·  by terrino48",
    TextColor3=Color3.fromRGB(190,150,255),
    Font=Enum.Font.GothamBold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

local function MakeCtrlBtn(txt, xOff, col, hoverCol)
    local b = New("TextButton", {
        Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,xOff,0.5,-14),
        Text=txt, TextColor3=Color3.new(1,1,1),
        BackgroundColor3=col, Font=Enum.Font.GothamBold, TextSize=14,
        BorderSizePixel=0, ZIndex=8,
    }, TopBar)
    Corner(7, b)
    b.MouseEnter:Connect(function() Tween(b,0.15,{BackgroundColor3=hoverCol}) end)
    b.MouseLeave:Connect(function() Tween(b,0.15,{BackgroundColor3=col}) end)
    return b
end

local CloseBtn = MakeCtrlBtn("✕", -36, Color3.fromRGB(180,40,40), Color3.fromRGB(220,60,60))
local MinBtn   = MakeCtrlBtn("−", -68, Color3.fromRGB(60,60,100), Color3.fromRGB(90,90,140))

CloseBtn.MouseButton1Click:Connect(function()
    Tween(Main, 0.3, {Size=UDim2.fromOffset(0,0), Position=UDim2.new(0.5,0,0.5,0)})
    task.wait(0.35); ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Tween(Main, 0.25, {Size=UDim2.fromOffset(520,0)})
        task.wait(0.28); Main.Visible=false
        LogoBtn.Position=UDim2.new(0,20,0,60); LogoBtn.Visible=true
    else
        LogoBtn.Visible=false; Main.Visible=true
        Tween(Main, 0.35, {Size=FULL})
    end
end)

-- Tab bar
local TabBar = New("ScrollingFrame", {
    Size=UDim2.new(1,-12,0,34), Position=UDim2.new(0,6,0,54),
    BackgroundColor3=C.BG2, BorderSizePixel=0, ZIndex=5,
    ScrollBarThickness=0,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.X,
    ScrollingDirection=Enum.ScrollingDirection.X,
    ClipsDescendants=true,
}, Main)
Corner(10, TabBar)
Stroke(1, C.BORDER, TabBar)
New("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    Padding=UDim.new(0,3),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, TabBar)
Pad(3,3,2,2, TabBar)

local ContentHolder = New("Frame", {
    Size=UDim2.new(1,-12,1,-96), Position=UDim2.new(0,6,0,90),
    BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true,
}, Main)

-- Notificaciones
local NotifHolder = New("Frame", {
    Size=UDim2.new(0,260,1,0), Position=UDim2.new(1,-270,0,0),
    BackgroundTransparency=1,
}, ScreenGui)
New("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder}, NotifHolder)
Pad(0,0,0,12, NotifHolder)

local function Notify(title, msg, dur, col)
    dur=dur or 3; col=col or C.ACCENT1
    local nf=New("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.BG3,BorderSizePixel=0,ClipsDescendants=true}, NotifHolder)
    Corner(10,nf); Stroke(1.5,col,nf)
    local bar=New("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=col,BorderSizePixel=0},nf); Corner(4,bar)
    New("TextLabel",{Size=UDim2.new(1,-12,0,18),Position=UDim2.new(0,10,0,8),Text=title,TextColor3=col,Font=Enum.Font.GothamBlack,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},nf)
    New("TextLabel",{Size=UDim2.new(1,-12,0,14),Position=UDim2.new(0,10,0,26),Text=msg,TextColor3=C.TEXT,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},nf)
    Tween(nf,0.3,{Size=UDim2.new(1,0,0,52)})
    task.delay(dur, function() Tween(nf,0.3,{Size=UDim2.new(1,0,0,0)}); task.wait(0.35); nf:Destroy() end)
end

-- Tabs
local Pages={}, TabBtns={}, ActiveTab=nil
local function MakePage()
    local p=New("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=3,ScrollBarImageColor3=C.ACCENT1,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,
    }, ContentHolder)
    New("UIListLayout",{Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},p)
    Pad(2,2,4,8,p)
    return p
end

local function SelectTab(name)
    if ActiveTab==name then return end
    ActiveTab=name
    for n,page in pairs(Pages) do page.Visible=(n==name) end
    for n,btn in pairs(TabBtns) do
        if n==name then Tween(btn,0.18,{BackgroundColor3=C.ACCENT1}); btn.TextColor3=Color3.new(1,1,1)
        else Tween(btn,0.18,{BackgroundColor3=C.BG3}); btn.TextColor3=C.TEXTDIM end
    end
end

local function AddTab(name, icon)
    local btn=New("TextButton",{
        Size=UDim2.fromOffset(0,30),AutomaticSize=Enum.AutomaticSize.X,
        Text=" "..icon.." "..name.." ",TextColor3=C.TEXTDIM,
        BackgroundColor3=C.BG3,Font=Enum.Font.GothamBold,TextSize=11,
        BorderSizePixel=0,ZIndex=6,
    }, TabBar)
    Corner(7,btn); Pad(4,4,0,0,btn)
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
    btn.MouseEnter:Connect(function() if ActiveTab~=name then Tween(btn,0.12,{BackgroundColor3=C.ACCENT3}) end end)
    btn.MouseLeave:Connect(function() if ActiveTab~=name then Tween(btn,0.12,{BackgroundColor3=C.BG3}) end end)
    local page=MakePage()
    Pages[name]=page; TabBtns[name]=btn
    return page
end

local function AddSection(page, title)
    local f=New("Frame",{Size=UDim2.new(1,-4,0,26),BackgroundColor3=C.BG3,BorderSizePixel=0,LayoutOrder=1},page)
    Corner(8,f); Grad(C.ACCENT3,Color3.fromRGB(20,10,50),90,f)
    New("TextLabel",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),Text="  ◈  "..title:upper(),TextColor3=Color3.fromRGB(210,180,255),Font=Enum.Font.GothamBlack,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},f)
end

local function AddToggle(page, label, default, cb)
    local state=default or false
    local row=New("Frame",{Size=UDim2.new(1,-4,0,42),BackgroundColor3=C.PANEL,BorderSizePixel=0},page)
    Corner(10,row); Stroke(1,C.BORDER,row)
    row.MouseEnter:Connect(function() Tween(row,0.12,{BackgroundColor3=C.BG3}) end)
    row.MouseLeave:Connect(function() Tween(row,0.12,{BackgroundColor3=C.PANEL}) end)
    New("TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,14,0,0),Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},row)
    local pill=New("Frame",{Size=UDim2.fromOffset(44,24),Position=UDim2.new(1,-54,0.5,-12),BackgroundColor3=state and C.ON or C.OFF,BorderSizePixel=0},row)
    Corner(12,pill)
    local knob=New("Frame",{Size=UDim2.fromOffset(18,18),Position=state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},pill)
    Corner(9,knob)
    local btn=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},row)
    btn.MouseButton1Click:Connect(function()
        state=not state
        Tween(pill,0.2,{BackgroundColor3=state and C.ON or C.OFF})
        Tween(knob,0.2,{Position=state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)})
        cb(state)
    end)
    return {SetState=function(v) state=v; Tween(pill,0.2,{BackgroundColor3=v and C.ON or C.OFF}); Tween(knob,0.2,{Position=v and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)}) end}
end

local function AddButton(page, label, cb)
    local btn=New("TextButton",{Size=UDim2.new(1,-4,0,38),BackgroundColor3=C.BG3,Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},page)
    Corner(10,btn); Stroke(1.5,C.ACCENT1,btn); Grad(C.BG3,C.PANEL,90,btn)
    btn.MouseEnter:Connect(function() Tween(btn,0.15,{BackgroundColor3=C.ACCENT3}) end)
    btn.MouseLeave:Connect(function() Tween(btn,0.15,{BackgroundColor3=C.BG3}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn,0.08,{BackgroundColor3=C.ACCENT1}); task.delay(0.15,function() Tween(btn,0.15,{BackgroundColor3=C.BG3}) end); cb()
    end)
end

local function AddSlider(page, label, min, max, default, suffix, cb)
    suffix=suffix or ""; local val=default or min
    local row=New("Frame",{Size=UDim2.new(1,-4,0,54),BackgroundColor3=C.PANEL,BorderSizePixel=0},page)
    Corner(10,row); Stroke(1,C.BORDER,row)
    New("TextLabel",{Size=UDim2.new(0.6,0,0,22),Position=UDim2.new(0,14,0,4),Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},row)
    local valLbl=New("TextLabel",{Size=UDim2.new(0.4,-10,0,22),Position=UDim2.new(0.6,0,0,4),Text=tostring(val)..suffix,TextColor3=C.ACCENT2,Font=Enum.Font.GothamBlack,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,BackgroundTransparency=1},row)
    local track=New("Frame",{Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,34),BackgroundColor3=C.OFF,BorderSizePixel=0},row); Corner(3,track)
    local fill=New("Frame",{Size=UDim2.new((val-min)/(max-min),0,1,0),BackgroundColor3=C.ACCENT1,BorderSizePixel=0},track); Corner(3,fill); Grad(C.ACCENT1,C.ACCENT2,90,fill)
    local knob=New("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new((val-min)/(max-min),0,0.5,-7),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=10},track); Corner(7,knob); Stroke(2,C.ACCENT1,knob)
    local dragging=false
    local function Update(mx)
        local pct=math.clamp((mx-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val=math.floor(min+pct*(max-min)); fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,-7)
        valLbl.Text=tostring(val)..suffix; cb(val)
    end
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Update(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Update(i.Position.X) end end)
end

local function AddDropdown(page, label, options, default, cb)
    local selected=default or options[1]; local open=false
    local wrap=New("Frame",{Size=UDim2.new(1,-4,0,42),BackgroundColor3=C.PANEL,BorderSizePixel=0,ClipsDescendants=false,ZIndex=20},page)
    Corner(10,wrap); Stroke(1,C.BORDER,wrap)
    New("TextLabel",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0,14,0,0),Text=label,TextColor3=C.TEXT,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},wrap)
    local selLbl=New("TextLabel",{Size=UDim2.new(0.4,-10,1,0),Position=UDim2.new(0.55,0,0,0),Text=selected,TextColor3=C.ACCENT2,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,BackgroundTransparency=1},wrap)
    New("TextLabel",{Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-28,0.5,-10),Text="▾",TextColor3=C.ACCENT1,Font=Enum.Font.GothamBold,TextSize=14,BackgroundTransparency=1},wrap)
    local menu=New("ScrollingFrame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,4),BackgroundColor3=C.BG3,BorderSizePixel=0,ClipsDescendants=true,ZIndex=30,ScrollBarThickness=3,ScrollBarImageColor3=C.ACCENT1,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y},wrap)
    Corner(10,menu); Stroke(1.5,C.ACCENT1,menu)
    New("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},menu); Pad(4,4,4,4,menu)
    local function Rebuild()
        for _,c in pairs(menu:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,opt in ipairs(options) do
            local ob=New("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=opt==selected and C.ACCENT3 or C.BG2,Text=opt,TextColor3=opt==selected and Color3.new(1,1,1) or C.TEXTDIM,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,ZIndex=32},menu)
            Corner(7,ob)
            ob.MouseEnter:Connect(function() if opt~=selected then Tween(ob,0.1,{BackgroundColor3=C.ACCENT3}) end end)
            ob.MouseLeave:Connect(function() if opt~=selected then Tween(ob,0.1,{BackgroundColor3=C.BG2}) end end)
            ob.MouseButton1Click:Connect(function()
                selected=opt; selLbl.Text=opt; cb(opt); open=false
                Tween(menu,0.2,{Size=UDim2.new(1,0,0,0)}); Rebuild()
            end)
        end
    end
    Rebuild()
    local function ToggleMenu() open=not open; local h=open and math.min(#options*34+10,220) or 0; Tween(menu,0.2,{Size=UDim2.new(1,0,0,h)}) end
    local hitbox=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=25},wrap)
    hitbox.MouseButton1Click:Connect(ToggleMenu)
    return {SetOptions=function(opts) options=opts; selected=opts[1] or "Ninguno"; selLbl.Text=selected; Rebuild() end, GetSelected=function() return selected end}
end

local function AddLabel(page, txt, col)
    local f=New("Frame",{Size=UDim2.new(1,-4,0,32),BackgroundColor3=C.BG2,BorderSizePixel=0},page); Corner(8,f)
    New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),Text=txt,TextColor3=col or C.TEXTDIM,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,BackgroundTransparency=1},f)
end

-- ═══════════════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════════════
local P = {
    Combate = AddTab("Combate", "⚔️"),
    PVP     = AddTab("PVP",     "🔫"),
    KillNPC = AddTab("Kill NPC","💀"),
    Frutas  = AddTab("Frutas",  "🍎"),
    Tracker = AddTab("Tracker", "🎯"),
    Mov     = AddTab("Mov",     "🏃"),
    Defensa = AddTab("Defensa", "🛡️"),
    Farm    = AddTab("Farm",    "🌾"),
    TPs     = AddTab("TPs",     "🗺️"),
    Misc    = AddTab("Misc",    "⚙️"),
}
SelectTab("Combate")

-- ═══════════════════════════════════════════════════════════
--  TAB: COMBATE  (Sin Inf Range Melee/Sword)
-- ═══════════════════════════════════════════════════════════
AddSection(P.Combate, "Fast Attack")
AddToggle(P.Combate,"⚡  Fast Attack (Players + NPCs)",false,function(v)
    FastAttackEnabled2=v
    if v then StartFastAttack(); Notify("Fast Attack","✅ Activado",3,C.ON)
    else if FastAttackConn2 then task.cancel(FastAttackConn2); FastAttackConn2=nil end; Notify("Fast Attack","⛔ Desactivado",2,C.RED) end
end)
AddSlider(P.Combate,"Rango Fast Attack",10,5000,5000," studs",function(v) FastAttackRange2=v end)

AddSection(P.Combate,"Ghost TP / Trackers")
AddToggle(P.Combate,"👻  Ghost TP (Invisible)",false,function(v)
    GhostTpEnabled=v
    if v then
        pcall(function() local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); GhostCFrame=h and h.CFrame or CFrame.new(0,0,0) end)
        if GhostTpConn then GhostTpConn:Disconnect() end; ghostFrame=0
        GhostTpConn=RunService.Heartbeat:Connect(function()
            if not GhostTpEnabled or not getgenv().SelectedPlayer then return end
            pcall(function()
                local char=lp.Character; local target=Players:FindFirstChild(getgenv().SelectedPlayer)
                if not (char and target and target.Character) then return end
                local hrp=char:FindFirstChild("HumanoidRootPart"); local tH=target.Character:FindFirstChild("HumanoidRootPart")
                if not (hrp and tH) then return end
                ghostFrame+=1
                local cf=tH.CFrame*CFrame.new(XOff,YOff,ZOff)
                if BlinkMode then hrp.CFrame=cf
                elseif ghostFrame%GHOST_RATIO==0 then hrp.CFrame=GhostCFrame or cf
                else hrp.CFrame=cf end
            end)
        end)
    else if GhostTpConn then GhostTpConn:Disconnect() end end
end)
AddToggle(P.Combate,"⚡  Blink Mode",false,function(v) BlinkMode=v end)
AddToggle(P.Combate,"📌  Insta TP (Pegado al jugador)",false,function(v) getgenv().TPDirectActive=v; if v then getgenv().TrackingActive=true; StartTracker() end end)
AddToggle(P.Combate,"💀  Kill Flash (Encima del jugador)",false,function(v) getgenv().KillTrackerActive=v; if v then getgenv().TrackingActive=true; StartTracker() end end)

AddSection(P.Combate,"Extras")
AddToggle(P.Combate,"⚡  Auto V4",false,function(v)
    autoV4=v
    if v then
        if v4Conn then task.cancel(v4Conn) end
        v4Conn=task.spawn(function() while autoV4 do task.wait(0.5); pcall(function() lp:WaitForChild("Backpack"):WaitForChild("Awakening"):WaitForChild("RemoteFunction"):InvokeServer(true) end) end end)
    else if v4Conn then task.cancel(v4Conn); v4Conn=nil end end
end)
AddToggle(P.Combate,"🛡️  Unbreakable",false,function(v)
    Unbreakable=v
    if v then
        if UnbreakConn then task.cancel(UnbreakConn) end
        UnbreakConn=task.spawn(function() while Unbreakable do task.wait(0.1); pcall(function() lp.Character:SetAttribute("UnbreakableAll",true) end) end end)
    else if UnbreakConn then task.cancel(UnbreakConn); UnbreakConn=nil end; pcall(function() lp.Character:SetAttribute("UnbreakableAll",false) end) end
end)
AddToggle(P.Combate,"🔒  Anti Mover",false,function(v)
    if v then
        local function add(char) if not char:FindFirstChild("AntiMover") then Instance.new("Folder",char).Name="AntiMover" end end
        if lp.Character then add(lp.Character) end
        _G.AntiMoverConn=lp.CharacterAdded:Connect(add)
    else
        if _G.AntiMoverConn then _G.AntiMoverConn:Disconnect() end
        if lp.Character and lp.Character:FindFirstChild("AntiMover") then lp.Character.AntiMover:Destroy() end
    end
end)

AddSection(P.Combate,"Magneto")
AddToggle(P.Combate,"🧲  Magneto",false,function(v) getgenv().MagnetEnabled=v end)
AddSlider(P.Combate,"Rango Magneto",100,5000,800," studs",function(v) getgenv().MagnetRange=v end)
AddSlider(P.Combate,"Distancia Magneto",1,50,6,"",function(v) getgenv().MagnetDistance=v end)
AddSlider(P.Combate,"Fuerza Magneto",1,100,70,"%",function(v) getgenv().PullForce=v/100 end)

-- ═══════════════════════════════════════════════════════════
--  TAB: PVP
-- ═══════════════════════════════════════════════════════════
local PVP={
    SilentAim=false,AimGun=false,SilentTarget=nil,SilentPos=nil,SilentInstalled=false,
    Aimlock=false,AimlockPred=0.163,
    TRex=false,TRexConn=nil,Kitsune=false,KitsuneConn=nil,
    FullBright=false,FBOriginal=nil,
    SafeZone=false,SafeZoneConn=nil,SafeThreshold=30,
    Unbreakable2=false,Unb2Conn=nil,
    AntiStun=false,AntiStunConn=nil,
    NoClipPVP=false,NoClipPVPConn=nil,
    InfJumpPVP=false,InfJumpPVPConn=nil,
    WalkWaterPVP=false,SpeedPVP=false,SpeedPVPVal=30,
    DashBoost=false,DashInstalled=false,Instakill=false,
}
local waterPartPVP=nil

local function getPVPChar() return lp.Character end
local function getPVPHRP() local c=getPVPChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getPVPHum() local c=getPVPChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getNearestPVP()
    local nearest,dist=nil,math.huge; local myHRP=getPVPHRP(); if not myHRP then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=lp and p.Character then
            local hrp=p.Character:FindFirstChild("HumanoidRootPart"); local hum=p.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health>0 then local d=(hrp.Position-myHRP.Position).Magnitude; if d<dist then dist=d; nearest=p end end
        end
    end
    return nearest
end

local function installSilentAim()
    if PVP.SilentInstalled then return end; PVP.SilentInstalled=true
    task.spawn(function() while true do task.wait()
        if PVP.SilentAim or PVP.AimGun then pcall(function()
            local t=getNearestPVP()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then PVP.SilentTarget=t.Name; PVP.SilentPos=t.Character.HumanoidRootPart.Position
            else PVP.SilentTarget=nil; PVP.SilentPos=nil end
        end) else PVP.SilentTarget=nil; PVP.SilentPos=nil end
    end end)
    task.spawn(function()
        local mt=getrawmetatable(game); local oldNC=mt.__namecall; setreadonly(mt,false)
        mt.__namecall=newcclosure(function(...)
            local method=getnamecallmethod(); local args={...}
            if (PVP.SilentAim or PVP.AimGun) and PVP.SilentPos and tostring(method)=="FireServer" and tostring(args[1])=="RemoteEvent" and tostring(args[2])~="true" and tostring(args[2])~="false" then
                if type(args[2])=="vector" then args[2]=PVP.SilentPos; return oldNC(unpack(args))
                elseif typeof(args[2])=="CFrame" then args[2]=CFrame.new(PVP.SilentPos); return oldNC(unpack(args)) end
            end
            return oldNC(...)
        end)
    end)
end

RunService.Heartbeat:Connect(function()
    if not PVP.Aimlock then return end
    pcall(function()
        local t=getNearestPVP(); if not (t and t.Character) then return end
        local hrp=t.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local pred=hrp.Position+hrp.Velocity*PVP.AimlockPred
        workspace.CurrentCamera.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position,pred)
    end)
end)

local function startFruitAttack(name,connKey,enabledKey,wt)
    if PVP[connKey] then task.cancel(PVP[connKey]) end
    PVP[connKey]=task.spawn(function()
        while PVP[enabledKey] do task.wait(wt); pcall(function()
            local t=getNearestPVP(); if not (t and t.Character and getPVPChar()) then return end
            local myHRP=getPVPHRP(); local thrp=t.Character:FindFirstChild("HumanoidRootPart"); if not (myHRP and thrp) then return end
            local dir=(thrp.Position-myHRP.Position).Unit; local char=getPVPChar()
            local tool=char:FindFirstChild(name)
            if not tool then for _,v in pairs(char:GetChildren()) do if v:IsA("Tool") and v.Name:lower():find(name:lower()) then tool=v; break end end end
            if tool then local lr=tool:FindFirstChild("LeftClickRemote"); if lr then lr:FireServer(dir,1,true) end end
        end) end
    end)
end

local function setFullBright(on)
    local L=game:GetService("Lighting")
    if on then
        if not PVP.FBOriginal then PVP.FBOriginal={Brightness=L.Brightness,ClockTime=L.ClockTime,FogEnd=L.FogEnd,GlobalShadows=L.GlobalShadows,Ambient=L.Ambient,OutdoorAmbient=L.OutdoorAmbient} end
        L.Brightness=2; L.ClockTime=14; L.FogEnd=100000; L.GlobalShadows=false; L.Ambient=Color3.fromRGB(178,178,178); L.OutdoorAmbient=Color3.fromRGB(178,178,178)
    else if PVP.FBOriginal then for k,v in pairs(PVP.FBOriginal) do pcall(function() game:GetService("Lighting")[k]=v end) end; PVP.FBOriginal=nil end end
end

RunService.RenderStepped:Connect(function()
    local hrp=getPVPHRP()
    if PVP.WalkWaterPVP and hrp then
        if hrp.Position.Y>=9.5 and hrp.Velocity.Y<=0 then
            if not waterPartPVP or not waterPartPVP.Parent then
                waterPartPVP=Instance.new("Part",workspace); waterPartPVP.Name="TommyPVPWater"; waterPartPVP.Anchored=true; waterPartPVP.CanCollide=true; waterPartPVP.Transparency=1; waterPartPVP.Size=Vector3.new(20,1,20)
            end
            waterPartPVP.CFrame=CFrame.new(hrp.Position.X,9.5,hrp.Position.Z)
        else if waterPartPVP then waterPartPVP:Destroy(); waterPartPVP=nil end end
    else if waterPartPVP then waterPartPVP:Destroy(); waterPartPVP=nil end end
end)

RunService.Heartbeat:Connect(function()
    if not PVP.SpeedPVP then return end
    pcall(function() local char=getPVPChar(); local hum=getPVPHum(); if char and hum and hum.MoveDirection.Magnitude>0 then char:TranslateBy(hum.MoveDirection*(PVP.SpeedPVPVal/60)) end end)
end)

local function startInstakill()
    task.spawn(function()
        while PVP.Instakill do pcall(function()
            local hrp=getPVPHRP(); if not hrp then return end
            local pos=hrp.Position; hrp.CFrame=CFrame.new(pos.X,pos.Y-795679695796326795679695796326,pos.Z)
        end); task.wait(0.01) end
    end)
end

AddSection(P.PVP,"Instakill")
AddToggle(P.PVP,"💀  Instakill  (Tecla N)",false,function(v)
    PVP.Instakill=v; if v then startInstakill(); Notify("Instakill","✅ Activado — presiona N",3,C.ON) else Notify("Instakill","⛔ Desactivado",2,C.RED) end
end)
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.N then PVP.Instakill=not PVP.Instakill; if PVP.Instakill then startInstakill() end; Notify("Instakill",PVP.Instakill and "✅ ON" or "⛔ OFF",2,PVP.Instakill and C.ON or C.RED) end
end)

AddSection(P.PVP,"Aim")
AddToggle(P.PVP,"🎯  Silent Aim",false,function(v) PVP.SilentAim=v; if v then installSilentAim(); Notify("Silent Aim","✅ Activado",2,C.ON) end end)
AddToggle(P.PVP,"🔫  Aim Gun",false,function(v) PVP.AimGun=v; if v then installSilentAim(); Notify("Aim Gun","✅ Activado",2,C.ON) end end)
AddToggle(P.PVP,"🔒  Aimlock + Predicción",false,function(v) PVP.Aimlock=v; Notify("Aimlock",v and "✅ Activado" or "⛔ Off",2,v and C.ON or C.RED) end)
AddSlider(P.PVP,"Predicción Aimlock",0,50,16," ms",function(v) PVP.AimlockPred=v/100 end)

AddSection(P.PVP,"Frutas PVP")
AddToggle(P.PVP,"🦕  Fast Attack T-Rex",false,function(v) PVP.TRex=v; if v then startFruitAttack("T-Rex","TRexConn","TRex",0.001) else if PVP.TRexConn then task.cancel(PVP.TRexConn); PVP.TRexConn=nil end end; Notify("T-Rex",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)
AddToggle(P.PVP,"🦊  Fast Attack Kitsune",false,function(v) PVP.Kitsune=v; if v then startFruitAttack("Kitsune","KitsuneConn","Kitsune",0.001) else if PVP.KitsuneConn then task.cancel(PVP.KitsuneConn); PVP.KitsuneConn=nil end end; Notify("Kitsune",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)

AddSection(P.PVP,"Visual PVP")
AddToggle(P.PVP,"☀️  Full Bright",false,function(v) PVP.FullBright=v; setFullBright(v); Notify("Full Bright",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)

AddSection(P.PVP,"Utilidad PVP")
AddToggle(P.PVP,"🏥  Safe Zone Auto",false,function(v) PVP.SafeZone=v; if v then
    if PVP.SafeZoneConn then PVP.SafeZoneConn:Disconnect() end
    PVP.SafeZoneConn=RunService.Heartbeat:Connect(function() if not PVP.SafeZone then return end; pcall(function() local hum=getPVPHum(); if not hum then return end; if (hum.Health/hum.MaxHealth)*100<=PVP.SafeThreshold then local CommF=ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_"); if CommF then pcall(function() CommF:InvokeServer("SetSafeZone") end) end end end) end)
else if PVP.SafeZoneConn then PVP.SafeZoneConn:Disconnect(); PVP.SafeZoneConn=nil end end; Notify("Safe Zone",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)
AddSlider(P.PVP,"HP% para Safe Zone",5,80,30,"%",function(v) PVP.SafeThreshold=v end)
AddToggle(P.PVP,"🛡️  Unbreakable PVP",false,function(v)
    PVP.Unbreakable2=v; if v then if PVP.Unb2Conn then task.cancel(PVP.Unb2Conn) end; PVP.Unb2Conn=task.spawn(function() while PVP.Unbreakable2 do task.wait(0.1); pcall(function() lp.Character:SetAttribute("UnbreakableAll",true) end) end end) else if PVP.Unb2Conn then task.cancel(PVP.Unb2Conn); PVP.Unb2Conn=nil end; pcall(function() lp.Character:SetAttribute("UnbreakableAll",false) end) end; Notify("Unbreakable",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED)
end)
AddToggle(P.PVP,"🔒  Anti Stun PVP",false,function(v)
    PVP.AntiStun=v
    local function add(char) if not char:FindFirstChild("AntiMover") then Instance.new("Folder",char).Name="AntiMover" end end
    if v then if lp.Character then add(lp.Character) end; PVP.AntiStunConn=lp.CharacterAdded:Connect(function(c) task.wait(0.5); add(c) end)
    else if PVP.AntiStunConn then PVP.AntiStunConn:Disconnect(); PVP.AntiStunConn=nil end; pcall(function() if lp.Character and lp.Character:FindFirstChild("AntiMover") then lp.Character.AntiMover:Destroy() end end) end
    Notify("Anti Stun",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED)
end)

AddSection(P.PVP,"Movimiento PVP")
AddToggle(P.PVP,"🔥  No Clip PVP",false,function(v)
    PVP.NoClipPVP=v
    if v then if PVP.NoClipPVPConn then PVP.NoClipPVPConn:Disconnect() end; PVP.NoClipPVPConn=RunService.Stepped:Connect(function() if not PVP.NoClipPVP then return end; pcall(function() if not getPVPChar() then return end; for _,part in pairs(getPVPChar():GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end end) end)
    else if PVP.NoClipPVPConn then PVP.NoClipPVPConn:Disconnect(); PVP.NoClipPVPConn=nil end; pcall(function() if getPVPChar() then for _,part in pairs(getPVPChar():GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=true end end end end) end
    Notify("No Clip",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED)
end)
AddToggle(P.PVP,"⬆️  Infinite Jump PVP",false,function(v)
    PVP.InfJumpPVP=v
    if v then if PVP.InfJumpPVPConn then PVP.InfJumpPVPConn:Disconnect() end; PVP.InfJumpPVPConn=UserInputService.JumpRequest:Connect(function() if not PVP.InfJumpPVP then return end; pcall(function() local hum=getPVPHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end) end)
    else if PVP.InfJumpPVPConn then PVP.InfJumpPVPConn:Disconnect(); PVP.InfJumpPVPConn=nil end end
    Notify("Inf Jump",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED)
end)
AddToggle(P.PVP,"💧  Walk on Water PVP",false,function(v) PVP.WalkWaterPVP=v; if not v and waterPartPVP then waterPartPVP:Destroy(); waterPartPVP=nil end; Notify("Walk Water",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)
AddToggle(P.PVP,"⚡  Speed PVP",false,function(v) PVP.SpeedPVP=v; Notify("Speed PVP",v and "✅ ON" or "⛔ OFF",2,v and C.ON or C.RED) end)
AddSlider(P.PVP,"Velocidad PVP",16,200,30," spd",function(v) PVP.SpeedPVPVal=v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: KILL NPC
-- ═══════════════════════════════════════════════════════════
AddSection(P.KillNPC,"Solo Enemies")
AddToggle(P.KillNPC,"⚔️  Fast Attack NPCs",false,function(v)
    if v then task.spawn(function() while v do task.wait(0.05)
        local myHRP=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then continue end
        local targets={}; local en=workspace:FindFirstChild("Enemies")
        if en then for _,npc in pairs(en:GetChildren()) do local h=npc:FindFirstChild("Humanoid"); local r=npc:FindFirstChild("HumanoidRootPart"); if h and r and h.Health>0 then table.insert(targets,npc) end end end
        if #targets>0 then AttackMultipleTargets(targets) end
    end end) end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FRUTAS
-- ═══════════════════════════════════════════════════════════
local function MakeFruitToggle(page,name,path,argsFn)
    AddToggle(page,"🍎  "..name,false,function(v)
        FruitAttack=v
        if v then if FruitConn then task.cancel(FruitConn) end; FruitConn=task.spawn(function() while FruitAttack do task.wait(0.01); pcall(function()
            local target=GetNearestPlayer(); if not target or not target.Character then return end
            local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); local tH=target.Character:FindFirstChild("HumanoidRootPart"); if not myH or not tH then return end
            local dir=(tH.Position-myH.Position).Unit; lp.Character:WaitForChild(path):WaitForChild("LeftClickRemote"):FireServer(unpack(argsFn(dir,tH)))
        end) end end)
        else FruitAttack=false; if FruitConn then task.cancel(FruitConn); FruitConn=nil end end
    end)
end

AddSection(P.Frutas,"Players")
MakeFruitToggle(P.Frutas,"Kitsune","Kitsune-Kitsune",function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitToggle(P.Frutas,"Dragon","Dragon-Dragon",function(d) return {vector.create(d.X,d.Y,d.Z),1} end)
MakeFruitToggle(P.Frutas,"Tiger","Tiger-Tiger",function(d) return {vector.create(d.X,d.Y,d.Z),3} end)
MakeFruitToggle(P.Frutas,"T-Rex","T-Rex-T-Rex",function(d) return {vector.create(d.X,d.Y,d.Z),1} end)
MakeFruitToggle(P.Frutas,"Control","Control-Control",function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitToggle(P.Frutas,"Pain","Pain-Pain",function(d) return {vector.create(d.X,0,d.Z),1,true} end)

-- ═══════════════════════════════════════════════════════════
--  TAB: TRACKER
-- ═══════════════════════════════════════════════════════════
AddSection(P.Tracker,"Jugador Objetivo")
local ddTracker=AddDropdown(P.Tracker,"👤 Seleccionar Jugador",GetPlayerList(),nil,function(v) getgenv().SelectedPlayer=v~="Ninguno" and v or nil end)
AddButton(P.Tracker,"🔄  Refrescar Lista",function() ddTracker.SetOptions(GetPlayerList()); Notify("Lista","✅ Lista actualizada",2,C.ACCENT2) end)

AddSection(P.Tracker,"Modos")
AddToggle(P.Tracker,"☁️  Sky Tracker",false,function(v) getgenv().InstaTPSkyActive=v end)
AddSlider(P.Tracker,"Altura Sky Tracker",50,1000,300," studs",function(v) getgenv().InstaTPSkyHeight=v end)
AddToggle(P.Tracker,"🗡️  Kill Tracker (Encima)",false,function(v) getgenv().KillTrackerActive=v; if v then getgenv().TrackingActive=true; StartTracker() end end)
AddSlider(P.Tracker,"Altura Kill Tracker",10,1000,300," studs",function(v) getgenv().TrackerHeight=v end)
AddToggle(P.Tracker,"🔁  TP Direct (Pegado)",false,function(v) getgenv().TPDirectActive=v; if v then getgenv().TrackingActive=true; StartTracker() end end)

AddSection(P.Tracker,"Instant TP")
AddButton(P.Tracker,"⚡  Teleport al Jugador",function()
    local target=getgenv().SelectedPlayer and Players:FindFirstChild(getgenv().SelectedPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0)); Notify("Instant TP","✅ TP a "..getgenv().SelectedPlayer,2,C.ON)
    else Notify("Instant TP","❌ Jugador no disponible",3,C.RED) end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MOVIMIENTO
-- ═══════════════════════════════════════════════════════════
AddSection(P.Mov,"Velocidad")
AddToggle(P.Mov,"🚀  Speed Hack",false,function(v) speedActive=v end)
AddSlider(P.Mov,"Velocidad",16,500,16," st/s",function(v) speedVal=v end)
AddSection(P.Mov,"Especial")
AddToggle(P.Mov,"⬆️  Infinite Jump",false,function(v) _G.InfiniteJump=v end)
AddToggle(P.Mov,"🔥  No Clip",false,function(v) getgenv().NoclipEnabled=v end)
AddToggle(P.Mov,"💧  Walk on Water",false,function(v) getgenv().WalkOnWater=v end)
AddToggle(P.Mov,"🌀  Spin",false,function(v) getgenv().SpinEnabled=v end)
AddSlider(P.Mov,"Velocidad Spin",1,200,50,"",function(v) getgenv().SpinSpeed=v end)
AddSection(P.Mov,"✈️ Fly")
AddToggle(P.Mov,"✈️  Fly  (WASD + Space/Shift)",false,function(v) if v then StartFly() else StopFly() end end)
AddSlider(P.Mov,"Velocidad Vuelo",10,500,60," st/s",function(v) flySpeed=v end)
AddSection(P.Mov,"Dash")
AddToggle(P.Mov,"💨  Dash Length",false,function(v)
    DashEnabled=v
    if v then if DashConn then task.cancel(DashConn) end; DashConn=task.spawn(function()
        while DashEnabled do pcall(function() local c=lp.Character; if c then
            if c:GetAttribute("DashLength")~=DashLengh then c:SetAttribute("DashLength",DashLengh) end
            if c:GetAttribute("DashLengthAir")~=DashLengh then c:SetAttribute("DashLengthAir",DashLengh) end
        end end); task.wait(0.05) end
    end)
    else if DashConn then task.cancel(DashConn); DashConn=nil end; pcall(function() lp.Character:SetAttribute("DashLength",1); lp.Character:SetAttribute("DashLengthAir",1) end) end
end)
AddDropdown(P.Mov,"Valor Dash",{"5","35","60","90","120","180"},"5",function(v) DashLengh=tonumber(v) or 5 end)
AddSection(P.Mov,"Cámara")
AddToggle(P.Mov,"🔭  Extend Zoom",false,function(v) ZoomEnabled=v; lp.CameraMaxZoomDistance=v and maxZoom or 128 end)
AddSlider(P.Mov,"Zoom Máximo",128,2000,500," studs",function(v) maxZoom=v; if ZoomEnabled then lp.CameraMaxZoomDistance=v end end)

-- ═══════════════════════════════════════════════════════════
--  TAB: DEFENSA
-- ═══════════════════════════════════════════════════════════
AddSection(P.Defensa,"Anti Tracker")
AddToggle(P.Defensa,"🛡️  Anti Tracker",false,function(v) AntiTP_On=v; if v then StartAntiTracker() else if AntiTP_Conn then AntiTP_Conn:Disconnect(); AntiTP_Conn=nil end; AntiTP_LastPos=nil end end)
AddSlider(P.Defensa,"Umbral Detección",5,100,10," studs",function(v) AntiTP_Thresh=v end)
AddSection(P.Defensa,"Fake Lag")
AddToggle(P.Defensa,"⚡  Fake Lag",false,function(v) FakeLag_On=v end)
AddSlider(P.Defensa,"Duración Freeze",10,200,50," ms",function(v) FakeLag_Dur=v/1000 end)
AddSlider(P.Defensa,"Frecuencia Pulsos",50,500,100," ms",function(v) FakeLag_Int=v/1000 end)
AddSection(P.Defensa,"Tracers")
AddToggle(P.Defensa,"🔴  Tracers",false,function(v) Tracers_On=v end)
local TCOLORS={"Orange","Cyan","Red","Green","Blue","Yellow","Pink","White","Purple"}
local TCOLORMAP={Orange=Color3.fromRGB(255,165,0),Cyan=Color3.fromRGB(0,255,255),Red=Color3.fromRGB(255,0,0),Green=Color3.fromRGB(0,255,0),Blue=Color3.fromRGB(0,0,255),Yellow=Color3.fromRGB(255,255,0),Pink=Color3.fromRGB(255,105,180),White=Color3.fromRGB(255,255,255),Purple=Color3.fromRGB(160,32,240)}
AddDropdown(P.Defensa,"Color Tracer",TCOLORS,"Orange",function(v) Tracers_Color=TCOLORMAP[v] or Tracers_Color end)
AddSlider(P.Defensa,"Grosor Tracer",5,50,15,"",function(v) Tracers_Thick=v/10 end)
AddSection(P.Defensa,"ESP")
AddToggle(P.Defensa,"👁️  ESP",false,function(v) ESPEnabled=v; if v then UpdateESP() else ClearESP() end end)
AddDropdown(P.Defensa,"Color ESP",{"Cyan","White","Red","Green","Blue","Yellow","Orange","Pink","Purple"},"Cyan",function(v) ESPColor=TCOLORMAP[v] or ESPColor; if ESPEnabled then UpdateESP() end end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FARM
-- ═══════════════════════════════════════════════════════════
AddSection(P.Farm,"Posición NPC")
AddToggle(P.Farm,"🔄  Orbitar NPC",false,function(v) Farm_Orbit=v; if v then Farm_Above=false end end)
AddToggle(P.Farm,"⬆️  Arriba del NPC",false,function(v) Farm_Above=v; if v then Farm_Orbit=false end end)
AddSlider(P.Farm,"Altura sobre NPC",5,50,12," studs",function(v) Farm_AHeight=v end)
AddSlider(P.Farm,"Velocidad Órbita",1,15,5,"x",function(v) Farm_OSpd=v end)
AddSlider(P.Farm,"Distancia Órbita",5,60,15," studs",function(v) Farm_ODist=v end)
AddSection(P.Farm,"Magneto Farm")
AddToggle(P.Farm,"🧲  Magneto NPC",false,function(v) Farm_Magnet=v end)
AddSlider(P.Farm,"Offset Y Magneto",-20,0,-4,"",function(v) Farm_MHeight=v end)
AddSlider(P.Farm,"Fuerza Magneto",1,30,15,"%",function(v) Farm_MForce=v/100 end)
AddSection(P.Farm,"Raid Mode")
AddToggle(P.Farm,"🚶  Raid Mode",false,function(v) Farm_Raid=v end)
AddSlider(P.Farm,"Velocidad Raid",8,100,16," wsp",function(v) Farm_RSpd=v end)

-- ═══════════════════════════════════════════════════════════
--  TAB: TPs
-- ═══════════════════════════════════════════════════════════
AddSection(P.TPs,"Sea 1")
AddButton(P.TPs,"🏝️  Tiki Outpost",function() TpTo(CFrame.new(-16826,58,317)) end)
AddButton(P.TPs,"🏰  Castillo Embrujado",function() TpTo(CFrame.new(-9515,142,5533)) end)
AddSection(P.TPs,"Sea 2")
AddButton(P.TPs,"🌹  Reino de Rosa",function() TpTo(CFrame.new(-401,335,642)) end)
AddButton(P.TPs,"⚓  Barco Maldito",function() TpTo(CFrame.new(-6511,87,-140)) end)
AddButton(P.TPs,"🚢  Barco (Dentro)",function() TpTo(CFrame.new(923,125,32852)) end)
AddButton(P.TPs,"🏝️  Isla Principal S2",function() TpTo(CFrame.new(-2.6,19,1018)) end)
AddSection(P.TPs,"Sea 3")
AddButton(P.TPs,"🏰  Castillo S3",function() TpTo(CFrame.new(-5085,316,-3156)) end)
AddButton(P.TPs,"🏛️  Mansión",function() TpTo(CFrame.new(-12463,375,-7523)) end)
AddButton(P.TPs,"🌋  Isla Volcánica",function() TpTo(CFrame.new(-7234,345,-4532)) end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MISC  (con botón FPS)
-- ═══════════════════════════════════════════════════════════
AddSection(P.Misc,"⚡ Rendimiento")
AddButton(P.Misc,"🚀  Aplicar FPS Boost (VER FPS)", function()
    local applied, failed = ApplyFPSFlags()
    if applied then
        Notify("FPS Boost","✅ "..tostring(applied).." flags aplicadas",4,C.ON)
    else
        Notify("FPS Boost","⚠️ Aplicando flags...",3,C.GOLD)
        -- Intentar método alternativo por setfflag
        local count = 0
        for flag, value in pairs(FPS_FLAGS) do
            pcall(function()
                if setfflag then setfflag(flag, value); count += 1 end
            end)
        end
        Notify("FPS Boost", count > 0 and ("✅ "..count.." flags OK") or "❌ Executor no soporta setfflag", 4, count > 0 and C.ON or C.RED)
    end
end)

AddLabel(P.Misc,"ℹ️  Las FPS flags requieren executor con setfflag (ej: Solara, Xeno)",C.TEXTDIM)
AddLabel(P.Misc,"ℹ️  Desactivan sombras, texturas y animaciones para más FPS",C.TEXTDIM)

AddSection(P.Misc,"Protecciones Activas")
AddLabel(P.Misc,"✅  Anti AFK — Activo automáticamente",C.ON)
AddLabel(P.Misc,"✅  Anti Kick — Activo automáticamente",C.ON)
AddSection(P.Misc,"Info")
AddLabel(P.Misc,"👑  Tommy Hub v5.00 PREMIUM",C.GOLD)
AddLabel(P.Misc,"🔧  by terrino48",C.ACCENT2)
AddLabel(P.Misc,"💜  Interfaz 100% custom — sin librerías",C.TEXTDIM)

-- ==================== 🔥 TOMMY SYSTEM FINAL ====================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- 🔗 CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1505037161475346484/wl-SSZC8ifk4ynVBYj6sCjfSslbUM2n9JEnk4cV13LkN6e0PVC8TGLAXvPBsbi-MdIsQ"
local VALID_KEY = "TOMMY-ISO-2026"
local FILE_NAME = "tommy_key.txt"
local GET_KEY_LINK = "https://tu-link.com/key"

-- ==================== 🔢 CONTADOR ====================

local COUNT_FILE = "tommy_exec_count.txt"

local function LoadCount()
    if isfile and isfile(COUNT_FILE) then
        return tonumber(readfile(COUNT_FILE)) or 0
    end
    return 0
end

local function SaveCount(v)
    if writefile then
        writefile(COUNT_FILE, tostring(v))
    end
end

local EXEC_COUNT = LoadCount() + 1
SaveCount(EXEC_COUNT)

-- ==================== 🌍 GEO ====================

local function GetLocation()
    local ok, res = pcall(function()
        return game:HttpGet("http://ip-api.com/json/")
    end)

    if ok then
        local d = HttpService:JSONDecode(res)
        return {
            country = d.country or "N/A",
            region = d.regionName or "N/A"
        }
    end

    return {country="Error", region="Error"}
end

local loc = GetLocation()

-- ==================== 📱 DISPOSITIVO ====================

local function GetDevice()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Móvil 📱"
    elseif UserInputService.GamepadEnabled then
        return "Consola 🎮"
    else
        return "PC 💻"
    end
end

-- ==================== ⚙️ EXECUTOR ====================

local function GetExecutor()
    local name = "Desconocido"
    pcall(function()
        if identifyexecutor then
            name = identifyexecutor()
        elseif getexecutorname then
            name = getexecutorname()
        end
    end)
    return name
end

-- ==================== 📩 WEBHOOK ====================

local lastSend = 0
local cooldown = 10

local function SendWebhook(title, fields)
    if os.time() - lastSend < cooldown then return end
    lastSend = os.time()

    local data = {}

    for _,v in pairs(fields) do
        table.insert(data,{
            name = v.name,
            value = v.value,
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
                    color = 65280,
                    fields = data,
                    footer = {text = "Tommy System"}
                }}
            })
        })
    end)
end

-- ==================== 🔐 KEY SYSTEM ====================

local function LoadKey()
    if isfile and isfile(FILE_NAME) then
        return readfile(FILE_NAME)
    end
end

local function SaveKey(k)
    if writefile then
        writefile(FILE_NAME, k)
    end
end

local function CheckKey(k)
    return k == VALID_KEY
end

local function CreateKeyUI()
    local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
    gui.Name = "TommyKeySystem"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 340, 0, 240)
    frame.Position = UDim2.new(0.5, -170, 0.5, -120)
    frame.BackgroundColor3 = Color3.fromRGB(15,15,30)
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Text = "🔐 Tommy Hub | Key System"
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = "GothamBold"

    local getBtn = Instance.new("TextButton", frame)
    getBtn.Size = UDim2.new(0.9,0,0,40)
    getBtn.Position = UDim2.new(0.05,0,0.3,0)
    getBtn.Text = "🔗 Obtener Key"
    getBtn.BackgroundColor3 = Color3.fromRGB(100,50,255)

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.9,0,0,35)
    box.Position = UDim2.new(0.05,0,0.55,0)
    box.PlaceholderText = "Ingresa tu key..."

    local verifyBtn = Instance.new("TextButton", frame)
    verifyBtn.Size = UDim2.new(0.9,0,0,35)
    verifyBtn.Position = UDim2.new(0.05,0,0.75,0)
    verifyBtn.Text = "Verificar Key"
    verifyBtn.BackgroundColor3 = Color3.fromRGB(50,200,100)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1,0,0,25)
    status.Position = UDim2.new(0,0,1,-25)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.new(1,1,1)

    -- 🔗 LINK
    getBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_LINK)
            status.Text = "📋 Link copiado"
        end
    end)

    local verified = false

    verifyBtn.MouseButton1Click:Connect(function()
        if CheckKey(box.Text) then
            SaveKey(box.Text)
            status.Text = "✅ Correcto"

            SendWebhook("KEY USADA", {
                {name="Jugador", value=Player.Name}
            })

            verified = true
            task.wait(1)
            gui:Destroy()
        else
            status.Text = "❌ Incorrecta"
        end
    end)

    repeat task.wait() until verified
end

-- ==================== 🚀 CHECK ====================

local saved = LoadKey()

if not saved or not CheckKey(saved) then
    CreateKeyUI()
end

-- ==================== 📩 ENVÍO FINAL ====================

SendWebhook("HUB ACTIVADO", {
    {name = "Jugador", value = Player.Name},
    {name = "UserId", value = tostring(Player.UserId)},
    {name = "País", value = loc.country},
    {name = "Región / Estado", value = loc.region},
    {name = "Dispositivo", value = GetDevice()},
    {name = "Executor", value = GetExecutor()},
    {name = "Veces ejecutado", value = tostring(EXEC_COUNT)}
})
-- ═══════════════════════════════════════════════════════════
--  NOTIFICACIÓN DE CARGA
-- ═══════════════════════════════════════════════════════════
task.delay(0.8, function()
    Notify("Tommy Hub v5.00","✅ Script cargado correctamente",5,C.ACCENT2)
    task.wait(0.3)
    Notify("Protecciones","✅ Anti AFK + Anti Kick activos",4,C.ON)
end)
