---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3725
---------------------------------------------------------------------------------------------------
-- Description:
-- SDL has to populate consumer friendly message data in all policy modes
--
-- Precondition:
-- 1) HMI Sends GetConsumerFriendlyMessage
-- SDL does:
--  - Reply with valid data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function sendGetConsumerFriendlyMessage()
  local gufmId = common.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage", { messageCodes = { "DataConsent" }})
  common.getHMIConnection():ExpectResponse(gufmId):ValidIf(function(_,data)
    if not data.result.messages then
      commonFunctions:userPrint(31, " GetUserFriendlyMessage response contains no messages")
      return false
    end

    local m = data.result.messages[1]
    if not m.messageCode then
      commonFunctions:userPrint(31, " GetUserFriendlyMessage response contains no messageCode")
      return false
    end

    if not m.label and not m.ttsString and not m.line1 and not m.line2 and not m.textBody then
      commonFunctions:userPrint(31, " GetUserFriendlyMessage response contains no data")
      return false
    end

    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Create mobile connection and session", common.start)

runner.Title("Test")
runner.Step("Send GetConsumerFriendlyMessage", sendGetConsumerFriendlyMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
