---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0182-audio-source-am-fm-xm.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) Mobile app is subscribed to get interior vehicle data for module AUDIO
-- 2) HMI sends OnInteriorVehicleData with source from PrimaryAudioSource enum
-- SDL must:
-- 1) Process this notification and transfer it to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function isSubscribed(pAudioSources)
	local moduleType = "AUDIO"
  local mobSession = common.getMobileSession(1)
  local rpc = "OnInteriorVehicleData"
  local hmiParams = common.getHMIResponseParams(rpc, moduleType)
  hmiParams.moduleData.audioControlData.source = pAudioSources
  local mobileParams = common.getAppResponseParams(rpc, moduleType)
  mobileParams.moduleData.audioControlData.source = pAudioSources
  mobileParams.moduleData.audioControlData.keepContext = nil
  common.getHMIConnection():SendNotification(common.getHMIEventName(rpc), hmiParams)
  mobSession:ExpectNotification(common.getAppEventName(rpc), mobileParams)
  :ValidIf(function(_,data)
      if nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile notification OnInteriorVehicleData contains unexpected keepContext parameter"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe app to AUDIO", common.subscribeToModule, { "AUDIO" })

runner.Title("Test")

for _, source in pairs(common.audioSources) do
  runner.Step("Send notification OnInteriorVehicleData " .. source .. ". App is subscribed", isSubscribed, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
