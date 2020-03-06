---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Merging rules for "app_policies" section
--
-- Description:
-- Check of merging rules for "app_policies" section
-- 1. Used preconditions
-- Delete files and policy table from previous ignition cycle if any
-- Start SDL with PreloadedPT json file with "preloaded_date" parameter and one <appid> subsection and "default", "device", "pre_DataConsent" subsections
-- 2. Performed steps
-- Stop SDL
-- Start SDL with corrected PreloadedPT json file with "preloaded_date" parameter with bigger value
-- and one <appid> subsection and "default", "device", "pre_DataConsent" subsections with other data
--
-- Expected result:
-- leave the "<appID>" sub-section of "app_policies" section at LocalPT without changes
-- overwrite fields&values of "default", "device", "pre_DataConsent" subsections based on updated PreloadedPT
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require("modules/json")

--[[ Local Variables ]]
config.pathToSDL = commonPreconditions.GetPathToSDL()
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"

local TESTED_DATA = {
  preloaded_date = {"1988-12-01","2015-05-02"},
  {
    app_policies =
    {
      default =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"}
      },
      ["007"] =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "NONE",
        groups = {"Base-4"}
      },
      device =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-6", "Base-4"}
      },
      pre_DataConsent =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"BaseBeforeDataConsent"}
      },
      ["003"] =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "NONE",
        groups = {"Base-4"}
      }
    }
  },
  {
    app_policies =
    {
      default =
      {
        keep_context = true,
        steal_focus = true,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"BaseBeforeDataConsent"}
      },
      device =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "BACKGROUND",
        groups = {"Base-6"}
      },
      pre_DataConsent =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"}
      },
      ["007"] =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"BaseBeforeDataConsent"}
      },
      ["009"] =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"}
      }
    }
  },
  {
    app_policies =
    {
      default =
      {
        keep_context = true,
        steal_focus = true,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"BaseBeforeDataConsent"}
      },
      device =
      {
        keep_context = false,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "BACKGROUND",
        groups = {"Base-6"}
      },
      pre_DataConsent =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"}
      },
      ["007"] =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "NONE",
        groups = {"Base-4"}
      },
      ["003"] =
      {
        keep_context = true,
        steal_focus = false,
        priority = "NORMAL",
        default_hmi = "NONE",
        groups = {"Base-4"}
      }
    }
  }
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

commonPreconditions:BackupFile(PRELOADED_PT_FILE_NAME)
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
      data.policy_table.module_config.preloaded_date = TESTED_DATA.preloaded_date[1]
    end,
    function(data)
      data.policy_table.app_policies = TESTED_DATA[1].app_policies
    end
  }
  updatePreloadedPt(initialUpdaters)
end
prepareInitialPreloadedPT()

local function prepareNewPreloadedPT()
  local newUpdaters = {
    function(data)
      for key, value in pairs(data.policy_table.functional_groupings) do
        if not value.rpcs then
          data.policy_table.functional_groupings[key] = nil
        end
      end
    end,
    function(data)
      data.policy_table.module_config.preloaded_date = TESTED_DATA.preloaded_date[2]
    end,
    function(data)
      data.policy_table.app_policies = TESTED_DATA[2].app_policies
    end
  }
  updatePreloadedPt(newUpdaters)
end

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General configuration parameters ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('user_modules/AppTypes')

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

function Test.backupPreloadedPT(backupPrefix)
  os.execute(table.concat({"cp ", config.pathToSDL, PRELOADED_PT_FILE_NAME, " ", config.pathToSDL, backupPrefix, PRELOADED_PT_FILE_NAME}))
end

function Test.restorePreloadedPT(backupPrefix)
  os.execute(table.concat({"mv ", config.pathToSDL, backupPrefix, PRELOADED_PT_FILE_NAME, " ", config.pathToSDL, PRELOADED_PT_FILE_NAME}))
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_VerifyInitialLocalPT()
  os.execute("sleep 3")
  TestData:store("Initial Local PT is stored", constructPathToDatabase(), "initial_policy.sqlite")
  local checks = {
    {
      query = 'select preloaded_date from module_config',
      expectedValues = {TESTED_DATA.preloaded_date[1]}
    },
    {
      query = 'select a.id, a.keep_context, a.steal_focus, a.default_hmi, a.priority_value, fg.name from application a inner join app_group ag on a.id = ag.application_id inner join functional_group fg on ag.functional_group_id = fg.id',
      expectedValues = (function(structure)

          local function evalBoolean(val)
            if not val then
              return 0
            else
              return 1
            end
          end

          local result = {}
          for key, value in pairs(structure) do
            for i = 1, #value.groups do
              table.insert(result, table.concat({tostring(key), "|", evalBoolean(value.keep_context), "|", evalBoolean(value.steal_focus), "|", value.default_hmi, "|", value.priority, "|", value.groups[i]}))
            end
          end
          return result
          end)(TESTED_DATA[1].app_policies)
      }
    }
    if not self.checkLocalPT(checks) then
      self:FailTestCase("SDL has wrong values in LocalPT")
    end
  end

  function Test:TestStep_StopSDL()
    StopSDL(self)
  end

  function Test.TestStep_PrepareNewPreloadedPT()
    prepareNewPreloadedPT()
  end

  function Test:TestStep_StartSDL()
    StartSDL(config.pathToSDL, true, self)
  end

  function Test:TestStep_VerifyNewLocalPT()
    os.execute("sleep 3")
    TestData:store("New Local PT is stored", constructPathToDatabase(), "new_policy.sqlite")
    local checks = {
      {
        query = 'select preloaded_date from module_config',
        expectedValues = {TESTED_DATA.preloaded_date[2]}
      },
      {
        query = 'select a.id, a.keep_context, a.steal_focus, a.default_hmi, a.priority_value, fg.name from application a inner join app_group ag on a.id = ag.application_id inner join functional_group fg on ag.functional_group_id = fg.id',
        expectedValues = (function(structure)

            local function evalBoolean(val)
              if not val then
                return 0
              else
                return 1
              end
            end

            local result = {}
            for key, value in pairs(structure) do
              for i = 1, #value.groups do
                table.insert(result, table.concat({tostring(key), "|", evalBoolean(value.keep_context), "|", evalBoolean(value.steal_focus), "|", value.default_hmi, "|", value.priority, "|", value.groups[i]}))
              end
            end
            return result
            end) (TESTED_DATA[3].app_policies)
        }
      }
      if not self.checkLocalPT(checks) then
        self:FailTestCase("SDL has wrong values in LocalPT")
      end
    end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition()
  StopSDL()
end

return Test
