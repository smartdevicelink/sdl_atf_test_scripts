---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_sync_out_of_memory" update
--
-- Description:
-- In case there is no free disk space for the new application registering even if the app’s disk quotes are not exceeded completely,
-- Policy Manager must increment "count_of_rejections_sync_out_of_memory" section value of Local Policy Table for the corresponding application.
-- 1. Used preconditions:
-- a) Set SDL in first life cycle state
-- b) Set AppDirectoryQuota in .ini file as avaliable disk space on mounted device
-- c) Register app which satisfies condition for AppDirectoryQuota, Perform PTU
-- 2. Performed steps
-- a) Register new app
-- b) Initiate PTU to get PTS
--
-- Expected result:
-- a) ASSUMPTION! As AppDirectoryQuota is equal all free disk space and one app already registered the second app should receive OUT_OF_MEMORY result code for RAI request
-- b) PoliciesManager increments value of "count-of_rejections_sync_out_of_memory" field at PolicyTable
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')

--[[ Local Variables ]]
local pathToSnapshot
-- Id of app which OUT_OF_MEMORY
local appID = "1234567_2"

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function BackupIniFile()
  os.execute('cp ' .. config.pathToSDL .. 'smartDeviceLink.ini' .. ' ' .. config.pathToSDL .. 'backup_smartDeviceLink.ini')
end

local function RestoreIniFile()
  os.execute('rm ' .. config.pathToSDL .. 'smartDeviceLink.ini')
  os.execute('cp ' .. config.pathToSDL .. 'backup_smartDeviceLink.ini' .. ' ' .. config.pathToSDL .. 'smartDeviceLink.ini')
end

local function getWords(str)
  local words = {}
  for word in string.gmatch(str, "%S+") do
    table.insert(words, word)
  end
  return words
end

local function GetAvaliableDiskSpase()
  local info = {}
  local lines = {}
  local file = io.popen("df " .. config.pathToSDL, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    local header = getWords(lines[1]);
    local object
    local values
    for i = 2, #lines do
      object = {}
      values = getWords(lines[i])
      for k = 1, #header do
        object[header[k]] = values[k]
      end
      table.insert(info, object)
    end
  end
  -- return avaliable disk space in bytes
  return info[1].Available * 1000
end

local function GetCountOfSyncOutOfMemoryFromPTS(pathToFile)
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local CountOfSyncOutOfMemory = data.policy_table.usage_and_error_counts.app_level[appID].count_of_rejections_sync_out_of_memory
  return CountOfSyncOutOfMemory
end

--[[ Precondition ]]
function Test:Precondition_StopSDL()
  StopSDL()
end

function Test:Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test:Precondition_Backup_Ini_File()
  BackupIniFile()
end

function Test:SetAppDirectoryQuotaInIniFile()
  commonFunctions:SetValuesInIniFile("AppDirectoryQuota = 104857600", "AppDirectoryQuota", math.floor(GetAvaliableDiskSpase()*0.75))
end

function Test:Precondition_StartSDL_FirstLifeCycle()
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

function Test:Precondition_Restore_Ini_File()
  RestoreIniFile()
end

function Test:Precondition_Register_First_App_SUCCESS()
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
          name = "127.0.0.1",
          id = config.deviceMAC,
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = data.params.application.appID})
      EXPECT_HMIRESPONSE(RequestIdActivateApp, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
      :Do(function(_,_)
          local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,_)
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data1)
                  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
                end)
            end)
        end)
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnapshot = data.params.file
      local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
      EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
          EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
          :Do(function()
              local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/ptu_general.json")
              local systemRequestId
              EXPECT_HMICALL("BasicCommunication.SystemRequest")
              :Do(function(_,data1)
                  systemRequestId = data1.id
                  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                    {
                      policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                    })
                  self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
                  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}):Timeout(500)
                  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                end)
            end)
        end)
    end)
end

function Test:Precondition_StartSession_2()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Precondition_Register_Second_App_OUT_OF_MEMORY()
  local CorIdRAI2 = self.mobileSession1:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "SPT2",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "1234567_2",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    })
  self.mobileSession1:ExpectResponse(CorIdRAI2, {success = false, resultCode = "OUT_OF_MEMORY"})
end

--[[ Test ]]
function Test:TestStep_Initiate_PTU_And_Check_Count_Of_Sync_Out_Of_Memory_In_PTS()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf(function(_,data)
      pathToSnapshot = data.params.file
      if GetCountOfSyncOutOfMemoryFromPTS(pathToSnapshot) == 1 then return true
      else
        print("Wrong count_of_rejections_sync_out_of_memory. Expected: " .. 1 .. ", Actual: " .. GetCountOfSyncOutOfMemoryFromPTS(pathToSnapshot))
        return false
      end
    end)
end

--[[ Postcondition ]]
function Test:Postcondition_StopSDL()
  StopSDL()
end
