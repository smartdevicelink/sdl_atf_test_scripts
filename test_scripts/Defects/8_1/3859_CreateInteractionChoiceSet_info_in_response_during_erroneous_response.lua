---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3859
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL transfers the error message from the HMI response to the mobile app

-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile app requests CreateInteractionChoiceSet RPC
-- 4. SDL sends VR.AddCommand(type = "Choice") request to the HMI
-- 5. HMI responds with erroneous code and error message to the VR.AddCommand(type = "Choice") request
-- SDL does:
-- 1. process the VR.AddCommand response from HMI
-- 2. send the CreateInteractionChoiceSet response to the mobile app with received error code and message
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  interactionChoiceSetID = 1001,
  choiceSet = {
    {
      choiceID = 1001,
      menuName ="Choice1001",
      vrCommands = {
        "Choice1001"
      }
    }
  }
}
local errorCodes = {
  "DISALLOWED",
  "REJECTED",
  "ABORTED",
  "IGNORED",
  "IN_USE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "GENERIC_ERROR",
  "UNSUPPORTED_REQUEST",
  "USER_DISALLOWED",
  "READ_ONLY"
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(resultCode)
  local errorMessage = "Error message"

  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", requestParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, resultCode, "Error message")
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = resultCode, info = errorMessage })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, code in ipairs(errorCodes) do
  runner.Step("CreateInteractionChoiceSet with result code:" .. code, createInteractionChoiceSet, { code })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
