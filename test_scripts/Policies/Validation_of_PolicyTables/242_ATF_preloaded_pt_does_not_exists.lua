---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policy] log an error if PreloadedPT does not exist at the path defined in .ini file
-- [INI file] [Policy]: PreloadedPT json location
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT does not exist at the path defined in .ini file
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create correct PreloadedPolicyTable file with default path
-- Change path to PreloadedPolicyTable file defined in .ini file (PreloadedPolicyTable can't be found by new path)
-- Start SDL
--
-- Expected result:
-- SDL shutted down
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local sdl = require('modules/SDL')

--[[ Local Functions ]]
local function checkSDLStatus(test, expStatus)
  local actStatus = sdl:CheckStatusSDL()
  print("SDL status: " .. tostring(actStatus))
  if actStatus ~= expStatus then
    local msg = "Expected SDL status: " .. expStatus .. ", actual: " .. actStatus
    test:FailTestCase(msg)
  end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Local variables ]]
local PPT_NEW_FOLDER = "newppt"
local PPT_FILE_NAME = "sdl_preloaded_pt.json"
local old_path_to_preloaded_pt

--[[ Local functions ]]
local function set_value_in_sdl_ini(parameter_name, parameter_value)
  local sdl_ini_file_name = config.pathToSDL .. "smartDeviceLink.ini"
  local old_parameter_value
  local file = assert(io.open(sdl_ini_file_name, "r"))
  if file then
    local file_content = file:read("*a")
    file:close()
    old_parameter_value = string.match(file_content, parameter_name .. "%s*=%s*(%S+)")
    if old_parameter_value then
      file_content = string.gsub(file_content, parameter_name .. "%s*=%s*%S+", parameter_name .. " = " .. parameter_value)
    else
      local last_char_of_file = string.sub(file_content, string.len(file_content))
      if last_char_of_file == "\n" then
        last_char_of_file = ""
      else
        last_char_of_file = "\n"
      end
      file_content = table.concat({file_content, last_char_of_file, parameter_name, " = ", parameter_value, "\n"})
      old_parameter_value = nil
    end
    file = assert(io.open(sdl_ini_file_name, "w"))
    if file then
      file:write(file_content)
      file:close()
      return true, old_parameter_value
    else
      return false
    end
  else
    return false
  end
end

function Test.create_path_to_preloaded_pt(path)
  local full_path = config.pathToSDL .. path
  os.execute("mkdir " .. full_path)
  return table.concat({full_path, "/", PPT_FILE_NAME})
end

function Test.change_ppt_path_in_sdl_ini(new_path)
  local result, old_path = set_value_in_sdl_ini("PreloadedPT", new_path)
  if not result then
    commonFunctions:userPrint(31, "Test can't change SDL .ini file")
  end
  return old_path
end

function Test.remove_path_to_preloaded_pt(path)
  local full_path = config.pathToSDL .. path
  os.execute("rm -r -f " .. full_path)
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_StopSDL()
  StopSDL(self)
end

function Test:Precondition_ChangePathToPreloadedPT()
  commonSteps:DeletePolicyTable()

  local new_path_to_preloaded_pt = self.create_path_to_preloaded_pt(PPT_NEW_FOLDER)
  old_path_to_preloaded_pt = self.change_ppt_path_in_sdl_ini(new_path_to_preloaded_pt)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test.TestStep_start_sdl()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:TestStep_checkSdl_Running()
  checkSDLStatus(self, sdl.STOPPED)
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result ~= true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (result ~= true) then
    self:FailTestCase("Error: 'BasicCommunication.OnSDLClose' is observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postconditions()
  self.remove_path_to_preloaded_pt(PPT_NEW_FOLDER)
  self.change_ppt_path_in_sdl_ini(old_path_to_preloaded_pt)
end

function Test:Postconditions_StopSDL()
  StopSDL(self)
end

return Test
