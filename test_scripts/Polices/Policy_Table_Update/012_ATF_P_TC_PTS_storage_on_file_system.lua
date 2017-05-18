---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered. Device consented by user
-- PTU is requested.
--
-- Expected result:
-- The policies manager must store the PT snapshot as a JSON file which filename and
-- filepath are defined in "PathToSnapshot" parameter of smartDeviceLink.ini file.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTS_Storage_On_File_System()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local PathToSnapshot = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress, isSDLAllowed = true}})
          local function check_snapshot()
            if ( commonSteps:file_exists( SystemFilesPath..'/' .. PathToSnapshot) == false ) then
              self:FailTestCase(SystemFilesPath..'/' .. PathToSnapshot.."sdl_snapshot.json doesn't exist!")
            end
          end

          RUN_AFTER(check_snapshot,1000)
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
  commonTestCases:DelayedExp(2000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
