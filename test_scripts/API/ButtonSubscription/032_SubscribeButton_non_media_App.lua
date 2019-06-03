---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Non media app is registered
-- 2) App requests SubscribeButton(media_button)
-- SDL does:
-- 1) Not send Buttons.SubscribeButton request to HMI and respond SubscribeButton(REJECTED) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local variable ]]
local errorCode = "REJECTED"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, buttonName in pairs(common.media_buttons) do
    runner.Step("SubscribeButton on " .. buttonName .. " , SDL sent REJECT",
        common.rpcUnsuccess, { 1, "SubscribeButton", buttonName, errorCode })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
