------------------------------------------------------------------------------
-----------------General Settings for configuration---------------------------
------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

local mobile_session = require("mobile_session")

local SDL = require('SDL')

local SDL_Core = { }

local sdl_core_config = { }

-- sdl core binary
sdl_core_config.sdl_bin_path = ""
-- sdl sources to build
sdl_core_config.sdl_source_path =""
-- path to build folder
sdl_core_config.sdl_build_path = ""
-- api xml
sdl_core_config.api_file_path = ""
-- api xml copy
sdl_core_config.backup_ext = ".origin"

sdl_core_config.build_script_path = ""

-- first parameter path to sdl_core_config.sdl_source_path  
-- second parameter path to sdl_core_config.sdl_build_path
local build_script_string = [[
#!/bin/bash
# remove build folder
rm -r $2
# create build folder
mkdir -p $2
#go into build folder
cd $2
cmake $1
make install
# check if build successfull
echo ${PIPESTATUS[*]}
]]

---- local functions
local function copy_file(srcPath, dstPath)
  local srcfile = io.open(srcPath, "r")
  local dstfile = io.open(dstPath, "w+")
  
  local content = srcfile:read("*a")
  dstfile:write(content)
  
  srcfile:close()
  dstfile:close()
end

local function gen_build_script()
  local script = io.open(sdl_core_config.build_script_path, "w+") 
  script:write(build_script_string)
  script:close()

  -- give it execution rights
  local result = os.execute("chmod +rwxrwxrwx ".. sdl_core_config.build_script_path)
  --print(tonumber(result))
end

------------------------------------------------------------------------------
----------------------------Functions used------------------------------------
------------------------------------------------------------------------------
function SDL_Core.configure(pathToSDL)
  -- assume that sdl sources are on same root as build/bin folder
  -- e.g. /home/user/sdl_r3.0/ is a root and 
  --      /home/user/sdl_r3.0/build/bin/ is sdl binary path 
  --      /home/user/sdl_r3.0/sdl_core/ is source folder
  local sdl_root = string.gsub(pathToSDL, "/[^/]+/[^/]+/?$", "")
  print ("sdlroot:" .. sdl_root)
  sdl_core_config.sdl_build_path = string.gsub(config.pathToSDL, "/[^/]+/?$", "")
  sdl_core_config.sdl_source_path = sdl_root .. "/sdl_core"
  sdl_core_config.api_file_path = sdl_core_config.sdl_source_path .. "/src/components/interfaces/MOBILE_API.xml"
  --sdl_core_config.api_copy_path = sdl_core_config.api_file_path .. ".origin"
  sdl_core_config.build_script_path = sdl_root .."/build.sh" 

  print(sdl_core_config.sdl_source_path)
  print(sdl_core_config.sdl_build_path)
  print(sdl_core_config.api_file_path)
  --print(sdl_core_config.api_copy_path)
  print(sdl_core_config.build_script_path)
end

function SDL_Core.backupAPIFile()
  copy_file(sdl_core_config.api_file_path, sdl_core_config.api_file_path .. sdl_core_config.backup_ext)
end

function SDL_Core.restoreAPIFile()
  print ("restoring origin of MOBILE_API.xml")
  copy_file(sdl_core_config.api_file_path .. sdl_core_config.backup_ext, sdl_core_config.api_file_path)
end

function SDL_Core.modifyAPIFile(pattern, value)
  -- read current content
  local api_file = io.open(sdl_core_config.api_file_path, "r")
  -- read content 
  local content = api_file:read("*a")
  api_file:close()
  
  -- substitute pattern with value
  local res = string.gsub(content, pattern, value)

  -- now save data with correct version
  api_file = io.open(sdl_core_config.api_file_path, "w+")
  -- write result into dstfile 
  api_file:write(res)
  api_file:close()
  
  -- check if set successfuly
  -- lookup in result for our value. if found then substitution is ok
  local check = string.find(res, value)
  if ( check ~= nil) then 
    return true
  end
  return false
end

function SDL_Core.setAPIFileVersion(value)
  -- for version pattern can be hardcoded
  return SDL_Core.modifyAPIFile("version%s*=%s*\"%d+.%d+\"", value)
end

