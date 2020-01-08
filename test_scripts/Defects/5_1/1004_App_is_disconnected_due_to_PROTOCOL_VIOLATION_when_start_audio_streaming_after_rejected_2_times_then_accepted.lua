---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1004
-- Description: App is disconnected due to PROTOCOL_VIOLATION when start audio streaming after rejected 2 times then accepted
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App is registered and activated
-- In case:
-- 1) Press "Audio Service - Show" button
-- 2) Press "Start Service"
-- 3) Press "Cancel" on pop-up
-- 4) Press "Cancel" on pop-up
-- 5) Press "OK" pop-up
-- 6) Press "Start File Streaming"
-- Expected result:
-- 1) Audio Streaming is started.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/TTSChunks/common')
local events = require('events')
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Constants ]]
local delay = 800

--[[ Local Functions ]]
local function expectEndService(pServiceId)
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
    and data.serviceType == pServiceId
    and data.sessionId == common.getMobileSession().mobile_session_impl.control_services.session.sessionId.get()
    and data.frameInfo == constants.FRAME_INFO.END_SERVICE
  end
  return common.getMobileSession():ExpectEvent(event, "EndService")
end

local function startStreaming()
  expectEndService(10)
  :Times(0)
  common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
  :Do(function(exp, data)
    local function responseRejected()
      common.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Ignored by USER")
    end
    local function responseSuccess()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
    if exp.occurences >= 1 and exp.occurences <= 3 then
      RUN_AFTER(responseRejected, delay)
    elseif exp.occurences == 4 then
      RUN_AFTER(responseSuccess, delay)
    end
  end)
  :Times(3)
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "PROTOCOL_VIOLATION" })
  :Times(0)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)
  common.getMobileSession():StartService(10)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App launched the audio service and the start of streaming", startStreaming)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
