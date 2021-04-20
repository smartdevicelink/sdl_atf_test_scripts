---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local sslCommon = require("test_scripts/Security/SSLHandshakeFlow/common")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions

--[[ Variables ]]
m.frameInfo = sslCommon.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile
m.initSDLCertificates = sslCommon.initSDLCertificates
m.policyTableUpdateSuccess = sslCommon.policyTableUpdateSuccess
m.postconditions = sslCommon.postconditions
m.preconditions = sslCommon.preconditions
m.preloadedPTUpdate = sslCommon.preloadedPTUpdate
m.cleanUpCertificates = sslCommon.cleanUpCertificates
m.start = sslCommon.start
m.ackData = {
  frameInfo = m.frameInfo.START_SERVICE_ACK,
  encryption = true
}
m.nackData = {
  frameInfo = m.frameInfo.START_SERVICE_NACK,
  encryption = false
}

--[[ Functions ]]
function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.ptUpdateWOcert(pTbl)
  pTbl.policy_table.module_config.certificate = nil
end

function m.ptUpdateFuncWithCert(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = m.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

function m.startServiceSecured(pServiceId, pData, pPTUpdateFunc)
  if not pPTUpdateFunc then pPTUpdateFunc = m.ptUpdateFuncWithCert end

  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)

  local handshakeOccurences = 0
  if pData.encryption == true then
    handshakeOccurences = 1
  end
  m.getMobileSession():ExpectHandshakeMessage()
  :Times(handshakeOccurences)

  local function expNotificationFunc()
    m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
  end

  m.policyTableUpdateSuccess(pPTUpdateFunc, expNotificationFunc)
  m.delayedExp()
end

function m.startServiceSecuredUnsuccess(pServiceId, pData)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)
  m.getMobileSession():ExpectHandshakeMessage()
  :Times(0)

  local function ptUpdateFunc(pTbl)
    pTbl.policy_table.module_config.seconds_between_retries = nil
  end

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UPDATE_NEEDED" })
  :Times(3)

  m.isPTUStarted()
  :Do(function()
      m.policyTableUpdate(ptUpdateFunc, function() end)
    end)
  m.delayedExp()
end

return m
