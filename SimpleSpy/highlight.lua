local cloneref = cloneref or function(...) return ... end
local TextService = cloneref(game:GetService("TextService"))
local RunService = cloneref(game:GetService("RunService"))

local Highlight = {}

local parentFrame, scrollingFrame, textFrame, lineNumbersFrame
local tableContents = {}
local lines = {}
local line, largestX = 0, 0

local lineSpace = 15
local font = Enum.Font.Ubuntu
local textSize = 14

local backgroundColor  = Color3.fromRGB(40, 44, 52)
local operatorColor    = Color3.fromRGB(187, 85, 255)
local functionColor    = Color3.fromRGB(97, 175, 239)
local stringColor      = Color3.fromRGB(152, 195, 121)
local numberColor      = Color3.fromRGB(209, 154, 102)
local booleanColor     = numberColor
local objectColor      = Color3.fromRGB(229, 192, 123)
local defaultColor     = Color3.fromRGB(224, 108, 117)
local commentColor     = Color3.fromRGB(148, 148, 148)
local genericColor     = Color3.fromRGB(240, 240, 240)

local operators = {"^(function)[^%w_]","^(local)[^%w_]","^(if)[^%w_]","^(for)[^%w_]","^(while)[^%w_]","^(then)[^%w_]","^(do)[^%w_]","^(else)[^%w_]","^(elseif)[^%w_]","^(return)[^%w_]","^(end)[^%w_]","^(continue)[^%w_]","^(and)[^%w_]","^(not)[^%w_]","^(or)[^%w_]","[^%w_](or)[^%w_]","[^%w_](and)[^%w_]","[^%w_](not)[^%w_]","[^%w_](continue)[^%w_]","[^%w_](function)[^%w_]","[^%w_](local)[^%w_]","[^%w_](if)[^%w_]","[^%w_](for)[^%w_]","[^%w_](while)[^%w_]","[^%w_](then)[^%w_]","[^%w_](do)[^%w_]","[^%w_](else)[^%w_]","[^%w_](elseif)[^%w_]","[^%w_](return)[^%w_]","[^%w_](end)[^%w_]"}
local strings   = {{'"','"'},{"'","'"},{"%[%[","%]%]",true}}
local comments  = {"%-%-%[%[[^%]%]]+%]?%]?","(%-%-[^\n]+)"}
local functions = {"[^%w_]([%a_][%a%d_]*)%s*%(","^([%a_][%a%d_]*)%s*%(","[:%.%(%[%p]([%a_][%a%d_]*)%s*%("}
local numbers   = {"[^%w_](%d+[eE]?%d*)","[^%w_](%.%d+[eE]?%d*)","[^%w_](%d+%.%d+[eE]?%d*)","^(%d+[eE]?%d*)","^(%.%d+[eE]?%d*)","^(%d+%.%d+[eE]?%d*)"}
local booleans  = {"[^%w_](true)","^(true)","[^%w_](false)","^(false)","[^%w_](nil)","^(nil)"}
local objects   = {"[^%w_:]([%a_][%a%d_]*):","^([%a_][%a%d_]*):"}
local other     = {"[^_%s%w=>~<%-%+%*]",">","~","<","%-","%+","=","%*"}
local offLimits = {}

local function isOffLimits(index)
	for _, v in next, offLimits do
		if index >= v[1] and index <= v[2] then return true end
	end
	return false
end

local function gfind(str, pattern)
	return coroutine.wrap(function()
		local start = 0
		while true do
			local s, e = str:find(pattern, start)
			if s and e ~= #str then
				start = e + 1
				coroutine.yield(s, e)
			else
				return
			end
		end
	end)
end

