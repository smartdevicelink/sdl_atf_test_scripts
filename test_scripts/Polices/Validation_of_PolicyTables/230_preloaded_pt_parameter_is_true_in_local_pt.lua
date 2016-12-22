---------------------------------------------------------------------------------------------
-- Description:
-- Behavior of SDL during start SDL in case when LocalPT(database) has the value of "preloaded_pt" field (Boolean) is "true"
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Start default SDL with valid PreloadedPT json file for create LocalPT(database) with "preloaded_pt" = "true"
-- 2. Performed steps:
-- Delete PreloadedPT json file
-- Start SDL only with LocalPT database and with corrupted PreloadedPT json file

-- Requirement summary:
-- [Policies]: PreloadedPolicyTable: "preloaded_pt: true"
--
-- Expected result:
-- SDL must consider LocalPT as PreloadedPolicyTable and start correctly
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General configuration parameters ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

function Test:TestStep_CheckPolicy()
	local preloaded_pt_initial = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.preloaded_pt")
  local preloaded_pt_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT preloaded_pt FROM module_config")
  local preloaded_pt
  for index, value in pairs(preloaded_pt_table) do
		preloaded_pt = value
  end
  if(preloaded_pt_initial == true) then
  	if(preloaded_pt ~= 1) then
  		self:FailTestCase("Error: Value of preloaded_pt should be 1(true). Real: "..preloaded_pt)	
  	end
  else
  	self:FailTestCase("Error: preloaded_pt.json should be updated. Value of preloaded_pt should be true. Real: "..preloaded_pt_initial)
  end    
    
end
