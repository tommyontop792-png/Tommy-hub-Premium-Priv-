--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║  🇨🇴                                                                      ║
    ║     ██╗   ██╗██╗██╗   ██╗ █████╗     ██████╗ ███████╗████████╗██████╗   ║
    ║     ██║   ██║██║██║   ██║██╔══██╗    ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗  ║
    ║     ██║   ██║██║██║   ██║███████║    ██████╔╝█████╗     ██║   ██████╔╝  ║
    ║     ╚██╗ ██╔╝██║╚██╗ ██╔╝██╔══██║    ██╔═══╝ ██╔══╝     ██║   ██╔══██╗  ║
    ║      ╚████╔╝ ██║ ╚████╔╝ ██║  ██║    ██║     ███████╗   ██║   ██║  ██║  ║
    ║       ╚═══╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝    ╚═╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝  ║
    ║                                                                      🇨🇴 ║
    ║                                                                          ║
    ║              🇨🇴 VIVA PETRO - EL PODER DEL PUEBLO 🇨🇴                     ║
    ║                        VERSIÓN COMPLETA CON BOTONES                      ║
    ║                                                                          ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

-- ==================== CONFIGURACIÓN ====================
local _user = getgenv and getgenv().VivaPetroConfig or {}
local CONFIG = {
    Team = _user.Team or "Pirates",
    Weapon = _user.Weapon or "Dragon Heart",
    MinLevel = _user.MinLevel or 0,
    NoHitTimeout = _user.NoHitTimeout or 15,
    HopMinPlayers = _user.HopMinPlayers or 4,
    HopMaxPlayers = _user.HopMaxPlayers or 12,
    HopRegion = _user.HopRegion,
    HopFallbackAny = (_user.HopFallbackAny ~= nil) and _user.HopFallbackAny or true,
    MaxServerTime = _user.MaxServerTime or 0,
    Theme = _user.Theme or "Cyan",
    AbuseSlot = 3,
}

-- ==================== SERVICIOS ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local UP_SPEED = 1e35
local orbitSpeed = 500
local angle = 0

-- ==================== ESTADO ====================
local State = {
    active = false,
    enabledCielo = false,
    autoHaki = false,
    respawnAbuse = false,
    lastHitTime = os.clock(),
    lastZTime = 0,
    serverJoinTime = os.clock(),
    sessionEarned = 0,
    startBounty = 0,
    currentBounty = 0,
    kills = 0,
    status = "🇨🇴 VIVA PETRO 🇨🇴",
    factionOK = false,
}

local AbuseState = {
    active = false,
    selectedSlot = Enum.KeyCode[CONFIG.AbuseSlot == 1 and "One" or CONFIG.AbuseSlot == 2 and "Two" or "Three"],
}

-- ==================== REMOTES ====================
local CommF_, CommE_
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        CommF_ = remotes:FindFirstChild("CommF_")
        CommE_ = remotes:FindFirstChild("CommE")
    end
end)

-- ==================== UTILIDADES ====================
local function fmt(n)
    if not n then return "0" end
    n = math.floor(n)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    end
    return tostring(n)
end

local function getBounty()
    local val = 0
    pcall(function()
        local d = player:FindFirstChild("Data")
        if d then
            local b = d:FindFirstChild("Bounty") or d:FindFirstChild("Honor") or d:FindFirstChild("Rep")
            if b and type(b.Value) == "number" then val = b.Value; return end
        end
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
            if b and type(b.Value) == "number" then val = b.Value end
        end
    end)
    return val
end

local function PressKey(key)
    pcall(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        VIM:SendKeyEvent(true, key, false, hrp or game)
        task.wait(0.01)
        VIM:SendKeyEvent(false, key, false, hrp or game)
    end)
end

