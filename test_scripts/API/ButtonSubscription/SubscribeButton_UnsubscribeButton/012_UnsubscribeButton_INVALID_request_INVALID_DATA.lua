------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to UnsubscribeButton request
--  if App sends request with invalid data for <button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for button
-- 2. Mobile app requests invalid UnsubscribeButton request
-- SDL does:
-- - not transfer `Buttons.UnsubscribeButton` request to HMI
-- - respond UnsubscribeButton(INVALID_DATA) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- - not transfer button events to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"
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
    rpcFunctionId    = 19,
    rpcCorrelationId = cid,
    payload          = '{"buttonName":"' .. pButtonName .. '", {}}'
  }
  common.getMobileSession():Send(msg)
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton")
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
common.runner.Step("Subscribe on " .. buttonName .. " button", common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Test")
common.runner.Step("Not unsubscribe on " .. buttonName .. " button, due to incorrect structure RPC",
  rpcIncorStruct, { buttonName })
common.runner.Step("Button  " .. buttonName .. " still subscribed", common.buttonPress, { appSessionId1, buttonName })
for _, buttonNameTop in common.spairs(invalidButtonName) do
  common.runner.Step("Not unsubscribe on " .. buttonNameTop .. " , button, due to invalid button Name",
    common.rpcUnsuccess, { appSessionId1, "UnsubscribeButton", buttonNameTop })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
