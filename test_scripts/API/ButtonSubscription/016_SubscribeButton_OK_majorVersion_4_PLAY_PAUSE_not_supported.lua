---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) HMI is not supported PLAY_PAUSE
-- 2) Mobile app is registered with major version=4.5
-- 3) Mobile app requests SubscribeButton(OK)
-- SDL does:
-- 1) Send Buttons.SubscribeButton(OK, appId) to HMI
-- 2) Wait response from HMI
-- 3) Receive Buttons.SubscribeButton(SUCCESS)
-- 4) Respond SubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local buttonName = "OK"
local buttonNamePLAY_PAUSE = "PLAY_PAUSE"

--[[ Local function ]]
local hmiValues = hmi_values.getDefaultHMITable()
for i, buttonNameTop in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTop.name == buttonNamePLAY_PAUSE) then
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
runner.Step("SubscribeButton " .. buttonName,
    common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press " .. buttonName,
    common.buttonPress, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
