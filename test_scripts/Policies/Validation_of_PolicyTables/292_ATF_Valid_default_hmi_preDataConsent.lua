---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pre_DataConsent" policies and "default_hmi" validation
--
-- Description:
-- Validation of "default_hmi" sub-section in "pre_DataConsent" if "pre_DataConsent" policies assigned to the application.
-- Checking correct value "BACKGROUND"
-- 1. Used preconditions:
-- SDL and HMI are running
-- Connect device
--
-- 2. Performed steps
-- Add second session("pre_DataConsent" policies are assigned to the application)-> PTU is triggered
--
-- Expected result:
-- PoliciesManager must validate "default_hmi"(BACKGROUND) sub-section in "pre_DataConsent" and treat it valid
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Functions ]]
local function Backup_preloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function Restore_preloaded()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function Set_default_hmi_background()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.app_policies["pre_DataConsent"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "BACKGROUND",
    groups = {"BaseBeforeDataConsent"}
  }
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test.Precondition_Backup_preloadedPT()
  Backup_preloaded()
end

function Test.Precondition_Set_default_hmi_background()
  Set_default_hmi_background()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.TestStep_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test.TestStep_Verify_valid_default_hmi_Preloaded()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose"):Times(0)
end

function Test:TestStep_CheckSDLLogError()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  -- result is true in case error is logged.
  if (result == true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' should not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded()
  Restore_preloaded()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
