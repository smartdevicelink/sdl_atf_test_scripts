--  Requirement summary:
--  [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle
--
--  Description:
--  Check that SDL does not perform HMI level resumption of an App in case when transport
--  disconnect occurs in more than 30 sec before BC.OnExitAllApplications(SUSPEND).

--  1. Used precondition
--  Media App is registered and active on HMI

--  2. Performed steps
--  Disconnect app, wait 31 sec
--  Perform ignition off
--  Perform ignition on
--
--  Expected behavior:
--  1. App is successfully registered and receive default HMI level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function expResData()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", common.reqParams.AddCommand.hmi)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", common.reqParams.AddSubMenu.hmi)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function expResLvl()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Times(1)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, 1st cycle", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Add Command", common.addCommand)
runner.Step("Add SubMenu", common.addSubMenu)

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Wait 31 sec", common.wait, { 31000 })

runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, 2nd cycle", common.start)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
