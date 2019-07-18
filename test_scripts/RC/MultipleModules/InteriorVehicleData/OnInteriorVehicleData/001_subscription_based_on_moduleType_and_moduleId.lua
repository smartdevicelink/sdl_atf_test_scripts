---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check regularity of subscribe process by sending "GetInteriorVehicleData" request containing "moduleType" and
--  "moduleId" parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "SEAT", moduleId = "650765bb", subscribe =true) request to the SDL
--   Check:
--    SDL resends "RC.GetInteriorVehicleData"(moduleType = "SEAT", moduleId = "650765bb", subscribe = true) request
--     to the HMI
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData, isSubscribed = true) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData, resultCode = "SUCCESS") response to the App
-- 2) After some changes were made in "650765bb" module, HMI sends "RC.OnInteriorVehicleData"
--     (moduleType = "SEAT", moduleId = "650765bb", seatControlData) notification to the SDL
--   Check:
--    SDL resends OnInteriorVehicleData (moduleType = "SEAT", moduleId = "650765bb", seatControlData) notification
--     to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customSeatCapabilities = {
  {
    moduleName = "Seat of Driver",
    moduleInfo = {
      moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
      location = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    coolingEnabledAvailable = true,
    coolingLevelAvailable = true,
    horizontalPositionAvailable = true,
    verticalPositionAvailable = true,
  },
  {
    moduleName = "Seat of Front Passenger",
    moduleInfo = {
      moduleId = "650765bb-2f89-4d68-a665-6267c80e6c62",
      location = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      serviceArea = {
        col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
      },
      allowMultipleAccess = true
    },
    coolingEnabledAvailable = true,
    coolingLevelAvailable = true,
    horizontalPositionAvailable = true,
    verticalPositionAvailable = true,
    massageEnabledAvailable = true,
    massageModeAvailable = true,
    massageCushionFirmnessAvailable = true,
    memoryAvailable = true
  }
}
local rcCapabilities = { SEAT = customSeatCapabilities }
local seatDataToSet = {
  moduleType = "SEAT",
  seatControlData = {
    coolingEnabled = true,
    coolingLevel = 77,
    horizontalPosition = 77,
    verticalPosition = 44
  }
}
local moduleId = customSeatCapabilities[2].moduleInfo.moduleId

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
  runner.Step("Subscribe on SEAT module by sending moduleType and moduleId", common.subscribeToModule,
    { "SEAT", moduleId, 1 })
  runner.Step("Check receiving of notification after making changes in SEAT module", common.isSubscribed,
    { "SEAT", moduleId, 1, true, seatDataToSet })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
