---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [HMI Status]: The <appID> param in Policies gets 'null' value in case of PTU
--
-- Description:
-- SDL should send OnHMIStatus (NONE, MAIN, NOT_AUDIBLE) to app
-- in case this app is currently in any HMILevel other than in NONE
-- and in result of PTU "<appID>" gets "null" policies
--
-- Preconditions:
-- 1. appID="123_xyz" is not registered to SDL yet
-- 2. appID="123_xyz" has NOT null policies
-- 3. appID="123_xyz" in FULL

-- Steps:
-- 1. After PTU appID="123_xyz" gets "null" policies
-- 2. Verify status of OnHMIStatus notification
--
-- Expected result:
-- OnHMIStatus: hmiLevel="NONE", systemContext="MAIN", audioStreamingState="NOT_AUDIBLE"
--
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

local HMIAppID
--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_013_1.json")
end

function Test:StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNewApp()
  config.application2.registerAppInterfaceParams.appName = "Media Application"
  config.application2.registerAppInterfaceParams.appID = "123_xyz"
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
      self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  self.mobileSession2:ExpectResponse(correlationId, { success = true })
end

function Test:ActivateApp()
  self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID})
  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_UpdatePolicy()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_013_2.json")
  self.mobileSession2:ExpectNotification("OnHMIStatus", { hmiLevel ="NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
end

return Test
