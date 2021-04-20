---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local sslCommon = require("test_scripts/Security/SSLHandshakeFlow/common")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local constants = require('protocol_handler/ford_protocol_constants')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.fullAppID = "spt"
constants.FRAME_SIZE["P2"] = 1400

--[[ Variables ]]
local m = actions
local failedTCs = { }

m.cloneTable = utils.cloneTable
m.spairs = utils.spairs
m.cprint = utils.cprint
m.wait = utils.wait
m.printTable = utils.printTable

--[[ Common Functions ]]
function m.updatePreloadedPT(pAppPolicy, pFuncGroup)
  local function pPTUpdateFunc(pPT)
    pPT.policy_table.functional_groupings["Base-4"].encryption_required = pFuncGroup
    pPT.policy_table.app_policies["spt"] = utils.cloneTable(pPT.policy_table.app_policies.default)
    pPT.policy_table.app_policies["spt"].encryption_required = pAppPolicy
  end
  m.preloadedPTUpdate(pPTUpdateFunc)
end

function m.getAddCommandParams(pCmdId)
  return {
    cmdID = pCmdId,
    menuParams = {
      position = pCmdId,
      menuName = "Command_" .. pCmdId
    }
  }
end

function m.unprotectedRpcInUnprotectedModeSuccess()
  local cid = m.getMobileSession():SendRPC("AddCommand", m.getAddCommandParams(1))
  m.getHMIConnection():ExpectRequest("UI.AddCommand", m.getAddCommandParams(1))
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectNotification("OnHashChange")
end

function m.switchRPCServiceToProtected()
  local serviceId = 7
  m.getMobileSession():StartSecureService(serviceId)
  m.getMobileSession():ExpectHandshakeMessage()
  m.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

function m.spairs(pTbl)
  local keys = {}
  for k in pairs(pTbl) do
    keys[#keys+1] = k
  end
  local function getStringKey(pKey)
    if type(pKey) == "number" then
      return tostring(string.format("%03d", pKey))
    end
    return pKey
  end
  table.sort(keys, function(a, b) return getStringKey(a) < getStringKey(b) end)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], pTbl[keys[i]]
    end
  end
end

function m.cleanSessions()
  for i = 1, m.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
end

function m.ignitionOff()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, m.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      config.ExitOnCrash = true
    end)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, m.getAppsCount() do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

