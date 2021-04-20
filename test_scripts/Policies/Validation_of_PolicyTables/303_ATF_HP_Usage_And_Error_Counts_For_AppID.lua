---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and <app id> policies
--
-- Description:
-- Policy Manager must verify that Local Policy Table has section for each unique
-- <app id> which contains app identifier of each application to which policies are applied (including null, default and "pre_DataConsented" policies).
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) App successfylly registered
-- 2. Performed steps
-- a) Activate app and check registered app in usage_and_error_counts section in PTS
--
-- Expected result:
-- a) App present in usage_and_error_counts section in PTS
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
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local pathToSnapshot
local appID = config.application1.registerAppInterfaceParams["fullAppID"]

--[[ Local Functions ]]
local function isAppPresentInUsageAndErrorCountsSection(pathToFile)
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  if next(data.policy_table.usage_and_error_counts.app_level, nil) == appID then return true
  else return false
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Activate_App_Consent_Device_And_Check_Error_Count_For_App_In_PTS()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
           :Do(function(_,data1)
              self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
             :Times(AtLeast(1))
        end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf(function(_,data)
      pathToSnapshot = data.params.file
      return isAppPresentInUsageAndErrorCountsSection(pathToSnapshot)
    end)
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Postcondition_StopSDL()
  StopSDL()
end
