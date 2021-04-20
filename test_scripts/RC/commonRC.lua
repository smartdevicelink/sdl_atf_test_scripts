---------------------------------------------------------------------------------------------------
-- RC common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ValidateSchema = false
config.checkAllValidations = true
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Required Shared libraries ]]
local test = require("user_modules/dummy_connecttest")
local json = require("modules/json")
local hmi_values = require("user_modules/hmi_values")
local utils = require('user_modules/utils')
local actions = require("user_modules/sequences/actions")
local apiLoader = require("modules/api_loader")
local SDL = require('modules/SDL')

--[[ Common Variables ]]

local commonRC = {}

commonRC.timeout = 2000
commonRC.minTimeout = 500
commonRC.DEFAULT = "Default"
commonRC.buttons = { climate = "FAN_UP", radio = "VOLUME_UP" }
commonRC.getHMIConnection = actions.getHMIConnection
commonRC.getMobileSession = actions.getMobileSession
commonRC.policyTableUpdate = actions.policyTableUpdate
commonRC.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
commonRC.registerApp = actions.registerApp
commonRC.getHMIAppId = actions.getHMIAppId
commonRC.jsonFileToTable = utils.jsonFileToTable
commonRC.tableToJsonFile = utils.tableToJsonFile
commonRC.cloneTable = utils.cloneTable
commonRC.wait = actions.run.wait
commonRC.isTableEqual = utils.isTableEqual
commonRC.getPreloadedPT = actions.sdl.getPreloadedPT
commonRC.getDefaultHMITable = hmi_values.getDefaultHMITable
commonRC.cprint = utils.cprint
commonRC.start = actions.start
commonRC.json = json
commonRC.HMICap = SDL.HMICap
commonRC.setSDLIniParameter = actions.setSDLIniParameter

commonRC.modules = { "RADIO", "CLIMATE" }
commonRC.allModules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
commonRC.newModules = { "AUDIO", "LIGHT", "HMI_SETTINGS" }
commonRC.modulesWithoutSeat = { "RADIO", "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

commonRC.capMap = {
  ["RADIO"] = "radioControlCapabilities",
  ["CLIMATE"] = "climateControlCapabilities",
  ["SEAT"] = "seatControlCapabilities",
  ["AUDIO"] = "audioControlCapabilities",
  ["LIGHT"] = "lightControlCapabilities",
  ["HMI_SETTINGS"] = "hmiSettingsControlCapabilities",
  ["BUTTONS"] = "buttonCapabilities"
}

commonRC.audioSources = {
  "NO_SOURCE_SELECTED",
  "CD",
  "BLUETOOTH_STEREO_BTST",
  "USB",
  "USB2",
  "LINE_IN",
  "IPOD",
  "MOBILE_APP",
  "AM",
  "FM",
  "XM",
  "DAB"
}

commonRC.LightsNameList = { "FRONT_LEFT_HIGH_BEAM", "FRONT_RIGHT_HIGH_BEAM", "FRONT_LEFT_LOW_BEAM",
  "FRONT_RIGHT_LOW_BEAM", "FRONT_LEFT_PARKING_LIGHT", "FRONT_RIGHT_PARKING_LIGHT",
  "FRONT_LEFT_FOG_LIGHT", "FRONT_RIGHT_FOG_LIGHT", "FRONT_LEFT_DAYTIME_RUNNING_LIGHT",
  "FRONT_RIGHT_DAYTIME_RUNNING_LIGHT", "FRONT_LEFT_TURN_LIGHT", "FRONT_RIGHT_TURN_LIGHT",
  "REAR_LEFT_FOG_LIGHT", "REAR_RIGHT_FOG_LIGHT", "REAR_LEFT_TAIL_LIGHT", "REAR_RIGHT_TAIL_LIGHT",
  "REAR_LEFT_BRAKE_LIGHT", "REAR_RIGHT_BRAKE_LIGHT", "REAR_LEFT_TURN_LIGHT", "REAR_RIGHT_TURN_LIGHT",
  "REAR_REGISTRATION_PLATE_LIGHT", "HIGH_BEAMS", "LOW_BEAMS", "FOG_LIGHTS", "RUNNING_LIGHTS",
  "PARKING_LIGHTS", "BRAKE_LIGHTS", "REAR_REVERSING_LIGHTS", "SIDE_MARKER_LIGHTS", "LEFT_TURN_LIGHTS",
  "RIGHT_TURN_LIGHTS", "HAZARD_LIGHTS", "AMBIENT_LIGHTS", "OVERHEAD_LIGHTS", "READING_LIGHTS",
  "TRUNK_LIGHTS", "EXTERIOR_FRONT_LIGHTS", "EXTERIOR_REAR_LIGHTS", "EXTERIOR_LEFT_LIGHTS",
  "EXTERIOR_RIGHT_LIGHTS", "REAR_CARGO_LIGHTS", "REAR_TRUCK_BED_LIGHTS", "REAR_TRAILER_LIGHTS",
  "LEFT_SPOT_LIGHTS", "RIGHT_SPOT_LIGHTS", "LEFT_PUDDLE_LIGHTS", "RIGHT_PUDDLE_LIGHTS",
  "EXTERIOR_ALL_LIGHTS" }
commonRC.readOnlyLightStatus = { "RAMP_UP", "RAMP_DOWN", "UNKNOWN", "INVALID" }

--[[ Common Functions ]]
function commonRC.registerAppWOPTU(pAppId, self)
   return actions.registerAppWOPTU(pAppId)
end

function commonRC.getRCAppConfig(tbl)
  if tbl then
    local out = commonRC.cloneTable(tbl.policy_table.app_policies.default)
    out.moduleType = commonRC.allModules
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = commonRC.allModules,
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

function actions.ptu.getAppData(pAppId)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "RemoteControl" },
    AppHMIType = actions.getConfigAppParams(pAppId).appHMIType
  }
