--!native

if getgenv().SimpleSpyExecuted and type(getgenv().SimpleSpyShutdown) == "function" then
	getgenv().SimpleSpyShutdown()
end

local realconfigs = {
	logcheckcaller = false,
	autoblock = false,
	funcEnabled = true,
	advancedinfo = false,
}

local configs = newproxy(true)
local configsmetatable = getmetatable(configs)
configsmetatable.__index = function(_, index) return realconfigs[index] end

local syn = syn
local oth = syn and syn.oth
local unhook = oth and oth.unhook
local hook = oth and oth.hook

local lower = string.lower
local byte = string.byte
local sfmt = string.format
local srep = string.rep
local ssub = string.sub
local running, resume, status, yield, create, close = coroutine.running, coroutine.resume, coroutine.status, coroutine.yield, coroutine.create, coroutine.close
local OldDebugId = game.GetDebugId
local info = debug.info
local IsA = game.IsA
local tostring, tonumber = tostring, tonumber
local delay, spawn = task.delay, task.spawn
local tinsert, tremove, tfind, tclear, tconcat = table.insert, table.remove, table.find, table.clear, table.concat
local mclamp, mmax, mfloor, mhuge = math.clamp, math.max, math.floor, math.huge
local clear = tclear

local function blankfunction(...) return ... end

local get_thread_identity = (syn and syn.get_thread_identity) or getidentity or getthreadidentity
local set_thread_identity = (syn and syn.set_thread_identity) or setidentity
local islclosure = islclosure or is_l_closure
local threadfuncs = (get_thread_identity and set_thread_identity) and true or false

local getinfo = getinfo or blankfunction
local getupvalues = getupvalues or debug.getupvalues or blankfunction
local getconstants = getconstants or debug.getconstants or blankfunction
local getcustomasset = getsynasset or getcustomasset
local getcallingscript = getcallingscript or blankfunction
local newcclosure = newcclosure or blankfunction
local clonefunction = clonefunction or blankfunction
local cloneref = cloneref or blankfunction
local request = request or (syn and syn.request)
local makewritable = makewriteable or function(tbl) setreadonly(tbl, false) end
local makereadonly = makereadonly or function(tbl) setreadonly(tbl, true) end
local isreadonly = isreadonly or table.isfrozen

local setclipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function(...)
	return ErrorPrompt("Attempted to set clipboard: " .. (...), true)
end

local hookmetamethod = hookmetamethod or (makewriteable and makereadonly and getrawmetatable) and function(obj, metamethod, func)
	local old = getrawmetatable(obj)
	if hookfunction then
		return hookfunction(old[metamethod], func)
	else
		local oldmm = old[metamethod]
		makewriteable(old)
		old[metamethod] = func
		makereadonly(old)
		return oldmm
	end
end

local function Create(instance, properties, children)
	local obj = Instance.new(instance)
	for i, v in next, properties or {} do
		obj[i] = v
		for _, child in next, children or {} do child.Parent = obj end
	end
	return obj
end

local function SafeGetService(service) return cloneref(game:GetService(service)) end

local function IsCyclicTable(tbl)
	local checked = {}
	local function Search(t)
		checked[t] = true
		for _, v in next, t do
			if type(v) == "table" then
				if checked[v] then return true end
				if Search(v) then return true end
			end
		end
	end
	return Search(tbl)
end

local function deepclone(args, copies)
	copies = copies or {}
	if type(args) == "table" then
		if copies[args] then return copies[args] end
		local copy = {}
		copies[args] = copy
		for i, v in next, args do copy[deepclone(i, copies)] = deepclone(v, copies) end
		return copy
	elseif typeof(args) == "Instance" then
		return cloneref(args)
	end
	return args
end

local function rawtostring(userdata)
	if type(userdata) == "table" or typeof(userdata) == "userdata" then
		local rawmeta = getrawmetatable(userdata)
		local cached = rawmeta and rawget(rawmeta, "__tostring")
		if cached then
			local wasreadonly = isreadonly(rawmeta)
			if wasreadonly then makewritable(rawmeta) end
			rawset(rawmeta, "__tostring", nil)
			local s = tostring(userdata)
			rawset(rawmeta, "__tostring", cached)
			if wasreadonly then makereadonly(rawmeta) end
			return s
		end
	end
	return tostring(userdata)
end

local CoreGui = SafeGetService("CoreGui")
local Players = SafeGetService("Players")
local RunService = SafeGetService("RunService")
local UserInputService = SafeGetService("UserInputService")
local TweenService = SafeGetService("TweenService")
local TextService = SafeGetService("TextService")
local http = SafeGetService("HttpService")
local GuiInset = game:GetService("GuiService"):GetGuiInset()

local function jsone(str) return http:JSONEncode(str) end
local function jsond(str) local ok, v = pcall(http.JSONDecode, http, str); return ok and v or ok end

function ErrorPrompt(Message, state)
	if getrenv then
		local EP = getrenv().require(CoreGui:WaitForChild("RobloxGui"):WaitForChild("Modules"):WaitForChild("ErrorPrompt"))
		local prompt = EP.new("Default", {HideErrorCode = true})
		local ErrorStorage = Create("ScreenGui", {Parent = CoreGui, ResetOnSpawn = false})
		local thread = state and running()
		prompt:setParent(ErrorStorage)
		prompt:setErrorTitle("Simple Spy V3 Error")
		prompt:updateButtons({{
			Text = "Proceed",
			Callback = function()
				prompt:_close()
				ErrorStorage:Destroy()
				if thread then resume(thread) end
			end,
			Primary = true
		}}, "Default")
		prompt:_open(Message)
		if thread then yield(thread) end
	else
		warn(Message)
	end
end

local Highlight = (isfile and loadfile and isfile("Highlight.lua") and loadfile("Highlight.lua")())
	or loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/SimpleSpyV3/highlight.lua"))()
local LazyFix = loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/SimpleSpyV3/DataToCode.lua"))()

