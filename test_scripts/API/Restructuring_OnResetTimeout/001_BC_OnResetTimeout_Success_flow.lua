---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) HMI sends BC.OnResetTimeout with resetPeriod = 25000 for GetInteriorVehicleDataConsent and
--   with resetPeriod = 15000 for all other RPCs to SDL right after receiving RPC request on HMI
-- 3)When HMI processes the RPC with InteriorVD consent, it sends the response in 21 seconds
--  to GetInteriorVehicleDataConsent request
--   and then responds to SetInteriorVD request after receiving request on HMI
-- 4)When HMI processes the requests without consent it sends the response in 11 seconds after receiving request on HMI
-- SDL does:
-- 1) Respond with SUCCESS resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunction = {
	respTime = 11000,
	notificationTime = 0,
	resetPeriod = 15000
}

local paramsForRespFunctionWithConsent = {
  respTime = 21000,
  notificationTime = 0,
  resetPeriod = 25000
}

local RespParams = { success = true, resultCode = "SUCCESS" }

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
for _, rpc in pairs(common.rpcsArray) do
  runner.Step("Send " .. rpc , common.rpcs[rpc],
	{ 12000, 11000, common.responseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })
end
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 22000, 21000, common.responseWithOnResetTimeout, paramsForRespFunctionWithConsent, RespParams, common.responseTimeCalculationFromNotif })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
