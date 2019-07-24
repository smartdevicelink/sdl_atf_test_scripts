---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is registered on SDL
--
--  Steps:
--  1) app1 sends a sends a CreateInteractionChoiceSet RPC
--  2) app1 sends a sends a PerformInteraction RPC
--  3) app1 sends a CancelInteraction Request with the functionID of PerformInteraction
--  4) the HMI receives the PerformInteraction Requests and replies to them both
--  5) the HMI receives the CancelInteraction Request and replies
--
--  Expected:
--  1) app1 receives SUCCESS from the CancelInteraction
--  2) app1 receives ABORTED from the PerformInteraction
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local util = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local rpcCreateChoiceSet = {
  name = "CreateInteractionChoiceSet",
  params = {
    interactionChoiceSetID = 42,
    choiceSet = {
      { choiceID = 1, menuName = "choice1" },
      { choiceID = 2, menuName = "choice2" }
    }
  }
}

local rpcInteraction = {
  name = "PerformInteraction",
  hmi_name = "UI.PerformInteraction",
  hmi_name2 = "VR.PerformInteraction",
  params = {
    initialText = "hello",
    interactionMode = 0,
    interactionChoiceSetIDList = { 42 },
    helpPrompt = { { text = "tts_chunk", type = "SILENCE" } }
  }
}

local rpcCancelInteraction = {
  name = "CancelInteraction",
  hmi_name = "UI.CancelInteraction",
  params = {
    cancelID = 99,
    functionID = 10
  }
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS"
}

local abortedResponse = {
  success = false,
  resultCode = "ABORTED"
}

--[[ Local functions ]]
local function SendCancelInteraction()
  local mobileSession = common.getMobileSession(1)
  local hmiSession = common.getHMIConnection()
  
  mobileSession:SendRPC(rpcCreateChoiceSet.name, rpcCreateChoiceSet.params)
  local cid0 = mobileSession:SendRPC(rpcInteraction.name, rpcInteraction.params)
  local cid1 = mobileSession:SendRPC(rpcCancelInteraction.name, rpcCancelInteraction.params)
  
  EXPECT_HMICALL(rpcInteraction.hmi_name, {})
  :Do(function(_, data)
    hmiSession:SendResponse(data.id, data.method, "ABORTED", {})
  end)

  EXPECT_HMICALL(rpcInteraction.hmi_name2, {})
  :Do(function(_, data)
    hmiSession:SendResponse(data.id, data.method, "ABORTED", {})
  end)

  EXPECT_HMICALL(rpcCancelInteraction.hmi_name, rpcCancelInteraction.params)
  :Do(function(_, data)
    hmiSession:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobileSession:ExpectResponse(cid0, abortedResponse)
  mobileSession:ExpectResponse(cid1, successResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI App 1", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send CancelInteraction", SendCancelInteraction)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
