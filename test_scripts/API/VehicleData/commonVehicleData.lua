---------------------------------------------------------------------------------------------------
-- VehicleData common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")
local events = require("events")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local ptu_table = {}
local hmiAppIds = {}

local commonVehicleData = {}

commonVehicleData.timeout = 2000
commonVehicleData.minTimeout = 500
commonVehicleData.DEFAULT = "Default"
commonVehicleData.cloneTable =  utils.cloneTable

local function checkIfPTSIsSentAsBinary(bin_data)
  if not (bin_data ~= nil and string.len(bin_data) > 0) then
    commonFunctions:userPrint(31, "PTS was not sent to Mobile in payload of OnSystemRequest")
  end
end

function commonVehicleData.getGetVehicleDataConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "Emergency-1", "VehicleInfo-3" }
  }
end

local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
  tbl.policy_table.vehicle_data = nil
end

local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function addParamToRPC(tbl, functional_grouping, rpc, param)
  local is_found = false
  local params = tbl.policy_table.functional_groupings[functional_grouping].rpcs[rpc].parameters
  for _, value in pairs(params) do
    if (value == param) then is_found = true end
  end
  if not is_found then
    table.insert(tbl.policy_table.functional_groupings[functional_grouping].rpcs[rpc].parameters, param)
  end
end

local function ptu(self, app_id, ptu_update_func)
  local function getAppsCount()
    local count = 0
    for _ in pairs(hmiAppIds) do
      count = count + 1
    end
    return count
  end

  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptu_table)
      local function updatePTU(tbl)
        for rpc in pairs(tbl.policy_table.functional_groupings["Emergency-1"].rpcs) do
          addParamToRPC(tbl, "Emergency-1", rpc, "engineOilLife")
          addParamToRPC(tbl, "Emergency-1", rpc, "fuelRange")
          addParamToRPC(tbl, "Emergency-1", rpc, "tirePressure")
          addParamToRPC(tbl, "Emergency-1", rpc, "electronicParkBrakeStatus")
          addParamToRPC(tbl, "Emergency-1", rpc, "turnSignal")
          addParamToRPC(tbl, "Emergency-1", rpc, "gps")
        end
        tbl.policy_table.app_policies[commonVehicleData.getMobileAppId(app_id)] = commonVehicleData.getGetVehicleDataConfig()
      end
      updatePTU(ptu_table)
      if ptu_update_func then
        ptu_update_func(ptu_table)
      end
      local function tableToJsonFile(tbl, file_name)
        local f = io.open(file_name, "w")
        f:write(json.encode(tbl))
        f:close()
      end
      tableToJsonFile(ptu_table, ptu_file_name)

      local event = events.Event()
      event.matches = function(self, e) return self == e end
      EXPECT_EVENT(event, "PTU event")
      :Timeout(11000)

      for id = 1, getAppsCount() do
        local mobileSession = commonVehicleData.getMobileSession(self, id)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d2)
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            checkIfPTSIsSentAsBinary(d2.binaryData)
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          end)
        :Times(AtMost(1))
      end
    end)
  os.remove(ptu_file_name)
end

function commonVehicleData.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[Module functions]]
function commonVehicleData.activateApp(pAppId, self)
  self, pAppId = commonVehicleData.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
  local mobSession = commonVehicleData.getMobileSession(self, pAppId)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(commonVehicleData.minTimeout)
end

function commonVehicleData.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

function commonVehicleData.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
end

function commonVehicleData.getMobileSession(self, pAppId)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

function commonVehicleData.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.fullAppID
end

function commonVehicleData.getPathToSDL()
  return config.pathToSDL
end

function commonVehicleData.postconditions()
  StopSDL()
end

function commonVehicleData.registerAppWithPTU(id, ptu_update_func, self)
  self, id, ptu_update_func = commonVehicleData.getSelfAndParams(id, ptu_update_func, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
            { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
          :Times(3)
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :Do(function(e, d2)
              if e.occurences == 1 then
                self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
                ptu_table = jsonFileToTable(d2.params.file)
                ptu(self, id, ptu_update_func)
              else
                self:FailTestCase("BC.PolicyUpdate was sent more than once (PTU update was incorrect)")
              end
            end)
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange"):Times(2)
          EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true})
        end)
    end)
end

function commonVehicleData.raiN(id, self)
  self, id = commonVehicleData.getSelfAndParams(id, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
      allowed = true,
      source = "GUI",
      device = {
        id = commonVehicleData.getDeviceMAC(),
        name = commonVehicleData.getDeviceName()
      }
    })
end

function commonVehicleData.start(pHMIParams, self)
  self, pHMIParams = commonVehicleData.getSelfAndParams(pHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady(pHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  allowSDL(self)
                end)
            end)
        end)
    end)
end

function commonVehicleData.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

function commonVehicleData.getDeviceMAC()
  local cmd = "echo -n " .. commonVehicleData.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

return commonVehicleData
