---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that app received two "OnHMIStatus" notifications with modified "systemContext" from "MAIN"
--  to VRSESSION and HMI_OBSCURED when an app and widget have FULL levels
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App creates a widget and it has NONE level
-- 5) Widget is activated on the HMI and has FULL level
-- Step:
-- 1) App sends Alert RPC
-- SDL does:
--  - send OnHMIStatus notification for main and widget window with VRSESSION and HMI_OBSCURED value
--    for a systemContext param to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function sendOnSystemContext(ctx, pWindowId, pAppId)
  if not pWindowId then pWindowId = 0 end
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(pAppId),
    systemContext = ctx,
    windowID = pWindowId
  })
end

local function createInteractionChoiceSet(pAppId)
  if not pAppId then pAppId = 1 end
  local paramsChoiceSet = {
    interactionChoiceSetID = 100,
    choiceSet = {
      {
        choiceID = 111,
        menuName = "Choice111",
        vrCommands = { "Choice111" }
      }
    }
}
  local cid = common.getMobileSession(pAppId):SendRPC("CreateInteractionChoiceSet", paramsChoiceSet)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function performInteraction(pAppId)
  if not pAppId then pAppId = 1 end
  local pMainId = 0
  local paramsPI = {
    initialText = "StartPerformInteraction",
    interactionMode = "BOTH",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    },
    helpPrompt = {
      { text = "Help Prompt", type = "TEXT" }
    },
    timeoutPrompt = {
      { text = "Time out Prompt", type = "TEXT" }
    },
    timeout = 5000,
    vrHelp = {
      { text = "New VRHelp", position = 1 }
    }
  }
  local cid = common.getMobileSession(pAppId):SendRPC("PerformInteraction", paramsPI)

  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    helpPrompt = paramsPI.helpPrompt,
    initialPrompt = paramsPI.initialPrompt,
    timeout = paramsPI.timeout,
    timeoutPrompt = paramsPI.timeoutPrompt
  })
  :Do(function(_, data)
    common.getHMIConnection():SendNotification("VR.Started")
    common.getHMIConnection():SendNotification("TTS.Started")
    sendOnSystemContext("VRSESSION", pMainId)
    sendOnSystemContext("VRSESSION", params.windowID)

    local function firstSpeakTimeOut()
      common.getHMIConnection():SendNotification("TTS.Stopped")
      common.getHMIConnection():SendNotification("TTS.Started")
    end
    RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        common.getHMIConnection():SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
    timeout = paramsPI.timeout,
    vrHelp = paramsPI.vrHelp,
    vrHelpTitle = "StartPerformInteraction"
  })
  :Do(function(_, data)
    local function choiceIconDisplayed()
      sendOnSystemContext("HMI_OBSCURED", pMainId)
      sendOnSystemContext("HMI_OBSCURED", params.windowID)
    end

    RUN_AFTER(choiceIconDisplayed, 25)
    local function uiResponse()
      common.getHMIConnection():SendNotification("TTS.Stopped")
      common.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
      sendOnSystemContext("MAIN", pMainId)
      sendOnSystemContext("MAIN", params.windowID)
    end
    RUN_AFTER(uiResponse, 30)
  end)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
  { systemContext = "MAIN", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "MAIN", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "VRSESSION", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "VRSESSION", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "VRSESSION", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "VRSESSION", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", windowID = params.windowID },
  { systemContext = "MAIN", hmiLevel = "FULL", windowID = pMainId },
  { systemContext = "MAIN", hmiLevel = "FULL", windowID = params.windowID })
  :Times(12)

  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT" })
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App create a widget", common.createWindow, { params })
common.Step("Widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params.windowID })
common.Step("Create InteractionChoiceSet", createInteractionChoiceSet)

common.Title("Test")
common.Step("Perform Interaction", performInteraction)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
