-- Requirement summary:
-- [PolicyTableUpdate] Apply PTU changes and OnPermissionChange notifying the apps
--
-- Description:
-- Right after the PoliciesManager merges the UpdatedPT with Local PT, it must apply the changes
-- and send onPermissionChange() notification to any registered mobile app in case the Updated PT
-- affected to this app`s policies.
-- app via OnSystemRequest() RPC.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- policyfile' corresponds to PTU validation rules
-- 2. Performed steps
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
--
-- Expected:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- SDL->app: onPermissionChange(permisssions)
-- SDL->HMI: SDL.OnAppPermissionChanged(app, permissions)
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
local basic_ptu_file = "files/ptu.json"
local ptu_app_registered = "files/ptu_app.json"

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4", "Emergency-1"
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
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
--ToDo: should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
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
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_app_registered)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RegisterApp()
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

function Test:TestStep_UpdatePolicy_ExpectOnAppPermissionChangedWithAppID()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")

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