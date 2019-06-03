---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
--  Sending an event notification without App ID only to app in full
-- In case:
-- 1) Mobile app_1 and app_2 are subscribed for OK button
-- 2) app_2 is set to LIMITED HMI level
-- 3) app_1 is set to FULL HMI level
-- 4) HMI sends OnButtonEvent and OnButtonPress notification without App ID
-- SDL does:
-- 1) resend notifications only to the app_1 in FULL hmi level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local buttonName = "OK"

--[[ Local functions ]]
local function hmiLeveltoLimited(pAppId)
  common.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
      { appID = common.getHMIAppId(pAppId) })
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function buttonPressWithoutAppId(pAppFULL, pAppLIMITED, pButtonName)
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN" })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT" })
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP" })
  common.getMobileSession(pAppFULL):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
  :Times(2)
  common.getMobileSession(pAppFULL):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})

  common.getMobileSession(pAppLIMITED):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
  :Times(0)
  common.getMobileSession(pAppLIMITED):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU, { 1 })
runner.Step("App_1 activation", common.activateApp, { 1 })
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_2 activation", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("App_1 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("Check subscribe only for App_1", common.buttonPress, { 1, buttonName })
runner.Step("Check not subscribe for App_2", common.buttonPressUnsuccess, { 2, buttonName })
runner.Step("App_2 SubscribeButton on " .. buttonName .. " button",
  common.rpcSuccess, { 2, "SubscribeButton", buttonName })
runner.Step("Set App_2 HMI Level to Limited)", hmiLeveltoLimited, { 2 })
runner.Step("Activate App_1", common.activateApp, { 1 })
runner.Step("Button Press on " .. buttonName .. "button for App_1 and App_2 ",
  buttonPressWithoutAppId, { 1, 2, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
