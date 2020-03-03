---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2966
--
-- Description:
-- SDL incorrectly assigned default permissions for an app if they were defined in preloaded
-- Steps to reproduce:
-- 1) Update SDL preloaded_pt file and add default permissions
-- 2) SDL and HMI are started
-- 3) App is registered
-- SDL does:
-- - a) SDL->HMI: OnAppRegistered(params)
-- - b) SDL->App: SUCCESS, success:"true":RegisterAppInterface()
-- - c) SDL->App: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
-- - d) SDL->App: OnPermissionsChange(permissionItem)
-- - e) SDL->App: OnSystemRequest(LOCK_SCREEN_ICON_URL)
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  pt.policy_table.app_policies[common.getConfigAppParams().fullAppID] = "default"
  common.sdl.setPreloadedPT(pt)
end

local function registerAppWOPTU()
  local mobileSession = common.getMobileSession(1)
  mobileSession:StartService(7)
  :Do(function()
    local corId = mobileSession:SendRPC("RegisterAppInterface", common.app.getParams(1))
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      mobileSession:ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      mobileSession:ExpectNotification("OnPermissionsChange")
      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Add app to SDL preloaded", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI", registerAppWOPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
