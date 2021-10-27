------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send an event notification "CUSTOM_BUTTON" without AppID to App
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile App_1 and App_2 are subscribed for 'OK' button
-- 2. App_1 is set to FULL HMI level
-- 3. HMI sends OnButtonEvent and OnButtonPress notification without App ID to App
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"

--[[ Local Functions ]]
local function buttonPress(pAppId, pButtonName, pExpTimesApp, pCustomButtonID)
  if not pAppId then pAppId = 1 end
  if not pExpTimesApp then pExpTimesApp = common.isExpected end
  local isExpectedOnButtonEvent = 2
  if pExpTimesApp == common.isNotExpected then isExpectedOnButtonEvent = common.isNotExpected end
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN", customButtonID = pCustomButtonID })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT", customButtonID = pCustomButtonID })
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP", customButtonID = pCustomButtonID })
  common.getMobileSession(pAppId):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN", customButtonID = pCustomButtonID },
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP",  customButtonID = pCustomButtonID })
  :Times(isExpectedOnButtonEvent)
  common.getMobileSession(pAppId):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT",  customButtonID = pCustomButtonID })
  :Times(pExpTimesApp)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration and check Subscribe on CUSTOM_BUTTON", common.registerAppSubCustomButton)
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)

common.runner.Title("Test")
common.runner.Step("On Custom_button press ", buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