local function getRaw()
	local t = {}
	for _, c in next, tableContents do t[#t+1] = c.Char end
	return table.concat(t)
end

local function renderComments()
	local str = getRaw()
	local step = 1
	for _, pattern in next, comments do
		for cs, ce in gfind(str, pattern) do
			if step % 1000 == 0 then RunService.Heartbeat:Wait() end
			step += 1
			if not isOffLimits(cs) then
				table.insert(offLimits, {cs, ce})
				for i = cs, ce do
					if tableContents[i] then tableContents[i].Color = commentColor end
				end
			end
		end
	end
end

local function renderStrings()
	local stringType, stringEndType, ignoreBackslashes
	local stringStart, offLimitsIndex
	local skip = false
	for i, char in next, tableContents do
		if stringType then
			char.Color = stringColor
			local possible = ""
			for k = stringStart, i do possible = possible .. tableContents[k].Char end
			if char.Char:match(stringEndType) and (not not ignoreBackslashes or (possible:match("(\\*)" .. stringEndType .. "$") and #possible:match("(\\*)" .. stringEndType .. "$") % 2 == 0)) then
				skip = true
				stringType, stringEndType, ignoreBackslashes = nil, nil, nil
				offLimits[offLimitsIndex][2] = i
			end
		end
		if not skip then
			for _, v in next, strings do
				if char.Char:match(v[1]) and not isOffLimits(i) then
					stringType, stringEndType, ignoreBackslashes = v[1], v[2], v[3]
					char.Color = stringColor
					stringStart = i
					offLimitsIndex = #offLimits + 1
					offLimits[offLimitsIndex] = {stringStart, math.huge}
				end
			end
		end
		skip = false
	end
end

local function highlightPattern(patternArray, color)
	local str = getRaw()
	local step = 1
	for _, pattern in next, patternArray do
		for s, e in gfind(str, pattern) do
			if step % 1000 == 0 then RunService.Heartbeat:Wait() end
			step += 1
			if not isOffLimits(s) and not isOffLimits(e) then
				for i = s, e do
					if tableContents[i] then tableContents[i].Color = color end
				end
			end
		end
	end
end

local escapeMap = {["<"]="&lt;",[">"]="&gt;",['"']="&quot;",["'"]="&apos;",["&"]="&amp;"}
local function autoEscape(s)
	return s:gsub('[<>"\'&]', escapeMap)
end

local function updateCanvasSize()
	scrollingFrame.CanvasSize = UDim2.new(0, largestX, 0, line * lineSpace)
end

local function updateZIndex()
	for _, v in next, parentFrame:GetDescendants() do
		if v:IsA("GuiObject") then v.ZIndex = parentFrame.ZIndex end
	end
end

local function render()
	offLimits = {}
	lines = {}
	textFrame:ClearAllChildren()
	lineNumbersFrame:ClearAllChildren()

	highlightPattern(functions, functionColor)
	highlightPattern(numbers, numberColor)
	highlightPattern(operators, operatorColor)
	highlightPattern(objects, objectColor)
	highlightPattern(booleans, booleanColor)
	highlightPattern(other, genericColor)
	renderComments()
	renderStrings()

	local lastColor, lineStr, rawStr = nil, "", ""
	largestX = 0
	line = 1

	for i = 1, #tableContents + 1 do
		local char = tableContents[i]
		if i == #tableContents + 1 or char.Char == "\n" then
			lineStr = lineStr .. (lastColor and "</font>" or "")

			local lineText = Instance.new("TextLabel")
			local x = TextService:GetTextSize(rawStr, textSize, font, Vector2.new(math.huge, math.huge)).X + 60
			if x > largestX then largestX = x end

			lineText.TextXAlignment = Enum.TextXAlignment.Left
			lineText.TextYAlignment = Enum.TextYAlignment.Top
			lineText.Position = UDim2.new(0, 0, 0, line * lineSpace - lineSpace / 2)
			lineText.Size = UDim2.new(0, x, 0, textSize)
			lineText.RichText = true
			lineText.Font = font
			lineText.TextSize = textSize
			lineText.BackgroundTransparency = 1
			lineText.Text = lineStr
			lineText.Parent = textFrame

			if i ~= #tableContents + 1 then
				local lineNumber = Instance.new("TextLabel")
				lineNumber.Text = line
				lineNumber.Font = font
				lineNumber.TextSize = textSize
				lineNumber.Size = UDim2.new(1, 0, 0, lineSpace)
				lineNumber.TextXAlignment = Enum.TextXAlignment.Right
				lineNumber.TextColor3 = commentColor
				lineNumber.Position = UDim2.new(0, 0, 0, line * lineSpace - lineSpace / 2)
				lineNumber.BackgroundTransparency = 1
				lineNumber.Parent = lineNumbersFrame
			end

			lineStr, rawStr, lastColor = "", "", nil
			line += 1
			updateZIndex()
			updateCanvasSize()
			if line % 5 == 0 then RunService.Heartbeat:Wait() end
		elseif char.Char == " " then
			lineStr = lineStr .. " "
			rawStr = rawStr .. " "
		elseif char.Char == "\t" then
			lineStr = lineStr .. string.rep(" ", 4)
			rawStr = rawStr .. "\t"
		else
			if char.Color == lastColor then
				lineStr = lineStr .. autoEscape(char.Char)
			else
				lineStr = lineStr .. (lastColor and "</font>" or "") .. string.format('<font color="rgb(%d,%d,%d)">', char.Color.R * 255, char.Color.G * 255, char.Color.B * 255) .. autoEscape(char.Char)
				lastColor = char.Color
			end
			rawStr = rawStr .. char.Char
		end
	end
	updateZIndex()
	updateCanvasSize()
end

function Highlight:init(frame)
	if typeof(frame) == "Instance" and frame:IsA("Frame") then
		frame:ClearAllChildren()
		parentFrame = frame
		scrollingFrame = Instance.new("ScrollingFrame")
		textFrame = Instance.new("Frame")
		lineNumbersFrame = Instance.new("Frame")

		local sz = frame.AbsoluteSize
		scrollingFrame.Size = UDim2.new(0, sz.X, 0, sz.Y)
		scrollingFrame.BackgroundColor3 = backgroundColor
		scrollingFrame.BorderSizePixel = 0
		scrollingFrame.ScrollBarThickness = 4

		textFrame.Size = UDim2.new(1, -40, 1, 0)
		textFrame.Position = UDim2.new(0, 40, 0, 0)
		textFrame.BackgroundTransparency = 1

		lineNumbersFrame.Size = UDim2.new(0, 25, 1, 0)
		lineNumbersFrame.BackgroundTransparency = 1

		textFrame.Parent = scrollingFrame
		lineNumbersFrame.Parent = scrollingFrame
		scrollingFrame.Parent = parentFrame

		render()
		parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local s = parentFrame.AbsoluteSize
			scrollingFrame.Size = UDim2.new(0, s.X, 0, s.Y)
		end)
		parentFrame:GetPropertyChangedSignal("ZIndex"):Connect(updateZIndex)
	else
		error("Initialization error: argument " .. typeof(frame) .. " is not a Frame Instance")
	end
end

function Highlight:setRaw(raw)
	raw = raw .. "\n"
	tableContents = {}
	for i = 1, #raw do
		tableContents[i] = { Char = raw:sub(i, i), Color = defaultColor }
		if i % 1000 == 0 then RunService.Heartbeat:Wait() end
	end
	render()
end

function Highlight:getRaw() return getRaw() end

function Highlight:getString()
	local t = {}
	for _, c in next, tableContents do t[#t+1] = c.Char:sub(1, 1) end
	return table.concat(t)
end

function Highlight:getTable() return tableContents end
function Highlight:getSize() return #tableContents end

function Highlight:getLine(targetLine)
	local current, rightLine, result = 0, false, ""
	for _, v in next, tableContents do
		current += 1
		if v.Char == "\n" and not rightLine then rightLine = true end
		if rightLine and v.Char ~= "\n" then result = result .. v.Char
		elseif rightLine then break end
	end
	return result
end

function Highlight:setLine(targetLine, text)
	local str = getRaw()
	if #tableContents == 0 then return end
	if targetLine >= (tableContents[#tableContents].Line or 0) then
		str = str:sub(0, #str) .. text
		self:setRaw(str)
		return
	end
	local currentLine, lastStart = 0, 0
	for i in gfind(str, "\n") do
		currentLine += 1
		if targetLine == currentLine then
			self:setRaw(str:sub(0, lastStart) .. text .. str:sub(i, #str))
			return
		end
		lastStart = i
	end
	error("Unable to set line")
end

function Highlight:insertLine(targetLine, text)
	if #tableContents == 0 then return end
	local str = getRaw()
	local currentLine, lastStart = 0, 0
	for i in gfind(str, "\n") do
		currentLine += 1
		if targetLine == currentLine then
			self:setRaw(str:sub(0, lastStart) .. "\n" .. text .. "\n" .. str:sub(i, #str))
			return
		end
		lastStart = i
	end
	error("Unable to insert line")
end

local constructor = {}
function constructor.new(...)
	local new = setmetatable({}, {__index = Highlight})
	new:init(...)
	return new
end

return constructor