-- ==================== INF RANGE ABUSE ====================
local function ExecuteAbuse()
    if not AbuseState.active then return end
    
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    
    if hrp and hum and hum.Health > 0 then
        pcall(function()
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 500, 0)
            task.wait(0.05)
            PressKey(AbuseState.selectedSlot)
            task.wait(0.05)
            PressKey(Enum.KeyCode.J)
            local targetPos = CFrame.new(923.2, 1e21, 32852.8)
            hrp.Anchored = true
            hrp.CFrame = targetPos
            Workspace.CurrentCamera.CFrame = targetPos
            task.wait(0.05)
            PressKey(Enum.KeyCode.Z)
            task.spawn(function()
                task.wait(0.03)
                hum.Health = 0
            end)
            task.wait(0.5)
        end)
    end
end

local function VoidSkill()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            local oldPos = hrp.CFrame
            hrp.Anchored = true
            hrp.CFrame = CFrame.new(923.2, 1e21, 32852.8)
            Workspace.CurrentCamera.CFrame = hrp.CFrame
            task.wait(0.1)
            PressKey(Enum.KeyCode.Z)
            task.wait(0.8)
            hrp.CFrame = oldPos
            Workspace.CurrentCamera.CameraSubject = char.Humanoid
            hrp.Anchored = false
        end)
    end
end

-- ==================== AUTO BOUNTY ====================
local function getAllTargets()
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            if hum.Health > 0 then
                table.insert(targets, p.Character)
            end
        end
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:FindFirstChild(obj.Name) then
            local hum = obj.Humanoid
            if hum.Health > 0 then
                table.insert(targets, obj)
            end
        end
    end
    return targets
end

local function instaKill(target)
    pcall(function()
        local hum = target:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            hum.Health = 0
            if CommE_ then
                CommE_:FireServer("Damage", target, 999999)
            end
        end
    end)
end

-- ==================== AUTO SERVER ====================
local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
local isHopping = false
local lastHopTime = 0
local HOP_COOLDOWN = 5
local placeId = game.PlaceId
local currentJobId = game.JobId

local function Hop()
    if isHopping then return false end
    if os.clock() - lastHopTime < HOP_COOLDOWN then return false end
    
    isHopping = true
    lastHopTime = os.clock()
    task.delay(10, function() isHopping = false end)
    
    local servers = {}
    
    pcall(function()
        if browser then
            for page = 1, 10 do
                local result = browser:InvokeServer(page)
                if type(result) == "table" then
                    for uuid, info in pairs(result) do
                        if uuid ~= currentJobId and info.Count then
                            table.insert(servers, {uuid = uuid, count = info.Count or 0})
                        end
                    end
                end
                task.wait()
            end
        end
    end)
    
    if #servers == 0 then
        pcall(function()
            local response = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=50"))
            if response and response.data then
                for _, sv in ipairs(response.data) do
                    if sv.id ~= currentJobId and sv.playing then
                        table.insert(servers, {uuid = sv.id, count = sv.playing})
                    end
                end
            end
        end)
    end
    
    if #servers == 0 then return false end
    
    table.sort(servers, function(a, b) return a.count > b.count end)
    local chosen = servers[math.random(1, math.min(5, #servers))]
    
    pcall(function()
        if browser then
            browser:InvokeServer("teleport", chosen.uuid)
        end
    end)
    
    return true
end

-- ==================== FUNCIONES BASE ====================
local function equip(tooltip)
    if not tooltip then return end
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.ToolTip == tooltip or tool.Name:find(tooltip)) then
                if not hum:IsDescendantOf(tool) then
                    hum:EquipTool(tool)
                    return
                end
            end
        end
    end)
end

local function buso()
    pcall(function()
        if CommF_ then
            CommF_:InvokeServer("Buso")
        end
    end)
end

-- ==================== LOOP PRINCIPAL ====================
task.spawn(function()
    while task.wait(0.5) do
        if State.autoHaki and State.active then
            buso()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if not State.respawnAbuse or not State.active then
            task.wait()
            continue
        end
        
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            angle = angle + math.rad(orbitSpeed)
            root.CFrame = root.CFrame * CFrame.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
        end
        
        equip(CONFIG.Weapon)
        task.wait(0.1)
        
        local targets = getAllTargets()
        for _, target in ipairs(targets) do
            instaKill(target)
        end
        
        PressKey(Enum.KeyCode.Z)
        
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
        
        player.CharacterAdded:Wait()
        task.wait(0.3)
    end
end)

-- ==================== ABUSE LOOP ====================
task.spawn(function()
    while task.wait(0.2) do
        if AbuseState.active then
            ExecuteAbuse()
        end
    end
end)

-- ==================== VUELO INFINITO ====================
RunService.RenderStepped:Connect(function(dt)
    if not State.enabledCielo or not State.active then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = root.CFrame + Vector3.new(0, UP_SPEED * dt, 0)
    end
end)

-- ==================== DETECCIÓN DE BOUNTY ====================
local SAVE_FILE = "viva_petro_save.json"

local function saveData()
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode({
            sessionEarned = State.sessionEarned,
            startBounty = State.startBounty,
            kills = State.kills,
        }))
    end)
