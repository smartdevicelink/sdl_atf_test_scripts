---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1398
--
-- Precondition:
-- 1) SDL and HMI are running.
-- 2) Mobile App is registered to SDL with appName=1, appID=1

-- Description:
-- Steps to reproduce:
-- 1) Try to register new app with the same: appName=1 and appID=1
-- 2) Try to register new app with the same: appName=2 and appID=1
-- Expected:
-- 1) App is not registered, SDL returns DUPLICATE_NAME response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local mobile_session = require("mobile_session")

--[[ Local Functions ]]
local function firstApplicationRegistered(self)
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
  :Do(function()
    local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", {
      syncMsgVersion = {
        majorVersion = 6,
        minorVersion = 0
      },
      appName = "SyncProxyTester",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appID = "1"
    })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "SyncProxyTester" } })
      self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
      self.mobileSession1:ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  end)
end

local function RAI_DuplicateWithApp1AppNameId(self)
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
  :Do(function()
    local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", {
      syncMsgVersion = {
      majorVersion = 6,
      minorVersion = 0 },
      appName = "SyncProxyTester",
      isMediaApplication = false,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appID = "1"
    })
    self.mobileSession2:ExpectResponse(CorIdRegister, { success = false, resultCode = "DUPLICATE_NAME" })
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Mobile app1 is registered", firstApplicationRegistered)

runner.Title("Test")
runner.Step("Mobile app2 is registered with the same name and id as the first application",
  RAI_DuplicateWithApp1AppNameId)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
