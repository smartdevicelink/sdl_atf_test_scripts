------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeButton RPC with 'CUSTOM_BUTTON' parameter if HMI responds
--  with any <successful> result code
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app starts registration
-- 2. SDL sends Buttons.SubscribeButton(CUSTOM_BUTTON) to HMI
-- 3. HMI sends Buttons.SubscribeButton response with <successful> resultCode
-- 4. HMI sends OnButtonEvent and OnButtonPress notification to App
-- SDL does:
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local successCodes = {
  "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "UNSUPPORTED_RESOURCE", "TRUNCATED_DATA"
}

--[[ Scenario ]]
for _, code in common.spairs(successCodes) do
  common.runner.Title("ResultCode: " .. code)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("App registration, Subscribe on CUSTOM_BUTTON with " .. code,
    common.registerAppSubCustomButton, { appSessionId1, code })
  common.runner.Step("Activate app", common.activateApp)
  common.runner.Step("Subscribe on Soft button", common.registerSoftButton)

  common.runner.Title("Test")
  common.runner.Step("On CUSTOM_BUTTON press", common.buttonPress,
    { appSessionId1, buttonName, common.isExpected, common.customButtonID })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
