---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PTU merge into Local Policy Table (consumer_friendly_messages)
--
-- Description:
--If the 'consumer_friendly_messages' section of PTU contains a 'messages' subsection,
--SDL _must_replace the consumer_friendly_messages portion of the Local Policy Table
--with the same section from PTU.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- PTU to be received satisfies data dictionary requirements and its
-- 'consumer_friendly_messages' section contains a 'messages' subsection
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
-- SDL replaces the following sections of the Local Policy Table with the
--corresponding sections from PTU: module_config, functional_groupings, app_policies
--and consumer_friendly_messages->'messages'
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
--local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_18192.json"

--[[ Local Functions ]]
local function is_table_equal(t1, t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not is_table_equal(v1, v2) then return false end
  end
  for k2, v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not is_table_equal(v1, v2) then return false end
  end
  return true
end

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/preloaded_18192.json")
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_DeleteSnapshot()
  os.remove(policy_file_path .. "/sdl_snapshot.json")
end

function Test.Precondition_ValidateResultBeforePTU()
  local r_expected = {
    "1|TTS1_AppPermissions|LABEL_AppPermissions|LINE1_AppPermissions|LINE2_AppPermissions|TEXTBODY_AppPermissions|en-us|AppPermissions",
    "2|||LINE1_DataConsent|LINE2_DataConsent|TEXTBODY_DataConsent|en-us|DataConsent" }
  local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
  local r_actual = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
  if not is_table_equal(r_expected, r_actual) then
    return false, "\nExpected:\n" .. commonFunctions:convertTableToString(r_expected, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(r_actual, 1)
  end
  return true
end

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
function Test:TestStep_PTU_Up_To_Date()
  local policy_file_name = "PolicyTableUpdate"
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

function Test.TestStep_ValidateResultAfterPTU()
  local r_expected = { "1|TTS1|LABEL|LINE1|LINE2|TEXTBODY|en-us|AppPermissions", "2|TTS2|||||en-us|AppPermissionsHelp" }
  local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
  local r_actual = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
  if not is_table_equal(r_expected, r_actual) then
    return false, "\nExpected:\n" .. commonFunctions:convertTableToString(r_expected, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(r_actual, 1)
  end
  return true
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
