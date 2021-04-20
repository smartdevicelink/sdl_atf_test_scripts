--  Requirement summary:
--  [HMILevel Resumption]: Conditions to resume app to LIMITED after "unexpected disconnect" event.
--
--  Description:
--  Check that SDL resumes LIMITED  level of media App and it's data
--  after transport unexpected disconnect

--  1. Used precondition
--  App in LIMITED on HMI.
--  App has added 1 sub menu, 1 command and 1 choice set.
--
--  2. Performed steps
--   Turn off transport.
--   Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered from HMI.
--  2. App is registered on HMI, SDL resumes all App's data and sends OnResumeAudioSource to HMI.
--     App gets LIMITED HMI Level
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
  common.getHMIConnection():SendNotification("BasicCommunication.OnResumeAudioSource", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(), reason = "GENERAL" })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
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
runner.Step("Deactivate app", deactivateApp)
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
