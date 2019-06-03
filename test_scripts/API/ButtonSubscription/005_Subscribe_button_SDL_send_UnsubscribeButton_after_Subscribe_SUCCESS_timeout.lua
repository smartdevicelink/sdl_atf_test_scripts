---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app requests SubscribeButton(button_1)
-- 2) SDL sends Buttons.SubscribeButton(button_1, appId) to HMI
-- 3) HMI does not respond during default timeout
-- 4) SDL responds SubscribeButton(GENERIC_ERROR) to mobile app
-- 5) HMI sends Buttons.SubscribeButton(SUCCESS) to SDL
-- SDL does:
-- 1) Send Buttons.UnsubscribeButton(button_1, appId) to HMI
-- 2) Receive response Buttons.UnsubscribeButton(SUCCESS) and keep actual unsubscribed state for button_1
-- 3) Not send  UnsubscribeButton response to mobile app
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
    local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButtonName })
    local appIdVariable = common.getHMIAppId()
    EXPECT_HMICALL("Buttons.SubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        -- HMI did not response
        himCID = data.id
    end)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
    :Do(function()
        common.getHMIConnection():SendResponse(himCID, "Buttons.SubscribeButton", "SUCCESS", { })
    end)
    EXPECT_HMICALL("Buttons.UnsubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    local event = events.Event()
    event.matches = function(_, data)
        return data.rpcType == 1 and
        data.rpcFunctionId == 19
    end
    EXPECT_EVENT(event, "UnsubscribeButtonResponse")
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
    runner.Step("Subscribe on " .. buttonName .. " button,timeout case", rpcGenericError, { buttonName })
    runner.Step("Button ".. buttonName .. " wasn't Subscribe", common.buttonPressUnsuccess, { 1, buttonName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
