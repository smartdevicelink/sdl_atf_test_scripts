------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that App is still subscribed on <button> if HMI does not respond to SubscribeButton request
--  from SDL once default timeout expires
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for <button>
-- 2. Mobile app requests UnsubscribeButton(<button>)
-- 3. SDL sends Buttons.UnsubscribeButton(<button>, appId) to HMI
-- 4. HMI does not respond during default timeout
-- 5. SDL responds UnsubscribeButton(GENERIC_ERROR) to mobile app
-- 6. HMI sends Buttons.UnsubscribeButton(SUCCESS) to SDL
-- SDL does:
-- - sends Buttons.SubscribeButton(<button>, appId) to HMI
-- In case:
-- 7. HMI doesn't respond for a `Buttons.SubscribeButton` request from SDL
-- 8. HMI sends OnButtonEvent and OnButtonPress notifications for <button>
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"

--[[ Local function ]]
local function rpcGenericError(pButtonName)
  local hmiCID
  local cid = common.getMobileSession():SendRPC("UnsubscribeButton", { buttonName = pButtonName })
  local appIdVariable = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton",
    { appID = appIdVariable, buttonName = pButtonName })
  :Do(function(_, data)
      -- HMI did not response
      hmiCID = data.id
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Do(function()
      common.getHMIConnection():SendResponse( hmiCID, "Buttons.UnsubscribeButton", "SUCCESS", { })
      common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
        { appID = appIdVariable, buttonName = pButtonName })
      :Do(function(_, data)
          -- HMI did not response
        end)
    end)
  local event = common.createEvent()
  event.matches = function(_, data)
    return data.rpcType == 1 and
    data.rpcFunctionId == 18
  end
  common.getMobileSession():ExpectEvent(event, "SubscribeButtonResponse")
  :Times(0)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Title("ButtonName parameter: " .. buttonName)
common.runner.Step("Subscribe on " .. buttonName, common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
common.runner.Step("Unsubscribe on " .. buttonName .. " button in timeout case", rpcGenericError, { buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
