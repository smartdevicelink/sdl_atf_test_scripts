---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies] Factory Reset
--
-- Description:
--    Policy manager behavior when SDL receives Factory Reset
-- 1. Used preconditions
--    Activate app
--    Perform factory_defaults
--    Register new app
-- 2. Performed steps
--    Check LPT
--
-- Expected result:
--    Policy Manager must clear all user consent records in "user_consent_records" section of the LocalPT, other content of the LocalPT must be unchanged
---------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local events = require('events')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
  RAISE_EVENT(event, event)
  end, time)
end

local function ReplacePreloadedFile()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  --os.execute('cp -f ' .. 'files/jsons/Policy/Related_HMI_API/OnAppPermissionConsent.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
os.execute('cp files/jsons/Policies/Related_HMI_API/OnAppPermissionConsent.json ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
   os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function FACTORY_DEFAULTS(self, appNumber)
  StopSDL()
  if appNumber == nil then
    appNumber = 1
  end
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
  {
    reason = "FACTORY_DEFAULTS"
  })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})
  :Times(1)
  DelayedExp(1000)
end

--[[ General preconditions before ATF start]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
ReplacePreloadedFile()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
  local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
  :Do(function(_,_)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
  {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1", isSDLAllowed = true}})

  local request_id_list_of_permissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(request_id_list_of_permissions)
  :Do(function(_,data)
  local groups = {}
  if #data.result.allowedFunctions > 0 then
    for i = 1, #data.result.allowedFunctions do
      groups[i] = data.result.allowedFunctions[i]
      groups[i].allowed = true
    end
  end
commonFunctions:printTable(groups)
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications[config.application1.registerAppInterfaceParams.appName], consentedFunctions = groups, source = "GUI"})
  EXPECT_NOTIFICATION("OnPermissionsChange")
  end)
  end)
  end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test:Precondition_Execute_Factory_reset()
  FACTORY_DEFAULTS(self)
end

function Test:Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_Register_To_Trigger_PTU()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "AnotherAppName",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "1234567",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    })
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})  
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Check_no_user_consent_records_in_PT()
  local is_test_fail = false
  testCasesForPolicyTableSnapshot:extract_pts({self.applications[config.application1.registerAppInterfaceParams.appName]})
  local app_consent_location = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID..".consent_groups.Location-1")
  local app_consent_notifications = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID..".consent_groups.Notifications")

  if(app_consent_location == true) then
    commonFunctions:printError("Error: user_consent_records.consent_groups.Location was not reset in LPT")
    is_test_fail = true
  end

  if(app_consent_notifications == true) then
    commonFunctions:printError("Error: user_consent_records.consent_groups.Notifications was not reset in LPT")
    is_test_fail = true
  end

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

--[[ Postcondition ]]
function Test:Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test:Postcondition_StopSDL()
  StopSDL()
end
