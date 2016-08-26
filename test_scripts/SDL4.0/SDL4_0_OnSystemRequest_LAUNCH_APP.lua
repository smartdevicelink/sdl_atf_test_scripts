--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnSystemRequest_launch_app.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_OpenConnection("connecttest_OnSystemRequest_launch_app.lua")

--------------------------------------------------------------------------------
-- creation dummy connection for new device
os.execute("ifconfig lo:1 1.0.0.1")

--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnSystemRequest_launch_app')
require('user_modules/AppTypes')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

--------------------------------------------------------------------------------
-- Set EnableProtocol4 to true
  local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

  local StringToReplace = "EnableProtocol4 = true\n"

  f = assert(io.open(SDLini, "r"))

  if f then
    fileContent = f:read("*all")

      local MatchResult = string.match(fileContent, "EnableProtocol4%s-=%s-[^%a]-%s-\n") or string.match(fileContent, "EnableProtocol4%s-=%s-true%s-\n") or string.match(fileContent, "EnableProtocol4%s-=%s-false%s-\n")

      if MatchResult ~= nil then
        fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
        f = assert(io.open(SDLini, "w"))
        f:write(fileContentUpdated)
      else 
        userPrint(31, "Finding of 'EnableProtocol4 = value' is failed. Expect string finding is true and replacing of value to " .. tostring(EnableProtocol4ValueUpdateTo))
      end
    f:close()
  end

local registeredApp = {}

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName )
  
  sessionName.correlationId = sessionName.correlationId + 1

  local msg = 
        {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 2,
          rpcFunctionId    = 32768,
          rpcCorrelationId = sessionName.correlationId,
          payload          = '{"hmiLevel" :"' .. tostring(level) .. '", "audioStreamingState" : "' .. tostring(audibleState) .. '", "systemContext" : "MAIN"}'
        }



  sessionName:Send(msg)

  if 
    sessionName == self.mobileSession then
      sessionDesc = "first session"
  elseif
    sessionName == self.mobileSession1 then
      sessionDesc = "second session"
  elseif
    sessionName == self.mobileSession2 then
      sessionDesc = "third session"
  elseif
    sessionName == self.mobileSession3 then
      sessionDesc = "fourth session"
  elseif
    sessionName == self.mobileSession4 then
      sessionDesc = "fifth session"
  elseif
    sessionName == self.mobileSession5 then
      sessionDesc = "sixth session"
  elseif
    sessionName == self.mobileSession6 then
      sessionDesc = "sixth session"
  end

  userPrint(33, "Sending OnHMIStatus from mobile app with level ".. tostring(level) .. " in " .. tostring(sessionDesc) )

end

local function RegisterWithQuerryApps(self, session, registeredParams, FileName, UpdateAppListParams, severalDevices)
  local CorIdRegister = session:SendRPC("RegisterAppInterface", registeredParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
        appName = registeredParams.appName
      }
    })
    :Do(function(_,data)
      local appId = data.params.application.appID
      self.applications[registeredParams.appName] = data.params.application.appID
        end)

    session:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})
        :Timeout(2000)
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", session)

          session:ExpectNotification("OnHMIStatus", 
                            { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            :Timeout(2000)


        end)


 --mobile side: OnSystemRequest notification 
  session:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
    :Do(function(_,data)
        local CorIdSystemRequest = session:SendRPC("SystemRequest",
          {
            requestType = "QUERY_APPS", 
            fileName = FileName
          },
          "files/jsons/QUERRY_jsons/" .. tostring(FileName))

          -- mobile side: SystemRequest response
          session:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
            :Timeout(2000) 
    end)

  --------------------------------------------
  for i=1,#UpdateAppListParams.applications do
    --TODO: remove after resolving APPLINK-16052
    if UpdateAppListParams.applications[i].deviceInfo then
      UpdateAppListParams.applications[i].deviceInfo = nil
    end
    --------------------------------------------
    --TODO: remove after resolving APPLINK-18305
    if UpdateAppListParams.applications[i].ttsName then
      UpdateAppListParams.applications[i].ttsName = nil
    end
  end
  --------------------------------------------

   --hmi side: BasicCommunication.UpdateAppList
      EXPECT_HMICALL("BasicCommunication.UpdateAppList", UpdateAppListParams)
        :ValidIf(function(_,data)
          if #data.params.applications == #UpdateAppListParams.applications then
            return true
            else 
              userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected "  .. tostring(#UpdateAppListParams.applications) )
              return false
            end
        end)
        :Do(function(_,data)

          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

          for i=1, #data.params.applications do

            if 
              severalDevices == true then
                local AppNameWithDeviceName = tostring(data.params.applications[i].appName) .. tostring(data.params.applications[i].deviceInfo.name)
                self.applications[AppNameWithDeviceName] = data.params.applications[i].appID
            else
               self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
            end
          end
        end)
end

--Precondition: Unregister registered app
local function UnregisterAppInterface_Success(self, sessionName, iappName) 

  --mobile side: UnregisterAppInterface request 
  local CorIdURAI = sessionName:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected  BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[iappName], unexpectedDisconnect = false})

  --mobile side: UnregisterAppInterface response 
  sessionName:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})

