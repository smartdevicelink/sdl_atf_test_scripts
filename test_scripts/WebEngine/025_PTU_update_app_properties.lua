---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Applying of the update application properties for policyAppID from PTU
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. PTU is performed, the update contains app properties of the policyAppID
-- 2. HMI sends the GetAppProperties request with appropriate policyAppID to SDL
--  a. SDL sends successful response with application properties data to HMI
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appPropPTU = {
  nicknames = { "Test Web Application_11", "Test Web Application_12" },
  enabled = true,
  auth_token = "ABCD1111",
  cloud_transport_type = "WS",
  hybrid_app_preference = "CLOUD",
  keep_context = false,
  steal_focus = false,
  priority = "NONE",
  default_hmi = "NONE",
  groups = { "Base-4" }
}

local appPropPTUExpect = {
  nicknames = { "Test Web Application_11", "Test Web Application_12" },
  policyAppID = "0000002",
  enabled = true,
  authToken = "ABCD1111",
  transportType = "WS",
  hybridAppPreference = "CLOUD"
}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = appPropPTU;
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("RAI", common.registerApp)
common.Step("PTU with app properties", common.policyTableUpdate, { PTUfunc })
common.Step("GetAppProperties request to check PTU", common.getAppProperties,
  { appPropPTUExpect })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
