------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "IGNORED" to 2nd SubscribeButton request
--  with <button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for <button>
-- 2. Mobile app requests SubscribeButton(<button>)
-- SDL does:
-- - not transfer `Buttons.SubscribeButton` request to HMI
-- - respond SubscribeButton(IGNORED) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for <button>
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress to App
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
  common.runner.Step("On Button Press " .. buttonName,
    common.buttonPress, { appSessionId1, buttonName })
  common.runner.Step("Try to Subscribe on the same button " .. buttonName,
    common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
  common.runner.Step("Button  " .. buttonName .. " still subscribed",
    common.buttonPress, { appSessionId1, buttonName })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
