---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local testCases = {
  [111] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "MEDIA", m = true }, a = 1, s = "ATTENUATED",  mix = true },
  [112] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "MEDIA", m = true }, a = 1, s = "NOT_AUDIBLE", mix = false },
  [113] = { [1] = { t = "MEDIA", m = true }, [2] = { t = "NAVIGATION", m = false }, a = 2, s = "ATTENUATED",  mix = true },
  [114] = { [1] = { t = "MEDIA", m = true }, [2] = { t = "NAVIGATION", m = false }, a = 2, s = "NOT_AUDIBLE", mix = false }
}

--[[ Local Functions ]]
local function getHMIParams(pIsMixingSupported)
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.BasicCommunication.MixingAudioSupported.params.attenuatedSupported = pIsMixingSupported
  return hmiParams
end

local function appStartStreaming(pTC, pStreamingAppId, pAudioSSApp)
  common.getMobileSession(pStreamingAppId):StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession(pStreamingAppId):StartStreaming(10,"files/Kalimba.mp3")
          EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
        end)
    end)
  local notStreamingAppId
  if pStreamingAppId == 1 then notStreamingAppId = 2 else notStreamingAppId = 1 end
  common.getMobileSession(pStreamingAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
  common.getMobileSession(notStreamingAppId):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      common.getMobileSession(pStreamingAppId):StopStreaming("files/Kalimba.mp3")
      return common.checkAudioSS(pTC, "App" .. notStreamingAppId, pAudioSSApp, data.payload.audioStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: isMixing:" .. tostring(tc.mix) .. ", "
    .. "App1[hmiType:" .. tc[1].t .. ", isMedia:" .. tostring(tc[1].m) .. "], "
    .. "App2[hmiType:" .. tc[2].t .. ", isMedia:" .. tostring(tc[2].m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session, isMixingSupported:" .. tostring(tc.mix),
    common.start, { getHMIParams(tc.mix) })
  runner.Step("Set App 1 Config", common.setAppConfig, { 1, tc[1].t, tc[1].m })
  runner.Step("Set App 2 Config", common.setAppConfig, { 2, tc[2].t, tc[2].m })
  runner.Step("Register App 1", common.registerApp, { 1 })
  runner.Step("Register App 2", common.registerApp, { 2 })
  runner.Step("Activate App 1", common.activateApp, { 1 })
  runner.Step("Activate App 2", common.activateApp, { 2 })
  runner.Step("App " .. tc.a .. " starts streaming", appStartStreaming, { n, tc.a, tc.s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