end

local function allowSDL()
  commonRC.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
  actions.run.wait(500) -- stabilization delay
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedTable = SDL.PreloadedPT.get()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = commonRC.getRCAppConfig(preloadedTable)
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  SDL.PreloadedPT.set(preloadedTable)
end

function commonRC.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  actions.preconditions()
  if isPreloadedUpdate == true then
    SDL.PreloadedPT.backup()
    updatePreloadedPT(pCountOfRCApps)
  end
end

function commonRC.postconditions()
  actions.postconditions()
  SDL.PreloadedPT.restore()
end

function commonRC.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = commonRC.getMobileSession(pAppId)
  local hmiAppId = commonRC.getHMIAppId(pAppId)
  commonRC.deleteHMIAppId(pAppId)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonRC.getModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351"
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
      ventilationMode = "BOTH",
      heatedSteeringWheelEnable = true,
      heatedWindshieldEnable = true,
      heatedRearWindowEnable = true,
      heatedMirrorsEnable = true,
      climateEnable = true
    }
  elseif module_type == "RADIO" then
    out.moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed"
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
      availableHdChannels = {0, 1, 2, 3, 4, 5, 6, 7},
      hdChannel = 7,
      signalStrength = 5,
      signalChangeThreshold = 10,
      radioEnable = true,
      state = "ACQUIRING",
      hdRadioEnable = true,
      sisData = {
        stationShortName = "Name1",
        stationIDNumber = {
          countryCode = 100,
          fccFacilityId = 100
        },
        stationLongName = "RadioStationLongName",
        stationLocation = {
          longitudeDegrees = 0.1,
          latitudeDegrees = 0.1,
          altitude = 0.1
        },
        stationMessage = "station message"
      }
    }
  elseif module_type == "SEAT" then
    out.moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73"
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
  elseif module_type == "AUDIO" then
    out.moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b"
    out.audioControlData = {
      source = "AM",
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
  elseif module_type == "LIGHT" then
    out.moduleId = "f31ef579-743d-41be-a75e-80630d16f4e6"
    out.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.2,
          color = {
            red = 50,
            green = 150,
            blue = 200
          }
        }
      }
    }
  elseif module_type == "HMI_SETTINGS" then
    out.moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1"
    out.hmiSettingsControlData = {
      displayMode = "DAY",
      temperatureUnit = "CELSIUS",
      distanceUnit = "KILOMETERS"
    }
  end
  return out
end

