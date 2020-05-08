---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetCloudAppProperties
--
--  Steps:
--  1) Application triggers a PTU with cloud app information present
--  2) Application sends a GetCloudAppProperties RPC request with the correct cloud app id
--
--  Expected:
--  1) SDL responds to mobile app with "ResultCode: SUCCESS,
--        success: true
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
      appID = "232"
    }
}

local get_expected = {
    nicknames = { "TestApp" },
    authToken = "ABCD12345",
    cloudTransportType = "WSS",
    enabled = true,
    hybridAppPreference = "CLOUD",
    endpoint = "ws://127.0.0.1:8080/"
}

--[[ Local Functions ]]
local function processGetRPCSuccess()
    local mobileSession = common.getMobileSession(1)
    local cid = mobileSession:SendRPC(get_rpc.name, get_rpc.params)
  
    local responseParams = {}
    responseParams.success = true
    responseParams.resultCode = "SUCCESS"
    responseParams.properties = get_expected
    mobileSession:ExpectResponse(cid, responseParams)
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getCloudAppStoreConfig(1);
  tbl.policy_table.app_policies[get_rpc.params.appID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" },
    nicknames = { "TestApp" },
    enabled = true,
    auth_token = "ABCD12345",
    cloud_transport_type = "WSS",
    hybrid_app_preference = "CLOUD",
    endpoint = "ws://127.0.0.1:8080/"
  };
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. get_rpc.name .. "_resultCode_SUCCESS", processGetRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

