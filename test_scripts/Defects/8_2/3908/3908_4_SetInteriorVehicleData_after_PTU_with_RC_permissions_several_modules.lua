---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/pull/3908
---------------------------------------------------------------------------------------------------
-- Description: SDL triggers PTU after changed RC permission for moduleType in case module was allocated before,
--  update with one module and several ones in moduleType for app specific section
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
--
-- Steps:
-- 1. PTU is performed with RC permissions and value in moduleType array
-- 2. Mobile app allocates allowed module via SetInteriorVehicleData RPC
-- 3. PTU is triggered by odometer value updating
-- SDL does:
--  - start PTU and send SDL.OnStatusUpdate("UPDATE_NEEDED")
-- 4. PTU is performed with RC permissions and added one more module type
-- 5. Mobile app allocates allowed module via SetInteriorVehicleData RPC
-- 6. PTU is triggered by odometer value updating
-- SDL does:
--  - start PTU and send SDL.OnStatusUpdate("UPDATE_NEEDED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3908/common")

--[[ Local Variables ]]
local moduleTypeUpdate1 = { "RADIO" }
local moduleTypeUpdate2 = { "RADIO", "CLIMATE" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)

common.Step("PTU RADIO", common.policyTableUpdate, { common.updFuncWrapper(moduleTypeUpdate1) })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)
common.Step("OnVehicleData odometer " .. common.odometer1, common.onVehicleDataPtuTrigger, { common.odometer1 })
common.Step("PTU RADIO CLIMATE", common.policyTableUpdate, { common.updFuncWrapper(moduleTypeUpdate2) })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)
common.Step("OnVehicleData odometer " .. common.odometer2, common.onVehicleDataPtuTrigger, { common.odometer2 })
common.Step("PTU RADIO", common.policyTableUpdate, { common.updFuncWrapper(moduleTypeUpdate1) })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
