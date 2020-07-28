-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL persists the videoStreamingCapability with additionalVideoStreamingCapabilities received from HMI
--  in UI.GetCapabilities response in case additionalVideoStreamingCapabilities parameter contains
--  nested additionalVideoStreamingCapabilities parameter
--
-- Preconditions:
-- 1. HMICapabilitiesCacheFile is set in smartDeviceLink.ini
-- 2. SDL and HMI are started
--
-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--  and additionalVideoStreamingCapabilities parameter contains nested additionalVideoStreamingCapabilities parameter
-- SDL does:
-- - a. cache the videoStreamingCapability with additionalVideoStreamingCapabilities
-- 2. It is restarted ignition cycle
-- SDL does:
-- - a. not requests UI.GetCapabilities()
-- 3. App registers with 5 transport protocol
-- 4. App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with videoStreamingCapability that contains
--    the additionalVideoStreamingCapabilities from cache
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local isSubscribe = false
local appSessionId = 1

local vsc = common.buildVideoStreamingCapabilities(2)
local tmpVsc = vsc
for i = 1, 5, 1 do
  tmpVsc.additionalVideoStreamingCapabilities[1] = common.buildVideoStreamingCapabilities(i)
  tmpVsc = tmpVsc.additionalVideoStreamingCapabilities[1]
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
  { "HMICapabilitiesCacheFile", "hmi_capabilities_cache.json" })
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities, { vsc })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, SDL doesn't send HMI capabilities requests to HMI",
  common.start, { common.getHMIParamsWithOutRequests() })
common.Step("Register App", common.registerAppWOPTU)
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { isSubscribe, appSessionId, vsc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
