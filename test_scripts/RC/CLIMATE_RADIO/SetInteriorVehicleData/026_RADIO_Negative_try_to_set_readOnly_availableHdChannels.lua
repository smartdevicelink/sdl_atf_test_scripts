---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("availableHdChannelsAvailable" = true) for RADIO module parameter from HMI
-- In case:
-- 1) Mobile app sends SetInteriorVehicleData with parameter (availableHdChannels = { 1, 2, 3 }) to SDL
-- SDL must:
-- 1) send SetInteriorVehicleData response with "resultCode: READ_ONLY, success:false" to Mobile
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hmiVal = hmi_values.getDefaultHMITable()
hmiVal.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].availableHdChannelsAvailable = true

--[[ Local Functions ]]
function commonRC.getSettableModuleControlData()
  return  { moduleType = "RADIO",
    radioControlData = { availableHdChannels = { 1, 2, 3 }}
  }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiVal })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData availableHdChannel", commonRC.rpcDenied,
  { "RADIO", 1, "SetInteriorVehicleData", "READ_ONLY" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
