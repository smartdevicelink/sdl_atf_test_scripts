---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. default_hmi for app is BACKGROUND
-- 2. App is registered and sets in BACKGROUND hmiLevel
-- 3. 10 seconds timer is expired
-- SDL does:
-- not send SetGlobalProperties  to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ptuFunc(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = common.cloneTable(tbl.policy_table.app_policies.default)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID].default_hmi = "BACKGROUND"
end

local function registerAppWOPTU()
	local mobSession = common.getMobileSession(2)
  mobSession:StartService(7)
  :Do(function()
    local corId = mobSession:SendRPC("RegisterAppInterface", common.getConfigAppParams(2))
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.getConfigAppParams(2).appName } })
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      mobSession:ExpectNotification("OnHMIStatus",
        { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerApp)
runner.Step("PTU with BACKGROUND default_hmi for App2", common.policyTableUpdate, { ptuFunc })

runner.Title("Test")
runner.Step("App2 registration", registerAppWOPTU)
runner.Step("Absence of SetGlobalProperties request from SDL", common.setGlobalPropertiesDoesNotExpect)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
