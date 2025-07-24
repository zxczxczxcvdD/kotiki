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

local CONFIG_DIR = "StretchConfigs"
local AUTOCONFIG_PATH = CONFIG_DIR.."/autoconfig.txt"
if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end

-- Получить список конфигов
local function getConfigList()
    local files = listfiles(CONFIG_DIR)
    local configs = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            table.insert(configs, file:match("([^/\\]+)%.json$"))
        end
    end
    table.sort(configs)
    return configs
end

-- Сохранить Resolution в конфиг
local function saveConfig(name, value)
    local data = HttpService:JSONEncode({Resolution = value})
    writefile(CONFIG_DIR.."/"..name..".json", data)
end

-- Загрузить Resolution из конфига
local function loadConfig(name)
    local path = CONFIG_DIR.."/"..name..".json"
    if isfile(path) then
        local data = readfile(path)
        local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok and decoded and decoded.Resolution then
            return tonumber(decoded.Resolution)
        end
    end
    return nil
end

-- Сохранить имя автозагружаемого конфига
local function setAutoConfig(name)
    writefile(AUTOCONFIG_PATH, name)
end

-- Получить имя автозагружаемого конфига
local function getAutoConfig()
    if isfile(AUTOCONFIG_PATH) then
        return readfile(AUTOCONFIG_PATH)
    end
    return nil
end

-- Автозагрузка Resolution из автоконфига или дефолт 0.75
local autoConfigName = getAutoConfig()
if autoConfigName then
    local val = loadConfig(autoConfigName)
    if val then
        getgenv().Resolution = val
    else
        getgenv().Resolution = 0.75
    end
else
    getgenv().Resolution = 0.75
end

-- Автосохранение Resolution раз в 10 секунд (в автоконфиг, если выбран)
spawn(function()
    while true do
        local name = getAutoConfig()
        if name then
            saveConfig(name, getgenv().Resolution)
        end
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
    Size = UDim2.fromOffset(340, 140),
    Position = UDim2.new(0.5, -170, 0.5, -70),
    NoClose = true,
})

-- Восстанавливаем видимость меню при запуске
if getgenv().StretchMenuVisible == false then
    Window:SetVisible(false)
else
    Window:SetVisible(true)
end

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

Window:Separator({Text = "Конфиги"})

local newConfigName = ""
local nameInput = Window:InputText({
    Label = "Имя нового конфига",
    Value = "",
    Callback = function(self, Value)
        newConfigName = tostring(Value)
    end,
})

local statusLabel = Window:Label({
    Text = "",
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextSize = 14,
})

local configList = getConfigList()
local selectedConfig = autoConfigName or configList[1] or ""
local configDropdown = Window:Combo({
    Label = "Выбрать конфиг",
    Items = configList,
    Selected = selectedConfig,
    Callback = function(self, Value)
        selectedConfig = Value
    end,
})

Window:Button({
    Text = "Сохранить как...",
    Size = UDim2.new(0.45, 0, 0, 22),
    Callback = function()
        local name = tostring(newConfigName)
        if #name == 0 then
            statusLabel.Text = "Введите имя конфига!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        saveConfig(name, getgenv().Resolution)
        configList = getConfigList()
        configDropdown:SetItems(configList)
        selectedConfig = name
        configDropdown:SetSelected(name)
        statusLabel.Text = "Сохранено: " .. name
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        nameInput:SetText("")
        newConfigName = ""
    end,
})

Window:Button({
    Text = "Загрузить",
    Size = UDim2.new(0.45, 0, 0, 22),
    Callback = function()
        local val = loadConfig(selectedConfig)
        if val then
            getgenv().Resolution = val
            slider:SetValue(val)
            sliderValueLabel.Text = string.format("Текущее: %.2f", val)
        end
    end,
})

Window:Button({
    Text = "Удалить",
    Size = UDim2.new(0.45, 0, 0, 22),
    Callback = function()
        local path = CONFIG_DIR.."/"..selectedConfig..".json"
        if isfile(path) then
            delfile(path)
            configList = getConfigList()
            configDropdown:SetItems(configList)
            selectedConfig = configList[1] or ""
            configDropdown:SetSelected(selectedConfig)
        end
    end,
})

local autoLoadCheckbox = Window:Checkbox({
    Label = "Автозагрузка этого конфига",
    Value = (selectedConfig == autoConfigName),
    Callback = function(self, Value)
        if Value and selectedConfig and #selectedConfig > 0 then
            setAutoConfig(selectedConfig)
        elseif not Value then
            if isfile(AUTOCONFIG_PATH) then delfile(AUTOCONFIG_PATH) end
        end
    end,
})

-- Бинд на K для скрытия/показа только нового меню
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        Window:SetVisible(not Window.Visible)
        getgenv().StretchMenuVisible = Window.Visible
    end
end)

-- Сохраняем состояние видимости при любом изменении
Window.OnVisibleChanged = function(visible)
    getgenv().StretchMenuVisible = visible
end

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
