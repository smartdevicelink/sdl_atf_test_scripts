---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that defined AppProperties are stored through ignition cycles
--
-- Precondition:
-- 1. SDL and HMI are started

-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. Ignition off is performed
-- 3. Ignition on is performed
-- 4. HMI sends BC.GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with application properties of the policyAppID to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Clear HMICapabilitiesCacheFile parameter in INI file",
  common.setSDLIniParameter, {"HMICapabilitiesCacheFile", ""})
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request for policyAppID", common.setAppProperties, { common.defaultAppProperties })
common.Step("IgnitionOff", common.ignitionOff)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
common.Step("GetAppProperties request: with policyAppID", common.getAppProperties,
  { common.defaultAppProperties })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
