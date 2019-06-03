---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app requests SubscribeButton(button_1)
-- SDL does:
-- 1) Send Buttons.SubscribeButton(button_1, appId) to HMI
-- 2) Wait response from HMI
-- 3) Not receive response from HMI during default timeout
-- 4) Respond SubscribeButton(GENERIC_ERROR) to mobile app
-- 5) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local errorCode = "GENERIC_ERROR"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, buttonName in pairs(common.buttons) do
    runner.Step("Failure Subscribe on " ..  buttonName .. " button, return GENERIC_ERROR",
        common.rpcHMIwithoutResponse, { 1, "SubscribeButton", buttonName, errorCode })
    runner.Step("Button ".. buttonName .. " wasn't Subscribed", common.buttonPressUnsuccess, { 1, buttonName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