end


--Precondition: "Register app"
local function AppRegistration(self, sessionName , iappName , iappID, isMediaFlag)

    local audibleStateRegister

    local CorIdRegister = sessionName:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
      majorVersion = 4,
      minorVersion = 3
      },
      appName = iappName,
      isMediaApplication = isMediaFlag,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "DEFAULT" },
      appID = iappID
    })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
      appName = iappName
      }
    })
    :Do(function(_,data)
        self.applications[iappName] = data.params.application.appID
    end)

    sessionName:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
      :Do(function(_,data)

          table.insert (registeredApp, {session = sessionName, appName = iappName})

          if 
            isMediaFlag == true then
              audibleStateRegister = "AUDIBLE"
          else
            audibleStateRegister = "NOT_AUDIBLE"
          end
          --mobile side: Sending OnHMIStatus hmiLevel = "FULL"
          SendingOnHMIStatusFromMobile(self, "FULL", audibleStateRegister, sessionName)

          --mobile side: OnSystemRequest notification 
          sessionName:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
      end)
end

--Precondition: Openning sessions
function Test:OpenningSessions()
  self.mobileSession = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession1 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession2 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession3 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession4 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession5 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession6 = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession.sendHeartbeatToSDL = false
  self.mobileSession1.sendHeartbeatToSDL = false
  self.mobileSession2.sendHeartbeatToSDL = false
  self.mobileSession3.sendHeartbeatToSDL = false
  self.mobileSession4.sendHeartbeatToSDL = false
  self.mobileSession5.sendHeartbeatToSDL = false
  self.mobileSession6.sendHeartbeatToSDL = false

  self.mobileSession.answerHeartbeatFromSDL = true
  self.mobileSession1.answerHeartbeatFromSDL = true
  self.mobileSession2.answerHeartbeatFromSDL = true
  self.mobileSession3.answerHeartbeatFromSDL = true
  self.mobileSession4.answerHeartbeatFromSDL = true
  self.mobileSession5.answerHeartbeatFromSDL = true
  self.mobileSession6.answerHeartbeatFromSDL = true

  self.mobileSession:StartService(7)
end

--TODO: remove print after resolving issues
userPrint(33, "Commented known defects related to tested feature in script: APPLINK-16052, APPLINK-18305")
userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

--===================================================================================--
-- Check url value from ptu for absent app in JSON file
--===================================================================================--
--Precondition: Registration of application 
  function Test:RegistrationApp()
    userPrint(35, "================================== Precondition ==================================")

    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
        {
            syncMsgVersion =
            {
              majorVersion = 4,
              minorVersion = 2
            },
            appName = "Test Application",
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appHMIType = { "NAVIGATION" },
            appID = "8675308",
          })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
        appName = "Test Application"
      }
    })
    :Do(function(_,data)
      self.applications["Test Application"] = data.params.application.appID
        end)

    self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})
      :Do(function()
        SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)
        table.insert (registeredApp, {session = self.mobileSession, appName = "Test Application"})
      end)


    self.mobileSession:ExpectNotification("OnHMIStatus", 
                            { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
        :Timeout(2000)

    --mobile side: OnSystemRequest notification 
    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "QUERY_APPS"})
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {
              requestType = "QUERY_APPS", 
              fileName = "jsonfile1"
            },
            "files/jsons/QUERRY_jsons/correctJSONLaunchApp.json")

            --mobile side: SystemRequest response
            self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
            :Timeout(2000) 
        end)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appID = self.applications["Test Application"],
                      appName = "Test Application",
                      appType = { "NAVIGATION" },

                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      hmiDisplayLanguageDesired = "EN-US",
                      isMediaApplication = true
                   },
                   {
                      appID = self.applications["Rock music App"],
                      appName = "Rock music App",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Rock music App"
                        }
                      },]=]
                      vrSynonyms = {"Rock music App"}
                   },
                   {
                      appID = self.applications["Rock music App LowerBound"],
                      appName = "Rock music App LowerBound",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Rock music App LowerBound"
                        }
                      },]=]
                      vrSynonyms = {"Rock music App LowerBound"}
                   },
                   {
                      appID = self.applications["Rock music App UpperBound"],
                      appName = "Rock music App UpperBound",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Rock music App UpperBound"
                        }
                      },]=]
                      vrSynonyms = {"Rock music App UpperBound"}
                   },
                    {
                      appID = self.applications["Awesome Music App"],
                      appName = "Awesome Music App",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Awesome Music App"
                        }
                      },]=]
                      vrSynonyms = {"Awesome Music App"}
                   },
                   {
                      appID = self.applications["Awesome Music App LowerBound"],
                      appName = "Awesome Music App LowerBound",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Awesome Music App LowerBound"
                        }
                      },]=]
                      vrSynonyms = {"Awesome Music App LowerBound"}
                   },
                   {
                      appID = self.applications["Awesome Music App UpperBound"],
                      appName = "Awesome Music App UpperBound",
                    --[=[TODO: uncommented after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      },]=]
                      greyOut = false,
                    --[=[TODO: Update after resolving APPLINK-18305
                      ttsName = {
                        {
                          type = "TEXT",
                          text = "Awesome Music App UpperBound"
                        }
                      },]=]
                      vrSynonyms = {"Awesome Music App UpperBound"}
                   }
                }
                })
      :ValidIf(function(_,data)
        if #data.params.applications == 7 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 7")
            return false
          end
      end)
      :Do(function(_,data)

        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

        for i=1,#data.params.applications do
          self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
        end

        DelayedExp(1000)

      end)

    DelayedExp(1000)

  end

