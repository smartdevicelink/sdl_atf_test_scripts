------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL does not reset timeout for Mobile app response for a specifc RPC in case
--  HMI sends 'OnResetTimeout(resetPeriod)' notification
-- Applicable RPCs: 'DialNumber', 'Alert' (with soft buttons), 'SubtleAlert' (with soft buttons)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL right after receiving request with 'resetPeriod = 12s'
-- 4) HMI sends response after delay of 14s
-- SDL does:
--  - not apply default timeout
--  - not reset timeout once 'BC.OnResetTimeout' notification is received
--  - wait for the response from HMI
--  - once received it proceed with response successfully and transfer it to Mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function DialNumber(isSendingNotification)
  local cid = common.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })
  local requestTime = timestamp()
  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = common.getHMIAppId(), number = "#3804567654*" })
  :Do(function(_, data)
      if isSendingNotification == true then
        common.onResetTimeoutNotification(data.id, data.method, 12000)
      end
      local function sendresponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(sendresponse, 14000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(15000)
  :ValidIf(function()
      if isSendingNotification == true then
        return common.responseTimeCalculationFromMobReq(14000, nil, requestTime)
      end
      return true
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send DialNumber", DialNumber)
common.Step("Send DialNumber with OnResetTimeout notification", DialNumber, { true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
