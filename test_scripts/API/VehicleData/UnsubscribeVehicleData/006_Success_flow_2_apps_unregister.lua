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
-- App1 is unregistered
-- App2 is unregistered
-- SDL must:
-- not send UnsubscriveVD request to HMI after app1 unregistration
-- send UnsubscriveVD request to HMI after app2 unregistration
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local actions = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
local function getVDParams()
  local out = {}
  for k in pairs(common.allVehicleData) do
    table.insert(out, k)
  end
  return out
end

local function ptUpdateForApps(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID].groups = { "Base-4", "Emergency-1" }
  pTbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  for _, v in pairs(grp.rpcs) do
    v.parameters = getVDParams()
  end
  pTbl.policy_table.vehicle_data = nil
end
local function processRPCSubscribeSuccess(pAppID, pHMIsubscription)
  local mobileSession = common.getMobileSession(pAppID)
  local cid = mobileSession:SendRPC(rpc_subscribe.name, rpc_subscribe.params)
  if true == pHMIsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc_subscribe.name, rpc_subscribe.params)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
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

local function unregisterApp(pAppId, pHMIunsubscription)
  local mobileSession = common.getMobileSession(pAppId)
  if true == pHMIunsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name, rpc_unsubscribe.params)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc_unsubscribe.name)
    :Times(0)
  end
  local cid = mobileSession:SendRPC("UnregisterAppInterface",{})
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false })
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI app1 with PTU", common.registerAppWOPTU)
runner.Step("RAI app2 with PTU", common.registerAppWOPTU, { 2 })
runner.Step("PTU", common.policyTableUpdate, { ptUpdateForApps })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc_subscribe.name .. " app1", processRPCSubscribeSuccess, { 1, true })
runner.Step("RPC " .. rpc_subscribe.name .. " app2", processRPCSubscribeSuccess, { 2, false })
runner.Step("Unregister app1", unregisterApp, { 1, false })
runner.Step("Unregister app2", unregisterApp, { 2, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
