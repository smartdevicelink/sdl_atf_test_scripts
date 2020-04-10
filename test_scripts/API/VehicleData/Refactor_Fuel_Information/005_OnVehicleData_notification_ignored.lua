---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL does not send OnVehicleData notification to mobile app if the notification contains new parameters
-- with invalid values
-- In case:
-- 1) App is subscribed to `FuelRange` data
-- 2) HMI sends the OnVehicleData notification with invalid values of new FuelRange parameters
-- (type, range, level, levelState, capacity, capacityUnit)
-- SDL does:
-- 1) ignore this notification
-- 2) not send OnVehicleData notification to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Local Variables ]]
local expTime = 0
local boolValue = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD, { "SubscribeVehicleData", common.subUnsubParams})

common.Title("Test")
for k,_ in pairs(common.allVehicleData) do
  common.Step("HMI sends OnVehicleData with invalid " .. k .. "=" .. tostring(boolValue), common.sendOnVehicleData,
    { { { [k] = boolValue } }, expTime })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
