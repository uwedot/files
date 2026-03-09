local cloneref = cloneref or function(...) return ... end
local HttpService = cloneref(game:GetService("HttpService"))

getgenv().Bloxstrap = {}

getgenv().errorlog = getgenv().errorlog or "Bloxstrap/Logs/crashlog" .. HttpService:GenerateGUID(false) .. ".txt"

Bloxstrap.ToggleFFlag = loadstring(game:HttpGet("https://raw.githubusercontent.com/uwedot/flagging/refs/heads/main/ToggleFFlag.txt"))()
Bloxstrap.GetFFlag = loadstring(game:HttpGet("https://raw.githubusercontent.com/uwedot/flagging/refs/heads/main/GetFFlag.txt"))()
Bloxstrap.TouchEnabled = cloneref(game:GetService("UserInputService")).TouchEnabled

local flags = {
    ["DFIntCSGLevelOfDetailSwitchingDistanceL23"] = "0",
    ["DFFlagDebugPauseVoxelizer"] = "True",
    ["DFIntCSGLevelOfDetailSwitchingDistance"] = "0",
    ["DFFlagDebugPerfMode"] = "True",
    ["FFlagFastGPULightCulling3"] = "True",
    ["FFlagRenderNoLowFrmBloom"] = "False",
    ["DFIntMaxFrameBufferSize"] = "4",
    ["FIntFRMMinGrassDistance"] = "0",
    ["FFlagDebugForceFSMCPULightCulling"] = "True",
    ["FIntRenderLocalLightFadeInMs"] = "0",
    ["FIntDebugForceMSAASamples"] = "0",
    ["FFlagRenderLegacyShadowsQualityRefactor"] = "True",
    ["FIntBloomFrmCutoff"] = "-1",
    ["FFlagUserHideCharacterParticlesInFirstPerson"] = "True",
    ["FFlagDebugSkyGray"] = "True",
    ["DFIntCSGLevelOfDetailSwitchingDistanceL34"] = "0",
    ["FIntFRMMaxGrassDistance"] = "0",
    ["FIntRenderShadowmapBias"] = "-1",
    ["FIntTerrainArraySliceSize"] = "0",
    ["DFIntCSGLevelOfDetailSwitchingDistanceL12"] = "0",
    ["FFlagAdServiceEnabled"] = "False",
    ["FIntGrassMovementReducedMotionFactor"] = "0",
    ["FFlagDebugRenderingSetDeterministic"] = "True",
    ["FFlagHandleAltEnterFullscreenManually"] = "False",
}

writefile("Bloxstrap/FFlags.json", HttpService:JSONEncode({}))

for flag, value in pairs(flags) do
    Bloxstrap.ToggleFFlag(flag, value)
end