function m.reRegisterAppSuccess(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = utils.cloneTable(m.getConfigAppParams(pAppId))
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

local preconditionsOrig = m.preconditions
function m.preconditions(ptUpdateFunc)
  preconditionsOrig(ptUpdateFunc)
  sslCommon.initSDLCertificates("./files/Security/client_credential.pem")
end

function m.subscribeToVD()
  local cid = m.getMobileSession():SendRPC("SubscribeVehicleData", { speed = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { speed = true })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS" }})
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.printFailedTCs()
  for tc, msg in m.spairs(failedTCs) do
    local e = string.find(msg, "\n")
    if e > 80 then e = 80 end
    m.cprint(35, string.format("%03d", tc), string.sub(msg, 1, e - 1) .. " ...")
  end
end

function m.getExp(pApp, pFG)
  local app = pApp
  local fg = nil
  if pFG == true and pApp ~= false then fg = true end
  return app, fg
end

function m.getTransitions(pStates, pStart, pFinish)
  local out = {}
  local n = 0
  for i = 1, #pStates do
    for j = 1, #pStates do
      n = n + 1
      if n >= pStart and n <= pFinish then
        table.insert(out, { from = i, to = j })
      end
    end
  end
  return out
end

function m.updatePreloadedPTSpecific(pRpcConfig, pAppPolicy, pFuncGroups)
  local function pPTUpdateFunc(pTbl)
    local pt = pTbl.policy_table
    for fg, item in pairs(pRpcConfig) do
      pt.functional_groupings[fg] = { rpcs = { } }
      if item.isEncFlagDefined == true then
        pt.functional_groupings[fg].encryption_required = pFuncGroups[fg]
      end
      for _, rpc in pairs(item.rpcs) do
        pt.functional_groupings[fg].rpcs[rpc] = {
          hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
        }
      end
    end
    pt.functional_groupings["Base-4"].encryption_required = nil
    pt.app_policies["default"].encryption_required = pAppPolicy
    pt.app_policies["default"].groups = {}
    for fg in m.spairs(pRpcConfig) do
      table.insert(pt.app_policies["default"].groups, fg)
    end
  end
  m.preloadedPTUpdate(pPTUpdateFunc)
end

function m.checkOnPermissionsChange(pRpcConfig, pExpApp, pExpRPC, pActPayload, pTC)
  local function isItemInArray(pItem, pArray)
    for _, i in pairs(pArray) do
      if i == pItem then return true end
    end
    return false
  end
  local function getRPCs(pIsEncFlagDefined)
    local out = {}
    for _, item in pairs(pRpcConfig) do
      for _, rpc in pairs(item.rpcs) do
        if not (pIsEncFlagDefined ~= nil and pIsEncFlagDefined ~= item.isEncFlagDefined )
          and not isItemInArray(rpc, out) then
          table.insert(out, rpc)
        end
      end
    end
    return out
  end
  local msg = ""
  -- check 'encryption' flag on Top level
  if pActPayload.requireEncryption ~= pExpApp then
    msg = msg .. "Expected 'requireEncryption' on a Top level " .. "'" .. tostring(pExpApp) .. "'"
      .. ", actual " .. "'" .. tostring(pActPayload.requireEncryption) .. "'\n"
  end
  -- check 'encryption' flag value for expected RPCs on Item level
  for _, rpc in pairs(getRPCs()) do
    local permItem = nil
    for _, v in pairs(pActPayload.permissionItem) do
      if v.rpcName == rpc then permItem = v end
    end
    if permItem == nil then
      msg = msg .. "Expected " .. rpc .. " is not found on an Item level\n"
    else
      local encAct = permItem.requireEncryption
      local encExp = pExpRPC
      if isItemInArray(rpc, getRPCs(false)) then encExp = nil end
      if encAct ~= encExp then
        msg = msg .. "Expected 'requireEncryption' on an Item level for '" .. rpc .. "': "
          .. "'" .. tostring(encExp) .. "'"
          .. ", actual " .. "'" .. tostring(encAct) .. "'\n"
      end
    end
  end
  -- check absence of unexpected RPCs on Item level
  for _, item in pairs(pActPayload.permissionItem) do
    if not isItemInArray(item.rpcName, getRPCs()) then
      msg = msg .. "Unexpected " .. item.rpcName .. " is found on an Item level\n"
    end
  end
  if string.len(msg) > 0 then
    if pTC then failedTCs[pTC] = msg end
    return false, string.sub(msg, 1, -2)
  end
  return true
end

local policyTableUpdate_Orig = m.policyTableUpdate
function m.policyTableUpdateSpecific(pRpcConfig, pNotifQty, pUpdateFunc, pExpApp, pExpRPC, pTC)
  local function expNotificationFunc()
    m.defaultExpNotificationFunc()
    m.getMobileSession():ExpectNotification("OnPermissionsChange")
    :ValidIf(function(e, data)
        if e.occurences == 1 and pNotifQty ~= 0 then
          return m.checkOnPermissionsChange(pRpcConfig, pExpApp, pExpRPC, data.payload, pTC)
        end
        return true
      end)
    :Times(pNotifQty)
  end
  policyTableUpdate_Orig(pUpdateFunc, expNotificationFunc)
  m.wait(1000)
end

function m.policyTableUpdate(pUpdateFunc, expNotificationFunc)
  m.getMobileSession():ExpectNotification("OnPermissionsChange")
  policyTableUpdate_Orig(pUpdateFunc, expNotificationFunc)
end

return m