-- Precondition: Activate app
  function Test:ActivationApp()

    --hmi side: sending SDL.ActivateApp request
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

    --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)

    --mobile side: expect OnHMIStatus notification
    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 

  end

--===================================================================================--
-- Check url packageName value from  JSON file for android devices
--===================================================================================--

  function Test:URLPackageName()
    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)

  		--hmi side: sending SDL.ActivateApp
  		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.awesome.fake"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)

          self.mobileSession1:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession1, "Awesome Music App", "853426", false)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(32, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
                  return false
              else return true
              end
            end)
  
          -- mobile side: expect OnHMIStatus on mobile side
          self.mobileSession1:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          self.mobileSession:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

          --mobile side: expect OnSystemRequest on other sessions
          self.mobileSession:ExpectNotification("OnSystemRequest", {})
            :Times(0)

            DelayedExp(1000)

        end)

  end


--===================================================================================--
-- Check url urlScheme value from  JSON file for iOs devices
--===================================================================================--

  function Test:URLUrlScheme()
    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession1)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Rock music App"]})

      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP"})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "rockmusicapp://"})
        :Do(function(exp,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Rock music App",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = false,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = false,
                   }}
                },
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = false,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = false,
                   }}
                })
            :Times(2)
            :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
            end)

          self.mobileSession2:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession2, "Rock music App", "553426", true)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession2:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

           self.mobileSession1:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          --mobile side: expect OnSystemRequest on other sessions
          self.mobileSession1:ExpectNotification("OnSystemRequest", {})
            :Times(0)
          self.mobileSession:ExpectNotification("OnSystemRequest", {})
            :Times(0)

          DelayedExp(1000)

        end)

  end


