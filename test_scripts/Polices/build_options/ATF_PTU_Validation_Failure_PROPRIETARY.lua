---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PTU validation failure
-- [HMI API] OnStatusUpdate
-- [HMI API] OnReceivedPolicyUpdate notification
--
-- Description:
-- In case PTU validation fails, SDL must log the error locally and discard the policy table update
-- with No notification of Cloud about invalid data and
-- notify HMI with OnPolicyUpdate(UPDATE_NEEDED)
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY)
-- SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON")
-- app->SDL: SystemRequest(requestType=PROPRIETARY)
-- SDL->HMI: SystemRequest(requestType=PROPRIETARY, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file): policy_file with missing mandatory seconds_between_retries.
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UPDATE_NEEDED)
-- SDL removes 'policyfile' from the directory
---------------------------------------------------------------------------------------------

---[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
testCasesForBuildingSDLPolicyFlag:Update_PolicyFlag("EXTENDED_POLICY", "PROPRIETARY")
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTENDED_POLICY","PROPRIETARY")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_validation_failure()
  local is_test_fail = false
  local endpoints = {}
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  print("hmi_app_id = " ..hmi_app_id)

  for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
      endpoints[#endpoints + 1] = { url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value, appID = nil}
    end

    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "app1") then
      endpoints[#endpoints + 1] = {
        url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value,
        appID = testCasesForPolicyTableSnapshot.pts_endpoints[i].appID}
    end
  end

  testCasesForPolicyTableSnapshot:extract_pts({hmi_app_id})
  local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
  local request_id_get_urls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(request_id_get_urls,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints} } )
  :Do(function(_,_)

      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { fileType = "JSON", timeout = timeout_after_x_seconds, requestType = "PROPRIETARY", url = endpoints[1].url})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY",
          fileType = "JSON",
          url = endpoints[1].url,
          timeout = timeout_after_x_seconds
        })
      :Do(function(_,_)
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"},
          "files/jsons/Policies/PTU_ValidationRules/invalid_PTU_missing_seconds_between_retries.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest",{
              requestType = "PROPRIETARY",
              fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate",
              --appID = hmi_app_id
            })
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
              :Do(function(_,_)
                  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate") == true) then
                    is_test_fail = true
                    commonFunctions:printError("File /tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate exists!")
                  end
                end)
            end)

          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test