-- Requirement summary:
-- [PTU] Trigger: ignition cycles
--
-- Description:
-- When the amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver gets equal to the value of
-- "exchange_after_x_ignition_cycles" field ("module_config" section) of policies database, SDL must trigger a PTU sequence
-- 1. Used preconditions:
-- SDL is built with "DEXTENDED_POLICY: ON" flag
-- the 1-st IGN cycle, PTU was succesfully applied. Policies DataBase contains "exchange_after_x_ignition_cycles" = 5
-- 2. Performed steps: Perform ignition_off/on 5 times
--
-- Expected result:
-- When amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver gets equal to the value of "exchange_after_x_ignition_cycles"
-- field ("module_config" section) of policies database, SDL must trigger a PolicyTableUpdate sequence
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.fullAppID = "123456"
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
Preconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", "")

--[[ Local Variables ]]
local exchange_after = 5
local sdl_preloaded_pt = "sdl_preloaded_pt.json"
local ptu_file = "files/ptu.json"

--[[ Local Functions ]]
local function genpattern2str(name, value_type)
  return "(%s*\"" .. name .. "\"%s*:%s*)".. value_type
end

local function modify_file(file_name, pattern, value)
  local f = io.open(file_name, "r")
  local content = f:read("*a")
  f:close()
  local res = string.gsub(content, pattern, "%1"..value, 1)
  f = io.open(file_name, "w+")
  f:write(res)
  f:close()
  local check = string.find(res, value)
  if check ~= nil then
    return true
  end
  return false
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

config.defaultProtocolVersion = 2

-- Backup files
commonPreconditions:BackupFile(sdl_preloaded_pt)
os.execute("cp ".. ptu_file .. " " .. ptu_file .. ".BAK")

-- Update files
for _, v in pairs({config.pathToSDL .. sdl_preloaded_pt, ptu_file}) do
  modify_file(v, genpattern2str("exchange_after_x_ignition_cycles", "%d+"), tostring(exchange_after))
end

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:StartNewSession()
  self.mobileSession = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RegisterNewApp()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }):Times(2)
end

function Test:Precondition_SUCCEESS_Flow_PROPRIETARY()
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = policy_file_name})
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name}, ptu_file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for i = 1, exchange_after do
  Test["TestStep_perform_" .. tostring(i) .. "_IGN_OFF_ON"] = function() end

  function Test:TestStep_IGNITION_OFF()
    self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
  end

  for j = 1, 3 do
    Test["TestStep_Waiting ".. j .." sec"] = function() os.execute("sleep 1") end
  end

  function Test.TestStep_StopSDL()
    StopSDL()
  end
  function Test.TestStep_StartSDL()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
  function Test:TestStep_InitHMI()
    self:initHMI()
  end
  function Test:TestStep_InitHMI_onReady()
    self:initHMI_onReady()
    if i == exchange_after then
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    else
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate"):Times(0)
    end
    commonTestCases:DelayedExp(5000)
  end
  function Test:TestStep_StartMobileSession()
    self:connectMobile()
    self.mobileSession = mobileSession.MobileSession(self, self.mobileConnection)
    self.mobileSession:StartService(7)
  end

  function Test:TestStep_Register_App()
    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
    self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

function Test.Postcondition_RestoreFiles()
  commonPreconditions:RestoreFile(sdl_preloaded_pt)
  local ptu_file_bak = ptu_file..".BAK"
  os.execute("cp -f " .. ptu_file_bak .. " " .. ptu_file)
  os.execute("rm -f " .. ptu_file_bak)
end

function Test.RestoreIniFile()
  Preconditions:RestoreFile("smartDeviceLink.ini")
end

return Test
