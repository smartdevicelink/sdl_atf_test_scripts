---------------------------------------------------------------------------------------------------
-- RC common module for AUDIO, LIGHT, HMI_SETTINGS modules
---------------------------------------------------------------------------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local commonRC = require("test_scripts/RC/commonRC")
local test = require("user_modules/dummy_connecttest")

--[[ Local Variables ]]
local c = {}
c.modules = { "RADIO", "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

function c.preconditions()
  commonRC.preconditions()
end

function c.start()
  commonRC.start(nil, test)
end

function c.AddOnRCStatusToPT(tbl)
  tbl.policy_table.functional_groupings.RemoteControl.rpcs.OnRCStatus = {
    hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
  }
end

function c.getRCAppConfig()
  local struct = commonRC.getRCAppConfig()
  struct.moduleType = c.modules
  return struct
end

local function PTUfunc(tbl)
  c.AddOnRCStatusToPT(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = c.getRCAppConfig()
end

function c.raiPTUn(pPTUfunc, pAppId)
  if not pAppId then pAppId = 1 end
  if not pPTUfunc then
    pPTUfunc = PTUfunc
  end
  commonRC.rai_ptu_n(pAppId, pPTUfunc, test)
end

function c.raiN(pAppId)
  commonRC.rai_n(pAppId, test)
end

function c.getHMIAppId(pAppId)
  local appId = commonRC.getHMIAppId(pAppId)
  return appId
end

function c.getModuleControlData(pModuleType)
  local struct = {}
  if "CLIMATE" == pModuleType then
    struct.moduleType = "CLIMATE"
    struct.climateControlData = {}
    struct.climateControlData.heatedSteeringWheelEnable = true
    struct.climateControlData.heatedWindshieldEnable = true
    struct.climateControlData.heatedRearWindowEnable = true
    struct.climateControlData.heatedMirrorsEnable = true
  elseif "RADIO" == pModuleType then
    struct.moduleType = "RADIO"
    struct.radioControlData = {}
    struct.radioControlData.sisData = {
      stationShortName = "Name1",
      stationIDNumber = {
        countryCode = 100,
        fccFacilityId = 100
      },
      stationLongName = "RadioStationLongName",
      stationLocation = {
        longitudeDegrees = 0.1,
        latitudeDegrees = 0.1,
        altitudeMeters = 0.1
      },
      stationMessage = "station message"
    }
  elseif "AUDIO" == pModuleType then
    struct.moduleType = "AUDIO"
    struct.audioControlData = {
      source = "RADIO_TUNER",
      keepContext = false,
      volume = 50,
      equalizerSettings = {
        {
          channelId = 10,
          channelName = "Channel 1",
          channelSetting = 50
        }
      }
    }
  elseif "LIGHT" == pModuleType then
    struct.moduleType = "LIGHT"
    struct.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.2,
          sRGBColor = {
            red = 50,
            green = 150,
            blue = 200
          }
        }
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

function c.getAnotherModuleControlData(pModuleType)
  local struct = {}
  if "CLIMATE" == pModuleType then
    struct.moduleType = "CLIMATE"
    struct.climateControlData = {}
    struct.climateControlData.heatedSteeringWheelEnable = false
    struct.climateControlData.heatedWindshieldEnable = false
    struct.climateControlData.heatedRearWindowEnable = false
    struct.climateControlData.heatedMirrorsEnable = false
  elseif "RADIO" == pModuleType then
    struct.moduleType = "RADIO"
    struct.RadioControlData = {}
    struct.RadioControlData.sisData = {
      stationShortName = "Name2",
      stationIDNumber = {
        countryCode = 200,
        fccFacilityId = 200
      },
      stationLongName = "RadioStationLongName2",
      stationLocation = {
        longitudeDegrees = 20.1,
        latitudeDegrees = 20.1,
        altitudeMeters = 20.1
      },
      stationMessage = "station message 2"
    }
  elseif "AUDIO" == pModuleType then
    struct.moduleType = "AUDIO"
    struct.audioControlData = {
      source = "USB",
      keepContext = true,
      volume = 20,
      equalizerSettings = {
        channelId = 20,
        channelName = "Channel 2",
        channelSetting = 20 }
    }
  elseif "LIGHT" == pModuleType then
    struct.moduleType = "LIGHT"
    struct.lightControlData = {
      lightState = {
        {
          id = "READING_LIGHTS",
          status = "ON",
          density = 0.5,
          sRGBColor = {
            red = 150,
            green = 200,
            blue = 250
          }
        }
      }
    }
  elseif "HMI_SETTINGS" == pModuleType then
    struct.moduleType = "HMI_SETTINGS"
    struct.hmiSettingsControlData = {
      displayMode = "NIGHT",
      temperatureUnit = "FAHRENHEIT",
      distanceUnit = "MILES"
    }
  end
  return struct
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
        appID = c.getHMIAppId(pAppId),
        moduleType = pModuleType,
        subscribe = pSubscribe
      }
    end,
    hmiResponseParams = function(pModuleType, pSubscribe)
      return {
        moduleData = c.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pSubscribe)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = c.getModuleControlData(pModuleType),
        isSubscribed = pSubscribe
      }
    end
  },
  SetInteriorVehicleData = {
    appEventName = "SetInteriorVehicleData",
    hmiEventName = "RC.SetInteriorVehicleData",
    requestParams = function(pModuleType)
      return {
        moduleData = c.getModuleControlData(pModuleType)
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = c.getHMIAppId(pAppId),
        moduleData = c.getModuleControlData(pModuleType)
      }
    end,
    hmiResponseParams = function(pModuleType)
      return {
        moduleData = c.getModuleControlData(pModuleType)
      }
    end,
    responseParams = function(success, resultCode, pModuleType)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = c.getModuleControlData(pModuleType)
      }
    end
  },
  ButtonPress = {
    appEventName = "ButtonPress",
    hmiEventName = "Buttons.ButtonPress",
    requestParams = function(pModuleType)
      return {
        moduleType = pModuleType,
        buttonName = c.getButtonNameByModule(pModuleType),
        buttonPressMode = "SHORT"
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      return {
        appID = c.getHMIAppId(pAppId),
        moduleType = pModuleType,
        buttonName = c.getButtonNameByModule(pModuleType),
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
        appID = c.getHMIAppId(pAppId),
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
        moduleData = c.getAnotherModuleControlData(pModuleType)
      }
    end,
    responseParams = function(pModuleType)
      return {
        moduleData = c.getAnotherModuleControlData(pModuleType)
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

function c.getAppEventName(pRPC)
  return rcRPCs[pRPC].appEventName
end

function c.getHMIEventName(pRPC)
  return rcRPCs[pRPC].hmiEventName
end

function c.getAppRequestParams(pRPC, ...)
  return rcRPCs[pRPC].requestParams(...)
end

function c.getAppResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function c.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function c.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

function c.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  return test["mobileSession" .. pAppId]
end

function c.getHMIconnection()
  return test.hmiConnection
end

function c.subscribeToModule(pModuleType, pAppId)
  if not pAppId then pAppId = 1 end
  local rpc = "GetInteriorVehicleData"
  local subscribe = true
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(rpc), c.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(c.getHMIEventName(rpc), c.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, c.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function c.unSubscribeToModule(pModuleType, pAppId)
  local rpc = "GetInteriorVehicleData"
  local subscribe = false
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(rpc), c.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(c.getHMIEventName(rpc), c.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, c.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

function c.activateApp(pAppId)
  commonRC.activate_app(pAppId, test)
end

function c.defineRAMode(pAllowed, pAccessMode)
  commonRC.defineRAMode(pAllowed, pAccessMode, test)
end

function c.rpcAllowed(pModuleType, pAppId, pRPC)
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(c.getHMIEventName(pRPC), c.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.rpcAllowedWithConsent(pModuleType, pAppId, pRPC)
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(c.getHMIEventName(consentRPC), c.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", c.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(c.getHMIEventName(pRPC), c.getHMIRequestParams(pRPC, pModuleType, pAppId))
      :Do(function(_, data2)
          test.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", c.getHMIResponseParams(pRPC, pModuleType))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function c.isSubscribed(pModuleType, pAppId)
  local mobSession = c.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"
  test.hmiConnection:SendNotification(c.getHMIEventName(rpc), c.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(c.getAppEventName(rpc), c.getAppResponseParams(rpc, pModuleType))
end

function c.isUnsubscribed(pModuleType, pAppId)
  local mobSession = c.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"
  test.hmiConnection:SendNotification(c.getHMIEventName(rpc), c.getHMIResponseParams(rpc, pModuleType))
  mobSession:ExpectNotification(c.getAppEventName(rpc), {}):Times(0)
end

function c.rpcDenied(pModuleType, pAppId, pRPC, pResultCode)
  local mobSession = c.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(c.getAppEventName(pRPC), c.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(c.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

function c.postconditions()
  commonRC.postconditions()
end

return c
