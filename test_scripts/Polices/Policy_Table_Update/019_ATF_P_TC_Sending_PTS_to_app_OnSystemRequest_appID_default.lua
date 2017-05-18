---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Sending PTS to mobile application on getting OnSystemRequest with appID "default"
-- [HMI API] SystemRequest request/response
--
-- Description:
-- SDL must forward OnSystemRequest(request_type=PROPRIETARY, url, appID) with encrypted PTS
-- snapshot as a hybrid data to any connected mobile application. "fileType" must be
-- assigned as "JSON" in mobile app notification.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- device an app with app_ID1 is running is consented
-- application with <app ID> is running on SDL
-- device an app with app_ID2 is running is consented
-- application with <app ID2> is running on SDL
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- 2. Performed steps
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY, appID="default")
--
-- Expected result:
--
-- SDL-><app1\app2>: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON")
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobileSession = require("mobile_session")

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/endpoints_appId.json")

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Register2App()
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  self.mobileSession2:ExpectResponse(correlationId, { success = true })
end
--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Sending_PTS_to_mobile_application()
  local endpoints = {}

  endpoints[1] ={}
  endpoints[1].url = "http://policies.telematics.ford.com/api/policies"

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints }} )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{
          requestType = "PROPRIETARY",
          fileName = "PolicyTableUpdate",
          url = endpoints[1].url})
      -- no appID is send, so notification can came to any apps
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON", url = endpoints[1].url }):Times(Between(0,1))
  self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON", url = endpoints[1].url }):Times(Between(0,1))
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
