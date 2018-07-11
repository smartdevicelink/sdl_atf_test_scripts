---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonRC = require('test_scripts/RC/commonRC')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require("modules/json")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions
m.cloneTable = utils.cloneTable
m.jsonFileToTable = utils.jsonFileToTable
m.tableToJsonFile = utils.tableToJsonFile
m.wait = utils.wait
m.tableToString = utils.tableToString

local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
m.preconditionOrigin = m.preconditions
local postconditionOrigin = m.postconditions

config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = false

m.modules = { "CLIMATE", "RADIO" }

m.actualInteriorDataStateOnHMI = {
	CLIMATE = {
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
    },
	RADIO = {
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
}

function m.setActualInteriorVD(pModuleType, pParams)
  for key, value in pairs(pParams) do
	  if type(value) ~= "table" then
	    if value ~= m.actualInteriorDataStateOnHMI[pModuleType][key] then
		    m.actualInteriorDataStateOnHMI[pModuleType][key] = value
	    end
	  else
	    if false == commonFunctions:is_table_equal(value, m.actualInteriorDataStateOnHMI[pModuleType][key]) then
        m.actualInteriorDataStateOnHMI[pModuleType][key] = value
      end
	  end
  end
end

function m.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL()
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = m.jsonFileToTable(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  preloadedTable.policy_table.app_policies.default.moduleType = { "RADIO", "CLIMATE" }
  preloadedTable.policy_table.app_policies.default.groups = { "Base-4", "RemoteControl" }
  preloadedTable.policy_table.app_policies.default.AppHMIType = { "REMOTE_CONTROL" }
  m.tableToJsonFile(preloadedTable, preloadedFile)
end

function m.GetInteriorVehicleData(pModuleType, isSubscribe, isHMIreqExpect, pAppId)
  if not pAppId then pAppId = 1 end
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
	  HMIrequestsNumber = 1
  else
	  HMIrequestsNumber = 0
  end
  local cid = m.getMobileSession(pAppId):SendRPC(commonRC.getAppEventName(rpc),
    commonRC.getAppRequestParams(rpc, pModuleType, isSubscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), m.getHMIRequestParams(rpc, pModuleType, pAppId, isSubscribe))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      m.getHMIResponseParams(rpc, pModuleType, isSubscribe))
    end)
  :Times(HMIrequestsNumber)
  m.getMobileSession(pAppId):ExpectResponse(cid, m.getResponseParams(rpc, true, "SUCCESS", pModuleType, isSubscribe))
end

function m.GetInteriorVehicleDataRejected(pModuleType, isSubscribe, pAppId)
  if not pAppId then pAppId = 1 end
  local rpc = "GetInteriorVehicleData"
  local subscribe = isSubscribe
  local mobSession = m.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc),
    commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc))
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
end

function m.OnInteriorVD(pModuleType, isExpectNotification, pAppId, pParams)
  local rpc = "OnInteriorVehicleData"
  local mobSession = m.getMobileSession(pAppId)
  if not pParams then pParams = m.getAnotherModuleControlData(pModuleType) end
  local notificationCount
  if isExpectNotification == true then
    notificationCount = 1
  else
    notificationCount = 0
  end
  m.setActualInteriorVD(pModuleType, pParams)
  m.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc),
    m.getHMIResponseParams(rpc, pModuleType, pParams))
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc),
    m.getResponseParams(rpc, pModuleType, pParams))
  :Times(notificationCount)
end

function m.getModuleControlData(module_type, pParams)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = pParams
  elseif module_type == "RADIO" then
    out.radioControlData = pParams
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
        moduleData = m.getModuleControlData(pModuleType, m.actualInteriorDataStateOnHMI[pModuleType]),
        isSubscribed = pSubscribe
      }
    end,
    responseParams = function(success, resultCode, pModuleType, pSubscribe)
      return {
        success = success,
        resultCode = resultCode,
        moduleData = m.getModuleControlData(pModuleType, m.actualInteriorDataStateOnHMI[pModuleType]),
        isSubscribed = pSubscribe
      }
    end
  },
  OnInteriorVehicleData = {
    appEventName = "OnInteriorVehicleData",
    hmiEventName = "RC.OnInteriorVehicleData",
    hmiResponseParams = function(pModuleType, pParams)
      return {
        moduleData = m.getModuleControlData(pModuleType, pParams)
      }
    end,
    responseParams = function(pModuleType, pParams)
      return {
        moduleData = m.getModuleControlData(pModuleType, pParams)
      }
    end
  }
}

function m.getHMIRequestParams(pRPC, ...)
  return rcRPCs[pRPC].hmiRequestParams(...)
end

function m.getHMIResponseParams(pRPC, ...)
  return rcRPCs[pRPC].hmiResponseParams(...)
end

function m.getResponseParams(pRPC, ...)
  return rcRPCs[pRPC].responseParams(...)
end

function m.getAnotherModuleControlData(module_type)
  local out = {}
  if module_type == "CLIMATE" then
    out = {
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
    out = {
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

function m.unregistrationApp(pAppId, isHMIreqExpect, pModuleType)
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
    HMIrequestsNumber = 1
  else
    HMIrequestsNumber = 0
  end
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), m.getHMIRequestParams(rpc, pModuleType, pAppId, false))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      m.getHMIResponseParams(rpc, pModuleType, false))
    end)
  :Times(HMIrequestsNumber)
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = commonRC.getHMIAppId(pAppId), unexpectedDisconnect = false })
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.setGetInteriorVehicleDataRequestValue(pValue)
  m.setSDLIniParameter("GetInteriorVehicleDataRequest", pValue)
  m.wait(1000)
end

function m.unexpectedDisconnect(pAppId, isHMIreqExpect, pModuleType)
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
    HMIrequestsNumber = 1
  else
    HMIrequestsNumber = 0
  end
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), m.getHMIRequestParams(rpc, pModuleType, pAppId, false))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      m.getHMIResponseParams(rpc, pModuleType, false))
    end)
  :Times(HMIrequestsNumber)
  m.getMobileSession(pAppId):Stop()
end

function m.activateApp(pAppId, pAudioState)
  if not pAppId then pAppId = 1 end
  if not pAudioState then pAudioState = "AUDIBLE" end
  local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  m.getHMIConnection():ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = pAudioState, systemContext = "MAIN" })
  utils.wait()
end

function m.preconditions()
  m.preconditionOrigin()
  commonPreconditions:BackupFile(preloadedPT)
  m.updatePreloadedPT()
end

function m.postconditions()
  postconditionOrigin()
  commonPreconditions:RestoreFile(preloadedPT)
end

return m
