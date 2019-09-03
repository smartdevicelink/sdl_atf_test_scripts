---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app will receive GENERIC_ERROR to the CreateWindow request if HMI doesn't respond
-- within the default timeout
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App sends valid CreateWindow request to SDL
-- SDL does:
--  - send valid UI.CreateWindow(params) request to HMI
-- 2) HMI doesn't send UI.CreateWindow response
-- SDL does:
--  - send CreateWindow response with (success = false, resultCode = GENERIC_ERROR") to App
--  - not send OnSystemCapabilityUpdated and OnHMIStatus notifications to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Functions ]]
local function createWindowUnsuccess(pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    windowID = 2,
    windowName = "Name",
    type = "WIDGET"
  }
  local cid = common.getMobileSession(pAppId):SendRPC("CreateWindow", params)

  params.appID = common.getHMIAppId(pAppId)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow", params)
  :Do(function()
    -- HMI did not respond
  end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })

  common.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)

  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("HMI does not respond to CreateWindow request", createWindowUnsuccess)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
