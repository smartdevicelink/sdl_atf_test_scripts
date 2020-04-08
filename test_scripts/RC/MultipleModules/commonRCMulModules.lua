---------------------------------------------------------------------------------------------------
-- Common RC related actions module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local rc = require('user_modules/sequences/remote_control')
local utils = require('user_modules/utils')
local hmi_values = require("user_modules/hmi_values")
local apiLoader = require("modules/api_loader")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Common Variables ]]
local common = {}

--[[ Common Functions ]]
common.preconditions = actions.preconditions
common.postconditions = actions.postconditions
common.getMobileSession = actions.mobile.getSession
common.getHMIConnection = actions.hmi.getConnection
common.getHMIAppId = actions.app.getHMIId
common.registerApp = actions.app.register
common.registerAppWOPTU = actions.app.registerNoPTU
common.activateApp = actions.app.activate
common.isSdlRunning = actions.sdl.isRunning
common.stopSDL = actions.sdl.stop
common.getPreloadedPT = actions.sdl.getPreloadedPT
common.setPreloadedPT = actions.sdl.setPreloadedPT
common.wait = actions.run.wait
common.failTestStep = actions.run.fail
common.setSDLIniParameter = actions.setSDLIniParameter

common.DEFAULT = rc.DEFAULT
common.getActualModuleStateOnHMI = rc.state.getActualModuleStateOnHMI
common.buildDefaultActualModuleState = rc.state.buildDefaultActualModuleState
common.initActualModuleStateOnHMI = rc.state.initActualModuleStateOnHMI
common.getActualModuleStateOnHMI = rc.state.getActualModuleStateOnHMI
common.getModulesAllocationByApp = rc.state.getModulesAllocationByApp
common.setModuleAllocation = rc.state.setModuleAllocation
common.updateActualModuleIVData = rc.state.updateActualModuleIVData
common.resetModuleAllocation = rc.state.resetModuleAllocation
common.getRcModuleTypes = rc.data.getRcModuleTypes
common.buildModuleData = rc.data.buildModuleData
common.buildSettableModuleData = rc.data.buildSettableModuleData
common.getRcCapabilities = rc.predefined.getRcCapabilities
common.getModuleControlData = rc.predefined.getModuleControlData
common.getSettableModuleControlData = rc.predefined.getSettableModuleControlData
common.updateDefaultRCCapabilitiesInFile = rc.rc.updateDefaultRCCapabilitiesInFile
common.start = rc.rc.start
common.processRpc = rc.rc.rpcSuccess
common.defineRAMode = rc.rc.defineRAMode
common.expectOnRCStatusOnMobile = rc.rc.expectOnRCStatusOnMobile
common.expectOnRCStatusOnHMI =  rc.rc.expectOnRCStatusOnHMI
common.rpcReject = rc.rc.rpcReject
common.rpcSuccess = rc.rc.rpcSuccess
common.releaseModule = rc.rc.releaseModule
common.subscribeToModule = rc.rc.subscribeToModule
common.unsubscribeFromModule = rc.rc.unsubscribeFromModule
common.isSubscribed = rc.rc.isSubscribed
common.policyTableUpdate = rc.rc.policyTableUpdate
common.rpcButtonPress = rc.rc.rpcButtonPress
common.getAppEventName = rc.rpc.getAppEventName
common.getAppRequestParams = rc.rpc.getAppRequestParams
common.getAppResponseParams = rc.rpc.getAppResponseParams
common.getHMIEventName = rc.rpc.getHMIEventName
common.getHMIRequestParams = rc.rpc.getHMIRequestParams
common.getHMIResponseParams = rc.rpc.getHMIResponseParams

common.toString = utils.toString
common.cloneTable = utils.cloneTable
common.json = utils.json
common.EMPTY_ARRAY = utils.json.EMPTY_ARRAY
common.isTableContains = utils.isTableContains
common.cprint = utils.cprint
common.deleteMobDevice = utils.deleteNetworkInterface
common.tableToJsonFile = utils.tableToJsonFile
common.jsonFileToTable = utils.jsonFileToTable

