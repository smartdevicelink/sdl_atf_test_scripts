---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) DialNumber is requested
-- 2) HMI sends response in 14 sec
-- 3) DialNumber is requested
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 12000) to SDL right after receiving DialNumber request on HMI
-- 5) HMI sends response in 14 sec
-- SDL does:
-- 1) not apply RPC timeout and not reset timeout by BC.OnResetTimeout
-- 2) process response from HMI and respond SUCCESS to mobile app
---------------------------------------------------------------------------------------------------
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
