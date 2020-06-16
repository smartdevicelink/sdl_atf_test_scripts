---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: OnVehicleData notification with StabilityControlsStatus parameter only,
-- invalid data from HMI related to this parameter
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with invalid data from HMI related to StabilityControlsStatus
--    parameter
--     - escSystem invalid value
--     - trailerSwayControl invalid value
--     - stabilityControlsStatus is not structure
--    SDL doesn't send OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local hmiResParams = {
  escSystemInvalidValue = {
    stabilityControlsStatus = {
      escSystem = 3,
      trailerSwayControl = "OFF"
    }
  },
  trailerSwayControlInvalidValue = {
    stabilityControlsStatus = {
      escSystem = "ON",
      trailerSwayControl = 3
    }
  },
  stabilityControlsStatusIsNotStructure = {
    stabilityControlsStatus = "ON"
  }
}

local function checkNotificationIgnored(pHMIParams)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", pHMIParams)
  common.getMobileSession():ExpectNotification("OnVehicleData")
  :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus" }})

common.Title("Test")
for k,v in pairs(hmiResParams) do
  common.Step("Ignore OnVehicleData with " .. k .. " from HMI", checkNotificationIgnored, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
