---------------------------------------------------------------------------------------------------
-- Common RC related actions module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")
local utils = require('user_modules/utils')

-- [[ Module ]]
local m = {
	predefined = {},
  data = {},
	rpc = {},
  state = {},
  rc = {}
}

--[[ Constants ]]
m.timeout = 2000
m.minTimeout = 500
m.DEFAULT = "Default"

--[[ data submodule ]]
local rcModuleTypes = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }

local readOnlyParameters = {
  RADIO = {"rdsData", "availableHDs", "signalStrength", "signalChangeThreshold", "state", "sisData"},
  CLIMATE = {"currentTemperature"},
  SEAT = {},
  AUDIO = { { equalizerSettings = { [1] = { "channelName" } } } },
  LIGHT = {},
  HMI_SETTINGS = {}
}

local capabilitiesMap = {
  RADIO = "radioControlCapabilities",
  CLIMATE = "climateControlCapabilities",
  SEAT = "seatControlCapabilities",
  AUDIO = "audioControlCapabilities",
  LIGHT = "lightControlCapabilities",
  HMI_SETTINGS = "hmiSettingsControlCapabilities",
  BUTTONS = "buttonCapabilities"
}

local controlDataMap = {
  RADIO = "radioControlData",
  CLIMATE = "climateControlData",
  SEAT = "seatControlData",
  AUDIO = "audioControlData",
  LIGHT = "lightControlData",
  HMI_SETTINGS = "hmiSettingsControlData"
}

local controlDataToCapabilitiesMap = {
  RADIO = {
    band = "radioBandAvailable",
    frequencyInteger = "radioFrequencyAvailable",
    frequencyFraction = "radioFrequencyAvailable",
    rdsData = "rdsDataAvailable",
    availableHDs = "availableHDsAvailable",
    hdChannel = "hdChannelAvailable",
    hdRadioEnable = "hdRadioEnableAvailable",
    signalStrength = "signalStrengthAvailable",
    signalChangeThreshold = "signalChangeThresholdAvailable",
    radioEnable = "radioEnableAvailable",
    state = "stateAvailable",
    sisData = "sisDataAvailable",
    -- ? = "siriusxmRadioAvailable" -- no mapping
  },
  CLIMATE = {
    fanSpeed = "fanSpeedAvailable",
    currentTemperature = "currentTemperatureAvailable",
    desiredTemperature = "desiredTemperatureAvailable",
    acEnable = "acEnableAvailable",
    circulateAirEnable = "circulateAirEnableAvailable",
    autoModeEnable = "autoModeEnableAvailable",
    defrostZone = "defrostZoneAvailable",
    dualModeEnable = "dualModeEnableAvailable",
    acMaxEnable = "acMaxEnableAvailable",
    ventilationMode = "ventilationModeAvailable",
    heatedSteeringWheelEnable = "heatedSteeringWheelAvailable",
    heatedWindshieldEnable = "heatedWindshieldAvailable",
    heatedMirrorsEnable = "heatedMirrorsAvailable",
    heatedRearWindowEnable = "heatedRearWindowAvailable",
  },
  SEAT = {
    heatingEnabled = "heatingEnabledAvailable",
    coolingEnabled = "coolingEnabledAvailable",
    heatingLevele = "heatingLevelAvailable",
    coolingLevel = "coolingLevelAvailable",
    horizontalPosition = "horizontalPositionAvailable",
    verticalPosition = "verticalPositionAvailable",
    frontVerticalPosition = "frontVerticalPositionAvailable",
    backVerticalPosition = "backVerticalPositionAvailable",
    backTiltAngle = "backTiltAngleAvailable",
    headSupportHorizontalPosition = "headSupportHorizontalPositionAvailable",
    headSupportVerticalPosition = "headSupportVerticalPositionAvailable",
    massageEnabled = "massageEnabledAvailable",
    massageMode = "massageModeAvailable",
    massageCushionFirmness = "massageCushionFirmnessAvailable",
    memory = "memoryAvailable"
  },
  AUDIO = {
    source = "sourceAvailable",
    keepContext = "keepContextAvailable",
    volume = "volumeAvailable",
    equalizerSettings = "equalizerAvailable"
  },
  LIGHT = {
    id = "name",
    status = "statusAvailable",
    density = "densityAvailable",
    color = "rgbColorSpaceAvailable"

  },
  HMI_SETTINGS = {
    distanceUnit = "distanceUnitAvailable",
    temperatureUnit = "temperatureUnitAvailable",
    displayMode = "displayModeUnitAvailable"
  }
}

--[[ moduleDataBuilder private table ]]
local moduleDataBuilder = {}

