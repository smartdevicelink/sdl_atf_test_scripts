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
-- 3) and starts video streaming
-- SDL must:
-- 1) Start service successful
-- 2) Process streaming from mobile
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
config.application1.registerAppInterfaceParams.isMediaApplication = true

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
runner.Step("Bring app to limited HMI level", bringAppToLimited)

runner.Title("Test")
runner.Step("Start video service", common.startService, { 11 })
runner.Step("Start video streaming", common.StartStreaming, { 11, "files/SampleVideo_5mb.mp4" })
runner.Step("Listen video streaming", common.ListenStreaming, { 11, 500000, "files/SampleVideo_5mb.mp4" })

runner.Title("Postconditions")
runner.Step("Stop video streaming", common.StopStreaming, { 11, "files/SampleVideo_5mb.mp4" })
runner.Step("Stop SDL", common.postconditions)
