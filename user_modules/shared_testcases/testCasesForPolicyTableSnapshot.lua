local testCasesForPolicyTableSnapshot = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local expectations = require('expectations')

local expOrig = expectations.Expectation
function expectations.Expectation(name, connection)
  local e = expOrig(name, connection)
  e.timeout = e.timeout + 10000
  return e
end

testCasesForPolicyTableSnapshot.preloaded_elements = {}
testCasesForPolicyTableSnapshot.pts_elements = {}
testCasesForPolicyTableSnapshot.seconds_between_retries = {}
testCasesForPolicyTableSnapshot.preloaded_pt = {}

local json_elements = {}

-----------------------------------------------------------------------------------------------------------------
-- The function extract specific json file and returns array <json_elements> with data:
-- <section_1>.<section_1>....<section_n>.name
-- <section_1>.<section_1>....<section_n>.value
local function extract_json(pathToFile)
  json_elements = {}
  if( commonSteps:file_exists(pathToFile) ) then

    local file = io.open(pathToFile, "r")
    local json_data = file:read("*all")
    file:close()

    local json = require("modules/json")
    local data = json.decode(json_data)
    local i = 1

    for index_level1, value_level1 in pairs(data.policy_table) do
      if(type(value_level1) ~= "table") then
        json_elements[i] = { name = index_level1 , elem_required = nil, value = value_level1}
        i = i + 1
      else
        --TODO(istoimenova): This function requires refactoring
        for index_level2, value_level2 in pairs(value_level1) do
          if( type(value_level2) ~= "table" ) then
            json_elements[i] = { name = index_level1.."."..index_level2, elem_required = nil, value = value_level2 }
            i = i + 1
          else
            for index_level3, value_level3 in pairs(value_level2) do

              if(type(value_level3) ~= "table") then
                json_elements[i] = { name = index_level1 .. "."..index_level2.."."..index_level3 , elem_required = nil, value = value_level3 }
                i = i + 1
              else
                for index_level4, value_level4 in pairs(value_level3) do

                  if(type(value_level4) ~= "table") then
                    json_elements[i] = { name = index_level1 .. "."..index_level2 .. "."..index_level3.."."..index_level4, elem_required = nil, value = value_level4 }
                    i = i + 1
                  else
                    for index_level5, value_level5 in pairs(value_level4) do
                      if(type(value_level5) ~= "table") then
                        json_elements[i] = { name = index_level1 .. "."..index_level2 .. "."..index_level3.. "."..index_level4.."."..index_level5, elem_required = nil, value = value_level5 }
                        i = i + 1
                      else
                        for index_level6, value_level6 in pairs(value_level5) do
                          if(type(value_level6) ~= "table") then
                            json_elements[i] = { name = index_level1 .. "."..index_level2 .. "."..index_level3.. "."..index_level4 .. "."..index_level5.."."..index_level6, elem_required = nil, value = value_level6 }
                            i = i + 1
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  else
    print("file doesn't exist: " ..pathToFile)
  end
end

-----------------------------------------------------------------------------------------------------------------
-- The function extract sdl_preloaded_pt.json and returns array testCasesForPolicyTableSnapshot.preloaded_elements
-- with parameters: name and value
function testCasesForPolicyTableSnapshot:extract_preloaded_pt()
  testCasesForPolicyTableSnapshot.preloaded_elements = {}
  testCasesForPolicyTableSnapshot.seconds_between_retries = {}
  local preloaded_pt = commonPreconditions:GetPathToSDL() ..'sdl_preloaded_pt.json'
  extract_json(preloaded_pt)
  local k = 1
  for i = 1, #json_elements do
    testCasesForPolicyTableSnapshot.preloaded_elements[i] = { name = json_elements[i].name, value = json_elements[i].value }
    if( string.sub(json_elements[i].name,1,string.len("module_config.seconds_between_retries.")) == "module_config.seconds_between_retries." ) then
      testCasesForPolicyTableSnapshot.seconds_between_retries[k] = { name = json_elements[i].name, value = json_elements[i].value}
      k = k + 1
    end
  end
end
local preloaded_pt_endpoints = {}

