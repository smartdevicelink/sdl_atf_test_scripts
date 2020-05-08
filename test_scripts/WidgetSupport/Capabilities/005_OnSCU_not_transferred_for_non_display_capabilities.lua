---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check `OnSystemCapabilityUpdated` is not sent to App if non-Display capabilities updated
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) HMI sends `OnSystemCapabilityUpdated` to SDL for non-display capabilities
-- SDL does:
--  - not transfer `OnSystemCapabilityUpdated` notification to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL for display capabilities
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local systemCapabilityParams = {
  [1] = {
    systemCapabilityType = "NAVIGATION",
    navigationCapability = { }
  },
  [2] = {
    systemCapabilityType = "PHONE_CALL",
    phoneCapability = { }
  },
  [3] = {
    systemCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = { }
  },
  [4] = {
    systemCapabilityType = "REMOTE_CONTROL",
    remoteControlCapability = { }
  },
  [5] = {
    systemCapabilityType = "APP_SERVICES",
    appServicesCapabilities = { }
  },
  [6] = {
    systemCapabilityType = "DISPLAYS",
    displayCapabilities = { { } }
  }
}

--[[ Local Functions ]]
local function sendOnSCU(pParams)
  local params = {
    appID = common.getHMIAppId(),
    systemCapability = pParams
  }
  local qty = 0
  if pParams.systemCapabilityType == "DISPLAYS" then qty = 1 end
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", params)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(qty)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for i = 1, 5 do
  common.Step("SDL doesn't transfer OnSCU notification for "
    .. systemCapabilityParams[i].systemCapabilityType, sendOnSCU, { systemCapabilityParams[i] })
end

common.Step("SDL does transfer OnSCU notification for "
  .. systemCapabilityParams[6].systemCapabilityType, sendOnSCU, { systemCapabilityParams[6] })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
