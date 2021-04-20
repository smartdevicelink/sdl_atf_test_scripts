------------- --------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Without data consent, assign "pre_DataConsent" policies
-- to the application which appID does not exist in LocalPT
--
-- Description:
-- SDL should assign "pre_DataConsent" permissions in case the application registers
-- (sends RegisterAppInterface request) with the appID that does not exist in Local Policy Table,
-- and Data Consent either has been denied or has not yet been asked for the device
-- this application registers from.
--
-- Preconditions:
-- 1. Register new app from unconsented device. -> PTU is not triggered.
--
-- Steps:
-- 1. Trigger PTU with user request from HMI
-- Expected result:
-- 1. sdl_snapshot is created.
-- 2. Application is added to policy and assigns pre_DataConsent group
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
local function get_permission_code(app_id)
  local query = "select fg.name from app_group ag, functional_group fg where ag.functional_group_id = fg.id and application_id = '" .. app_id .. "'"
  local result = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)
  return result[1]
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconfition_trigger_user_request_update_from_HMI()
  local r_actual = get_permission_code("0000001")
  local r_expected = get_permission_code("pre_DataConsent")
  print("Actual: '" .. tostring(r_actual) .. "'")
  print("Expected: '" .. tostring(r_expected) .. "'")
  if r_actual ~= r_expected then
    local msg = table.concat({"Assigned app permissions is not for pre_DataConsent, expected '", r_expected, "', actual '", r_actual, "'"})
    self:FailTestCase(msg)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
