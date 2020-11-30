---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3527
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. There are 2 apps registered: App_1 and App_2
-- 2. App_1 is in 'LIMITED' and App_2 is in 'FULL' HMI levels
-- 3. App_1 sends 'SubtleAlert'
--
-- Expected:
-- SDL does:
--  - proceed with request successfully
--  - not change HMI level of both apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "MEDIA" }
common.app.getParams(1).isMediaApplication = true
common.app.getParams(2).appHMIType = { "DEFAULT" }
common.app.getParams(2).isMediaApplication = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function sendOnSystemContext(pCtx, appID)
  common.getHMIConnection():SendNotification("UI.OnSystemContext", {
    appID = common.getHMIAppId(appID),
    systemContext = pCtx
  })
end

local function sendSubtleAlert()
  local cid = common.getMobileSession(1):SendRPC("SubtleAlert", { alertText1 = "Message" })
  common.getHMIConnection():ExpectRequest("UI.SubtleAlert")
  :Do(function(_, data)
      sendOnSystemContext("ALERT", 1)
      sendOnSystemContext("HMI_OBSCURED", 2)
      common.run.runAfter(function()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        sendOnSystemContext("MAIN", 1)
        sendOnSystemContext("MAIN", 2)
      end, 1000)
    end)
  common.getMobileSession(1):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", systemContext = "ALERT" },
    { hmiLevel = "LIMITED", systemContext = "MAIN" })
  :Times(2)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", systemContext = "MAIN" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.app.registerNoPTU)
runner.Step("Register App 2", common.app.registerNoPTU, { 2 })
runner.Step("Activate App 1", common.activateApp)
runner.Step("Activate App 2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("App 1 sends SubtleAlert", sendSubtleAlert)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
