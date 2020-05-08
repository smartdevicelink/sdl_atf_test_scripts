---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: SnapshotPT without "disallowed_by_external_consent_entities_on" struct
--
-- Description:
-- In case:
-- SDL Policies database omits “disallowed_by_external_consent_entities_on:
-- [entityType: <Integer>, entityId: <Integer>]” struct -> in "<functional grouping>"
-- -> from "functional_groupings" section,
-- and SDL is triggered to create a SnapshotPolicyTable
-- SDL must:
-- omit this "disallowed_by_external_consent_entities_on: [entityType: <Integer>, entityId: <Integer>]" field
-- in the corresponding "<functional grouping>" -> in the SnapshotPolicyTable.
--
-- Preconditions:
-- 1. Start SDL (make sure 'disallowed_by_external_consent_entities_on' section is omitted in PreloadedPT)
--
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Verify PTSnapshot
--
-- Expected result:
-- Section "disallowed_by_external_consent_entities_on" is omitted
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
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')

--[[ Local variables ]]
local grpId = "Location-1"
local checkedSection = "disallowed_by_external_consent_entities_on"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
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
    if testCasesForExternalUCS.pts.policy_table.functional_groupings[grpId][checkedSection] ~= nil then
      self:FailTestCase("Section '" .. checkedSection .. "' was found in PTS")
    else
      print("Section '".. checkedSection .. "' doesn't exist in PTS")
      print(" => OK")
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

return Test
