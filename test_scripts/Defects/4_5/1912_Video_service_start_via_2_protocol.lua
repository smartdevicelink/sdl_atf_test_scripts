---------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1912
-- Description
-- SDL must respond NACK in case navigation app connected over protocol v2 sends StartService for audio service
-- Preconditions
-- SDL and HMI are started.
-- Steps to reproduce
-- navigation app connects over protocol v2 and this app sends StartService for audio service
-- Actual result
-- N/A
-- Expected result
-- SDL must respond StartService_NACK to this app
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local constants = require('protocol_handler/ford_protocol_constants')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local events = require('events')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Local Functions ]]
--! @StartAudioServiceVia2Protocol: Start audio service via 2 protocol
--! @parameters:
--! self - test object
--! @return: none
local function StartAudioServiceVia2Protocol(self)
  local StartServiceResponseEvent = events.Event()
  StartServiceResponseEvent.matches =
  function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
    data.serviceType == constants.SERVICE_TYPE.PCM and
    data.sessionId == self.mobileSession1.sessionId and
    (data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK or
      data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK)
  end
  -- Send Audio service start from mobile app to SDL
  self.mobileSession1:Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = constants.SERVICE_TYPE.PCM,
      frameInfo = constants.FRAME_INFO.START_SERVICE
    })
  -- Expect StartServiceNACK on mobile app from SDL, it means service is not started
  self.mobileSession1:ExpectEvent(StartServiceResponseEvent, "Expect StartServiceNACK")
  :ValidIf(function(_, data)
      if data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK then
        return true
      else
        return false, "StartService ACK received"
      end
    end)
  commonDefects.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI", commonDefects.start)
runner.Step("RAI, PTU", commonDefects.rai_ptu)
runner.Step("Activate App", commonDefects.activate_app)

runner.Title("Test")
runner.Step("Start audio service via 2 protocol with expectation of StartServiceNACK", StartAudioServiceVia2Protocol)

runner.Title("Postconditions")
runner.Step("Stop SDL", StopSDL)