common.MISSED = "MISSED"

common.grid = {
  DRIVER = { col = 0, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  FRONT_PASSENGER = { col = 2, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  BACK_LEFT_PASSENGER = { col = 0, colspan = 1, row = 1, rowspan = 1, level = 0, levelspan = 1 },
  BACK_CENTER_PASSENGER = { col = 1, colspan = 1, row = 1, rowspan = 1, level = 0, levelspan = 1 },
  BACK_RIGHT_PASSENGER = { col = 2, colspan = 1, row = 1, rowspan = 1, level = 0, levelspan = 1 },
  BACK_SEATS = { col = 0, colspan = 3, row = 1, rowspan = 1, level = 0, levelspan = 1 },
  MISSED = common.MISSED
}

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

local function createDefaultRCCapabilitiesInFile()
  local hmiCapabilities = actions.sdl.getHMICapabilitiesFromFile()
  local rcCapabilities = hmiCapabilities.UI.systemCapabilities.remoteControlCapability
  local defaultValue = "Default"
  for moduleType, params in pairs(rcCapabilities) do
    if moduleType ~= "buttonCapabilities"  then
      if moduleType ~= "lightControlCapabilities" and moduleType ~= "hmiSettingsControlCapabilities" then
        for _, module in pairs(params) do
          module.moduleName = module.moduleName .. " "..defaultValue
          module.moduleInfo.moduleId = string.sub(moduleType, 1, 1) .. defaultValue
        end
      else
        params.moduleName = params.moduleName.." "..defaultValue
        params.moduleInfo.moduleId = string.sub(moduleType, 1, 1) .. defaultValue
      end
    end
  end
  return hmiCapabilities
end

function common.getExpectedParameters()
  local rcDefaultCapabilities = createDefaultRCCapabilitiesInFile().UI.systemCapabilities.remoteControlCapability
  local expectedParameters = {
    remoteControlCapability = {
      climateControlCapabilities = rcDefaultCapabilities.climateControlCapabilities,
      radioControlCapabilities = rcDefaultCapabilities.radioControlCapabilities,
      audioControlCapabilities = rcDefaultCapabilities.audioControlCapabilities,
      seatControlCapabilities = rcDefaultCapabilities.seatControlCapabilities,
      hmiSettingsControlCapabilities = rcDefaultCapabilities.hmiSettingsControlCapabilities,
      lightControlCapabilities = rcDefaultCapabilities.lightControlCapabilities
    }
  }
  return expectedParameters
end

function common.updateDefaultHmiCapabilities()
  local hmiCapabilities = createDefaultRCCapabilitiesInFile()
  actions.sdl.setHMICapabilitiesToFile(hmiCapabilities)
end

local function getRCAppConfig(pPt)
  if pPt then
    local out = utils.cloneTable(pPt.policy_table.app_policies.default)
    out.moduleType = rc.data.getRcModuleTypes()
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = rc.data.getRcModuleTypes(),
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

function common.preparePreloadedPT(pRCAppIds)
  local preloadedTable = common.getPreloadedPT()
  for _, rcAppId in pairs(pRCAppIds) do
    local appId = config["application" .. rcAppId].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
  end
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  common.setPreloadedPT(preloadedTable)
end

function common.initHmiRcCapabilities(pUpdRcCapabilities, pIsReplace)
  local capabilities = common.getRcCapabilities()
  for updModuleType, updModuleTypeCapabilities in pairs(pUpdRcCapabilities) do
    if pIsReplace then
      capabilities[updModuleType] = updModuleTypeCapabilities
    else
      for _, updModuleCapabilities in ipairs(updModuleTypeCapabilities) do
        local isFound = false
        for idx, moduleCapabilities in ipairs(capabilities[updModuleType]) do
          if moduleCapabilities.moduleInfo.moduleId == updModuleCapabilities.moduleInfo.moduleId then
            capabilities[updModuleType][idx] = updModuleCapabilities
            isFound = true
          end
        end
        if not isFound then
          table.insert(capabilities[updModuleType], updModuleCapabilities)
        end
      end
    end
  end
  return capabilities
end

function common.initHmiDataState(pRcCapabilities)
  local state = common.buildDefaultActualModuleState(pRcCapabilities)
  common.initActualModuleStateOnHMI(state)
end

function common.buildDefaultSettableModuleData(pModuleType, pModuleId)
  local data = rc.predefined.getSettableModuleControlData(pModuleType, 1)
  data.moduleId = pModuleId
  return data
end

function common.setUserLocation(pAppId, pGrid, pResultCode)
  pResultCode = pResultCode or "SUCCESS"
  local isSuccess = pResultCode == "SUCCESS"
  local mobileSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobileSession:SendRPC("SetGlobalProperties", { userLocation = { grid = pGrid }})
  if isSuccess then
    hmi:ExpectRequest("RC.SetGlobalProperties", {
        appID = actions.app.getHMIId(pAppId), userLocation = { grid = pGrid }})
    :Do(function(_, data)
        hmi:SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
  mobileSession:ExpectResponse(cid, { success = isSuccess, resultCode = pResultCode })
end

function common.setRpcRejectNoModuleId(pModuleType, _, pAppId, pModuleData, pResultCode)
  local rpc = "SetInteriorVehicleData"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local moduleDataNoId = utils.cloneTable(pModuleData)
  moduleDataNoId.moduleId = nil
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
      rc.rpc.getAppRequestParams(rpc, pModuleType, nil, moduleDataNoId))
  hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc), {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

function common.setRpcSuccessNoModuleId(pModuleType, pModuleId, pAppId, pModuleData)
  rc.state.updateActualModuleIVData(pModuleType, pModuleId, pModuleData)
  local rpc = "SetInteriorVehicleData"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local moduleDataNoId = utils.cloneTable(pModuleData)
  moduleDataNoId.moduleId = nil
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
      rc.rpc.getAppRequestParams(rpc, pModuleType, nil, moduleDataNoId))
  hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc),
      rc.rpc.getHMIRequestParams(rpc, pModuleType, pModuleId, pAppId, pModuleData))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          rc.rpc.getHMIResponseParams(rpc, pModuleType, pModuleId, pModuleData))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    rc.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  end)
