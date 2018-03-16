---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] <device identifier> section creation. Connection of the new device with SDL-enabled applications
--
-- Description:
-- New device is connected over WiFi WITH SDL-enabled applications
-- 1. Used preconditions:
-- SDL and HMI are running
-- Connect device not from LPT
--
-- 2. Performed steps:
-- Register app
-- Check lpt for device identifier
--
-- Expected result:
-- SDL must add new <device identifier> section in "device_data" section
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local pts_json = '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json'

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    }
  )
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:Precondition_Register_app()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local RequestIDRai1 = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        {
          application =
          {
            deviceInfo =
            {
              name = utils.getDeviceName(),
              id = utils.getDeviceMAC(),
              transportType = "WIFI"
            }
          }
        })
      :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(RequestIDRai1, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:Precondition_TriggerGettingDeviceConsent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Check_device_identifier_added_to_lpt()
  if( commonSteps:file_exists(pts_json) == false) then
    self:FailTestCase(pts_json .. " doesn't exist")
  else
    local file = io.open(pts_json, "r")
    local json_data = file:read("*all") -- may be abbreviated to "*a";
    file:close()
    local json = require("modules/json")
    local data = json.decode(json_data)
    local deviceIdentificatorInPTS = next(data.policy_table.device_data, nil)

    if (deviceIdentificatorInPTS == utils.getDeviceMAC()) then
      commonFunctions:userPrint(33, "device_identifier ".. deviceIdentificatorInPTS.. " section is created")
    else
      self:FailTestCase("Test is FAILED. device_identifier section is not created.")
    end

  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
