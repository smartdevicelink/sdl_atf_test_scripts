---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0014-adding-audio-file-playback-to-ttschunk.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) HMI provides ‘FILE’ item in ‘speechCapabilities’ parameter of ‘TTS.GetCapabilities’ response
-- 2) New app registers and send PerformInteraction with ‘FILE’ item in ‘initialPrompt’, ‘helpPrompt’,
-- ‘timeoutPrompt’ parameters
-- SDL does:
-- 1) Send VR.PerformInteraction request to HMI with ‘FILE’ item in ‘initialPrompt’, ‘helpPrompt’,
-- ‘timeoutPrompt’ parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/TTSChunks/common')

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'pathToFile1',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local putFileParams2 = {
  requestParams = {
    syncFileName = 'pathToFile2',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local putFileParams3 = {
  requestParams = {
    syncFileName = 'pathToFile3',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}


local params = {
  initialText = "StartPerformInteraction",
  interactionMode = "VR_ONLY",
  interactionChoiceSetIDList = { 100 },
  initialPrompt = {
    { type = common.type, text = "pathToFile1" }
  },
  helpPrompt = {
    { type = common.type, text = "pathToFile2" }
  },
  timeoutPrompt = {
    { type = common.type, text = "pathToFile3" }
  }
}


local hmiParams = {
  initialPrompt = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile1") }
  },
  helpPrompt = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile2") }
  },
  timeoutPrompt = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile3") }
  }
}

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function createInteractionChoiceSet()
  local choiceParams = {
    interactionChoiceSetID = 100,
    choiceSet = {
      {
        choiceID = 111,
        menuName = "Choice111",
        vrCommands = { "Choice111" }
      }
    }
  }
  local corId = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

local function sendPerformInteraction_FILE_NOT_FOUND()
  local corId = common.getMobileSession():SendRPC("PerformInteraction", params)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "FILE_NOT_FOUND" })
end

local function sendPerformInteraction_SUCCESS()
  local corId = common.getMobileSession():SendRPC("PerformInteraction", params)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = hmiParams.initialPrompt,
    helpPrompt = hmiParams.helpPrompt,
    timeoutPrompt = hmiParams.timeoutPrompt
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Create InteractionChoiceSet", createInteractionChoiceSet)

runner.Title("Test")
runner.Step("Send PerformInteraction FILE_NOT_FOUND response", sendPerformInteraction_FILE_NOT_FOUND)
runner.Step("Upload first icon file", common.putFile, { putFileParams })
runner.Step("Upload second icon file", common.putFile, { putFileParams2 })
runner.Step("Upload third icon file", common.putFile, { putFileParams3 })
runner.Step("Send PerformInteraction SUCCESS response", sendPerformInteraction_SUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
