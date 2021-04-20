require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
--------------------------------------Requirement summary---------------------------------------------
--[Policies] External UCS: "externalConsentStatus" was not received from HMI

------------------------------------General Settings for Configuration--------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_steps = require('user_modules/common_steps')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local common_functions = require ('user_modules/common_functions')

commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
local id_group_1, hmi_app_id_1

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- TEST:
-- In case:
-- SDL did not receive "externalConsentStatus" via SDL.OnAppPermissionsConsent from HMI
-- and SDL Policies Table does not have "external_consent_status_groups" in "device_data" -> "user_consent_records" -> "appID" section for the registered app
-- SDL must process requested RPCs from "functional groupings" assigned to mobile app in terms of user_consent and data_consent policies rules
--------------------------------------------------------------------------
-- Test 01:
-- Description: disallowed_by_external_consent_entities_on doesn't exists. Data consent is allowed.
-- Expected Result: requested RPC is allowed
--------------------------------------------------------------------------
-- Test 02:
-- Description: disallowed_by_external_consent_entities_on doesn't exists. Data consent is disallowed by user.
-- Expected Result: requested RPC is user_disallowed
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file without consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  --insert application "0000001" which belong to functional group "Group001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
    tts = "tts_test",
    label = "label_test",
    textBody = "textBody_test"
  }
  -- create json file for Policy Table Update
  common_functions_external_consent:CreateJsonFileForPTU(data, "/tmp/ptu_update.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items)
  local removed_json_items_preloaded_date = {"preloaded_date"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items_preloaded_date)
  -- update policy table
  common_functions_external_consent:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty externalConsentStatus array list. Get group id.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")

  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
        externalConsentStatus = {}
      }
    })
  :Do(function(_,data)
      id_group_1 = common_functions_external_consent:GetGroupId(data, "ConsentGroup001")
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent without externalConsentStatus, consent groups allowed
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_HMI_sends_OnAppPermissionConsent_allowed"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = true}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {"BACKGROUND", "FULL", "LIMITED"}, userDisallowed = {}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_MainCheck_RPC_is_allowed"] = function(self)
  self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM" }
      })
    end)

  EXPECT_RESPONSE("SubscribeVehicleData", {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent without externalConsentStatus, consent groups user disallowed
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_HMI_sends_OnAppPermissionConsent_user_disallowed"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = false}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is user disallowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_MainCheck_RPC_is_user_disallowed"] = function(self)
  self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData"):Times(0)

  EXPECT_RESPONSE("SubscribeVehicleData", {success = false , resultCode = "USER_DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange"):Times(0)

  commonTestCases:DelayedExp(10000)
end

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function()
  StopSDL()
end
