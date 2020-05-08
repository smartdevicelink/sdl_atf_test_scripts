---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PTU with "external_consent_status_groups" struct
--
-- Description:
-- In case:
-- SDL receives PolicyTableUpdate with "external_consent_status_groups:
-- [<functional_grouping>: <Boolean>]” -> of "device_data" -> "<device identifier>"
-- -> "user_consent_records" -> "<app id>" section
-- SDL must:
-- a. consider this PTU as invalid
-- b. do not merge this invalid PTU to LocalPT.
--
-- Steps:
-- 1. Register app
-- 2. Activate app
-- 3. Perform PTU (make sure 'external_consent_status_groups' exists in PTU file)
-- 4. Verify status of update
-- 5. Verify LocalPT (using data in snapshot)
--
-- Expected result:
-- a) PTU fails with UPDATE_NEEDED status
-- b) 'external_consent_status_groups' section doesn't exist in LocalPT
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
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local appId = config.application1.registerAppInterfaceParams.fullAppID
local grpId = "Location"
local checkedStatus = "UPDATE_NEEDED"
local checkedSection = "external_consent_status_groups"

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

function Test:RAI()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:ActivateApp()
  local updateFunc = function(pts)
    pts.policy_table.device_data = {
      [utils.getDeviceMAC()] = {
        user_consent_records = {
          [appId] = {
            [checkedSection] = {
              [grpId] = true
            }
          }
        }
      }
    }
  end
  testCasesForExternalUCS.activateApp(self, 1, checkedStatus, updateFunc)
end

function Test:CheckStatus_UPDATE_NEEDED()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = checkedStatus })
end

function Test.RemovePTS()
  testCasesForExternalUCS.removePTS()
end

function Test:CreateNewPTS()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
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
      self:FailTestCase("Section '" .. checkedSection .. "' was found in PTS")
    else
      print("Section '".. checkedSection .. "' doesn't exist in PTS")
      print(" => OK")
    end
  end

  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")

  function Test.StopSDL()
    StopSDL()
  end

  return Test