function commonRC.getAnotherModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351"
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
      ventilationMode = "UPPER",
      climateEnable = false
    }
  elseif module_type == "RADIO" then
    out.moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed"
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
      state = "ACQUIRING",
      hdRadioEnable = true,
      sisData = {
        stationShortName = "Name2",
        stationIDNumber = {
          countryCode = 200,
          fccFacilityId = 200
        },
        stationLongName = "RadioStationLongName2",
        stationLocation = {
          longitudeDegrees = 20.1,
          latitudeDegrees = 20.1,
          altitude = 20.1
        },
        stationMessage = "station message 2"
      }
    }
  elseif module_type == "SEAT" then
    out.moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73"
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
  elseif module_type == "AUDIO" then
    out.moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b"
    out.audioControlData = {
      source = "USB",
      keepContext = true,
      volume = 20,
      equalizerSettings = {
        {
          channelId = 20,
          channelName = "Channel 2",
          channelSetting = 20
        }
      }
    }
  elseif module_type == "LIGHT" then
    out.moduleId = "f31ef579-743d-41be-a75e-80630d16f4e6"
    out.lightControlData = {
      lightState = {
        {
          id = "READING_LIGHTS",
          status = "ON",
          density = 0.5,
          color = {
            red = 150,
            green = 200,
            blue = 250
          }
        }
      }
    }
  elseif module_type == "HMI_SETTINGS" then
    out.moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1"
    out.hmiSettingsControlData = {
      displayMode = "NIGHT",
      temperatureUnit = "FAHRENHEIT",
      distanceUnit = "MILES"
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
      availableHdChannels = {2, 3, 4},
      signalStrength = 4,
      signalChangeThreshold = 22,
      state = "MULTICAST",
      sisData = {
        stationShortName = "Name2",
        stationIDNumber = {
          countryCode = 200,
          fccFacilityId = 200
        },
        stationLongName = "RadioStationLongName2",
        stationLocation = {
          longitudeDegrees = 20.1,
          latitudeDegrees = 20.1,
          altitude = 20.1
        },
        stationMessage = "station message 2"
      }
    }
  elseif pModuleType == "AUDIO" then
    out.audioControlData = {
      equalizerSettings = { { channelName = "Channel 1" } }
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
  elseif pModuleData.moduleType == "AUDIO" then
    if not pModuleData.audioControlData then
      pModuleData.audioControlData = { }
    end
    return pModuleData.audioControlData
  elseif pModuleData.moduleType == "SEAT" then
    if not pModuleData.seatControlData then
      pModuleData.seatControlData = { }
    end
    return pModuleData.seatControlData
  end
end

function commonRC.getSettableModuleControlData(pModuleType)
  local out = commonRC.getModuleControlData(pModuleType)
  local params_read_only = commonRC.getModuleParams(commonRC.getReadOnlyParamsByModule(pModuleType))
  if params_read_only then
    for p_read_only, p_read_only_value in pairs(params_read_only) do
      if pModuleType == "AUDIO" then
        for sub_read_only_key, sub_read_only_value in pairs(p_read_only_value) do
          for sub_read_only_name in pairs(sub_read_only_value) do
            commonRC.getModuleParams(out)[p_read_only][sub_read_only_key][sub_read_only_name] = nil
          end
        end
      else
        commonRC.getModuleParams(out)[p_read_only] = nil
      end
    end
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
    hmiRequestParams = function(pModuleType, _, pSubscribe)
      return {
        moduleType = pModuleType,
        moduleId = commonRC.actualInteriorDataStateOnHMI[pModuleType].moduleId,
        subscribe = pSubscribe
      }
    end,
    hmiResponseParams = function(pModuleType, pSubscribe)
      local GetInteriorVDModuleData = commonRC.actualInteriorDataStateOnHMI[pModuleType]
      if GetInteriorVDModuleData.audioControlData then
        GetInteriorVDModuleData.audioControlData.keepContext = nil
      end
      return {
        moduleData = GetInteriorVDModuleData,
        isSubscribed = pSubscribe
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pSubscribe)
      local GetInteriorVDModuleData = commonRC.actualInteriorDataStateOnHMI[pModuleType]
      if GetInteriorVDModuleData.audioControlData then
        GetInteriorVDModuleData.audioControlData.keepContext = nil
      end
      return {
        success = success,
        resultCode = resultCode,
        moduleData = GetInteriorVDModuleData,
        isSubscribed = pSubscribe
      }
    end
  },
  SetInteriorVehicleData = {
    appEventName = "SetInteriorVehicleData",
    hmiEventName = "RC.SetInteriorVehicleData",
    requestParams = function(pModuleType)
      local moduleData = commonRC.getSettableModuleControlData(pModuleType)
      moduleData.moduleId = nil
      return {
        moduleData = moduleData
      }
    end,
    hmiRequestParams = function(pModuleType, pAppId)
      local  moduleData = commonRC.getSettableModuleControlData(pModuleType)
      moduleData.moduleId = commonRC.actualInteriorDataStateOnHMI[pModuleType].moduleId
      return {
        moduleData = moduleData,
        appID = commonRC.getHMIAppId(pAppId),
      }
    end,
    hmiResponseParams = function(pModuleType)
      local  moduleData = commonRC.getSettableModuleControlData(pModuleType)
      moduleData.moduleId = commonRC.actualInteriorDataStateOnHMI[pModuleType].moduleId
      return {
        moduleData = moduleData
      }
    end,
    responseParams = function(success, resultCode, pModuleType)
      local  moduleData = commonRC.getSettableModuleControlData(pModuleType)
      moduleData.moduleId = commonRC.actualInteriorDataStateOnHMI[pModuleType].moduleId
      return {
        success = success,
        resultCode = resultCode,
        moduleData = moduleData
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
        allowed = {pAllowed}
      }
    end,
  },
  OnInteriorVehicleData = {
    appEventName = "OnInteriorVehicleData",
    hmiEventName = "RC.OnInteriorVehicleData",
    hmiResponseParams = function(pModuleType)
      local OnInteriorVDModuleData = commonRC.getAnotherModuleControlData(pModuleType)
      if OnInteriorVDModuleData.audioControlData then
        OnInteriorVDModuleData.audioControlData.keepContext = nil
      end
      return {
        moduleData = OnInteriorVDModuleData
      }
    end,
    responseParams = function(pModuleType)
      local OnInteriorVDModuleData = commonRC.getAnotherModuleControlData(pModuleType)
      if OnInteriorVDModuleData.audioControlData then
        OnInteriorVDModuleData.audioControlData.keepContext = nil
      end
      return {
        moduleData = OnInteriorVDModuleData
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
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
      commonRC.setActualInteriorVD(pModuleType, commonRC.getHMIResponseParams(rpc, pModuleType, subscribe).moduleData)
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
  :ValidIf(function(_,data)
      if "AUDIO" == pModuleType and
      nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
      end
      return true
    end)
end

function commonRC.unSubscribeToModule(pModuleType, pAppId)
  local rpc = "GetInteriorVehicleData"
  local subscribe = false
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, subscribe))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(rpc, pModuleType, subscribe))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
  :ValidIf(function(_,data)
      if "AUDIO" == pModuleType and
      nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
      end
      return true
    end)
