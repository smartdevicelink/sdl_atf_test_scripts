------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local policy_table = require('user_modules/shared_testcases_custom/testCasesForPolicyTable')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
TEST_NAME_ON = "EXTERNAL_CONSENT_ON:_"
TEST_NAME_OFF = "EXTERNAL_CONSENT_OFF:_"
local external_consent_common_functions = {}
------------------------------------------------------------------------------------------------------
---------------------------------------Common Functions-----------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- function: delete sdl_snapshot, delete logs and policy table, connect mobile and register 2 applications
-- params:
-- mobile_connection_name: mobile connection name
-- mobile_session_name_1: name of first application's mobile session
-- mobile_session_name_2: name of second application's mobile session. If mobile_session_name_2 == nil, the application 2 will not be added
--------------------------------------------------------------------------
function external_consent_common_functions:PreconditonSteps(mobile_connection_name, mobile_session_name_1, mobile_session_name_2)
  -- delete sdl_snapshot
  os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
  -- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, HmiFrameworkPlugin.log and policy.sqlite
  common_functions:DeleteLogsFileAndPolicyTable()
  common_steps:PreconditionSteps("Start_SDL_and_Add_Mobile_Connection", 4)
  -- register and activate first application (appID = "0000001")
  common_steps:AddMobileSession("Add_Mobile_Session_1", mobile_connection_name, mobile_session_name_1)
  common_steps:RegisterApplication("Register_Application_1", mobile_session_name_1, config.application1.registerAppInterfaceParams)
  if mobile_session_name_2 then
    -- register second application (appID = "0000002")
    common_steps:AddMobileSession("Add_Mobile_Session_2", mobile_connection_name, mobile_session_name_2)
    common_steps:RegisterApplication("Register_Application_2", mobile_session_name_2, config.application2.registerAppInterfaceParams)
  end
end

--------------------------------------------------------------------------
-- function: Convert preload_pt.json file to a json file, which is used to update policy
-- params: no
--------------------------------------------------------------------------
function external_consent_common_functions:ConvertPreloadedToJson()
  -- load data from sdl_preloaded_pt.json
  path_to_file = config.pathToSDL .. "sdl_preloaded_pt.json"
  local file = io.open(path_to_file, "r")
  local json_data = file:read("*all")
  file:close()
  -- decode json to array
  local json = require("json")
  local data = json.decode(json_data)
  local function has_value (tab, val)
    for index, value in ipairs (tab) do
      if value == val then
        return true
      end
    end
    return false
  end
  for k,v in pairs(data.policy_table.functional_groupings) do
    if has_value(data.policy_table.app_policies.default.groups, k) or
    has_value(data.policy_table.app_policies.pre_DataConsent.groups, k) then
    else
      data.policy_table.functional_groupings[k] = nil
    end
  end
  return data
end

--------------------------------------------------------------------------
-- function: Create json file for Policy Table Update
-- params:
-- input_data: data table will be encoded to json style and added into file
-- json_file_path: path of json file which will be used for policy updating
-- json_file_path_debug: path of debug json file, keep for debug only. If value == nil then do not save file for debug
--------------------------------------------------------------------------
function external_consent_common_functions:CreateJsonFileForPTU(input_data, json_file_path, json_file_path_debug)
  -- save file for update policy
  local json = require("json")
  data = json.encode(input_data)
  file = io.open(json_file_path, "w")
  file:write(data)
  file:close()
  -- save file for debugging
  if json_file_path_debug then
    file_debug = io.open(json_file_path_debug, "w")
    file_debug:write(data)
    file_debug:close()
  end
end

--------------------------------------------------------------------------
-- function: Update policy
-- params:
-- self
-- json_file_path: path of json file which will be used for policy updating
-- input_app_id: appID of application which policy will be updated. If value == nil then use id of first app
--------------------------------------------------------------------------
function external_consent_common_functions:UpdatePolicy(self, json_file_path, input_app_id)
  if not input_app_id then
    input_app_id = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  end
  --hmi side: sending SDL.GetURLS request
  local request_id_get_urls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  --hmi side: expect SDL.GetURLS response from HMI
  EXPECT_HMIRESPONSE(request_id_get_urls)
  :Do(function(_,data)
    --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {
      requestType = "PROPRIETARY",
      fileName = "PolicyTableUpdate",
      appID = input_app_id
    })
    --mobile side: expect OnSystemRequest notification
    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
    :Do(function(_,data)
      --mobile side: sending SystemRequest request
      local corid = self.mobileSession:SendRPC("SystemRequest",{
        fileName = "PolicyTableUpdate",
        requestType = "PROPRIETARY"
      },
      json_file_path
      )
      local system_request_id
      --hmi side: expect SystemRequest request
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
        system_request_id = data.id
        --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
        {
          policyfile = json_file_path
        }
        )
        function to_run()
          --hmi side: sending SystemRequest response
          self.hmiConnection:SendResponse(system_request_id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end

        RUN_AFTER(to_run, 1500)
      end)
      --hmi side: expect SDL.OnStatusUpdate
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
      :ValidIf(function(exp,data)
        if
        exp.occurences == 1 and
        data.params.status == "UP_TO_DATE" then
          return true
        elseif
        exp.occurences == 1 and
        data.params.status == "UPDATING" then
          return true
        elseif
        exp.occurences == 2 and
        data.params.status == "UP_TO_DATE" then
          return true
        else
          if
          exp.occurences == 1 then
            print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
          elseif exp.occurences == 2 then
            print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
          end
          return false
        end
      end)
      :Times(Between(1,2))
      --mobile side: expect SystemRequest response
      EXPECT_RESPONSE(corid, { success = true, resultCode = "SUCCESS"})
      :Do(function(_,data)
        --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
        local request_id_GetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
        --hmi side: expect SDL.GetUserFriendlyMessage response
        EXPECT_HMIRESPONSE(request_id_GetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
      end) -- Do EXPECT_RESPONSE: SystemRequest response
    end) -- Do EXPECT_NOTIFICATION: "OnSystemRequest" notification
  end) -- Do EXPECT_HMIRESPONSE: SDL.GetURLS response from HMI
end

--------------------------------------------------------------------------
-- function: Get group id of function_groups in allowedFunctions array of GetListOfPermissions response
-- params:
-- data: data from the SDL.GetListOfPermissions response
-- group_name: consent group name of group which is needed to get id
--------------------------------------------------------------------------
function external_consent_common_functions:GetGroupId(data, group_name)
  for i = 1, #data.result.allowedFunctions do
    if(data.result.allowedFunctions[i].name == group_name) then
      return data.result.allowedFunctions[i].id
    end
  end
end

--------------------------------------------------------------------------
-- function: Validate hmiPermissions of specific RPC
-- params:
-- data: data payload from hmi
-- rpc_name: name of rpc
-- expected_table: the expected table to compare with actual hmiPermissions table
--------------------------------------------------------------------------
function external_consent_common_functions:ValidateHMIPermissions(data, rpc_name, expected_table)
  for i = 1, #data.payload.permissionItem do
    if data.payload.permissionItem[i].rpcName == rpc_name then
      if expected_table then
        return common_functions:CompareTables(data.payload.permissionItem[i].hmiPermissions, expected_table)
      else
        return true
      end
    end
  end
  return false
end

return external_consent_common_functions
