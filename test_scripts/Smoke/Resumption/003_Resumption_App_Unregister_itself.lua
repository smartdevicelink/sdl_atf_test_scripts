--  Requirement summary:
--  [Data Resumption] Application data must not be resumed
--
--  Description:
--  Check that no resumption occurs if App unregister itself gracefully.

--  1. Used precondition
--  App is registered and activated on HMI.

--  2. Performed steps
--  Exit from SPT
--  Start SPT again, Find Apps
--
--  Expected behavior:
--  1. SPT sends UnregisterAppInterface and EndSession to SDL.
--     SPT register in usual way, no resumption occurs
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
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Add Command", common.addCommand)
runner.Step("Add SubMenu", common.addSubMenu)

runner.Title("Test")
runner.Step("UnRegister App", common.unregisterApp)
runner.Step("ReRegister App", common.reregisterApp, { "RESUME_FAILED", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
