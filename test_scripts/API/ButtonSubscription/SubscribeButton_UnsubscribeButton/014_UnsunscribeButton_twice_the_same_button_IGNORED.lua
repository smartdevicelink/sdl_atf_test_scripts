------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "IGNORED" to 2nd UnsubscribeButton request
--  with <button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is not subscribed for <button>
-- 2. Mobile app requests UnsubscribeButton(<button>)
-- SDL does:
-- - not transfer `Buttons.UnsubscribeButton` request to HMI
-- - respond UnsubscribeButton(IGNORED) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local errorCode = "IGNORED"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
for _, buttonName in common.spairs(common.buttons) do
  common.runner.Title("ButtonName parameter: " .. buttonName)
  common.runner.Step("SubscribeButton " .. buttonName,
    common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName })
  common.runner.Step("UnsubscribeButton " .. buttonName,
    common.rpcSuccess, { appSessionId1, "UnsubscribeButton", buttonName })
  common.runner.Step("Check unsubscribe " .. buttonName,
    common.buttonPress, { appSessionId1, buttonName, common.isNotExpected })
  common.runner.Step("Try to Unsubscribe on the same button " .. buttonName,
    common.rpcUnsuccess, { appSessionId1, "UnsubscribeButton", buttonName, errorCode })
  common.runner.Step("Button ".. buttonName .. " still Unsubscribed",
    common.buttonPress, { appSessionId1, buttonName, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
