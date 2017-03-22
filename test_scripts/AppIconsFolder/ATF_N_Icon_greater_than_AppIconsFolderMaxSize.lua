---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage 
--    [AppIconsFolder]: App sends icon with size greater than defined at "AppIconsFolderMaxSize" param
-- Description:
--    Case when app sends icon with size greater than defined at "AppIconsFolderMaxSize" param in .ini file
-- 1. Used preconditions:
--      Stop SDL
--      Configure AppIconsFolder, AppIconsFolderMaxSize in ini file
--      Start SDL and HMI
--      Connect mobile
-- 2. Performed steps:
--      Register app 
--      Send SetAppicon with icon greater than AppIconsFolderMaxSize
-- Expected result:
--    SDL must continue normal operation without storing this icon 
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
require('user_modules/AppTypes')

--[[ Local variables ]]
local RAIParameters = config.application1.registerAppInterfaceParams

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
assert(os.execute( "rm -rf " .. commonPreconditions:GetPathToSDL() .. "Icons"))
commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'Icons')
commonFunctions:SetValuesInIniFile("AppIconsFolderMaxSize%s-=%s-.-%s-\n", "AppIconsFolderMaxSize", 1048576)

--[[ Local functions ]]
local function registerApplication(self)
  local corIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RAIParameters)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
  {
    application =
    {
     appName = RAIParameters.appName
    }
  })
  :Do(function(_,data)
    self.applications[RAIParameters.appName] = data.params.application.appID
  end)
  self.mobileSession:ExpectResponse(corIdRAI, { success = true, resultCode = "SUCCESS" })
end

-- Generate path to application folder
local function pathToAppFolderFunction(appID)
  return commonPreconditions:GetPathToSDL() .. "storage/" .. appID .. "_" .. config.deviceMAC .. "/"
end

local function checkFunction()
  local status = true
  local applicationFileToCheck = commonPreconditions:GetPathToSDL() .. "Icons/" .. RAIParameters.appID
  local applicationFileExistsResult = commonSteps:file_exists(applicationFileToCheck)
  local aHandle = assert( io.popen( "ls " .. commonPreconditions:GetPathToSDL() .. "Icons/" , 'r'))
  local listOfFilesInStorageFolder = aHandle:read( '*a' )
  commonFunctions:userPrint(33, "Content of storage folder: " .."\n" .. listOfFilesInStorageFolder)
  if applicationFileExistsResult ~= false then
    commonFunctions:userPrint(31, RAIParameters.appID .. " icon is added to AppIconsFolder although the size of file is larger than AppIconsFolderMaxSize")
    status = false
  end
  return status
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

 function Test:Precondition_ConnectMobile()
  self:connectMobile()
 end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_Icon_greater_than_AppIconsFolderMaxSize_is_not_stored()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession.version = 4
  self.mobileSession:StartService(7)
  :Do(function()
    registerApplication(self)
    EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
    :Do(function()
     local cidPutFile = self.mobileSession:SendRPC("PutFile",
      {
        syncFileName = "iconFirstApp.png",
        fileType = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false
      }, "files/png_1211kb.png")
     EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
     :Do(function()
     local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "iconFirstApp.png" })
     local pathToAppFolder = pathToAppFolderFunction(RAIParameters.appID)
     EXPECT_HMICALL("UI.SetAppIcon",
      {
        syncFileName =
          {
            imageType = "DYNAMIC",
            value = pathToAppFolder .. "iconFirstApp.png"
          }
       })
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
    :ValidIf(function()
      return checkFunction()
    end)
    end)
    end)
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

function Test.Postcondition_deleteCreatedIconsFolder()
  assert(os.execute( "rm -rf " .. commonPreconditions:GetPathToSDL() .. "Icons"))
end  

function Test.Postcondition_restoreDefaultValuesInIni()
  commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'storage')
  commonFunctions:SetValuesInIniFile("AppIconsFolderMaxSize%s-=%s-.-%s-\n", "AppIconsFolderMaxSize", 104857600)
end 
