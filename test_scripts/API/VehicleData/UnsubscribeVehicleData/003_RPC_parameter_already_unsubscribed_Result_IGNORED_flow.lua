---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
--  for already unsubscribed specified parameter
--
-- Description:
-- In case:
-- 1) Mobile application sends valid UnsubscribeVehicleData to SDL and this request is allowed by Policies
-- 2) Mobile app is already unsubscribed from this parameter
-- SDL must:
-- Respond IGNORED, success:false {dataType = "VEHICLEDATA_engin eOilLife",
-- resultCode = "DATA_NOT_SUBSCRIBED"} to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc_subscribe = {
  name = "SubscribeVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true,
    electronicParkBrakeStatus = true,
    turnSignal = true
  }
}

local rpc_unsubscribe = {
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
    resultCode = "SUCCESS"
  },
  fuelRange = {
    dataType = "VEHICLEDATA_FUELRANGE",
    resultCode = "SUCCESS"
  },
  tirePressure = {
    dataType = "VEHICLEDATA_TIREPRESSURE",
    resultCode = "SUCCESS"
  },
  electronicParkBrakeStatus = {
    dataType = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
    resultCode = "SUCCESS"
  },
  turnSignal = {
    dataType = "VEHICLEDATA_TURNSIGNAL",
    resultCode = "SUCCESS"
  }
}

local vehicleDataResults2 = {
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
local function processRPCSubscribeSuccess()
  local cid = common.getMobileSession():SendRPC(rpc_subscribe.name, rpc_subscribe.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc_subscribe.name, rpc_subscribe.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        vehicleDataResults)
    end)
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

local function processRPCUnsubscribeSuccess()
  local cid = common.getMobileSession():SendRPC(rpc_unsubscribe.name, rpc_unsubscribe.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        vehicleDataResults)
    end)
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

local function processRPCUnsubscribeIgnored()
  local cid = common.getMobileSession():SendRPC(rpc_unsubscribe.name, rpc_unsubscribe.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params):Times(0)
  local responseParams = vehicleDataResults2
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
common.Step("RPC " .. rpc_subscribe.name, processRPCSubscribeSuccess)
common.Step("RPC " .. rpc_unsubscribe.name, processRPCUnsubscribeSuccess)
common.Title("Trying to unsubscribe from already unsubscribed parameter...")
common.Step("RPC " .. rpc_unsubscribe.name, processRPCUnsubscribeIgnored)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
