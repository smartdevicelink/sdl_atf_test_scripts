---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3838
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL does not send UI.ClosePopUp to HMI in case
--  mobile App sends two PerformInteraction request with VR_ONLY interaction mode to SDL
--
-- Pre-conditions:
-- 1. SDL, HMI, Mobile session are started
-- 2. App is registered and activated
-- 3. ChoiceSets is added
-- Steps:
-- 1. Mobile app requests PerformInteraction(VR_ONLY) to SDL
-- 2. Mobile app requests PerformInteraction(VR_ONLY) one more time while the first one is in progress
-- 3. HMI responds with 'REJECTED' to second UI/VR.PerformInteraction requests
-- SDL does:
-- - not send UI.ClosePopUp request to HMI
-- - send PerformInteraction response with (resultCode: REJECTED, success:false) to mobile App
-- 4. HMI responds with 'SUCCESS' to first UI/VR.PerformInteraction requests
-- SDL does:
-- - send PerformInteraction response with choiceID from VR response (resultCode: SUCCESS, success:true) to mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_1/3838/common")
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local initialPromptValue = common.getPromptValue(" Make your choice ")

local helpPromptValue = common.getPromptValue(" Help Prompt ")

local timeoutPromptValue = common.getPromptValue(" Time out ")

--[[ Local Functions ]]
local function sendPI(pChoiceVR, pExpResult)
  local params1 = {
    initialText = "StartPerformInteraction",
    initialPrompt = initialPromptValue,
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    helpPrompt = helpPromptValue,
    timeoutPrompt = timeoutPromptValue,
    timeout = 5000,
    vrHelp = { { text = pChoiceVR, position = 1 } }
  }
  local cid = common.getMobileSession():SendRPC("PerformInteraction", params1)
  local success = true
  if pExpResult ~= "SUCCESS" then success = false end
  common.getMobileSession():ExpectResponse(cid, { success = success, resultCode = pExpResult })
end

local function PI_ViaVR_ONLY()
  sendPI("ChoiceVR1", "SUCCESS")
  common.runAfter(function() sendPI("ChoiceVR2", "REJECTED") end, 500)
  common.getHMIConnection():ExpectRequest("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
  :Times(0)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
  :Do(function(exp, data)
      if exp.occurences == 1 then
        common.runAfter(function()
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
            { choiceID = 100 })
          end, 1500)
      else
        common.getHMIConnection():SendError(data.id, data.method, "REJECTED",
          "VR.PerformInteraction is already in progress")
      end
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(exp, data)
      if exp.occurences == 1 then
      common.runAfter(function()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        end, 1000)
      else
        common.getHMIConnection():SendError(data.id, data.method, "REJECTED",
          "UI.PerformInteraction is already in progress")
      end
    end)
  :Times(2)

  utils.wait(5000)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("CreateInteractionChoiceSet with id 100", common.createInteractionChoiceSet, { 100 })

common.Title("Test")
common.Step("Two PerformInteraction requests with VR_ONLY", PI_ViaVR_ONLY)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
