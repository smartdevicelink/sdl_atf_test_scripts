---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 012
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local mod1 = "CLIMATE"
local mod2 = "RADIO"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

runner.Step("Subscribe app to " .. mod1, commonRC.subscribeToModule, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod1 .. ". App is subscribed", commonRC.isSubscribed, { mod1 })

runner.Step("Send notification OnInteriorVehicleData " .. mod2 .. ". App is not subscribed", commonRC.isUnsubscribed, { mod2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
