---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "INVALID_DATA" on request with value
--  in out of range for String type
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends the GetAppProperties request with out of range for String type
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local stringOutOfMinLengthPolicyAppID = string.rep("a", 0)
local stringOutOfMaxLengthPolicyAppID = string.rep("a", 101)

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("GetAppProperties request: policyAppID to minLenght", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.INVALID_DATA, { policyAppID = stringOutOfMinLengthPolicyAppID }})
common.Step("GetAppProperties request: policyAppID to maxLenght", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.INVALID_DATA, { policyAppID = stringOutOfMaxLengthPolicyAppID }})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
