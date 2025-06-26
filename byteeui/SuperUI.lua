--[[
    ByteRise-UI - Modern Roblox UI Library
    Features: All major elements (Button, Toggle, Slider, Dropdown, Input, Keybind, Colorpicker, Notification, etc.), Key System, Notification System, Theming, and more.
    Theme: Dark, semi-transparent, modern, WindUI-inspired
    Author: (Your Name)
    Usage: See example at the end
]]

local ByteRiseUI = {}

--// THEME CONFIG //--
local Theme = {
    Background = Color3.fromRGB(20, 20, 20),
    Panel = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(99, 102, 241), -- indigo
    Accent2 = Color3.fromRGB(225, 29, 72), -- rose
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(170, 170, 170),
    Border = Color3.fromRGB(40, 40, 40),
    Transparency = 0.15,
    CornerRadius = UDim.new(0, 8),
    Shadow = true,
}

--// UTILS //--
local function Tween(obj, props, time, style, dir)
    local ts = game:GetService("TweenService")
    local tween = ts:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, dragHandle)
    local UIS = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos
    dragHandle = dragHandle or frame
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Utility: Returns the best parent for GUIs, disables duplicates (Rayfield-style)
local function getBestGuiParent(guiName)
    local CoreGui = game:GetService("CoreGui")
    local parent
    if gethui then
        parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui()
        parent = CoreGui
    elseif CoreGui:FindFirstChild("RobloxGui") then
        parent = CoreGui:FindFirstChild("RobloxGui")
    else
        parent = CoreGui
    end
    -- Disable duplicates
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == guiName then
            v.Enabled = false
            v.Name = guiName.."-Old"
        end
    end
    return parent
end

-- ADVANCED: Multi-Tab Navigation, Config, Resizable, Key System, Theming, Icons, Scroll, etc.

-- Utility: Icon support (simple, can be extended)
local function getIcon(name)
    -- Placeholder: Use emoji or asset id, or extend with your own icon set
    local icons = {
        settings = "⚙️", info = "ℹ️", check = "✔️", x = "❌", bell = "🔔", key = "🔑", color = "🎨", tab = "📁", save = "💾", load = "📂"
    }
    return icons[name] or ""
end

-- Config Save/Load (writefile/readfile if available)
local function canFile()
    return writefile and readfile and isfile and isfolder
end
local function saveConfig(name, data)
    if canFile() then
        writefile(name..".bytcfg", game:GetService("HttpService"):JSONEncode(data))
    end
end
local function loadConfig(name)
    if canFile() and isfile(name..".bytcfg") then
        return game:GetService("HttpService"):JSONDecode(readfile(name..".bytcfg"))
    end
    return nil
end

-- Window resize support
local function MakeResizable(frame, minSize, maxSize)
    local UIS = game:GetService("UserInputService")
    local resizing = false
    local startPos, startSize
    local grip = Instance.new("Frame", frame)
    grip.Size = UDim2.new(0, 16, 0, 16)
    grip.Position = UDim2.new(1, -16, 1, -16)
    grip.BackgroundTransparency = 1
    grip.Name = "ResizeGrip"
    grip.ZIndex = 100
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startPos = input.Position
            startSize = frame.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            local newX = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
            local newY = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
            frame.Size = UDim2.new(0, newX, 0, newY)
        end
    end)
end

--// CONFIG OPTIONS //--
-- config.BlurEffects: enables blur/neon effects (default true)
-- config.UISounds: enables UI sounds (default true)
-- config.UISoundId: custom sound asset id (default: Roblox click)

