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
    ║              🇨🇴 VIVA PETRO - BLOX FRUITS 🇨🇴                            ║
    ║                                                                          ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

-- ==================== CONFIGURACIÓN ====================
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")
local uis = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local players = game:GetService("Players")

-- Colores de Colombia
local COLORS = {
    yellow = Color3.fromRGB(252, 209, 22),
    blue = Color3.fromRGB(0, 56, 147),
    red = Color3.fromRGB(206, 17, 38),
}

-- Estado
local autoFarm = false
local kills = 0
local bountyGanado = 0
local currentBounty = 0

-- ==================== REMOTES DE BLOX FRUITS ====================
local remotes = rs:FindFirstChild("Remotes")
local commF, commE

if remotes then
    commF = remotes:FindFirstChild("CommF_")
    commE = remotes:FindFirstChild("CommE")
end

-- ==================== FUNCIONES ====================
local function getBounty()
    local val = 0
    pcall(function()
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            local bounty = stats:FindFirstChild("Bounty") or stats:FindFirstChild("Honor")
            if bounty then
                val = bounty.Value
            end
        end
    end)
    return val
end

local function equipWeapon(weaponName)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find(weaponName:lower()) or tool.ToolTip:lower():find(weaponName:lower())) then
                hum:EquipTool(tool)
                return true
            end
        end
    end)
    return false
end

local function activateHaki()
    pcall(function()
        if commF then
            commF:InvokeServer("Buso")
        end
    end)
end

local function useAbility(ability)
    pcall(function()
        if commE then
            commE:FireServer(ability)
        end
    end)
end

local function getNearestEnemy()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local closest = nil
    local closestDist = 200
    
    -- Buscar players enemigos
    for _, p in pairs(players:GetPlayers()) do
        if p ~= player and p.Character then
            local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = p.Character:FindFirstChild("Humanoid")
            if targetHrp and targetHum and targetHum.Health > 0 then
                local dist = (targetHrp.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = p.Character
                end
            end
        end
    end
    
    -- Buscar NPCs (enemigos del juego)
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not players:FindFirstChild(obj.Name) then
            local targetHrp = obj:FindFirstChild("HumanoidRootPart")
            local targetHum = obj:FindFirstChild("Humanoid")
            if targetHrp and targetHum and targetHum.Health > 0 then
                -- Verificar si es enemigo (tiene "Enemy" o "NPC" en el nombre)
                local name = obj.Name:lower()
                if name:find("enemy") or name:find("npc") or name:find("boss") or name:find("marine") or name:find("pirate") then
                    local dist = (targetHrp.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    
    return closest, closestDist
end

local function attackTarget(target)
    pcall(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not target then return end
        
        local targetHrp = target:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end
        
        -- Teletransportarse al enemigo
        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 5)
        task.wait(0.05)
        
        -- Activar Haki
        activateHaki()
        task.wait(0.05)
        
        -- Equipar arma (Dragon Heart o Melee)
        equipWeapon("Dragon") or equipWeapon("Melee")
        task.wait(0.05)
        
        -- Usar habilidades
        useAbility("Z")
        task.wait(0.05)
        useAbility("X")
        task.wait(0.05)
        useAbility("C")
        task.wait(0.05)
        
        -- Click para atacar
        vim:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, true, hrp, 0, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, false, hrp, 0, 0)
        
        kills = kills + 1
        bountyGanado = bountyGanado + 100
        currentBounty = getBounty()
        
        print("[🇨🇴] Atacó a enemigo - Kills: " .. kills)
    end)
end

-- ==================== LOOP PRINCIPAL ====================
local farmLoop = nil

