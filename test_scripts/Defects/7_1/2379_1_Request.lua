---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2379
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to reject request from HMI after cut off of fake parameters
-- and request becomes invalid
-- Scenario: request that SDL should use internally
--
-- Steps:
-- 1. HMI sends request with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether request is valid
--  - reject request in case if it's invalid
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendGetUserFriendlyMessage()
  local params = {
    language = "EN-US",
    messageCodes = { 123 }, --invalid data type
    fakeParam = "123"
  }
  local exp = {
    error = {
      code = 11, --INVALID_DATA
      data = {
        method = "SDL.GetUserFriendlyMessage",
      }
    }
  }
  local cid = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", params)
  common.getHMIConnection():ExpectResponse(cid, exp)
  :ValidIf(function(_, data)
      if data.error.data.fakeParam then
        return false, "Unexpected 'fakeParam' is received"
      end
      return  true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

runner.Title("Test")
runner.Step("HMI sends GetUserFriendlyMessage", sendGetUserFriendlyMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
