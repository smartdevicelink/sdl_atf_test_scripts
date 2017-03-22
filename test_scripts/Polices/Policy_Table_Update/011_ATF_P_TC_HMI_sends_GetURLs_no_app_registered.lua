---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends GetURLs and no apps registered SDL must return only default url
-- [HMI API] GetURLs request/response
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered. AppID is listed in PTS
-- No PTU is requested.
-- 2. Performed steps
-- Unregister application.
-- User press button on HMI to request PTU.
-- HMI->SDL: SDL.GetURLs(service=0x07)
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL.GetURLs({urls[] = default})
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

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

function Test:Precondition_flow_PTU_SUCCEESS_EXTERNAL_PROPRIETARY()
  local SystemFilesPath = "/tmp/fs/mp/images/ivsu_cache/"

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS"} } )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
        {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_,_)
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = config.application1.registerAppInterfaceParams.appID},
          "files/ptu.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath.."PolicyTableUpdate" })
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."PolicyTableUpdate"})
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
end

function Test:Precondition_UnregisterApp()
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTU_GetURLs_NoAppRegistered()
  local endpoints = {}
  testCasesForPolicyTableSnapshot:extract_pts()

  for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
      endpoints[#endpoints + 1] = {
        url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value,
        appID = testCasesForPolicyTableSnapshot.pts_endpoints[i].appID}
    end
  end

  local RequestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetURLS"} } )
  :Do(function(_,data)
      local is_correct = {}
      for i = 1, #data.result.urls do
        is_correct[i] = false
        for j = 1, #endpoints do
          if ( data.result.urls[i].url == endpoints[j].url ) then
            is_correct[i] = true
          end
        end
      end
      if(#data.result.urls ~= #endpoints ) then
        self:FailTestCase("Number of urls is not as expected: "..#endpoints..". Real: "..#data.result.urls)
      end
      for i = 1, #is_correct do
        if(is_correct[i] == false) then
          self:FailTestCase("url: "..data.result.urls[i].url.." is not correct. Expected: "..endpoints[i].url)
        end
      end
    end)
end

function Test:TestStep_PTU_DB_GetURLs_NoAppRegistered()
  local is_test_fail = false
  local policy_endpoints = {}

  local sevices_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select service from endpoint")

  for _, value in pairs(sevices_table) do
    policy_endpoints[#policy_endpoints + 1] = { found = false, service = value }
    --TODO(istoimenova): Should be updated when policy defect is fixed
    if ( value == "4" or value == "7") then
      policy_endpoints[#policy_endpoints].found = true
    end
  end

  for i = 1, #policy_endpoints do
    if(policy_endpoints[i].found == false) then
      commonFunctions:printError("endpoints for service "..policy_endpoints[i].service .. " should not be observed." )
      is_test_fail = true
    end
  end

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
