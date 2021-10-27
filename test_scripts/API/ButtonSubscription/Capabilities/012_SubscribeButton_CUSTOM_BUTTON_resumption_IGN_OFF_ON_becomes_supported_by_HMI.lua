------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0205-Avoid_custom_button_subscription_when_HMI_does_not_support.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends SubscribeButton RPC with 'CUSTOM_BUTTON' parameter during resumption
--  after Ignition Cycle in case:
--  - 'CUSTOM_BUTTON' is missing in the hmi_capabilities.json file
--  - 'CUSTOM_BUTTON' becomes supported by HMI after Ignition cycle
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. CUSTOM_BUTTON is missing in the hmi_capabilities.json
-- 2. SDL and HMI are started
-- 3. HMI doesn't support CUSTOM_BUTTON (HMI sends Buttons.GetCapabilities response without CUSTOM_BUTTON)
-- 4. Mobile app is registered and activated
-- In case:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. HMI sends GetSystemInfo with new ccpu_version_2 to SDL
-- 3. HMI supported CUSTOM_BUTTON (SDL receives Buttons.GetCapabilities response from HMI with supported CUSTOM_BUTTON)
-- 4. App re-registered with actual HashId
-- SDL does:
-- - send request Buttons.SubscribeButtons(CUSTOM_BUTTON) to HMI
-- - wait respond Buttons.SubscribeButtons(SUCCESS) from HMI
-- - receive Buttons.SubscribeButton(SUCCESS)
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 5. HMI sends OnButtonEvent and OnButtonPress notifications to SDL
-- SDL does:
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App for CUSTOM_BUTTON
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local isCacheNotUsed = false

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Remove CUSTOM_BUTTON from hmi_capabilities.json",
  common.removeButtonFromHMICapabilitiesFile, { buttonName })
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
  { common.getUpdatedHMICaps("cppu_version_1", common.removeButtonFromCapabilities(buttonName)) })
common.runner.Step("App registration and SDL doesn't send Subscribe CUSTOM_BUTTON",
  common.registerAppSubCustomButton, { appSessionId1, "SUCCESS", common.isNotExpected })
common.runner.Step("App activation", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("IGNITION OFF", common.ignitionOff)
common.runner.Step("IGNITION ON, HMI sends different cppu_version", common.startCacheUsed,
  { common.getUpdatedHMICaps("cppu_version_2", common.addButtonToCapabilities(common.customButtonCapabilities)),
    isCacheNotUsed })

common.runner.Title("Test")
common.runner.Step("Reregister App resumption data, send Subscribe CUSTOM_BUTTON", common.reRegisterAppSuccess,
  { appSessionId1, common.checkResumptionData, common.isExpected })
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
