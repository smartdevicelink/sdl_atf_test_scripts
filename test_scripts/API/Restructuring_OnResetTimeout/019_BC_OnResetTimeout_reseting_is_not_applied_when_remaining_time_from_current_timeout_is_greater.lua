---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) HMI sends BC.OnResetTimeout(resetPeriod = 6000) to SDL right after receiving RPC request on HMI
-- 3) HMI does not respond
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app to RPC in 10 seconds
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
	notificationTime = 0,
	resetPeriod = 6000
}

local RespParams = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send SendLocation" , common.rpcs.SendLocation,
  { 11000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
