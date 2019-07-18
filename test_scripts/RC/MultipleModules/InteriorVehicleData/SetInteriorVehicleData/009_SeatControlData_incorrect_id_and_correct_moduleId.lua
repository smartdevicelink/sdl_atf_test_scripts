---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sends "SetInteriorVehicleData" request with SeatControlData having incorrect value of "id" parameter and
--  correct "moduleId" one to the SDL.
--  SDL should decline this request answering with (resultCode = "INVALID_DATA") to the mobile App
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent SEAT module capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "SEAT", moduleId = "a42bf1e0", seatControlData ={"INVALID_VALUE"})
--     request to the SDL
--   Check:
--    SDL does NOT resend "RC.SetInteriorVehicleData" request to the HMI
--    SDL responds with "SetInteriorVehicleData"(success = false, resultCode = "INVALID_DATA") to the App
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
  moduleId = common.getRcCapabilities().SEAT[1].moduleInfo.moduleId,
  seatControlData = {
    id = "INVALID_VALUE",                                               -- incorrect value of "id" parameter
    horizontalPosition = 44,
    verticalPosition = 44,
    frontVerticalPosition = 44,
    backVerticalPosition = 44,
    backTiltAngle = 44
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send request for SEAT module with invalid id value in seatControlData", common.rpcReject,
  { "SEAT", requestModuleData.moduleId, 1, "SetInteriorVehicleData", requestModuleData, "INVALID_DATA"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
