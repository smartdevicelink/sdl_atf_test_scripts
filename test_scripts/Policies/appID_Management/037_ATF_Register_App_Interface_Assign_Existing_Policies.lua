------------- --------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Assign existing policies to the application which appID exists in LocalPT
--
-- Description:
-- SDL should apply Local PT permissions existing in "<appID>" from "app_policies" section
-- to this application in case it registers (sends RegisterAppInterface request) with the appID
-- that exists in Local Policy Table.
--
-- Preconditions:
-- 1. appID="456_abc" is not registered to SDL yet
-- 2. SDL.OnStatusUpdate = "UP_TO_DATE"
-- Steps:
-- 1. Register new application with appID="456_abc"
-- Default permissions are assigned in app_policies: "456_abc": "default"
-- "SetGlobalProperties" RPC is allowed for HMILevel = "NONE"
-- 2. Send "SetGlobalProperties" RPC and verifies that RPC is allowed
-- 3. Initiate a Policy Table Update and remove permission for "SetGlobalProperties" RPC
-- if HMILevel = "NONE" for "456_abc" application
-- 4. Send "SetGlobalProperties" RPC again and verifies RPC's respond status
--
-- Expected result:
-- Status of response: sucess = false, resultCode = "DISALLOWED"

---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTableSnapshot = require("user_modules/shared_testcases/testCasesForPolicyTableSnapshot")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_0.json")
end

function Test:StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:RegisterNewApp()
  config.application2.registerAppInterfaceParams.appName = "ABC Application"
  config.application2.registerAppInterfaceParams.fullAppID = "456_abc"
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "ABC Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data3)
      self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
    end)
end

function Test:CheckPermissions()
  local corId = self.mobileSession2:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})
  EXPECT_HMICALL("UI.SetGlobalProperties",{})
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_HMICALL("TTS.SetGlobalProperties",{}):Times(0)

  self.mobileSession2:ExpectResponse(corId, {success = true, resultCode = "SUCCESS" })
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_01.json")
end

function Test:CheckPermissions()
  local corId = self.mobileSession2:SendRPC("SetGlobalProperties" ,{ menuTitle = "Menu Title"})
  EXPECT_HMICALL("UI.SetGlobalProperties",{}):Times(0)
  EXPECT_HMICALL("TTS.SetGlobalProperties",{}):Times(0)
  self.mobileSession2:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
