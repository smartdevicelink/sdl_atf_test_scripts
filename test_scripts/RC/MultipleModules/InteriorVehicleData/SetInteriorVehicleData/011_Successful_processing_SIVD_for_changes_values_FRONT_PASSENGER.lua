---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that SDL correctly processed "SetInteriorVehicleData"( moduleType = "SEAT", id: "FRONT_PASSENGER")
--  requests using deprecated parameter 'id' instead of new one 'moduleId' and adding to the requests to HMI "moduleId"
--  parameter which corresponds to this 'id' parameter.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent SEAT module capabilities to the SDL( where the second SEAT module with 'id' = "FRONT_PASSENGER" has
--    moduleId = "650765bb")
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
-- 5) App successfully sends "SetInteriorVehicleData" RPC request with id:"FRONT_PASSENGER"
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "SEAT", seatControlData = {id = "FRONT_PASSENGER"})
--    request to the SDL('moduleId' is absent in the request)
--   Check:
--    SDL resends "RC.SetInteriorVehicleData" (moduleType = "SEAT", seatControlData = { moduleId = "650765bb"})
--     request to the HMI using the second SEAT module's "moduleId"
--    HMI sends "RC.SetInteriorVehicleData"(moduleType = "SEAT", moduleId = "650765bb", seatControlData) response
--     to the SDL
--    SDL resends "SetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", moduleData = seatControlData, resultCode = "SUCCESS")
--     response to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = { SEAT = common.DEFAULT }
local moduleId = common.getRcCapabilities().SEAT[2].moduleInfo.moduleId

local requestModuleData = {
  [1] = {
    moduleType = "SEAT",
    seatControlData = {
      id = "FRONT_PASSENGER",
      heatingEnabled = true,
      coolingEnabled = true
    }
  },
  [2] = {
    moduleType = "SEAT",
    seatControlData = {
      id = "FRONT_PASSENGER",
      heatingEnabled = false,
      coolingEnabled = false,
      horizontalPosition = 50
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Send request for SEAT module for FRONT_PASSENGER", common.sendSuccessRpcNoModuleId,
  { "SEAT", moduleId, 1, "SetInteriorVehicleData", requestModuleData[1]})

runner.Title("Test")
runner.Step("Send request for SEAT module with changes value for FRONT_PASSENGER", common.sendSuccessRpcNoModuleId,
  { "SEAT", moduleId, 1, "SetInteriorVehicleData", requestModuleData[2]})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
