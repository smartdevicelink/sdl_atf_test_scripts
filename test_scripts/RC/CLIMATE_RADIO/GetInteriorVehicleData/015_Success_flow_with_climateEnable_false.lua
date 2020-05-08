---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("climateEnableAvailable" = true) for CLIMATE module parameter from HMI
-- In case:
-- 1) Mobile app sends GetInteriorVehicleData (CLIMATE) to SDL
-- 2) HMI sends response RC.GetInteriorVehicleData ("climateEnable" = false) to SDL
-- SDL must:
-- 1) send RC.GetInteriorVehicleData (CLIMATE) to HMI
-- 2) send GetInteriorVehicleData  with ("climateEnable" = false) parameter to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
commonRC.actualInteriorDataStateOnHMI.CLIMATE.climateControlData = {
  climateEnable = false
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData CLIMATE with climateEnable:false",
  commonRC.rpcAllowed, {"CLIMATE", 1, "GetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
