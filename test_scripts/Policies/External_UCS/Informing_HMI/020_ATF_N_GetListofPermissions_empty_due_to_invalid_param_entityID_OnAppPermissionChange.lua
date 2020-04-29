---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [HMI API] GetListOfPermissions request/response
-- [HMI API] ExternalConsentStatus struct & EntityStatus enum
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polcies
-- Check that SDL invalidates notification OnAppPermissionConsent due to invalid value type of parameter entityID
--
-- 1. Used preconditions
-- SDL is built with External_Proprietary flag
-- SDL and HMI are running
-- Application is registered and activated
-- PTU file is updated and application is assigned to functional groups: Base-4, user-consent groups:
-- Location-1 and Notifications
-- PTU has passed successfully
-- HMI sends <externalConsentStatus> to SDl via OnAppPermissionConsent (parameter entityID has invalid value type,
-- rest of params present and within bounds, EntityStatus = 'ON')
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

--[[Local Variables]]
local params_invalid_data =
{
  {param_value = "invalidValue", comment = "String"},
  {param_value = 1.32, comment = "Float"},
  {param_value = {}, comment = "Empty table" },
  {param_value = { entityType = 1, entityID = 1 }, comment = "Non-empty table"},
  {param_value = -1, comment = "OutOfLowerBound"},
  {param_value = 130, comment = "OutOfUpperBound" },
  {param_value = "", comment = "Empty" },
  {param_value = nil, comment = "Null" }
}
local ptu_file
local consentedgroups
local allowed_func

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

for i = 1, #params_invalid_data do
  if(i > 1) then
    commonFunctions:newTestCasesGroup("Preconditions")

    Test["Precondition_trigger_user_request_update_from_HMI_"..params_invalid_data[i].comment] = function(self)
      testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
    end
  end

  Test["Precondition_PTU_and_OnAppPermissionConsent_Invalid_"..params_invalid_data[i].comment] = function(self)
    local ptu_file_path = "files/jsons/Policies/Related_HMI_API/"
    if ( (i % 2) == 0 ) then

      ptu_file = "OnAppPermissionConsent_ptu1.json"
      consentedgroups = {{ allowed = true, id = 4734356, name = "DrivingCharacteristics-3"}}
      allowed_func = { { name = "DrivingCharacteristics", id = 4734356}}
    else
      ptu_file = "OnAppPermissionConsent_ptu.json"
      consentedgroups = {
        { allowed = true, id = 156072572, name = "Location-1"},
        { allowed = true, id = 1809526495, name = "Notifications"}
      }
      allowed_func = {
        { name = "Location", id = 156072572},
        { name = "Notifications", id = 1809526495}
      }
    end

    EXPECT_NOTIFICATION("OnPermissionsChange")
    :Do(function() print("SDL->mob: OnPermissionsChange time: " .. timestamp()) end)

    EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
    :Do(function(_,data)
        if (data.params.appPermissionsConsentNeeded== true) then
          local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
          EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions",
                -- allowed: If ommited - no information about User Consent is yet found for app.
                allowedFunctions = allowed_func,
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
                      consentedFunctions = consentedgroups,
                      externalConsentStatus = {
                        {entityType = 13, entityID = params_invalid_data[i].param_value, status = "ON"}
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

  function Test:TestStep_GetListofPermissions_entityID_invalid()
    local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
    if ( (i % 2) == 0 ) then
      allowed_func = { { name = "DrivingCharacteristics", id = 4734356}}
    else
      allowed_func = {
        { name = "Location", id = 156072572},
        { name = "Notifications", id = 1809526495}
      }
    end
    EXPECT_HMIRESPONSE(RequestIdListOfPermissions, {
        code = "0",
        allowedFunctions = allowed_func,
        externalConsentStatus = {}
      })
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
