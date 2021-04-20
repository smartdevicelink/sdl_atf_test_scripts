--  Requirement summary:
--  [HMILevel Resumption]: Both LIMITED and FULL applications must be included to resumption list
--
--  Description:
--  Applications of BACKGROUND are not the case of HMILevel resumption in the next ignition cycle.
--  Check that SDL performs app's data resumption and does not resume BACKGROUND HMI level
--  of media after transport unexpected disconnect on mobile side.

--  1.  Used precondition
--  App in  BACKGROUND
--  Default HMI level is NONE.
--  App has added 1 sub menu, 1 command and 1 choice set.

--  2. Performed steps
--  Turn off transport.
--  Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered from HMI.
--     App is registered on HMI, SDL resumes all data and App gets default HMI level NONE.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function expResData()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", common.reqParams.AddCommand.hmi)
  :Times(0)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", common.reqParams.AddSubMenu.hmi)
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
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
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App 1", common.registerApp)
runner.Step("Activate App 1", common.activateApp)
runner.Step("Add Command", common.addCommand)
runner.Step("Add SubMenu", common.addSubMenu)
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("UnRegister App 2", common.unregisterApp, { 2 })
runner.Step("UnRegister App 1", common.unregisterApp)

runner.Title("Test")
runner.Step("ReRegister App", common.reregisterApp, { "RESUME_FAILED", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
