local actions = require("user_modules/sequences/actions")

local commonAppServices = actions

local serviceIDs = {}

function commonAppServices.appServiceCapability(update_reason, manifest) 
  local appService = {
    updateReason = update_reason,
    updatedAppServiceRecord = {
      serviceManifest = manifest
    }
  }
  if update_reason == "PUBLISHED" then
    appService.updatedAppServiceRecord.servicePublished = true
    appService.updatedAppServiceRecord.serviceActive = false
  elseif update_reason == "REMOVED" then
    appService.updatedAppServiceRecord.servicePublished = false
    appService.updatedAppServiceRecord.serviceActive = false
  elseif update_reason == "ACTIVATED" then
    appService.updatedAppServiceRecord.servicePublished = true
    appService.updatedAppServiceRecord.serviceActive = true
  elseif update_reason == "DEACTIVATED" then
    appService.updatedAppServiceRecord.servicePublished = true
    appService.updatedAppServiceRecord.serviceActive = false
  end
  return appService
end

function commonAppServices.appServiceCapabilityUpdateParams(update_reason, manifest)
  return {
    systemCapability = {
      systemCapabilityType = "APP_SERVICES",
      appServicesCapabilities = {
        appServices = {
          commonAppServices.appServiceCapability(update_reason, manifest)
        }
      }
    }
  }
end

function commonAppServices.getAppServiceConsumerConfig(app_id)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "AppServiceConsumer" },
    nicknames = { config["application" .. app_id].registerAppInterfaceParams.appName }
  }
end

function commonAppServices.getAppServiceProducerConfig(app_id)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "AppServiceProvider" },
    nicknames = { config["application" .. app_id].registerAppInterfaceParams.appName },
    app_services = {
      MEDIA = {
        handled_rpcs = {{function_id = 2000}},
        service_names = {
          config["application" .. app_id].registerAppInterfaceParams.appName
        }
      }
    }
  }
end

function commonAppServices.findCapabilityUpdate(capability, params)
  if not params.systemCapability then
    return false, "params.systemCapability is nil"
  end
  local systemCapability = params.systemCapability
  if not systemCapability.systemCapabilityType == "APP_SERVICES" or not systemCapability.appServicesCapabilities then
    return false, "appServicesCapabilities is nil"
  end
  local appServices = systemCapability.appServicesCapabilities.appServices
  for key, value in pairs(appServices) do
    local res, err = compareValues(capability, value, "params")
    if res then
      return true
    end
  end
  return false, "unable to find matching app service update"
end

function commonAppServices.publishEmbeddedAppService(manifest)
  local cid = commonAppServices.getHMIConnection():SendRequest("AppService.PublishAppService", {
    appServiceManifest = manifest
  })
  local first_run = true
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated"):Times(AtLeast(1)):ValidIf(function(self, data)
      if first_run then
        first_run = false
        local publishedParams = commonAppServices.appServiceCapability("PUBLISHED", manifest)
        return commonAppServices.findCapabilityUpdate(publishedParams, data.params)
      else
        local activatedParams = commonAppServices.appServiceCapability("ACTIVATED", manifest)
        return commonAppServices.findCapabilityUpdate(activatedParams, data.params)
      end
    end)
  EXPECT_HMIRESPONSE(cid, {
    result = {
      appServiceRecord = {
        serviceManifest = manifest,
        servicePublished = true
      },
      code = 0, 
      method = "AppService.PublishAppService"
    }
  }):Do(function(_, data)
      if data.result.appServiceRecord then
        serviceIDs[0] = data.result.appServiceRecord.serviceID
      end
    end)
end

function commonAppServices.publishMobileAppService(manifest, app_id)
  if not app_id then app_id = 1 end
  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("PublishAppService", {
    appServiceManifest = manifest
  })

  local first_run = true
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated"):Times(AtLeast(1)):ValidIf(function(self, data)
      if first_run then
        first_run = false
        local publishedParams = commonAppServices.appServiceCapability("PUBLISHED", manifest)
        return commonAppServices.findCapabilityUpdate(publishedParams, data.payload)
      else
        local activatedParams = commonAppServices.appServiceCapability("ACTIVATED", manifest)
        return commonAppServices.findCapabilityUpdate(activatedParams, data.payload)
      end
    end)
  mobileSession:ExpectResponse(cid, {
    appServiceRecord = {
      serviceManifest = manifest,
      servicePublished = true
    },
    success = true,
    resultCode = "SUCCESS"
  }):Do(function(_, data)
      if data.payload.success then
        serviceIDs[app_id] = data.payload.appServiceRecord.serviceID
      end
    end)
