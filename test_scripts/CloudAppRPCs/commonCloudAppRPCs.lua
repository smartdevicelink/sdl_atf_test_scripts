local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require("user_modules/utils")
local events = require("events")

local commonCloudAppRPCs = actions

local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

function commonCloudAppRPCs.getCloudAppConfig(app_id)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "CloudApp" },
    endpoint = "ws://127.0.0.1:2000/",
    nicknames = { config["application" .. app_id].registerAppInterfaceParams.appName },
    cloud_transport_type = "WS",
    enabled = true
  }
end

function commonCloudAppRPCs.getCloudAppStoreConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "CloudAppStore" }
  }
end

function commonCloudAppRPCs:Request_PTU()  
  commonCloudAppRPCs.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
  commonCloudAppRPCs.isPTUStarted()
end

function commonCloudAppRPCs.test_assert(condition, msg)
  if not condition then
    test:FailTestCase(msg)
  end
end

function commonCloudAppRPCs.GetPolicySnapshot()
  return jsonFileToTable("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
end

function commonCloudAppRPCs:Directory_exist(DirectoryPath)
  if type( DirectoryPath ) ~= 'string' then
          error('Directory_exist : Input parameter is not string : ' .. type(DirectoryPath) )
          return false
  else
      local response = os.execute( 'cd ' .. DirectoryPath .. " 2> /dev/null" )
      -- ATf returns as result of 'os.execute' boolean value, lua interp returns code. if conditions process result as for lua enterp and for ATF.
      if response == nil or response == false then
          return false
      end
      if response == true then
          return true
      end
      return response == 0;
  end
end

function commonCloudAppRPCs.DeleteStorageFolder()
  local ExistDirectoryResult = commonCloudAppRPCs:Directory_exist( tostring(config.pathToSDL .. "storage"))
  if ExistDirectoryResult == true then
    local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage/*" )))
    if RmFolder ~= true then
      print("Folder 'storage' is not deleted")
    end
  else
    print("Folder 'storage' is empty")
  end
end

local function getPTUFromPTS()
  local pTbl = {}
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  if utils.isFileExist(ptsFileName) then
    pTbl = utils.jsonFileToTable(ptsFileName)
  else
    utils.cprint(35, "PTS file was not found, PreloadedPT is used instead")
    local appConfigFolder = commonFunctions:read_parameter_from_smart_device_link_ini("AppConfigFolder")
    if appConfigFolder == nil or appConfigFolder == "" then
      appConfigFolder = commonPreconditions:GetPathToSDL()
    end
    local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
    local ptsFile = appConfigFolder .. preloadedPT
    if utils.isFileExist(ptsFile) then
      pTbl = utils.jsonFileToTable(ptsFile)
    else
      utils.cprint(35, "PreloadedPT was not found, PTS is not created")
    end
  end
  if next(pTbl) ~= nil then
    pTbl.policy_table.consumer_friendly_messages.messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
    pTbl.policy_table.vehicle_data = nil
  end
  return pTbl
end

function commonCloudAppRPCs.policyTableUpdateWithIconUrl(pPTUpdateFunc, pExpNotificationFunc, url)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  end
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptuFileName = os.tmpname()
  local requestId = commonCloudAppRPCs.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  commonCloudAppRPCs.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
    commonCloudAppRPCs.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = ptsFileName })
      local ptuTable = getPTUFromPTS()
      for i = 1, commonCloudAppRPCs.getAppsCount() do
        ptuTable.policy_table.app_policies[commonCloudAppRPCs.getConfigAppParams(i).fullAppID] = commonCloudAppRPCs.getAppDataForPTU(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      commonCloudAppRPCs.getHMIConnection():ExpectEvent(event, "PTU event")
      for id = 1, commonCloudAppRPCs.getAppsCount() do
        commonCloudAppRPCs.getMobileSession(id):ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY"}, {requestType = "ICON_URL"  })
        :ValidIf(function(self, data)
          if data.payload.requestType == "PROPRIETARY" then
            return true
          end
          if data.payload.requestType == "ICON_URL" and data.payload.url == url then
            return true
          end
          return false
        end)
        :Do(function(_, data)
            if data.payload.requestType == "PROPRIETARY" then
              commonCloudAppRPCs.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
              :Do(function(_, d3)
                  if not pExpNotificationFunc then
                    commonCloudAppRPCs.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
                    commonCloudAppRPCs.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
                  end
                  commonCloudAppRPCs.getHMIConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                  commonCloudAppRPCs.getHMIConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
                end)
              utils.cprint(35, "App ".. id .. " was used for PTU")
              commonCloudAppRPCs.getHMIConnection():RaiseEvent(event, "PTU event")
              local corIdSystemRequest = commonCloudAppRPCs.getMobileSession(id):SendRPC("SystemRequest", {
                requestType = "PROPRIETARY" }, ptuFileName)
              commonCloudAppRPCs.getMobileSession(id):ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
              :Do(function()
                os.remove(ptuFileName) end)
            end
          end)
        :Times(AtMost(2))
      end
    end)
end

return commonCloudAppRPCs
