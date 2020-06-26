require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })
--------------------------------------Requirement summary---------------------------------------------
--[Policies] External UCS: "OFF" status between ignition cycles
--[Policies] External UCS: "OFF" in case of omitted "disallowed_by_external_consent_entities" param in functional groupings

------------------------------------General Settings for Configuration--------------------------------
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
require('user_modules/all_common_modules')
config.defaultProtocolVersion = 2
local common_functions_external_consent = require('user_modules/shared_testcases_custom/ATF_Policies_External_Consent_common_functions')
local common_steps = require('user_modules/common_steps')
local common_functions = require ('user_modules/common_functions')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

---------------------------------------Common Variables-----------------------------------------------
local id_group_1, id_group_2

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_external_consent:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

-------------------------------------------Functions--------------------------------------------------
local function CheckGroup001IsNotConsentedAndGroup002IsNotConsented()
  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group001 is disallowed to process SubscribeWayPoints.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group001_is_disallowed"] = function(self)
    --mobile side: send SubscribeWayPoints request
    local cid = self.mobileSession:SendRPC("SubscribeWayPoints",{})

    EXPECT_RESPONSE(cid, {success = false , resultCode = "DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange"):Times(0)

    common_functions:DelayedExp(10000)
  end

  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group002 is disallowed to process SubscribeVehicleData.
  --------------------------------------------------------------------------
  Test["TEST_NAME_OFF_MainCheck_RPC_of_Group002_is_disallowed"] = function(self)
    local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})

    EXPECT_RESPONSE(cid, {success = false , resultCode = "DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange"):Times(0)
    common_functions:DelayedExp(5000)
  end

end -- function CheckGroup001IsNotConsentedAndGroup002IsNotConsented()

local function CheckGroup001IsConsentedAndGroup002IsConsented()
  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group001 is allowed to process SubscribeWayPoints.
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

    common_functions:DelayedExp(10000)
  end

  --------------------------------------------------------------------------
  -- Main check:
  -- RPC of Group002 is allowed to process SubscribeVehicleData.
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
end -- function CheckGroup001IsConsentedAndGroup002IsConsented()

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
-- Description: disallowed_by_external_consent_entities_on/off is omitted. HMI -> SDL: OnAppPermissionConsent(externalConsentStatus OFF). Ignition Off then On.
-- Expected Result: externalConsentStatus is kept.
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- omit disallowed_by_external_consent_entities_on/off
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
  local data = common_functions_external_consent:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    -- omit disallowed_by_external_consent_entities_on/off
    user_consent_prompt = "ConsentGroup001",
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    -- omit disallowed_by_external_consent_entities_on/off
    user_consent_prompt = "ConsentGroup002",
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
  :Do(function(_,data)
      id_group_1 = common_functions_external_consent:GetGroupId(data, "ConsentGroup001")
      id_group_2 = common_functions_external_consent:GetGroupId(data, "ConsentGroup002")
    end)
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
  self.mobileSession:ExpectNotification("OnPermissionsChange"):Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Precondition:
-- Group001: is_consented = 0
-- Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsNotConsented()

--------------------------------------------------------------------------
-- Precondition:
-- Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_externalConsentStatus_OFF")

--------------------------------------------------------------------------
-- Main check:
-- Group001: is_consented = 0
-- Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsNotConsented()

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with consented function = allowed
--------------------------------------------------------------------------
Test["TEST_NAME_OFF_Precondition_HMI_sends_again_OnAppPermissionConsent_userConsent"] = function(self)
  local hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)

  -- hmi side: sending SDL.OnAppPermissionConsent for applications with omitted externalConsentStatus
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {
        {name = "ConsentGroup001", id = id_group_1, allowed = true},
        {name = "ConsentGroup002", id = id_group_2, allowed = true}
      }
    })

  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result_1 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      local validate_result_2 = common_functions_external_consent:ValidateHMIPermissions(data,
        "SubscribeVehicleData", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})

      if(validate_result_1 == false) then commonFunctions:printError("SubscribeWayPoints doesn't have permissions for allowed = {BACKGROUND, FULL, LIMITED}") end
      if(validate_result_2 == false) then commonFunctions:printError("SubscribeVehicleData doesn't have permissions for allowed = {BACKGROUND, FULL, LIMITED}") end

      return (validate_result_1 and validate_result_2)
    end)
end

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
  self.mobileSession:ExpectNotification("OnPermissionsChange"):Times(0)
  common_functions:DelayedExp(5000)
end

--------------------------------------------------------------------------
-- Precondition:
-- Group001: is_consented = 1
-- Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsConsented()

--------------------------------------------------------------------------
-- Precondition:
-- Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_externalConsentStatus_ON")

--------------------------------------------------------------------------
-- Main check:
-- Group001: is_consented = 1
-- Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsConsented()

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function()
  StopSDL()
end