end

function common.setRpcSuccessWithConsentNoModuleId(pModuleType, pModuleId, pAppId, pModuleData)
  rc.state.updateActualModuleIVData(pModuleType, pModuleId, pModuleData)
  local rpc = "SetInteriorVehicleData"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local moduleDataNoId = utils.cloneTable(pModuleData)
  moduleDataNoId.moduleId = nil
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
      rc.rpc.getAppRequestParams(rpc, pModuleType, nil, moduleDataNoId))
  local consentRPC = "GetInteriorVehicleDataConsent"
  hmi:ExpectRequest(rc.rpc.getHMIEventName(consentRPC),
      rc.rpc.getHMIRequestParams(consentRPC, pModuleType, pModuleId, pAppId, { pModuleId }))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          rc.rpc.getHMIResponseParams(consentRPC, pModuleType, pModuleId, { true }))
      hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc),
          rc.rpc.getHMIRequestParams(rpc, pModuleType, pModuleId, pAppId, pModuleData))
      :Do(function(_, data2)
          hmi:SendResponse(data2.id, data2.method, "SUCCESS",
              rc.rpc.getHMIResponseParams(rpc, pModuleType, pModuleId, pModuleData))
        end)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    rc.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  end)
end

function common.setRpcSuccessWithoutConsentNoModuleId(pModuleType, pModuleId, pAppId, pModuleData)
  actions.hmi.getConnection():ExpectRequest(rc.rpc.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  common.setRpcSuccessNoModuleId(pModuleType, pModuleId, pAppId, pModuleData)
end

function common.allocateModule(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local hmiExpDataTable  = { }
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  rc.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  for _, appId in pairs(pRCAppIds) do
    local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
    hmiExpDataTable[actions.app.getHMIId(appId)] = utils.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
  rc.rc.rpcSuccess(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData)
end

function common.allocateModuleWithoutConsent(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local hmiExpDataTable  = { }
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  rc.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  for _, appId in pairs(pRCAppIds) do
    local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
    hmiExpDataTable[actions.app.getHMIId(appId)] = utils.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
  rc.rc.rpcSuccessWithoutConsent(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData)
end

function common.allocateModuleWithConsent(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local hmiExpDataTable  = { }
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  rc.state.setModuleAllocation(pModuleType, pModuleId, pAppId)
  for _, appId in pairs(pRCAppIds) do
    local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
    hmiExpDataTable[actions.app.getHMIId(appId)] = utils.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
  rc.rc.rpcSuccessWithConsent(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData)
end

function common.rejectedAllocationOfModule(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds, pResultCode)
  if not pResultCode then pResultCode = "REJECTED" end
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  for _, appId in pairs(pRCAppIds) do
    actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  rc.rc.rpcReject(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData, pResultCode)
end

function common.rejectedAllocationOfModuleWithoutConsent(pAppId, pModuleType, pModuleId,
                                                         pModuleParams, pRCAppIds, pResultCode)
  if not pResultCode then pResultCode = "REJECTED" end
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  for _, appId in pairs(pRCAppIds) do
    actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  rc.rc.rpcRejectWithoutConsent(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData, pResultCode)
end

function common.rejectedAllocationOfModuleWithConsent(pAppId, pModuleType, pModuleId, pModuleParams, pRCAppIds)
  local moduleData = nil
  if pModuleParams then
    moduleData = rc.data.buildSettableModuleData(pModuleType, pModuleId, pModuleParams)
  end
  for _, appId in pairs(pRCAppIds) do
    actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  rc.rc.rpcRejectWithConsent(pModuleType, pModuleId, pAppId, "SetInteriorVehicleData", moduleData)
end

local function buildTestModuleId(pModuleType)
  return string.sub(pModuleType, 1, 1) .. "0Test"
end

function common.initHmiRcCapabilitiesAllocation(pModuleInfoUpdate)
  local excludedModuleTypes = {"BUTTONS", "HMI_SETTINGS", "LIGHT"}
  local function updateModuleInfo(moduleType, pModuleInfo, pUpdate)
    pModuleInfo.moduleId = buildTestModuleId(moduleType)
    for param, value in pairs(pUpdate) do
      if value ~= common.MISSED then
        pModuleInfo[param] = value
      else
        pModuleInfo[param] = nil
      end
    end
  end

  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    if not common.isTableContains(excludedModuleTypes, moduleType) then
      local newModuleCapabilities = common.cloneTable(modules[1])
      updateModuleInfo(moduleType, newModuleCapabilities.moduleInfo, pModuleInfoUpdate)
      table.insert(capabilities[moduleType], newModuleCapabilities)
    elseif moduleType ~= "BUTTONS" then
      updateModuleInfo(moduleType, modules.moduleInfo, pModuleInfoUpdate)
    end
  end
  return capabilities
end

function common.driverConsentForReallocationToApp(pAppId, pModuleType, pModuleConsentArray,
                                                  pRCAppIds, pAccessMode, pSdlDecisions)
  if not pAccessMode then pAccessMode = "ASK_DRIVER" end
  local hmi = actions.hmi.getConnection()
  for _, appId in pairs(pRCAppIds) do
    actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  hmi:ExpectNotification("RC.OnRCStatus"):Times(0)
  local filteredConsentsArray = {}
  local isHmiRequestExpected = false
  if pAccessMode == "ASK_DRIVER" then
    if type(pSdlDecisions) == "table" then
      for moduleId, isSdlDecision in pairs(pSdlDecisions) do
        if not isSdlDecision then 
          isHmiRequestExpected = true
          filteredConsentsArray[moduleId] = pModuleConsentArray[moduleId]
        end
      end
    else
      isHmiRequestExpected = true
      filteredConsentsArray = nil
    end
  else
    hmi:ExpectRequest("RC.GetInteriorVehicleDataConsent"):Times(0)
  end
  rc.rc.consentModules(pModuleType, pModuleConsentArray, pAppId, isHmiRequestExpected, filteredConsentsArray)
end

-- Used once
function common.driverConsentForReallocationToAppNoModuleId(pAppId, pModuleType, pExpModuleId, pIsAllowed, pRCAppIds)
  for _, appId in pairs(pRCAppIds) do
    actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
  end
  actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)

  local rpc = "GetInteriorVehicleDataConsent"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(rc.rpc.getAppEventName(rpc),
      rc.rpc.getAppRequestParams(rpc, pModuleType, nil, utils.json.EMPTY_ARRAY))
  hmi:ExpectRequest(rc.rpc.getHMIEventName(rpc),
      rc.rpc.getHMIRequestParams(rpc, pModuleType, nil, pAppId, { pExpModuleId }))
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS",
          rc.rpc.getHMIResponseParams(rpc, pModuleType, nil, { pIsAllowed }))
    end)
  mobSession:ExpectResponse(cid, rc.rpc.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, nil, { pIsAllowed }))
