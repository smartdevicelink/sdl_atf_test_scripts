---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with SetCloudAppProperties
--
--  Steps:
--  1) Application sends a SetCloudAppProperties RPC request(with invalid param)
--
--  Expected:
--  1) SDL responds to mobile app with "ResultCode: INVALID_DATA,
--        success: false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rpc = {
  name = "SetCloudAppProperties",
  params = {
    properties = {
      nicknames = { "TestApp" },
      appID = "0000001",
      enabled = true,
      authToken = 12345,
      cloudTransportType = "WSS",
      hybridAppPreference = "BOTH",
      endpoint = "ws://127.0.0.1:8080/"
    }
  }
}


--[[ Local Functions ]]
local function processRPCSuccess()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  local responseParams = {}
  responseParams.success = false
  responseParams.resultCode = "INVALID_DATA"
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
runner.Step("RPC " .. rpc.name .. "_resultCode_INVALID_DATA", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
