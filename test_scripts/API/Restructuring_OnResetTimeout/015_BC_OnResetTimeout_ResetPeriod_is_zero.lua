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
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
    { 11000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif})
end
runner.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
runner.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
runner.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 8000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
runner.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromNotif})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
