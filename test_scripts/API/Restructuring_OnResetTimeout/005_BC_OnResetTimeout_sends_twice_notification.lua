---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 11000) to SDL after receiving HMI request
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 7000) to SDL in 6 sec after receiving HMI request
-- 5) HMI does not send response in 13 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 13 seconds are expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunctionFirstNot = {
  notificationTime = 0,
  resetPeriod = 11000
}

local paramsForRespFunctionSecondNot = {
  notificationTime = 6000,
  resetPeriod = 7000
}

--[[ Local Functions ]]
local function diagnosticMessageError()
  local pRespTime = 7000
  local requestParams = { targetID = 1, messageLength = 1, messageData = { 1 } }
  local cid = common.getMobileSession():SendRPC("DiagnosticMessage", requestParams)

  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", requestParams)
  :Do(function(_, data)
    common.withoutResponseWithOnResetTimeout(data, paramsForRespFunctionFirstNot)
    common.withoutResponseWithOnResetTimeout(data, paramsForRespFunctionSecondNot)
  end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(14000)
  :ValidIf(function()
    local respTime = timestamp()
    local timeBetweenRespAndNot = respTime - common.notificationTime
    if timeBetweenRespAndNot >= pRespTime - 500 and timeBetweenRespAndNot <= pRespTime + 500 then
      return true
    else
      return false, "Response is received in some unexpected time. Actual time is " .. timeBetweenRespAndNot ..
      ". Expected time is " .. pRespTime
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Send DiagnosticMessage", diagnosticMessageError)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
