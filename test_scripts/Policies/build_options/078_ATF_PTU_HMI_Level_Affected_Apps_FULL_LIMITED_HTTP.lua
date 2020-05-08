--In script two PTUs pass after each application is registered
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in FULL/LIMITED
--
-- Description:
-- The applications that are currently in FULL or LIMITED should remain in the
--same HMILevel in case of Policy Table Update
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- 2. Performed steps
-- Mobile application 1 is registered and is in FULL HMILevel
-- (SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- Mobile application 2 is registered and is in LIMITED HMILevel
--(SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- Expected result:
-- 1) Mobile application 1 remains in FULL
-- 2) Mobile application 2 remains in LIMITED
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ Local Variables ]]
local HMIAppID

-- Basic PTU file
local basic_ptu_file = "files/ptu.json"
-- PTU for first app
local ptu_first_app_registered = "files/ptu1app.json"
-- PTU for Second app
local ptu_second_app_registered = "files/ptu2app.json"

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4", "Location-1"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.fullAppID, ptu_first_app_registered)
  PrepareJsonPTU1(config.application2.registerAppInterfaceParams.fullAppID, ptu_second_app_registered)
end
--[[ end of Preconditions ]]

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      EXPECT_RESPONSE(correlationId, { success = true })
      EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

function Test:TestStep_ActivateAppInFull()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"FULL")
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) print("SDL -> MOB1: OnHMIStatus, level: " .. data.payload.hmiLevel) end)
end

function Test:TestStep_UpdatePolicyAfterAddFirstAp_ExpectOnHMIStatusNotCall()

  local CorIdSystemRequest1 = self.mobileSession:SendRPC("SystemRequest",
    {
      requestType = "HTTP",
      fileName = "ptu1app.json",
    },"files/ptu1app.json")
  self.mobileSession:ExpectResponse(CorIdSystemRequest1, {success = true, resultCode = "SUCCESS"})

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})

  self.mobileSession:ExpectNotification("OnPermissionsChange")
  -- Expect after updating HMI status will not change
  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  commonTestCases:DelayedExp(10000)
end

function Test:TestStep_RegisterSecondApp()
  local onsystemreq_app1 = false
  local onsystemreq_app2 = false
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      self.mobileSession1:ExpectResponse(correlationId, { success = true })
      self.mobileSession1:ExpectNotification("OnPermissionsChange")
    end)

  self.mobileSession1:ExpectNotification("OnSystemRequest"):Times(Between(0,1)) --HTTP
  :Do(function(_,data)
      print("SDL -> MOB2: OnSystemRequest, requestType: " .. data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(onsystemreq_app2 == true) then self:FailTestCase("OnSystemRequest(HTTP) has already received for application 1") end
        onsystemreq_app1 = true
      end
    end)

  self.mobileSession:ExpectNotification("OnSystemRequest"):Times(Between(0,1)) --HTTP
  :Do(function(_,data)
      print("SDL -> MOB1: OnSystemRequest, requestType: " .. data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(onsystemreq_app1 == true) then self:FailTestCase("OnSystemRequest(HTTP) has already received for application 2") end
        onsystemreq_app2 = true
      end
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)

  commonTestCases:DelayedExp(10000)
end

function Test:TestStep_ActivateSecondAppInLimited()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"LIMITED") -- function is working only for activate application in FULL
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) print("SDL -> MOB1: OnHMIStatus, level: " .. data.payload.hmiLevel) end)

  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data) print("SDL -> MOB2: OnHMIStatus, level: " .. data.payload.hmiLevel) end)
end

function Test:TestStep_UpdatePolicyAfterAddSecondApp_ExpectOnHMIStatusNotCall()

  local CorIdSystemRequest = self.mobileSession1:SendRPC("SystemRequest",
    {
      requestType = "HTTP",
      fileName = "ptu2app.json",
    },"files/ptu2app.json")
  self.mobileSession1:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})

  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  -- Expect after updating HMI status will not change
  self.mobileSession1:ExpectNotification("OnHMIStatus"):Times(0)
  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RemovePTUfiles()
  os.remove(ptu_first_app_registered)
  os.remove(ptu_second_app_registered)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
