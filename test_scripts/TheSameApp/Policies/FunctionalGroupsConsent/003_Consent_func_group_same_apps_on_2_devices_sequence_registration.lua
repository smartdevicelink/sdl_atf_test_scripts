---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- User consent for functional groups of two consented mobile devices with the same mobile applications registered
-- sequentially
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 is connected to SDL and is consented
-- 3) RPC SendLocation exists only in Group001 according policies and requires user consent ConsentGroup001
-- 4) Application App1 is registered on Mobile №1
--
-- Steps:
-- 1) User allows ConsentGroup001 for App1 on Mobile №1.
-- Application App1 from Mobile №1 sends to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №1
-- 2) Connect Mobile №2 to SDL and consent it.
-- Register application App1 on Mobile №2.
-- Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №1
--    SDL sends SendLocation(resultCode = DISALLOWED) response to Mobile №2
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
    user_consent_prompt = "ConsentGroup001",
    rpcs = {
      SendLocation = {
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
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["Group001"] = ptFuncGroup.Group001

  pt.app_policies[appParams[1].fullAppID] =
      common.cloneTable(pt.app_policies["default"])
  pt.app_policies[appParams[1].fullAppID].groups = {"Base-4", "Group001"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect mobile device 1 to SDL", common.connectMobDevice, {1, devices[1], true})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})

runner.Title("Test")
runner.Step("Allow group Group001 for App1 on Device 1", common.funcGroupConsentForApp,
    {{{name = "ConsentGroup001", allowed = true}}, 1})
runner.Step("Successful SendLocation from App1 from device 1", common.sendLocation, {1, "SUCCESS"})

runner.Step("Connect mobile device 2 to SDL", common.connectMobDevice, {2, devices[2], true})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Successful SendLocation from App1 from device 1", common.sendLocation, {1, "SUCCESS"})
runner.Step("Disallowed SendLocation from App1 from device 2", common.sendLocation, {2, "DISALLOWED"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
