---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- User consent for multiple functional groups of two consented mobile devices with the same mobile applications
-- registered
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) RPC SendLocation exists only in Group001 according policies and requires user consent ConsentGroup001
--    RPC Show exists only in Group002 according policies and requires user consent ConsentGroup001
-- 4) Application App1 is registered on Mobile №1 and Mobile №2 (two copies of one application)
--
-- Steps:
-- 1) Application App1 from Mobile №1 sends to SDL valid SendLocation RPC request
--   Check:
--    SDl sends SendLocation(resultCode = DISALLOWED) response to Mobile №1
-- 2) Application App1 from Mobile №2 sends to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = DISALLOWED) response to Mobile №2
-- 3) User allows ConsentGroup001 for App1 on Mobile №1
-- Application App1 from Mobile №1 sends to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №1
-- 4) Application App1 from Mobile №2 sends to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = DISALLOWED) response to Mobile №2
-- 5) User allows ConsentGroup001 for App1 on Mobile №2 and disallows it for App1 on Mobile №1
-- Application App1 from Mobile №1 sends to SDL valid SendLocation RPC request
--    SDL sends SendLocation(resultCode = USER_DISALLOWED) response to Mobile №1
--   Check:
-- 6) Application App1 from Mobile №2 sends to SDL valid Show RPC request
--   Check:
--    SDL sends Show(resultCode = SUCCESS) response to Mobile №2
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
  }
}

local ptFuncGroup = {
  Group001 = {
    user_consent_prompt = "ConsentTwoGroups",
    rpcs = {
      SendLocation = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}
      }
    }
  },
  Group002 = {
    user_consent_prompt = "ConsentTwoGroups",
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
      pt.functional_groupings[funcGroupName].rpcs["SendLocation"] = nil
      pt.functional_groupings[funcGroupName].rpcs["Show"] = nil
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["Group001"] = ptFuncGroup.Group001
  pt.functional_groupings["Group002"] = ptFuncGroup.Group002

  pt.app_policies[appParams[1].fullAppID] =
      common.cloneTable(pt.app_policies["default"])
  pt.app_policies[appParams[1].fullAppID].groups = {"Base-4", "Group001", "Group002"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})

runner.Title("Test")
runner.Step("Disallowed SendLocation (Group001) from App1 from device 1", common.sendLocation, {1, "DISALLOWED"})
runner.Step("Disallowed Show (Group002) from App1 from device 2", common.show, {2, "DISALLOWED"})

runner.Step("Allow group Group001 and Group002 for App1 on device 1", common.funcGroupConsentForApp,
    {{{name = "ConsentTwoGroups", allowed = true}}, 1})
runner.Step("Successful SendLocation (Group001) from App1 from device 1", common.sendLocation, {1, "SUCCESS"})
runner.Step("Disallowed Show (Group002) from App1 from device 2", common.show, {2, "DISALLOWED"})

runner.Step("Disallow group Group001 and Group002 for App1 on device 1", common.funcGroupConsentForApp,
    {{{name = "ConsentTwoGroups", allowed = false}}, 1})
runner.Step("Allow group Group001 and Group002 for App1 on device 2", common.funcGroupConsentForApp,
    {{{name = "ConsentTwoGroups", allowed = true}}, 2})
runner.Step("User disallowed SendLocation (Group001) from App1 from device 1", common.sendLocation, {1, "USER_DISALLOWED"})
runner.Step("Successful Show  (Group002) from App1 from device 2", common.show, {2, "SUCCESS"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
