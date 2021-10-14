---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2989
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL allows all RemoteControl RPCs in case if policies are disabled in SDL .ini
--
-- Preconditions:
-- 1. Make sure 'EnablePolicy=false' in SDL .ini
-- 2. SDL, HMI, Mobile session are started
-- 3. App is registered
-- Steps:
-- 1. App sends 'GetInteriorVehicle' and 'SetInteriorVehicle' requests
-- SDL does:
--  - proceed with requests successfully
-- 2. App subscribed for RC module
-- 3. HMI sends 'OnInteriorVehicleData' notification for RC module
-- SDL does:
--  - transfer notification to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local common = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local modules = { "RADIO" }

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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Disable policies", common.setSDLIniParameter, { "EnablePolicy", "false" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, common.subscribeToModule, { mod })
  runner.Step("OnInteriorVehicleData " .. mod, common.isSubscribed, { mod })
end
for _, mod in pairs(modules)  do
  runner.Step("SetInteriorVehicleData " .. mod, common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
