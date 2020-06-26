require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
-------------------------------------- Requirement summary -------------------------------------------
-- [Policies] External UCS: "ON" status between ignition cycles
-- [Policies] External UCS: "ON" - allowed RPCs
--
------------------------------------------------------------------------------------------------------
------------------------------------ General Settings for Configuration ------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)
------------------------------------------------------------------------------------------------------
------------------------------------------- Functions ------------------------------------------------
------------------------------------------------------------------------------------------------------
local function CheckRPCisAllowed()
  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group001 is allowed to process.
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_RPC_of_Group001_is_allowed"] = function(self)
    local corid = self.mobileSession:SendRPC("SubscribeVehicleData", {rpm = true})
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM" }
      })
      end)
    EXPECT_RESPONSE(corid, {success = true , resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function IgnitionOffOnActivateApp(test_case_name)
  common_steps:IgnitionOff("Precondition_Ignition_Off_" .. test_case_name)
  common_steps:IgnitionOn("Precondition_Ignition_On_" .. test_case_name)
  common_steps:AddMobileSession("Precondition_Add_Mobile_Session_1_" .. test_case_name, "mobileConnection", "mobileSession")
  common_steps:RegisterApplication("Precondition_Register_Application_1_" .. test_case_name, "mobileSession", config.application1.registerAppInterfaceParams)
  common_steps:ActivateApplication("Precondition_Activate_Application_1_" .. test_case_name, config.application1.registerAppInterfaceParams.appName)
  Test["Precondition_Wait_For_Database_After_Activate_Application_1_" .. test_case_name] = function(self)
    common_functions:DelayedExp(5000)
  end
end

------------------------------------------------------------------------------------------------------
------------------------------------------ Tests -----------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 10:
-- In case
-- SDL has received SDL.OnAppPermissionConsent ("externalConsentStatus: ON") from HMI
-- SDL must
-- use this value through ignition cycles
-- until this externalConsentStatus value is changed by corresponding notification from HMI.
--------------------------------------------------------------------------
-- Test 10.01:
-- Description:
-- 1. disallowed_by_external_consent_entities_off.
-- 2. HMI->SDL: OnAppPermissionConsent(externalConsentStatus ON).
-- 3. Ignition Off then On.
-- 4. Expected Result: externalConsentStatus is kept. RPC is allowed

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
-- Check GetListOfPermissions response with empty externalConsentStatus array list.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
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
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result_1 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      return validate_result_1
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- Group001: is_consented = 1
--------------------------------------------------------------------------
CheckRPCisAllowed()

--------------------------------------------------------------------------
-- Precondition:
-- Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_externalConsentStatus_ON")

--------------------------------------------------------------------------
-- Main check:
-- Group001: is_consented = 1
--------------------------------------------------------------------------
CheckRPCisAllowed()

------------------------------------------------------------------------------------------------------
-------------------------------------- Postcondition -------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function()
  StopSDL()
end
