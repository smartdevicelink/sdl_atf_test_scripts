---------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function processAddCommandSuccessfully()
  local cid = common.getMobileSession():SendRPC("AddCommand", { cmdID = 1, vrCommands = { "CMD" }})
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate for App", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

runner.Step("Send WAKE_UP signal", common.sendMQWakeUpSignal)

runner.Step("AddCommand success", processAddCommandSuccessfully)

runner.Step("Send SHUT_DOWN signal", common.sendMQShutDownSignal)

runner.Step("Check SDL stopped", common.isSDLStopped)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
