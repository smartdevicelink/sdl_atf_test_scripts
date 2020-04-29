---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Verify that the SDL responds with success:false, "INVALID_DATA" on request with value in out of range for Array type,
--  minlength and maxlength for array element
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends the SetAppProperties request with out of range for Array type
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local boundaryNicknames = {
  minsize = 0,
  maxsize = 100,
  minLength = 0,
  maxLength = 100
}

local stringMinLength = string.rep("a", boundaryNicknames.minLength)
local stringMaxLength = string.rep("a", boundaryNicknames.maxLength)

local arrayOutOfRangeMaxSizeMinLengthNicknames = {}
local arrayOutOfRangeMaxSizeMaxLengthNicknames = {}

for i = 1, boundaryNicknames.maxsize + 1 do
  arrayOutOfRangeMaxSizeMinLengthNicknames[i] = stringMinLength
  arrayOutOfRangeMaxSizeMaxLengthNicknames[i] = stringMaxLength
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request: nicknames out of maxsize, minlength", common.errorRPCprocessingUpdate,
  { "SetAppProperties", common.resultCode.INVALID_DATA, "nicknames", arrayOutOfRangeMaxSizeMinLengthNicknames })
common.Step("GetAppProperties request to check set values", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })
common.Step("SetAppProperties request: nicknames out of maxsize, maxlength", common.errorRPCprocessingUpdate,
  { "SetAppProperties", common.resultCode.INVALID_DATA, "nicknames", arrayOutOfRangeMaxSizeMaxLengthNicknames })
common.Step("GetAppProperties request to check set values", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.DATA_NOT_AVAILABLE })
common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