function SDL_Core.getAPIFileVersion()
  for line in io.lines(sdl_core_config.api_file_path) do 
    local major, minor = string.match(line, "^%s*<interface%s*name=\"SmartDeviceLink RAPI\"%s*version%s*=%s*\"(%d+).(%d+)\"")
      ---"^%s*version%s*=%s*\"4\.0\"")
    if (major ~= nil and minor ~=nil) then  
      return tonumber(major),  tonumber(minor)
    end
  end
  return nul,nul
end

function SDL_Core.buildSDL()
  gen_build_script()
    -- rebuilt
  print("Start build of SDL_Core. It may take a while. Please be patient! :)")
    
  --local res = os.execute(sdl_core_config.build_script_path .. " " .. sdl_core_config.sdl_source_path .. " " .. sdl_core_config.sdl_build_path)
  local con_out = io.popen(sdl_core_config.build_script_path .. " " .. sdl_core_config.sdl_source_path .. " " .. sdl_core_config.sdl_build_path, "r")
  local result = con_out:read("*a")
  con_out:close()

--  print("build result: " .. result)
  local n = tonumber(string.match(result, "(%d+)\n*$"))
  if (n == 0 ) then
    print("Build result: SUCCESS")
  else
    print("Build result: FAILED")
  end
  return tonumber(string.match(result, "(%d+)\n*$"))
end


local function ReStartSDL( prefix )

  Test["Precondition_StartSDL_" .. tostring(prefix)] = function(self)
   StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["Precondition_InitHMI_" .. tostring(prefix)] = function(self)
    self:initHMI()
  end

  Test["Precondition_InitHMI_onReady_" .. tostring(prefix)] = function(self)
    self:initHMI_onReady()
  end

  Test["Precondition_ConnectMobile_" .. tostring(prefix)] = function(self)
    self:connectMobile()
  end

end


local function CreateSessionRegisterApp(self, majorVersionValue, minorVersionValue )
  self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)

  self.mobileSession:StartService(7)
    :Do(function()
      local CorIdRAIVD = self.mobileSession:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 1,
                }, 
                appName ="SyncProxyTester",
                isMediaApplication = true,
                languageDesired = "EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appID ="123456",
              }) 

      --hmi side: expected  BasicCommunication.OnAppRegistered
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
                {
                    application = 
                    {
                      appName = "SyncProxyTester",
                      policyAppID = "123456",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true
                    }
                })


        :Do (function (_,data)
           self.applications["SyncProxyTester"] = data.params.application.appID
        end)
      --mobile side: RegisterAppInterface response 
      EXPECT_RESPONSE(CorIdRAIVD, { success = true, resultCode = "SUCCESS",
--TODO: update script to described in manual TC values after resolvind of APPLINK-24372
        syncMsgVersion = 
                { 
                  majorVersion = majorVersionValue,
                  minorVersion = minorVersionValue,
                },
        })
      end)
end

----------------------------------------------------------------------------
-----------------------------Preconditions----------------------------------
----------------------------------------------------------------------------
--Begin Precondition.1
--Description: Activation of application

function Test:ActivationApp()

    --hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

      --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)

                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

  end
--End Precondition.1
----------------------------------------------------------------------------
-------------------------------------Tests----------------------------------
----------------------------------------------------------------------------
--Test checks if there is a correct 'version' in MOBILE_API.xml (MAN APPLINK-19128)
-- function syncMsgVersionInMOBILE_API()
--   local major, minor = SDL_Core.getAPIFileVersion()

--   if (major == 4 and minor== 0 ) then
--     return true
--   else 
--     return false
--   end
-- end


-- if syncMsgVersionInMOBILE_API() then
--   print(" \27[36m 01_syncMsgVersion_in_MOBILE_API passed \27[0m ")

