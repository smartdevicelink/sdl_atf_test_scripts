------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeButton/UnsubscribeButton RPC's with <button> parameter
--  if HMI responds with any <successful> result code
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app requests SubscribeButton(<button>)
-- 2. HMI responds with any <successful> resultCode to request:
-- - "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
-- SDL does:
-- - process responses from HMI
-- - respond SubscribeButton(success=true,result_code=<successful>) to mobile app
-- - send OnHashChange with updated hashId to mobile app
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App
-- In case:
-- 3. Mobile app requests UnsubscribeButton(<button>)
-- 4. HMI responds with any <successful> resultCode to request:
-- - "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
-- SDL does:
-- - process responses from HMI
-- - respond UnsubscribeButton(success=true,result_code=<successful>) to mobile app
-- - send OnHashChange with updated hashId to mobile app
-- - not resend OnButtonEvent and OnButtonPress notifications to mobile App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "OK"
local successCodes = {
  "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
}

--[[ Local function ]]
local function rpcSuccess(pAppId, pRpc, pSuccessCodes)
  local cid = common.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = buttonName })
  common.getHMIConnection():ExpectRequest("Buttons." .. pRpc,
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, pSuccessCodes, { })
    end)
  common.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :Times(0)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = pSuccessCodes })
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
for _, code in common.spairs(successCodes) do
  common.runner.Title("ButtonName parameter: " .. buttonName .. " with " .. code)
  common.runner.Step("SubscribeButton " .. buttonName .. " with " .. code, rpcSuccess,
    { appSessionId1, "SubscribeButton", code })
  common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
  common.runner.Step("UnsubscribeButton " .. buttonName .. " with " .. code, common.rpcSuccess,
    { appSessionId1, "UnsubscribeButton", buttonName })
  common.runner.Step("Check unsubscribe " .. buttonName, common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
