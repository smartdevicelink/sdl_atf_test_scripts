---------------------------------------------------------------------------------------------
-- Requirement summary:
-- OnPermissionsChange send after app's permissions change by Policy Table Update
--
-- Description:
-- In case the application is registered to SDL and the application's permissions are changed (items are either added or removed) because of applying the Updated Policy Table
-- SDL must: send OnPermissionsChange (<updated policies>) to such application.
-- 1. Used preconditions:
-- a) Set SDL to first life cycle state.
-- 2. Performed steps:
-- a) Register application, activate and consent device.
-- b) Check permissions from assigned default section and received in OnPermissionsChange notification.
-- c) Perform PTU.
-- d) Check permissions from assigned specific for app and received in OnPermissionsChange notification.
--
-- Expected result:
-- SDL notify app with new changed permissions via OnPermissionsChange
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')

function Test:TestStep_Assign_To_App_Default_Permissions_And_Check_Them_In_OnPermissionsChange()

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, { result = {
        code = 0,
        isSDLAllowed = false},
      method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
          :ValidIf(function(_,data1)
              local tableOfPolicyPermissions = commonFunctions:convert_ptu_to_permissions_change_data(config.pathToSDL .. "sdl_preloaded_pt.json", "Base-4", true)
              if commonFunctions:is_table_equal(tableOfPolicyPermissions, data1.payload.permissionItem) then
                return true
              else
                return false
              end
            end)
        end)
    end)
end

function Test:TestStep_Update_Policy_With_New_Permissions_And_Check_Them_In_OnPermissionsChange()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "filename"
        }
      )
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {
              fileName = "PolicyTableUpdate",
              requestType = "PROPRIETARY"
            }, "files/ptu_general_0000001.json")
          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              systemRequestId = data.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                {
                  policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                })
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 800)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              EXPECT_NOTIFICATION("OnPermissionsChange", {})
              :ValidIf(function(_,data1)
                  local tableOfPolicyPermissions = commonFunctions:convert_ptu_to_permissions_change_data("files/ptu_general_0000001.json", "Base-8", true)
                  if commonFunctions:is_table_equal(tableOfPolicyPermissions, data1.payload.permissionItem) then
                    return true
                  else
                    return false
                  end
                end)
            end)
        end)
    end)
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
