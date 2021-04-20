---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL transfer `OnSystemCapabilitiesUpdated` notification from HMI to an App
-- which created a widget after `CreateWindow` response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) App creates new widget
-- SDL does:
--  - proceed with `CreateWindow` request successfully
--  - not send `OnSystemCapabilityUpdated` to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Functions ]]
local function sendCreateWindow()
  local createWindowParams = {
    windowID = 2,
    windowName = "Name",
    type = "WIDGET"
  }
  local cid = common.getMobileSession():SendRPC("CreateWindow", createWindowParams)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
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
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App sends CreateWindow RPC no OnSCU notification", sendCreateWindow)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
