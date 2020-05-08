---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for CLIMATE module with "climateEnableAvailable" = true parameter from HMI
-- 2) Mobile app subscribed on getting RC.OnInteriorVehicleData notification for CLIMATE module
-- In case:
-- 1) HMI sends RC.OnInteriorVehicleData notification ("climateEnable" = 1) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("climateEnable" = "false") to SDL
-- 3) HMI sends RC.OnInteriorVehicleData notification ("climateEnable" = "") to SDL
-- SDL must:
-- 1) does not send OnInteriorVehicleData notification to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "CLIMATE"
local paramValues = {
  invalidTypeNumber = 1,
  invalidTypeString = "false",
  emptyValue = ""
}

--[[ Local Functions ]]
local function notificationIgnored(pValue)
  function commonRC.getAnotherModuleControlData()
    return commonRC.actualInteriorDataStateOnHMI[mType]
  end
  commonRC.actualInteriorDataStateOnHMI[mType].climateControlData = {
    climateEnable = pValue
  }
  commonRC.isUnsubscribed(mType)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to module CLIMATE", commonRC.subscribeToModule, { mType })

runner.Title("Test")
for k, v in pairs(paramValues) do
  runner.Step("OnInteriorVehicleData climateEnable " .. k, notificationIgnored, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
