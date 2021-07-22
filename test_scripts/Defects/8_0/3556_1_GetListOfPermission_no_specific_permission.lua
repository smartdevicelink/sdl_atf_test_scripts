---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3556
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends response to SDL.GetListOfPermission with appId in case there are no specific
--   permissions for the app
--
-- Preconditions:
-- 1. Clean environment
-- 2. PT does not contain group with user_consent_prompt in default section
-- 3. SDL, HMI, Mobile session are started
-- 4. App is registered
-- 5. App is activated
-- Steps:
-- 1. HMI sends GetListOfPermissions request
-- SDL does:
--  - sends GetListOfPermissions response with empty allowedFunctions array list
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local json = require('modules/json')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = { "EXTERNAL_PROPRIETARY" }}}
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getListOfPermissions()
  local rid = common.getHMIConnection():SendRequest("SDL.GetListOfPermissions", { appID = common.getHMIAppId() })
  local resultGetListOfPermissions = {
    code = 0,
    method = "SDL.GetListOfPermissions",
    allowedFunctions = json.EMPTY_ARRAY,
    externalConsentStatus = json.EMPTY_ARRAY
  }
  common.getHMIConnection():ExpectResponse(rid, { result = resultGetListOfPermissions })
  :ValidIf(function(_,data)
    if data.result.allowedFunctions ~= resultGetListOfPermissions.allowedFunctions then
      return false, "allowedFunctions contains unexpected parameters\n"
    elseif data.result.externalConsentStatus ~= resultGetListOfPermissions.externalConsentStatus then
      return false, "externalConsentStatus contains unexpected parameters\n"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send GetListOfPermissions", getListOfPermissions)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
