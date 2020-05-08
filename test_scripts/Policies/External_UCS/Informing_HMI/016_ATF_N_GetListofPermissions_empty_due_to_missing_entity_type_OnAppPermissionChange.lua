---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [HMI API] GetListOfPermissions request/response
-- [HMI API] ExternalConsentStatus struct & EntityStatus enum
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polcies
-- Check that SDL invalidates notification OnAppPermissionConsent due to missing mandatory parameter entityType
--
-- 1. Used preconditions
-- SDL is built with External_Proprietary flag
-- SDL and HMI are running
-- Application is registered and activated
-- PTU file is updated and application is assigned to functional groups: Base-4, user-consent groups: Location-1 and Notifications
-- PTU has passed successfully
-- HMI sends <externalConsentStatus> to SDl via OnAppPermissionConsent (mandatory parameter entityType is missed, rest of params present and within bounds, EntityStatus = 'ON')
-- SDL doesn't receive updated Permission items and consent status
--
-- 2. Performed steps
-- HMI sends to SDL GetListOfPermissions (appID)
--
-- Expected result:
-- SDL sends to HMI empty array
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
-- ToDo (vvvakulenko): remove after issue "ATF does not stop HB timers by closing session and connection" is resolved
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_PTU_and_OnAppPermissionConsent_entityType_missing()
  local ptu_file_path = "files/jsons/Policies/Related_HMI_API/"
  local ptu_file = "OnAppPermissionConsent_ptu.json"

  EXPECT_NOTIFICATION("OnPermissionsChange")
  :Do(function() print("SDL->mob: OnPermissionsChange time: " .. timestamp()) end)

  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  :Do(function(_,data)
      if (data.params.appPermissionsConsentNeeded== true) then
        local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions",
              -- allowed: If ommited - no information about User Consent is yet found for app.
              allowedFunctions = {
                { name = "Location", id = 156072572},
                { name = "Notifications", id = 1809526495}
              },
              externalConsentStatus = {}
            }
          })
        :Do(function()
            local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
              {language = "EN-US", messageCodes = {"AppPermissions"}})

            EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage,
              {result = {code = 0, messages = {{messageCode = "AppPermissions"}}, method = "SDL.GetUserFriendlyMessage"}})
            :Do(function(_,_)
                self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                  {
                    appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                    consentedFunctions = {
                      { allowed = true, id = 156072572, name = "Location-1"},
                      { allowed = true, id = 1809526495, name = "Notifications"}
                    },
                    externalConsentStatus = {
                      {entityID = 113, status = "ON"}
                    },
                    source = "GUI"
                  })
                print("SDL->HMI: SDL.OnAppPermissionConsent time: ".. timestamp())
                commonTestCases:DelayedExp(10000)
              end)
          end)
      else
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)

  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self, nil, nil, nil, ptu_file_path, nil, ptu_file)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_GetListofPermissions_entityType_missing()
  local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestIdListOfPermissions, {
      code = "0",
      allowedFunctions = {
        { name = "Location", id = 156072572},
        { name = "Notifications", id = 1809526495}
      },
      externalConsentStatus = {}
    })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
