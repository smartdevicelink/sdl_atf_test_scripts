---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User-consent "YES"
-- [Mobile API] OnPermissionsChange notification
-- [HMI API] OnAppPermissionConsent notification
--
-- Description:
-- SDL gets user consent information from HMI
-- 1. Used preconditions:
-- Delete log files and policy table from previous cycle
-- Close current connection
-- Backup preloaded PT
-- Overwrite preloaded with specific groups for app
-- Connect device
-- Register app
--
-- 2. Performed steps
-- Activate app
--
-- Expected result:
-- SDL must notify an application about the current permissions active on HMI via onPermissionsChange() notification
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceConsentedAndAppPermissionsForConsent_preloaded_pt.json")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local variables ]]
local allowed_rps = {}
local array_allpermissions = {}
local array_DrivingCharacteristics3 = {}
local array_Base4 = {}

--[[ Local functions ]]
-- Function gets RPCs for Notification and Location-1
local function Get_RPCs()
  local RPC_Base4 = {}
  local RPC_DrivingCharacteristics3 = {}

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

  for i = 1, #RPC_Base4 do
    array_Base4[i] = {
      -- permissionItem = {
      --hmiPermissions = { userDisallowed = {}, allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" } },
      --parameterPermissions = { userDisallowed = {}, allowed = {} },
      rpcName = RPC_Base4[i]
    }
    array_allpermissions[#array_allpermissions + 1] = array_Base4[i]
  end

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.DrivingCharacteristics-3.rpcs.")) == "functional_groupings.DrivingCharacteristics-3.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.DrivingCharacteristics%-3%.rpcs%.(%S+)%.%S+%.%S+")

      if(#RPC_DrivingCharacteristics3 == 0) then
        RPC_DrivingCharacteristics3[#RPC_DrivingCharacteristics3 + 1] = str
      end

      if(RPC_DrivingCharacteristics3[#RPC_DrivingCharacteristics3] ~= str) then
        RPC_DrivingCharacteristics3[#RPC_DrivingCharacteristics3 + 1] = str
        allowed_rps[#allowed_rps + 1] = str
      end
    end
  end

  for i = 1, #RPC_DrivingCharacteristics3 do
    array_DrivingCharacteristics3[i] = {
      -- permissionItem = {
      --hmiPermissions = { userDisallowed = {}, allowed = { "BACKGROUND", "FULL", "LIMITED", "NONE" } },
      --parameterPermissions = { userDisallowed = {}, allowed = {} },
      rpcName = RPC_DrivingCharacteristics3[i]
    }
    array_allpermissions[#array_allpermissions + 1] = array_DrivingCharacteristics3[i]
  end

  -- for i = 1, #array_allpermissions do
  -- print("array_allpermissions = "..array_allpermissions[i].rpcName)
  -- end
end
Get_RPCs()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:IsPermissionsConsentNeeded_false_on_app_activation()
  local is_test_passed = true
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = true, isSDLAllowed = true}})
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
        local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
        EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions",
              --TODO(istoimenova): id should be read from policy.sqlite
              -- allowed: If ommited - no information about User Consent is yet found for app.
              allowedFunctions = {{ name = "DrivingCharacteristics", id = 4734356}}}})
        :Do(function()
            local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
              {language = "EN-US", messageCodes = {"AppPermissions"}})

            EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage,
              { result = { code = 0, messages = {{ messageCode = "AppPermissions"}}, method = "SDL.GetUserFriendlyMessage"}})
            :Do(function(_,_)
                self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                  { appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                    consentedFunctions = {{ allowed = true, id = 4734356, name = "DrivingCharacteristics"}}, source = "GUI"})

                EXPECT_NOTIFICATION("OnPermissionsChange")
                :Do(function(_,_data2)
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
                        commonFunctions:printError("Occ1 RPC: ".._data2.payload.permissionItem[i].rpcName.." should not be sent")
                        is_test_passed = false
                      end
                    end

                    -- check that all RPCs that request permission are received
                    for i = 1,#is_perm_item_receved do
                      if (is_perm_item_receved[i] == false) then
                        commonFunctions:printError("Occ1 RPC: "..array_allpermissions[i].rpcName.." is not sent")
                        is_test_passed = false
                      end
                    end
                  end)

              end)

          end)
      else
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)

  local function check()
    if(is_test_passed == false) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
  end

  RUN_AFTER(check, 10000)
  commonTestCases:DelayedExp(11000)
end

-- Triger PTU to update sdl snapshot
function Test:TestStep_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test:TestStep_verify_PermissionConsent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.DrivingCharacteristics-3")
  if(app_permission ~= true) then
    self:FailTestCase("DrivingCharacteristics-3 is not assigned to application, real: " ..app_permission)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
