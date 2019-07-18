---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities("climateEnableAvailable" = true) for CLIMATE module parameter from HMI
-- In case:
-- 1) Mobile app sends SetInteriorVehicleData with parameter ("climateEnable" = false) to SDL
-- 2) HMI sends response RC.SetInteriorVehicleData ("climateEnable" = false)
-- SDL must:
-- 1) sends RC.SetInteriorVehicleData (CLIMATE ("climateEnable" = false)) to HMI
-- 2) send SetInteriorVehicleData  with ("resultCode" = SUCCESS) to Mobile
-- In case:
-- 1) Mobile app sends SetInteriorVehicleData  request parameter ("climateEnable" = true) to SDL
-- 2) HMI sends RC.SetInteriorVehicleData response ("climateEnable" = true)
-- SDL must:
-- 1) sends RC.SetInteriorVehicleData request (CLIMATE ("climateEnable" = true)) to HMI
-- 2) sends SetInteriorVehicleData response with ("resultCode" = SUCCESS) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "CLIMATE"
local paramValues = {
  false,
  true
}

--[[ Local Functions ]]
local function requestSuccessful(pValue)
  function commonRC.getModuleControlData()
    return commonRC.cloneTable(commonRC.actualInteriorDataStateOnHMI[mType])
  end
  commonRC.actualInteriorDataStateOnHMI[mType].climateControlData = {
    climateEnable = pValue
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
  runner.Step("SetInteriorVehicleData climateEnable " .. tostring(v), requestSuccessful, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
