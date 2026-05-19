local Players           = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local BG_MAIN = Color3.fromRGB(10, 0, 20)
local ACCENT  = Color3.fromRGB(160, 0, 255)

getgenv().AbuseActive   = false
getgenv().SelectedSlot  = Enum.KeyCode.Three
getgenv().InfAutoActive = false
getgenv().CombatStyle   = "Melee" -- "Melee" o "Sword"

-- ===== GUI =====
local ScreenGui  = Instance.new("ScreenGui", game.CoreGui)
local MainFrame  = Instance.new("Frame", ScreenGui)
MainFrame.Size   = UDim2.new(0, 200, 0, 360)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -180)
MainFrame.BackgroundColor3 = BG_MAIN
MainFrame.BorderSizePixel  = 2
MainFrame.BorderColor3     = ACCENT
Instance.new("UICorner", MainFrame)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size  = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar)

-- Avatar
local avImg = Instance.new("ImageLabel", TitleBar)
avImg.Size  = UDim2.new(0, 26, 0, 26)
avImg.Position = UDim2.new(0, 3, 0.5, -13)
avImg.BackgroundTransparency = 1
avImg.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", avImg).CornerRadius = UDim.new(1, 0)
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avImg.Image = url end
end)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size  = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 32, 0, 0)
Title.Text  = lp.Name
Title.TextColor3 = ACCENT
Title.Font  = Enum.Font.GothamBold
Title.TextSize   = 13
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size  = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -28, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
MinBtn.Text  = "-"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font  = Enum.Font.GothamBold
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn)

local Subtitle = Instance.new("TextLabel", MainFrame)
Subtitle.Size = UDim2.new(1, 0, 0, 16)
Subtitle.Position = UDim2.new(0, 0, 0, 32)
Subtitle.Text = "https://discord.gg/vggTR35SRh"
Subtitle.TextColor3 = Color3.fromRGB(200, 150, 255)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 10
Subtitle.BackgroundTransparency = 1

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -50)
ContentFrame.Position = UDim2.new(0, 0, 0, 50)
ContentFrame.BackgroundTransparency = 1

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 200, 0, 32)
        ContentFrame.Visible = false
        Subtitle.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 200, 0, 360)
        ContentFrame.Visible = true
        Subtitle.Visible = true
        MinBtn.Text = "-"
    end
end)

-- ===== FUNCIONES =====
local function Press(key)
    VirtualInputManager:SendKeyEvent(true,  key, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function AutoHaki()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Buso")
    end)
end

local function EquipCombat()
    pcall(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, tool in pairs(lp.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local style = getgenv().CombatStyle
                local match = false
                if style == "Melee" then
                    match = tool.ToolTip == "Melee"
                        or tool.Name:lower():find("fist")
                        or tool.Name:lower():find("melee")
                        or tool.Name:lower():find("combat")
                elseif style == "Sword" then
                    match = tool.ToolTip == "Sword"
                        or tool.Name:lower():find("sword")
                        or tool.Name:lower():find("katana")
                        or tool.Name:lower():find("blade")
                end
                if match then hum:EquipTool(tool); return end
            end
        end
    end)
end

local function GetNearestPlayer()
    local nearest, minDist = nil, math.huge
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < minDist then minDist = d; nearest = p end
            end
        end
    end
    return nearest
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
        end)
        local s = tick()
        while tick() - s < 0.6 do RunService.Heartbeat:Wait() end
    end
end

-- INF AUTOMATICO con estilo de combate + haki
local function ExecuteInfAuto()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- Auto haki de armadura
    AutoHaki()

    -- Equipar estilo de combate elegido
    EquipCombat()
    task.wait(0.1)

    -- Buscar jugador mas cercano y posicionarse encima
    local target    = GetNearestPlayer()
    local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

    local oldPos = hrp.CFrame
    hrp.Anchored = true

    if targetHRP then
        local tPos = targetHRP.Position
        hrp.CFrame = CFrame.lookAt(
            Vector3.new(tPos.X, tPos.Y + 80, tPos.Z),
            Vector3.new(tPos.X, tPos.Y, tPos.Z)
        )
    else
        hrp.CFrame = CFrame.new(923.2, 3e21, 32852.8)
    end

    workspace.CurrentCamera.CFrame = hrp.CFrame
    task.wait(0.08)

    -- Atacar con Z
    Press(Enum.KeyCode.Z)

    task.wait(0.35)
    hrp.CFrame   = oldPos
    hrp.Anchored = false
    pcall(function() workspace.CurrentCamera.CameraSubject = hum end)
end

-- Loop INF automatico
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().InfAutoActive then
            pcall(ExecuteInfAuto)
        end
    end
end)

-- Loop haki constante cuando INF activo
task.spawn(function()
    while true do
        task.wait(0.8)
        if getgenv().InfAutoActive then
            AutoHaki()
        end
    end
end)

-- ===== BOTONES =====
local function MakeButton(parent, text, yPos, bgColor)
    local btn = Instance.new("TextButton", parent)
    btn.Size  = UDim2.new(0.88, 0, 0, 38)
    btn.Position = UDim2.new(0.06, 0, 0, yPos)
    btn.BackgroundColor3 = bgColor
    btn.Text  = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font  = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

