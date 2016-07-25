--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
-- creation dummy connection for new device
os.execute("ifconfig lo:1 1.0.0.1")

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_UpdateAppList.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_OpenConnection("connecttest_UpdateAppList.lua")

Test = require('user_modules/connecttest_UpdateAppList')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local json = require("json")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- Set EnableProtocol4 to true
commonFunctions:SetValuesInIniFile("EnableProtocol4%s-=%s-[%w]-%s-\n", "EnableProtocol4", "true" )

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

-- Sending OnHMIStatus from mobile app
local function SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName )

  if level == nil then
    level = "FULL"
  end

  if audibleState == nil then
    audibleState = "NOT_AUDIBLE"
  end

  if sessionName == nil then
    sessionName = self.mobileSession
  end

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
  end

  userPrint(33, "Sending OnHMIStatus from mobile app with level ".. tostring(level) .. " in " .. tostring(sessionDesc) )

end

-- App registration
local function RegistrationApp(self, sessionName , RAIParams)

  local CorIdRegister = sessionName:SendRPC("RegisterAppInterface", RAIParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
  {
    application = 
    {
    appName = RAIParams.appName
    }
  })
  :Do(function(_,data)
      self.applications[RAIParams.appName] = data.params.application.appID
  end)

  sessionName:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

  DelayedExp(2000)

end


--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
  findresult = string.find (config.pathToSDL, '.$')

  if string.sub(config.pathToSDL,findresult) ~= "/" then
    config.pathToSDL = config.pathToSDL..tostring("/")
  end 
end

local n = 1
local UpdateAppListReceivedParams = {FirstDevice = {}, SecondDevice = {}}
-- Seting app to foreground, sending SystemRequest(QUERY_APPS) after receiving OnSystemRequest notification, expecting UpdadeAppList
local function ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, JsonFileName, UpdateAppListParams, sessionName )

  sessionName.correlationId = sessionName.correlationId + 1

  local msg = 
    {
      serviceType      = 7,
      frameInfo        = 0,
      rpcType          = 2,
      rpcFunctionId    = 32768,
      rpcCorrelationId = sessionName.correlationId,
      payload          = '{"hmiLevel" :"FULL", "audioStreamingState" : "AUDIBLE", "systemContext" : "MAIN"}'
    }

  sessionName:Send(msg)

  --mobile side: OnSystemRequest notification 
  sessionName:ExpectNotification("OnSystemRequest", {})
    :Do(function()
        local CorIdSystemRequest = sessionName:SendRPC("SystemRequest",
          {
            requestType = "QUERY_APPS", 
            fileName = FileName
          },
          "files/jsons/QUERRY_jsons/" .. tostring(JsonFileName))

          --mobile side: SystemRequest response
          sessionName:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
    end)


    --------------------------------------------
    --TODO: remove after resolving APPLINK-16052
    for i=1,#UpdateAppListParams.applications do
      if UpdateAppListParams.applications[i].deviceInfo then
        UpdateAppListParams.applications[i].deviceInfo = nil
      end
    end
    --------------------------------------------

  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", 
    UpdateAppListParams)
    :ValidIf(function(exp,data)
        if
          data.params and
          data.params.applications and
          #data.params.applications == #UpdateAppListParams.applications then
            for i=1,#data.params.applications do
              if not data.params.applications[i].appID then
                userPrint(31, "Element of " .. tostring(data.params.applications[i].appID) .. " is without appID in UpdateAppList ")
                return false
              end
            end
            return true
        else 
          userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected " .. tostring(#UpdateAppListParams.applications))
          return false
        end
    end)
    :Do(function(_,data)
      if  data.params.applications then
        for i=1, #data.params.applications do 
          if data.params.applications[i].deviceInfo.id == "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0" then
            UpdateAppListReceivedParams.FirstDevice[data.params.applications[i].appName] = data.params.applications[i].appID
          elseif data.params.applications[i].deviceInfo.id == "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2" then
            UpdateAppListReceivedParams.SecondDevice[data.params.applications[i].appName] = data.params.applications[i].appID
          else
            userPrint(31, "Wrong id " .. tostring(data.params.applications.deviceInfo.id) .. " of " .. tostring(data.params.applications[i].appName) .. " element in UpdateAppList ")
          end
        end
      end
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

end

-- Unregister registered app
local function UnregisterAppInterface_Success(self, sessionName, iappName) 

  --mobile side: UnregisterAppInterface request 
  local CorIdURAI = sessionName:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected  BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[iappName], unexpectedDisconnect = false})

  --mobile side: UnregisterAppInterface response 
  sessionName:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})

