---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_rpcs_sent_in_hmi_none" update
--
-- Description:
-- In case an application sends RPC in HMILevel NONE which is restricted and declined by Policies,
-- Policy Manager must increment "count_of_rpcs_sent_in_hmi_none" section value of
-- Local Policy Table for the corresponding application. For more details refer APPLINK-16145

-- Pre-conditions:
-- a. SDL and HMI are started
-- b. app successfully registers and running in NONE on SDL

-- Steps:
-- 1. app -> SDL: RPC

-- Expected:
-- 2. PoliciesManager increment "count_of_rpcs_sent_in_hmi_none" at LocalPT for this app
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
function Test:SendDissalowedRpcInNone()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 10,
      menuParams =
      {
        position = 0,
        menuName ="Command"
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

function Test:CheckDB_updated_count_of_rejections_duplicate_name()
  StopSDL()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT count_of_rpcs_sent_in_hmi_none FROM app_level WHERE application_id = '0000001'"
  local exp_result = {"1"}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) ==false then
    self:FailTestCase("DB doesn't include expected value for count_of_rpcs_sent_in_hmi_none. Exp: "..exp_result[1])
  end
end

return Test
