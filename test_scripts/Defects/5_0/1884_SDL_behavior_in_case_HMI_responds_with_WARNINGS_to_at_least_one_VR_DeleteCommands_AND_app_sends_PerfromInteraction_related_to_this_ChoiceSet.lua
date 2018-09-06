---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1884
--
-- Description:
-- SDL behavior in case HMI responds with WARNINGS to at least one VR.DeleteCommands
-- AND app sends PerfromInteraction related to this ChoiceSet
-- Precondition:
-- SDL and HMI are started.
-- App is registered and activated.
-- In case:
-- 1) In case of processing DeleteInteractionChoiceSet
--    HMI responds with WARNINGS to at least one VR.DeleteCommands_request related to ChoiceSetID_1
--    and app sends PerformInteraction for removed choiceSetID
-- Expected result:
-- 1) SDL must respond PerformInteraction (REJECTED, success:false) to mobile app
-- Actual result:
-- N/A
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grammarIDValue

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
  cmdID = requestchoiceParams.interactionChoiceSetID,
  type = "Choice"
}

local deleteAllParams = {
  requestParams = deleteRequestParams,
  responseVrParams = deleteResponseVrParams
}

local performParams = {
  initialText = "TextInitial",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { 100 },
  initialPrompt = {
    { type = "TEXT", text = "pathToFile1" }
  }
}

--[[ Local Functions ]]
local function createInteractionChoiceSet()
  local corId = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", requestchoiceParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand",
    { cmdID = 111, type = "Choice", vrCommands = { "Choice111" } })
  :Times(1)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

local function deleteInteractionChoiceSet(params)
	local cid = common.getMobileSession():SendRPC("DeleteInteractionChoiceSet", params.requestParams)

	params.responseVrParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("VR.DeleteCommand", { cmdID = 111, type = "Choice" })
	:Do(function(_,data)
    grammarIDValue = data.params.grammarID
		common.getHMIConnection():SendResponse(data.id, data.method, "WARNINGS", {})
	end)

	common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.getMobileSession():ExpectNotification("OnHashChange")
end

local function sendPerformInteraction_SUCCESS()
  local corId = common.getMobileSession():SendRPC("PerformInteraction", performParams)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "REJECTED" })
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet)
runner.Step("DeleteInteractionChoiceSet", deleteInteractionChoiceSet, {deleteAllParams})
runner.Step("Send PerformInteraction SUCCESS response", sendPerformInteraction_SUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
