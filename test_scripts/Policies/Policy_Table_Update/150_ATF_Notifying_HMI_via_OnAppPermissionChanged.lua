---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Notifying HMI via OnAppPermissionChanged about the affected application
--
-- Description:
-- PoliciesManager must initiate sending SDL.OnAppPermissionChanged{appID} notification to HMI IN CASE the Updated PT resulted any changes in the appID app`s policies.
-- Preconditions:
-- 1.SDL and HMI are running
-- 2.AppID_1 is connected to SDL.
-- 3.The device the app is running on is consented
-- 4.Policy Table Update procedure is on stage waiting for:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- 'policyfile' corresponds to PTU validation rules
-- Steps:
-- Request policy update via HMI:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)

-- Expected result:
-- 1.PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields and everything that is defined with related requirements)
-- 2.On validation success:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3.SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU:
-- module_config,
-- functional_groupings,
-- app_policies
-- 4.SDL removes 'policyfile' from the directory
-- 5.SDL->app: onPermissionChange(<permisssionItem>)
-- 6.SDL->HMI: SDL.OnAppPermissionChanged(<appID_1>, params)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local basic_ptu_file = "files/ptu.json"
local ptu_app_registered = "files/ptu_app.json"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
-- local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_PreparePTData()
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [ "Base-4", "Location-1" ],
    "RequestType":[ "TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "QUERY_APPS" ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, ptu_app_registered, config.application1.registerAppInterfaceParams.fullAppID, app)
end

function Test:Precondition_ActivateApp()
  local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestIdActivateApp, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data1)
              self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:UpdatePolicy_ExpectOnAppPermissionChangedWithAppID()
  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_app_registered,
    config.application1.registerAppInterfaceParams.appName,
    self.mobileSession)
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged")
  :ValidIf(function (_, data)
      if data.params.appID~=nil then
        return true
      else
        print("OnAppPermissionChanged came without appID")
        return false
      end
    end)
  :Times(AtLeast(1))
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RemovePTUfiles()
  os.remove(ptu_app_registered)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
