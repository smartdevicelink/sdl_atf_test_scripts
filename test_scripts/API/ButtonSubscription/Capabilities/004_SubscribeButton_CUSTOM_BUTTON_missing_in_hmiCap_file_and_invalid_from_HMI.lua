------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL uses default capabilities from hmi_capabilities.json file if HMI sends
--  Buttons.GetCapabilities response with invalid value for 'CUSTOM_BUTTON' capabilities in case:
--  - 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json file
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. CUSTOM_BUTTON is missing in the hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI sends Buttons.GetCapabilities response with an invalid value for CUSTOM_BUTTON capabilities
-- In case:
-- 1. Mobile app starts registration
-- SDL does:
-- - not send Buttons.SubscribeButtons(CUSTOM_BUTTON) to HMI
-- In case:
-- 2. HMI sends OnButtonEvent and OnButtonPress notifications to SDL
-- SDL does:
-- - not resend OnButtonEvent and OnButtonPress notifications to mobile App for CUSTOM_BUTTON
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local invalidCustomButton = {
  name = buttonName,
  shortPressAvailable = true,
  longPressAvailable = true,
  upDownAvailable = 2 -- invalid Type
}

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Remove CUSTOM_BUTTON from hmi_capabilities.json",
  common.removeButtonFromHMICapabilitiesFile, { buttonName })
common.runner.Step("Start SDL, HMI, connect Mobile, start Session, Capabilities with invalid value", common.start,
  { common.addButtonToCapabilities(invalidCustomButton) })

common.runner.Title("Test")
common.runner.Step("App registration and SDL doesn't send SubscribeButton CUSTOM_BUTTON",
  common.registerAppSubCustomButton, { appSessionId1, "SUCCESS", common.isNotExpected })
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
