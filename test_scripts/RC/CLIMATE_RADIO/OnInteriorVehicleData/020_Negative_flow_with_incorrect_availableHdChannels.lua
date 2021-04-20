---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for RADIO module
--  with ("radioEnableAvailable" = true, "availableHdChannelsAvailable" = true) parameter from HMI
-- 2) Mobile app subscribed on getting RC.OnInteriorVehicleData notification for RADIO module
-- In case:
-- 1) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {0,1, 2, 3, 7, 8}) to SDL
-- 2) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {-1, 0, 1, 2, 3, 4}) to SDL
-- 3) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = "Z") to SDL
-- 4) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {0, 1, 2, 3, 4, 'a', 'b'}) to SDL
-- 4) HMI sends RC.OnInteriorVehicleData notification ("availableHdChannels" = {0, 0, 0, 0, 0, 0, 0, 0, 0}) to SDL
-- SDL must:
-- 1) does not send OnInteriorVehicleData notification to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local params = {
  outOfBoundaryValue = { 0, 1, 2, 3, 7, 8 },
  negativeValue = { -1, 0, 1, 2, 3, 4 },
  notArray = "Z",
  stringValue = { 0, 1, 2, 3, 4, 'a', 'b' },
  outOfBoundaryArray = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
}

--[[ Local Functions ]]
local function notificationIgnored(pValue)
  function commonRC.getAnotherModuleControlData()
    return commonRC.actualInteriorDataStateOnHMI[mType]
  end
  commonRC.actualInteriorDataStateOnHMI[mType].radioControlData = {
    availableHdChannels = pValue
  }
  commonRC.isUnsubscribed(mType)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to module RADIO", commonRC.subscribeToModule, { mType })

runner.Title("Test")
for k, v in pairs(params) do
  runner.Step("OnInteriorVehicleData incorrect availableHdChannels " ..k, notificationIgnored, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