end

local function loadData()
    pcall(function()
        if isfile and isfile(SAVE_FILE) then
            local d = HttpService:JSONDecode(readfile(SAVE_FILE))
            if d then
                State.sessionEarned = d.sessionEarned or 0
                State.startBounty = d.startBounty or getBounty()
                State.kills = d.kills or 0
                return
            end
        end
        State.startBounty = getBounty()
    end)
end

pcall(function()
    if CommE_ then
        CommE_.OnClientEvent:Connect(function(event, ...)
            if not State.active then return end
            if event ~= "Notify" then return end
            local msg = select(1, ...) or ""
            if msg:find("Bounty") or msg:find("Honor") then
                local earned = tonumber(string.match(msg, ">(%d+)")) or 0
                State.sessionEarned = State.sessionEarned + earned
                State.kills = State.kills + 1
                State.lastHitTime = os.clock()
                State.currentBounty = getBounty()
                saveData()
            end
        end)
    end
end)

-- ==================== AUTO SERVER LOOP ====================
task.spawn(function()
    while task.wait(1) do
        if not State.active then continue end
        
        local sinceHit = os.clock() - State.lastHitTime
        if sinceHit >= CONFIG.NoHitTimeout then
            State.status = "🔄 HOPEANDO... 🔄"
            for i = 1, 5 do
                if Hop() then break end
                task.wait(4)
            end
            State.serverJoinTime = os.clock()
            State.lastHitTime = os.clock()
            State.status = "⚔️ VIVA PETRO ⚔️"
        end
    end
end)

-- ==================== SELECCIÓN DE FACCIÓN ====================
local function selectFaction(faction)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local activity = remotes:FindFirstChild("RE/OnEventServiceActivity")
        if activity then
            activity:FireServer("TeamSelect/Team/" .. faction)
        end
        task.wait(0.05)
        if CommF_ then
            CommF_:InvokeServer("SetTeam", faction)
        end
    end)
end

local function startAll()
    loadData()
    State.active = true
    State.enabledCielo = true
    State.autoHaki = true
    State.respawnAbuse = true
    State.lastHitTime = os.clock()
    State.currentBounty = getBounty()
    State.status = "⚔️ VIVA PETRO ⚔️"
    print("[🇨🇴 VIVA PETRO] ACTIVADO")
end

