------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL does not reset timeout for Mobile app response for a specific RPC in case
--  HMI sends 'OnResetTimeout(resetPeriod)' notification
-- Applicable RPCs: 'DialNumber', 'Alert' (with soft buttons), 'SubtleAlert' (with soft buttons)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL right after receiving request with 'resetPeriod = 15s'
-- 4) HMI sends response after delay of 17s
-- SDL does:
--  - not apply default timeout
--  - not reset timeout once 'BC.OnResetTimeout' notification is received
--  - wait for the response from HMI
--  - once received it proceed with response successfully and transfer it to Mobile app
------------------------------------------------------------------------------------------------------------------------
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
        common.onResetTimeoutNotification(data.id, data.method, common.defaultTimeout + 5000)
      end
      local function sendresponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(sendresponse, common.defaultTimeout + 7000)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(common.defaultTimeout + 8000)
  :ValidIf(function()
      if isSendingNotification == true then
        return common.responseTimeCalculationFromMobReq(common.defaultTimeout + 7000, nil, requestTime)
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