end


--TODO: remove after resolving APPLINK-16052
userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

--===================================================================================--
-- Precondition for test cases
--===================================================================================--


  function Test:Precondition_OpenSession()
    self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession.sendHeartbeatToSDL = false
    self.mobileSession.answerHeartbeatFromSDL = true

    self.mobileSession:StartService(7)
  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- SDL assign internal integer appIDs to 2 apps from json file; SDL send the array of each app-from-the-list's to HMI via BC.UpdateAppList;  
-- After registration of this apps the internal integer appIDs the same as was assigned before (by sending request from mobile to HMI and on the contrary)
--===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_TheSameAppIdAfterRegistrationApp()
    local RAIParameters = config.application1.registerAppInterfaceParams 

    RegistrationApp(self, self.mobileSession, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appName = RAIParameters.appName
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

    EXPECT_NOTIFICATION("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

  end
  
  --===================================================================================--

  function Test:OnSysemRequestQueryApps_TheSameAppIdAfterRegistrationApp()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                appName = config.application1.registerAppInterfaceParams.appName,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
             },
             {
                appName = "Rock music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                greyOut = false
             },
             {
                appName = "Awesome Music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                greyOut = false
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "correctJSON.json", UpdateAppListParameters, self.mobileSession)

  end

  function Test:TheSameAppIdFromUpdateAppListAfterRegistrationApp()
    userPrint(34, "=================================== Test  Case ===================================")
    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)

      --hmi side: sending SDL.ActivateApp
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = UpdateAppListReceivedParams.FirstDevice["Awesome Music App"]})

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.awesome.fake"})
        :Do(function(exp,data)

          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)

          self.mobileSession1.version = 3

          self.mobileSession1:StartService(7)
            :Do(function()

              local RAIParameters = config.application2.registerAppInterfaceParams
              RAIParameters.appName = "Awesome Music App"
              RAIParameters.appID = "853426"

              SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)
              --RegisterApp through new session
              RegistrationApp(self, self.mobileSession1, RAIParameters)

               --hmi side: BasicCommunication.UpdateAppList
              EXPECT_HMICALL("BasicCommunication.UpdateAppList",
                    {
                      applications = {
                       {
                          appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                          appName = config.application1.registerAppInterfaceParams.appName,
                        --[[TODO: update after resolving APPLINK-16052
                          deviceInfo = {
                          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                          isSDLAllowed = true,
                          name = "127.0.0.1",
                          transportType = "WIFI"
                          }]]
                       },
                       {
                          appName = "Awesome Music App",
                          appID = UpdateAppListReceivedParams.FirstDevice["Awesome Music App"],
                          --[[TODO: update after resolving APPLINK-16052
                          deviceInfo = {
                          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                          isSDLAllowed = true,
                          name = "127.0.0.1",
                          transportType = "WIFI"
                          }]]
                       },
                       {
                          appName = "Rock music App",
                          appID = UpdateAppListReceivedParams.FirstDevice["Rock music App"],
                          --[[TODO: update after resolving APPLINK-16052
                          deviceInfo = {
                          id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                          isSDLAllowed = true,
                          name = "127.0.0.1",
                          transportType = "WIFI"
                          }]]
                       }}
                    })
                :Do(function(_,data)
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
                end)
                :ValidIf(function(_,data)
                  if #data.params.applications == 3 then
                    return true
                    else 
                      userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3")
                      return false
                    end
                end)

              --mobile side: expect OnHMIStatus on mobile side
              self.mobileSession1:ExpectNotification("OnHMIStatus", 
                {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
                {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                :Times(2)

              EXPECT_NOTIFICATION("OnHMIStatus", {})
                :Times(0)

              self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "LOCK_SCREEN_ICON_URL"})
                :Times(AtMost(1))

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

          DelayedExp(1000)

        end)

  end

