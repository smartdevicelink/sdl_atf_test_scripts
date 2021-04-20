---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in FULL/LIMITED
--
-- Description:
-- The applications that are currently in FULL or LIMITED should remain in the same HMILevel in case of Policy Table Update
-- 1. Used preconditions
-- a) SDL and HMI are running
-- b) device is connected to SDL and is consented by the User
-- 2. Performed steps
-- 1) register the app_1
-- 2) register the app_2 and activate in FULL HMILevel
-- 4) Update PTU.

-- Expected result:
-- 1) appID_1 remains in NONE. After PTU OnHMIStatus does not calls
-- 2) appID_2 remains in FULL. After PTU OnHMIStatus does not calls
-- 3) After PTU OnPermissionsChange is called for both applications.

---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local json = require('json')

--[[ Local Variables ]]
local HMIAppID2

local applications =
{
  {
    registerAppInterfaceParams =
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "Vasya",
      isMediaApplication = false,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "NAVIGATION" },
      appID = "0000001",
      fullAppID = "0000001",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    }
  },
  {
    registerAppInterfaceParams =
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "Petya",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "MEDIA" },
      appID = "0000002",
      fullAppID = "0000002",
      deviceInfo =
      {
        os = "Android",
        carrier = "MTS",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    }
  }
}

-- Basic PTU file
local basic_ptu_file = "files/ptu.json"
local ptu_first_app_registered = "files/ptu1app.json"

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, previous_ptu, new_ptufile)
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
  --testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(previous_ptu, new_ptufile, name, app)

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

function Test:Precondition_StartFirstSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test:Precondition_StartSecondSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(applications[1].registerAppInterfaceParams.fullAppID, basic_ptu_file, ptu_first_app_registered)
  PrepareJsonPTU1(applications[2].registerAppInterfaceParams.fullAppID, ptu_first_app_registered, ptu_first_app_registered)
end
--[[ end of Preconditions ]]

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", applications[1].registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")

      self.mobileSession:ExpectResponse(correlationId, { success = true })
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE"})
    end)
end

function Test:RegisterSecondApp()
  self.mobileSession2:StartService(7)
  :Do(function (_,_)
      local correlationId2 = self.mobileSession2:SendRPC("RegisterAppInterface", applications[2].registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID2 = data.params.application.appID
        end)
      self.mobileSession2:ExpectResponse(correlationId2, { success = true })
      self.mobileSession2:ExpectNotification("OnPermissionsChange")
    end)
  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE"})
end

function Test:ActivateSecondApp()
  commonSteps:ActivateAppInSpecificLevel(self, HMIAppID2)
  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
end

function Test:UpdatePolicyAfterAddApps_ExpectOnHMIStatusNotCall()
  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_first_app_registered,
    applications[2].registerAppInterfaceParams.appName,
    self.mobileSession2)

  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Do(function() print("App1: OnPermissionsChange") end)
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
  :Do(function() print("App2: OnPermissionsChange") end)

  -- Expect after updating HMI status will not change
  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  self.mobileSession2:ExpectNotification("OnHMIStatus"):Times(0)

  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RemovePTUfiles()
  os.remove(ptu_first_app_registered)
end
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
