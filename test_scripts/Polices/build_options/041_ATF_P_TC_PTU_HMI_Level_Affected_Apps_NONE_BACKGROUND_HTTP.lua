-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in NONE/BACKGROUND
--
-- Description:
-- SDL must change HMILevel of applications that are currently in 
-- NONE or BACKGROUND "default_hmi" from assigned policies in case of Policy Table Update.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- device is connected to SDL
-- Mobile application 1 is registered and is in BACKGROUND HMILevel 
--(SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- Mobile application 2 is registered and is in NONE HMILevel 
--(SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- appID_1 and appID_2 have just received the updated PT with new permissions.
-- 2. Performed steps
-- SDL->app_2: OnPermissionsChange
--
-- Expected:
-- 1) SDL->appID_2: OnHMIStatus(BACKGROUND) //as "default_hmi" from the newly assigned policies has value of BACKGROUND

---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ Local Variables ]]
local basic_ptu_file = "files/ptu.json"
local ptu_second_app_registered = "files/ptu2app.json"

local function PrepareJsonPTU(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": [
    "Base-4", "Location-1"
    ],
    "RequestType":[
    "TRAFFIC_MESSAGE_CHANNEL",
    "PROPRIETARY",
    "HTTP",
    "QUERY_APPS"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConsentDevice()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestIdgetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdgetMes)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AtLeast(1))
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_Backup_preloadedPT()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU(config.application2.registerAppInterfaceParams.appID, ptu_second_app_registered)
end

function Test:Precondition_RegisterAppBACKGROUND()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID2 = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:Precondition_RegisterAppNONE()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
  :Do(function()
      local correlationId2 = self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID3 = data.params.application.appID
        end)
      self.mobileSession2:ExpectResponse(correlationId2, { success = true, resultCode = "SUCCESS" })
      self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_UpdatePolicyAfterAddSecondApp_ExpectOnHMIStatusCall()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")

  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_second_app_registered,
    config.application3.registerAppInterfaceParams.appName,
    self.mobileSession2)
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel="BACKGROUND"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RemovePTUfiles()
  policyTable:Restore_preloaded_pt()
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test