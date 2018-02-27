---------------------------------------------------------------------------------------------------
-- RC common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require("mobile_session")
local json = require("modules/json")
local hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local ptu_table = {}
local hmiAppIds = {}

local commonRC = {}

commonRC.timeout = 2000
commonRC.minTimeout = 500
commonRC.DEFAULT = "Default"
commonRC.buttons = { climate = "FAN_UP", radio = "VOLUME_UP" }

local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
end

function commonRC.getRCAppConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    moduleType = { "RADIO", "CLIMATE" },
    groups = { "Base-4", "RemoteControl" },
    AppHMIType = { "REMOTE_CONTROL" }
  }
end

local function updatePTU(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function tableToJsonFile(tbl, file_name)
  local f = io.open(file_name, "w")
  f:write(json.encode(tbl))
  f:close()
end

local function checkIfPTSIsSentAsBinary(bin_data)
  if not (bin_data ~= nil and string.len(bin_data) > 0) then
    commonFunctions:userPrint(31, "PTS was not sent to Mobile in payload of OnSystemRequest")
  end
end

local function ptu(self, ptu_update_func)
  local function getAppsCount()
    local count = 0
    for _, _ in pairs(hmiAppIds) do
      count = count + 1
    end
    return count
  end

  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptu_table)
      updatePTU(ptu_table)
      if ptu_update_func then
        ptu_update_func(ptu_table)
      end
      tableToJsonFile(ptu_table, ptu_file_name)

      local event = events.Event()
      event.matches = function(self, e) return self == e end
      EXPECT_EVENT(event, "PTU event")
      :Timeout(11000)

      for id = 1, getAppsCount() do
        local mobileSession = commonRC.getMobileSession(self, id)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d2)
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            checkIfPTSIsSentAsBinary(d2.binaryData)
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptu_file_name) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

local function allow_sdl(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = commonRC.getDeviceMAC(),
      name = commonRC.getDeviceName()
    }
  })
end

function commonRC.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

function commonRC.getDeviceMAC()
  local cmd = "echo -n " .. commonRC.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

function commonRC.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

function commonRC.start(pHMIParams, self)
  self, pHMIParams = commonRC.getSelfAndParams(pHMIParams, self)
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
                  allow_sdl(self)
                end)
            end)
        end)
    end)
end

function commonRC.rai_ptu(ptu_update_func, self)
  self, ptu_update_func = commonRC.getSelfAndParams(ptu_update_func, self)
  commonRC.rai_ptu_n(1, ptu_update_func, self)
end

function commonRC.rai_ptu_n(id, ptu_update_func, self)
  self, id, ptu_update_func = commonRC.getSelfAndParams(id, ptu_update_func, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.appID] = d1.params.application.appID
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
          :Times(3)
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(self, ptu_update_func)
            end)
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
          :Times(2)
        end)
    end)
end

function commonRC.rai_n(id, self)
  self, id = commonRC.getSelfAndParams(id, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function commonRC.unregisterApp(pAppId, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local hmiAppId = commonRC.getHMIAppId(pAppId)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonRC.activate_app(pAppId, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(commonRC.minTimeout)
end

function commonRC.postconditions()
  StopSDL()
end

function commonRC.getSelfAndParams(...)
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

function commonRC.getModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 50,
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 20.1
      },
      desiredTemperature = {
        unit = "CELSIUS",
        value = 10.5
      },
      acEnable = true,
      circulateAirEnable = true,
      autoModeEnable = true,
      defrostZone = "FRONT",
      dualModeEnable = true,
      acMaxEnable = true,
      ventilationMode = "BOTH"
    }
  elseif module_type == "RADIO" then
    out.radioControlData = {
      frequencyInteger = 1,
      frequencyFraction = 2,
      band = "AM",
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 1,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 1,
      hdChannel = 1,
      signalStrength = 5,
      signalChangeThreshold = 10,
      radioEnable = true,
      state = "ACQUIRING"
    }
  end
  return out
end

function commonRC.getAnotherModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 65,
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 44.3
      },
      desiredTemperature = {
        unit = "CELSIUS",
        value = 22.6
      },
      acEnable = false,
      circulateAirEnable = false,
      autoModeEnable = true,
      defrostZone = "ALL",
      dualModeEnable = true,
      acMaxEnable = false,
      ventilationMode = "UPPER"
    }
  elseif module_type == "RADIO" then
    out.radioControlData = {
      frequencyInteger = 1,
      frequencyFraction = 2,
      band = "AM",
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 2,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 1,
      hdChannel = 1,
      signalStrength = 5,
      signalChangeThreshold = 20,
      radioEnable = true,
      state = "ACQUIRING"
    }
  end
  return out
