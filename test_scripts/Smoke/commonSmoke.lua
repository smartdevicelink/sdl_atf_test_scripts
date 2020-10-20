---------------------------------------------------------------------------------------------------
-- Smoke API common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local test = require("user_modules/dummy_connecttest")
local utils = require('user_modules/utils')
local json = require("modules/json")
local mobileConnection  = require('mobile_connection')
local SDL = require("SDL")
local mobile_adapter_controller = require("mobile_adapter/mobile_adapter_controller")
local file_connection  = require('file_connection')
local events = require("events")
local constants = require('protocol_handler/ford_protocol_constants')
local expectations = require('expectations')
local atf_logger = require("atf_logger")
local hmi_values = require("user_modules/hmi_values")

--[[ Module ]]
local common = require('user_modules/sequences/actions')

--[[ Mapped functions and constants ]]
common.cloneTable = utils.cloneTable
common.tableToString = utils.tableToString
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC
common.wait = utils.wait
common.cprint = utils.cprint
common.cprintTable = utils.cprintTable
common.tableToJsonFile = utils.tableToJsonFile
common.jsonFileToTable = utils.jsonFileToTable
common.isTableEqual = utils.isTableEqual
common.constants = constants
common.json = { decode = json.decode, null = json.null }
common.events = { disconnectedEvent = events.disconnectedEvent }
common.SDL = { buildOptions = SDL.buildOptions }
common.SDL.PTS = SDL.PTS
common.runAfter = common.run.runAfter
common.failTestCase = common.run.fail
common.getDeviceTransportType = utils.getDeviceTransportType

--[[ Module constants ]]
common.timeout = 4000

--[[ Module functions ]]
function common.readParameterFromSDLINI(pParamName)
  return SDL.INI.get(pParamName)
end

function common.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(35, str)
end

--[[ Local Variables ]]
local isPreloadedUpdated = false

function common.postconditions()
  StopSDL()
  common.restoreSDLIniParameters()
  if isPreloadedUpdated == true then SDL.PreloadedPT.restore() end
end

function common.updatePreloadedPT()
  if isPreloadedUpdated == false then
    isPreloadedUpdated = true
    SDL.PreloadedPT.backup()
  end
  local pt = SDL.PreloadedPT.get()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "SubscribeVehicleData", "UnsubscribeVehicleData", "GetVehicleData", "UpdateTurnList",
    "AlertManeuver", "DialNumber", "ReadDID", "GetDTCs", "ShowConstantTBT", "Alert", "SubtleAlert", 
    "OnSubtleAlertPressed"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies["0000001"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies["0000001"].keep_context = true
  pt.policy_table.app_policies["0000001"].steal_focus = true
  pt.policy_table.app_policies["0000001"].priority = "NORMAL"
  SDL.PreloadedPT.set(pt)
end

function common.preparePreloadedPTForRC()
  if isPreloadedUpdated == false then
    isPreloadedUpdated = true
    SDL.PreloadedPT.backup()
  end
  local pt = SDL.PreloadedPT.get()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local appId = config["application1"].registerAppInterfaceParams.fullAppID
  pt.policy_table.app_policies[appId] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    moduleType ={ "CLIMATE" },
    groups = { "Base-4", "RemoteControl" },
    AppHMIType = { "REMOTE_CONTROL" }
  }
  SDL.PreloadedPT.set(pt)
end

function common.getRcModuleId(pRcModuleType, pIdx)
  local capMap = {
    RADIO = "radioControlCapabilities",
    CLIMATE = "climateControlCapabilities",
    SEAT = "seatControlCapabilities",
    AUDIO = "audioControlCapabilities",
    LIGHT = "lightControlCapabilities",
    HMI_SETTINGS = "hmiSettingsControlCapabilities",
    BUTTONS = "buttonCapabilities"
  }

  local rcCapabilities = hmi_values.getDefaultHMITable().RC.GetCapabilities.params.remoteControlCapability
  if pRcModuleType == "LIGHT" or pRcModuleType == "HMI_SETTINGS" then
    return rcCapabilities[capMap[pRcModuleType]].moduleInfo.moduleId
  else
    return rcCapabilities[capMap[pRcModuleType]][pIdx].moduleInfo.moduleId
  end
end

function common.createMobileSession(pAppId, pHBParams, pConId)
  return common.mobile.createSession(pAppId, pConId, pHBParams)
end

common.getMobileSession = common.mobile.getSession

function common.putFile(pParams)
  local cid = common.getMobileSession():SendRPC("PutFile", pParams.requestParams, pParams.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.registerApp(pAppId, pHBParams)
  if not pAppId then pAppId = 1 end
  local mobConnId = 1
  local session = common.mobile.createSession(pAppId, mobConnId, pHBParams)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
          session:ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
        end)
    end)
end

function common.getPathToFileInAppStorage(pFileName, pAppId)
  return SDL.AppStorage.path() .. common.getConfigAppParams(pAppId).fullAppID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