local function startFarm()
    if autoFarm then return end
    autoFarm = true
    
    farmLoop = task.spawn(function()
        while autoFarm do
            pcall(function()
                -- Esperar personaje
                if not player.Character or not player.Character:FindFirstChild("Humanoid") then
                    player.CharacterAdded:Wait()
                    task.wait(1)
                end
                
                -- Buscar enemigo
                local target, dist = getNearestEnemy()
                
                if target then
                    attackTarget(target)
                    task.wait(0.5)
                else
                    -- Sin enemigos, volar para buscar
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.new(0, 100, 0)
                    end
                    task.wait(1)
                end
            end)
            task.wait(0.8)
        end
    end)
end

local function stopFarm()
    autoFarm = false
    if farmLoop then
        task.cancel(farmLoop)
        farmLoop = nil
    end
end

-- ==================== UI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VivaPetroBloxFruits"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

local mainCorner = Instance.new("UICorner")
mainCorner.Parent = mainFrame
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Parent = mainFrame
mainStroke.Color = COLORS.yellow
mainStroke.Thickness = 2

-- Barra de título
local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner")
titleCorner.Parent = titleBar
titleCorner.CornerRadius = UDim.new(0, 12)

-- Bandera izquierda
local flagLeft = Instance.new("Frame")
flagLeft.Parent = titleBar
flagLeft.Size = UDim2.new(0, 45, 1, 0)
flagLeft.Position = UDim2.new(0, 5, 0, 0)
flagLeft.BackgroundColor3 = COLORS.yellow
flagLeft.BorderSizePixel = 0

local flagLeftBlue = Instance.new("Frame")
flagLeftBlue.Parent = flagLeft
flagLeftBlue.Size = UDim2.new(1, 0, 0.5, 0)
flagLeftBlue.BackgroundColor3 = COLORS.blue
flagLeftBlue.BorderSizePixel = 0

local flagLeftRed = Instance.new("Frame")
flagLeftRed.Parent = flagLeft
flagLeftRed.Size = UDim2.new(1, 0, 0.5, 0)
flagLeftRed.Position = UDim2.new(0, 0, 0.5, 0)
flagLeftRed.BackgroundColor3 = COLORS.red
flagLeftRed.BorderSizePixel = 0

-- Título
local title = Instance.new("TextLabel")
title.Parent = titleBar
title.Size = UDim2.new(0.55, 0, 1, 0)
title.Position = UDim2.new(0, 55, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🇨🇴 VIVA PETRO 🇨🇴"
title.TextColor3 = COLORS.yellow
title.TextSize = 16
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left

local subTitle = Instance.new("TextLabel")
subTitle.Parent = titleBar
subTitle.Size = UDim2.new(0.55, 0, 0, 16)
subTitle.Position = UDim2.new(0, 55, 0, 35)
subTitle.BackgroundTransparency = 1
subTitle.Text = "BLOX FRUITS"
subTitle.TextColor3 = Color3.fromRGB(150, 150, 180)
subTitle.TextSize = 9
subTitle.Font = Enum.Font.Gotham
subTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Bandera derecha
local flagRight = Instance.new("Frame")
flagRight.Parent = titleBar
flagRight.Size = UDim2.new(0, 45, 1, 0)
flagRight.Position = UDim2.new(1, -50, 0, 0)
flagRight.BackgroundColor3 = COLORS.yellow
flagRight.BorderSizePixel = 0

local flagRightBlue = Instance.new("Frame")
flagRightBlue.Parent = flagRight
flagRightBlue.Size = UDim2.new(1, 0, 0.5, 0)
flagRightBlue.BackgroundColor3 = COLORS.blue
flagRightBlue.BorderSizePixel = 0

local flagRightRed = Instance.new("Frame")
flagRightRed.Parent = flagRight
flagRightRed.Size = UDim2.new(1, 0, 0.5, 0)
flagRightRed.Position = UDim2.new(0, 0, 0.5, 0)
flagRightRed.BackgroundColor3 = COLORS.red
flagRightRed.BorderSizePixel = 0

-- Botón minimizar
local minBtn = Instance.new("TextButton")
minBtn.Parent = titleBar
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -85, 0.5, -15)
minBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0

