--  Requirement summary:
--  [HeartBeat]: SDL must close only session in case mobile app does not answer on Heartbeat_request
--  [HeartBeat] [GENIVI]: SDL must start HeartBeat process immediately after first StartService request from mobile app
--
--  Description:
--  Check that heartbeat timeout occurs if App uses v3 protocol version and doesn't send HB to SDL
--  and doesn't response to SDL HB

--  1. Used precondition
--  SDL, HMI are running.
--  Mobile device is connected.
--  HeartBeatTimeout = 5000
--
--  2. Performed steps
--  Start SPT, select transport, specify protocols = 3
--  sendHeartbeatToSDL = false
--  answerHeartbeatFromSDL = false
--  Wait 15 sec.
--
--  Expected behavior:
--  1. App has successfully registered.
--  2. App is disconnected by SDL due to heartbeat timeout occurs.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local HBParams_1 = {
  activateHeartbeat = false,
  sendHeartbeatToSDL = false,
  answerHeartbeatFromSDL = false,
  ignoreSDLHeartBeatACK = false,
}

local HBParams_2 = {
  activateHeartbeat = true,
  sendHeartbeatToSDL = true,
  answerHeartbeatFromSDL = true,
  ignoreSDLHeartBeatACK = false,
}

--[[ Local Functions ]]
local function firstAppIsUnregistered()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(1), unexpectedDisconnect = true })
  :Do(function()
      common.getMobileSession(1):StopHeartbeat()
    end)
  :Timeout(15000)
end

local function secondAppIsStillRegistered()
  local cid = common.getMobileSession(2):SendRPC("RegisterAppInterface", common.getConfigAppParams(2))
  common.getMobileSession(2):ExpectResponse(cid, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set HeartBeatTimeout", common.setSDLIniParameter, { "HeartBeatTimeout", 5000 })
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App 1", common.registerApp, { 1, HBParams_1 })
runner.Step("Register App 2", common.registerApp, { 2, HBParams_2 })

runner.Title("Test")
runner.Step("Wait 15 seconds and verify 1st app is unregistered", firstAppIsUnregistered)
runner.Step("Verify 2nd app is still registered", secondAppIsStillRegistered)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