-----------------------------------------------------------------------------------------------------------------
-- The function does:
-- Gets data from preloaded_pt.json file and create local array #data_dictionary according to S13j_Applink_Policy_Table_Data_Dictionary_046_LizEdits.xlsx.
-- Check if PTS is created.
-- In case PTS is created and is_created == true gets data from PTS.
-- According to parameters app_IDs, device_IDs, app_names fills sections that should be included for applications and devices for verification.
-- Check that all datas that are required in #data_dictionary are included in PTS.
-- Check that all datas that are optional in #data_dictionary may be included in PTS.
-- Check that all datas that are omittted in #data_dictionary are not included in PTS.
-- Check that value of elements in PTS is correctly exported from sdl_preloaded_pt.json.
--
-- Return data
-- testCasesForPTS.pts_elements – array of all elements in PTS.
-- testCasesForPTS.pts_endpoints = {}
-- testCasesForPTS.pts_seconds_between_retries = {}
-- flag: If is set to PROPRIETARY or HTTP will verify section SDL in DataDictionary
-- in all other cases: (nil or EXTERNAL_PROPRIETARY) will check SDL + Ford DataDictionary
function testCasesForPolicyTableSnapshot:verify_PTS(is_created, app_IDs, device_IDs, app_names, to_print, flag)
  if ( flag == nil ) then flag = "EXTERNAL_PROPRIETARY" end
  local is_verification_passed = true
  preloaded_pt_endpoints = {}
  --local data_dictionary = {}
  -- Data dictionary according to which PTS should be created. Will be automated export from xls.
  local origin_data_dictionary =
  {
    { name = "module_config.preloaded_pt", elem_required = "optional"},
    { name = "module_config.preloaded_date", elem_required = "optional"},
    { name = "module_config.exchange_after_x_ignition_cycles", elem_required = "required"},
    { name = "module_config.exchange_after_x_kilometers", elem_required = "required"},
    { name = "module_config.exchange_after_x_days", elem_required = "required"},
    { name = "module_config.timeout_after_x_seconds", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.EMERGENCY", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.NAVIGATION", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.VOICECOM", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.COMMUNICATION", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.NORMAL", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.NONE", elem_required = "required"},
    { name = "module_config.notifications_per_minute_by_priority.PROJECTION", elem_required = "optional"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.EMERGENCY", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.NAVIGATION", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.VOICECOM", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.COMMUNICATION", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.NORMAL", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.NONE", elem_required = "required"},
    { name = "module_config.subtle_notifications_per_minute_by_priority.PROJECTION", elem_required = "optional"},
    { name = "module_config.certificate", elem_required = "optional"},
    { name = "module_config.vehicle_make", elem_required = "optional"},
    { name = "module_config.vehicle_model", elem_required = "optional"},
    { name = "module_config.vehicle_year", elem_required = "optional"},
    { name = "module_config.display_order", elem_required = "optional"},
    { name = "module_config.full_app_id_supported", elem_required = "required"},
    { name = "module_config.lock_screen_dismissal_enabled", elem_required = "optional"},

    { name = "consumer_friendly_messages.version", elem_required = "required"},

    { name = "app_policies.default.priority", elem_required = "required"},
    { name = "app_policies.default.memory_kb", elem_required = "optional"},
    { name = "app_policies.default.heart_beat_timeout_ms", elem_required = "optional"},
    { name = "app_policies.default.RequestType", elem_required = "optional"},
    { name = "app_policies.pre_DataConsent.priority", elem_required = "required"},
    { name = "app_policies.pre_DataConsent.memory_kb", elem_required = "optional"},
    { name = "app_policies.pre_DataConsent.heart_beat_timeout_ms", elem_required = "optional"},
    { name = "app_policies.pre_DataConsent.RequestType", elem_required = "optional"},
    -- RC
    { name = "module_config.country_consent_passengersRC", elem_required = "optional" },
    { name = "module_config.equipment.zones.Front_Passenger.col", elem_required = "optional" },
    { name = "module_config.equipment.zones.Front_Passenger.row", elem_required = "optional" },
    { name = "module_config.equipment.zones.Front_Passenger.level", elem_required = "optional" },
    { name = "module_config.equipment.zones.Right_Rear_Passenger.col", elem_required = "optional" },
    { name = "module_config.equipment.zones.Right_Rear_Passenger.row", elem_required = "optional" },
    { name = "module_config.equipment.zones.Right_Rear_Passenger.level", elem_required = "optional" },
    { name = "module_config.equipment.zones.Left_Rear_Passenger.col", elem_required = "optional" },
    { name = "module_config.equipment.zones.Left_Rear_Passenger.row", elem_required = "optional" },
    { name = "module_config.equipment.zones.Left_Rear_Passenger.level", elem_required = "optional" },
    { name = "module_config.equipment.zones.Driver.col", elem_required = "optional" },
    { name = "module_config.equipment.zones.Driver.row", elem_required = "optional" },
    { name = "module_config.equipment.zones.Driver.level", elem_required = "optional" },
    { name = "app_policies.pre_DataConsent.certificate", elem_required = "optional"},
    { name = "app_policies.default.groups_nonPrimaryRC.1", elem_required = "optional"},
    { name = "app_policies.default.groups_nonPrimaryRC.2", elem_required = "optional"},
    { name = "app_policies.default.certificate", elem_required = "optional"},
    { name = "app_policies.default.groups_primaryRC.1", elem_required = "optional"},
    { name = "app_policies.default.groups_primaryRC.2", elem_required = "optional"},
    { name = "app_policies.default.moduleType.1", elem_required = "optional"},
    { name = "app_policies.default.moduleType.2", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.memory_kb", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.heart_beat_timeout_ms", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.RequestType", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.certificate", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.priority", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.groups.1", elem_required = "optional"},
    { name = "app_policies.pre_consent_passengersRC.AppHMIType.1", elem_required = "optional"},
    -- custom vehicle_data
    { name = "module_config.endpoint_properties.custom_vehicle_data_mapping_url.version", elem_required = "optional"},
    { name = "vehicle_data.schema_version", elem_required = "optional"}
  }

  if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
    table.insert(origin_data_dictionary,  { name = "app_policies.default.keep_context", elem_required = "required"} )
    table.insert(origin_data_dictionary,  { name = "app_policies.default.steal_focus", elem_required = "required"} )
    table.insert(origin_data_dictionary,  { name = "app_policies.default.default_hmi", elem_required = "required"} )
    table.insert(origin_data_dictionary,  { name = "app_policies.pre_DataConsent.keep_context", elem_required = "required"} )
    table.insert(origin_data_dictionary,  { name = "app_policies.pre_DataConsent.steal_focus", elem_required = "required"} )
    table.insert(origin_data_dictionary,  { name = "app_policies.pre_DataConsent.default_hmi", elem_required = "required"} )
  end

  local data_dictionary = origin_data_dictionary

  local omitted_preloaded_original =
  {
    { name = "module_meta.pt_exchanged_at_odometer_x", elem_required = "required"},
    { name = "module_meta.pt_exchanged_x_days_after_epoch", elem_required = "required"},
    { name = "module_meta.ignition_cycles_since_last_exchange", elem_required = "required"},



    { name = "app_policies.device.time_stamp", elem_required = "optional"},

    { name = "app_policies.device.priority", elem_required = "required"},

  }

  if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
      table.insert(omitted_preloaded_original,  { name = "module_meta.ccpu_version", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "module_meta.language", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "module_meta.wers_country_code", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "module_meta.vin", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "app_policies.device.keep_context", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "app_policies.device.steal_focus", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "app_policies.device.default_hmi", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "usage_and_error_counts.count_of_iap_buffer_full", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "usage_and_error_counts.count_sync_out_of_memory", elem_required = "required"} )
      table.insert(omitted_preloaded_original,  { name = "usage_and_error_counts.count_of_sync_reboots", elem_required = "required"} )
  end


  if(app_IDs ~= nil) then
    for i = 1, #app_IDs do
      omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_TLS_errors", elem_required = "required"}

      if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".minutes_in_hmi_full", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".app_registration_language_gui", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".app_registration_language_vui", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".minutes_in_hmi_limited", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".minutes_in_hmi_background", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".minutes_in_hmi_none", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_user_selections", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_rejections_sync_out_of_memory", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_rejections_nickname_mismatch", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_rejections_duplicate_name", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_rejected_rpc_calls", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_rpcs_sent_in_hmi_none", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_removals_for_bad_behavior", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_run_attempts_while_revoked", elem_required = "required"}
        -- omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".count_of_invalid_certificates", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "usage_and_error_counts.app_level."..app_IDs[i]..".time_stamp", elem_required = "optional"}
      end
    end
  end
  if(device_IDs ~= nil) then
    for i = 1, #device_IDs do
      if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".hardware", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".firmware_rev", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".os", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".os_version", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".carrier", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".max_number_rfcom_ports", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".connection_type", elem_required = "required"}
        --TODO(istoimenova): Update when "[GENIVI] SDL must support "Mobile Apps via USB" setting for each Android device " is implemented
        --omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".usb_transport_enabled", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records.device.input", elem_required = "required"}
        omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records.device.time_stamp", elem_required = "required"}
      end

      --TODO(istoimenova): Clarification for the section - exist only if application has consented groups?
