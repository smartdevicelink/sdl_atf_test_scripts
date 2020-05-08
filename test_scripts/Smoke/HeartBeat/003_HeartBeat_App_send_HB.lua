--  Requirement summary:
--  [Services]: SDL must be able to respond to Heartbeat_request over control service from mobile app
--  [HeartBeat][Genivi]: SDL must track sending of HeartBeat_request from/to mobile app
--
--  Description:
--  Check that no heartbeat timeout occurs if App uses v3 protocol version and send HB to SDL in time less than HB timeout.
--
--  1. Used precondition
--  SDL, HMI are running.
--  Mobile device is connected.
--  HeartBeatTimeout = 5000
--
--  2. Performed steps
--  Start SPT, select transport, specify protocols = 3
--  sendHeartbeatToSDL = true
--  answerHeartbeatToSDL = false
--  Wait 15 sec.
--
--  Expected behavior:
--  1. App has successfully registered.
--  2. App is still registered, no unexpected disconnect occurs.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local HBParams = {
  activateHeartbeat = true,
  sendHeartbeatToSDL = true,
  answerHeartbeatFromSDL = false,
  ignoreSDLHeartBeatACK = true,
}

--[[ Local Functions ]]
local function wait()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Times(0)
  common.wait(15000)
end

local function appIsStillRegistered()
  local cid = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set HeartBeatTimeout", common.setSDLIniParameter, { "HeartBeatTimeout", 5000 })
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp, { 1, HBParams })

runner.Title("Test")
runner.Step("Wait 15 seconds", wait)
runner.Step("Verify app is still registered", appIsStillRegistered)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
