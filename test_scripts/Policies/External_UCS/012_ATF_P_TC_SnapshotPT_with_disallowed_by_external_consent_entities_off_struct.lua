---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: SnapshotPT with "disallowed_by_external_consent_entities_off" struct
--
-- Description:
-- In case:
-- SDL Policies database contains “disallowed_by_external_consent_entities_off:
-- [entityType: <Integer>, entityId: <Integer>]” struct -> in "<functional grouping>"
-- -> from "functional_groupings" section,
-- and SDL is triggered to create a SnapshotPolicyTable
-- SDL must:
-- include this “disallowed_by_external_consent_entities_off:
-- [entityType: <Integer>, entityId: <Integer>]” field with the corresponding value
-- in the corresponding "<functional grouping>" -> to the SnapshotPolicyTable.
--
-- Preconditions:
-- 1. Make sure 'disallowed_by_external_consent_entities_off' section is defined in PreloadedPT
-- 2. Start SDL
--
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Verify PTSnapshot
--
-- Expected result:
-- PTSnapshot contains 'disallowed_by_external_consent_entities_off' section
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
local json = require("modules/json")
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')

--[[ Local variables ]]
local grpId = "Location-1"
local checkedSection = "disallowed_by_external_consent_entities_off"

--[[ Local Functions ]]
local function replaceSDLPreloadedPtFile()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json"
  local preloadedTable = testCasesForExternalUCS.createTableFromJsonFile(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  --
  preloadedTable.policy_table.functional_groupings[grpId][checkedSection] = {
    {
      entityID = 128,
      entityType = 0
    }
  }
  testCasesForExternalUCS.createJsonFileFromTable(preloadedTable, preloadedFile)
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
replaceSDLPreloadedPtFile()
testCasesForExternalUCS.removePTS()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  testCasesForExternalUCS.startSession(self, 1)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

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
      print("Section '".. checkedSection .. "' exists in PTS")
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
