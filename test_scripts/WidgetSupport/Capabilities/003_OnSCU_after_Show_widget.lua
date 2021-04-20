---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL transfer `OnSystemCapabilitiesUpdated` notification from HMI to an App
-- which sent `Show` RPC with `templateConfiguration` parameter for widget window after `Show` response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) App creates new widget
-- Steps:
-- 1) App sends `Show` request with `templateConfiguration` for widget window
-- SDL does:
--  - proceed with `Show` request successfully
--  - not send `OnSystemCapabilityUpdated` to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local createWindowParams = {
  windowID = 1,
  windowName = "Name",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function sendShow()
  local showParams = {
    mainField1 = "MainField1",
    windowID = createWindowParams.windowID,
    templateConfiguration = {
      template = "Template1"
    }
  }
  local cid = common.getMobileSession():SendRPC("Show", showParams)
  common.getHMIConnection():ExpectRequest("UI.Show")
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
common.Step("Create widget", common.createWindow, { createWindowParams })
common.Step("Activate widget", common.activateWidgetFromNoneToFULL, { createWindowParams.windowID })

common.Title("Test")
common.Step("App sends Show RPC no OnSCU notification", sendShow)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
