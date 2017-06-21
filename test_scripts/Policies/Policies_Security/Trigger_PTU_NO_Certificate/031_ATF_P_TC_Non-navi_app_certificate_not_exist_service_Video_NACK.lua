---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU] [GENIVI] SDL must start PTU for any app except navi right after app successfully request to start first secure service
-- [Mobile Navi]: SDL must allow opening audio&video services only for navigation app
--
-- Description:
-- In case any app except navigation connects and sucessfully registers on SDL (opens RPC 7 service)
-- and sends first StartService (<any_serviceType>, encrypted=true) to SDL
-- and PolicyTable has NO "certificate" at "module_config" section of LocalPolicyTable
-- SDL must: start PolicyTableUpdate process on sending SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI to get "certificate"
-- (meaning: SDL will NOT respond to StartService_request from mobile app till PTU will be finished per comment)
--
-- 1. Used preconditions:
-- Default app exists in LP, no certificate in module_config
--
-- 2. Performed steps
-- 2.1. Register and activate application
-- 2.2. Start secure Video service
--
-- Expected result:
-- 1. Application is registered and activated successfully
-- 2. SDL doesn't trigger PTU
-- 3. SDL returns StartServiceNACK to Video
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')
local testCasesForPolicyCeritificates = require('user_modules/shared_testcases/testCasesForPolicyCeritificates')
local events = require('events')
local Event = events.Event

--[[ Local Variables ]]
local serviceType = 11

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("ForceProtectedService", "Non")
testCasesForPolicyCeritificates.update_preloaded_pt(config.application1.registerAppInterfaceParams.appID, false)

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

function Test:Precondition_RAI()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  :Do(function(_,data)
      self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
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
    if (e.occurences == 1) and (data.frameInfo == 3) and (data.encryption == false) then
      return true
    end
    return false, "StartServiceNACK, encryption: false is not received"
  end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Times(0)
  :Do(function(e, d) print("SDL.OnStatusUpdate", e.occurences, d.params.status) end)

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_Files()
  os.execute( "rm -f files/ptu_certificate_exist.json")
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