--===================================================================================--
-- Check url default value from ptu in case bound packageName/urlScheme values
--===================================================================================--

  function Test:URLPackageNameLowerBound()
    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession2)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App LowerBound"]})

      --mobile side: expect OnSystemRequest on other sessions
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP"})
        :Times(0)

      self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP"})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "a"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession2)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = false,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = false,
                   }}
                },
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = false,
                   }}
                })
            :Times(2)
            :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
            end)

          self.mobileSession3:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession3, "Awesome Music App LowerBound", "853428", false)
            end)


          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession3:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", {})
            :Times(0)

          self.mobileSession1:ExpectNotification("OnHMIStatus", {})
            :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus",
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})


          DelayedExp(1000)

        end)

  end

 --------------------------------------------------------------------------------------------------

  function Test:URLPackageNameUpperBound()

    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession3)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App UpperBound"]})

      --mobile side: expect OnSystemRequest on other sessions
      self.mobileSession:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession1:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession2:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession3:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "qwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPASDF"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession3)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = false,
                   }}
                },
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Awesome Music App UpperBound"
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   }}
                })
            :Times(2)
            :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
            end)

          self.mobileSession4:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession4, "Awesome Music App UpperBound", "853429", false)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession4:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", {})
            :Times(0)

          self.mobileSession1:ExpectNotification("OnHMIStatus", {})
            :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus",{})
            :Times(0)

          self.mobileSession3:ExpectNotification("OnHMIStatus",
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          DelayedExp(1000)

        end)
  end

  ------------------------------------------------------------------------------------------------------

  function Test:URLUrlSchemeLowerBound()

    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession4)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Rock music App LowerBound"]})

      --mobile side: expect OnSystemRequest on other sessions
      self.mobileSession:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession1:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession2:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession3:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession4:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "i"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession4)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = true,
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = false
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   }}
                },
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = true,
                   },
                   {
                      appName = "Rock music App LowerBound",
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   }}
                })
            :Times(2)
            :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
            end)

          self.mobileSession5:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession5, "Rock music App LowerBound", "553428", true)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession5:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", {})
            :Times(0)

          self.mobileSession1:ExpectNotification("OnHMIStatus", {})
            :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus",
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          self.mobileSession3:ExpectNotification("OnHMIStatus",{})
            :Times(0)

          self.mobileSession4:ExpectNotification("OnHMIStatus",
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          DelayedExp(1000)

        end)
  end

  ------------------------------------------------------------------------------------------------------

  function Test:URLUrlSchemeUpperBound()

    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession5)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Rock music App UpperBound"]})

      --mobile side: expect OnSystemRequest on other sessions
      self.mobileSession:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession1:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession2:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession3:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      self.mobileSession4:ExpectNotification("OnSystemRequest", {})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession5:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "iosqwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiop[]{}asdfghjkl;':|zxcvbnm,./<>?1234567890~!@#$%^&*()_+QWERTYUIOPA"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession5)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = true,
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App UpperBound",
                      greyOut = false
                   }}
                },
                {
                  applications = {
                   {
                      appName = "Test Application",
                   },
                   {
                      appName = "Awesome Music App",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App",
                      greyOut = true
                   },
                   {
                      appName = "Awesome Music App LowerBound",
                      greyOut = true,
                   },
                   {
                      appName = "Awesome Music App UpperBound",
                      greyOut = true,
                   },
                   {
                      appName = "Rock music App LowerBound",
                      greyOut = true
                   },
                   {
                      appName = "Rock music App UpperBound",
                   }}
                })
            :Times(2)
            :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
            end)

          self.mobileSession6:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession6, "Rock music App UpperBound", "553429", true)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession6:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", {})
            :Times(0)

          self.mobileSession1:ExpectNotification("OnHMIStatus", {})
            :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus",{})

          self.mobileSession3:ExpectNotification("OnHMIStatus",{})
            :Times(0)

          self.mobileSession4:ExpectNotification("OnHMIStatus",{})
            :Times(0)

          self.mobileSession5:ExpectNotification("OnHMIStatus",
            {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          DelayedExp(1000)


        end)
  end

--===================================================================================--
-- Check sending SDL.ActivateApp to nonexistent app in JSON and notregistered 
--===================================================================================--
  function Test:ActivateAppNonExistentAppId()

    userPrint(34, "=================================== Test  Case ===================================")

    --hmi side: sending SDL.ActivateApp
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = 111111})

    EXPECT_HMIRESPONSE(RequestId)
      :ValidIf(function(_,data)
        if 
          data.result.code ~= 11 then
          userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected INVALID_DATA(11), actual " .. tostring(data.result.code))
            return false
        else return true
        end
      end)

    --Expect absence OnSystemRequest on all sessions
    EXPECT_ANY_SESSION_NOTIFICATION("OnSystemRequest")
      :Times(0)

    DelayedExp(2000)

  end

--===================================================================================--
-- Checks that SDL send OnSystemRequest(LAUNCH_APP) if all registered Apps are in BACKGROUND on the phone
--===================================================================================--

  function Test:Precondition_UnregisteredApp()
    userPrint(35, "================================== Precondition ==================================")
    for i = 1, #registeredApp do
      --mobile side: UnregisterAppInterface request 
      local CorIdURAI = registeredApp[i].session:SendRPC("UnregisterAppInterface", {})

      --mobile side: UnregisterAppInterface response 
      registeredApp[i].session:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
    end

     --hmi side: expected  BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
      :Times(#registeredApp)
  end


  function Test:Precondition_CloseOpennedConnectionSessions()
    self.mobileConnection:Close()
  end

  function Test:Precondition_OpenFirstConnectionCreateSession()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)

  end

  function Test:Precondition_RegisterApp_OnSystemRequestLaunchToBackgroundAppOnMobile()

  local registeredParams = 
  {
    syncMsgVersion =
    {
      majorVersion = 4,
      minorVersion = 2
    },
    appName = "Test Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "8675308",
  }

  local UpdateAppListParams = 
  {
    applications = {
   {
      appName = "Test Application",
      appType = { "NAVIGATION" },

      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      hmiDisplayLanguageDesired = "EN-US",
      isMediaApplication = true
   },
   {
      appName = "Rock music App",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App"
        }
      },
      vrSynonyms = {"Rock music App"}
   },
   {
      appName = "Rock music App LowerBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App LowerBound"
        }
      },
      vrSynonyms = {"Rock music App LowerBound"}
   },
   {
      appName = "Rock music App UpperBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App UpperBound"
        }
      },
      vrSynonyms = {"Rock music App UpperBound"}
   },
    {
      appName = "Awesome Music App",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App"
        }
      },
      vrSynonyms = {"Awesome Music App"}
   },
   {
      appName = "Awesome Music App LowerBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App LowerBound"
        }
      },
      vrSynonyms = {"Awesome Music App LowerBound"}
   },
   {
      appName = "Awesome Music App UpperBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App UpperBound"
        }
      },
      vrSynonyms = {"Awesome Music App UpperBound"}
   }
  }
  }

  RegisterWithQuerryApps(self, self.mobileSession, registeredParams, "correctJSONLaunchApp.json", UpdateAppListParams)

  end


  function Test:OnSystemRequestLaunchToBackgroundAppOnMobile()
    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)

    --hmi side: sending SDL.ActivateApp
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

    --mobile side: expect OnSystemRequest on mobile side
    self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.awesome.fake"})

    --hmi side: expect SDL.ActivateApp response
    --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 15})
    EXPECT_HMIRESPONSE(RequestId)
      :Timeout(11000)
      :ValidIf(function(_,data)
        if 
          data.result.code ~= 15 then
          userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected APPLICATION_NOT_REGISTERED(15), actual " .. tostring(data.result.code) )
            return false
        else return true
        end
      end)

    DelayedExp(1000)

  end

