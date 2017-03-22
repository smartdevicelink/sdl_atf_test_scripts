---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [USER_DISALLOWED]: Conditions for USER_DISALLOWED result code
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polciies
-- SDL must return 'USER_DISALLOWED, success:false' to mobile app
-- in case the requested RPC is included to the group disallowed by the user.
--
-- 1. Used preconditions
-- SDL is built with External Proprietary flag.
-- Include in Testing_group(user_consent group) RPC SetAudioStreamingIndicator
-- Register and activate media application
-- Perform successfull PTU for External Proprietary flow
-- Disallow by user SetAudioStreamingIndicator
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response("USER_DISALLOWED", success:false)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ Local Functions ]]

--[[@create_ptu_SetAudioStreamingIndicator_group: update sdl_preloaded_pt and creates PTU files
! sdl_preloaded_pt.json: add Testing_group with RPC SetAudioStreamingIndicator and user consent
! SetAudioStreamingIndicator_group1.json: Assign groups "Base-4", "Testing_group" to application
! @parameters: NO
]]
local function create_ptu_SetAudioStreamingIndicator_group()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  local config_path = commonPreconditions:GetPathToSDL()
  
  local pathToFile = config_path .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  data.policy_table.functional_groupings["Base-4"].rpcs.SetAudioStreamingIndicator = nil
  data.policy_table.functional_groupings["Testing_group"] = {
    user_consent_prompt = "Purpose_of_Test",
    rpcs = {
      SetAudioStreamingIndicator = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
      }
    }
  }
  
  file = io.open(config_path .. 'sdl_preloaded_pt.json', "w")
  file:write(json.encode(data))
  file:close()

  data.policy_table.module_config.preloaded_pt = nil
  data.policy_table.module_config.preloaded_date = nil
  data.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] =
  {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Testing_group"}
  }

  file = io.open("SetAudioStreamingIndicator_group1.json", "w")
  file:write(json.encode(data))
  file:close()
end


--[[ General Precondition before ATF start ]]
create_ptu_SetAudioStreamingIndicator_group()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:Precondition_SetAudioStreamingIndicator_DISALLOWED_audioStreamingIndicator_PLAY_PAUSE()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY_PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "DISALLOWED"})
end

function Test:Precondition_PTU_appPermissionsConsentNeeded_false()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_,_)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
    :Do(function(_,_)
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "SetAudioStreamingIndicator_group1.json")

      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."/PolicyTableUpdate"})

        local function to_run()
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end
        RUN_AFTER(to_run, 500)
      end)

      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
      :Do(function(_,data)
        if(data.params.status == "UP_TO_DATE") then
          EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], appPermissionsConsentNeeded = true })
          :Do(function()
            local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })

            EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
            :Do(function(_,data1)
              local groups = {}
              if #data1.result.allowedFunctions > 0 then
                for i = 1, #data1.result.allowedFunctions do
                  groups[i] = {
                    name = data1.result.allowedFunctions[i].name,
                    id = data1.result.allowedFunctions[i].id,
                    allowed = false}
                end
              end
              self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications[config.application1.registerAppInterfaceParams.appName], consentedFunctions = groups, source = "GUI"})
              EXPECT_NOTIFICATION("OnPermissionsChange")
            end)
          end)
        end
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_USER_Disallowed_RPC_disallowed_by_user()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "USER_DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  os.execute( " rm -f SetAudioStreamingIndicator_group1.json" )
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
