local cloneref = cloneref or function(...) return ... end
local HttpService = cloneref(game.GetService(game, "HttpService"))
return function(flag: string, value: string): (string, string) -> ()
	local type = type or typeof
	if type(flag) ~= "string" then return task.spawn(error, "string expected, got "..type(flag)) end
	local FFlag: string = Bloxstrap.TouchEnabled and flag:gsub("DFInt", ""):gsub("DFFlag", ""):gsub("FFlag", ""):gsub("FInt", ""):gsub("DFString", ""):gsub("FString", "") or flag --> Removes the keyword of the FFlag, setfflag doesn't like those so we will need to remove it.
	
	if getfflag(FFlag) ~= nil then
		local fflagfile = HttpService:JSONDecode(readfile("Bloxstrap/FFlags.json"))
		fflagfile[flag] = tostring(value)
		writefile("Bloxstrap/FFlags.json", HttpService:JSONEncode(fflagfile))
		return setfflag(FFlag, tostring(value))
	else
		local err = isfile(errorlog) and readfile(errorlog) or "Error while loading FFlags: "
		return writefile(errorlog, err.."\nFFlag expected, got "..FFlag)
	end
end;