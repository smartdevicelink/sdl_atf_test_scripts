---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_rejected_rpcs_calls" update
--
-- Description:
-- In case mobile RPC has been rejected by SDL because of the Policy disallowance
-- (including disallowed parameters, HMI levels and RPCs),
-- Policy Manager must increment "count_of_rejected_rpcs_calls" section value
-- of Local Policy Table for the corresponding application.

-- a. SDL and HMI are started
-- b. app successfully registers and running on SDL
-- c. RPC_1 disallowed by Policies

-- Steps:
-- app -> SDL: RPC_1
-- SDL -> app: RPC_1 (DISALLOWED)

-- Expected:
-- PoliciesManager increments "count_of_rejected_rpcs_calls" field at PolicyTable
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

--[[ General Settings for configuration ]]
Test = require("connecttest")
require('user_modules/AppTypes')

local connectMobile_Orig = Test.connectMobile
function Test:connectMobile()
  local ret = connectMobile_Orig(self)
  ret:Do(function()
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() }} )
      utils.wait(500)
    end)
  return ret
end

--[[ Test ]]
function Test:SendDissalowedRpcInNone()
  local cid = self.mobileSession:SendRPC("GetVehicleData", { gps = true})
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

function Test:CheckDB_updated_count_of_rejected_rpcs_calls()
  StopSDL()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT count_of_rejected_rpcs_calls FROM app_level WHERE application_id = '0000001'"
  local exp_result = {"1"}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) ==false then
    self:FailTestCase("DB doesn't include expected value for count_of_rejected_rpcs_calls. Exp: "..exp_result[1])
  end
end

testCasesForPolicyTable:Restore_preloaded_pt()

return Test
