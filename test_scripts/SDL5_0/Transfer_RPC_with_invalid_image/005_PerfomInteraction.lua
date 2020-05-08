---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests PerfromInteraction with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found.”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local ImageValue = {
  value = common.getPathToFileInStorage("missed_icon.png"),
  imageType = "DYNAMIC",
}

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

local vrHelpvalue = {
  {
    text = " New VRHelp ",
    position = 1,
    image = ImageValue
  }
}

local requestParams = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
    100, 200, 300
  },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY"
}

--[[ Local Functions ]]

--! @setChoiceSet: Creates Choice structure
--! @parameters:
--! choiceIDValue - Id for created choice
--! @return: table of created choice structure
local function setChoiceSet(choiceIDValue)
  local temp = {
    {
      choiceID = choiceIDValue,
      menuName ="Choice" .. tostring(choiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(choiceIDValue)
      },
      image = {
        value ="missed_icon.png",
        imageType ="DYNAMIC"
      }
    }
  }
  return temp
end

--! @SendOnSystemContext: OnSystemContext notification
--! @parameters:
--! ctx - systemContext value
--! @return: none
local function SendOnSystemContext(ctx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = common.getHMIAppId(), systemContext = ctx })
end

--! @setExChoiceSet: ChoiceSet structure for UI.PerformInteraction request
--! @parameters:
--! choiceIDValues - value of choice id
--! @return: none
local function setExChoiceSet(choiceIDValues)
  local exChoiceSet = { }
  for i = 1, #choiceIDValues do
    exChoiceSet[i] = {
      choiceID = choiceIDValues[i],
      image = {
        value = common.getPathToFileInStorage("missed_icon.png"),
        imageType = "DYNAMIC",
      },
      menuName = "Choice" .. choiceIDValues[i]
    }
  end
  return exChoiceSet
end

--! @ExpectOnHMIStatusWithAudioStateChanged_PI: Expectations of OnHMIStatus notification depending on the application
--! type, HMI level and interaction mode
--! @parameters:
--! request - interaction mode,
--! @return: none
local function ExpectOnHMIStatusWithAudioStateChanged_PI(request)
  if "BOTH" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(6)
  elseif "VR" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(5)
  elseif "MANUAL" == request then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  end
end

--! @CreateInteractionChoiceSet: Creation of Choice Set
--! @parameters:
--! choiceSetID - id for choice set
--! @return: none
local function CreateInteractionChoiceSet(choiceSetID)
  local choiceID = choiceSetID
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { resultCode = "WARNINGS", success = true })
end

--! @PI_PerformViaVR_ONLY: Processing PI with interaction mode VR_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaVR_ONLY(paramsSend)
  paramsSend.interactionMode = "VR_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      local function vrResponse()
        common.getHMIConnection():SendNotification("TTS.Started")
        common.getHMIConnection():SendNotification("VR.Started")
        SendOnSystemContext("VRSESSION")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("VR.Stopped")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(vrResponse, 1000)
    end)

  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      vrHelp = paramsSend.vrHelp,
      vrHelpTitle = paramsSend.initialText,
    })
  :Do(function(_,data)
      common.getHMIConnection():SendError( data.id, data.method, "WARNINGS","Requested image(s) not found.")
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "WARNINGS", choiceID = paramsSend.interactionChoiceSetIDList[1],
    info = "Requested image(s) not found." })
end

--! @PI_PerformViaMANUAL_ONLY: Processing PI with interaction mode MANUAL_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaMANUAL_ONLY(paramsSend)
  paramsSend.interactionMode = "MANUAL_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction", paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      choiceSet = setExChoiceSet(paramsSend.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = paramsSend.initialText
      }
    })
  :Do(function(_,data)
      SendOnSystemContext("HMI_OBSCURED")
      local function uiResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "WARNINGS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] } )
        common.getHMIConnection():SendNotification("TTS.Stopped")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 1000)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("MANUAL")
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "WARNINGS", choiceID = paramsSend.interactionChoiceSetIDList[1] })
  -- this is the only case when 'info' won't be populated since HMI couldn't provide it within success response
end

--! @PI_PerformViaBOTH: Processing PI with interaction mode BOTH with timeout on VR and IU
--! @parameters:
--! paramsSend - parameters for PI request
--! @return: none
local function PI_PerformViaBOTH(paramsSend)
  paramsSend.interactionMode = "BOTH"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      SendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)
  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      choiceSet = setExChoiceSet(paramsSend.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = paramsSend.initialText
      },
      vrHelp = paramsSend.vrHelp,
      vrHelpTitle = paramsSend.initialText
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        SendOnSystemContext("HMI_OBSCURED")
      end
      RUN_AFTER(choiceIconDisplayed, 25)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found.")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 30)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found., Perform Interaction error response." })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet with id 100", CreateInteractionChoiceSet, {100})
runner.Step("CreateInteractionChoiceSet with id 200", CreateInteractionChoiceSet, {200})
runner.Step("CreateInteractionChoiceSet with id 300", CreateInteractionChoiceSet, {300})

runner.Title("Test")
runner.Step("PerformInteraction with VR_ONLY interaction mode with invalid image", PI_PerformViaVR_ONLY, {requestParams})
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode with invalid image", PI_PerformViaMANUAL_ONLY, {requestParams})
runner.Step("PerformInteraction with BOTH interaction mode with invalid image", PI_PerformViaBOTH, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
