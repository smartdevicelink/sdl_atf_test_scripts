------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes UnsubscribeButton RPC for two Apps with the same <button> parameters
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile App1 requests SubscribeButton(button)
-- 2. Mobile App2 requests SubscribeButton(button)
-- 3. Mobile App1 requests UnsubscribeButton(button)
-- 4. Mobile App2 requests UnsubscribeButton(button)
-- SDL does:
-- - send Buttons.UnsubscribeButton(button, appId1) to HMI
-- - send Buttons.UnsubscribeButton(button, appId2) to HMI
-- - process successful responses from HMI
-- - respond UnsubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile App1 and App2 after unsubscription
-- In case:
-- 5. HMI sends OnButtonEvent and OnButtonPress notifications for App1
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App1 and  App2
-- In case:
-- 6. HMI sends OnButtonEvent and OnButtonPress notifications for App2
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App1 and  App2
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local buttonName = "PRESET_0"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App_1 registration", common.registerAppWOPTU, { appSessionId1 })
common.runner.Step("App_1 activation", common.activateApp, { appSessionId1 })
common.runner.Step("App_2 registration", common.registerAppWOPTU, { appSessionId2 })
common.runner.Step("App_2 activation, Set App_1 HMI Level to Limited", common.activateApp, { appSessionId2 })
common.runner.Step("App_1 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("App_2 SubscribeButton on " .. buttonName .. " button",
  common.rpcSuccess, { appSessionId2, "SubscribeButton", buttonName })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId1, buttonName, common.isExpected, common.isNotExpected  })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId2, buttonName, common.isNotExpected, common.isExpected  })

common.runner.Title("Test")
common.runner.Step("App_1 UnsubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId1, "UnsubscribeButton", buttonName })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId1, buttonName, common.isNotExpected, common.isNotExpected  })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId2, buttonName, common.isNotExpected, common.isExpected  })
common.runner.Step("App_2 UnsubscribeButton on " .. buttonName .. " button",
  common.rpcSuccess, { appSessionId2, "UnsubscribeButton", buttonName })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId1, buttonName, common.isNotExpected, common.isNotExpected  })
common.runner.Step("Press on " .. buttonName .. " button", common.buttonPressMultipleApps,
  { appSessionId2, buttonName, common.isNotExpected, common.isNotExpected  })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
