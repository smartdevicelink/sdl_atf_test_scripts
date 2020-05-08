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
-- 2) App in FULL HMI level
-- 3) App tries to change audio source from any type except of MOBILE_APP and with any value of keepContext parameter or event without it
-- SDL must:
-- 1) Change audio source successfully
-- 2) Not change HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true

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
  "AM",
  "FM",
  "XM",
  "DAB"
}

local keepContext = {
  false,
  true,
  "empty"
}

--[[ Local Functions ]]
local function setVehicleData(pSource,pKeepContext)
  local mobSession = common.getMobileSession()
  audioData.audioControlData.source = pSource
  if "empty" == pKeepContext then
    audioData.audioControlData.keepContext = nil
  else
    audioData.audioControlData.keepContext = pKeepContext
  end
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
      moduleData = audioData
    })
  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleData = audioData
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = audioData
        })
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, source in pairs(audioSources) do
  for _, keepContextValue in pairs(keepContext) do
    runner.Step("Change audio source from " .. source .. " source with keepContext is " ..
      tostring(keepContextValue), setVehicleData, { source, keepContextValue })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
