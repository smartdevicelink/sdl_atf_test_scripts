require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
--------------------------------------Requirement summary---------------------------------------------
--[Policies] External UCS: "OFF" status between ignition cycles
--[Policies] External UCS: "OFF" - userDisallowed RPCs

------------------------------------General Settings for Configuration--------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
require('user_modules/all_common_modules')
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_steps = require('user_modules/common_steps')
local common_functions = require ('user_modules/common_functions')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local preconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
preconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", "")

---------------------------------------Common Variables-----------------------------------------------
--local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

-------------------------------------------Functions--------------------------------------------------
local function CheckGroup001IsNotConsentedAndGroup002IsConsented()
  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group001 is disallowed to process.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group001_is_user_disallowed"] = function(self)
    --mobile side: send SubscribeWayPoints request
    local cid = self.mobileSession:SendRPC("SubscribeWayPoints",{})

    EXPECT_RESPONSE(cid, {success = false , resultCode = "USER_DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
    common_functions:DelayedExp(5000)
  end

  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group002 is allowed to process.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group002_is_allowed"] = function(self)
    local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        rpm = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM" }
      })
      end)
    EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end

end -- function CheckGroup001IsNotConsentedAndGroup002IsDisallowedByUser()

local function CheckGroup001IsConsentedAndGroup002IsNotConsented()
  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group001 is allowed to process.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group001_is_allowed"] = function(self)
    --mobile side: send SubscribeWayPoints request
    local cid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
    --hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_,data)
        --hmi side: sending Navigation.SubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
      end)
    --mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end

  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group002 is disallowed to process.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group002_is_user_disallowed"] = function(self)
    local corid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
    self.mobileSession:ExpectResponse(corid, {success = false, resultCode = "USER_DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
    common_functions:DelayedExp(5000)
  end
end -- function CheckGroup001IsConsentedAndGroup002IsNotConsented()

local function IgnitionOffOnActivateApp(test_case_name)
  common_steps:IgnitionOff("Precondition_Ignition_Off_" .. test_case_name)
  common_steps:IgnitionOn("Precondition_Ignition_On_" .. test_case_name)
  common_steps:AddMobileSession("Precondition_Add_Mobile_Session_1_" .. test_case_name, "mobileConnection","mobileSession")
  common_steps:RegisterApplication("Precondition_Register_Application_1_" .. test_case_name, "mobileSession", config.application1.registerAppInterfaceParams)
  common_steps:ActivateApplication("Precondition_Activate_Application_1_" .. test_case_name, config.application1.registerAppInterfaceParams.appName)
  Test["Precondition_Wait_For_Database_After_Activate_Application_1_" .. test_case_name] = function()
    common_functions:DelayedExp(5000)
  end
end

------------------------------------------Tests-------------------------------------------------------
-- TEST 10:
-- In case
-- SDL has received SDL.OnAppPermissionConsent ("externalConsentStatus: OFF") from HMI
-- SDL must
-- use this value through ignition cycles
-- until this externalConsentStatus value is changed by corresponding notification from HMI.
--------------------------------------------------------------------------
-- Test 10.02:
-- Description: disallowed_by_external_consent_entities_on/off . HMI -> SDL: OnAppPermissionConsent(externalConsentStatus OFF). Ignition Off then On.
-- Expected Result: externalConsentStatus is kept.
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
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
  local removed_json_items_preloaded_date = {"preloaded_date"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items_preloaded_date)
  -- update policy table
  common_functions_external_consent:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty externalConsentStatus array list.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
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
-- HMI sends OnAppPermissionConsent with External Consent status = OFF
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus_OFF"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "OFF"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result_1 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      local validate_result_2 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})

      if(validate_result_1 == false) then commonFunctions:printError("SubscribeWayPoints doesn't have permissions for userDisallowed = {BACKGROUND, FULL, LIMITED}") end
      if(validate_result_2 == false) then commonFunctions:printError("SubscribeVehicleData doesn't have permissions for allowed = {BACKGROUND, FULL, LIMITED}") end

      return (validate_result_1 and validate_result_2)
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- Group001: is_consented = 0
-- Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsConsented()

--------------------------------------------------------------------------
-- Precondition:
-- Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_externalConsentStatus_OFF")

--------------------------------------------------------------------------
-- Main check:
-- Group001: is_consented = 0
-- Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsConsented()

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with External Consent status = ON
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus_ON"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      externalConsentStatus = {{entityType = 2, entityID = 5, status = "ON"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result_1 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      local validate_result_2 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})

      if(validate_result_1 == false) then commonFunctions:printError("SubscribeWayPoints doesn't have permissions for allowed = {BACKGROUND, FULL, LIMITED}") end
      if(validate_result_2 == false) then commonFunctions:printError("SubscribeVehicleData doesn't have permissions for userDisallowed = {BACKGROUND, FULL, LIMITED}") end

      return (validate_result_1 and validate_result_2)
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- Group001: is_consented = 1
-- Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsNotConsented()

--------------------------------------------------------------------------
-- Precondition:
-- Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_externalConsentStatus_ON")

--------------------------------------------------------------------------
-- Main check:
-- Group001: is_consented = 1
-- Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsNotConsented()

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function()
  StopSDL()
end

Test["RestoreIniFile"] = function()
  preconditions:RestoreFile("smartDeviceLink.ini")
end
