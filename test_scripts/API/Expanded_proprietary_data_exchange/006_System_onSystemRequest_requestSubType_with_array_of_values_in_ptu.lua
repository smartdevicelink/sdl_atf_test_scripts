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
-- 1. PTU is performed with list of values in requestSubType
-- 2. SDL receives SystemRequest and onSystemRequest with requestSubType with value from list in pt
-- 3. SDL receives SystemRequest and onSystemRequest with requestSubType with value not from list in pt
-- SDL does:
-- 1. send OnAppPermissionChanged with list of values in requestSubType parameter to HMI during update
-- 2. successful process SystemRequest RPC and resend onSystemRequest to mobile application
-- 3. respond disallowed to SystemRequest and not resend onSystemRequest
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
  requestSubType = "TYPE1",
  fileName = "action.png"
}
local unsuccessParams = {
  requestType = "OEM_SPECIFIC",
  requestSubType = "TYPE4",
  fileName = "action.png"
}
local requestSubTypeArray = { "TYPE1", "TYPE2", "TYPE3" }

--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestSubType = requestSubTypeArray
end

local function policyUpdate()
  common.policyTableUpdate(ptuFuncRPC)
  common.getHMIConnection():ExpectNotification("SDL.OnAppPermissionChanged", {
    appID = common.getHMIAppId(),
    requestSubType = requestSubTypeArray
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("PTU with list of requestSubType", policyUpdate)
runner.Step("SystemRequest with not allowed requestSubType", common.unsuccessSystemRequest,
  {unsuccessParams, usedFile})
runner.Step("SystemRequest with allowed requestSubType", common.systemRequest,
  {params, usedFile})
runner.Step("onSystemRequest with not allowed requestSubType", common.unsuccessOnSystemRequest,
  {unsuccessParams})
runner.Step("onSystemRequest with allowed requestSubType", common.onSystemRequest,
  {params})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
