require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [Policies] External UCS: empty "consent_groups" changes after externalConsentStatus was received
--
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_functions = require ('user_modules/common_functions')
local common_steps = require('user_modules/common_steps')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession", "mobileSession2")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 07:
-- In case
-- SDL Policies database does not have "consent_groups" in "device_data" -> "user_consent_records" -> "appID" section
-- and_ SDL received SDL.OnAppPermissionsConsent (externalConsentStatus)
-- SDL must
-- add "consent_groups" to "device_data" -> "user_consent_records" -> "appID" section in Policy Table
-- change_ according to the received externalConsentStatus settings in both:
-- "consent_groups" in "device_data" -> "user_consent_records" -> "appID" section
-- and
-- "external_consent_status_groups" in "device_data" -> "user_consent_records" -> "appID" section
--------------------------------------------------------------------------
-- Test 07.01:
-- Description: "consent_groups" does not exist. disallowed_by_external_consent_entities_on/off. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus ON)
-- Expected Result: "consent_groups" is created with same status as externalConsentStatus
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_ON_Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_off = {{
        entityType = 1,
        entityID = 4
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    disallowed_by_external_consent_entities_on = {{
        entityType = 2,
        entityID = 5
    }},
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert application "0000002" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
    tts = "tts_test",
    label = "label_test",
    textBody = "textBody_test"
  }
  --insert "ConsentGroup002" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup002"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup002.languages["en-us"] = {
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
  -- update policy table
  common_functions_external_consent:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty externalConsentStatus array list.
--------------------------------------------------------------------------
Test["TEST_NAME_ON_Precondition_GetListOfPermissions"] = function(self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {
          {name = "ConsentGroup001", allowed = nil},
          {name = "ConsentGroup002", allowed = nil}
        },
        externalConsentStatus = {}
      }
    })
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with External Consent status = ON
--------------------------------------------------------------------------
Test["TEST_NAME_ON_Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {
        {entityType = 1, entityID = 4, status = "ON"},
        {entityType = 2, entityID = 5, status = "ON"}
      }
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
-- RPC of Group001 on Application 1 is allowed to process.
--------------------------------------------------------------------------
Test["TEST_NAME_ON_MainCheck_RPC_Of_App1_Group001_is_allowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      --hmi side: sending Navigation.SubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(corid, {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

-- end Test 07.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function()
  StopSDL()
end
