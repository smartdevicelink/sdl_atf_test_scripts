---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table
-- [RegisterAppInterface] Allow only RegisterAppInterface for the application with NULL policies
--
-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID,
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.
-- Performed steps
-- Pre_step. Add in sdl_preloaded_pt application id with NULL policy
-- 1. MOB-SDL - Open new session and register application in this session
-- 2. MOB-SDL - send the list of RPCs
-- 3. SDL responce, success = false, resultCode = "DISALLOWED"
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyAppIdManagament = require('user_modules/shared_testcases/testCasesForPolicyAppIdManagament')

--[[ Local variables ]]
local RPC_Base4 = {}
local HMIAppID

--[[ Local functions ]]
local function Get_RPCs()
  testCasesForPolicyTableSnapshot:extract_preloaded_pt()

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.Base-4.rpcs.")) == "functional_groupings.Base-4.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.Base%-4%.rpcs%.(%S+)%.%S+%.%S+")
      if(#RPC_Base4 == 0) then
        RPC_Base4[#RPC_Base4 + 1] = str
      end

      if(RPC_Base4[#RPC_Base4] ~= str) then
        RPC_Base4[#RPC_Base4 + 1] = str
      end
    end
  end
  -- for i = 1, #RPC_Base4 do
  -- print ("RPC_Base4 = "..RPC_Base4[i])
  -- end
end

--[[ General Precondition before ATF start ]]
Get_RPCs()
commonSteps:DeleteLogsFileAndPolicyTable()
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require("mobile_session")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_23511_1.json")
end

function Test:Pre_StartNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNewApp()
  config.application1.registerAppInterfaceParams.appName = "App_test"
  config.application1.registerAppInterfaceParams.appID = "123abc"
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
      self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  self.mobileSession2:ExpectResponse(correlationId, { success = true })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PerformPTU_Check_OnAppPermissionChanged()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_23511.json")
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", { appRevoked = true, appID = HMIAppID})
end

for i = 1, #RPC_Base4 do

  if( (RPC_Base4[i] ~= "UnregisterAppInterface") and (RPC_Base4[i] ~= "RegisterAppInterface")
    and (string.sub (RPC_Base4[i], 1, string.len("On")) ~= "On") ) then
    function Test:TestStep_CheckRPCs_DISALLOWED()
      print("RPC_Base4: "..RPC_Base4[i])

      local correlationId = self.mobileSession2:SendRPC(RPC_Base4[i], {})
      self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
    end
  end
end

function Test:TestStep_UnregisterAppInterface_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC("UnregisterAppInterface", {})
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:TestStep_CloseSession()
  self.mobileSession:Stop()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
end

function Test:TestStep_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_RAI_SUCCESS()
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end
return Test
