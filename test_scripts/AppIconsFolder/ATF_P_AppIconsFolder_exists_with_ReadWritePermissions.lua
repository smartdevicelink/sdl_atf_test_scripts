---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage
-- [AppIconsFolder]: SDL must check whether folder defined at "AppIconsFolder" param exists and has read-write permissions
--
-- Description:
-- SDL checks and finds icon related to app if such icons exist
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Set SDL "IconsFolder" as AppiconsFolder in .ini file
-- Start SDL and HMI
-- 2. Performed steps:
-- Register app
-- Send SetAppIcon with appid as icon name
-- Expected result:
-- SDL correctly finds app related icons
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
local appWithPermissions = commonPreconditions:GetPathToSDL() .. "IconsFolder"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
assert(os.execute( "rm -rf " .. appWithPermissions))
commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'IconsFolder')

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

local function checkFunction()
  local status = true
  local dirExistResult = commonFunctions:Directory_exist(appWithPermissions)
  if dirExistResult == true then
    local applicationFileToCheck = appWithPermissions .. "/" .. RAIParameters.appID
    local applicationFileExistsResult = commonSteps:file_exists(applicationFileToCheck)
    if applicationFileExistsResult == false then
      commonFunctions:userPrint(31, RAIParameters.appID .. " icon is not written to folder")
      status = false
    end
  else
    commonFunctions:userPrint(31, "IconsFolder folder does not exist in SDL bin folder" )
    status = false
  end
  return status
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_SDL_finds_icons_saved_in_AppIconsFolder()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
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
  assert(os.execute( "rm -rf " .. appWithPermissions))
end

function Test.Postcondition_restoreDefaultValueInIni()
  commonFunctions:SetValuesInIniFile("AppIconsFolder%s-=%s-.-%s-\n", "AppIconsFolder", 'storage')
end
