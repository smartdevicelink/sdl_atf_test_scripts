---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2354
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with request from HMI after cut off of fake parameters
-- Scenario: request that SDL should use internally
--
-- Steps:
-- 1. HMI sends request with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether request is valid
--  - proceed with request in case if it's valid
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
    messageCodes = { "DataConsent" },
    fakeParam = "123"
  }
  local exp = {
    result = {
      code = 0, -- SUCCESS
      method = "SDL.GetUserFriendlyMessage",
      messages = {
        { messageCode = "DataConsent" }
      }
    }
  }
  local cid = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", params)
  common.getHMIConnection():ExpectResponse(cid, exp)
  :ValidIf(function(_, data)
      if data.result.fakeParam then
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
