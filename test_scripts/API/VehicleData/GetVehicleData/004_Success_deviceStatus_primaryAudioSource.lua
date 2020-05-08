---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0182-audio-source-am-fm-xm.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1) Mobile app sends GetVehicleData request with deviceStatus=true
-- 2) SDL transfers this request to HMI
-- 3) HMI responds with value from PrimaryAudioSource enum in deviceStatus.primaryAudioSource
-- SDL must:
-- 1) Process GetVehicleData response and transfer it to mobile
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local audioSources = {
  "NO_SOURCE_SELECTED",
  "CD",
  "BLUETOOTH_STEREO_BTST",
  "USB",
  "USB2",
  "LINE_IN",
  "IPOD",
  "MOBILE_APP",
  "AM",
  "FM",
  "XM",
  "DAB"
}

local rpc = {
  name = "GetVehicleData",
  params = {
    deviceStatus = true
  }
}

--[[ Local Functions ]]
local function processRPCSuccess(pAudioSource)
  local cid = common.getMobileSession():SendRPC(rpc.name, rpc.params)
  local vehicleDataValues = {
    deviceStatus = {
      primaryAudioSource = pAudioSource,
      voiceRecOn = false,
      btIconOn = false,
      callActive = false,
      phoneRoaming = false,
      textMsgAvailable = false,
      battLevelStatus = "TWO_LEVEL_BARS",
      stereoAudioOutputMuted = false,
      monoAudioOutputMuted = false,
      signalLevelStatus = "ONE_LEVEL_BARS",
      eCallEventActive = false
    }
  }
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", vehicleDataValues)
    end)
  local responseParams = vehicleDataValues
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
  common.wait(300)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for _, source in pairs(audioSources) do
  common.Step("RPC " .. rpc.name .. " source " .. source, processRPCSuccess, { source })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
