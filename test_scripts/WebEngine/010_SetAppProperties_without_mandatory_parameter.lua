---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "INVALID_DATA" to request without mandatory parameters
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties (without mandatory parameters)
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
-- 2. HMI sends BC.GetAppProperties request with wrong policyAppID to SDL
--  a.  SDL sends response with success:false, "DATA_NOT_AVAILABLE" to HMI
-- 3. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 4. HMI sends BC.GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with application properties of the policyAppID to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appPropWOMandatory = {
  properties = {
    -- policyAppId is missed
    nicknames = { "Test Web Application_3" },
    enabled = false,
    authToken = "ABCD",
    transportType = "WSS",
    hybridAppPreference = "BOTH",
    endpoint = "wss://127.0.0.1:8080/"
  }
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request: mandatory parameter policyAppID is missing", common.errorRPCprocessing,
  { "SetAppProperties", common.resultCode.INVALID_DATA, appPropWOMandatory })
common.Step("GetAppProperties request to check set values", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })
common.Step("SetAppProperties request: mandatory parameter properties is missing", common.errorRPCprocessing,
  { "SetAppProperties", common.resultCode.INVALID_DATA })
common.Step("GetAppProperties request to check set values", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })

common.Step("SetAppProperties request for policyAppID", common.setAppProperties, { common.defaultAppProperties })
common.Step("SetAppProperties request: mandatory parameter policyAppID is missing", common.errorRPCprocessing,
  { "SetAppProperties", common.resultCode.INVALID_DATA, appPropWOMandatory })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.defaultAppProperties })
common.Step("SetAppProperties request: mandatory parameter 'properties' is missing", common.errorRPCprocessing,
  { "SetAppProperties", common.resultCode.INVALID_DATA })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.defaultAppProperties })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
