---------------------------------------------------------------------------------------------------
-- RC common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = nil

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local mobile_session = require("mobile_session")
local json = require("modules/json")

--[[ Local Variables ]]
local ptu_table = {}

--[[ Local Functions ]]
local function initHMI(self)
  local exp_waiter = commonFunctions:createMultipleExpectationsWaiter(self, "HMI initialization")
  local function registerComponent(name, subscriptions)
    local rid = self.hmiConnection:SendRequest("MB.registerComponent", { componentName = name })
    local exp = EXPECT_HMIRESPONSE(rid)
    exp_waiter:AddExpectation(exp)
    if subscriptions then
      for _, s in ipairs(subscriptions) do
        exp:Do(function()
            rid = self.hmiConnection:SendRequest("MB.subscribeTo", { propertyName = s })
            exp = EXPECT_HMIRESPONSE(rid)
            exp_waiter:AddExpectation(exp)
          end)
      end
    end
  end

  local web_socket_connected_event = EXPECT_HMIEVENT(events.connectedEvent, "Connected websocket")
  :Do(function()
      registerComponent("Buttons", {"Buttons.OnButtonSubscription"})
      registerComponent("TTS")
      registerComponent("VR")
      registerComponent("BasicCommunication", {
          "BasicCommunication.OnPutFile",
          "SDL.OnStatusUpdate",
          "SDL.OnAppPermissionChanged",
          "BasicCommunication.OnSDLPersistenceComplete",
          "BasicCommunication.OnFileRemoved",
          "BasicCommunication.OnAppRegistered",
          "BasicCommunication.OnAppUnregistered",
          "BasicCommunication.PlayTone",
          "BasicCommunication.OnSDLClose",
          "SDL.OnSDLConsentNeeded",
          "BasicCommunication.OnResumeAudioSource"
        })
      registerComponent("UI", {
          "UI.OnRecordStart"
        })
      registerComponent("VehicleInfo")
      registerComponent("RC")
      registerComponent("Navigation", {
          "Navigation.OnAudioDataStreaming",
          "Navigation.OnVideoDataStreaming"
        })
    end)
  exp_waiter:AddExpectation(web_socket_connected_event)

  self.hmiConnection:Connect()
  return exp_waiter.expectation
end

local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
end

local function updatePTU(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = { "RADIO", "CLIMATE" },
      groups = { "Base-4" },
      groups_primaryRC = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  tbl.policy_table.functional_groupings["RemoteControl"] = {
      rpcs = {
        GetInteriorVehicleDataCapabilities = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        },
        GetInteriorVehicleData = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        },
        SetInteriorVehicleData = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        },
        ButtonPress = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        },
        OnInteriorVehicleData = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
        },
      }
    }
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
      self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d2)
          checkIfPTSIsSentAsBinary(d2.binaryData)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, d3)
              self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          self.mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
        end)
    end)
  os.remove(ptu_file_name)
end

--[[ Module Functions ]]

local commonRC = {}

commonRC.timeout = 2000

function commonRC.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

function commonRC.start(self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady()
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
                  self.mobileSession:StartService(7)
                  :Do(function()
                      commonFunctions:userPrint(35, "Session started")
                    end)
                end)
            end)
        end)
    end)
end

function commonRC.rai_ptu(ptu_update_func, self)
  self, ptu_update_func = commonRC.getSelfAndParams(ptu_update_func, self)

  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.appID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
      :Times(3)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(function(_, d2)
          self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
          ptu_table = jsonFileToTable(d2.params.file)
          ptu(self, ptu_update_func)
        end)
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
      self.mobileSession:ExpectNotification("OnPermissionsChange")
    end)
end

function commonRC.rai_n(id, self)
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config["application" .. id].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          self.applications[config["application" .. id].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function commonRC.postconditions()
  StopSDL()
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

function commonRC.getSelfAndParams(param, self)
  if not self then
    return param, nil
  end
  return self, param
end

function commonRC.getMobileSession(self, id)
  if id == 2 then
    return self.mobileSession2
  end
  return self.mobileSession
end

local function subscriptionToModule(pModuleType, pSubscribe, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = pSubscribe
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType),
    isSubscribed = pSubscribe
  })
end

function commonRC.subscribeToModule(pModuleType, self)
  subscriptionToModule(pModuleType, true, self)
end

function commonRC.unSubscribeToModule(pModuleType, self)
  subscriptionToModule(pModuleType, false, self)
end

function commonRC.isSubscribed(pModuleType, self)
  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
    moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {
    moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  })
end

function commonRC.isUnsubscribed(pModuleType, self)
  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
    moduleData = commonRC.getAnotherModuleControlData(pModuleType)
  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {}):Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.getButtonNameByModule(pModuleType)
  if pModuleType == "CLIMATE" then
    return "FAN_UP"
  elseif pModuleType == "RADIO" then
    return "VOLUME_UP"
  end
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
      radioEnable = true,
      state = "MULTICAST"
    }
  end
  return out
end

return commonRC
