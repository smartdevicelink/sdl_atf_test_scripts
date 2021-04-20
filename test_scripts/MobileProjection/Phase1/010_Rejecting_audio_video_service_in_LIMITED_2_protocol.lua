---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType via 2 protocol
-- 4) set in LIMITED HMI level
-- 5) and starts audio/video service
-- SDL must:
-- 1) reject audio/video service via 2 protocol in LIMITED HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase1/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.defaultProtocolVersion = 2

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].AppHMIType = { appHMIType }
end

local function bringAppToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Bring app to LIMITED", bringAppToLimited)

runner.Title("Test")
runner.Step("Reject video service in LIMITED via 2 protocol", common.RejectingServiceStart, { 11 })
runner.Step("Reject audio service in LIMITED via 2 protocol", common.RejectingServiceStart, { 10 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
