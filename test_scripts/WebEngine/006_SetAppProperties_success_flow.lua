---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the SetAppProperties request from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends BC.GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with application properties of the policyAppID to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local propTypes = {
  hybridAppPreference = { "MOBILE", "CLOUD", "BOTH" },
  enabled = { true, false }
}

-- [[ Scenario ]]
for parameter, pValues in pairs(propTypes) do
  common.Title("TC processing [" ..  parameter .."] parameter")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

  common.Title("Test")
  for _, value  in pairs(pValues) do
    common.Step("SetAppProperties request parameter " .. parameter .. " with ".. tostring(value),
      common.setAppProperties, { common.updateDefaultAppProperties(parameter, value) })
    common.Step("GetAppProperties request to check set values", common.getAppProperties,
      { common.updateDefaultAppProperties(parameter, value) })
  end

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
