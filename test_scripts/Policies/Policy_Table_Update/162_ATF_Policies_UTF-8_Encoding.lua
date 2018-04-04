---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: UTF-8 encoding
--
-- Description:
-- The policy table variations must be authored in JSON (UTF-8 encoded).
--
-- Preconditions
-- 1. LPT has non empty 'consumer_friendly_messages'
-- 2. Register new app
-- 3. Activate app
-- Steps:
-- 1. Perform PTU with specific data in UTF-8 format in 'consumer_friendly_messages' section
-- 2. After PTU is finished verify consumer_friendly_messages.messages section in LPT
--
-- Expected result:
-- The texts in Russian & Chinese in appropriate are parsed correctly by SDL
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_22420.json"

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

local function execute_sqlite_query(file_db, query)
  if not file_db then
    return nil
  end
  local res = { }
  local file = io.popen(table.concat({"sqlite3 ", file_db, " '", query, "'"}), 'r')
  if file then
    for line in file:lines() do
      res[#res + 1] = line
    end
    file:close()
    return res
  else
    return nil
  end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_DeleteSnapshot()
  os.remove(policy_file_path .. "/sdl_snapshot.json")
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

function Test:TestStep_PTU()
  local policy_file_name = "PolicyTableUpdate"
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
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          :Do(function(_, _)
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
    end)
end

function Test:TestStep_ValidateResult_UTF8_Encoding()
  self.mobileSession:ExpectAny()
  :ValidIf(function(_, _)
      local r_expected = { "1|表示您同意_1|Метка|LINE1|LINE2|TEXTBODY|en-us|AppPermissions", "2|授權請求_2|||||en-us|AppPermissionsHelp" }
      local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
      local r_actual = execute_sqlite_query(db_file, query)
      if not is_table_equal(r_expected, r_actual) then
        return false, "\nExpected:\n" .. commonFunctions:convertTableToString(r_expected, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(r_actual, 1)
      end
      return true
    end)
  :Times(1)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.StopSDL()
  StopSDL()
end

return Test
