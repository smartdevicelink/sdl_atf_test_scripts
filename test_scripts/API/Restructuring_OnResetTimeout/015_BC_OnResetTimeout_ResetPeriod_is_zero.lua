---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) 15 seconds after receiving GetInteriorVehicleDataConsent request
--   or 5 seconds after receiving all other RPCs on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 0) to SDL
-- 4) HMI does not respond
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app when 2*default timeout for SetInteriorVD with consent
--   and default timeout for all other RPCs is expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 5000,
  resetPeriod = 0
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 15000,
  resetPeriod = 0
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

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
    { 11000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif})
end
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 8000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromNotif})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
