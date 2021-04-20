---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is started (there was no LOW_VOLTAGE signal sent)
-- 2) SDL get IGNITION_OFF or WAKE_UP signal
-- SDL does:
-- 1) Ignore WAKE_UP signal and continue working as usual
-- 2) Ignore IGNITION_OFF signal and continue working as usual
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/SDL5_0/LowVoltage/common')
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

local function sendIgnitionOffSignal()
  common.sendSignal("IGNITION_OFF")
  os.execute("sleep 1")
end

local function isSDLRunning()
  if common.SDL:CheckStatusSDL() ~= common.SDL.RUNNING then
    common.failTestCase("SDL is stopped")
  else
    common.cprint(35, "SDL is running")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send WAKE_UP signal", common.sendWakeUpSignal)
runner.Step("AddCommand success", processAddCommandSuccessfully)
runner.Step("Send IGNITION_OFF signal", sendIgnitionOffSignal)
runner.Step("Check SDL is not stopped", isSDLRunning)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
