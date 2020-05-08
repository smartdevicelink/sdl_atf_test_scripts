---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Check "count_of_rpcs_sent_in_hmi_none" counter in case two consented mobile devices
-- with the same mobile applications registered (the same appName but different appID)
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) RPC AddCommand exists only in AddCommandGroup according PT
--    RPC AddSubMenu does not exists in any functional group according PT
-- 4) Application App1 (appID: "0019", appName: "Tester") is registered on Mobile №1 and has not functional group
--     AddCommandGroup assigned in PT
--    Application App2 (appID: "0015", appName: "Tester") is registered on Mobile №2 and has functional group
--     AddCommandGroup assigned in PT
-- 5) Value of counter "count_of_rpcs_sent_in_hmi_none" for appID: "0019" is 0 in PT
--    Value of counter "count_of_rpcs_sent_in_hmi_none" for appID: "0015" is 0 in PT
--
-- Steps:
-- 1) Application App1 from Mobile №1 is in NONE HMI level and sends valid AddCommand RPC request to SDL
--   Check:
--   SDL sends AddCommand (resultCode = DISALLOWED) response to Mobile №1
--   SDL increments counter "count_of_rpcs_sent_in_hmi_none" for applicaion App1
--    (value of the counter become 1 for appID: "0019" in PT)
-- 2) Application App2 from Mobile №2 is in NONE HMI level and sends valid AddCommand RPC request to SDL
--   Check:
--   SDL sends AddCommand (resultCode = SUCCESS) response to Mobile №2
--   SDL does not increments counter "count_of_rpcs_sent_in_hmi_none" for applicaion App2
--    (value of the counter remains 0 for appID: "0015" in PT)
-- 3) Application App1 from Mobile №1 is in NONE HMI level and sends valid AddSubMenu RPC request to SDL
--   Check:
--   SDL sends AddSubMenu (resultCode = DISALLOWED) response to Mobile №1
--   SDL increments counter "count_of_rpcs_sent_in_hmi_none" for applicaion App1
--    (value of the counter become 2 for appID: "0019" in PT)
-- 4) Application App2 from Mobile №2 is in NONE HMI level and sends valid AddSubMenu RPC request to SDL
--   Check:
--   SDL sends AddSubMenu (resultCode = DISALLOWED) response to Mobile №2
--   SDL increments counter "count_of_rpcs_sent_in_hmi_none" for applicaion App2
--    (value of the counter become 1 for appID: "0019" in PT)
--
-- The script checks values of "count_of_rpcs_sent_in_hmi_none" counters for both applications via PTS
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
    appName = "Tester",
    isMediaApplication = true,
    appHMIType = { "DEFAULT" },
    appID = "0019",
    fullAppID = "0000019"
  },
  [2] = {
    appName = "Tester",
    isMediaApplication = true,
    appHMIType = { "DEFAULT" },
    appID = "0015",
    fullAppID = "0000015"
  }
}

local ptFuncGroup = {
  AddCommandGroup = {
    rpcs = {
      AddCommand = {
        hmi_levels = {"FULL", "LIMITED", "BACKGROUND", "NONE"}
      }
    }
  }
}

local contentData = {
  [1] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "VRVR" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "VRVR" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 300, menuName = "NewerSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 300, menuName = "NewerSubMenu" }}
    }
  },
  [2] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "vrCo" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "vrCo" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 200, menuName = "JustSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 200, menuName = "JustSubMenu" }}
    }
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table

  for funcGroupName in pairs(pt.functional_groupings) do
    if type(pt.functional_groupings[funcGroupName].rpcs) == "table" then
      pt.functional_groupings[funcGroupName].rpcs["AddCommand"] = nil
      pt.functional_groupings[funcGroupName].rpcs["AddSubMenu"] = nil
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["AddCommandGroup"] = ptFuncGroup.AddCommandGroup

  for i in pairs(common.mobile.getApps()) do
    pt.app_policies[appParams[i].fullAppID] = common.cloneTable(pt.app_policies["default"])
    if i == 2 then table.insert(pt.app_policies[appParams[i].fullAppID].groups, "AddCommandGroup") end
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Allow SDL for Device 1", common.mobile.allowSDL, {1})
runner.Step("Allow SDL for Device 2", common.mobile.allowSDL, {2})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1, true})
runner.Step("PTU", common.ptu.policyTableUpdate, {modificationOfPreloadedPT})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2, true})
runner.Step("PTU", common.ptu.policyTableUpdate, {modificationOfPreloadedPT})

runner.Title("Test")
runner.Step("Disallowed AddCommand in NONE from App1 from device 1", common.addCommand,
    {1, contentData[1].addCommand, "DISALLOWED"})
runner.Step("Successful AddCommand in NONE from App2 from device 2", common.addCommand,
    {2, contentData[2].addCommand, "SUCCESS"})
runner.Step("Disallowed AddSubMenu in NONE from App1 from device 1", common.addSubMenu,
    {1, contentData[1].addSubMenu, "DISALLOWED"})
runner.Step("Disallowed AddSubMenu in NONE from App2 from device 2", common.addSubMenu,
    {2, contentData[2].addSubMenu, "DISALLOWED"})
runner.Step("Trigger PTU to get PTS", common.triggerPTUtoGetPTS)
runner.Step("Check count_of_rpcs_sent_in_hmi_none in PTS for App1", common.checkCounter,
    {appParams[1].fullAppID, "count_of_rpcs_sent_in_hmi_none", 2})
runner.Step("Check count_of_rpcs_sent_in_hmi_none in PTS for App2", common.checkCounter,
    {appParams[2].fullAppID, "count_of_rpcs_sent_in_hmi_none", 1})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
