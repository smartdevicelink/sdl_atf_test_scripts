---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2810
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends required messages for a streaming stop during unexpected app unregistration
--
-- Steps:
-- 1. Core and HMI are started
-- 2. Mobile app is registered and activated
-- 3. Mobile app starts video service and streaming
-- 4. Connection is closed
-- SDL does:
-- 1. send Navigation.OnVideoDataStreaming(available=false) and Navigation.StopStream to HMI to stop streaming
-- 2. send BasicCommunication.OnAppUnregistered to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_0/common_3479_2810')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local serviceType = common.services.video

--[[ Local Functions ]]
local function appStartStreaming()
  common.run.wait(5000)
  common.startStreaming(serviceType)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App starts video streaming", appStartStreaming)
runner.Step("Unexpected disconnect", common.unexpectedDisconnect, { serviceType })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
