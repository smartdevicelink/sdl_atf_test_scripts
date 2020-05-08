---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0083-Expandable-design-for-proprietary-data-exchange.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1. PT is updated with list of values for requestSubType for application App2 and App2 starts regisration
-- SDL does:
-- 1. send list of requestSubType values from PT in OnAppRegistered during registration
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Expanded_proprietary_data_exchange/commonDataExchange')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestSubTypeArray = { "TYPE1", "TYPE2", "TYPE3" }

--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = tbl.policy_table.app_policies.default
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID].RequestSubType = requestSubTypeArray
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Policy table update", common.policyTableUpdate, {ptuFuncRPC})

runner.Title("Test")
runner.Step("List of requestSubType in OnAppRegistered by app registration", common.registerAppWOPTU,
  { 2, requestSubTypeArray })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
