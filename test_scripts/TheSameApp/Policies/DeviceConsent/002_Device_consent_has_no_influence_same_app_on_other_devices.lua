---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Consent of one mobile device has no influence on the same application registered on another device
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 is connected to SDL and is consented
-- 3) Application App1 is registered on Mobile №1
--
-- Steps:
-- 1) App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №1
-- 2) Mobile №2 connects to SDL but is not consented
-- Application App1 registers on Mobile №2
-- App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №1
--   Check:
-- 3) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{extendedPolicy = {"EXTERNAL_PROPRIETARY"}}}

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort },
}

local appParams = {
  [1] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application3",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0003",
    fullAppID = "0000333",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  pPolicyTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  pPolicyTable.policy_table.functional_groupings["BaseBeforeDataConsent"].rpcs["GetSystemCapability"] = nil
  pPolicyTable.policy_table.functional_groupings["Base-4"].rpcs["GetSystemCapability"] = {
    hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
  }

  pPolicyTable.policy_table.app_policies[appParams[1].fullAppID] =
      common.cloneTable(pPolicyTable.policy_table.app_policies["default"])
  pPolicyTable.policy_table.app_policies[appParams[1].fullAppID].groups = {"Base-4"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect mobile device 1 to SDL", common.connectMobDevice, {1, devices[1], true})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})

runner.Title("Test")
runner.Step("Successful GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "SUCCESS"})
runner.Step("Connect mobile device 2 to SDL", common.connectMobDevice, {2, devices[2], false})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Successful GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "SUCCESS"})
runner.Step("Disallowed GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "DISALLOWED"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
