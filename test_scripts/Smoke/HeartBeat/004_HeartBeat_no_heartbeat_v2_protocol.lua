--  Requirement summary:
--  [Services]: SDL must support Heartbeat over protocol v3 or higher
--
--  Description:
--  Check that no heartbeat timeout occurs if App uses v2 protocol version.

--  1. Used precondition
--  SDL, HMI are running.
--  Mobile device is connected.
--  HeartBeatTimeout = 5000
--
--  2. Performed steps
--  Start SPT, select transport, specify protocols = 2
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
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local HBParams = {
  activateHeartbeat = false,
  sendHeartbeatToSDL = false,
  answerHeartbeatFromSDL = false,
  ignoreSDLHeartBeatACK = false
}

--[[ Local Functions ]]
local function wait()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Times(0)
  local event = common.createEvent(function(_, data)
    return data.frameType == common.constants.FRAME_TYPE.CONTROL_FRAME
      and data.serviceType == common.constants.SERVICE_TYPE.CONTROL
      and data.frameInfo == common.constants.FRAME_INFO.HEARTBEAT
      and data.sessionId == common.getMobileSession().sessionId
  end)
  common.getMobileSession():ExpectEvent(event, "Heartbeat")
  :Times(0)
  common.wait(15000)
end

local function appIsStillRegistered()
  local cid = common.getMobileSession(1):SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
  common.getMobileSession(1):ExpectResponse(cid, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" })
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
