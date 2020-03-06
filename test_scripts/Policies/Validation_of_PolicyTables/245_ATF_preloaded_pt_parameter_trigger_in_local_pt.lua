---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: New trigger for changing the value of "preloaded_pt" field to 'false'
-- Clarification
-- [Policies]: preloaded_pt" flag set-up to false (Ford-specific)
--
-- Description:
-- Behavior of SDL with "preloaded_pt" field (Boolean) is "true" in LocalPT when was performed UpdatedPolicyTable procedure
-- 1. Used preconditions
-- Delete files and policy table from previous ignition cycle if any
-- Start SDL with PreloadedPT json file (the value of "preloaded_pt" field to "true")
-- 2. Performed steps
-- SDL sends the first Snapshot to mobile app
-- SDL receives UpdatedPolicyTable via SystemRequest from mobile app
--
-- Expected result:
-- SDL must change the value of "preloaded_pt" field to "false"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General configuration parameters ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')


--[[ Local Variables ]]
local PATH_TO_POLICY_FILE = "files/jsons/Policies/PTU_ValidationRules/ptu_012.json"
local DB_FALSE_VALUE = "0"

--[[ Local Functions ]]
local function constructPathToDatabase()
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    return config.pathToSDL .. "storage/policy.sqlite"
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    return config.pathToSDL .. "policy.sqlite"
  else
    commonFunctions:userPrint(31, "policy.sqlite is not found" )
    return nil
  end
end

local function executeSqliteQuery(rawQueryString, dbFilePath)
  if not dbFilePath then
    return nil
  end
  local queryExecutionResult = {}
  local queryString = table.concat({"sqlite3 ", dbFilePath, " '", rawQueryString, "'"})
  local file = io.popen(queryString, 'r')
  if file then
    local index = 1
    for line in file:lines() do
      queryExecutionResult[index] = line
      index = index + 1
    end
    file:close()
    return queryExecutionResult
  else
    return nil
  end
end

local function isValuesCorrect(actualValues, expectedValues)
  if #actualValues ~= #expectedValues then
    return false
  end

  local tmpExpectedValues = {}
  for i = 1, #expectedValues do
    tmpExpectedValues[i] = expectedValues[i]
  end

  local isFound
  for j = 1, #actualValues do
    isFound = false
    for key, value in pairs(tmpExpectedValues) do
      if value == actualValues[j] then
        isFound = true
        tmpExpectedValues[key] = nil
        break
      end
    end
    if not isFound then
      return false
    end
  end
  if next(tmpExpectedValues) then
    return false
  end
  return true
end

function Test.checkLocalPT()
  local expectedLocalPtRequestTypeValues = DB_FALSE_VALUE
  local queryString = 'SELECT preloaded_pt FROM module_config'
  local actualLocalPtRequestTypeValues = executeSqliteQuery(queryString, constructPathToDatabase())
  for k,v in pairs(actualLocalPtRequestTypeValues) do
    print(k..": "..v)
  end
  if actualLocalPtRequestTypeValues then
    local result = isValuesCorrect(actualLocalPtRequestTypeValues, expectedLocalPtRequestTypeValues)
    if not result then
      commonFunctions:userPrint(31, "Test failed: SDL don't change the value of preloaded_pt field to false after PTU")
    end
    return result
  else
    commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
    return false
  end
end

function Test:updatePolicyTable(pathToPolicyFile)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(exp, data)
      if (exp.occurences == 1 and data.params.status == "UPDATING") or
      (data.params.status == "UP_TO_DATE") then
        return true
      else
        local reason = "SDL.OnStatusUpdate came with wrong values. "
        if exp.occurences == 1 then
          reason = reason .. "Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "'"
        elseif exp.occurences == 2 then
          reason = reason .. "Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "'"
        end
        return false, reason
      end
    end)
  :Times(Between(1,2))

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })

  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "PolicyTableUpdate"
        }
      )
    end)

  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function(_, _)
      local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "PolicyTableUpdate"
        },
        pathToPolicyFile)

      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
            }
          )
        end)

      EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
      :Do(function(_, _)
          requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
          EXPECT_HMIRESPONSE(requestId)
        end)
    end)
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Check_preloaded_pt_true()
  local preloaded_pt_initial = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.preloaded_pt")
  local preloaded_pt_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT preloaded_pt FROM module_config")
  local preloaded_pt
  for _, value in pairs(preloaded_pt_table) do
    preloaded_pt = value
  end
  if(preloaded_pt_initial == true) then
    if(preloaded_pt ~= "0") then
      self:FailTestCase("Error: Value of preloaded_pt should be 0(false). Real: "..preloaded_pt)
    end
  else
    self:FailTestCase("Error: preloaded_pt.json should be updated. Value of preloaded_pt should be true. Real: "..preloaded_pt_initial)
  end
end


function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_Status_UP_TO_DATE()
  self:updatePolicyTable(PATH_TO_POLICY_FILE)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Check_preloaded_pt_false_policyDB()
  os.execute("sleep 3")
  local result = commonFunctions:is_db_contains(config.pathToSDL.."/storage/policy.sqlite", "SELECT preloaded_pt FROM module_config", {DB_FALSE_VALUE} )
  if(result ~= true) then
    self:FailTestCase("Error: Value of preloaded_pt on policy DB should be false.")
  end
end

function Test:TestStep_Check_preloaded_pt_false_PTS()
  local preloaded_pt =testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.preloaded_pt")
  if(preloaded_pt ~= false) then
    self:FailTestCase("Error: Value of preloaded_pt should be false. Real: "..tostring(preloaded_pt))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
