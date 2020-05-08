---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/5
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/unsubscribe_from_module_status_change_notification.md
-- Item: Use Case 1: Alternative flow 3
--
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
-- [SDL_RC] Unsubscribe from RC module change notifications
--
-- Description:
-- In case:
-- 1) RC app is subscribed to one of the RC module
-- 2) and then SDL received OnInteriorVehicleData notification for another module
-- SDL must:
-- 1) Does not re-send OnInteriorVehicleData notification to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mod1 = "CLIMATE"
local mod2 = "RADIO"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

runner.Step("Subscribe app to " .. mod1, commonRC.subscribeToModule, { mod1 })
runner.Step("Send notification OnInteriorVehicleData " .. mod1 .. ". App is subscribed", commonRC.isSubscribed, { mod1 })

runner.Step("Send notification OnInteriorVehicleData " .. mod2 .. ". App is not subscribed", commonRC.isUnsubscribed, { mod2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
