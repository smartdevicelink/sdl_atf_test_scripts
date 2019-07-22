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
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

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

local function processRPCUnsubscribeIgnored(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc_unsubscribe.name, rpc_unsubscribe.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params):Times(0)
  commonTestCases:DelayedExp(common.timeout)
  local responseParams = vehicleDataResults2
  responseParams.success = false
  responseParams.resultCode = "IGNORED"
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
runner.Title("Trying to unsubscribe from already unsubscribed parameter...")
runner.Step("RPC " .. rpc_unsubscribe.name, processRPCUnsubscribeIgnored)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