end

function commonRC.isSubscribed(pModuleType, pAppId)
  local mobSession = commonRC.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"

  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  commonRC.setActualInteriorVD(pModuleType, commonRC.getHMIResponseParams(rpc, pModuleType).moduleData)
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), commonRC.getAppResponseParams(rpc, pModuleType))
  :ValidIf(function(_,data)
      if "AUDIO" == pModuleType and
      nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile notification OnInteriorVehicleData contains unexpected keepContext parameter"
      end
      return true
    end)
end

function commonRC.isUnsubscribed(pModuleType, pAppId)
  local mobSession = commonRC.getMobileSession(pAppId)
  local rpc = "OnInteriorVehicleData"
  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pModuleType))
  commonRC.setActualInteriorVD(pModuleType, commonRC.getHMIResponseParams(rpc, pModuleType).moduleData)
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), {}):Times(0)
  utils.wait(commonRC.timeout)
end

function commonRC.defineRAMode(pAllowed, pAccessMode)
  local rpc = "OnRemoteControlSettings"
  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc), commonRC.getHMIResponseParams(rpc, pAllowed, pAccessMode))
  utils.wait(commonRC.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

function commonRC.rpcDenied(pModuleType, pAppId, pRPC, pResultCode)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
  utils.wait(commonRC.timeout)
end

function commonRC.rpcDeniedWithCustomParams(pParams, pAppId, pRPC, pResultCode)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), pParams)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
  utils.wait(commonRC.timeout)
