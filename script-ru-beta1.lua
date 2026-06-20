-- Проверка Place ID
local expectedPlaceId = 137519142947486
if game.PlaceId ~= expectedPlaceId then
    local player = game.Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Parent = player.PlayerGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 500, 0, 100)
    label.Position = UDim2.new(0.5, -250, 0.3, 0)
    label.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "❌ Не тот плейс!\nОжидается ID: " .. expectedPlaceId .. "\nТекущий ID: " .. game.PlaceId
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    task.wait(10)
    gui:Destroy()
    return
end

-- --- Основной код ---
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lighting = game:GetService("Lighting")

-- Переменные
local speedhackEnabled = false
local speedhackValue = 50
local defaultSpeed = 16
local espEnabled = false
local fullBrightEnabled = false
local fullBrightLoop = nil -- храним ссылку на цикл

-- Сервисы
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

-- --- Сообщение о запуске ---
local function showStartMessage()
    local gui = Instance.new("ScreenGui")
    gui.Parent = player.PlayerGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 450, 0, 50)
    label.Position = UDim2.new(0.5, -225, 0.1, 0)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "DOORS Hardcore скрипт загружен!\nF1 — Speed, F2 — TP, F3 — ESP, F4 — FullBright"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    task.wait(5)
    gui:Destroy()
end
showStartMessage()

-- --- SpeedHack ---
runService.Heartbeat:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if speedhackEnabled then
            hum.WalkSpeed = speedhackValue
        else
            hum.WalkSpeed = defaultSpeed
        end
    end
end)

-- --- TP Tool ---
local function giveTpTool()
    local backpack = player.Backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool.Name == "Tp tool" then
            return
        end
    end
    local mouse = player:GetMouse()
    local tool = Instance.new("Tool")
    tool.Name = "Tp tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        if mouse then
            local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
            end
        end
    end)
    tool.Parent = backpack
end

-- --- FullBright (Loop-версия) ---
local function applyFullBright()
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(255, 255, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.FogEnd = 100000
    lighting.FogStart = 0
end

local function startFullBrightLoop()
    if fullBrightLoop then return end
    fullBrightEnabled = true
    applyFullBright() -- сразу применить
    fullBrightLoop = runService.Heartbeat:Connect(function()
        applyFullBright() -- постоянно переустанавливаем
    end)
    print("FullBright ВКЛ (loop)")
end

local function stopFullBrightLoop()
    if fullBrightLoop then
        fullBrightLoop:Disconnect()
        fullBrightLoop = nil
    end
    fullBrightEnabled = false
    -- Восстанавливаем настройки (можно оставить как есть, или сбросить на стандартные)
    lighting.Brightness = 1
    lighting.Ambient = Color3.fromRGB(127, 127, 127)
    lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    lighting.FogEnd = 100000
    lighting.FogStart = 0
    print("FullBright ВЫКЛ")
end

local function toggleFullBright()
    if fullBrightEnabled then
        stopFullBrightLoop()
    else
        startFullBrightLoop()
    end
end

-- --- ESP (сквозь стены) ---
local espData = {}
local espAddedConnection = nil
local espRemovedConnection = nil
local entityNames = {}

local function createESP(object)
    if espData[object] or not object or not object.Parent then return end
    if object:IsA("BasePart") and object.Parent and object.Parent:IsA("Model") then
        return
    end
    print("ESP: подсвечиваю " .. object.Name)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = object

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.Adornee = object
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = object

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = object.Name
    label.Parent = billboard

    espData[object] = {Highlight = highlight, Billboard = billboard}
end

local function removeESP(object)
    local data = espData[object]
    if data then
        data.Highlight:Destroy()
        data.Billboard:Destroy()
        espData[object] = nil
    end
end

local function clearAllESP()
    for obj, _ in pairs(espData) do
        removeESP(obj)
    end
    espData = {}
end

local function getEntityNames()
    local names = {}
    local entities = replicatedStorage:FindFirstChild("Entities")
    if entities then
        for _, child in ipairs(entities:GetChildren()) do
            names[child.Name] = true
        end
    end
    return names
end

local function scanWorkspace()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if entityNames[descendant.Name] and not espData[descendant] then
            createESP(descendant)
        end
    end
end

local function onDescendantAdded(descendant)
    if espEnabled and entityNames[descendant.Name] and not espData[descendant] then
        createESP(descendant)
    end
end

local function onDescendantRemoving(descendant)
    if espData[descendant] then
        removeESP(descendant)
    end
end

local function activateESP()
    if espEnabled then return end
    espEnabled = true
    entityNames = getEntityNames()
    scanWorkspace()
    espAddedConnection = workspace.DescendantAdded:Connect(onDescendantAdded)
    espRemovedConnection = workspace.DescendantRemoving:Connect(onDescendantRemoving)
    print("ESP активирован")
end

local function deactivateESP()
    if not espEnabled then return end
    espEnabled = false
    if espAddedConnection then espAddedConnection:Disconnect() espAddedConnection = nil end
    if espRemovedConnection then espRemovedConnection:Disconnect() espRemovedConnection = nil end
    clearAllESP()
    print("ESP деактивирован")
end

-- --- Обработка клавиш (ПК) ---
userInput.InputBegan:Connect(function(input, chat)
    if chat then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        speedhackEnabled = not speedhackEnabled
        print("SpeedHack " .. (speedhackEnabled and "ВКЛ" or "ВЫКЛ"))
    elseif input.KeyCode == Enum.KeyCode.F2 then
        giveTpTool()
        print("TP Tool выдан")
    elseif input.KeyCode == Enum.KeyCode.F3 then
        if espEnabled then
            deactivateESP()
        else
            activateESP()
        end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        toggleFullBright()
    end
end)

-- --- Кнопки для мобильных и ПК ---
local function createMobileButtons()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileControls"
    gui.Parent = player.PlayerGui

    local function makeButton(text, positionX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 0, 50) -- увеличил высоту для переноса
        btn.Position = UDim2.new(0, positionX, 0, 10)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.BorderSizePixel = 0
        btn.Parent = gui
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    makeButton("Speed", 10, function()
        speedhackEnabled = not speedhackEnabled
        print("SpeedHack " .. (speedhackEnabled and "ВКЛ" or "ВЫКЛ"))
    end)

    makeButton("TP", 110, function()
        giveTpTool()
        print("TP Tool выдан")
    end)

    makeButton("ESP", 210, function()
        if espEnabled then
            deactivateESP()
        else
            activateESP()
        end
    end)

    makeButton("Full\nBright", 310, function() -- изменён текст кнопки
        toggleFullBright()
    end)
end
game:GetService("CoreGui"):FindFirstChild("chatInputBar", true).Visible = true

createMobileButtons()
