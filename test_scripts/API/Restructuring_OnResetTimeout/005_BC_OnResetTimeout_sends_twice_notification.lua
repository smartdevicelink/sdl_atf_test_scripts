---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) HMI sends BC.OnResetTimeout(resetPeriod = 15000) to SDL right after receiving HMI request
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 7000) to SDL in 12 sec after receiving HMI request
-- 4) HMI does not send response in 13 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 19 seconds are expired
---------------------------------------------------------------------------------------------------
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

  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", requestParams)
  :Do(function(_, data)
      common.withoutResponseWithOnResetTimeout(data, paramsForRespFunctionFirstNot)
      common.withoutResponseWithOnResetTimeout(data, paramsForRespFunctionSecondNot)
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
