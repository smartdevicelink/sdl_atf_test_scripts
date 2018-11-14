---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC_1 for several interfaces is requested by mobile app
-- 2) SDL sends Interface_1.RPC_1 and Interface_2.RPC_1
-- 3) HMI sends BC.OnResetTimeout(resetPeriod =  15000) to SDL for request on Interface_1 right after receiving requests on HMI
-- 4) HMI responds to Interface_1.RPC_1 and Interface_2.RPC_1 with SUCCESS resultCode in 12 seconds after receiving HMI requests
-- SDL does:
-- 1) Respond in 12 seconds with SUCCESS resultCode to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 12000,
  notificationTime = 0,
  resetPeriod = 15000
}

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
  :Do(function(_, data)
      local function Response()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(Response, 12000)
    end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.responseWithOnResetTimeout(data, paramsForRespFunction)
    end)

  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Timeout(13000)
  :ValidIf(function()
      return common.responseTimeCalculationFromNotif(12000)
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
