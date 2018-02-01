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
-- 2) app is deactivated to limited HMI level
-- 3) and starts audio streaming
-- SDL must:
-- 1) Start service successful
-- 2) Process streaming from mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/PROJECTION/common')
local runner = require('user_modules/script_runner')
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.defaultProtocolVersion = 3

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
end

local function bringAppToLimited()
  test.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  test.mobileSession1:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Bring app to limited HMI level", bringAppToLimited)

runner.Title("Test")
runner.Step("Start audio service", common.startService, { 10 })
runner.Step("Start audio streaming", common.StartStreaming, { 10, "files/MP3_4555kb.mp3" })

runner.Title("Postconditions")
runner.Step("Stop audio streaming", common.StopStreaming, { 10, "files/MP3_4555kb.mp3" })
runner.Step("Stop SDL", common.postconditions)
