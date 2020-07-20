---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Factory Reset
--
-- Description:
-- Policy manager behavior when SDL receives Factory Reset
-- 1. Used preconditions
-- Activate app
-- Perform factory_defaults
-- Register new app
-- 2. Performed steps
-- Check LPT
--
-- Expected result:
-- Policy Manager must clear all user consent records in "user_consent_records" section of the LocalPT, other content of the LocalPT must be unchanged
---------------------------------------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')
local sdl = require('SDL')
local utils = require ('user_modules/utils')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]

local function ReplacePreloadedFile()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  --os.execute('cp -f ' .. 'files/jsons/Policy/Related_HMI_API/OnAppPermissionConsent.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp files/jsons/Policies/Related_HMI_API/OnAppPermissionConsent.json ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'storage/policy.sqlite')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function FACTORY_DEFAULTS(self)--, appNumber)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "FACTORY_DEFAULTS"
    })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "FACTORY_DEFAULTS" })
  commonTestCases:DelayedExp(5000)
end

--[[ General preconditions before ATF start]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
ReplacePreloadedFile()

Test = require('user_modules/connecttest_resumption')
require('user_modules/AppTypes')
require('cardinalities')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_Register_App()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  :Do(function(_,data) self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID end)

  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_Activate_app_To_Trigger_PTU()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})

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
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test:Precondition_Execute_Factory_reset()
  FACTORY_DEFAULTS(self)
end

--TODO(istoimenova): Remove when "[ATF] ATF stops execution of scripts at IGNITION_OFF." is resolved.
function Test.CheckSDLStatus()
  local actStatus = sdl:CheckStatusSDL()
  print("SDL status: " .. tostring(actStatus))
  if actStatus == sdl.RUNNING then
    StopSDL()
  end
end

function Test.Precondition_StartSDL()
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

function Test:Precondition_Register_App_after_reset()
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

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data) self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"})
end

function Test:Precondition_Activate_app_To_Trigger_PTU_after_reset()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})

        end)
    end)

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Check_no_user_consent_records_in_PT()
  local is_test_fail = false

  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json") == false) then
    self:FailTestCase(config.pathToSDL .."sdl_preloaded_pt.json ".."is not created")
  else
    testCasesForPolicyTableSnapshot:extract_pts({self.applications[config.application1.registerAppInterfaceParams.appName]})
    local app_consent_location = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Location-1")
    local app_consent_notifications = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Notifications")

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
end

--[[ Postcondition ]]
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
