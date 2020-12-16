---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "ignition_cycles_since_last_exchange" reset in LocalPT
--
-- Description:
-- Reseting value in 'ignition_cycles_since_last_exchange' section of LocalPT
-- 1. Used preconditions:
-- Delete log file and policy table if any
-- Start SDL and HMI
-- Perform ignition OFF
-- Perform ignition ON
-- Register app
-- Activate app-> PTU is triggered
--
-- 2. Performed steps
-- Check "ignition_cycles_since_last_exchange" value of LocalPT
--
-- Expected result:
-- On successful PolicyTable exchange, Policies Manager must reset to "0" the value in 'ignition_cycles_since_last_exchange"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local ignition_cycles_before_ptu

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Update_IgnCycles()
  self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
  local function check_update_ign_cycles()
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
      ignition_cycles_before_ptu = result
    end
    --print("1: ignition_cycles_before_ptu: "..tostring(ignition_cycles_before_ptu))
  end
  RUN_AFTER(check_update_ign_cycles, 1000)
  --commonTestCases:DelayedExp(2000)
end

function Test:Precondition_SDL_Ign_Off()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
end

function Test.Precondition_SDL_Ign_On()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI()
  self:initHMI()
end

function Test:Precondition_InitOnready()
  self:initHMI_onReady()
  commonTestCases:DelayedExp(10000)
end

function Test:Precondition_StartNewSession()
  self:connectMobile()
  self.mobileSession = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_Get_ignition_cycles_since_last_exchange()
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
    if( result ~= ignition_cycles_before_ptu) then
      self:FailTestCase("ignition_cycles_since_last_exchange is reset at IGN_OFF->IGN_ON. Expected: " .. tostring(ignition_cycles_before_ptu)..". Real: "..tostring(result))
    end
  end
  --print("2: ignition_cycles_before_ptu: "..tostring(ignition_cycles_before_ptu))
end

function Test:Precondition_Registering_app()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  :Do(
    function(_, d)
      self.applications[config.application1.registerAppInterfaceParams.appName] = d.params.application.appID
    end)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }):Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Ignition_cycles_since_last_exchange_not_reset_after_RAI()
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

    if( result ~= ignition_cycles_before_ptu) then
      self:FailTestCase("ignition_cycles_since_last_exchange is reset at RAI. Expected: " .. tostring(ignition_cycles_before_ptu)..". Real: "..tostring(result))
    end
  end
end

function Test:ActivateAppInFULLLevel()
  commonSteps:ActivateAppInSpecificLevel(self,self.applications[config.application1.registerAppInterfaceParams.appName],"FULL")
  EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "FULL" })
end

function Test:TestStep_flow_SUCCEESS_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

function Test:TestStep_Ignition_cycles_since_last_exchange_should_be_reset()
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
    if result == "0" then
      return true
    else
      self:FailTestCase("ignition_cycles_since_last_exchange in DB has wrong value: " .. tostring(result))
      return false
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
