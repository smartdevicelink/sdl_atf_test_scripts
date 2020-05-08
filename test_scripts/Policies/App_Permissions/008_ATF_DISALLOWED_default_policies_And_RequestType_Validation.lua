---------------------------------------------------------------------------------------------
-- Requirement summary:
-- DISALLOWED "default" policies and "RequestType" validation
--
-- Description:
-- In case the "default" policies are assigned to the application,
-- PoliciesManager must ignore RPC with requestTypes different from "RequestType" defined in "default" section.
-- SDL must respond with (resultCode:DISALLOWED, success:false) to mobile application.
-- 1. Used preconditions:
-- a) Set SDL to first life cycle state.
-- b) Set "RequestType" for "default" section "PROPRIETARY" only.
-- c) Register application, activate and consent device (assign "default group")
-- 2. Performed steps:
-- b) Send SystemRequest with requestType = "PROPRIETARY"
-- c) Send SystemRequest with requestType = "HTTP"
--
-- Expected result:
-- SDL allow SystemRequest with requestType = "PROPRIETARY" and disallow SystemRequest with requestType = "HTTP"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
local function SetRequestTypeForDefaultGroup()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  -- json library restriction to decode-encode element defined as "null"
  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = json.null}
  end

  data.policy_table.app_policies.default["RequestType"] = {"PROPRIETARY"}

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
SetRequestTypeForDefaultGroup()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconditions_Assign_To_App_Default_RequestType_PROPRIETARY_Via_Activation_And_Consenting_Device()

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId, { result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestId1,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Verify_default_section()
  local test_fail = false
  local request_consent = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.default.RequestType.1")

  if(request_consent ~= "PROPRIETARY") then
    commonFunctions:printError("Error: RequestType is not PROPRIETARY")
    test_fail = true
  end
  if(test_fail == true) then
    self:FailTestCase("Test failed. See prints")
  end
end

function Test:TestStep_SDL_Allow_SystemRequest_Of_PROPRIETARY_Type()

  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/icon.png")
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})

end

function Test:TestStep_SDL_Disallow_SystemRequest_Of_HTTP_Type()

  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "HTTP"}, "files/icon.png")
  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
