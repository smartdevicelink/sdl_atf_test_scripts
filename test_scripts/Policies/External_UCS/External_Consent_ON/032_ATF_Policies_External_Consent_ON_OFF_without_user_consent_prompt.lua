require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [HMI API] OnAppPermissionConsent notification
--
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
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
-- TEST:
-- externalConsentStatus is not applied when user_consent_prompt does not exist in functional group
--------------------------------------------------------------------------
-- Test:
-- Description:
-- user_consent_prompt does not exist in functional group. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus ON))
-- Expected Result:
-- "consent_group" is not added.
-- "external_consent_status_groups" is not added.
-- OnPermissionsChange is not sent.
-- Process RPCs from such "<functional_grouping>" as user allowed
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    -- user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_on = {{
        entityType = 2,
        entityID = 5
    }},
    rpcs = {
      SendLocation = {
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
  -- update policy table
  common_functions_external_consent:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty externalConsentStatus array list. Get group id.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {},
        externalConsentStatus = {}
      }
    })
end

--------------------------------------------------------------------------
-- Main Check:
-- OnAppPermissionChanged is NOT sent
-- when HMI sends OnAppPermissionConsent with externalConsentStatus = ON
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus_ON"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}}
    })
  EXPECT_NOTIFICATION("OnPermissionsChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_allowed_When_External_Consent_ON"] = function(self)
  local cid = self.mobileSession:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  EXPECT_HMICALL("Navigation.SendLocation")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  EXPECT_RESPONSE("SendLocation", {success = true , resultCode = "SUCCESS"})
end

--------------------------------------------------------------------------
-- Main check:
-- OnAppPermissionChanged is NOT sent
-- when HMI sends OnAppPermissionConsent with externalConsentStatus = OFF
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_HMI_sends_OnAppPermissionConsent_externalConsentStatus_OFF"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "OFF"}}
    })
  EXPECT_NOTIFICATION("OnPermissionsChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_allowed_When_External_Consent_OFF"] = function(self)
  local cid = self.mobileSession:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  EXPECT_HMICALL("Navigation.SendLocation")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  EXPECT_RESPONSE("SendLocation", {success = true , resultCode = "SUCCESS"})
end

-- end Test
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
