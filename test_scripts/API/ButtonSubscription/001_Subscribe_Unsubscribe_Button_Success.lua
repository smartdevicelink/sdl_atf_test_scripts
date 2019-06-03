---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app requests SubscribeButton(button_1)
-- SDL does:
-- 1) Send Buttons.SubscribeButton(button_1, appId) to HMI
-- 2) Wait response from HMI
-- 3) Receive Buttons.SubscribeButton(SUCCESS)
-- 4) Respond SubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, buttonName in pairs(common.buttons) do
	runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess, { 1, "SubscribeButton", buttonName })
	runner.Step("On Button Press " .. buttonName, common.buttonPress, { 1, buttonName })
	runner.Step("UnsubscribeButton " .. buttonName, common.rpcSuccess, { 1, "UnsubscribeButton", buttonName })
	runner.Step("Check unsubscribe " .. buttonName, common.buttonPressUnsuccess, { 1, buttonName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