--===================================================================================--
-- Checks that SDL sends UpdateAppList with the registered apps if exit app of v4 protocol.
--===================================================================================--

  function Test:RegisteredAppInUpdateAppListAfterUnregisterFourthProtocolApp()
    userPrint(34, "=================================== Test  Case ===================================")
    UnregisterAppInterface_Success(self, self.mobileSession, config.application1.registerAppInterfaceParams.appName)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appName = "Awesome Music App",
                appID = self.applications["Awesome Music App"]
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

  end

--===================================================================================--
-- Checks that SDL sends UpdateAppList after SystemRequest when 2 devices registered and both has v4.0 protocol application.
--===================================================================================--

  --Precondition: Close openned connection
  function Test:Precondition_CloseOpennedConnection()
    userPrint(35, "=================================== Precondition ===================================")
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

    self.mobileSession.version = 4

    self.mobileSession.sendHeartbeatToSDL = false
    self.mobileSession.answerHeartbeatFromSDL = true

    self.mobileSession:StartService(7)

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

    self.mobileSession2.sendHeartbeatToSDL = false
    self.mobileSession2.answerHeartbeatFromSDL = true

    self.mobileSession2:StartService(7)

  end

  function Test:Precondition_RegiaterApp_FirstDevice()
    local RAIParameters = config.application1.registerAppInterfaceParams 

    RAIParameters.appName = "First device application 1"
    RAIParameters.appID = "00001"

    RegistrationApp(self, self.mobileSession, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = self.applications[RAIParameters.appName],
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

    EXPECT_NOTIFICATION("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

  end

  function Test:UpdateAppList_AfterSystemRequestQueryApps_OnFirstDevice()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = "First device application 1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appName = "First device application 2",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appName = "First device application 3",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "UpdateAppListFirstDevice.json", UpdateAppListParameters, self.mobileSession)
  end

  function Test:Precondition_RegisterApp_SecondDevice()
    userPrint(35, "=================================== Precondition ===================================")
    local RAIParameters = config.application2.registerAppInterfaceParams 

    RAIParameters.appName = "Second device application 1"
    RAIParameters.appID = "00002"

    RegistrationApp(self, self.mobileSession2, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = self.applications[RAIParameters.appName],
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]           
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

    self.mobileSession2:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

  end

  function Test:UpdateAppList_AfterSystemRequestQueryApps_OnSecondDevice()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = self.applications["Second device application 1"],
                appName = "Second device application 1",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Second device application 2"],
                appName = "Second device application 2",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Second device application 3"],
                appName = "Second device application 3",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "UpdateAppListSecondDevice.json", UpdateAppListParameters, self.mobileSession2)
  end

--===================================================================================--
-- Checks that SDL sends BC.UpdateAppList with apps on first device after exit v4 protocol app on second device.
--===================================================================================--

function Test:ApplicationsOfFirstDeviceInUpdateAppListAfterUnregisterAppOnSecondDevice()
  userPrint(34, "=================================== Test  Case ===================================")
  --request from mobile side
  local CorIdUnregisterAppInterface = self.mobileSession2:SendRPC("UnregisterAppInterface",{})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})

  --response on mobile side
  self.mobileSession2:ExpectResponse(CorIdUnregisterAppInterface, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)

  EXPECT_HMICALL("BasicCommunication.UpdateAppList",{
    applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]    
             }
    }})
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 3 then
          return true
        else 
          userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3")
          return false
        end
      end)
end

--===================================================================================--
-- Checks that SDL sends BC.UpdateAppList with apps on first device after disconnect second device.
--===================================================================================--

function Test:Precondition_ReOpenSecondConnectionCreateSession()
  userPrint(35, "=================================== Precondition ===================================")
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

  self.mobileSession2.sendHeartbeatToSDL = false
  self.mobileSession2.answerHeartbeatFromSDL = true

  self.mobileSession2:StartService(7)

end

