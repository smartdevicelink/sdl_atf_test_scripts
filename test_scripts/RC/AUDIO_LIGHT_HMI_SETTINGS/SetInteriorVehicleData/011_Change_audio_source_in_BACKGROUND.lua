---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) App is RC and Media
-- 2) App in NONE or BACKGROUND HMI level
-- 3) App tries to change audio source
-- SDL must:
-- 1) Not change audio source
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Variables ]]
local audioData = common.getSettableModuleControlData("AUDIO")
local audioSources = {
  "NO_SOURCE_SELECTED",
  "CD",
  "BLUETOOTH_STEREO_BTST",
  "USB",
  "USB2",
  "LINE_IN",
  "IPOD",
  "MOBILE_APP",
  "RADIO_TUNER"
}

--[[ Local Functions ]]
local function setVehicleData(pSource)
  audioData.audioControlData.source = pSource
  local cid = common.getMobileSession():SendRPC("SetInteriorVehicleData", { moduleData = audioData })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", { appID = common.getHMIAppId(), moduleData = audioData })
  :Do(function(_, data)
      common.getHMIconnection():SendError(data.id, data.method, "REJECTED", "Error")
    end)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = "Error" })
end

local function BringAppToBACKGROUND()
  common.activateApp(2)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU App1", common.raiPTUn)
runner.Step("RAI App2", common.raiN, {2})
runner.Step("Activate App1", common.activateApp)
runner.Step("Set App1 to BACKGROUND HMI level", BringAppToBACKGROUND)

runner.Title("Test")
for _, source in pairs(audioSources) do
  runner.Step("SetInteriorVehicleData with source " .. source, setVehicleData, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
