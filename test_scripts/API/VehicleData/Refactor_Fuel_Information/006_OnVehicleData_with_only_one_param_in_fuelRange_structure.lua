---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL successfully processes OnVehicleData notification and transfers it to a mobile app in case HMI
-- sends only one new param in FuelRange structure
-- In case:
-- 1) App is subscribed to `FuelRange` data
-- 2) HMI sends valid OnVehicleData notification with only one new param of `FuelRange` structure
-- SDL does:
-- 1) process this notification and transfer it to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Local Functions ]]
local function sendOnVehicleData(pData)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { fuelRange = pData })
  common.getMobileSession():ExpectNotification("OnVehicleData", { fuelRange = pData }):Times(1)
  :ValidIf(function(_, data)
    return common.checkParam(data, "OnVehicleData")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD, { "SubscribeVehicleData", common.subUnsubParams })

common.Title("Test")
for k,v in pairs(common.allVehicleData) do
  common.Step("HMI sends OnVehicleData with one param " .. k, sendOnVehicleData, { { { [k] = v } } })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