local minCorner = Instance.new("UICorner")
minCorner.Parent = minBtn
minCorner.CornerRadius = UDim.new(0, 6)

-- Panel de estadísticas
local statsPanel = Instance.new("Frame")
statsPanel.Parent = mainFrame
statsPanel.Size = UDim2.new(0.9, 0, 0, 80)
statsPanel.Position = UDim2.new(0.05, 0, 0, 65)
statsPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
statsPanel.BorderSizePixel = 0

local statsCorner = Instance.new("UICorner")
statsCorner.Parent = statsPanel
statsCorner.CornerRadius = UDim.new(0, 10)

-- Kills
local killsLabel = Instance.new("TextLabel")
killsLabel.Parent = statsPanel
killsLabel.Size = UDim2.new(0.33, 0, 0.5, 0)
killsLabel.Position = UDim2.new(0, 0, 0, 5)
killsLabel.BackgroundTransparency = 1
killsLabel.Text = "🔪 KILLS"
killsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
killsLabel.TextSize = 10
killsLabel.Font = Enum.Font.GothamBold

local killsValue = Instance.new("TextLabel")
killsValue.Parent = statsPanel
killsValue.Size = UDim2.new(0.33, 0, 0.5, 0)
killsValue.Position = UDim2.new(0, 0, 0.5, 0)
killsValue.BackgroundTransparency = 1
killsValue.Text = "0"
killsValue.TextColor3 = COLORS.red
killsValue.TextSize = 24
killsValue.Font = Enum.Font.GothamBlack

-- Ganado
local earnedLabel = Instance.new("TextLabel")
earnedLabel.Parent = statsPanel
earnedLabel.Size = UDim2.new(0.34, 0, 0.5, 0)
earnedLabel.Position = UDim2.new(0.33, 0, 0, 5)
earnedLabel.BackgroundTransparency = 1
earnedLabel.Text = "💰 GANADO"
earnedLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
earnedLabel.TextSize = 10
earnedLabel.Font = Enum.Font.GothamBold

local earnedValue = Instance.new("TextLabel")
earnedValue.Parent = statsPanel
earnedValue.Size = UDim2.new(0.34, 0, 0.5, 0)
earnedValue.Position = UDim2.new(0.33, 0, 0.5, 0)
earnedValue.BackgroundTransparency = 1
earnedValue.Text = "+0"
earnedValue.TextColor3 = COLORS.yellow
earnedValue.TextSize = 18
earnedValue.Font = Enum.Font.GothamBlack

-- Bounty actual
local bountyLabel = Instance.new("TextLabel")
bountyLabel.Parent = statsPanel
bountyLabel.Size = UDim2.new(0.33, 0, 0.5, 0)
bountyLabel.Position = UDim2.new(0.67, 0, 0, 5)
bountyLabel.BackgroundTransparency = 1
bountyLabel.Text = "🏆 BOUNTY"
bountyLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
bountyLabel.TextSize = 10
bountyLabel.Font = Enum.Font.GothamBold

local bountyValue = Instance.new("TextLabel")
bountyValue.Parent = statsPanel
bountyValue.Size = UDim2.new(0.33, 0, 0.5, 0)
bountyValue.Position = UDim2.new(0.67, 0, 0.5, 0)
bountyValue.BackgroundTransparency = 1
bountyValue.Text = "0"
bountyValue.TextColor3 = COLORS.blue
bountyValue.TextSize = 18
bountyValue.Font = Enum.Font.GothamBlack

-- Estado
local statusFrame = Instance.new("Frame")
statusFrame.Parent = mainFrame
statusFrame.Size = UDim2.new(0.9, 0, 0, 35)
statusFrame.Position = UDim2.new(0.05, 0, 0, 155)
statusFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
statusFrame.BorderSizePixel = 0

local statusCorner = Instance.new("UICorner")
statusCorner.Parent = statusFrame
statusCorner.CornerRadius = UDim.new(0, 8)

