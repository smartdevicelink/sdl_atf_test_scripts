---------------------------------------------------------------------------------------------------
-- User story: 0125 Validate ATF Streaming Data
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0125-atf-videostreaming-full-support.md
-- Use case: Validate data transmitted by mobile can be received by an HMI from Core
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType
-- 2) and starts video streaming
-- SDL must:
-- 1) Start service successful
-- 2) Process streaming from mobile
-- HMI must:
-- 1) Receive valid data from SDL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase1/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"
local video = common.serviceType.VIDEO

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].AppHMIType = { appHMIType }
end

local function switchToPipeStreaming()
  common.setSDLIniParameter("VideoStreamConsumer", "pipe")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Switch to Pipe Streaming", switchToPipeStreaming)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Start video service", common.startService, { video })

runner.Title("Test")
runner.Step("Start video streaming", common.StartStreaming, { video, "files/SampleVideo_5mb.mp4" })
runner.Step("Listen video streaming", common.hmi.listenStreaming, { video, 100000, "files/SampleVideo_5mb.mp4" })

runner.Title("Postconditions")
runner.Step("Stop video streaming", common.StopStreaming, { video, "files/SampleVideo_5mb.mp4" })
runner.Step("Stop SDL", common.postconditions)
