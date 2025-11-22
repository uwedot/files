local cloneref = (cloneref or function(x) return x end)

local TS  = cloneref(game:GetService("TweenService"))
local UIS = cloneref(game:GetService("UserInputService"))
local CG  = cloneref(game:GetService("CoreGui"))

local C3new, U2new, V2new = Color3.new, UDim2.new, Vector2.new
local EFG = Enum.Font.Gotham
local EES = Enum.EasingStyle
local EED = Enum.EasingDirection

local COLORS = {
    Background     = C3new(30/255, 30/255, 30/255),
    DarkBackground = C3new(24/255, 24/255, 24/255),
    TabBackground  = C3new(33/255, 33/255, 33/255),
    Button         = C3new(185/255, 13/255, 68/255),
    ButtonHover    = C3new(134/255, 10/255, 49/255),
    Accent         = C3new(232/255, 17/255, 85/255),
    White          = C3new(1, 1, 1),
    Gray           = C3new(72/255, 72/255, 72/255),
    LightGray      = C3new(199/255, 199/255, 199/255),
    DarkGray       = C3new(35/255, 35/255, 35/255),
    MediumGray     = C3new(40/255, 40/255, 40/255),
    InputBackground= C3new(45/255, 45/255, 45/255),
}

local function create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function rounded(parent, r)
    return create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local TWEEN = {
    Fast   = TweenInfo.new(0.10, EES.Quad, EED.Out),
    Normal = TweenInfo.new(0.20, EES.Quad, EED.Out),
    Slow   = TweenInfo.new(0.30, EES.Quad, EED.Out),
}

local function tween(target, speed, props)
    return TS:Create(target, TWEEN[speed or "Normal"], props or {})
end

local function tweenPlay(target, speed, props)
    tween(target, speed, props):Play()
end

local function onHover(gui, overProps, outProps, speed)
    gui.MouseEnter:Connect(function() tweenPlay(gui, speed or "Normal", overProps) end)
    gui.MouseLeave:Connect(function() tweenPlay(gui, speed or "Normal", outProps) end)
end

local function bindListAutoSize(holder, list, extraY)
    extraY = extraY or 15
    local function update()
        local y = (list.AbsoluteContentSize and list.AbsoluteContentSize.Y or 0) + extraY
        if holder:IsA("ScrollingFrame") then
            holder.CanvasSize = U2new(0, 0, 0, y)
        else
            holder.Size = U2new(1, 0, 0, y)
        end
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    if holder.ChildAdded then holder.ChildAdded:Connect(update) end
    if holder.ChildRemoved then holder.ChildRemoved:Connect(update) end
    task.defer(update)
end

pcall(function()
    local existing = CG:FindFirstChild("Sentinel")
    if existing then existing:Destroy() end
end)

local Library = {}

