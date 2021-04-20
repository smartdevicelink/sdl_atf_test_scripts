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
-- 2) New app registers with ‘FILE’ item in ‘ttsName’ parameter
-- SDL does:
-- 1) Send BC.OnAppRegistered notification to HMI with ‘FILE’ item in ‘ttsName’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/TTSChunks/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function registerApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local params = common.getConfigAppParams()
      params.ttsName = {
        { type = common.type, text = "pathToFile" }
      }
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        ttsName = {
          { type = common.type, text = common.getPathToFileInStorage("pathToFile") }
        }
      })
      -- WARNINGS response is received since `pathToFile` is not a valid file
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "WARNINGS" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Register App", registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
