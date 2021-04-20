---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: PerformInteraction
-- Item: Happy path
--
-- Requirement summary:
-- [PerformInteraction]:
-- SUCCESS result code
-- TIMED_OUT result code
--
-- Description:
-- Mobile application sends PerformInteraction request with valid parameters to SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. ChoiceSets are already added

-- Steps:
-- appID requests PerformInteraction with valid parameters to SDL

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if PerformInteraction is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL provides ability to perform choice on HMI manually or by voice
-- After user provide the choice SDL responds with (resultCode: SUCCESS, success:true) to mobile application
-- After user does not provide the choice SDL responds with (resultCode: TIMED_OUT, success:false) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local ImageValue = {
  value = common.getPathToFileInAppStorage("icon.png"),
  imageType = "DYNAMIC",
}

local function getPromptValue(pText)
  return {
    {
      text = pText,
      type = "TEXT"
    }
  }
end

local initialPromptValue = getPromptValue(" Make your choice ")

local helpPromptValue = getPromptValue(" Help Prompt ")

local timeoutPromptValue = getPromptValue(" Time out ")

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
local function setChoiceSet(pChoiceIDValue)
  local temp = {
    {
      choiceID = pChoiceIDValue,
      menuName ="Choice" .. tostring(pChoiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(pChoiceIDValue),
      },
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

local function sendOnSystemContext(pCtx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext", {
    appID = common.getHMIAppId(),
    systemContext = pCtx
  })
end

local function setExChoiceSet(pChoiceIDValues)
  local exChoiceSet = { }
  for i = 1, #pChoiceIDValues do
    exChoiceSet[i] = {
      choiceID = pChoiceIDValues[i],
      image = {
        value = "icon.png",
        imageType = "STATIC",
      },
      menuName = "Choice" .. pChoiceIDValues[i]
    }
  end
  return exChoiceSet
end

local function expectOnHMIStatusWithAudioStateChanged_PI(pRequest)
  if pRequest == "BOTH" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(3)
  elseif pRequest == "VR" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "MAIN",     hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  elseif pRequest == "MANUAL" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(2)
  end
end

local function createInteractionChoiceSet(choiceSetID)
  local choiceID = choiceSetID
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  common.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function PI_ViaVR_ONLY(pParams)
  pParams.interactionMode = "VR_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",pParams)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_, data)
      local function vrResponse()
        common.getHMIConnection():SendNotification("TTS.Started")
        common.getHMIConnection():SendNotification("VR.Started")
        sendOnSystemContext("VRSESSION")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("VR.Stopped")
        sendOnSystemContext("MAIN")
      end
      common.runAfter(vrResponse, 1000)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      vrHelp = pParams.vrHelp,
      vrHelpTitle = pParams.initialText,
    })
  :Do(function(_,data)
      common.getHMIConnection():ExpectRequest("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
        :Do(function()
          common.getHMIConnection():SendError(data.id, data.method, "ABORTED", "Error message")
        end)
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = pParams.interactionChoiceSetIDList[1] })
end

local function PI_ViaMANUAL_ONLY(pParams)
  pParams.interactionMode = "MANUAL_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction", pParams)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      choiceSet = setExChoiceSet(pParams.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParams.initialText
      }
    })
  :Do(function(_, data)
      sendOnSystemContext("HMI_OBSCURED")
      local function uiResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
        sendOnSystemContext("MAIN")
      end
      common.runAfter(uiResponse, 1000)
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("MANUAL")
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = pParams.interactionChoiceSetIDList[1] })
end

local function PI_ViaBOTH(pParams)
  pParams.interactionMode = "BOTH"
  local cid = common.getMobileSession():SendRPC("PerformInteraction", pParams)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      sendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("TTS.Started")
      end
      common.runAfter(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      common.runAfter(vrResponse, 20)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      choiceSet = setExChoiceSet(pParams.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParams.initialText
      },
      vrHelp = pParams.vrHelp,
      vrHelpTitle = pParams.initialText
    })
  :Do(function(_, data)
      local function choiceIconDisplayed()
        sendOnSystemContext("HMI_OBSCURED")
      end
      common.runAfter(choiceIconDisplayed, 25)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        sendOnSystemContext("MAIN")
      end
      common.runAfter(uiResponse, 30)
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

local function PI_ViaBOTHuiChoice(pParams)
  pParams.interactionMode = "BOTH"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",pParams)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      sendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("TTS.Started")
      end
      common.runAfter(firstSpeakTimeOut, 1000)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      common.runAfter(vrResponse, 2000)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      choiceSet = setExChoiceSet(pParams.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParams.initialText
      },
      vrHelp = pParams.vrHelp,
      vrHelpTitle = pParams.initialText
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        sendOnSystemContext("HMI_OBSCURED")
      end
      common.runAfter(choiceIconDisplayed, 2050)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        sendOnSystemContext("MAIN")
      end
      common.runAfter(uiResponse, 3000)
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    choiceID = pParams.interactionChoiceSetIDList[1], triggerSource = "MENU" })
end

local function PI_ViaBOTHvrChoice(pParams)
  pParams.interactionMode = "BOTH"
  local cid = common.getMobileSession():SendRPC("PerformInteraction",pParams)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("TTS.Started")
      common.getHMIConnection():SendNotification("VR.Started")
      sendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(firstSpeakTimeOut, 1000)
      local function vrResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("VR.Stopped")
        sendOnSystemContext("MAIN")
      end
      common.runAfter(vrResponse, 2000)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      choiceSet = setExChoiceSet(pParams.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParams.initialText
      },
      vrHelp = pParams.vrHelp,
      vrHelpTitle = pParams.initialText
    })
  :Do(function(_,data)
      common.getHMIConnection():ExpectRequest("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
        :Do(function()
          common.getHMIConnection():SendError(data.id, data.method, "ABORTED", "Error message")
        end)
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    choiceID = pParams.interactionChoiceSetIDList[1], triggerSource = "VR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })
runner.Step("CreateInteractionChoiceSet with id 100", createInteractionChoiceSet, { 100 })
runner.Step("CreateInteractionChoiceSet with id 200", createInteractionChoiceSet, { 200 })
runner.Step("CreateInteractionChoiceSet with id 300", createInteractionChoiceSet, { 300 })

runner.Title("Test")
runner.Step("PerformInteraction with VR_ONLY interaction mode", PI_ViaVR_ONLY, { requestParams })
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode", PI_ViaMANUAL_ONLY, { requestParams })
runner.Step("PerformInteraction with BOTH interaction mode TIMED_OUT", PI_ViaBOTH, { requestParams })
runner.Step("PerformInteraction with BOTH interaction mode choice via UI", PI_ViaBOTHuiChoice, {requestParams})
runner.Step("PerformInteraction with BOTH interaction mode choice via VR", PI_ViaBOTHvrChoice, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
