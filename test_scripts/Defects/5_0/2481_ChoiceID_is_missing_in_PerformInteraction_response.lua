---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2481
-- Description:
-- 1) ChoiceID is missing in PerformInteraction response
-- Precondition:
-- 1) Vehicle Ignition On and Running
-- 2) Android connected via BT
-- 3) SyncProxyTester Media App running on phone and SYNC
-- 4) Created Interaction Choice Set with ID 1 and data items as A, B and C respectively
-- Steps to reproduce:
-- 1) Select Send Message -> PerformInteraction and enter following data:
--    Set the Initial text as 'Pick an Alphabet:', Initial Prompt as 'Pick a command', Interaction Mode as 'BOTH',
--    Choice Set ID as '2', Check help prompt, timeout prompt and set timeout as 10000. Uncheck the VR help Item #. Press Ok.  
-- Expected:
-- 1) PerformInteraction(request) notificaiton is displayed on the app.
--    Sync displays 'Pick an Alphabet' followed by the choice set A,B and C. Sync TTS 'Pick a command'
-- 2) PerformInteraction(response): SUCCESS is displayed on the mobile app. Verify the ChoiceID in the response was correct.
--    The app should next exit out of the PerformInteraction popup back to previous screen.
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local paramsBoth = {
    initialText = "Pick an Alphabet",
    initalPrompt = "Pick a command",
    interactionMode = "BOTH",
    interactionChoiceSetIDList = { 1 }
}

-- [[ Local Functions ]]
local function setExChoiceSet(choiceIDValues)
  local exChoiceSet = { }
  for i = 1, #choiceIDValues do
    exChoiceSet[i] = {
      choiceID = choiceIDValues[i]
    }
  end
  return exChoiceSet
end

local function PromptValue(text)
  local tmp = {
    {
      text = text,
      type = "TEXT"
    }
  }
  return tmp
end

local initialPromptValue = PromptValue(" Make your choice ")
local helpPromptValue = PromptValue(" Help Prompt ")
local timeoutPromptValue = PromptValue(" Time out ")

local function SendOnSystemContext(pParam)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = common.getHMIAppId(), systemContext = pParam })
end

local function createInteractionChoiceSet()
    local choiceParams = {
        interactionChoiceSetID = 1,
        choiceSet = {
          {
            choiceID = 1,
            menuName = "Choice1",
            vrCommands = { "Choice1" }
          }
        } 
    }
    local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end 

local function sendPerformInteraction(pParam)
    local cid = common.getMobileSession():SendRPC("PerformInteraction", pParam)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParam.helpPrompt,
      initialPrompt = pParam.initialPrompt,
      timeout = pParam.timeout,
      timeoutPrompt = pParam.timeoutPrompt      
    })
    :Do(function(_,data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      SendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("VR.Stopped")
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)        
    common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParam.timeout,
      choiceSet = setExChoiceSet(pParam.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParam.initialText
      },
      vrHelp = pParam.vrHelp,
      vrHelpTitle = pParam.initialText
    })
  :Do(function(_,data)
    SendOnSystemContext("HMI_OBSCURED")
    local function uiResponse()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { choiceID = pParam.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      SendOnSystemContext("MAIN")
    end
    RUN_AFTER(uiResponse, 1000)
  end)
  common.getMobileSession():ExpectResponse(cid,
  { success = true, resultCode = "SUCCESS", choiceID = pParam.interactionChoiceSetIDList[1] })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Create InteractionChoiceSetVR", createInteractionChoiceSet)
-- [[ Test ]]
runner.Title("Test")
runner.Step("Send PerformInteraction BOTH mode", sendPerformInteraction, { paramsBoth })
-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
