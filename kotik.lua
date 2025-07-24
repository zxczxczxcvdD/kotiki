-- ВСТАВЬ СЮДА СВОЮ ССЫЛКУ НА ЭТОТ ЖЕ ФАЙЛ В РЕПОЗИТОРИИ ДЛЯ АВТОИНЖЕКТА:
getgenv().StretchMenuURL = "https://raw.github.com/zxczxczxcvdD/kotiki/main/kotik.lua"

-- Удаляем все старые окна ReGui при запуске
pcall(function()
    for _,v in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "ReGui" then v:Destroy() end
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local CONFIG_PATH = "StretchMenuConfig.json"

-- Автозагрузка Resolution из файла
local function loadConfig()
    if isfile(CONFIG_PATH) then
        local data = readfile(CONFIG_PATH)
        local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok and decoded and decoded.Resolution then
            return tonumber(decoded.Resolution)
        end
    end
    return 0.6
end
getgenv().Resolution = loadConfig()

-- Автосохранение Resolution раз в 10 секунд
spawn(function()
    while true do
        local data = HttpService:JSONEncode({Resolution = getgenv().Resolution})
        writefile(CONFIG_PATH, data)
        wait(10)
    end
end)

-- Импорт ReGui
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local PrefabsId = `rbxassetid://{ImGui.PrefabsId}`
ImGui:Init({
    Prefabs = game:GetService("InsertService"):LoadLocalAsset(PrefabsId)
})

-- Меню
local Window = ImGui:Window({
    Title = "Растяг камеры",
    Size = UDim2.fromOffset(320, 100),
    Position = UDim2.new(0.5, -160, 0.5, -50),
    NoClose = true,
})

local sliderValueLabel = Window:Label({
    Text = string.format("Текущее: %.2f", getgenv().Resolution),
    TextColor3 = Color3.fromRGB(200, 200, 255),
    TextSize = 16,
})

local slider = Window:SliderProgress({
    Label = "Resolution",
    Value = getgenv().Resolution,
    Minimum = 0.2,
    Maximum = 1.8,
    Callback = function(self, Value)
        getgenv().Resolution = tonumber(string.format("%.2f", Value))
        sliderValueLabel.Text = string.format("Текущее: %.2f", getgenv().Resolution)
    end,
})

-- Бинд на K для скрытия/показа только нового меню
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        Window:SetVisible(not Window.Visible)
    end
end)

-- СТАРЫЙ РАСТЯГ: применяем на каждый кадр
RunService.RenderStepped:Connect(function()
    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution, 0, 0, 0, 1)
end)

-- Автоинжект при смене placeId
local lastPlace = game.PlaceId
spawn(function()
    while wait(2) do
        if game.PlaceId ~= lastPlace then
            lastPlace = game.PlaceId
            if getgenv().StretchMenuURL and #getgenv().StretchMenuURL > 0 then
                loadstring(game:HttpGet(getgenv().StretchMenuURL))()
            end
            break
        end
    end
end) 
