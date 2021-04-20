---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "language" storage into PolicyTable
--
-- Description:
-- Getting "language" from HMI and storing it by PolicyManager
-- 1. Used preconditions:
-- Stop SDL
-- Delete log file and policy table if any
-- Start SDL
--
-- 2. Performed steps
-- Check policy table for 'language'
--
-- Expected result:
-- SDL must send GetSystemInfo to HMI;
-- SDL must set received value to "language" section of "module_meta" section in PolicyTable
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFileAndPolicyTable()
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI()
  self:initHMI()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep1_SDL_requests_systemInfo_on_InitHMI()
  self:initHMI_onReady()
  EXPECT_HMICALL("BasicCommunication.GetSystemInfo"):Times(AtLeast(1))
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.GetSystemInfo", "SUCCESS", {ccpu_version ="OpenS",
          language ="EN-US",wersCountryCode = "open_wersCountryCode"})
    end)
end

function Test:TestStep2_Check_language_stored_in_PT()
  local query
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select language from module_meta\""
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select language from module_meta\""
  else commonFunctions:userPrint(31, "policy.sqlite is not found")
  end

  if query ~= nil then
    os.execute("sleep 3")
    local handler = io.popen(query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()

    --print("result:" ..result)
    if result == "EN-US" then
      return true
    else
      self:FailTestCase("language in DB has unexpected value: " .. tostring(result))
      return false
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
