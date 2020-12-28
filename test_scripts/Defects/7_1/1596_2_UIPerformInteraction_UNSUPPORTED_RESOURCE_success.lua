---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1596
--
-- Description:
-- HMI responds with UNSUPPORTED_RESOURCE to single PerformInteraction component
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session started
-- 3) Registered app
-- 4) Activated app
--
-- Steps: 
-- 1) Send PerformInteraction mobile RPC from app with type BOTH, HMI responds with UNSUPPORTED_RESOURCE 
--    and choiceID for UI portion
--
-- Expected:
-- 1) App receives PerformInteraction response with choiceID from UI response, UNSUPPORTED_RESOURCE 
--    result code, and success=true
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
        vrCommands = { "Choice111" },
        choiceImage = {
          value = "0x11",
          imageType = "STATIC"
        }
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
      { type = "TEXT", text = "Initial Prompt" }
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
  
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    common.getHMIConnection():SendNotification("VR.Stopped")
  end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
    timeout = paramsPI.timeout,
    vrHelp = paramsPI.vrHelp,
    vrHelpTitle = "StartPerformInteraction"
  })
  :Do(function(_, data)
    sendOnSystemContext("HMI_OBSCURED", pMainId)

    local function uiResponse()
      common.getHMIConnection():SendNotification("TTS.Stopped")
      common.getHMIConnection():SendResponse(data.id, data.method, "UNSUPPORTED_RESOURCE", { choiceID = 111 })
      sendOnSystemContext("MAIN", pMainId)
    end
    RUN_AFTER(uiResponse, 5)
  end)

  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", choiceID = 111 })
end

--[[ Scenario ]]
runner.Title("Precondition")
runner.Step("Clean environment and Back-up/update PPT", common.preconditions)
runner.Step("Start SDL, HMI", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", createInteractionChoiceSet)

runner.Title("Test")
runner.Step("Perform Interaction", performInteraction)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
