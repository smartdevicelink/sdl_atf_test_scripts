--------------------------------------------------------------------------------------------------
-- Requirement summary:
--    [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage 
--    [AppIconsFolder]: SDL must compare the value from "AppIconsFolderMaxSize" param with the referenced value
--    [AppIconsFolder]: Value of "AppIconsFolderMaxSize" param greater than default
-- Description:
--    Case when value defined at "AppIconsFolderMaxSize" param in .ini file is greater than 1048576 bytes  
-- 1. Used preconditions:
--      Stop SDL
--      Configure "AppIconsFolderMaxSize" param in .ini file to be greater than 1048576 bytes  
--      Start SDL and HMI
--      Connect mobile
--      Make AppIconsFolder full
-- 2. Performed steps:
--      Register app 
--      Send SetAppicon
-- Expected result:
--    SDL should use value defined at "AppIconsFolderMaxSize" as the "AppIconsFolder" folder size so oldest icon should be deleted
---------------------------------------------------------------------------------------------------
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
local testIconsFolder = commonPreconditions:GetPathToSDL() .. "Icons"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
assert(os.execute( "rm -rf " .. testIconsFolder))
commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'Icons')
commonFunctions:SetValuesInIniFile("AppIconsFolderMaxSize%s-=%s-.-%s-\n", "AppIconsFolderMaxSize", 1374936)

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

local function pathToAppFolderFunction(appID)
  return commonPreconditions:GetPathToSDL() .. "storage/" .. appID .. "_" .. config.deviceMAC .. "/"
end

 local function folderSize(PathToFolder) 
  local aHandle = assert(io.popen( "du -s -B1 " .. PathToFolder, 'r'))
  local buff = aHandle:read( '*l' ) 
  return buff:match("^%d+")
end

local function makeAppIconsFolderFull(AppIconsFolder)
  local folderSizeInBytes = 1374936
  local oneIconSizeInBytes = 326360
  local sizeAppIconsFolderInBytes = folderSize(commonPreconditions:GetPathToSDL() .. AppIconsFolder)
  local sizeToFull = folderSizeInBytes - sizeAppIconsFolderInBytes
  local i = 1
  while sizeToFull > oneIconSizeInBytes do
    os.execute("sleep 1")
    local copyFileToAppIconsFolder = assert( os.execute( "cp files/icon.png " .. commonPreconditions:GetPathToSDL() .. AppIconsFolder .. "/icon" .. i ..".png"))
    i = i + 1
    if copyFileToAppIconsFolder ~= true then
      commonFunctions:userPrint(31, " Files are not copied to " .. AppIconsFolder)
    end
    sizeAppIconsFolderInBytes = folderSize(commonPreconditions:GetPathToSDL() .. AppIconsFolder)
    sizeToFull = folderSizeInBytes - sizeAppIconsFolderInBytes
    if i > 10 then
      commonFunctions:userPrint(31, " Loop is breaking due to a lot of iterations ")
      break
    end
  end
end

local function checkFunction()
  local status = true
  local aHandle = assert( io.popen( "ls " .. testIconsFolder .. "/" , 'r'))
  local ListOfFilesInStorageFolder = aHandle:read( '*a' )
  commonFunctions:userPrint(32, "Content of storage folder: " .."\n" ..ListOfFilesInStorageFolder)
  local iconsFolder = testIconsFolder .. "/"
  local applicationFileToCheck = iconsFolder .. RAIParameters.appID
  local applicationFileExistsResult = commonSteps:file_exists(applicationFileToCheck)
  if applicationFileExistsResult ~= true then
    commonFunctions:userPrint(31, RAIParameters.appID .. " icon is absent")
    status = false
  end
  local oldFileExistResult = commonSteps:file_exists(iconsFolder.. "icon1.png")
  if oldFileExistResult ~= false then
    commonFunctions:userPrint(31,"Oldest icon1.png is not deleted from AppIconsFolder. More space is occupied than AppIconsFolderMaxSize")
    status = false
  end
  return status
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test.Precondition_makeAppIconsFolderFull()
  makeAppIconsFolderFull( "Icons" )
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_SDL_uses_AppIconsFolderMaxSize_and_deletes_oldest_icon()
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
      }, "files/icon.png")
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
function Test.Postcondition_stopSDL()
  StopSDL()
end

function Test.Postcondition_deleteCreatedIconsFolder()
  assert(os.execute( "rm -rf " .. testIconsFolder))
end  

function Test.Postcondition_restoreDefaultValuesInIni()
  commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'storage')
  commonFunctions:SetValuesInIniFile("AppIconsFolderMaxSize%s-=%s-.-%s-\n", "AppIconsFolderMaxSize", 1048576)
end  
