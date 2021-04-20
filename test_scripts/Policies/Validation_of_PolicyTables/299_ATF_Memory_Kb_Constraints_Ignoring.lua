---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pre_DataConsent", "default" and <app id> policies and "'memory_kb'" validation
--
-- Description:
-- In case the "pre_DataConsent" or "default" or <app id> policies are assigned to the application, and "memory_kb" section exists and is not empty,
-- PoliciesManager must ignore the memory constraints in PT defined in "memory_kb" and apply the value "AppDirectoryQuota" from smartDeviceLink.ini file.
-- 1. Used preconditions:
-- a) Set SDL in first life cycle state
-- b) Set AppDirectoryQuota = 15000000 in .ini file
-- c) Register app, activate, consent device and update policy where memory_kb = 5000 for this app
-- 2. Performed steps
-- a) Send PutFile with file 8414449 bytes
-- b) Send one more time this file
--
-- Expected result:
-- a) PutFile SUCCESS resultCode - memory_kb parameter is ignored for app
-- b) PutFile OUT_OF_MEMORY resultCode - AppDirectoryQuota applies for app
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appName = "SPT"
config.application1.registerAppInterfaceParams.fullAppID = "1234567"
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/PTU_ValidationRules/preloaded_memory_kb_exist.json")
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("AppDirectoryQuota", "1000000")
commonFunctions:write_parameter_to_smart_device_link_ini("FrequencyCount", "0")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PredataConsent_Send_PutFile_Bigger_Than_AppDirectoryQuota_OUT_OF_MEMORY()
  local cid = self.mobileSession:SendRPC("PutFile", {syncFileName ="1166384_bytes_audio_1.mp3", fileType ="AUDIO_MP3"}, "files/MP3_1140kb.mp3")
  EXPECT_RESPONSE(cid, { success = false, resultCode = "OUT_OF_MEMORY" }):Timeout(15000)
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test:TestStep_PredataConsent_Send_PutFile_Bigger_Than_AppDirectoryQuota_OUT_OF_MEMORY()
  local cid = self.mobileSession:SendRPC("PutFile", {syncFileName ="icon1.png", fileType ="AUDIO_MP3"}, "files/icon.png")
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" }):Timeout(15000)
end

function Test:TestStep_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:TestStep_Default_Send_PutFile_Bigger_Than_AppDirectoryQuota_OUT_OF_MEMORY()
  local cid = self.mobileSession:SendRPC("PutFile", {syncFileName ="1166384_bytes_audio_2.mp3", fileType ="AUDIO_MP3"}, "files/MP3_1140kb.mp3")
  EXPECT_RESPONSE(cid, { success = false, resultCode = "OUT_OF_MEMORY" }):Timeout(15000)
end

function Test:Precondition_Update_Policy_With_memory_kb_Param()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"},
          "files/ptu_memory_kb_app_1234567.json")
          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              systemRequestId = data.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                {
                  policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                })
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
                self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              end
              RUN_AFTER(to_run, 800)
            end)
        end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
end

function Test:TestStep_PredataConsent_Send_PutFile_Bigger_Than_AppDirectoryQuota_OUT_OF_MEMORY()
  local cid = self.mobileSession:SendRPC("PutFile", {syncFileName ="1166384_bytes_audio_2.mp3", fileType ="AUDIO_MP3"}, "files/MP3_1140kb.mp3")
  EXPECT_RESPONSE(cid, { success = false, resultCode = "OUT_OF_MEMORY" }):Timeout(15000)
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test:TestStep_PredataConsent_Send_PutFile_Bigger_Than_AppDirectoryQuota_OUT_OF_MEMORY()
  local cid = self.mobileSession:SendRPC("PutFile", {syncFileName ="icon2.png", fileType ="AUDIO_MP3"}, "files/icon.png")
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" }):Timeout(15000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Restore_INI_file()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
