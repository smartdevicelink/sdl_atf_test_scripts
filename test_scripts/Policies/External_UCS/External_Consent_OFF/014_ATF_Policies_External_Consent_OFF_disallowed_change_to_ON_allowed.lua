require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
--------------------------------------Requirement summary---------------------------------------------
--[Policies] External UCS: "OFF" updates in "consent_groups" and "external_consent_status_groups" when externalConsentStatus changes to "ON"
--[Policies] External UCS: "OFF" OnPermissionsChange after externalConsentStatus changes to "ON"

------------------------------------General Settings for Configuration--------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_steps = require('user_modules/common_steps')
local common_functions = require ('user_modules/common_functions')

---------------------------------------Common Variables-----------------------------------------------
--local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
-- TEST 08:
-- In case
-- SDL gets SDL.OnAppPermissionConsent with externalConsentStatus change from "OFF" to "ON"
-- and this changes the "<functional grouping>" permissions to "user_allowed",
-- SDL must
-- for all impacted apps
-- update "consent_groups" to status "true"
-- update "external_consent_status_groups" to status "true"
-- send OnPermissionsChange ("RPCs from assigned "functional_groupings" "hmiPermission": (<current assigned permissions>)", allowed) notification
--------------------------------------------------------------------------
-- Test 08.01:
-- Description:
-- "functional grouping" is user_disallowed by External Consent "OFF"
-- (disallowed_by_external_consent_entities_off exists. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus OFF))
-- HMI -> SDL: OnAppPermissionConsent(externalConsentStatus ON)
-- Expected Result:
-- Update: "consent_group"'s is_consented = 1.
-- Update: "external_consent_status_groups" is_consented = 1.
-- OnPermissionsChange is sent.
-- Process RPCs from such "<functional_grouping>" as user allowed
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF".."_Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_off = {{
        entityType = 2,
        entityID = 5
    }},
    rpcs = {
      SubscribeWayPoints = {
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
Test["TEST_NAME_OFF".."_Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
        externalConsentStatus = {}
      }
    })
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with External Consent status = OFF
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus_OFF"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "OFF"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_ON" .. "_Precondition_RPC_is_disallowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corr_id = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(corr_id, {success = false , resultCode = "USER_DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Main check:
-- OnAppPermissionChanged is sent
-- when HMI sends OnAppPermissionConsent with externalConsentStatus = ON
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_MainCheck_HMI_sends_OnAppPermissionConsent_externalConsentStatus_ON"] = function(self)
  common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_MainCheck_RPC_is_allowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corr_id = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      --hmi side: sending Navigation.SubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(corr_id, {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function()
  StopSDL()
end
