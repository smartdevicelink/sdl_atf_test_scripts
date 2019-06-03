---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1
-- 2) Mobile app requests SubscribeButton(button_1)
-- SDL does:
-- 1) Respond SubscribeButton(IGNORED) to mobile app
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

runner.Title("Test")
runner.Step("SubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press " .. buttonName,
    common.buttonPress, { 1, buttonName })
runner.Step("Try to Subscribe on the same button " .. buttonName,
    common.rpcUnsuccess, { 1, "SubscribeButton", buttonName, errorCode })
runner.Step("Button  " .. buttonName .. " still subscribed",
    common.buttonPress, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
