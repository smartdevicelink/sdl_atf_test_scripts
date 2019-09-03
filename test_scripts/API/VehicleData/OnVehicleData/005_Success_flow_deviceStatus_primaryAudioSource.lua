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
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local utils = require('user_modules/utils')

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
      primaryAudioSource = "CD"
    }
  }
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc1.name, rpc1.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", vehicleDataResults)
    end)

  local responseParams = utils.cloneTable(vehicleDataResults)
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function checkNotificationSuccess(pAudioSource, self)
  rpc2.params.deviceStatus.primaryAudioSource = pAudioSource
  local mobileSession = common.getMobileSession(self, 1)
  self.hmiConnection:SendNotification("VehicleInfo." .. rpc2.name, rpc2.params)
  mobileSession:ExpectNotification("OnVehicleData", rpc2.params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc1.name, processRPCSubscribeSuccess)
for _, source in pairs(audioSources) do
  runner.Step("RPC " .. rpc2.name .. " source " .. source, checkNotificationSuccess, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
