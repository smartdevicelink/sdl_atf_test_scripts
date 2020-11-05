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
--  с. PTS is created with application properties of the policyAppID and other mandatory pts
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{ extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" }}}

--[[ Local Variables ]]
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
  enabled = true,
  hybrid_app_preference = "CLOUD"
}

--[[ Local Functions ]]
local function setAppProperties(pData)
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.SetAppProperties",
    { properties = pData })
  common.getHMIConnection():ExpectResponse(corId,
    { result = { code = 0 }})
  common.isPTUStarted()
  common.wait(1000)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request to check: PTU is triggered", setAppProperties, { appProperties })
common.Step("Validate PTS", common.verifyPTSnapshot, { appProperties, appPropExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
