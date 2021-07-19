------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL doesn't send SubscribeButton RPC with 'CUSTOM_BUTTON' during registering App in case:
--  - 'CUSTOM_BUTTON' exists in the hmi_capabilities.json file
--  - 'CUSTOM_BUTTON' is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. CUSTOM_BUTTON exists in hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI doesn't support CUSTOM_BUTTON (HMI sends Buttons.GetCapabilities response without CUSTOM_BUTTON)
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

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Add CUSTOM_BUTTON support to hmi_capabilities.json",
  common.addButtonToHMICapabilitiesFile, { common.customButtonCapabilities })
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
  { common.removeButtonFromCapabilities(buttonName) })

common.runner.Title("Test")
common.runner.Step("App registration and SDL doesn't send SubscribeButton CUSTOM_BUTTON",
  common.registerAppSubCustomButton, { appSessionId1, "SUCCESS", common.isNotExpected })
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
