---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) HMI is not supported PLAY_PAUSE
-- 2) Mobile app is registered with major version=5.0
-- 3) Mobile app requests SubscribeButton(PLAY_PAUSE)
-- SDL does:
-- 1) Respond SubscribeButton(UNSUPPORTED_RESOURCE) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Local Variables ]]
local buttonName = "PLAY_PAUSE"
local errorCode = "UNSUPPORTED_RESOURCE"

--[[ Local function ]]
local hmiValues = hmi_values.getDefaultHMITable()
for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTab.name == buttonName) then
        table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
    end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeButton " .. buttonName .. ", HMI not supported",
    common.rpcUnsuccess, { 1, "SubscribeButton", buttonName, errorCode })
runner.Step("Button ".. buttonName .. " wasn't Subscribed",
    common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
