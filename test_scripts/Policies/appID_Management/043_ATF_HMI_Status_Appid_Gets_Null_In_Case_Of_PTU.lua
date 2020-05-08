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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appName = "App1"
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application2.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

local HMIAppID
--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
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
  config.application2.registerAppInterfaceParams.fullAppID = "123_xyz"
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
  --testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_013_2.json")
  local policy_file_name = "PolicyTableUpdate"
  local file = "files/jsons/Policies/appID_Management/ptu_013_2.json"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
  {
    file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
  })
  :Do(function(_, data1)
    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATING" }, { status = "UP_TO_DATE" }):Times(2)
    self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
    local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    EXPECT_HMIRESPONSE(requestId)
    :Do(function()
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })

        local request_received = false

        -- Steps in case OnSystemRequest is sent to application 1
        self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" }):Times(Between(0,1))
        :Do(function()
            print("OnSystemRequest for App1 is received")
            if(request_received == true) then
              self:FailTestCase("OnSystemRequest already received for application 2")
            end
            request_received = true
            local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, file)
            self.mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          end)

        -- Steps in case OnSystemRequest is sent to application 2
        self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" }):Times(Between(0,1))
        :Do(function()
            print("OnSystemRequest for App2 is received")
            if(request_received == true) then
              self:FailTestCase("OnSystemRequest already received for application 1")
            end
            request_received = true
            local corIdSystemRequest = self.mobileSession2:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, file)
            self.mobileSession2:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          end)

        EXPECT_HMICALL("BasicCommunication.SystemRequest",{requestType = "PROPRIETARY", fileName = policy_file_path.."/"..policy_file_name },file)
        :Do(function(_, data)
            self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
            self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path.."/"..policy_file_name} )
          end)
      end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", { appID = HMIAppID, appRevoked = true})
  EXPECT_HMICALL("BasicCommunication.CloseApplication", {})
  :Do(function(_, data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)
  self.mobileSession2:ExpectNotification("OnHMIStatus", { hmiLevel ="NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
