require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
--------------------------------------Requirement summary---------------------------------------------
--[Policies] External UCS: "OFF" user enables "functional grouping" for specific app
--[Policies] External UCS: "OFF" updates in "consent_groups" and "external_consent_status_groups" when SDL gets user consent for specific app

------------------------------------General Settings for Configuration--------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_steps = require('user_modules/common_steps')
local common_functions = require ('user_modules/common_functions')

---------------------------------------Common Variables-----------------------------------------------
local id_group_1 = nil
--local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
-- TEST 05:
-- In case
-- "functional grouping" is user_disallowed by External Consent "OFF" notification from HMI
-- and SDL gets SDL.OnAppPermissionConsent ( "functional grouping": allowed, appID)from HMI
-- SDL must
-- update "consent_groups" of specific app (change appropriate <functional_grouping> status to "true")
-- leave the same value in "external_consent_status_groups" (<functional_grouping>:false)
-- send OnPermissionsChange to all impacted apps
-- process RPCs from such "<functional_grouping>" as user allowed
--------------------------------------------------------------------------
-- Test 05.03:
-- Description:
-- "functional grouping" is user_disallowed by External Consent "OFF"
-- (disallowed_by_external_consent_entities_on exists. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus OFF))
-- HMI -> SDL: OnAppPermissionConsent((function allowed = omitted))
-- Expected Result:
-- Not update: "consent_group"'s is_consented = 0.
-- Not update: "External Consent_consent_group"'s is_consented = 0.
-- OnPermissionsChange is not sent.
-- Process RPCs from such "<functional_grouping>" as user disallowed
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF".."_Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_off = {{
        entityType = 1,
        entityID = 1
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
-- HMI sends OnAppPermissionConsent with External Consent status = OFF
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 1, entityID = 1, status = "OFF"}}
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
-- OnAppPermissionChanged is not sent
-- when HMI sends OnAppPermissionConsent with consentedFunctions allowed = false
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = nil}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF" .. "_MainCheck_RPC_is_disallowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corr_id = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(corr_id, {success = false , resultCode = "USER_DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function()
  StopSDL()
end