function Test:Precondition_ReregisterApp_SecondDevice()
  userPrint(35, "=================================== Precondition ===================================")
    local RAIParameters = config.application2.registerAppInterfaceParams 

    RAIParameters.appName = "Second device application 1"
    RAIParameters.appID = "00002"

    RegistrationApp(self, self.mobileSession2, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]             
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 4 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4")
            return false
          end
      end)

    self.mobileSession2:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  function Test:Precondition_SystemRequestQueryAppsOnSecondDevice()
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = self.applications["Second device application 1"],
                appName = "Second device application 1",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Second device application 2"],
                appName = "Second device application 2",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Second device application 3"],
                appName = "Second device application 3",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "UpdateAppListFirstDevice.json", UpdateAppListParameters, self.mobileSession2)
  end

  function Test:ApplicationsOfFirstDeviceInUpdateAppListAfterDisconnectSecondDevice()
    userPrint(34, "=================================== Test  Case ===================================")
    --closing connection
    self.mobileConnection2:Close()

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,  appID = self.applications["Second device application 1"]})

    EXPECT_HMICALL("BasicCommunication.UpdateAppList",{
      applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 1"],
                appName = "First device application 1",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 2"],
                appName = "First device application 2",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["First device application 3"],
                appName = "First device application 3",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]             
             }
    }})
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 3 then
          return true
        else 
          userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3")
          return false
        end
      end)
  end

function Test:Postcondition_CloseFirstConnection()
  self.mobileConnection:Close()
end

--===================================================================================--
-- Checks that SDL sends UpdateAppList with the same names Apps from different phones
--===================================================================================--

