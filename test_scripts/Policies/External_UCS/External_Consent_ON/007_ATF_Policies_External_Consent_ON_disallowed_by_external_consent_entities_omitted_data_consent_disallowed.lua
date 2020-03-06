require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [Policies] External UCS: "ON" in case of omitted "disallowed_by_external_consent_entities" param in functional groupings
--
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local id_group_1
local policy_file = config.pathToSDL .. "storage/policy.sqlite"
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 01:
-- In case:
-- SDL Policies database omits "disallowed_by_external_consent_entities_off" or "disallowed_by_external_consent_entities_on" param in "functional grouping" section
-- and SDL gets SDL.OnAppPermissionConsent ("externalConsentStatus: ON")
-- and registered application has this "functional grouping" assigned,
-- SDL must process requested RPCs from "functional groupings" assigned to mobile app in terms of user_consent and data_consent policies rules
--------------------------------------------------------------------------
-- Test 01.04:
-- Description: disallowed_by_external_consent_entities_on/off is omitted. Data consent is disallowed. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus ON, function allowed)
-- Expected Result: requested RPC is disallowed by data consent
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    -- omit disallowed_by_external_consent_entities_on/off
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"NONE", "BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
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
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
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
-- Check GetListOfPermissions response with empty externalConsentStatus array list. Get group id.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_GetListOfPermissions"] = function(self)
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
  :Do(function(_,data)
      id_group_1 = common_functions_external_consent:GetGroupId(data, "ConsentGroup001")
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAllowSDLFunctionality with data consent = disallowed
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAllowSDLFunctionality"] = function(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = false, source = "GUI"})
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
      "SubscribeWayPoints")
      return not validate_result
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with External Consent status = ON and consented function = allowed
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}},
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = true}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      return not validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_disallowed"] = function(self)
  corid = self.mobileSession:SendRPC("SubscribeVehicleData", {rpm = true})
  EXPECT_RESPONSE(corid, { success = false, resultCode = "DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

-- end Test 01.04
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
