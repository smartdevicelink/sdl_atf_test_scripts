---------------------------------------------------------------------------------------------
-- Description:
-- In case the application successfully registers to SDL SDL must send OnPermissionsChange (<assigned policies>) to such application.
-- Preconditions:
-- 1. Delete policy.sqlite file, app_info.dat files
-- 2. Replace sdl_preloaded_pt.json file where specified "pre_DataConsent" section and group for it.
--
-- Requirement summary:
-- app -> SDL: RegisterAppInterface_request (appID=, appName=<appName>, params):
-- SDL -> app: RegisterAppInterface_response
-- SDL -> app: OnPermissionsChange (<current permissions>)
--
-- Actions:
-- appID->SDL: RegisterAppInterface(parameters)
--
-- Expected:
-- 1. SDL -> app: RegisterAppInterface_response
-- 2. SDL -> app: OnPermissionsChange (<permissions assigned in pre_DataConsent group>)
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
-- Function gets RPCs for BaseBeforeDataConsent
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

  -- for i = 1, #RPC_BaseBeforeDataConsent do
  -- print("allowed_rps = "..RPC_BaseBeforeDataConsent[i])
  -- end
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
function Test:Step1_Register_App_And_Check_Its_Permissions_In_OnPermissionsChange()
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
  :Do(function(_,data)
      self.applications["SPT"] = data.params.application.appID
    end)

  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      if(order_communication ~= 1) then
        commonFunctions:printError("RegisterAppInterface response is not received 1 or 2 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,_)
      if( order_communication ~= 2) then
        commonFunctions:printError("OnHMIStatus is not received 3 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnPermissionsChange")
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
      for i = 1, #_data2.payload.permissionItem do
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

function Test:Step2_Check_Disallowed_RPC()
  local cid = self.mobileSession:SendRPC("GetVehicleData",{})
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

function Test:Step3_Check_RPC_From_OnPermissionsChange_Allowance()
  local CorIdRAI = self.mobileSession:SendRPC("ListFiles", {})
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
