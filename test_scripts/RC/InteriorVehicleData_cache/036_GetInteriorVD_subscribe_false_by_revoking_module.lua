---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app is subscribed to module_1
-- 2. Mobile app2 is subscribed to module_1
-- 3. Module_1 is revoked during PTU
-- SDL must
-- 1. send GetInteriorVD(module_1, subscribe = false) request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { common.modules[2] }
end

local function ptu()
  local rpc = "GetInteriorVehicleData"
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), common.getHMIRequestParams(rpc, common.modules[1], 1, false))
  :Do(function(_, data)
	    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
	    common.getHMIResponseParams(rpc, common.modules[1], false))
    end)
  common.policyTableUpdate(ptuFuncRPC)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerApp, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })

runner.Title("Test")

runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, true, 1 })
runner.Step("Absence RC.GetInteriorVehicleData with subscribe=false by revoking module during PTU " .. common.modules[1],
	ptu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
