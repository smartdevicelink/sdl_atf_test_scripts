require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [Policies] External UCS: settings for all connected apps
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
-------------------------------------------Functions--------------------------------------------------
------------------------------------------------------------------------------------------------------
local function RegistAndActivateApp(test_case_name, mobile_session, application_params)
  common_steps:AddMobileSession("Precondition_Add_Mobile_Session_" .. test_case_name, "mobileConnection",mobile_session)
  common_steps:RegisterApplication("Precondition_Register_Application_" .. test_case_name, mobile_session, application_params)
  common_steps:ActivateApplication("Precondition_Activate_Application_" .. test_case_name, application_params.appName)
end
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 12:
-- In case
-- SDL received SDL.OnAppPermissionConsent (externalConsentStatus) that changed user's permissions for a "<functional_grouping>"
-- and new app that has this "<functional_grouping>" assigned connects
-- SDL must
-- 1. apply External Consent User Consent Settings to this app
-- 2. send corresponding OnPermissionsChange
-- 3. add corresponding records to PolicyTable -> "<deviceID>" section
--------------------------------------------------------------------------
-- Test 12.01:
-- Description: disallowed_by_external_consent_entities_off. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus ON). Register new applications.
-- Expected Result: external_consent is created automatically.
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_Update_Policy_Table_1"] = function(self)
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
      SendLocation = {
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
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000002" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000003" into "app_policies"
  data.policy_table.app_policies["0000003"] = {
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
-- Check GetListOfPermissions response with empty externalConsentStatus array list.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {
          {name = "ConsentGroup001", allowed = nil}
        },
        externalConsentStatus = {}
      }
    })
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with External Consent status = ON
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_external_consent:ValidateHMIPermissions(data,
        "SendLocation", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- Register and activate application 2
--------------------------------------------------------------------------
RegistAndActivateApp("2", "mobileSession2", config.application2.registerAppInterfaceParams)

--------------------------------------------------------------------------
-- Main check:
-- RPC of Group001 is allowed to process on Application 1.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_of_Application_1_Group001_is_allowed"] = function(self)
  local cid = self.mobileSession:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  EXPECT_HMICALL("Navigation.SendLocation")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  self.mobileSession:ExpectResponse("SendLocation", {success = true , resultCode = "SUCCESS"})
end

--------------------------------------------------------------------------
-- Main check:
-- RPC of Group001 is allowed to process on Application 2.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_of_Application_2_Group001_is_allowed"] = function(self)
  local cid = self.mobileSession2:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  EXPECT_HMICALL("Navigation.SendLocation")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  self.mobileSession2:ExpectResponse("SendLocation", {success = true , resultCode = "SUCCESS"})
end

-- end Test 12.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
