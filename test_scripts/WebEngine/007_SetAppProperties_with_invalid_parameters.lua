---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "INVALID_DATA" on request with invalid parameters type
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with invalid parameters type
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
-- 2. HMI sends BC.GetAppProperties request with wrong policyAppID to SDL
--  a.  SDL sends response with success:false, "DATA_NOT_AVAILABLE" to HMI
-- 3. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 4. HMI sends BC.SetAppProperties request with invalid parameters type
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
-- 5. HMI sends BC.GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with application properties of the policyAppID to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local invalidAppPropType = {
  -- value type is updated to string instead of array
  nicknames = "Test Web Application invalidType",
  -- value type is updated to integer instead of string
  policyAppID = 5,
  -- value type is updated to string instead of boolean
  enabled = "false",
  -- value type is updated to integer instead of string
  authToken = 12345,
  -- value type is updated to integer instead of string
  transportType = 123,
  -- value type is updated to array instead of individual value ("BOTH", "CLOUD", "MOBILE")
  hybridAppPreference = {"CLOUD", "MOBILE"},
  -- value type is updated to integer instead of string
  endpoint = 8080
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
for parameter, value  in pairs(invalidAppPropType) do
  common.Step("SetAppProperties request: invalid parameter type  " .. parameter .. " with ".. tostring(value),
    common.errorRPCprocessingUpdate, { "SetAppProperties", common.resultCode.INVALID_DATA, parameter, value })
  common.Step("GetAppProperties request: with policyAppID",
    common.errorRPCprocessing, { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })
end

common.Step("SetAppProperties request for policyAppID", common.setAppProperties, { common.defaultAppProperties })
for parameter, value  in pairs(invalidAppPropType) do
  common.Step("SetAppProperties request: invalid parameter type  " .. parameter .. " with ".. tostring(value),
    common.errorRPCprocessingUpdate, { "SetAppProperties", common.resultCode.INVALID_DATA, parameter, value })
  common.Step("GetAppProperties request: with policyAppID", common.getAppProperties, { common.defaultAppProperties })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
