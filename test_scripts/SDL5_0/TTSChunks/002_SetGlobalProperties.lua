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
-- 2) New app registers and send SetGlobalProperties with ‘FILE’ item in ‘helpPrompt’, ‘timeoutPrompt’ parameters
-- SDL does:
-- 1) Send TTS.SetGlobalProperties request to HMI with ‘FILE’ item in ‘helpPrompt’, ‘timeoutPrompt’ parameters
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

local params = {
  helpPrompt = {
    { type = common.type, text = "pathToFile1" }
  },
  timeoutPrompt = {
    { type = common.type, text = "pathToFile2" }
  }
}

local hmiParams = {
  helpPrompt = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile1") }
  },
  timeoutPrompt = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile2") }
  }
}

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendSetGlobalProperties_FILE_NOT_FOUND()
  local corId = common.getMobileSession():SendRPC("SetGlobalProperties", params)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "FILE_NOT_FOUND" })
end

local function sendSetGlobalProperties_SUCCESS()
  local corId = common.getMobileSession():SendRPC("SetGlobalProperties", params)
  common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {
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

runner.Title("Test")
runner.Step("Send SetGlobalProperties FILE_NOT_FOUND response", sendSetGlobalProperties_FILE_NOT_FOUND)
runner.Step("Upload first icon file", common.putFile, { putFileParams })
runner.Step("Upload second icon file", common.putFile, { putFileParams2 })
runner.Step("Send SetGlobalProperties SUCCESS response", sendSetGlobalProperties_SUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
