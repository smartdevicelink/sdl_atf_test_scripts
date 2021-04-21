---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2462
--
-- Description:
-- SDL sends SDL.OnAppPermissionChanged(appPermissionsConsentNeeded = true) to HMI
-- in case new functional group requires user consent is assigned to the App within PTU
--
-- Steps to reproduce:
-- 1) Register app
-- 2) Perform PTU with group that requires the user consent
-- Expected:
-- 1) SDL checks a new added group from PTU requires user consent prompt
-- 2) SDL sends SDL.OnAppPermissionChanged(appPermissionsConsentNeeded = true) to HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

-- [[ Local functions ]]
local function expectationAppPermissionsParam()
  common.getHMIConnection():ExpectNotification("SDL.OnAppPermissionChanged",
    { appPermissionsConsentNeeded = true, appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
end

local function ptuFunc(tbl)
  tbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Location-1" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("RAI, PTU", common.policyTableUpdate, { ptuFunc, expectationAppPermissionsParam })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