-- ==================== UI MODERNA CON BANDERAS DE COLOMBIA ====================
local THEMES = {
    Default = {accent = Color3.fromRGB(210, 215, 225), bg = Color3.fromRGB(9, 9, 11), panel = Color3.fromRGB(14, 14, 16), card = Color3.fromRGB(17, 17, 20)},
    Red = {accent = Color3.fromRGB(230, 60, 60), bg = Color3.fromRGB(14, 7, 7), panel = Color3.fromRGB(18, 10, 10), card = Color3.fromRGB(20, 12, 12)},
    Cyan = {accent = Color3.fromRGB(0, 190, 240), bg = Color3.fromRGB(8, 10, 20), panel = Color3.fromRGB(10, 13, 25), card = Color3.fromRGB(12, 15, 28)},
    Green = {accent = Color3.fromRGB(50, 220, 100), bg = Color3.fromRGB(7, 13, 8), panel = Color3.fromRGB(9, 17, 10), card = Color3.fromRGB(10, 19, 12)},
    Yellow = {accent = Color3.fromRGB(240, 210, 40), bg = Color3.fromRGB(13, 12, 6), panel = Color3.fromRGB(17, 16, 8), card = Color3.fromRGB(19, 18, 9)},
}

local THEME = THEMES[CONFIG.Theme] or THEMES.Cyan
local T_ACCENT = THEME.accent
local T_BG = THEME.bg
local T_PANEL = THEME.panel
local T_CARD = THEME.card

local C = {
    bg = T_BG, panel = T_PANEL, card = T_CARD,
    border = T_ACCENT:Lerp(Color3.fromRGB(5, 5, 10), 0.75),
    green = Color3.fromRGB(45, 210, 110), red = Color3.fromRGB(215, 60, 60),
    gold = Color3.fromRGB(240, 185, 55), text = Color3.fromRGB(220, 225, 245),
    muted = Color3.fromRGB(90, 100, 135),
}

-- Colores de la bandera de Colombia
local COLORS = {
    yellow = Color3.fromRGB(252, 209, 22),   -- Amarillo
    blue = Color3.fromRGB(0, 56, 147),       -- Azul
    red = Color3.fromRGB(206, 17, 38),       -- Rojo
}

-- Limpiar UI anterior
for _, parent in ipairs({player.PlayerGui, game:GetService("CoreGui")}) do
    pcall(function() parent:FindFirstChild("VivaPetroUI"):Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VivaPetroUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- Frame principal
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 420, 0, 540)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
MainFrame.BackgroundColor3 = T_BG
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

local MainCorner = Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = COLORS.yellow
MainStroke.Thickness = 2

-- Barra de título con bandera
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = T_PANEL
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleBar
TitleCorner.CornerRadius = UDim.new(0, 12)

-- Bandera izquierda
local FlagLeft = Instance.new("Frame")
FlagLeft.Parent = TitleBar
FlagLeft.Size = UDim2.new(0, 40, 1, 0)
FlagLeft.Position = UDim2.new(0, 5, 0, 0)
FlagLeft.BackgroundColor3 = COLORS.yellow
FlagLeft.BorderSizePixel = 0

local FlagLeftBlue = Instance.new("Frame")
FlagLeftBlue.Parent = FlagLeft
FlagLeftBlue.Size = UDim2.new(1, 0, 0.5, 0)
FlagLeftBlue.Position = UDim2.new(0, 0, 0, 0)
FlagLeftBlue.BackgroundColor3 = COLORS.blue
FlagLeftBlue.BorderSizePixel = 0

local FlagLeftRed = Instance.new("Frame")
FlagLeftRed.Parent = FlagLeft
FlagLeftRed.Size = UDim2.new(1, 0, 0.5, 0)
FlagLeftRed.Position = UDim2.new(0, 0, 0.5, 0)
FlagLeftRed.BackgroundColor3 = COLORS.red
FlagLeftRed.BorderSizePixel = 0

-- Título
local Title = Instance.new("TextLabel")
Title.Parent = TitleBar
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 55, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🇨🇴 VIVA PETRO 🇨🇴"
Title.TextColor3 = COLORS.yellow
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = TitleBar
SubTitle.Size = UDim2.new(0.6, 0, 0, 16)
SubTitle.Position = UDim2.new(0, 55, 0, 34)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "EL PODER DEL PUEBLO"
SubTitle.TextColor3 = C.muted
SubTitle.TextSize = 9
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Bandera derecha
local FlagRight = Instance.new("Frame")
FlagRight.Parent = TitleBar
FlagRight.Size = UDim2.new(0, 40, 1, 0)
FlagRight.Position = UDim2.new(1, -45, 0, 0)
FlagRight.BackgroundColor3 = COLORS.yellow
FlagRight.BorderSizePixel = 0

