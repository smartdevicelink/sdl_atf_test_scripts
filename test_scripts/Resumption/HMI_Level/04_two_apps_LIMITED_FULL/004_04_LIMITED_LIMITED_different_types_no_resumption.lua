---------------------------------------------------------------------------------------------------
-- Description:
-- Check absence of HMI level resumption in case if:
--  - app has LIMITED level before unexpected disconnect
--  - another app of different HMI type is registered and switched to LIMITED just after unexpected disconnect
--  - app has been re-registered
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App_1 is registered and switched to LIMITED HMI level
--
-- Steps:
-- 1) App_1 is disconnected unexpectedly
-- 2) App_2 of different HMI type is registered and switched to LIMITED HMI level
-- 2) App_1 is re-registered and got NONE HMI level
-- 3) Timeout expires and SDL starts HMI level resumption process for App_1
-- SDL does not resume app's HMI level
-- 4) App_1 is switched to FULL
-- SDL does change app's HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Resumption/HMI_Level/common")

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App 1", common.registerApp, { "NAVIGATION", 1 })
common.Step("Set HMI level App 1", common.setAppHMILevel, { "LIMITED", 1 })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Register App 2", common.registerApp, { "MEDIA", 2 })
common.Step("Set HMI level App 2", common.setAppHMILevel, { "LIMITED", 2 })
common.Step("Register App 1", common.registerApp, { "NAVIGATION", 1 })
common.Step("Check HMI level resumption App 1", common.checkHMILevelResumption, { nil })
common.Step("Activate App 1", common.activateApp, { "FULL" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
