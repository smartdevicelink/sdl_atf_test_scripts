---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("availableHdChannelsAvailable" = true) for RADIO module parameter from HMI
-- In case:
-- 1) Mobile app sends SetInteriorVehicleData with parameter ("hdChannels" = 7) to SDL
-- SDL must:
-- 1) send RC.SetInteriorVehicleData request ("hdChannel" = 7) to HMI
-- 2) HMI send response RC.SetInteriorVehicleData ("hdChannel" = 7, success = true, resultCode = "SUCCESS")
-- 3) sends SetInteriorVehicleData response with ("hdChannel" = 7, success = true, resultCode = "SUCCESS") to Mobile
---------------------------------------------------------------------------------------------------

--[[ Requiredcontaining incorrect  Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local paramValues = {
  0,
  7
}

--[[ Local Functions ]]
local function requestSuccessful(pValue)
  function commonRC.getModuleControlData()
   return commonRC.cloneTable(commonRC.actualInteriorDataStateOnHMI[mType])
  end
  commonRC.actualInteriorDataStateOnHMI[mType].radioControlData = {
    hdChannel = pValue
  }
  commonRC.rpcAllowed(mType, 1, "SetInteriorVehicleData")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
for _, v in pairs(paramValues) do
  runner.Step("SetInteriorVehicleData hdChannel " .. tostring(v), requestSuccessful, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
