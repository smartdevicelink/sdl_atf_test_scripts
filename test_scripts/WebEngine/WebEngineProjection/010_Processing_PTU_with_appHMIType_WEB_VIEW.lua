---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Processing PTU with AppHMIType WEB_VIEW
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. PTU is performed, the update contains App1 properties with WEB_VIEW HMI type
-- 2. Application registers with WEB_VIEW HMI type
--  a. SDL successfully registers application with WEB_VIEW HMI type (resultCode SUCCESS, success:"true")
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
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId1).fullAppID] =
    common.getAppDataForPTU(appSessionId1)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start)

common.Title("Test")
common.Step("Register App2, PTU is triggered ", common.registerApp,{ appSessionId2 })
common.Step("PTU contains App1 with AppHMIType WEB_VIEW", common.policyTableUpdate, { ptUpdate })
common.Step("Register App1 with AppHMIType WEB_VIEW", common.registerAppWOPTU,{ appSessionId1 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
