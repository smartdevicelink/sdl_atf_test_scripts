---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getHMIAppId = actions.app.getHMIId

--[[ Common Variables ]]
m.tcs = {
  [01] = "WARNINGS",
  [02] = "TRUNCATED_DATA",
  [03] = "RETRY",
  [04] = "SAVED",
  [05] = "WRONG_LANGUAGE",
  [06] = "UNSUPPORTED_RESOURCE"
}

m.responsesStructures = {
  result = function(data, code) m.getHMIConnection():SendResponse(data.id, data.method, code, {}) end,
  error = function(data, code) m.getHMIConnection():SendError(data.id, data.method, code, "Error message") end
}

--[[ Local Functions ]]
local function getCICSparams(choiceId)
  local requestParams = {
    interactionChoiceSetID = choiceId,
    choiceSet = {
      {
        choiceID = choiceId,
        menuName ="Choice" .. choiceId,
        vrCommands = {
          "Choice" .. choiceId
        }
      }
    }
  }

  local vrRequest = {
    cmdID = requestParams.interactionChoiceSetID,
    type = "Choice",
    vrCommands = requestParams.vrCommands
  }

  local allParams = {
    requestParams = requestParams,
    vrRequest = vrRequest
  }

  return allParams
end

local function getPIparams(choiceSetID)
  local function getPromptValue(pText)
    return {
      {
        text = pText,
        type = "TEXT"
      }
    }
  end

  local initialPromptValue = getPromptValue("Make your choice")

  local helpPromptValue = getPromptValue("Help Prompt")

  local timeoutPromptValue = getPromptValue("Time out")

  local vrHelpvalue = {
    {
      text = "New VRHelp",
      position = 1
    }
  }
  local requestParams = {
    initialText = "StartPerformInteraction",
    initialPrompt = initialPromptValue,
    interactionMode = "BOTH",
    interactionChoiceSetIDList = {
      choiceSetID
    },
    helpPrompt = helpPromptValue,
    timeoutPrompt = timeoutPromptValue,
    timeout = 5000,
    vrHelp = vrHelpvalue,
    interactionLayout = "ICON_ONLY"
  }
  return requestParams
end

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

function m.createInteractionChoiceSet(choiceNumber, response)
  local params = getCICSparams(choiceNumber)
  local cid = m.getMobileSession():SendRPC("CreateInteractionChoiceSet", params.requestParams)

  params.vrRequest.appID = m.getHMIAppId()
  m.getHMIConnection():ExpectRequest("VR.AddCommand", params.vrRequest)
  :Do(function(_, data)
      response.structure(data, response.code)
    end)

  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = response.code })
  m.getMobileSession():ExpectNotification("OnHashChange")
end

function m.performInteraction(choiceId)
  local params = getPIparams(choiceId)
  params.interactionMode = "BOTH"
  local cid = m.getMobileSession():SendRPC("PerformInteraction", params)
  m.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    helpPrompt = params.helpPrompt,
    initialPrompt = params.initialPrompt,
    timeout = params.timeout,
    timeoutPrompt = params.timeoutPrompt
  })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { choiceID = choiceId })
    end)
  m.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
    timeout = params.timeout,
    choiceSet = setExChoiceSet(params.interactionChoiceSetIDList),
    initialText = {
      fieldName = "initialInteractionText",
      fieldText = params.initialText
    },
    vrHelp = params.vrHelp,
    vrHelpTitle = params.initialText
  })
  :Do(function(_, data)
      m.getHMIConnection():SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", choiceID = choiceId })
end

return m
