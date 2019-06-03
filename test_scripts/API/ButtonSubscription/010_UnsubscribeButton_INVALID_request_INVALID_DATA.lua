---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for button_1
-- 2) Mobile app requests invalid UnsubscribeButton request
-- SDL does:
-- 1) Respond UnsubscribeButton(INVALID_DATA) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local buttonName = "PRESET_0"
local invalidButtonName = {
    "IncorrectName", -- invalid enum value
    123,             -- invalid type
    ""               -- empty value
}

local function rpcIncorStruct(pButtonName)
    local cid = common.getMobileSession().correlationId + 40
    local msg = {
        serviceType      = 7,
        frameInfo        = 0,
        rpcType          = 0,
        rpcFunctionId    = 19,
        rpcCorrelationId = cid,
        payload          = '{"buttonName":"' .. pButtonName .. '", {}}'
        }
    common.getMobileSession():Send(msg)
    EXPECT_HMICALL("Buttons.UnsubscribeButton")
    :Times(0)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Subscribe on " .. buttonName .. " button", common.rpcSuccess, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press " .. buttonName, common.buttonPress, { 1, buttonName })

runner.Title("Test")
runner.Step("Not unsubscribe on " .. buttonName .. " button, due to incorrect structure RPC",
    rpcIncorStruct, { buttonName })
runner.Step("Button  " .. buttonName .. " still subscribed", common.buttonPress, { 1, buttonName })
for _, buttonNameTop in pairs(invalidButtonName) do
    runner.Step("Not unsubscribe on " .. buttonNameTop .. " , button, due to invalid button Name",
        common.rpcUnsuccess, { 1, "UnsubscribeButton", buttonNameTop })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
