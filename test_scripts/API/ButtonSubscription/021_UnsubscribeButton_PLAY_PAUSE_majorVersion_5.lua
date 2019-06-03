---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is registered with major version=5.0
-- 2) Mobile app requests SubscribeButton(PLAY_PAUSE)
-- 3) Mobile app requests UnsubscribeButton(PLAY_PAUSE)
-- SDL does:
-- 1) Send Buttons.UnsubscribeButton(PLAY_PAUSE, appId) to HMI
-- 2) Wait response from HMI
-- 3) Receive Buttons.UnsubscribeButton(SUCCESS)
-- 4) Respond UnsubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Local Variables ]]
local buttonName = "PLAY_PAUSE"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press " .. buttonName,
    common.buttonPress, { 1, buttonName })

runner.Title("Test")
runner.Step("UnsubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "UnsubscribeButton", buttonName })
runner.Step("Check unsubscribe " .. buttonName,
    common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
