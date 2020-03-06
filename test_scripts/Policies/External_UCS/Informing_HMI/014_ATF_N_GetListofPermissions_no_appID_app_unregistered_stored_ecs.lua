---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [HMI API] GetListOfPermissions request/response
-- [HMI API] ExternalConsentStatus struct & EntityStatus enum
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polcies
-- Upon GetListOfPermissions_request, SDL must inform "externalConsentStatus" setting to HMI
--
-- 1. Used preconditions
-- SDL is built with External_Proprietary flag
-- SDL and HMI are running
-- Application is registered and activated
-- PTU file is updated and application is assigned to functional groups: Base-4, user-consent groups: Location-1 and Notifications
-- PTU has passed successfully
-- HMI sends <externalConsentStatus> to SDl via OnAppPermissionConsent ( all params present and within bounds)
-- SDL stores internally the received <externalConsentStatus>
-- Second application is registered and then unregistered
--
-- 2. Performed steps
-- HMI sends to SDL GetListOfPermissions (appID of the unregistered application)
--
-- Expected result:
-- SDL invalidates the appID and cuts it off, the GetListOfPermissions request is treated as if sent without appID
-- SDL sends to HMI <externalConsentStatus> received from HMI
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')
local utils = require ('user_modules/utils')
local hmi_appid

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_PTU_and_OnAppPermissionConsent_AllParams_First_Application()
  local ptu_file_path = "files/jsons/Policies/Related_HMI_API/"
  local ptu_file = "OnAppPermissionConsent_ptu.json"
  local time_onAppPermissionChanged = 0

  EXPECT_NOTIFICATION("OnPermissionsChange")
  :Times(AnyNumber())
  :ValidIf(function(exp)
      local time = timestamp()
      print("SDL->mob: OnPermissionsChange time: " .. time)
      if (exp.occurences == 2) then
        if (time < time_onAppPermissionChanged) then
          commonFunctions:printError("Second OnPermissionsChange is received before OnAppPermissionConsent")
          return false
        else
          return true
        end
      end
      return true
    end)

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
                      { allowed = true, id = 156072572, name = "Location"},
                      { allowed = true, id = 1809526495, name = "Notifications"}
                    },
                    externalConsentStatus = {
                      {entityType = 115, entityID = 14, status = "ON"}
                    },
                    source = "GUI"
                  })
                time_onAppPermissionChanged = timestamp()
                print("SDL->HMI: SDL.OnAppPermissionConsent time: ".. time_onAppPermissionChanged)
              end)
          end)
      else
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)

  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self, nil, nil, nil, ptu_file_path, nil, ptu_file)
end

function Test:Precondition_StartSecondSession()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Preconditon_RegisterSecondApplication()
  local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName }})
  :Do(function(_,data)
      self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
      hmi_appid = self.applications[config.application2.registerAppInterfaceParams.appName]
    end)

  self.mobileSession1:ExpectResponse(CorIdRegister, { success=true, resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:TestStep_Unregister_Second_Application()
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_GetListofPermissions_appID_Unregistred_App_Stored_ecs()
  local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_appid})
  EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{code = "0",
      allowedFunctions = {
        { name = "Location", id = 156072572, allowed = true},
        { name = "Notifications", id = 1809526495, allowed = true}
      },
      externalConsentStatus = {
        {entityType = 115, entityID = 14, status = "ON"}
      }
    })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