end

function commonRC.getButtonNameByModule(pModuleType)
  return commonRC.buttons[string.lower(pModuleType)]
end

function commonRC.getReadOnlyParamsByModule(pModuleType)
  local out = { moduleType = pModuleType }
  if pModuleType == "CLIMATE" then
    out.climateControlData = {
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 32.6
      }
    }
  elseif pModuleType == "RADIO" then
    out.radioControlData = {
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 2,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 2,
      signalStrength = 4,
      signalChangeThreshold = 22,
      state = "MULTICAST"
    }
  end
  return out
end

function commonRC.getModuleParams(pModuleData)
  if pModuleData.moduleType == "CLIMATE" then
    if not pModuleData.climateControlData then
      pModuleData.climateControlData = { }
    end
    return pModuleData.climateControlData
  elseif pModuleData.moduleType == "RADIO" then
    if not pModuleData.radioControlData then
      pModuleData.radioControlData = { }
    end
    return pModuleData.radioControlData
  end
end

function commonRC.getSettableModuleControlData(pModuleType)
  local out = commonRC.getModuleControlData(pModuleType)
  local params_read_only = commonRC.getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))
  for p_read_only in pairs(params_read_only) do
    commonRC.getModuleParams(out)[p_read_only] = nil
  end
  return out
end

-- RC RPCs structure
local rcRPCs = {
  GetInteriorVehicleData = {
    appEventName = "GetInteriorVehicleData",
    hmiEventName = "RC.GetInteriorVehicleData",
    requestParams = function(pModuleType, pSubscribe)
      return {
        moduleType = pModuleType,
        subscribe = pSubscribe
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId, pSubscribe)
      return {
        appID = commonRC.getHMIAppId(pAppId),
        moduleType = pModuleType,
        subscribe = pSubscribe
      }
    end,
    hmiResponseParams = function(pModuleType, pSubscribe)
      return {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pSubscribe)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      }
    end
  },
  SetInteriorVehicleData = {
    appEventName = "SetInteriorVehicleData",
    hmiEventName = "RC.SetInteriorVehicleData",
    requestParams = function(pModuleType)
      return {
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = commonRC.getHMIAppId(pAppId),
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      }
    end,
    hmiResponseParams = function(pModuleType)
      return {
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      }
    end,
    responseParams = function(success, resultCode, pModuleType)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = commonRC.getSettableModuleControlData(pModuleType)
      }
    end
  },
  ButtonPress = {
    appEventName = "ButtonPress",
    hmiEventName = "Buttons.ButtonPress",
    requestParams = function(pModuleType)
      return {
        moduleType = pModuleType,
        buttonName = commonRC.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = commonRC.getHMIAppId(pAppId),
        moduleType = pModuleType,
        buttonName = commonRC.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      }
    end,
    hmiResponseParams = function()
      return {}
    end,
    responseParams = function(success, resultCode)
      return {
        success = success,
        resultCode = resultCode
      }
    end
  },
  GetInteriorVehicleDataConsent = {
    hmiEventName = "RC.GetInteriorVehicleDataConsent",
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = commonRC.getHMIAppId(pAppId),
        moduleType = pModuleType
      }
    end,
    hmiResponseParams = function(pAllowed)
      return {
        allowed = pAllowed
      }
    end,
  },
  OnInteriorVehicleData = {
    appEventName = "OnInteriorVehicleData",
    hmiEventName = "RC.OnInteriorVehicleData",
    hmiResponseParams = function(pModuleType)
      return {
        moduleData = commonRC.getAnotherModuleControlData(pModuleType)
      }
    end,
    responseParams = function(pModuleType)
      return {
        moduleData = commonRC.getAnotherModuleControlData(pModuleType)
      }
    end
  },
  OnRemoteControlSettings = {
    hmiEventName = "RC.OnRemoteControlSettings",
    hmiResponseParams = function(pAllowed, pAccessMode)
      return {
        allowed = pAllowed,
        accessMode = pAccessMode
      }
    end
  }
}

