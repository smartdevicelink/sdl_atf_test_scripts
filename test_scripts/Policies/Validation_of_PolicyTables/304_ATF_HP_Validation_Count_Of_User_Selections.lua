---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]"usage_and_error_counts" and "count_of_user_selections" update
--
-- Description:
-- Policy Manager must update "count_of_user_selections" section of Local Policy Table for the corresponding application on the following conditions:
-- 1. Increment "count_of_user_selections" when app starts via Mobile Apps Menu or VR.
-- 2. Increment "count_of_user_selections" when the first time the app leaves it's default_hmi for HMI_FULL, as in the resuming app scenario.
-- Note: Do not increment anytime an app comes into HMI_FULL and when cycling sources. For all above, both successful and unsuccessful app starts shall be counted.
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) App successfylly registered on consented device and activated
-- 2. Performed steps
-- a) Activate and deactivate app several times
-- b) Initiate PTS creation
--
-- Expected result:
-- a) "count_of_user_selections" in PTS is equal actual numbers of app activation
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local utils = require ('user_modules/utils')
require('user_modules/AppTypes')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local appID = config.application1.registerAppInterfaceParams["fullAppID"]
local countAppActivation = 0

--[[ Preconditions ]]
function Test:Precondition_Activate_App_Consent_Device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AtLeast(1))
        end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  :Do(function()
      countAppActivation = 1
    end)
end

function Test:Precondition_Deactivate_App()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED"})
end

function Test:Precondition_Activate_App()
  self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})
  :Do(function()
      countAppActivation = countAppActivation + 1
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Get_New_PTS_And_Check_Counter()
  local query = "select count_of_user_selections from app_level where application_id = '" .. appID .. "'"
  local CountOfRejectionsDuplicateName = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)[1]
  if CountOfRejectionsDuplicateName == tostring(countAppActivation) then
    return true
  else
    self:FailTestCase("Wrong count_of_user_selections. Expected: " .. countAppActivation .. ", Actual: " .. CountOfRejectionsDuplicateName)
  end
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Postcondition_StopSDL()
  StopSDL()
end
