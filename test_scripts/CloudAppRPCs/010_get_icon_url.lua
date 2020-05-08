---------------------------------------------------------------------------------------------------
--  Precondition:
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for a cloud app with an icon_url
--
--  Steps:
--  1) Core sends a systemRequest type = ICONURL
--  2) Mobile responds with image data in a SystemRequest ICON_URL
--
--  Expected:
--  1) SDL responds to mobile app with "ResultCode: SUCCESS,
--        success: true
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')

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
      requestType = "ICON_URL", fileName = url
  }
}

--[[ Local Functions ]]
local function PTUfunc(tbl)
    local params = {
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
    local mobileSession = common.getMobileSession()
    local cid = mobileSession:SendRPC(rpc.name, rpc.params, icon_image_path)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Times(1)
    :ValidIf(function(self, data)
      if data.params == nil then
        return false
      end
      if data.params.applications[1] == nil and data.params.applications[2] == nil then
        return false
      end
      return data.params.applications[1].icon ~= nil or data.params.applications[2].icon ~= nil
    end)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
    local responseParams = {}
    responseParams.success = true
    responseParams.resultCode = "SUCCESS"
    mobileSession:ExpectResponse(cid, responseParams)
  end

local function ptu()
  common.policyTableUpdateWithIconUrl(PTUfunc, nil, url)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Delete Storage", common.DeleteStorageFolder)

runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI", common.registerApp)
runner.Step("PTU", ptu)
runner.Step("Send App Icon SystemRequest", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Delete Storage", common.DeleteStorageFolder)
