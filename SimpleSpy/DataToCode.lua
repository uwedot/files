--!optimize 2
--!native

local assert, type, typeof, rawset, getmetatable, tostring = assert, type, typeof, rawset, getmetatable, tostring
local print, warn, pack, unpack, next = print, warn, table.pack, unpack, next
local IsSharedFrozen, SharedSize = SharedTable.isFrozen, SharedTable.size
local bufftostring, fromstring, readu8 = buffer.tostring, buffer.fromstring, buffer.readu8
local isfrozen, concat = table.isfrozen, table.concat
local FindService = game.FindService
local info = debug.info
local IsClient = game:GetService("RunService"):IsClient()
local Players = game:GetService("Players")
local inf, neginf = math.huge, -math.huge

local DefaultMethods = {}
local Methods = setmetatable({}, {__index = DefaultMethods})
local Class = {
	Methods = Methods,
	__tostringUnsupported = false,
	__Serializeinf = false
}

local Keywords = {
	["local"]="\"local\"",["function"]="\"function\"",["and"]="\"and\"",["break"]="\"break\"",
	["not"]="\"not\"",["or"]="\"or\"",["else"]="\"else\"",["elseif"]="\"elseif\"",["if"]="\"if\"",
	["then"]="\"then\"",["until"]="\"until\"",["repeat"]="\"repeat\"",["while"]="\"while\"",
	["do"]="\"do\"",["for"]="\"for\"",["in"]="\"in\"",["end"]="\"end\"",["return"]="\"return\"",
	["true"]="\"true\"",["false"]="\"false\"",["nil"]="\"nil\""
}

local islclosure = islclosure or function(f) return info(f, "l") ~= -1 end

local DefaultVectors, DefaultCFrames = {}, {}
do
	local function ExtractTypes(From, Path, DataType, Storage)
		Storage = Storage or setmetatable({}, {__mode = "k"})
		for i, v in next, From do
			if typeof(v) == DataType and not Storage[v] and type(i) == "string" and not Keywords[i] and not i:match("[a-Z_][a-Z_0-9]") then
				Storage[v] = Path .. "." .. i
			end
		end
		return Storage
	end
	ExtractTypes(vector, "vector", "Vector3", DefaultVectors)
	ExtractTypes(Vector3, "Vector3", "Vector3", DefaultVectors)
	ExtractTypes(CFrame, "CFrame", "CFrame", DefaultCFrames)
	Class.DefaultTypes = { Vector3 = DefaultVectors, CFrame = DefaultCFrames }
end

local function Serialize(DataStructure, format, indents, CyclicList, InComment)
	local DataHandler = Methods[typeof(DataStructure)]
	return DataHandler and DataHandler(DataStructure, format, indents, CyclicList, InComment)
		or "nil --[" .. (InComment and "=" or "") .. "[ Unsupported Data Type | " .. typeof(DataStructure)
		.. (Class.__tostringUnsupported and " | " .. tostring(DataStructure) or "") .. " ]"
		.. (InComment and "=" or "") .. "]"
end

-- Shared identifier-validation logic
local function ValidateIdentifier(Index, isNumber, wrapResult)
	if not isNumber and Index == "" then return "[\"\"] = " end
	local buf = fromstring(tostring(Index))
	local b0 = readu8(buf, 0)
	if (b0 >= 97 and b0 <= 122) or (b0 >= 65 and b0 <= 90) or b0 == 95 then
		for i = 1, #tostring(Index) - 1 do
			local b = readu8(buf, i)
			if not ((b >= 97 and b <= 122) or (b >= 65 and b <= 90) or b == 95 or (b >= 48 and b <= 57)) then
				return "[" .. Methods.string(tostring(Index)) .. "] = "
			end
		end
		return tostring(Index) .. " = "
	end
	return "[" .. Methods.string(tostring(Index)) .. "] = "
end

local function ValidateSharedTableIndex(Index)
	local IsKeyword = type(Index) == "number" and Index or Keywords[Index]
	if IsKeyword then return "[" .. IsKeyword .. "] = " end
	return ValidateIdentifier(Index, false)
