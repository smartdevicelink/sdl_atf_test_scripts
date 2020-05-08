---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) App is RC and Non-Media
-- 2) App in any HMI level
-- 3) App tries to change audio source
-- SDL must:
-- 1) Not change audio source
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Variables ]]
local audioData = common.getSettableModuleControlData("AUDIO")

--[[ Local Functions ]]
local function setVehicleData(pSource)
  audioData.audioControlData.source = pSource
  local cid = common.getMobileSession():SendRPC("SetInteriorVehicleData", {
      moduleData = audioData
    })

  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)

  -- Confirmation nedded, not clear what resultCode must be
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, source in pairs(common.audioSources) do
  runner.Step("SetInteriorVehicleData with source " .. source, setVehicleData, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