function commonRC.getAppEventName(pRPC)
  return rcRPCs[pRPC].appEventName
end

function commonRC.getHMIEventName(pRPC)
  return rcRPCs[pRPC].hmiEventName
end

function commonRC.getAppRequestParams(pRPC, ...)
  return rcRPCs[pRPC].requestParams(...)
end

function commonRC.getAppResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function commonRC.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function commonRC.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

function commonRC.subscribeToModule(pModuleType, pAppId, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  local rpc = "GetInteriorVehicleData"
  local subscribe = true
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function commonRC.unSubscribeToModule(pModuleType, pAppId, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  local rpc = "GetInteriorVehicleData"
  local subscribe = false
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function commonRC.isSubscribed(pModuleType, pAppId, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local rpc = "OnInteriorVehicleData"
  self.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), commonRC.getAppResponseParams(rpc, pModuleType))
end

function commonRC.isUnsubscribed(pModuleType, pAppId, self)
  self, pAppId = commonRC.getSelfAndParams(pAppId, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local rpc = "OnInteriorVehicleData"
  self.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), {}):Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
end

function commonRC.getMobileSession(self, pAppId)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

function commonRC.defineRAMode(pAllowed, pAccessMode, self)
  self, pAccessMode = commonRC.getSelfAndParams(pAccessMode, self)
  local rpc = "OnRemoteControlSettings"
  self.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pAllowed, pAccessMode))
  commonTestCases:DelayedExp(commonRC.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

function commonRC.rpcDenied(pModuleType, pAppId, pRPC, pResultCode, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.rpcAllowed(pModuleType, pAppId, pRPC, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.rpcAllowedWithConsent(pModuleType, pAppId, pRPC, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
      :Do(function(_, data2)
          self.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.rpcRejectWithConsent(pModuleType, pAppId, pRPC, self)
  local info = "The resource is in use and the driver disallows this remote control RPC"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, false))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.rpcRejectWithoutConsent(pModuleType, pAppId, pRPC, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.buildButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return hmi_values.createButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
end

function commonRC.buildHmiRcCapabilities(pClimateCapabilities, pRadioCapabilities, pButtonCapabilities)
  local hmiParams = hmi_values.getDefaultHMITable()
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability

  hmiParams.RC.IsReady.params.available = true

  if pClimateCapabilities then
    if pClimateCapabilities ~= commonRC.DEFAULT then
      capParams.climateControlCapabilities = pClimateCapabilities
    end
  else
    capParams.climateControlCapabilities = nil
  end

  if pRadioCapabilities then
    if pRadioCapabilities ~= commonRC.DEFAULT then
      capParams.radioControlCapabilities = pRadioCapabilities
    end
  else
    capParams.radioControlCapabilities = nil
  end

  if pButtonCapabilities then
    if pButtonCapabilities ~= commonRC.DEFAULT then
      capParams.buttonCapabilities = pButtonCapabilities
    end
  else
    capParams.buttonCapabilities = nil
  end

  return hmiParams
end

function commonRC.backupHMICapabilities()
  local hmiCapabilitiesFile = commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  commonPreconditions:BackupFile(hmiCapabilitiesFile)
end

function commonRC.restoreHMICapabilities()
  local hmiCapabilitiesFile = commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  commonPreconditions:RestoreFile(hmiCapabilitiesFile)
end

function commonRC.getButtonIdByName(pArray, pButtonName)
  for id, buttonData in pairs(pArray) do
    if buttonData.name == pButtonName then
      return id
    end
  end
end

function commonRC.updateDefaultCapabilities(pDisabledModuleTypes)
  local hmiCapabilitiesFile = commonPreconditions:GetPathToSDL()
    .. commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  local hmiCapTbl = jsonFileToTable(hmiCapabilitiesFile)
  local rcCapTbl = hmiCapTbl.UI.systemCapabilities.remoteControlCapability
  for _, pDisabledModuleType in pairs(pDisabledModuleTypes) do
    local buttonId = commonRC.getButtonIdByName(rcCapTbl.buttonCapabilities, commonRC.getButtonNameByModule(pDisabledModuleType))
    table.remove(rcCapTbl.buttonCapabilities, buttonId)
    rcCapTbl[string.lower(pDisabledModuleType) .. "ControlCapabilities"] = nil
  end
  tableToJsonFile(hmiCapTbl, hmiCapabilitiesFile)
end

return commonRC
