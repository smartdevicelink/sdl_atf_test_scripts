---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/pull/3908
---------------------------------------------------------------------------------------------------
-- Description: SDL triggers PTU after changed RC permission for moduleType in case module was allocated before,
--  same update for all PTU in default section
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
-- 4. PTU is performed with the same update as in step 1
-- 5. Mobile app allocates allowed module via SetInteriorVehicleData RPC
-- 6. PTU is triggered by odometer value updating
-- SDL does:
--  - start PTU and send SDL.OnStatusUpdate("UPDATE_NEEDED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3908/common")

--[[ Local Functions ]]
local function updFunc(pTbl)
  local appPolicies = pTbl.policy_table.app_policies
  local index = common.getParams().fullAppID
  appPolicies.default.groups = { "Base-4", "RemoteControl" }
  appPolicies.default.moduleType = { "RADIO" }
  appPolicies[index] = nil
  pTbl.policy_table.module_config.exchange_after_x_kilometers = 10
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)

common.Step("PTU", common.policyTableUpdate, { updFunc })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)
common.Step("OnVehicleData odometer " .. common.odometer1, common.onVehicleDataPtuTrigger, { common.odometer1 })
common.Step("PTU", common.policyTableUpdate, { updFunc })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)
common.Step("OnVehicleData odometer " .. common.odometer2, common.onVehicleDataPtuTrigger, { common.odometer2 })
common.Step("PTU", common.policyTableUpdate, { updFunc })
common.Step("SetInteriorVehicleData", common.setInteriorVehicleDataRadio)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
