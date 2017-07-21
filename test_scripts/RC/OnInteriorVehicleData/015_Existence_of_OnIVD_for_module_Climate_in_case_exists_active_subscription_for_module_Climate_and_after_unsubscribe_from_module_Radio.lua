---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local mod1 = "RADIO"
local mod2 = "CLIMATE"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Test")

runner.Step("Unsubscribe app to " .. mod1, commonRC.unSubscribeToModule, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod1 .. ". App is unsubscribed", commonRC.isUnsubscribed, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod2 .. ". App is still subscribed", commonRC.isSubscribed, { mod2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