end

local function ValidateIndex(Index)
	local t = type(Index)
	if t == "number" or t == "string" then
		local IsKeyword = t == "number" and Index or Keywords[Index]
		if IsKeyword then return "[" .. IsKeyword .. "] = " end
		return ValidateIdentifier(Index, t == "number")
	end
	return "[" .. (t ~= "table" and Serialize(Index, false, "")
		or "\"<Table> (table: " .. (getmetatable(Index) == nil and tostring(Index):sub(8) or "@metatable") .. ")\"") .. "] = "
end

function DefaultMethods.Axes(Axes)
	return "Axes.new(" .. concat({
		Axes.X and "Enum.Axis.X" or nil,
		Axes.Y and "Enum.Axis.Y" or nil,
		Axes.Z and "Enum.Axis.Z" or nil
	}, ", ") .. ")"
end

function DefaultMethods.BrickColor(Color)
	return "BrickColor.new(" .. Color.Number .. ")"
end

function DefaultMethods.CFrame(CFrame)
	if DefaultCFrames[CFrame] then return DefaultCFrames[CFrame] end
	local N = Methods.number
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()
	return "CFrame.new(" .. N(x) .. ", " .. N(y) .. ", " .. N(z) .. ", "
		.. N(R00) .. ", " .. N(R01) .. ", " .. N(R02) .. ", "
		.. N(R10) .. ", " .. N(R11) .. ", " .. N(R12) .. ", "
		.. N(R20) .. ", " .. N(R21) .. ", " .. N(R22) .. ")"
end

