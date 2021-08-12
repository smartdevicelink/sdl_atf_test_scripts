------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with GENERIC_ERROR:false to UnsubscribeButton request if HMI doesn't respond
--  during default timeout
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for button
-- 2. Mobile app requests UnsubscribeButton(<button>)
-- SDL does:
-- - send Buttons.UnsubscribeButton(<button>, appId) to HMI
-- - wait response from HMI
-- - not receive response from HMI during default timeout
-- - respond UnsubscribeButton(GENERIC_ERROR) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- - resend OnButtonEvent and OnButtonPress notifications to mobile App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"
local errorCode = "GENERIC_ERROR"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("Subscribe on " .. buttonName .. " button",
  common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
common.runner.Step("Failure Unsubscribe on "  .. buttonName .. " button, return GENERIC_ERROR",
  common.rpcHMIwithoutResponse, { appSessionId1, "UnsubscribeButton", buttonName, errorCode })
common.runner.Step("Button  " .. buttonName .. " still subscribed", common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
