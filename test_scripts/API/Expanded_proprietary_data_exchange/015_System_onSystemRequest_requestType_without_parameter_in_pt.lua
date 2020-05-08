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
-- 1. PTU is performed without requestType
-- 2. SDL receives SystemRequest and onSystemRequest with requestType value
-- SDL does:
-- 1. send OnAppPermissionChanged wihout requestType to HMI during update
-- 2. process SystemRequest request successful and resend onSystemRequest to mobile application
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

local paramsProprietary = {
  requestType = "PROPRIETARY",
  fileName = "action.png"
}
--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
	tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestType = nil
	tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestSubType = { "TYPE1" }
end

local function policyUpdate()
  common.policyTableUpdate(ptuFuncRPC)
  common.getHMIConnection():ExpectNotification("SDL.OnAppPermissionChanged", {
    appID = common.getHMIAppId(),
  })
  :ValidIf(function(_, data)
    if data.params.requestType then
      return false, "SDL.OnAppPermissionChanged notification contains unexpected parameter requestType"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Policy table update", policyUpdate)
runner.Step("SystemRequest with request type OEM_SPECIFIC", common.systemRequest,
  {params, usedFile})
runner.Step("SystemRequest with request type PROPRIETARY", common.systemRequest,
  {paramsProprietary, usedFile})
runner.Step("onSystemRequest with request type OEM_SPECIFIC", common.onSystemRequest,
  {params})
runner.Step("onSystemRequest with request type PROPRIETARY", common.onSystemRequest,
  {paramsProprietary})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
