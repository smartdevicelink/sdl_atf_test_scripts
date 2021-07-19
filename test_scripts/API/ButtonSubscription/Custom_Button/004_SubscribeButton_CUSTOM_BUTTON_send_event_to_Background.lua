------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends an event notification for 'CUSTOM_BUTTON' in case
--  App in 'BACKGROUND' HMI level
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for CUSTOM_BUTTON Alert and Default action
-- 2. App is sent to hmi level BACKGROUND
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications
-- SDL does:
-- - resend OnButtonEvent and OnButtonPress to mobile app for CUSTOM_BUTTON
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local buttonName = "CUSTOM_BUTTON"
local customButtonIDAlert = 1
local alertId

local RequestAlert = {
  alertText1 = "alertText1",
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "action.png",
        imageType = "DYNAMIC"
      },
      isHighlighted = true,
      softButtonID = customButtonIDAlert,
      systemAction = "KEEP_CONTEXT"
    }
  }
}

-- [[ Local Functions ]]
local function pTUpdateFunc(pTbl)
  pTbl.policy_table.module_config.notifications_per_minute_by_priority["NONE"] = 2
  pTbl.policy_table.functional_groupings["Base-4"].rpcs["Alert"].hmi_levels = {
    "FULL",
    "BACKGROUND",
    "LIMITED"
  }
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId1).fullAppID].keep_context = true
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId1).fullAppID].steal_focus = true
end

local function registerSoftButton(pAppId)
  common.getMobileSession(pAppId):SendRPC("Alert", RequestAlert)
  common.getHMIConnection():ExpectRequest("UI.Alert")
  :Do(function(_,data)
      alertId = data.id
    end)
end

local function pressOnButton(...)
  common.buttonPress (...)
  common.getHMIConnection():SendResponse(alertId, "UI.Alert", "SUCCESS", {})
  common.getMobileSession():ExpectResponse("Alert", { success = true, resultCode = "SUCCESS" })
end

local function app_1_to_BACKGROUND()
  common.activateApp(appSessionId2)
  common.getMobileSession(appSessionId1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App_1 registration", common.registerApp)
common.runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
common.runner.Step("App_2 registration", common.registerAppWOPTU, { appSessionId2 })
common.runner.Step("Activate app_1", common.activateApp, { appSessionId1 })
common.runner.Step("Subscribe on Soft button, Alert", registerSoftButton, { appSessionId1 })
common.runner.Step("Press on " .. buttonName .. " Alert", pressOnButton,
  { appSessionId1, buttonName, common.isExpected, customButtonIDAlert })
common.runner.Step("Activate App_2, App_1 goes to BACKGROUND", app_1_to_BACKGROUND)

common.runner.Title("Test")
common.runner.Step("Subscribe on Soft button, Alert", registerSoftButton, { appSessionId1 })
common.runner.Step("Press on " .. buttonName .. " Alert",  pressOnButton,
  { appSessionId1, buttonName, common.isExpected, customButtonIDAlert })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
