---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that PTS is created with appHmiType WEB_VIEW
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WEB_VIEW appHMITypes is allowed by policy for application (App1)
-- 3. WebEngine App1 with WEB_VIEW HMI type is registered
--
-- Sequence:
-- 1. App2 registers with NAVIGATION HMI type
--   a. PTU is triggered, SDL sends UPDATE_NEEDED to HMI
--   b. PTS is created with AppHMIType WEB_VIEW for App1 and other mandatory pts
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local appHMIType = { "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Local Functions ]]
local function verifyAppHMITypeInPTSnapshot()
  local ptsTable = common.ptsTable()
  local appHMITypeApp1 = ptsTable.policy_table.app_policies[common.getParams(appSessionId1).fullAppID].AppHMIType
  if not ptsTable then
    common.failTestStep("Policy table snapshot was not created")
  elseif not common.isTableEqual(appHMITypeApp1, appHMIType) then
    common.failTestStep("Incorrect AppHMIType value\n" ..
      " Expected: " .. common.tableToString(appHMIType) .. "\n" ..
      " Actual: " .. common.tableToString(appHMITypeApp1) .. "\n" )
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add App1 with AppHMIType WEB_VIEW to preloaded policy table", common.updatePreloadedPT,
  { appSessionId1, appHMIType })
common.Step("Start SDL, HMI", common.start)
common.Step("Register App1 with AppHMIType WEB_VIEW", common.registerAppWOPTU,{ appSessionId1 })

common.Title("Test")
common.Step("Register App2, PTU is triggered ", common.registerApp,{ appSessionId2 })
common.Step("Check that PTS contains AppHMIType WEB_VIEW for App1", verifyAppHMITypeInPTSnapshot)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
