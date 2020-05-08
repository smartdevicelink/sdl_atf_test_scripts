---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 2.2
--
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Use Case 1: Exceptions: 7.3
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Application registered with REMOTE_CONTROL AppHMIType and sends SetInteriorVehicleData RPC
-- 2) (with "climateControlData" and RADIO moduleType) OR (with "radioControlData" and CLIMATE moduleType)
-- SDL must:
-- 1) Respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
  local moduleType2 = nil
  if pModuleType == "CLIMATE" then
    moduleType2 = "RADIO"
  elseif pModuleType == "RADIO" then
    moduleType2 = "CLIMATE"
  end

  local moduleData = commonRC.getSettableModuleControlData(moduleType2)
  moduleData.moduleType = pModuleType

  local cid = commonRC.getMobileSession():SendRPC("SetInteriorVehicleData", {
    moduleData = moduleData
  })

  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)

  commonRC.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonRC.wait(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Step("SetInteriorVehicleData " .. mod .. "_gets_INVALID_DATA", setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