local FlagRightBlue = Instance.new("Frame")
FlagRightBlue.Parent = FlagRight
FlagRightBlue.Size = UDim2.new(1, 0, 0.5, 0)
FlagRightBlue.Position = UDim2.new(0, 0, 0, 0)
FlagRightBlue.BackgroundColor3 = COLORS.blue
FlagRightBlue.BorderSizePixel = 0

local FlagRightRed = Instance.new("Frame")
FlagRightRed.Parent = FlagRight
FlagRightRed.Size = UDim2.new(1, 0, 0.5, 0)
FlagRightRed.Position = UDim2.new(0, 0, 0.5, 0)
FlagRightRed.BackgroundColor3 = COLORS.red
FlagRightRed.BorderSizePixel = 0

-- Botón minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -80, 0.5, -15)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0

local MinCorner = Instance.new("UICorner")
MinCorner.Parent = MinBtn
MinCorner.CornerRadius = UDim.new(0, 6)

-- Panel de estadísticas
local StatsPanel = Instance.new("Frame")
StatsPanel.Parent = MainFrame
StatsPanel.Size = UDim2.new(0.9, 0, 0, 80)
StatsPanel.Position = UDim2.new(0.05, 0, 0, 65)
StatsPanel.BackgroundColor3 = T_CARD
StatsPanel.BorderSizePixel = 0

local StatsCorner = Instance.new("UICorner")
StatsCorner.Parent = StatsPanel
StatsCorner.CornerRadius = UDim.new(0, 10)

local KillsLabel = Instance.new("TextLabel")
KillsLabel.Parent = StatsPanel
KillsLabel.Size = UDim2.new(0.33, 0, 0.5, 0)
KillsLabel.Position = UDim2.new(0, 0, 0, 5)
KillsLabel.BackgroundTransparency = 1
KillsLabel.Text = "🔪 KILLS"
KillsLabel.TextColor3 = C.muted
KillsLabel.TextSize = 10
KillsLabel.Font = Enum.Font.GothamBold

local KillsValue = Instance.new("TextLabel")
KillsValue.Parent = StatsPanel
KillsValue.Size = UDim2.new(0.33, 0, 0.5, 0)
KillsValue.Position = UDim2.new(0, 0, 0.5, 0)
KillsValue.BackgroundTransparency = 1
KillsValue.Text = "0"
KillsValue.TextColor3 = COLORS.red
KillsValue.TextSize = 24
KillsValue.Font = Enum.Font.GothamBlack

local EarnedLabel = Instance.new("TextLabel")
EarnedLabel.Parent = StatsPanel
EarnedLabel.Size = UDim2.new(0.34, 0, 0.5, 0)
EarnedLabel.Position = UDim2.new(0.33, 0, 0, 5)
EarnedLabel.BackgroundTransparency = 1
EarnedLabel.Text = "💰 GANADO"
EarnedLabel.TextColor3 = C.muted
EarnedLabel.TextSize = 10
EarnedLabel.Font = Enum.Font.GothamBold

local EarnedValue = Instance.new("TextLabel")
EarnedValue.Parent = StatsPanel
EarnedValue.Size = UDim2.new(0.34, 0, 0.5, 0)
EarnedValue.Position = UDim2.new(0.33, 0, 0.5, 0)
EarnedValue.BackgroundTransparency = 1
EarnedValue.Text = "+0"
EarnedValue.TextColor3 = COLORS.yellow
EarnedValue.TextSize = 20
EarnedValue.Font = Enum.Font.GothamBlack

