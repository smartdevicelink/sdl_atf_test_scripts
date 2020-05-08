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
-- 2) New app registers and send AlertManeuver with ‘FILE’ item in ‘ttsChunks’ parameter
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
local function pTUpdateFunc(pTbl)
  table.insert(pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups, "Navigation-1")
end

local function sendAlertManeuver_FILE_NOT_FOUND()
  local corId = common.getMobileSession():SendRPC("AlertManeuver", params)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "FILE_NOT_FOUND" })
end

local function sendAlertManeuver_SUCCESS()
  local corId = common.getMobileSession():SendRPC("AlertManeuver", params)
  common.getHMIConnection():ExpectRequest("Navigation.AlertManeuver")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
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
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send AlertManeuver FILE_NOT_FOUND response", sendAlertManeuver_FILE_NOT_FOUND)
runner.Step("Upload icon file", common.putFile, { putFileParams })
runner.Step("Send AlertManeuver SUCCESS response", sendAlertManeuver_SUCCESS)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
