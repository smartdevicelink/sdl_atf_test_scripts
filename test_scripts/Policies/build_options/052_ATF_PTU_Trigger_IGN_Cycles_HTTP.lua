-- Requirement summary:
-- [PTU] Trigger: ignition cycles
--
-- Description:
-- If the amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver
-- gets equal to the value of "exchange_after_x_ignition_cycles" field ("module_config" section)
-- of policies database, SDL must trigger a PolicyTableUpdate sequence

-- 1. Used preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- PTU was succesfully applied at first ignition cycle
-- Policies DataBase contains "exchange_after_x_ignition_cycles" = 10 in "module_config"
-- 2. Performed steps:
--Perform Ignition OFF followed by Ignition ON 11 times
--
-- Expected result:
-- Amount of ignition cycles received via BasicCommunication.OnIgnitionCycleOver
-- gets equal to the value of field "exchange_after_x_ignition_cycles" ("module_config" section)
----PTU sequence is triggered and SDL sends to HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
Test = require('connecttest')

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local variables]]
local ignition_cycles_before_ptu
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

local function check_Ignition_cycles_since_last_exchange(self, ignition_cycles)
  local query
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select ignition_cycles_since_last_exchange from module_meta\""
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select ignition_cycles_since_last_exchange from module_meta\""
  else commonFunctions:userPrint(31, "policy.sqlite is not found")
  end
  if query ~= nil then
    os.execute("sleep 3")
    local handler = io.popen(query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()

    if( result ~= ignition_cycles ) then
      self:FailTestCase("ignition_cycles_since_last_exchange is not as expected. Expected: " .. tostring(ignition_cycles)..". Real: "..tostring(result))
    else
      print("ignition_cycles_since_last_exchange = "..tostring(ignition_cycles))
    end
  end
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
--TODO(mmihaylova): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

commonPreconditions:BackupFile("sdl_preloaded_pt.json")

--Ign cycles are reduced to 2 in case to save time. Long term test should be additionally prepared
--Update should be done when "[GENIVI] SDL doesn't update exchange_after_x_ignition_cycles from preloaded_pt.json to PolicyDB" is fixed.
local function Preconditions_set_exchange_after_x_ignition_cycles_to_2()
  modify_preloaded(genpattern2str("exchange_after_x_ignition_cycles", "%d+"), "2")
  ignition_cycles_before_ptu = 1
end
Preconditions_set_exchange_after_x_ignition_cycles_to_2()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_CheckPreloaded_IGN_Cycles()
  check_Ignition_cycles_since_last_exchange(self, "0")
  commonTestCases:DelayedExp(500)
end

function Test:Precondition_PTU_SUCCESS()
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate"},
  "files/jsons/Policies/Policy_Table_Update/ign_cycle_ptu.json")
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UP_TO_DATE"})
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", {odometer=true})
  :Do( function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id,"VehicleInfo.GetVehicleData", "SUCCESS", {odometer=0})
    end)
end

--local count_of_ign_cycles = {}
for i = 1, (ignition_cycles_before_ptu) do
  Test["Preconditions_perform_" .. tostring(i) .. "_IGN_OFF_ON"] = function() end

  function Test:Precondition_IGNITION_OFF()

    self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
    commonTestCases:DelayedExp(500)
  end

  function Test.Precondition_StopSDL()
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered") :Times(1)
    StopSDL()
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

  function Test:Precondition_Check_IGN_Cycles_Incremented()
    check_Ignition_cycles_since_last_exchange(self, tostring(i))
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
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Ignition_cycles_since_last_exchange_not_reset_after_RAI()
  check_Ignition_cycles_since_last_exchange(self, tostring(ignition_cycles_before_ptu))
end

function Test:TestStep_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
  ignition_cycles_before_ptu = ignition_cycles_before_ptu + 1
  commonTestCases:DelayedExp(500)
end

function Test.TestStep_StopSDL()
  StopSDL()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered") :Times(1)
end

function Test.TestStep_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:TestStep_InitHMI()
  self:initHMI()
end

function Test:TestStep_InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:TestStep_Register_app()
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
  EXPECT_NOTIFICATION("OnSystemRequest")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(exp,data)
      if exp.occurences == 1 and data.params.status == "UPDATE_NEEDED" then
        return true
      elseif exp.occurences == 2 and data.params.status == "UPDATING" then
        return true
      end
      return false
      end):Times(2)
  end

  function Test:TestStep_Ignition_cycles_since_last_exchange()
    check_Ignition_cycles_since_last_exchange(self, tostring(ignition_cycles_before_ptu))
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
