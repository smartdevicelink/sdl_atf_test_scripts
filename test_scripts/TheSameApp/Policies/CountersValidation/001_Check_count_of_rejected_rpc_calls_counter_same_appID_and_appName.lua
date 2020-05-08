---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Check "count_of_rejected_rpc_calls" counter in case two consented mobile devices
-- with the same mobile applications registered (the same appID and appName)
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) RPC AddCommand exists only in AddCommandGroup according PT
-- 4) Application App1 (appID: "0008", appName: "Test App") is registered on Mobile №1 and Mobile №2
--  (two copies of one application)
-- 5) Value of counter "count_of_rejected_rpc_calls" is 0 for appID: "0008" is 0 in PT
--
-- Steps:
-- 1) Application App1 from Mobile №1 is activated and sends valid AddCommand RPC request to SDL
--   Check:
--   SDL sends AddCommand (resultCode = DISALLOWED) response to Mobile №1
--   SDL increments counter "count_of_rejected_rpc_calls" for applicaion App1
--    (value of the counter become 1 for appID: "0008" in PT)
-- 2) Application App1 from Mobile №2 is activated and sends valid AddCommand RPC request to SDL
--   Check:
--   SDL sends AddCommand (resultCode = DISALLOWED) response to Mobile №2
--   SDL increments counter "count_of_rejected_rpc_calls" for applicaion App1
--    (value of the counter become 2 for appID: "0008" in PT)
--
-- The script checks value of "count_of_rejected_rpc_calls" counter via PTS
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
    appName = "Test App",
    isMediaApplication = true,
    appHMIType = { "NAVIGATION" },
    appID = "0008",
    fullAppID = "0000008"
  }
}

local ptFuncGroup = {
  AddCommandGroup = {
    rpcs = {
      AddCommand = {
        hmi_levels = {"FULL", "LIMITED"}
      }
    }
  }
}

local contentData = {
  [1] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "OnlyVR" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "OnlyVR" }}
    }
  },
  [2] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "vrCommand" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "vrCommand" }}
    }
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table

  for funcGroupName in pairs(pt.functional_groupings) do
    if type(pt.functional_groupings[funcGroupName].rpcs) == "table" then
      pt.functional_groupings[funcGroupName].rpcs["AddCommand"] = nil
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["AddCommandGroup"] = ptFuncGroup.AddCommandGroup

  pt.app_policies[appParams[1].fullAppID] =
      common.cloneTable(pt.app_policies["default"])
  pt.app_policies[appParams[1].fullAppID].groups = {"Base-4"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Allow SDL for Device 1", common.mobile.allowSDL, {1})
runner.Step("Allow SDL for Device 2", common.mobile.allowSDL, {2})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1, true})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2, false})
runner.Step("PTU", common.ptu.policyTableUpdate, {modificationOfPreloadedPT})

runner.Title("Test")
runner.Step("Activate App1 from device 1", common.app.activate, {1})
runner.Step("Disallowed AddCommand from App1 from device 1", common.addCommand,
    {1, contentData[1].addCommand, "DISALLOWED"})
runner.Step("Activate App2 from device 2", common.app.activate, {2})
runner.Step("Disallowed AddCommand from App1 from device 2", common.addCommand,
    {2, contentData[2].addCommand, "DISALLOWED"})
runner.Step("Trigger PTU to get PTS", common.triggerPTUtoGetPTS)
runner.Step("Check count_of_rejected_rpc_calls in PTS", common.checkCounter,
    {appParams[1].fullAppID, "count_of_rejected_rpc_calls", 2})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
