---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app requests invalid SubscribeButton request.
-- SDL does:
-- 1) respond SubscribeButton(INVALID_DATA) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local buttonName_1 = "PRESET_0"
local buttonName_2 = "PRESET_1"
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
        rpcFunctionId    = 18,
        rpcCorrelationId = cid,
        payload          = '{"buttonName":"' .. pButtonName .. '", {}}'
        }
    common.getMobileSession():Send(msg)
    EXPECT_HMICALL("Buttons.SubscribeButton")
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

runner.Title("Test")
runner.Step("SubscribeButton " .. buttonName_1, common.rpcSuccess, { 1, "SubscribeButton", buttonName_1 })
runner.Step("On Button Press " .. buttonName_1, common.buttonPress, { 1, buttonName_1 })
runner.Step("Not subscribe on " .. buttonName_2 .. " button, due to incorrect structure RPC",
    rpcIncorStruct, { buttonName_2 })
for _, buttonName in pairs(invalidButtonName) do
    runner.Step("Not subscribe on " .. buttonName .. " button, due to incorrect data",
        common.rpcUnsuccess, { 1, "SubscribeButton", buttonName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