end

function commonRC.rpcAllowed(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
    end)
  mobSession:ExpectResponse(cid, commonRC.getAppResponseParams(pRPC, true, "SUCCESS", pModuleType))
end

function commonRC.rpcAllowedWithConsent(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, true))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC), commonRC.getHMIRequestParams(pRPC, pModuleType, pAppId))
      :Do(function(_, data2)
          commonRC.getHMIConnection():SendResponse(data2.id, data2.method, "SUCCESS", commonRC.getHMIResponseParams(pRPC, pModuleType))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.rpcRejectWithConsent(pModuleType, pAppId, pRPC)
  local moduleId = commonRC.actualInteriorDataStateOnHMI[pModuleType].moduleId
  local info = "The resource [" .. pModuleType .. ":" .. moduleId ..
    "] is in use and the driver disallows this remote control RPC"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, false))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
  utils.wait(commonRC.timeout)
end

function commonRC.rpcRejectWithoutConsent(pModuleType, pAppId, pRPC)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  utils.wait(commonRC.timeout)
end

function commonRC.rpcButtonPress(pParams, pAppId)
  local cid = commonRC.getMobileSession(pAppId):SendRPC("ButtonPress",  pParams)
  pParams.appID = commonRC.getHMIAppId(pAppId)
  EXPECT_HMICALL("Buttons.ButtonPress", pParams)
  :Do(function(_, data)
    commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  commonRC.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonRC.buildButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return hmi_values.createButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
end

commonRC.getDefaultHMITable = hmi_values.getDefaultHMITable

function commonRC.buildHmiRcCapabilities(pCapabilities)
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.RC.IsReady.params.available = true
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability
  for k, v in pairs(commonRC.capMap) do
    if pCapabilities[k] then
      if pCapabilities[k] ~= commonRC.DEFAULT then
        capParams[v] = pCapabilities[k]
      end
    else
      capParams[v] = nil
    end
  end
  return hmiParams
end

function commonRC.backupHMICapabilities()
  SDL.HMICap.backup()
end

function commonRC.restoreHMICapabilities()
  SDL.HMICap.restore()
end

function commonRC.getButtonIdByName(pArray, pButtonName)
  for id, buttonData in pairs(pArray) do
    if buttonData.name == pButtonName then
      return id
    end
  end
end

local function audibleState(pAppId)
  if not pAppId then pAppId = 1 end
  local appParams = config["application" .. pAppId].registerAppInterfaceParams
  local audibleStateValue
  if appParams.isMediaApplication == true then
    audibleStateValue = "AUDIBLE"
  else
    audibleStateValue = "NOT_AUDIBLE"
  end
  return audibleStateValue
end

function commonRC.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = commonRC.getHMIAppId(pAppId)
  local mobSession = commonRC.getMobileSession(pAppId)
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = audibleState(pAppId),
      systemContext = "MAIN" })
  actions.run.wait(commonRC.minTimeout)
end

function commonRC.getModuleId(pModuleType)
  local rcCapabilities = hmi_values.getDefaultHMITable().RC.GetCapabilities.params.remoteControlCapability
  if pModuleType == "LIGHT" or pModuleType == "HMI_SETTINGS" then
    return rcCapabilities[commonRC.capMap[pModuleType]].moduleInfo.moduleId
  else
    return rcCapabilities[commonRC.capMap[pModuleType]][1].moduleInfo.moduleId
  end
end

local function updateModuleId(pRcCapTbl)
  for _, moduleType in pairs(commonRC.allModules) do
    local defaultModuleId
    if moduleType == "LIGHT" or moduleType == "HMI_SETTINGS" then
      defaultModuleId = pRcCapTbl[commonRC.capMap[moduleType]].moduleInfo.moduleId
    else
      defaultModuleId = pRcCapTbl[commonRC.capMap[moduleType]][1].moduleInfo.moduleId
    end
    commonRC.actualInteriorDataStateOnHMI[moduleType].moduleId = defaultModuleId
  end
