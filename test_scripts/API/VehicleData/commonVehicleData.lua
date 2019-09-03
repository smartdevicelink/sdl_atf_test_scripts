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

commonVehicleData.EMPTY_ARRAY = json.EMPTY_ARRAY
commonVehicleData.timeout = 2000
commonVehicleData.minTimeout = 500
commonVehicleData.DEFAULT = "Default"
commonVehicleData.cloneTable =  utils.cloneTable
commonVehicleData.allVehicleData = {
  gps = {
    value = {
      longitudeDegrees = 100,
      latitudeDegrees = 20.5,
      utcYear = 2020,
      utcMonth = 6,
      utcDay = 3,
      utcHours = 14,
      utcMinutes = 4,
      utcSeconds = 34,
      pdop = 10,
      hdop = 100,
      vdop = 500,
      actual = false,
      compassDirection = "WEST",
      dimension = "2D",
      satellites = 5,
      altitude = 10,
      heading = 100.9,
      speed = 40.5
    },
    type = "VEHICLEDATA_GPS"
  },
  speed = {
    value = 30.2,
    type = "VEHICLEDATA_SPEED"
  },
  rpm = {
    value = 10,
    type = "VEHICLEDATA_RPM"
  },
  fuelLevel = {
    value = -3,
    type = "VEHICLEDATA_FUELLEVEL"
  },
  fuelLevel_State = {
    value = "NORMAL",
    type = "VEHICLEDATA_FUELLEVEL_STATE"
  },
  instantFuelConsumption = {
    value = 1000.1,
    type = "VEHICLEDATA_FUELCONSUMPTION"
  },
  fuelRange = {
    value = { { type = "GASOLINE" , range = 20 }, { type = "BATTERY", range = 100 } },
    type = "VEHICLEDATA_FUELRANGE"
  },
  externalTemperature = {
    value = 24.1,
    type = "VEHICLEDATA_EXTERNTEMP"
  },
  turnSignal = {
    value = "OFF",
    type = "VEHICLEDATA_TURNSIGNAL"
  },
  vin = {
    value = "SJFHSIGD4058569",
    type = "VEHICLEDATA_VIN"
  },
  prndl = {
    value = "PARK",
    type = "VEHICLEDATA_PRNDL"
  },
  tirePressure = {
    value = {
      pressureTelltale = "OFF",
      leftFront = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      rightFront = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      leftRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      rightRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      innerLeftRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      innerRightRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      }
    },
    type = "VEHICLEDATA_TIREPRESSURE"
  },
  odometer = {
    value = 10000,
    type = "VEHICLEDATA_ODOMETER"
  },
  beltStatus = {
    value = {
      driverBeltDeployed = "NO_EVENT",
      passengerBeltDeployed = "NO_EVENT",
      passengerBuckleBelted = "NO_EVENT",
      driverBuckleBelted = "NO_EVENT",
      leftRow2BuckleBelted = "YES",
      passengerChildDetected = "YES",
      rightRow2BuckleBelted = "YES",
      middleRow2BuckleBelted = "NO",
      middleRow3BuckleBelted = "NO",
      leftRow3BuckleBelted = "NOT_SUPPORTED",
      rightRow3BuckleBelted = "NOT_SUPPORTED",
      leftRearInflatableBelted = "NOT_SUPPORTED",
      rightRearInflatableBelted = "FAULT",
      middleRow1BeltDeployed = "NO_EVENT",
      middleRow1BuckleBelted = "NO_EVENT"
    },
    type = "VEHICLEDATA_BELTSTATUS"
  },
  bodyInformation = {
    value = {
      parkBrakeActive = true,
      ignitionStableStatus = "IGNITION_SWITCH_STABLE",
      ignitionStatus = "RUN",
      driverDoorAjar = true,
      passengerDoorAjar = false,
      rearLeftDoorAjar = false,
      rearRightDoorAjar = false
    },
    type = "VEHICLEDATA_BODYINFO"
  },
  deviceStatus = {
    value = {
      voiceRecOn = true,
      btIconOn = false,
      callActive = false,
      phoneRoaming = true,
      textMsgAvailable = false,
      battLevelStatus = "NOT_PROVIDED",
      stereoAudioOutputMuted = false,
      monoAudioOutputMuted = false,
      signalLevelStatus = "NOT_PROVIDED",
      primaryAudioSource = "CD",
      eCallEventActive = false
    },
    type = "VEHICLEDATA_DEVICESTATUS"
  },
  driverBraking = {
    value = "NO_EVENT",
    type = "VEHICLEDATA_BRAKING"
  },
  wiperStatus = {
    value = "AUTO_OFF",
    type = "VEHICLEDATA_WIPERSTATUS"
  },
  headLampStatus = {
    value = {
      ambientLightSensorStatus = "NIGHT",
      highBeamsOn = true,
      lowBeamsOn = false
    },
    type = "VEHICLEDATA_HEADLAMPSTATUS"
  },
  engineTorque = {
    value = 24.5,
    type = "VEHICLEDATA_ENGINETORQUE"
  },
  accPedalPosition = {
    value = 10,
    type = "VEHICLEDATA_ACCPEDAL"
  },
  steeringWheelAngle = {
    value = -100,
    type = "VEHICLEDATA_STEERINGWHEEL"
  },
  engineOilLife = {
    value = 10.5,
    type = "VEHICLEDATA_ENGINEOILLIFE"
  },
  electronicParkBrakeStatus = {
    value = "OPEN",
    type = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS"
  },
  cloudAppVehicleID = {
    value = "GHF5848363FGHY90034847",
    type = "VEHICLEDATA_CLOUDAPPVEHICLEID"
  },
  eCallInfo = {
    value = {
      eCallNotificationStatus = "NOT_USED",
      auxECallNotificationStatus = "NOT_USED",
      eCallConfirmationStatus = "NORMAL"
    },
    type = "VEHICLEDATA_ECALLINFO"
  },
  airbagStatus = {
    value = {
      driverAirbagDeployed = "NO_EVENT",
      driverSideAirbagDeployed = "NO_EVENT",
      driverCurtainAirbagDeployed = "NO_EVENT",
      passengerAirbagDeployed = "NO_EVENT",
      passengerCurtainAirbagDeployed = "NO_EVENT",
      driverKneeAirbagDeployed = "NO_EVENT",
      passengerSideAirbagDeployed = "NO_EVENT",
      passengerKneeAirbagDeployed = "NO_EVENT"
    },
    type = "VEHICLEDATA_AIRBAGSTATUS"
  },
  emergencyEvent = {
    value = {
      emergencyEventType = "NO_EVENT",
      fuelCutoffStatus = "NORMAL_OPERATION",
      rolloverEvent = "NO",
      maximumChangeVelocity = "NO_EVENT",
      multipleEvents = "NO"
    },
    type = "VEHICLEDATA_EMERGENCYEVENT"
  },
  clusterModeStatus = {
    value = {
      powerModeActive = true,
      powerModeQualificationStatus = "POWER_MODE_OK",
      carModeStatus = "NORMAL",
      powerModeStatus = "KEY_APPROVED_0"
    },
    type = "VEHICLEDATA_CLUSTERMODESTATUS"
  },
  myKey = {
    value = { e911Override = "ON" },
    type = "VEHICLEDATA_MYKEY"
  }
}

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
          for vehicleDataName in pairs(commonVehicleData.allVehicleData) do
            addParamToRPC(tbl, "Emergency-1", rpc, vehicleDataName)
          end
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

