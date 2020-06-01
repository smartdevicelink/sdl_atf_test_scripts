---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) 17 seconds after receiving GetInteriorVehicleDataConsent request
--   or 7 seconds after receiving all other RPCs on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 9000) to SDL
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 26 seconds to SetInteriorVD with consent
--   and after 16 seconds to all other RPCs
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 7000,
  resetPeriod = 9000
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 17000,
  resetPeriod = 9000
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
for _, rpc in pairs(common.rpcsArray) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 17000, 9000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
end
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 27000, 9000, common.withoutResponseWithOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
