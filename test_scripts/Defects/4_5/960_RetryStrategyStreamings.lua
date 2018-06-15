---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/960
---------------------------------------------------------------------------------------------------
-- SDL retry send StartStream/StartAudioStream less on one time than configured in .ini file
-- Preconditions:
-- Core, HMI started.
-- StartStreamRetry = 3, 3 in .ini file.
-- Navi app registered and activated on HMI.
-- Steps to reproduce:
-- Start Audio/Video service.
-- Press cancel on HTML5 HMI (emulate REJECT from HMI) => SDL start retry sequence.
-- Press Cancel on all appeared pop-ups.
-- Actual result:
-- After unsuccessful StartStream/StartAudioStream (first REJECT) SDL retry to start 2 times instead 3 times.
-- Expected result:
-- The counting of retries should be started after first unsuccessfuly response.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/commonDefects')
local SmartDeviceLinkConfigurations = require("user_modules/shared_testcases/SmartDeviceLinkConfigurations")

config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local StartStreamRetryIniValue

--[[ Local Functions ]]
local function NavigationVideoRetry(self)
  self.mobileSession1:StartService(11)
  :Do(function()
      EXPECT_HMICALL("Navigation.StartStream")
      :Times(4)
      :Do(function(exp,data)
          if exp.occurences == 4 then
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          else
            self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Request is rejected")
          end
        end)
    end)
end

local function NavigationAudioRetry(self)
  self.mobileSession1:StartService(10)
  :Do(function()
      EXPECT_HMICALL("Navigation.StartAudioStream")
      :Times(4)
      :Do(function(exp,data)
          if exp.occurences == 4 then
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          else
            self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Request is rejected")
          end
        end)
    end)
end

local function SetNewRetryValue(setValue)
  if setValue == "default" then
    setValue = StartStreamRetryIniValue
  end
  SmartDeviceLinkConfigurations:ReplaceString("StartStreamRetry =.*$", "StartStreamRetry = " .. setValue)
end

local function GetRetryValue()
  StartStreamRetryIniValue = SmartDeviceLinkConfigurations:GetValue("StartStreamRetry")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("GetRetryValue", GetRetryValue)
runner.Step("SetNewRetryValue", SetNewRetryValue, { "3, 1000" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
runner.Step("RAI, PTU", commonDefects.rai_ptu)
runner.Step("Activate App", commonDefects.activate_app)

runner.Title("Test")
runner.Step("Retry_sequence_start_video_streaming", NavigationVideoRetry)
runner.Step("Retry_sequence_start_audio_streaming", NavigationAudioRetry)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
runner.Step("RestoreDefaultValues", SetNewRetryValue, { "default" })