end

local function getModules(pModuleType, pModules)
  if pModuleType ~= "BUTTONS" then
    if not pModules[1] then -- HMI_SETTINGS and LIGHT
      pModules =  { pModules }
    end
    return pModules
  end
  return nil
end

function common.initHmiRcCapabilitiesForRelease(pAppLocation)
  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    modules = getModules(moduleType, modules)
    if modules then modules[1].moduleInfo.serviceArea = pAppLocation end
  end
  return capabilities
end

function common.buildTestModulesArray()
  local testModulesArray = {}
  for _, moduleType in ipairs(common.getRcModuleTypes()) do
    table.insert(testModulesArray, { moduleType = moduleType, moduleId = buildTestModuleId(moduleType) })
  end
  return testModulesArray
end

function common.buildTestModulesArrayFirst(pRcCapabilities)
  local testModulesArray = {}
  for moduleType, modules in pairs(pRcCapabilities) do
    modules = getModules(moduleType, modules)
    if modules then
      table.insert(testModulesArray, { moduleType = moduleType, moduleId = modules[1].moduleInfo.moduleId })
    end
  end
  return testModulesArray
end

local function getInfo(pModuleType, pModuleId, pInfoType)
  local info = {
    SUCCESS = "is released successfully.",
    FREE_MODULE ="is not allocated to any application.",
    ALLOCATED_TO_ANOTHER_APP ="is allocated to a different application.",
    NOT_EXISTING_MODULE = "",
    INCORRECT_MODULE_TYPE = ""
  }

  if pInfoType == "INCORRECT_MODULE_TYPE" then
    return "RPC.msg_params.moduleType: Invalid enum value: " .. pModuleType
  elseif pInfoType == "NOT_EXISTING_MODULE" then
    return "Accessing not supported module"
  end
  return "Module [" .. pModuleType .. ":" .. pModuleId .. "] " .. info[pInfoType]
