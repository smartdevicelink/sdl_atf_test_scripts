---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3330
--
-- Description: SetInteriorVehicleData request is rejected for SEAT module
-- without the deprecated `id` parameter from an app with version that is less than the deprecated parameter version
--
--In case:
-- 1. REMOTE_CONTROL app with version 5.9 is registered
-- 2. App requests SetInteriorVehicleData(SEAT) without `id` parameter
-- SDL does:
--   a. rejects the SetInteriorVehicleData request with INVALID_DATA resultCode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/6_1/3330_common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 9

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetInteriorVehicleData", common.rpcDisallowed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
