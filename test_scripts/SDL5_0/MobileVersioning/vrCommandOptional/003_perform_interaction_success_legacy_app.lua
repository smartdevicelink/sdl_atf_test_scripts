---------------------------------------------------------------------------------------------------
-- User story: MobileVersioning Legacy App
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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

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

local storagePath = commonPreconditions:GetPathToSDL() .. "storage/" ..
config.application1.registerAppInterfaceParams.appID .. "_" .. commonSmoke.getDeviceMAC() .. "/"

local ImageValue = {
  value = storagePath .. "icon.png",
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
        "VrChoice" .. tostring(choiceIDValue),
      },
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

--! @SendOnSystemContext: OnSystemContext notification
--! @parameters:
--! self - test object,
--! ctx - systemContext value
--! @return: none
local function SendOnSystemContext(ctx)
  commonSmoke.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = commonSmoke.getHMIAppId(), systemContext = ctx })
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
        value = "icon.png",
        imageType = "STATIC",
      },
      menuName = "Choice" .. choiceIDValues[i]
    }
  end
  return exChoiceSet
end

--! @ExpectOnHMIStatusWithAudioStateChanged_PI: Expectations of OnHMIStatus notification depending on the application
--! type, HMI level and interaction mode
--! @parameters:
--! self - test object,
--! request - interaction mode,
--! @return: none
local function ExpectOnHMIStatusWithAudioStateChanged_PI(request)
  if "BOTH" == request then
    commonSmoke.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(4)
  elseif "VR" == request then
    commonSmoke.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  elseif "MANUAL" == request then
    commonSmoke.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(3)
  end
end

--! @CreateInteractionChoiceSet: Creation of Choice Set
--! @parameters:
--! choiceSetID - id for choice set
--! self - test object
--! @return: none
local function CreateInteractionChoiceSet(choiceSetID)
  local choiceID = choiceSetID
  local cid = commonSmoke.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  commonSmoke.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

--! @PI_PerformViaVR_ONLY: Processing PI with interaction mode VR_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaVR_ONLY(paramsSend)
  paramsSend.interactionMode = "VR_ONLY"
  local cid = commonSmoke.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      local function vrResponse()
        commonSmoke.getHMIConnection():SendNotification("TTS.Started")
        commonSmoke.getHMIConnection():SendNotification("VR.Started")
        SendOnSystemContext("VRSESSION")
        commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        commonSmoke.getHMIConnection():SendNotification("TTS.Stopped")
        commonSmoke.getHMIConnection():SendNotification("VR.Stopped")
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
      commonSmoke.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS", { } )
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("VR")
  commonSmoke.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = paramsSend.interactionChoiceSetIDList[1] })
end

--! @PI_PerformViaMANUAL_ONLY: Processing PI with interaction mode MANUAL_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaMANUAL_ONLY(paramsSend)
  paramsSend.interactionMode = "MANUAL_ONLY"
  local cid = commonSmoke.getMobileSession():SendRPC("PerformInteraction", paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      commonSmoke.getHMIConnection():SendNotification("TTS.Started")
      commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
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
        commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        commonSmoke.getHMIConnection():SendNotification("TTS.Stopped")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 1000)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("MANUAL")
  commonSmoke.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = paramsSend.interactionChoiceSetIDList[1] })
end

--! @PI_PerformViaBOTH: Processing PI with interaction mode BOTH with timeout on VR and IU
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaBOTH(paramsSend)
  paramsSend.interactionMode = "BOTH"
  local cid = commonSmoke.getMobileSession():SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      commonSmoke.getHMIConnection():SendNotification("VR.Started")
      commonSmoke.getHMIConnection():SendNotification("TTS.Started")
      SendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        commonSmoke.getHMIConnection():SendNotification("TTS.Stopped")
        commonSmoke.getHMIConnection():SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        commonSmoke.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        commonSmoke.getHMIConnection():SendNotification("VR.Stopped")
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
        commonSmoke.getHMIConnection():SendNotification("TTS.Stopped")
        commonSmoke.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 30)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  commonSmoke.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})
runner.Step("CreateInteractionChoiceSet with id 100", CreateInteractionChoiceSet, {100})
runner.Step("CreateInteractionChoiceSet with id 200", CreateInteractionChoiceSet, {200})
runner.Step("CreateInteractionChoiceSet with id 300", CreateInteractionChoiceSet, {300})

runner.Title("Test")
runner.Step("PerformInteraction with VR_ONLY interaction mode", PI_PerformViaVR_ONLY, {requestParams})
runner.Step("PerformInteraction with MANUAL_ONLY interaction mode", PI_PerformViaMANUAL_ONLY, {requestParams})
runner.Step("PerformInteraction with BOTH interaction mode", PI_PerformViaBOTH, {requestParams})


runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
