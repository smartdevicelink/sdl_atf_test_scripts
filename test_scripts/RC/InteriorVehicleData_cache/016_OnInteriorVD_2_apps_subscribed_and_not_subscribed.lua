---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app1 is subscribed to module_1
-- 2. Mobile app2 is not subscribed to modules
-- 3. HMI sends OnInteriorVD with params changing for module_1
-- SDL must
-- 1. send OnInteriorVD to mobile app1
-- 2. not send OnInteriorVD to mobile app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Funstions ]]
local function OnInteriorVDUpdatedData2Apps(pModuleType)
  local params = common.cloneTable(common.actualInteriorDataStateOnHMI[pModuleType])
  for key, value in pairs(params) do
    if type(value) == "boolean" then
      if value == true then
        params[key] = false
      else
        params[key] = true
      end
    end
  end
  common.OnInteriorVD(pModuleType, true, 1, params)
  common.getMobileSession(2):ExpectNotification("OnInteriorVehicleData")
  :Times(0)
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
  runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("App1 OnInteriorVehicleData for " .. mod, OnInteriorVDUpdatedData2Apps, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
