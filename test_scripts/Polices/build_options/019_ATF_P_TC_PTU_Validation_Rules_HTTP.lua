---------------------------------------------------------------------------------------------
-- Clarification: "sdl_snapshot.json saving to file system"
-- HTTP flow
-- Requirements summary:
-- [PolicyTableUpdate] PTU validation rules
--
-- Description:
-- After Base-64 decoding, SDL must validate the Policy Table Update according to
-- S13j_Applink_Policy_Table_Data_Dictionary_040.xlsx rules: "required" fields must be present,
-- "optional" may be present but not obligatory, "ommited" - accepted to be present in PTU (PTU won't be rejected if the fields with option "ommited" exists)
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered
-- PTU is requested
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->MOB: OnSystemRequest()
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING)
-- 2. Performed steps
-- app->SDL:SystemRequest(requestType=HTTP), policy_file: all sections in data dictionary + optional + omit
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
-- SDL stops timeout started by OnSystemRequest. No other OnSystemRequest messages are received.
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

-- Used PTU is valid according to DataDictionary
function Test:TestStep_PoliciesManager_changes_UP_TO_DATE()
  testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP (self)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {}):Times(0)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{}):Times(0)
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
