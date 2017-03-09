--UNCLEAR: exchange_after_x_ignition_cycles - not found in DataDictionary!!!
---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [[PolicyTableUpdate] Request to update PT - after "N" ignition cycles
--
-- Description:
-- In case:
-- the amount of ignition cycles notified by HMI via BasicCommunication.OnIgnitionCycleOver gets equal 
-- to the value of "exchange_after_x_ignition_cycles" field ("module_config" section) of policies database,
-- SDL must:
-- trigger a PolicyTableUpdate sequence.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone.
-- Register new application.
-- Activate application.
-- User consent device 
-- Device an app with app_ID is running is consented
-- Application is running on SDL
-- The value in PT "module_config"->"'ignition_cycles_since_last_exchange'" 
-- is "1" less than "exchange_after_x_ignition_cycles"
-- 2. Performed steps
-- HMI->SDL:BasicCommunication.OnIgnitionCycleOver
--
-- Expected result:
-- PTU is requested. PTS is created.
-- Increment "module_meta" -> "ignition_cycles_since_last_exchange" value
-- Initiate PTU:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- PTS is created by SDL:
-- SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')


-- Activate application and provide consent to device.
function Test:ConsentDevice()
  testCasesForPolicyTable:trigger_getting_device_consent(self,config.application1.registerAppInterfaceParams.appName,config.deviceMAC ) 
end

-- Desired result 
function Test:ConsentDevice()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self) 
end                       


--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTU_Trigger_N_Ignition_Cyvles()
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  testCasesForPolicyTable.time_trigger = 0
  testCasesForPolicyTable.time_onstatusupdate = 0
  testCasesForPolicyTable.time_policyupdate = 0

 --UNCLEAR: exchange_after_x_ignition_cycles - not found in DataDictionary!!!
 -- [[1. Increment "module_meta" -> "ignition_cycles_since_last_exchange" value

  testCasesForPolicyTable.time_trigger = timestamp()

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  :Do(function(_,_) testCasesForPolicyTable.time_onstatusupdate = timestamp() end)

  testCasesForPolicyTableSnapshot:verify_PTS(true,
    {config.application1.registerAppInterfaceParams.appID },
    {config.deviceMAC},
    {hmi_app1_id})

  local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
  local seconds_between_retries = {}
  for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
    seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
  end
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
  {
    file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
    timeout = timeout_after_x_seconds,
    retry = seconds_between_retries
  })
  :Do(function(_,data)
    testCasesForPolicyTable.time_policyupdate = timestamp()
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end



  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")
  function Test:Postcondition_SDLForceStop()
    commonFunctions:SDLForceStop(self)
  end

  return Test