---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local test = require("user_modules/dummy_connecttest")
local json = require("modules/json")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Module ]]
local m = actions

--[[ @getRequestParams: parameters for RAI request
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.getRequestParams(pAppId)
  local pParams = m.getConfigAppParams(pAppId)
  pParams.ttsName = {{ text = "SyncProxyTester" .. pAppId, type = "TEXT"}}
  pParams.ngnMediaScreenAppName ="SPT" .. pAppId
  pParams.vrSynonyms = { "SyncProxyTester" .. pAppId}
  return pParams
end

--[[ @getOnAppRegisteredParams: parameters for OnAppRegistered
--! @parameters:
--! pParam - params for RAI request
--! @return: none
--]]
local function getOnAppRegisteredParams(pParams)
  local out = {
    application = {
      appName = pParams.appName,
      ngnMediaScreenAppName = pParams.ngnMediaScreenAppName,
      policyAppID = pParams.policyAppID,
      hmiDisplayLanguageDesired = pParams.hmiDisplayLanguageDesired,
      isMediaApplication = pParams.isMediaApplication,
      appType = pParams.appType,
    },
    ttsName = pParams.ttsName,
    vrSynonyms = pParams.vrSynonyms
  }
  return out
end

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pParam - params for RAI request
--! pResultCode - result code in RAI response
--! pSystemSoftwareVersion - systemSoftwareVersion in RAI response
--! @return: none
--]]
function m.registerApp(pAppId, pParams, pResultCode, pSystemSoftwareVersion)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local CorIdRegister = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", pParams)
      EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
      :Times(0)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        getOnAppRegisteredParams(pParams))
      m.getMobileSession(pAppId):ExpectResponse(CorIdRegister,
        { success = true, resultCode = pResultCode, systemSoftwareVersion = pSystemSoftwareVersion })
      :Do(function()
          m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
end

--[[ @unregisterAppInterface: Mobile application unregistration
--! @parameters: none
--! @return: none
--]]
function m.unregisterAppInterface()
  local mobSession = m.getMobileSession()
  local corId = mobSession:SendRPC("UnregisterAppInterface", { })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
    appID = m.getHMIAppId(), unexpectedDisconnect = false
  })
  mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ @cleanSessions: close count of registered applications
--! @parameters: none
--! @return: none
--]]
function m.cleanSessions()
    for i = 1, m.getAppsCount() do
      test.mobileSession[i]:Stop()
      test.mobileSession[i] = nil
    end
    utils.wait()
end

--[[ @backupINIFile: backup SDL .ini file
--! @parameters: none
--! @return: none
--]]
function m.backupINIFile()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
end

--[[ @restoreINIFile: backup SDL .ini file
--! @parameters: none
--! @return: none
--]]
function m.restoreINIFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

--[[ @unsuccessRAI: unsuccessful RAI
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pParam - params for RAI request
--! pResultCode - result code in RAI response
--! @return: none
--]]
function m.unsuccessRAI(pAppId, pParams, pResultCode)
  if not pAppId then pAppId = 2 end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local CorIdRegister = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", pParams)
      m.getMobileSession(pAppId):ExpectResponse(CorIdRegister,
        { success = false, resultCode = pResultCode })
    end)
end

return m
