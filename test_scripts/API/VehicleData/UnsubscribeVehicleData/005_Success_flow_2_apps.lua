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
-- App1 is alredy subscribed to vehicle data
-- App2 is alredy subscribed to vehicle data
-- App2 sends valid UnsubscribeVehicleData to SDL
-- This request is allowed by Policies and mobile app is subscribed for this parameter
-- SDL must:
-- not transfer this request to HMI
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
    tirePressure = true
  }
}

local rpc_unsubscribe = {
  name = "UnsubscribeVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true
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
  }
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess(pAppID, pHMIsubscription, self)
  local mobileSession = common.getMobileSession(self, pAppID)
  local cid = mobileSession:SendRPC(rpc_subscribe.name, rpc_subscribe.params)
  if true == pHMIsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc_subscribe.name, rpc_subscribe.params)
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc_subscribe.name)
    :Times(0)
  end
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function processRPCUnsubscribeSuccess(pAppID, pHMIunsubscription, self)
  local mobileSession = common.getMobileSession(self, pAppID)
  local cid = mobileSession:SendRPC(rpc_unsubscribe.name, rpc_unsubscribe.params)
  if true == pHMIunsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params)
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name)
    :Times(0)
  end
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI app1 with PTU", common.registerAppWithPTU)
runner.Step("RAI app2 with PTU", common.registerAppWithPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc_subscribe.name .. " app1", processRPCSubscribeSuccess, { 1, true })
runner.Step("RPC " .. rpc_subscribe.name .. " app2", processRPCSubscribeSuccess, { 2, false })
runner.Step("RPC " .. rpc_unsubscribe.name .. " app2", processRPCUnsubscribeSuccess, { 2, false })
runner.Step("RPC " .. rpc_subscribe.name .. " app2", processRPCSubscribeSuccess, { 2, false })
runner.Step("RPC " .. rpc_unsubscribe.name .. " app1", processRPCUnsubscribeSuccess, { 1, false })
runner.Step("RPC " .. rpc_unsubscribe.name .. " app2", processRPCUnsubscribeSuccess, { 2, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
