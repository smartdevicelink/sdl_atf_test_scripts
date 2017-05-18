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
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local pathToSnapshot
local appID = config.application1.registerAppInterfaceParams["appID"]
local countAppActivation

--[[ Local Functions ]]
local function GetCountOfUserSelectionsFromPTS(pathToFile)
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local userSelectionsCounteFromPTS = data.policy_table.usage_and_error_counts.app_level[appID].count_of_user_selections
  return userSelectionsCounteFromPTS
end

--[[ Preconditions ]]
function Test:Precondition_Activate_App_Consent_Device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
    local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
    EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
    :Do(function(_,_)
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
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
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"]})
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
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf(function(_,data)
      pathToSnapshot = data.params.file
      return GetCountOfUserSelectionsFromPTS(pathToSnapshot) == countAppActivation
    end)
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Postcondition_StopSDL()
  StopSDL()
end
