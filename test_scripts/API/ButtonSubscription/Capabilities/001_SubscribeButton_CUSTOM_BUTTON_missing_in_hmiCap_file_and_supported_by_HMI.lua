------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends SubscribeButton RPC with 'CUSTOM_BUTTON' parameter during registering App in case:
--  - 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json file
--  - 'CUSTOM_BUTTON' is supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI is supported 'CUSTOM_BUTTON' (HMI sends Buttons.GetCapabilities response with CUSTOM_BUTTON)
-- In case:
-- 1. Mobile app starts registration
-- SDL does:
-- - send Buttons.SubscribeButtons(CUSTOM_BUTTON) to HMI
-- - wait response Buttons.SubscribeButtons(SUCCESS) from HMI
-- - receive Buttons.SubscribeButton(SUCCESS)
-- - not send OnHashChange with updated hashId to mobile app
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App for CUSTOM_BUTTON
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
  common.addButtonToCapabilities(common.customButtonCapabilities))

common.runner.Title("Test")
common.runner.Step("App registration and check Subscribe on CUSTOM_BUTTON", common.registerAppSubCustomButton)
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
