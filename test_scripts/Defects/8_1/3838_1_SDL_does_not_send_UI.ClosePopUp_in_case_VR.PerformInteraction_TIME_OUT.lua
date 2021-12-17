---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3838
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send UI.ClosePopUp to HMI in case:
-- - mobile App sends PerformInteraction request with VR_ONLY interaction mode to SDL
-- - HMI responds with 'TIMED_OUT' to VR.PerformInteraction request
--
-- Pre-conditions:
-- 1. SDL, HMI, Mobile session are started
-- 2. App is registered and activated
-- 3. CreateInteractionChoiceSet is added
-- Steps:
-- 1. App sends PerformInteraction request with VR_ONLY interaction mode to SDL
-- 2. HMI responds with 'SUCCESS' to UI.PerformInteraction request
-- 3. HMI responds with 'TIMED_OUT' to VR.PerformInteraction request
-- SDL does:
-- - not send UI.ClosePopUp request to HMI
-- - send PerformInteraction response (resultCode: TIMED_OUT, success:false) to mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
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
    position = 1
  }
}

local requestParams = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = { 100 },
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
      menuName = "Choice" .. tostring(pChoiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(pChoiceIDValue),
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

local function expectOnHMIStatusWithAudioStateChanged_PI(pRequest)
  if pRequest == "BOTH" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(6)
  elseif pRequest == "VR" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(5)
  elseif pRequest == "MANUAL" then
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  end
end

local function createInteractionChoiceSet(pChoiceSetID)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
    interactionChoiceSetID = pChoiceSetID,
    choiceSet = setChoiceSet(pChoiceSetID),
  })
  common.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = pChoiceSetID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(pChoiceSetID) }
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function PI_ViaVR_ONLY(pParams)
  pParams.interactionMode = "VR_ONLY"
  local cid = common.getMobileSession():SendRPC("PerformInteraction", pParams)
  common.getHMIConnection():ExpectRequest("UI.ClosePopUp")
  :Times(0)
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
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("VR.Stopped")
        sendOnSystemContext("MAIN")
      end
      common.run.runAfter(vrResponse, 1000)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
    timeout = pParams.timeout,
    vrHelp = pParams.vrHelp,
    vrHelpTitle = pParams.initialText,
  })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  expectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet with id 100", createInteractionChoiceSet, { 100 })

runner.Title("Test")
runner.Step("PerformInteraction with VR_ONLY interaction mode", PI_ViaVR_ONLY, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
