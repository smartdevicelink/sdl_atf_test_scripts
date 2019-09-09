---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed but parameter of this request is NOT allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
-- from specified parameter but parameter is disallowed by Policies
-- Description:
-- In case:
-- 1) mobile application sends valid UnsubscribeVehicleData to SDL and this request is
-- allowed by Policies but RPC parameter is not allowed
-- SDL must:
-- 1) SDL responds DISALLOWED, success:false to mobile application and doesn't transfer this request to HMI
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
    resultCode = "DISALLOWED"
  },
  fuelRange = {
    dataType = "VEHICLEDATA_FUELRANGE",
    resultCode = "DISALLOWED"
  },
  tirePressure = {
    dataType = "VEHICLEDATA_TIREPRESSURE",
    resultCode = "DISALLOWED"
  },
  electronicParkBrakeStatus = {
    dataType = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
    resultCode = "DISALLOWED"
  },
  turnSignal = {
    dataType = "VEHICLEDATA_TURNSIGNAL",
    resultCode = "DISALLOWED"
  }
}

--[[ Local Functions ]]
local function processRPCFailure()
  local cid = common.getMobileSession():SendRPC(rpc.name, rpc.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc.name, rpc.params):Times(0)
  local responseParams = vehicleDataResults
  responseParams.success = false
  responseParams.resultCode = "DISALLOWED"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdateMin })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("RPC " .. rpc.name , processRPCFailure)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
