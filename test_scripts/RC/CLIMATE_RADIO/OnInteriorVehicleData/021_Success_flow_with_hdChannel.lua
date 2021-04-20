---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for RADIO module
--  with ("radioEnableAvailable" = true, "availableHdChannelsAvailable" = true) parameter from HMI
-- 2) Mobile app subscribed on getting RC.OnInteriorVehicleData notification for RADIO module
-- In case:
-- 1) HMI sends RC.OnInteriorVehicleData notification ("hdChannel" = 0) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("hdChannel" = 7) to SDL
-- SDL must:
-- 1) sends OnInteriorVehicleData notification ("hdChannel" = 0) to Mobile
-- 1) sends OnInteriorVehicleData notification ("hdChannel" = 7) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local paramValues = { 0, 7 }

--[[ Local Functions ]]
local function notificationProcessedSuccessfully(pValue)
  function commonRC.getAnotherModuleControlData()
    return commonRC.actualInteriorDataStateOnHMI[mType]
  end
  commonRC.actualInteriorDataStateOnHMI[mType].radioControlData = {
    hdChannel = pValue
  }
  commonRC.isSubscribed(mType)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to module RADIO", commonRC.subscribeToModule, { mType })

runner.Title("Test")
for _, v in pairs(paramValues) do
  runner.Step("OnInteriorVehicleData hdChannel " .. tostring(v), notificationProcessedSuccessfully, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
