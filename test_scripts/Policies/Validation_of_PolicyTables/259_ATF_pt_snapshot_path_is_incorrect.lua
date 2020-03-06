---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Name defined in PathToSnapshot of .ini file is incorrect for the specific OS
-- [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
--
-- Behavior of SDL during start SDL with correct path to PathToSnapshot in INI file for the specific OS (Linux)
-- 1. Used preconditions:
-- Do not start default SDL
-- 2. Performed steps:
-- Set incorrect PathToSnapshot path in INI file for the specific OS (Linux)
-- Start SDL
--
-- Expected result:
-- SDL must shutdown
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
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
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Local Variables ]]
local INCORRECT_LINUX_PATH_TO_POLICY_SNAPSHOT_FILE = "-\tsdl$snapshot.json"

--[[ Local Functions ]]

local function setValueInSdlIni(parameterName, parameterValue)
  local sdlIniFileName = config.pathToSDL .. "smartDeviceLink.ini"
  local oldParameterValue
  local file = assert(io.open(sdlIniFileName, "r"))
  if file then
    local fileContent = file:read("*a")
    file:close()
    oldParameterValue = string.match(fileContent, parameterName .. "%s*=%s*(%S+)")
    if oldParameterValue then
      fileContent = string.gsub(fileContent, parameterName .. "%s*=%s*%S+", parameterName .. " = " .. parameterValue)
    else
      local lastCharOfFile = string.sub(fileContent, string.len(fileContent))
      if lastCharOfFile == "\n" then
        lastCharOfFile = ""
      else
        lastCharOfFile = "\n"
      end
      fileContent = table.concat({fileContent, lastCharOfFile, parameterName, " = ", parameterValue, "\n"})
      oldParameterValue = nil
    end
    file = assert(io.open(sdlIniFileName, "w"))
    if file then
      file:write(fileContent)
      file:close()
      return true, oldParameterValue
    else
      return false
    end
  else
    return false
  end
end

function Test.changePtsPathInSdlIni(newPath)
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  local result, oldPath = setValueInSdlIni("PathToSnapshot", newPath)
  if not result then
    commonFunctions:userPrint(31, "Test can't change SDL .ini file")
  end
  return oldPath
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_StopSDL()
  StopSDL(self)
end

function Test:Precondition_ReloadNewINIFile()
  self.changePtsPathInSdlIni(INCORRECT_LINUX_PATH_TO_POLICY_SNAPSHOT_FILE)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test.TestStep_start_sdl()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:TestStep_VerifySDL_Stops()
  checkSDLStatus(self, sdl.STOPPED)
  -- Errors for SDL can't be checked in log, because SDL stops imediatelly because of incorrect path.
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Restore_INI()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