local statusDot = Instance.new("Frame")
statusDot.Parent = statusFrame
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 12, 0.5, -4)
statusDot.BackgroundColor3 = COLORS.green
statusDot.BorderSizePixel = 0

local statusDotCorner = Instance.new("UICorner")
statusDotCorner.Parent = statusDot
statusDotCorner.CornerRadius = UDim.new(1, 0)

local statusText = Instance.new("TextLabel")
statusText.Parent = statusFrame
statusText.Size = UDim2.new(0.8, 0, 1, 0)
statusText.Position = UDim2.new(0, 28, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "🇨🇴 VIVA PETRO 🇨🇴"
statusText.TextColor3 = Color3.fromRGB(220, 220, 240)
statusText.TextSize = 11
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Left

-- Botón Iniciar/Detener
local farmBtn = Instance.new("TextButton")
farmBtn.Parent = mainFrame
farmBtn.Size = UDim2.new(0.85, 0, 0, 50)
farmBtn.Position = UDim2.new(0.075, 0, 0, 205)
farmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
farmBtn.Text = "🇨🇴 INICIAR AUTO FARM 🇨🇴"
farmBtn.TextColor3 = Color3.new(1, 1, 1)
farmBtn.TextSize = 14
farmBtn.Font = Enum.Font.GothamBold
farmBtn.BorderSizePixel = 0

local farmCorner = Instance.new("UICorner")
farmCorner.Parent = farmBtn
farmCorner.CornerRadius = UDim.new(0, 10)

-- Botón Haki
local hakiBtn = Instance.new("TextButton")
hakiBtn.Parent = mainFrame
hakiBtn.Size = UDim2.new(0.85, 0, 0, 40)
hakiBtn.Position = UDim2.new(0.075, 0, 0, 265)
hakiBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
hakiBtn.Text = "🥋 ACTIVAR HAKI"
hakiBtn.TextColor3 = Color3.new(1, 1, 1)
hakiBtn.TextSize = 12
hakiBtn.Font = Enum.Font.GothamBold
hakiBtn.BorderSizePixel = 0

local hakiCorner = Instance.new("UICorner")
hakiCorner.Parent = hakiBtn
hakiCorner.CornerRadius = UDim.new(0, 8)

-- Botón Fix Camera
local fixBtn = Instance.new("TextButton")
fixBtn.Parent = mainFrame
fixBtn.Size = UDim2.new(0.85, 0, 0, 35)
fixBtn.Position = UDim2.new(0.075, 0, 0, 315)
fixBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
fixBtn.Text = "📷 FIX CAMERA"
fixBtn.TextColor3 = Color3.new(1, 1, 1)
fixBtn.TextSize = 12
fixBtn.Font = Enum.Font.GothamBold
fixBtn.BorderSizePixel = 0

local fixCorner = Instance.new("UICorner")
fixCorner.Parent = fixBtn
fixCorner.CornerRadius = UDim.new(0, 8)

-- Footer
local footer = Instance.new("Frame")
footer.Parent = mainFrame
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Position = UDim2.new(0, 0, 1, -22)
footer.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
footer.BackgroundTransparency = 0.5
footer.BorderSizePixel = 0

local footerCorner = Instance.new("UICorner")
footerCorner.Parent = footer
footerCorner.CornerRadius = UDim.new(0, 8)

local footerText = Instance.new("TextLabel")
footerText.Parent = footer
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.BackgroundTransparency = 1
footerText.Text = "🇨🇴 EL PODER DEL PUEBLO - VIVA PETRO 🇨🇴"
footerText.TextColor3 = Color3.fromRGB(100, 100, 120)
footerText.TextSize = 9
footerText.Font = Enum.Font.Gotham

-- ==================== FUNCIONES DE BOTONES ====================
farmBtn.MouseButton1Click:Connect(function()
    if autoFarm then
        stopFarm()
        farmBtn.Text = "🇨🇴 INICIAR AUTO FARM 🇨🇴"
        farmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        statusText.Text = "🇨🇴 DETENIDO 🇨🇴"
        statusDot.BackgroundColor3 = COLORS.red
        print("[🇨🇴] Auto Farm DETENIDO")
    else
        startFarm()
        farmBtn.Text = "🔴 DETENER AUTO FARM"
        farmBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        statusText.Text = "🇨🇴 FARMANDO 🇨🇴"
        statusDot.BackgroundColor3 = COLORS.green
        print("[🇨🇴] Auto Farm INICIADO")
    end
end)

hakiBtn.MouseButton1Click:Connect(function()
    activateHaki()
    statusText.Text = "🥋 HAKI ACTIVADO"
    task.delay(1.5, function()
        if autoFarm then
            statusText.Text = "🇨🇴 FARMANDO 🇨🇴"
        else
            statusText.Text = "🇨🇴 DETENIDO 🇨🇴"
        end
    end)
    print("[🇨🇴] Haki activado manualmente")
end)

fixBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if player.Character then
            ws.CurrentCamera.CameraSubject = player.Character.Humanoid
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end)
    statusText.Text = "📷 CAMARA RESTAURADA"
    task.delay(1.5, function()
        if autoFarm then
            statusText.Text = "🇨🇴 FARMANDO 🇨🇴"
        else
            statusText.Text = "🇨🇴 DETENIDO 🇨🇴"
        end
    end)
