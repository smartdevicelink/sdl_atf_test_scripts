------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - App sends 2 different requests
--  - and HMI provides 'OnResetTimeout(resetPeriod)' for each request
--  - and HMI hasn't responded
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends 2 different applicable RPCs
-- 2) SDL transfers these requests to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notifications to SDL for these 2 requests right after receiving them:
--  - 1st request with 'resetPeriod=11s'
--  - 2nd request with 'resetPeriod=13s'
-- 4) HMI doesn't provide a response for both requests
-- SDL does:
--  - wait for the 1st response from HMI within '1st reset period' (11s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
--  - wait for the 2nd response from HMI within '2nd reset period' (13s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 0,
  resetPeriod = common.defaultTimeout + 1000
}

local paramsForRespFunctionSecondNot = {
  notificationTime = 0,
  resetPeriod = common.defaultTimeout + 3000
}

local RespParams = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function twoRequestsinSameTime()
  common.rpcs.DiagnosticMessage(common.defaultTimeout + 2000, common.defaultTimeout + 1000,
    common.onResetTimeoutOnly,
    paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif)

  common.rpcs.SetInteriorVehicleData(common.defaultTimeout + 4000, common.defaultTimeout + 3000,
    common.onResetTimeoutOnly,
    paramsForRespFunctionSecondNot, RespParams, common.responseTimeCalculationFromNotif)
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
