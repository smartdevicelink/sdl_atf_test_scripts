---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 6000) with wrong methodName to SDL in 6 sec after HMI request
-- 4) HMI does not send response in 10 seconds after receiving request
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local wrongMethodName = "Wrong_methodName"

local paramsForRespFunction = {
  notificationTime = 6000,
  resetPeriod = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(pData.id, wrongMethodName, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU)
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_1 activation", common.activateApp)
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
for _, rpc in pairs(common.rpcsArrayWithoutRPCWithCustomTimeout) do
  runner.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 4000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
end
runner.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 9000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 5000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 7000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 5000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 11000, 4000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
