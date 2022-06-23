---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends PerformInteraction response with SUCCESS, success:true for UI/VR-related RPC
--  and 'BOTH' interaction mode in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- 4. CreateInteractionChoiceSet is added
-- Steps:
-- 1. App requests PerformInteraction with 'BOTH' interaction mode to SDL
-- SDL does:
-- - not send UI.PerformInteraction request to HMI
-- - send VR.PerformInteraction request to HMI
-- - respond PerformInteraction with (resultCode: SUCCESS, success: true) to App only in case user provide the choice
-- - respond PerformInteraction with (resultCode: TIMED_OUT, success: false) to App in case user does not provide choice
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Functions ]]
local function sendPerformInteractionBothVrChoice(pParams)
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
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(firstSpeakTimeOut, 1000)
      local function vrResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      common.runAfter(vrResponse, 2000)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    choiceID = pParams.interactionChoiceSetIDList[1],
    triggerSource = "VR",
    info = common.errorMessage
  })
end

local function sendPerformInteractionBoth(pParams)
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
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      common.runAfter(vrResponse, 20)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Times(0)

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "TIMED_OUT",
    info = "Perform Interaction error response"
  })
end

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("CreateInteractionChoiceSet", common.createInteractionChoiceSet)

common.Title("Test")
common.Step("PerformInteraction with BOTH interaction mode choice via VR", sendPerformInteractionBothVrChoice,
  { common.requestPiParams  })
common.Step("PerformInteraction with BOTH interaction mode TIMED_OUT", sendPerformInteractionBoth,
  { common.requestPiParams  })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
