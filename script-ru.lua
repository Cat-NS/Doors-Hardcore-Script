-- Проверяем, что мы в нужном месте
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
    return -- скрипт завершается
end

-- --- Основной код (выполняется только в нужном месте) ---
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Переменные для SpeedHack
local speedhackEnabled = false
local speedhackValue = 50
local defaultSpeed = 16

-- Сервисы
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- --- Сообщение о запуске ---
local function showStartMessage()
    local gui = Instance.new("ScreenGui")
    gui.Parent = player.PlayerGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 50)
    label.Position = UDim2.new(0.5, -200, 0.1, 0)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "DOORS Hardcore скрипт загружен!\nF1 — SpeedHack, F2 — TP Tool"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    task.wait(5)
    gui:Destroy()
end
showStartMessage()

-- --- SpeedHack (обновление через Heartbeat) ---
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

-- --- Функция выдачи телепорт-инструмента ---
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

-- --- Обработка клавиш (ПК) ---
userInput.InputBegan:Connect(function(input, chat)
    if chat then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        speedhackEnabled = not speedhackEnabled
        print("SpeedHack " .. (speedhackEnabled and "ВКЛ" or "ВЫКЛ"))
    elseif input.KeyCode == Enum.KeyCode.F2 then
        giveTpTool()
        print("TP Tool выдан")
    end
end)

-- --- Создание кнопок для мобильных и ПК ---
local function createMobileButtons()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileControls"
    gui.Parent = player.PlayerGui

    local function makeButton(text, positionX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 40)
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

    makeButton("SpeedHack", 10, function()
        speedhackEnabled = not speedhackEnabled
        print("SpeedHack " .. (speedhackEnabled and "ВКЛ" or "ВЫКЛ"))
    end)

    makeButton("TP Tool", 140, function()
        giveTpTool()
        print("TP Tool выдан")
    end)
end

createMobileButtons()

createMobileButtons()
