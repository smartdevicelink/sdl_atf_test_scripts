---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("availableHdChannelsAvailable" = true) for RADIO module parameter from HMI
-- In case:
-- 1) Mobile app sends SetInteriorVehicleData with parameter ("hdChannels" = 8) to SDL
-- 1) Mobile app sends SetInteriorVehicleData with parameter ("hdChannels" = -1) to SDL
-- 1) Mobile app sends SetInteriorVehicleData with parameter ("hdChannels" = "0") to SDL
-- SDL must:
-- 1) send RC.SetInteriorVehicleData response (RADIO (success = false, resultCode = "INVALID_DATA")) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local paramValues = {
  outOfBoundaryValue = 8,
  negativeNumber = -1,
  stringValue = "0"
}

--[[ Local Functions ]]
local function requestFailed(pValue)
  function commonRC.getModuleControlData()
    return commonRC.actualInteriorDataStateOnHMI[mType]
  end
  commonRC.actualInteriorDataStateOnHMI[mType].radioControlData = {
    hdChannel = pValue
  }
  commonRC.rpcDenied(mType, 1, "SetInteriorVehicleData", "INVALID_DATA")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
for k, v in pairs(paramValues) do
  runner.Step("SetInteriorVehicleData set incorrect values for hdChannel as " .. k, requestFailed, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