end

function common.releaseModuleWithInfoCheck(pAppId, pModuleType, pModuleId, pResultCode, pInfoType, pRCAppIds)
  local isSuccess = pResultCode == "SUCCESS"
  local infoMsg = getInfo(pModuleType, pModuleId, pInfoType)
  local mobSession = common.getMobileSession(pAppId)
  if isSuccess then
    local hmiExpDataTable  = { }
    rc.state.resetModuleAllocation(pModuleType, pModuleId)
    for _, appId in pairs(pRCAppIds) do
      local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
      hmiExpDataTable[actions.app.getHMIId(appId)] = utils.cloneTable(rcStatusForApp)
      rcStatusForApp.allowed = true
      rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
    end
    rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
  else
    for _, appId in pairs(pRCAppIds) do
      actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
    end
    actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  end
  local cid = mobSession:SendRPC("ReleaseInteriorVehicleDataModule",
      { moduleType = pModuleType, moduleId = pModuleId })
  mobSession:ExpectResponse(cid, { success = isSuccess, resultCode = pResultCode, info = infoMsg })
end

function common.releaseModuleNoModuleId(pAppId, pModuleType, pModuleId, pResultCode, pInfoType, pRCAppIds)
  local isSuccess = pResultCode == "SUCCESS"
  local infoMsg = getInfo(pModuleType, pModuleId, pInfoType)
  local mobSession = common.getMobileSession(pAppId)
  if isSuccess then
    local hmiExpDataTable  = { }
    rc.state.resetModuleAllocation(pModuleType, pModuleId)
    for _, appId in pairs(pRCAppIds) do
      local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
      hmiExpDataTable[actions.app.getHMIId(appId)] = utils.cloneTable(rcStatusForApp)
      rcStatusForApp.allowed = true
      rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
    end
    rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
  else
    for _, appId in pairs(pRCAppIds) do
      actions.mobile.getSession(appId):ExpectNotification("OnRCStatus"):Times(0)
    end
    actions.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  end
  local cid = mobSession:SendRPC("ReleaseInteriorVehicleDataModule", { moduleType = pModuleType })
  mobSession:ExpectResponse(cid, { success = isSuccess, resultCode = pResultCode, info = infoMsg })
