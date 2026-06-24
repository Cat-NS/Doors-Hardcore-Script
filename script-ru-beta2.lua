-- Проверка Place ID (поддерживаем два плейса)
local expectedPlaceIds = {
    137519142947486,
    92934548952604,
    137519142947486,
    89566832465264
}
local currentPlaceId = game.PlaceId
local isValidPlace = false
for _, id in ipairs(expectedPlaceIds) do
    if currentPlaceId == id then
        isValidPlace = true
        break
    end
end

if not isValidPlace then
    local player = game.Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Parent = player.PlayerGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 500, 0, 100)
    label.Position = UDim2.new(0.5, -250, 0.3, 0)
    label.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "❌ Не тот плейс!\nОжидается ID: " .. table.concat(expectedPlaceIds, ", ") .. "\nТекущий ID: " .. currentPlaceId
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    task.wait(10)
    gui:Destroy()
    return
end

-- --- Основной код (остаётся без изменений) ---
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lighting = game:GetService("Lighting")
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local playerGui = player:WaitForChild("PlayerGui")

-- Переменные состояния
local speedhackEnabled = false
local speedhackValue = 100
local defaultSpeed = 16
local espEnabled = false
local fullBrightEnabled = false
local fullBrightLoop = nil
local flyEnabled = false
local flyBodyVelocity = nil
local flyBodyGyro = nil
local noclipLoop = nil
local flyMovementConnection = nil
local flySpeed = 100

-- Таблица для хранения всех соединений
local connections = {}
local function addConnection(conn)
    table.insert(connections, conn)
    return conn
end

-- Таблица для GUI
local createdGuis = {}

local function createUnloadableGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.Parent = playerGui
    table.insert(createdGuis, gui)
    return gui
end

-- --- Сообщение о запуске ---
local function showStartMessage()
    local gui = createUnloadableGui("StartMessage")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 480, 0, 50)
    label.Position = UDim2.new(0.5, -240, 0.1, 0)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "DOORS Hardcore скрипт загружен!\nF1 — Speed, F2 — TP, F3 — ESP, F4 — Bright, F5 — Fly, Del — Unload"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    task.wait(5)
    gui:Destroy()
    for i, g in ipairs(createdGuis) do
        if g == gui then table.remove(createdGuis, i) break end
    end
end
showStartMessage()

-- --- SpeedHack ---
local speedHackConnection = addConnection(runService.Heartbeat:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if speedhackEnabled and not flyEnabled then
            hum.WalkSpeed = speedhackValue
        elseif not flyEnabled then
            hum.WalkSpeed = defaultSpeed
        end
    end
end))

-- --- TP Tool ---
local function giveTpTool()
    if not player or not player.Backpack then return end
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

-- --- FullBright ---
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
    applyFullBright()
    fullBrightLoop = addConnection(runService.Heartbeat:Connect(applyFullBright))
    print("FullBright ВКЛ (loop)")
end

local function stopFullBrightLoop()
    if fullBrightLoop then
        fullBrightLoop:Disconnect()
        for i, conn in ipairs(connections) do
            if conn == fullBrightLoop then table.remove(connections, i) break end
        end
        fullBrightLoop = nil
    end
    fullBrightEnabled = false
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

-- --- ESP ---
local espData = {}
local espAddedConnection = nil
local espRemovedConnection = nil
local entityNames = {}

local function createESP(object)
    if espData[object] or not object or not object.Parent then return end
    if object:IsA("BasePart") and object.Parent and object.Parent:IsA("Model") then
        return
    end
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
    espAddedConnection = addConnection(workspace.DescendantAdded:Connect(onDescendantAdded))
    espRemovedConnection = addConnection(workspace.DescendantRemoving:Connect(onDescendantRemoving))
    print("ESP активирован")
end

local function deactivateESP()
    if not espEnabled then return end
    espEnabled = false
    if espAddedConnection then
        espAddedConnection:Disconnect()
        for i, conn in ipairs(connections) do
            if conn == espAddedConnection then table.remove(connections, i) break end
        end
        espAddedConnection = nil
    end
    if espRemovedConnection then
        espRemovedConnection:Disconnect()
        for i, conn in ipairs(connections) do
            if conn == espRemovedConnection then table.remove(connections, i) break end
        end
        espRemovedConnection = nil
    end
    clearAllESP()
    print("ESP деактивирован")
end

-- --- Fly + NoClip ---
local function restoreCollision()
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

