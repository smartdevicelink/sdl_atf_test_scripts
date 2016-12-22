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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconfition_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies."..config.application1.registerAppInterfaceParams.appID)
  if(app_permission ~= "pre_DataConsent") then
    self:FailTestCase("Assigned app permissions is not for pre_DataConsent, real: " ..app_permission)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