-- else
--   print(" \27[31m 01_syncMsgVersion_in_MOBILE_API failed \27[0m ")
-- end
----------------------------------------------------------------------------
-- Test_01 checks the correctness of version of "syncMsgVersion" param in 
-- RegisterAppInterface_response to mobile app (MAN APPLINK-19130)
function Test:RegisterAppInterface()
      local CorIdRAIVD = self.mobileSession:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 1,
                }, 
                appName ="SyncProxyTester",
                isMediaApplication = true,
                languageDesired = "EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appID ="123456",
              }) 

      --hmi side: expected  BasicCommunication.OnAppRegistered
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
                {
                    application = 
                    {
                      appName = "SyncProxyTester",
                      policyAppID = "123456",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true
                    }
                })


        :Do (function (_,data)
         self.applications["SyncProxyTester"] = data.params.application.appID
      end)
      --mobile side: RegisterAppInterface response 
      EXPECT_RESPONSE(CorIdRAIVD, { success = true, resultCode = "SUCCESS",
--TODO: update test to described in MAN test values after resolving APPLINK-24372
        syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 0,
                },
        })

    end
----------------------------------------------------------------------------
-- Test_02 checks the correctness of version of "syncMsgVersion" param in 
-- RegisterAppInterface_response to mobile app on reregister (MAN APPLINK-19131)

--Begin Precondition 1
--Description: Unregister Application befpre test
 function Test:UnregisterAppInterface()  
      local CorIdUnregisterAppInterfaceVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})

      --mobile side: UnregisterAppInterface response 
      EXPECT_RESPONSE(CorIdUnregisterAppInterfaceVD, { success = true, resultCode = "SUCCESS"})

  end
--End Precondition 1

--Begin Test

function Test:FirstRegistration()
      local CorIdRAIVD = self.mobileSession:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 0,
                }, 
                appName ="SyncProxyTester",
                isMediaApplication = true,
                languageDesired = "EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appID ="123456",
              }) 

      --hmi side: expected  BasicCommunication.OnAppRegistered
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
                {
                    application = 
                    {
                      appName = "SyncProxyTester",
                      policyAppID = "123456",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true
                    }
                })


        :Do (function (_,data)
         self.applications["SyncProxyTester"] = data.params.application.appID
      end)
      --mobile side: RegisterAppInterface response 
      EXPECT_RESPONSE(CorIdRAIVD, { success = true, resultCode = "SUCCESS",
-- TODO: edit test after resolving of APPLINK-24372 (update to value 3.1)       
        syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 0,
                },
        })

    end


  -- UnregisterAppInterface

  function Test:UnregisterAppInterface()  
      local CorIdUnregisterAppInterfaceVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})

      --mobile side: UnregisterAppInterface response 
      EXPECT_RESPONSE(CorIdUnregisterAppInterfaceVD, { success = true, resultCode = "SUCCESS"})

  end



    function Test:SecondRefistration()
      local CorIdRAIVD = self.mobileSession:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 0,
                }, 
                appName ="SyncProxyTester",
                isMediaApplication = true,
                languageDesired = "EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appID ="123456",
              }) 

      --hmi side: expected  BasicCommunication.OnAppRegistered
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
                {
                    application = 
                    {
                      appName = "SyncProxyTester",
                      policyAppID = "123456",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true
                    }
                })


        :Do (function (_,data)
         self.applications["SyncProxyTester"] = data.params.application.appID
      end)
      --mobile side: RegisterAppInterface response 
      EXPECT_RESPONSE(CorIdRAIVD, { success = true, resultCode = "SUCCESS",
      -- TODO: edit test after resolving of APPLINK-24372  (update to value 3.1)
        syncMsgVersion = 
                { 
                  majorVersion = 3,
                  minorVersion = 0,
                },
        })

    end
----------------------------------------------------------------------------
-- Test_03 check the correctness of version of "syncMsgVersion" param in MOBILE_API in 
-- case when changing (MAN APPLINK-19148)
-----------------------------------------------------------------------------
  function Test:PreTestSteps()
    print ("preTestSteps")
    -- call in sdl_core_test.lua function which configurates all necessary for the test pathes
    SDL_Core.configure(config.pathToSDL)
    -- make backup copy of MOBILE_API.xml
    SDL_Core.backupAPIFile()
    -- change version to value described in manual test 
    SDL_Core.setAPIFileVersion("version=\"4.2\"")
  end

    --UnregisterAppInterface(self)
  function Test:UnregisterAppInterface()  
        print ("Test:UnregisterAppInterface()")
        --self.mobileSession = mobile_session.MobileSession(
        --      self,
        --      self.mobileConnection)

        local CorIdUnregisterAppInterfaceVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})

        --mobile side: UnregisterAppInterface response 
        EXPECT_RESPONSE(CorIdUnregisterAppInterfaceVD, { success = true, resultCode = "SUCCESS"})

        StopSDL()
    
    -- local buildres = SDL_Core.buildSDL()
     SDL_Core.restoreAPIFile()

    -- print(buildres)
    -- if ( buildres ~= 0) then
    --   print("SDL_Core rebuild FAILED")
    -- end

       ReStartSDL( "Restart" )
   
  end

