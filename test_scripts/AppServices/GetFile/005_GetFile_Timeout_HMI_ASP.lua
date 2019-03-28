---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) AppServiceConsumer permissions are assigned for <appID>
--  3) HMI sends a PublishAppService
--
--  Steps:
--  1) Application sends a GetFile Request with the id of the service published by the HMI
--
--  Expected:
--  1) GetFile will return SUCCESS
--  2) The CRC value returned in the GetFile response will be the same as the crc32 hash of the file binary data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local putFileParams = {
  syncFileName = "icon.png",
  fileType ="GRAPHIC_PNG",
}

local getFileParams = {
  fileName = "icon.png",
  fileType = "GRAPHIC_PNG",
}

local result = { success = true, resultCode = "SUCCESS"}


--[[ Local functions ]]
local function PTUfunc(tbl)
    tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
end

local function getATFPath()
  local handle = io.popen("echo $(pwd)")
  local result = handle:read("*a")
  handle:close()
  return result:sub(0, -2)
end

local function getFileFromService(app_id, asp_app_id, request_params, response_params)
  local mobileSession = common.getMobileSession(app_id)
  request_params.appServiceId = common.getAppServiceID(asp_app_id)
  --mobile side: sending GetFile request
  local cid = mobileSession:SendRPC("GetFile", request_params)
  if asp_app_id == 0 then 
    --EXPECT_HMICALL
    common.getHMIConnection():ExpectRequest("BasicCommunication.GetFilePath")
    :Do(function(_, d2)
      local cwd = getATFPath()
      file_path = cwd.."/files/"..request_params.fileName
      RUN_AFTER((function() 
        common.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", {filePath = file_path})      
      end), runner.testSettings.defaultTimeout + 2000)
    end) 
  end
  --mobile side: expected GetFile response   
  mobileSession:ExpectResponse(cid, response_params):Timeout(runner.testSettings.defaultTimeout + common.getRpcPassThroughTimeoutFromINI())
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("PublishAppService", common.publishEmbeddedAppService, { manifest })
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")    
runner.Step("Getfile", getFileFromService, {1, 0, getFileParams, result})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)