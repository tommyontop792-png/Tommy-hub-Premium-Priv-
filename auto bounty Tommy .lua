local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

getgenv().AbuseActive   = false
getgenv().SelectedSlot  = Enum.KeyCode.Three
getgenv().InfAutoActive = false
getgenv().CombatStyle   = "Melee"

local function Press(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.01)
    VIM:SendKeyEvent(false, key, false, game)
end

local function AutoHaki()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("Buso")
    end)
end

local function EquipCombat()
    pcall(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
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
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)
    if hrp and hum and hum.Health > 0 then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 500, 0)
        Press(getgenv().SelectedSlot)
        task.wait(0.08)
        Press(Enum.KeyCode.J)
        local targetPos = CFrame.new(923.2, 3e21, 32852.8)
        hrp.Anchored = true
        hrp.CFrame = targetPos
        workspace.CurrentCamera.CFrame = targetPos
        task.wait(0.05)
        Press(Enum.KeyCode.Z)
        task.spawn(function() task.wait(0.03); hum.Health = 0 end)
        local s = tick()
        while tick() - s < 0.6 do RunService.Heartbeat:Wait() end
    end
end

local function ExecuteInfAuto()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    AutoHaki()
    EquipCombat()
    task.wait(0.1)
    local target = GetNearestPlayer()
    local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local oldPos = hrp.CFrame
    hrp.Anchored = true
    if targetHRP then
        local tPos = targetHRP.Position
        hrp.CFrame = CFrame.lookAt(Vector3.new(tPos.X, tPos.Y+80, tPos.Z), Vector3.new(tPos.X, tPos.Y, tPos.Z))
    else
        hrp.CFrame = CFrame.new(923.2, 3e21, 32852.8)
    end
    workspace.CurrentCamera.CFrame = hrp.CFrame
    task.wait(0.08)
    Press(Enum.KeyCode.Z)
    task.wait(0.35)
    hrp.CFrame = oldPos
    hrp.Anchored = false
    pcall(function() workspace.CurrentCamera.CameraSubject = hum end)
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().InfAutoActive then pcall(ExecuteInfAuto) end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.8)
        if getgenv().InfAutoActive then AutoHaki() end
    end
end)

-- GUI
local pgui = lp:WaitForChild("PlayerGui")
if pgui:FindFirstChild("TommyHub") then pgui.TommyHub:Destroy() end
local screenGui = Instance.new("ScreenGui", pgui)
screenGui.Name = "TommyHub"
screenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", screenGui)
MainFrame.Size = UDim2.new(0,220,0,400)
MainFrame.Position = UDim2.new(0.5,-110,0.5,-200)
MainFrame.BackgroundColor3 = Color3.fromRGB(10,0,20)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,12)
local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = Color3.fromRGB(160,0,255)
mStroke.Thickness = 2

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1,0,0,36)
TitleBar.BackgroundColor3 = Color3.fromRGB(20,0,40)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,12)

local avImg = Instance.new("ImageLabel", TitleBar)
avImg.Size = UDim2.new(0,26,0,26)
avImg.Position = UDim2.new(0,5,0.5,-13)
avImg.BackgroundTransparency = 1
avImg.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", avImg).CornerRadius = UDim.new(1,0)
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avImg.Image = url end
end)

local titleLbl = Instance.new("TextLabel", TitleBar)
titleLbl.Size = UDim2.new(1,-90,1,0)
titleLbl.Position = UDim2.new(0,36,0,0)
titleLbl.Text = "TOMMY HUB"
titleLbl.TextColor3 = Color3.fromRGB(160,0,255)
titleLbl.Font = "GothamBlack"
titleLbl.TextSize = 13
titleLbl.BackgroundTransparency = 1
titleLbl.TextXAlignment = "Left"

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0,26,0,26)
MinBtn.Position = UDim2.new(1,-30,0.5,-13)
MinBtn.BackgroundColor3 = Color3.fromRGB(180,0,0)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Font = "GothamBold"
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

local ContentFrame = Instance.new("ScrollingFrame", MainFrame)
ContentFrame.Size = UDim2.new(1,0,1,-40)
ContentFrame.Position = UDim2.new(0,0,0,40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(160,0,255)
ContentFrame.CanvasSize = UDim2.new(0,0,0,500)
ContentFrame.BorderSizePixel = 0
local cfLayout = Instance.new("UIListLayout", ContentFrame)
cfLayout.Padding = UDim.new(0,8)
cfLayout.HorizontalAlignment = "Center"
local cfPad = Instance.new("UIPadding", ContentFrame)
cfPad.PaddingTop = UDim.new(0,8)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0,220,0,36) or UDim2.new(0,220,0,400)
    MinBtn.Text = minimized and "+" or "−"
end)

local function makeBtn(txt, color)
    local btn = Instance.new("TextButton", ContentFrame)
    btn.Size = UDim2.new(0.9,0,0,38)
    btn.BackgroundColor3 = Color3.fromRGB(25,0,50)
    btn.Text = txt
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = "GothamBold"
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local s = Instance.new("UIStroke", btn)
    s.Color = color
    s.Thickness = 2
    return btn
end

local abuse3Btn = makeBtn("🐉 Talon Abuse (Slot 3): OFF", Color3.fromRGB(120,0,200))
abuse3Btn.MouseButton1Click:Connect(function()
    getgenv().SelectedSlot = Enum.KeyCode.Three
    getgenv().AbuseActive = not getgenv().AbuseActive
    abuse3Btn.Text = getgenv().AbuseActive and "🐉 Talon Abuse (Slot 3): ON" or "🐉 Talon Abuse (Slot 3): OFF"
    abuse3Btn.BackgroundColor3 = getgenv().AbuseActive and Color3.fromRGB(80,0,160) or Color3.fromRGB(25,0,50)
    if getgenv().AbuseActive then task.spawn(ExecuteAbuse) end
end)