end

function commonAppServices.mobileSubscribeAppServiceData(provider_app_id, app_id)
  if not app_id then app_id = 1 end
  local requestParams = {
    serviceType = "MEDIA",
    subscribe = true
  }
  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("GetAppServiceData", requestParams)
  local service_id = commonAppServices.getAppServiceID(provider_app_id)
  local responseParams = {
    serviceData = {
      serviceID = service_id,
      serviceType = "MEDIA",
      mediaServiceData = {}
    }
  }
  if provider_app_id == 0 then
    EXPECT_HMICALL("AppService.GetAppServiceData", requestParams):Do(function(_, data) 
        commonAppServices.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
      end)
  else
    local providerMobileSession = commonAppServices.getMobileSession(provider_app_id)

    -- Fill out mobile response params
    responseParams.resultCode = "SUCCESS"
    responseParams.success = true
    providerMobileSession:ExpectRequest("GetAppServiceData", requestParams):Do(function(_, data) 
        providerMobileSession:SendResponse("GetAppServiceData", data.rpcCorrelationId, responseParams)
      end)
  end

  mobileSession:ExpectResponse(cid, responseParams)
end

function commonAppServices.getAppServiceID(app_id)
  if not app_id then app_id = 1 end
  return serviceIDs[app_id]
end

--[[ GetFile ]]

local function file_check(file_name)
  local file_found=io.open(file_name, "r")
  return file_found~=nil
end

local function getFileCRC32(fileName)
  pFile = "files/"..fileName
  local cmd = "cat " .. pFile .. " | gzip -1 | tail -c 8 | head -c 4"
  local handle = io.popen(cmd)
  local crc = handle:read("*a")
  handle:close()
  local function bytesToInt(pStr)
    local t = { string.byte(pStr, 1, -1) }
    local n = 0
    for k = 1, #t do
      n = n + t[k] * 2 ^ ((k - 1) * 8)
    end
    return n
  end
  return bytesToInt(crc)
end

local function getATFPath()
  local handle = io.popen("echo $(pwd)")
  local result = handle:read("*a")
  handle:close()
  return result:sub(0, -2)
end

function commonAppServices.getFileFromStorage(app_id, request_params, response_params)
  local mobileSession = commonAppServices.getMobileSession(app_id)
  if file_check("files/"..request_params.fileName) and response_params.crc == nil then
    local file_crc = getFileCRC32(request_params.fileName)   
    if response_params.success then
      response_params.crc = file_crc
    end
  end
  --mobile side: sending GetFile request
  local cid = mobileSession:SendRPC("GetFile", request_params)
  --mobile side: expected GetFile response   
  mobileSession:ExpectResponse(cid, response_params)
end

function commonAppServices.getFileFromService(app_id, asp_app_id, request_params, response_params)
  local mobileSession = commonAppServices.getMobileSession(app_id)
  if file_check("files/"..request_params.fileName) and response_params.crc == nil then
    local file_crc = getFileCRC32(request_params.fileName)   
    if response_params.success then
      response_params.crc = file_crc
    end
  end

  request_params.appServiceId = commonAppServices.getAppServiceID(asp_app_id)

  --mobile side: sending GetFile request
  local cid = mobileSession:SendRPC("GetFile", request_params)
  if asp_app_id == 0 then 
    --EXPECT_HMICALL
    commonAppServices.getHMIConnection():ExpectRequest("BasicCommunication.GetFilePath")
    :Do(function(_, d2)
      local cwd = getATFPath()
      file_path = cwd.."/files/"..request_params.fileName
      commonAppServices.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", {filePath = file_path})
    end) 
  end

  --mobile side: expected GetFile response   
  mobileSession:ExpectResponse(cid, response_params)
end

function commonAppServices.putFileInStorage(app_id, request_params, response_params)
  local mobileSession = commonAppServices.getMobileSession(app_id)      
  --mobile side: sending PutFile request
  local cid = mobileSession:SendRPC("PutFile", request_params, "files/"..request_params.syncFileName)
  --mobile side: expected PutFile response
  mobileSession:ExpectResponse(cid, response_params)
end



return commonAppServices