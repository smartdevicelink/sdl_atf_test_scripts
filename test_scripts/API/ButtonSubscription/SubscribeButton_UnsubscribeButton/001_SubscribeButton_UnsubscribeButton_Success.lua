------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeButton/UnsubscribeButton RPC's with <button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app requests SubscribeButton(<button>)
-- SDL does:
-- - send Buttons.SubscribeButton(<button>, appId) to HMI
-- - wait response from HMI
-- - receive Buttons.SubscribeButton(SUCCESS)
-- - respond SubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
for _, buttonName in common.spairs(common.buttons) do
  common.runner.Title("ButtonName parameter: " .. buttonName)
  common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
    { appSessionId1, "SubscribeButton", buttonName })
  common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
  common.runner.Step("UnsubscribeButton " .. buttonName, common.rpcSuccess,
    { appSessionId1, "UnsubscribeButton", buttonName })
  common.runner.Step("Check unsubscribe " .. buttonName, common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