-- Enhanced Notification System (queue, icons)
local NotificationQueue = {}
local function showNotification(config)
    local gui = (function()
        local parent = getBestGuiParent("ByteRise-UI-Notifications")
        local g = parent:FindFirstChild("ByteRise-UI-Notifications")
        if not g then
            g = Instance.new("ScreenGui")
            g.Name = "ByteRise-UI-Notifications"
            g.Parent = parent
        end
        return g
    end)()
    local notif = Instance.new("Frame", gui)
    notif.Size = UDim2.new(0, 260, 0, 60)
    notif.Position = UDim2.new(1, -280, 1, -80 - (#NotificationQueue*70))
    notif.BackgroundColor3 = Theme.Panel
    notif.BackgroundTransparency = Theme.Transparency
    notif.BorderSizePixel = 0
    notif.AnchorPoint = Vector2.new(0,1)
    notif.ZIndex = 50
    local notifCorner = Instance.new("UICorner", notif)
    notifCorner.CornerRadius = Theme.CornerRadius
    -- Neon/Glow effect (soft shadow)
    local neon = Instance.new("ImageLabel", notif)
    neon.Image = "rbxassetid://1316045217"
    neon.Size = UDim2.new(1, 24, 1, 24)
    neon.Position = UDim2.new(0, -12, 0, -12)
    neon.BackgroundTransparency = 1
    neon.ImageTransparency = 0.85
    neon.ZIndex = 0
    notif.ZIndex = 1
    -- Blur effect (DepthOfField) if enabled
    local blurEffect
    if blurEnabled and not getgenv or not getgenv().SecureMode then
        local Lighting = game:GetService("Lighting")
        blurEffect = Instance.new("DepthOfFieldEffect")
        blurEffect.Enabled = true
        blurEffect.FarIntensity = 0
        blurEffect.FocusDistance = 51.6
        blurEffect.InFocusRadius = 50
        blurEffect.NearIntensity = 1
        blurEffect.Parent = Lighting
    end
    if config.Icon then
        local icon = Instance.new("TextLabel", notif)
        icon.Text = getIcon(config.Icon)
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 22
        icon.TextColor3 = Theme.Accent
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0, 8, 0, 14)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        icon.TextYAlignment = Enum.TextYAlignment.Center
    end
    local title = Instance.new("TextLabel", notif)
    title.Text = config.Title or "Notification"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Theme.Text
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -48, 0, 24)
    title.Position = UDim2.new(0, 44, 0, 4)
    title.TextXAlignment = Enum.TextXAlignment.Left
    local content = Instance.new("TextLabel", notif)
    content.Text = config.Content or ""
    content.Font = Enum.Font.Gotham
    content.TextSize = 14
    content.TextColor3 = Theme.TextSecondary
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -48, 0, 24)
    content.Position = UDim2.new(0, 44, 0, 28)
    content.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(NotificationQueue, notif)
    notif.Position = notif.Position + UDim2.new(0, 0, 0, 40)
    Tween(notif, {Position = UDim2.new(1, -280, 1, -80 - ((#NotificationQueue-1)*70))}, 0.3)
    task.spawn(function()
        task.wait(config.Duration or 3)
        Tween(notif, {Position = notif.Position + UDim2.new(0, 0, 0, 40)}, 0.3)
        task.wait(0.3)
        notif:Destroy()
        if blurEffect then pcall(function() blurEffect:Destroy() end) end
        table.remove(NotificationQueue, 1)
    end)
    return notif
end

-- Key System UI
local function showKeySystem(config, onSuccess)
    local parent = getBestGuiParent("ByteRise-UI-KeySystem")
    local gui = Instance.new("ScreenGui")
    gui.Name = "ByteRise-UI-KeySystem"
    gui.Parent = parent
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 340, 0, 180)
    frame.Position = UDim2.new(0.5, -170, 0.5, -90)
    frame.BackgroundColor3 = Theme.Panel
    frame.BackgroundTransparency = Theme.Transparency
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = Theme.CornerRadius
    local title = Instance.new("TextLabel", frame)
    title.Text = getIcon("key").."  Key System"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Theme.Text
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    local note = Instance.new("TextLabel", frame)
    note.Text = config.Note or "Enter your key."
    note.Font = Enum.Font.Gotham
    note.TextSize = 14
    note.TextColor3 = Theme.TextSecondary
    note.BackgroundTransparency = 1
    note.Size = UDim2.new(1, -32, 0, 32)
    note.Position = UDim2.new(0, 16, 0, 40)
    note.TextWrapped = true
    local box = Instance.new("TextBox", frame)
    box.Text = ""
    box.PlaceholderText = "Key here..."
    box.Font = Enum.Font.Gotham
    box.TextSize = 16
    box.TextColor3 = Theme.Text
    box.BackgroundColor3 = Theme.Background
    box.BackgroundTransparency = Theme.Transparency + 0.05
    box.Size = UDim2.new(1, -32, 0, 32)
    box.Position = UDim2.new(0, 16, 0, 80)
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = Theme.CornerRadius
    local submit = Instance.new("TextButton", frame)
    submit.Text = getIcon("check").."  Submit"
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 16
    submit.TextColor3 = Theme.Text
    submit.BackgroundColor3 = Theme.Accent
    submit.BackgroundTransparency = Theme.Transparency
    submit.Size = UDim2.new(1, -32, 0, 32)
    submit.Position = UDim2.new(0, 16, 0, 124)
    local submitCorner = Instance.new("UICorner", submit)
    submitCorner.CornerRadius = Theme.CornerRadius
    submit.MouseButton1Click:Connect(function()
        local key = box.Text
        if type(config.Keys) == "table" then
            for _, v in ipairs(config.Keys) do
                if tostring(key) == tostring(v) then
                    gui:Destroy()
                    if typeof(onSuccess) == "function" then onSuccess() end
                    return
                end
            end
        elseif tostring(key) == tostring(config.Keys) then
            gui:Destroy()
            if typeof(onSuccess) == "function" then onSuccess() end
            return
        end
        showNotification({Title = "Key System", Content = "Invalid key!", Icon = "x", Duration = 2})
    end)
    return gui
end

-- Theming support
function ByteRiseUI:SetTheme(newTheme)
    for k,v in pairs(newTheme) do
        Theme[k] = v
    end
end

-- Enhanced Window with multi-tab navigation, scroll, and config
function ByteRiseUI:CreateWindow(config)
    config = config or {}
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = config.Title or "ByteRise-UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = getBestGuiParent(ScreenGui.Name)

    -- Loading Screen (Rayfield-inspired)
    local loadingEnabled = true
    local loadingTitle = (config.LoadingScreen and config.LoadingScreen.Title) or config.Title or "ByteRise-UI"
    local loadingSubtitle = (config.LoadingScreen and config.LoadingScreen.Subtitle) or "by (Your Name)"
    local loadingVersion = (config.LoadingScreen and config.LoadingScreen.Version) or "v1.0"
    local loadingDuration = (config.LoadingScreen and config.LoadingScreen.Duration) or 1.2
    if config.LoadingScreen and config.LoadingScreen.Enabled == false then loadingEnabled = false end

    local LoadingScreen = Instance.new("Frame")
    LoadingScreen.Name = "LoadingScreen"
    LoadingScreen.Size = UDim2.new(1, 0, 1, 0)
    LoadingScreen.Position = UDim2.new(0, 0, 0, 0)
    LoadingScreen.BackgroundColor3 = Theme.Panel
    LoadingScreen.BackgroundTransparency = Theme.Transparency
    LoadingScreen.ZIndex = 100
    LoadingScreen.Parent = ScreenGui
    local LoadingCorner = Instance.new("UICorner", LoadingScreen)
    LoadingCorner.CornerRadius = Theme.CornerRadius
    local Title = Instance.new("TextLabel", LoadingScreen)
    Title.Text = loadingTitle
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 28
    Title.TextColor3 = Theme.Text
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 48)
    Title.Position = UDim2.new(0, 0, 0.4, 0)
    Title.TextYAlignment = Enum.TextYAlignment.Center
    local Subtitle = Instance.new("TextLabel", LoadingScreen)
    Subtitle.Text = loadingSubtitle
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 18
    Subtitle.TextColor3 = Theme.TextSecondary
    Subtitle.BackgroundTransparency = 1
    Subtitle.Size = UDim2.new(1, 0, 0, 32)
    Subtitle.Position = UDim2.new(0, 0, 0.4, 44)
    Subtitle.TextYAlignment = Enum.TextYAlignment.Center
    local Version = Instance.new("TextLabel", LoadingScreen)
    Version.Text = loadingVersion
    Version.Font = Enum.Font.Gotham
    Version.TextSize = 14
    Version.TextColor3 = Theme.TextSecondary
    Version.BackgroundTransparency = 1
    Version.Size = UDim2.new(1, 0, 0, 24)
    Version.Position = UDim2.new(0, 0, 0.4, 80)
    Version.TextYAlignment = Enum.TextYAlignment.Center
    -- Optional: Add a spinner or animated icon here
    -- Hide main UI until loading finishes
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 500, 0, 400)
    Main.Position = UDim2.new(0.5, -250, 0.5, -200)
    Main.BackgroundColor3 = Theme.Panel
    Main.BackgroundTransparency = Theme.Transparency
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    Main.Visible = not loadingEnabled
    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = Theme.CornerRadius
    if Theme.Shadow then
        local shadow = Instance.new("ImageLabel", Main)
        shadow.Image = "rbxassetid://1316045217"
        shadow.Size = UDim2.new(1, 30, 1, 30)
        shadow.Position = UDim2.new(0, -15, 0, -15)
        shadow.BackgroundTransparency = 1
        shadow.ImageTransparency = 0.7
        shadow.ZIndex = 0
    end
    if loadingEnabled then
        Main.Visible = false
        LoadingScreen.BackgroundTransparency = 1
        Title.TextTransparency = 1
        Subtitle.TextTransparency = 1
        Version.TextTransparency = 1
        Tween(LoadingScreen, {BackgroundTransparency = Theme.Transparency}, 0.5)
        Tween(Title, {TextTransparency = 0}, 0.5)
        Tween(Subtitle, {TextTransparency = 0.2}, 0.5)
        Tween(Version, {TextTransparency = 0.2}, 0.5)
        task.spawn(function()
            task.wait(loadingDuration)
            Tween(Title, {TextTransparency = 1}, 0.4)
            Tween(Subtitle, {TextTransparency = 1}, 0.4)
            Tween(Version, {TextTransparency = 1}, 0.4)
            Tween(LoadingScreen, {BackgroundTransparency = 1}, 0.4)
            task.wait(0.45)
            LoadingScreen.Visible = false
            Main.Visible = true
        end)
    end
    MakeDraggable(Main)
    MakeResizable(Main, {X=320,Y=200}, {X=900,Y=700})

    -- Key System
    if config.KeySystem and config.KeySystem.Enabled then
        showKeySystem(config.KeySystem, function() Main.Visible = true end)
        Main.Visible = false
    end

    -- Topbar (Minimize/Maximize/Hide)
    local Topbar = Instance.new("Frame", Main)
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 38)
    Topbar.Position = UDim2.new(0, 0, 0, 0)
    Topbar.BackgroundColor3 = Theme.Background
    Topbar.BackgroundTransparency = Theme.Transparency + 0.05
    Topbar.BorderSizePixel = 0
    local TopbarCorner = Instance.new("UICorner", Topbar)
    TopbarCorner.CornerRadius = Theme.CornerRadius
    local TitleLabel = Instance.new("TextLabel", Topbar)
    TitleLabel.Text = config.Title or "ByteRise-UI"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -120, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    -- Button icons
    local function makeTopbarBtn(icon, name, pos)
        local btn = Instance.new("TextButton", Topbar)
        btn.Name = name
        btn.Text = icon
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.TextColor3 = Theme.TextSecondary
        btn.BackgroundColor3 = Theme.Panel
        btn.BackgroundTransparency = Theme.Transparency + 0.05
        btn.Size = UDim2.new(0, 32, 0, 32)
        btn.Position = UDim2.new(1, -36 * pos, 0.5, -16)
        btn.AnchorPoint = Vector2.new(0, 0)
        btn.AutoButtonColor = false
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = Theme.CornerRadius
        btn.ZIndex = 10
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.TextSecondary}, 0.15)
        end)
        return btn
    end
    local MinBtn = makeTopbarBtn("_", "Minimize", 3)
    local MaxBtn = makeTopbarBtn("□", "Maximize", 2)
    local HideBtn = makeTopbarBtn("✕", "Hide", 1)
    -- State
    local isMinimized, isHidden = false, false
    local origSize, origPos = Main.Size, Main.Position
    -- Minimize
    MinBtn.MouseButton1Click:Connect(function()
        if isMinimized or isHidden then return end
        isMinimized = true
        Tween(Main, {Size = UDim2.new(0, 500, 0, 38)}, 0.4)
        Tween(Main, {Position = UDim2.new(0.5, -250, 0.5, -19)}, 0.4)
        for _, child in ipairs(Main:GetChildren()) do
            if child ~= Topbar then child.Visible = false end
        end
    end)
    -- Maximize
    MaxBtn.MouseButton1Click:Connect(function()
        if not isMinimized or isHidden then return end
        isMinimized = false
        Tween(Main, {Size = origSize}, 0.4)
        Tween(Main, {Position = origPos}, 0.4)
        for _, child in ipairs(Main:GetChildren()) do
            if child ~= Topbar then child.Visible = true end
        end
    end)
    -- Hide
    local function doHide()
        if isHidden then return end
        isHidden = true
        Tween(Main, {BackgroundTransparency = 1}, 0.4)
        Tween(Main, {Position = UDim2.new(0.5, -250, 1.2, 0)}, 0.5)
        task.wait(0.5)
        Main.Visible = false
    end
    local function doUnhide()
        if not isHidden then return end
        isHidden = false
        Main.Visible = true
        Tween(Main, {BackgroundTransparency = Theme.Transparency}, 0.4)
        Tween(Main, {Position = origPos}, 0.5)
    end
    HideBtn.MouseButton1Click:Connect(doHide)
    -- Hotkey (RightShift)
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if isHidden then doUnhide() else doHide() end
        end
    end)

    -- Tab bar (side)
    local TabBar = Instance.new("Frame", Main)
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(0, 120, 1, 0)
    TabBar.Position = UDim2.new(0, 0, 0, 0)
    TabBar.BackgroundColor3 = Theme.Background
    TabBar.BackgroundTransparency = Theme.Transparency + 0.05
    local TabBarCorner = Instance.new("UICorner", TabBar)
    TabBarCorner.CornerRadius = Theme.CornerRadius
    local TabList = Instance.new("UIListLayout", TabBar)
    TabList.Padding = UDim.new(0, 4)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Main content area (scrollable)
    local Content = Instance.new("Frame", Main)
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -120, 1, 0)
    Content.Position = UDim2.new(0, 120, 0, 0)
    Content.BackgroundTransparency = 1
    local Scroll = Instance.new("ScrollingFrame", Content)
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 6
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local ScrollLayout = Instance.new("UIListLayout", Scroll)
    ScrollLayout.Padding = UDim.new(0, 8)
    ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Tabs management
    local tabs = {}
    local currentTab
    local currentTabFrame
    local function switchTab(tabName)
        for name, tab in pairs(tabs) do
            if name == tabName then
                if currentTabFrame and currentTabFrame ~= tab.Frame then
                    -- Animated transition: fade out old, fade in new
                    Tween(currentTabFrame, {BackgroundTransparency = 1}, 0.2)
                    Tween(tab.Frame, {BackgroundTransparency = 0}, 0.2)
                    task.wait(0.2)
                    currentTabFrame.Visible = false
                end
                tab.Frame.Visible = true
                tab.Frame.BackgroundTransparency = 0
                tab.Button.BackgroundColor3 = Theme.Accent
                currentTabFrame = tab.Frame
            else
                tab.Frame.Visible = false
                tab.Button.BackgroundColor3 = Theme.Panel
            end
        end
        currentTab = tabName
    end
    local window = {}
    local Flags = {}
    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Title or ("Tab"..tostring(#tabs+1))
        -- Tab button
        local tabBtn = Instance.new("TextButton", TabBar)
        tabBtn.Text = (tabConfig.Icon and getIcon(tabConfig.Icon) .. "  " or "") .. tabName
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 16
        tabBtn.TextColor3 = Theme.Text
        tabBtn.BackgroundColor3 = Theme.Panel
        tabBtn.BackgroundTransparency = Theme.Transparency
        tabBtn.Size = UDim2.new(1, -8, 0, 36)
        tabBtn.AutoButtonColor = false
        local tabBtnCorner = Instance.new("UICorner", tabBtn)
        tabBtnCorner.CornerRadius = Theme.CornerRadius
        -- Tab content frame
        local tabFrame = Instance.new("Frame", Scroll)
        tabFrame.Name = tabName
        tabFrame.BackgroundTransparency = 1
        tabFrame.Size = UDim2.new(1, 0, 0, 0)
        tabFrame.AutomaticSize = Enum.AutomaticSize.Y
        tabFrame.Visible = false
        -- Tab switching
        tabBtn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end)
        -- First tab auto-select
        if not currentTab then
            switchTab(tabName)
        end
        -- Tab API (reuse previous element implementations, but parent to tabFrame)
        local tab = {}
        -- For each element, add Flag support:
        local function registerFlag(flag, api, getValue, setValue)
            if flag then
                Flags[flag] = {api = api, get = getValue, set = setValue}
            end
        end
        -- Button (no value to save)
        function tab:Button(btnConfig)
            btnConfig = btnConfig or {}
            local btn = Instance.new("TextButton")
            btn.Name = btnConfig.Title or "Button"
            if btnConfig.IconId then
                local icon = Instance.new("ImageLabel", btn)
                icon.Image = "rbxassetid://"..tostring(btnConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 8, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                btn.Text = "    "..(btnConfig.Title or "Button")
            else
                btn.Text = (btnConfig.Icon and getIcon(btnConfig.Icon) .. "  " or "") .. (btnConfig.Title or "Button")
            end
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 16
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Accent
            btn.BackgroundTransparency = Theme.Transparency
            btn.Size = UDim2.new(1, 0, 0, 44)
            btn.AutoButtonColor = false
            btn.Parent = tabFrame
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local shadow = Instance.new("ImageLabel", btn)
            shadow.Image = "rbxassetid://1316045217"
            shadow.Size = UDim2.new(1, 12, 1, 12)
            shadow.Position = UDim2.new(0, -6, 0, -6)
            shadow.BackgroundTransparency = 1
            shadow.ImageTransparency = 0.85
            shadow.ZIndex = 0
            btn.ZIndex = 1
            -- Hover effect
            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Accent2}, 0.15)
                shadow.ImageTransparency = 0.7
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.15)
                shadow.ImageTransparency = 0.85
            end)
            -- Click effect
            btn.MouseButton1Down:Connect(function()
                Tween(btn, {BackgroundTransparency = 0.25}, 0.08)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, {BackgroundTransparency = Theme.Transparency}, 0.08)
            end)
            btn.MouseButton1Click:Connect(function(x, y)
                playUISound()
                local mx, my = x or btn.AbsoluteSize.X/2, y or btn.AbsoluteSize.Y/2
                rippleEffect(btn, mx, my)
                if typeof(btnConfig.Callback) == "function" then
                    local ok, err = pcall(btnConfig.Callback)
                    if not ok then showErrorFeedback(btn, err) end
                end
            end)
            -- Mobile support: Touch
            btn.TouchTap:Connect(function()
                if typeof(btnConfig.Callback) == "function" then
                    pcall(btnConfig.Callback)
                end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newTitle)
                if btnConfig.IconId then
                    btn.Text = "    "..(newTitle or "Button")
                else
                    btn.Text = (btnConfig.Icon and getIcon(btnConfig.Icon) .. "  " or "") .. (newTitle or "Button")
                end
            end
            function api:Disable()
                btn.AutoButtonColor = false
                btn.TextColor3 = Theme.TextSecondary
                btn.BackgroundColor3 = Theme.Panel
                btn.Active = false
            end
            function api:Enable()
                btn.AutoButtonColor = true
                btn.TextColor3 = Theme.Text
                btn.BackgroundColor3 = Theme.Accent
                btn.Active = true
            end
            registerFlag(btnConfig.Flag, api, function() return nil end, function() end)
            return api
        end
        -- Toggle (WindUI style)
        function tab:Toggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            if toggleConfig.IconId then
                local icon = Instance.new("ImageLabel", holder)
                icon.Image = "rbxassetid://"..tostring(toggleConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 0, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                label.Text = "    "..(toggleConfig.Title or "Toggle")
            else
                label.Text = (toggleConfig.Icon and getIcon(toggleConfig.Icon) .. "  " or "") .. (toggleConfig.Title or "Toggle")
            end
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            -- Toggle switch
            local toggle = Instance.new("Frame", holder)
            toggle.Size = UDim2.new(0, 52, 0, 28)
            toggle.Position = UDim2.new(1, -60, 0.5, -14)
            toggle.BackgroundColor3 = Theme.Border
            toggle.BackgroundTransparency = Theme.Transparency
            local corner = Instance.new("UICorner", toggle)
            corner.CornerRadius = UDim.new(0, 14)
            -- Shadow
            local shadow = Instance.new("ImageLabel", toggle)
            shadow.Image = "rbxassetid://1316045217"
            shadow.Size = UDim2.new(1, 10, 1, 10)
            shadow.Position = UDim2.new(0, -5, 0, -5)
            shadow.BackgroundTransparency = 1
            shadow.ImageTransparency = 0.85
            shadow.ZIndex = 0
            toggle.ZIndex = 1
            -- On fill
            local on = Instance.new("Frame", toggle)
            on.Size = UDim2.new(0.5, 0, 1, 0)
            on.BackgroundColor3 = Theme.Accent
            on.BackgroundTransparency = 0
            on.Name = "On"
            local onCorner = Instance.new("UICorner", on)
            onCorner.CornerRadius = UDim.new(0, 14)
            -- Knob
            local knob = Instance.new("Frame", toggle)
            knob.Size = UDim2.new(0, 24, 0, 24)
            knob.Position = UDim2.new(toggleConfig.Default and 0.5 or 0, 2, 0.5, -12)
            knob.BackgroundColor3 = Theme.Text
            knob.BackgroundTransparency = 0
            local knobCorner = Instance.new("UICorner", knob)
            knobCorner.CornerRadius = UDim.new(1, 0)
            -- State
            local value = toggleConfig.Default and true or false
            local function updateUI()
                if value then
                    Tween(knob, {Position = UDim2.new(0.5, 2, 0.5, -12)}, 0.15)
                    Tween(on, {Size = UDim2.new(1, 0, 1, 0)}, 0.15)
                else
                    Tween(knob, {Position = UDim2.new(0, 2, 0.5, -12)}, 0.15)
                    Tween(on, {Size = UDim2.new(0.5, 0, 1, 0)}, 0.15)
                end
            end
            updateUI()
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    playUISound()
                    value = not value
                    updateUI()
                    if typeof(toggleConfig.Callback) == "function" then
                        local ok, err = pcall(toggleConfig.Callback, value)
                        if not ok then showErrorFeedback(holder, err) end
                    end
                end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newValue)
                value = newValue and true or false
                updateUI()
                if typeof(toggleConfig.Callback) == "function" then
                    pcall(toggleConfig.Callback, value)
                end
            end
            function api:Disable()
                holder.Active = false
                label.TextColor3 = Theme.TextSecondary
                toggle.BackgroundColor3 = Theme.Panel
            end
            function api:Enable()
                holder.Active = true
                label.TextColor3 = Theme.Text
                toggle.BackgroundColor3 = Theme.Border
            end
            registerFlag(toggleConfig.Flag, api, function() return value end, api.Set)
            return api
        end
        -- Slider (WindUI style)
        function tab:Slider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 56)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            if sliderConfig.IconId then
                local icon = Instance.new("ImageLabel", holder)
                icon.Image = "rbxassetid://"..tostring(sliderConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 0, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                label.Text = "    "..(sliderConfig.Title or "Slider")
            else
                label.Text = (sliderConfig.Icon and getIcon(sliderConfig.Icon) .. "  " or "") .. (sliderConfig.Title or "Slider")
            end
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 0.5, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            local valueBox = Instance.new("TextBox", holder)
            valueBox.Text = tostring(sliderConfig.Default or sliderConfig.Min or 0)
            valueBox.Font = Enum.Font.GothamBold
            valueBox.TextSize = 14
            valueBox.TextColor3 = Theme.Text
            valueBox.BackgroundColor3 = Theme.Panel
            valueBox.BackgroundTransparency = Theme.Transparency
            valueBox.Size = UDim2.new(0, 56, 0, 28)
            valueBox.Position = UDim2.new(1, -64, 0, 0)
            valueBox.ClearTextOnFocus = false
            local valueCorner = Instance.new("UICorner", valueBox)
            valueCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local valueShadow = Instance.new("ImageLabel", valueBox)
            valueShadow.Image = "rbxassetid://1316045217"
            valueShadow.Size = UDim2.new(1, 8, 1, 8)
            valueShadow.Position = UDim2.new(0, -4, 0, -4)
            valueShadow.BackgroundTransparency = 1
            valueShadow.ImageTransparency = 0.85
            valueShadow.ZIndex = 0
            valueBox.ZIndex = 1
            -- Slider bar
            local sliderBar = Instance.new("Frame", holder)
            sliderBar.Size = UDim2.new(1, -72, 0, 10)
            sliderBar.Position = UDim2.new(0, 0, 1, -18)
            sliderBar.BackgroundColor3 = Theme.Border
            sliderBar.BackgroundTransparency = Theme.Transparency
            local barCorner = Instance.new("UICorner", sliderBar)
            barCorner.CornerRadius = UDim.new(1, 0)
            -- Shadow
            local barShadow = Instance.new("ImageLabel", sliderBar)
            barShadow.Image = "rbxassetid://1316045217"
            barShadow.Size = UDim2.new(1, 8, 1, 8)
            barShadow.Position = UDim2.new(0, -4, 0, -4)
            barShadow.BackgroundTransparency = 1
            barShadow.ImageTransparency = 0.9
            barShadow.ZIndex = 0
            sliderBar.ZIndex = 1
            -- Fill
            local fill = Instance.new("Frame", sliderBar)
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BackgroundTransparency = 0
            local fillCorner = Instance.new("UICorner", fill)
            fillCorner.CornerRadius = UDim.new(1, 0)
            -- Knob
            local knob = Instance.new("Frame", sliderBar)
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = UDim2.new(0, -9, 0.5, -9)
            knob.BackgroundColor3 = Theme.Text
            knob.BackgroundTransparency = 0
            local knobCorner = Instance.new("UICorner", knob)
            knobCorner.CornerRadius = UDim.new(1, 0)
            -- Knob shadow
            local knobShadow = Instance.new("ImageLabel", knob)
            knobShadow.Image = "rbxassetid://1316045217"
            knobShadow.Size = UDim2.new(1, 8, 1, 8)
            knobShadow.Position = UDim2.new(0, -4, 0, -4)
            knobShadow.BackgroundTransparency = 1
            knobShadow.ImageTransparency = 0.85
            knobShadow.ZIndex = 0
            knob.ZIndex = 1
            -- State
            local min, max = sliderConfig.Min or 0, sliderConfig.Max or 100
            local value = sliderConfig.Default or min
            local function setSlider(val)
                value = math.clamp(val, min, max)
                local percent = (value - min) / (max - min)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                knob.Position = UDim2.new(percent, -9, 0.5, -9)
                valueBox.Text = tostring(value)
            end
            setSlider(value)
            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    playUISound()
                    local mouse = game:GetService("UserInputService"):GetMouseLocation().X
                    local abs = sliderBar.AbsolutePosition.X
                    local width = sliderBar.AbsoluteSize.X
                    local percent = math.clamp((mouse - abs) / width, 0, 1)
                    setSlider(math.floor((min + (max - min) * percent) + 0.5))
                    if typeof(sliderConfig.Callback) == "function" then
                        local ok, err = pcall(sliderConfig.Callback, value)
                        if not ok then showErrorFeedback(holder, err) end
                    end
                end
            end)
            valueBox.FocusLost:Connect(function()
                local num = tonumber(valueBox.Text)
                if num then
                    setSlider(num)
                    if typeof(sliderConfig.Callback) == "function" then
                        pcall(sliderConfig.Callback, value)
                    end
                else
                    valueBox.Text = tostring(value)
                end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newValue)
                setSlider(newValue)
                if typeof(sliderConfig.Callback) == "function" then
                    pcall(sliderConfig.Callback, value)
                end
            end
            function api:Disable()
                holder.Active = false
                label.TextColor3 = Theme.TextSecondary
                sliderBar.BackgroundColor3 = Theme.Panel
            end
            function api:Enable()
                holder.Active = true
                label.TextColor3 = Theme.Text
                sliderBar.BackgroundColor3 = Theme.Border
            end
            registerFlag(sliderConfig.Flag, api, function() return value end, api.Set)
            return api
        end
        -- Dropdown (single-select and multi-select)
        function tab:Dropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            if dropdownConfig.IconId then
                local icon = Instance.new("ImageLabel", holder)
                icon.Image = "rbxassetid://"..tostring(dropdownConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 0, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                label.Text = "    "..(dropdownConfig.Title or "Dropdown")
            else
                label.Text = (dropdownConfig.Icon and getIcon(dropdownConfig.Icon) .. "  " or "") .. (dropdownConfig.Title or "Dropdown")
            end
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            local box = Instance.new("TextButton", holder)
            box.Text = "--"
            box.Font = Enum.Font.GothamBold
            box.TextSize = 14
            box.TextColor3 = Theme.Text
            box.BackgroundColor3 = Theme.Panel
            box.BackgroundTransparency = Theme.Transparency
            box.Size = UDim2.new(0, 140, 0, 32)
            box.Position = UDim2.new(1, -148, 0.5, -16)
            box.AutoButtonColor = false
            local boxCorner = Instance.new("UICorner", box)
            boxCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local boxShadow = Instance.new("ImageLabel", box)
            boxShadow.Image = "rbxassetid://1316045217"
            boxShadow.Size = UDim2.new(1, 8, 1, 8)
            boxShadow.Position = UDim2.new(0, -4, 0, -4)
            boxShadow.BackgroundTransparency = 1
            boxShadow.ImageTransparency = 0.85
            boxShadow.ZIndex = 0
            box.ZIndex = 1
            local open = false
            local menu
            local values = dropdownConfig.Values or {}
            local multi = dropdownConfig.Multi or false
            local allowNone = dropdownConfig.AllowNone or false
            local locked = dropdownConfig.Locked or false
            local selected = multi and (dropdownConfig.Default or {}) or (dropdownConfig.Default or values[1])
            local function updateBoxText()
                if multi then
                    if #selected == 0 then box.Text = "--" else box.Text = table.concat(selected, ", ") end
                else
                    box.Text = selected or "--"
                end
            end
            updateBoxText()
            local function closeMenu()
                if menu then
                    Tween(menu, {BackgroundTransparency = 1}, 0.15)
                    Tween(menu, {GroupTransparency = 1}, 0.15)
                    task.wait(0.15)
                    menu:Destroy()
                    menu = nil
                end
                open = false
            end
            local function openMenu()
                if open or locked then return end
                open = true
                menu = Instance.new("Frame")
                menu.Size = UDim2.new(0, 140, 0, math.min(6, #values)*32 + 8)
                menu.Position = UDim2.new(1, -148, 1, 0)
                menu.BackgroundColor3 = Theme.Panel
                menu.BackgroundTransparency = 1
                menu.BorderSizePixel = 0
                menu.ZIndex = 10
                menu.Parent = holder
                local menuCorner = Instance.new("UICorner", menu)
                menuCorner.CornerRadius = Theme.CornerRadius
                local scroll = Instance.new("ScrollingFrame", menu)
                scroll.Size = UDim2.new(1, 0, 1, 0)
                scroll.CanvasSize = UDim2.new(0, 0, 0, #values*32)
                scroll.BackgroundTransparency = 1
                scroll.ScrollBarThickness = 6
                scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                scroll.ZIndex = 11
                scroll.BorderSizePixel = 0
                local layout = Instance.new("UIListLayout", scroll)
                layout.Padding = UDim.new(0, 2)
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                for _, v in ipairs(values) do
                    local opt = Instance.new("TextButton", scroll)
                    opt.Text = v
                    opt.Font = Enum.Font.Gotham
                    opt.TextSize = 14
                    opt.TextColor3 = Theme.Text
                    opt.BackgroundColor3 = Theme.Panel
                    opt.BackgroundTransparency = Theme.Transparency
                    opt.Size = UDim2.new(1, 0, 0, 28)
                    opt.AutoButtonColor = false
                    local optCorner = Instance.new("UICorner", opt)
                    optCorner.CornerRadius = Theme.CornerRadius
                    if multi then
                        if table.find(selected, v) then
                            opt.BackgroundColor3 = Theme.Accent
                            opt.TextColor3 = Theme.Text
                        end
                    else
                        if selected == v then
                            opt.BackgroundColor3 = Theme.Accent
                            opt.TextColor3 = Theme.Text
                        end
                    end
                    opt.MouseButton1Click:Connect(function()
                        playUISound()
                        if multi then
                            if table.find(selected, v) then
                                if allowNone or #selected > 1 then
                                    for i, val in ipairs(selected) do
                                        if val == v then table.remove(selected, i) break end
                                    end
                                end
                            else
                                table.insert(selected, v)
                            end
                        else
                            selected = v
                            closeMenu()
                        end
                        updateBoxText()
                        if typeof(dropdownConfig.Callback) == "function" then
                            local ok, err = pcall(dropdownConfig.Callback, multi and selected or selected)
                            if not ok then showErrorFeedback(opt, err) end
                        end
                        if not multi then closeMenu() end
                    end)
                end
                Tween(menu, {BackgroundTransparency = Theme.Transparency}, 0.15)
                Tween(menu, {GroupTransparency = 0}, 0.15)
            end
            box.MouseButton1Click:Connect(function()
                playUISound()
                if open then closeMenu() else openMenu() end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newValue)
                if multi then
                    selected = type(newValue) == "table" and newValue or {newValue}
                else
                    selected = newValue
                end
                updateBoxText()
                if typeof(dropdownConfig.Callback) == "function" then
                    pcall(dropdownConfig.Callback, multi and selected or selected)
                end
            end
            function api:SetSelected(newTable)
                if multi then
                    selected = newTable
                    updateBoxText()
                    if typeof(dropdownConfig.Callback) == "function" then
                        pcall(dropdownConfig.Callback, selected)
                    end
                end
            end
            function api:UpdateValues(newValues)
                values = newValues
                if multi then
                    selected = {}
                else
                    selected = values[1]
                end
                updateBoxText()
            end
            function api:Disable()
                holder.Active = false
                label.TextColor3 = Theme.TextSecondary
                box.TextColor3 = Theme.TextSecondary
                box.BackgroundColor3 = Theme.Panel
            end
            function api:Enable()
                holder.Active = true
                label.TextColor3 = Theme.Text
                box.TextColor3 = Theme.Text
                box.BackgroundColor3 = Theme.Panel
            end
            registerFlag(dropdownConfig.Flag, api, function() return multi and selected or selected end, api.Set)
            return api
        end
        -- Input (WindUI style, enhanced)
        function tab:Input(inputConfig)
            inputConfig = inputConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, inputConfig.Type == "Textarea" and 64 or 44)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            if inputConfig.IconId then
                local icon = Instance.new("ImageLabel", holder)
                icon.Image = "rbxassetid://"..tostring(inputConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 0, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                label.Text = "    "..(inputConfig.Title or "Input")
            else
                label.Text = (inputConfig.Icon and getIcon(inputConfig.Icon) .. "  " or "") .. (inputConfig.Title or "Input")
            end
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            local box = Instance.new(inputConfig.Type == "Textarea" and "TextBox" or "TextBox", holder)
            box.Text = inputConfig.Default or ""
            box.Font = Enum.Font.GothamBold
            box.TextSize = 14
            box.TextColor3 = Theme.Text
            box.BackgroundColor3 = Theme.Panel
            box.BackgroundTransparency = Theme.Transparency
            box.Size = UDim2.new(0, 140, 0, inputConfig.Type == "Textarea" and 48 or 32)
            box.Position = UDim2.new(1, -148, 0.5, inputConfig.Type == "Textarea" and -20 or -16)
            box.ClearTextOnFocus = inputConfig.ClearTextOnFocus or false
            box.PlaceholderText = inputConfig.Placeholder or "Enter text..."
            box.MultiLine = inputConfig.Type == "Textarea"
            box.TextWrapped = inputConfig.Type == "Textarea"
            box.TextYAlignment = inputConfig.Type == "Textarea" and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
            local boxCorner = Instance.new("UICorner", box)
            boxCorner.CornerRadius = Theme.CornerRadius
            -- Icon support
            if inputConfig.InputIcon then
                local icon = Instance.new("TextLabel", holder)
                icon.Text = getIcon(inputConfig.InputIcon)
                icon.Font = Enum.Font.GothamBold
                icon.TextSize = 18
                icon.TextColor3 = Theme.Accent
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.new(0, 24, 0, 24)
                icon.Position = UDim2.new(1, -180, 0.5, -12)
                icon.TextXAlignment = Enum.TextXAlignment.Center
                icon.TextYAlignment = Enum.TextYAlignment.Center
            end
            -- Shadow
            local boxShadow = Instance.new("ImageLabel", box)
            boxShadow.Image = "rbxassetid://1316045217"
            boxShadow.Size = UDim2.new(1, 8, 1, 8)
            boxShadow.Position = UDim2.new(0, -4, 0, -4)
            boxShadow.BackgroundTransparency = 1
            boxShadow.ImageTransparency = 0.85
            boxShadow.ZIndex = 0
            box.ZIndex = 1
            -- Locked support
            if inputConfig.Locked then
                box.TextEditable = false
                box.TextColor3 = Theme.TextSecondary
            end
            box.FocusLost:Connect(function(enter)
                if enter and typeof(inputConfig.Callback) == "function" then
                    local ok, err = pcall(inputConfig.Callback, box.Text)
                    if not ok then showErrorFeedback(box, err) end
                end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newValue)
                box.Text = newValue
                if typeof(inputConfig.Callback) == "function" then
                    pcall(inputConfig.Callback, newValue)
                end
            end
            function api:Lock()
                box.TextEditable = false
                box.TextColor3 = Theme.TextSecondary
            end
            function api:Unlock()
                box.TextEditable = true
                box.TextColor3 = Theme.Text
            end
            function api:Disable()
                holder.Active = false
                label.TextColor3 = Theme.TextSecondary
                box.TextColor3 = Theme.TextSecondary
                box.TextEditable = false
            end
            function api:Enable()
                holder.Active = true
                label.TextColor3 = Theme.Text
                box.TextColor3 = Theme.Text
                box.TextEditable = true
            end
            registerFlag(inputConfig.Flag, api, function() return box.Text end, api.Set)
            return api
        end
        -- Keybind (WindUI style, enhanced, with HoldToInteract)
        function tab:Keybind(keybindConfig)
            keybindConfig = keybindConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            if keybindConfig.IconId then
                local icon = Instance.new("ImageLabel", holder)
                icon.Image = "rbxassetid://"..tostring(keybindConfig.IconId)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(0, 0, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.ZIndex = 2
                label.Text = "    "..(keybindConfig.Title or "Keybind")
            else
                label.Text = (keybindConfig.Icon and getIcon(keybindConfig.Icon) .. "  " or "") .. (keybindConfig.Title or "Keybind")
            end
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            local box = Instance.new("TextButton", holder)
            box.Text = keybindConfig.Default or "None"
            box.Font = Enum.Font.GothamBold
            box.TextSize = 14
            box.TextColor3 = Theme.Text
            box.BackgroundColor3 = Theme.Panel
            box.BackgroundTransparency = Theme.Transparency
            box.Size = UDim2.new(0, 100, 0, 32)
            box.Position = UDim2.new(1, -108, 0.5, -16)
            box.AutoButtonColor = false
            local boxCorner = Instance.new("UICorner", box)
            boxCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local boxShadow = Instance.new("ImageLabel", box)
            boxShadow.Image = "rbxassetid://1316045217"
            boxShadow.Size = UDim2.new(1, 8, 1, 8)
            boxShadow.Position = UDim2.new(0, -4, 0, -4)
            boxShadow.BackgroundTransparency = 1
            boxShadow.ImageTransparency = 0.85
            boxShadow.ZIndex = 0
            box.ZIndex = 1
            local locked = keybindConfig.Locked or false
            local canChange = keybindConfig.CanChange ~= false
            local value = keybindConfig.Default or "F"
            local picking = false
            local holdToInteract = keybindConfig.HoldToInteract or false
            local UIS = game:GetService("UserInputService")
            local function setKey(newKey)
                value = newKey
                box.Text = newKey
                if typeof(keybindConfig.Callback) == "function" then
                    pcall(keybindConfig.Callback, newKey)
                end
            end
            box.MouseButton1Click:Connect(function()
                playUISound()
                if locked or not canChange or picking then return end
                picking = true
                box.Text = "..."
                local event
                event = UIS.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    local key
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode.Name
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        key = "MouseLeft"
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        key = "MouseRight"
                    end
                    if key then
                        setKey(key)
                        picking = false
                        if event then event:Disconnect() end
                    end
                end)
            end)
            UIS.InputBegan:Connect(function(input, gpe)
                if gpe or locked then return end
                local key = value
                if input.KeyCode.Name == key or (key == "MouseLeft" and input.UserInputType == Enum.UserInputType.MouseButton1) or (key == "MouseRight" and input.UserInputType == Enum.UserInputType.MouseButton2) then
                    if holdToInteract then
                        if typeof(keybindConfig.Callback) == "function" then
                            local ok, err = pcall(keybindConfig.Callback, true)
                            if not ok then showErrorFeedback(box, err) end
                        end
                        local ended
                        ended = UIS.InputEnded:Connect(function(endInput)
                            if (endInput.KeyCode.Name == key or (key == "MouseLeft" and endInput.UserInputType == Enum.UserInputType.MouseButton1) or (key == "MouseRight" and endInput.UserInputType == Enum.UserInputType.MouseButton2)) then
                                if typeof(keybindConfig.Callback) == "function" then
                                    local ok, err = pcall(keybindConfig.Callback, false)
                                    if not ok then showErrorFeedback(box, err) end
                                end
                                ended:Disconnect()
                            end
                        end)
                    else
                        if typeof(keybindConfig.Callback) == "function" then
                            local ok, err = pcall(keybindConfig.Callback, key)
                            if not ok then showErrorFeedback(box, err) end
                        end
                    end
                end
            end)
            -- Set/Update API
            local api = {}
            function api:Set(newValue)
                setKey(newValue)
            end
            function api:Lock()
                locked = true
                box.TextColor3 = Theme.TextSecondary
            end
            function api:Unlock()
                locked = false
                box.TextColor3 = Theme.Text
            end
            function api:Disable()
                holder.Active = false
                label.TextColor3 = Theme.TextSecondary
                box.TextColor3 = Theme.TextSecondary
                box.AutoButtonColor = false
            end
            function api:Enable()
                holder.Active = true
                label.TextColor3 = Theme.Text
                box.TextColor3 = Theme.Text
                box.AutoButtonColor = true
            end
            registerFlag(keybindConfig.Flag, api, function() return value end, api.Set)
            return api
        end
        -- Advanced Colorpicker (WindUI+ style)
        function tab:AdvancedColorpicker(colorConfig)
            colorConfig = colorConfig or {}
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 56)
            holder.Parent = tabFrame
            local label = Instance.new("TextLabel", holder)
            label.Text = (colorConfig.Icon and getIcon(colorConfig.Icon) .. "  " or "") .. (colorConfig.Title or "Colorpicker")
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Theme.Text
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            local box = Instance.new("TextButton", holder)
            box.Text = " "
            box.BackgroundColor3 = colorConfig.Default or Theme.Accent
            box.BackgroundTransparency = Theme.Transparency
            box.Size = UDim2.new(0, 36, 0, 32)
            box.Position = UDim2.new(1, -44, 0.5, -16)
            box.AutoButtonColor = false
            local boxCorner = Instance.new("UICorner", box)
            boxCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local boxShadow = Instance.new("ImageLabel", box)
            boxShadow.Image = "rbxassetid://1316045217"
            boxShadow.Size = UDim2.new(1, 8, 1, 8)
            boxShadow.Position = UDim2.new(0, -4, 0, -4)
            boxShadow.BackgroundTransparency = 1
            boxShadow.ImageTransparency = 0.85
            boxShadow.ZIndex = 0
            box.ZIndex = 1
            -- Advanced color picker popup
            box.MouseButton1Click:Connect(function()
                local popup = Instance.new("Frame")
                popup.Size = UDim2.new(0, 260, 0, 220)
                popup.Position = UDim2.new(0, box.AbsolutePosition.X, 0, box.AbsolutePosition.Y + 36)
                popup.BackgroundColor3 = Theme.Panel
                popup.BackgroundTransparency = Theme.Transparency
                popup.BorderSizePixel = 0
                popup.ZIndex = 20
                popup.Parent = game:GetService("CoreGui")
                local popupCorner = Instance.new("UICorner", popup)
                popupCorner.CornerRadius = Theme.CornerRadius
                -- Palette
                local palette = Instance.new("ImageLabel", popup)
                palette.Image = "rbxassetid://6020299385" -- rainbow palette
                palette.Size = UDim2.new(0, 180, 0, 100)
                palette.Position = UDim2.new(0, 8, 0, 8)
                palette.BackgroundTransparency = 1
                palette.ZIndex = 21
                -- Alpha slider
                local alphaLabel = Instance.new("TextLabel", popup)
                alphaLabel.Text = "Opacity"
                alphaLabel.Font = Enum.Font.Gotham
                alphaLabel.TextSize = 13
                alphaLabel.TextColor3 = Theme.TextSecondary
                alphaLabel.BackgroundTransparency = 1
                alphaLabel.Size = UDim2.new(0, 60, 0, 18)
                alphaLabel.Position = UDim2.new(0, 8, 0, 116)
                local alphaBar = Instance.new("Frame", popup)
                alphaBar.Size = UDim2.new(0, 180, 0, 10)
                alphaBar.Position = UDim2.new(0, 8, 0, 136)
                alphaBar.BackgroundColor3 = Theme.Border
                alphaBar.BackgroundTransparency = Theme.Transparency
                local alphaCorner = Instance.new("UICorner", alphaBar)
                alphaCorner.CornerRadius = UDim.new(1, 0)
                local alphaFill = Instance.new("Frame", alphaBar)
                alphaFill.Size = UDim2.new(1, 0, 1, 0)
                alphaFill.BackgroundColor3 = Theme.Accent
                alphaFill.BackgroundTransparency = 0
                local alphaFillCorner = Instance.new("UICorner", alphaFill)
                alphaFillCorner.CornerRadius = UDim.new(1, 0)
                -- Hex input
                local hexBox = Instance.new("TextBox", popup)
                hexBox.Text = "#" .. string.format("%02X%02X%02X", box.BackgroundColor3.R*255, box.BackgroundColor3.G*255, box.BackgroundColor3.B*255)
                hexBox.Font = Enum.Font.GothamBold
                hexBox.TextSize = 14
                hexBox.TextColor3 = Theme.Text
                hexBox.BackgroundColor3 = Theme.Panel
                hexBox.BackgroundTransparency = Theme.Transparency
                hexBox.Size = UDim2.new(0, 100, 0, 28)
                hexBox.Position = UDim2.new(0, 8, 0, 170)
                local hexCorner = Instance.new("UICorner", hexBox)
                hexCorner.CornerRadius = Theme.CornerRadius
                -- Preview
                local preview = Instance.new("Frame", popup)
                preview.Size = UDim2.new(0, 36, 0, 28)
                preview.Position = UDim2.new(0, 120, 0, 170)
                preview.BackgroundColor3 = box.BackgroundColor3
                preview.BackgroundTransparency = 0
                local previewCorner = Instance.new("UICorner", preview)
                previewCorner.CornerRadius = Theme.CornerRadius
                -- OK button
                local ok = Instance.new("TextButton", popup)
                ok.Text = "OK"
                ok.Font = Enum.Font.GothamBold
                ok.TextSize = 14
                ok.TextColor3 = Theme.Text
                ok.BackgroundColor3 = Theme.Accent
                ok.BackgroundTransparency = Theme.Transparency
                ok.Size = UDim2.new(0, 56, 0, 28)
                ok.Position = UDim2.new(1, -64, 1, -36)
                ok.ZIndex = 21
                local okCorner = Instance.new("UICorner", ok)
                okCorner.CornerRadius = Theme.CornerRadius
                -- State
                local r, g, b, a = box.BackgroundColor3.R, box.BackgroundColor3.G, box.BackgroundColor3.B, 1
                local function updateColor()
                    local color = Color3.new(r, g, b)
                    box.BackgroundColor3 = color
                    preview.BackgroundColor3 = color
                    hexBox.Text = "#" .. string.format("%02X%02X%02X", r*255, g*255, b*255)
                end
                palette.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mouse = game:GetService("UserInputService")
                        local conn
                        local function update(inputPos)
                            local relX = math.clamp((inputPos.X - palette.AbsolutePosition.X)/palette.AbsoluteSize.X, 0, 1)
                            local relY = math.clamp((inputPos.Y - palette.AbsolutePosition.Y)/palette.AbsoluteSize.Y, 0, 1)
                            local color = Color3.fromHSV(relX, 1, 1-relY)
                            r, g, b = color.R, color.G, color.B
                            updateColor()
                        end
                        update(mouse:GetMouseLocation())
                        conn = mouse.InputChanged:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                                update(mouse:GetMouseLocation())
                            end
                        end)
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                if conn then conn:Disconnect() end
                            end
                        end)
                    end
                end)
                alphaBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mouse = game:GetService("UserInputService")
                        local conn
                        local function update(inputPos)
                            local rel = math.clamp((inputPos.X - alphaBar.AbsolutePosition.X)/alphaBar.AbsoluteSize.X, 0, 1)
                            a = rel
                            alphaFill.Size = UDim2.new(rel, 0, 1, 0)
                        end
                        update(mouse:GetMouseLocation())
                        conn = mouse.InputChanged:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                                update(mouse:GetMouseLocation())
                            end
                        end)
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                if conn then conn:Disconnect() end
                            end
                        end)
                    end
                end)
                hexBox.FocusLost:Connect(function(enter)
                    if enter then
                        local hex = hexBox.Text:gsub("#","")
                        if #hex == 6 then
                            local nr = tonumber(hex:sub(1,2),16)
                            local ng = tonumber(hex:sub(3,4),16)
                            local nb = tonumber(hex:sub(5,6),16)
                            if nr and ng and nb then
                                r, g, b = nr/255, ng/255, nb/255
                                updateColor()
                            end
                        end
                    end
                end)
                ok.MouseButton1Click:Connect(function()
                    popup:Destroy()
                    if typeof(colorConfig.Callback) == "function" then
                        pcall(colorConfig.Callback, Color3.new(r,g,b), a)
                    end
                end)
            end)
            return holder
        end
        -- Search Bar (WindUI+ style)
        function tab:SearchBar(searchConfig)
            searchConfig = searchConfig or {}
            local bar = Instance.new("TextBox")
            bar.Text = searchConfig.Placeholder or "Search..."
            bar.Font = Enum.Font.Gotham
            bar.TextSize = 14
            bar.TextColor3 = Theme.TextSecondary
            bar.BackgroundColor3 = Theme.Panel
            bar.BackgroundTransparency = Theme.Transparency
            bar.Size = UDim2.new(1, 0, 0, 32)
            bar.Parent = tabFrame
            local barCorner = Instance.new("UICorner", bar)
            barCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local barShadow = Instance.new("ImageLabel", bar)
            barShadow.Image = "rbxassetid://1316045217"
            barShadow.Size = UDim2.new(1, 8, 1, 8)
            barShadow.Position = UDim2.new(0, -4, 0, -4)
            barShadow.BackgroundTransparency = 1
            barShadow.ImageTransparency = 0.85
            barShadow.ZIndex = 0
            bar.ZIndex = 1
            -- Filtering logic (hides elements that don't match)
            bar:GetPropertyChangedSignal("Text"):Connect(function()
                local query = bar.Text:lower()
                for _, child in ipairs(tabFrame:GetChildren()) do
                    if child:IsA("Frame") and child ~= bar then
                        local label = child:FindFirstChildWhichIsA("TextLabel")
                        if label and label.Text then
                            child.Visible = (query == "" or label.Text:lower():find(query, 1, true))
                        end
                    end
                end
            end)
            return bar
        end
        -- Notification (WindUI style, animated)
        function tab:Notification(notifConfig)
            notifConfig = notifConfig or {}
            local gui = (function()
                local parent = getBestGuiParent("ByteRise-UI-Notifications")
                local g = parent:FindFirstChild("ByteRise-UI-Notifications")
                if not g then
                    g = Instance.new("ScreenGui")
                    g.Name = "ByteRise-UI-Notifications"
                    g.Parent = parent
                end
                return g
            end)()
            local notif = Instance.new("Frame", gui)
            notif.Size = UDim2.new(0, 280, 0, 68)
            notif.Position = UDim2.new(1, -300, 1, -100)
            notif.BackgroundColor3 = Theme.Panel
            notif.BackgroundTransparency = Theme.Transparency
            notif.BorderSizePixel = 0
            notif.AnchorPoint = Vector2.new(0,1)
            notif.ZIndex = 50
            local notifCorner = Instance.new("UICorner", notif)
            notifCorner.CornerRadius = Theme.CornerRadius
            -- Shadow
            local notifShadow = Instance.new("ImageLabel", notif)
            notifShadow.Image = "rbxassetid://1316045217"
            notifShadow.Size = UDim2.new(1, 12, 1, 12)
            notifShadow.Position = UDim2.new(0, -6, 0, -6)
            notifShadow.BackgroundTransparency = 1
            notifShadow.ImageTransparency = 0.85
            notifShadow.ZIndex = 0
            notif.ZIndex = 1
            if notifConfig.Icon then
                local icon = Instance.new("TextLabel", notif)
                icon.Text = getIcon(notifConfig.Icon)
                icon.Font = Enum.Font.GothamBold
                icon.TextSize = 22
                icon.TextColor3 = Theme.Accent
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.new(0, 32, 0, 32)
                icon.Position = UDim2.new(0, 8, 0, 18)
                icon.TextXAlignment = Enum.TextXAlignment.Center
                icon.TextYAlignment = Enum.TextYAlignment.Center
            end
            local title = Instance.new("TextLabel", notif)
            title.Text = notifConfig.Title or "Notification"
            title.Font = Enum.Font.GothamBold
            title.TextSize = 16
            title.TextColor3 = Theme.Text
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, -48, 0, 24)
            title.Position = UDim2.new(0, 44, 0, 8)
            title.TextXAlignment = Enum.TextXAlignment.Left
            local content = Instance.new("TextLabel", notif)
            content.Text = notifConfig.Content or ""
            content.Font = Enum.Font.Gotham
            content.TextSize = 14
            content.TextColor3 = Theme.TextSecondary
            content.BackgroundTransparency = 1
            content.Size = UDim2.new(1, -48, 0, 24)
            content.Position = UDim2.new(0, 44, 0, 32)
            content.TextXAlignment = Enum.TextXAlignment.Left
            notif.Position = notif.Position + UDim2.new(0, 0, 0, 40)
            Tween(notif, {Position = UDim2.new(1, -300, 1, -100)}, 0.3)
            task.spawn(function()
                task.wait(notifConfig.Duration or 3)
                Tween(notif, {Position = notif.Position + UDim2.new(0, 0, 0, 40)}, 0.3)
                task.wait(0.3)
                notif:Destroy()
            end)
            return notif
        end
        -- Section (multi-column, nested)
        function tab:Section(sectionConfig)
            sectionConfig = sectionConfig or {}
            local columns = sectionConfig.Columns or 1
            local section = Instance.new("Frame", tabFrame)
            section.BackgroundColor3 = Theme.Panel
            section.BackgroundTransparency = Theme.Transparency + 0.05
            section.Size = UDim2.new(1, 0, 0, 32 * columns)
            local sectionCorner = Instance.new("UICorner", section)
            sectionCorner.CornerRadius = Theme.CornerRadius
            local label = Instance.new("TextLabel", section)
            label.Text = sectionConfig.Title or "Section"
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextColor3 = Theme.TextSecondary
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -16, 0, 24)
            label.Position = UDim2.new(0, 8, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            -- Columns
            local columnFrames = {}
            for i = 1, columns do
                local col = Instance.new("Frame", section)
                col.BackgroundTransparency = 1
                col.Size = UDim2.new(1 / columns, -8, 1, -32)
                col.Position = UDim2.new((i - 1) / columns, 4, 0, 28)
                col.Name = "Column"..i
                table.insert(columnFrames, col)
            end
            -- API: next elements added go to columns in round-robin
            local colIndex = 1
            local origAdd = tabFrame.AddChild or tabFrame.AddChildAt
            function section:AddElement(element)
                columnFrames[colIndex]:AddChild(element)
                colIndex = colIndex % columns + 1
            end
            -- Set/Update API
            local api = {}
            function api:Set(newTitle)
                label.Text = newTitle
            end
            return api
        end
        -- Ripple effect utility
        local function rippleEffect(parent, x, y)
            local ripple = Instance.new("Frame", parent)
            ripple.BackgroundColor3 = Theme.TextSecondary
            ripple.BackgroundTransparency = 0.7
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.Position = UDim2.new(0, x, 0, y)
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.ZIndex = 100
            local corner = Instance.new("UICorner", ripple)
            corner.CornerRadius = UDim.new(1, 0)
            Tween(ripple, {Size = UDim2.new(0, parent.AbsoluteSize.X * 2, 0, parent.AbsoluteSize.Y * 2), BackgroundTransparency = 1}, 0.5)
            task.spawn(function()
                task.wait(0.5)
                ripple:Destroy()
            end)
        end
        -- HelpPopup (modal)
        function tab:HelpPopup(popupConfig)
            popupConfig = popupConfig or {}
            local gui = Instance.new("Frame", game:GetService("CoreGui"))
            gui.Size = UDim2.new(0.4, 0, 0.3, 0)
            gui.Position = UDim2.new(0.3, 0, 0.35, 0)
            gui.BackgroundColor3 = Theme.Panel
            gui.BackgroundTransparency = Theme.Transparency
            gui.ZIndex = 200
            local corner = Instance.new("UICorner", gui)
            corner.CornerRadius = Theme.CornerRadius
            local title = Instance.new("TextLabel", gui)
            title.Text = popupConfig.Title or "Help"
            title.Font = Enum.Font.GothamBold
            title.TextSize = 20
            title.TextColor3 = Theme.Text
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0, 40)
            title.Position = UDim2.new(0, 0, 0, 0)
            local content = Instance.new("TextLabel", gui)
            content.Text = popupConfig.Content or "Info goes here."
            content.Font = Enum.Font.Gotham
            content.TextSize = 16
            content.TextColor3 = Theme.TextSecondary
            content.BackgroundTransparency = 1
            content.Size = UDim2.new(1, -32, 1, -56)
            content.Position = UDim2.new(0, 16, 0, 44)
            content.TextWrapped = true
            content.TextYAlignment = Enum.TextYAlignment.Top
            local close = Instance.new("TextButton", gui)
            close.Text = "Close"
            close.Font = Enum.Font.GothamBold
            close.TextSize = 16
            close.TextColor3 = Theme.Text
            close.BackgroundColor3 = Theme.Accent
            close.BackgroundTransparency = Theme.Transparency
            close.Size = UDim2.new(0, 80, 0, 32)
            close.Position = UDim2.new(1, -88, 1, -40)
            local closeCorner = Instance.new("UICorner", close)
            closeCorner.CornerRadius = Theme.CornerRadius
            close.MouseButton1Click:Connect(function()
                gui:Destroy()
            end)
            return gui
        end
        -- Tab (side tab, for now just returns self)
        function tab:Tab(tabConfig)
            return self
        end
        -- Tooltip (hover info)
        function tab:Tooltip(target, text)
            if not target or not text then return end
            local tip
            target.MouseEnter:Connect(function()
                tip = Instance.new("TextLabel")
                tip.Text = text
                tip.Font = Enum.Font.Gotham
                tip.TextSize = 13
                tip.TextColor3 = Theme.Text
                tip.BackgroundColor3 = Theme.Panel
                tip.BackgroundTransparency = Theme.Transparency + 0.05
                tip.Size = UDim2.new(0, #text*8+16, 0, 28)
                tip.Position = UDim2.new(0, target.AbsolutePosition.X, 0, target.AbsolutePosition.Y - 32)
                tip.AnchorPoint = Vector2.new(0,1)
                tip.ZIndex = 100
                local tipCorner = Instance.new("UICorner", tip)
                tipCorner.CornerRadius = Theme.CornerRadius
                tip.Parent = game:GetService("CoreGui")
            end)
            target.MouseLeave:Connect(function()
                if tip then tip:Destroy() tip = nil end
            end)
        end
        -- Label (single-line info)
        function tab:Label(labelConfig)
            labelConfig = labelConfig or {}
            local label = Instance.new("TextLabel", tabFrame)
            label.Text = labelConfig.Text or "Label"
            label.Font = Enum.Font.Gotham
            label.TextSize = 15
            label.TextColor3 = Theme.TextSecondary
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, 28)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextWrapped = false
            -- Set/Update API
            local api = {}
            function api:Set(newText)
                label.Text = newText
            end
            registerFlag(labelConfig.Flag, api, function() return label.Text end, api.Set)
            return api
        end
        -- Paragraph (multi-line info)
        function tab:Paragraph(parConfig)
            parConfig = parConfig or {}
            local holder = Instance.new("Frame", tabFrame)
            holder.BackgroundTransparency = 1
            holder.Size = UDim2.new(1, 0, 0, 64)
            local title = Instance.new("TextLabel", holder)
            title.Text = parConfig.Title or "Paragraph"
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.TextColor3 = Theme.Text
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0, 22)
            title.Position = UDim2.new(0, 0, 0, 0)
            title.TextXAlignment = Enum.TextXAlignment.Left
            local content = Instance.new("TextLabel", holder)
            content.Text = parConfig.Content or "Paragraph content goes here."
            content.Font = Enum.Font.Gotham
            content.TextSize = 14
            content.TextColor3 = Theme.TextSecondary
            content.BackgroundTransparency = 1
            content.Size = UDim2.new(1, 0, 0, 38)
            content.Position = UDim2.new(0, 0, 0, 24)
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextWrapped = true
            -- Set/Update API
            local api = {}
            function api:Set(newPar)
                title.Text = newPar.Title or title.Text
                content.Text = newPar.Content or content.Text
            end
            registerFlag(parConfig.Flag, api, function() return {Title = title.Text, Content = content.Text} end, api.Set)
            return api
        end
        -- Save reference
        tab.Frame = tabFrame
        tab.Button = tabBtn
        tabs[tabName] = tab
        return tab
    end
    -- Config save/load
    function window:SaveConfig(name)
        local data = {}
        for flag, entry in pairs(Flags) do
            data[flag] = entry.get()
        end
        saveConfig(name or (config.Title or "ByteRise-UI"), data)
    end
    function window:LoadConfig(name)
        local data = loadConfig(name or (config.Title or "ByteRise-UI"))
        if not data then return end
        for flag, value in pairs(data) do
            if Flags[flag] then
                Flags[flag].set(value)
            end
        end
    end
    return window
