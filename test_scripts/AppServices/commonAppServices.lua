local crc32 = require('crc32')
local actions = require("user_modules/sequences/actions")
local commonAppServices = actions

commonAppServices.serviceIDs = {}

--[[ Common Functions ]]
-- COMMON FUNCTIONS TO TABLE
local function ConvertTableToString(tbl, i)
    local strIndex = ""
    local strIndex2 = ""
    local strReturn = ""
    for j = 1, i do
      strIndex = strIndex .. "\t"
    end
    strIndex2 = strIndex .."\t"
    local x = 0
    if type(tbl) == "table" then
      strReturn = strReturn .. strIndex .. "{\n"
      for k,v in pairs(tbl) do
        x = x + 1
        if type(k) == "number" then
          if type(v) == "table" then
            if x ==1 then
            else
              strReturn = strReturn .. ",\n"
            end
          else
            if x ==1 then
              strReturn = strReturn .. strIndex2
            else
              strReturn = strReturn .. ",\n" .. strIndex2
            end
          end
        else
          if x ==1 then
            strReturn = strReturn .. strIndex2 .. k .. " = "
          else
            strReturn = strReturn .. ",\n" .. strIndex2 .. k .. " = "
          end
          if type(v) == "table" then
            strReturn = strReturn .. "\n"
          end
        end
        strReturn = strReturn .. ConvertTableToString(v, i+1)
      end
      strReturn = strReturn .. "\n"
      strReturn = strReturn .. strIndex .. "}"
    else
      if type(tbl) == "number" then
        strReturn = strReturn .. tbl
      elseif type(tbl) == "boolean" then
        strReturn = strReturn .. tostring(tbl)
      elseif type(tbl) == "string" then
        strReturn = strReturn .."\"".. tbl .."\""
      end
    end
    return strReturn
end
  
local function PrintTable(tbl)
    print ("-------------------------------------------------------------------")
    print (ConvertTableToString (tbl, 1))
    print ("-------------------------------------------------------------------")
end
  
--[[ App Service RPCS ]]
local function appServiceCapability(update_reason, manifest) 
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
          appServiceCapability(update_reason, manifest)
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
    groups = { "Base-4" , "AppServiceProducer" },
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

function commonAppServices.publishEmbeddedAppService(manifest)
    local cid = commonAppServices.getHMIConnection():SendRequest("AppService.PublishAppService", {appServiceManifest = manifest})

    -- EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated"):Times(AtLeast(1))
    -- EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    --     commonAppServices.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    --     commonAppServices.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)
  EXPECT_HMIRESPONSE(cid, {
    result = {
      appServiceRecord = {
        serviceManifest = manifest,
        servicePublished = true
      },
      code = 0, 
      method = "AppService.PublishAppService"
    }
  })
  :Do(function(_, data)
    -- PrintTable(data)
    commonAppServices.serviceIDs["HMI"] = data.result.appServiceRecord.serviceID
    end)
end


function commonAppServices.publishMobileAppService(manifest, app_id)
  if not app_id then app_id = 1 end
  local mobileSession = commonAppServices.getMobileSession(app_id)
  local cid = mobileSession:SendRPC("PublishAppService", {
    appServiceManifest = manifest
  })

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    commonAppServices.appServiceCapabilityUpdateParams("PUBLISHED", manifest), 
    commonAppServices.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)

  mobileSession:ExpectResponse(cid, {
    appServiceRecord = {
      serviceManifest = manifest,
      servicePublished = true
    },
    success = true,
    resultCode = "SUCCESS"}
  ):Do(function(_, data)
      commonAppServices.serviceIDs[app_id] = data.payload.appServiceRecord.serviceID
    --   print(commonAppServices.serviceIDs[app_id])
    end)
end


--[[ GetFile ]]

local function file_check(file_name)
    local file_found=io.open(file_name, "r")
  
    if file_found==nil then
      return false
    else
      return true
    end
end

local function getBinaryData(fileName)
    local inp = assert(io.open("files/"..fileName, "rb"))
    local data = inp:read("*all")
    data = string.gsub(data, "\r\n", "\n")
    assert(inp:close())
    return data
end

local function getFileCRC32(bin_data)
    local crc = crc32.crc32(0, bin_data)   
    return crc
end

function commonAppServices.getFileFromStorage(app_id, request_params, response_params)
    local mobileSession = commonAppServices.getMobileSession(app_id)
    if file_check("files/"..request_params.fileName) and response_params.crc == nil then
        local file_data = getBinaryData(request_params.fileName);
        local file_crc = getFileCRC32(file_data)   
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
        local file_data = getBinaryData(request_params.fileName);
        local file_crc = getFileCRC32(file_data)   
        if response_params.success then
            response_params.crc = file_crc
        end
    end

    request_params.appServiceId = commonAppServices.serviceIDs[asp_app_id]

    --mobile side: sending GetFile request
    local cid = mobileSession:SendRPC("GetFile", request_params)
    if asp_app_id == "HMI" then 
        --EXPECT_HMICALL
        commonAppServices.getHMIConnection():ExpectRequest("BasicCommunication.GetFilePath")
        :Do(function(_, d2)
            print("Received get file path")
            -- commonAppServices.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", {})
            -- ptuTable = utils.jsonFileToTable(d2.params.file)
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