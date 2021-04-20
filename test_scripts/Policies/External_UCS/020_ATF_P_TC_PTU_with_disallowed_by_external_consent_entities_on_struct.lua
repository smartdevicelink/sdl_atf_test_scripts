---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PTU with “disallowed_by_external_consent_entities_on” struct
--
-- Description:
-- In case:
-- SDL receives PolicyTableUpdate with “disallowed_by_external_consent_entities_on:
-- [entityType: <Integer>, entityId: <Integer>]” -> of "<functional grouping>"
-- -> from "functional_groupings" section
-- SDL must:
-- a. consider this PTU as valid (with the pre-conditions of all other valid PTU content)
-- b. add this “disallowed_by_external_consent_entities_on:
-- [entityType: <Integer>, entityId: <Integer>]” field with the corresponding value
-- to the corresponding "<functional grouping>" to the Policies database.
--
-- Preconditions:
-- 1. Start SDL (make sure 'disallowed_by_external_consent_entities_on' section is omitted in PreloadedPT)
--
-- Steps:
-- 1. Register app1
-- 3. Activate app1
-- 4. Perform PTU (make sure 'disallowed_by_external_consent_entities_on' section is defined)
-- 5. Verify status of update
-- 6. Register app2
-- 7. Activate app2
-- 8. Verify PTSnapshot
--
-- Expected result:
-- a. PTU finished successfully with UP_TO_DATE status
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
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')

--[[ Local variables ]]
local checkedStatus = "UP_TO_DATE"
local checkedSection = "disallowed_by_external_consent_entities_on"
local grpId = "Location-1"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
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

function Test:RAI_1()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:ActivateApp_1()
  local updateFunc = function(pts)
    pts.policy_table.functional_groupings[grpId][checkedSection] = {
      {
        entityID = 128,
        entityType = 0
      }
    }
  end
  testCasesForExternalUCS.activateApp(self, 1, checkedStatus, updateFunc)
end

function Test:CheckStatus_UP_TO_DATE()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = checkedStatus })
end

function Test.RemovePTS()
  testCasesForExternalUCS.removePTS()
end

function Test:StartSession()
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

return Test
