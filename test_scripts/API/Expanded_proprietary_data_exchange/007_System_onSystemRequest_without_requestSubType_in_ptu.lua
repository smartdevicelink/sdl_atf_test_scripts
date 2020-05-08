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
-- 1. PTU is performed without requestSubType and with requestType
-- 2. SDL receives SystemRequest and onSystemRequest with requestSubType value
-- SDL does:
-- 1. send OnAppPermissionChanged without requestSubType and with requestType parameters to HMI during update
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
  requestSubType = "someValue",
  fileName = "action.png"
}

--[[ Local Functions ]]
local function ptuFuncRPC(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestType = { "PROPRIETARY", "OEM_SPECIFIC" }
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].RequestSubType = nil
end

local function policyUpdate()
  common.policyTableUpdate(ptuFuncRPC)
  common.getHMIConnection():ExpectNotification("SDL.OnAppPermissionChanged", {
    appID = common.getHMIAppId(),
    requestType = { "PROPRIETARY", "OEM_SPECIFIC" },
  })
  :ValidIf(function(_, data)
    if data.params.requestSubType then
      return false, "SDL.OnAppPermissionChanged notification contains unexpected parameter requestSubType"
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
runner.Step("PTU without requestSubType", policyUpdate)
runner.Step("SystemRequest with requestSubType", common.systemRequest,
  {params, usedFile})
runner.Step("onSystemRequest with requestSubType", common.onSystemRequest,
  {params})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