function moduleDataBuilder.checkModuleData(pModuleType, pModuleId, pModuleData)
  if pModuleData.moduleType ~= pModuleType or pModuleData.moduleId ~= pModuleId then
    utils.cprint(35, "Warning: Module data of Module: [".. tostring(pModuleType) .. ":" .. tostring(pModuleId)
      .. "] has moduleType: " .. tostring(pModuleData.moduleType)
      .. " and moduleId: " .. tostring(pModuleData.moduleId))
    return false
  end
  return true
end

function moduleDataBuilder.precheckModuleData(pModuleType, pModuleParams)
  local controlDataParamName = controlDataMap[pModuleType]
  if not controlDataParamName then
    utils.cprint(31, "Module data was not built. ModuleType " .. tostring(pModuleType) .. " is incorrect.")
    return false
  end

  if type(pModuleParams) ~= "table" then
    utils.cprint(31, "Module data was not built. ModuleParams " .. tostring(pModuleParams) .. " is not a table.")
    return false
  end
  return true
end

function moduleDataBuilder.addParameter(pDestTbl, pSourceTbl, pParam)
  if type(pParam) == "table" then
    if pSourceTbl[pParam] == nil then
      for k, v in pairs(pParam) do
        if type(v) == "table" then
          if not pDestTbl[k] then
            pDestTbl[k] = {}
          end
          moduleDataBuilder.addParameter(pDestTbl[k], pSourceTbl[k], v)
        else
          pDestTbl[v] = pSourceTbl[v]
        end
      end
    else
      pDestTbl[pParam] = pSourceTbl[pParam]
    end
  else
    pDestTbl[pParam] = pSourceTbl[pParam]
  end
end

function moduleDataBuilder.removeParameter(pTbl, _, pParam)
  if type(pParam) == "table" then
    if pTbl[pParam] == nil then
      for k, v in pairs(pParam) do
        if type(v) == "table" then
          moduleDataBuilder.removeParameter(pTbl[k], nil, v)
        else
          pTbl[v] = nil
        end
      end
    else
      pTbl[pParam] = nil
    end
  else
    pTbl[pParam] = nil
  end
end

function moduleDataBuilder.filterModuleData(pModuleData, pFilterFunc)
  if not pModuleData then return end
  local moduleType = pModuleData.moduleType
  local controlDataParamName = controlDataMap[moduleType]
  local sourceModuleParams = pModuleData[controlDataParamName]
  if pFilterFunc == moduleDataBuilder.addParameter then
    pModuleData[controlDataParamName] = {}
  end
  for _, readOnlyParam in ipairs(readOnlyParameters[moduleType]) do
    pFilterFunc(pModuleData[controlDataParamName], sourceModuleParams, readOnlyParam)
  end
end
--[[ --- ]]

function m.data.getRcModuleTypes()
	return utils.cloneTable(rcModuleTypes)
end

function m.data.buildModuleData(pModuleType, pModuleId, pModuleParams)
  if not moduleDataBuilder.precheckModuleData(pModuleType, pModuleParams) then
    return nil
  end

  return {
    moduleType = pModuleType,
    moduleId = pModuleId,
    [controlDataMap[pModuleType]] = utils.cloneTable(pModuleParams)
  }
end

function m.data.buildReadOnlyModuleData(pModuleType, pModuleId, pModuleParams)
  local out = m.data.buildModuleData(pModuleType, pModuleId, pModuleParams)
  moduleDataBuilder.filterModuleData(out, moduleDataBuilder.addParameter)
  return out
end

function m.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  local out = m.data.buildModuleData(pModuleType, pModuleId, pModuleParams)
  moduleDataBuilder.filterModuleData(out, moduleDataBuilder.removeParameter)
  return out
end

