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
-- 1. PT is updated with list of values without OEM_SPECIFIC in requestType for app
-- 2. Mobile app sends SystemRequest and HMI sends onSystemRequest to SDL with requestType = OEM_SPECIFIC
-- SDL does: respond DISALLOWED to SystemRequest and does not send onSystemRequest to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Expanded_proprietary_data_exchange/commonDataExchange')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/action.png"
local params = {
  requestType = "OEM_SPECIFIC",
  fileName = "action.png"
}
--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestType = { "HTTP", "PROPRIETARY" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Policy table update", common.policyTableUpdate, {ptuFuncRPC})

runner.Title("Test")
runner.Step("SystemRequest with request type OEM_SPECIFIC", common.unsuccessSystemRequest,
  {params, usedFile})
runner.Step("onSystemRequest with request type OEM_SPECIFIC", common.unsuccessOnSystemRequest,
  {params})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
