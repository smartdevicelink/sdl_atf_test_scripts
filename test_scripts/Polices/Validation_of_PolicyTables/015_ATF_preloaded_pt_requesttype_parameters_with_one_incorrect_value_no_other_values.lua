---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] PreloadPT the only one invalid value in "RequestType" array
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has one value in "RequestType" array and it is invalid
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Add one invalid value in "RequestType" array in PreloadedPT json file
-- Start SDL with created PreloadedPT json file
--
-- Expected result:
-- SDL must shutdown
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
local config = require('config')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"
local INCORRECT_REQUEST_TYPE = "TRAFIC_MESSAGE_CHANNEL"
Test.APP_POLICIES_DATA = {
  ["007"] = {
    keep_context = true,
    steal_focus = true,
    priority = "NORMAL",
    default_hmi = "NONE",
    groups = {"BaseBeforeDataConsent"},
    RequestType = {
      INCORRECT_REQUEST_TYPE,
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
function Test.backupPreloadedPT()
  os.execute(table.concat({"cp ", config.pathToSDL, PRELOADED_PT_FILE_NAME, ' ', config.pathToSDL, "backup_", PRELOADED_PT_FILE_NAME}))
end

function Test:updatePreloadedPT()
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

function Test.checkSdl()
  local status = SDL:CheckStatusSDL()
  if status == SDL.RUNNING then
    commonFunctions:userPrint(31, "Test failed: SDL is running with invalid PreloadedPT json file")
    return false
  end
  return true
end

function Test:Test_StartSdl()
  StartSDL(config.pathToSDL, true, self)
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
function Test:Test()
  os.execute("sleep 3")
  self.checkSdl()
end

--[[ Postconditions ]]
function Test:Postconditions()
  self.restorePreloadedPT()
end

commonFunctions:SDLForceStop()
