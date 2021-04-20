---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the SetAppProperties request with only mandatory parameters from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties (only mandatory parameters,
-- missing some not mandatory parameters ) of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends BC.GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with appropriate application properties of the policyAppID to HMI
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appPropMandatory = {
  policyAppID = "0000001"
}

local appPropMandatoryResponse = {
  policyAppID = "0000001",
  enabled = false,
  nicknames = common.EMPTY_ARRAY
}

local appPropMissingSomeParam = {
  policyAppID = "0000001",
  enabled = false,
  nicknames = common.EMPTY_ARRAY,
  authToken = "ABCD12345",
  transportType = "WS"
  -- hybridAppPreference is missed
  -- endpoint is missed
}

local appPropUpdateParam = {
  policyAppID = "0000001",
  nicknames = { "Test Web Application_1", "Test Web Application_2" },
  hybridAppPreference = "CLOUD",
  endpoint = "ws://127.0.0.1:8080/",
  enabled = true
  -- authToken is missed
  -- transportType is missed
}

local appPropUpdateParamResponse = {
  nicknames = { "Test Web Application_1", "Test Web Application_2" },
  policyAppID = "0000001",
  enabled = true,
  hybridAppPreference = "CLOUD",
  endpoint = "ws://127.0.0.1:8080/",
  authToken = "ABCD12345",
  transportType = "WS"
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request: mandatory parameters only", common.setAppProperties, { appPropMandatory })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { appPropMandatoryResponse })
common.Step("SetAppProperties request: one of parameters is missing", common.setAppProperties,
  { appPropMissingSomeParam })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { appPropMissingSomeParam })
common.Step("SetAppProperties request: update some parameter", common.setAppProperties, { appPropUpdateParam })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { appPropUpdateParamResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