end

function common.connectMobDevice(pMobConnId, pDeviceInfo, pIsSDLAllowed)
  if pIsSDLAllowed == nil then pIsSDLAllowed = true end
  utils.addNetworkInterface(pMobConnId, pDeviceInfo.host)
  actions.mobile.createConnection(pMobConnId, pDeviceInfo.host, pDeviceInfo.port)
  local mobConnectExp = actions.mobile.connect(pMobConnId)
  if pIsSDLAllowed then
    mobConnectExp:Do(function()
        actions.mobile.allowSDL(pMobConnId)
      end)
  end
end

function common.unRegisterApp(pAppId)
  rc.state.resetModulesAllocationByApp(pAppId)
  actions.app.unRegister(pAppId)
end

local function createDefaultSLCapabilitiesInFile()
  local hmiCapabilities = actions.sdl.getHMICapabilitiesFromFile()
  local seatLocationCapability = {
    columns = 1, levels = 1, rows = 1,
    seats = {{ grid = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }}}
  }
  hmiCapabilities.UI.systemCapabilities.seatLocationCapability = utils.cloneTable(seatLocationCapability)
  return hmiCapabilities
end

function common.getExpectedSLParameters()
  local slDefaultCapabilities = createDefaultSLCapabilitiesInFile().UI.systemCapabilities.seatLocationCapability
  local expectedParameters = { seatLocationCapability =  slDefaultCapabilities.seatLocationCapability }
  return expectedParameters
end

function common.updateDefaultHmiSLCapabilities()
  local hmiCapabilities = createDefaultSLCapabilitiesInFile()
  actions.sdl.setHMICapabilitiesToFile(hmiCapabilities)
end

function common.startSl(pSlCapabilities)
  local hmiCapabilities
  if pSlCapabilities then
    hmiCapabilities = hmi_values.getDefaultHMITable()
    hmiCapabilities.RC.IsReady.params.available = true
    hmiCapabilities.RC.GetCapabilities.params.seatLocationCapability = pSlCapabilities
  end
  return actions.start(hmiCapabilities)
end

function common.sendGetSystemCapability(pAppId, pSystemCapabilityType, pResponseCapabilities)
  local mobSession = actions.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("GetSystemCapability", { systemCapabilityType = pSystemCapabilityType })
  mobSession:ExpectResponse(cid, { systemCapability = pResponseCapabilities, success = true, resultCode = "SUCCESS" })
end