--===================================================================================--
-- Checks that SDL activate already registered App in common way
--===================================================================================--

  function Test:Precondition_UnregisterApp_OnSystemRequestLaunchToBackgroundAppOnMobile()
    userPrint(35, "================================== Precondition ==================================")
    UnregisterAppInterface_Success(self, self.mobileSession , "Test Application")
  end

  function Test:Precondition_RegisterApp_ActivationAlreadyRegisteredAppInCommonWay()

    local registeredParams = 
    {
      syncMsgVersion =
      {
        majorVersion = 4,
        minorVersion = 2
      },
      appName = "Test Application",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "NAVIGATION" },
      appID = "8675308",
    }

    local UpdateAppListParams = 
    {
      applications = {
     {
        appName = "Test Application",
        appType = { "NAVIGATION" },

        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        hmiDisplayLanguageDesired = "EN-US",
        isMediaApplication = true
     },
     {
        appName = "Rock music App",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Rock music App"
          }
        },
        vrSynonyms = {"Rock music App"}
     },
     {
        appName = "Rock music App LowerBound",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Rock music App LowerBound"
          }
        },
        vrSynonyms = {"Rock music App LowerBound"}
     },
     {
        appName = "Rock music App UpperBound",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Rock music App UpperBound"
          }
        },
        vrSynonyms = {"Rock music App UpperBound"}
     },
      {
        appName = "Awesome Music App",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Awesome Music App"
          }
        },
        vrSynonyms = {"Awesome Music App"}
     },
     {
        appName = "Awesome Music App LowerBound",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Awesome Music App LowerBound"
          }
        },
        vrSynonyms = {"Awesome Music App LowerBound"}
     },
     {
        appName = "Awesome Music App UpperBound",
        deviceInfo = {
          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
          isSDLAllowed = true,
          name = "127.0.0.1",
          transportType = "WIFI"
        },
        greyOut = false,
        ttsName = {
          {
            type = "TEXT",
            text = "Awesome Music App UpperBound"
          }
        },
        vrSynonyms = {"Awesome Music App UpperBound"}
     }
    }
    }

    RegisterWithQuerryApps(self, self.mobileSession, registeredParams, "correctJSONLaunchApp.json", UpdateAppListParams)

  end


  function Test:ActivationAlreadyRegisteredAppInCommonWay()

    userPrint(34, "=================================== Test  Case ===================================")

    self.mobileSession1= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession1:StartService(7)
      :Do(function()

        AppRegistration(self, self.mobileSession1, "Awesome Music App", "853426", false)

        EXPECT_HMICALL("BasicCommunication.UpdateAppList",{
          applications = {
           {
              appName = "Test Application",
              appType = { "NAVIGATION" },
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Awesome Music App",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
           },
           {
              appName = "Rock music App",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            --[=[TODO: Update after resolving APPLINK-18305
              ttsName = {
                {
                  type = "TEXT",
                  text = "Rock music App"
                }
              },]=]
              vrSynonyms = {"Rock music App"}
           },
           {
              appName = "Rock music App LowerBound",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            --[=[TODO: Update after resolving APPLINK-18305
              ttsName = {
                {
                  type = "TEXT",
                  text = "Rock music App LowerBound"
                }
              },]=]
              vrSynonyms = {"Rock music App LowerBound"}
           },
           {
              appName = "Rock music App UpperBound",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            --[=[TODO: Update after resolving APPLINK-18305
              ttsName = {
                {
                  type = "TEXT",
                  text = "Rock music App UpperBound"
                }
              },]=]
              vrSynonyms = {"Rock music App UpperBound"}
           },
           {
              appName = "Awesome Music App LowerBound",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            --[=[TODO: Update after resolving APPLINK-18305
              ttsName = {
                {
                  type = "TEXT",
                  text = "Awesome Music App LowerBound"
                }
              },]=]
              vrSynonyms = {"Awesome Music App LowerBound"}
           },
           {
              appName = "Awesome Music App UpperBound",
            --[=[TODO: update  after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            --[=[TODO: Update after resolving APPLINK-18305
              ttsName = {
                {
                  type = "TEXT",
                  text = "Awesome Music App UpperBound"
                }
              },]=]
              vrSynonyms = {"Awesome Music App UpperBound"}
           }
          }
        },
        {
          applications = {
           {
              appName = "Test Application",
           },
           {
              appName = "Awesome Music App",
              greyOut = true
           },
           {
              appName = "Rock music App",
              greyOut = false
           },
           {
              appName = "Rock music App LowerBound",
              greyOut = false
           },
           {
              appName = "Rock music App UpperBound",
              greyOut = false
           },
           {
              appName = "Awesome Music App LowerBound",
              greyOut = false
           },
           {
              appName = "Awesome Music App UpperBound",
              greyOut = false
            }
          }
        })
          :Do(function(exp,data)

            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

            if exp.occurences == 1 then

              SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1)

              SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession)

              local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

              --hmi side: expect SDL.ActivateApp response
              --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
              EXPECT_HMIRESPONSE(RequestId)
                :ValidIf(function(_,data)
                if 
                  data.result.code ~= 0 then
                    userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                    return false
                else return true
                end
              end)

            end

          end)
          :Times(2)
          :ValidIf(function(_,data)
              if 
                data.params.applications[1].appName == "Test Application" and
                data.params.applications[1].greyOut then
                  userPrint(31, "UpdateAppList contains greyOut parameter for registered 'Test Application' application")
                  return false
              else 
                return true
              end
          end)

          self.mobileSession:ExpectNotification("OnSystemRequest", {})
            :Times(0)

        self.mobileSession1:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

        DelayedExp(2000)

    end)

  end

