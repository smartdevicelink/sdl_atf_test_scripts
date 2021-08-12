------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends an event notification without App ID only to App in FULL HMI level
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile Apps are subscribed for 'OK' button
-- 2. App_1 is set to FULL HMI level
-- 3. App_2 is set to LIMITED HMI level
-- 4. App_3 is set to BACKGROUND HMI level
-- 5. App_4 is set to NONE HMI level
-- 6. HMI sends OnButtonEvent and OnButtonPress notification without App ID
-- SDL does:
-- - resend notifications only to the App_1 in FULL hmi level
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application3.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application4.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local appSessionId3 = 3
local appSessionId4 = 4
local buttonName = "OK"

--[[ Local functions ]]
local function pTUpdateFunc(pTbl)
  local hmiLevels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.SubscribeButton.hmi_levels = hmiLevels
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.OnButtonPress.hmi_levels = hmiLevels
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.OnButtonEvent.hmi_levels = hmiLevels
end

local function buttonPressWithoutAppId(pButtonName, pAppFULL, pAppBACKGROUND, pAppLIMITED, pAppNONE)
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN" })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT" })
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP" })

  common.getMobileSession(pAppFULL):ExpectNotification("OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
  :Times(2)
  common.getMobileSession(pAppFULL):ExpectNotification("OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})
  common.getMobileSession(pAppBACKGROUND):ExpectNotification("OnButtonEvent")
  :Times(0)
  common.getMobileSession(pAppBACKGROUND):ExpectNotification("OnButtonPress")
  :Times(0)
   common.getMobileSession(pAppLIMITED):ExpectNotification("OnButtonEvent")
  :Times(0)
  common.getMobileSession(pAppLIMITED):ExpectNotification("OnButtonPress")
  :Times(0)
  common.getMobileSession(pAppNONE):ExpectNotification("OnButtonEvent")
  :Times(0)
  common.getMobileSession(pAppNONE):ExpectNotification("OnButtonPress")
  :Times(0)
end

local function activateApp(pAppFULL, pAppBACKGROUND)
  common.getMobileSession(pAppBACKGROUND):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
  common.activateApp(pAppFULL)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App_1 registration", common.registerAppWOPTU, { appSessionId1 })
common.runner.Step("App_2 registration", common.registerAppWOPTU, { appSessionId2 })
common.runner.Step("App_3 registration", common.registerAppWOPTU, { appSessionId3 })
common.runner.Step("App_4 registration", common.registerApp, { appSessionId4 })
common.runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
common.runner.Step("App_2 activation, Set App_2 HMI Level to Limited", common.activateApp, { appSessionId2 })
common.runner.Step("App_3 activation", common.activateApp, { appSessionId3 })
common.runner.Step("App_1 activation, Set App_3 HMI Level to BACKGROUND", activateApp, { appSessionId1, appSessionId3 })
common.runner.Step("App_1 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("App_2 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId2, "SubscribeButton", buttonName })
common.runner.Step("App_3 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId3, "SubscribeButton", buttonName })
common.runner.Step("App_4 SubscribeButton on " .. buttonName .." button",
  common.rpcSuccess, { appSessionId4, "SubscribeButton", buttonName })

common.runner.Title("Test")
common.runner.Step("Button Press on " .. buttonName,
  buttonPressWithoutAppId, { buttonName,  appSessionId1, appSessionId2, appSessionId3, appSessionId4 })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
