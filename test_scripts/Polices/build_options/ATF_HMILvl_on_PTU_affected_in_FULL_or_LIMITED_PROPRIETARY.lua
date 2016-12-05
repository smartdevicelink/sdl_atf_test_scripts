--UNREADY
-- function AddApplicationToPTJsonFile should be added to the testCasesForPolicyTable.lua

---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in FULL/LIMITED
--
-- Description:
-- The applications that are currently in FULL or LIMITED should remain in the same HMILevel in case of Policy Table Update
-- 1. Used preconditions
-- a) SDL is built with "DEXTENDED_POLICY: ON" flag, SDL and HMI are running
-- b) device is connected to SDL and is consented by the User
-- 2. Performed steps
-- 1) register the app_1 and activate in FULL HMILevel
-- 2) Update PTU.
-- 3) register the app_2 and activate in LIMITED HMILevel
-- 4) Update PTU.
--
-- Expected result:
-- 1) appID_1 remains in FULL. After PTU OnHMIStatus does not calls
-- 2) appID_2 remains in LIMITED. After PTU OnHMIStatus does not calls
-- 3) After each PTU OnPermissionsChange is called

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
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
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
--ToDo(vvvakulenko): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

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
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_first_app_registered)
  PrepareJsonPTU1(config.application2.registerAppInterfaceParams.appID, ptu_second_app_registered)
end

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
end

function Test:TestStep_ActivateAppInFull()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"FULL")
end

function Test:TestStep_UpdatePolicyAfterAddFirstAp_ExpectOnHMIStatusNotCall()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")

  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_first_app_registered,
    config.application1.registerAppInterfaceParams.appName,
    self.mobileSession)
  self.mobileSession:ExpectNotification("OnPermissionsChange")

  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
end

function Test:TestStep_RegisterSecondApp()
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
end

function Test:TestStep_ActivateSecondAppInLimited()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"LIMITED")
end

function Test:TestStep_UpdatePolicyAfterAddSecondApp_ExpectOnHMIStatusNotCall()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")

  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_second_app_registered,
    config.application2.registerAppInterfaceParams.appName,
    self.mobileSession1)
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  self.mobileSession1:ExpectNotification("OnHMIStatus"):Times(0)

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RemovePTUfiles()
  os.remove(ptu_first_app_registered)
  os.remove(ptu_second_app_registered)
end

function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test