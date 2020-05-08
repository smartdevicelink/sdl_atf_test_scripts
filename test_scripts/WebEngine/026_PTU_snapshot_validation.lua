---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that PTU is performed after BC.SetAppProperties request with new application properties of the policyAppID
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with new application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
--  b. PTU is triggered, SDL sends UPDATE_NEDDED to HMI
--  с. PTS is created with application properties of the policyAppID
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local  appStoreConfig = {
  keep_context = false,
  steal_focus = false,
  priority = "NONE",
  default_hmi = "NONE",
  groups = { "Base-4" }
}

local appProperties = {
  nicknames = { "Test Web Application_21", "Test Web Application_22" },
  policyAppID = "0000002",
  enabled = true,
  authToken = "ABCD12345",
  transportType = "WS",
  hybridAppPreference = "CLOUD"
}

local appPropExpected = {
  nicknames = { "Test Web Application_21", "Test Web Application_22" },
  auth_token = "ABCD12345",
  cloud_transport_type = "WS",
  enabled = "true",
  hybrid_app_preference = "CLOUD"
}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams().fullAppID] = appStoreConfig;
end

local function setAppProperties(pData)
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.SetAppProperties",
    { properties = pData })
  common.getHMIConnection():ExpectResponse(corId,
    { result = { code = 0 }})
  common.isPTUStarted()
  common.wait(1000)
end

local function verifyAppProperties()
  local snp_tbl = common.ptsTable()
  local app_id = appProperties.policyAppID
  local result = {}
  local msg = ""

  result.nicknames = snp_tbl.policy_table.app_policies[app_id].nicknames
  if not common.isTableEqual(result.nicknames, appPropExpected.nicknames) then
    msg = msg .. "Incorrect nicknames\n" ..
      " Expected: " .. common.tableToString(appPropExpected.nicknames) .. "\n" ..
      " Actual: " .. common.tableToString(result.nicknames) .. "\n"
  end

  result.auth_token = snp_tbl.policy_table.app_policies[app_id].auth_token
  if not (result.auth_token == appPropExpected.auth_token) then
    msg = msg .. "Incorrect auth token value\n" ..
      " Expected: " .. appPropExpected.auth_token .. "\n" ..
      " Actual: " .. result.auth_token .. "\n"
  end

  result.cloud_transport_type = snp_tbl.policy_table.app_policies[app_id].cloud_transport_type
  if not (result.cloud_transport_type == appPropExpected.cloud_transport_type) then
    msg = msg ..     "Incorrect cloud_transport_type value\n" ..
      " Expected: " .. appPropExpected.cloud_transport_type .. "\n" ..
      " Actual: " .. result.cloud_transport_type .. "\n"
  end

  result.enabled = tostring(snp_tbl.policy_table.app_policies[app_id].enabled)
  if not (result.enabled == appPropExpected.enabled) then
    msg = msg .. "Incorrect enabled value\n"..
      " Expected: " .. appPropExpected.enabled .. "\n" ..
      " Actual: " .. result.enabled .. "\n"
  end

  result.hybrid_app_preference = snp_tbl.policy_table.app_policies[app_id].hybrid_app_preference
  if not (result.hybrid_app_preference == appPropExpected.hybrid_app_preference) then
    msg = msg .. "Incorrect hybrid_app_preference value\n" ..
      " Expected: " .. appPropExpected.hybrid_app_preference .. "\n" ..
      " Actual: " .. result.hybrid_app_preference .. "\n"
  end

  if string.len(msg) > 0 then
    common.failTestStep("PTS is incorrect\n".. msg)
  end
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { PTUfunc })
common.Step("SetAppProperties request to check: PTU is triggered", setAppProperties, { appProperties })
common.Step("Verify app properties via PTS", verifyAppProperties)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
