---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User consent initiatation after Policy Table update
-- Description:
-- Local PT is successfully updated AND there are new application permissions that require User`s consent. App is in FULL.
-- 1. Used preconditions:
-- Activate application
--
-- 2. Performed steps
-- Perform PTU with new permissions that require User consent
--
-- Expected result:
-- Policies Manager must notify HMI about 'user-consent-required' via SDL.OnAppPermissionChanged{appID, appPermissionsConsentNeeded: true} per application in FULL,
-- that lacks the User`s permissions right after Policies Manager detects the user-unconsented permissions in Local PT
---------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

function Test:Precondition_Activate_app()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:OnAppPermissionChanged_to_FULL_upon_PTU()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "filename"} )

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY" },
          "files/PTU_NewPermissionsForUserConsent.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              local systemRequestId = data.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
            end)

          EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.HMIAppID, appPermissionsConsentNeeded = true })
          :Do(function()
              local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
              EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
              :Do(function()
                  local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"allowedFunctions"}})
                  EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage)
                  :Do(function() print("SDL.GetUserFriendlyMessage is received") end)
                end)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
            end)
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
