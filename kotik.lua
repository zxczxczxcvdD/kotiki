-- ВСТАВЬ СЮДА СВОЮ ССЫЛКУ НА ЭТОТ ЖЕ ФАЙЛ В РЕПОЗИТОРИИ ДЛЯ АВТОИНЖЕКТА:
getgenv().StretchMenuURL = "https://raw.githubusercontent.com/ТВОЙ_РЕПО/ПУТЬ/StretchMenu.lua"

-- ДАЛЬШЕ ИДЁТ ВЕСЬ КОД МЕНЮ (НЕ МЕНЯЙ ЭТУ СТРОКУ В ДРУГИХ МЕСТАХ)

-- Минималистичное меню растяга камеры на ReGui, только слайдер, пресеты, автосохранение и автоинжект

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local CONFIG_PATH = "StretchMenuConfig.json"

-- Импорт ReGui
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local PrefabsId = `rbxassetid://{ImGui.PrefabsId}`
ImGui:Init({
    Prefabs = game:GetService("InsertService"):LoadLocalAsset(PrefabsId)
})

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

-- Мини-меню через ReGui
local Window = ImGui:Window({
    Title = "Растяг камеры",
    Size = UDim2.fromOffset(260, 120),
    Position = UDim2.new(0.5, -130, 0.5, -60),
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
        sliderValueLabel:SetText(string.format("Текущее: %.2f", getgenv().Resolution))
    end,
})

Window:Separator({Text = "Пресеты"})
local presetValues = {}
for i = 0.2, 1.8, 0.1 do table.insert(presetValues, tonumber(string.format("%.1f", i))) end
local row = Window:Row()
for i, v in ipairs(presetValues) do
    if (i-1) % 5 == 0 and i > 1 then row = Window:Row() end
    row:Button({
        Text = tostring(v),
        Size = UDim2.new(0, 38, 0, 22),
        Callback = function()
            getgenv().Resolution = v
            slider:SetValue(v)
            sliderValueLabel:SetText(string.format("Текущее: %.2f", v))
        end,
    })
end

-- Бинд на K для скрытия/показа меню
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        Window:SetVisible(not Window.Visible)
    end
end)

-- Оптимизированное применение растяга камеры
local baseCFrame = Camera.CFrame
local lastRes = getgenv().Resolution
RunService.RenderStepped:Connect(function()
    if getgenv().Resolution ~= lastRes then
        Camera.CFrame = baseCFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution, 0, 0, 0, 1)
        lastRes = getgenv().Resolution
    end
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
