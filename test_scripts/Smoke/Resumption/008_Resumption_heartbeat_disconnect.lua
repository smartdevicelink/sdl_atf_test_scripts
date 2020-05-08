--  Requirement summary:
--  [Data Resumption]: Data resumption on Unexpected Disconnect
--
--  Description:
--  Check that SDL perform resumption after heartbeat disconnect.

--  1. Used precondition
--  In smartDeviceLink.ini file HeartBeatTimeout parameter is:
--  HeartBeatTimeout = 7000.
--  App is registerer and activated on HMI.
--  App has added 1 sub menu, 1 command and 1 choice set.
--
--  2. Performed steps
--  Wait 20 seconds.
--  Register App with hashId.
--
--  Expected behavior:
--  1. SDL sends OnAppUnregistered to HMI.
--  2. App is registered and  SDL resumes all App data, sends BC.ActivateApp to HMI, app gets FULL HMI level.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

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
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
end

local function Wait_20_sec()
  common.getMobileSession():StopHeartbeat()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Timeout(20000)
  common.getMobileSession():ExpectEvent(common.events.disconnectedEvent, "Disconnected")
  :Times(0)
  :Timeout(20000)
  common.wait(20000)
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
runner.Step("Wait_20_sec", Wait_20_sec)
runner.Step("ReRegister App", common.reregisterApp, { "SUCCESS", expResData, expResLvl })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
