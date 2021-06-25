------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to reset timeout for Mobile app response to defined period
--  by receiving 'OnResetTimeout(resetPeriod)' notification from HMI
-- Applicable RPCs: 'SendLocation', 'Alert', 'SubtleAlert', 'PerformInteraction', 'Slider', 'Speak',
--  'ScrollableMessage', 'DiagnosticMessage', 'SetInteriorVehicleData'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL right after receiving request with data:
--  - 'resetPeriod = 25s' for 'GetInteriorVehicleDataConsent' RPC
--  - 'resetPeriod = 15s' for all other RPCs
-- 4) HMI sends response after:
--  - 21s for 'GetInteriorVehicleDataConsent'
--  - 11s for all other requests
-- SDL does:
--  - wait for the response from HMI within reset period
--  - once received it proceed with response successfully and transfer it to Mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

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
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("Create InteractionChoiceSet id 100", common.createInteractionChoiceSet, { 100 })
common.Step("Create InteractionChoiceSet id 200", common.createInteractionChoiceSet, { 200 })
common.Step("Add AddSubMenu", common.addSubMenu)

common.Title("Test")
for _, rpc in pairs(common.rpcsArray) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
	{ 12000, 11000, common.responseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })
end
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 22000, 21000, common.responseWithOnResetTimeout, paramsForRespFunctionWithConsent, RespParams, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
