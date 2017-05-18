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
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")

--[[ Local Variables ]]
-- local r_expected = { true, false } -- Expected file is created and then afterwards is deleted
-- local r_actual = { }
local policy_file_name = "PolicyTableUpdate"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_19168.json"

--[[ Local Functions ]]
-- local function is_table_equal(t1, t2)
--   local ty1 = type(t1)
--   local ty2 = type(t2)
--   if ty1 ~= ty2 then return false end
--   if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
--   for k1, v1 in pairs(t1) do
--     local v2 = t2[k1]
--     if v2 == nil or not is_table_equal(v1, v2) then return false end
--   end
--   for k2, v2 in pairs(t2) do
--     local v1 = t1[k2]
--     if v1 == nil or not is_table_equal(v1, v2) then return false end
--   end
--   return true
-- end

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
              { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
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
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              --table.insert(r_actual, check_file_exists(policy_file_path .. "/" .. policy_file_name))
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          :Do(function(_, _)
              --table.insert(r_actual, check_file_exists(policy_file_path .. "/" .. policy_file_name))
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
  end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
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