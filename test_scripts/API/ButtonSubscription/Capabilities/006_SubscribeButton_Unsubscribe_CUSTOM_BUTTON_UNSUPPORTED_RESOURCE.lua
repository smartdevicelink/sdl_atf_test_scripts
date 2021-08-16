------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "UNSUPPORTED_RESOURCE" to SubscribeButton/UnSubscribeButton
--  requests in case:
--  - 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json file
--  - 'CUSTOM_BUTTON' is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. CUSTOM_BUTTON is missing in the hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI doesn't support CUSTOM_BUTTON (HMI sends Buttons.GetCapabilities response without CUSTOM_BUTTON)
-- 4. Mobile app is registered
-- In case:
-- 1. Mobile app requests SubscribeButton(CUSTOM_BUTTON)
-- SDL does:
-- - respond SubscribeButtons(resultCode: UNSUPPORTED_RESOURCE, success:false) to App
-- In case:
-- 2. Mobile app requests UnSubscribeButton(CUSTOM_BUTTON) to SDL
-- SDL does:
-- - respond UnSubscribeButtons(resultCode: UNSUPPORTED_RESOURCE, success: false) to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Remove CUSTOM_BUTTON from hmi_capabilities.json",
  common.removeButtonFromHMICapabilitiesFile, { buttonName })
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
  { common.removeButtonFromCapabilities(buttonName) })
common.runner.Step("App registration and SDL doesn't send Subscribe CUSTOM_BUTTON",
  common.registerAppSubCustomButton, { appSessionId1, "SUCCESS", common.isNotExpected })
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)

common.runner.Title("Test")
common.runner.Step("Failure Subscribe on CUSTOM_BUTTON with error UNSUPPORTED_RESOURCE", common.rpcUnsuccess,
  { appSessionId1, "SubscribeButton", buttonName, "UNSUPPORTED_RESOURCE" })
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })
common.runner.Step("Failure UnSubscribe on CUSTOM_BUTTON with error UNSUPPORTED_RESOURCE", common.rpcUnsuccess,
  { appSessionId1, "UnsubscribeButton", buttonName, "UNSUPPORTED_RESOURCE" })
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
