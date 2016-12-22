-- Requirement summary:
-- [PTU] Trigger: ignition cycles
--
-- Description:
-- When the amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver gets equal to the value of 
-- "exchange_after_x_ignition_cycles" field ("module_config" section) of policies database, SDL must trigger a PTU sequence
-- 1. Used preconditions: 
-- SDL is built with "DEXTENDED_POLICY: ON" flag
-- the 1-st IGN cycle, PTU was succesfully applied. Policies DataBase contains "exchange_after_x_ignition_cycles" = 10
-- 2. Performed steps: Perform ignition_on/off 11 times
--
-- Expected result:
-- When amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver gets equal to the value of "exchange_after_x_ignition_cycles" 
-- field ("module_config" section) of policies database, SDL must trigger a PolicyTableUpdate sequence
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')
--local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local Functions ]]
local function genpattern2str(name, value_type)
  return "(%s*\"" .. name .. "\"%s*:%s*)".. value_type
end
 
local function modify_preloaded(pattern, value)
  local preloaded_file = io.open(config.pathToSDL .. 'sdl_preloaded_pt.json', "r")
  local content = preloaded_file:read("*a")
  preloaded_file:close()
  local res = string.gsub(content, pattern, "%1"..value, 1)
  preloaded_file = io.open(config.pathToSDL .. 'sdl_preloaded_pt.json', "w+")
  preloaded_file:write(res)
  preloaded_file:close()
  local check = string.find(res, value)
  if ( check ~= nil) then
    return true
  end
  return false
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
--TODO(VVVakulenko): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

commonPreconditions:BackupFile("sdl_preloaded_pt.json")

local function Preconditions_set_exchange_after_x_ignition_cycles_to_10()
  modify_preloaded(genpattern2str("exchange_after_x_ignition_cycles", "%d+"), "10")
end
Preconditions_set_exchange_after_x_ignition_cycles_to_10()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

local count_of_ign_cycles = {}
for i = 1, 10 do
Test["Preconditions_perform_" .. tostring(count_of_ign_cycles[i]) .. "_IGN_OFF_ON"] = function() end

    function Test:IGNITION_OFF()
      StopSDL()
      self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
      :Times(1)
    end

    function Test.Precondition_StartSDL()
      StartSDL(config.pathToSDL, config.ExitOnCrash)
    end

    function Test:Precondition_InitHMI()
      self:initHMI()
    end

    function Test:Precondition_InitHMI_onReady()
      self:initHMI_onReady()
    end

    function Test:Precondition_Register_app()
      self:connectMobile()
      self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
      self.mobileSession:StartService(7)
      :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
      self.HMIAppID = data.params.application.appID
      end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      end)
    end

    function Test:Precondition_Activate_app()
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.HMIAppID})
      EXPECT_HMIRESPONSE(RequestId,{})
      :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
        {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdGetMes)
        :Do(function()
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function()
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Times(AtLeast(1))
        end)
      end
      end)
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
    end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Check_PTU_triggered_on_IGNOFF()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
  EXPECT_HMICALL("SDL.PolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  :Timeout(500)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

function Test.Postcondition_RestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test