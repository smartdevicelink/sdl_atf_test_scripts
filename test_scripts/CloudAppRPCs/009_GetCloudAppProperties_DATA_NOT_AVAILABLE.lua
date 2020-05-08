---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetCloudAppProperties
--
--  Steps:
--  1) Application triggers a PTU with cloud app information present
--  2) Application sends a GetCloudAppProperties RPC request with the wrong app id
--
--  Expected:
--  1) SDL responds to mobile app with "ResultCode: DATA_NOT_AVAILABLE,
--        success: false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local get_rpc = {
    name = "GetCloudAppProperties",
    params = {
      appID = "231"
    }
}

--[[ Local Functions ]]

local function processGetRPCFailure()
    local mobileSession = common.getMobileSession(1)
    local cid = mobileSession:SendRPC(get_rpc.name, get_rpc.params)
  
    local responseParams = {}
    responseParams.success = false
    responseParams.resultCode = "DATA_NOT_AVAILABLE"
    mobileSession:ExpectResponse(cid, responseParams)
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getCloudAppStoreConfig(1);
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. get_rpc.name .. "_resultCode_DATA_NOT_AVAILABLE", processGetRPCFailure)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