-- GUI
local SimpleSpy3 = Create("ScreenGui", {ResetOnSpawn = false})
local Storage = Create("Folder", {})
local Background = Create("Frame", {Parent=SimpleSpy3,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,500,0,200),Size=UDim2.new(0,450,0,268)})
local LeftPanel = Create("Frame", {Parent=Background,BackgroundColor3=Color3.fromRGB(53,52,55),BorderSizePixel=0,Position=UDim2.new(0,0,0,19),Size=UDim2.new(0,131,0,249)})
local LogList = Create("ScrollingFrame", {Parent=LeftPanel,Active=true,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0,0,0,9),Size=UDim2.new(0,131,0,232),CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=4})
local UIListLayout = Create("UIListLayout", {Parent=LogList,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
local RightPanel = Create("Frame", {Parent=Background,BackgroundColor3=Color3.fromRGB(37,36,38),BorderSizePixel=0,Position=UDim2.new(0,131,0,19),Size=UDim2.new(0,319,0,249)})
local CodeBox = Create("Frame", {Parent=RightPanel,BackgroundColor3=Color3.new(0.0823529,0.0745098,0.0784314),BorderSizePixel=0,Size=UDim2.new(0,319,0,119)})
local ScrollingFrame = Create("ScrollingFrame", {Parent=RightPanel,Active=true,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0.5,-9),CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=4})
local UIGridLayout = Create("UIGridLayout", {Parent=ScrollingFrame,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,CellPadding=UDim2.new(0,0,0,0),CellSize=UDim2.new(0,94,0,27)})
local TopBar = Create("Frame", {Parent=Background,BackgroundColor3=Color3.fromRGB(37,35,38),BorderSizePixel=0,Size=UDim2.new(0,450,0,19)})
local Simple = Create("TextButton", {Parent=TopBar,BackgroundColor3=Color3.new(1,1,1),AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.new(0,5,0,0),Size=UDim2.new(0,57,0,18),Font=Enum.Font.SourceSansBold,Text="SimpleSpy",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
local CloseButton = Create("TextButton", {Parent=TopBar,BackgroundColor3=Color3.new(0.145098,0.141176,0.14902),BorderSizePixel=0,Position=UDim2.new(1,-19,0,0),Size=UDim2.new(0,19,0,19),Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.new(0,0,0),TextSize=14})
Create("ImageLabel", {Parent=CloseButton,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,9,0,9),Image="http://www.roblox.com/asset/?id=5597086202"})
local MaximizeButton = Create("TextButton", {Parent=TopBar,BackgroundColor3=Color3.new(0.145098,0.141176,0.14902),BorderSizePixel=0,Position=UDim2.new(1,-38,0,0),Size=UDim2.new(0,19,0,19),Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.new(0,0,0),TextSize=14})
Create("ImageLabel", {Parent=MaximizeButton,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,9,0,9),Image="http://www.roblox.com/asset/?id=5597108117"})
local MinimizeButton = Create("TextButton", {Parent=TopBar,BackgroundColor3=Color3.new(0.145098,0.141176,0.14902),BorderSizePixel=0,Position=UDim2.new(1,-57,0,0),Size=UDim2.new(0,19,0,19),Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.new(0,0,0),TextSize=14})
Create("ImageLabel", {Parent=MinimizeButton,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,9,0,9),Image="http://www.roblox.com/asset/?id=5597105827"})
local ToolTip = Create("Frame", {Parent=SimpleSpy3,BackgroundColor3=Color3.fromRGB(26,26,26),BackgroundTransparency=0.1,BorderColor3=Color3.new(1,1,1),Size=UDim2.new(0,200,0,50),ZIndex=3,Visible=false})
local TextLabel = Create("TextLabel", {Parent=ToolTip,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,196,0,46),ZIndex=3,Font=Enum.Font.SourceSans,Text="This is some slightly longer text.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})

-- State
local layoutOrderNum = 999999999
local mainClosing, closed = false, false
local sideClosing, sideClosed = false, false
local maximized = false
local logs, selected = {}, nil
local blacklist, blocklist = {}, {}
local getNil = false
local connectedRemotes = {}
local toggle = false
local prevTables = {}
local remoteLogs = {}
getgenv().SIMPLESPYCONFIG_MaxRemotes = 300
local indent = 4
local scheduled = {}
local schedulerconnect
local SimpleSpy = {}
local topstr, bottomstr = "", ""
local remotesFadeIn, rightFadeIn
local codebox, getnilrequired = nil, false
local history, excluding = {}, {}
local mouseInGui = false
local connections, DecompiledScripts, generation = {}, {}, {}
local running_threads = {}
local originalnamecall

local remoteEvent = Instance.new("RemoteEvent", Storage)
local unreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
local remoteFunction = Instance.new("RemoteFunction", Storage)
local NamecallHandler = Instance.new("BindableEvent", Storage)
local IndexHandler = Instance.new("BindableEvent", Storage)
local GetDebugIdHandler = Instance.new("BindableFunction", Storage)

local originalEvent = remoteEvent.FireServer
local originalUnreliableEvent = unreliableRemoteEvent.FireServer
local originalFunction = remoteFunction.InvokeServer
local GetDebugIDInvoke = GetDebugIdHandler.Invoke

function GetDebugIdHandler.OnInvoke(obj) return OldDebugId(obj) end
local function ThreadGetDebugId(obj) return GetDebugIDInvoke(GetDebugIdHandler, obj) end

local synv3 = false
if syn and identifyexecutor then
	local _, version = identifyexecutor()
	if version and version:sub(1, 2) == "v3" then synv3 = true end
end

xpcall(function()
	if isfile and readfile and isfolder and makefolder then
		local cachedconfigs = isfile("SimpleSpy//Settings.json") and jsond(readfile("SimpleSpy//Settings.json"))
		if cachedconfigs then
			for i, v in next, realconfigs do
				if cachedconfigs[i] == nil then cachedconfigs[i] = v end
			end
			realconfigs = cachedconfigs
		end
		if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
		if not isfolder("SimpleSpy//Assets") then makefolder("SimpleSpy//Assets") end
		if not isfile("SimpleSpy//Settings.json") then writefile("SimpleSpy//Settings.json", jsone(realconfigs)) end
		configsmetatable.__newindex = function(_, index, newindex)
			realconfigs[index] = newindex
			writefile("SimpleSpy//Settings.json", jsone(realconfigs))
		end
	else
		configsmetatable.__newindex = function(_, index, newindex) realconfigs[index] = newindex end
	end
end, function(err) ErrorPrompt(("An error has occured: (%s)"):format(err)) end)

local function logthread(thread) tinsert(running_threads, thread) end

function clean()
	local max = getgenv().SIMPLESPYCONFIG_MaxRemotes
	if not typeof(max) == "number" or mfloor(max) ~= max then max = 500 end
	if #remoteLogs > max then
		for i = 100, #remoteLogs do
			local v = remoteLogs[i]
			if typeof(v[1]) == "RBXScriptConnection" then v[1]:Disconnect() end
			if typeof(v[2]) == "Instance" then v[2]:Destroy() end
		end
		local newLogs = {}
		for i = 1, 100 do newLogs[i] = remoteLogs[i] end
		remoteLogs = newLogs
	end
end

local function ThreadIsNotDead(thread) return not status(thread) == "dead" end

local function tween(obj, t, props) TweenService:Create(obj, TweenInfo.new(t), props):Play() end

function scaleToolTip()
	local size = TextService:GetTextSize(TextLabel.Text, TextLabel.TextSize, TextLabel.Font, Vector2.new(196, mhuge))
	TextLabel.Size = UDim2.new(0, size.X, 0, size.Y)
	ToolTip.Size = UDim2.new(0, size.X + 4, 0, size.Y + 4)
end

function onToggleButtonHover()
	tween(Simple, 0.5, {TextColor3 = toggle and Color3.fromRGB(68, 206, 91) or Color3.fromRGB(252, 51, 51)})
end
function onToggleButtonUnhover() tween(Simple, 0.5, {TextColor3 = Color3.fromRGB(255, 255, 255)}) end
function onXButtonHover() tween(CloseButton, 0.2, {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}) end
function onXButtonUnhover() tween(CloseButton, 0.2, {BackgroundColor3 = Color3.fromRGB(37, 36, 38)}) end

function onToggleButtonClick()
	tween(Simple, 0.5, {TextColor3 = toggle and Color3.fromRGB(252, 51, 51) or Color3.fromRGB(68, 206, 91)})
	toggleSpyMethod()
end

function connectResize()
	if not workspace.CurrentCamera then workspace:GetPropertyChangedSignal("CurrentCamera"):Wait() end
	local lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		lastCam:Disconnect()
		lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
	end)
end

function bringBackOnResize()
	validateSize()
	if sideClosed then minimizeSize() else maximizeSize() end
	local pos = Background.AbsolutePosition
	local vp = workspace.CurrentCamera.ViewportSize
	local cx = mclamp(pos.X, 0, vp.X - (sideClosed and 131 or Background.AbsoluteSize.X))
	local cy = mclamp(pos.Y, 0, vp.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y)
	TweenService.Create(TweenService, Background, TweenInfo.new(0.1), {Position = UDim2.new(0, cx, 0, cy)}):Play()
end

