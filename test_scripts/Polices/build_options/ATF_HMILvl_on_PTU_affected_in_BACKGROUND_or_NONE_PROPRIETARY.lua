---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in NONE/BACKGROUND
--
-- Description:
-- SDL must change HMILevel of applications that are currently in NONE or BACKGROUND "default_hmi" from assigned policies in case of Policy Table Update
-- 1. Used preconditions
-- a) SDL is built with "DEXTENDED_POLICY: ON" flag, SDL and HMI are running
-- b) device is connected to SDL and is consented by the User
-- c) the app_1 is registered with SDL and is in BACKGROUND HMILevel
-- d) the app_2 is registered with SDL and is in NONE HMILevel
-- e) appID_1 and appID_2 have just received the updated PT with new permissions.
--
-- 2. Performed steps
-- 1) SDL->app_1: OnPermissionsChange
-- 2) SDL->app_2: OnPermissionsChange
--
-- Expected:
-- 1) SDL->appID_2: OnHMIStatus(BACKGROUND) //as "default_hmi" from the newly assigned policies has value of BACKGROUND

---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
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
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
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

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU(config.application1.registerAppInterfaceParams.appID, ptu_first_app_registered)
  PrepareJsonPTU(config.application2.registerAppInterfaceParams.appID, ptu_second_app_registered)
end
--[[ end of Preconditions ]]

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      EXPECT_RESPONSE(correlation_id, { success = true })
      EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end

function Test:ActivateAppInBACKGROUND()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"BACKGROUND")
end

function Test:RegisterSecondApp()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)

  self.mobileSession1:StartService(7)
  :Do(function (_,_)
      local correlation_id = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      self.mobileSession1:ExpectResponse(correlation_id, { success = true })
      self.mobileSession1:ExpectNotification("OnPermissionsChange")
    end)
end

function Test:ActivateSecondAppInNone()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"NONE")
end

function Test:UpdatePolicyAfterAddSecondApp_ExpectOnHMIStatusCall()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")

  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_second_app_registered,
    config.application2.registerAppInterfaceParams.appName,
    self.mobileSession1)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  -- Expect after updating HMI status will change from None to BACKGROUND
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel="BACKGROUND"})

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