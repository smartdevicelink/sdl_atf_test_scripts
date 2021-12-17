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
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

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
  common.run.runAfter(function() sendPI("ChoiceVR2", "REJECTED") end, 500)
  common.getHMIConnection():ExpectRequest("UI.ClosePopUp", { methodName = "UI.PerformInteraction" })
  :Times(0)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
  :Do(function(exp, data)
      if exp.occurences == 1 then
        common.run.runAfter(function()
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
      common.run.runAfter(function()
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
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet with id 100", createInteractionChoiceSet, { 100 })

runner.Title("Test")
runner.Step("Two PerformInteraction requests with VR_ONLY", PI_ViaVR_ONLY)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
