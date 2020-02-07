---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Module ]]
local m = actions

m.frameInfo = security.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile
local preconditionsOrig = m.preconditions
local postconditionsOrig = m.postconditions

--[[ Variables ]]
m.ackData = {
  frameInfo = m.frameInfo.START_SERVICE_ACK,
  encryption = true
}
m.nackData = {
  frameInfo = m.frameInfo.START_SERVICE_NACK,
  encryption = false
}

--[[ Functions ]]
local function registerGetSystemTimeNotification()
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
  m.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, d)
      local function getSystemTime()
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
      m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { systemTime = getSystemTime() })
    end)
  :Times(AnyNumber())
  :Pin()
end

local startOrig = m.start

function m.start(pHMIParams)
	startOrig(pHMIParams)
	:Do(function()
			registerGetSystemTimeNotification()
		end)
end

function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).fullAppID
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

function m.preloadedPTUpdate(pPTUpdateFunc)
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  if pPTUpdateFunc then pPTUpdateFunc(pt) end
  actions.sdl.setPreloadedPT(pt)
end

function m.preconditions(pPTUpdateFunc)
  preconditionsOrig()
  m.cleanUpCertificates()
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
end

function m.policyTableUpdateSuccess(pPTUpdateFunc)
  m.isPTUStarted()
  :Do(function()
      m.policyTableUpdate(pPTUpdateFunc)
    end)
end

local registerAppOrigin = m.registerApp

function m.registerApp(pAppId, pExpFunc)
  registerAppOrigin(pAppId)
  if pExpFunc then
    pExpFunc()
  end
end

function m.ptUpdateWOcert(pTbl)
  pTbl.policy_table.module_config.certificate = nil
end

function m.ptUpdateFuncWithCert(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = m.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

function m.startServiceSecured(pAppId, pServiceId,  pData, pPTUpdateFunc)
  if not pPTUpdateFunc then pPTUpdateFunc = m.ptUpdateFuncWithCert end

  m.getMobileSession(pAppId):StartSecureService(pServiceId)
  m.getMobileSession(pAppId):ExpectControlMessage(pServiceId, pData)

  local handshakeOccurences = 0
  if pData.encryption == true then
    handshakeOccurences = 1
  end
  m.getMobileSession(pAppId):ExpectHandshakeMessage()
  :Times(handshakeOccurences)

  local function expNotificationFunc()
    m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
  end

  m.policyTableUpdateSuccess(pPTUpdateFunc, expNotificationFunc)
  m.delayedExp()
end

function m.startServiceSecuredUnsuccess(pServiceId, pData, pPTUpdateFunc)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)
  m.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  local function expNotificationFunc()
    m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UPDATE_NEEDED" })
    :Times(3)
  end

  m.policyTableUpdate(pPTUpdateFunc, expNotificationFunc)
  m.delayedExp()
end

return m
