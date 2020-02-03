---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/3226
--
-- Description: SDL crashes when the HMI sends UI.OnTouchEvent with the 'ts' param has a value greater than maxvalue (not valid)
-- Steps to reproduce:
-- 1) Navi_app is registered and activated
-- 2) OnTouchEventOnlyGroup is allowed by policies
-- 2) HMI sends UI.OnTouchEvent with the 'ts' param has a value greater than maxvalue (not valid)
-- Expected:
-- 1) SDL does not transfer OnTouchEvent notification to the application being currently in FULL HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

local sendParams = {
  type = "BEGIN",
  event = { {c = {{x = 1, y = 1}}, id = 1, ts = {2147483648} } }
}

-- [[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].AppHMIType = { "NAVIGATION" }
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "OnTouchEventOnlyGroup" }
end

local function OnTouchEvent()
  common.getHMIConnection():SendNotification("UI.OnTouchEvent", sendParams)
  common.getMobileSession():ExpectNotification("OnTouchEvent", sendParams)
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("HMI sends UI.OnTouchEvent with the 'ts' param has a value greater than maxvalue", OnTouchEvent)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
