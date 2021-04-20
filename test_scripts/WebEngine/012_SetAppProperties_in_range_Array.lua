---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the SetAppProperties request with the minsize and maxsize value for Array type,
--  minlength and maxlength for array element
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
local boundaryNicknames = {
  minsize = 0,
  maxsize = 100,
  minLength = 0,
  maxLength = 100
}

local stringMinLength = string.rep("a", boundaryNicknames.minLength)
local stringMaxLength = string.rep("a", boundaryNicknames.maxLength)

local arrayMaxSizeMinLengthNicknames = {}
local arrayMaxSizeMaxLengthNicknames = {}

for i = 1, boundaryNicknames.maxsize do
  arrayMaxSizeMinLengthNicknames[i] = stringMinLength
  arrayMaxSizeMaxLengthNicknames[i] = stringMaxLength
end

local arrayMinSize = common.EMPTY_ARRAY

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request: nicknames of maxsize, minlength", common.setAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMaxSizeMinLengthNicknames) })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMaxSizeMinLengthNicknames) })
common.Step("SetAppProperties request: nicknames of maxsize, maxlength", common.setAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMaxSizeMaxLengthNicknames) })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMaxSizeMaxLengthNicknames) })
common.Step("SetAppProperties request: nicknames of minsize", common.setAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMinSize) })
common.Step("GetAppProperties request to check set values", common.getAppProperties,
  { common.updateDefaultAppProperties("nicknames", arrayMinSize) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
