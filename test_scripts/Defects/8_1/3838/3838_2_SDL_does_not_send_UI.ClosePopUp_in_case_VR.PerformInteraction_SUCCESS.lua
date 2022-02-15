---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3838
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send UI.ClosePopUp to HMI in case:
-- - mobile App sends PerformInteraction request with VR_ONLY interaction mode to SDL
-- - HMI responds with 'SUCCESS' to VR.PerformInteraction request
--
-- Pre-conditions:
-- 1. SDL, HMI, Mobile session are started
-- 2. App is registered and activated
-- 3. CreateInteractionChoiceSet is added
-- Steps:
-- 1. App sends PerformInteraction request with VR_ONLY interaction mode to SDL
-- 2. HMI responds with 'SUCCESS' to UI.PerformInteraction request
-- 3. HMI responds with 'SUCCESS' to VR.PerformInteraction request
-- SDL does:
-- - not send UI.ClosePopUp request to HMI
-- - send PerformInteraction response with choiceID from VR response (resultCode: SUCCESS, success:true) to mobile App
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
  interactionMode = "VR_ONLY",
  interactionChoiceSetIDList = { 100 },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY"
}

--[[ Local Functions ]]
local function PI_ViaVR_ONLY(pParams)
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
        common.sendOnSystemContext("VRSESSION")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("VR.Stopped")
        common.sendOnSystemContext("MAIN")
      end
      common.runAfter(vrResponse, 1000)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
    timeout = pParams.timeout,
    vrHelp = pParams.vrHelp,
    vrHelpTitle = pParams.initialText,
  })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.expectOnHMIStatusWithAudioStateChanged_PI("VR")
  common.getMobileSession():ExpectResponse(cid, {
    success = true, resultCode = "SUCCESS", choiceID = pParams.interactionChoiceSetIDList[1]
  })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("CreateInteractionChoiceSet with id 100", common.createInteractionChoiceSet, { 100 })

common.Title("Test")
common.Step("PerformInteraction with VR_ONLY interaction mode", PI_ViaVR_ONLY, { requestParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
