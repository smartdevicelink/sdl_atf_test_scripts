---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1
-- 2) Mobile app requests UnsubscribeButton(button_1)
-- 3) SDL sends Buttons.UnsubscribeButton(button_1, appId) to HMI
-- 4) HMI does not respond during default timeout
-- 5) SDL responds UnsubscribeButton(GENERIC_ERROR) to mobile app
-- 6) HMI sends Buttons.UnsubscribeButton(SUCCESS) to SDL
-- SDL does:
-- 1) Send Buttons.SubscribeButton(button_1, appId) to HMI
-- 2) Receive response Buttons.SubscribeButton(SUCCESS) and keep actual subscribed state for button_1
-- 3) Not send SubscribeButton response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')
local events = require('events')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local himCID

--[[ Local function ]]
local function rpcGenericError(pButtonName)
    local cid = common.getMobileSession():SendRPC("UnsubscribeButton", { buttonName = pButtonName })
    local appIdVariable = common.getHMIAppId()
    EXPECT_HMICALL("Buttons.UnsubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        -- HMI did not response
        himCID = data.id
    end)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
    :Do(function()
        common.getHMIConnection():SendResponse( himCID, "Buttons.UnsubscribeButton", "SUCCESS", { })
    end)
    EXPECT_HMICALL("Buttons.SubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    local event = events.Event()
    event.matches = function(_, data)
        return data.rpcType == 1 and
        data.rpcFunctionId == 18
    end
    EXPECT_EVENT(event, "SubscribeButtonResponse")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, buttonName in pairs(common.buttons) do
    runner.Step("Subscribe on " .. buttonName, common.rpcSuccess, { 1, "SubscribeButton", buttonName })
    runner.Step("On Button Press " .. buttonName, common.buttonPress, { 1, buttonName })
    runner.Step("Unsubscribe on " .. buttonName .. " button in timeout case", rpcGenericError, { buttonName })
    runner.Step("On Button Press " .. buttonName, common.buttonPress, { 1, buttonName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
