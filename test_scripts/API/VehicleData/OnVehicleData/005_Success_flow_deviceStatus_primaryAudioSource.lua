---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0182-audio-source-am-fm-xm.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1) Mobile app is subscribed to get deviceStatus vehicle data
-- 2) HMI sends OnVehicleData with value from PrimaryAudioSource enum in deviceStatus.primaryAudioSource
-- SDL must:
-- 1) Process OnVehicleData notification and transfer it to mobile
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

local rpc1 = {
  name = "SubscribeVehicleData",
  params = {
    deviceStatus = true
  }
}

local vehicleDataResults = {
  deviceStatus = {
    dataType = "VEHICLEDATA_DEVICESTATUS",
    resultCode = "SUCCESS"
  }
}

local rpc2 = {
  name = "OnVehicleData",
  params = {
    deviceStatus = {
      primaryAudioSource = "CD",
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
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess()
  local cid = common.getMobileSession():SendRPC(rpc1.name, rpc1.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", vehicleDataResults)
    end)

  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

local function checkNotificationSuccess(pAudioSource)
  rpc2.params.deviceStatus.primaryAudioSource = pAudioSource
  common.getHMIConnection():SendNotification("VehicleInfo." .. rpc2.name, rpc2.params)
  common.getMobileSession():ExpectNotification("OnVehicleData", rpc2.params)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("RPC " .. rpc1.name, processRPCSubscribeSuccess)
for _, source in pairs(audioSources) do
  common.Step("RPC " .. rpc2.name .. " source " .. source, checkNotificationSuccess, { source })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
