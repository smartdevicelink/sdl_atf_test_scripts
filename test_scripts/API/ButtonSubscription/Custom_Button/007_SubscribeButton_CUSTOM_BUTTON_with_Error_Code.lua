------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeButton RPC with 'CUSTOM_BUTTON' parameter if HMI respond
--  with unsuccessful <erroneous> resultCode
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app starts registration
-- 2. HMI sends Buttons.SubscribeButton response with unsuccessful <erroneous> resultCode
-- 3. HMI sends OnButtonEvent and OnButtonPress notification to App
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"

--[[ Scenario ]]
for _, errorCode in common.spairs(common.errorCode) do
  common.runner.Title("ResultCode: " .. errorCode)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("App registration, Failure Subscribe on CUSTOM_BUTTON with error " .. errorCode,
    common.registerAppSubCustomButton, { appSessionId1, errorCode })
  common.runner.Step("Activate app", common.activateApp)
  common.runner.Step("Subscribe on Soft button", common.registerSoftButton)

  common.runner.Title("Test")
  common.runner.Step("On Custom_button press ", common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })
  common.runner.Step("Failure Subscribe on " .. buttonName .. " with error " .. errorCode,
    common.rpcHMIResponseErrorCode, { appSessionId1, "SubscribeButton", buttonName, errorCode })
  common.runner.Step("On Custom_button press ", common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })
  common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
    { appSessionId1, "SubscribeButton", buttonName })
  common.runner.Step("On Custom_button press ", common.buttonPress,
    { appSessionId1, buttonName, common.isExpected, common.customButtonID })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
