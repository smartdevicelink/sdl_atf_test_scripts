---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/885,
--  https://github.com/smartdevicelink/sdl_core/issues/3829
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not stop processing softButton events once a response is received for the RPC.
-- 'ShowConstantTBT' scenario.
--
-- Steps:
-- 1. App is registered and activated
-- 2. App sends 'ShowConstantTBT' RPC with soft buttons
-- SDL does:
--  - transfer request to HMI
-- 3. HMI sends 'OnButtonEvent' and 'OnButtonPress' notifications
-- SDL does:
--  - transfer notifications to the App
-- 4. HMI provides a response for 'ShowConstantTBT'
-- SDL does:
--  - transfer response to the App
-- 5. HMI sends 'OnButtonEvent' and 'OnButtonPress' notifications
-- SDL does:
-- - transfer notifications to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local btn = {
  id = 4,
  name = "CUSTOM_BUTTON"
}
local params = {
  navigationText1 = "navigationText1",
  softButtons = {
    { type = "TEXT", softButtonID = 4, text = "text" }
  }
}

--[[ Local Functions ]]
local function sendOnButtonEvents()
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = btn.name, mode = "BUTTONDOWN", customButtonID = btn.id, appID = common.getHMIAppId() })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = btn.name, mode = "SHORT", customButtonID = btn.id, appID = common.getHMIAppId() })
end

local function showConstantTBT()
  local cid = common.getMobileSession():SendRPC("ShowConstantTBT", params)
  common.getMobileSession():ExpectNotification("OnButtonEvent",
    { buttonName = btn.name, buttonEventMode = "BUTTONDOWN", customButtonID = btn.id })
  :Times(2)
  common.getMobileSession():ExpectNotification("OnButtonPress",
    { buttonName = btn.name, buttonPressMode = "SHORT", customButtonID = btn.id })
  :Times(2)
  common.getHMIConnection():ExpectRequest("Navigation.ShowConstantTBT")
  :Do(function(_, data)
      common.run.runAfter(function()
          sendOnButtonEvents()
        end, 500)
      common.run.runAfter(function()
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      sendOnButtonEvents()
    end)
end

local function pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Navigation-1" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Update ptu", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ShowConstantTBT with soft buttons", showConstantTBT)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
