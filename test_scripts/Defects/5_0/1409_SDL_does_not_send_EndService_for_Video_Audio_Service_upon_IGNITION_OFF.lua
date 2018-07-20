-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1409
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) SPT is registered using v3 protocol and activated on HMI
-- Description:
--
-- Steps to reproduce:
-- 1) Start Video Service -> SDL send StartServiceACK to mobile
-- 2) Start Audio service -> SDL send StartServiceACK to mobile
-- 3) Send IGNITION_OFF from HMI: On HTML5 HMI click Exit Application and select Ignition Off from drop down
-- Expected result:
-- SDL sends End Service (Control Frame 0x04) for: RPC, Audio and Video services
-- Actual result:
-- SDL sends End Service for RPCservice only.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local events = require('events')

config.defaultProtocolVersion = 3

--[[ Local Variables ]]

--[[ Local Functions ]]
local function appStartAudioStreaming(self)
  self.mobileSession1:StartService(10)
  :Do(function()
      self.hmiConnection:ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          self.mobileSession1:StartStreaming(10,"files/MP3_1140kb.mp3")
          self.hmiConnection:ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
        end)
    end)
end

local function appStartVideoStreaming(self)
  self.mobileSession1:StartService(11)
  :Do(function()
      self.hmiConnection:ExpectRequest("Navigation.StartStream")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          self.mobileSession1:StartStreaming(11, "files/MP3_4555kb.mp3")
          self.hmiConnection:ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
        end)
    end)
end

local function ExitAllApplications(self)
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  local event = events.Event()
    event.matches = function(_, data)
          return data.frameType   == 0 and
              (data.serviceType == 11 or data.serviceType == 10 or data.serviceType == 7) and
                 data.sessionId   == self.mobileSession1.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
    self.mobileSession1:ExpectEvent(event, "EndService")
    :Timeout(60000)
    :Times(3)
    :ValidIf(function(_, data)
      if data.frameInfo == 4  and data.serviceType == 11 then
        self.mobileSession1:Send(
          {
            frameType   = 0,
            serviceType = 11,
            frameInfo   = 5,
            sessionId   = self.mobileSession1.sessionId,
          })
        return true

        elseif data.frameInfo == 4  and data.serviceType == 10 then
          return true
        elseif data.frameInfo == 4  and data.serviceType == 7 then
          return true
        else return false, "End Service not received"
      end
    end)

    EXPECT_HMICALL("Navigation.StopAudioStream")
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
      end)

    EXPECT_HMICALL("Navigation.StopStream")
    :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("App starts Audio streaming", appStartAudioStreaming)
runner.Step("App starts Video streaming", appStartVideoStreaming)
runner.Step("Exit application", ExitAllApplications)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
