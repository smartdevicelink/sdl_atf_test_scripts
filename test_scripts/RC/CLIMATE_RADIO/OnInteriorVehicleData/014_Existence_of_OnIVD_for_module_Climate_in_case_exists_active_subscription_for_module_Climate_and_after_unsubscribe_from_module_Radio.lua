---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/5
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/unsubscribe_from_module_status_change_notification.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Unsubscribe from RC module change notifications
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

--[[ Local Variables ]]
local mod1 = "RADIO"
local mod2 = "CLIMATE"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

for _, mod in pairs(commonRC.modules)  do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Test")

runner.Step("Unsubscribe app to " .. mod1, commonRC.unSubscribeToModule, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod1 .. ". App is unsubscribed", commonRC.isUnsubscribed, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod2 .. ". App is still subscribed", commonRC.isSubscribed, { mod2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
