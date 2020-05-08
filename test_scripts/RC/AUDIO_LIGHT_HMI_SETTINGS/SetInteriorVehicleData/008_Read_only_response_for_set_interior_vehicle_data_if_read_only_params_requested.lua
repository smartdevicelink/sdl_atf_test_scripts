---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 7.1
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- application sends valid SetInteriorVehicleData with just read-only parameters in "radioControlData" struct for muduleType: RADIO
-- SDL must
-- respond with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local module_data_radio = common.getReadOnlyParamsByModule("RADIO")

--[[ Local Functions ]]
local function setVehicleData(module_data)
  local cid = common.getMobileSession():SendRPC("SetInteriorVehicleData", {moduleData = module_data})

  EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "READ_ONLY" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test: SDL respond with READ_ONLY if SetInteriorVehicleData is sent with read_only params")
runner.Step("Send SetInteriorVehicleData with read only sisData", setVehicleData, {module_data_radio})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
