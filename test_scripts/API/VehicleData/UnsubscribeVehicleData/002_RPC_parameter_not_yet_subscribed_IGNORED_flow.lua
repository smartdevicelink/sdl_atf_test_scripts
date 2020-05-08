---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
-- for not yet subscribed specified parameter
--
-- Description:
-- In case:
-- Mobile application sends valid UnsubscribeVehicleData to SDL and this request
-- is allowed by Policies but app is not yet subscribed for this parameter
-- SDL must:
-- Respond IGNORED, success:false to mobile application and not transfer this request to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc = {
  name = "UnsubscribeVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true,
    electronicParkBrakeStatus = true,
    turnSignal = true
  }
}

local vehicleDataResults = {
  engineOilLife = {
    dataType = "VEHICLEDATA_ENGINEOILLIFE",
    resultCode = "DATA_NOT_SUBSCRIBED"
  },
  fuelRange = {
    dataType = "VEHICLEDATA_FUELRANGE",
    resultCode = "DATA_NOT_SUBSCRIBED"
  },
  tirePressure = {
    dataType = "VEHICLEDATA_TIREPRESSURE",
    resultCode = "DATA_NOT_SUBSCRIBED"
  },
  electronicParkBrakeStatus = {
    dataType = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
    resultCode = "DATA_NOT_SUBSCRIBED"
  },
  turnSignal = {
    dataType = "VEHICLEDATA_TURNSIGNAL",
    resultCode = "DATA_NOT_SUBSCRIBED"
  }
}

--[[ Local Functions ]]
local function processRPCFailure()
  local cid = common.getMobileSession():SendRPC(rpc.name, rpc.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc.name, rpc.params):Times(0)
  local responseParams = vehicleDataResults
  responseParams.success = false
  responseParams.resultCode = "IGNORED"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("RPC " .. rpc.name , processRPCFailure)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