end

--// ELEMENTS (PLACEHOLDERS) //--
-- Button, Toggle, Slider, Dropdown, Input, Keybind, Colorpicker, Notification, etc.
-- (To be filled in next steps)

--// KEY SYSTEM, NOTIFICATION SYSTEM, ETC. (PLACEHOLDERS) //--

--// API EXPOSURE //--
return ByteRiseUI

--[[
EXAMPLE USAGE:

local ByteRiseUI = loadstring(game:HttpGet("https://yourdomain.com/ByteRiseUI.lua"))()

local window = ByteRiseUI:CreateWindow({
    Title = "My Script",
    KeySystem = {
        Enabled = true,
        Keys = {"1234", "5678"},
        Note = "Get your key from discord.gg/xyz"
    }
})

-- Create main tab with various UI elements
local mainTab = window:CreateTab({Title = "Main"})

-- Section for input elements
local inputSection = mainTab:Section({Title = "Input Elements", Columns = 2})

-- Single select dropdown
local weaponSelect = inputSection:Dropdown({
    Title = "Select Weapon",
    Values = {"AK-47", "M4A1", "AWP", "Desert Eagle"},
    Default = "AK-47",
    Callback = function(value)
        print("Selected weapon:", value)
    end
})

-- Toggle with icon
local godMode = inputSection:Toggle({
    Title = "God Mode",
    Default = false,
    IconId = "rbxassetid://6031068436", -- Shield icon
    Callback = function(enabled)
        print("God Mode:", enabled and "Enabled" or "Disabled")
    end
})

-- Slider for numeric input
local walkSpeed = inputSection:Slider({
    Title = "Walk Speed",
    Min = 16,
    Max = 100,
    Default = 32,
    Suffix = " studs",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- Keybind for quick actions
local sprintKey = inputSection:Keybind({
    Title = "Sprint Key",
    Default = "LeftShift",
    Callback = function()
        print("Sprinting!")
    end
})

-- Color picker
local auraColor = inputSection:AdvancedColorpicker({
    Title = "Aura Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("Aura color set to:", color)
    end
})

-- Multi-select dropdown
local lootDrops = inputSection:Dropdown({
    Title = "Loot Drops",
    Values = {"Health", "Ammo", "Armor", "Credits", "Power-ups"},
    Multi = true,
    Default = {"Health", "Ammo"},
    Callback = function(selected)
        print("Loot drops enabled:", table.concat(selected, ", "))
    end
})

-- Text input
local playerName = inputSection:Input({
    Title = "Player Name",
    Placeholder = "Enter player name...",
    Callback = function(text)
        print("Searching for:", text)
    end
})

-- Create a second section for actions
local actionSection = mainTab:Section({Title = "Actions"})

-- Button with icon
actionSection:Button({
    Title = "Teleport to Base",
    IconId = "rbxassetid://6031075931", -- Teleport icon
    Callback = function()
        print("Teleporting to base...")
        -- Add teleport logic here
    end
})

-- Toggle with rich text
local nightVision = actionSection:Toggle({
    Title = "<b>Night Vision</b> <font color='#888888'>(N)</font>",
    RichText = true,
    Default = false,
    Callback = function(enabled)
        print("Night Vision:", enabled and "ON" or "OFF")
    end
})

-- Bind a key to night vision
actionSection:Keybind({
    Title = "Night Vision Toggle",
    Default = "N",
    Callback = function()
        nightVision:Set(not nightVision:Get())
    end
})

-- Create a settings tab
local settingsTab = window:CreateTab({Title = "Settings"})

-- Save/Load settings
settingsTab:Button({
    Title = "Save Settings",
    Callback = function()
        window:SaveConfig("my_settings")
        window:Notify({
            Title = "Settings",
            Content = "Settings saved successfully!",
            Duration = 3
        })
    end
})

settingsTab:Button({
    Title = "Load Settings",
    Callback = function()
        window:LoadConfig("my_settings")
        window:Notify({
            Title = "Settings",
            Content = "Settings loaded!",
            Duration = 3
        })
    end
})

-- Show a notification when the UI loads
window:Notify({
    Title = "Welcome",
    Content = "UI Loaded Successfully!",
    Duration = 5
})
]]