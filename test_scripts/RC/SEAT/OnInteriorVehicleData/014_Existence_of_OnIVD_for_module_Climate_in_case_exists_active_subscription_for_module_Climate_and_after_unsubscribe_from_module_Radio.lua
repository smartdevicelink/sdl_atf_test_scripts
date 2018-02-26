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
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO", "SEAT" }
local mod1 = "SEAT"        
local mod2 = "CLIMATE"
local mod3 = "RADIO"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is subscribed", commonRC.isSubscribed, { "SEAT" })

runner.Title("Test")

runner.Step("Unsubscribe app to SEAT", commonRC.unSubscribeToModule, { "SEAT" })
runner.Step("Send notification OnInteriorVehicleData SEAT. App is unsubscribed", commonRC.isUnsubscribed, { "SEAT" })
runner.Step("Send notification OnInteriorVehicleData CLIMATE. App is still subscribed", commonRC.isSubscribed, { "CLIMATE" })
runner.Step("Send notification OnInteriorVehicleData RADIO. App is still subscribed", commonRC.isSubscribed, { "RADIO" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)