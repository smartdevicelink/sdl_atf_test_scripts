---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
--
-- Description: TRS: GetInteriorVehicleData, #4
-- In case:
-- 1) RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:true" parameter
-- 2) and SDL received GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS" from HMI
-- 3) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Internally subscribe this application for requested <moduleType_value>
-- 2) Transfer GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS", "success:true" to the related app
-- 3) Re-send OnInteriorVehicleData notification to the related app
--
-- [SDL_RC] Unsubscribe from RC module change notifications
--
-- Description: TRS: GetInteriorVehicleData, #8
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS" from HMI
-- 4) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Internally un-subscribe this application for requested <moduleType_value>
-- 2) Transfer GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS", "success:true" to the related app
-- 3) Does not re-send OnInteriorVehicleData notification  to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod, 1 })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod, 1 })
end

for _, mod in pairs(modules) do
  runner.Step("Unsubscribe app to " .. mod, commonRC.unSubscribeToModule, { mod, 1 })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is unsubscribed", commonRC.isUnsubscribed, { mod, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
