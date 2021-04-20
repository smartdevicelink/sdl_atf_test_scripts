---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sends "SetInteriorVehicleData" request with SeatControlData having omitted "moduleId" parameter and
--  with deprecated "id" one to the SDL.
--  SDL should transfer this request to the HMI and add to it the value of "moduleId" which corresponds to the "id"
--  parameter and use these parameters in further communication with HMI and App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent SEAT module capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"
--    (moduleType = "SEAT", seatControlData = {id = "FRONT_PASSENGER"}) request to the SDL
--   Check:
--    SDL resends "RC.SetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData = {id = "FRONT_PASSENGER"}) request to the HMI
--     adding corresponding value of "moduleId" ("650765bb") to the request
--    HMI sends "RC.SetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData = {id = "FRONT_PASSENGER"}) response to the SDL
--    SDL resends "SetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData = {id = "FRONT_PASSENGER"}, resultCode = "SUCCESS")
--     response to the mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {SEAT = common.DEFAULT}
local requestModuleData = {
  moduleType = "SEAT",
  seatControlData = {
    id = "FRONT_PASSENGER",
    horizontalPosition = 44,
    verticalPosition = 44,
    frontVerticalPosition = 44,
    backVerticalPosition = 44,
    backTiltAngle = 44
  }
}
local defaultModuleId = common.getRcCapabilities().SEAT[2].moduleInfo.moduleId

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Positive test. Send request for SEAT module with id parameter but w/o moduleId",
  common.sendSuccessRpcNoModuleId, { "SEAT", defaultModuleId, 1, "SetInteriorVehicleData", requestModuleData })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
