---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] SDL must remove PTU file got from Sync after getting the updates
--
-- Description:
-- Policies Manager must delete the file with Policy Table Update (got by SDL.OnReceivedPolicyUpdate) for the both cases:
-- 1) After successful merge Policy Table Update into Local Policy Table
-- or
-- 2) Validation failure against Data Dictionary
--
-- Preconditions
-- 1. Register new app
-- 2. Activate app
-- 3. Start PTU
-- Steps:
-- 1. PTU file is created
-- 2. When PTU sequence is finished verify that PTU file is deleted
--
-- Expected result:
-- PTU file is deleted
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local policy_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_19168.json"

--[[ Local Functions ]]
local function check_file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function(_, _)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
            :Do(function(_,data3)
                self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
              end)
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
              end)
            :Times(1)
          end)
      end
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_Success_PTUfile_removed()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptu_file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = data.params.fileName })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
        end)
  end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
  :Do(function(_,data)
    if(data.params.status == "UP_TO_DATE") then
      local result = check_file_exists(policy_file_path .. "/" .. policy_file_name)
      if(result == true) then
        self:FailTestCase("Error: PolicyTableUpdate is not deleted")
      end
    end
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
