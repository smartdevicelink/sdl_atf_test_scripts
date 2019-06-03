---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1
-- 2) Mobile app requests UnsubscribeButton(button_1)
-- SDL does:
-- 1) Send Buttons.UnsubscribeButton(button_1, appId) to HMI
-- 2) Wait response from HMI
-- 3) Receive Buttons.UnsubscribeButton(errorCode_n)
-- 4) Respond UnsubscribeButton(errorCode_n) to mobile app
-- 5) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "OK"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess, { 1, "SubscribeButton", buttonName })

runner.Title("Test")
for _, errorCode in pairs(common.errorCode) do
    runner.Step("Failure Unsubscribe on " .. buttonName .. " with error " .. errorCode,
        common.rpcHMIResponseErrorCode, { 1, "UnsubscribeButton", buttonName, errorCode })
end
runner.Step("Button  " .. buttonName .. " still subscribed", common.buttonPress, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
