---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for a cloud app with an icon_url
--
--  Steps:
--  1) Mobile sends a SystemRequest with an invalid RequestType("ION_URL") and correlation id of -1
--
--  Expected:
--  1) SDL responds to mobile app with {ResultCode: "INVALID_ID", success: false}
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

 --[[ Test Configuration ]]
 runner.testSettings.isSelfIncluded = false
 runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local cloud_app_id = "cloudAppID123"
local url = "https://fakeurl1234512345.com"
local icon_image_path = "files/icon.png"
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 1

local rpc = {
  name = "SystemRequest",
  params = {
      requestType = "ION_URL", 
      fileName = url
  }
}

local responseParams = {
  success = false,
  resultCode = "INVALID_ID"
}

--[[ Local Functions ]]
local function PTUfunc(tbl)
    params = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"},
        RequestType = {},
        RequestSubType = {},
        hybrid_app_preference = "CLOUD",
        endpoint = "ws://192.168.1.1:3000/",
        enabled = true,
        cloud_transport_type = "WS",
        icon_url = url,
        nicknames = {"CloudApp"}
    }
    tbl.policy_table.app_policies[cloud_app_id] = params
end

local function processRPCSuccess()
  local mobileSession = common.getMobileSession(self, 1)
  
  mobileSession.correlationId = -2
  local cid = mobileSession:SendRPC(rpc.name, rpc.params, icon_image_path)
  common.test_assert(commonFunctions:is_table_equal(cid, -1), "Incorrect correlation id")

  mobileSession:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Delete Storage", common.DeleteStorageFolder)

runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdateWithIconUrl, { PTUfunc, nil, url })

runner.Step("Send App Icon SystemRequest_INVALID_ID", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Delete Storage", common.DeleteStorageFolder)