function Test:ActivationApp()

    --hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

      --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)

                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

  end


--End Precondition.1

  function Test:RegisterAppWithModifiedVersion()
    print("Test:RegisterAppWithModifiedVersion()")
    --TODO: update script to described in manual TC values after resolvind of APPLINK-24372 (update to value 4.2)
    CreateSessionRegisterApp(self, 3, 0)
  end
-----------------------------------------------------------------------------
-- Test checks case when "syncMsgVersion" is "0.0" in MOBILE_API (MAN APPLINK-19150)

 function Test:PreTestSteps()
    print ("preTestSteps")
    -- call in sdl_core_test.lua function which configurates all necessary for the test pathes
    SDL_Core.configure(config.pathToSDL)
    -- make backup copy of MOBILE_API.xml
    SDL_Core.backupAPIFile()
    -- change version to value described in manual test 
    SDL_Core.setAPIFileVersion("version=\"0.0\"")
  end

    --UnregisterAppInterface(self)
  function Test:UnregisterAppInterface()  
        print ("Test:UnregisterAppInterface()")
        --self.mobileSession = mobile_session.MobileSession(
        --      self,
        --      self.mobileConnection)

        local CorIdUnregisterAppInterfaceVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})

        --mobile side: UnregisterAppInterface response 
        EXPECT_RESPONSE(CorIdUnregisterAppInterfaceVD, { success = true, resultCode = "SUCCESS"})

        StopSDL()
    
    -- local buildres = SDL_Core.buildSDL()
     SDL_Core.restoreAPIFile()

    -- print(buildres)
    -- if ( buildres ~= 0) then
    --   print("SDL_Core rebuild FAILED")
    -- end

       ReStartSDL( "Restart" )
   
  end

function Test:ActivationApp()

    --hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

      --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)

                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

  end


--End Precondition.1

  function Test:RegisterAppWithWithZeroVersion()
    print("Test:RegisterAppWithZeroVersion()")
    --TODO: update script to described in manual TC values after resolvind of APPLINK-24372 (update to value 0.0)
    CreateSessionRegisterApp(self, 3, 0)
  end
-----------------------------------------------------------------------------
-- Test checks case when "syncMsgVersion" is empty in MOBILE_API (MAN APPLINK-19156)
function Test:CheckBuildWithEmptyVersion()
  -- 
  StopSDL()
  -- call in sdl_core_test.lua function which configurates all necessary for the test pathes
  SDL_Core.configure(config.pathToSDL)
  -- make backup copy of MOBILE_API.xml
  SDL_Core.backupAPIFile()
  -- change version to value described in manual test 
  SDL_Core.setAPIFileVersion("version=\"\"")

  local buildres = SDL_Core.buildSDL()
  SDL_Core.restoreAPIFile()
  print(buildres)
  if ( buildres ~= 0) then
    print("SDL_Core build FAILED")
  else 
    print("SDL_Core build SUCCESS") 
  end
end
-----------------------------------------------------------------------------
-- test checks case when "syncMsgVersion" in MOBILE_AP contains special symbols (MAN APPLINK-19149)
function Test:CheckBuildWithInvalidVersion()
  -- 
  StopSDL()
  -- call in sdl_core_test.lua function which configurates all necessary for the test pathes
  SDL_Core.configure(config.pathToSDL)
  -- make backup copy of MOBILE_API.xml
  SDL_Core.backupAPIFile()
  -- change version to value described in manual test 
  SDL_Core.setAPIFileVersion("version=\"4.*\"")

  local buildres = SDL_Core.buildSDL()
  SDL_Core.restoreAPIFile()
  print(buildres)
  if ( buildres ~= 0) then
    print("SDL_Core build FAILED")
  else 
    print("SDL_Core build SUCCESS") 
  end
end