end

function commonRC.updateDefaultCapabilities(pDisabledModuleTypes, pIsHmiCapCorrect)
  local hmiCapTbl = SDL.HMICap.get()
  local rcCapTbl = hmiCapTbl.RC.remoteControlCapability
  if not pIsHmiCapCorrect then
    updateModuleId(rcCapTbl)
  end
  for _, pDisabledModuleType in pairs(pDisabledModuleTypes) do
    local buttonId = commonRC.getButtonIdByName(rcCapTbl.buttonCapabilities,
      commonRC.getButtonNameByModule(pDisabledModuleType))
    table.remove(rcCapTbl.buttonCapabilities, buttonId)
    rcCapTbl[string.lower(pDisabledModuleType) .. "ControlCapabilities"] = nil
  end
  SDL.HMICap.set(hmiCapTbl)
end

commonRC.getHMIAppIds =  actions.getHMIAppIds
commonRC.deleteHMIAppId = actions.deleteHMIAppId

commonRC.actualInteriorDataStateOnHMI = {
  CLIMATE = commonRC.cloneTable(commonRC.getModuleControlData("CLIMATE")),
  RADIO = commonRC.cloneTable(commonRC.getModuleControlData("RADIO")),
  SEAT = commonRC.cloneTable(commonRC.getModuleControlData("SEAT")),
  AUDIO = commonRC.cloneTable(commonRC.getModuleControlData("AUDIO")),
  LIGHT = commonRC.cloneTable(commonRC.getModuleControlData("LIGHT")),
  HMI_SETTINGS = commonRC.cloneTable(commonRC.getModuleControlData("HMI_SETTINGS"))
}

updateModuleId(commonRC.getDefaultHMITable().RC.GetCapabilities.params.remoteControlCapability)

function commonRC.setActualInteriorVD(pModuleType, pParams)
  local moduleParams
  if pModuleType == "CLIMATE" then
    moduleParams = "climateControlData"
  elseif pModuleType == "RADIO" then
    moduleParams = "radioControlData"
  elseif pModuleType == "SEAT" then
    moduleParams = "seatControlData"
  elseif pModuleType == "AUDIO" then
    moduleParams = "audioControlData"
  elseif pModuleType == "LIGHT" then
    moduleParams = "lightControlData"
  elseif pModuleType == "HMI_SETTINGS" then
    moduleParams = "hmiSettingsControlData"
  end
  for key, value in pairs(pParams[moduleParams]) do
    if type(value) ~= "table" then
      if value ~= commonRC.actualInteriorDataStateOnHMI[pModuleType][moduleParams][key] then
        commonRC.actualInteriorDataStateOnHMI[pModuleType][moduleParams][key] = value
      end
    else
      if false == utils.isTableEqual(value, commonRC.actualInteriorDataStateOnHMI[pModuleType][moduleParams][key]) then
        commonRC.actualInteriorDataStateOnHMI[pModuleType][moduleParams][key] = value
      end
    end
  end
end

function commonRC.getModuleControlDataForResponse(pModuleType)
  local moduleData = commonRC.actualInteriorDataStateOnHMI[pModuleType]
  if moduleData.audioControlData then
    moduleData.audioControlData.keepContext = nil
  end
  return moduleData
end

function commonRC.rpcUnsuccessResultCode(pAppId, pRPC, pRequestParams, pResult)
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), pRequestParams)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC))
  :Times(0)
  mobSession:ExpectResponse(cid, pResult)
end

local function setSyncMsgVersion()
  local mobile = apiLoader.init("data/MOBILE_API.xml")
  local schema = mobile.interface[next(mobile.interface)]
  local ver = schema.version
  for appId = 1, 3 do
    local syncMsgVersion = actions.getConfigAppParams(appId).syncMsgVersion
    syncMsgVersion.majorVersion = tonumber(ver.majorVersion)
    syncMsgVersion.minorVersion = tonumber(ver.minorVersion)
    syncMsgVersion.patchVersion = tonumber(ver.patchVersion)
  end
end

setSyncMsgVersion()

return commonRC
