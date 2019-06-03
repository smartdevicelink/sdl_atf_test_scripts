---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app1 requests SubscribeButton(button_1)
-- 2) Mobile app2 requests SubscribeButton(button_2)
-- SDL does:
-- 1) Send Buttons.SubscribeButton(button_1, appId1) to HMI
-- 2) Send Buttons.SubscribeButton(button_2, appId2) to HMI
-- 3) Process successful responses from HMI
-- 4) Respond SubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app1 and app2 after adding subscription
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

--[[ Local Functions ]]
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

runner.Title("Test")
runner.Step("App_1 SubscribeButton on " .. buttonName_1 .." button",
    common.rpcSuccess, { 1, "SubscribeButton", buttonName_1 })
runner.Step("App_2 SubscribeButton on " .. buttonName_2 .. " button",
    common.rpcSuccess, { 2, "SubscribeButton", buttonName_2 })
runner.Step("Set App_2 HMI Level to Limited)", hmiLeveltoLimited, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Press on " .. buttonName_1 .. " button", common.buttonPress, { 1, buttonName_1 })
runner.Step("Press on " .. buttonName_2 .. " button", common.buttonPress, { 2, buttonName_2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