--===================================================================================--
-- Checks that SDL sends OnSystemRequest(LAUNCH_APP) to foreground App on phone that use ONLY protocol version 4.
--===================================================================================--

  function Test:Precondition_UnregisterApp_ActivationAlreadyRegisteredAppInCommonWay()
    userPrint(35, "================================== Precondition ==================================")
    UnregisterAppInterface_Success(self, self.mobileSession , "Test Application")
  end

  --Precondition: Close openned connection
  function Test:Precondition_CloseOpennedConnection()
    self.mobileConnection:Close()
  end

  function Test:Precondition_OpenFirstConnectionCreateSession()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)

  end

  function Test:Precondition_RegisterApp_SendingOnSystemRequestLaunchForAppsOnlyWith4Protocol()

  local registeredParams = 
  {
    syncMsgVersion =
    {
      majorVersion = 4,
      minorVersion = 2
    },
    appName = "Test Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "8675308",
  }

  local UpdateAppListParams = 
  {
    applications = {
   {
      appName = "Test Application",
      appType = { "NAVIGATION" },

      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      hmiDisplayLanguageDesired = "EN-US",
      isMediaApplication = true
   },
   {
      appName = "Rock music App",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App"
        }
      },
      vrSynonyms = {"Rock music App"}
   },
   {
      appName = "Rock music App LowerBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App LowerBound"
        }
      },
      vrSynonyms = {"Rock music App LowerBound"}
   },
   {
      appName = "Rock music App UpperBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Rock music App UpperBound"
        }
      },
      vrSynonyms = {"Rock music App UpperBound"}
   },
    {
      appName = "Awesome Music App",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App"
        }
      },
      vrSynonyms = {"Awesome Music App"}
   },
   {
      appName = "Awesome Music App LowerBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App LowerBound"
        }
      },
      vrSynonyms = {"Awesome Music App LowerBound"}
   },
   {
      appName = "Awesome Music App UpperBound",
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
      greyOut = false,
      ttsName = {
        {
          type = "TEXT",
          text = "Awesome Music App UpperBound"
        }
      },
      vrSynonyms = {"Awesome Music App UpperBound"}
   }
  }
  }

  RegisterWithQuerryApps(self, self.mobileSession, registeredParams, "correctJSONLaunchApp.json", UpdateAppListParams)

  end


  function Test:Precondition_RegisterAppViaThirdProtocol()

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.awesome.fake"})
        :Do(function(exp,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)

          self.mobileSession1= mobile_session.MobileSession(
          self,
          self.mobileConnection)

          self.mobileSession1.version = 3

          self.mobileSession1:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession1, "Awesome Music App", "853426", true)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession1:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

          EXPECT_NOTIFICATION("OnHMIStatus", {})
          :Times(0)


          DelayedExp(1000)

        end)
  end

  function Test:SendingOnSystemRequestLaunchForAppsOnlyWith4Protocol()
    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession1)

    --hmi side: sending SDL.ActivateApp
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Rock music App"]})

    --mobile side: expect OnSystemRequest on mobile side
    self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "rockmusicapp:///"})


    self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "rockmusicapp://"})
      :Times(0)

    --hmi side: expect SDL.ActivateApp response
    --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 15})
    EXPECT_HMIRESPONSE(RequestId)
      :Timeout(11000)
      :ValidIf(function(_,data)
          if 
            data.result.code ~= 15 then
              userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected APPLICATION_NOT_REGISTERED(15), actual " .. tostring(data.result.code) )
              return false
          else return true
          end
        end)

    DelayedExp(2000)

  end

