---------------------------------------------------------------------------------------------------
-- Navigation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
-- config.SecurityProtocol = "DTLS"
-- config.cipherListString = ":SSLv2:AES256-GCM-SHA384"

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local common = require('test_scripts/TheSameApp/commonTheSameApp')
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local constants = require('protocol_handler/ford_protocol_constants')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

constants.FRAME_SIZE["P9"] = 131084 -- add unsupported SDL protocol version
config.SecurityProtocol = "DTLS"
config.serverCertificatePath = "./files/Security/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/spt_credential.pem"

--[[ Module ]]
local m = actions
m.frameInfo   = constants.FRAME_INFO
m.frameType   = constants.FRAME_TYPE
m.serviceType = constants.SERVICE_TYPE
m.readFile    = utils.readFile

--[[ Functions ]]
function common.protectedModeRPC(pAppId, pParams)
  local cid = common.getMobileSession(pAppId):SendEncryptedRPC("AddCommand", pParams)
  common.hmi.getConnection():ExpectRequest("UI.AddCommand", pParams)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession(pAppId):ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession(pAppId):ExpectEncryptedNotification("OnHashChange")
end

function common.nonProtectedRPC(pAppId, pRPCParams, pAppInProtectedMode)
  local cid = common.getMobileSession(pAppId):SendRPC("AddCommand", pRPCParams)
      common.hmi.getConnection():ExpectRequest("UI.AddCommand", pRPCParams)
  :Do(function(_, data)
       common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  if not pAppInProtectedMode then
    common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  else common.getMobileSession(pAppId):ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  end
end

--[[ @startServiceProtected: start (or switch) service in protected mode
--! @parameters:
--! pServiceId - service id
--! @return: none
--]]
function m.startServiceProtected(pServiceId, pAppId)
  m.getMobileSession(pAppId):StartSecureService(pServiceId)
  m.getMobileSession(pAppId):ExpectHandshakeMessage()
  m.getMobileSession(pAppId):ExpectControlMessage(pServiceId, {
    frameInfo = m.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

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
                      m.mobile.allowSDL()
                    end)
                end)
            end)
        end)
    end)
end

--[[ @ptUpdate: add certificate to policy table
--! @parameters:
--! pTbl - policy table to update
--! @return: none
--]]
function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = utils.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

local policyTableUpdate_orig = m.policyTableUpdate

function m.policyTableUpdate(pPTUpdateFunc)
  local function expNotificationFunc()
    m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
    :Do(function(_, d)
        m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
      end)
    :Times(AnyNumber())
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  policyTableUpdate_orig(pPTUpdateFunc, expNotificationFunc)
end

--////////////////////////////////////
--// Most common functions
--////////////////////////////////////
function m.cleanUpCertificates()
  local sdlBin = commonPreconditions:GetPathToSDL()
  os.execute("cd " .. sdlBin .. " && find . -type l -not -name 'lib*' -exec rm -f {} \\;")
  os.execute("cd " .. sdlBin .. " && rm -rf *.pem")
end

local postconditionsOrig = m.postconditions
function m.postconditions()
  postconditionsOrig()
  m.cleanUpCertificates()
end

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  m.initSDLCertificates("./files/Security/client_credential.pem", false)
end

local function saveFile(pContent, pFileName)
  local f = io.open(pFileName, "w")
  f:write(pContent)
  f:close()
end

local function createCrtHashes()
  local sdlBin = commonPreconditions:GetPathToSDL()
  os.execute("cd " .. sdlBin .. " && c_rehash .")
end

local function updateSDLIniFile()
  m.setSDLIniParameter("KeyPath", "module_key.pem")
  m.setSDLIniParameter("CertificatePath", "module_crt.pem")
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

return m
