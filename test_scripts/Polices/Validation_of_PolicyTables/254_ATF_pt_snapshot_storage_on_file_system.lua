---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
--
-- Check creation of PT snapshot
-- 1. Used preconditions:
-- Do not start default SDL
-- 2. Performed steps:
-- Set correct PathToSnapshot path in INI file
-- Start SDL
-- Initiate PT snapshot creation
--
-- Expected result:
-- SDL must store the PT snapshot as a JSON file which filename and filepath are defined in "PathToSnapshot" parameter of smartDeviceLink.ini file.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Check_PathToSnapshot()
  local PathToSnapshot = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  if (PathToSnapshot ~= "sdl_snapshot.json") then
    self:FailTestCase("ERROR: PathToSnapshot is not sdl_snapshot.json. Real: "..PathToSnapshot)
  end
end

function Test:TestStep_Check_SystemFilesPath()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  if (SystemFilesPath ~= "/tmp/fs/mp/images/ivsu_cache") then
    self:FailTestCase("ERROR: PathToSnapshot is not /tmp/fs/mp/images/ivsu_cache. Real: "..SystemFilesPath)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test