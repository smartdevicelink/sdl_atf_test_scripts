---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) 15 seconds after receiving GetInteriorVehicleDataConsent request
--   or 5 seconds after receiving all other RPCs on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(without resetPeriod) to SDL
-- 4)When HMI processes the RPC with InteriorVD consent, it sends the response in 21 seconds
--  to GetInteriorVehicleDataConsent request
--   and then responds to SetInteriorVD request after receiving request on HMI
-- 5)When HMI processes the requests without consent it sends the response in 11 seconds after receiving request on HMI
-- SDL does:
-- 1) Apply default 10 sec timeout by receiving BC.OnResetTimeout(without resetPeriod)
-- 2) Receive response and successful process it
-- 3) Respond with SUCCESS resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
	respTime = 11000,
	notificationTime = 5000
}

local paramsForRespFunctionWithConsent = {
  respTime = 21000,
  notificationTime = 15000,
}

local RespParams = { success = true, resultCode = "SUCCESS" }

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
    { 12000, 6000, common.responseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })
end
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 22000, 6000, common.responseWithOnResetTimeout, paramsForRespFunctionWithConsent, RespParams, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