function onBarInput(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local lastPos = UserInputService:GetMouseLocation()
		local offset = Background.AbsolutePosition - lastPos
		local currentPos = offset + lastPos
		if not connections["drag"] then
			connections["drag"] = RunService.RenderStepped:Connect(function()
				local newPos = UserInputService:GetMouseLocation()
				if newPos == lastPos then return end
				local vp = workspace.CurrentCamera.ViewportSize
				local cx = mclamp((offset + newPos).X, 0, vp.X - (sideClosed and 131 or TopBar.AbsoluteSize.X))
				local cy = mclamp((offset + newPos).Y, 0, vp.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y)
				currentPos = Vector2.new(cx, cy)
				lastPos = newPos
				TweenService.Create(TweenService, Background, TweenInfo.new(0.1), {Position = UDim2.new(0, cx, 0, cy)}):Play()
			end)
		end
		tinsert(connections, UserInputService.InputEnded:Connect(function(inputE)
			if input == inputE and connections["drag"] then
				connections["drag"]:Disconnect()
				connections["drag"] = nil
			end
		end))
	end
end

function fadeOut(elements)
	local data = {}
	for _, v in next, elements do
		if typeof(v) == "Instance" and v:IsA("GuiObject") and v.Visible then
			spawn(function()
				data[v] = {BackgroundTransparency = v.BackgroundTransparency}
				tween(v, 0.5, {BackgroundTransparency = 1})
				if v:IsA("TextBox") or v:IsA("TextButton") or v:IsA("TextLabel") then
					data[v].TextTransparency = v.TextTransparency
					tween(v, 0.5, {TextTransparency = 1})
				elseif v:IsA("ImageButton") or v:IsA("ImageLabel") then
					data[v].ImageTransparency = v.ImageTransparency
					tween(v, 0.5, {ImageTransparency = 1})
				end
				delay(0.5, function()
					v.Visible = false
					for i, x in next, data[v] do v[i] = x end
					data[v] = true
				end)
			end)
		end
	end
	return function()
		for i in next, data do
			spawn(function()
				local props = {BackgroundTransparency = i.BackgroundTransparency}
				i.BackgroundTransparency = 1
				tween(i, 0.5, {BackgroundTransparency = props.BackgroundTransparency})
				if i:IsA("TextBox") or i:IsA("TextButton") or i:IsA("TextLabel") then
					props.TextTransparency = i.TextTransparency
					i.TextTransparency = 1
					tween(i, 0.5, {TextTransparency = props.TextTransparency})
				elseif i:IsA("ImageButton") or i:IsA("ImageLabel") then
					props.ImageTransparency = i.ImageTransparency
					i.ImageTransparency = 1
					tween(i, 0.5, {ImageTransparency = props.ImageTransparency})
				end
				i.Visible = true
			end)
		end
	end
end

function toggleMinimize(override)
	if (mainClosing and not override) or maximized then return end
	mainClosing = true
	closed = not closed
	if closed then
		if not sideClosed then toggleSideTray(true) end
		LeftPanel.Visible = true
		remotesFadeIn = fadeOut(LeftPanel:GetDescendants())
		tween(LeftPanel, 0.5, {Size = UDim2.new(0, 131, 0, 0)})
		wait(0.5)
	else
		tween(LeftPanel, 0.5, {Size = UDim2.new(0, 131, 0, 249)})
		wait(0.5)
		if remotesFadeIn then remotesFadeIn(); remotesFadeIn = nil end
		bringBackOnResize()
	end
	mainClosing = false
end

function toggleSideTray(override)
	if (sideClosing and not override) or maximized then return end
	sideClosing = true
	sideClosed = not sideClosed
	if sideClosed then
		rightFadeIn = fadeOut(RightPanel:GetDescendants())
		wait(0.5)
		minimizeSize(0.5)
		wait(0.5)
		RightPanel.Visible = false
	else
		if closed then toggleMinimize(true) end
		RightPanel.Visible = true
		maximizeSize(0.5)
		wait(0.5)
		if rightFadeIn then rightFadeIn() end
		bringBackOnResize()
	end
	sideClosing = false
end

function toggleMaximize()
	if not sideClosed and not maximized then
		maximized = true
		local disable = Instance.new("TextButton")
		local prevSize = UDim2.new(0, CodeBox.AbsoluteSize.X, 0, CodeBox.AbsoluteSize.Y)
		local prevPos = UDim2.new(0, CodeBox.AbsolutePosition.X, 0, CodeBox.AbsolutePosition.Y)
		disable.Size = UDim2.new(1, 0, 1, 0)
		disable.BackgroundColor3 = Color3.new()
		disable.BorderSizePixel = 0
		disable.Text = 0
		disable.ZIndex = 3
		disable.BackgroundTransparency = 1
		disable.AutoButtonColor = false
		CodeBox.ZIndex = 4
		CodeBox.Position = prevPos
		CodeBox.Size = prevSize
		tween(CodeBox, 0.5, {Size = UDim2.new(0.5, 0, 0.5, 0), Position = UDim2.new(0.25, 0, 0.25, 0)})
		tween(disable, 0.5, {BackgroundTransparency = 0.5})
		disable.MouseButton1Click:Connect(function()
			local mpos = UserInputService:GetMouseLocation()
			local cbpos, cbsz = CodeBox.AbsolutePosition, CodeBox.AbsoluteSize
			if mpos.X >= cbpos.X and mpos.X <= cbpos.X + cbsz.X and mpos.Y + GuiInset.Y >= cbpos.Y and mpos.Y + GuiInset.Y <= cbpos.Y + cbsz.Y then return end
			tween(CodeBox, 0.5, {Size = prevSize, Position = prevPos})
			tween(disable, 0.5, {BackgroundTransparency = 1})
			wait(0.5)
			disable:Destroy()
			CodeBox.Size = UDim2.new(1, 0, 0.5, 0)
			CodeBox.Position = UDim2.new(0, 0, 0, 0)
			CodeBox.ZIndex = 0
			maximized = false
		end)
	end
end

function isInResizeRange(p)
	local rp = p - Background.AbsolutePosition
	local range = 5
	local tsz, bsz = TopBar.AbsoluteSize, Background.AbsoluteSize
	if rp.X >= tsz.X - range and rp.Y >= bsz.Y - range and rp.X <= tsz.X and rp.Y <= bsz.Y then
		return true, "B"
	elseif rp.X >= tsz.X - range and rp.X <= bsz.X then
		return true, "X"
	elseif rp.Y >= bsz.Y - range and rp.Y <= bsz.Y then
		return true, "Y"
	end
	return false
end

function isInDragRange(p)
	local rp = p - Background.AbsolutePosition
	local tsz = TopBar.AbsoluteSize
	return rp.X <= tsz.X - CloseButton.AbsoluteSize.X * 3 and rp.X >= 0 and rp.Y <= tsz.Y and rp.Y >= 0
end

local customCursor = Create("ImageLabel", {Parent=SimpleSpy3,Visible=false,Size=UDim2.fromOffset(200,200),ZIndex=1e9,BackgroundTransparency=1,Image=""})

function mouseEntered()
	local con = connections["SIMPLESPY_CURSOR"]
	if con then con:Disconnect(); connections["SIMPLESPY_CURSOR"] = nil end
	connections["SIMPLESPY_CURSOR"] = RunService.RenderStepped:Connect(function()
		UserInputService.MouseIconEnabled = not mouseInGui
		customCursor.Visible = mouseInGui
		if mouseInGui and getgenv().SimpleSpyExecuted then
			local ml = UserInputService:GetMouseLocation() - GuiInset
			customCursor.Position = UDim2.fromOffset(ml.X - customCursor.AbsoluteSize.X / 2, ml.Y - customCursor.AbsoluteSize.Y / 2)
			local inRange, rtype = isInResizeRange(ml)
			if inRange and not closed then
				if not sideClosed then
					customCursor.Image = rtype == "B" and "rbxassetid://6065821980" or rtype == "X" and "rbxassetid://6065821086" or "rbxassetid://6065821596"
				elseif rtype == "Y" or rtype == "B" then
					customCursor.Image = "rbxassetid://6065821596"
				end
			elseif customCursor.Image ~= "rbxassetid://6065775281" then
				customCursor.Image = "rbxassetid://6065775281"
			end
		else
			connections["SIMPLESPY_CURSOR"]:Disconnect()
		end
	end)
end

function mouseMoved()
	local mp = UserInputService:GetMouseLocation() - GuiInset
	local tp, ts = TopBar.AbsolutePosition, TopBar.AbsoluteSize
	local bp, bs = Background.AbsolutePosition, Background.AbsoluteSize
	if not closed and mp.X >= tp.X and mp.X <= tp.X + ts.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y then
		if not mouseInGui then mouseInGui = true; mouseEntered() end
	else
		mouseInGui = false
	end
end

local function tweenPanels(speed, lpSize, rpSize, tbSize, sfSize, sfPos, cbSize)
	tween(LeftPanel, speed, {Size = lpSize})
	tween(RightPanel, speed, {Size = rpSize})
	tween(TopBar, speed, {Size = tbSize})
	tween(ScrollingFrame, speed, {Size = sfSize, Position = sfPos})
	tween(CodeBox, speed, {Size = cbSize})
	tween(LogList, speed, {Size = UDim2.fromOffset(LogList.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y - 18)})
end

function maximizeSize(speed)
	speed = speed or 0.05
	local bsz, tsz, lsz = Background.AbsoluteSize, TopBar.AbsoluteSize, LeftPanel.AbsoluteSize
	local panelH = bsz.Y - tsz.Y
	tweenPanels(speed,
		UDim2.fromOffset(lsz.X, panelH),
		UDim2.fromOffset(bsz.X - lsz.X, panelH),
		UDim2.fromOffset(bsz.X, tsz.Y),
		UDim2.fromOffset(bsz.X - lsz.X, 110),
		UDim2.fromOffset(0, bsz.Y - 119 - tsz.Y),
		UDim2.fromOffset(bsz.X - lsz.X, bsz.Y - 119 - tsz.Y)
	)
end

function minimizeSize(speed)
	speed = speed or 0.05
	local bsz, tsz, lsz = Background.AbsoluteSize, TopBar.AbsoluteSize, LeftPanel.AbsoluteSize
	tweenPanels(speed,
		UDim2.fromOffset(lsz.X, bsz.Y - tsz.Y),
		UDim2.fromOffset(0, bsz.Y - tsz.Y),
		UDim2.fromOffset(lsz.X, tsz.Y),
		UDim2.fromOffset(0, 119),
		UDim2.fromOffset(0, bsz.Y - 119 - tsz.Y),
		UDim2.fromOffset(0, bsz.Y - 119 - tsz.Y)
	)
end

function validateSize()
	local x, y = Background.AbsoluteSize.X, Background.AbsoluteSize.Y
	local scr = workspace.CurrentCamera.ViewportSize
	local bpos = Background.AbsolutePosition
	if x + bpos.X > scr.X then x = mmax(scr.X - bpos.X, 450) end
	if y + bpos.Y > scr.Y then y = mmax(scr.Y - bpos.Y, 268) end
	Background.Size = UDim2.fromOffset(x, y)
end

function backgroundUserInput(input)
	local mp = UserInputService:GetMouseLocation() - GuiInset
	local inResizeRange, rtype = isInResizeRange(mp)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and inResizeRange then
		local lastPos = UserInputService:GetMouseLocation()
		local offset = Background.AbsoluteSize - lastPos
		if not connections["SIMPLESPY_RESIZE"] then
			connections["SIMPLESPY_RESIZE"] = RunService.RenderStepped:Connect(function()
				local newPos = UserInputService:GetMouseLocation()
				if newPos == lastPos then return end
				local cp = newPos + offset
				local cx = mmax(cp.X, 450)
				local cy = mmax(cp.Y, 268)
				Background.Size = UDim2.fromOffset(
					(not sideClosed and not closed and (rtype == "X" or rtype == "B")) and cx or Background.AbsoluteSize.X,
					(not closed and (rtype == "Y" or rtype == "B")) and cy or Background.AbsoluteSize.Y
				)
				validateSize()
				if sideClosed then minimizeSize() else maximizeSize() end
				lastPos = newPos
			end)
		end
		tinsert(connections, UserInputService.InputEnded:Connect(function(inputE)
			if input == inputE and connections["SIMPLESPY_RESIZE"] then
				connections["SIMPLESPY_RESIZE"]:Disconnect()
				connections["SIMPLESPY_RESIZE"] = nil
			end
		end))
	elseif isInDragRange(mp) then
		onBarInput(input)
	end
end

function getPlayerFromInstance(instance)
	for _, v in next, Players:GetPlayers() do
		if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then return v end
	end
end

function eventSelect(frame)
	if selected and selected.Log then
		if selected.Button then spawn(function() tween(selected.Button, 0.5, {BackgroundColor3 = Color3.fromRGB(0,0,0)}) end) end
		selected = nil
	end
	for _, v in next, logs do
		if frame == v.Log then selected = v; break end
	end
	if selected and selected.Log then
		spawn(function() tween(frame.Button, 0.5, {BackgroundColor3 = Color3.fromRGB(92,126,229)}) end)
		codebox:setRaw(selected.GenScript)
	end
	if sideClosed then toggleSideTray() end
end

function updateFunctionCanvas()
	ScrollingFrame.CanvasSize = UDim2.fromOffset(UIGridLayout.AbsoluteContentSize.X, UIGridLayout.AbsoluteContentSize.Y)
end

function updateRemoteCanvas()
	LogList.CanvasSize = UDim2.fromOffset(UIListLayout.AbsoluteContentSize.X, UIListLayout.AbsoluteContentSize.Y)
end

function makeToolTip(enable, text)
	if enable and text then
		if ToolTip.Visible then
			ToolTip.Visible = false
			local tt = connections["ToolTip"]
			if tt then tt:Disconnect() end
		end
		local first = true
		connections["ToolTip"] = RunService.RenderStepped:Connect(function()
			local mp = UserInputService:GetMouseLocation()
			local vp = workspace.CurrentCamera.ViewportSize
			local tl = mp + Vector2.new(20, -15)
			local br = tl + ToolTip.AbsoluteSize
			tl = Vector2.new(
				mclamp(tl.X, 0, vp.X - ToolTip.AbsoluteSize.X),
				mclamp(tl.Y, 0, vp.Y - ToolTip.AbsoluteSize.Y - 35)
			)
			if tl.X <= mp.X and tl.Y <= mp.Y then
				tl = mp - ToolTip.AbsoluteSize - Vector2.new(2, 2)
			end
			if first then ToolTip.Position = UDim2.fromOffset(tl.X, tl.Y); first = false
			else ToolTip:TweenPosition(UDim2.fromOffset(tl.X, tl.Y), "Out", "Linear", 0.1) end
		end)
		TextLabel.Text = text
		TextLabel.TextScaled = true
		ToolTip.Visible = true
	else
		ToolTip.Visible = false
		local tt = connections["ToolTip"]
		if tt then tt:Disconnect() end
	end
end

function newButton(name, description, onClick)
	local FunctionTemplate = Create("Frame", {Name="FunctionTemplate",Parent=ScrollingFrame,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Size=UDim2.new(0,117,0,23)})
	Create("Frame", {Name="ColorBar",Parent=FunctionTemplate,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Position=UDim2.new(0,7,0,10),Size=UDim2.new(0,7,0,18),ZIndex=3})
	Create("TextLabel", {Text=name,Name="Text",Parent=FunctionTemplate,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,19,0,10),Size=UDim2.new(0,69,0,18),ZIndex=2,Font=Enum.Font.SourceSans,TextColor3=Color3.new(1,1,1),TextSize=14,TextStrokeColor3=Color3.new(0.145098,0.141176,0.14902),TextXAlignment=Enum.TextXAlignment.Left})
	local Button = Create("TextButton", {Name="Button",Parent=FunctionTemplate,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.7,BorderColor3=Color3.new(1,1,1),Position=UDim2.new(0,7,0,10),Size=UDim2.new(0,80,0,18),AutoButtonColor=false,Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.new(0,0,0),TextSize=14})
	Button.MouseEnter:Connect(function() makeToolTip(true, description()) end)
	Button.MouseLeave:Connect(function() makeToolTip(false) end)
	FunctionTemplate.AncestryChanged:Connect(function() makeToolTip(false) end)
	Button.MouseButton1Click:Connect(function(...) logthread(running()); onClick(FunctionTemplate, ...) end)
	updateFunctionCanvas()
