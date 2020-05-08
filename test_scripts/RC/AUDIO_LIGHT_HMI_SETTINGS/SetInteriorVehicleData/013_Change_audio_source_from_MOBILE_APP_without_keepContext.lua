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
-- 3) App tries to change audio source from MOBILE_APP with keepContext = false
-- SDL must:
-- 1) Change audio source successfully
-- 2) Change HMI level of App to BACKGROUND
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
local function setVehicleDataMobileApp()
  local mobSession = common.getMobileSession()
  audioData.audioControlData.source = "MOBILE_APP"
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
end

local function setVehicleData()
  local mobSession = common.getMobileSession()
  audioData.audioControlData.source = "USB"
  audioData.audioControlData.keepContext = nil
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
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
          eventName = "AUDIO_SOURCE",
          isActive = true
        })
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SetInteriorVehicleData source MOBILE_APP", setVehicleDataMobileApp)

runner.Title("Test")
runner.Step("Change audio source from MOBILE_APP without keepContext", setVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
