---------------------------------------------------------------------------------------------------
-- OnRCStatus common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = {}

--[[ Functions ]]
local function backupPreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:BackupFile(preloadedFile)
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedFile = commonPreconditions:GetPathToSDL()
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = commonRC.jsonFileToTable(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.appID
    preloadedTable.policy_table.app_policies[appId] = commonRC.getRCAppConfig()
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  commonRC.tableToJsonFile(preloadedTable, preloadedFile)
end

local function restorePreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:RestoreFile(preloadedFile)
end

function m.getModules()
  return commonFunctions:cloneTable({ "RADIO", "CLIMATE" })
end

function m.getAllModules()
  return commonFunctions:cloneTable({ "RADIO", "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS", "SEAT" })
end

function m.getRCAppConfig()
  return commonRC.getRCAppConfig()
end

function m.getMobileSession(pAppId)
  return commonRC.getMobileSession(test, pAppId)
end

function m.getHMIconnection()
  return test.hmiConnection
end

function m.preconditions(pCountOfRCApps)
  commonRC.preconditions()
  backupPreloadedPT()
  updatePreloadedPT(pCountOfRCApps)
end

function m.start()
  commonRC.start(nil, test)
end

function m.getModulesArray(pModules)
  local out = {}
  for _, mod in pairs(pModules) do
    table.insert(out, { moduleType = mod })
  end
  return out
end

function m.getHMIAppIdsRC()
  local out = {}
  for appID, hmiAppId in pairs(commonRC.getHMIAppIds()) do
    for i = 1, 5 do
      local params = config["application" .. i].registerAppInterfaceParams
      if params.appID == appID and params.appHMIType[1] == "REMOTE_CONTROL" then
        table.insert(out, hmiAppId)
      end
    end
  end
  return out
end

function m.registerRCApplication(pAppId)
  if not pAppId then pAppId = 1 end
  local pModuleStatus = {
    freeModules = m.getModulesArray(m.getAllModules()),
    allocatedModules = { }
  }
  commonRC.rai_n(pAppId, test)
  for i = 1, pAppId do
    m.validateOnRCStatusForApp(i, pModuleStatus)
  end
  m.validateOnRCStatusForHMI(pAppId, { pModuleStatus })
end

function m.raiPTU_n(ptu_update_func, pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.rai_ptu_n(pAppId, ptu_update_func, test)
end

function m.rai_n(pAppId)
  commonRC.rai_n(pAppId, test)
end

function m.subscribeToModule(pModule, pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.subscribeToModule(pModule, pAppId, test)
end

function m.activateApp(pAppId)
  commonRC.activate_app(pAppId, test)
end

function m.getHMIAppId(pAppId)
  return commonRC.getHMIAppId(pAppId)
end

function m.getSettableModuleControlData(pModuleType)
  return commonRC.getSettableModuleControlData(pModuleType)
end

function m.postconditions()
  commonRC.postconditions()
  restorePreloadedPT()
end

local function setAllocationState(pAllocArrays, pAllocApp, pModule)
  for i=1,#pAllocArrays do
    for key, value in pairs(pAllocArrays[i]) do
      if pModule == value then
        table.remove(pAllocArrays[i], key)
      end
    end
  end
  table.insert(pAllocArrays[pAllocApp], pModule)
end

function m.setModuleStatus(pFreeMod, pAllocatedMod, pModule, pAllocApp)
  if not pAllocApp then pAllocApp = 1 end
  local modulesStatusAllocatedApp = { }
  local modulesStatusAnotherApp = { }
  setAllocationState(pAllocatedMod, pAllocApp, pModule)
  for key, value in pairs(pFreeMod) do
    if pModule == value then
      table.remove(pFreeMod, key)
    end
  end
  modulesStatusAllocatedApp.freeModules = m.getModulesArray(pFreeMod)
  modulesStatusAnotherApp.freeModules = m.getModulesArray(pFreeMod)
  modulesStatusAllocatedApp.allocatedModules = m.getModulesArray(pAllocatedMod[pAllocApp])
  if 1 == pAllocApp then
    modulesStatusAnotherApp.allocatedModules = pAllocatedMod[2]
  else
    modulesStatusAnotherApp.allocatedModules = pAllocatedMod[1]
  end
  return modulesStatusAllocatedApp, modulesStatusAnotherApp
end

function m.setModuleStatusByDeallocation(pFreeMod, pAllocatedMod, pModule, pRemoveAllocFromApp)
  if not pRemoveAllocFromApp then pRemoveAllocFromApp = 1 end
  local modulesStatusAllocatedApp = { }
  local modulesStatusAnotherApp = { }
  table.insert(pFreeMod, pModule)
  for key, value in pairs(pAllocatedMod[pRemoveAllocFromApp]) do
    if pModule == value then
      table.remove(pAllocatedMod[pRemoveAllocFromApp], key)
    end
  end
  modulesStatusAllocatedApp.freeModules = m.getModulesArray(pFreeMod)
  modulesStatusAnotherApp.freeModules = m.getModulesArray(pFreeMod)
  modulesStatusAllocatedApp.allocatedModules = m.getModulesArray(pAllocatedMod[pRemoveAllocFromApp])
  if 1 == pRemoveAllocFromApp then
    modulesStatusAnotherApp.allocatedModules = pAllocatedMod[2]
  else
    modulesStatusAnotherApp.allocatedModules = pAllocatedMod[1]
  end
  return modulesStatusAllocatedApp, modulesStatusAnotherApp
end

function m.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.deleteHMIAppId(pAppId)
  commonRC.unregisterApp(pAppId, test)
end

function m.closeSession(pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.deleteHMIAppId(pAppId)
  m.getMobileSession(pAppId):Stop()
end

function m.defineRAMode(pAllowed, pAccessMode)
  commonRC.defineRAMode(pAllowed, pAccessMode, test)
end

function m.rpcRejectWithConsent(pModuleType, pAppId, pRPC)
  commonRC.rpcRejectWithConsent(pModuleType, pAppId, pRPC, test)
end

function m.rpcAllowedWithConsent(pModuleType, pAppId, pRPC)
  commonRC.rpcAllowedWithConsent(pModuleType, pAppId, pRPC, test)
end

m.getAppEventName = commonRC.getAppEventName
m.getHMIEventName = commonRC.getHMIEventName
m.getAppRequestParams = commonRC.getAppRequestParams
m.getAppResponseParams = commonRC.getAppResponseParams
m.getHMIRequestParams = commonRC.getHMIRequestParams
m.getHMIResponseParams = commonRC.getHMIResponseParams

function m.rpcAllowed(pModuleType, pAppId, pRPC)
  commonRC.rpcAllowed(pModuleType, pAppId, pRPC, test)
end

function m.cloneTable(...)
  commonFunctions:cloneTable(...)
end

function m.sortModules(pModulesArray)
  local function f(a, b)
    if a.moduleType and b.moduleType then
      return a.moduleType < b.moduleType
    elseif a and b then
      return a < b
    end
    return 0
  end
  table.sort(pModulesArray, f)
end

function m.validateOnRCStatusForApp(pAppId, pExpData)
  m.getMobileSession(pAppId):ExpectNotification("OnRCStatus")
  :ValidIf(function(_, d)
      m.sortModules(pExpData.freeModules)
      m.sortModules(pExpData.allocatedModules)
      m.sortModules(d.payload.freeModules)
      m.sortModules(d.payload.allocatedModules)
      return compareValues(pExpData, d.payload, "payload")
    end)
end

function m.validateOnRCStatusForHMI(pCountOfRCApps, pExpData, pAllocApp)
  local usedHmiAppIds = { }
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :ValidIf(function(_, d)
      m.sortModules(d.params.freeModules)
      m.sortModules(d.params.allocatedModules)
      for i=1,#pExpData do
        m.sortModules(pExpData[i].freeModules)
        m.sortModules(pExpData[i].allocatedModules)
      end
      local AnotherApp
      if pAllocApp and pAllocApp == 1 then
        AnotherApp = 2
      else
        AnotherApp = 1
      end
      if d.params.appID == commonRC.getHMIAppId(pAllocApp) and pAllocApp then
        return compareValues(pExpData[pAllocApp], d.params, "params")
      else
        return compareValues(pExpData[AnotherApp], d.params, "params")
      end
    end)
  :ValidIf(function(e, d)
      if e.occurences == 1 then
        usedHmiAppIds = {}
      end
      local avlHmiAppIds = {}
      for _, appId in pairs(m.getHMIAppIdsRC()) do
        avlHmiAppIds[appId] = true
      end
      local actAppId = d.params.appID
      if avlHmiAppIds[actAppId] and not usedHmiAppIds[actAppId] then
        usedHmiAppIds[actAppId] = true
        return true
      end
      local expAppIds = {}
      for appId in pairs(avlHmiAppIds) do
        if not usedHmiAppIds[appId] then
          table.insert(expAppIds, appId)
        end
      end
      return false, " Occurence: " .. e.occurences .. ", "
      .. "expected appID: [" .. table.concat(expAppIds, ", ") .. "], " .. "actual: " .. tostring(actAppId)
    end)
  :Times(pCountOfRCApps)
end

m.wait = utils.wait

return m
