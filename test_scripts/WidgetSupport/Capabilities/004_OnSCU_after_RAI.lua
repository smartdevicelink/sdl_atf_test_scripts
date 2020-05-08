---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL transfer `OnSystemCapabilitiesUpdated` notification from HMI to an App
-- which is registered after `RAI` response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- Steps:
-- 1) App tries to register
-- SDL does:
--  - proceed with `RAI` request successfully
--  - not send `OnSystemCapabilityUpdated` to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Functions ]]
local function sendRegisterApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

local function sendOnSCU()
  local paramsToSDL = common.getOnSystemCapabilityParams()
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", common.getOnSystemCapabilityParams())
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("App sends RAI RPC no OnSCU notification", sendRegisterApp)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
