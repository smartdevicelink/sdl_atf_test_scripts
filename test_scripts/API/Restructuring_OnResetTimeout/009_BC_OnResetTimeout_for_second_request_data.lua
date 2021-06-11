------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - App sends 2 the same requests
--  - and HMI provides 'OnResetTimeout(resetPeriod)' for the 2nd request
--  - and HMI hasn't responded
-- Applicable RPCs: 'SendLocation', 'Alert', 'SubtleAlert', 'PerformInteraction', 'Slider', 'Speak',
--  'ScrollableMessage', 'DiagnosticMessage', 'SetInteriorVehicleData'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC two times
-- 2) SDL transfers these requests to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL for the 2nd request right after receiving it
-- with 'resetPeriod=13s'
-- 4) HMI doesn't provide a response for both requests
-- SDL does:
--  - wait for the 1st response from HMI within 'default timeout' (10s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
--  - wait for the 2nd response from HMI within 'reset period' (13s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function DiagnosticMessage( )
  local cid1 = common.getMobileSession():SendRPC("DiagnosticMessage",
    { targetID = 1, messageLength = 1, messageData = { 1 } })
  local requestTime = timestamp()

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
      return common.responseTimeCalculationFromMobReq(10000, nil, requestTime)
    end)

  common.getMobileSession():ExpectResponse(cid2, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(14000)
  :ValidIf(function()
      return common.responseTimeCalculationFromNotif(13000)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send DiagnosticMessage", DiagnosticMessage)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
