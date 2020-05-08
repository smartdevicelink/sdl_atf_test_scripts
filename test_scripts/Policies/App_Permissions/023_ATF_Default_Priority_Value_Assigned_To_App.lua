---------------------------------------------------------------------------------------------
-- Requirement summary:
-- "default" policies assigned to the application and "priority" value
--
-- Description:
-- In case the "default" policies are assigned to the application,
-- PoliciesManager must provide to HMI the app`s priority value taken from "priority" field in "default" section of PolicyTable.
-- 1. Used preconditions:
-- a) Set SDL to first life cycle state.
-- b) Register application, activate and consent device
-- c) preloaded_pt.json has "priority": "NONE" in default section, set "priority": "NORMAL" to "pre_DataConsent" section to get OnAppPermissionChanged after consenting device
-- d) Aplication registered
-- 2. Performed steps:
-- a) Activate App and consent device
--
-- Expected result:
-- SDL->HMI: SDL.ActivateApp_response {priority: NONE, params}
-- SDL->HMI: SDL.OnAppPermissionsChanged {priority: NONE, params}
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Preconditions before ATF starts ]]
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ Local Functions ]]
local function SetPriorityToPre_DataConsentNORMAL()
  local pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  -- json library restriction to decode-encode element which defined as "null"
  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = json.null}
  end
  -- set "NORMAL" priority to pre_DataConsent section to get OnAppPermissionChanged after consenting device (for default priority = NONE)
  data.policy_table.app_policies.pre_DataConsent["priority"] = "NORMAL"

  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
SetPriorityToPre_DataConsentNORMAL()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Register_App_And_Check_Priority()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",{ priority = "NORMAL" } )
  :Do(function(_,data)
      self.HMIapp = data.params.application.appID
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:TestStep_Activate_App_Consent_Device_And_Check_Priority_In_ActivateApp_And_OnAppPermissionChanged()

  local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.HMIapp})
  EXPECT_HMIRESPONSE(RequestIdActivateApp, { result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.applications["Test Application"], priority = "NONE"})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
