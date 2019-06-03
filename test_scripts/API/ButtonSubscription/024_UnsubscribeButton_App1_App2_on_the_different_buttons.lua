---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app1 requests SubscribeButton(button_1)
-- 2) Mobile app2 requests SubscribeButton(button_2)
-- 3) Mobile app1 requests UnsubscribeButton(button_1)
-- 4) Mobile app2 requests UnsubscribeButton(button_2)
-- SDL does:
-- 1) Send Buttons.UnsubscribeButton(button_1, appId1) to HMI
-- 2) Send Buttons.UnsubscribeButton(button_2, appId2) to HMI
-- 3) Process successful responses from HMI
-- 4) Respond UnsubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app1 and app2 after unsubscription
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local buttonName_1 = "PRESET_1"
local buttonName_2 = "PRESET_0"

--[[ Local Function ]]
local function hmiLeveltoLimited(pAppId)
    common.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
        { appID = common.getHMIAppId(pAppId) })
    common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU, { 1 })
runner.Step("App_1 activation", common.activateApp, { 1 })
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_2 activation", common.activateApp, { 2 })

runner.Step("App_1 SubscribeButton on " .. buttonName_1 .." button",
    common.rpcSuccess, { 1, "SubscribeButton", buttonName_1 })
runner.Step("App_2 SubscribeButton on " .. buttonName_2 .. " button",
    common.rpcSuccess, { 2, "SubscribeButton", buttonName_2 })
runner.Step("Set App_2 HMI Level to Limited", hmiLeveltoLimited, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("On Button Press for App_1 on " .. buttonName_1,
    common.buttonPress, { 1, buttonName_1 })
runner.Step("On Button Press for App_2 on " .. buttonName_2,
    common.buttonPress, { 2, buttonName_2 })

runner.Title("Test")
runner.Step("App_1 UnsubscribeButton on " .. buttonName_1 .." button",
    common.rpcSuccess, { 1, "UnsubscribeButton", buttonName_1 })
runner.Step("App_1, check unsubscribe " .. buttonName_1,
    common.buttonPressUnsuccess, { 1, buttonName_1 })
runner.Step("Check that App_2 still subscribe on " .. buttonName_2,
    common.buttonPress, { 2, buttonName_2 })
runner.Step("App_2 UnsubscribeButton on " .. buttonName_2 .. " button",
    common.rpcSuccess, { 2, "UnsubscribeButton", buttonName_2 })
runner.Step("App_2, check unsubscribe " .. buttonName_2,
    common.buttonPressUnsuccess, { 2, buttonName_2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
