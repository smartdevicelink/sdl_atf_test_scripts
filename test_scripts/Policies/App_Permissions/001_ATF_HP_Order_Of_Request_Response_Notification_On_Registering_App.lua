---------------------------------------------------------------------------------------------
-- Description:
-- Application with appID intends to be registered on SDL, device with deviceID the application is running on is connected to HU.
-- 1. Used preconditions:
-- Restart SDL and clean all data to set SDL in first life cycle state.
-- 2. Performed steps
-- Register new application.
--
-- Requirement summary:
-- [RegisterAppInterface] Order of request/response/notifications on registering an application
-- [Mobile API] OnPermissionsChange notification
-- [Mobile API] RegisterAppInterface request/response
-- [HMI API] OnAppRegistered
-- The order of requests/responses/notifications during application registering must be the following:
-- 1. app->SDL: RegisterAppInterface (policy_appID, parameters)
-- 2. SDL->HMI: OnAppRegistered (hmi_appID, params)
-- 3. SDL->app: RegisterAppInterface_response (<applicable resultCode>, success:true)
-- 4. SDL->app: OnHMIStatus(hmiLevel,audioStreamingState, systemContext)
-- 5. SDL->app: OnPermissionsChange(params)
--
-- Expected result:
-- 1. On performing all checks for successful registering SDL notifies HMI about registering before sending a response to mobile application:
-- SDL->HMI: OnAppRegistered(hmi_appID)
-- 2. SDL->appID: (<applicable resultCode>, success:true): RegisterAppInterface()
-- 3. On registering the application, HMIStatus parameters are assinged to the application:
-- SDL->app: OnHMIStatus(hmiLevel,audioStreamingState, systemContext)
-- 4. SDL assigns the appropriate policies and notifies application:
-- SDL->app: OnPermissionsChange (params) - as specified in "pre_DataConsent" section.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_connect_device.lua")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Local variables ]]
local RPC_BaseBeforeDataConsent = {}

--[[ Local functions ]]
-- Function gets RPCs for Notification and Location-1
local function Get_RPCs()
  testCasesForPolicyTableSnapshot:extract_preloaded_pt()

  for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
    if ( string.sub(testCasesForPolicyTableSnapshot.preloaded_elements[i].name,1,string.len("functional_groupings.BaseBeforeDataConsent.rpcs.")) == "functional_groupings.BaseBeforeDataConsent.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.preloaded_elements[i].name, "functional_groupings%.BaseBeforeDataConsent%.rpcs%.(%S+)%.%S+%.%S+")

      if(#RPC_BaseBeforeDataConsent == 0) then
        RPC_BaseBeforeDataConsent[#RPC_BaseBeforeDataConsent + 1] = str
      end

      if(RPC_BaseBeforeDataConsent[#RPC_BaseBeforeDataConsent] ~= str) then
        RPC_BaseBeforeDataConsent[#RPC_BaseBeforeDataConsent + 1] = str
      end
    end
  end
end
Get_RPCs()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_connect_device')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require("mobile_session")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_device()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:Precondition_StartNewSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Register_App_And_Check_Order_Of_Request_Response_Notiofications()
  local is_test_fail = false
  local order_communication = 1

  config.application1.registerAppInterfaceParams.appName = "SPT"
  config.application1.registerAppInterfaceParams.isMediaApplication = true
  config.application1.registerAppInterfaceParams.fullAppID = "1234567"

  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    { application = {
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
    } } })
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      if(order_communication ~= 1) then
        commonFunctions:printError("RAI response is not received 1 or 2 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,_)
      if(order_communication ~= 2) then
        commonFunctions:printError("OnHMIStatus is not received 3 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnPermissionsChange", {})
  :Do(function(_,_data2)
      if(order_communication ~= 3) then
        commonFunctions:printError("OnPermissionsChange is not received 4 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      -- Will be used to check if all needed RPC for permissions are received
      local is_perm_item_receved = {}
      for i = 1, #RPC_BaseBeforeDataConsent do
        is_perm_item_receved[i] = false
      end

      -- will be used to check RPCs that needs permission
      local is_perm_item_needed = {}
      for i = 1, #_data2.payload.permissionItem[1].rpcName do
        is_perm_item_needed[i] = false
      end

      for i = 1, #_data2.payload.permissionItem do
        for j = 1, #RPC_BaseBeforeDataConsent do
          if(_data2.payload.permissionItem[i].rpcName == RPC_BaseBeforeDataConsent[j]) then
            is_perm_item_receved[j] = true
            is_perm_item_needed[i] = true
            break
          end
        end
      end

      -- check that all RPCs from notification are requesting permission
      for i = 1,#is_perm_item_needed do
        if (is_perm_item_needed[i] == false) then
          commonFunctions:printError("RPC: ".._data2.payload.permissionItem[i].rpcName.." should not be sent")
          is_test_fail = false
        end
      end

      -- check that all RPCs that request permission are received
      for i = 1,#is_perm_item_receved do
        if (is_perm_item_receved[i] == false) then
          commonFunctions:printError("RPC: "..RPC_BaseBeforeDataConsent[i].." is not sent")
          is_test_fail = false
        end
      end

      order_communication = order_communication + 1
      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
