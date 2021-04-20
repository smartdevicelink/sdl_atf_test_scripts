---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1030
--
-- Description: 
-- [API] SDL sends OnAppInterfaceUnregistered(DRIVER_DISTRACTION_VIOLATION) to app 
-- when receives OnExitApplication(DRIVER_DISTRACTION_VIOLATION) from HMI
-- 
--
-- Preconditions: 
-- 1) SDL Core and HMI are started. App is registered
-- 2) App is None
--
-- Steps:
-- 1) From HMI: send BasicCommunication.OnExitApplication", 
-- {reason = "DRIVER_DISTRACTION_VIOLATION", AppId=ID of app in the precondition}
--
-- Expected result:
-- SDL doesn't send OnAppInterfaceUnregistered(reason = "DRIVER_DISTRACTION_VIOLATION") to mobile app
-- App is not registered
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendOnExitApplication()
	common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", 
		{reason = "DRIVER_DISTRACTION_VIOLATION", appID = 1 })
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", 
		{unexpectedDisconnect = false, appID = 1})
	:Times(0)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SDL recieves OnExitApplication from HMI", sendOnExitApplication)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
