---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [OnAppInterfaceUnregistered] "APP_UNAUTHORIZED" in case of failed nickname validation after updated policies
--
-- Description:
-- In case the application with "appName" is successfully registered to SDL
-- and the updated policies do not have this "appName" in this app's specific policies (= "nicknames" filed in "<appID>" section of "app_policies")
-- SDL must: send OnAppInterfaceUnregistered (APP_UNAUTHORIZED) to such application.
-- 1. Used preconditions:
-- a) First SDL life cycle with loaded permissions for specific appId and nickname
-- 2. Performed steps
-- a) Perform PTU where nickname is different for this app name
--
-- Expected result:
-- a) SDL->app: OnAppInterfaceUnregistered (APP_UNAUTHORIZED)
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
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function BackupPreloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function SetNickNameForSpecificApp()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.app_policies["1234567"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4"},
    nicknames = {"SPT"}
  }
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ Preconditions ]]
function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test.Precondition_Backup_sdl_preloaded_pt()
  BackupPreloaded()
end

function Test.Precondition_Set_NickName_Permissions_For_Specific_AppId()
  SetNickNameForSpecificApp()
end

function Test.Precondition_StartSDL_FirstLifeCycle()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI_FirstLifeCycle()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady_FirstLifeCycle()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test.Precondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

--[[ Test ]]
function Test:Precondition_RegisterApp()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "SPT",
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
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "SPT",
        policyAppID = "1234567",
        isMediaApplication = true,
        hmiDisplayLanguageDesired = "EN-US",
        deviceInfo =
        {
          name = utils.getDeviceName(),
          id = utils.getDeviceMAC(),
          transportType = utils.getDeviceTransportType(),
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      self.applications["SPT"] = data.params.application.appID
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:TestStep_Update_PT_With_Another_NickName_For_Current_App_And_Check_Unregistration_App()
        local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["SPT"]})
        EXPECT_HMIRESPONSE(RequestIdActivateApp, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
        :Do(function(_,_)
            local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
            EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
            :Do(function(_,_)
                self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
                EXPECT_HMICALL("BasicCommunication.ActivateApp")
                :Do(function(_,data1)
                    self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  end)
                EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
              end)
          end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,_)
      local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
          { policyType = "module_config", property = "endpoints" })
      EXPECT_HMIRESPONSE(requestId)
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
          EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
          :Do(function()
              local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTFromCloud_Nickname_validation.json")
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              EXPECT_HMICALL("BasicCommunication.SystemRequest")
              :Do(function(_,data)
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                    {
                      policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                    })
                  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}):Timeout(500)
                end)
            end)
        end)
    end)
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