local Abuse3Btn = MakeButton(ContentFrame, "ABUSE 3",    10,  Color3.fromRGB(50, 0, 80))
local Abuse1Btn = MakeButton(ContentFrame, "ABUSE 1",    58,  Color3.fromRGB(50, 0, 80))
local InfBtn    = MakeButton(ContentFrame, "⚡ INF: OFF", 106, Color3.fromRGB(25, 0, 50))

-- Selector de estilo (Melee / Sword)
local StyleRow = Instance.new("Frame", ContentFrame)
StyleRow.Size = UDim2.new(0.88, 0, 0, 30)
StyleRow.Position = UDim2.new(0.06, 0, 0, 152)
StyleRow.BackgroundTransparency = 1

local MeleeBtn = Instance.new("TextButton", StyleRow)
MeleeBtn.Size  = UDim2.new(0.48, 0, 1, 0)
MeleeBtn.Position = UDim2.new(0, 0, 0, 0)
MeleeBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 30)
MeleeBtn.Text  = "👊 Melee"
MeleeBtn.TextColor3 = Color3.fromRGB(80, 255, 140)
MeleeBtn.Font  = Enum.Font.GothamBold
MeleeBtn.TextSize = 11
Instance.new("UICorner", MeleeBtn)

local SwordBtn = Instance.new("TextButton", StyleRow)
SwordBtn.Size  = UDim2.new(0.48, 0, 1, 0)
SwordBtn.Position = UDim2.new(0.52, 0, 0, 0)
SwordBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 0)
SwordBtn.Text  = "⚔️ Sword"
SwordBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
SwordBtn.Font  = Enum.Font.GothamBold
SwordBtn.TextSize = 11
Instance.new("UICorner", SwordBtn)

-- Label estado INF
local InfStatusLbl = Instance.new("TextLabel", ContentFrame)
InfStatusLbl.Size = UDim2.new(0.88, 0, 0, 14)
InfStatusLbl.Position = UDim2.new(0.06, 0, 0, 185)
InfStatusLbl.BackgroundTransparency = 1
InfStatusLbl.Text = "● Melee + Haki auto"
InfStatusLbl.TextColor3 = Color3.fromRGB(150, 100, 255)
InfStatusLbl.Font = Enum.Font.Gotham
InfStatusLbl.TextSize = 10
InfStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local FixBtn = MakeButton(ContentFrame, "FIX CAMERA", 205, Color3.fromRGB(20, 0, 35))
FixBtn.TextColor3 = ACCENT
FixBtn.Size = UDim2.new(0.88, 0, 0, 28)

-- ===== LOGICA BOTONES =====
local function UpdateStyleBtns()
    if getgenv().CombatStyle == "Melee" then
        MeleeBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 30)
        MeleeBtn.TextColor3 = Color3.fromRGB(80, 255, 140)
        SwordBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 0)
        SwordBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        InfStatusLbl.Text = "● Melee + Haki armadura auto"
    else
        SwordBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 0)
        SwordBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
        MeleeBtn.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
        MeleeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        InfStatusLbl.Text = "● Sword + Haki armadura auto"
    end
end

MeleeBtn.MouseButton1Click:Connect(function()
    getgenv().CombatStyle = "Melee"
    UpdateStyleBtns()
end)
SwordBtn.MouseButton1Click:Connect(function()
    getgenv().CombatStyle = "Sword"
    UpdateStyleBtns()
end)

Abuse3Btn.MouseButton1Click:Connect(function()
    getgenv().SelectedSlot = Enum.KeyCode.Three
    getgenv().AbuseActive  = not getgenv().AbuseActive
    Abuse3Btn.BackgroundColor3 = getgenv().AbuseActive and Color3.fromRGB(120, 0, 200) or Color3.fromRGB(50, 0, 80)
    if getgenv().AbuseActive then task.spawn(ExecuteAbuse) end
end)

Abuse1Btn.MouseButton1Click:Connect(function()
    getgenv().SelectedSlot = Enum.KeyCode.One
    getgenv().AbuseActive  = not getgenv().AbuseActive
    Abuse1Btn.BackgroundColor3 = getgenv().AbuseActive and Color3.fromRGB(120, 0, 200) or Color3.fromRGB(50, 0, 80)
    if getgenv().AbuseActive then task.spawn(ExecuteAbuse) end
end)

-- INF toggle automatico
InfBtn.MouseButton1Click:Connect(function()
    getgenv().InfAutoActive = not getgenv().InfAutoActive
    if getgenv().InfAutoActive then
        InfBtn.Text = "⚡ INF: ON"
        InfBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 160)
    else
        InfBtn.Text = "⚡ INF: OFF"
        InfBtn.BackgroundColor3 = Color3.fromRGB(25, 0, 50)
    end
end)

FixBtn.MouseButton1Click:Connect(function()
    getgenv().AbuseActive   = false
    getgenv().InfAutoActive = false
    InfBtn.Text = "⚡ INF: OFF"
    InfBtn.BackgroundColor3 = Color3.fromRGB(25, 0, 50)
    if lp.Character then
        workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid
        lp.Character.HumanoidRootPart.Anchored = false
    end
end)

lp.CharacterAdded:Connect(function()
    if getgenv().AbuseActive then
        task.wait(0.5)
        task.spawn(ExecuteAbuse)
    end
end)

-- Draggable
local d, ds, sp
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        d = true; ds = i.Position; sp = MainFrame.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
    end
end)
TitleBar.InputChanged:Connect(function(i)
    if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - ds
        MainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
    end
end)

UpdateStyleBtns()
