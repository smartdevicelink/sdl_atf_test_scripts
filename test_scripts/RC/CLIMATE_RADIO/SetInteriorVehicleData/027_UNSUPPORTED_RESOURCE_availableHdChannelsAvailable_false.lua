---------------------------------------------------------------------------------------------------
-- Proposal:
--   https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities with ("availableHdChannelsAvailable" = false) for RADIO module from HMI
-- In case:
-- 1) Mobile app send SetInteriorVehicleData with parameter ("hdChannel" = 4) to SDL
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
commonRC.actualInteriorDataStateOnHMI.RADIO.radioControlData = {
  hdChannel = 4
}

--[[ Local Variables ]]
local hmiVal = hmi_values.getDefaultHMITable()
hmiVal.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].availableHdChannelsAvailable = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiVal })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

runner.Step("SetInteriorVehicleData UNSUPPORTED_RESOURCE when availableHdChannelsAvailable = false", commonRC.rpcDenied,
  {"RADIO", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
