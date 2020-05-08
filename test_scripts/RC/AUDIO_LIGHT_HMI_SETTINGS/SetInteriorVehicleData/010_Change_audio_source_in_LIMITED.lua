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
-- 2) App in LIMITED HMI level
-- 3) App tries to change audio source between various audio sources several times
-- SDL must:
-- 1) Change audio source successfully as many times as defined
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

--[[ Local Functions ]]
local function setVehicleData(pSource)
  audioData.audioControlData.source = pSource
  local cid = common.getMobileSession():SendRPC("SetInteriorVehicleData", {
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

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function bringAppToLIMITED()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
      appID = common.getHMIAppId(),
      reason = "GENERAL"
    })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Set App to LIMITED HMI level", bringAppToLIMITED)

runner.Title("Test")
for _, source in pairs(common.audioSources) do
  runner.Step("SetInteriorVehicleData with source " .. source, setVehicleData, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
