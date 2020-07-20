---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Apply PTU changes and OnPermissionChange notifying the apps
--
-- Description:
-- Right after the PoliciesManager merges the UpdatedPT with Local PT, it must apply the changes
-- and send onPermissionChange() notification to any registered mobile app in case the Updated PT
-- affected to this app`s policies.
-- a. SDL and HMI are running
-- b. AppID_1 is connected to SDL.
-- c. The device the app is running on is consented, appID1 requires PTU
-- d. Policy Table Update procedure is on stage waiting for:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- e. 'policyfile' corresponds to PTU validation rules

-- Action:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)

-- Expected:
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields
-- and everything that is defined with related requirements)
-- 2. On validation success:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU:
-- module_config,
-- functional_groupings,
-- app_policies
-- 4. SDL removes 'policyfile' from the directory
-- 5. SDL->appID_1: onPermissionChange(permisssions)
-- 6. SDL->HMI: SDL.OnAppPermissionChanged(appID_1, permissions)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')
local mobile_session = require('mobile_session')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local HMIAppID
local basic_ptu_file = "files/ptu.json" -- Basic PTU file
local ptu_app_registered = "files/ptu_app.json" -- PTU for registered app

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4", "Emergency-1"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.fullAppID, ptu_app_registered)
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterApp()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
    end)
  EXPECT_RESPONSE(correlationId, { success = true })
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

function Test:ActivateAppInFull()
  commonSteps:ActivateAppInSpecificLevel(self, HMIAppID, "FULL")
  EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "FULL" })
end

function Test:UpdatePolicy_ExpectOnAppPermissionChangedWithAppID()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function()

      testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_app_registered,
        config.application1.registerAppInterfaceParams.appName,
        self.mobileSession)

      EXPECT_NOTIFICATION("OnPermissionsChange")
      :ValidIf(function (_, data)
          if data.payload~=nil then
            return true
          else
            print("OnPermissionsChange came without permissions")
            return false
          end
        end)
    end)
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
