------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to SubscribeButton/UnsubscribeButton RPC's
--  with 'PLAY_PAUSE' parameter in case mobile app is registered with syncMsgVersion (4.5)
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is registered with major version=4.5
-- 2. Mobile app requests SubscribeButton(PLAY_PAUSE)
-- SDL does:
-- - not transfer `Buttons.SubscribeButton` request to HMI
-- - respond SubscribeButton(INVALID_DATA) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- - not transfer button events to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PLAY_PAUSE"
local errorCode = "INVALID_DATA"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("SubscribeButton " .. buttonName .. " INVALID_DATA",
  common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
 common.runner.Step("On Button Press " .. buttonName, common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })
 common.runner.Step("UnsubscribeButton " .. buttonName .. " INVALID_DATA",
  common.rpcUnsuccess, { appSessionId1, "UnsubscribeButton", buttonName, errorCode })
 common.runner.Step("On Button Press " .. buttonName, common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
