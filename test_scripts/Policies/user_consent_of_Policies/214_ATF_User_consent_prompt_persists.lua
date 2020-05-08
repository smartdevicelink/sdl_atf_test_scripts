---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: "user_consent_prompt" field is included to the <appID>`s policies
--
-- Description:
-- Functional grouping that has "user_consent_prompt" field, is included to the <appID>`s policies
-- 1. Used preconditions:
-- Delete log files and policy table
-- Unregister default application
-- Register application
-- Activate application
-- Send RPC -> should be disallowed
-- Perform PTU with new permissions that require User consent
-- Activate application and consent new permissions
--
-- 2. Performed steps
-- Send RPC from <functional grouping>
--
-- Expected result:
-- PoliciesManager must apply <functional grouping> only after the User has consented it -> RPC should be allowed
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

---[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local allowed_rps = {}
local arrayNotifications = {}
local arrayBase4 = {}
local array_allpermissions = {}
local array_without_Location = {}
local arrayLocation = {}

--[[ Local functions ]]
-- Function gets RPCs for Notification and Location-1
local function Get_RPCs()
  local RPC_Base4 = {}
  local RPC_Notifications = {}
  local RPC_Location = {}

  testCasesForPolicyTableSnapshot:extract_preloaded_pt()

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.Base-4.rpcs.")) == "functional_groupings.Base-4.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.Base%-4%.rpcs%.(%S+)%.%S+%.%S+")
      if(#RPC_Base4 == 0) then
        RPC_Base4[#RPC_Base4 + 1] = str
      end

      if(RPC_Base4[#RPC_Base4] ~= str) then
        RPC_Base4[#RPC_Base4 + 1] = str
        -- allowed_rps[#allowed_rps + 1] = str
      end
    end
  end

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.Notifications.rpcs.")) == "functional_groupings.Notifications.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.Notifications%.rpcs%.(%S+)%.%S+%.%S+")

      if(#RPC_Notifications == 0) then
        RPC_Notifications[#RPC_Notifications + 1] = str
      end

      if(RPC_Notifications[#RPC_Notifications] ~= str) then
        RPC_Notifications[#RPC_Notifications + 1] = str
        allowed_rps[#allowed_rps + 1] = str
      end
    end
  end

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.Location-1.rpcs.")) == "functional_groupings.Location-1.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.Location%-1%.rpcs%.(%S+)%.%S+%.%S+")

      if(#RPC_Location == 0) then
        RPC_Location[#RPC_Location + 1] = str
      end

      if(RPC_Location[#RPC_Location] ~= str) then
        RPC_Location[#RPC_Location + 1] = str
        allowed_rps[#allowed_rps + 1] = str
      end
    end
  end

  for i = 1, #RPC_Base4 do
    arrayBase4[i] = {
      --permissionItem = {
      --hmiPermissions = { userDisallowed = {}, allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" } },
      --parameterPermissions = { userDisallowed = {}, allowed = {} },
      rpcName = RPC_Base4[i]
      -- }
    }
    array_allpermissions[#array_allpermissions + 1] = arrayBase4[i]
    array_without_Location[#array_without_Location + 1] = arrayBase4[i]
  end

  for i = 1, #RPC_Notifications do
    arrayNotifications[i] = {
      --permissionItem = {
      --hmiPermissions = { userDisallowed = {}, allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" } },
      --parameterPermissions = { userDisallowed = {}, allowed = {} },
      rpcName = RPC_Notifications[i]
      -- }
    }
    array_allpermissions[#array_allpermissions + 1] = arrayNotifications[i]
    array_without_Location[#array_without_Location + 1] = arrayNotifications[i]
  end
  --Location will be not allowed
  for i = 1, #RPC_Location do
    arrayLocation[i] = {
      -- permissionItem = {
      --hmiPermissions = { userDisallowed = {}, allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" } },
      --parameterPermissions = { userDisallowed = {}, allowed = {} },
      rpcName = RPC_Location[i]
    }
    -- }
    --Location will be not allowed
    array_allpermissions[#array_allpermissions + 1] = arrayLocation[i]
  end

  -- for i = 1, #allowed_rps do
  -- print("allowed_rps = "..allowed_rps[i])
  -- end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()


testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/sdl_preloaded_pt_AlertOnlyNotifications_1.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_IsPermissionsConsentNeeded_false_on_app_activation()
  Get_RPCs()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = false, isSDLAllowed = false}})
  :Do(function(_,data)
      if(data.result.isSDLAllowed == false) then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
          end)
      end

      if (data.result.isPermissionsConsentNeeded == true) then
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function()
      local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID)
      if(app_permission ~= nil) then
        self:FailTestCase("Consented gropus are assigned to application")
      end
    end)
end

function Test:Precondition_Alert_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("Alert",{alertText1 = "alertText1"})
  EXPECT_HMICALL("UI.Alert",{speed = true}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_GetVehicleData_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_PTU_user_consent_prompt_present()
  local is_test_passed = true
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "filename"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"},
          "files/jsons/Policies/user_consent/OnAppPermissionConsent_1.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
              local function to_run()
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
            end)

          EXPECT_NOTIFICATION("OnPermissionsChange" --[[, {permissionItem = array_allpermissions}, {permissionItem = arrayNotifications}]]):Times(2)
            :Do(function(exp,_data2)
                if( (_data2.payload.permissionItem ~= nil) )then
                  -- Will be used to check if all needed RPC for permissions are received
                  local is_perm_item_receved = {}
                  for i = 1, #array_allpermissions do
                    is_perm_item_receved[i] = false
                  end

                  -- will be used to check RPCs that needs permission
                  local is_perm_item_needed = {}
                  for i = 1, #_data2.payload.permissionItem do
                    is_perm_item_needed[i] = false
                  end

                  for i = 1, #_data2.payload.permissionItem do
                    for j = 1, #array_allpermissions do
                      if(_data2.payload.permissionItem[i].rpcName == array_allpermissions[j].rpcName) then
                        is_perm_item_receved[j] = true
                        is_perm_item_needed[i] = true
                        break
                      end
                    end
                  end

                  -- check that all RPCs from notification are requesting permission
                  for i = 1,#is_perm_item_needed do
                    if (is_perm_item_needed[i] == false) then
                      commonFunctions:printError("Occ"..exp.occurences.." RPC: ".._data2.payload.permissionItem[i].rpcName.." should not be sent")
                      is_test_passed = false
                    end
                  end

                  -- check that all RPCs that request permission are received
                  for i = 1,#is_perm_item_receved do
                    if (is_perm_item_receved[i] == false) then
                      commonFunctions:printError("Occ"..exp.occurences.." RPC: "..array_allpermissions[i].rpcName.." is not sent")
                      is_test_passed = false
                    end
                  end
                end
              end)

            EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.HMIAppID, appPermissionsConsentNeeded = true })
            :Do(function()
                local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
                EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions"}})
                :Do(function()
                    local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"allowedFunctions"}})
                    EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage)
                    :Do(function()
                        self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                          { appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                            consentedFunctions = { { allowed = true, id = 1809526495, name = "Notifications"} },
                            source = "GUI"})
                      end)
                  end)

                self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              end)
          end)
      end)
    local function check()
      if(is_test_passed == false) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end

    RUN_AFTER(check, 10000)
    commonTestCases:DelayedExp(11000)
  end

  --[[ Test ]]
  commonFunctions:newTestCasesGroup("Test")

  -- Triger PTU to update sdl snapshot
  function Test:TestStep_trigger_user_request_update_from_HMI()
    testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
  end

  function Test.TestStep_verify_PermissionConsent()
    local is_test_passed = true
    local app_permission_Location = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Location-1")
    local app_permission_Notifications = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Notifications")
    if(app_permission_Location ~= nil) then
      commonFunctions:printError("Location-1 is assigned user_consent_records")
      is_test_passed = false
    end
    if(app_permission_Notifications == nil) then
      commonFunctions:printError("Notifications is not assigned user_consent_records")
      is_test_passed = false
    elseif(app_permission_Notifications ~= true) then
      commonFunctions:printError("Notifications is not assigned to true of application, real: " ..app_permission_Notifications)
      is_test_passed = false
    end
    return is_test_passed
  end

  --Notification is allowed by user
  function Test:TestStep_New_functional_grouping_applied_Alert_allowed()
    local RequestAlert = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})

    EXPECT_RESPONSE(RequestAlert, {success = false, resultCode = "GENERIC_ERROR"})
    :Timeout(20000)
  end

  --Location-1 is disallowed by user
  function Test:Precondition_GetVehicleData_disallowed()
    local RequestiDGetVData = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{}):Times(0)
    EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
  end

  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")
  testCasesForPolicyTable:Restore_preloaded_pt()
  function Test.Postcondition_Stop()
    StopSDL()
  end

  return Test
