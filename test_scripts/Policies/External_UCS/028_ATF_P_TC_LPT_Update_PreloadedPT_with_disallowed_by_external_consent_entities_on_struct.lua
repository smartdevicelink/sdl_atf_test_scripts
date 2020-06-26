---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PreloadedPT with "disallowed_by_external_consent_entities_on" struct
--
-- Description:
-- In case:
-- SDL uploads PreloadedPolicyTable with "disallowed_by_external_consent_entities_on:
-- [entityType: <Integer>, entityId: <Integer>]" -> of "<functional grouping>" -> from "functional_groupings" section
-- SDL must:
-- a. consider this PreloadedPT as valid (with the pre-conditions of all other valid PreloadedPT content)
-- b. add this "disallowed_by_external_consent_entities_on: [entityType: <Integer>, entityId: <Integer>]"
-- field of the corresponding "<functional grouping>" in the Policies database.
--
-- Preconditions:
-- 1. Stop SDL (Ignition Off)
-- 2. Modify PreloadedPolicyTable (add 'disallowed_by_external_consent_entities_on' section)
-- 3. Initiate Local Policy Table update by setting 'preloaded_date' parameter
--
-- Steps:
-- 1. Start SDL (Ignition On)
-- 2. Check SDL status
-- 3. Register app
-- 4. Activate app
-- 5. Verify PTSnapshot
--
-- Expected result:
-- a. Status = 1 (SDL is running)
-- b. PTSnapshot contains 'disallowed_by_external_consent_entities_on' section
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local sdl = require('SDL')
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')

--[[ Local variables ]]
local grpId = "Location-1"
local checkedSection = "disallowed_by_external_consent_entities_on"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
testCasesForExternalUCS.removePTS()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:CheckPreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json"
  local preloadedTable = testCasesForExternalUCS.createTableFromJsonFile(preloadedFile)
  local result = true
  if preloadedTable
  and preloadedTable.policy_table
  and preloadedTable.policy_table.functional_groupings
  then
    for _, v in pairs(preloadedTable.policy_table.functional_groupings) do
      if v[checkedSection] then
        result = false
      end
    end
  end
  if result == false then
    self:FailTestCase("Section '" .. checkedSection .. "'' was found in PreloadedPT")
  end
end

function Test:CheckSDLStatus()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

function Test:StopSDL_IGNITION_OFF()
  testCasesForExternalUCS.ignitionOff(self)
end

function Test:CheckSDLStatus()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.STOPPED)
end

function Test.UpdatePreloadedPT()
  local updateFunc = function(preloadedTable)
    preloadedTable.policy_table.module_config.preloaded_date = os.date("%Y-%m-%d")
    preloadedTable.policy_table.functional_groupings[grpId][checkedSection] = {
      {
        entityID = 128,
        entityType = 0
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

function Test:CheckSDLStatus()
  testCasesForExternalUCS.checkSDLStatus(self, sdl.RUNNING)
end

function Test:InitHMI()
  self:initHMI()
end

function Test:InitHMI_onReady()
  self:initHMI_onReady()
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

function Test:ActivateApp()
  testCasesForExternalUCS.activateApp(self, 1)
end

function Test:CheckPTS()
  if not testCasesForExternalUCS.pts then
    self:FailTestCase("PTS was not created")
  else
    if testCasesForExternalUCS.pts.policy_table.functional_groupings[grpId][checkedSection] == nil then
      self:FailTestCase("Section '" .. checkedSection .. "' was not found in PTS")
    else
      print("Section '".. checkedSection .. "' exists in 'functional_groupings['" .. grpId .. "'] in PTS")
      print(" => OK")
    end
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
