---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local constants = require("protocol_handler/ford_protocol_constants")
local events = require("events")
local json = require("modules/json")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"

--[[ Module ]]
local m = actions

m.frameInfo = security.frameInfo
m.readFile = utils.readFile

--[[ Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Functions ]]
local function getSystemTimeValue()
  local dd = os.date("*t")
  return {
    millisecond = 0,
    second = dd.sec,
    minute = dd.min,
    hour = dd.hour,
    day = dd.day,
    month = dd.month,
    year = dd.year,
    tz_hour = 2,
    tz_minute = 0
  }
end

local function registerGetSystemTimeResponse()
  actions.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { systemTime = getSystemTimeValue() })
    end)
  :Pin()
  :Times(AnyNumber())
end

function m.allowSDL()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  m.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
  RUN_AFTER(function() m.getHMIConnection():RaiseEvent(event, "Allow SDL event") end, 500)
  return m.getHMIConnection():ExpectEvent(event, "Allow SDL event")
end

function m.start()
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          local rid = actions.getHMIConnection():SendRequest("MB.subscribeTo", {
            propertyName = "BasicCommunication.OnSystemTimeReady" })
          actions.getHMIConnection():ExpectResponse(rid)
          :Do(function()
              utils.cprint(35, "HMI initialized")
              test:initHMI_onReady()
              :Do(function()
                  utils.cprint(35, "HMI is ready")
                  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
                  registerGetSystemTimeResponse()
                  test:connectMobile()
                  :Do(function()
                      utils.cprint(35, "Mobile connected")
                      m.allowSDL()
                    end)
                end)
            end)
        end)
    end)
end

function m.sendAddCommandProtected()
  local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = m.getMobileSession():SendEncryptedRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  m.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

function m.activateAppProtected()
  local rid = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId() })
  m.getHMIConnection():ExpectResponse(rid)
  m.getMobileSession():ExpectEncryptedNotification("OnHMIStatus", {
    hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function saveFile(pContent, pFileName)
  local f = io.open(pFileName, "w")
  f:write(pContent)
  f:close()
end

local function getAllCrtsFromPEM(pCrtsFileName)
  local crts = utils.readFile(pCrtsFileName)
  local o = {}
  local i = 1
  local s = crts:find("-----BEGIN RSA PRIVATE KEY-----", i, true)
  local _, e = crts:find("-----END RSA PRIVATE KEY-----", i, true)
  o.key = crts:sub(s, e) .. "\n"
  for _, v in pairs({ "crt", "rootCA", "issuingCA" }) do
    i = e
    s = crts:find("-----BEGIN CERTIFICATE-----", i, true)
    _, e = crts:find("-----END CERTIFICATE-----", i, true)
    o[v] = crts:sub(s, e) .. "\n"
  end
  return o
end

local function createCrtHashes()
  local sdlBin = commonPreconditions:GetPathToSDL()
  os.execute("cd " .. sdlBin .. " && c_rehash .")
end

local function updateSDLIniFile()
  m.setSDLIniParameter("KeyPath", "module_key.pem")
  m.setSDLIniParameter("CertificatePath", "module_crt.pem")
end

function m.initSDLCertificates(pCrtsFileName, pIsModuleCrtDefined)
  if pIsModuleCrtDefined == nil then pIsModuleCrtDefined = true end
  local allCrts = getAllCrtsFromPEM(pCrtsFileName)
  local sdlBin = commonPreconditions:GetPathToSDL()
  saveFile(allCrts.rootCA, sdlBin .. "rootCA.pem")
  saveFile(allCrts.issuingCA, sdlBin .. "issuingCA.pem")
  createCrtHashes()
  if pIsModuleCrtDefined then
    saveFile(allCrts.key, sdlBin .. "module_key.pem")
    saveFile(allCrts.crt, sdlBin .. "module_crt.pem")
  end
  updateSDLIniFile()
end

function m.cleanUpCertificates()
  local sdlBin = commonPreconditions:GetPathToSDL()
  os.execute("cd " .. sdlBin .. " && find . -type l -not -name 'lib*' -exec rm -f {} \\;")
  os.execute("cd " .. sdlBin .. " && rm -rf *.pem")
end

local preconditionsOrig = m.preconditions
local postconditionsOrig = m.postconditions

function m.preloadedPTUpdate(pPTUpdateFunc)
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  if pPTUpdateFunc then pPTUpdateFunc(pt) end
  utils.tableToJsonFile(pt, preloadedFile)
end

function m.preconditions(pPTUpdateFunc)
  preconditionsOrig()
  m.cleanUpCertificates()
  commonPreconditions:BackupFile(preloadedPT)
  if pPTUpdateFunc == nil then
    pPTUpdateFunc = function(pPT)
      pPT.policy_table.app_policies["default"].encryption_required = true
      pPT.policy_table.functional_groupings["Base-4"].encryption_required = true
    end
  end
  m.preloadedPTUpdate(pPTUpdateFunc)
end

function m.postconditions()
  postconditionsOrig()
  m.cleanUpCertificates()
  commonPreconditions:RestoreFile(preloadedPT)
end

function m.defaultExpNotificationFunc()
  m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
  :Do(function(_, d)
      m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
      utils.wait(1000) -- time for SDL to save certificates
    end)
  :Times(AnyNumber())
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
end

local policyTableUpdateOrig = m.policyTableUpdate
function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  local func = m.defaultExpNotificationFunc
  if pExpNotificationFunc then func = pExpNotificationFunc end
  policyTableUpdateOrig(pPTUpdateFunc, func)
end

function m.policyTableUpdateSuccess(pPTUpdateFunc)
  m.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(e, d)
      if e.occurences == 1 then
        m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
        m.policyTableUpdate(pPTUpdateFunc)
      end
    end)
end

local function registerStartSecureServiceFunc(pMobSession)
  function pMobSession.mobile_session_impl.control_services:StartSecureService(pServiceId, pPayload)
    local msg = {
      serviceType = pServiceId,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      sessionId = self.session.sessionId.get(),
      encryption = true,
      binaryData = pPayload
    }
    self:Send(msg)
  end
  function pMobSession.mobile_session_impl:StartSecureService(pServiceId, pPayload)
    if not self.isSecuredSession then
      self.security:registerSessionSecurity()
      self.security:prepareToHandshake()
    end
    return self.control_services:StartSecureService(pServiceId, pPayload)
  end
  function pMobSession:StartSecureService(pServiceId, pPayload)
    return self.mobile_session_impl:StartSecureService(pServiceId, pPayload)
  end
end

local origGetMobileSession = actions.getMobileSession
function actions.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  if not test.mobileSession[pAppId] then
    local session = origGetMobileSession(pAppId)
    registerStartSecureServiceFunc(session)
  end
  return origGetMobileSession(pAppId)
end

return m