end)

-- ==================== DETECCIÓN DE BOUNTY ====================
pcall(function()
    if commE then
        commE.OnClientEvent:Connect(function(event, ...)
            if event == "Notify" then
                local msg = select(1, ...) or ""
                if msg:find("Bounty") or msg:find("Honor") then
                    local earned = tonumber(string.match(msg, "(%d+)")) or 50
                    bountyGanado = bountyGanado + earned
                    currentBounty = getBounty()
                end
            end
        end)
    end
end)

-- ==================== ACTUALIZAR UI ====================
task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            killsValue.Text = tostring(kills)
            earnedValue.Text = "+" .. tostring(bountyGanado)
            bountyValue.Text = tostring(getBounty())
        end)
    end
end)

-- ==================== ARRASTRAR VENTANA ====================
local dragging = false
local dragStart, frameStart

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)

uis.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==================== MINIMIZAR ====================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame:TweenSize(UDim2.new(0, 350, 0, 55), "Out", "Quad", 0.2, true)
        minBtn.Text = "+"
        for _, child in pairs(mainFrame:GetChildren()) do
            if child ~= titleBar and child ~= mainStroke then
                child.Visible = false
            end
        end
    else
        mainFrame:TweenSize(UDim2.new(0, 350, 0, 400), "Out", "Quad", 0.2, true)
        minBtn.Text = "−"
        for _, child in pairs(mainFrame:GetChildren()) do
            if child ~= titleBar and child ~= mainStroke then
                child.Visible = true
            end
        end
    end
end)

-- ==================== INICIALIZAR ====================
print([[
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║     🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴🇨🇴     ║
║                                                                      ║
║     🔥 VIVA PETRO - BLOX FRUITS 🔥                                  ║
║                                                                      ║
║     🇨🇴 EL PODER DEL PUEBLO - VIVA PETRO CARAJO 🇨🇴                  ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   ✅ SCRIPT CARGADO CORRECTAMENTE PARA BLOX FRUITS                  ║
║   ✅ PRESIONA "INICIAR AUTO FARM" PARA COMENZAR                     ║
║   ✅ EL SCRIPT BUSCARÁ ENEMIGOS Y ATACARÁ AUTOMÁTICAMENTE           ║
║   ✅ PUEDES ARRASTRAR LA VENTANA                                    ║
║   ✅ BOTÓN "−" PARA MINIMIZAR                                       ║
║                                                                      ║
║   🇨🇴 ¡VIVA PETRO, CARAJO! 🇨🇴                                      ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]])

print("[🇨🇴] Script de Blox Fruits cargado - Presiona INICIAR para empezar a farmear")
