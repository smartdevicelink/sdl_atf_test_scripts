---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = nil

--[[ Required Shared libraries ]]
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local mobile_session = require("mobile_session")
local json = require("modules/json")

--[[ Local Variables ]]
local ptu_table = {}
local radioControlCapabilities;
local climateControlCapabilities

local backupedFiles = {}
local createdFiles = {}

--[[ Local Functions ]]
local function insertFunctions()
  local function_id = require("function_id")
  function_id["ButtonPress"] = 100015
  function_id["GetInteriorVehicleDataCapabilities"] = 100016
  function_id["GetInteriorVehicleData"] = 100017
  function_id["SetInteriorVehicleData"] = 100018
  function_id["OnInteriorVehicleData"] = 100019
end

insertFunctions()

local function initRandom()
  math.randomseed( os.time() )
  math.random()
  math.random()
  math.random()
end

local function generateRandomValueFromList(list)
  return list[math.random(#list)]
end

local function generateRandomValueFromIntInterval(min, max)
  return math.random(min, max)
end

local function generateRandomArrayFromList(list, isValUnique, min, max)
    max = max or min
    if max < min then
      min, max = max, min
    end

    local isVariableLength = true
    if min == max then isVariableLength = false end
    local values = {table.unpack(list)}

    local count = min
    if count > #values and isValUnique and not isVariableLength then
      return error("Random array with " .. min .. " unique elements can not be generated from current list")
    end

    if isVariableLength then
      count = math.random(min, max)
    end

    local result = {}
    for _ = 1, count do
      local randVal = math.random(#values)
      table.insert(result, values[randVal])
      if isValUnique then
        table.remove(values, randVal)
      end
    end
    return result
end

local function generateRadioControlCapabilities()
  return {
      name = "Radio control module",
      radioEnableAvailable = generateRandomValueFromList({true, false}),
      radioBandAvailable = generateRandomValueFromList({true, false}),
      radioFrequencyAvailable = generateRandomValueFromList({true, false}),
      hdChannelAvailable = generateRandomValueFromList({true, false}),
      rdsDataAvailable = generateRandomValueFromList({true, false}),
      availableHDsAvailable = generateRandomValueFromList({true, false}),
      stateAvailable = generateRandomValueFromList({true, false}),
      signalStrengthAvailable = generateRandomValueFromList({true, false}),
      signalChangeThresholdAvailable = generateRandomValueFromList({true, false})
    }
end

local function generateClimateControlCapabilities()
  return {
      name = "Climate control module",
      fanSpeedAvailable = generateRandomValueFromList({true, false}),
      desiredTemperatureAvailable = generateRandomValueFromList({true, false}),
      acEnableAvailable = generateRandomValueFromList({true, false}),
      acMaxEnableAvailable = generateRandomValueFromList({true, false}),
      circulateAirEnableAvailable = generateRandomValueFromList({true, false}),
      autoModeEnableAvailable = generateRandomValueFromList({true, false}),
      dualModeEnableAvailable = generateRandomValueFromList({true, false}),
      defrostZoneAvailable = generateRandomValueFromList({true, false}),
      defrostZone = generateRandomArrayFromList({"FRONT", "REAR", "ALL", "NONE"}, true, 1, 4),
      ventilationModeAvailable = generateRandomValueFromList({true, false}),
      ventilationMode = generateRandomArrayFromList({"UPPER", "LOWER", "BOTH", "NONE"}, true, 1, 4)
    }
end

local function initCommonRC()
  initRandom()
  radioControlCapabilities = {generateRadioControlCapabilities()}
  climateControlCapabilities = {generateClimateControlCapabilities()}
end

initCommonRC()

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
        }
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

function commonRC.prepareInteriorVehicleDataCapabilitiesJson(IVDCapabilitiesTable, IVDCapabilitiesFileName)
  -- Validation check
  if not IVDCapabilitiesTable.interiorVehicleDataCapabilities then IVDCapabilitiesTable = nil end
  if not IVDCapabilitiesFileName or type(IVDCapabilitiesFileName) ~= "string" then IVDCapabilitiesFileName = "IVDCapabilities.json" end

  commonPreconditions:BackupFile("smartDeviceLink.ini")
  table.insert(backupedFiles, "smartDeviceLink.ini")
  local isBackuped = false
  local sdlPath = commonPreconditions:GetPathToSDL()
  local IVDCapabilitiesFilePath = commonFunctions:pathJoin(sdlPath, "plugins/" .. IVDCapabilitiesFileName)
  commonFunctions:write_parameter_to_smart_device_link_ini("InteriorVDCapabilitiesFile", "./plugins/" .. IVDCapabilitiesFileName)

  if commonFunctions:File_exists(IVDCapabilitiesFilePath) then
    commonPreconditions:BackupFile("plugins/" .. IVDCapabilitiesFileName)
    table.insert(backupedFiles, "plugins/" .. IVDCapabilitiesFileName)
    isBackuped = true
  end

  if IVDCapabilitiesTable then
    tableToJsonFile(IVDCapabilitiesTable, IVDCapabilitiesFilePath)
    if not isBackuped then
      table.insert(createdFiles, IVDCapabilitiesFilePath)
    end
  end
end

function commonRC.restoreInteriorVehicleDataCapabilitiesJson()
  for _,fileName in pairs(backupedFiles) do
    commonPreconditions:RestoreFile(fileName)
  end
  for _,fileName in pairs(createdFiles) do
    os.execute( " rm -f " .. fileName)
  end
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
  commonRC.restoreInteriorVehicleDataCapabilitiesJson()
  StopSDL()
end

function commonRC.getInteriorZone()
  return {
      col = 0,
      row = 0,
      level = 0,
      colspan = 2,
      rowspan = 2,
      levelspan = 1
    }
end

function commonRC.getClimateControlData()
  return {
      fanSpeed = 50,
      currentTemp = 30,
      desiredTemp = 24,
      temperatureUnit = "CELSIUS",
      acEnable = true,
      circulateAirEnable = true,
      autoModeEnable = true,
      defrostZone = "FRONT",
      dualModeEnable = true
    }
end

function commonRC.getRadioControlData()
  return {
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

function commonRC.getClimateControlCapabilities()
  return climateControlCapabilities
end

function commonRC.getRadioControlCapabilities()
  return radioControlCapabilities
end

function commonRC.getInteriorVehicleDataCapabilities(module_types)
  local out = { }
  if not module_types then
    return out
  end
  for _, v in pairs(module_types) do
    if v == "CLIMATE" then
      out.climateControlCapabilities = commonRC.getClimateControlCapabilities()
    elseif v == "RADIO" then
      out.radioControlCapabilities = commonRC.getRadioControlCapabilities()
    end
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

function commonRC.consent(self)
  EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent")
  :Times(1)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { allowed = true })
    end)
end

return commonRC
