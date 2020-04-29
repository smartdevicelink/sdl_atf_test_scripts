---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Merging rules for "module_config" section
-- Clarification:
-- Preloaded state meaning
--
-- Description:
-- Check of merging rules for "module_config" section
-- 1. Used preconditions
-- Delete files and policy table from previous ignition cycle if any
-- Start SDL with PreloadedPT json file with "preloaded_date" parameter
-- Add information about vehicle (vehicle_make, vehicle_model, vehicle_year)
-- 2. Performed steps
-- Stop SDL
-- Start SDL with corrected PreloadedPT json file with "preloaded_date" parameter with bigger value
-- and updated information for "module_config" section with new fields and changed information for some other fields
--
-- Expected result:
-- SDL must add new fields (known to PM) & sub-sections if such are present in the updated PreloadedPT to database
-- leave fields and values of "vehicle_make", “model”, “year” params as they were in the database without changes
-- overwrite the values with the new ones from PreloadedPT for all other fields
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require("modules/json")

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local vehicle_make
local vehicle_model
local vehicle_year

local TESTED_DATA = {
  {
    module_config =
    {
      preloaded_pt = false,
      preloaded_date = "2016-02-02",
      exchange_after_x_ignition_cycles = 100,
      exchange_after_x_kilometers = 1800,
      exchange_after_x_days = 30,
      timeout_after_x_seconds = 60,
      seconds_between_retries = {2},
      certificate = "ABCDQWERTYUUYT",
      endpoints =
      {
        ["0x07"] = {
          default = {"http://policies.telematics.ford.com/api/policies"}
        },
        ["0x04"] = {
          default = {"http://ivsu.software.ford.com/api/getsoftwareupdates"}
        }
      },
      notifications_per_minute_by_priority =
      {
        EMERGENCY = 60,
        NAVIGATION = 15,
        VOICECOM = 20,
        COMMUNICATION = 6,
        NORMAL = 4,
        NONE = 0
      }
    }
  },
  {
    module_config =
    {
      preloaded_pt = false,
      preloaded_date = "2016-04-05",
      exchange_after_x_ignition_cycles = 150,
      exchange_after_x_kilometers = 2000,
      exchange_after_x_days = 60,
      timeout_after_x_seconds = 20,
      seconds_between_retries = {10},
      certificate = "MIIEpTCCA42gAwIBAgIKYSlrdAAAAAAAAjANBgkqhk",
      endpoints =
      {
        ["0x07"] = {
          default = {"http://ivsu.software.ford.com/api/getsoftwareupdates"},
        },
        ["0x04"] = {
          default = {"http://policies.telematics.ford.com/api/policies"}
        }
      },
      notifications_per_minute_by_priority =
      {
        EMERGENCY = 90,
        NAVIGATION = 18,
        VOICECOM = 30,
        COMMUNICATION = 8,
        NORMAL = 5,
        NONE = 0
      }
    }
  },
  expected =
  {
    module_config =
    {
      preloaded_pt = "0",
      exchange_after_x_ignition_cycles = 150,
      exchange_after_x_kilometers = 2000,
      exchange_after_x_days = 60,
      timeout_after_x_seconds = 20,
      seconds_between_retries = {2, 10, 25, 125, 625},
      certificate = "MIIEpTCCA42gAwIBAgIKYSlrdAAAAAAAAjANBgkqhk",
      endpoints =
      {
       ["0x07"] = {
          default = {"http://policies.telematics.ford.com/api/policies"},
          new = {"http://policies.telematics.ford.com/api/policies2"}
        },
        ["0x04"] = {
          default = {"http://ivsu.software.ford.com/api/getSoftwareUpdates"}
        },
        queryAppsUrl = {
          default = {"http://sdl.shaid.server"}
        },
        lock_screen_icon_url = {
          default = {"http://i.imgur.com/QwZ9uKG.png"}
        }
      },
      notifications_per_minute_by_priority =
      {
        EMERGENCY = 90,
        NAVIGATION = 18,
        VOICECOM = 30,
        COMMUNICATION = 8,
        NORMAL = 5,
        NONE = 0
      }
    }
  }
}
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"

