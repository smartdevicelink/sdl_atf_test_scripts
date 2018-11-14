---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC_1 for several interfaces is requested by mobile app
-- 2) SDL sends Interface_1.RPC_1 and Interface_2.RPC_1
-- 3) Some time after receiving requests  on HMI is passed
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 6000) to SDL for request on Interface_1
-- 5) HMI does not respond to both request
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function addCommand()
  local params = {
    cmdID = 11,
    vrCommands = {
      "VRCommandonepositive",
      "VRCommandonepositivedouble"
    },
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local corId = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function()
    -- HMi did not respond
  end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
    common.onResetTimeoutNotification(data.id, data.method, 6000)
  end)

  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(11000)
  :ValidIf(function()
    local respTime = timestamp()
    local checkTime = 10000
    local timeBetweenRespAndNot = respTime - common.notificationTime
    if timeBetweenRespAndNot >= checkTime - 500 and timeBetweenRespAndNot <= checkTime + 500 then
      return true
    else
      return false, "Response is received in some unexpected time. Actual time is " .. timeBetweenRespAndNot ..
      ". Expected time is " .. checkTime
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
runner.Step("Send AddCommand" , addCommand)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
