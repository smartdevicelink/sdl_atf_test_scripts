---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: Permissions assignment in case device is not yet consented (didn't get any user response yet)
--
-- Description:
-- Condition for assigning by PoliciesManager policies from 'pre_DataConsent' section ('default_hmi', 'groups' and other) to the app.
-- PoliciesManager has not yet received the User`s response on data consent prompt for the corresponding device
-- 1. Used preconditions:
-- Delete log files and policy table
-- Close current connection
-- Connect unconsented device
-- Register application
-- 2. Performed steps
-- Activate application
-- Perform phone call
-- Activate app again
--
-- Expected result:
-- PoliciesManager must assign policies from 'pre_DataConsent' section ('default_hmi', 'groups' and other) to the app ->
-- Step1:
-- HMI->SDL: SDL.ActivateApp{appID}
-- SDL->HMI: SDL.ActivateApp_response{isSDLAllowed: false, params} * //HMI does not activete the app, PoliciesManager assigns HMILevel from default_hmi' in 'pre_DataConsent' section to the <App>*
-- HMI->SDL: GetUserFriendlyMessage{params},
-- SDL->HMI: GetUserFriendlyMessage_response{params}
-- HMI: display the 'data consent' message.
-- Some system event (for exmaple, incoming pnonecall) aborts the data consent dialog.
-- PoliciesManager keeps HMILevel, groups, etc from default_hmi' in 'pre_DataConsent' section to the <App>.
-- Step2:
-- HMI->SDL: SDL.ActivateApp{appID}
-- SDL->HMI: SDL.ActivateApp_response{isSDLAllowed: false, params}
-------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local pre_dataconsent = "129372391"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_ActivateApp_on_unconsented_device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0,
        device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() },
        isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= false then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device needs to be consented on HMI")
      else

        local RequestIdGetMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdGetMessage)
        --Data consent is interrupted by phone call
        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
      end
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{}) :Times(0)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
end

function Test:TestStep2_Send_RPC_from_default_group()
  --AddCommand belongs to default permissions, so should be disallowed
  local RequestIDAddCommand = self.mobileSession:SendRPC("AddCommand", { cmdID = 111, menuParams = { position = 1, menuName ="Command111"}})

  EXPECT_HMICALL("UI.AddCommand",{}):Times(0)
  EXPECT_RESPONSE(RequestIDAddCommand, { success = false, resultCode = "DISALLOWED" })
  EXPECT_NOTIFICATION("OnHashChange"):Times(0)
end

function Test:TestStep3_Check_App_assigned_PreDataConsent()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= pre_dataconsent) then
    self:FailTestCase("Application is not assigned to BaseBeforeDataConsent. Group: "..group_app_id)
  end
end

function Test:TestStep4_ActivateApp_again_on_unconsented_device()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = false, eventName ="PHONE_CALL"})

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  --Device is still not consented, isSDLAllowed should be "false"
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0,
        device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() },
        isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false, method ="SDL.ActivateApp"}})

  EXPECT_HMICALL("BasicCommunication.ActivateApp") :Times(0)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
end

function Test:TestStep2_Send_RPC_from_default_group()
  --AddCommand belongs to default permissions, so should be disallowed
  local RequestIDAddCommand = self.mobileSession:SendRPC("AddCommand", { cmdID = 111, menuParams = { position = 1, menuName ="Command111"}})

  EXPECT_HMICALL("UI.AddCommand",{}):Times(0)
  EXPECT_RESPONSE(RequestIDAddCommand, { success = false, resultCode = "DISALLOWED" })
  EXPECT_NOTIFICATION("OnHashChange"):Times(0)
end

function Test:TestStep5_Check_App_assigned_PreDataConsent()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= pre_dataconsent) then
    self:FailTestCase("Application is not assigned to BaseBeforeDataConsent. Group: "..group_app_id)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
