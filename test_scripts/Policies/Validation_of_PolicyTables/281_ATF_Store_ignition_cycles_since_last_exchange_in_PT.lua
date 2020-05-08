---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "ignition_cycles_since_last_exchange" storage into PolicyTable
--
-- Description:
-- Incrementing value in 'ignition_cycles_since_last_exchange' section of LocalPT
-- 1. Used preconditions:
-- Delete log file and policy table if any
-- Start SDL and HMI
-- Register app
--
-- 2. Performed steps
-- Check initial value of 'ignition_cycles_since_last_exchange' in PTs
-- Perform ignition OFF
-- Check 'ignition_cycles_since_last_exchange' value in policy table
--
-- Expected result:
-- On getting BasicCommunication.OnIgnitionCycleOver from HMI,
-- Pollicies Manager must increment the value in 'ignition_cycles_since_last_exchange' section of LocalPT
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local variables ]]
local ignition_cycles_before_ptu_prev
local ignition_cycles_before_ptu_current

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Local functions ]]
local function Check_ignition_cycles_since_last_exchange_is_PT(self, value)
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
    ignition_cycles_before_ptu_prev = tonumber(result)

    if (result == tostring(value) ) then
      return true
    else
      self:FailTestCase("ignition_cycles_since_last_exchange in DB has wrong value: " .. result)
      return false
    end
  end
end

--[[ Preconditions ]]
function Test.Precondition_Check_ignition_cycles_since_last_exchange()
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

    ignition_cycles_before_ptu_prev = tonumber(result)
  end
end

function Test:Precondition_Register_app()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID2 = data.params.application.appID
        end)
      self.mobileSession2:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

-- only PTU should reset ignition_cycles_since_last_exchange
function Test:TestStep1_Check_initial_ignition_cycles_since_last_exchange()
  ignition_cycles_before_ptu_current = ignition_cycles_before_ptu_prev
  Check_ignition_cycles_since_last_exchange_is_PT(self, ignition_cycles_before_ptu_current)
end

for _ = 1, 3 do
  function Test:TestStep6_Increment_ignition_cycles_since_last_exchange()
    self.hmiConnection:SendNotification("BasicCommunication.OnIgnitionCycleOver")
    ignition_cycles_before_ptu_current = ignition_cycles_before_ptu_current + 1
    commonTestCases:DelayedExp(1000)
  end
end

function Test:TestStep6_Check_ignition_cycles_since_last_exchange()
  Check_ignition_cycles_since_last_exchange_is_PT(self, ignition_cycles_before_ptu_current)
end

function Test:TestStep2_IgnitionOff()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  StopSDL()
end

function Test.TestStep3_SDL_Ign_On()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:TestStep4_InitHMI()
  self:initHMI()
end

function Test:TestStep5_InitOnready()
  self:initHMI_onReady()
  commonTestCases:DelayedExp(10000)
end

function Test:TestStep6_Check_ignition_cycles_since_last_exchange()
  Check_ignition_cycles_since_last_exchange_is_PT(self, ignition_cycles_before_ptu_current)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
