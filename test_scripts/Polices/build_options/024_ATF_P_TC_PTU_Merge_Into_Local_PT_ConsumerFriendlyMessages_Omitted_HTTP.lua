-- Requirements summary:
-- [Policies] Merge: PTU into LocalPT (PTU omits "consumer_friendly_messages" section)
--
-- Description:
-- In case the Updated PT omits "consumer_friendly_messages" section,
-- PoliciesManager must maintain the current "consumer_friendly_messages"
-- section in Local PT.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- PTU to be received satisfies data dictionary requirements
-- PTU omits "consumer_friendly_messages" section
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP)
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON")
-- app->SDL: SystemRequest(requestType=HTTP)
-- SDL->HMI: SystemRequest(requestType=HTTP, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file) according to data dictionary
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
-- Expected result:
-- SDL maintains the current "consumer_friendly_messages" section in Local PT
--(no updates on merge)
-- SDL replaces the following sections of the Local Policy Table with the
--corresponding sections from PTU: module_config, functional_groupings and app_policies
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local Variables ]]
--local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_22734.json"


--[[ General Precondition before ATF start ]]
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/preloaded_18192.json")
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_NoteNumOfRecords()
 -- r_expected = get_num_records()
end

function Test:Precondition_ValidateResultBeforePTU()
      local expected_res = {
      --According to DataDictionary for SDL:
        "1||||||en-us|AppPermissions",
        "2||||||en-us|DataConsent" }
      local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
      local actual_res = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
      local is_table_equal = commonFunctions:is_table_equal(expected_res, actual_res)

      if not is_table_equal then
        self:FailTestCase("\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1))
        --return false, "\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1)
      end

end


--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Perform_PTU_Success()

  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate", },ptu_file)
  
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UP_TO_DATE"})

end

function Test:TestStep_StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RegisterNewApp()
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(d.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:TestStep_ValidateNumberMessages()
  -- self.mobileSession:ExpectAny()
  -- :ValidIf(function(_, _)
      local expected_res = {
      --According to DataDictionary for SDL:
        "1||||||en-us|AppPermissions",
        "2||||||en-us|DataConsent" }
      local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
      local actual_res = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
      local is_table_equal = commonFunctions:is_table_equal(expected_res, actual_res)

      if not is_table_equal then
        self:FailTestCase("\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1))
        --return false, "\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1)
      end
      --return true
  --   end)
  -- :Times(1)
end

function Test:TestStep_ValidateResultAfterPTU()
      local expected_res = {
      --According to DataDictionary for SDL:
        "1||||||en-us|AppPermissions",
        "2||||||en-us|DataConsent" }
      local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
      local actual_res = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
      local is_table_equal = commonFunctions:is_table_equal(expected_res, actual_res)

      if not is_table_equal then
        self:FailTestCase("\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1))
        --return false, "\nExpected:\n" .. commonFunctions:convertTableToString(expected_res, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(actual_res, 1)
      end

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
