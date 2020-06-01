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
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

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
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

common.Title("Test")
for _, rpc in pairs(common.rpcsArrayWithoutRPCWithCustomTimeout) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 10000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
end
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 15000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 13000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 11000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 20000, invalidParamOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromMobReq })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
