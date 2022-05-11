---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1006
---------------------------------------------------------------------------------------------------
-- Description: SDL sends PerformInteraction response with UNSUPPORTED_RESOURCE, success:false for UI/VR-related RPC
--  and 'MANUAL_ONLY' interaction mode in case HMI responds UI.IsReady with "available" = false
--
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. HMI responds with 'available' = false on UI.IsReady request from SDL
-- 3. App is registered and activated
-- 4. CreateInteractionChoiceSet is added
-- Steps:
-- 1. App requests PerformInteraction with <interaction_mode> to SDL
-- SDL does:
-- - not send UI.PerformInteraction request to HMI
-- - send VR.PerformInteraction request to HMI
-- - respond PerformInteraction with (resultCode: UNSUPPORTED_RESOURCE, success: false) to App
--  only in case 'MANUAL_ONLY' interaction mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/1006/common")

--[[ Local Functions ]]
local function sendPerformInteractionManualOnly(pParams)
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
      common.getHMIConnection():SendNotification("TTS.Stopped")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Times(0)

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "UNSUPPORTED_RESOURCE",
    info = common.errorMessage
  })
end

local function sendPerformInteractionVrOnly(pParams)
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

        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = pParams.interactionChoiceSetIDList[1] })
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      common.runAfter(vrResponse, 1000)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    choiceID = pParams.interactionChoiceSetIDList[1],
    triggerSource = "VR"
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
common.Step("PerformInteraction with MANUAL_ONLY interaction mode", sendPerformInteractionManualOnly,
  { common.requestPiParams })
common.Step("PerformInteraction with VR_ONLY interaction mode", sendPerformInteractionVrOnly,
  { common.requestPiParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