--[[ predefined submodule ]]
local predefinedInteriorVehicleData = {
	[1] = {
		RADIO = {
			moduleType = "RADIO",
      moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed",
      radioControlData = {
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
		},
		CLIMATE = {
			moduleType = "CLIMATE",
      moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351",
      climateControlData = {
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
        heatedMirrorsEnable = true
      }
		},
		SEAT = {
			moduleType = "SEAT",
      moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
      seatControlData = {
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
		},
		AUDIO = {
			moduleType = "AUDIO",
      moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      audioControlData = {
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
		},
		LIGHT = {
			moduleType = "LIGHT",
      moduleId = "f31ef579-743d-41be-a75e-80630d16f4e6",
      lightControlData = {
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
		},
		HMI_SETTINGS = {
			moduleType = "HMI_SETTINGS",
      moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1",
      hmiSettingsControlData = {
        displayMode = "DAY",
        temperatureUnit = "CELSIUS",
        distanceUnit = "KILOMETERS"
      }
		}
	},
	[2] = {
		RADIO = {
			moduleType = "RADIO",
      moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed",
      radioControlData = {
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
		},
		CLIMATE = {
			moduleType = "CLIMATE",
      moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351",
      climateControlData = {
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
		},
		SEAT = {
			moduleType = "SEAT",
      moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
      seatControlData ={
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
		},
		AUDIO = {
			moduleType = "AUDIO",
      moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      audioControlData = {
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
		},
		LIGHT = {
			moduleType = "LIGHT",
      moduleId = "f31ef579-743d-41be-a75e-80630d16f4e6",
      lightControlData = {
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
		},
		HMI_SETTINGS = {
			moduleType = "HMI_SETTINGS",
      moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1",
      hmiSettingsControlData = {
        displayMode = "NIGHT",
        temperatureUnit = "FAHRENHEIT",
        distanceUnit = "MILES"
      }
		}
	}
}

function m.predefined.getModuleControlData(pModuleType, pIdx)
  if not pIdx then pIdx = 1 end
  local moduleData = predefinedInteriorVehicleData[pIdx][pModuleType]
  if not moduleDataBuilder.precheckModuleData(pModuleType, moduleData[controlDataMap[pModuleType]]) then
    return nil
  end
  return utils.cloneTable(moduleData)
end

function m.predefined.getReadOnlyModuleControlData(pModuleType, pIdx)
  local out = m.predefined.getModuleControlData(pModuleType, pIdx)
  moduleDataBuilder.filterModuleData(out, moduleDataBuilder.addParameter)
  return out
end

function m.predefined.getSettableModuleControlData(pModuleType, pIdx)
  local out = m.predefined.getModuleControlData(pModuleType, pIdx)
  moduleDataBuilder.filterModuleData(out, moduleDataBuilder.removeParameter)
  return out
end

local predefinedButtonNames = {
  CLIMATE = "FAN_UP",
  RADIO = "VOLUME_UP"
}

function m.predefined.getButtonName(pModuleType)
  return predefinedButtonNames[pModuleType]
end

function m.predefined.getRcCapabilities()
  local hmiCapabilities = hmi_values.getDefaultHMITable()
  local hmiRcCapabilities = hmiCapabilities.RC.GetCapabilities.params.remoteControlCapability
  local rcCapabilities = {}
  for moduleType, capabilitiesParamName in pairs(capabilitiesMap) do
    rcCapabilities[moduleType] = hmiRcCapabilities[capabilitiesParamName]
  end
  return rcCapabilities
end


--[[ state submodule ]]
local function applyCapabilitiesToModuleData(pModuleData, pModuleCapabilities)
  local out = {}
  local moduleType = pModuleData.moduleType
  out.moduleType = moduleType
  out.moduleId = pModuleData.moduleId
  local moduleControlDataName = controlDataMap[moduleType]
  out[moduleControlDataName] = {}
  if moduleType == "LIGHT" then
    local baseLightData = m.predefined.getModuleControlData(moduleType, 1)
    local baseLightInfo = baseLightData[controlDataMap[moduleType]].lightState[1]
    local newLightState = {}
    for _, lightCapability in pairs(pModuleCapabilities.supportedLights) do
      local newLightInfo = {}
      for paramName, paramValue in pairs(baseLightInfo) do
        local capabilityParamName = controlDataToCapabilitiesMap[moduleType][paramName]
        if lightCapability[capabilityParamName] and paramName ~= "id" then
          newLightInfo[paramName] = paramValue
        end
      end
      newLightInfo.id = lightCapability.name
      table.insert(newLightState, newLightInfo)
    end
    out[moduleControlDataName].lightState = newLightState
  else
    for paramName, paramValue in pairs(pModuleData[moduleControlDataName]) do
      local capabilityParamName = controlDataToCapabilitiesMap[moduleType][paramName]
      if pModuleCapabilities[capabilityParamName] then
        out[moduleControlDataName][paramName] = paramValue
      end
    end
  end
  return out
end

local function initDefaultActualModuleStateOnHMI()
  local state = {}
  for _, moduleType in pairs(rcModuleTypes) do
    state[moduleType] = {}
    local moduleControlData = m.predefined.getModuleControlData(moduleType, 1)
    local moduleId = moduleControlData.moduleId
    state[moduleType][moduleId] = {}
    state[moduleType][moduleId].data = moduleControlData
    state[moduleType][moduleId].allocation = -1 -- free
  end
  return state
end

local actualModuleStateOnHMI = initDefaultActualModuleStateOnHMI()

function m.state.getActualModuleStateOnHMI()
  return utils.cloneTable(actualModuleStateOnHMI)
end

function m.state.initActualModuleStateOnHMI(pActualModuleState)
  actualModuleStateOnHMI = utils.cloneTable(pActualModuleState)
  for moduleType, moduleIdArray in pairs(actualModuleStateOnHMI) do
    for moduleId in pairs(moduleIdArray) do
        m.state.resetModuleAllocation(moduleType, moduleId)
    end
  end
end

function m.state.buildDefaultActualModuleState(pRcCapabilities)
  local defaultRcCapabilities
  local state = {}
  for moduleType, moduleCapabilities in pairs(pRcCapabilities) do
    if utils.isTableContains(rcModuleTypes, moduleType) then
      if moduleCapabilities == m.DEFAULT then
        if not defaultRcCapabilities then
          local hmiCapabilities = hmi_values.getDefaultHMITable()
          defaultRcCapabilities = hmiCapabilities.RC.GetCapabilities.params.remoteControlCapability
        end
        moduleCapabilities = defaultRcCapabilities[capabilitiesMap[moduleType]]
      end
      state[moduleType] = {}
      if not moduleCapabilities[1] then
        moduleCapabilities = { moduleCapabilities }
      end
      for _, capabilities in pairs(moduleCapabilities) do
        local moduleId = capabilities.moduleInfo.moduleId
        state[moduleType][moduleId] = {}
        local moduleState = state[moduleType][moduleId]
        moduleState.data = m.predefined.getModuleControlData(moduleType, 1)
        moduleState.data.moduleId = moduleId
        moduleState.data = applyCapabilitiesToModuleData(moduleState.data, capabilities)
      end
    end
  end
  return state
end

function m.state.getActualModuleIVData(pModuleType, pModuleId)
  local moduleData = actualModuleStateOnHMI[pModuleType][pModuleId].data
  if moduleData and moduleData.audioControlData then
    moduleData.audioControlData.keepContext = nil
  end
  return moduleData
end

function m.state.updateActualModuleIVData(pModuleType, pModuleId, pModuleData)
  local function updateTable(pDestTbl, pSourceTbl)
    for k, v in pairs(pSourceTbl) do
      if type(v) == "table" then
        if type(pDestTbl[k]) == "table" then
          updateTable(pDestTbl[k], v)
        else
          pDestTbl[k] = v
        end
      else
        pDestTbl[k] = v
      end
    end
  end

  updateTable(actualModuleStateOnHMI[pModuleType][pModuleId].data, pModuleData)
end

function m.state.getModuleAllocation(pModuleType, pModuleId)
  return actualModuleStateOnHMI[pModuleType][pModuleId].allocation
end

function m.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  actualModuleStateOnHMI[pModuleType][pModuleId].allocation = pAppId
end

function m.state.resetModuleAllocation(pModuleType, pModuleId)
  local FREE = -1
  m.state.setModuleAllocation(pModuleType, pModuleId, FREE)
end

function m.state.resetAllModulesAllocation()
  for moduleType, moduleIdArray in pairs(actualModuleStateOnHMI) do
    for moduleId, _ in pairs(moduleIdArray) do
      m.state.resetModuleAllocation(moduleType, moduleId)
    end
  end
end

function m.state.resetModulesAllocationByApp(pAppId)
  for moduleType, moduleIdArray in pairs(actualModuleStateOnHMI) do
    for moduleId, moduleState in pairs(moduleIdArray) do
      if moduleState.allocation == pAppId then
        m.state.resetModuleAllocation(moduleType, moduleId)
      end
    end
  end
end

function m.state.getModulesAllocationByApp(pAppId)
  local out = {
    freeModules = {},
    allocatedModules = {}
  }

  for moduleType, moduleIdArray in pairs(actualModuleStateOnHMI) do
    for moduleId, moduleState in pairs(moduleIdArray) do
      if moduleState.allocation == pAppId then
        table.insert(out.allocatedModules, {moduleType = moduleType, moduleId = moduleId})
      elseif moduleState.allocation == -1 then
        table.insert(out.freeModules, {moduleType = moduleType, moduleId = moduleId})
      end
    end
  end

  return out
end

--[[ rpc submodule ]]
local rcRPCs = {
  GetInteriorVehicleData = {
    appEventName = "GetInteriorVehicleData",
    hmiEventName = "RC.GetInteriorVehicleData",
    requestParams = function(pModuleType, pModuleId, pSubscribe)
      return {
        moduleType = pModuleType,
        moduleId = pModuleId,
        subscribe = pSubscribe
      }
    end,
    hmiRequestParams = function(pModuleType, pModuleId, _, pSubscribe)
      return {
        moduleType = pModuleType,
        moduleId = pModuleId,
        subscribe = pSubscribe
      }
    end,
    hmiResponseParams = function(pModuleType, pModuleId, pSubscribe)
      return {
        moduleData = m.state.getActualModuleIVData(pModuleType, pModuleId),
        isSubscribed = pSubscribe
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pModuleId, pSubscribe)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = m.state.getActualModuleIVData(pModuleType, pModuleId),
        isSubscribed = pSubscribe
      }
    end
  },
  SetInteriorVehicleData = {
    appEventName = "SetInteriorVehicleData",
    hmiEventName = "RC.SetInteriorVehicleData",
    requestParams = function(pModuleType, pModuleId, pModuleData)
      if pModuleData then
        moduleDataBuilder.checkModuleData(pModuleType, pModuleId, pModuleData)
      else
        pModuleData = m.predefined.getSettableModuleControlData(pModuleType, 1)
        pModuleData.moduleId = pModuleId
      end
      return {
        moduleData = pModuleData
      }
    end,
    hmiRequestParams = function(pModuleType, pModuleId, pAppId, pModuleData)
      if pModuleData then
        moduleDataBuilder.checkModuleData(pModuleType, pModuleId, pModuleData)
      else
        pModuleData = m.predefined.getSettableModuleControlData(pModuleType, 1)
        pModuleData.moduleId = pModuleId
      end
      return {
        appID = actions.app.getHMIId(pAppId),
        moduleData = pModuleData
      }
    end,
    hmiResponseParams = function(pModuleType, pModuleId, pModuleData)
      if pModuleData then
        moduleDataBuilder.checkModuleData(pModuleType, pModuleId, pModuleData)
      else
        pModuleData = m.predefined.getSettableModuleControlData(pModuleType, 1)
        pModuleData.moduleId = pModuleId
      end
      return {
        moduleData = pModuleData
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pModuleId, pModuleData)
      if pModuleData then
        moduleDataBuilder.checkModuleData(pModuleType, pModuleId, pModuleData)
      else
        pModuleData = m.predefined.getSettableModuleControlData(pModuleType, 1)
        pModuleData.moduleId = pModuleId
      end
      return {
        success = success,
        resultCode = resultCode,
        moduleData = pModuleData
      }
    end
  },
  ButtonPress = {
    appEventName = "ButtonPress",
    hmiEventName = "Buttons.ButtonPress",
    requestParams = function(pModuleType, pModuleId, pModuleData)
      if pModuleData then
        return pModuleData
      else
      return {
        moduleType = pModuleType,
        moduleId = pModuleId,
        buttonName = m.predefined.getButtonName(pModuleType),
        buttonPressMode = "SHORT"
      }
      end
    end,
    hmiRequestParams = function(pModuleType, pModuleId, pAppId)
      return {
        appID = actions.app.getHMIId(pAppId),
        moduleType = pModuleType,
        moduleId = pModuleId,
        buttonName = m.predefined.getButtonName(pModuleType),
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
    appEventName = "GetInteriorVehicleDataConsent",
    hmiEventName = "RC.GetInteriorVehicleDataConsent",
    requestParams = function(pModuleType, pModuleId, pModuleIdArray)
      return {
        moduleType = pModuleType,
        moduleIds = pModuleIdArray
      }
    end,
    hmiRequestParams = function(pModuleType, pModuleId, pAppId, pModuleIdArray)
      return {
        appID = actions.app.getHMIId(pAppId),
        moduleType = pModuleType,
        moduleIds = pModuleIdArray
      }
    end,
    hmiResponseParams = function(pModuleType, pModuleId, pAllowedArray)
      return {
        allowed = pAllowedArray
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pModuleId, pAllowedArray)
      return {
        success = success,
        resultCode = resultCode,
        allowed = pAllowedArray
      }
    end
  },
  ReleaseInteriorVehicleDataModule = {
    appEventName = "ReleaseInteriorVehicleDataModule",
    hmiEventName = nil,
    requestParams = function(pModuleType, pModuleId)
      return {
        moduleType = pModuleType,
        moduleId = pModuleId
      }
    end,
    hmiRequestParams = function()
      return nil
    end,
    hmiResponseParams = function()
      return nil
    end,
    responseParams = function(success, resultCode, pModuleType, pModuleId)
      return {
        success = success,
        resultCode = resultCode
      }
    end
  },
  OnInteriorVehicleData = {
    appEventName = "OnInteriorVehicleData",
    hmiEventName = "RC.OnInteriorVehicleData",
    hmiResponseParams = function(pModuleType, pModuleId)
      return {
        moduleData = m.state.getActualModuleIVData(pModuleType, pModuleId)
      }
    end,
    responseParams = function(pModuleType, pModuleId)
      return {
        moduleData = m.state.getActualModuleIVData(pModuleType, pModuleId)
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

function m.rpc.getAppEventName(pRPC)
  return rcRPCs[pRPC].appEventName
end

function m.rpc.getHMIEventName(pRPC)
  return rcRPCs[pRPC].hmiEventName
end

function m.rpc.getAppRequestParams(pRPC, ...)
  return rcRPCs[pRPC].requestParams(...)
end

function m.rpc.getAppResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function m.rpc.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function m.rpc.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

--[[ rc actions submodule ]]
local function boolToTimes(isTrue)
  if isTrue then
    return 1
  end
  return 0
end

local function validateIVData(_, data)
  if data and data.payload and data.payload.moduleData then
    if data.payload.moduleData.audioControlData and nil ~= data.payload.moduleData.audioControlData.keepContext then
      return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
    end
  end
  return true
end

local function updateIVData(pModuleType, pModuleId, pRPC, pModuleData)
  if pRPC == "SetInteriorVehicleData" or pRPC == "OnInteriorVehicleData" then
    if not pModuleData then
      pModuleData = m.predefined.getSettableModuleControlData(pModuleType, 1)
      pModuleData.moduleId = pModuleId
    end
    m.state.updateActualModuleIVData(pModuleType, pModuleId, pModuleData)
    return pModuleData
  else
    return nil
  end
end

local function isRpcAllocateModule(pRPC)
  local allocationRpcs = {"SetInteriorVehicleData", "ButtonPress"}
  return utils.isTableContains(allocationRpcs, pRPC)
end

local function subscribeToIVData(pModuleType, pModuleId, pAppId, pSubscribe, pIsSubscriptionCached)
  local rpc = "GetInteriorVehicleData"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(rpc),
      m.rpc.getAppRequestParams(rpc, pModuleType, pModuleId, pSubscribe))
  hmi:ExpectRequest(m.rpc.getHMIEventName(rpc),
      m.rpc.getHMIRequestParams(rpc, pModuleType, pModuleId, pAppId, pSubscribe))
  :Times(boolToTimes(not pIsSubscriptionCached))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          m.rpc.getHMIResponseParams(rpc, pModuleType, pModuleId, pSubscribe))
    end)
  mobSession:ExpectResponse(cid, m.rpc.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, pModuleId, pSubscribe))
  :ValidIf(validateIVData)
end

function m.rc.subscribeToModule(pModuleType, pModuleId, pAppId, pIsSubscriptionCached)
  subscribeToIVData(pModuleType, pModuleId, pAppId, true, pIsSubscriptionCached)
end

function m.rc.unsubscribeFromModule(pModuleType, pModuleId, pAppId, pIsSubscriptionCached)
  subscribeToIVData(pModuleType, pModuleId, pAppId, false, pIsSubscriptionCached)
end

function m.rc.checkSubscription(pModuleType, pModuleId, pAppId, pHasSubscription, pModuleData)
  local rpc = "OnInteriorVehicleData"
  updateIVData(pModuleType, pModuleId, rpc, pModuleData)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  hmi:SendNotification(m.rpc.getHMIEventName(rpc), m.rpc.getHMIResponseParams(rpc, pModuleType, pModuleId))
  mobSession:ExpectNotification(m.rpc.getAppEventName(rpc), m.rpc.getAppResponseParams(rpc, pModuleType, pModuleId))
  :Times(boolToTimes(pHasSubscription))
  :ValidIf(validateIVData)
end

function m.rc.defineRAMode(pAllowed, pAccessMode)
  local rpc = "OnRemoteControlSettings"
  local hmi = actions.hmi.getConnection()
  hmi:SendNotification(m.rpc.getHMIEventName(rpc), m.rpc.getHMIResponseParams(rpc, pAllowed, pAccessMode))
  if not pAllowed then
    m.state.resetAllModulesAllocation()
  end
  actions.run.wait(m.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

function m.rc.consentModules(pModuleType, pModuleConsentArray, pAppId, isHmiRequestExpected, pFilteredConsentsArray)
  if not pFilteredConsentsArray then pFilteredConsentsArray = pModuleConsentArray end
  local rpc = "GetInteriorVehicleDataConsent"
  local mobSession = actions.mobile.getSession(pAppId)
  local mobile_moduleIdArray = {}
  local mobile_allowedArray = {}
  for k, v in pairs(pModuleConsentArray) do
    table.insert(mobile_moduleIdArray, k)
    table.insert(mobile_allowedArray, v)
  end
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(rpc),
      m.rpc.getAppRequestParams(rpc, pModuleType, nil, mobile_moduleIdArray))
  if isHmiRequestExpected then
    local hmi_moduleIdArray = {}
    local hmi_allowedArray = {}
    for k, v in pairs(pFilteredConsentsArray) do
      table.insert(hmi_moduleIdArray, k)
      table.insert(hmi_allowedArray, v)
    end
    local hmi = actions.hmi.getConnection()
    hmi:ExpectRequest(m.rpc.getHMIEventName(rpc),
        m.rpc.getHMIRequestParams(rpc, pModuleType, nil, pAppId, hmi_moduleIdArray))
    :Do(function(_, data)
        hmi:SendResponse(data.id, data.method, "SUCCESS",
            m.rpc.getHMIResponseParams(rpc, pModuleType, nil, hmi_allowedArray))
      end)
  end
  mobSession:ExpectResponse(cid, m.rpc.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, nil, mobile_allowedArray))
end



function m.rc.releaseModule(pModuleType, pModuleId, pAppId)
  local rpc = "ReleaseInteriorVehicleDataModule"
  local mobSession = actions.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(rpc), m.rpc.getAppRequestParams(rpc, pModuleType, pModuleId))
  mobSession:ExpectResponse(cid, m.rpc.getAppResponseParams(rpc, true, "SUCCESS"))
  :Do(function()
      m.state.resetModuleAllocation(pModuleType, pModuleId)
    end)
end

function m.rc.rpcSuccess(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pIsIVDataCached)
  pModuleData = updateIVData(pModuleType, pModuleId, pRPC, pModuleData)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(pRPC),
      m.rpc.getAppRequestParams(pRPC, pModuleType, pModuleId, pModuleData))
  hmi:ExpectRequest(m.rpc.getHMIEventName(pRPC),
      m.rpc.getHMIRequestParams(pRPC, pModuleType, pModuleId, pAppId, pModuleData))
  :Times(boolToTimes(not pIsIVDataCached or pRPC ~= "GetInteriorVehicleData"))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          m.rpc.getHMIResponseParams(pRPC, pModuleType, pModuleId, pModuleData))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    if isRpcAllocateModule(pRPC) then
      m.state.setModuleAllocation(pModuleType, pModuleId, pAppId)

    end
  end)
end

function m.rc.rpcReject(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pResultCode)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(pRPC),
      m.rpc.getAppRequestParams(pRPC, pModuleType, pModuleId, pModuleData))
  hmi:ExpectRequest(m.rpc.getHMIEventName(pRPC), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

function m.rc.rpcSuccessWithConsent(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pIsIVDataCached)
  pModuleData = updateIVData(pModuleType, pModuleId, pRPC, pModuleData)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(pRPC),
      m.rpc.getAppRequestParams(pRPC, pModuleType, pModuleId, pModuleData))
  local consentRPC = "GetInteriorVehicleDataConsent"
  hmi:ExpectRequest(m.rpc.getHMIEventName(consentRPC),
      m.rpc.getHMIRequestParams(consentRPC, pModuleType, pModuleId, pAppId, { pModuleId }))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          m.rpc.getHMIResponseParams(consentRPC, pModuleType, pModuleId, { true }))
      hmi:ExpectRequest(m.rpc.getHMIEventName(pRPC),
          m.rpc.getHMIRequestParams(pRPC, pModuleType, pModuleId, pAppId, pModuleData))
      :Times(boolToTimes(not pIsIVDataCached or pRPC ~= "GetInteriorVehicleData"))
      :Do(function(_, data2)
          hmi:SendResponse(data2.id, data2.method, "SUCCESS",
              m.rpc.getHMIResponseParams(pRPC, pModuleType, pModuleId, pModuleData))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    if isRpcAllocateModule(pRPC) then
      m.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
    end
  end)
end

function m.rc.rpcSuccessWithoutConsent(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pIsIVDataCached)
  actions.hmi.getConnection():ExpectRequest(m.rpc.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  m.rc.rpcSuccess(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pIsIVDataCached)
end

function m.rc.rpcRejectWithConsent(pModuleType, pModuleId, pAppId, pRPC, pModuleData)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(m.rpc.getAppEventName(pRPC),
      m.rpc.getAppRequestParams(pRPC, pModuleType, pModuleId, pModuleData))
  local consentRPC = "GetInteriorVehicleDataConsent"
  hmi:ExpectRequest(m.rpc.getHMIEventName(consentRPC),
      m.rpc.getHMIRequestParams(consentRPC, pModuleType, pModuleId, pAppId, { pModuleId }))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          m.rpc.getHMIResponseParams(consentRPC, pModuleType, pModuleId, { false }))
      hmi:ExpectRequest(m.rpc.getHMIEventName(pRPC)):Times(0)
    end)
  local info = "The resource [" .. pModuleType ..":" .. pModuleId
      .."] is in use and the driver disallows this remote control RPC"
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
end

