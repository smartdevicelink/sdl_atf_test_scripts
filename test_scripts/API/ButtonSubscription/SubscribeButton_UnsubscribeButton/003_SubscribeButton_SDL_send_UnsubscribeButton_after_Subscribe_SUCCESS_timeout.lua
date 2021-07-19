------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends UnsubscribeButton request if HMI respond to SubscribeButton request
--  once default timeout expires
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app requests SubscribeButton(<button>)
-- 2. SDL sends Buttons.SubscribeButton(<button>, appId) to HMI
-- 3. HMI does not respond during default timeout
-- 4. SDL responds SubscribeButton(GENERIC_ERROR) to mobile app
-- 5. HMI sends Buttons.SubscribeButton(SUCCESS) to SDL
-- SDL does:
-- - send Buttons.UnsubscribeButton(<button>, appId) to HMI
-- - receive response Buttons.UnsubscribeButton(SUCCESS) and keep actual unsubscribed state for <button>
-- - not send UnsubscribeButton response to mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"

--[[ Local function ]]
local function rpcGenericError(pButtonName)
  local hmiCID
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButtonName })
  local appIdVariable = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
  :Do(function(_, data)
      -- HMI did not response
      hmiCID = data.id
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Do(function()
      common.getHMIConnection():SendResponse(hmiCID, "Buttons.SubscribeButton", "SUCCESS", { })
    end)
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton",
    { appID = appIdVariable, buttonName = pButtonName })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  local event = common.createEvent()
  event.matches = function(_, data)
    return data.rpcType == 1 and
    data.rpcFunctionId == 19
  end
  common.getMobileSession():ExpectEvent(event, "UnsubscribeButtonResponse")
  :Times(0)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("Subscribe on " .. buttonName .. " button,timeout case", rpcGenericError, { buttonName })
common.runner.Step("Button ".. buttonName .. " wasn't Subscribe", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
