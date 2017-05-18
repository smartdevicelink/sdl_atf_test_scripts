---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pre_DataConsent" policies and " heart_beat_timeout_ms" value
--
-- Description:
-- In case the "pre_DataConsent" policies are assigned to the application, PoliciesManager must apply 'heart_beat_timeout_ms' parameter:
-- 1) in case 'heart_beat_timeout_ms' parameter is presented, SDL must change the applied value of HeartBeatTimeout to the one from Policies 'heart_beat_timeout_ms' parameter
-- 2) in case 'heart_beat_timeout_ms' parameter is not presented -> SDL must use the value of HeartBeatTimeout from .ini file
--
-- 1. Used preconditions:
-- a) Set SDL in first life cycle state
-- b) Set HeartBeatTimeout = 7000 in .ini file
-- c) Register app, activate, consent device and update policy where heart_beat_timeout_ms = 2000 for pre_DataConsent section
-- d) Send OnAllowSDLFunctionality allowed = false to assign pre_DataConsent permission to app
-- 2. Performed steps
-- a) Check heartBeat time sent from SDL
--
-- Expected result:
-- a) SDL send HB with time specified in pre_DataConsent section (2000 ms)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--Heartbeat is supported after protocolversion 3
--config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local HBTime_max
local HBTime_min

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_heart_beat_timeout_ms_app_1234567.json")
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", "7000")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')
local events = require('events')
local constants = require('protocol_handler/ford_protocol_constants')

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

function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_Register_Activate_Consent_App_And_Update_Policy_With_heart_beat_timeout_ms_Param()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Test ]]
function Test:TestStep_Get_HeartBeat_Time()
local function getHB()
  local time_prev = 0
  local time_now = 0

  self.mobileSession.sendHeartbeatToSDL = false
  self.mobileSession.answerHeartbeatFromSDL = false
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == 0 and
    (data.serviceType == 0) and
    (data.frameInfo == 0) --HeartBeat
  end

  self.mobileSession:ExpectEvent(event, "Heartbeat")
  :ValidIf(function()
      self.mobileSession:Send(
        { frameType = constants.FRAME_TYPE.CONTROL_FRAME,
          serviceType = constants.SERVICE_TYPE.CONTROL,
          frameInfo = constants.FRAME_INFO.HEARTBEAT_ACK
        })
      if time_now ~= 0 then
        time_prev = time_now
        time_now = timestamp()
        local diff = time_now - time_prev

        if(HBTime_max == nil) then
          HBTime_max = diff
          HBTime_min = diff
        else
          if HBTime_max < diff then HBTime_max = diff end
          if HBTime_min > diff then HBTime_min = diff end
        end
      else
        time_now = timestamp()
      end
      return true

      end):Times(AnyNumber())
    DelayedExp(60000)
  end
  getHB()

end

function Test:TestStep_Check_HB_Time()
  -- Send request to bind ValidIf for HB time validation
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
  :ValidIf(function()
      if ( (HBTime_min < 3850) or (HBTime_max > 4150) ) then
        print("Wrong HearBeat time! Expected: 4000ms, Actual: ["..HBTime_min.." ; "..HBTime_max.."]ms ")
        return false
      else
        print(" HearBeat is in range ["..HBTime_min.." ; "..HBTime_max.."]ms ")
        return true
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Restore_INI_file()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test