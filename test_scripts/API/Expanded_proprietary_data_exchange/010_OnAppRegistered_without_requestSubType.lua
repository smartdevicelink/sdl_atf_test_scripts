---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0083-Expandable-design-for-proprietary-data-exchange.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case: PT is updated without requestSubType for application App2 and App2 starts regisration
-- SDL does: send empty array(value from default section) in requestSubType in OnAppRegistered during registration
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Expanded_proprietary_data_exchange/commonDataExchange')
local json = require('modules/json')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
	local appId = config.application2.registerAppInterfaceParams.fullAppID
  tbl.policy_table.app_policies[appId] = utils.cloneTable(tbl.policy_table.app_policies.default)
  tbl.policy_table.app_policies[appId].RequestSubType = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Policy table update", common.policyTableUpdate, {ptuFuncRPC})

runner.Title("Test")
runner.Step("Empty array in requestSubType in OnAppRegistered by app registration", common.registerAppWOPTU,
  { 2, json.EMPTY_ARRAY })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
