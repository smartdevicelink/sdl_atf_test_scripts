------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeButton RPC for two Apps with different <button> parameters
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile App1 requests SubscribeButton(button_1)
-- 2. Mobile App2 requests SubscribeButton(button_2)
-- SDL does:
-- - send Buttons.SubscribeButton(button_1, appId1) to HMI
-- - send Buttons.SubscribeButton(button_2, appId2) to HMI
-- - process successful responses from HMI
-- - respond SubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile App1 and App2 after adding subscription
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for button_1
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress notifications to App1 and not transfer to App2
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for button_2
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress notifications to App2 and not transfer to App1
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local buttonName_1 = "PRESET_1"
local buttonName_2 = "PRESET_0"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App_1 registration", common.registerAppWOPTU, { appSessionId1 })
common.runner.Step("App_1 activation", common.activateApp, { appSessionId1 })
common.runner.Step("App_2 registration", common.registerAppWOPTU, { appSessionId2 })
common.runner.Step("App_2 activation, Set App_1 HMI Level to Limited", common.activateApp, { appSessionId2 })

common.runner.Title("Test")
common.runner.Step("App_1 SubscribeButton on " .. buttonName_1 .." button",
  common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName_1 })
common.runner.Step("App_2 SubscribeButton on " .. buttonName_2 .. " button",
  common.rpcSuccess, { appSessionId2, "SubscribeButton", buttonName_2 })
common.runner.Step("Press on " .. buttonName_1 .. " button", common.buttonPressMultipleApps,
  { appSessionId1, buttonName_1, common.isExpected, common.isNotExpected  })
common.runner.Step("Press on " .. buttonName_2 .. " button", common.buttonPressMultipleApps,
  { appSessionId2, buttonName_2, common.isNotExpected, common.isExpected  })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
