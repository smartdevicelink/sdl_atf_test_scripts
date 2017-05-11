---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage
-- [AppIconsFolder]: Folder defined at "AppIconsFolder" param does NOT exist but has read-write permissions
-- Description:
-- SDL behavior when on startup AppIconsFolder doesn't exist
-- 1. Used preconditions:
-- Delete log files and polisy table from previous cycle if any
-- AppIconsFolder doesn't exist
-- 2. Performed steps:
-- Start SDL and HMI
-- Expected result:
-- SDL:
-- checks if AppIconsFolder exists;
-- creates AppIconsFolder
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
require('user_modules/AppTypes')

--[[ Local variables ]]
local testIconsFolder = commonPreconditions:GetPathToSDL() .. "Icons"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
assert(os.execute( "rm -rf " .. testIconsFolder))
commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'Icons')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_AppIconsFolder_is_created_on_startup()
  local dirExistResult = commonSteps:Directory_exist(testIconsFolder)
  if dirExistResult == true then
    commonFunctions:userPrint(32, "AppIconsFolder exists")
  else
    self:FailTestCase("Icons folder doesn't exist in SDL bin folder")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_stopSDL()
  StopSDL()
end

function Test.Postcondition_deleteCreatedIconsFolder()
  assert(os.execute( "rm -rf " .. testIconsFolder))
end

function Test.Postcondition_restoreDefaultValuesInIni()
  commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'storage')
end