do
	local DefaultCatalogSearchParams = CatalogSearchParams.new()
	function DefaultMethods.CatalogSearchParams(Params, format, indents)
		if DefaultCatalogSearchParams == Params then return "CatalogSearchParams.new()" end
		local fs = format and "\n" .. indents or " "
		local S = Methods.string
		local function emit(cond, str) return cond and str .. fs or "" end
		return "(function(Param : CatalogSearchParams)" .. fs
			.. emit(Params.SearchKeyword ~= "", "\tParam.SearchKeyword = " .. S(Params.SearchKeyword))
			.. emit(Params.MinPrice ~= 0, "\tParam.MinPrice = " .. Params.MinPrice)
			.. emit(Params.MaxPrice ~= 2147483647, "\tParam.MaxPrice = " .. Params.MaxPrice)
			.. emit(Params.SortType ~= Enum.CatalogSortType.Relevance, "\tParam.SortType = Enum.CatalogSortType." .. Params.SortType.Name)
			.. emit(Params.SortAggregation ~= Enum.CatalogSortAggregation.AllTime, "\tParam.SortAggregation = Enum.CatalogSortAggregation." .. Params.SortAggregation.Name)
			.. emit(Params.CategoryFilter ~= Enum.CatalogCategoryFilter.None, "\tParam.CategoryFilter = Enum.CatalogCategoryFilter." .. Params.CategoryFilter.Name)
			.. emit(Params.SalesTypeFilter ~= Enum.SalesTypeFilter.All, "\tParam.SalesTypeFilter = Enum.SalesTypeFilter." .. Params.SalesTypeFilter.Name)
			.. emit(#Params.BundleTypes > 0, "\tParam.BundleTypes = " .. Methods.table(Params.BundleTypes, false, ""))
			.. emit(#Params.AssetTypes > 0, "\tParam.AssetTypes = " .. Methods.table(Params.AssetTypes, false, ""))
			.. emit(Params.IncludeOffSale, "\tParams.IncludeOffSale = true")
			.. emit(Params.CreatorName ~= "", "\tParams.CreatorName = " .. S(Params.CreatorName))
			.. emit(Params.CreatorType ~= Enum.CreatorTypeFilter.All, "\tParam.CreatorType = Enum.CreatorTypeFilter." .. Params.CreatorType.Name)
			.. emit(Params.CreatorId ~= 0, "\tParams.CreatorId = " .. Params.CreatorId)
			.. emit(Params.Limit ~= 30, "\tParams.Limit = " .. Params.Limit)
			.. "\treturn Params" .. fs .. "end)(CatalogSearchParams.new())"
	end
end

function DefaultMethods.Color3(Color)
	local N = Methods.number
	return "Color3.new(" .. N(Color.R) .. ", " .. N(Color.G) .. ", " .. N(Color.B) .. ")"
end

local function SerializeKeypoints(Keypoints, Serializer)
	local Size = #Keypoints
	local parts = {}
	for i = 1, Size do parts[i] = Serializer(Keypoints[i]) end
	return concat(parts, ", ")
end

function DefaultMethods.ColorSequence(Sequence)
	return "ColorSequence.new({" .. SerializeKeypoints(Sequence.Keypoints, Methods.ColorSequenceKeypoint) .. "})"
end

function DefaultMethods.ColorSequenceKeypoint(kp)
	return "ColorSequenceKeypoint.new(" .. Methods.number(kp.Time) .. ", " .. Methods.Color3(kp.Value) .. ")"
end

function DefaultMethods.Content(content)
	local Uri = content.Uri
	return Uri and "Content.fromUri(" .. Uri .. ")" or "Content.none"
end

function DefaultMethods.DateTime(Date)
	return "DateTime.fromUnixTimestampMillis(" .. Date.UnixTimestampMillis .. ")"
end

function DefaultMethods.DockWidgetPluginGuiInfo(Dock)
	local it = tostring(Dock):gmatch(":([%w%-]+)")
	return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState." .. it() .. ", "
		.. (it() == "1" and "true" or "false") .. ", "
		.. (it() == "1" and "true" or "false") .. ", "
		.. it() .. ", " .. it() .. ", " .. it() .. ", " .. it() .. ")"
end

function DefaultMethods.Enum(e) return "Enums." .. tostring(e) end

do
	local Enums = {}
	for _, v in Enum:GetEnums() do Enums[v] = "Enum." .. tostring(v) end
	function DefaultMethods.EnumItem(Item) return Enums[Item.EnumType] .. "." .. Item.Name end
end

function DefaultMethods.Enums() return "Enums" end

function DefaultMethods.Faces(Faces)
	return "Faces.new(" .. concat({
		Faces.Top and "Enum.NormalId.Top" or nil,
		Faces.Bottom and "Enum.NormalId.Bottom" or nil,
		Faces.Left and "Enum.NormalId.Left" or nil,
		Faces.Right and "Enum.NormalId.Right" or nil,
		Faces.Back and "Enum.NormalId.Back" or nil,
		Faces.Front and "Enum.NormalId.Front" or nil,
	}, ", ") .. ")"
end

function DefaultMethods.FloatCurveKey(CurveKey)
	local N = Methods.number
	return "FloatCurveKey.new(" .. N(CurveKey.Time) .. ", " .. N(CurveKey.Value) .. ", Enum.KeyInterpolationMode." .. CurveKey.Interpolation.Name .. ")"
end

function DefaultMethods.Font(Font)
	return "Font.new(" .. Methods.string(Font.Family) .. ", Enum.FontWeight." .. Font.Weight.Name .. ", Enum.FontStyle." .. Font.Style.Name .. ")"
end

do
	local Services = {
		Workspace = "workspace", Lighting = "game.lighting", GlobalSettings = "settings()",
		Stats = "stats()", UserSettings = "UserSettings()", PluginManagerInterface = "PluginManager()",
		DebuggerManager = "DebuggerManager()"
	}

	local function InstancePath(obj)
		local parent, className = obj.Parent, obj.ClassName
		if not parent then
			return className == "DataModel" and "game" or "Instance.new(\"" .. className .. "\", nil)"
		end
		local name = Methods.string(obj.Name)
		if className ~= "Model" and className ~= "Player" then
			local ok, svc = pcall(FindService, game, className)
			return (not ok or not svc) and InstancePath(parent) .. ":WaitForChild(" .. name .. ")"
				or Services[className] or "game:GetService(\"" .. className .. "\")"
		elseif className == "Model" then
			local player = Players:GetPlayerFromCharacter(obj)
			if not player then return InstancePath(parent) .. ":WaitForChild(" .. name .. ")" end
			if IsClient then
				local LocalPlayer = Players.LocalPlayer
				return "game:GetService(\"Players\")" .. (player == LocalPlayer and ".LocalPlayer.Character" or ":WaitForChild(" .. name .. ").Character")
			else
				return "game:GetService(\"Players\"):WaitForChild(" .. name .. ").Character"
			end
		end
		if IsClient then
			local LocalPlayer = Players.LocalPlayer
			return "game:GetService(\"Players\")" .. (obj == LocalPlayer and ".LocalPlayer" or ":WaitForChild(" .. name .. ")")
		end
		return "game:GetService(\"Players\"):WaitForChild(" .. name .. ")"
	end

	if IsClient then
		Players:GetPropertyChangedSignal("LocalPlayer"):Once(function() end) -- ensure LocalPlayer loaded
	end

	DefaultMethods.Instance = InstancePath
	Class.Services = Services
end

function DefaultMethods.NumberRange(Range)
	local N = Methods.number
	return "NumberRange.new(" .. N(Range.Min) .. ", " .. N(Range.Max) .. ")"
end

function DefaultMethods.NumberSequence(Sequence)
	return "NumberSequence.new({" .. SerializeKeypoints(Sequence.Keypoints, Methods.NumberSequenceKeypoint) .. "})"
end

function DefaultMethods.NumberSequenceKeypoint(kp)
	local N = Methods.number
	return "NumberSequenceKeypoint.new(" .. N(kp.Time) .. ", " .. N(kp.Value) .. ", " .. N(kp.Envelope) .. ")"
end

local function ParamSerializer(TypeName, Default, fields)
	return function(Params, format, indents)
		if Default == Params then return TypeName .. ".new()" end
		local fs = format and "\n" .. indents or " "
		local result = "(function(Param : " .. TypeName .. ")" .. fs
		for _, field in ipairs(fields) do
			local cond, str = field(Params, fs)
			if cond then result = result .. str .. fs end
		end
		return result .. "\treturn Params" .. fs .. "end)(" .. TypeName .. ".new())"
	end
end

do
	local DefaultOverlapParams = OverlapParams.new()
	DefaultMethods.OverlapParams = ParamSerializer("OverlapParams", DefaultOverlapParams, {
		function(P, fs) return #P.FilterDescendantsInstances > 0, "\tParam.FilterDescendantsInstances = " .. Methods.table(P.FilterDescendantsInstances, false, "") end,
		function(P) return P.FilterType ~= Enum.RaycastFilterType.Exclude, "\tParam.FilterType = Enum.RaycastFilterType." .. P.FilterType.Name end,
		function(P) return P.CollisionGroup ~= "Default", "\tParam.CollisionGroup = " .. Methods.string(P.CollisionGroup) end,
		function(P) return P.RespectCanCollide, "\tParam.RespectCanCollide = true" end,
		function(P) return P.BruteForceAllSlow, "\tParam.BruteForceAllSlow = true" end,
	})
end

do
	local DefaultRaycastParams = RaycastParams.new()
	DefaultMethods.RaycastParams = ParamSerializer("RaycastParams", DefaultRaycastParams, {
		function(P) return #P.FilterDescendantsInstances > 0, "\tParam.FilterDescendantsInstances = " .. Methods.table(P.FilterDescendantsInstances, false, "") end,
		function(P) return P.FilterType ~= Enum.RaycastFilterType.Exclude, "\tParam.FilterType = Enum.RaycastFilterType." .. P.FilterType.Name end,
		function(P) return P.IgnoreWater, "\tParam.IgnoreWater = true" end,
		function(P) return P.CollisionGroup ~= "Default", "\tParam.CollisionGroup = " .. Methods.string(P.CollisionGroup) end,
		function(P) return P.RespectCanCollide, "\tParam.RespectCanCollide = true" end,
		function(P) return P.BruteForceAllSlow, "\tParam.BruteForceAllSlow = true" end,
	})
end

function DefaultMethods.PathWaypoint(Waypoint)
	return "PathWaypoint.new(" .. Methods.Vector3(Waypoint.Position) .. ", Enum.PathWaypointAction." .. Waypoint.Action.Name .. ", " .. Methods.string(Waypoint.Label) .. ")"
end

do
	local function nanToString(n) return n == n and n or "0/0" end
	function DefaultMethods.PhysicalProperties(P)
		return "PhysicalProperties.new(" .. nanToString(P.Density) .. ", " .. nanToString(P.Friction) .. ", " .. nanToString(P.Elasticity) .. ", " .. nanToString(P.FrictionWeight) .. ", " .. nanToString(P.ElasticityWeight) .. ")"
	end
end

local function CommentSep(InComment) return InComment and "=" or "" end

function DefaultMethods.RBXScriptConnection(Connection, _, _, _, InComment)
	local s = CommentSep(InComment)
	return "(nil --[" .. s .. "[ RBXScriptConnection | IsConnected: " .. (Connection.Connected and "true" or "false") .. " ]" .. s .. "])"
end

do
	local Signals = {
		GraphicsQualityChangeRequest="game.GraphicsQualityChangeRequest",AllowedGearTypeChanged="game.AllowedGearTypeChanged",
		ScreenshotSavedToAlbum="game.ScreenshotSavedToAlbum",UniverseMetadataLoaded="game.UniverseMetadataLoaded",
		ScreenshotReady="game.ScreenshotReady",ServiceRemoving="game.ServiceRemoving",ServiceAdded="game.ServiceAdded",
		ItemChanged="game.ItemChanged",CloseLate="game.CloseLate",Loaded="game.Loaded",Close="game.Close",
		RobloxGuiFocusedChanged="game:GetService(\"RunService\").RobloxGuiFocusedChanged",
		PostSimulation="game:GetService(\"RunService\").PostSimulation",
		RenderStepped="game:GetService(\"RunService\").RenderStepped",
		PreSimulation="game:GetService(\"RunService\").PreSimulation",
		PreAnimation="game:GetService(\"RunService\").PreAnimation",
		PreRender="game:GetService(\"RunService\").PreRender",
		Heartbeat="game:GetService(\"RunService\").Heartbeat",
		Stepped="game:GetService(\"RunService\").Stepped"
	}
	function DefaultMethods.RBXScriptSignal(Signal, _, _, _, InComment)
		local s = CommentSep(InComment)
		local name = tostring(Signal):match("Signal (%a+)")
		return Signals[name] or "(nil --[" .. s .. "[ RBXScriptSignal | " .. name .. " is not supported ]" .. s .. "])"
	end
	Class.Signals = Signals
end

function DefaultMethods.Random(_, _, _, _, InComment)
	local s = CommentSep(InComment)
	return "Random.new(--[" .. s .. "[ <Seed> ]" .. s .. "])"
end

function DefaultMethods.Ray(Ray)
	local V = Methods.Vector3
	return "Ray.new(" .. V(Ray.Origin) .. ", " .. V(Ray.Direction) .. ")"
end

function DefaultMethods.Rect(Rect)
	local V = Methods.Vector2
	return "Rect.new(" .. V(Rect.Min) .. ", " .. V(Rect.Max) .. ")"
end

function DefaultMethods.Region3(Region)
	local V = Methods.Vector3
	local Center, Size = Region.CFrame.Position, Region.Size / 2
	return "Region3.new(" .. V(Center - Size) .. ", " .. V(Center + Size) .. ")"
end

function DefaultMethods.Region3int16(Region)
	local V = Methods.Vector3int16
	return "Region3int16.new(" .. V(Region.Min) .. ", " .. V(Region.Max) .. ")"
end

function DefaultMethods.RotationCurveKey(Curve)
	return "RotationCurveKey.new(" .. Methods.number(Curve.Time) .. ", " .. Methods.CFrame(Curve.Value) .. ", Enum.KeyInterpolationMode." .. Curve.Interpolation.Name .. ")"
end

function DefaultMethods.SharedTable(Shared, format, indents, _, InComment)
	local isreadonly = IsSharedFrozen(Shared)
	local wrap = isreadonly and function(s) return "SharedTable.cloneAndFreeze(SharedTable.new(" .. s .. "))" end
		or function(s) return "SharedTable.new(" .. s .. ")" end
	if SharedSize(Shared) == 0 then return wrap("") end
	local stackindent = indents .. (format and "\t" or "")
	local CurrentIndex, Serialized = 1, {}
	for i, v in Shared do
		Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateSharedTableIndex(i) or "") .. Serialize(v, format, stackindent, nil, InComment)
		CurrentIndex += 1
	end
	local fs = format and "\n" or ""
	return wrap(fs .. stackindent .. concat(Serialized, (format and ",\n" or ", ") .. stackindent) .. fs .. indents)
end

function DefaultMethods.TweenInfo(Info)
	return "TweenInfo.new(" .. Methods.number(Info.Time) .. ", Enum.EasingStyle." .. Info.EasingStyle.Name .. ", Enum.EasingDirection." .. Info.EasingDirection.Name .. ", " .. Info.RepeatCount .. ", " .. (Info.Reverses and "true" or "false") .. ", " .. Methods.number(Info.DelayTime) .. ")"
end

function DefaultMethods.UDim(UDim)
	return "UDim.new(" .. Methods.number(UDim.Scale) .. ", " .. UDim.Offset .. ")"
end

function DefaultMethods.UDim2(UDim2)
	local N, X, Y = Methods.number, UDim2.X, UDim2.Y
	return "UDim2.new(" .. N(X.Scale) .. ", " .. X.Offset .. ", " .. N(Y.Scale) .. ", " .. Y.Offset .. ")"
end

function DefaultMethods.Vector2(Vector)
	local N = Methods.number
	return "Vector2.new(" .. N(Vector.X) .. ", " .. N(Vector.Y) .. ")"
end

function DefaultMethods.Vector2int16(Vector)
	return "Vector2int16.new(" .. Vector.X .. ", " .. Vector.Y .. ")"
end

function DefaultMethods.Vector3(Vector)
	local N = Methods.number
	return DefaultVectors[Vector] or "vector.create(" .. N(Vector.X) .. ", " .. N(Vector.Y) .. ", " .. N(Vector.Z) .. ")"
end

function DefaultMethods.Vector3int16(Vector)
	return "Vector3int16.new(" .. Vector.X .. ", " .. Vector.Y .. ", " .. Vector.Z .. ")"
end

function DefaultMethods.boolean(bool) return bool and "true" or "false" end

function DefaultMethods.buffer(buff)
	return "buffer.fromstring(" .. Methods.string(bufftostring(buff)) .. ")"
end

do
	local GlobalFunctions = {}
	do
		local getrenv = getrenv or (function()
			local env = {
				bit32=bit32,buffer=buffer,coroutine=coroutine,debug=debug,math=math,os=os,string=string,table=table,utf8=utf8,
				Content=Content,Axes=Axes,AdReward=AdReward,BrickColor=BrickColor,CatalogSearchParams=CatalogSearchParams,
				CFrame=CFrame,Color3=Color3,ColorSequence=ColorSequence,ColorSequenceKeypoint=ColorSequenceKeypoint,
				DateTime=DateTime,DockWidgetPluginGuiInfo=DockWidgetPluginGuiInfo,Faces=Faces,FloatCurveKey=FloatCurveKey,
				Font=Font,Instance=Instance,NumberRange=NumberRange,NumberSequence=NumberSequence,
				NumberSequenceKeypoint=NumberSequenceKeypoint,OverlapParams=OverlapParams,PathWaypoint=PathWaypoint,
				PhysicalProperties=PhysicalProperties,Random=Random,Ray=Ray,RaycastParams=RaycastParams,Rect=Rect,
				Region3=Region3,Region3int16=Region3int16,RotationCurveKey=RotationCurveKey,SharedTable=SharedTable,
				task=task,TweenInfo=TweenInfo,UDim=UDim,UDim2=UDim2,Vector2=Vector2,Vector2int16=Vector2int16,
				Vector3=Vector3,vector=vector,Vector3int16=Vector3int16,CellId=CellId,PluginDrag=PluginDrag,
				SecurityCapabilities=SecurityCapabilities,assert=assert,error=error,getfenv=getfenv,getmetatable=getmetatable,
				ipairs=ipairs,loadstring=loadstring,newproxy=newproxy,next=next,pairs=pairs,pcall=pcall,print=print,
				rawequal=rawequal,rawget=rawget,rawlen=rawlen,rawset=rawset,select=select,setfenv=setfenv,
				setmetatable=setmetatable,tonumber=tonumber,tostring=tostring,unpack=unpack,xpcall=xpcall,
				collectgarbage=collectgarbage,delay=delay,gcinfo=gcinfo,PluginManager=PluginManager,
				DebuggerManager=DebuggerManager,require=require,settings=settings,spawn=spawn,tick=tick,time=time,
				UserSettings=UserSettings,wait=wait,warn=warn,Delay=Delay,ElapsedTime=ElapsedTime,
				elapsedTime=elapsedTime,printidentity=printidentity,Spawn=Spawn,Stats=Stats,stats=stats,
				Version=Version,version=version,Wait=Wait
			}
			return function() return env end
		end)()

		local Visited = setmetatable({}, {__mode = "k"})
		for i, v in getrenv() do
			local t = type(i) == "string" and type(v)
			if not t then continue end
			if t == "table" then
				local function LoadLibrary(Path, tbl)
					if Visited[tbl] then return end
					Visited[tbl] = true
					for k, x in next, tbl do
						local xtype = type(k) == "string" and not Keywords[k] and k:match("[A-z_][A-z_0-9]") and type(x)
						local newPath = xtype and (xtype == "function" or xtype == "table") and Path .. "." .. k
						if newPath then
							if xtype == "function" then GlobalFunctions[x] = newPath
							else LoadLibrary(newPath, x) end
						end
					end
					Visited[tbl] = nil
				end
				LoadLibrary(i, v)
				table.clear(Visited)
			elseif t == "function" then
				GlobalFunctions[v] = i
			end
		end
		Class.GlobalFunctions = GlobalFunctions
	end

	DefaultMethods["function"] = function(Function, format, indents, _, InComment)
		local IsGlobal = GlobalFunctions[Function]
		if IsGlobal then return IsGlobal end
		if format then
			local S = Methods.string
			local cs = CommentSep(InComment)
			local ti = indents .. "\t\t\t"
			local nl = ",\n" .. ti
			local source, line, name, numparams, vargs = info(Function, "slna")
			return "function()" .. (line ~= -1 and "" or " --[" .. cs .. "[ CClosure " .. name .. " ]" .. cs .. "]")
				.. "\n\t" .. indents .. "--[" .. cs .. "[\n\t\t" .. indents .. "info = {\n"
				.. ti .. "source = " .. S(source) .. nl .. "line = " .. line .. nl
				.. "what = " .. (line ~= -1 and "\"Lua\"" or "\"C\"") .. nl
				.. "name = " .. S(name) .. nl .. "numparams = " .. numparams .. nl
				.. "vargs = " .. (vargs and "true" or "false") .. nl .. "function = " .. tostring(Function)
				.. "\n\t\t" .. indents .. "}\n\t" .. indents .. "]" .. cs .. "]\n" .. indents .. "end"
		end
		return islclosure(Function) and "function() end"
			or "function() --[" .. CommentSep(InComment) .. "[ CClosure " .. info(Function, "n") .. " ]" .. CommentSep(InComment) .. "] end"
	end
end

function DefaultMethods.table(tbl, format, indents, CyclicList, InComment)
	CyclicList = CyclicList or setmetatable({}, {__mode = "k"})
	if CyclicList[tbl] then return "*** cycle table reference detected ***" end
	local isreadonly = isfrozen(tbl)
	local Index, Value = next(tbl)
	if Index == nil then
		return isreadonly and "table.freeze({})" or "{}"
	end
	local Indents = indents .. (format and "\t" or "")
	local Ending = format and ",\n" or ", "
	local fs = format and "\n" or ""
	local Generation = "{" .. fs
	local CurrentIndex = 1
	CyclicList[tbl] = true
	repeat
		Generation ..= Indents .. (CurrentIndex ~= Index and ValidateIndex(Index) or "") .. Serialize(Value, format, Indents, CyclicList, InComment)
		Index, Value = next(tbl, Index)
		Generation ..= Index ~= nil and Ending or fs .. indents .. "}"
		CurrentIndex += 1
	until Index == nil
	CyclicList[tbl] = nil
	return isreadonly and "table.freeze(" .. Generation .. ")" or Generation
end

DefaultMethods["nil"] = function() return "nil" end

function DefaultMethods.number(num)
	if num ~= inf and num ~= neginf and num == num then return tostring(num) end
	if num == inf then return Class.__Serializeinf and "math.huge" or "1/0" end
	if num == neginf then return Class.__Serializeinf and "-math.huge" or "-1/0" end
	return "0/0"
end

do
	local ByteList = {
		["\a"]="\\a",["\b"]="\\b",["\t"]="\\t",["\n"]="\\n",["\v"]="\\v",
		["\f"]="\\f",["\r"]="\\r",["\""]="\\\"",["\\"]="\\\\",
	}
	for i = 0, 255 do
		local c = string.char(i)
		if not ByteList[c] and (i < 32 or i > 126) then
			ByteList[c] = ("\\%03d"):format(i)
		end
	end
	function DefaultMethods.string(RawString)
		return "\"" .. RawString:gsub("[\0-\31\34\92\127-\255]", ByteList) .. "\""
	end
end

function DefaultMethods.thread() return "coroutine.create(function() end)" end

function DefaultMethods.userdata(u)
	return getmetatable(u) ~= nil and "newproxy(true)" or "newproxy(false)"
end

do
	local SecurityCapabilityEnums = Enum.SecurityCapability:GetEnumItems()
	function DefaultMethods.SecurityCapabilities(Capabilities)
		local Contains, idx = {}, 1
		for _, v in SecurityCapabilityEnums do
			if Capabilities:Contains(v) then
				Contains[idx] = "Enum.SecurityCapability." .. v.Name
				idx += 1
			end
		end
		return "SecurityCapabilities.new(" .. concat(Contains, ", ") .. ")"
	end
end

function DefaultMethods.PluginDrag(Drag)
	local S = Methods.string
	return "PluginDrag.new(" .. S(Drag.Sender) .. ", " .. S(Drag.MimeType) .. ", " .. S(Drag.Data) .. ", " .. S(Drag.MouseIcon) .. ", " .. S(Drag.DragIcon) .. ", " .. Methods.Vector2(Drag.HotSpot) .. ")"
end

function DefaultMethods.CellId(_, _, _, _, InComment)
	local s = InComment and "=" or ""
	return "CellId.new(--[" .. s .. "[ Undocumented ]" .. s .. "])"
end

local function Serializevargs(...)
	local tbl = pack(...)
	local GenerationSize = 0
	for i = 1, #tbl do
		local g = Serialize(tbl[i], true, "")
		tbl[i] = g
		GenerationSize += #g
		if GenerationSize > 100000 then break end
	end
	return unpack(tbl, 1, tbl.n)
end

function Class.Convert(DataStructure, format) return Serialize(DataStructure, format, "") end
function Class.ConvertKnown(DataType, DataStructure, format) return Methods[DataType](DataStructure, format, "") end
function Class.print(...) print(Serializevargs(...)) end
function Class.warn(...) warn(Serializevargs(...)) end

if type(setclipboard) == "function" then
	local setclipboard = setclipboard
	function Class.setclipboard(DataStructure, format) setclipboard(Serialize(DataStructure, format, "")) end
end

return setmetatable(Class, { __tostring = "DataToCode" })
