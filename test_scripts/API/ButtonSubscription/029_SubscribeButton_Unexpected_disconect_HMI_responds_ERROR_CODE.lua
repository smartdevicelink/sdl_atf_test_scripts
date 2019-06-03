---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1
-- 2) Unexpected disconnect and connect are performed
-- 3) App registers with actual hashId
-- 4) SDL sends Buttons.SubscribeButton(button_1, appId) to HMI during resumption
-- 5) HMI responds with error code
-- SDL does:
-- 1) Process error response from HMI
-- 3) Respond RAI(RESUME_FAILED) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "PRESET_0"

--[[ Local Functions ]]
local function checkResumptionData(pAppId)
  EXPECT_HMICALL("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" },
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName })
  :Times(2)
  :Do(function(_, data)
    if data.params.buttonName == buttonName then
      common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
    else
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
  end)
  EXPECT_HMICALL("Buttons.UnsubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName })
  :Times(1)
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

runner.Title("Test")
runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press " .. buttonName, common.buttonPress, { 1, buttonName })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data with error code",
    common.reRegisterApp, { 1, checkResumptionData, common.resumptionFullHMILevel})
runner.Step("Subscription on ".. buttonName .. " button wasn't Resumed",
    common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