local BountyLabel = Instance.new("TextLabel")
BountyLabel.Parent = StatsPanel
BountyLabel.Size = UDim2.new(0.33, 0, 0.5, 0)
BountyLabel.Position = UDim2.new(0.67, 0, 0, 5)
BountyLabel.BackgroundTransparency = 1
BountyLabel.Text = "🏆 BOUNTY"
BountyLabel.TextColor3 = C.muted
BountyLabel.TextSize = 10
BountyLabel.Font = Enum.Font.GothamBold

local BountyValue = Instance.new("TextLabel")
BountyValue.Parent = StatsPanel
BountyValue.Size = UDim2.new(0.33, 0, 0.5, 0)
BountyValue.Position = UDim2.new(0.67, 0, 0.5, 0)
BountyValue.BackgroundTransparency = 1
BountyValue.Text = "0"
BountyValue.TextColor3 = COLORS.blue
BountyValue.TextSize = 20
BountyValue.Font = Enum.Font.GothamBlack

-- Panel de estado
local StatusFrame = Instance.new("Frame")
StatusFrame.Parent = MainFrame
StatusFrame.Size = UDim2.new(0.9, 0, 0, 35)
StatusFrame.Position = UDim2.new(0.05, 0, 0, 155)
StatusFrame.BackgroundColor3 = T_CARD
StatusFrame.BorderSizePixel = 0

local StatusCorner = Instance.new("UICorner")
StatusCorner.Parent = StatusFrame
StatusCorner.CornerRadius = UDim.new(0, 8)

