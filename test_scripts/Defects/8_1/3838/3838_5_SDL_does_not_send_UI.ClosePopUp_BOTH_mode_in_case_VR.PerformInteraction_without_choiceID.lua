---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3838
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send UI.ClosePopUp to HMI in case:
-- - mobile App sends PerformInteraction request with BOTH interaction mode to SDL
-- - HMI responds with 'SUCCESS' to VR.PerformInteraction request without choiceID
--
-- Pre-conditions:
-- 1. SDL, HMI, Mobile session are started
-- 2. App is registered and activated
-- 3. CreateInteractionChoiceSet is added
--
-- Steps:
-- 1. App sends PerformInteraction request with BOTH interaction mode to SDL
-- 2. HMI responds with 'SUCCESS' to VR.PerformInteraction request without choiceID
-- SDL does:
-- - not send UI.ClosePopUp request to HMI
-- - send PerformInteraction response (resultCode: SUCCESS, success:true) to mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_1/3838/common")

--[[ Local Variables ]]
local initialPromptValue = common.getPromptValue(" Make your choice ")

local helpPromptValue = common.getPromptValue(" Help Prompt ")

local timeoutPromptValue = common.getPromptValue(" Time out ")

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
local function setExChoiceSet(pChoiceIDValues)
  local exChoiceSet = { }
  for i = 1, #pChoiceIDValues do
    exChoiceSet[i] = {
      choiceID = pChoiceIDValues[i],
      menuName = "Choice" .. pChoiceIDValues[i]
    }
  end
  return exChoiceSet
end

local function PI_ViaBOTH(pParams)
  local cid = common.getMobileSession():SendRPC("PerformInteraction",pParams)
  common.getHMIConnection():ExpectRequest("UI.ClosePopUp", { methodName = "UI.PerformInteraction" }):Times(0)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
      helpPrompt = pParams.helpPrompt,
      initialPrompt = pParams.initialPrompt,
      timeout = pParams.timeout,
      timeoutPrompt = pParams.timeoutPrompt
    })
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("VR.Started")
      common.getHMIConnection():SendNotification("TTS.Started")
      common.sendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("TTS.Started")
      end
      common.runAfter(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS") -- without choiceID
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
        common.sendOnSystemContext("HMI_OBSCURED")
      end
      common.runAfter(choiceIconDisplayed, 2050)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.sendOnSystemContext("MAIN")
      end
      common.runAfter(uiResponse, 3000)
    end)
  common.expectOnHMIStatusWithAudioStateChanged_PI("BOTH")
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    choiceID = pParams.interactionChoiceSetIDList[1], triggerSource = "MENU" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("CreateInteractionChoiceSet with id 100", common.createInteractionChoiceSet, { 100 })

common.Title("Test")
common.Step("PerformInteraction with BOTH interaction mode, without choiceID from VR response",
  PI_ViaBOTH, { requestParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
