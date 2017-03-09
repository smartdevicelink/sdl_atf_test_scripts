---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [HMI API] GetListOfPermissions request/response
-- [HMI API] ExternalConsentStatus struct & EntityStatus enum
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polcies
-- Check that SDL invalidates notification OnAppPermissionConsent due to invalid value type of parameter entityType
--
-- 1. Used preconditions
-- SDL is built with External_Proprietary flag
-- SDL and HMI are running
-- Application is registered and activated
-- PTU file is updated and application is assigned to functional groups: Base-4, user-consent groups: Location-1 and Notifications
-- PTU has passed successfully
-- HMI sends <externalConsentStatus> to SDl via OnAppPermissionConsent (parameter entityType has invalid value, rest of params present and within bounds, EntityStatus = 'ON')
-- SDL doesn't receive updated Permission items and consent status
--
-- 2. Performed steps
-- HMI sends to SDL GetListOfPermissions (appID)
--
-- Expected result:
-- SDL sends to HMI empty array
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
-- ToDo (vvvakulenko): remove after issue "ATF does not stop HB timers by closing session and connection" is resolved
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[Local Variables]]
local params_invalid_data =
{
  {param_value = "invalidValue", comment = "String"}
  {param_value = 1.32 comment = "Float"},
  {param_value = {}, comment = "Empty table" },
  {param_value = { entityType = 1, entityID = 1 }, comment = "Non-empty table"},
  {param_value = xxxx, comment = "OutOfLowerBound"},
  {param_value = xxxx, comment = "OutOfUpperBound" },
  {param_value = "", comment = "Empty" },
  {param_value = nil, desc = "Null" }
}

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
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

for i = 1, #params_invalid_data do
  Test["Precondition_PTU_and_OnAppPermissionConsent_Invalid_"..params_invalid_data[i]] = function(self)
    local ptu_file_path = "files/jsons/Policies/Related_HMI_API/"
    local ptu_file = "OnAppPermissionConsent_ptu.json"
    
    testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self, nil, nil, nil, ptu_file_path, nil, ptu_file)
    
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
                {entityType = params_invalid_data[i], entityID = 113, status = "ON"}
              },
              source = "GUI"
            })
            EXPECT_NOTIFICATION("OnPermissionsChange"):Times(0)
            commonTestCases:DelayedExp(10000)
          end)
        end)
      else
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_GetListofPermissions_entityType_invalid()
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