--[[      if(app_IDs ~= nil) then
        for j = 1, #app_IDs do
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".minutes_in_hmi_full", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".app_registration_language_gui", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".app_registration_language_vui", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".minutes_in_hmi_limited", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".minutes_in_hmi_background", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".minutes_in_hmi_none", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_user_selections", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_rejections_sync_out_of_memory", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_rejections_nickname_mismatch", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_rejections_duplicate_name", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_rejected_rpc_calls", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_rpcs_sent_in_hmi_none", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_removals_for_bad_behavior", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_run_attempts_while_revoked", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_TLS_errors", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".count_of_invalid_certificates", elem_required = "required"}
          omitted_preloaded_original[#omitted_preloaded_original + 1] = { name = "device_data."..device_IDs[i]..".user_consent_records."..app_IDs[j]..".input", elem_required = "required"}
        end
      end]]
    end
  end

  for i = 1, #omitted_preloaded_original do
    data_dictionary[#data_dictionary + 1] = omitted_preloaded_original[i]
  end

  testCasesForPolicyTableSnapshot.preloaded_elements = {}
  testCasesForPolicyTableSnapshot.pts_elements = {}
  testCasesForPolicyTableSnapshot.seconds_between_retries = {}
  testCasesForPolicyTableSnapshot.preloaded_pt = {}

  if(is_created == false) then
    if ( commonSteps:file_exists( '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json') ) then
      print(" \27[31m /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json is created \27[0m")
    end
  else
    testCasesForPolicyTableSnapshot:extract_preloaded_pt()

    local k = 1

    for i = 1, #json_elements do
      if( string.sub(json_elements[i].name,1,string.len("module_config.endpoints.")) == "module_config.endpoints." ) then
        local substr = {}
        local j = 1
        for each_element in string.gmatch(json_elements[i].name,"[^.]*") do
          substr[j] = each_element
          j = j+1
        end
        if(preloaded_pt_endpoints == nil) then
          preloaded_pt_endpoints[#preloaded_pt_endpoints + 1] = substr[5]
        elseif(preloaded_pt_endpoints[#preloaded_pt_endpoints] ~= substr[5]) then
          preloaded_pt_endpoints[#preloaded_pt_endpoints + 1] = substr[5]
        end
      end
    end
    for i = 1, #preloaded_pt_endpoints do
      testCasesForPolicyTableSnapshot.preloaded_pt[i] = preloaded_pt_endpoints[i]
    end

    local consent_groups = {}
    for i = 1, #json_elements do
      local str_1 = json_elements[i].name
      if( string.sub(str_1,1,string.len("functional_groupings.")) == "functional_groupings." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
      end

      if( string.sub(str_1,1,string.len("app_policies.default.groups.")) == "app_policies.default.groups." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
      end

      if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
        if( string.sub(str_1,1,string.len("app_policies.default.preconsented_groups.")) == "app_policies.default.preconsented_groups." ) then
          data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "optional" }
        end
      end

      if( string.sub(str_1,1,string.len("app_policies.default.AppHMIType.")) == "app_policies.default.AppHMIType." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "optional" }
      end

      if( string.sub(str_1,1,string.len("app_policies.pre_DataConsent.groups.")) == "app_policies.pre_DataConsent.groups." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
      end

      if( string.sub(str_1,1,string.len("app_policies.pre_DataConsent.preconsented_groups.")) == "app_policies.pre_DataConsent.preconsented_groups." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "optional" }
      end

      if( string.sub(str_1,1,string.len("app_policies.pre_DataConsent.AppHMIType.")) == "app_policies.pre_DataConsent.AppHMIType." ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "optional" }
      end

      if( string.sub(str_1,1,string.len("module_config.seconds_between_retries.")) == "module_config.seconds_between_retries." ) then
        testCasesForPolicyTableSnapshot.seconds_between_retries[k] = { name = json_elements[i].name, value = json_elements[i].value}
        k = k + 1
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
      end

      if( string.sub(str_1,1,string.len("app_policies.device.consent_groups")) == "app_policies.device.consent_groups" ) then
        data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
      end
      if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
        if( string.sub(str_1,1,string.len("app_policies.device.groups")) == "app_policies.device.groups" ) then
          consent_groups[#consent_groups +1 ] = json_elements[i].value
          data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
        end

        if( string.sub(str_1,1,string.len("app_policies.device.preconsented_groups")) == "app_policies.device.preconsented_groups" ) then
          data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "required" }
        end
      end

      for cnt = 1, #preloaded_pt_endpoints do
       -- length_data_dict = #data_dictionary
        if( string.sub(str_1,1,string.len("module_config.endpoints."..preloaded_pt_endpoints[cnt]..".default.")) == "module_config.endpoints."..preloaded_pt_endpoints[cnt]..".default." ) then
          data_dictionary[#data_dictionary + 1] = { name = json_elements[i].name, value = json_elements[i].value, elem_required = "optional" }
        end
      end
    end --for i = 1, #json_elements do

    if(device_IDs~= nil) then
        for k1 = 1, #device_IDs do
          if(consent_groups ~= nil) then
            for con = 1, #consent_groups do
              data_dictionary[#data_dictionary + 1] = { name = "device_data."..device_IDs[k1]..".user_consent_records.device.consent_groups."..consent_groups[con]
              , value = consent_groups[con], elem_required = "required" }
            end
          end
        end
      end

    if(app_IDs ~= nil) then
      for i = 1, #app_IDs do

        --TODO(istoimenova): should be updated in future, due to luck of time
        data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts.app_level."..tostring(app_IDs[i])..".AppHMIType", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts.app_level."..tostring(app_IDs[i])..".memory_kb", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts.app_level."..tostring(app_IDs[i])..".heart_beat_timeout_ms", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts.app_level."..tostring(app_IDs[i])..".RequestType", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i]), value = nil, elem_required = "optional" }

        -- Will be applicable after app gets specific different than default group
        -- data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".nicknames", value = nil, elem_required = "required" }
        -- data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".priority", value = nil, elem_required = "required" }
        -- data_dictionary[#data_dictionary + 1 + 19] = { name = "app_policies."..tostring(app_IDs[i])..".groups", value = nil, elem_required = "required" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".AppHMIType", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".memory_kb", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".heart_beat_timeout_ms", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i])..".RequestType", value = nil, elem_required = "optional" }
        data_dictionary[#data_dictionary + 1] = { name = "app_policies."..tostring(app_IDs[i]), value = nil, elem_required = "optional" }
    --     if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
    --       table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".keep_context", elem_required = "required"} )
    --       table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".steal_focus", elem_required = "required"} )
    --       table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".default_hmi", elem_required = "required"} )
    --       -- TODO(istoimenova): preconsented_groups will be suspended due to lack of time
    --       --
    --       -- table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".preconsented_groups", elem_required = "required"} )
    --     end
    --   end
    -- else
    --   data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts", elem_required = "required"}
    -- end
    if(flag ~= "PROPRIETARY" and flag ~= "HTTP") then
          if (function(appID)
            for kk = 1, #testCasesForPolicyTableSnapshot.pts_elements do
              if testCasesForPolicyTableSnapshot.pts_elements[kk].name == ("app_policies." .. tostring(appID)) and testCasesForPolicyTableSnapshot.pts_elements[kk].value == "default" then
                return true
              end
            end
            return false
           end)(app_IDs[i]) then
            table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".keep_context", elem_required = "required"} )
            table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".steal_focus", elem_required = "required"} )
            table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".default_hmi", elem_required = "required"} )
          end
          -- TODO(istoimenova): preconsented_groups will be suspended due to lack of time
          --
          -- table.insert(data_dictionary,  { name = "app_policies."..tostring(app_IDs[i])..".preconsented_groups", elem_required = "required"} )
        end
      end
    else
      data_dictionary[#data_dictionary + 1] = { name = "usage_and_error_counts", elem_required = "required"}
    end

    local pts = '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json'
    if ( commonSteps:file_exists(pts) ) then
      testCasesForPolicyTableSnapshot:extract_pts()
      -- Skip other devices
      if device_IDs ~= nil then
        for i = #testCasesForPolicyTableSnapshot.pts_elements, 1, -1 do
          local item = testCasesForPolicyTableSnapshot.pts_elements[i].name
          if string.find(item, "^device_data") and not string.find(item, device_IDs[1]) then
            table.remove(testCasesForPolicyTableSnapshot.pts_elements, i)
          end
        end
      end
      --Check for ommited parameters
      for i = 1, #testCasesForPolicyTableSnapshot.pts_elements do
        local is_existing = false
        local str_1 = testCasesForPolicyTableSnapshot.pts_elements[i].name
        for j = 1, #data_dictionary do
          local str_2 = data_dictionary[j].name
          if( str_1 == str_2 ) then
            is_existing = true
            for k1 = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
              if(testCasesForPolicyTableSnapshot.preloaded_elements[k1].name == "module_config.preloaded_pt") then
                testCasesForPolicyTableSnapshot.preloaded_elements[k1].value = false
              end

              if(testCasesForPolicyTableSnapshot.preloaded_elements[k1].name == str_2) then
                if(testCasesForPolicyTableSnapshot.pts_elements[i].value ~= testCasesForPolicyTableSnapshot.preloaded_elements[k1].value) then
                  if(to_print ~= nil) then
                    is_verification_passed = false
                    print(testCasesForPolicyTableSnapshot.pts_elements[i].name .." = " .. tostring(testCasesForPolicyTableSnapshot.pts_elements[i].value) .. ". Should be " ..tostring(testCasesForPolicyTableSnapshot.preloaded_elements[k1].value) )
                  end
                end
              end
            end
            break
          end
        end
        if (is_existing == false) then
          if(to_print ~= nil) then
            is_verification_passed = false
            print(testCasesForPolicyTableSnapshot.pts_elements[i].name .. ": should NOT exist")
          end
        end
      end

      --Check for mandatory elements
      for i = 1, #data_dictionary do
        local is_existing = false
        if(data_dictionary[i].elem_required == "required") then
          local str_2 = data_dictionary[i].name
          for j = 1, #testCasesForPolicyTableSnapshot.pts_elements do
            local str_1 = testCasesForPolicyTableSnapshot.pts_elements[j].name
            if( str_1 == str_2 ) then
              is_existing = true
              break
            end
          end
        else
          is_existing = true
        end
        if (is_existing == false) then
          if(to_print ~= nil) then
            is_verification_passed = false
            print(data_dictionary[i].name .. ": mandatory parameter does not exist in PTS")
          end
        end
      end
    else
      is_verification_passed = false
      commonFunctions:printError("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json doesn't exits! ")
    end
  end --if(is_created == false) then
  return is_verification_passed
end

testCasesForPolicyTableSnapshot.pts_endpoints = {}
testCasesForPolicyTableSnapshot.pts_endpoints_apps = {}
testCasesForPolicyTableSnapshot.pts_seconds_between_retries = {}

-----------------------------------------------------------------------------------------------------------------
-- The function extract data form sdl_snapshot and is used in testCasesForPolicyTableSnapshot:verify_PTS
-- for check correct snapshot creation
--
-- Returns global variables:
-- testCasesForPolicyTableSnapshot.pts_seconds_between_retries
-- testCasesForPolicyTableSnapshot.pts_endpoints including appID check of presence
function testCasesForPolicyTableSnapshot:extract_pts(app_IDs, hmi_IDs)
  testCasesForPolicyTableSnapshot.pts_endpoints = {}
  testCasesForPolicyTableSnapshot.pts_endpoints_apps = {}
  testCasesForPolicyTableSnapshot.pts_seconds_between_retries = {}
  local pts_json = '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json'
  extract_json(pts_json)
  local length_pts

  for i = 1, #json_elements do
    length_pts = #testCasesForPolicyTableSnapshot.pts_elements
    testCasesForPolicyTableSnapshot.pts_elements[length_pts + 1] = {
      name = json_elements[i].name,
      value = json_elements[i].value
    }
  end

  local length_seconds_between_retries
  for i = 1, #json_elements do
    length_seconds_between_retries = #testCasesForPolicyTableSnapshot.pts_seconds_between_retries
    testCasesForPolicyTableSnapshot.pts_elements[i] = { name = json_elements[i].name, value = json_elements[i].value }

    if( string.sub(json_elements[i].name,1,string.len("module_config.seconds_between_retries.")) == "module_config.seconds_between_retries." ) then
      testCasesForPolicyTableSnapshot.pts_seconds_between_retries[length_seconds_between_retries + 1] = { name = json_elements[i].name, value = json_elements[i].value}
    end

    for j = 1, #preloaded_pt_endpoints do
      if( string.sub(json_elements[i].name,1,string.len("module_config.endpoints."..tostring(preloaded_pt_endpoints[j])..".default.")) == "module_config.endpoints."..tostring(preloaded_pt_endpoints[j])..".default." ) then
        testCasesForPolicyTableSnapshot.pts_endpoints[#testCasesForPolicyTableSnapshot.pts_endpoints + 1] = { name = json_elements[i].name, value = json_elements[i].value, service = preloaded_pt_endpoints[j], appID = nil}
      end

      if(app_IDs ~= nil) then
        for k2 = 1, #app_IDs do
          if( string.sub(json_elements[i].name,1,string.len("module_config.endpoints."..tostring(preloaded_pt_endpoints[j]).."."..app_IDs[k2]..".")) == "module_config.endpoints."..tostring(preloaded_pt_endpoints[j]).."."..app_IDs[k2].."." ) then
            testCasesForPolicyTableSnapshot.pts_endpoints[#testCasesForPolicyTableSnapshot.pts_endpoints + 1] = { name = json_elements[i].name, value = json_elements[i].value, service = preloaded_pt_endpoints[j], appID = hmi_IDs[k2]}
          end
        end
      end
    end
  end
end

-----------------------------------------------------------------------------------------------------------------
-- The function returns value of specific data from sdl snapshot
-- pts_element should be in format: module_config.timeout_after_x_seconds to define correct section of search
function testCasesForPolicyTableSnapshot:get_data_from_PTS(pts_element)
  testCasesForPolicyTableSnapshot:extract_pts()
  local value
  local is_found = false
  for i = 1, #testCasesForPolicyTableSnapshot.pts_elements do
    if (pts_element == testCasesForPolicyTableSnapshot.pts_elements[i].name) then
      value = testCasesForPolicyTableSnapshot.pts_elements[i].value
      is_found = true
      break
    end
  end
  if(is_found == false) then
    print(" \27[33m Element "..pts_element.." is not found in PTS! \27[0m")
  end
  if (value == nil) then
    print(" \27[33m Value of "..pts_element.." is nil \27[0m")
  end

  return value
end

-----------------------------------------------------------------------------------------------------------------
-- The function returns value of specific data from sdl preloaded_pt.json
-- preloaded_element should be in format: module_config.timeout_after_x_seconds to define correct section of search
function testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT(preloaded_element)
  testCasesForPolicyTableSnapshot.extract_preloaded_pt()
  local value
  local is_found = false
  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if (preloaded_element == testCasesForPolicyTableSnapshot.preloaded_elements[i].name) then
      value = testCasesForPolicyTableSnapshot.preloaded_elements[i].value
      is_found = true
      break
    end
  end
  if(is_found == false) then
    print(" \27[31m Element "..preloaded_element.." is not found in preloaded_pt.json! \27[0m")
  end
  if (value == nil) then
    print(" \27[31m Value of "..preloaded_element.." is nil \27[0m")
    value = 0
  end

  return value
end

return testCasesForPolicyTableSnapshot
