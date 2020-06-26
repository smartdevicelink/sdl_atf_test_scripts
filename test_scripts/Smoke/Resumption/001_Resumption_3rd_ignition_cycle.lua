--  Requirement summary:
--  [Data Resumption]: Data resumption on IGNITION OFF
--  [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle.

--  Description:
--  Check that:
--  1. SDL performs App data resumption in case when media app tries to resume in 3rd ignition cycle.
--
--  1. Used precondition
--  Media App is registered and active on HMI
--
--  2. Performed steps
--  Send IGNITION_OFF from HMI.
--  Start SDL. (2nd ignition cycle)
--  Send IGNITION_OFF from HMI.
--  Start SDL. (3rd ignition cycle)
--  Connect transport.
--
--  Expected behavior:
--  1. In 3rd ignition cycle App is registered, app data and HMI level are resumed.
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
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
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
runner.Step("Ignition Off", common.ignitionOff, { expAppUnregistered })
runner.Step("Start SDL, HMI, connect Mobile, 2nd cycle", common.start)
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, 3rd cycle", common.start)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
