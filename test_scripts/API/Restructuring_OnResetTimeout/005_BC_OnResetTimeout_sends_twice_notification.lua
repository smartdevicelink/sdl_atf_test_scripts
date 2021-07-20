------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - two reset periods received withing 2 'OnResetTimeout(resetPeriod)' notifications from HMI are expired
--  - and HMI hasn't responded
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 1st 'BC.OnResetTimeout' notification to SDL right after receiving request with 'resetPeriod=15s'
-- 4) HMI sends 2nd 'BC.OnResetTimeout' notification to SDL after delay of 12s with 'resetPeriod=7s'
-- 5) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within 'delay + 2nd resetPeriod' (19s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunctionFirstNot = {
  notificationTime = 0,
  resetPeriod = 15000
}

local paramsForRespFunctionSecondNot = {
  notificationTime = 12000,
  resetPeriod = 7000
}

--[[ Local Functions ]]
local function diagnosticMessageError()
  local requestParams = { targetID = 1, messageLength = 1, messageData = { 1 } }
  local cid = common.getMobileSession():SendRPC("DiagnosticMessage", requestParams)

  common.getHMIConnection():ExpectRequest("VehicleInfo.DiagnosticMessage", requestParams)
  :Do(function(_, data)
      common.onResetTimeoutOnly(data, paramsForRespFunctionFirstNot)
      common.onResetTimeoutOnly(data, paramsForRespFunctionSecondNot)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(20000)
  :ValidIf(function()
      return common.responseTimeCalculationFromNotif(7000)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send DiagnosticMessage", diagnosticMessageError)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
