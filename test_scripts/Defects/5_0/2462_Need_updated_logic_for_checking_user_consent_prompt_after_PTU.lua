---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2462
--
-- Description:
-- 1) Need updated logic for checking user consent prompt after PTU.
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

-- [[ Local functions ]]
local function expectationAppPermissionsParam()
  common.getHMIConnection():ExpectNotification("SDL.OnAppPermissionChanged", { appPermissionsConsentNeeded = true })
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATING" },
    { status = "UP_TO_DATE" })
  :Times(2)
end

local function ptuFunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = { "Base-4", "Location-1" }
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
