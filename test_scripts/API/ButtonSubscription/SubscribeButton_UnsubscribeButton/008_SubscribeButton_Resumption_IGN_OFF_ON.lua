------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL resumes the subscription for <button> parameter after Ignition Cycle
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for <button>
-- 2. IGN_OFF and IGN_ON are performed
-- 3. App registers with actual hashId
-- SDL does:
-- - send Buttons.SubscribeButton(<button>, appId) to HMI during resumption
-- - process successful response from HMI
-- - respond RAI(SUCCESS) to mobile app
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for <button>
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"

--[[ Local Functions ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(), buttonName = "CUSTOM_BUTTON" },
    { appID = common.getHMIAppId(), buttonName = buttonName })
  :Times(2)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
  end)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
common.runner.Step("IGNITION OFF", common.ignitionOff)
common.runner.Step("IGNITION ON", common.start)

common.runner.Title("Test")
common.runner.Step("Reregister App resumption data",
  common.reRegisterAppSuccess, { appSessionId1, checkResumptionData })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
