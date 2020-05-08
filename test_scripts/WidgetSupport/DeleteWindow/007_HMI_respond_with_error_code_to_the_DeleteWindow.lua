---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app will receive "errorCode_n" to the "DeleteWindow" request if HMI responds with error code
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
-- 2) HMI sends UI.DeleteWindow response with "errorCode_n" to SDL
-- SDL does:
--  - send DeleteWindow response with (success = false, resultCode = errorCode_n) to App
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

local errorCode = {
  "UNSUPPORTED_REQUEST",
  "DISALLOWED",
  "REJECTED",
  "IN_USE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "GENERIC_ERROR",
  "USER_DISALLOWED",
  "READ_ONLY"
}

--[[ Local Functions ]]
local function deleteWindowUnsuccess(pErrorCode, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = common.getMobileSession(pAppId):SendRPC("DeleteWindow", { windowID = params.windowID })

  params.appID = common.getHMIAppId(pAppId)
  common.getHMIConnection():ExpectRequest("UI.DeleteWindow", { windowID = params.windowID })
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, pErrorCode, "Error code")
  end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pErrorCode })

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
for _, v in ipairs(errorCode) do
  common.Step("HMI sends response with errorCode " .. tostring(v) .. " to DeleteWindow", deleteWindowUnsuccess, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
