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
-- 2) New app registers and send Alert with ‘FILE’ item in ‘ttsChunks’ parameter
-- SDL does:
-- 1) Send TTS.Speak request to HMI with ‘FILE’ item in ‘ttsChunks’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/TTSChunks/common')

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'pathToFile',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local params = {
  ttsChunks = {
    { type = common.type, text = "pathToFile" }
  }
}

local hmiParams = {
  ttsChunks = {
    { type = common.type, text = common.getPathToFileInStorage("pathToFile") }
  }
}

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendAlert_FILE_NOT_FOUND()
  local corId = common.getMobileSession():SendRPC("Alert", params)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "FILE_NOT_FOUND" })
end

local function sendAlert_SUCCESS()
  local corId = common.getMobileSession():SendRPC("Alert", params)
  common.getHMIConnection():ExpectRequest("TTS.Speak", { ttsChunks = hmiParams.ttsChunks })
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
runner.Step("Send Alert FILE_NOT_FOUND response", sendAlert_FILE_NOT_FOUND)
runner.Step("Upload icon file", common.putFile, { putFileParams })
runner.Step("Send Alert SUCCESS response", sendAlert_SUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
