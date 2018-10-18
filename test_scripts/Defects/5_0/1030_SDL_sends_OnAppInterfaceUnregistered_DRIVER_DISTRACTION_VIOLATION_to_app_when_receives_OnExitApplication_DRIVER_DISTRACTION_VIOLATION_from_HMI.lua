---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1030
-- Description:
-- Precondition:
-- SDL Core and HMI are started. App is registered
-- App is None
-- In case:
-- 1) From HMI: send BasicCommunication.OnExitApplication", {reason = "DRIVER_DISTRACTION_VIOLATION", AppId=ID of app in the precondition}
-- Note: You can use attached lua file to reproduce this defect automatically.
-- Expected result:
-- 1) SDL doesn't send OnAppInterfaceUnregistered(reason = "DRIVER_DISTRACTION_VIOLATION") to mobile app
--  App is not registered
-- Actual result:
-- 1) SDL sends OnAppInterfaceUnregistered(reason = "DRIVER_DISTRACTION_VIOLATION") to mobile app
-- App is not registered
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function driverDistractionViolation()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    { appID = common.getHMIAppId(), reason = "DRIVER_DISTRACTION_VIOLATION" })

    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered",
    { reason = "DRIVER_DISTRACTION_VIOLATION" })
    :Times(0)

    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {})
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("SDL doesn't send OnAppInterfaceUnregistered", driverDistractionViolation)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
