---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) Alert with softButton is requested
-- 2) HMI sends response in 17 seconds after response receiving for first request
-- 3) Alert with softButton is requested
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 15000) to SDL right after receiving Alert request on HMI
-- 5) HMI sends response in 17 seconds after response receiving for second request
-- SDL does:
-- 1) not apply Alert timeout and not reset timeout by BC.OnResetTimeout
-- 2) process response from HMI and respond SUCCESS to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function Alert(isSendingNotification)
  local requestParams = {
    alertText1 = "alertText1",
    progressIndicator = true,
    duration = 3000,
    softButtons = {
      {
        softButtonID = 1,
        text = "Button",
        type = "TEXT",
        isHighlighted = false,
        systemAction = "DEFAULT_ACTION"
      }
    }
  }

  local cid = common.getMobileSession():SendRPC("Alert", requestParams)
  local requestTime = timestamp()

  common.getHMIConnection():ExpectRequest( "UI.Alert")
  :Do(function(_, data)
      if isSendingNotification == true then
        common.onResetTimeoutNotification(data.id, data.method, 15000)
      end
      local function sendresponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(sendresponse, 17000)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(18000)
  :ValidIf(function()
      if isSendingNotification == true then
        return common.responseTimeCalculationFromMobReq(17000, nil, requestTime)
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
common.Step("Send Alert with softButton", Alert)
common.Step("Send Alert with softButton with onResetTimeout notification", Alert, { true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