function m.rc.rpcRejectWithoutConsent(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pResultCode)
  actions.hmi.getConnection():ExpectRequest(m.rpc.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  m.rc.rpcReject(pModuleType, pModuleId, pAppId, pRPC, pModuleData, pResultCode)
end

function m.rc.rpcButtonPress(pParams, pAppId)
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC("ButtonPress", pParams)
  pParams.appID = actions.app.getHMIId(pAppId)
  hmi:ExpectRequest("Buttons.ButtonPress", pParams)
  :Do(function(_, data)
    hmi:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    m.state.setModuleAllocation(pParams.moduleType, pParams.moduleId, pAppId)
  end)
end

local function updateRcCapabilities(pBaseRcCapabilities, pNewRcCapabilities)
  for k, v in pairs(capabilitiesMap) do
    if pNewRcCapabilities[k] then
      if pNewRcCapabilities[k] ~= m.DEFAULT then
        pBaseRcCapabilities[v] = pNewRcCapabilities[k]
      end
    else
      pBaseRcCapabilities[v] = nil
    end
  end
end

function m.rc.start(pRcCapabilities)
	local hmiCapabilities
	if pRcCapabilities then
    hmiCapabilities = hmi_values.getDefaultHMITable()
    hmiCapabilities.RC.IsReady.params.available = true
    local rcCapabilities = hmiCapabilities.RC.GetCapabilities.params.remoteControlCapability
    updateRcCapabilities(rcCapabilities, pRcCapabilities)
	end
	return actions.start(hmiCapabilities)
end

function m.rc.updateDefaultRCCapabilitiesInFile(pRcCapabilities)
  local hmiCapabilities = actions.sdl.getHMICapabilitiesFromFile()
  local rcCapabilities = hmiCapabilities.UI.systemCapabilities.remoteControlCapability
  updateRcCapabilities(rcCapabilities, pRcCapabilities)
  actions.sdl.setHMICapabilitiesToFile(hmiCapabilities)
end

function m.rc.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  local ptuUpdateFunc = function(ptuTable)
    for i, _ in pairs(actions.mobile.getApps()) do
      local appParams = actions.app.getParams(i)
      if utils.isTableContains(appParams.appHMIType, "REMOTE_CONTROL") then
        local appPolicies = ptuTable.policy_table.app_policies[appParams.fullAppID]
        table.insert(appPolicies.groups, "RemoteControl")
        appPolicies.moduleType = m.data.getRcModuleTypes()
      end
    end
    pPTUpdateFunc(ptuTable)
  end
  actions.ptu.policyTableUpdate(ptuUpdateFunc, pExpNotificationFunc)
end

-- local function sortModules(pModulesArray)
--   local function f(a, b)
--     if a.moduleType and a.moduleId and b.moduleType and b.moduleId then
--       if a.moduleType == b.moduleType then
--         return a.moduleId < b.moduleId
--       else
--         return a.moduleType < b.moduleType
--       end
--     end
--     return 0
--   end
--   table.sort(pModulesArray, f)
-- end

function m.rc.expectOnRCStatusOnMobile(pAppId, pExpData)
  local expData = utils.cloneTable(pExpData)
  actions.mobile.getSession(pAppId):ExpectNotification("OnRCStatus")
  :ValidIf(function(_, d)
      if d.payload.allowed == nil  then
        return false, "OnRCStatus notification doesn't contains 'allowed' parameter"
      end
      -- sortModules(expData.freeModules)
      -- sortModules(expData.allocatedModules)
      -- sortModules(d.payload.freeModules)
      -- sortModules(d.payload.allocatedModules)
      -- return compareValues(expData, d.payload, "payload")
      local msg = "Response parameters are incorrect."
        .. "\n Expected: " .. utils.toString(expData)
        .. "\n Actual: " .. utils.toString(d.payload)
      local isResponseCorrect =utils.isTableEqual(d.payload, expData)
      if not isResponseCorrect then
        return false, msg
      end
      return true
   end)
end

function m.rc.expectOnRCStatusOnHMI(pExpDataTable)
  local expDataTable = utils.cloneTable(pExpDataTable)
  local usedHmiAppIds = {}
  local appCount = 0;
  for id,_ in pairs(expDataTable) do
    expDataTable[id].appID = id
    appCount = appCount + 1
  end
  actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus")
  :ValidIf(function(_, d)
      if d.params.allowed ~= nil then
        return false, "RC.OnRCStatus notification contains unexpected 'allowed' parameter"
      end

      local hmiAppId = d.params.appID
      local msg
      if expDataTable[hmiAppId] and not usedHmiAppIds[hmiAppId] then
        usedHmiAppIds[hmiAppId] = true
        -- sortModules(expDataTable[hmiAppId].freeModules)
        -- sortModules(expDataTable[hmiAppId].allocatedModules)
        -- sortModules(d.params.freeModules)
        -- sortModules(d.params.allocatedModules)
        -- return compareValues(expDataTable[hmiAppId], d.params, "params")
        msg = "Response parameters for hmiAppId: " .. hmiAppId .. " are incorrect."
          .. "\n Expected: " .. utils.toString(expDataTable[hmiAppId])
          .. "\n Actual: " .. utils.toString(d.params)
        local isResponseCorrect = utils.isTableEqual(d.params, expDataTable[hmiAppId])
        if not isResponseCorrect then
          return false, msg
        end
        return true
      else
        if usedHmiAppIds[hmiAppId] then
          msg = "To many occurrences of RC.OnRCStatus notification for hmiAppId: " .. hmiAppId
        else
          msg = "Unexpected RC.OnRCStatus notification for hmiAppId: " .. hmiAppId
        end
        return false, msg
      end
    end)
  :Times(appCount)
end

return m