--===================================================================================--
-- Checks that SDL sends OnSystemRequest(LAUNCH_APP) to foreground App on phone from the same device
--===================================================================================--

  function Test:Precondtion_UnregisterAppsInFirstSession()
    userPrint(35, "================================== Precondition ==================================")
    UnregisterAppInterface_Success(self, self.mobileSession , "Test Application")
  end

  function Test:Precondition_UnregisterAppsInSecondSession()
    UnregisterAppInterface_Success(self, self.mobileSession1 , "Awesome Music App")
  end

  --Precondition: Close openned connection
  function Test:Precondition_CloseOpennedConnection()
    self.mobileConnection:Close()
  end

  --Precondition openning 2 conections
  function Test:Precondition_OpenFirstConnectionCreateSession()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)

    self.mobileSession.version = 4
    self.mobileSession3.version = 4

    self.mobileSession3= mobile_session.MobileSession(
    self,
    self.mobileConnection)
  end

  function Test:Precondition_OpenSecondConnectionCreateSession()
    local tcpConnection = tcp.Connection("1.0.0.1", config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection2 = mobile.MobileConnection(fileConnection)
    self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
    event_dispatcher:AddConnection(self.mobileConnection2)
    self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection2:Connect()

    self.mobileSession2.version = 4

    self.mobileSession2:StartService(7)
  end

  function Test:Precondition_RegisterApp_InFirstConnection()

    local registeredParams = 
    {
      syncMsgVersion =
      {
        majorVersion = 4,
        minorVersion = 2
      },
      appName = "SyncProxyTester",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "DEFAULT" },
      appID = "8675309"
    }

    local UpdateAppListParams = 
    {
      applications = {
       {
          appName = "SyncProxyTester",
          appType = { "DEFAULT" },
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          hmiDisplayLanguageDesired = "EN-US",
          isMediaApplication = true
       },
       {
          appName = "Pandora",
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          greyOut = false,
          ttsName = {
            {
              type = "TEXT",
              text = "Pandora"
            }
          },
          vrSynonyms = {"Pandora"}
       }
      }
    }

    RegisterWithQuerryApps(self, self.mobileSession, registeredParams, "JSONFirstDevice.json", UpdateAppListParams)

  end

  function Test:Precondtion_RegisterApp_InSecondConnection()

    local registeredParams = 
    {
      syncMsgVersion =
      {
        majorVersion = 4,
        minorVersion = 2
      },
      appName = "Test Application",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "DEFAULT" },
      appID = "8675308",
    }

    local UpdateAppListParams = 
    {
      applications = {
        {
          appName = "SyncProxyTester",
          appType = { "DEFAULT" },
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          hmiDisplayLanguageDesired = "EN-US",
          isMediaApplication = true
       },
       {
          appName = "Test Application",
          appType = { "DEFAULT" },
          deviceInfo = {
            id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
            isSDLAllowed = true,
            name = "1.0.0.1",
            transportType = "WIFI"
          },
          hmiDisplayLanguageDesired = "EN-US",
          isMediaApplication = true
       },
       {
          appName = "Pandora",
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          greyOut = false,
          ttsName = {
            {
              type = "TEXT",
              text = "Pandora"
            }
          },
          vrSynonyms = {"Pandora"}
       },
       {
          appName = "Pandora",
          deviceInfo = {
            id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
            isSDLAllowed = true,
            name = "1.0.0.1",
            transportType = "WIFI"
          },
          greyOut = false,
          ttsName = {
            {
              type = "TEXT",
              text = "Pandora"
            }
          },
          vrSynonyms = {"Pandora"}
       }
      }
    }

    RegisterWithQuerryApps(self, self.mobileSession2, registeredParams, "JSONSecondDevice.json", UpdateAppListParams, true)

    self.mobileSession:ExpectNotification("OnSystemRequest")
      :Times(0)

    DelayedExp(1000)

  end


  function Test:ReceivingOnSystemRequestLaunchOnAppropriateDevice()

    userPrint(34, "=================================== Test  Case ===================================")

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)

    local appName = "Pandora127.0.0.1"
      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[appName]})

      self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP"})
        :Times(0)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.Pandora.fake"})
        :Do(function(exp,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)

          self.mobileSession3:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, self.mobileSession3, "Pandora", "853426", true)
            end)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 0 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession3:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Times(2)

          EXPECT_NOTIFICATION("OnHMIStatus", {})
          :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus", {})
          :Times(0)

          DelayedExp(1000)

        end)

  end

