---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: Device unpairing and data consent
--
-- Description:
-- SDL must:
-- SDL gives permissions only from pre_DataConsent group to all apps that register from the device.
--
-- In case:
-- Policy Manager gets information about device being unpaired (SDL.OnDeviceStateChanged(UNPAIRED) obtained from HMI)
--
-- Preconditions:
-- 1. Application with <appID> is registered to SDL
-- No activation, no PTU --> device is non-consented
-- 2. Verifies that "Alert" RPC is not allowed for non-consented device
-- 3. Activate app --> device becames consented
-- 4. Verifies that "Alert" RPC is allowed for consented device
-- Steps:
-- 1. HMI -> SDL: Send SDL.OnDeviceStateChanged(UNPAIRED) notification
-- Device becames non-consented
-- 2. Verifies that PTU sequence is not triggered
-- 3. Verifies that "Alert" RPC is not allowed for non-consented device
--
-- Expected result:
-- 2. PTU sequence is not triggered
-- 3. SDL -> HMI: "Alert" RPC is not allowed
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTERNAL_PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Verify_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  EXPECT_HMICALL("UI.Alert", {alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}})
  :Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:ActivateApp()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Times(1)
  local reqId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(reqId1)
  :Do(function(_, d1)
      -- EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded", {})
      if d1.result.isSDLAllowed == false then
        local reqId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(reqId2)
        :Do(function(_, _)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, d2)
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(1)
          end)
      end
    end)
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"})
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

function Test:Verify_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  EXPECT_HMICALL("UI.Alert", {alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}})
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, "UI.Alert", "SUCCESS", {})
    end)
  self.mobileSession:ExpectResponse(corId, {success = true, resultCode = "SUCCESS"})
end

function Test:Send_UNPAIRED()
  self.hmiConnection:SendNotification("SDL.OnDeviceStateChanged", {deviceState = "UNPAIRED", deviceInternalId = config.deviceMAC})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Times(0)
end

function Test:Verify_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  EXPECT_HMICALL("UI.Alert", {alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}})
  :Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

return Test
