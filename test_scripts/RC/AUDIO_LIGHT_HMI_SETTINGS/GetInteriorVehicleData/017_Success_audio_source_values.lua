---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0182-audio-source-am-fm-xm.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1) Mobile app sends GetInteriorVehicleData request with moduleType=AUDIO
-- 2) SDL transfers this request to HMI
-- 3) HMI responds with source from PrimaryAudioSource enum
-- SDL must:
-- 1) Process this response and transfer it to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function subscribeToModule(pAudioSources)
  local rpc = "GetInteriorVehicleData"
  local subscribe = nil
  local moduleType = "AUDIO"
  local mobSession = common.getMobileSession(1)
  local hmiResponseParams = common.getHMIResponseParams(rpc, moduleType, subscribe)
  hmiResponseParams.moduleData.audioControlData.source = pAudioSources
  hmiResponseParams.moduleData.audioControlData.keepContext = nil
  local mobileResponseParams = common.getAppResponseParams(rpc, true, "SUCCESS", moduleType, subscribe)
  mobileResponseParams.moduleData.audioControlData.source = pAudioSources
  local cid = mobSession:SendRPC(common.getAppEventName(rpc), common.getAppRequestParams(rpc, moduleType, subscribe))
  EXPECT_HMICALL(common.getHMIEventName(rpc), common.getHMIRequestParams(rpc, moduleType, 1, subscribe))
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseParams)
    end)
  mobSession:ExpectResponse(cid, mobileResponseParams)
  :ValidIf(function(_,data)
      if nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
      end
      return true
    end)
  common.wait(500)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, source in pairs(common.audioSources) do
  runner.Step("GetInteriorVehicleData source " .. source, subscribeToModule, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
