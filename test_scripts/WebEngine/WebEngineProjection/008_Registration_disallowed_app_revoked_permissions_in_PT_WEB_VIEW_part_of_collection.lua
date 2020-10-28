---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be disallowed to register with HMI type collection {"MEDIA", "WEB_VIEW"}
-- when application has revoked permissions in policy table
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
-- 3. PT contains record for App1 with null permissions
--
-- Sequence:
-- 1. Application1 tries to register with WEB_VIEW appHMIType
--  a. SDL rejects registration of application (resultCode: "DISALLOWED", success: false)
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultMobileAdapterType = "WS"

-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "MEDIA", "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Local Functions ]]
local function updatePreloadedPT(pAppId)
  local preloadedTable = common.getPreloadedPT()
  local appId = config["application" .. pAppId].registerAppInterfaceParams.fullAppID
  preloadedTable.policy_table.app_policies[appId] = common.null
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  common.setPreloadedPT(preloadedTable)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add AppHMIType to preloaded policy table", updatePreloadedPT,
  { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect Mobile", common.start)

common.Title("Test")
common.Step("Register App, PT does not contain WEB_VIEW AppHMIType", common.expectRegistrationDisallowed,
  { appSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
