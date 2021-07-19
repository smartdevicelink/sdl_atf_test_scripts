------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to SubscribeButton request
--  if App sends request with invalid data for <button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app requests invalid SubscribeButton request.
-- SDL does:
-- - not transfer `Buttons.SubscribeButton` request to HMI
-- - respond SubscribeButton(INVALID_DATA) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- - not transfer button events to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName_1 = "PRESET_0"
local buttonName_2 = "PRESET_1"
local errorCode = "INVALID_DATA"
local invalidButtonName = {
  "IncorrectName", -- invalid enum value
  123,             -- invalid type
  ""               -- empty value
}

local function rpcIncorStruct(pButtonName)
  local cid = common.getMobileSession().correlationId + 40
  local msg = {
    serviceType      = 7,
    frameInfo        = 0,
    rpcType          = 0,
    rpcFunctionId    = 18,
    rpcCorrelationId = cid,
    payload          = '{"buttonName":"' .. pButtonName .. '", {}}'
  }
  common.getMobileSession():Send(msg)
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("SubscribeButton " .. buttonName_1, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName_1 })
common.runner.Step("On Button Press " .. buttonName_1, common.buttonPress, { appSessionId1, buttonName_1 })
common.runner.Step("Not subscribe on " .. buttonName_2 .. " button, due to incorrect structure RPC",
  rpcIncorStruct, { buttonName_2 })
for _, buttonName in common.spairs(invalidButtonName) do
  common.runner.Step("Not subscribe on " .. buttonName .. " button, due to incorrect data",
    common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
