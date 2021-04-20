---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "DATA_NOT_AVAILABLE" on GetAppProperties request
--  with wrong policyAppID
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends BC.GetAppProperties request with wrong policyAppID to SDL
--  a.  SDL sends response with success:false, "DATA_NOT_AVAILABLE" to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("GetAppProperties request: wrong policyAppID", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE, { policyAppID = "WrongPolicyAppID" }})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
