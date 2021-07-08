------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to two Mobile apps in case:
--  - wrong 'methodName' is provided in 'OnResetTimeout()' notifications from HMI
--  - and default reset period is expired
--  - and HMI hasn't responded
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App_1 and App_2 send different applicable RPCs (RPC_1 and RPC_2)
-- 2) SDL transfers these requests to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notifications with
--   - 'resetPeriod=11s' for RPC_1 and 'methodName' for RPC_2
--   - 'resetPeriod=13s' for RPC_2 and 'methodName' for RPC_1
-- 4) HMI doesn't provide a responses
-- SDL does:
--  - wait for the response from HMI within 'default timeout' (10s)
--  - respond with GENERIC_ERROR:false to both Mobile apps once this timeout expires
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
function common.withoutResponseWithOnResetTimeout(pData, pOnRTParams)
  if pData.method == "VehicleInfo.DiagnosticMessage" then
    pData.method = "RC.SetInteriorVehicleData"
  else
    pData.method = "VehicleInfo.DiagnosticMessage"
  end
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(pData.id, pData.method, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

local function twoRequestsinSameTime()
  common.rpcs.DiagnosticMessage(common.defaultTimeout + 1000, common.defaultTimeout,
    common.withoutResponseWithOnResetTimeout,
    paramsForRespFunction, RespParams, common.responseTimeCalculationFromNotif)

  common.rpcs.SetInteriorVehicleData(common.defaultTimeout + 1000, common.defaultTimeout,
    common.withoutResponseWithOnResetTimeout, paramsForRespFunctionSecondNot,
    RespParams, common.responseTimeCalculationFromNotif)
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