local StatusDot = Instance.new("Frame")
StatusDot.Parent = StatusFrame
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 12, 0.5, -4)
StatusDot.BackgroundColor3 = COLORS.green
StatusDot.BorderSizePixel = 0

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.Parent = StatusDot
StatusDotCorner.CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel")
StatusText.Parent = StatusFrame
StatusText.Size = UDim2.new(0.8, 0, 1, 0)
StatusText.Position = UDim2.new(0, 28, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
StatusText.TextColor3 = C.text
StatusText.TextSize = 12
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left

-- Barra de tiempo
local TimerBg = Instance.new("Frame")
TimerBg.Parent = MainFrame
TimerBg.Size = UDim2.new(0.9, 0, 0, 10)
TimerBg.Position = UDim2.new(0.05, 0, 0, 200)
TimerBg.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
TimerBg.BorderSizePixel = 0

local TimerBgCorner = Instance.new("UICorner")
TimerBgCorner.Parent = TimerBg
TimerBgCorner.CornerRadius = UDim.new(0, 5)

local TimerBar = Instance.new("Frame")
TimerBar.Parent = TimerBg
TimerBar.Size = UDim2.new(1, 0, 1, 0)
TimerBar.BackgroundColor3 = COLORS.yellow
TimerBar.BorderSizePixel = 0

local TimerBarCorner = Instance.new("UICorner")
TimerBarCorner.Parent = TimerBar
TimerBarCorner.CornerRadius = UDim.new(0, 5)

local TimerText = Instance.new("TextLabel")
TimerText.Parent = TimerBg
TimerText.Size = UDim2.new(1, 0, 1, 0)
TimerText.BackgroundTransparency = 1
TimerText.Text = "15s"
TimerText.TextColor3 = Color3.new(1, 1, 1)
TimerText.TextSize = 8
TimerText.Font = Enum.Font.GothamBold

-- ==================== BOTONES ====================
local function CreateButton(parent, text, yPos, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0.85, 0, 0, 42)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = bgColor
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.Parent = btn
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Botón Auto Bounty
local BountyBtn = CreateButton(MainFrame, "🔴 AUTO BOUNTY", 220, Color3.fromRGB(150, 0, 0), function()
    if State.active then
        State.active = false
        BountyBtn.Text = "🔴 AUTO BOUNTY"
        BountyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StatusText.Text = "🇨🇴 INACTIVO 🇨🇴"
        StatusDot.BackgroundColor3 = COLORS.red
        print("[🇨🇴 VIVA PETRO] Auto Bounty DESACTIVADO")
    else
        startAll()
        selectFaction(CONFIG.Team)
        BountyBtn.Text = "🟢 AUTO BOUNTY (ACTIVO)"
        BountyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        StatusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
        StatusDot.BackgroundColor3 = COLORS.green
        print("[🇨🇴 VIVA PETRO] Auto Bounty ACTIVADO")
    end
end)

-- Botón Abuse Inf Range
local AbuseBtn = CreateButton(MainFrame, "🔴 ABUSE INF RANGE", 272, Color3.fromRGB(100, 0, 150), function()
    AbuseState.active = not AbuseState.active
    if AbuseState.active then
        AbuseBtn.Text = "🟢 ABUSE INF RANGE (ACTIVO)"
        AbuseBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        print("[🇨🇴 VIVA PETRO] Abuse Inf Range ACTIVADO")
    else
        AbuseBtn.Text = "🔴 ABUSE INF RANGE"
        AbuseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
        print("[🇨🇴 VIVA PETRO] Abuse Inf Range DESACTIVADO")
    end
end)

-- Botón Void Skill
local VoidBtn = CreateButton(MainFrame, "🌌 VOID SKILL (INF)", 324, Color3.fromRGB(0, 100, 150), function()
    VoidSkill()
    StatusText.Text = "🌌 VOID SKILL EJECUTADO"
    task.delay(1.5, function()
        if State.active then
            StatusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
        else
            StatusText.Text = "🇨🇴 INACTIVO 🇨🇴"
        end
    end)
end)

-- Botón Facción
local FactionBtn = CreateButton(MainFrame, "🏴‍☠️ SELECCIONAR " .. CONFIG.Team, 376, Color3.fromRGB(30, 80, 120), function()
    selectFaction(CONFIG.Team)
    FactionBtn.Text = "✅ " .. CONFIG.Team .. " SELECCIONADO"
    task.delay(1.5, function()
        FactionBtn.Text = "🏴‍☠️ SELECCIONAR " .. CONFIG.Team
    end)
end)

-- Botón Fix Camera
local FixBtn = CreateButton(MainFrame, "📷 FIX CAMERA", 428, Color3.fromRGB(40, 40, 50), function()
    AbuseState.active = false
    AbuseBtn.Text = "🔴 ABUSE INF RANGE"
    AbuseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
    if player.Character then
        Workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end
    StatusText.Text = "📷 CAMARA RESTAURADA"
    task.delay(1.5, function()
        if State.active then
            StatusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
        else
            StatusText.Text = "🇨🇴 INACTIVO 🇨🇴"
        end
    end)
end)

-- Footer con bandera
local Footer = Instance.new("Frame")
Footer.Parent = MainFrame
Footer.Size = UDim2.new(1, 0, 0, 25)
Footer.Position = UDim2.new(0, 0, 1, -25)
Footer.BackgroundColor3 = T_PANEL
Footer.BackgroundTransparency = 0.5
Footer.BorderSizePixel = 0

local FooterCorner = Instance.new("UICorner")
FooterCorner.Parent = Footer
FooterCorner.CornerRadius = UDim.new(0, 8)

local FooterFlag = Instance.new("Frame")
FooterFlag.Parent = Footer
FooterFlag.Size = UDim2.new(0, 50, 1, 0)
FooterFlag.Position = UDim2.new(0.5, -25, 0, 0)
FooterFlag.BackgroundColor3 = COLORS.yellow
FooterFlag.BorderSizePixel = 0

local FooterFlagBlue = Instance.new("Frame")
FooterFlagBlue.Parent = FooterFlag
FooterFlagBlue.Size = UDim2.new(1, 0, 0.5, 0)
FooterFlagBlue.Position = UDim2.new(0, 0, 0, 0)
FooterFlagBlue.BackgroundColor3 = COLORS.blue
FooterFlagBlue.BorderSizePixel = 0

local FooterFlagRed = Instance.new("Frame")
FooterFlagRed.Parent = FooterFlag
FooterFlagRed.Size = UDim2.new(1, 0, 0.5, 0)
FooterFlagRed.Position = UDim2.new(0, 0, 0.5, 0)
FooterFlagRed.BackgroundColor3 = COLORS.red
FooterFlagRed.BorderSizePixel = 0

local FooterText = Instance.new("TextLabel")
FooterText.Parent = Footer
FooterText.Size = UDim2.new(1, 0, 1, 0)
FooterText.BackgroundTransparency = 1
FooterText.Text = "🇨🇴 EL PODER DEL PUEBLO - VIVA PETRO 🇨🇴"
FooterText.TextColor3 = C.muted
FooterText.TextSize = 9
FooterText.Font = Enum.Font.Gotham

-- ==================== DRAG & DROP ====================
local dragging = false
local dragStart
local frameStart

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==================== MINIMIZAR ====================
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 55), "Out", "Quad", 0.2, true)
        MinBtn.Text = "+"
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TitleBar and child ~= MainStroke then
                child.Visible = false
            end
        end
    else
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 540), "Out", "Quad", 0.2, true)
        MinBtn.Text = "−"
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TitleBar and child ~= MainStroke then
                child.Visible = true
            end
        end
    end
