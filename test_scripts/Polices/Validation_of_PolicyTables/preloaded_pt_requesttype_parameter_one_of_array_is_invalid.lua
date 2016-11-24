---------------------------------------------------------------------------------------------
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has has several values in "RequestType" array and one of them is invalid
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Add several values in "RequestType" array (one of them is invalid) in PreloadedPT json file
-- Start SDL with created PreloadedPT json file

-- Requirement summary:
-- [Policies] PreloadPT one invalid and other valid values in "RequestType" array
--
-- Expected result:
-- SDL must cut off this invalid value and continue working.
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
local config = require('config')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
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

--[[ Preconditions ]]
function Test.backup_preloaded_pt()
  os.execute(table.concat({"cp ", config.pathToSDL, PRELOADED_PT_FILE_NAME, ' ', config.pathToSDL, "backup_", PRELOADED_PT_FILE_NAME}))
end

function Test:update_preloaded_pt()
  local changed_parameters = self.APP_POLICIES_DATA

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

    for key, value in pairs(changed_parameters) do
      data.policy_table.app_policies[key] = value
    end
  end

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

local function construct_path_to_database()
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    return config.pathToSDL .. "storage/policy.sqlite"
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    return config.pathToSDL .. "policy.sqlite"
  else
    commonFunctions:userPrint(31, "policy.sqlite is not found" )
    return nil
  end
end

function Test:Precondition_stop_sdl()
  StopSDL(self)
end

function Test:Precondition()
  commonSteps:DeletePolicyTable()
  self.backup_preloaded_pt()
  self:update_preloaded_pt()
end

--[[ Test ]]

local function execute_sqlite_query(raw_query_string, db_file_path)
  if not db_file_path then
    return nil
  end
  local query_execution_result = {}
  local query_string = table.concat({"sqlite3 ", db_file_path, " '", raw_query_string, "'"})
  local file = io.popen(query_string, 'r')
  if file then
    local index = 1
    for line in file:lines() do
      query_execution_result[index] = line
      index = index + 1
    end
    file:close()
    return query_execution_result
  else
    return nil
  end
end

local function is_request_type_values_correct(actual_values, expected_values)
  if #actual_values ~= #expected_values then
    return false
  end

  local tmp_expected_values = {}
  for i = 1, #expected_values do
    tmp_expected_values[i] = expected_values[i]
  end

  local is_found
  for j = 1, #actual_values do
    is_found = false
    for key, value in pairs(tmp_expected_values) do
      if value == actual_values[j] then
        is_found = true
        tmp_expected_values[key] = nil
        break
      end
    end
    if not is_found then
      return false
    end
  end
  if next(tmp_expected_values) then
    return false
  end
  return true
end

function Test:check_local_pt()
  local app_id = next(self.APP_POLICIES_DATA, nil)
  local expected_local_pt_request_type_values = {}
  local index = 1
  for _, value in ipairs(self.APP_POLICIES_DATA[app_id].RequestType) do
    if value ~= INCORRECT_REQUEST_TYPE then
      expected_local_pt_request_type_values[index] = value
      index = index + 1
    end
  end

  local query_string = 'SELECT request_type FROM request_type WHERE application_id = "007"'
  local actual_local_pt_request_type_values = execute_sqlite_query(query_string, construct_path_to_database())
  if actual_local_pt_request_type_values then
    local result = is_request_type_values_correct(actual_local_pt_request_type_values, expected_local_pt_request_type_values)
    if not result then
      commonFunctions:userPrint(31, "Test failed: SDL upload to LocalPT incorrect RequestType values")
    end
    return result
  else
    commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
    return false
  end
end

function Test.check_sdl()
  local status = SDL:CheckStatusSDL()
  if status ~= SDL.RUNNING then
    commonFunctions:userPrint(31, "Test failed: SDL aren't running with valid PreloadedPT json file")
    return false
  end
  return true
end

function Test:Test_start_sdl()
  StartSDL(config.pathToSDL, true, self)
end

function Test:Test()
  os.execute("sleep 3")
  self.check_sdl()
  self:check_local_pt()
end

--[[ Postconditions ]]
function Test.restore_preloaded_pt()
  os.execute(table.concat({"mv ", config.pathToSDL, "backup_", PRELOADED_PT_FILE_NAME, " ", config.pathToSDL, PRELOADED_PT_FILE_NAME}))
end

function Test:Postconditions()
  self.restore_preloaded_pt()
end

commonFunctions:SDLForceStop()
