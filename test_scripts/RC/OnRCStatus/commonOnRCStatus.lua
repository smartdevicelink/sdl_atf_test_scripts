---------------------------------------------------------------------------------------------------
-- OnRCStatus common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local test = require("user_modules/dummy_connecttest")

--[[ Local Variables ]]
local commonOnRCStatus = {}
commonOnRCStatus.modules = {
  "CLIMATE",
  "RADIO",
  "AUDIO",
  "LIGHT",
  "HMI_SETTINGS",
  "SEAT"
}

function commonOnRCStatus.getRCAppConfig()
  local struct = commonRC.getRCAppConfig()
  struct.moduleType = { "RADIO", "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS", "SEAT" }
  return struct
end

function commonOnRCStatus.getMobileSession(pAppId)
  return commonRC.getMobileSession(test, pAppId)
end

function commonOnRCStatus.getHMIconnection()
  return test.hmiConnection
end

function commonOnRCStatus.preconditions()
  commonRC.preconditions()
end

function commonOnRCStatus.start()
  commonRC.start(nil, test)
end

function commonOnRCStatus.AddOnRCStatusToPT(tbl)
  tbl.policy_table.functional_groupings.RemoteControl.rpcs.OnRCStatus = {
    hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
  }
end

local function PTUfunc(tbl)
  commonOnRCStatus.AddOnRCStatusToPT(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
end

function commonOnRCStatus.ModulesArray(pModules)
  local out = {}
  for _, mod in pairs(pModules) do
    table.insert(out, { moduleType = mod })
  end
  return out
end

function commonOnRCStatus.RegisterRCapplication(pModuleStatus, ptu_update_func, pAppId)
  if not pAppId then pAppId = 1 end
  if not pModuleStatus then
    pModuleStatus = { freeModules = commonOnRCStatus.ModulesArray(commonOnRCStatus.modules), allocatedModules = { } }
  end
  if not ptu_update_func then
    ptu_update_func = PTUfunc
  end
  commonRC.rai_ptu_n(pAppId, ptu_update_func, test)
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  mobSession:ExpectNotification("OnRCStatus",pModuleStatus)
  pModuleStatus.appID = commonRC.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", pModuleStatus )
end

function commonOnRCStatus.rai_ptu_n(ptu_update_func, pAppId)
  if not pAppId then pAppId = 1 end
  if not ptu_update_func then
    ptu_update_func = PTUfunc
  end
  commonRC.rai_ptu_n(pAppId, ptu_update_func, test)
end

function commonOnRCStatus.rai_n_rc_app(id)
  commonRC.rai_n(id, test)
end

function commonOnRCStatus.SubscribeToModuleWOOnRCStatus(pModule, pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.subscribeToModule(pModule, pAppId, test)
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  mobSession:ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

function commonOnRCStatus.unsubscribeToModule(pModule, pModuleStatus, pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.unSubscribeToModule(pModule, pAppId, test)
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  mobSession:ExpectNotification("OnRCStatus",pModuleStatus)
  pModuleStatus.appID = commonRC.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", pModuleStatus)
end

function commonOnRCStatus.ActivateApp(pAppId)
  commonRC.activate_app(pAppId, test)
end

function commonOnRCStatus.getHMIAppId(pAppId)
  local appId  = commonRC.getHMIAppId(pAppId)
  return appId
end

function commonOnRCStatus.getSettableModuleControlData(pModuleType)
  local struct = {}
  if "CLIMATE" == pModuleType or
    "RADIO" == pModuleType then
    struct = commonRC.getSettableModuleControlData(pModuleType)
  elseif pModuleType == "SEAT" then
    struct.moduleType = "SEAT"
    struct.seatControlData = {
      id = "DRIVER" ,
      heatingEnabled = false ,
      coolingEnabled = true ,
      heatingLevel = 0 ,
      coolingLevel = 3 ,
      horizontalPosition = 10 ,
      verticalPosition = 10 ,
      frontVerticalPosition = 10 ,
      backVerticalPosition = 10 ,
      backTiltAngle = 10 ,
      headSupportHorizontalPosition = 50 ,
      headSupportVerticalPosition = 50 ,
      massageEnabled = true ,
      massageMode = {{
        massageZone = "LUMBAR",
        massageMode = "LOW"
      }},
      massageCushionFirmness = {{
        cushion = "TOP_LUMBAR",
        firmness = 10
      }},
      memory = {
        id = 1,
        label = "first",
        action = "SAVE"
      }
    }
  elseif "AUDIO" == pModuleType then
    struct.moduleType = "AUDIO"
    struct.audioControlData = {
      source = "CD",
      keepContext = false,
      volume = 50,
      equalizerSettings = {
        channelId = 10,
        channelName = "Channel 1",
        channelSetting = 50 }
    }
  elseif "LIGHT" == pModuleType then
    struct.moduleType = "LIGHT"
    struct.lightControlData = {
      lightState = {
        id = "FRONT_LEFT_HIGH_BEAM",
        status = "ON",
        density = 0.2,
        sRGBColor = "red"
      }
    }
  elseif "HMI_SETTINGS" == pModuleType then
    struct.moduleType = "HMI_SETTINGS"
    struct.hmiSettingsControlData = {
      displayMode = "DAY",
      temperatureUnit = "CELSIUS",
      distanceUnit = "KILOMETERS"
    }
  end
  return struct
end

function commonOnRCStatus.postconditions()
  commonRC.postconditions()
end

function commonOnRCStatus.SetModuleStatus(pFreeMod, pAllocatedMod, pModule)
  local ModulesStatus = { }
  table.insert(pAllocatedMod, pModule)
  for key, value in pairs(pFreeMod) do
    if pModule == value then
      table.remove(pFreeMod, key)
    end
  end
  ModulesStatus.freeModules = commonOnRCStatus.ModulesArray(pFreeMod)
  ModulesStatus.allocatedModules = commonOnRCStatus.ModulesArray(pAllocatedMod)
  return ModulesStatus
end

function commonOnRCStatus.SetModuleStatusByDeallocation(pFreeMod, pAllocatedMod, pModule)
  local ModulesStatus = { }
  table.insert(pFreeMod, pModule)
  for key, value in pairs(pAllocatedMod) do
    if pModule == value then
      table.remove(pAllocatedMod, key)
    end
  end
  ModulesStatus.freeModules = commonOnRCStatus.ModulesArray(pFreeMod)
  ModulesStatus.allocatedModules = commonOnRCStatus.ModulesArray(pAllocatedMod)
  return ModulesStatus
end

function commonOnRCStatus.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.unregisterApp(pAppId, test)
end

function commonOnRCStatus.defineRAMode(pAllowed, pAccessMode)
  commonRC.defineRAMode(pAllowed, pAccessMode, test)
end

function commonOnRCStatus.rpcRejectWithConsent(pModuleType, pAppId, pRPC)
  local info = "The resource is in use and the driver disallows this remote control RPC"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonOnRCStatus.getAppEventName(pRPC),
    commonOnRCStatus.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonOnRCStatus.getHMIEventName(consentRPC),
    commonOnRCStatus.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        commonOnRCStatus.getHMIResponseParams(consentRPC, false))
      EXPECT_HMICALL(commonOnRCStatus.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
end

function commonOnRCStatus.rpcAllowedWithConsent(pModuleType, pAppId, pRPC)
  commonRC.rpcAllowedWithConsent(pModuleType, pAppId, pRPC, test)
end

function commonOnRCStatus.setVehicleData(pModuleType, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
    moduleData = commonOnRCStatus.getSettableModuleControlData(pModuleType)
  })
  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
    appID = commonOnRCStatus.getHMIAppId(),
    moduleData = commonOnRCStatus.getSettableModuleControlData(pModuleType)
  })
  :Do(function(_, data)
    commonOnRCStatus.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
      moduleData = commonOnRCStatus.getSettableModuleControlData(pModuleType)
    })
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
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

function commonOnRCStatus.getAppEventName(pRPC)
  return rcRPCs[pRPC].appEventName
end

function commonOnRCStatus.getHMIEventName(pRPC)
  return rcRPCs[pRPC].hmiEventName
end

function commonOnRCStatus.getAppRequestParams(pRPC, ...)
  return rcRPCs[pRPC].requestParams(...)
end

function commonOnRCStatus.getAppResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function commonOnRCStatus.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function commonOnRCStatus.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

function commonOnRCStatus.rpcAllowed(pModuleType, pAppId, pRPC)
  local mobSession = commonOnRCStatus.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonOnRCStatus.getAppEventName(pRPC),
    commonOnRCStatus.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonOnRCStatus.getHMIEventName(pRPC),
    commonOnRCStatus.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonOnRCStatus.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS",
        commonOnRCStatus.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end


return commonOnRCStatus