end)

-- ==================== UPDATE UI ====================
task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            KillsValue.Text = tostring(State.kills)
            EarnedValue.Text = "+" .. fmt(State.sessionEarned)
            BountyValue.Text = fmt(getBounty())
            
            local sinceHit = os.clock() - State.lastHitTime
            local remaining = math.max(0, CONFIG.NoHitTimeout - sinceHit)
            TimerBar.Size = UDim2.new(remaining / CONFIG.NoHitTimeout, 0, 1, 0)
            TimerText.Text = math.ceil(remaining) .. "s"
        end)
    end
end)

-- ==================== INICIALIZAR ====================
print([[
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║     🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴     ║
║                                                                      ║
║     🔥 VIVA PETRO - BOUNTY + ABUSE INF RANGE 🔥                     ║
║                                                                      ║
║     🇨🇴 EL PODER DEL PUEBLO - VIVA PETRO CARAJO 🇨🇴                  ║
║                                                                      ║
║     🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴     ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   ✅ SCRIPT CARGADO CORRECTAMENTE                                   ║
║   ✅ USA LOS BOTONES PARA ACTIVAR LAS FUNCIONES                     ║
║   ✅ PUEDES ARRASTRAR LA VENTANA                                    ║
║   ✅ BOTÓN "−" PARA MINIMIZAR                                       ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   🎮 FUNCIONES DISPONIBLES:                                         ║
║   • AUTO BOUNTY - Farmeo automático de bounty/honor                 ║
║   • ABUSE INF RANGE - Ataque infinito con habilidad especial       ║
║   • VOID SKILL - Teletransporte y ataque infinito                  ║
║   • SELECCIONAR FACCIÓN - Pirates o Marines                        ║
║   • FIX CAMERA - Restaura la cámara y desancla                     ║
║                                                                      ║
║   🇨🇴 ¡VIVA PETRO, CARAJO! 🇨🇴                                      ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]])

-- Iniciar auto bounty automáticamente
task.wait(1)
startAll()
selectFaction(CONFIG.Team)
BountyBtn.Text = "🟢 AUTO BOUNTY (ACTIVO)"
BountyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
StatusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
StatusDot.BackgroundColor3 = COLORS.green
print("[🇨🇴 VIVA PETRO] Auto Bounty INICIADO AUTOMÁTICAMENTE")
print("[🇨🇴 VIVA PETRO] ¡EL PODER DEL PUEBLO! 🇨🇴")
