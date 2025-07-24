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

Window:Separator({Text = "ESP"})

-- ESP настройки (getgenv)
getgenv().ESP_Enabled = getgenv().ESP_Enabled or false
getgenv().ESP_Skeleton = getgenv().ESP_Skeleton or false
getgenv().ESP_NameTagsThroughWalls = getgenv().ESP_NameTagsThroughWalls or false
getgenv().ESP_Color = getgenv().ESP_Color or Color3.fromRGB(0,255,0)
getgenv().ESP_Thickness = getgenv().ESP_Thickness or 2
getgenv().ESP_Boxes = getgenv().ESP_Boxes or true
getgenv().ESP_Names = getgenv().ESP_Names or true
getgenv().ESP_EnemiesOnly = getgenv().ESP_EnemiesOnly or false
getgenv().ESP_MaxDistance = getgenv().ESP_MaxDistance or 1000

-- ESP SETTINGS TABLE
getgenv().ESP_Settings = getgenv().ESP_Settings or {
    NameSize = 14,
    NameColor = Color3.fromRGB(0,255,0),
    NameTransparency = 0,
    OutlineColor = Color3.fromRGB(0,0,0),
    HighlightColor = Color3.fromRGB(255,0,0),
    HighlightTransparency = 0.5,
    NameOffset = 2
}

-- Синхронизация настроек из меню
local function SyncESPSettings()
    getgenv().ESP_Settings.NameColor = getgenv().ESP_Color
    getgenv().ESP_Settings.NameSize = getgenv().ESP_Settings.NameSize or 14
    getgenv().ESP_Settings.NameTransparency = 0
    getgenv().ESP_Settings.OutlineColor = Color3.fromRGB(0,0,0)
    getgenv().ESP_Settings.HighlightColor = getgenv().ESP_Color
    getgenv().ESP_Settings.HighlightTransparency = 0.5
    getgenv().ESP_Settings.NameOffset = 2
end

-- Создание ESP для игрока
local function CreateESP(plr)
    if plr == player or not plr.Character then return end
    local character = plr.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    if character:FindFirstChild("ESP") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, getgenv().ESP_Settings.NameOffset, 0)
    billboard.AlwaysOnTop = getgenv().ESP_NameTagsThroughWalls
    billboard.Adornee = rootPart
    billboard.Parent = character

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = getgenv().ESP_Settings.NameColor
    nameLabel.TextTransparency = getgenv().ESP_Settings.NameTransparency
    nameLabel.TextStrokeColor3 = getgenv().ESP_Settings.OutlineColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = getgenv().ESP_Settings.NameSize
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = getgenv().ESP_Settings.HighlightColor
    highlight.FillTransparency = getgenv().ESP_Settings.HighlightTransparency
    highlight.OutlineColor = getgenv().ESP_Settings.OutlineColor
    highlight.Adornee = character
    highlight.Parent = character
end

-- Удаление ESP с игрока
local function RemoveESP(plr)
    if plr.Character then
        local esp = plr.Character:FindFirstChild("ESP")
        local highlight = plr.Character:FindFirstChild("ESPHighlight")
        if esp then esp:Destroy() end
        if highlight then highlight:Destroy() end
    end
end

-- Обновление ESP для всех игроков
local function UpdateESP()
    SyncESPSettings()
    for _,plr in ipairs(Players:GetPlayers()) do
        if getgenv().ESP_Enabled then
            if plr ~= player and plr.Character and not plr.Character:FindFirstChild("ESP") then
                CreateESP(plr)
            end
        else
            RemoveESP(plr)
        end
    end
end

-- Обновлять ESP при изменении чекбокса
espCheckbox.Callback = function(self, Value)
    getgenv().ESP_Enabled = Value
    UpdateESP()
end
nametagsCheckbox.Callback = function(self, Value)
    getgenv().ESP_NameTagsThroughWalls = Value
    UpdateESP()
end
colorPicker.Callback = function(self, Color)
    getgenv().ESP_Color = Color
    UpdateESP()
end

-- Следить за появлением новых персонажей
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if getgenv().ESP_Enabled then
            wait(1)
            CreateESP(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

-- При старте — обновить ESP для всех
UpdateESP()

-- ESP отрисовка
local function IsEnemy(target)
    -- Можно доработать под свою игру (например, по командам)
    return true
end

local function WorldToScreen(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function DrawESP()
    if not getgenv().ESP_Enabled then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if getgenv().ESP_EnemiesOnly and not IsEnemy(plr) then continue end
            local root = plr.Character.HumanoidRootPart
            local pos, onScreen, dist = WorldToScreen(root.Position)
            if not onScreen or dist > getgenv().ESP_MaxDistance then continue end
            -- Боксы
            if getgenv().ESP_Boxes then
                -- Можно использовать Drawing API или Gui (зависит от окружения)
                -- Здесь только пример:
                -- Drawing.new("Square") ...
            end
            -- Skeleton ESP
            if getgenv().ESP_Skeleton then
                -- Перебор костей и отрисовка линий между ними
                -- Например: Head->Torso->Arms->Legs
            end
            -- NameTags
            if getgenv().ESP_Names then
                -- Если NameTagsThroughWalls, то всегда рисуем, иначе проверяем видимость
                -- Drawing.new("Text") ...
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(DrawESP)
end) 
