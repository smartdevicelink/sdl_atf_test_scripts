---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC_1 is requested
-- 2) RPC_1 is requested one more time
-- 3) Some time after receiving RPC_1 requests on HMI is passed
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 13000) to SDL for second request
-- 5) HMI does not respond
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app to first request
-- 2) Respond in 13 seconds with GENERIC_ERROR resultCode to mobile app to second request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function DiagnosticMessage( )
  local requestTime = timestamp()
  local cid1 = common.getMobileSession():SendRPC("DiagnosticMessage",
    { targetID = 1, messageLength = 1, messageData = { 1 } })

  local cid2 = common.getMobileSession():SendRPC("DiagnosticMessage",
    { targetID = 2, messageLength = 1, messageData = { 1 } })

  EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
    { targetID = 1, messageLength = 1, messageData = { 1 } },
    { targetID = 2, messageLength = 1, messageData = { 1 } })
  :Times(2)
  :Do(function(exp, data)
      if exp.occurences == 2 then
        common.onResetTimeoutNotification(data.id, data.method, 13000)
      end
      -- HMI does not respond
    end)

  common.getMobileSession():ExpectResponse(cid1, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(11000)
  :ValidIf(function()
      return common.responseTimeCalculation(10000, nil, requestTime)
    end)

  common.getMobileSession():ExpectResponse(cid2, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(14000)
  :ValidIf(function()
      return common.responseTimeCalculation(13000)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Send DiagnosticMessage", DiagnosticMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
