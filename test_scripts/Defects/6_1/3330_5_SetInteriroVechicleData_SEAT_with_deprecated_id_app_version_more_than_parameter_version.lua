---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3330
--
-- Description: SetInteriorVehicleData request is successfully processed for SEAT module
-- with the deprecated `id` parameter from an app with version that is more than the deprecated parameter version
--
--In case:
-- 1. REMOTE_CONTROL app with version 6.0 is registered
-- 2. App requests SetInteriorVehicleData(SEAT) with `id` parameter
-- SDL does:
--   a. process the request successful
--   b. respond with SUCCESS resultCode to mobile app after successful response from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/6_1/3330_common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData", common.rpcAllowed, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
