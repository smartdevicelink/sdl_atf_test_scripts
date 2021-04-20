---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2990
--
-- Steps:
-- 1. Start SDL, HMI, connect Mobile device
-- 2. Register mobile application
-- 3. Activate application
-- 4. App creates a few interaction choice sets
-- 5. App tries to do PerformInteraction in BOTH mode
-- SDL does:
--   - forwards VR.PerformInteraction and UI.PerformInteraction requests to HMI
-- 5. HMI replies with one of the following:
--   a) different ChoiceID from UI and VR
--   b) the same ChoiceID from UI and VR
--   c) some ChoiceID from VR only
--   d) some ChoiceID from UI only
-- SDL does respond to the App with one of the following:
--   a) success = false, resultCode = "GENERIC_ERROR", choiceID = nil
--   b) success = true, resultCode = "SUCCESS", choiceID = <VR_choiceID> or <UI_choiceID>
--   c) success = true, resultCode = "SUCCESS", choiceID = <VR_choiceID>
--   d) success = true, resultCode = "SUCCESS", choiceID = <UI_choiceID>
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local ImageValue = {
  value = common.getPathToFileInAppStorage("icon.png"),
  imageType = "DYNAMIC",
}

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

local vrHelpvalue = {
  {
    text = " New VRHelp ",
    position = 1,
    image = ImageValue
  }
}

local requestParams = {
  initialText = "StartPerformInteraction",
  initialPrompt = initialPromptValue,
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
    100, 200, 300
  },
  helpPrompt = helpPromptValue,
  timeoutPrompt = timeoutPromptValue,
  timeout = 5000,
  vrHelp = vrHelpvalue,
  interactionLayout = "ICON_ONLY",
}

--[[ Local Functions ]]
local function setChoiceSet(pChoiceIDValue)
  local temp = {
    {
      choiceID = pChoiceIDValue,
      menuName ="Choice" .. tostring(pChoiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(pChoiceIDValue),
      },
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

local function sendOnSystemContext(pCtx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext", {
    appID = common.getHMIAppId(),
    systemContext = pCtx
  })
end

local function setExChoiceSet(pChoiceIDValues)
  local exChoiceSet = { }
  for i = 1, #pChoiceIDValues do
    exChoiceSet[i] = {
      choiceID = pChoiceIDValues[i],
      image = {
        value = "icon.png",
        imageType = "STATIC",
      },
      menuName = "Choice" .. pChoiceIDValues[i]
    }
  end
  return exChoiceSet
end

local function createInteractionChoiceSet(pChoiceSetID)
  local choiceID = pChoiceSetID
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = pChoiceSetID,
      choiceSet = setChoiceSet(choiceID),
    })
  common.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function PI_ViaBOTH(pVRChoiceID, pUIhoiceID)
  local pParams = requestParams
  local appChoiceID = pVRChoiceID or pUIhoiceID
  local appExp = { success = true, resultCode = "SUCCESS", choiceID = appChoiceID }
  if pVRChoiceID ~= nil and pUIhoiceID ~= nil and pVRChoiceID ~= pUIhoiceID then
    appExp = { success = false, resultCode = "GENERIC_ERROR", choiceID = nil }
  end
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
      sendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(firstSpeakTimeOut, 1000)
      local function vrResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { choiceID = pVRChoiceID })
        common.getHMIConnection():SendNotification("VR.Stopped")
        sendOnSystemContext("MAIN")
      end
      common.runAfter(vrResponse, 2000)
    end)

  common.getHMIConnection():ExpectRequest("UI.PerformInteraction", {
      timeout = pParams.timeout,
      choiceSet = setExChoiceSet(pParams.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = pParams.initialText
      },
      vrHelp = pParams.vrHelp,
      vrHelpTitle = pParams.initialText
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        sendOnSystemContext("HMI_OBSCURED")
      end
      common.runAfter(choiceIconDisplayed, 2050)
      local function uiResponse()
        common.getHMIConnection():SendNotification("TTS.Stopped")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { choiceID = pUIhoiceID })
        sendOnSystemContext("MAIN")
      end
      common.runAfter(uiResponse, 3000)
    end)

  common.getMobileSession():ExpectResponse(cid, appExp)
  :ValidIf(function(_, data)
      if data.payload.choiceID ~= appExp.choiceID then
        return false, "Expected choiceID:'" .. tostring(appExp.choiceID)
          .. "', actual: '" .. tostring(data.payload.choiceID) .. "'"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })
runner.Step("CreateInteractionChoiceSet with id 100", createInteractionChoiceSet, { 100 })
runner.Step("CreateInteractionChoiceSet with id 200", createInteractionChoiceSet, { 200 })
runner.Step("CreateInteractionChoiceSet with id 300", createInteractionChoiceSet, { 300 })

runner.Title("Test")
runner.Step("PerformInteraction with different ChoiceID from UI and VR", PI_ViaBOTH, { 100, 200 })
runner.Step("PerformInteraction with the same ChoiceID from UI and VR", PI_ViaBOTH, { 100, 100 })
runner.Step("PerformInteraction with ChoiceID from VR only", PI_ViaBOTH, { 100, nil })
runner.Step("PerformInteraction with ChoiceID from UI only", PI_ViaBOTH, { nil, 100 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
