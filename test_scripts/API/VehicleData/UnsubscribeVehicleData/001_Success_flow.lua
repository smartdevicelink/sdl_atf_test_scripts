---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
--  for already subscribed specified parameter
--
-- Description:
-- In case:
-- Mobile application sends valid UnsubscribeVehicleData to SDL
-- This request is allowed by Policies and mobile app is subscribed for this parameter
-- SDL must:
-- Transfer this request to HMI and after successful response from hmi
-- Respond SUCCESS, success:true to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
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

--[[ Local Functions ]]
local function processRPCSubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc_subscribe.name, rpc_subscribe.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc_subscribe.name, rpc_subscribe.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        vehicleDataResults)
    end)
  local responseParams = common.cloneTable(vehicleDataResults)
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function processRPCUnsubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc_unsubscribe.name, rpc_unsubscribe.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        vehicleDataResults)
    end)
  local responseParams = common.cloneTable(vehicleDataResults)
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc_subscribe.name, processRPCSubscribeSuccess)
runner.Step("RPC " .. rpc_unsubscribe.name, processRPCUnsubscribeSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
