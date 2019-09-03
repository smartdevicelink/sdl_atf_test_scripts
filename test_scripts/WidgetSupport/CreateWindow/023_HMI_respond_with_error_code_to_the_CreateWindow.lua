---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app will receive <errorCode> to the "CreateWindow" request if HMI responds with error code
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App sends valid CreateWindow request to SDL
-- SDL does:
--  - send valid UI.CreateWindow(param) request to HMI
-- 2) HMI sends UI.CreateWindow response with <errorCode> to SDL
-- SDL does:
--  - send CreateWindow response with (success = false, resultCode = errorCode_n) to App
--  - not send OnSystemCapabilityUpdated and OnHMIStatus notifications to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
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
local function createWindowUnsuccess(pErrorCode, pAppId)
  if not pAppId then pAppId = 1 end
  local params = {
    windowID = 3,
    windowName = "Widget",
    type = "WIDGET"
  }
  local cid = common.getMobileSession(pAppId):SendRPC("CreateWindow", params )

  params.appID = common.getHMIAppId(pAppId)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow", params)
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, pErrorCode, "Error code")
  end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pErrorCode })

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
for _, v in ipairs(errorCode) do
  common.Step("HMI sends response with errorCode " .. tostring(v) .. " to CreateWindow", createWindowUnsuccess, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
