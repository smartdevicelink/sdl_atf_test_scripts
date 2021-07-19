------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check data resumption is failed in case HMI responds with <erroneous> result code
--  to SubscribeButton request after unexpected disconnect
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for <button>
-- 2. Unexpected disconnect and connect are performed
-- 3. App registers with actual hashId
-- 4. SDL sends Buttons.SubscribeButton(<button>, appId) to HMI during resumption
-- 5. HMI responds with error code
-- SDL does:
-- - process error response from HMI
-- - respond RAI(RESUME_FAILED) to mobile app
-- In case:
-- 6. HMI sends OnButtonEvent and OnButtonPress notifications to SDL
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"

--[[ Local Functions ]]
local function reRegisterApp(pAppId, pButtonName, pRAIResponseExp)
  if not pAppId then pAppId = 1 end
  if not pRAIResponseExp then pRAIResponseExp = 10000 end
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = common.cloneTable(common.getConfigAppParams(pAppId))
      params.hashID = common.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = { appName = common.getConfigAppParams(pAppId).appName }
      })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp",
            { appID = common.getHMIAppId(pAppId) })
          :Do(function(_, data)
              common.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
      :Timeout(pRAIResponseExp)
    end)
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" },
    { appID = common.getHMIAppId(pAppId), buttonName = pButtonName })
  :Times(2)
  :Do(function(_, data)
      if data.params.buttonName == pButtonName then
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
    end)
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton")
  :Times(0)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
common.runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.runner.Step("Connect mobile", common.connectMobile)
common.runner.Step("Reregister App resumption data with error code",
  reRegisterApp, { appSessionId1, buttonName })
common.runner.Step("Subscription on ".. buttonName .. " button wasn't Resumed",
  common.buttonPress, { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
