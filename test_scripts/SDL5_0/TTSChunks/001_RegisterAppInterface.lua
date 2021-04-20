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
-- 2) New app registers
-- SDL does:
-- 1) Send ‘RegisterAppInterface’ response to mobile app with ‘FILE’ item in ‘speechCapabilities’ parameter
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
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams().appName } })
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :ValidIf(function(_, data)
          for _, v in pairs(data.payload.speechCapabilities) do
            if v == common.type then return true end
          end
          return false, "'" .. common.type .. "'"
            .. " item was not provided in 'speechCapabilities' of 'RegisterAppInterface' response"
        end)
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
        end)
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
