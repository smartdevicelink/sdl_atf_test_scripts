---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU] [GENIVI] PolicyTableUpdate is failed by any reason and "ForceProtectedService"=OFF at .ini file
-- [PTU] [GENIVI] SDL must start PTU for navi app right after app successfully registration
--
-- Description:
-- In case SDL starts PolicyTableUpdate in case of no "certificate" at "module_config" section at LocalPT
-- and PolicyTableUpdate is failed by any reason even after retry strategy
-- and "ForceProtectedService" is OFF at .ini file
-- and app sends StartService (<any_serviceType>, encypted=true) to SDL
-- SDL must respond StartService (ACK, encrypted=false) to this mobile app
--
-- 1. Used preconditions:
-- ForceProtectedService is set to OFF in .ini file
-- Navi app exists in LP, no certificate in module_config
--
-- 2. Performed steps
-- 2.1 Register and activate navi application
-- 2.2 Wait PTU retry sequence to elapse
-- 2.3 Start secure Audio service
--
-- Expected result:
-- 1. SDL sends SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 2. SDL returns StartServiceACK, encrypt = false to Audio
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')
local testCasesForPolicyCeritificates = require('user_modules/shared_testcases/testCasesForPolicyCeritificates')
local events = require('events')
local Event = events.Event

--[[ Local Variables ]]
local serviceType = 10

local timeout_after_x_seconds = 5
local seconds_between_retries = {1, 1, 1, 1, 1}

local time_wait = {}
time_wait[0] = timeout_after_x_seconds -- 5
time_wait[1] = timeout_after_x_seconds + seconds_between_retries[1] -- 5 + 1 = 6
time_wait[2] = timeout_after_x_seconds + seconds_between_retries[2] + time_wait[1] -- 5 + 1 + 6 = 12
time_wait[3] = timeout_after_x_seconds + seconds_between_retries[3] + time_wait[2] -- 5 + 1 + 12 = 18
time_wait[4] = timeout_after_x_seconds + seconds_between_retries[4] + time_wait[3] -- 5 + 1 + 18 = 24
time_wait[5] = timeout_after_x_seconds + seconds_between_retries[5] + time_wait[4] -- 5 + 1 + 24 = 30

local total_time_wait = (time_wait[0] + time_wait[1] + time_wait[2] + time_wait[3] + time_wait[4] + time_wait[5]) * 1000 + 10000

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("ForceProtectedService", "Non")
testCasesForPolicyCeritificates.update_preloaded_pt(config.application1.registerAppInterfaceParams.appID, false, seconds_between_retries, timeout_after_x_seconds)

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_RAI_PTU_Trigger_PTU_SUCCESS()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate"):Times(3)
  :Do(function(e, d) print("SDL.OnStatusUpdate", e.occurences, d.params.status) end)

  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  :Do(function(_, data)
      self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(function(_, d2)
          self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
          testCasesForPolicyCeritificates.create_ptu_certificate_exist(false, false) -- include_certificate, invalid_ptu
          testCasesForPolicyCeritificates.ptu(self)
        end)
    end)

  EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application1.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL"})
end

function Test:Precondition_CheckStatus_UP_TO_DATE()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = "UP_TO_DATE" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:StartSecureService()
  print("Wait: " .. total_time_wait .. "ms")

  self.mobileSession.correlationId = self.mobileSession.correlationId + 1
  local msg = {
    serviceType = serviceType,
    frameInfo = 1,
    frameType = 0,
    rpcCorrelationId = self.mobileSession.correlationId,
    encryption = true
  }

  self.mobileSession:Send(msg)

  local startserviceEvent = Event()
  startserviceEvent.matches = function(_, data) return (data.frameType == 0 and data.serviceType == serviceType) end

  self.mobileSession:ExpectEvent(startserviceEvent, "Service ".. serviceType)
  :Times(AtLeast(1))
  :Do(function(e, data)
      print("Service: " .. serviceType .. "         ", e.occurences,
        "serviceType: " .. testCasesForPolicyCeritificates.getServiceType(data.serviceType) .. ", " ..
        "frameInfo: " .. testCasesForPolicyCeritificates.getFrameInfo(data.frameInfo) .. ", " ..
        "encryption: " .. tostring(data.encryption))
    end)
  :ValidIf(function(e, data)
    if ((e.occurences == 1) and (data.frameInfo == 2) and (data.encryption == false))
    or ((e.occurences == 2) and (data.frameInfo == 4) and (data.encryption == false)) then
      return true
    end
    return false, "StartServiceACK, encryption: false is not received"
  end)
  :Timeout(total_time_wait)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 0
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 1
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 2
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 3
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 4
    {status="UPDATE_NEEDED"}, {status = "UPDATING"}, -- 5
    {status="UPDATE_NEEDED"})
  :Times(13)
  :Do(function(e, d) print("SDL.OnStatusUpdate", e.occurences, d.params.status) end)
  :Timeout(total_time_wait)

  commonTestCases:DelayedExp(total_time_wait)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_Files()
  os.execute("rm -f files/ptu_certificate_exist.json")
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
