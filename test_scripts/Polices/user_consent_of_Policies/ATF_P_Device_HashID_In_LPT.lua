---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must hash <device identifier>
--
-- Description:
-- Before storing the number in the policy table, Policy manager must hash the number using SHA-256. SDL must store the hashed device identifier
-- (BTMAC for Bluetoth connection or Serial number of USB connected device) in <device identifier> section of Local Policy Table
-- 1. Used preconditions:
-- a) Start SDL, HMI and register app via Wifi (MAC address - 127.0.0.1)
-- 2. Performed steps
-- a) Initiate PTU to verify device hash in policy shapshot
--
-- Expected result:
-- a) Hash of device is present in snapshot
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local MACHash = nil

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
  local macHashFromPTS = next(data.policy_table.device_data, nil)
  return macHashFromPTS
end

--[[ Preconditions ]]
function Test:Precondition_Get_List_Of_Connected_Devices()
  self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
  {
    deviceList = {
      {

        name = "127.0.0.1",
        transportType = "WIFI",
        isSDLAllowed = false
      }
    }
  }
  ):Do(function(_,data)
  MACHash = data.params.deviceList[1].id
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
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
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = MACHash, name = "127.0.0.1"}})
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data1)
  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  :Times(AtLeast(1))
  end)
  end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf (function(_,data)
  return GetDeviceMacHashFromSnapshot(data.params.file) == MACHash
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