function common.isFileExistInAppStorage(pFileName)
  return SDL.AppStorage.isFileExist(pFileName)
end

function common.unregisterApp(pAppId)
  if pAppId == nil then pAppId = 1 end
  local cid = common.getMobileSession(pAppId):SendRPC("UnregisterAppInterface", {})
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false, appID = common.getHMIAppId(pAppId) })
  :Do(function()
      common.setHMIAppId(nil, pAppId)
      common.deleteMobileSession(pAppId)
    end)
end

function common.reregisterApp(pResultCode, pExpResDataFunc, pExpResLvlFunc)
  common.createMobileSession()
  local params = common.cloneTable(common.getConfigAppParams())
  params.hashID = common.hashId
  common.getMobileSession():StartService(7)
  :Do(function()
      if pExpResDataFunc then pExpResDataFunc() end
      if pExpResLvlFunc then pExpResLvlFunc() end
      local cid = common.getMobileSession():SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = pResultCode })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)
  common.wait(common.timeout)
end

function common.deleteMobileSession(pAppId)
  if pAppId == nil then pAppId = 1 end
  common.getMobileSession(pAppId):Stop()
  :Do(function()
      test.mobileSession[pAppId] = nil
    end)
end

function test.mobileConnection:Close()
  for i = 1, common.getAppsCount() do
    test.mobileSession[i] = nil
  end
  self.connection:Close()
end

common.reqParams = {
  AddCommand = {
    mob = { cmdID = 1, vrCommands = { "OnlyVRCommand" }},
    hmi = { cmdID = 1, type = "Command", vrCommands = { "OnlyVRCommand" }}
  },
  AddSubMenu = {
    mob = { menuID = 1, position = 500, menuName = "SubMenu" },
    hmi = { menuID = 1, menuParams = { position = 500, menuName = "SubMenu" }}
  }
}

function common.addCommand()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.reqParams.AddCommand.mob)
  common.getHMIConnection():ExpectRequest("VR.AddCommand", common.reqParams.AddCommand.hmi)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId = data.payload.hashID
    end)
end

function common.addSubMenu()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", common.reqParams.AddSubMenu.mob)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", common.reqParams.AddSubMenu.hmi)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId = data.payload.hashID
    end)
end

function common.ignitionOff(pExpFunc)
  local isOnSDLCloseSent = false
  if pExpFunc then pExpFunc() end
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
          SDL.DeleteFile()
        end)
    end)
  common.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then common.cprint(35, "BC.OnSDLClose was not sent") end
      StopSDL()
    end)
end

function common.masterReset(pExpFunc)
  local isOnSDLCloseSent = false
  if pExpFunc then pExpFunc() end
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "MASTER_RESET" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  common.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then common.cprint(35, "BC.OnSDLClose was not sent") end
      StopSDL()
    end)
end

function common.unexpectedDisconnect(pAppId)
  if pAppId == nil then pAppId = 1 end
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true, appID = common.getHMIAppId(pAppId) })
  common.deleteMobileSession(pAppId)
  utils.wait(1000)
end

function common.createEvent(pMatchFunc)
  if pMatchFunc == nil then
    pMatchFunc = function(e1, e2) return e1 == e2 end
  end
  local event = events.Event()
  event.matches = pMatchFunc
  return event
end

function common.createConnection(pConId, pDevice)
  local function getMobileAdapter(pSource)
    if config.defaultMobileAdapterType ~= "TCP" then
      print("WARNING: Default mobile adapter type is not TCP. Create TCP mobile connection.")
    end
    local mobileAdapterParameters = {
      host = config.remoteConnection.enabled and config.remoteConnection.url or config.mobileHost,
      port = config.mobilePort,
      source = pSource
    }
    return mobile_adapter_controller.getAdapter("TCP", mobileAdapterParameters)
  end

  if pConId == nil then pConId = 1 end
  if pDevice == nil then pDevice = config.mobileHost end
  local filename = "mobile" .. pConId .. ".out"
  local mobileAdapter = getMobileAdapter(pDevice)
  local fileConnection = file_connection.FileConnection(filename, mobileAdapter)
  local connection = mobileConnection.MobileConnection(fileConnection)
  test.mobileConnections[pConId] = connection
  function connection:ExpectEvent(pEvent, pEventName)
    if pEventName == nil then pEventName = "noname" end
    local ret = expectations.Expectation(pEventName, self)
    ret.event = pEvent
    event_dispatcher:AddEvent(self, pEvent, ret)
    test:AddExpectation(ret)
    return ret
  end
  event_dispatcher:AddConnection(connection)
  local ret = connection:ExpectEvent(events.connectedEvent, "Connection started")
  ret:Do(function()
      common.cprint(35, "Mobile #" .. pConId .. " connected")
    end)
  connection:Connect()
  return ret
end

return common