--Precondition openning 2 conections
  function Test:Precondition_OpenFirstConnectionCreateSession_TheSameQueryAppsOnBothDevices()
    userPrint(35, "=================================== Precondition ===================================")
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()

    self.mobileSession.version = 4

    self.mobileSession:StartService(7)

  end

  function Test:Precondition_OpenSecondConnectionCreateSession_TheSameQueryAppsOnBothDevices()
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

  function Test:Precondition_RegisterApp_FirstDevice_TheSameQueryAppsOnBothDevices()
    local RAIParameters = config.application1.registerAppInterfaceParams 

    RAIParameters.appName = "Test application1"
    RAIParameters.appID = "00001"

    RegistrationApp(self, self.mobileSession, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = self.applications[RAIParameters.appName],
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

    EXPECT_NOTIFICATION("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

  end

  function Test:UpdateAppListAfterSystemRequestQueryApps_OnFirstDevice_TheSameQueryAppsOnBothDevices()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = "Test application1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appName = "Rock music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appName = "Awesome Music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "correctJSON.json", UpdateAppListParameters, self.mobileSession)
  end

  function Test:Precondition_RegisterApp_SecondDevice_TheSameQueryApps()
    userPrint(35, "=================================== Precondition ===================================")
    local RAIParameters = config.application2.registerAppInterfaceParams 

    RAIParameters.appName = "Test application2"
    RAIParameters.appID = "00002"

    RegistrationApp(self, self.mobileSession2, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Test application1"],
                appName = "Test application1",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Rock music App"],
                appName = "Rock music App",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Awesome Music App"],
                appName = "Awesome Music App",
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]           
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 4 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4")
            return false
          end
      end)

    self.mobileSession2:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

  end

  function Test:UpdateAppListAfterAfterSystemRequestQueryApps_OnSecondDevice_TheSameQueryApps()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Test application1"],
                appName = "Test application1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = self.applications["Test application2"],
                appName = "Test application2",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Rock music App"],
                appName = "Rock music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Rock music App"],
                appName = "Rock music App",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Awesome Music App"],
                appName = "Awesome Music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             },
             {
                appID = UpdateAppListReceivedParams.SecondDevice["Awesome Music App"],
                appName = "Awesome Music App",
                deviceInfo = {
                  id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
                  isSDLAllowed = true,
                  name = "1.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "UpdateAppListSecondDevice.json", UpdateAppListParameters, self.mobileSession2)
  end

  function Test:Postcondition_CloseConnections()
    self.mobileConnection:Close()
    self.mobileConnection2:Close()

    DelayedExp(1000)
  end

--===================================================================================--
-- Checks that SDL sends UpdateAppList with the present on device apps if v3 apps from this device was registered.
--===================================================================================--

  --Precondition openning 2 conections
  function Test:Precondition_OpenConnectionCreateSession()
    userPrint(35, "=================================== Precondition ===================================")
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()

    self.mobileSession.version = 3

    self.mobileSession:StartService(7)

  end

  function Test:Precondition_RegisterApp_ThirdProtocol()
    local RAIParameters = config.application1.registerAppInterfaceParams 

    RAIParameters.appName = "Awesome Music App"
    RAIParameters.appID = "853426"

    RegistrationApp(self, self.mobileSession, RAIParameters)

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appName = RAIParameters.appName,
              --[[TODO: update after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }]]
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 1 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1")
            return false
          end
      end)

    EXPECT_NOTIFICATION("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))

    DelayedExp(1000)
  end

  function Test:Precondition_RegisterApp_FourthProtocolQueryApps()
    local RAIParameters = config.application1.registerAppInterfaceParams 

    RAIParameters.appName = "Test application1"
    RAIParameters.appID = "0000001"

    self.mobileSession1 = mobile_session.MobileSession(
      self,
      self.mobileConnection)

    self.mobileSession1.version = 4

    self.mobileSession1:StartService(7)
      :Do(function()
        RegistrationApp(self, self.mobileSession1, RAIParameters)

        --hmi side: BasicCommunication.UpdateAppList
        EXPECT_HMICALL("BasicCommunication.UpdateAppList",
              {
                applications = {
                  {
                      appID = self.applications["Awesome Music App"],
                      appName = "Awesome Music App",
                    --[[TODO: update after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      }]]
                   },
                   {
                      appID = self.applications["Test application1"],
                      appName = "Test application1",
                    --[[TODO: update after resolving APPLINK-16052
                      deviceInfo = {
                        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                        isSDLAllowed = true,
                        name = "127.0.0.1",
                        transportType = "WIFI"
                      }]]
                   }}
              })
          :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          end)
          :ValidIf(function(_,data)
            if #data.params.applications == 2 then
              return true
              else 
                userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 2")
                return false
              end
          end)

        self.mobileSession1:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

        self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
          :Times(AtMost(1))

        DelayedExp(1000)
      end)
  end

  function Test:UpdateAppListAfterSystemRequest_QueryAppAlreadyRegistered()
    userPrint(34, "=================================== Test  Case ===================================")
    local UpdateAppListParameters = 
        {
          applications = {
             {
                appID = self.applications["Awesome Music App"],
                appName = "Awesome Music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = self.applications["Test application1"],
                appName = "Test application1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appName = "Rock music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "correctJSON.json", UpdateAppListParameters, self.mobileSession1)
  end
--===================================================================================--
-- Checks that SDL sends UpdateAppList without application after it's unregistering as avaliable on device.
--===================================================================================--

  function Test:AbsenceUnregisteredQueryAppInUpdateAppListAfterUnregistrationQueryApp()
    userPrint(34, "=================================== Test  Case ===================================")
    UnregisterAppInterface_Success(self, self.mobileSession , "Awesome Music App")

    --hmi side: BasicCommunication.UpdateAppList
    EXPECT_HMICALL("BasicCommunication.UpdateAppList",
          {
            applications = {
             {
                appID = self.applications["Test application1"],
                appName = "Test application1",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }
             },
             {
                appID = UpdateAppListReceivedParams.FirstDevice["Rock music App"],
                appName = "Rock music App",
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                }             
             }}
          })
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      end)
      :ValidIf(function(_,data)
        if #data.params.applications == 3 then
          return true
          else 
            userPrint(31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3")
            return false
          end
      end)

  end

function Test:Postcondition_removeCreatedUserConnecttest()
  os.execute(" rm -f  ./user_modules/connecttest_UpdateAppList.lua")
end

function Test:Postcondition_DeleteDummyConnectionForSecondDevice()
  os.execute("ifconfig lo:1 down")
end