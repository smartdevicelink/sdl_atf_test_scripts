---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetVehicleData
--
--  Steps:
--  1) Application sends a SubscribeVehicleData request with the param cloudAppVehicleID
--
--  Expected:
--  1) SDL responds to mobile app with "ResultCode: SUCCESS,
--        success: true
--        dataType = "VEHICLEDATA_CLOUDAPPVEHICLEID"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rpc = {
  name = "SubscribeVehicleData",
  params = {
    cloudAppVehicleID = true
  }
}

local vehicleDataResults = {
  cloudAppVehicleID = {
    dataType = "VEHICLEDATA_CLOUDAPPVEHICLEID", 
    resultCode = "SUCCESS"
  }
}

--[[ Local Functions ]]
local function processRPCSuccess()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        vehicleDataResults)
    end)
  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getCloudAppConfig(1);
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name, processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