local TestData = {
  path = config.pathToSDL .. "TestData",
  isExist = false,
  init = function(self)
    if not self.isExist then
      os.execute("mkdir ".. self.path)
      os.execute("echo 'List test data files files:' > " .. self.path .. "/index.txt")
      self.isExist = true
    end
  end,
  store = function(self, message, pathToFile, fileName)
    if self.isExist then
      local dataToWrite = message

      if pathToFile and fileName then
        os.execute(table.concat({"cp ", pathToFile, " ", self.path, "/", fileName}))
        dataToWrite = table.concat({dataToWrite, " File: ", fileName})
      end

      dataToWrite = dataToWrite .. "\n"
      local file = io.open(self.path .. "/index.txt", "a+")
      file:write(dataToWrite)
      file:close()
    end
  end,
  delete = function(self)
    if self.isExist then
      os.execute("rm -r -f " .. self.path)
      self.isExist = false
    end
  end,
  info = function(self)
    if self.isExist then
      commonFunctions:userPrint(35, "All test data generated by this test were stored to folder: " .. self.path)
    else
      commonFunctions:userPrint(35, "No test data were stored" )
    end
  end
}

--[[ Local Functions ]]
local function updatePreloadedPt(updaters)
  local pathToFile = config.pathToSDL .. PRELOADED_PT_FILE_NAME
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  if data then
    for _, updateFunc in pairs(updaters) do
      updateFunc(data)
    end
  end

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

local function prepareNewPreloadedPT()
  local newUpdaters = {
    function(data)
      data.policy_table.module_config = TESTED_DATA[2].module_config
    end
  }
  updatePreloadedPt(newUpdaters)
end

local function prepareInitialPreloadedPT()
  local initialUpdaters = {
    function(data)
      for key, value in pairs(data.policy_table.functional_groupings) do
        if not value.rpcs then
          data.policy_table.functional_groupings[key] = nil
        end
      end
    end,
    function(data)
      data.policy_table.module_config = TESTED_DATA[1].module_config
    end,
  }
  updatePreloadedPt(initialUpdaters)
end

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

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile(PRELOADED_PT_FILE_NAME)
prepareInitialPreloadedPT()

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')

