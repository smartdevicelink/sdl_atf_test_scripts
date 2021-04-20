---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Application groups checking order

-- Description:
-- Application registers on device for which there's no User permissions
-- 1. Used preconditions:
-- Delete log files and policy table from previous ign cycle
-- Overwrite preloaded PT with specific grups in pre_consented
-- Connect device
--
-- 2. Performed steps
-- Register application
--
-- Expected result:
-- App should have only "pre_DataConsent" groups allowed
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/user_consent/pre_dataconsent.json")
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_RAI.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_RAI')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Local variables:
--@arrayRegisterNewApp - pre_consented premissions ]]
local arrayRegisterNewApp = {
  permissionItem =
  {
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "ChangeRegistration"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "DeleteFile"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "EncodedSyncPData"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "ListFiles"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnAppInterfaceUnregistered"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnEncodedSyncPData"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnHMIStatus"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnHashChange"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnLanguageChange"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnPermissionsChange"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "OnSystemRequest"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "PutFile"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "RegisterAppInterface"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "ResetGlobalProperties"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "SetAppIcon"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "SetDisplayLayout"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "SetGlobalProperties"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "SystemRequest"
    },
    {
      hmiPermissions = {
        userDisallowed = {},
        allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      parameterPermissions = {
        userDisallowed = {},
        allowed = {}
      },
      rpcName = "UnregisterAppInterface"
    }
  }
}

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConnectDevice()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterApp_PreConsented_group()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      self.mobileSession:ExpectNotification("OnPermissionsChange", arrayRegisterNewApp )
    end)
end

function Test:SendRPC_Alert_DISALLOWED()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_PutFile_SUCCESS()
  local CorIdPutFile = self.mobileSession:SendRPC("PutFile",
    {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false,
    }, "files/icon.png")

  EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
