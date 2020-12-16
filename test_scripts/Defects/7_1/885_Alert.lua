---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/885
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL stops processing softButton events once a response is received for the RPC.
-- 'Alert' scenario.
--
-- Steps:
-- 1. App is registered and activated
-- 2. App sends 'Alert' RPC with soft buttons
-- SDL does:
--  - transfer request to HMI
-- 3. HMI sends 'OnButtonEvent' and 'OnButtonPress' notifications
-- SDL does:
--  - transfer notifications to the App
-- 4. HMI provides a response for 'Alert'
-- SDL does:
--  - transfer response to the App
-- 5. HMI sends 'OnButtonEvent' and 'OnButtonPress' notifications
-- SDL does:
-- - not transfer notifications to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local expected = {
  yes = true,
  no = false
}
local btn = {
  id = 4,
  name = "CUSTOM_BUTTON"
}
local params = {
  softButtons = {
    { type = "TEXT", softButtonID = 4, text = "text" }
  },
  alertText1 = "alertText1"
}

--[[ Local Functions ]]
local function sendOnButtonEvents(pIsExp)
  local times = pIsExp == true and 1 or 0
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = btn.name, mode = "BUTTONDOWN", customButtonID = btn.id, appID = common.getHMIAppId() })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = btn.name, mode = "SHORT", customButtonID = btn.id, appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnButtonEvent",
    { buttonName = btn.name, buttonEventMode = "BUTTONDOWN", customButtonID = btn.id })
  :Times(times)
  common.getMobileSession():ExpectNotification("OnButtonPress",
    { buttonName = btn.name, buttonPressMode = "SHORT", customButtonID = btn.id } )
  :Times(times)
end

local function alert()
  local cid = common.getMobileSession():SendRPC("Alert", params)
  common.getHMIConnection():ExpectRequest("UI.Alert")
  :Do(function(_, data)
      common.run.runAfter(function()
          sendOnButtonEvents(expected.yes)
        end, 500)
      common.run.runAfter(function()
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      sendOnButtonEvents(expected.no)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Alert with soft buttons", alert)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
