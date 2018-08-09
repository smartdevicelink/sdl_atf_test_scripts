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

--[[ Module ]]
local m = actions

--[[ @registerApp: register mobile application
--! @parameters: none
--! @return: none
--]]
function m.registerApp()
    m.getMobileSession():StartService(7)
    :Do(function()
        local CorIdRegister = m.getMobileSession():SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = "Test Application",
            appHMIType = {"DEFAULT"},
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "1",
            ttsName = {{ text = "SyncProxyTester", type = "TEXT"}},
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
        })
        m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",{ application = {
            appName = "Test Application",
            ngnMediaScreenAppName ="SPT",
            policyAppID = "1",
            hmiDisplayLanguageDesired ="EN-US",
            isMediaApplication = true,
            appType = { "DEFAULT"}},
            ttsName = {{ text = "SyncProxyTester", type = "TEXT"}},
            vrSynonyms = { "SyncProxyTester"}
        })
        m.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            m.getMobileSession():ExpectNotification("OnHMIStatus",
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
        m.getMobileSession():ExpectNotification("OnPermissionsChange")
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

return m
