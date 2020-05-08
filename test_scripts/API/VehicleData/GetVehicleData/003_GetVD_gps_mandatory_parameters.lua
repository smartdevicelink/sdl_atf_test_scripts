---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- mobile application sends valid GetVehicleData to SDL and this request is allowed by Policies
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) After successful response from hmi with all mandatory parameters
-- respond SUCCESS, success:true and resend parameter values received from HMI to mobile application
-- 3) After response from HMI with missed mandatory parameters
-- respond success:false, GENERIC_ERROR
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc = {
  name = "GetVehicleData",
  params = {
    gps = true
  }
}

local vehicleDataValues = {
  allData = {
    longitudeDegrees = 10,
    latitudeDegrees = 20,
    utcYear = 2010,
    utcMonth = 1,
    utcDay = 2,
    utcHours = 3,
    utcMinutes = 4,
    utcSeconds = 5,
    compassDirection = "NORTH",
    actual = true,
    satellites = 6,
    dimension = "2D",
    altitude = 7,
    heading = 8,
    speed = 9,
    pdop = 10,
    hdop = 11,
    vdop = 12
  },
  mandatoryOnly = {
    longitudeDegrees = 10,
    latitudeDegrees = 20
  }
}

local vehicleDataValuesMissedMandatory = {
  missedAll = { utcYear = 2010 },
  missedLongitude = { latitudeDegrees = 20 },
  missedLatitude = { longitudeDegrees = 10 }
}

--[[ Local Functions ]]
local function processRPC(pParams, isSuccess)
  local cid = common.getMobileSession():SendRPC(rpc.name, rpc.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = pParams })
    end)
  if isSuccess == true then
    local responseParams = {}
    responseParams.gps = pParams
    responseParams.success = true
    responseParams.resultCode = "SUCCESS"
    common.getMobileSession():ExpectResponse(cid, responseParams)
  else
    common.getMobileSession():ExpectResponse(cid,
      { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for key, value in pairs(vehicleDataValues) do
  common.Step("RPC GetVehicleData gps " .. key, processRPC, { value, true })
end
for key, value in pairs(vehicleDataValuesMissedMandatory) do
  common.Step("RPC GetVehicleData gps " .. key, processRPC, { value, false })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
