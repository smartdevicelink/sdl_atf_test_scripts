---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType
-- 2) set in NONE HMI level
-- 3) and starts audio/video service
-- SDL must:
-- 1) reject audio/video service in NONE HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/PROJECTION/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })

runner.Title("Test")
runner.Step("Reject video service in NONE", common.RejectingServiceStart, { 11 })
runner.Step("Reject audio service in NONE", common.RejectingServiceStart, { 10 })


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