--===================================================================================--
-- Checks that SDL activates app by OnsystemRequest(LAUNCH_APP) in case app registered from device which sends OnSystemRequest(QUERY_APPS) with registered app in json
--===================================================================================--

  function Test:Precondtion_UnregisterAppsOnBothDevices()
    userPrint(35, "================================== Precondition ==================================")
     --mobile side: UnregisterAppInterface request 
    local URAIcorId1 = self.mobileSession:SendRPC("UnregisterAppInterface", {})
    local URAIcorId2 = self.mobileSession2:SendRPC("UnregisterAppInterface", {})
    local URAIcorId3 = self.mobileSession3:SendRPC("UnregisterAppInterface", {})

    --hmi side: expected  BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
      :Times(3)

    --mobile side: UnregisterAppInterface response 
     self.mobileSession:ExpectResponse(URAIcorId1, {success = true , resultCode = "SUCCESS"})
     self.mobileSession2:ExpectResponse(URAIcorId2, {success = true , resultCode = "SUCCESS"})
     self.mobileSession3:ExpectResponse(URAIcorId3, {success = true , resultCode = "SUCCESS"})

     DelayedExp(1000)
  end

  function Test:Precondition_CloseBothOpennedConnection()
    self.mobileConnection:Close()
    self.mobileConnection2:Close()
  end


  --Precondition openning 2 conections
  function Test:Precondition_OpenFirstConnectionCreateSession_AbsenceActivation()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)
  end

  function Test:Precondition_OpenSecondConnectionCreateSession_AbsenceActivation()
    local tcpConnection = tcp.Connection("1.0.0.1", config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection2 = mobile.MobileConnection(fileConnection)
    self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
    event_dispatcher:AddConnection(self.mobileConnection2)
    self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection2:Connect()

    self.mobileSession2:StartService(7)
  end

  function Test:Precondition_RegisterApp_OnFirstDevice()

    local registeredParams = 
    {
      syncMsgVersion =
      {
        majorVersion = 4,
        minorVersion = 2
      },
      appName = "SyncProxyTester",
      isMediaApplication = true,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "DEFAULT" },
      appID = "8675309"
    }

    local UpdateAppListParams = 
    {
      applications = {
       {
          appName = "SyncProxyTester",
          appType = { "DEFAULT" },
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          hmiDisplayLanguageDesired = "EN-US",
          isMediaApplication = true
       },
       {
          appName = "Pandora",
          deviceInfo = {
            id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
            isSDLAllowed = true,
            name = "127.0.0.1",
            transportType = "WIFI"
          },
          greyOut = false,
          ttsName = {
            {
              type = "TEXT",
              text = "Pandora"
            }
          },
          vrSynonyms = {"Pandora"}
       }
      }
    }

    RegisterWithQuerryApps(self, self.mobileSession, registeredParams, "JSONFirstDevice.json", UpdateAppListParams)

  end

  function Test:AbsenceActivationAfterRegistrationAppFromSecondDeviceAfterReceivingOnSystemRequestLaunchOnFirstOne()

    userPrint(34, "=================================== Test  Case ===================================")

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Pandora"]})

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.Pandora.fake"})
        :Do(function(exp,data)

          AppRegistration(self, self.mobileSession2, "Pandora", "pandora", true)

          --hmi side: expect SDL.ActivateApp response
          --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 15})
          EXPECT_HMIRESPONSE(RequestId)
            :ValidIf(function(_,data)
              if 
                data.result.code ~= 15 then
                  userPrint(31, "SDL.ActivateApp response came with wrong result code. Expected APPLICATION_NOT_REGISTERED(15), actual " .. tostring(data.result.code) )
                  return false
              else return true
              end
            end)

          --hmi side: BasicCommunication.UpdateAppList
          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
            {
              appName = "SyncProxyTester",
              appType = { "DEFAULT" },
            --[=[TODO: uncommented after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
            },
            {
              appName = "Pandora",
            --[=[TODO: uncommented after resolving APPLINK-16052
              deviceInfo = {
                id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                isSDLAllowed = true,
                name = "1.0.0.1",
                transportType = "WIFI"
              }]=]
            },
            {
              appName = "Pandora",
            --[=[TODO: uncommented after resolving APPLINK-16052
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },]=]
              greyOut = false,
            }
          }})
          :ValidIf(function(_,data)
            if #data.params.applications == 3 then
              return true
            else 
              userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3")
              return false
            end
          end)
          :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          end)

          --mobile side: expect OnHMIStatus on mobile side
          self.mobileSession2:ExpectNotification("OnHMIStatus", 
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

          EXPECT_NOTIFICATION("OnHMIStatus", {})
          :Times(0)

          self.mobileSession2:ExpectNotification("OnHMIStatus", {})
          :Times(0)

          DelayedExp(1000)

        end)

  end

function Test:Postcondition_removeCreatedUserConnecttest()
  os.execute(" rm -f  ./user_modules/connecttest_OnSystemRequest_launch_app.lua")
end

function Test:Postcondition_DeleteDummyConnectionForSecondDevice()
  os.execute("ifconfig lo:1 down")
end