function commonVehicleData.processRPCSubscriptionSuccess(pRpcName, pData, self)
  local mobileSession = commonVehicleData.getMobileSession(self, 1)
  local reqParams = {
    [pData] = true
  }
  local respData
  if pData == "clusterModeStatus" then
    respData = "clusterModes"
  else
    respData = pData
  end
  local hmiResParams = {
    [respData] = {
      resultCode = "SUCCESS",
      dataType = commonVehicleData.allVehicleData[pData].type
    }
  }
  local cid = mobileSession:SendRPC(pRpcName, reqParams)
  EXPECT_HMICALL("VehicleInfo." .. pRpcName, reqParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)

  local mobResParams = commonVehicleData.cloneTable(hmiResParams)
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, mobResParams)
end

function commonVehicleData.checkNotificationSuccess(pData, self)
  local mobileSession = commonVehicleData.getMobileSession(self, 1)
  local hmiNotParams = { [pData] = commonVehicleData.allVehicleData[pData].value }
  local mobNotParams = commonVehicleData.cloneTable(hmiNotParams)
  if mobNotParams.emergencyEvent then
    mobNotParams.emergencyEvent.maximumChangeVelocity = 0
  end
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  mobileSession:ExpectNotification("OnVehicleData", mobNotParams)
end

function commonVehicleData.checkNotificationIgnored(pData, self)
  local mobileSession = commonVehicleData.getMobileSession(self, 1)
  local hmiNotParams = { [pData] = commonVehicleData.allVehicleData[pData].value }
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  mobileSession:ExpectNotification("OnVehicleData")
  :Times(0)
end

return commonVehicleData
