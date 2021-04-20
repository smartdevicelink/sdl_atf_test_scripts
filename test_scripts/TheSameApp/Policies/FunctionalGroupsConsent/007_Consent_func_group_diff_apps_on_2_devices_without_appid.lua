---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: User consent for functional groups without application specification for two consented mobile devices
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) RPC Show exists only in Group001 according policies and requires user consent ConsentGroup001
-- 4) Application App1 is registered on Mobile №1 and Mobile №2 (two copies of one application)
--    Application App2 is registered on Mobile №1
--
-- Steps:
-- 1) User allows ConsentGroup001 for all applications (HMI sends SDL.OnAppPermissionConsent without appId)
-- All applications (App1 and App2 on Mobile №1 and App1 on Mobile №1) send to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = SUCCESS) response to App1 on Mobile №1
--    SDL sends Show(resultCode = SUCCESS) response to App1 on Mobile №2
--    SDL sends Show(resultCode = SUCCESS) response to App2 on Mobile №1
-- 2) Register application App2 on Mobile №2
-- (another application with the same appName and appId on other device was registered before allowing ConsentGroup001)
-- Application App2 Mobile №2 sends to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = SUCCESS) response to App2 on Mobile №2
-- 3) Register application App3 on Mobile №2 (new application)
-- Application App3 Mobile №2 sends to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = SUCCESS) response to App3 on Mobile №2
-- 4) User disallows ConsentGroup001 for all applications (HMI sends SDL.OnAppPermissionConsent without appId)
-- All applications (App1 and App2 on Mobile №1 and App1 on Mobile №1) send to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = USER_DISALLOWED) response to App1 on Mobile №1
--    SDL sends Show(resultCode = USER_DISALLOWED) response to App1 on Mobile №2
--    SDL sends Show(resultCode = USER_DISALLOWED) response to App2 on Mobile №1
--    SDL sends Show(resultCode = USER_DISALLOWED) response to App2 on Mobile №2
--    SDL sends Show(resultCode = USER_DISALLOWED) response to App3 on Mobile №1
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
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application4",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0004",
    fullAppID = "0000004",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  [2] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application5",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0005",
    fullAppID = "0000005",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  [3] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application6",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0065",
    fullAppID = "0000065",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
}

local ptFuncGroup = {
  Group001 = {
    user_consent_prompt = "ConsentGroup001",
    rpcs = {
      Show = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
      }
    }
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table

  for funcGroupName in pairs(pt.functional_groupings) do
    if type(pt.functional_groupings[funcGroupName].rpcs) == "table" then
      pt.functional_groupings[funcGroupName].rpcs["Show"] = nil
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["Group001"] = ptFuncGroup.Group001

  local appPolicies = common.cloneTable(pt.app_policies["default"])
  appPolicies.groups = {"Base-4", "Group001"}

  pt.app_policies[appParams[1].fullAppID] = appPolicies
  pt.app_policies[appParams[2].fullAppID] = common.cloneTable(appPolicies)
  pt.app_policies[appParams[3].fullAppID] = common.cloneTable(appPolicies)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 1", common.registerAppEx, {2, appParams[2], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {3, appParams[1], 2})

runner.Title("Test")
runner.Step("Allow group Group001 for all Apps", common.funcGroupConsentForApp,
    {{{name = "ConsentGroup001", allowed = true}}})
runner.Step("Successful Show from App1 from device 1", common.show, {1, "SUCCESS"})
runner.Step("Successful Show from App2 from device 1", common.show, {2, "SUCCESS"})
runner.Step("Successful Show from App1 from device 2", common.show, {3, "SUCCESS"})

runner.Step("Disallow group Group001 for all Apps", common.funcGroupConsentForApp,
    {{{name = "ConsentGroup001", allowed = false}}})
runner.Step("User disallowed Show from App1 from device 1", common.show, {1, "USER_DISALLOWED"})
runner.Step("User disallowed Show from App2 from device 1", common.show, {2, "USER_DISALLOWED"})
runner.Step("User disallowed Show from App1 from device 2", common.show, {3, "USER_DISALLOWED"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
