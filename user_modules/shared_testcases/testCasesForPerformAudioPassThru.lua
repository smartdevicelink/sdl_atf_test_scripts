--This script contains common functions that are used in CRQs:
-- [GENIVI] PerformAudioPassThru: SDL must support new "audioPassThruIcon" parameter
--How to use:
--1. local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')

local commonSteps = require('user_modules/shared_testcases/commonSteps')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local config_path_sdl = commonPreconditions:GetPathToSDL()
local PathToAppFolder = config_path_sdl .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")

local testCasesForPerformAudioPassThru = {}

--[[@Check_audioPassThruIcon_Existence: check that file icon exists in storage folder
--! @parameters: icon
--! defines file that should exist in app storage folder.
--]]
function testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, icon)
  local result = commonSteps:file_exists(PathToAppFolder .. icon)
  
  if(result == true) then
    print("The audioPassThruIcon:"..icon.." exists at application's sandbox")
  else
  	print("The audioPassThruIcon:"..icon.." doesn't exist at application's sandbox")  	
    self:FailTestCase ("The audioPassThruIcon:"..icon.." doesn't exist at application's sandbox")
  end
end

--[[@Check_ActivateAppDiffPolicyFlag: check that application is allowed by policy and activate it 
--! @parameters: 
--! app_name: name of application
--! device_ID - MAC address of device, usually config.deviceMAC 
--]]
function testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, app_name, device_ID)

  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = self.applications[app_name]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if(data.result.isSDLAllowed == false) then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        --hmi side: expect SDL.GetUserFriendlyMessage message response
        EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = device_ID, name = ServerAddress, isSDLAllowed = true}})
          end)
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data1) self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)
      end

    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

return testCasesForPerformAudioPassThru