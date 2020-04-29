---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PreloadedPT with "external_consent_status_groups" struct
--
-- Description:
-- In case:
-- SDL uploads PreloadedPolicyTable with "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]" -> of "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section
-- SDL must:
-- a. consider such PreloadedPT is invalid
-- b. log corresponding error internally
-- c. shut SDL down
--
-- Preconditions:
-- 1. Stop SDL (Ignition Off)
-- 2. Modify PreloadedPolicyTable (add 'external_consent_status_groups' section)
-- 3. Initiate Local Policy Table update by setting 'preloaded_date' parameter
--
-- Steps:
-- 1. Start SDL (Ignition On)
-- 2. Check SDL status
--
-- Expected result:
-- Status = 0 (SDL is stopped)
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local sdl = require('SDL')
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:CheckSDLStatus_1_RUNNING()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  testCasesForExternalUCS.startSession(self, 1)
end

function Test:RAI()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:StopSDL_IGNITION_OFF()
  testCasesForExternalUCS.ignitionOff(self)
end

function Test:CheckSDLStatus_2_STOPPED()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test.UpdatePreloadedPT()
  local updateFunc = function(preloadedTable)
    preloadedTable.policy_table.module_config.preloaded_date = os.date("%Y-%m-%d")
    preloadedTable.policy_table.device_data = {
      [utils.getDeviceMAC()] = {
        user_consent_records = {
          [config.application1.registerAppInterfaceParams.fullAppID] = {
            external_consent_status_groups = {
              Location = false
            }
          }
        }
      }
    }
  end
  testCasesForExternalUCS.updatePreloadedPT(updateFunc)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:CheckSDLStatus_3_STOPPED()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test:CheckLog()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Parsed table is not valid policy_table")
  if result ~= true then
    self:FailTestCase("Error message was not found in log file")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

function Test.RestorePreloadedFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
