---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2957
---------------------------------------------------------------------------------------------------
-- Description: SDL has to proceed with 'OnAppPermissionConsent' notification from HMI in case:
--  - it sends with or without AppId
--  - regardless of preceding 'GetListOfPermissions' request/response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile is connected to SDL and is consented
-- 3) RPC Show exists only in 'Group001' according policies and requires user consent
-- 4) Application App1 is registered
--    Application App2 is registered
--
-- Steps:
-- 1) User allows 'Group001' for all applications (HMI sends SDL.OnAppPermissionConsent without 'appID')
-- 2) Each of 2 apps sends valid Show RPC request
-- SDL does:
--  - proceed with Show request successfully for both apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = {"EXTERNAL_PROPRIETARY" }}}

--[[ Local Variables ]]
local testCases = {
  [01] = { getLOP = nil, onAPC = nil, appExpRpc = { [1] = "DISALLOWED", [2] = "DISALLOWED" }},

  [02] = { getLOP = { appId = nil }, onAPC = nil, appExpRpc = { [1] = "DISALLOWED", [2] = "DISALLOWED" }},
  [03] = { getLOP = { appId = 1 },   onAPC = nil, appExpRpc = { [1] = "DISALLOWED", [2] = "DISALLOWED" }},
  [04] = { getLOP = { appId = 2 },   onAPC = nil, appExpRpc = { [1] = "DISALLOWED", [2] = "DISALLOWED" }},

  [05] = { getLOP = nil, onAPC = { appId = nil }, appExpRpc = { [1] = "SUCCESS",    [2] = "SUCCESS"    }},
  [06] = { getLOP = nil, onAPC = { appId = 1 },   appExpRpc = { [1] = "SUCCESS",    [2] = "DISALLOWED" }},
  [07] = { getLOP = nil, onAPC = { appId = 2 },   appExpRpc = { [1] = "DISALLOWED", [2] = "SUCCESS"    }},

  [08] = { getLOP = { appId = nil }, onAPC = { appId = nil }, appExpRpc = { [1] = "SUCCESS",    [2] = "SUCCESS"    }},
  [09] = { getLOP = { appId = nil }, onAPC = { appId = 1 },   appExpRpc = { [1] = "SUCCESS",    [2] = "DISALLOWED" }},
  [10] = { getLOP = { appId = nil }, onAPC = { appId = 2 },   appExpRpc = { [1] = "DISALLOWED", [2] = "SUCCESS"    }},

  [11] = { getLOP = { appId = 1 }, onAPC = { appId = nil }, appExpRpc = { [1] = "SUCCESS",    [2] = "SUCCESS"      }},
  [12] = { getLOP = { appId = 1 }, onAPC = { appId = 1 },   appExpRpc = { [1] = "SUCCESS",    [2] = "DISALLOWED"   }},
  [13] = { getLOP = { appId = 1 }, onAPC = { appId = 2 },   appExpRpc = { [1] = "DISALLOWED", [2] = "SUCCESS"      }},

  [14] = { getLOP = { appId = 2 }, onAPC = { appId = nil }, appExpRpc = { [1] = "SUCCESS",    [2] = "SUCCESS"      }},
  [15] = { getLOP = { appId = 2 }, onAPC = { appId = 1 },   appExpRpc = { [1] = "SUCCESS",    [2] = "DISALLOWED"   }},
  [16] = { getLOP = { appId = 2 }, onAPC = { appId = 2 },   appExpRpc = { [1] = "DISALLOWED", [2] = "SUCCESS"      }}
}

--[[ Local Functions ]]
local function updatePreloadedPT()
  local preloadedTable = common.sdl.getPreloadedPT()
  local pt = preloadedTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null
  local ptFuncGroup = {
    Group001 = {
      user_consent_prompt = "ConsentGroup001",
      rpcs = {
        Show = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        }
      }
    }
  }
  for funcGroupName in pairs(pt.functional_groupings) do
    if type(pt.functional_groupings[funcGroupName].rpcs) == "table" then
      pt.functional_groupings[funcGroupName].rpcs["Show"] = nil
    end
  end
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null
  pt.functional_groupings["Group001"] = ptFuncGroup.Group001
  local appPolicies = utils.cloneTable(pt.app_policies["default"])
  appPolicies.groups = { "Base-4", "Group001" }
  pt.app_policies[common.app.getParams(1).fullAppID] = appPolicies
  pt.app_policies[common.app.getParams(2).fullAppID] = utils.cloneTable(appPolicies)
  common.sdl.setPreloadedPT(preloadedTable)
end

local function sendGetListOfPermissions(pAppId)
  local hmiAppID = nil
  if pAppId then hmiAppID = common.app.getHMIId(pAppId) end
  local corId = common.hmi.getConnection():SendRequest("SDL.GetListOfPermissions", { appID = hmiAppID})
  common.hmi.getConnection():ExpectResponse(corId)
end

local function sendOnAppPermissionConsent(pAppId)
  local hmiAppID = nil
  if pAppId then hmiAppID = common.app.getHMIId(pAppId) end
  common.hmi.getConnection():SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmiAppID,
      source = "GUI",
      consentedFunctions = { { allowed = true, id = 1423208483, name = "ConsentGroup001"} }
    })
  common.mobile.getSession(pAppId):ExpectNotification("OnPermissionsChange")
end

local function show(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("Show", { mediaClock = "00:00:01", mainField1 = "Show1" })
  if pResultCode == "SUCCESS" then
    common.hmi.getConnection():ExpectRequest("UI.Show")
    :Do(function(_,data)
        common.hmi.getConnection():SendResponse(data.id, "UI.Show", "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, { success = isSuccess, resultCode = pResultCode})
end

--[[ Scenario ]]

for i, tc in utils.spairs(testCases) do
  runner.Title("Test case "..i)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Prepare preloaded PT", updatePreloadedPT)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register App1", common.app.registerNoPTU, { 1 })
  runner.Step("Register App2", common.app.registerNoPTU, { 2 })

  runner.Title("Test")
  if tc.getLOP then
    runner.Step("GetListOfPermissions", sendGetListOfPermissions, { tc.getLOP.appId })
  end
  if tc.onAPC then
    runner.Step("Allow group Group001 for all Apps", sendOnAppPermissionConsent, { tc.onAPC.appId })
  end
  runner.Step("Successful Show from App1", show, { 1, tc.appExpRpc[1] })
  runner.Step("Successful Show from App2", show, { 2, tc.appExpRpc[2] })

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
