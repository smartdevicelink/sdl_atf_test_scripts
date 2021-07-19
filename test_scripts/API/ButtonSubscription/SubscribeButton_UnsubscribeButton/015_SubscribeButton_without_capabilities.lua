------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "UNSUPPORTED_RESOURCE" to SubscribeButton request
--  if <button> is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. <button> is not present in capabilities
-- 2. Mobile app requests SubscribeButton(<button>)
-- SDL does:
-- - not transfer `Buttons.SubscribeButton` request to HMI
-- - respond SubscribeButton(UNSUPPORTED_RESOURCE) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for <button>
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local errorCode = "UNSUPPORTED_RESOURCE"

--[[ Scenario ]]
for _, buttonName in common.spairs(common.buttons) do
  common.runner.Title("ButtonName parameter: " .. buttonName)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
    { common.removeButtonFromCapabilities(buttonName) })
  common.runner.Step("App registration", common.registerAppWOPTU)
  common.runner.Step("App activation", common.activateApp)

  common.runner.Title("Test")
  common.runner.Step("SubscribeButton without capabilities on " .. buttonName,
    common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
  common.runner.Step("Button ".. buttonName .. " wasn't Subscribed", common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
