---------------------------------------------------------------------------------------------------
--Issue: https://github.com/smartdevicelink/sdl_core/issues/3309
---------------------------------------------------------------------------------------------------
-- In case:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) `shifted` param in `gps` structure have since=6.0 in DB and API
-- 3) App subscribed on vehicle data (gps)
-- 4) App sends GetVehicleData (gps) request
-- 5) SDL transfers this request to HMI
-- 6) HMI sends GetVehicleData response with "shifted" item
-- SDL does:
--  a) cut off the `shifted` param from HMI response that allowed for apps starting from 6.0 version
--  b) send GetVehicleData response to mobile app without not allowed param
-- 7) HMI sends "shifted" item in "gps" parameter of OnVehicleData notification
-- SDL does:
--  a) cut off the `shifted` param from HMI notification that allowed for apps starting from 6.0 version
--  b) send OnVehicleData notification to app without "shifted" item in "gps" parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Functions ]]
local function getVehicleData(pShiftValue)
  common.gpsParams.shifted = pShiftValue
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { gps = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = common.gpsParams })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = common.gpsParams })
  :ValidIf(function(_,data)
    if data.payload.gps.shifted ~= nil then
      return false, "Unexpected params are received in GetVehicleData response"
    end
    return true
  end)
end

local function sendOnVehicleData(pShiftValue)
  common.gpsParams.shifted = pShiftValue
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = common.gpsParams })
  common.getMobileSession():ExpectNotification("OnVehicleData", { gps = common.gpsParams })
  :ValidIf(function(_,data)
    if data.payload.gps.shifted ~= nil then
      return false, "Unexpected params are received in GetVehicleData response"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe on GPS VehicleData", common.subscribeVehicleData)

runner.Title("Test")
for _, v in pairs(common.shiftValue) do
  runner.Step("Get GPS VehicleData, gps-shifted " .. tostring(v), getVehicleData, { v })
  runner.Step("Send On VehicleData with GpsShift " .. tostring(v), sendOnVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
