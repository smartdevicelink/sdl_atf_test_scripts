---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Assign "default" policies to the application which appID does not exist in LocalPT
--
-- Description:
-- In case the application registers (sends RegisterAppInterface request) with the appID that does not exist in Local Policy Table,
-- PoliciesManager must add "<appID>" to "app_policies" section of Local PT and assign and apply "default" permissions: "<appID>": "default".
--
-- Preconditions:
-- 1. App "000000" is not registered yet
-- 2. Make sure there no specific permission for app "0000001"
-- Steps:
-- 1. Register new "0000001" app
-- 2. Activate "0000001" app and device
-- 3. Verify in LPT which permissions has been assigned for app
--
-- Expected result:
-- Default permissions is assigned for app
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local r_expected = { }
local r_actual = { }

--[[ Local Functions ]]
local function contains(t, item)
  for _, v in pairs(t) do
    if v == item then return true end
  end
  return false
end

local function is_array_equal(a1, a2)
  if #a1 ~= #a2 then return false end
  local res1 = true
  local res2 = true
  for _, v1 in pairs(a1) do
    if not contains(a2, v1) then
      res1 = false
      break
    end
  end
  for _, v2 in pairs(a2) do
    if not contains(a1, v2) then
      res2 = false
      break
    end
  end
  return res1 and res2
end

local function execute_sqlite_query(file_db, query)
  if not file_db then
    return nil
  end
  local res = { }
  local file = io.popen(table.concat({"sqlite3 ", file_db, " '", query, "'"}), 'r')
  if file then
    for line in file:lines() do
      table.insert(res, line)
    end
    file:close()
    return res
  else
    return nil
  end
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ActivateApp()
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
  os.execute("sleep 1")
end

function Test.StopSDL()
  StopSDL()
end

function Test.TestStep_FetchLPTDB()
  os.execute("sleep 3")
  local query = "select fg.name from app_group ag inner join functional_group fg on fg.id = ag.functional_group_id where ag.application_id = "
  r_expected = execute_sqlite_query(db_file, query .. '"default"')
  r_actual = execute_sqlite_query(db_file, query .. '"0000001"')
end

function Test.TestStep_ValidateResult()
  if not is_array_equal(r_expected, r_actual) then
    return false, "\nExpected groups:\n" .. commonFunctions:convertTableToString(r_expected, 1) .. "\nActual groups:\n" .. commonFunctions:convertTableToString(r_actual, 1)
  end
  return true
end

return Test
