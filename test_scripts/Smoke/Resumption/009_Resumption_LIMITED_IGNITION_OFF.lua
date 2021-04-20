--  Requirement summary:
--  [HMILevel Resumption]: Send BC.OnResumeAudioSource to HMI for the app resumed to LIMITED
--  [HMILevel Resumption]: Conditions to resume app to LIMITED in the next ignition cycle
--
--  Description:
--  Any application in LIMITED HMILevel during the time frame of 30 sec (inclusive) before
--  BC.OnExitAllApplications(SUSPEND) from HMI
--  SDL must resume LIMITED level, send OnResumeAudioSource to each application.
--
--  1. Used preconditions
--  App is registered and activated on HMI

--  2. Performed steps
--  Perform iginition off
--  Perform ignition on
--
--  Expected result:
--  1. SDL sends to HMI OnSDLClose
--  2. App is registered, SDL sends OnAppRegistered with the same HMI appID as in last ignition cycle, then sets App to LIMITED HMI level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function expAppUnregistered()
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
end

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
runner.Step("Ignition Off", common.ignitionOff, { expAppUnregistered })
runner.Step("Start SDL, HMI, connect Mobile, 2nd cycle", common.start)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
