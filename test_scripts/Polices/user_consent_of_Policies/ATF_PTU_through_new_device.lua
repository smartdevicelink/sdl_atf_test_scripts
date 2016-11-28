---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies]: user data concent - PTU update through the app on the device that does not have records in "user_consent_records"-> "device"
--
-- Description:
--     PoliciesManager needs to perform the triggerred PTUpdate through the application which runs on the device that does not have records in "user_consent_records"-> "device" sub-section of Local PT
--     1. Used preconditions:
--        Delete log files and policy table
--        Connect device
--     2. Performed steps
--        Add app session
--
-- Expected result:
--      PoliciesManager must initiate getting User`s data consent (that is, User`s permission for using the mobile device`s connection for Policy Table exchange) ->
--      SDL->HMI: OnAppRegistered (appID)
--      PoliciesManager: device needs consent; app is not present in Local PT.
--      PoliciesManager: "<appID>": "pre_DataConsent" //that is, adds appID to the Local PT and assigns default policies to it
--      SDL->HMI: SDL.OnSDLConsentNeeded
--      HMI->SDL: SDL.GetUserFriendlyMessages ("DataConsent")
--      SDL->HMI: SDL.GetUserFriendlyMessages_response
--      HMI displays the device consent prompt. User makes choice.
--      HMI->SDL: OnAllowSDLFunctionality
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
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_ConnectDevice()
  self:connectMobile()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_Add_session()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep2_PTU_through_device_not_in_consent_records()
  local RequestIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName }})
  EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded", {})
  :Do(function()
  local RequestIdGetMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(RequestIdGetMessage)
  :Do(function()
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
  :Do(function(_,data)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
  {
    file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
  })
  :Do(function()
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  end)
  end)
  end)
  self.mobileSession:ExpectResponse(RequestIdRAI, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end