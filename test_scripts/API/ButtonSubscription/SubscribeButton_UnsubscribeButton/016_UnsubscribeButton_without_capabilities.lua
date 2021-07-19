------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "UNSUPPORTED_RESOURCE" to UnsubscribeButton request in case
--   <button> is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. <button> is not present in capabilities
-- 2. Mobile app requests UnsubscribeButton(<button>)
-- SDL does:
-- - not transfer `Buttons.UnsubscribeButton` request to HMI
-- - respond UnsubscribeButton(UNSUPPORTED_RESOURCE) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
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
  common.runner.Step("UnsubscribeButton without capabilities on " .. buttonName,
    common.rpcUnsuccess, { appSessionId1, "UnsubscribeButton", buttonName, errorCode })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
