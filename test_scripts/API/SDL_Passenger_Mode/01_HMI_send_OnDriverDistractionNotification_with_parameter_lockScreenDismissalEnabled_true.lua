----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md

-- User story: TBD
-- Use case: TBD

-- Requirement summary: TBD

-- Description:
-- In case:

-- 1) The vehicle is in motion (screen is locked)
-- 2) Recieved "OnDriverDistraction" notification with param lockScreenDismissalEnabled = true
-- 3) User trying to unlock the screen by swipe (notification recieved)
-- SDL does:

-- 1) Show OEM's "Driver distraction" warning message 
-- 2) Allow user to unlock the screen by swipe again
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- HMI sends "lockScreenDismissalEnabled" item (boolean) as a parameter of OnDriverDistraction notification
-- SDL does: Sends  OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled" parameter
local function FromHMIToMobileWithScreenDismissalEnabled()
    common.getHMIConnection():SendNotification("UI.OnDriverDistraction", 
        {state = "DD_ON", lockScreenDismissalEnabled = true })
    common.getMobileSession():ExpectNotification("OnDriverDistraction",
        {state = "DD_ON", lockScreenDismissalEnabled = true})
end

-- HMI not sends "lockScreenDismissalEnabled" item as a parameter of OnDriverDistraction notification
-- SDL does: Sends  OnDriverDistraction notification to mobile without "lockScreenDismissalEnabled" parameter
local function FromHMIToMobileWithOutScreenDismissalEnabled()
    common.getHMIConnection():SendNotification("UI.OnDriverDistraction", 
        {state = "DD_ON"})
    common.getMobileSession():ExpectNotification("OnDriverDistraction",
        {state = "DD_ON"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("HMI sends to Mobile OnDriverDistraction notification with lockScreenDismissalEnabled",
    FromHMIToMobileWithScreenDismissalEnabled)

runner.Step("HMI sends to Mobile OnDriverDistraction notification without lockScreenDismissalEnabled",
    FromHMIToMobileWithOutScreenDismissalEnabled)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)