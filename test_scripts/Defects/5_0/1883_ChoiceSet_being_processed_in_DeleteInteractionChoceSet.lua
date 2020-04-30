---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1883
--
-- Reproduction Steps:
--1. Start SDL, HMI, Mobile
--2. Register and activate Application.
--3. Create InteractionChoiseSet choiceSetID_1.
--4. Delete InteractionChoiseSet choiceSetID_1.
  -- During HMI processes VR.DeleteCommands_request that relate to choiceSetID_1
  -- Mobile sends PerformInteraction request choiceSetID_1.

-- Expected Behavior:
-- SDL must respond to mobile REJECTED (success:false) to this PerfromInteraction

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestchoiceParams = {
  interactionChoiceSetID = 1,
  choiceSet = {
    {
      choiceID = 111,
      menuName = "Choice111",
      vrCommands = { "Choice111" }
    }
  }
}

local deleteRequestParams = {
  interactionChoiceSetID = requestchoiceParams.interactionChoiceSetID
}

local deleteResponseVrParams = {
  cmdID = requestchoiceParams.choiceID,
  type = "Choice"
}

local deleteAllParams = {
  requestParams = deleteRequestParams,
  responseVrParams = deleteResponseVrParams
}

local performParams = {
  initialText = "TextInitial",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { 1 },
  initialPrompt = {
    { type = "TEXT", text = "pathToFile1" }
  }
}

--[[ Local Functions ]]
local function sendPerformInteraction_REJECTED()
  local corId = common.getMobileSession():SendRPC("PerformInteraction", performParams)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "REJECTED" })
end

local function createInteractionChoiceSet()
  local corId = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", requestchoiceParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand",
    { cmdID = 111, type = "Choice", vrCommands = { "Choice111" } })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

local function deleteInteractionChoiceSetAndSendPerfomInteraction(params)
  local cid = common.getMobileSession():SendRPC("DeleteInteractionChoiceSet", params.requestParams)

  EXPECT_HMICALL("VR.DeleteCommand", params.responseVrParams)
  :Do(function(_, data)
      sendPerformInteraction_REJECTED()
      local function deleteCommandResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(deleteCommandResp, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("PTU", common.policyTableUpdate)

runner.Title("Test")
runner.Step("Create InteractionChoiceSet", createInteractionChoiceSet, {})
runner.Step("Delete InteractionChoiseSet", deleteInteractionChoiceSetAndSendPerfomInteraction, {deleteAllParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
