---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "INVALID_DATA" on request with value in out of range for String type
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends the SetAppProperties request with out of range for String type
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local strOutOfRangeAppProperties = {
  nicknames = {
    stringOutOfMaxLength = string.rep("a", 101)
  },
  policyAppID = {
    stringOutOfMinLength = string.rep("a", 0),
    stringOutOfMaxLength = string.rep("a", 101)
  },
  authToken = {
    stringOutOfMinLength = string.rep("a", 0),
    stringOutOfMaxLength = string.rep("a", 65536)
  },
  transportType = {
    stringOutOfMinLength = string.rep("a", 0),
    stringOutOfMaxLength = string.rep("a", 101)
  },
  endpoint = {
    stringOutOfMinLength = string.rep("a", 0),
    stringOutOfMaxLength = string.rep("a", 65536)
  }
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
for parameter, range  in pairs(strOutOfRangeAppProperties) do
  for length, value  in pairs(range) do
    common.Step("SetAppProperties request parameter "  .. parameter .. " to " .. length,
      common.errorRPCprocessingUpdate, { "SetAppProperties", common.resultCode.INVALID_DATA, parameter, value })
    common.Step("GetAppProperties request to check set values", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })
  end
end
common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
