---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) 6 seconds after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout with resetPeriod = 16000 for GetInteriorVehicleDataConsent and
--   with resetPeriod = 6000 for all other RPCs to SDL
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 20 seconds to SetInteriorVD with consent
--   and after 10 seconds to all other RPCs
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local wrongRequestID = 1234

local paramsForRespFunction = {
  notificationTime = 6000,
  resetPeriod = 6000
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 6000,
  resetPeriod = 16000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(wrongRequestID, pData.method, pOnRTParams.resetPeriod)
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
    { 11000, 10000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
end
runner.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 15000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
runner.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
runner.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 13000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
runner.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 20000, invalidParamOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromMobReq })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