function Test.checkLocalPT(checkTable)
  local expectedLocalPtValues
  local queryString
  local actualLocalPtValues
  local comparationResult
  local isTestPass = true
  for _, check in pairs(checkTable) do
    expectedLocalPtValues = check.expectedValues
    queryString = check.query
    actualLocalPtValues = executeSqliteQuery(queryString, constructPathToDatabase())
    if actualLocalPtValues then
      comparationResult = isValuesCorrect(actualLocalPtValues, expectedLocalPtValues)
      if not comparationResult then
        TestData:store(table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        TestData:store("ExpectedLocalPtValues")
        commonFunctions:userPrint(31, table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        commonFunctions:userPrint(35, "ExpectedLocalPtValues")
        for _, values in pairs(expectedLocalPtValues) do
          TestData:store(values)
          print(values)
        end
        TestData:store("ActualLocalPtValues")
        commonFunctions:userPrint(35, "ActualLocalPtValues")
        for _, values in pairs(actualLocalPtValues) do
          TestData:store(values)
          print(values)
        end
        isTestPass = false
      end
    else
      TestData:store("Test failed: Can't get data from LocalPT")
      commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
      isTestPass = false
    end
  end
  return isTestPass
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_VerifyInitialLocalPT()
  local is_test_fail = false
  os.execute("sleep 3")

  local checks = {
    { query = 'select preloaded_date from module_config', expectedValues = { tostring(TESTED_DATA[1].module_config.preloaded_date) } },
    { query = 'select exchange_after_x_ignition_cycles from module_config', expectedValues = {tostring( TESTED_DATA[1].module_config.exchange_after_x_ignition_cycles) } },
    { query = 'select exchange_after_x_kilometers from module_config', expectedValues = {tostring(TESTED_DATA[1].module_config.exchange_after_x_kilometers)} },
    { query = 'select exchange_after_x_days from module_config', expectedValues = {tostring(TESTED_DATA[1].module_config.exchange_after_x_days)} },
    { query = 'select timeout_after_x_seconds from module_config', expectedValues = {tostring(TESTED_DATA[1].module_config.timeout_after_x_seconds)} },
    { query = 'select certificate from module_config', expectedValues = {tostring(TESTED_DATA[1].module_config.certificate)} },
    { query = 'select * from notifications_by_priority where priority_value is "COMMUNICATION"',
      expectedValues = {"COMMUNICATION|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.COMMUNICATION)} },
    { query = 'select * from notifications_by_priority where priority_value is "EMERGENCY"',
      expectedValues = {"EMERGENCY|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.EMERGENCY)} },
    { query = 'select * from notifications_by_priority where priority_value is "NAVIGATION"',
      expectedValues = {"NAVIGATION|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.NAVIGATION)} },
    { query = 'select * from notifications_by_priority where priority_value is "VOICECOM"',
      expectedValues = {"VOICECOM|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.VOICECOM)} },
    { query = 'select * from notifications_by_priority where priority_value is "NORMAL"',
      expectedValues = {"NORMAL|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.NORMAL)} },
    { query = 'select * from notifications_by_priority where priority_value is "NONE"',
      expectedValues = {"NONE|"..tostring(TESTED_DATA[1].module_config.notifications_per_minute_by_priority.NONE)} },
      { query = 'select * from seconds_between_retry',
     expectedValues = {"0|"..tostring(TESTED_DATA[1].module_config.seconds_between_retries[1])} },
      { query = 'select * from endpoint where service is "0x04"',
     expectedValues = {"0x04|http://ivsu.software.ford.com/api/getsoftwareupdates|default"} }
  }

  if not self.checkLocalPT(checks) then
    commonFunctions:printError("ERROR: SDL has wrong values in LocalPT")
    is_test_fail = true
  end
  local preloaded_pt
  local preloaded_pt_table = executeSqliteQuery('select preloaded_pt from module_config', constructPathToDatabase())
  for _, v in pairs(preloaded_pt_table) do
    preloaded_pt = v
  end
  if(preloaded_pt == "1") then
    commonFunctions:printError("ERROR: preloaded_pt is true, should be false")
    is_test_fail = true
  end

  local vehicle_make_table = executeSqliteQuery('select vehicle_make from module_config', constructPathToDatabase())
  if( vehicle_make_table == nil ) then
    commonFunctions:printError("ERROR: new vehicle_make is null")
    is_test_fail = true
  else
    for _,v in pairs(vehicle_make_table) do
      vehicle_make = v
    end
  end

  local vehicle_model_table = executeSqliteQuery('select vehicle_model from module_config', constructPathToDatabase())
  if( vehicle_model_table == nil ) then
    commonFunctions:printError("ERROR: new vehicle_model is null")
    is_test_fail = true
  else
    for _,v in pairs(vehicle_make_table) do
      vehicle_model = v
    end
  end
  vehicle_year = executeSqliteQuery('select vehicle_year from module_config', constructPathToDatabase())
  if( vehicle_year == nil ) then
    commonFunctions:printError("ERROR: new vehicle_year is null")
    is_test_fail = true
  else
    for _,v in pairs(vehicle_make_table) do
      vehicle_year = v
    end
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

function Test:TestStep_StopSDL()
  StopSDL(self)
end

function Test.TestStep_LoadNewPreloadedPT()
  prepareNewPreloadedPT()
end

function Test:TestStep_StartSDL()
  StartSDL(config.pathToSDL, true, self)
end

function Test:Test_NewLocalPT()
  local is_test_fail = false
  os.execute("sleep 3")

  local checks = {
    { query = 'select preloaded_date from module_config', expectedValues = { tostring(TESTED_DATA[2].module_config.preloaded_date) } },
    { query = 'select exchange_after_x_ignition_cycles from module_config', expectedValues = {tostring( TESTED_DATA[2].module_config.exchange_after_x_ignition_cycles) } },
    { query = 'select exchange_after_x_kilometers from module_config', expectedValues = {tostring(TESTED_DATA[2].module_config.exchange_after_x_kilometers)} },
    { query = 'select exchange_after_x_days from module_config', expectedValues = {tostring(TESTED_DATA[2].module_config.exchange_after_x_days)} },
    { query = 'select timeout_after_x_seconds from module_config', expectedValues = {tostring(TESTED_DATA[2].module_config.timeout_after_x_seconds)} },
    { query = 'select certificate from module_config', expectedValues = {tostring(TESTED_DATA[2].module_config.certificate)} },
    { query = 'select * from notifications_by_priority where priority_value is "COMMUNICATION"',
      expectedValues = {"COMMUNICATION|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.COMMUNICATION)} },
    { query = 'select * from notifications_by_priority where priority_value is "EMERGENCY"',
      expectedValues = {"EMERGENCY|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.EMERGENCY)} },
    { query = 'select * from notifications_by_priority where priority_value is "NAVIGATION"',
      expectedValues = {"NAVIGATION|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.NAVIGATION)} },
    { query = 'select * from notifications_by_priority where priority_value is "VOICECOM"',
      expectedValues = {"VOICECOM|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.VOICECOM)} },
    { query = 'select * from notifications_by_priority where priority_value is "NORMAL"',
      expectedValues = {"NORMAL|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.NORMAL)} },
    { query = 'select * from notifications_by_priority where priority_value is "NONE"',
      expectedValues = {"NONE|"..tostring(TESTED_DATA[2].module_config.notifications_per_minute_by_priority.NONE)} },
       { query = 'select * from seconds_between_retry',
     expectedValues = {"0|"..tostring(TESTED_DATA[2].module_config.seconds_between_retries[1])} },
          { query = 'select * from endpoint where service is "0x04"',
     expectedValues = {"0x04|http://policies.telematics.ford.com/api/policies|default"} }
  }

  if not self.checkLocalPT(checks) then
    commonFunctions:printError("ERROR: SDL has wrong values in LocalPT")
    is_test_fail = true
  end
  local preloaded_pt
  local preloaded_pt_table = executeSqliteQuery('select preloaded_pt from module_config', constructPathToDatabase())
  for _, v in pairs(preloaded_pt_table) do
    preloaded_pt = v
  end
  if(preloaded_pt == "1") then
    commonFunctions:printError("ERROR: preloaded_pt is true, should be false")
    is_test_fail = true
  end

  local vehicle_make_new_table = executeSqliteQuery('select vehicle_make from module_config', constructPathToDatabase())
  for _,v in pairs(vehicle_make_new_table) do
    if(v ~= vehicle_make) then
      if(v == nil) then
        commonFunctions:printError("ERROR: new vehicle_make is null")
        is_test_fail = true
      else
        commonFunctions:printError("ERROR: new vehicle_make should not be rewritten. Exprected: "..tostring(vehicle_make) .." . Real: "..tostring(v) )
        is_test_fail = true
      end
    end
  end
  local vehicle_model_new_table = executeSqliteQuery('select vehicle_model from module_config', constructPathToDatabase())
  for _,v in pairs(vehicle_model_new_table) do
    if(v ~= vehicle_model) then
      if(v == nil) then
        commonFunctions:printError("ERROR: new vehicle_model is null")
        is_test_fail = true
      else
        commonFunctions:printError("ERROR: new vehicle_model should not be rewritten. Exprected: "..tostring(vehicle_model) .." . Real: "..tostring(v) )
        is_test_fail = true
      end
    end
  end
  local vehicle_year_new_table = executeSqliteQuery('select vehicle_year from module_config', constructPathToDatabase())
  for _,v in pairs(vehicle_year_new_table) do
    if(v ~= vehicle_year) then
      if(v == nil) then
        commonFunctions:printError("ERROR: new vehicle_year is null")
        is_test_fail = true
      else
        commonFunctions:printError("ERROR: new vehicle_year should not be rewritten. Exprected: "..tostring(vehicle_year) .." . Real: "..tostring(v) )
        is_test_fail = true
      end
    end
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
