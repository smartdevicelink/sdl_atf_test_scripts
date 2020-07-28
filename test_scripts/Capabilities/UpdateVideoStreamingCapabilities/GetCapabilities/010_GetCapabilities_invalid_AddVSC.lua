-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL applies default videoStreamingCapability in case HMI responds with videoStreamingCapability
--  that contains additionalVideoStreamingCapabilities array with incorrect parameters in single item
--
-- Preconditions:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--  and additionalVideoStreamingCapabilities array contains parameters with invalid type of value in single item
-- SDL does:
-- - a. ignore the videoStreamingCapability with additionalVideoStreamingCapabilities
--    received from HMI in UI.GetCapabilities response
-- - b. apply the default videoStreamingCapability from hmi_capabilities.json
-- 3. App registers with 5 transport protocol
-- 4. App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with the default videoStreamingCapability from hmi_capabilities.json
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local isSubscribe = false

local checks = { }

checks.invalid_type = common.buildVideoStreamingCapabilities(1)
checks.invalid_type.additionalVideoStreamingCapabilities[1].preferredResolution.resolutionWidth = true -- invalid type

checks.invalid_value = common.buildVideoStreamingCapabilities(2)
checks.invalid_value.additionalVideoStreamingCapabilities[1].maxBitrate = -1 -- invalid value

checks.invalid_nested_type = common.buildVideoStreamingCapabilities(2)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2] = common.buildVideoStreamingCapabilities(1)
checks.invalid_nested_type.additionalVideoStreamingCapabilities[2]
  .additionalVideoStreamingCapabilities[1].hapticSpatialDataSupported = 18 -- invalid type

checks.invalid_nested_value = common.buildVideoStreamingCapabilities(3)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2] = common.buildVideoStreamingCapabilities(2)
checks.invalid_nested_value.additionalVideoStreamingCapabilities[2]
  .additionalVideoStreamingCapabilities[2].scale = -1 -- invalid value

--[[ Scenario ]]
for type, value in pairs(checks) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities, { value })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerAppWOPTU)

  common.Title("Test")
  common.Step("App sends GetSystemCapability for VIDEO_STREAMING " .. type, common.getSystemCapability,
    { isSubscribe, appSessionId, common.getVscFromDefaultCapabilitiesFile() })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
