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
---[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ Local variables ]]
local allowed_rps = {}
local RPC_Base4 = {}
local RPC_Notifications = {}
local RPC_Location = {}

--[[ Local functions ]]
-- Function gets RPCs for Notification and Location-1
local function Get_RPCs()
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

  -- for i = 1, #allowed_rps do
  -- print("allowed_rps = "..allowed_rps[i])
  -- end
end
Get_RPCs()
--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_IsPermissionsConsentNeeded_false_on_app_activation()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = false, isSDLAllowed = false}})
  :Do(function(_,data)
      if(data.result.isSDLAllowed == false) then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress, isSDLAllowed = true}})
          end)
      end

      if (data.result.isPermissionsConsentNeeded == true) then
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
end

function Test:TestStep_app_no_consent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID)
  if(app_permission ~= 0) then
    self:FailTestCase("Consented gropus are assigned to application")
  end
end

function Test:Precondition_Alert_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("Alert",{speed = true})
  EXPECT_HMICALL("UI.Alert",{speed = true}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_GetVehicleData_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("GetVehicleData",{})
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_Alert_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("Alert",{speed = true})
  EXPECT_HMICALL("UI.Alert",{speed = true}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_PTU_user_consent_prompt_present()
  local is_test_passed = true
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "filename"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"},
          "files/jsons/Policies/user_consent/OnAppPermissionConsent.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
              local function to_run()
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
            end)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
            {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
          :Do(function(_,_data1)
              if(_data1.params.status == "UP_TO_DATE") then
                EXPECT_NOTIFICATION("OnPermissionsChange",{})
                :Do(function(_,_data2)
                    if(_data2.payload.permissionItem ~= nil) then
                      -- Will be used to check if all needed RPC for permissions are received
                      local is_perm_item_receved = {}
                      for i = 1, #allowed_rps do
                        is_perm_item_receved[i] = false
                      end

                      -- will be used to check RPCs that needs permission
                      local is_perm_item_needed = {}
                      for i = 1, #_data2.payload.permissionItem do
                        is_perm_item_needed[i] = false
                      end

                      for i = 1, #_data2.payload.permissionItem do
                        for j = 1, #allowed_rps do
                          if(_data2.payload.permissionItem[i].rpcName == allowed_rps[j]) then
                            is_perm_item_receved[j] = true
                            is_perm_item_needed[i] = true
                            break
                          end
                        end
                      end

                      -- check that all RPCs from notification are requesting permission
                      for i = 1,#is_perm_item_needed do
                        if (is_perm_item_needed[i] == false) then
                          commonFunctions:printError("RPC: ".._data2.payload.permissionItem[i].rpcName.." should not be sent")
                          is_test_passed = false
                        end
                      end

                      -- check that all RPCs that request permission are received
                      for i = 1,#is_perm_item_receved do
                        if (is_perm_item_receved[i] == false) then
                          commonFunctions:printError("RPC: "..allowed_rps[i].." is not sent")
                          is_test_passed = false
                        end
                      end
                    end
                  end)

                EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.HMIAppID, appPermissionsConsentNeeded = true })
                :Do(function()
                    local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
                    EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions",
                          allowedFunctions = { {allowed_rps} }}})
                    :Do(function()
                        local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"allowedFunctions"}})
                        EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage)
                        :Do(function()
                            self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                              { appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                                consentedFunctions = {
                                  { allowed = true, id = 1809526495, name = "Notifications"},
                                  { allowed = false, id = 156072572, name = "Location-1"}}, source = "GUI"})
                            EXPECT_NOTIFICATION("OnPermissionsChange",
                              {permissionItem = {RPC_Notifications} })
                          end)
                      end)
                    self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                  end)
              end -- if(_data1.params.status == "UP_TO_DATE") then
            end)
        end)
    end)

  return is_test_passed
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

-- Triger PTU to update sdl snapshot
function Test:TestStep_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test.TestStep_verify_PermissionConsent()
  local is_test_passed = true
  local app_permission_Location = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID..".consent_groups.Location-1")
  local app_permission_Notifications = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID..".consent_groups.Notifications")
  if(app_permission_Location ~= false) then
    commonFunctions:printError("Location-1 is not assigned to false of application, real: " ..app_permission_Location)
    is_test_passed = false
  end
  if(app_permission_Notifications ~= true) then
    commonFunctions:printError("Notifications is not assigned to true of application, real: " ..app_permission_Notifications)
    is_test_passed = false
  end
  return is_test_passed
end

--Notification is allowed by user
function Test:New_functional_grouping_applied_Alert_allowed()
  local RequestAlert = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})

  EXPECT_RESPONSE(RequestAlert, {success = false, resultCode = "GENERIC_ERROR"})
end

--Location-1 is disallowed by user
function Test:Precondition_GetVehicleData_disallowed()
  local RequestiDGetVData = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{}):Times(0)
  EXPECT_RESPONSE(RequestiDGetVData, { success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end
