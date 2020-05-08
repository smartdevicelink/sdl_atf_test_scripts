---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("climateEnableAvailable" = false) for CLIMATE module parameter from HMI
-- In case:
-- 1) Mobile app send SetInteriorVehicleData with parameter ("climateEnable" = false) to SDL
-- SDL must:
-- 1) rejects with "resultCode" = UNSUPPORTED_RESOURCE
-- 2) not send RC.SetInteriorVehicleData to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
commonRC.actualInteriorDataStateOnHMI.CLIMATE.climateControlData = {
  climateEnable = true
}

--[[ Local Variables ]]
local hmiValues = hmi_values.getDefaultHMITable()
hmiValues.RC.GetCapabilities.params.remoteControlCapability.climateControlCapabilities[1].climateEnableAvailable = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiValues })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE in case climateEnableAvailable false", commonRC.rpcDenied,
  { "CLIMATE", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
