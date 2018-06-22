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
-- Actual result:
-- 1) App is not registered, SDL returns DISALLOWED response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local mobile_session = require("mobile_session")

--[[ Local Functions ]]
local function firstApplicationRegistered(self)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
  {
    syncMsgVersion = {
      majorVersion = 3,
        minorVersion = 0
    },
  appName = "SyncProxyTester",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
    appID = "1"
  })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "SyncProxyTester"} })
    self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
    :Timeout(2000)
    self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

local function RAI_DuplicateWithApp1AppNameId(self)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
  {
    syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0 },
  appName = "SyncProxyTester",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
    appID = "1"
  })
    self.mobileSession:ExpectResponse(CorIdRegister, { success = false, resultCode = "DUPLICATE_NAME" })
    :Timeout(2000)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Mobile app1 is registered", firstApplicationRegistered)

runner.Title("Test")
runner.Step("Mobile app2 is registered with the same name and id as the first application", RAI_DuplicateWithApp1AppNameId)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
