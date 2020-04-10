---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL successfully processes GetVehicleData with all parameters of structure `FuelRange`
-- In case:
-- 1) App sends GetVehicleData(fuelRange:true) request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends all params of structure `FuelRange`
--    (type, range, level, levelState, capacity, capacityUnit)
-- SDL does:
-- 1) send GetVehicleData response to mobile with all parameters in `FuelRange` structure
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends GetVehicleData for fuelRange", common.getVehicleData, { { common.allVehicleData } })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
