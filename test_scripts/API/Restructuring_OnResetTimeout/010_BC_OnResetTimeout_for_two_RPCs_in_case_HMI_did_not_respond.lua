---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC_1 is requested
-- 2) RPC_2 is requested
-- 3) Some time after receiving RPC_1 and RPC_2 requests on HMI is passed
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 11000) to SDL for RPC_1 and BC.OnResetTimeout(resetPeriod = 13000) for RPC_2
-- 5) HMI does not respond
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app to RPC_1 in 11 seconds
-- 2) Respond with GENERIC_ERROR resultCode to mobile app to RPC_2 in 13 seconds
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local paramsForRespFunction = {
	notificationTime = 0,
	resetPeriod = 11000
}

local paramsForRespFunctionSecondNot = {
	notificationTime = 0,
	resetPeriod = 13000
}

--[[ Local Functions ]]
local function twoRequestsinSameTime()
	common.rpcs.DiagnosticMessage(12000, 11000,
		common.withoutResponseWithOnResetTimeout, paramsForRespFunction, common.rpcResponse)

	common.rpcs.SetInteriorVehicleData(14000, 13000,
    common.withoutResponseWithOnResetTimeout, paramsForRespFunctionSecondNot, common.rpcResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Send DiagnosticMessage and SetInteriorVehicleData" , twoRequestsinSameTime)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