local abuse1Btn = makeBtn("🐉 Talon Abuse (Slot 1): OFF", Color3.fromRGB(120,0,200))
abuse1Btn.MouseButton1Click:Connect(function()
    getgenv().SelectedSlot = Enum.KeyCode.One
    getgenv().AbuseActive = not getgenv().AbuseActive
    abuse1Btn.Text = getgenv().AbuseActive and "🐉 Talon Abuse (Slot 1): ON" or "🐉 Talon Abuse (Slot 1): OFF"
    abuse1Btn.BackgroundColor3 = getgenv().AbuseActive and Color3.fromRGB(80,0,160) or Color3.fromRGB(25,0,50)
    if getgenv().AbuseActive then task.spawn(ExecuteAbuse) end
end)

local infBtn = makeBtn("⚡ INF Auto: OFF", Color3.fromRGB(100,0,200))
infBtn.MouseButton1Click:Connect(function()
    getgenv().InfAutoActive = not getgenv().InfAutoActive
    infBtn.Text = getgenv().InfAutoActive and "⚡ INF Auto: ON" or "⚡ INF Auto: OFF"
    infBtn.BackgroundColor3 = getgenv().InfAutoActive and Color3.fromRGB(80,0,160) or Color3.fromRGB(25,0,50)
end)

-- Selector Melee / Sword
local styleRow = Instance.new("Frame", ContentFrame)
styleRow.Size = UDim2.new(0.9,0,0,34)
styleRow.BackgroundTransparency = 1
local srLayout = Instance.new("UIListLayout", styleRow)
srLayout.FillDirection = "Horizontal"
srLayout.Padding = UDim.new(0,6)
srLayout.HorizontalAlignment = "Center"

local meleeBtn = Instance.new("TextButton", styleRow)
meleeBtn.Size = UDim2.new(0,90,0,30)
meleeBtn.BackgroundColor3 = Color3.fromRGB(0,80,30)
meleeBtn.Text = "👊 Melee"
meleeBtn.TextColor3 = Color3.fromRGB(80,255,140)
meleeBtn.Font = "GothamBold"
meleeBtn.TextSize = 11
meleeBtn.BorderSizePixel = 0
Instance.new("UICorner", meleeBtn).CornerRadius = UDim.new(0,8)

local swordBtn = Instance.new("TextButton", styleRow)
swordBtn.Size = UDim2.new(0,90,0,30)
swordBtn.BackgroundColor3 = Color3.fromRGB(30,20,0)
swordBtn.Text = "⚔️ Sword"
swordBtn.TextColor3 = Color3.fromRGB(150,150,150)
swordBtn.Font = "GothamBold"
swordBtn.TextSize = 11
swordBtn.BorderSizePixel = 0
Instance.new("UICorner", swordBtn).CornerRadius = UDim.new(0,8)

local infStatusLbl = Instance.new("TextLabel", ContentFrame)
infStatusLbl.Size = UDim2.new(0.9,0,0,16)
infStatusLbl.BackgroundTransparency = 1
infStatusLbl.Text = "● Melee + Haki armadura auto"
infStatusLbl.TextColor3 = Color3.fromRGB(150,100,255)
infStatusLbl.Font = "GothamBold"
infStatusLbl.TextSize = 10
infStatusLbl.TextXAlignment = "Left"

local fixBtn = makeBtn("🔧 Fix Camera", Color3.fromRGB(100,50,255))
fixBtn.MouseButton1Click:Connect(function()
    getgenv().AbuseActive = false
    getgenv().InfAutoActive = false
    abuse3Btn.Text = "🐉 Talon Abuse (Slot 3): OFF"
    abuse3Btn.BackgroundColor3 = Color3.fromRGB(25,0,50)
    abuse1Btn.Text = "🐉 Talon Abuse (Slot 1): OFF"
    abuse1Btn.BackgroundColor3 = Color3.fromRGB(25,0,50)
    infBtn.Text = "⚡ INF Auto: OFF"
    infBtn.BackgroundColor3 = Color3.fromRGB(25,0,50)
    if lp.Character then
        workspace.CurrentCamera.CameraSubject = lp.Character:FindFirstChildOfClass("Humanoid")
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end
end)

local function UpdateStyleBtns()
    if getgenv().CombatStyle == "Melee" then
        meleeBtn.BackgroundColor3 = Color3.fromRGB(0,80,30)
        meleeBtn.TextColor3 = Color3.fromRGB(80,255,140)
        swordBtn.BackgroundColor3 = Color3.fromRGB(30,20,0)
        swordBtn.TextColor3 = Color3.fromRGB(150,150,150)
        infStatusLbl.Text = "● Melee + Haki armadura auto"
    else
        swordBtn.BackgroundColor3 = Color3.fromRGB(80,60,0)
        swordBtn.TextColor3 = Color3.fromRGB(255,200,80)
        meleeBtn.BackgroundColor3 = Color3.fromRGB(10,5,20)
        meleeBtn.TextColor3 = Color3.fromRGB(150,150,150)
        infStatusLbl.Text = "● Sword + Haki armadura auto"
    end
end

meleeBtn.MouseButton1Click:Connect(function() getgenv().CombatStyle = "Melee"; UpdateStyleBtns() end)
swordBtn.MouseButton1Click:Connect(function() getgenv().CombatStyle = "Sword"; UpdateStyleBtns() end)

lp.CharacterAdded:Connect(function()
    if getgenv().AbuseActive then task.wait(0.5); task.spawn(ExecuteAbuse) end
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
        MainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y)
    end
end)

UpdateStyleBtns()
