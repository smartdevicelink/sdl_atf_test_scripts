---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/3838 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.runAfter = actions.run.runAfter

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

--[[ Common Functions ]]
function m.getPromptValue(pText)
  return {
    {
      text = pText,
      type = "TEXT"
    }
  }
end

function m.sendOnSystemContext(pCtx)
  actions.getHMIConnection():SendNotification("UI.OnSystemContext", {
    appID = actions.getHMIAppId(),
    systemContext = pCtx
  })
end

function m.expectOnHMIStatusWithAudioStateChanged_PI(pRequest)
  if pRequest == "BOTH" then
    actions.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION" },
      { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(6)
  elseif pRequest == "VR" then
    actions.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(5)
  elseif pRequest == "MANUAL" then
    actions.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  end
end

function m.createInteractionChoiceSet(pChoiceSetID)
  local cid = actions.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
    interactionChoiceSetID = pChoiceSetID,
    choiceSet = setChoiceSet(pChoiceSetID),
  })
  actions.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = pChoiceSetID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(pChoiceSetID) }
    })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  actions.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

return m
