--UNDONE
-- script is not working correctly due testCasesForPolicyTableSnapshot.lua is not ready yet
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Request PTU - an app registered is not listed in local PT
-- 
-- Description:
-- The policies manager must request an update to its local policy table when an appID of a registered app is not listed on the Local Policy Table. 
-- 1. Used preconditions: application with app_ID is not listed in LocalPT
-- 2. Performed steps: app_ID->SDL: RegisterAppInterface(params)
--
-- Expected result:
-- SDL->app_ID: SUCCESS: RegisterAppInterface()
-- SDL->HMI: OnAppRegistered(app_ID)
-- PTU sequence started: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- PTS is created by SDL.....//PTU started
-- Define the urls and an app to transfer PTU
-- SDL->app: OnSystemRequest()
--
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:Update_PolicyFlag("EXTENDED_POLICY", "EXTERNAL_PROPRIETARY")
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTENDED_POLICY","EXTERNAL_PROPRIETARY")
commonSteps:DeleteLogsFileAndPolicyTable()
--ToDo(VVVakulenko): shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Precondition ]]
--ToDo(VVVakulenko): shall be substituted to StopSDL when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
function Test.Precondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test.Precondition_StartSDL_FirstLifeCycle()
  StartSDL(config.pathToSDL, config.ExitOnCrash)

end

function Test:Precondition_InitHMI_FirstLifeCycle()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady_FirstLifeCycle()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test.Precondition_RestorePreloadedPT()
  testCasesForPolicyTable:Restore_preloaded_pt()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RegisterApp()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
    local corr_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function()
      self.HMIAppID = "1234567"
    end)
    self.mobileSession:ExpectResponse(corr_id, { success = true, resultCode = "SUCCESS" })
    self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

--ToDo: function in testCasesForPolicyTableSnapshot.lua is not implemented
function Test:TestStep_PTU_NotSuccessful_AppID_ListedPT_NewIgnCycle()
  local corr_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function()
      self.HMIAppID = "1234567"
   -- end)
    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
    testCasesForPolicyTableSnapshot:create_PTS(true, {
      config.application.registerAppInterfaceParams.appID,
        },
        {config.deviceMAC},
        {"1234567"}
      )

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("timeout_after_x_seconds")
      local seconds_between_retry = testCasesForPolicyTableSnapshot:get_data_from_PTS("seconds_between_retry")

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
        {
          file = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate",
          timeout = timeout_after_x_seconds,
          retry = seconds_between_retry
        })
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)
  self.mobileSession:ExpectResponse(corr_id, { success = true, resultCode = "SUCCESS"})
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postcondition_DESCRIPTION()
  commonFunctions:SDLForceStop(self)
end

return Test