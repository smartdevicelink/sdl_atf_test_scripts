---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app will receive "GENERIC_ERROR" to the "DeleteWindow" request if HMI response is invalid
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow and DeleteWindow are allowed by policies
-- 3) App is registered and activated
-- 4) App successfully created a widget
-- Step:
-- 1) App sends valid DeleteWindow request to SDL
-- SDL does:
--  - send valid UI.DeleteWindow(param) request to HMI
-- 2) HMI response is invalid
-- SDL does:
--  - send DeleteWindow response with (success = false, resultCode = GENERIC_ERROR) to App
--  - not send OnSystemCapabilityUpdated and OnHMIStatus notifications to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 3,
  windowName = "Widget",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function deleteWindowUnsuccess(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = common.getMobileSession(pAppId):SendRPC("DeleteWindow", { windowID = params.windowID })

  params.appID = common.getHMIAppId(pAppId)
  common.getHMIConnection():ExpectRequest("UI.DeleteWindow", { windowID = params.windowID })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, 123, "SUCCESS", {}) -- invalid method
  end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })

  common.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Success create Window", common.createWindow, { params })

common.Title("Test")
common.Step("App sends DeleteWindow RPC", deleteWindowUnsuccess)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