local function enableNoClipLoop()
    if noclipLoop then return end
    noclipLoop = addConnection(runService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end))
end

local function disableNoClipLoop()
    if noclipLoop then
        noclipLoop:Disconnect()
        for i, conn in ipairs(connections) do
            if conn == noclipLoop then table.remove(connections, i) break end
        end
        noclipLoop = nil
    end
    restoreCollision()
end

local function startFly()
    if flyEnabled then return end
    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    flyEnabled = true

    humanoid.PlatformStand = true
    humanoid.WalkSpeed = 0

    enableNoClipLoop()

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.Parent = rootPart

    if not flyMovementConnection then
        flyMovementConnection = addConnection(runService.Heartbeat:Connect(function()
            if not flyEnabled then return end
            local char = player.Character
            if not char then return end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local camera = workspace.CurrentCamera
            if not camera then return end

            local forward = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
            local right = camera.CFrame.RightVector * Vector3.new(1, 0, 1)
            local up = Vector3.new(0, 1, 0)

            local move = Vector3.new(0, 0, 0)
            if userInput:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
            if userInput:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
            if userInput:IsKeyDown(Enum.KeyCode.A) then move = move - right end
            if userInput:IsKeyDown(Enum.KeyCode.D) then move = move + right end
            if userInput:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
            if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - up end

            if move.Magnitude > 0 then
                move = move.Unit * flySpeed
            end

            if flyBodyVelocity then
                flyBodyVelocity.Velocity = move
            end

            if flyBodyGyro then
                flyBodyGyro.CFrame = camera.CFrame * CFrame.Angles(0, 0, 0)
            end
        end))
    end

    print("Fly + NoClip ВКЛ")
end

local function stopFly()
    if not flyEnabled then return end
    flyEnabled = false

    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

    if flyMovementConnection then
        flyMovementConnection:Disconnect()
        for i, conn in ipairs(connections) do
            if conn == flyMovementConnection then table.remove(connections, i) break end
        end
        flyMovementConnection = nil
    end

    humanoid.PlatformStand = false
    humanoid.WalkSpeed = defaultSpeed

    disableNoClipLoop()

    print("Fly + NoClip ВЫКЛ")
end

local function toggleFly()
    if flyEnabled then
        stopFly()
    else
        startFly()
    end
end

local characterAddedConnection = addConnection(player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    if flyEnabled then
        stopFly()
        startFly()
    end
end))

-- --- Обработка клавиш ---
local inputBeganConnection = addConnection(userInput.InputBegan:Connect(function(input, chat)
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
    elseif input.KeyCode == Enum.KeyCode.F5 then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.Delete then
        unloadScript()
    end
end))

-- --- Функция разгрузки ---
function unloadScript()
    if speedhackEnabled then
        speedhackEnabled = false
    end

    if fullBrightEnabled then
        stopFullBrightLoop()
    end

    if espEnabled then
        deactivateESP()
    end

    if flyEnabled then
        stopFly()
    end

    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}

    for _, gui in ipairs(createdGuis) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    createdGuis = {}

    speedhackEnabled = false
    fullBrightEnabled = false
    espEnabled = false
    flyEnabled = false
    fullBrightLoop = nil
    espData = {}
    entityNames = {}

    print("Скрипт полностью выгружен (клавиша Delete)")

    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Parent = playerGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 50)
    label.Position = UDim2.new(0.5, -200, 0.5, -25)
    label.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "Скрипт выгружен"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = notifyGui
    task.wait(3)
    notifyGui:Destroy()
end

-- --- Кнопки для мобильных ---
local function createMobileButtons()
    local gui = createUnloadableGui("MobileControls")
    local function makeButton(text, positionX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 0, 40)
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

    makeButton("Spd", 10, function()
        speedhackEnabled = not speedhackEnabled
        print("SpeedHack " .. (speedhackEnabled and "ВКЛ" or "ВЫКЛ"))
    end)

    makeButton("TP", 90, function()
        giveTpTool()
        print("TP Tool выдан")
    end)

    makeButton("ESP", 170, function()
        if espEnabled then
            deactivateESP()
        else
            activateESP()
        end
    end)

    makeButton("Br", 250, function()
        toggleFullBright()
    end)

    makeButton("Fly", 330, function()
        toggleFly()
    end)

    makeButton("Unld", 410, function()
        unloadScript()
    end)
end

createMobileButtons()
