---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) PTU is completed with <app1> permissions all_unknown_rpc_passthrough = true 
--
--  Steps:
--  1) HMI initiates PTU to deliver PT snapshot to mobile
--
--  Expected:
--  1) PT Snapshot contains <app1> permissions all_unknown_rpc_passthrough = true 
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID]["allow_unknown_rpc_passthrough"] = true
end

local function verifyAllowUnknownRPCPassthrough()
  local snp_tbl = common.GetPolicySnapshot()
  local app_id = common.getConfigAppParams(1).fullAppID
  local result = {}
  result.allow_unknown_rpc_passthrough = snp_tbl.policy_table.app_policies[app_id].allow_unknown_rpc_passthrough
  common.test_assert(result.allow_unknown_rpc_passthrough == true, "Incorrect result value")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Request PTU", common.Request_PTU)
runner.Step("Validate PTU", verifyAllowUnknownRPCPassthrough)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

