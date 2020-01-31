---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
-- [HMI API] OnStatusUpdate
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- and device is not consented.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone over WiFi.
-- Register new application
-- 2. Performed steps
-- Trigger getting device consent
--
-- Expected result:
-- PTU is requested. PTS is created.
-- HMI->SDL: SDL.UpdateSDL
-- SDL->HMI: SDL.UpdateSDL(UPDATE_NEEDED)
-- SDL->HMI: BasicCommunication.PolicyUpdate
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING)
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_flow_SUCCEESS_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

function Test.Precondition_Remove_PTS()
  os.execute("rm /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json") ~= false) then
    os.execute("rm /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_OnStatusUpdate_UPDATE_NEEDED_new_PTU_request()
  local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
