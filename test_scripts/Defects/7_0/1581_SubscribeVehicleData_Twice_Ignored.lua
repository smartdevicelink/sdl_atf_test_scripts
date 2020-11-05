---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/1581
--
-- Steps:
-- 1) Start SDL core and HMI
-- 2) Connect a mobile app and activate app
-- 3) Subscribe to some vehicle data
-- 4) Try to subscribe to the same vehicle data again

-- Expected:
-- SDL replies success: true, resultCode: SUCCESS to first request to subscribe to vehicle data
-- SDL replies success: false, resultCode: IGNORED to second request to subscribe to vehicle data
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local VDValues = {
  gps = "VEHICLEDATA_GPS",
  speed = "VEHICLEDATA_SPEED",
  rpm = "VEHICLEDATA_RPM",
  fuelLevel = "VEHICLEDATA_FUELLEVEL",
  fuelLevel_State = "VEHICLEDATA_FUELLEVEL_STATE",
  fuelRange = "VEHICLEDATA_FUELRANGE",
  instantFuelConsumption = "VEHICLEDATA_FUELCONSUMPTION",
  externalTemperature = "VEHICLEDATA_EXTERNTEMP",
  turnSignal = "VEHICLEDATA_TURNSIGNAL",
  prndl = "VEHICLEDATA_PRNDL",
  tirePressure = "VEHICLEDATA_TIREPRESSURE",
  odometer = "VEHICLEDATA_ODOMETER",
  beltStatus = "VEHICLEDATA_BELTSTATUS",
  electronicParkBrakeStatus = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
  bodyInformation = "VEHICLEDATA_BODYINFO",
  deviceStatus = "VEHICLEDATA_DEVICESTATUS",
  driverBraking = "VEHICLEDATA_BRAKING",
  wiperStatus = "VEHICLEDATA_WIPERSTATUS",
  headLampStatus = "VEHICLEDATA_HEADLAMPSTATUS",
  engineTorque = "VEHICLEDATA_ENGINETORQUE",
  engineOilLife = "VEHICLEDATA_ENGINEOILLIFE",
  accPedalPosition = "VEHICLEDATA_ACCPEDAL",
  steeringWheelAngle = "VEHICLEDATA_STEERINGWHEEL",
  eCallInfo = "VEHICLEDATA_ECALLINFO",
  airbagStatus = "VEHICLEDATA_AIRBAGSTATUS",
  emergencyEvent = "VEHICLEDATA_EMERGENCYEVENT",
  myKey = "VEHICLEDATA_MYKEY"
}

local requestParams = {}
for k, _ in pairs(VDValues) do
  requestParams[k] = true
end

local function genResponse(pCode)
  local temp = { }
  for key, value in pairs(VDValues) do
    temp[key] = {
      resultCode = pCode,
      dataType = value
    }
  end
  return temp
end

--[[ Local Functions ]]
local function subscribeVD(requestParams, responseParams)
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", requestParams)

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", requestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
  end)

  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function subscribeVDAgain(requestParams, responseParams)
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", requestParams)

  responseParams.success = false
  responseParams.resultCode = "IGNORED"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeVehicleData SUCCESS", subscribeVD, { requestParams, genResponse("SUCCESS") })
runner.Step("SubscribeVehicleData DATA_ALREADY_SUBSCRIBED", subscribeVDAgain, { requestParams, genResponse("DATA_ALREADY_SUBSCRIBED") })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
