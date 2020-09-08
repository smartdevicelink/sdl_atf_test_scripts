-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1906
--
-- Description:
-- Navigation app must be activated during active embedded navigation and "MixingAudioSupported" = true.
--
-- Precondition:
-- 1) MixingAudioSupported" = true at .ini file
-- 2) SDL and HMI are started.
-- 3) Navigation app is registered.
-- 4) Navigation app in LIMITED and AUDIBLE due to active embedded audio source
--
-- Steps to reproduce:
-- 1) SDL receives SDL.ActivateApp (<appID_of_navigation_app>) from HMI
-- SDL does:
-- a. send OnHMIStatus (FULL, AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local hmi_values = require('user_modules/hmi_values')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function hmiCapabilitiesUpdate()
  local params = hmi_values.getDefaultHMITable()
  params.BasicCommunication.MixingAudioSupported.attenuatedSupported = true
  return params
end

local function start(getHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
    self:initHMI(self)
    :Do(function()
        commonFunctions:userPrint(35, "HMI initialized")
        self:initHMI_onReady(getHMIParams)
        :Do(function()
          commonFunctions:userPrint(35, "HMI is ready")
          self:connectMobile()
          :Do(function()
            commonFunctions:userPrint(35, "Mobile connected")
            common.allow_sdl(self)
          end)
        end)
      end)
  end)
end

local function onEventChange(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

local function setMixingAudioSupportedTrue()
  commonFunctions:write_parameter_to_smart_device_link_ini("MixingAudioSupported", "true")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Backup .ini file", common.backupINIFile)
runner.Step("Set MixingAudioSupported=true in .ini file", setMixingAudioSupportedTrue)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { hmiCapabilitiesUpdate() })
runner.Step("RAI", common.rai_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("onEventChange AUDIO_SOURCE true", onEventChange)
runner.Step("Activate App", common.activate_app)

runner.Title("Postconditions")
runner.Step("Restore .ini file", common.restoreINIFile)
runner.Step("Stop SDL", common.postconditions)
