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

local requestParams = function( pAppId, pParam  )
if not pAppId then pAppId = 1 end
if not pParam then pParam =  "TEXT" end
return {
    syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0 },
    appName = "Test Application",
    appHMIType = {"DEFAULT"},
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appID = "1",
    ttsName = {{ text = "SyncProxyTester", type = pParam}},
    ngnMediaScreenAppName ="SPT",
    vrSynonyms = { "SyncProxyTester"},
    deviceInfo = {
        hardware = "hardware",
        firmwareRev = "firmwareRev",
        os = "os",
        osVersion = "osVersion",
        carrier = "carrier",
        maxNumberRFCOMMPorts = 5
    }
}
end

local onARparams = { application = {
    appName = "Test Application",
    ngnMediaScreenAppName ="SPT",
    policyAppID = "1",
    hmiDisplayLanguageDesired ="EN-US",
    isMediaApplication = true,
    appType = { "DEFAULT"}},
    ttsName = {{ text = "SyncProxyTester", type = pParam}},
    vrSynonyms = { "SyncProxyTester"}
}
   
--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pParam - type for ttsName
--! @return: none
--]]
function m.registerApp(pAppId, pParam, presultParam)
    if not pAppId then pAppId = 1 end
    if not pParam then pParam =  "TEXT" end
    if presultParam then presultParam { success = false, resultCode = "SUCCESS" } end
    m.getMobileSession(pAppId):StartService(7)
    :Do(function()
        local CorIdRegister = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface",requestParams())
        EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
        :Times(0)
        m.getHMIConnection(pAppId):ExpectNotification("BasicCommunication.OnAppRegistered", onARparams)
        m.getMobileSession(pAppId):ExpectResponse(CorIdRegister, presultParam)
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

--[[ @restorePreloadedPT: backup SDL .ini file
--! @parameters: none
--! @return: none
--]]
function m.restorePreloadedPT()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function m.duplicateAppName (pAppId, pAppName, pVrSynonyms)
    if not pAppId then pAppId = "2" end
    if not pAppName then pAppName = "Test Application2" end
    if not pVrSynonyms then pVrSynonyms = { "SyncProxyTester2"} end
    m.getMobileSession(pAppId):StartService(7)
    :Do(function()
        local CorIdRegister = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = pAppName,
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            vrSynonyms = pVrSynonyms,
            appID = pAppId
        })
        m.getMobileSession(pAppId):ExpectResponse(CorIdRegister, { success = false, resultCode = "DUPLICATE_NAME" })
    end)
end

return m
