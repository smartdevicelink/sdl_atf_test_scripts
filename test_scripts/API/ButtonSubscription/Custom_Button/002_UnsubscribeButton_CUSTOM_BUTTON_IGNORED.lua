------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL ignores UnsubscribeButton RPC with 'CUSTOM_BUTTON' parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for 'CUSTOM_BUTTON'
-- 2. Mobile app requests UnsubscribeButton(<button>)
-- SDL does:
-- - respond UnsubscribeButton(IGNORED) to mobile app
-- - not send Buttons.UnsubscribeButton(CUSTOM_BUTTON, appId) to HMI
-- - not send OnHashChange with updated hashId to mobile app
-- - still resend OnButtonEvent and OnButtonPress notifications to mobile App for CUSTOM_BUTTON
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local errorCode = "IGNORED"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration and check Subscribe on CUSTOM_BUTTON", common.registerAppSubCustomButton)
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Test")
common.runner.Step("UnsubscribeButton " .. buttonName, common.rpcUnsuccess,
  { appSessionId1, "UnsubscribeButton", buttonName, errorCode })
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
