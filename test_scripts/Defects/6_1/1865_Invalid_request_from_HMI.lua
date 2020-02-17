---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1865
--
-- Steps:
-- 1. HMI sends invalid request:
--  a) array size of parameter is beyond the max restriction
--  b) string value of parameter is beyond the max restriction
--  c) invalid value type of parameter
--  d) missing mandatory parameter
--  e) empty string value for parameter
--
-- Expected result:
-- 1. SDL responds with code INVALID_DATA to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local tcs = {
  [1] = {
    name = "string value of parameter is beyond the max restriction",
    method = "SDL.GetUserFriendlyMessage",
    params = { messageCodes = { string.rep("q", 501) } }
  },
  [2] = {
    name = "array size of parameter is beyond the max restriction",
    method = "SDL.GetUserFriendlyMessage",
    params = { messageCodes = (function()
      local out = { }
      for i = 1, 101 do out[i] = "DataConsent" end
      return out
    end)() }
  },
  [3] = {
    name = "invalid value type of parameter",
    method = "SDL.ActivateApp",
    params = { appID = "12345" }
  },
  [4] = {
    name = "missing mandatory parameter",
    method = "SDL.ActivateApp",
    params = { fake = "" }
  },
  [5] = {
    name = "empty string value for parameter",
    method = "SDL.GetUserFriendlyMessage",
    params = { messageCodes = { "" } }
  }
}

--[[ Local Functions ]]
local function hmiRequest(pRequest, pParams)
	local cid = common.getHMIConnection():SendRequest(pRequest, pParams)
	common.getHMIConnection():ExpectResponse(cid, { error = { code = 11, data = { method = pRequest }}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)

runner.Title("Test")
for _, tc in utils.spairs(tcs) do
  runner.Step(tc.name, hmiRequest, { tc.method, tc.params })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
