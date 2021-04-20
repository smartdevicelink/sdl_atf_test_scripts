---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for RADIO module
--  with ("radioEnableAvailable" = true, "availableHdChannelsAvailable" = true) parameter from HMI
-- 2) Mobile app subscribed on getting RC.OnInteriorVehicleData notification for RADIO module
-- In case:
-- 1) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {0,1, 2, 3, 4, 5, 6, 7}) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {3}) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {2,3,5,7}) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {}) to SDL - an empty array
-- SDL must:
-- 1) sends OnInteriorVehicleData notification ("availableHdChannels" = {0,1, 2, 3, 4, 5, 6, 7}) to Mobile
-- 2) sends OnInteriorVehicleData notification ("availableHdChannels" = {3}) to Mobile
-- 2) sends OnInteriorVehicleData notification ("availableHdChannels" = {2,3,5,7}) to Mobile
-- 2) sends OnInteriorVehicleData notification ("availableHdChannels" = {}) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local json = require('json')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local paramValues = {
  fullArray = { 0, 1, 2, 3, 4, 5, 6, 7 },
  singleValue = { 3 },
  fewItems = { 2, 3, 5, 7 },
  emptyArray = json.EMPTY_ARRAY
}

--[[ Local Functions ]]
local function notificationProcessedSuccessfully(pValue)
  function commonRC.getAnotherModuleControlData()
    return commonRC.actualInteriorDataStateOnHMI[mType]
  end
  commonRC.actualInteriorDataStateOnHMI[mType].radioControlData = {
    availableHdChannels = pValue
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
for k, v in pairs(paramValues) do
  runner.Step("OnInteriorVehicleData availableHdChannels " .. tostring(k), notificationProcessedSuccessfully, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
