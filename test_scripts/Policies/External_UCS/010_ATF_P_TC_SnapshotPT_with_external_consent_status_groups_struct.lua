---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: SnapshotPT with "external_consent_status_groups" param
-- [Policies] External UCS: "ON" updates in allowed "consent_groups" and "external_consent_status_groups" when externalConsentStatus changes to "OFF"
--
-- Description:
-- In case:
-- SDL Policies database contains "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]” param-> in "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section,
-- and SDL is triggered to create a SnapshotPolicyTable
-- SDL must:
-- add this "external_consent_status_groups: [<functional_grouping>: <Boolean>]” field
-- in the corresponding "appID" section -> in the SnapshotPolicyTable.
--
-- Preconditions:
-- 1. Modify PreloadedPT by adding 'disallowed_by_external_consent_entities_on' section
--
-- Steps:
-- 1. Register app
-- 2. Send SDL.OnAppPermissionConsent (change ON -> OFF)
-- 3. Activate app
-- 4. Verify PTSnapshot
--
-- Expected result:
-- Section "external_consent_status_groups" is added for app section
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local appId = config.application1.registerAppInterfaceParams.appID
local grpId = "Location-1"
local checkedSection = "external_consent_status_groups"

--[[ Local Functions ]]
local function replaceSDLPreloadedPtFile()
  local preloadedFile = commonPreconditions:GetPathToSDL() ..
  commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = testCasesForExternalUCS.createTableFromJsonFile(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  --
  preloadedTable.policy_table.app_policies[appId] = {
    default_hmi = "NONE",
    keep_context = false,
    priority = "NONE",
    steal_focus = false,
    groups = {
      "Base-4", grpId
    }
  }
  preloadedTable.policy_table.functional_groupings[grpId].disallowed_by_external_consent_entities_on = {
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

function Test:StartSession_1()
  testCasesForExternalUCS.startSession(self, 1)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI_1()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:ActivateApp_1()
  testCasesForExternalUCS.activateApp(self, 1)
end

function Test:SendExternalConsent()
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { source = "GUI",
      externalConsentStatus = {
        { entityType = 0, entityID = 128, status = "OFF" }
    } })
end

function Test.RemovePTS()
  testCasesForExternalUCS.removePTS()
end

function Test:StartSession_2()
  testCasesForExternalUCS.startSession(self, 2)
end

function Test:RAI_2()
  testCasesForExternalUCS.registerApp(self, 2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d) testCasesForExternalUCS.pts = testCasesForExternalUCS.createTableFromJsonFile(d.params.file) end)
end

function Test:CheckPTS()
  if not testCasesForExternalUCS.pts then
    self:FailTestCase("PTS was not created")
  elseif testCasesForExternalUCS.pts.policy_table
    and testCasesForExternalUCS.pts.policy_table.device_data
    and testCasesForExternalUCS.pts.policy_table.device_data[utils.getDeviceMAC()]
    and testCasesForExternalUCS.pts.policy_table.device_data[utils.getDeviceMAC()].user_consent_records
    and testCasesForExternalUCS.pts.policy_table.device_data[utils.getDeviceMAC()].user_consent_records[appId]
    and testCasesForExternalUCS.pts.policy_table.device_data[utils.getDeviceMAC()].user_consent_records[appId][checkedSection]
    then
      print("Section '".. checkedSection .. "' exists in PTS")
      print(" => OK")
    else
      self:FailTestCase("Section '" .. checkedSection .. "' was not found in PTS")
    end
  end

  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")

  function Test.StopSDL()
    StopSDL()
  end

  function Test.Postcondition_RestorePreloadedFile()
    commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
  end

  return Test
