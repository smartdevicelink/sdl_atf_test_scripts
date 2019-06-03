---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is not subscribed for button_1
-- 2) Mobile app requests UnsubscribeButton(button_1)
-- SDL does:
-- 1) Respond UnsubscribeButton(IGNORED) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local buttonName = "OK"
local errorCode = "IGNORED"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "SubscribeButton", buttonName })

runner.Title("Test")
runner.Step("UnsubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "UnsubscribeButton", buttonName })
runner.Step("Check unsubscribe " .. buttonName,
    common.buttonPressUnsuccess, { 1, buttonName })
runner.Step("Try to Unsubscribe on the same button " .. buttonName,
    common.rpcUnsuccess, { 1, "UnsubscribeButton", buttonName, errorCode })
runner.Step("Button ".. buttonName .. " Unsubscribed",
    common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
