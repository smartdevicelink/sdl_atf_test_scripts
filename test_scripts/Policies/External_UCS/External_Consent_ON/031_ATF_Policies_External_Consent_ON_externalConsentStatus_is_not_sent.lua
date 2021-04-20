require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [Policies] External UCS: "externalConsentStatus" was not received from HMI
--
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local hmi_app_id_1
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
-- TEST 13:
-- In case
-- SDL did not receive "externalConsentStatus" via SDL.OnAppPermissionsConsent from HMI
-- and SDL Policies Table does not have "external_consent_status_groups" in "device_data" -> "user_consent_records" -> "appID" section for the registered app
-- SDL must
-- 1. process requested RPCs from "functional groupings" assigned to mobile app in terms of user_consent and data_consent policies rules
-- 2. not create "external_consent_status_groups" in "device_data" -> "user_consent_records" -> "appID" section in Policy Table
--------------------------------------------------------------------------
-- Test 13.01:
-- Description: disallowed_by_external_consent_entities_off exists. HMI -> SDL: OnAppPermissionConsent()//without externalConsentStatus
-- Expected Result: requested RPC depends on user_consent and data_consent
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
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_off = {{
        entityType = 2,
        entityID = 5
    }},
    disallowed_by_external_consent_entities_on = {{
        entityType = 1,
        entityID = 4
    }},
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
  -- update policy table
  common_functions_external_consent:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty externalConsentStatus array list. Get group id and app id.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
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
  :Do(function(_,data)
      id_group_1 = common_functions_external_consent:GetGroupId(data, "ConsentGroup001")
    end)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_disallowed_by_omit_of_user_consent"] = function(self)
  local corid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
  self.mobileSession:ExpectResponse(corid, {success = false, resultCode = "DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with consented function = allowed and without External Consent status
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent_userConsent_allowed"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = true}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_allowed_by_user_consent"] = function(self)
  corid = self.mobileSession:SendRPC("SubscribeVehicleData", {rpm = true})
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
-- HMI sends OnAppPermissionConsent with consented function = disallowed and without External Consent status
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent_userConsent_disallowed"] = function(self)
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
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_disallowed_by_user_consent"] = function(self)
  local corid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
  self.mobileSession:ExpectResponse(corid, {success = false, resultCode = "USER_DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAllowSDLFunctionality with data consent = disallowed
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAllowSDLFunctionality"] = function(self)
  --hmi side: send request SDL.OnAllowSDLFunctionality
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = false, source = "GUI"})
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
      "SubscribeVehicleData")
      return not validate_result
    end)
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_disallowed_by_data_consent_false"] = function(self)
  local corid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
  self.mobileSession:ExpectResponse(corid, {success = false, resultCode = "DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  common_functions:DelayedExp(5000)
end

-- end Test 13.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
