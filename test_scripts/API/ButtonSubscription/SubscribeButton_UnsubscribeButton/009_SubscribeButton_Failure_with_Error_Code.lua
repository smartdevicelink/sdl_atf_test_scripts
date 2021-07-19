------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing of SubscribeButton request if HMI respond with unsuccessful <erroneous> resultCode
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app requests SubscribeButton(<button>)
-- SDL does:
-- - send Buttons.SubscribeButton(<button>, appId) to HMI
-- - wait response from HMI
-- - receive Buttons.SubscribeButton(<erroneous>)
-- - respond SubscribeButton(<erroneous>) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- - not transfer button events to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "OK"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
for _, errorCode in common.spairs(common.errorCode) do
  common.runner.Step("Failure Subscribe on " .. buttonName .. " with error " .. errorCode,
    common.rpcHMIResponseErrorCode, { appSessionId1, "SubscribeButton", buttonName, errorCode })
end
common.runner.Step("Button ".. buttonName .. " wasn't Subscribed", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
