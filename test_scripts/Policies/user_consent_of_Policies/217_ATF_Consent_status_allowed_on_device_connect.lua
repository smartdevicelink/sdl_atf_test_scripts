---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [DeviceConsent] DataConsent status for each device is written in LocalPT
--
-- Description:
-- Providing the device`s DataConsent status (allowed) to HMI upon device connection to SDL
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Overwrite preloaded to make device consented
-- 2. Performed steps:
-- Connect device
--
-- Expected result:
-- SDL/PoliciesManager must provide the device`s DataConsent status (allowed) to HMI upon device`s connection->
-- SDL must request DataConsent status of the corresponding device from the PoliciesManager
-------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")

--[[ Local functions ]]
local function UpdatePolicy()
  local pathToFile = config.pathToSDL .. '/sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.app_policies["device"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4"},
    preconsented_groups = {"Base-4"}
  }
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end
UpdatePolicy()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_device_connects_as_consented()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          isSDLAllowed = true,
          name = utils.getDeviceName(),
          transportType = "WIFI"
        }
      }
    }
    ):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(AtLeast(1))
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLStop()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
  StopSDL()
end

return Test
