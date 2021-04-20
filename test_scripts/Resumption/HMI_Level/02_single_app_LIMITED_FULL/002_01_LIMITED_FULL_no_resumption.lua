---------------------------------------------------------------------------------------------------
-- Description:
-- Check absence of HMI level resumption in case if:
--  - app has LIMITED level before unexpected disconnect
--  - app has been registered and switched to FULL just after unexpected disconnect
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered and switched to LIMITED HMI level
--
-- Steps:
-- 1) App is disconnected unexpectedly and re-registered again
-- 2) App switched to FULL within default 3 sec. timeout
-- 3) Timeout expires and SDL starts HMI level resumption process
-- SDL does not resume app's HMI level
-- 4) App switched to FULL
-- SDL does not change app's HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Resumption/HMI_Level/common")

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App 1", common.registerApp, { "NAVIGATION" })
common.Step("Set HMI level App 1", common.setAppHMILevel, { "LIMITED" })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Register App 1", common.registerApp, { "NAVIGATION" })
common.Step("Set HMI level App 1", common.setAppHMILevel, { "FULL" })
common.Step("Check HMI level resumption App 1", common.checkHMILevelResumption, { nil })
common.Step("Activate App 1", common.activateApp, { nil })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
