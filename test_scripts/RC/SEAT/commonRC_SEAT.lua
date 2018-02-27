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
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local hmi_values = require("user_modules/hmi_values")
local initialCommon = require('test_scripts/RC/commonRC')
local test = require("user_modules/dummy_connecttest")
local json = require("modules/json")
--[[ Local Variables ]]
local commonRC = {}

commonRC.timeout = 2000
commonRC.minTimeout = 500
commonRC.DEFAULT = "Default"
commonRC.buttons = { climate = "FAN_UP", radio = "VOLUME_UP" }


function commonRC.getRCAppConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    moduleType = { "RADIO", "CLIMATE", "SEAT" },
    groups = { "Base-4", "RemoteControl" },
    AppHMIType = { "REMOTE_CONTROL" }
  }
end

local function tableToJsonFile(tbl, file_name)
  local f = io.open(file_name, "w")
  f:write(json.encode(tbl))
  f:close()
end

function commonRC.preconditions()
  initialCommon.preconditions()
end

function commonRC.start(pHMIParams)
  initialCommon.start(pHMIParams, test)
end

function commonRC.rai_ptu(ptu_update_func)
  initialCommon.rai_ptu(ptu_update_func, test)
end

function commonRC.rai_ptu_n(id, ptu_update_func)
  initialCommon.rai_ptu_n(id, ptu_update_func, test)
end

function commonRC.rai_n(id)
  initialCommon.rai_n(id, test)
end

function commonRC.unregisterApp(pAppId)
  initialCommon.unregisterApp(pAppId, test)
end

function commonRC.activate_app(pAppId)
  initialCommon.activate_app(pAppId, test)
end

function commonRC.postconditions()
  initialCommon.postconditions()
end

function commonRC.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  return test["mobileSession" .. pAppId]
end

function commonRC.getHMIconnection()
  return test.hmiConnection
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
    elseif module_type == "SEAT" then
      out.seatControlData ={
      id = "DRIVER",
      heatingEnabled = true,
      coolingEnabled = true,
      heatingLevel = 50,
      coolingLevel = 50,
      horizontalPosition = 50,
      verticalPosition = 50,
      frontVerticalPosition = 50,
      backVerticalPosition = 50,
      backTiltAngle = 50,
      headSupportHorizontalPosition = 50,
      headSupportVerticalPosition = 50,
      massageEnabled = true,
      massageMode = {
        {
          massageZone = "LUMBAR",
          massageMode = "HIGH"
        },
        {
          massageZone = "SEAT_CUSHION",
          massageMode = "LOW"
        }
      },
      massageCushionFirmness = {
        {
          cushion = "TOP_LUMBAR",
          firmness = 30
        },
        {
          cushion = "BACK_BOLSTERS",
          firmness = 60
        }
      },
      memory = {
        SeatMemoryAction = "SAVE"
      },
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
    elseif module_type == "SEAT" then
      out.seatControlData ={
      id = "FRONT_PASSENGER",
      heatingEnabled = true,
      coolingEnabled = false,
      heatingLevel = 75,
      coolingLevel = 0,
      horizontalPosition = 75,
      verticalPosition = 75,
      frontVerticalPosition = 75,
      backVerticalPosition = 75,
      backTiltAngle = 75,
      headSupportHorizontalPosition = 75,
      headSupportVerticalPosition = 75,
      massageEnabled = true,
      massageMode = {
        {
          massageZone = "LUMBAR",
          massageMode = "OFF"
        },
        {
          massageZone = "SEAT_CUSHION",
          massageMode = "HIGH"
        }
      },
      massageCushionFirmness = {
        {
          cushion = "MIDDLE_LUMBAR",
          firmness = 65
        },
        {
          cushion = "SEAT_BOLSTERS",
          firmness = 30
        }
      },
      memory = {
        SeatMemoryAction = "RESTORE"
      },
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
    return pModuleData.seatControlData
  elseif pModuleData.moduleType == "SEAT" then
    if not pModuleData.seatControlData then
      pModuleData.seatControlData = { }
    end
  end
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

function commonRC.subscribeToModule(pModuleType, pAppId)
  local rpc = "GetInteriorVehicleData"
  local subscribe = true
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function commonRC.unSubscribeToModule(pModuleType, pAppId)
  local rpc = "GetInteriorVehicleData"
  local subscribe = false
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function commonRC.isSubscribed(pModuleType, pAppId)
  local mobSession = commonRC.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"
  test.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), commonRC.getAppResponseParams(rpc, pModuleType))
end

function commonRC.isUnsubscribed(pModuleType, pAppId)
  local mobSession = commonRC.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"
  test.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), {}):Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.getHMIAppId(pAppId)
  return initialCommon.getHMIAppId(pAppId)
end

function commonRC.defineRAMode(pAllowed, pAccessMode)
  local rpc = "OnRemoteControlSettings"
  test.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pAllowed, pAccessMode))
  commonTestCases:DelayedExp(commonRC.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

function commonRC.rpcDenied(pModuleType, pAppId, pRPC, pResultCode)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.rpcAllowed(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.rpcAllowedWithConsent(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
      :Do(function(_, data2)
          test.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.rpcRejectWithConsent(pModuleType, pAppId, pRPC)
  local info = "The resource is in use and the driver disallows this remote control RPC"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, false))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.rpcRejectWithoutConsent(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  commonTestCases:DelayedExp(commonRC.timeout)
end

function commonRC.buildButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return hmi_values.createButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
end

function commonRC.buildHmiRcCapabilities(pClimateCapabilities, pRadioCapabilities, pSeatCapabilities, pButtonCapabilities)
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

  if pSeatCapabilities then
    if pSeatCapabilities ~= commonRC.DEFAULT then
      capParams.seatControlCapabilities = pSeatCapabilities
    end
  else
    capParams.seatControlCapabilities = nil
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

local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

function commonRC.updateDefaultCapabilities(pDisabledModuleTypes)
  local hmiCapabilitiesFile = commonPreconditions:GetPathToSDL()
    .. commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  local hmiCapTbl = jsonFileToTable(hmiCapabilitiesFile)
  local rcCapTbl = hmiCapTbl.UI.systemCapabilities.remoteControlCapability
  for _, pDisabledModuleType in pairs(pDisabledModuleTypes) do
    local buttonId = commonRC.getButtonIdByName(rcCapTbl.buttonCapabilities,
      commonRC.getButtonNameByModule(pDisabledModuleType))
    table.remove(rcCapTbl.buttonCapabilities, buttonId)
    rcCapTbl[string.lower(pDisabledModuleType) .. "ControlCapabilities"] = nil
  end
  tableToJsonFile(hmiCapTbl, hmiCapabilitiesFile)
end

return commonRC