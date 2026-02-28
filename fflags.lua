local cloneref = cloneref or function(...) return ... end
local HttpService = cloneref(game:GetService("HttpService"))
local getgenv = getgenv or _G

getgenv().Bloxstrap = {}
local files = {}

local writefile = writefile or function(name, src)
    files[name] = src
end

local isfile = isfile or function(file)
    return readfile(file) ~= nil and true or false
end

getgenv().errorlog = getgenv().errorlog or "Bloxstrap/Logs/crashlog" .. HttpService:GenerateGUID(false) .. ".txt"

if not isfile("Bloxstrap/FFlags.json") then
    writefile("Bloxstrap/FFlags.json", "{}")
end

Bloxstrap.ToggleFFlag = loadstring(game:HttpGet("https://raw.githubusercontent.com/uwedot/files/refs/heads/main/ToggleFFlag.lua"))()
Bloxstrap.GetFFlag = loadstring(game:HttpGet("https://raw.githubusercontent.com/uwedot/files/refs/heads/main/GetFFlag.lua"))()
Bloxstrap.TouchEnabled = cloneref(game:GetService("UserInputService")).TouchEnabled

local flags = {
    ["DFIntCSGLevelOfDetailSwitchingDistanceL23"] = "0",
    ["DFFlagDisableDPIScale"] = "True",
    ["DFIntS2PhysicsSenderRate"] = "38000",
    ["FIntFontSizePadding"] = "3",
    ["DFIntMaxProcessPacketsStepsPerCyclic"] = "5000",
    ["DFIntWaitOnRecvFromLoopEndedMS"] = "100",
    ["FIntTerrainArraySliceSize"] = "0",
    ["DFIntRaknetBandwidthPingSendEveryXSeconds"] = "1",
    ["FIntGrassMovementReducedMotionFactor"] = "0",
    ["DFIntMegaReplicatorNetworkQualityProcessorUnit"] = "10",
    ["DFIntRakNetResendRttMultiple"] = "1",
    ["DFFlagDebugPauseVoxelizer"] = "True",
    ["DFIntTextureQualityOverride"] = "0",
    ["DFFlagTextureQualityOverrideEnabled"] = "True",
    ["FFlagDebugDisplayFPS"] = "True",
    ["FIntRakNetResendBufferArrayLength"] = "128",
    ["DFIntCSGLevelOfDetailSwitchingDistance"] = "0",
    ["FIntDebugForceMSAASamples"] = "0",
    ["DFIntPerformanceControlTextureQualityBestUtility"] = "-1",
    ["FFlagTaskSchedulerLimitTargetFpsTo2402"] = "False",
    ["DFIntLargePacketQueueSizeCutoffMB"] = "1000",
    ["FFlagDebugGraphicsPreferD3D11"] = "True",
    ["FIntFRMMinGrassDistance"] = "0",
    ["DFIntRaknetBandwidthInfluxHundredthsPercentageV2"] = "10000",
    ["FIntFullscreenTitleBarTriggerDelayMillis"] = "3600000",
    ["FFlagDebugSkyGray"] = "True",
    ["DFIntMaxProcessPacketsJobScaling"] = "10000",
    ["DFIntCodecMaxOutgoingFrames"] = "10000",
    ["DFIntCSGLevelOfDetailSwitchingDistanceL12"] = "0",
    ["DFIntCanHideGuiGroupId"] = "32380007",
    ["DFIntWaitOnUpdateNetworkLoopEndedMS"] = "100",
    ["FIntFRMMaxGrassDistance"] = "0",
    ["DFIntMaxProcessPacketsStepsAccumulated"] = "0",
    ["DFIntCSGLevelOfDetailSwitchingDistanceL34"] = "0",
    ["DFIntRakNetLoopMs"] = "1",
    ["DFIntDebugFRMQualityLevelOverride"] = "1",
    ["DFIntCodecMaxIncomingPackets"] = "100",
    ["FFlagHandleAltEnterFullscreenManually"] = "False",
}

for flag, value in pairs(flags) do
    local success, err = pcall(function()
        Bloxstrap.ToggleFFlag(flag, value)
    end)
    if not success then
        warn("Failed to set flag: " .. flag .. " | Error: " .. tostring(err))
    end
end