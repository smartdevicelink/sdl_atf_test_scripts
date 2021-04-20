---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Consent of two different mobile devices with registered the same mobile applications
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL but are not consented
-- 3) Application App1 is registered on Mobile №1 and Mobile №2 (two copies of one application)
--
-- Steps:
-- 1) App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №1
-- 2) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №2
-- 3) Mobile №1 is consented by user from HMI GUI (SDL.OnAllowSDLFunctionality)
-- App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №1
-- 4) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №2
-- 5) Mobile №2 is consented by user from HMI GUI (SDL.OnAllowSDLFunctionality)
-- App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №1
-- 6) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №2
-- 7) Mobile №1 is declined by user from HMI GUI (SDL.OnAllowSDLFunctionality)
-- App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №1
-- 8) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = SUCCESS) response to Mobile №2
-- 9) Mobile №2 is declined by user from HMI GUI (SDL.OnAllowSDLFunctionality)
-- App1 from Mobile №1 sends valid GetSystemCapability request to SDL
--   Check:
--    SDL sends GetSystemCapability(resultCode = DISALLOWED) response to Mobile №1
-- 10) App1 from Mobile №2 sends valid GetSystemCapability request to SDL
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
    appName = "Test Application1",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0001",
    fullAppID = "0000001",
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

local function connectMobDevices(pDevices)
  for i = 1, #pDevices do
    common.connectMobDevice(i, pDevices[i], false)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})

runner.Title("Test")
runner.Step("Disallowed GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "DISALLOWED"})
runner.Step("Disallowed GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "DISALLOWED"})

runner.Step("Allow SDL for Device 1", common.mobile.allowSDL, {1})
runner.Step("Successful GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "SUCCESS"})
runner.Step("Disallowed GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "DISALLOWED"})

runner.Step("Allow SDL for Device 2", common.mobile.allowSDL, {2})
runner.Step("Successful GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "SUCCESS"})
runner.Step("Successful GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "SUCCESS"})

runner.Step("Disallow SDL for Device 1", common.mobile.disallowSDL, {1})
runner.Step("Disallowed GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "DISALLOWED"})
runner.Step("Disallowed GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "SUCCESS"})

runner.Step("Disallow SDL for Device Device 2", common.mobile.disallowSDL, {2})
runner.Step("Disallowed GetSystemCapability from App1 from device 1", common.getSystemCapability, {1, "DISALLOWED"})
runner.Step("Disallowed GetSystemCapability from App1 from device 2", common.getSystemCapability, {2, "DISALLOWED"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