end

function newRemote(rtype, data)
	if layoutOrderNum < 1 then layoutOrderNum = 999999999 end
	local remote = data.remote
	local RemoteTemplate = Create("Frame", {LayoutOrder=layoutOrderNum,Name="RemoteTemplate",Parent=LogList,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Size=UDim2.new(0,117,0,27)})
	Create("Frame", {Name="ColorBar",Parent=RemoteTemplate,BackgroundColor3=(rtype=="event" and Color3.fromRGB(255,242,0) or Color3.fromRGB(99,86,245)),BorderSizePixel=0,Position=UDim2.new(0,0,0,1),Size=UDim2.new(0,7,0,18),ZIndex=2})
	Create("TextLabel", {TextTruncate=Enum.TextTruncate.AtEnd,Name="Text",Parent=RemoteTemplate,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.new(0,12,0,1),Size=UDim2.new(0,105,0,18),ZIndex=2,Font=Enum.Font.SourceSans,Text=remote.Name,TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
	local Button = Create("TextButton", {Name="Button",Parent=RemoteTemplate,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.75,BorderColor3=Color3.new(1,1,1),Position=UDim2.new(0,0,0,1),Size=UDim2.new(0,117,0,18),AutoButtonColor=false,Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.new(0,0,0),TextSize=14})

	local log = {
		Name = remote.Name,
		Function = data.infofunc or "--Function Info is disabled",
		Remote = remote,
		DebugId = data.id,
		metamethod = data.metamethod,
		args = data.args,
		Log = RemoteTemplate,
		Button = Button,
		Blocked = data.blocked,
		Source = data.callingscript,
		returnvalue = data.returnvalue,
		GenScript = "-- Generating, please wait...\n-- (If this message persists, the remote args are likely extremely long)"
	}
	logs[#logs + 1] = log

	local connect = Button.MouseButton1Click:Connect(function()
		logthread(running())
		eventSelect(RemoteTemplate)
		log.GenScript = genScript(log.Remote, log.args)
		if log.Blocked then log.GenScript = "-- THIS REMOTE WAS PREVENTED FROM FIRING TO THE SERVER BY SIMPLESPY\n\n" .. log.GenScript end
		if selected == log and RemoteTemplate then eventSelect(RemoteTemplate) end
	end)
	layoutOrderNum -= 1
	tinsert(remoteLogs, 1, {connect, RemoteTemplate})
	clean()
	updateRemoteCanvas()
end

function genScript(remote, args)
	prevTables = {}
	local gen = ""
	local suffix
	if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
		suffix = ":FireServer("
	else
		suffix = ":InvokeServer("
	end

	if #args > 0 then
		xpcall(function()
			gen = "local args = " .. LazyFix.Convert(args, true) .. "\n"
		end, function(err)
			gen ..= "-- An error has occured:\n--" .. err .. "\n-- TableToString failure! Reverting to legacy functionality\nlocal args = {"
			xpcall(function()
				for i, v in next, args do
					local itype, vtype = type(i), type(v)
					if itype ~= "Instance" and itype ~= "userdata" then gen ..= "\n    [object] = "
					elseif itype == "string" then gen ..= '\n    ["' .. i .. '"] = '
					elseif typeof(i) ~= "Instance" then gen ..= "\n    [" .. sfmt("nil --[[%s]]", typeof(v)) .. "] = "
					else gen ..= "\n    [game." .. i:GetFullName() .. "] = " end
					if vtype ~= "Instance" and vtype ~= "userdata" then gen ..= "object"
					elseif vtype == "string" then gen ..= '"' .. v .. '"'
					elseif typeof(v) ~= "Instance" then gen ..= sfmt("nil --[[%s]]", typeof(v))
					else gen ..= "game." .. v:GetFullName() end
				end
				gen ..= "\n}\n\n"
			end, function() gen ..= "}\n-- Legacy tableToString failure! Unable to decompile." end)
		end)
		if not remote:IsDescendantOf(game) and not getnilrequired then
			gen = "function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v end end end\n\n" .. gen
		end
		gen ..= LazyFix.ConvertKnown("Instance", remote) .. suffix .. "unpack(args))"
	else
		gen ..= LazyFix.ConvertKnown("Instance", remote) .. suffix .. ")"
	end
	prevTables = {}
	return gen
end

local CustomGeneration = {
	Vector3 = (function()
		local t = {}
		for i, v in Vector3 do if type(v) == "vector" then t[v] = "Vector3." .. i end end
		return t
	end)(),
	Vector2 = (function()
		local t = {}
		for i, v in Vector2 do if type(v) == "userdata" then t[v] = "Vector2." .. i end end
		return t
	end)(),
	CFrame = {[CFrame.identity] = "CFrame.identity"}
}

local number_table = {["inf"]="math.huge",["-inf"]="-math.huge",["nan"]="0/0"}

local ufunctions
ufunctions = {
	TweenInfo = function(u) return ("TweenInfo.new(%s, %s, %s, %s, %s, %s)"):format(u.Time, u.EasingStyle, u.EasingDirection, u.RepeatCount, u.Reverses, u.DelayTime) end,
	Ray = function(u) local V = ufunctions.Vector3; return ("Ray.new(%s, %s)"):format(V(u.Origin), V(u.Direction)) end,
	BrickColor = function(u) return ("BrickColor.new(%s)"):format(u.Number) end,
	NumberRange = function(u) return ("NumberRange.new(%s, %s)"):format(u.Min, u.Max) end,
	Region3 = function(u)
		local V = ufunctions.Vector3; local c, s = u.CFrame.Position, u.Size/2
		return ("Region3.new(%s, %s)"):format(V(c-s), V(c+s))
	end,
	Faces = function(u)
		local f = {}
		for _, pair in ipairs({{"Top","Top"},{"Bottom","Bottom"},{"Left","Left"},{"Right","Right"},{"Back","Back"},{"Front","Front"}}) do
			if u[pair[1]] then f[#f+1] = "Enum.NormalId." .. pair[2] end
		end
		return "Faces.new(" .. tconcat(f, ", ") .. ")"
	end,
	EnumItem = function(u) return tostring(u) end,
	Enums = function() return "Enum" end,
	Enum = function(u) return "Enum." .. tostring(u) end,
	Vector3 = function(u) return CustomGeneration.Vector3[u] or ("Vector3.new(%s)"):format(tostring(u)) end,
	Vector2 = function(u) return CustomGeneration.Vector2[u] or ("Vector2.new(%s)"):format(tostring(u)) end,
	CFrame = function(u) return CustomGeneration.CFrame[u] or ("CFrame.new(%s)"):format(tconcat({u:GetComponents()}, ", ")) end,
	PathWaypoint = function(u) return ('PathWaypoint.new(%s, %s, "%s")'):format(ufunctions.Vector3(u.Position), tostring(u.Action), u.Label) end,
	UDim = function(u) return ("UDim.new(%s)"):format(tostring(u)) end,
	UDim2 = function(u) return ("UDim2.new(%s)"):format(tostring(u)) end,
	Rect = function(u) local V = ufunctions.Vector2; return ("Rect.new(%s, %s)"):format(V(u.Min), V(u.Max)) end,
	Color3 = function(u) return ("Color3.new(%s, %s, %s)"):format(u.R, u.G, u.B) end,
	RBXScriptSignal = function() return "RBXScriptSignal --[[RBXScriptSignal's are not supported]]" end,
	RBXScriptConnection = function() return "RBXScriptConnection --[[RBXScriptConnection's are not supported]]" end,
}

local typeofv2sfunctions = {
	number = function(v) local s = tostring(v); return number_table[s] or s end,
	boolean = function(v) return tostring(v) end,
	string = function(v, l) return formatstr(v, l) end,
	["function"] = function(v) return f2s(v) end,
	table = function(v, l, p, n, vtv, i, pt, path, tables, tI) return t2s(v, l, p, n, vtv, i, pt, path, tables, tI) end,
	Instance = function(v) return i2p(v, generation[OldDebugId(v)]) end,
	userdata = function(v)
		if configs.advancedinfo then
			return getrawmetatable(v) and "newproxy(true)" or "newproxy(false)"
		end
		return "newproxy(true)"
	end,
}

local typev2sfunctions = {
	userdata = function(v, vtypeof)
		return ufunctions[vtypeof] and ufunctions[vtypeof](v) or (vtypeof .. "(" .. rawtostring(v) .. ") --[[Generation Failure]]")
	end,
	vector = ufunctions["Vector3"],
}

function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
	local vtypeof = typeof(v)
	local vtypeoffunc = typeofv2sfunctions[vtypeof]
	local vtypefunc = typev2sfunctions[type(v)]
	if not tI then tI = {0} else tI[1] += 1 end
	if vtypeoffunc then return vtypeoffunc(v, l, p, n, vtv, i, pt, path, tables, tI)
	elseif vtypefunc then return vtypefunc(v, vtypeof) end
	return vtypeof .. "(" .. rawtostring(v) .. ") --[[Generation Failure]]"
end

function v2v(t)
	topstr, bottomstr, getnilrequired = "", "", false
	local ret, count = "", 1
	for i, v in next, t do
		local varname
		if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
			varname = i
		elseif rawtostring(i):match("^[%a_]+[%w_]*$") then
			varname = lower(rawtostring(i)) .. "_" .. count
		else
			varname = type(v) .. "_" .. count
		end
		ret ..= "local " .. varname .. " = " .. v2s(v, nil, nil, varname, true) .. "\n"
		count += 1
	end
	if getnilrequired then
		topstr = "function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v end end end\n" .. topstr
	end
	if #topstr > 0 then ret = topstr .. "\n" .. ret end
	if #bottomstr > 0 then ret = ret .. bottomstr end
	return ret
end

function tabletostring(tbl, format) end

function t2s(t, l, p, n, vtv, i, pt, path, tables, tI)
	local globalIndex = tfind(getgenv(), t)
	if type(globalIndex) == "string" then return globalIndex end
	tI = tI or {0}
	path = path or ""
	if not l then l = 0; tables = {} end
	p = p or t
	for _, v in next, tables do
		if n and rawequal(v, t) then
			bottomstr ..= "\n" .. rawtostring(n) .. rawtostring(path) .. " = " .. rawtostring(n) .. rawtostring(({v2p(v, p)})[2])
			return "{} --[[DUPLICATE]]"
		end
	end
	tinsert(tables, t)
	local s = "{"
	local size = 0
	l += indent
	for k, v in next, t do
		size += 1
		if size > (getgenv().SimpleSpyMaxTableSize or 1000) then
			s ..= "\n" .. srep(" ", l) .. "-- MAXIMUM TABLE SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxTableSize' TO ADJUST"
			break
		end
		if rawequal(k, t) then
			bottomstr ..= ("\n%s%s[%s%s] = %s"):format(n, path, n, path, (rawequal(v,k) and n..path or v2s(v,l,p,n,vtv,k,t,path.."["..n..path.."]",tables)))
			size -= 1
			continue
		end
		local currentPath = type(k) == "string" and k:match("^[%a_]+[%w_]*$") and "." .. k or "[" .. v2s(k,l,p,n,vtv,k,t,path,tables,tI) .. "]"
		if size % 100 == 0 then scheduleWait() end
		s ..= "\n" .. srep(" ", l) .. "[" .. v2s(k,l,p,n,vtv,k,t,path..currentPath,tables,tI) .. "] = " .. v2s(v,l,p,n,vtv,k,t,path..currentPath,tables,tI) .. ","
	end
	if #s > 1 then s = s:sub(1, #s - 1) end
	if size > 0 then s ..= "\n" .. srep(" ", l - indent) end
	return s .. "}"
end

function f2s(f)
	for k, x in next, getgenv() do
		local isgucci, gpath
		if rawequal(x, f) then isgucci, gpath = true, ""
		elseif type(x) == "table" then isgucci, gpath = v2p(f, x) end
		if isgucci and type(k) ~= "function" then
			return (type(k) == "string" and k:match("^[%a_]+[%w_]*$") and k or "getgenv()[" .. v2s(k) .. "]") .. gpath
		end
	end
	if configs.funcEnabled then
		local funcname = info(f, "n")
		if funcname and funcname:match("^[%a_]+[%w_]*$") then
			return ("function %s() end -- Function Called: %s"):format(funcname, funcname)
		end
	end
	return tostring(f)
end

function i2p(i, customgen)
	if customgen then return customgen end
	local player = getplayer(i)
	local parent, out = i, ""
	if parent == nil then return "nil" end
	if player then
		while true do
			if parent == player.Character then
				if player == Players.LocalPlayer then
					return 'game:GetService("Players").LocalPlayer.Character' .. out
				else
					return i2p(player) .. ".Character" .. out
				end
			else
				out = (parent.Name:match("[%a_]+[%w+]*") ~= parent.Name and ':FindFirstChild(' .. formatstr(parent.Name) .. ')' or "." .. parent.Name) .. out
			end
			task.wait()
			parent = parent.Parent
		end
	elseif parent ~= game then
		while true do
			if parent and parent.Parent == game then
				if SafeGetService(parent.ClassName) then
					return (lower(parent.ClassName) == "workspace" and "workspace" or 'game:GetService("' .. parent.ClassName .. '")') .. out
				else
					return (parent.Name:match("[%a_]+[%w_]*") and "game." .. parent.Name or 'game:FindFirstChild(' .. formatstr(parent.Name) .. ')') .. out
				end
			elseif not parent.Parent then
				getnilrequired = true
				return 'getNil(' .. formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
			else
				out = (parent.Name:match("[%a_]+[%w_]*") ~= parent.Name and ':WaitForChild(' .. formatstr(parent.Name) .. ')' or ':WaitForChild("' .. parent.Name .. '")') .. out
			end
			if i:IsDescendantOf(Players.LocalPlayer) then
				return 'game:GetService("Players").LocalPlayer' .. out
			end
			parent = parent.Parent
			task.wait()
		end
	end
	return "game"
end

function getplayer(instance)
	for _, v in next, Players:GetPlayers() do
		if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then return v end
	end
end

function v2p(x, t, path, prev)
	path = path or ""
	prev = prev or {}
	if rawequal(x, t) then return true, "" end
	for i, v in next, t do
		if rawequal(v, x) then
			return true, path .. (type(i) == "string" and i:match("^[%a_]+[%w_]*$") and "." .. i or "[" .. v2s(i) .. "]")
		end
		if type(v) == "table" then
			local dup = false
			for _, y in next, prev do if rawequal(y, v) then dup = true; break end end
			if not dup then
				tinsert(prev, t)
				local found, p2 = v2p(x, v, path, prev)
				if found then
					return true, (type(i) == "string" and i:match("^[%a_]+[%w_]*$") and "." .. i or "[" .. v2s(i) .. "]") .. p2
				end
			end
		end
	end
	return false, ""
end

function formatstr(s, indentation)
	indentation = indentation or 0
	local handled, reachedMax = handlespecials(s, indentation)
	return '"' .. handled .. '"' .. (reachedMax and " --[[ MAXIMUM STRING SIZE REACHED ]]" or "")
end

local function isFinished(coroutines)
	for _, v in next, coroutines do if status(v) == "running" then return false end end
	return true
end

local specialstrings = {
	["\n"] = function(t, i) resume(t, i, "\\n") end,
	["\t"] = function(t, i) resume(t, i, "\\t") end,
	["\\"] = function(t, i) resume(t, i, "\\\\") end,
	['"'] = function(t, i) resume(t, i, '\\"') end,
}

function handlespecials(s, indentation)
	local i, n, coroutines, timeout = 0, 1, {}, 0
	local coroutineFunc = function(idx, r) s = s:sub(0, idx-1) .. r .. s:sub(idx+1, -1) end
	repeat
		i += 1
		if timeout >= 10 then task.wait(); timeout = 0 end
		local char = s:sub(i, i)
		if byte(char) then
			timeout += 1
			local c = create(coroutineFunc)
			tinsert(coroutines, c)
			local sf = specialstrings[char]
			if sf then
				sf(c, i); i += 1
			elseif byte(char) > 126 or byte(char) < 32 then
				resume(c, i, "\\" .. byte(char))
				i += #rawtostring(byte(char))
			end
			if i >= n * 100 then
				local extra = sfmt('" ..\n%s"', srep(" ", indentation + indent))
				s = s:sub(0, i) .. extra .. s:sub(i+1, -1)
				i += #extra; n += 1
			end
		end
	until char == "" or i > (getgenv().SimpleSpyMaxStringSize or 10000)
	while not isFinished(coroutines) do RunService.Heartbeat:Wait() end
	clear(coroutines)
	if i > (getgenv().SimpleSpyMaxStringSize or 10000) then
		return ssub(s, 0, getgenv().SimpleSpyMaxStringSize or 10000), true
	end
	return s, false
end

function getScriptFromSrc(src)
	local realPath, runningTest, s, e, match
	if src:sub(1, 1) == "=" then
		realPath = game; s = 2
	else
		runningTest = src:sub(2, e and e-1 or -1)
		for _, v in next, getnilinstances() do
			if v.Name == runningTest then realPath = v; break end
		end
		s = #runningTest + 1
	end
	if realPath then
		e = src:sub(s, -1):find("%.")
		for _ = 1, 50 do
			if not e then
				runningTest = src:sub(s, -1)
				local test = realPath.FindFirstChild(realPath, runningTest)
				if test then realPath = test end
				match = true
			else
				runningTest = src:sub(s, e)
				local test = realPath.FindFirstChild(realPath, runningTest)
				local yeOld = e
				if test then
					realPath = test; s = e + 2
					e = src:sub(e+2, -1):find("%.")
					e = e and e + yeOld or e
				else
					e = src:sub(e+2, -1):find("%.")
					e = e and e + yeOld or e
				end
			end
			if match then break end
		end
	end
	return realPath
end

function schedule(f, ...) tinsert(scheduled, {f, ...}) end

function scheduleWait()
	local thread = running()
	schedule(function() resume(thread) end)
	yield()
end

local function taskscheduler()
	if not toggle then scheduled = {}; return end
	if #scheduled > SIMPLESPYCONFIG_MaxRemotes + 100 then tremove(scheduled, #scheduled) end
	if #scheduled > 0 then
		local f = tremove(scheduled, 1)
		if type(f) == "table" and type(f[1]) == "function" then pcall(unpack(f)) end
	end
end

local function tablecheck(t, instance, id)
	return t[id] or t[instance.Name]
end

function remoteHandler(data)
	if configs.autoblock then
		local id = data.id
		if excluding[id] then return end
		if not history[id] then history[id] = {badOccurances = 0, lastCall = tick()} end
		if tick() - history[id].lastCall < 1 then
			history[id].badOccurances += 1
			return
		else
			history[id].badOccurances = 0
		end
		if history[id].badOccurances > 3 then excluding[id] = true; return end
		history[id].lastCall = tick()
	end
	local m = lower(data.method)
	if (data.remote:IsA("RemoteEvent") or data.remote:IsA("UnreliableRemoteEvent")) and m == "fireserver" then
		newRemote("event", data)
	elseif data.remote:IsA("RemoteFunction") and m == "invokeserver" then
		newRemote("function", data)
	end
end

local function handleRemoteCall(method, originalfunction, ...)
	if typeof(...) == "Instance" then
		local remote = cloneref(...)
		if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent") then
			if not configs.logcheckcaller and checkcaller() then return originalfunction(...) end
			local id = ThreadGetDebugId(remote)
			local blockcheck = tablecheck(blocklist, remote, id)
			local args = {select(2, ...)}
			if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
				local data = {
					method = method, remote = remote, args = deepclone(args),
					infofunc = nil, callingscript = nil,
					metamethod = "__index", blockcheck = blockcheck,
					id = id, returnvalue = {}
				}
				args = nil
				if configs.funcEnabled then
					data.infofunc = info(2, "f")
					local calling = getcallingscript()
					data.callingscript = calling and cloneref(calling) or nil
				end
				schedule(remoteHandler, data)
			end
			if blockcheck then return end
		end
	end
	return originalfunction(...)
end

local newnamecall = newcclosure(function(...)
	local method = getnamecallmethod()
	if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
		if typeof(...) == "Instance" then
			local remote = cloneref(...)
			if IsA(remote, "RemoteEvent") or IsA(remote, "RemoteFunction") or IsA(remote, "UnreliableRemoteEvent") then
				if not configs.logcheckcaller and checkcaller() then return originalnamecall(...) end
				local id = ThreadGetDebugId(remote)
				local blockcheck = tablecheck(blocklist, remote, id)
				local args = {select(2, ...)}
				if not tablecheck(blacklist, remote, id) and not IsCyclicTable(args) then
					local data = {
						method = method, remote = remote, args = deepclone(args),
						infofunc = nil, callingscript = nil,
						metamethod = "__namecall", blockcheck = blockcheck,
						id = id, returnvalue = {}
					}
					args = nil
					if configs.funcEnabled then
						data.infofunc = info(2, "f")
						local calling = getcallingscript()
						if type(calling) == "userdata" then
							data.callingscript = calling and cloneref(calling) or nil
						end
					end
					schedule(remoteHandler, data)
				end
				if blockcheck then return end
			end
		end
	end
	return originalnamecall(...)
end)

local newFireServer = newcclosure(function(...) return handleRemoteCall("FireServer", originalEvent, ...) end)
local newUnreliableFireServer = newcclosure(function(...) return handleRemoteCall("FireServer", originalUnreliableEvent, ...) end)
local newInvokeServer = newcclosure(function(...) return handleRemoteCall("InvokeServer", originalFunction, ...) end)

local function disablehooks()
	if synv3 then
		unhook(getrawmetatable(game).__namecall, originalnamecall)
		unhook(Instance.new("RemoteEvent").FireServer, originalEvent)
		unhook(Instance.new("RemoteFunction").InvokeServer, originalFunction)
		unhook(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
		restorefunction(originalnamecall)
		restorefunction(originalEvent)
		restorefunction(originalFunction)
	else
		if hookmetamethod then hookmetamethod(game, "__namecall", originalnamecall)
		else hookfunction(getrawmetatable(game).__namecall, originalnamecall) end
		hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
		hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
		hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
	end
end

function toggleSpy()
	if not toggle then
		local oldnamecall
		if synv3 then
			oldnamecall = hook(getrawmetatable(game).__namecall, clonefunction(newnamecall))
			originalEvent = hook(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
			originalFunction = hook(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
			originalUnreliableEvent = hook(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
		else
			if hookmetamethod then oldnamecall = hookmetamethod(game, "__namecall", clonefunction(newnamecall))
			else oldnamecall = hookfunction(getrawmetatable(game).__namecall, clonefunction(newnamecall)) end
			originalEvent = hookfunction(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
			originalFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
			originalUnreliableEvent = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
		end
		originalnamecall = originalnamecall or function(...) return oldnamecall(...) end
	else
		disablehooks()
	end
end

function toggleSpyMethod() toggleSpy(); toggle = not toggle end

local function shutdown()
	if schedulerconnect then schedulerconnect:Disconnect() end
	for _, connection in next, connections do connection:Disconnect() end
	for _, v in next, running_threads do if ThreadIsNotDead(v) then close(v) end end
	clear(running_threads); clear(connections); clear(logs); clear(remoteLogs)
	disablehooks()
	SimpleSpy3:Destroy()
	Storage:Destroy()
	UserInputService.MouseIconEnabled = true
	getgenv().SimpleSpyExecuted = false
end

if not getgenv().SimpleSpyExecuted then
	local succeeded, err = pcall(function()
		if not RunService:IsClient() then error("SimpleSpy cannot run on the server!") end
		getgenv().SimpleSpyShutdown = shutdown
		onToggleButtonClick()
		if not hookmetamethod then
			ErrorPrompt("Simple Spy V3 will not function to its fullest capability due to your executor not supporting hookmetamethod.", true)
		end
		codebox = Highlight.new(CodeBox)
		logthread(spawn(function()
			local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/SimpleSpyV3/update.txt")
			codebox:setRaw((ok and result) or "")
		end))
		getgenv().SimpleSpy = SimpleSpy
		getgenv().getNil = function(name, class)
			for _, v in next, getnilinstances() do
				if v.ClassName == class and v.Name == name then return v end
			end
		end
		Background.MouseEnter:Connect(function() mouseInGui = true; mouseEntered() end)
		Background.MouseLeave:Connect(function() mouseInGui = false; mouseEntered() end)
		TextLabel:GetPropertyChangedSignal("Text"):Connect(scaleToolTip)
		MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
		MaximizeButton.MouseButton1Click:Connect(toggleSideTray)
		Simple.MouseButton1Click:Connect(onToggleButtonClick)
		CloseButton.MouseEnter:Connect(onXButtonHover)
		CloseButton.MouseLeave:Connect(onXButtonUnhover)
		Simple.MouseEnter:Connect(onToggleButtonHover)
		Simple.MouseLeave:Connect(onToggleButtonUnhover)
		CloseButton.MouseButton1Click:Connect(shutdown)
		tinsert(connections, UserInputService.InputBegan:Connect(backgroundUserInput))
		connectResize()
		SimpleSpy3.Enabled = true
		logthread(spawn(function() delay(1, onToggleButtonUnhover) end))
		schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)
		bringBackOnResize()
		SimpleSpy3.Parent = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(SimpleSpy3)) or CoreGui
		logthread(spawn(function()
			local lp = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
			generation = {
				[OldDebugId(lp)] = 'game:GetService("Players").LocalPlayer',
				[OldDebugId(lp:GetMouse())] = 'game:GetService("Players").LocalPlayer:GetMouse',
				[OldDebugId(game)] = "game",
				[OldDebugId(workspace)] = "workspace",
			}
		end))
	end)
	if succeeded then
		getgenv().SimpleSpyExecuted = true
	else
		shutdown()
		ErrorPrompt("An error has occured:\n" .. rawtostring(err))
		return
	end
else
	SimpleSpy3:Destroy()
	return
end

function SimpleSpy:newButton(name, description, onClick) return newButton(name, description, onClick) end

-- ADD-ONS
newButton("Copy Code", function() return "Click to copy code" end, function()
	setclipboard(codebox:getString())
	TextLabel.Text = "Copied successfully!"
end)

newButton("Copy Remote", function() return "Click to copy the path of the remote" end, function()
	if selected and selected.Remote then
		setclipboard(v2s(selected.Remote))
		TextLabel.Text = "Copied!"
	end
end)

newButton("Run Code", function() return "Click to execute code" end, function()
	local Remote = selected and selected.Remote
	if Remote then
		TextLabel.Text = "Executing..."
		xpcall(function()
			local rv
			if Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then
				rv = Remote:FireServer(unpack(selected.args))
			elseif Remote:IsA("RemoteFunction") then
				rv = Remote:InvokeServer(unpack(selected.args))
			end
			TextLabel.Text = ("Executed successfully!\n%s"):format(v2s(rv))
		end, function(err) TextLabel.Text = ("Execution error!\n%s"):format(err) end)
		return
	end
	TextLabel.Text = "Source not found"
end)

newButton("Get Script", function() return "Click to copy calling script to clipboard\nWARNING: Not super reliable, nil == could not find" end, function()
	if selected then
		if not selected.Source then selected.Source = rawget(getfenv(selected.Function), "script") end
		setclipboard(v2s(selected.Source))
		TextLabel.Text = "Done!"
	end
end)

newButton("Function Info", function() return "Click to view calling function information" end, function()
	local func = selected and selected.Function
	if func then
		if typeof(func) ~= "string" then
			codebox:setRaw("--[[Generating Function Info please wait]]")
			RunService.Heartbeat:Wait()
			local lclosure = islclosure(func)
			local SourceScript = rawget(getfenv(func), "script")
			local CallingScript = selected.Source or nil
			local funcinfo = {
				info = getinfo(func),
				constants = lclosure and deepclone(getconstants(func)) or "N/A --Lua Closure expected got C Closure",
				upvalues = deepclone(getupvalues(func)),
				script = {SourceScript = SourceScript or "nil", CallingScript = CallingScript or "nil"}
			}
			if configs.advancedinfo then
				local Remote = selected.Remote
				funcinfo.advancedinfo = {
					Metamethod = selected.metamethod,
					DebugId = {
						SourceScriptDebugId = SourceScript and typeof(SourceScript) == "Instance" and OldDebugId(SourceScript) or "N/A",
						CallingScriptDebugId = CallingScript and typeof(CallingScript) == "Instance" and OldDebugId(CallingScript) or "N/A",
						RemoteDebugId = OldDebugId(Remote),
					},
					Protos = lclosure and getprotos(func) or "N/A --Lua Closure expected got C Closure"
				}
				if Remote:IsA("RemoteFunction") then
					funcinfo.advancedinfo.OnClientInvoke = getcallbackmember and (getcallbackmember(Remote, "OnClientInvoke") or "N/A") or "N/A --Missing getcallbackmember"
				elseif getconnections then
					funcinfo.advancedinfo.OnClientEvents = {}
					for i, v in next, getconnections(Remote.OnClientEvent) do
						funcinfo.advancedinfo.OnClientEvents[i] = {Function = v.Function or "N/A", State = v.State or "N/A"}
					end
				end
			end
			codebox:setRaw("--[[Converting table to string please wait]]")
			selected.Function = v2v({functionInfo = funcinfo})
		end
		codebox:setRaw("-- Calling function info\n-- Generated by the SimpleSpy V3 serializer\n\n" .. selected.Function)
		TextLabel.Text = "Done! Function info generated by the SimpleSpy V3 Serializer."
	else
		TextLabel.Text = "Error! Selected function was not found."
	end
end)

newButton("Clr Logs", function() return "Click to clear logs" end, function()
	TextLabel.Text = "Clearing..."
	clear(logs)
	for _, v in next, LogList:GetChildren() do if not v:IsA("UIListLayout") then v:Destroy() end end
	codebox:setRaw("")
	selected = nil
	TextLabel.Text = "Logs cleared!"
end)

newButton("Exclude (i)", function() return "Click to exclude this Remote.\nExcluding makes SimpleSpy ignore it, but it will continue to be usable." end, function()
	if selected then blacklist[OldDebugId(selected.Remote)] = true; TextLabel.Text = "Excluded!" end
end)

newButton("Exclude (n)", function() return "Click to exclude all remotes with this name.\nExcluding makes SimpleSpy ignore it, but it will continue to be usable." end, function()
	if selected then blacklist[selected.Name] = true; TextLabel.Text = "Excluded!" end
end)

newButton("Clr Blacklist", function() return "Click to clear the blacklist." end, function()
	blacklist = {}; TextLabel.Text = "Blacklist cleared!"
end)

newButton("Block (i)", function() return "Click to stop this remote from firing.\nBlocking won't remove it from logs, but prevents server fires." end, function()
	if selected then blocklist[OldDebugId(selected.Remote)] = true; TextLabel.Text = "Blocked!" end
end)

newButton("Block (n)", function() return "Click to stop remotes with this name from firing." end, function()
	if selected then blocklist[selected.Name] = true; TextLabel.Text = "Blocked!" end
end)

newButton("Clr Blocklist", function() return "Click to stop blocking remotes." end, function()
	blocklist = {}; TextLabel.Text = "Blocklist cleared!"
end)

newButton("Decompile", function() return "Decompile source script" end, function()
	if decompile then
		if selected and selected.Source then
			local Source = selected.Source
			if not DecompiledScripts[Source] then
				codebox:setRaw("--[[Decompiling]]")
				xpcall(function()
					local src = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.", "")
					local Sourcev2s = v2s(Source)
					if src:find("script") and Sourcev2s then
						DecompiledScripts[Source] = ("local script = %s\n%s"):format(Sourcev2s, src)
					end
				end, function(err) codebox:setRaw(("--[[\nAn error has occured\n%s\n]]"):format(err)) end)
			end
			codebox:setRaw(DecompiledScripts[Source] or "--No Source Found")
			TextLabel.Text = "Done!"
		else
			TextLabel.Text = "Source not found!"
		end
	else
		TextLabel.Text = "Missing function (decompile)"
	end
end)

newButton("Disable Info", function()
	return ("[%s] Toggle function info"):format(configs.funcEnabled and "ENABLED" or "DISABLED")
end, function()
	configs.funcEnabled = not configs.funcEnabled
	TextLabel.Text = ("[%s] Toggle function info"):format(configs.funcEnabled and "ENABLED" or "DISABLED")
end)

newButton("Autoblock", function()
	return ("[%s] [BETA] Intelligently detects and excludes spammy remote calls"):format(configs.autoblock and "ENABLED" or "DISABLED")
end, function()
	configs.autoblock = not configs.autoblock
	TextLabel.Text = ("[%s] [BETA] Intelligently detects and excludes spammy remote calls"):format(configs.autoblock and "ENABLED" or "DISABLED")
	history = {}; excluding = {}
end)

newButton("Logcheckcaller", function()
	return ("[%s] Log remotes fired by the client"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end, function()
	configs.logcheckcaller = not configs.logcheckcaller
	TextLabel.Text = ("[%s] Log remotes fired by the client"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end)

newButton("Advanced Info", function()
	return ("[%s] Display more remoteinfo"):format(configs.advancedinfo and "ENABLED" or "DISABLED")
end, function()
	configs.advancedinfo = not configs.advancedinfo
	TextLabel.Text = ("[%s] Display more remoteinfo"):format(configs.advancedinfo and "ENABLED" or "DISABLED")
end)


if tfind({Enum.Platform.IOS, Enum.Platform.Android}, UserInputService:GetPlatform()) then
	Background.Draggable = true
	local QuickCapture = Instance.new("TextButton")
	local UICorner = Instance.new("UICorner")
	QuickCapture.Parent = SimpleSpy3
	QuickCapture.BackgroundColor3 = Color3.fromRGB(37, 36, 38)
	QuickCapture.BackgroundTransparency = 0.14
	QuickCapture.Position = UDim2.new(0.529, 0, 0, 0)
	QuickCapture.Size = UDim2.new(0, 32, 0, 33)
	QuickCapture.Font = Enum.Font.SourceSansBold
	QuickCapture.Text = "Spy"
	QuickCapture.TextColor3 = Background.Visible and Color3.fromRGB(255,255,255) or Color3.fromRGB(252,51,51)
	QuickCapture.TextSize = 16
	QuickCapture.TextWrapped = true
	QuickCapture.ZIndex = 10
	QuickCapture.Draggable = true
	UICorner.CornerRadius = UDim.new(0.5, 0)
	UICorner.Parent = QuickCapture
	QuickCapture.MouseButton1Click:Connect(function()
		Background.Visible = not Background.Visible
		QuickCapture.TextColor3 = Background.Visible and Color3.fromRGB(255,255,255) or Color3.fromRGB(252,51,51)
	end)
end
