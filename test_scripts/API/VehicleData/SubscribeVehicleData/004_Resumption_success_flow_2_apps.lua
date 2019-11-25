---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) App1 and app2 are registered
-- 2) App1 and app2 send valid SubscribeVehicleData to SDL and these requests are allowed by Policies
-- 3) Apps reconnect
-- SDL must:
-- 1) Perform resumption of data
-- 2) Transfer SubscribeVehicleData request to HMI and by resumption of app1
-- 3) not transfer SubscribeVehicleData request to HMI and by resumption of app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local actions = require("user_modules/sequences/actions")
local test = require("user_modules/dummy_connecttest")
local mobile_session = require("mobile_session")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

local hashIdArray = { }

local rpc = {
  name = "SubscribeVehicleData",
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

local function processRPCSubscribeSuccess(pAppId, pHMIsubscription)
  local mobileSession = common.getMobileSession( pAppId)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  if true == pHMIsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc.name)
    :Times(0)
  end
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
  mobileSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    hashIdArray[pAppId] = data.payload.hashID
  end)
end

local function processRPCSubscribeResumption(pHMIunsubscription)
  if true == pHMIunsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc.name)
    :Times(0)
  end
end

local function ActivateSecondApp()
  common.activateApp(2)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function reconnect()
  common.getMobileSession(1):Stop()
  common.getMobileSession(2):Stop()
  common.getHMIConnection():ExpectNotification("VehicleInfo.UnsubscribeVehicleData")
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
  { unexpectedDisconnect = true }):Times(2)
  :Do(function()
    test.mobileSession[1] = mobile_session.MobileSession(
      test,
      test.mobileConnection,
      config["application" .. 1].registerAppInterfaceParams)
    test.mobileSession[2] = mobile_session.MobileSession(
      test,
      test.mobileConnection,
      config["application" .. 2].registerAppInterfaceParams)
    test.mobileConnection:Connect()
  end)
end

local function raiN(id, pHashId)
  test["mobileSession" .. id] = mobile_session.MobileSession(test.mobileConnection)
  local session = actions.mobile.createSession(id)
  session:StartService(7)
  :Do(function()
    config["application" .. id].registerAppInterfaceParams.hashID = pHashId
      local corId = common.getMobileSession(id):SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
        common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      common.getMobileSession(id):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
end

local function resumptionApps(pAppId, level, pHMIsubscription)
  raiN(pAppId, hashIdArray[pAppId])
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
    :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :Times(AtMost(1))
  processRPCSubscribeResumption(pHMIsubscription)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 is registered", common.registerAppWOPTU)
runner.Step("App_2 is registered", common.registerAppWOPTU, { 2 })
runner.Step("PTU", common.policyTableUpdate, { ptUpdateForApps })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", ActivateSecondApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. " app1", processRPCSubscribeSuccess, { 1, true })
runner.Step("RPC " .. rpc.name .. " app2", processRPCSubscribeSuccess, { 2, false })
runner.Step("Reconnect", reconnect)
runner.Step("Resumption app2", resumptionApps, { 2, "FULL", true })
runner.Step("Resumption app1", resumptionApps, { 1, "LIMITED", false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
