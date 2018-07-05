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
local initialCommon = require('test_scripts/RC/commonRC')
local test = require("user_modules/dummy_connecttest")
--[[ Local Variables ]]
local commonRC = {}

commonRC.timeout = 2000
commonRC.minTimeout = 500
commonRC.DEFAULT = initialCommon.DEFAULT

function initialCommon.getRCAppConfig()
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

function commonRC.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  return test["mobileSession" .. pAppId]
end

function commonRC.getHMIconnection()
  return test.hmiConnection
end

local origGetModuleControlData = initialCommon.getModuleControlData
function initialCommon.getModuleControlData(module_type)
  local out = { }
  if module_type == "SEAT" then
    out.moduleType = module_type
    out.seatControlData = {
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
        id = 1,
        label = "Label value",
        action = "SAVE"
      }
    }
  else
    out = origGetModuleControlData(module_type)
  end
  return out
end

function commonRC.getModuleControlData(module_type)
  return initialCommon.getModuleControlData(module_type)
end

local origGetAnotherModuleControlData = initialCommon.getAnotherModuleControlData
function commonRC.getAnotherModuleControlData(module_type)
  local out = { }
  if module_type == "SEAT" then
    out.moduleType = module_type
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
        id = 2,
        label = "Another label value",
        action = "RESTORE"
      }
    }
  else
    out = origGetAnotherModuleControlData(module_type)
  end
  return out
end

local origGetModuleParams = initialCommon.getModuleParams
function initialCommon.getModuleParams(pModuleData)
  if pModuleData.moduleType == "SEAT" then
    if not pModuleData.seatControlData then
      pModuleData.seatControlData = { }
    end
    return pModuleData.seatControlData
  end
  return origGetModuleParams(pModuleData)
end

function commonRC.getModuleParams(pModuleData)
  return initialCommon.getModuleParams(pModuleData)
end

function commonRC.buildHmiRcCapabilities(pClimateCapabilities, pRadioCapabilities, pSeatCapabilities, pButtonCapabilities)
  local hmiParams = initialCommon.buildHmiRcCapabilities(pClimateCapabilities, pRadioCapabilities, pButtonCapabilities)
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability

  if pSeatCapabilities then
    if pSeatCapabilities ~= commonRC.DEFAULT then
      capParams.seatControlCapabilities = pSeatCapabilities
    end
  else
    capParams.seatControlCapabilities = nil
  end

  return hmiParams
end

function commonRC.getReadOnlyParamsByModule(pModuleType)
  return initialCommon.getReadOnlyParamsByModule(pModuleType)
end

function commonRC.getSettableModuleControlData(pModuleType)
  return initialCommon.getSettableModuleControlData(pModuleType)
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

function commonRC.subscribeToModule(pModuleType, pAppId)
  return initialCommon.subscribeToModule(pModuleType, pAppId, test)
end

function commonRC.unSubscribeToModule(pModuleType, pAppId)
  return initialCommon.unSubscribeToModule(pModuleType, pAppId, test)
end

function commonRC.isSubscribed(pModuleType, pAppId)
  return initialCommon.isSubscribed(pModuleType, pAppId, test)
end

function commonRC.isUnsubscribed(pModuleType, pAppId)
  return initialCommon.isUnsubscribed(pModuleType, pAppId, test)
end

function commonRC.getHMIAppId(pAppId)
  return initialCommon.getHMIAppId(pAppId)
end

function commonRC.rpcDenied(pModuleType, pAppId, pRPC, pResultCode)
  return initialCommon.rpcDenied(pModuleType, pAppId, pRPC, pResultCode, test)
end

function commonRC.rpcAllowed(pModuleType, pAppId, pRPC)
  return initialCommon.rpcAllowed(pModuleType, pAppId, pRPC, test)
end

function commonRC.backupHMICapabilities()
  return initialCommon.backupHMICapabilities()
end

function commonRC.restoreHMICapabilities()
  return initialCommon.restoreHMICapabilities()
end

function commonRC.updateDefaultCapabilities(pDisabledModuleTypes)
  return initialCommon.updateDefaultCapabilities(pDisabledModuleTypes)
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

return commonRC
