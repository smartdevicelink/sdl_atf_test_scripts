---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1862
--
-- In case:
-- 1) HMI sends SDL.GetUserFriendlyMessage request to SDL
-- and this request has at least one String parameter with '\n' and/or '\t'
-- and/or 'whitespace' as the only symbol(s).
--
-- Expected result:
-- 1) SDL responds with 'INVALID_DATA' to HMI
-- 2) Log corresponding error internally
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function testGetUserFriendlyMessageValidParams()
  local rqIdValid = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", {
    language = "EN-US",
    messageCodes = {"DataConsent"}
  })
  common.getHMIConnection():ExpectResponse(rqIdValid, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
end

local function testGetUserFriendlyMessageRequest(pRqParams)
  local cid = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", pRqParams)
  common.getHMIConnection():ExpectResponse(cid, { error = {code = 11, data = {method = "SDL.GetUserFriendlyMessage" }}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("GetUserFriendlyMessage valid params", testGetUserFriendlyMessageValidParams)
runner.Step("GetUserFriendlyMessage mandatory endline", testGetUserFriendlyMessageRequest, {
  {
    messageCodes = {"\n"}
  }
})
runner.Step("GetUserFriendlyMessage mandatory tab", testGetUserFriendlyMessageRequest, {
  {
    messageCodes = {"\t"}
  }
})
runner.Step("GetUserFriendlyMessage mandatory whitespace", testGetUserFriendlyMessageRequest, {
  {
    messageCodes = {" "}
  }
})
runner.Step("GetUserFriendlyMessage full endline", testGetUserFriendlyMessageRequest, {
  {
    language = "EN-US",
    messageCodes = {"\n"}
  }
})
runner.Step("GetUserFriendlyMessage full tab", testGetUserFriendlyMessageRequest, {
  {
    language = "EN-US",
    messageCodes = {"\t"}
  }
})
runner.Step("GetUserFriendlyMessage full whitespace", testGetUserFriendlyMessageRequest, {
  {
    language = "EN-US",
    messageCodes = {" "}
  }
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