function common.rpcWithModuleIdOmitted(pAppId, pModuleType, pDefaultModuleId, pSubscribe)
  local rpc = "GetInteriorVehicleData"
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC(rpc, { moduleType = pModuleType, subscribe = pSubscribe })
  hmi:ExpectRequest("RC."..rpc, { moduleType = pModuleType, moduleId = pDefaultModuleId })
  :Do(function(_, data)
    hmi:SendResponse(data.id, data.method, "SUCCESS",
      rc.rpc.getHMIResponseParams(rpc, pModuleType, pDefaultModuleId, pSubscribe))
    end)
  mobSession:ExpectResponse(cid, rc.rpc.getAppResponseParams
    (rpc, true, "SUCCESS", pModuleType, pDefaultModuleId, pSubscribe))
  :ValidIf(function(_, data)
    if data and data.payload and data.payload.moduleData then
      if data.payload.moduleData.audioControlData and nil ~= data.payload.moduleData.audioControlData.keepContext then
        return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
      end
    end
    return true
  end)
end

function common.PTUfunc(tbl)
  local appPolicies = tbl.policy_table.app_policies
  local index = config.application1.registerAppInterfaceParams.fullAppID
  appPolicies[index].moduleType = common.getRcModuleTypes()
end

function common.customModulesPTU (pModuleType)
  local function PTUfunc(tbl)
    local appPolicies = tbl.policy_table.app_policies
    local index = config.application1.registerAppInterfaceParams.fullAppID
    appPolicies[index].moduleType = { pModuleType }
  end
  common.policyTableUpdate(PTUfunc)
end

function common.subscribeToIVDataNoModuleId(pModuleType, pModuleId, pAppId, pSubscribe, pResultCode)
  local rpc = "GetInteriorVehicleData"
  local mobSession = common.getMobileSession(pAppId)
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC(rpc, { moduleType = pModuleType, subscribe = pSubscribe })     -- omitted moduleID
  hmi:ExpectRequest("RC.GetInteriorVehicleData", { moduleId = pModuleId, moduleType =  pModuleType })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, pResultCode,
          common.getHMIResponseParams(rpc, pModuleType, pModuleId, pSubscribe))
    end)
  mobSession:ExpectResponse(cid, common.getAppResponseParams
    (rpc, true, "SUCCESS", pModuleType, pModuleId, pSubscribe))
  :ValidIf(function(_, data)
      if data and data.payload and data.payload.moduleData then
        if data.payload.moduleData.audioControlData and nil ~= data.payload.moduleData.audioControlData.keepContext then
          return false, "Mobile response GetInteriorVehicleData contains unexpected keepContext parameter"
        end
      end
      return true
    end)
end

function common.sendSuccessRpcNoModuleId(pModuleType, pModuleId, pAppId, pRPC, pModuleData)
  if not pModuleData then
    pModuleData = rc.predefined.getSettableModuleControlData(pModuleType, 1)
    pModuleData.moduleId = pModuleId
  end
  rc.state.updateActualModuleIVData(pModuleType, pModuleId, pModuleData)
  local mobSession = common.getMobileSession(pAppId)
  local hmi = common.getHMIConnection()
  local cid = mobSession:SendRPC(common.getAppEventName(pRPC), {moduleData = pModuleData})
  hmi:ExpectRequest(common.getHMIEventName(pRPC),
      common.getHMIRequestParams(pRPC, pModuleType, pModuleId, pAppId, pModuleData))
  :Do(function(_, data)
    local hmiRequestModuleId = data.params.moduleData.moduleId
    pModuleData.moduleId = hmiRequestModuleId
    hmi:SendResponse(data.id, data.method, "SUCCESS",
          common.getHMIResponseParams(pRPC, pModuleType, hmiRequestModuleId, pModuleData))
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.setModuleAllocation(pModuleType, pModuleId, pAppId)
    end)
end

