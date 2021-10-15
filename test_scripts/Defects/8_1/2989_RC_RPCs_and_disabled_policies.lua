---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2989
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL allows all RemoteControl RPCs in case if policies are disabled in SDL .ini
--
-- Preconditions:
-- 1. Make sure 'EnablePolicy=false' in SDL .ini
-- 2. SDL, HMI, Mobile session are started
-- 3. HMI defines RC access mode to 'ASK_DRIVER'
-- 4. App1 and App2 are registered
-- Steps:
-- 1. App1 sends 'GetInteriorVehicleData', 'SetInteriorVehicleData' requests
-- SDL does:
--  - proceed with requests successfully
-- 2. App1 subscribed for RC module
-- 3. HMI sends 'OnInteriorVehicleData' notification for RC module
-- SDL does:
--  - transfer notification to the App1
-- 4. App2 tries to subscribe for RC module
-- SDL does:
--  - ask for the user consent within 'GetInteriorVehicleDataConsent' request
--  - proceed with 'SetInteriorVehicleData' request once consent is provided
-- 5. App2 sends 'ReleaseInteriorVehicleDataModule' request
-- SDL does:
--  - release RC module successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local common = require('test_scripts/RC/commonRC')
local hmi_table = require('user_modules/hmi_values').getDefaultHMITable()

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local modules = { "RADIO" }
local moduleIds = {
  RADIO = hmi_table.RC.GetCapabilities.params.remoteControlCapability.radioControlCapabilities[1].moduleId
}

--[[ Override Common Functions ]]
local createSession_Orig = actions.mobile.createSession
function actions.mobile.createSession(...)
  local session = createSession_Orig(...)
  local ExpectNotification_Orig = session.ExpectNotification
  function session:ExpectNotification(funcName, ...)
    local params = table.pack(...)
    if funcName == "OnSystemRequest" and params[1] and params[1].requestType == "LOCK_SCREEN_ICON_URL" then
      return -- skip expectation on notification
    end
    return ExpectNotification_Orig(self, funcName, ...)
  end
  return session
end

local function releaseRCModule(pModuleType, pAppId)
  local cid = common.getMobileSession(pAppId):SendRPC("ReleaseInteriorVehicleDataModule",
      { moduleType = pModuleType, moduleId = moduleIds[pModuleType] })
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Disable policies", common.setSDLIniParameter, { "EnablePolicy", "false" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App1", common.activateApp)
runner.Step("RAI2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("App 1 GetInteriorVehicleData " .. mod, common.subscribeToModule, { mod })
  runner.Step("App 1 OnInteriorVehicleData " .. mod, common.isSubscribed, { mod })
  runner.Step("App 1 SetInteriorVehicleData " .. mod, common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("App 2 SetInteriorVehicleData with consent " .. mod, common.rpcAllowedWithConsent,
    { mod, 2, "SetInteriorVehicleData" })
  runner.Step("App 2 ReleaseInteriorVehicleDataModule " .. mod, releaseRCModule, { mod, 2 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
