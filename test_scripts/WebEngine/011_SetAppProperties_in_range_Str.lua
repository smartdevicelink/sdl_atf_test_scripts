---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the SetAppProperties request with the minlength and maxlength for String type from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with the application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends the GetAppProperties request with policyAppID to SDL
--  a. SDL sends successful response with application properties of the policyAppID to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local strInRangeAppProperties = {
  nicknames = {
    stringMinMaxLength = { "", string.rep("a", 100)}
  },
  policyAppID = {
    stringMinLength = string.rep("a", 1),
    stringMaxLength = string.rep("a", 100)
  },
  authToken = {
    stringMinLength = string.rep("a", 1),
    stringMaxLength = string.rep("a", 65535)
  },
  transportType = {
    stringMinLength = string.rep("a", 1),
    stringMaxLength = string.rep("a", 100)
  },
  endpoint = {
    stringMinLength = string.rep("a", 1),
    stringMaxLength = string.rep("a", 100)
  }
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
for parameter, range  in pairs(strInRangeAppProperties) do
  for length, value  in pairs(range) do
    common.Step("SetAppProperties request parameter "  .. parameter .. " to " .. length,
      common.setAppProperties, { common.updateDefaultAppProperties(parameter, value) })
    common.Step("GetAppProperties request to check set values", common.getAppProperties,
      { common.updateDefaultAppProperties(parameter, value) })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
