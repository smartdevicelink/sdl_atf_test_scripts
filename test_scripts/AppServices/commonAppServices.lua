local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

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

local appServiceData = {
  MEDIA = {
    mediaServiceData = {
      mediaType = "MUSIC",
      mediaTitle = "Song name",
      mediaArtist = "Band name",
      mediaAlbum = "Album name",
      playlistName = "Sample music",
      isExplicit = true,
      trackPlaybackProgress = 300,
      trackPlaybackDuration = 400,
      queuePlaybackProgress = 3200,
      queuePlaybackDuration = 5000,
      queueCurrentTrackNumber = 12,
      queueTotalTrackCount = 25
    }
  },
  NAVIGATION = {
    navigationServiceData = {
      timeStamp = {
        hour = 2,
        minute = 24,
        second = 16
      },
      origin = {
        locationName = "start"
      },
      destination = {
        locationName = "finish"
      },
      destinationETA = {
        hour = 2,
        minute = 38,
        second = 40
      },
      prompt = "Navigating to destination"
    }
  },
  WEATHER = {
    weatherServiceData = {
      location = {
        locationName = "location"
      },
      currentForecast = {
        currentTemperature = {
          unit = "CELSIUS",
          value = 24.6
        },
        weatherSummary = "Windy",
        humidity = 0.28,
        cloudCover = 0.55,
        moonPhase = 0.85,
        windBearing = 180,
        windGust = 2.0,
        windSpeed = 50.0
      },
      alerts = {
        {
          title = "Weather Alert"
        }
      }
    }
  },
  FUTURE = {
    futureServiceData = {
      futureParam1 = "A String Value",
      futureParam2 = 6,
      futureParam3 = {
        futureParam4 = 4.6
      }
    }
  }
}

function commonAppServices.appServiceDataByType(service_id, service_type)
  if not service_type then service_type = "MEDIA" end
  local data = appServiceData[service_type]
  if data == nil then
    data = appServiceData["FUTURE"]
  end
  data.serviceType = service_type
  data.serviceID = service_id
  return data
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

function commonAppServices.getAppServiceProducerConfig(app_id, service_type)
  local policy = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "AppServiceProvider" },
    nicknames = { config["application" .. app_id].registerAppInterfaceParams.appName },
    app_services = {}
  }
  local service_info = {
    handled_rpcs = {{function_id = 2000}},
    service_names = {
      config["application" .. app_id].registerAppInterfaceParams.appName
    }
  }
  if service_type then
    policy.app_services[service_type] = service_info
  else
    policy.app_services["MEDIA"] = service_info
  end
  return policy
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
    if data.params.systemCapability.systemCapabilityType == "NAVIGATION" then
      return true
    elseif first_run then
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
  commonTestCases:DelayedExp(2000)
end

function commonAppServices.publishMobileAppService(manifest, app_id)
  if not app_id then app_id = 1 end
  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("PublishAppService", {
    appServiceManifest = manifest
  })

  local first_run_mobile = true
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated"):Times(AtLeast(1)):ValidIf(function(self, data)
    if first_run_mobile then
      first_run_mobile = false
      local publishedParams = commonAppServices.appServiceCapability("PUBLISHED", manifest)
      return commonAppServices.findCapabilityUpdate(publishedParams, data.payload)
    else
      local activatedParams = commonAppServices.appServiceCapability("ACTIVATED", manifest)
      return commonAppServices.findCapabilityUpdate(activatedParams, data.payload)
    end
  end)
  local first_run_hmi = true
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated"):Times(AtLeast(1)):ValidIf(function(self, data)
    if data.params.systemCapability.systemCapabilityType == "NAVIGATION" then
      return true
    elseif first_run_hmi then
      first_run_hmi = false
      local publishedParams = commonAppServices.appServiceCapability("PUBLISHED", manifest)
      return commonAppServices.findCapabilityUpdate(publishedParams, data.params)
    else
      local activatedParams = commonAppServices.appServiceCapability("ACTIVATED", manifest)
      return commonAppServices.findCapabilityUpdate(activatedParams, data.params)
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
  commonTestCases:DelayedExp(2000)
end

function commonAppServices.publishSecondMobileAppService(manifest1, manifest2, app_id)
  if not app_id then app_id = 2 end

  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("PublishAppService", {
    appServiceManifest = manifest2
  })

  local second_app_record = commonAppServices.appServiceCapability("PUBLISHED", manifest2)

  local publishedParams = commonAppServices.appServiceCapabilityUpdateParams("ACTIVATED", manifest1)
  publishedParams.systemCapability.appServicesCapabilities.appServices[2] = second_app_record
  publishedParams.systemCapability.appServicesCapabilities.appServices[1].updateReason = nil

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", publishedParams):Times(1)
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
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated")
end

function commonAppServices.mobileSubscribeAppServiceData(provider_app_id, service_type, app_id)
  if not app_id then app_id = 1 end
  if not service_type then service_type = "MEDIA" end
  local requestParams = {
    serviceType = service_type,
    subscribe = true
  }
  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("GetAppServiceData", requestParams)
  local service_id = commonAppServices.getAppServiceID(provider_app_id)
  local responseParams = {
    serviceData = commonAppServices.appServiceDataByType(service_id, service_type)
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

function commonAppServices.GetAppServiceSystemCapability(manifest, subscribe, app_id)
  if not app_id then app_id = 1 end
  local requestParams = {
    systemCapabilityType = "APP_SERVICES",
    subscribe = subscribe
  }

  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("GetSystemCapability", requestParams)

  local responseParams = {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "APP_SERVICES",
      appServicesCapabilities = {
        appServices = {{
          updatedAppServiceRecord = {
            serviceManifest = manifest
          }
        }}
      }
    }
  }

  mobileSession:ExpectResponse(cid, responseParams)
end

function commonAppServices.cleanSession(app_id)
  test.mobileSession[app_id]:StopRPC()
  :Do(function(_, d)
    utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
    test.mobileSession[app_id] = nil
  end)
  utils.wait()
end

function commonAppServices.setValidateSchema(value)
  config.ValidateSchema = value
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

--[[Timeout]]
function commonAppServices.getRpcPassThroughTimeoutFromINI()
  return tonumber(commonAppServices.sdl.getSDLIniParameter("RpcPassThroughTimeout"))
end

function commonAppServices:Request_PTU()  
  commonAppServices.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
  commonAppServices.isPTUStarted()
end

function commonAppServices.GetPolicySnapshot()
  return utils.jsonFileToTable("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
end

function commonAppServices.test_assert(condition, msg)
  if not condition then
    test:FailTestCase(msg)
  end
end


return commonAppServices
