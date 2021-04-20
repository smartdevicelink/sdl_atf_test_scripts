---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) Specific permissions are assigned for <appID> with PublishAppService
--  4) Specific permissions are assigned for <appID2> with GetAppServiceData
--  5) Application 1 has published a WEATHER service
--
--  Steps:
--  1) Application 2 sends a GetAppServiceData RPC request with serviceType WEATHER
--
--  Expected:
--  1) SDL forwards the GetAppServiceData request to Application 1
--  2) Application 1 sends a GetAppServiceData response (SUCCESS) to Core with its own serviceData
--  3) SDL forwards the response to Application 2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "WEATHER",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  weatherServiceManifest = {}
}

local rpc = {
  name = "GetAppServiceData",
  params = {
    serviceType = manifest.serviceType
  }
}

local expectedResponse = {
  serviceData = {
    serviceType = manifest.serviceType,
    weatherServiceData = {
      location = {
        locationName = "location"
      },
      currentForecast = {
        currentTemperature = {
          unit = "CELSIUS",
          value = -4.6
        },
        weatherSummary = "Cold",
        humidity = 0.25,
        cloudCover = 0.5,
        moonPhase = 0.75,
        windBearing = 180,
        windGust = 2.0,
        windSpeed = 5.0
      },
      alerts = {
        {
          title = "Weather Alert"
        }
      }
    }
  },
  success = true,
  resultCode = "SUCCESS"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1, manifest.serviceType);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceConsumerConfig(2);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local cid = mobileSession2:SendRPC(rpc.name, rpc.params)
  local service_id = common.getAppServiceID()
  local responseParams = expectedResponse
  responseParams.serviceData.serviceID = service_id
  mobileSession:ExpectRequest(rpc.name, rpc.params):Do(function(_, data) 
      mobileSession:SendResponse(rpc.name, data.rpcCorrelationId, responseParams)
    end)

  mobileSession2:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
