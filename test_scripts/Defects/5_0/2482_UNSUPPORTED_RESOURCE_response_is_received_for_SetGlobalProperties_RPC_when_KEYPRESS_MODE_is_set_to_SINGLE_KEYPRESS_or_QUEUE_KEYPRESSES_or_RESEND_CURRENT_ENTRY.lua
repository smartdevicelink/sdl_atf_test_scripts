---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2482
--
-- Description:
-- UNSUPPORTED_RESOURCE response is received for SetGlobalProperties RPC when KEYPRESS MODE is set to SINGLE_KEYPRESS,
-- QUEUE_KEYPRESSES or RESEND_CURRENT_ENTRY
-- Precondition:
-- Vehicle ignition is ON
-- SYNC is ON
-- Device is connected to the SYNC via BT
-- Autotester is installed and registered to the system
-- In case:
-- 1) Launch Emergency on the phone
-- 2) Select Apps from the status interaction menu
-- 3) Select Emergency app
-- 4) Select "send message" and "SetGlobalproperties" ,
-- 	  edit Keyboard properties "KeypressMode as Single_keyPress" and press ok
-- 5) Select 'Send Message' in the test app on the phone and
--    Select CreateInteractionChoiceSet then enter all the details and press OK.
-- 6) Select 'Send Message' in the test app on the phone and
--    Select "PerformInteraction", Enter data for Initial TextInitial Prompt:
--    Interaction Mode: MANUAL_ONLY, Layout: KEYBOARD(as in step 4 KeyPress mode: SINGLE_KEYPRESS )and press OK
-- 7) Verify the Screen displayed on SYNC
-- 8) Press on the text box and enter the Single key in the keyboard displayed on the sync
-- Expected result:
-- 1) SUCCESS response should be recieved for both SetGlobalProperties and PerformInteraction RPC.
-- Actual result:
-- UNSUPPORTED_RESOURCE response is recieved fot SetGlobalProperties.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local keyPressMode = {
	"SINGLE_KEYPRESS",
	"QUEUE_KEYPRESSES",
	"RESEND_CURRENT_ENTRY"
}

local choiceParams = {
  interactionChoiceSetID = 100,
  choiceSet = {
    {
      choiceID = 100,
      menuName = "Choice100",
      vrCommands = { "Choice100" }
    }
  }
}

local createVrParams = {
	cmdID = choiceParams.interactionChoiceSetID,
	type = "Choice",
	vrCommands = choiceParams.vrCommands
}

local performParams = {
  initialText = "TextInitial",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { 100 },
  initialPrompt = {
    { type = "TEXT", text = "pathToFile1" }
  },
  helpPrompt = {
    { type = "TEXT", text = "pathToFile2" }
  },
  timeoutPrompt = {
    { type = "TEXT", text = "pathToFile3" }
  },
  interactionLayout = "KEYBOARD"
}

--[[ Local Functions ]]
local function setGlobalProperties(pkeyPressMode)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties",
  {
    keyboardProperties = {
      keypressMode = pkeyPressMode
    }
  })
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties",
    { appID = common.getHMIAppId(),
    keyboardProperties = {
      keypressMode = pkeyPressMode
    } })
	:Do(function(_,data)
		common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.getMobileSession():ExpectNotification("OnHashChange")
end

local function createInteractionChoiceSet()
  local corId = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

local function sendPerformInteraction_SUCCESS()
  local corId = common.getMobileSession():SendRPC("PerformInteraction", performParams)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = performParams.initialPrompt,
    helpPrompt = performParams.helpPrompt,
    timeoutPrompt = performParams.timeoutPrompt
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet)

for _, v in pairs(keyPressMode) do
  runner.Title("Test")
	runner.Step("SetGlobalProperties with keypressMode " .. v, setGlobalProperties, { v })
  runner.Step("Send PerformInteraction SUCCESS response", sendPerformInteraction_SUCCESS)

end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
