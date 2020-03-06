---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must hash <device identifier>
--
-- Description:
-- Before storing the number in the policy table, Policy manager must hash the number using SHA-256. SDL must store the hashed device identifier
-- (BTMAC for Bluetoth connection or Serial number of USB connected device) in <device identifier> section of Local Policy Table
-- 1. Used preconditions:
-- a) Start SDL, HMI and register app via Wifi
-- 2. Performed steps
-- a) Initiate PTU to verify device hash in policy shapshot
--
-- Expected result:
-- a) Hash of device is present in snapshot
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Functions ]]
local function GetDeviceMacHashFromSnapshot(pathToFile)
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local macHashFromPTS = {}
  for device in pairs(data.policy_table.device_data) do
    table.insert(macHashFromPTS, device)
  end
  return macHashFromPTS
end

--[[ Preconditions ]]
function Test:Precondition_Get_List_Of_Connected_Devices()
  self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Initiate_PTU_And_Check_DeviceHashId_In_PTS()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
  local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
  :Do(function(_,_)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data1)
  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  :Times(AtLeast(1))
  end)
  end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf (function(_,data)
    for _, device in pairs(GetDeviceMacHashFromSnapshot(data.params.file)) do
      if device == utils.getDeviceMAC() then return true end
    end
    return false, "Expected device was not found in PTS"
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
