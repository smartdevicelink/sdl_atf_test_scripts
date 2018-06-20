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
local mobile_session = require("mobile_session")

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
local function processRPCSubscribeSuccess(pAppId, pHMIsubscription, self)
  local mobileSession = common.getMobileSession(self, pAppId)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  if true == pHMIsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
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

local function processRPCSubscribeResumption(pHMIunsubscription, self)
  if true == pHMIunsubscription then
    EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          vehicleDataResults)
      end)
  else
    EXPECT_HMICALL("VehicleInfo." .. rpc.name)
    :Times(0)
  end
end

local function ActivateSecondApp(self)
  common.activateApp(2, self)
  common.getMobileSession(self, 1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function reconnect(self)
  common.getMobileSession(self, 1):Stop()
  common.getMobileSession(self, 2):Stop()
  EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData")
  :Times(0)
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true })
  :Times(2)
  :Do(function()
    self.mobileSession["1"] = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config["application" .. 1].registerAppInterfaceParams)
    self.mobileSession["2"] = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config["application" .. 2].registerAppInterfaceParams)
    self.mobileConnection:Connect()
  end)
end

local function raiN(id, pHashId, self)
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
    config["application" .. id].registerAppInterfaceParams.hashID = pHashId
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
end

local function resumptionApps(pAppId, level, pHMIsubscription, self)
  raiN(pAppId, hashIdArray[pAppId], self)
  common.getMobileSession(self, 1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :Times(AtMost(1))
  processRPCSubscribeResumption(pHMIsubscription, self)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI app1 with PTU", common.registerAppWithPTU)
runner.Step("RAI app2 with PTU", common.registerAppWithPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", ActivateSecondApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. " app1", processRPCSubscribeSuccess, { 1, true })
runner.Step("RPC " .. rpc.name .. " app2", processRPCSubscribeSuccess, { 2, false })
runner.Step("Reconnect", reconnect)
runner.Step("Resumption app1", resumptionApps, { 2, "FULL", true })
runner.Step("Resumption app2", resumptionApps, { 1, "LIMITED", false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