function common.sendButtonPressNoModuleId(pModuleId, pParams, pAppId)
  local mobRequestParams = common.cloneTable(pParams)
  pParams.moduleId = pModuleId
  local mobSession = actions.mobile.getSession(pAppId)
  local hmi = actions.hmi.getConnection()
  local cid = mobSession:SendRPC("ButtonPress", mobRequestParams)
  pParams.appID = actions.app.getHMIId(pAppId)
  hmi:ExpectRequest("Buttons.ButtonPress", pParams)
  :Do(function(_, data)
    hmi:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
    common.setModuleAllocation(pParams.moduleType, pParams.moduleId, pAppId)
  end)
end

function common.initHmiRcCapabilitiesConsent(pAppLocation, pModuleIdModification)
  pModuleIdModification = pModuleIdModification or ""
  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    modules = getModules(moduleType, modules)
    if modules then
      local moduleInfo = modules[1].moduleInfo
      moduleInfo.serviceArea = pAppLocation
      moduleInfo.moduleId = moduleInfo.moduleId .. pModuleIdModification
    end
  end
  return capabilities
end

function common.initHmiRcCapabilitiesMultiConsent(pAppLocation)
  local excludedModuleTypes = {"BUTTONS", "HMI_SETTINGS", "LIGHT"}
  local capabilities = common.getRcCapabilities()
  for moduleType, modules in pairs(capabilities) do
    if not common.isTableContains(excludedModuleTypes, moduleType) then
      local originModuleCapabilities = modules[1]
      originModuleCapabilities.moduleInfo.serviceArea = pAppLocation
      originModuleCapabilities.moduleInfo.allowMultipleAccess = true
      local newModuleTypeCapabilities = { }
      table.insert(newModuleTypeCapabilities, common.cloneTable(originModuleCapabilities))
      originModuleCapabilities.moduleInfo.moduleId = originModuleCapabilities.moduleInfo.moduleId .. "+"
      table.insert(newModuleTypeCapabilities, originModuleCapabilities)
      capabilities[moduleType] = newModuleTypeCapabilities
    end
  end
  return capabilities
end

function common.buildTestModulesStruct(pRcCapabilities)
  local excludedModuleTypes = {"BUTTONS", "HMI_SETTINGS", "LIGHT"}
  local modulesStuct = {}
  for moduleType, modules in pairs(pRcCapabilities) do
    if not common.isTableContains(excludedModuleTypes, moduleType) then
      modulesStuct[moduleType] = {}
      local isAllowed = true
      for _, rcModuleCapabilities in ipairs(modules) do
        modulesStuct[moduleType][rcModuleCapabilities.moduleInfo.moduleId] = isAllowed
        isAllowed = not isAllowed
      end
    end
  end
  return modulesStuct
end

function common.buildTestModulesStructSame(pRcCapabilities, pIsAllowed)
  local excludedModuleTypes = {"BUTTONS", "HMI_SETTINGS", "LIGHT"}
  local modulesStuct = {}
  for moduleType, modules in pairs(pRcCapabilities) do
    if not common.isTableContains(excludedModuleTypes, moduleType) then
      modulesStuct[moduleType] = {}
      for _, rcModuleCapabilities in ipairs(modules) do
        modulesStuct[moduleType][rcModuleCapabilities.moduleInfo.moduleId] = pIsAllowed
      end
    end
  end
  return modulesStuct
end

function common.getAllocationFunction(pIsAllowed, pIsConsentRequired)
  if pIsConsentRequired then
    return pIsAllowed and common.allocateModuleWithConsent
      or common.rejectedAllocationOfModuleWithConsent
  else
    return pIsAllowed and common.allocateModuleWithoutConsent
      or common.rejectedAllocationOfModuleWithoutConsent
  end
end

function common.ignitionOff()
  local isOnSDLCloseSent = false
  local hmi = common.getHMIConnection()
  hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmi:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      hmi:ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
        end)
      :Times(AtMost(1))
    end)
  common.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then common.cprint(35, "BC.OnSDLClose was not sent") end
      if common.isSdlRunning() then common.stopSDL() end
    end)
end

return common
