------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "REJECTED" to SubscribeButton request in case
--  non media app sends request with <media_button> parameter
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Non media app is registered
-- 2. App requests SubscribeButton(media_button)
-- SDL does:
-- - not send Buttons.SubscribeButton request to HMI and respond SubscribeButton(REJECTED) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for <media_button>
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Variables ]]
local appSessionId1 = 1
local errorCode = "REJECTED"

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
for _, buttonName in pairs(common.mediaButtons) do
  common.runner.Title("ButtonName parameter: " .. buttonName)
  common.runner.Step("SubscribeButton on " .. buttonName .. " , SDL sent REJECT",
    common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
  common.runner.Step("Button ".. buttonName .. " wasn't Subscribed", common.buttonPress,
    { appSessionId1, buttonName, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
