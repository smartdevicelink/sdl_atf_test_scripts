---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies]: user data concent - PTU update through the device which is NOT Consented
--
-- Description:
--     PoliciesManager needs to perform the triggerred PTUpdate through the application which runs on the device that is recorded as NOT-consented
--     1. Used preconditions:
--			Delete log files and policy table
--			Close current connection
-- 			Connect unconsented device
--     2. Performed steps
--		    Register application
--
-- Expected result:
--     PoliciesManager must send OnSDLConsentNeeded to initiate getting User`s data consent on HMI ->
--     (that is, User`s permission for using the mobile device`s connection for Policy Table exchange):
--			SDL->HMI: OnAppRegistered (appID)
--			PoliciesManager: device needs consent; app is not present in Local PT.
--			PoliciesManager: "<appID>": "pre_DataConsent" //that is, adds appID to the Local PT and assigns default policies to it
--			SDL->HMI: SDL.OnSDLConsentNeeded
--			HMI->SDL: SDL.GetUserFriendlyMessages ("DataConsent")
--			SDL->HMI: SDL.GetUserFriendlyMessages_response
--			HMI displays the device consent prompt. User makes choice.
--			HMI->SDL: OnAllowSDLFunctionality
-------------------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_CloseDefaultConnection()
  self.mobileConnection:Close()
  commonTestCases:DelayedExp(3000)
end

function Test:Precondition_ConnectUnconsentedDevice()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
  {
    deviceList = {
      {
        id = config.deviceMAC,
        isSDLAllowed = false,
        name = "127.0.0.1",
        transportType = "WIFI"
      }
    }
  }
  ):Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(AtLeast(1))
end

function Test:Precondition_RegisterApp_on_unconsented_device()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
  self.HMIAppID = data.params.application.appID
  end)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:ActivateApp_on_unconsented_device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = { code = 0, device = { id = config.deviceMAC, name = "127.0.0.1" }, isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false,
  method ="SDL.ActivateApp", priority ="NONE"}})
  :Do(function(_,data)
  --Consent for device is needed
  if data.result.isSDLAllowed ~= false then
    commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device needs to be consented on HMI")
  else
    EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded", {})
    :Do(function()
    local RequestIdGetMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
    EXPECT_HMIRESPONSE(RequestIdGetMessage)
    :Do(function()
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
    :Do(function()
    EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
    {
      file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
    })
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function()
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    end)
    :Times(AtLeast(1))
    end)
    end)
  end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end