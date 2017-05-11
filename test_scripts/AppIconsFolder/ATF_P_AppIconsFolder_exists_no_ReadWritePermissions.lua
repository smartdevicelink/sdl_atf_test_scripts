---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage
-- [AppIconsFolder]: Folder defined at "AppIconsFolder" param has NO read-write permissions
-- Description:
-- SDL behavior when on startup AppIconsFolder exists but has no permissions
-- 1. Used preconditions:
-- Stop SDL
-- Set AppIconsFolder in .ini file
-- Start SDL and HMI
-- Connect mobile
-- 2. Performed steps:
-- Register app
-- Send SetAppIcon
-- Expected result:
-- SDL must not use the 'store-app's-icon' mechanism
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

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
local folderNoPermissions = commonPreconditions:GetPathToSDL() .. "FolderWithoutPermissions"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
assert(os.execute( "rm -rf " .. folderNoPermissions))
commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'FolderWithoutPermissions')

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

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_setNoPermissionsForIconsFolder()
  local changePermissions = assert(os.execute( "chmod 000 " .. folderNoPermissions))
  if changePermissions ~= true then
    self:FailTestCase("Permissions for FolderWithoutPermissions are not changed")
  end
end

function Test:Precondition_registerAppAndSendSetAppIcon()
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
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_SDL_works_correctly_if_IconsFolder_has_no_permissions()
  local dirExistResult = commonFunctions:Directory_exist(folderNoPermissions)
  if dirExistResult == true then
    local applicationFileToCheck = folderNoPermissions .. "/" .. RAIParameters.appID
    local applicationFileExistsResult = commonSteps:file_exists(applicationFileToCheck)
    if applicationFileExistsResult ~= false then
      self:FailTestCase(RAIParameters.appID .. " icon is written to folder without permissions")
    end
  else
    self:FailTestCase("FolderWithoutPermissions folder does not exist in SDL bin folder")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_stopSDL()
  StopSDL()
end

function Test.Postcondition_deleteCreatedIconsFolder()
  assert(os.execute( "rm -rf " .. folderNoPermissions))
end

function Test.Postcondition_restoreDefaultValuesInIni()
  commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'storage')
end
