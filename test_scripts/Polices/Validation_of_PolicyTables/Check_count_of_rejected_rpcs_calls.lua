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
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ General Precondition before ATF start ]]
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Common variables ]]
local basic_ptu_file = "files/ptu.json"
local ptu_app_registered = "files/ptu1app.json"

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4"
    ],
    "RequestType":[
    "TRAFFIC_MESSAGE_CHANNEL",
    "PROPRIETARY",
    "HTTP",
    "QUERY_APPS"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[Preconditions]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_app_registered)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_InitiatePTUForGetSnapshot()
  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_app_registered,
    config.application1.registerAppInterfaceParams.appName,
    self.mobileSession)
end

function Test:TestStep2_SendDissalowedRpc()
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

  function Test:TestStep3_Check_count_of_rejected_rpc_calls_incremented_in_PT()
    local appID ="0000001"
    local file = io.open("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json", "r")
    local json_data = file:read("*all") -- may be abbreviated to "*a";
    file:close()
    local data = json.decode(json_data)
    local CountOfRejectedRpcCalls = data.policy_table.usage_and_error_counts.app_level[appID].count_of_rejected_rpc_calls
    if CountOfRejectedRpcCalls == 1 then
      return true
    else
      self:FailTestCase("Wrong count_of_rejected_rpc_calls. Expected: " .. 1 .. ", Actual: " .. CountOfRejectedRpcCalls)
    end
  end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end