function Library:Window(title)
    local ui = create("ScreenGui", {
        Name = "Sentinel",
        Parent = CG,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    local Main = create("Frame", {
        Name = "Main",
        Parent = ui,
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Position = U2new(0.5, -235, 0.5, -141),
        Size = U2new(0, 470, 0, 283),
        Active = true, Selectable = true, Draggable = true,
    })
    rounded(Main, 6)

    create("ImageLabel", {
        Name = "Shadow",
        Parent = Main,
        AnchorPoint = V2new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = U2new(0.5, 0, 0.5, 0),
        Size = U2new(1, 30, 1, 30),
        ZIndex = 0,
        Image = "rbxassetid://5554236805",
        ImageColor3 = C3new(0,0,0),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
    })

    local tabs = create("Frame", {
        Name = "tabs",
        Parent = Main,
        BackgroundColor3 = COLORS.TabBackground,
        BorderSizePixel = 0,
        Position = U2new(0, 0, 0, 35),
        Size = U2new(0, 122, 1, -35),
    })
    rounded(tabs, 6)
    create("Frame", {
        Name = "Cover",
        Parent = tabs,
        AnchorPoint = V2new(1, 0.5),
        BackgroundColor3 = COLORS.TabBackground,
        BorderSizePixel = 0,
        Position = U2new(1, 0, 0.5, 0),
        Size = U2new(0, 5, 1, 0),
    })

    local Top = create("Frame", {
        Name = "Top",
        Parent = Main,
        BackgroundColor3 = COLORS.DarkBackground,
        BorderSizePixel = 0,
        Size = U2new(1, 0, 0, 34),
    })
    rounded(Top, 6)
    create("Frame", {
        Name = "Cover",
        Parent = Top,
        AnchorPoint = V2new(0.5, 1),
        BackgroundColor3 = COLORS.DarkBackground,
        BorderSizePixel = 0,
        Position = U2new(0.5, 0, 1, 0),
        Size = U2new(1, 0, 0, 4),
    })
    create("Frame", {
        Name = "Line",
        Parent = Top,
        AnchorPoint = V2new(0.5, 1),
        BackgroundColor3 = COLORS.White,
        BackgroundTransparency = 0.92,
        Position = U2new(0.5, 0, 1, 1),
        Size = U2new(1, 0, 0, 1),
    })
    create("ImageLabel", {
        Name = "Logo",
        Parent = Top,
        AnchorPoint = V2new(0, 0.5),
        BackgroundTransparency = 1,
        Position = U2new(0, 4, 0.5, 0),
        Size = U2new(0, 26, 0, 30),
        Image = "http://www.roblox.com/asset/?id=7803241868",
        ImageColor3 = COLORS.Accent,
    })

    local Close = create("ImageButton", {
        Name = "Close",
        Parent = Top,
        AnchorPoint = V2new(1, 0.5),
        BackgroundTransparency = 1,
        Position = U2new(1, -6, 0.5, 0),
        Size = U2new(0, 20, 0, 20),
        Image = "http://www.roblox.com/asset/?id=7755372427",
        ImageColor3 = COLORS.LightGray,
        ScaleType = Enum.ScaleType.Crop,
        AutoButtonColor = false,
    })
    Close.MouseButton1Click:Connect(function() ui:Destroy() end)
    onHover(Close, { ImageColor3 = COLORS.White }, { ImageColor3 = C3new(166/255,166/255,166/255) })

    create("TextLabel", {
        Name = "GameName",
        Parent = Top,
        AnchorPoint = V2new(0, 0.5),
        BackgroundTransparency = 1,
        Position = U2new(0, 32, 0.5, 0),
        Size = U2new(0, 165, 0, 22),
        Font = EFG,
        Text = title or "Game Name",
        TextColor3 = COLORS.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local Pages = create("Frame", {
        Name = "Pages",
        Parent = Main,
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Position = U2new(0, 130, 0, 42),
        Size = U2new(1, -138, 1, -50),
        ClipsDescendants = true,
    })

    local TabsContainer = create("ScrollingFrame", {
        Name = "TabsContainer",
        Parent = tabs,
        BackgroundTransparency = 1,
        Size = U2new(1, 0, 1, 0),
        CanvasSize = U2new(0,0,0,0),
        ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1,
        BorderSizePixel = 0,
        ScrollingEnabled = true,
        ClipsDescendants = true,
    })
    local TabsListLayout = create("UIListLayout", {
        Name = "TabsList",
        Parent = TabsContainer,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })
    create("UIPadding", {
        Parent = TabsContainer,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
    })
    bindListAutoSize(TabsContainer, TabsListLayout, 15)

    local DeviceType = UIS.TouchEnabled and "Mobile" or "PC"
    local MobileToggleButton
    local uitoggled = false
    if DeviceType == "Mobile" then
        MobileToggleButton = create("TextButton", {
            Name = "MobileToggle",
            Parent = ui,
            Size = U2new(0, 40, 0, 40),
            Position = U2new(1, -50, 0, 10),
            AnchorPoint = V2new(1, 0),
            BackgroundColor3 = COLORS.TabBackground,
            Text = "−",
            TextColor3 = COLORS.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = 20,
            AutoButtonColor = false,
        })
        rounded(MobileToggleButton, 6)
        local Stroke = create("UIStroke", {
            Parent = MobileToggleButton,
            Color = COLORS.Accent,
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })

        do
            local dragging, dragInput, dragStart, startPos
            MobileToggleButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging, dragStart, startPos = true, input.Position, MobileToggleButton.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            MobileToggleButton.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
            end)
            UIS.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    local delta = input.Position - dragStart
                    MobileToggleButton.Position = U2new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end

        onHover(MobileToggleButton, { BackgroundColor3 = COLORS.MediumGray }, { BackgroundColor3 = COLORS.TabBackground })
        MobileToggleButton.MouseEnter:Connect(function() tweenPlay(Stroke, "Normal", { Thickness = 3 }) end)
        MobileToggleButton.MouseLeave:Connect(function() tweenPlay(Stroke, "Normal", { Thickness = 2 }) end)

        MobileToggleButton.MouseButton1Click:Connect(function()
            uitoggled = not uitoggled
            Main.Visible = not uitoggled
            MobileToggleButton.Text = uitoggled and "+" or "−"
            tweenPlay(MobileToggleButton, "Normal", {
                BackgroundColor3 = uitoggled and COLORS.Accent or COLORS.TabBackground
            })
        end)
    end

    local Tabs = {}
    local firstTab = true

    function Tabs:Tab(tabTitle)
        local TabButton = create("TextButton", {
            Name = "TabButton",
            Parent = TabsContainer,
            BackgroundColor3 = COLORS.Accent,
            BackgroundTransparency = 1,
            Size = U2new(1, -12, 0, 30),
            AutoButtonColor = false,
            Font = EFG,
            Text = tabTitle or "Home",
            TextColor3 = COLORS.Gray,
            TextSize = 14,
        })
        rounded(TabButton, 6)

        local Page = create("ScrollingFrame", {
            Name = "Page",
            Parent = Pages,
            Visible = false,
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = U2new(1, 0, 1, 0),
            CanvasPosition = V2new(0, 0),
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            ScrollingEnabled = true,
            ClipsDescendants = true,
        })
        local PageListLayout = create("UIListLayout", {
            Parent = Page,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        create("UIPadding", {
            Parent = Page,
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
        })
        bindListAutoSize(Page, PageListLayout, 15)

        if firstTab then
            Page.Visible = true
            TabButton.BackgroundTransparency = 0.6
            TabButton.TextColor3 = COLORS.White
            firstTab = false
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, v in ipairs(Pages:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            Page.Visible = true
            for _, v in ipairs(TabsContainer:GetChildren()) do
                if v.Name == "TabButton" then
                    tweenPlay(v, "Normal", { BackgroundTransparency = 1, TextColor3 = COLORS.Gray })
                end
            end
            tweenPlay(TabButton, "Normal", { BackgroundTransparency = 0.6, TextColor3 = COLORS.White })
        end)

        local TabFunctions = {}

        function TabFunctions:Button(text, callback)
            callback = callback or function() end
            local Button = create("TextButton", {
                Name = "Button",
                Text = text or "Button",
                Parent = Page,
                BackgroundColor3 = COLORS.Button,
                BorderSizePixel = 0,
                Size = U2new(1, -6, 0, 34),
                AutoButtonColor = false,
                Font = EFG,
                TextColor3 = COLORS.White,
                TextSize = 14,
            })
            rounded(Button, 6)
            onHover(Button, { BackgroundColor3 = COLORS.ButtonHover }, { BackgroundColor3 = COLORS.Button })
            Button.MouseButton1Click:Connect(function() pcall(callback) end)
        end

        function TabFunctions:Toggle(text, value, callback)
            local toggled = not not value
            callback = callback or function() end

            local Toggle = create("TextButton", {
                Name = "Toggle",
                Parent = Page,
                BackgroundColor3 = COLORS.DarkGray,
                Size = U2new(1, -6, 0, 34),
                AutoButtonColor = false,
                Text = "",
            })
            rounded(Toggle, 6)

            create("TextLabel", {
                Name = "Title",
                Parent = Toggle,
                BackgroundTransparency = 1,
                Position = U2new(0, 8, 0, 0),
                Size = U2new(1, -6, 1, 0),
                Font = EFG,
                Text = text or "Toggle",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local ToggleFrame = create("Frame", {
                Name = "Toggle",
                Parent = Toggle,
                AnchorPoint = V2new(1, 0.5),
                BackgroundColor3 = COLORS.ButtonHover,
                BackgroundTransparency = toggled and 0 or 1,
                BorderSizePixel = 0,
                Position = U2new(1, -8, 0.5, 0),
                Size = U2new(0, 14, 0, 14),
            })
            create("UIStroke", {
                Parent = ToggleFrame,
                LineJoinMode = Enum.LineJoinMode.Round,
                Thickness = 2,
                Color = COLORS.ButtonHover,
            })
            local Checked = create("ImageLabel", {
                Name = "Checked",
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Position = U2new(-0.214285731, 0, -0.214285731, 0),
                Size = U2new(0, 20, 0, 20),
                Image = "http://www.roblox.com/asset/?id=7812909048",
                ImageTransparency = toggled and 0 or 1,
                ScaleType = Enum.ScaleType.Fit,
            })

            local function render()
                tweenPlay(ToggleFrame, "Fast", { BackgroundTransparency = toggled and 0 or 1 })
                tweenPlay(Checked,     "Fast", { ImageTransparency      = toggled and 0 or 1 })
                pcall(callback, toggled)
            end

            Toggle.MouseButton1Click:Connect(function()
                toggled = not toggled
                render()
            end)

            onHover(Toggle, { BackgroundColor3 = COLORS.MediumGray }, { BackgroundColor3 = COLORS.DarkGray })
            
            local ToggleFunctions = {}
            
            function ToggleFunctions:Set(state)
                if toggled ~= state then
                    toggled = state
                    render()
                end
            end
            
            render()
            
            return ToggleFunctions
        end

        function TabFunctions:Label(text)
            local lbl = create("TextLabel", {
                Parent = Page,
                BackgroundColor3 = COLORS.DarkGray,
                BorderSizePixel = 0,
                Size = U2new(1, -6, 0, 34),
                Font = EFG,
                Text = text or "Label",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            rounded(lbl, 6)
        end

        function TabFunctions:Slider(text, min, max, increment, callback)
            min, max = tonumber(min) or 0, tonumber(max) or 100
            increment = tonumber(increment) or 1
            callback = callback or function() end

            local m_abs, m_clamp, m_floor, m_log10, m_ceil, m_max, m_min = math.abs, math.clamp, math.floor, math.log10, math.ceil, math.max, math.min
            local fmt = string.format

            local current, lastFired = min, nil

            local Slider = create("Frame", {
                Name = "Slider",
                Parent = Page,
                BackgroundColor3 = COLORS.DarkGray,
                Size = U2new(1, -6, 0, 48),
            })
            rounded(Slider, 6)

            create("TextLabel", {
                Name = "Title",
                Parent = Slider,
                BackgroundTransparency = 1,
                Position = U2new(0, 8, 0, 0),
                Size = U2new(1, -6, 0, 34),
                Font = EFG,
                Text = text or "Slider",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local SliderClick = create("TextButton", {
                Name = "SliderClick",
                Parent = Slider,
                AnchorPoint = V2new(0.5, 1),
                BackgroundColor3 = C3new(52/255, 52/255, 52/255),
                Position = U2new(0.5, 0, 1, -8),
                Size = U2new(1, -12, 0, 6),
                AutoButtonColor = false,
                Text = "",
            })
            rounded(SliderClick, 6)

            local SliderDrag = create("Frame", {
                Name = "SliderDrag",
                Parent = SliderClick,
                BackgroundColor3 = COLORS.Button,
                Size = U2new(0, 0, 1, 0),
            })
            rounded(SliderDrag, 6)

            local Value = create("TextLabel", {
                Name = "Value",
                Parent = Slider,
                AnchorPoint = V2new(1, 0),
                BackgroundTransparency = 1,
                Position = U2new(1, -10, 0, 0),
                Size = U2new(1, 0, 0, 34),
                Font = EFG,
                Text = tostring(current),
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local function formatNumber(val)
                if m_abs(val) < 0.0001 and val ~= 0 then
                    return fmt("%.2e", val)
                end
                if m_abs(val) >= 10000 then
                    local s = tostring(m_floor(val))
                    local k = #s % 3; if k == 0 then k = 3 end
                    return s:sub(1, k) .. s:sub(k+1):gsub("(%d%d%d)", ",%1")
                end
                if increment < 1 then
                    local dp = m_max(1, m_ceil(-m_log10(increment))); dp = m_min(dp, 6)
                    local out = fmt("%." .. dp .. "f", val)
                    out = out:gsub("%.(%d-)0*$", function(dec) return dec == "" and "" or "." .. dec end)
                    return out:gsub("%.$", "")
                end
                return tostring(m_floor(val))
            end

            local function setValue(v, fire)
                v = m_clamp(v, min, max)
                if increment > 0 then v = m_floor(v / increment) * increment end
                current = v
                local t = (v - min) / (max - min)
                tweenPlay(SliderDrag, "Fast", { Size = U2new(t, 0, 1, 0) })
                Value.Text = formatNumber(v)
                if fire and v ~= lastFired then
                    pcall(callback, v)
                    lastFired = v
                end
            end

            local function startDrag(input)
                local function update(pos)
                    local x0 = SliderClick.AbsolutePosition.X
                    local w  = SliderClick.AbsoluteSize.X
                    local x  = m_clamp(pos.X - x0, 0, w)
                    local pct = x / w
                    setValue(min + pct * (max - min), false)
                end
                update(input.Position)
                local moveConn, endConn
                moveConn = UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                        update(i.Position)
                    end
                end)
                endConn = UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        if moveConn then moveConn:Disconnect() end
                        if endConn then endConn:Disconnect() end
                        setValue(current, true)
                    end
                end)
            end

            SliderClick.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    startDrag(input)
                end
            end)

            setValue(current, true)
        end

        function TabFunctions:Dropdown(text, list, callback)
            list = list or {}
            callback = callback or function() end

            local Dropdown = create("Frame", {
                Name = "Dropdown",
                Parent = Page,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Size = U2new(1, -6, 0, 34),
            })
            local DropdownListLayout = create("UIListLayout", {
                Parent = Dropdown,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
            })

            local dropped = false

            local Choose = create("Frame", {
                Name = "Choose",
                Parent = Dropdown,
                BackgroundColor3 = COLORS.DarkGray,
                BorderSizePixel = 0,
                Size = U2new(1, 0, 0, 34),
            })
            rounded(Choose, 6)

            local TitleLabel = create("TextLabel", {
                Name = "Title",
                Parent = Choose,
                BackgroundTransparency = 1,
                Position = U2new(0, 8, 0, 0),
                Size = U2new(1, -40, 1, 0),
                Font = EFG,
                Text = text or "Dropdown",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local arrow = create("ImageButton", {
                Name = "arrow",
                Parent = Choose,
                AnchorPoint = V2new(1, 0.5),
                BackgroundColor3 = COLORS.DarkGray,
                BackgroundTransparency = 0.5,
                Position = U2new(1, -6, 0.5, 0),
                Size = U2new(0, 28, 0, 28),
                ZIndex = 2,
                Image = "rbxassetid://3926307971",
                ImageColor3 = COLORS.ButtonHover,
                ImageRectOffset = V2new(324, 524),
                ImageRectSize = V2new(36, 36),
                ScaleType = Enum.ScaleType.Crop,
                AutoButtonColor = false,
            })
            rounded(arrow, 6)

            local OptionHolder = create("Frame", {
                Name = "OptionHolder",
                Parent = Dropdown,
                BackgroundColor3 = COLORS.DarkGray,
                BorderSizePixel = 0,
                Size = U2new(1, 0, 0, 0),
            })
            rounded(OptionHolder, 6)
            local OptionList = create("UIListLayout", {
                Name = "OptionList",
                Parent = OptionHolder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
            })
            create("UIPadding", { Parent = OptionHolder, PaddingTop = UDim.new(0, 8) })
            bindListAutoSize(OptionHolder, OptionList, 15)

            local function setDropped(state)
                dropped = state
                if dropped then
                    Dropdown:TweenSize(U2new(1, -7, 0, DropdownListLayout.AbsoluteContentSize.Y), EED.Out, EES.Quad, 0.15, true)
                    tweenPlay(arrow, "Normal", { Rotation = 180, BackgroundTransparency = 0.2 })
                else
                    tweenPlay(arrow, "Normal", { Rotation = 0, BackgroundTransparency = 0.5 })
                    Dropdown:TweenSize(U2new(1, -7, 0, 34), EED.Out, EES.Quad, 0.12, true)
                end
            end

            arrow.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    setDropped(not dropped)
                end
            end)
            onHover(arrow, { BackgroundTransparency = 0.3 }, { BackgroundTransparency = 0.5 })

            local function addOption(txt)
                local Option = create("TextButton", {
                    Name = "Option",
                    Parent = OptionHolder,
                    BackgroundColor3 = COLORS.ButtonHover,
                    BorderSizePixel = 0,
                    Size = U2new(1, -16, 0, 30),
                    AutoButtonColor = false,
                    Font = EFG,
                    Text = txt,
                    TextColor3 = COLORS.White,
                    TextSize = 14,
                })
                rounded(Option, 6)
                Option.MouseButton1Click:Connect(function()
                    pcall(callback, txt)
                    setDropped(false)
                    TitleLabel.Text = (text or "Dropdown") .. ": " .. txt
                end)
            end

            for _, v in ipairs(list) do addOption(v) end

            local DropdownFunc = {}

            function DropdownFunc:RefreshDropdown(newlist)
                setDropped(false)
                for _, v in ipairs(OptionHolder:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                for _, v in ipairs(newlist or {}) do addOption(v) end
            end

            return DropdownFunc
        end

        function TabFunctions:Textbox(text, placeholder, callback)
            callback = callback or function() end

            local Textbox = create("Frame", {
                Name = "Textbox",
                Parent = Page,
                BackgroundColor3 = COLORS.DarkGray,
                Size = U2new(1, -6, 0, 34),
            })
            rounded(Textbox, 6)

            create("TextLabel", {
                Name = "Title",
                Parent = Textbox,
                BackgroundTransparency = 1,
                Position = U2new(0, 8, 0, 0),
                Size = U2new(0.4, -8, 1, 0),
                Font = EFG,
                Text = text or "Textbox",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local InputBox = create("TextBox", {
                Name = "InputBox",
                Parent = Textbox,
                AnchorPoint = V2new(1, 0),
                BackgroundColor3 = COLORS.InputBackground,
                BackgroundTransparency = 0.5,
                Position = U2new(1, -8, 0, 4),
                Size = U2new(0.6, -12, 1, -8),
                Font = EFG,
                PlaceholderColor3 = C3new(178/255, 178/255, 178/255),
                PlaceholderText = placeholder or "Type here...",
                Text = "",
                TextColor3 = COLORS.White,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ClipsDescendants = true,
            })
            rounded(InputBox, 4)
            create("UIPadding", { Parent = InputBox, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

            onHover(Textbox, { BackgroundColor3 = COLORS.MediumGray }, { BackgroundColor3 = COLORS.DarkGray })
            onHover(InputBox, { BackgroundTransparency = 0.3 }, { BackgroundTransparency = 0.5 })

            InputBox.Focused:Connect(function()
                tweenPlay(InputBox, "Normal", { BackgroundColor3 = C3new(50/255, 50/255, 50/255), BackgroundTransparency = 0.2 })
            end)
            InputBox.FocusLost:Connect(function(enterPressed)
                tweenPlay(InputBox, "Normal", { BackgroundColor3 = COLORS.InputBackground, BackgroundTransparency = 0.5 })
                if enterPressed then pcall(callback, InputBox.Text) end
            end)
        end

        return TabFunctions
    end

    return Tabs
end

return Library