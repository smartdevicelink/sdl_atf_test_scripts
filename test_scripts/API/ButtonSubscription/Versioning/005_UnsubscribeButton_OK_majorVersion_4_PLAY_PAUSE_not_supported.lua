------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing of UnsubscribeButton request with 'OK' parameter in case:
--  - mobile app is registered with syncMsgVersion (4.5)
--  -'PLAY_PAUSE' is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. HMI is not supported PLAY_PAUSE
-- 2. Mobile app is registered with major version=4.5
-- 3. Mobile app requests SubscribeButton(OK)
-- 4. Mobile app requests UnsubscribeButton(OK)
-- SDL does:
-- - send Buttons.UnsubscribeButton(OK, appId) to HMI
-- - wait response from HMI
-- - receive Buttons.UnsubscribeButton(SUCCESS)
-- - respond UnsubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile app
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for "OK"
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')
--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonNameOK = "OK"
local buttonNamePLAY_PAUSE = "PLAY_PAUSE"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
  { common.removeButtonFromCapabilities(buttonNamePLAY_PAUSE) })
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonNameOK, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonNameOK })
common.runner.Step("On Button Press " .. buttonNameOK, common.buttonPress, { appSessionId1, buttonNameOK })

common.runner.Title("Test")
common.runner.Step("UnsubscribeButton " .. buttonNameOK, common.rpcSuccess,
  { appSessionId1, "UnsubscribeButton", buttonNameOK })
common.runner.Step("Check unsubscribe " .. buttonNameOK, common.buttonPress,
  { appSessionId1, buttonNameOK, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
