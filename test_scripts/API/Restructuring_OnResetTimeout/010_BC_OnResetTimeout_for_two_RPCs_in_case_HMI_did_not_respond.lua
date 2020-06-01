---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC_1 is requested
-- 2) RPC_2 is requested
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 11000) to SDL for RPC_1 and BC.OnResetTimeout(resetPeriod = 13000)
--  for RPC_2 right after receiving requests on HMI
-- 4) HMI does not respond
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app to RPC_1 in 11 seconds
-- 2) Respond with GENERIC_ERROR resultCode to mobile app to RPC_2 in 13 seconds
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
	notificationTime = 0,
	resetPeriod = 11000
}

local paramsForRespFunctionSecondNot = {
	notificationTime = 0,
	resetPeriod = 13000
}

local RespParams = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function twoRequestsinSameTime()
	common.rpcs.DiagnosticMessage(12000, 11000,
		common.withoutResponseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif)

	common.rpcs.SetInteriorVehicleData(14000, 13000,
    common.withoutResponseWithOnResetTimeout, paramsForRespFunctionSecondNot, RespParams, common.responseTimeCalculationFromNotif)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send DiagnosticMessage and SetInteriorVehicleData" , twoRequestsinSameTime)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
