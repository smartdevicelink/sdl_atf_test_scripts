---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/1006 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.runAfter = actions.run.runAfter
m.policyTableUpdate = actions.policyTableUpdate
m.getParams = actions.app.getParams

--[[ Local Variables ]]
local function getPromptValue(pText)
  return {{
    text = pText,
    type = "TEXT"
  }}
end

local initialPromptValue = getPromptValue(" Make your choice ")
local helpPromptValue = getPromptValue(" Help Prompt ")
local timeoutPromptValue = getPromptValue(" Time out ")

local vrHelpvalue = {{
  text = " New VRHelp ",
  position = 1
}}

--[[ Common Variables ]]
m.errorMessage = "UI is not supported by system"

m.requestPiParams = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionChoiceSetIDList = { 100 },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY"
}

--[[ Common Functions ]]
function m.start()
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.UI.IsReady.params.available = false
  hmiParams.UI.GetCapabilities = nil
  hmiParams.UI.GetLanguage = nil
  hmiParams.UI.GetSupportedLanguages = nil
  actions.start(hmiParams)
end

function m.sendRPC(pParams)
  local cid = m.getMobileSession():SendRPC(pParams.rpc, pParams.requestParam)
  if pParams.expectExtraRequest then
    pParams.expectExtraRequest()
  end
  m.getHMIConnection():ExpectRequest("UI." .. pParams.rpc)
  :Times(0)
  m.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "UNSUPPORTED_RESOURCE",
    info = m.errorMessage
  })
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

function m.createInteractionChoiceSet()
  local cid = m.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
    interactionChoiceSetID = 100,
    choiceSet =   {{
      choiceID = 100,
      menuName ="Choice_100",
      vrCommands = { "VrChoice_100" }
    }},
  })
  m.getHMIConnection():ExpectRequest("VR.AddCommand", {
    cmdID = 100,
    type = "Choice",
    vrCommands = { "VrChoice_100" }
  })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  m.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

return m
