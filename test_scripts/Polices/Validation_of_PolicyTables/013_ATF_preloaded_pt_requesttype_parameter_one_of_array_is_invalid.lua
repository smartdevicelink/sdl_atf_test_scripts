---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] PreloadPT one invalid and other valid values in "RequestType" array
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has has several values in "RequestType" array and one of them is invalid
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Add several values in "RequestType" array (one of them is invalid) in PreloadedPT json file
-- Start SDL with created PreloadedPT json file
--
-- Expected result:
-- SDL must cut off this invalid value and continue working.
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
local config = require('config')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"
local INCORRECT_REQUEST_TYPE = "SHTTPS"
Test.APP_POLICIES_DATA = {
  ["007"] = {
    keep_context = true,
    steal_focus = true,
    priority = "NORMAL",
    default_hmi = "NONE",
    groups = {"BaseBeforeDataConsent"},
    RequestType = {
      "TRAFFIC_MESSAGE_CHANNEL",
      "PROPRIETARY",
      INCORRECT_REQUEST_TYPE, -- incorrect value, correct is HTTP
      "FILE_RESUME"
    },
    nicknames = {"MI6"}
  }
}

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local SDL = require('modules/SDL')
local json = require("modules/json")

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

local function isRequestTypeValuesCorrect(actualValues, expectedValues)
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

function Test:checkLocalPT()
  local app_id = next(self.APP_POLICIES_DATA, nil)
  local expectedLocalPtRequestTypeValues = {}
  local index = 1
  for _, value in ipairs(self.APP_POLICIES_DATA[app_id].RequestType) do
    if value ~= INCORRECT_REQUEST_TYPE then
      expectedLocalPtRequestTypeValues[index] = value
      index = index + 1
    end
  end

  local queryString = 'SELECT request_type FROM request_type WHERE application_id = "007"'
  local actualLocalPtRequestTypeValues = executeSqliteQuery(queryString, constructPathToDatabase())
  if actualLocalPtRequestTypeValues then
    local result = isRequestTypeValuesCorrect(actualLocalPtRequestTypeValues, expectedLocalPtRequestTypeValues)
    if not result then
      commonFunctions:userPrint(31, "Test failed: SDL upload to LocalPT incorrect RequestType values")
    end
    return result
  else
    commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
    return false
  end
end

function Test.checkSdl()
  local status = SDL:CheckStatusSDL()
  if status ~= SDL.RUNNING then
    commonFunctions:userPrint(31, "Test failed: SDL aren't running with valid PreloadedPT json file")
    return false
  end
  return true
end

function Test.backupPreloadedPT()
  os.execute(table.concat({"cp ", config.pathToSDL, PRELOADED_PT_FILE_NAME, ' ', config.pathToSDL, "backup_", PRELOADED_PT_FILE_NAME}))
end

function Test:updatePreloadedPT()
  local changedParameters = self.APP_POLICIES_DATA

  local pathToFile = config.pathToSDL .. PRELOADED_PT_FILE_NAME

  local file = io.open(pathToFile, "r")
  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  if data then
    for key, value in pairs(data.policy_table.functional_groupings) do
      if not value.rpcs then
        data.policy_table.functional_groupings[key] = nil
      end
    end

    for key, value in pairs(changedParameters) do
      data.policy_table.app_policies[key] = value
    end
  end

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

function Test.restorePreloadedPT()
  os.execute(table.concat({"mv ", config.pathToSDL, "backup_", PRELOADED_PT_FILE_NAME, " ", config.pathToSDL, PRELOADED_PT_FILE_NAME}))
end

--[[ Preconditions ]]
function Test:Precondition_StopSdl()
  StopSDL(self)
end

function Test:Precondition()
  commonSteps:DeletePolicyTable()
  self.backupPreloadedPT()
  self:updatePreloadedPT()
end

--[[ Test ]]
function Test:Test_StartSdl()
  StartSDL(config.pathToSDL, true, self)
end

function Test:Test()
  os.execute("sleep 3")
  self.checkSdl()
  self:checkLocalPT()
end

--[[ Postconditions ]]
function Test:Postconditions()
  self.restorePreloadedPT()
end

commonFunctions:SDLForceStop()
