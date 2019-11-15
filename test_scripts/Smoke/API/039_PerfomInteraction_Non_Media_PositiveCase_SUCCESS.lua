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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

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

local storagePath = commonPreconditions:GetPathToSDL() .. "storage/" ..
config.application1.registerAppInterfaceParams.fullAppID .. "_" .. commonSmoke.getDeviceMAC() .. "/"

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
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",
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

--! @ExpectOnHMIStatusWithAudioStateChanged_PI: Expectations of OnHMIStatus notification depending on interaction mode
--! @parameters:
--! self - test object,
--! request - interaction mode,
--! @return: none
local function ExpectOnHMIStatusWithAudioStateChanged_PI(self, request)
  if request == "BOTH" then
    self.mobileSession1:ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(3)
  elseif request == "VR" then
    self.mobileSession1:ExpectNotification("OnHMIStatus",
      { systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "MAIN",     hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  elseif request == "MANUAL" then
    self.mobileSession1:ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(2)
  end
end

--! @CreateInteractionChoiceSet: Creation of Choice Set
--! @parameters:
--! choiceSetID - id for choice set
--! self - test object
--! @return: none
local function CreateInteractionChoiceSet(choiceSetID, self)
  local choiceID = choiceSetID
  local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  self.mobileSession1:ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

--! @PI_PerformViaVR_ONLY: Processing PI with interaction mode VR_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaVR_ONLY(paramsSend, self)
  paramsSend.interactionMode = "VR_ONLY"
  local cid = self.mobileSession1:SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      local function vrResponse()
        self.hmiConnection:SendNotification("TTS.Started")
        self.hmiConnection:SendNotification("VR.Started")
        SendOnSystemContext(self, "VRSESSION")
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendNotification("VR.Stopped")
        SendOnSystemContext(self, "MAIN")
      end
      RUN_AFTER(vrResponse, 1000)
    end)

  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      vrHelp = paramsSend.vrHelp,
      vrHelpTitle = paramsSend.initialText,
    })
  :Do(function(_,data)
      EXPECT_HMICALL("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
        :Do(function()
          self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Error message")
        end)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "VR")
  self.mobileSession1:ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = paramsSend.interactionChoiceSetIDList[1] })
end

--! @PI_PerformViaMANUAL_ONLY: Processing PI with interaction mode MANUAL_ONLY with performing selection
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaMANUAL_ONLY(paramsSend, self)
  paramsSend.interactionMode = "MANUAL_ONLY"
  local cid = self.mobileSession1:SendRPC("PerformInteraction", paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
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
      SendOnSystemContext(self,"HMI_OBSCURED")
      local function uiResponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        self.hmiConnection:SendNotification("TTS.Stopped")
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(uiResponse, 1000)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "MANUAL")
  self.mobileSession1:ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = paramsSend.interactionChoiceSetIDList[1] })
end

--! @PI_PerformViaBOTH: Processing PI with interaction mode BOTH with timeout on VR and IU
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaBOTH(paramsSend, self)
  paramsSend.interactionMode = "BOTH"
  local cid = self.mobileSession1:SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("VR.Started")
      self.hmiConnection:SendNotification("TTS.Started")
      SendOnSystemContext(self,"VRSESSION")
      local function firstSpeakTimeOut()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        self.hmiConnection:SendNotification("VR.Stopped")
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
        SendOnSystemContext(self,"HMI_OBSCURED")
      end
      RUN_AFTER(choiceIconDisplayed, 25)
      local function uiResponse()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(uiResponse, 30)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "BOTH")
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

--! @PI_PerformViaBOTHuiChoice: Processing PI with interaction mode BOTH with user choice on UI part
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaBOTHuiChoice(paramsSend, self)
  paramsSend.interactionMode = "BOTH"
  local cid = self.mobileSession1:SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("VR.Started")
      self.hmiConnection:SendNotification("TTS.Started")
      SendOnSystemContext(self,"VRSESSION")
      local function firstSpeakTimeOut()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 1000)
      local function vrResponse()
        self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        self.hmiConnection:SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 2000)
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
        SendOnSystemContext(self,"HMI_OBSCURED")
      end
      RUN_AFTER(choiceIconDisplayed, 2050)
      local function uiResponse()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(uiResponse, 3000)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "BOTH")
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    choiceID = paramsSend.interactionChoiceSetIDList[1], triggerSource = "MENU" })
end

--! @PI_PerformViaBOTHvrChoice: Processing PI with interaction mode BOTH with user choice on VR part
--! @parameters:
--! paramsSend - parameters for PI request
--! self - test object
--! @return: none
local function PI_PerformViaBOTHvrChoice(paramsSend, self)
  paramsSend.interactionMode = "BOTH"
  local cid = self.mobileSession1:SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendNotification("VR.Started")
      SendOnSystemContext(self,"VRSESSION")
      local function firstSpeakTimeOut()
        self.hmiConnection:SendNotification("TTS.Stopped")
      end
      RUN_AFTER(firstSpeakTimeOut, 1000)
      local function vrResponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = paramsSend.interactionChoiceSetIDList[1] })
        self.hmiConnection:SendNotification("VR.Stopped")
        SendOnSystemContext(self, "MAIN")
      end
      RUN_AFTER(vrResponse, 2000)
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
      EXPECT_HMICALL("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
        :Do(function()
          self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Error message")
        end)
    end)
  ExpectOnHMIStatusWithAudioStateChanged_PI(self, "VR")
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    choiceID = paramsSend.interactionChoiceSetIDList[1], triggerSource = "VR" })
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
runner.Step("PerformInteraction with BOTH interaction mode TIMED_OUT", PI_PerformViaBOTH, {requestParams})
runner.Step("PerformInteraction with BOTH interaction mode choice via UI", PI_PerformViaBOTHuiChoice, {requestParams})
runner.Step("PerformInteraction with BOTH interaction mode choice via VR", PI_PerformViaBOTHvrChoice, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
