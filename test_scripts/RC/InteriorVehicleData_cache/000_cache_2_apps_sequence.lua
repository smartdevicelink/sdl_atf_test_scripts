---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- 1. App1 sends GetInteriorVD(module_1) without subscribe parameter
-- 2. App2 sends GetInteriorVD(module_1) without subscribe parameter
-- 3. App1 sends GetInteriorVD(module_1) with subscribe=true
-- 4. HMI sends OnInteriorVD(data for module_1)
-- 5. App1 sends GetInteriorVD(module_1) with subscribe=true
-- 6. App1 sends GetInteriorVD(module_1) without subscribe parameter
-- 7. App2 sends GetInteriorVD(module_1) with subscribe=true
-- 8. App2 sends GetInteriorVD(module_1) without subscribe parameter
-- 9. HMI sends OnInteriorVD(data for module_1)
-- 10. App1 sends GetInteriorVD(module_1) with subscribe=false
-- 11. App2 sends GetInteriorVD(module_1) with subscribe=false
-- SDL must
-- 1. send GetInteriorVD(module_1, without subscribe parameter, without appId) request to HMI by processing request from app1
-- 2. send GetInteriorVD(module_1, without subscribe parameter, without appId) request to HMI by processing request from app2
-- 3. send GetInteriorVD(module_1, subscribe=true, without appId) request to HMI by processing request from app1
-- 4. update data for module_1 in cache and send OnInteriorVD notification to mobile app1
-- 5. not send GetInteriorVD(module_1, subscribe=true, without appId) request to HMI by processing request from app1
-- 6. not send GetInteriorVD(module_1, without subscribe parameter, without appId) request to HMI by processing request from app1
-- 7. not send GetInteriorVD(module_1, subscribe=true, without appId) request to HMI by processing request from app2
-- 8. not send GetInteriorVD(module_1, without subscribe parameter, without appId) request to HMI by processing request from app2
-- 9. update data for module_1 in cache and send OnInteriorVD notification to mobile app1 and mobile app2
-- 10. not send GetInteriorVD(module_1, subscribe=false, without appId) request to HMI by processing request from app1
-- 11. send GetInteriorVD(module_1, subscribe=true, without appId) request to HMI by processing request from app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Function ]]
local function OnInteriorVDUpdatedData2Apps(pModuleType)
  local params = common.moduleDataUpdate(pModuleType)
  common.OnInteriorVD(pModuleType, true, 1, params)
  common.getMobileSession(2):ExpectNotification("OnInteriorVehicleData",{moduleData = params})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp, { 1 })
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")

for _, mod in pairs(common.modules) do
  -- Block 'Get' from diagram
  runner.Step("App1 GetInteriorVehicleData " .. mod, common.GetInteriorVehicleData, { mod, nil, true, 1 })
  runner.Step("App2 GetInteriorVehicleData " .. mod, common.GetInteriorVehicleData, { mod, nil, true, 2 })
  -- Block 'Subscribe app1' from diagram
  runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("App1 OnInteriorVehicleData for " .. mod, common.OnInteriorVD,
    { mod, true, 1 })
  runner.Step("App1 GetInteriorVehicleData with subscribe=true without request to HMI " .. mod, common.GetInteriorVehicleData,
    { mod, true, false, 1 })
  runner.Step("App1 GetInteriorVehicleData without request to HMI " .. mod, common.GetInteriorVehicleData,
    { mod, nil, false, 1 })
  -- Block 'Subscribe app2' from diagram
  runner.Step("App2 GetInteriorVehicleData with subscribe=true without request to HMI" .. mod, common.GetInteriorVehicleData,
    { mod, true, false, 2 })
  runner.Step("App2 GetInteriorVehicleData without request to HMI " .. mod, common.GetInteriorVehicleData,
    { mod, nil, false, 2 })
  runner.Step("App1 and App2 OnInteriorVehicleData for " .. mod, OnInteriorVDUpdatedData2Apps,
    { mod })
  -- Block 'Un-Subscribe' from diagram
  runner.Step("App1 GetInteriorVehicleData with subscribe=false without request to HMI " .. mod, common.GetInteriorVehicleData,
    { mod, false, false, 1 })
  runner.Step("App2 GetInteriorVehicleData with subscribe=false " .. mod, common.GetInteriorVehicleData,
    { mod, false, true, 2 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
