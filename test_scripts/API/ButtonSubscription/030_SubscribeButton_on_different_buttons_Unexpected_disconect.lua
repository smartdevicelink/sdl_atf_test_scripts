---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1 and button_2
-- 2) Unexpected disconnect and connect are performed
-- 3) App registers with actual hashId
-- 4) SDL sends Buttons.SubscribeButton(button_1, appId) to HMI during resumption
-- 5) SDL sends Buttons.SubscribeButton(button_2, appId) to HMI during resumption
-- 6) HMI responds with error code to SubscribeButton(button_1, appId) and success to SubscribeButton(button_2)
-- SDL does:
-- 1) Process error response from HMI and revert subscription for button_2
-- 2) Respond RAI(RESUME_FAILED) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName_1 = "PRESET_0"
local buttonName_2 = "PRESET_1"

--[[ Local Functions ]]
local function checkResumptionData(pAppId)
    EXPECT_HMICALL("Buttons.SubscribeButton",
        { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" },
        { appID = common.getHMIAppId(pAppId), buttonName = buttonName_1 },
        { appID = common.getHMIAppId(pAppId), buttonName = buttonName_2 })
    :Times(3)
    :Do(function(_, data)
        if data.params.buttonName == buttonName_1 then
            common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
        else
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        end
    end)
    EXPECT_HMICALL("Buttons.UnsubscribeButton",
        { appID = common.getHMIAppId(pAppId), buttonName = buttonName_2 })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeButton " .. buttonName_1, common.rpcSuccess, { 1, "SubscribeButton", buttonName_1 })
runner.Step("SubscribeButton " .. buttonName_2, common.rpcSuccess, { 1, "SubscribeButton", buttonName_2 })
runner.Step("On Button Press " .. buttonName_1, common.buttonPress, { 1, buttonName_1 })
runner.Step("On Button Press " .. buttonName_2, common.buttonPress, { 1, buttonName_2 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)

runner.Title("Test")
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App, resumption failed",
    common.reRegisterApp, { 1, checkResumptionData, common.resumptionFullHMILevel })
runner.Step("Subscription on ".. buttonName_1 .. " button wasn't Resumed",
    common.buttonPressUnsuccess, { 1, buttonName_1 })
runner.Step("Subscription on ".. buttonName_2 .. " button wasn't Resumed",
    common.buttonPressUnsuccess, { 1, buttonName_2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
