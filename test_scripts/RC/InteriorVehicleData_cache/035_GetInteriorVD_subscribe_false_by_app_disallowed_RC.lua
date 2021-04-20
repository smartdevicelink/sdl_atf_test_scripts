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
-- 2. Mobile app2 is subscribed to module_1
-- 3. RC functionality is disabled on HMI
-- SDL must
-- 1. send GetInteriorVD(module_1, subscribe = false) request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function dissalowRCFunctionality()
  local rpc = "GetInteriorVehicleData"
  EXPECT_HMICALL(common.getHMIEventName(rpc))
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      common.getHMIResponseParams(rpc, common.modules[1], false))
    end)
  :ValidIf(function(_, data)
      local ExpectedResult = common.getHMIRequestParams(rpc, common.modules[1], 1, false)
      if false == common.isTableEqual(data.params, ExpectedResult) then
        return false, "Parameters in RC.GetInteriorVehicleData are not match to expected result.\n" ..
          "Actual result:" .. common.tableToString(data.params) .. "\n" ..
          "Expected result:" ..common.tableToString(ExpectedResult) .."\n"
      end
      return true
    end)
  common.defineRAMode(false, nil)
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

runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, true, 1 })
runner.Step("App2 GetInteriorVehicleData with subscribe=true " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, false, 2 })
runner.Step("RC.GetInteriorVehicleData with subscribe=false by disabling RC functionality " .. common.modules[1],
	dissalowRCFunctionality)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
