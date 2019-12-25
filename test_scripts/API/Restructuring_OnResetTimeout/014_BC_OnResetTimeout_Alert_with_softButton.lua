---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) Alert with softButton is requested
-- 2) Some time after receiving Alert request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 15000) to SDL
-- 4) HMI sends response in 17 seconds after response receiving
-- SDL does:
-- 1) not apply Alert timeout and not reset timeout by BC.OnResetTimeout
-- 2) process response from HMI and respond SUCCESS to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 17000,
  notificationTime = 0,
  resetPeriod = 15000
}

--[[ Local Functions ]]
local function Alert()
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

  common.getHMIConnection():ExpectRequest( "UI.Alert")
  :Do(function(_, data)
      common.responseWithOnResetTimeout(data, paramsForRespFunction)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(18000)
  :ValidIf(function()
      return common.responseTimeCalculation(17000)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Send Alert with softButton", Alert)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
