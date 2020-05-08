---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md
-- User story:
-- Use case:
-- Item
--
-- Description:
-- In case:
-- 1) RC app is subscribed to a few RC modules
-- 2) and then RC app is unsubscribed to one of the module
-- 3) and then SDL received OnInteriorVehicleData notification for another module
-- SDL must:
-- 1) Does not re-send OnInteriorVehicleData notification to the related app for unsubscribed module
-- 2) Re-send OnInteriorVehicleData notification to the related app for subscribed module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)
runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is subscribed", commonRC.isSubscribed, { "SEAT" })
runner.Step("Subscribe app to CLIMATE", commonRC.subscribeToModule, { "CLIMATE" })
runner.Step("Send notification OnInteriorVehicleData CLIMATE. App is subscribed", commonRC.isSubscribed, { "CLIMATE" })

runner.Title("Test")
runner.Step("Unsubscribe app from CLIMATE", commonRC.unSubscribeToModule, { "CLIMATE" })
runner.Step("Send notification OnInteriorVehicleData CLIMATE. App is unsubscribed", commonRC.isUnsubscribed, { "CLIMATE" })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is still subscribed", commonRC.isSubscribed, { "SEAT" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
