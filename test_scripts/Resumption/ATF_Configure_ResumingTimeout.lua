---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")
commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")
-- creation dummy connection for new device
os.execute("ifconfig lo:1 192.168.100.199")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local mobile = require('mobile_connection')
require('user_modules/AppTypes')

-- Postcondition: removing user_modules/connecttest_resumption.lua
function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
-------------------------------------------Common functions----------------------------------
---------------------------------------------------------------------------------------------
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local AppValuesOnHMIStatusFULL
local AppValuesOnHMIStatusLIMITED

if  config.application1.registerAppInterfaceParams.isMediaApplication == true then
  -- Test.appHMITypes["NAVIGATION"] == true or
  -- Test.appHMITypes["COMMUNICATION"] == true) then
    AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
    AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
elseif config.application1.registerAppInterfaceParams.isMediaApplication == false then
  AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
end

local DefaultHMILevel = "NONE"
local HMIAppID = nil

local timeOfRegistrationFirstApp = nil

local AppValuesOnHMIStatusDEFAULT = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}

local applicationData =
{
  mediaApp1 = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 3
    },
    appName = "TestAppMedia1",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "MEDIA" },
    appID = "0000002",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  mediaApp2 = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 3
    },
    appName = "TestAppMedia2",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "MEDIA" },
    appID = "0000003",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  nonmediaApp = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 3
    },
    appName = "TestAppNonMedia",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0000004",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  navigationApp = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 3
    },
    appName = "TestAppNavigation",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0000005",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  communicationApp = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 3
    },
    appName = "TestAppCommunication",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "COMMUNICATION" },
    appID = "0000006",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }
}

  local HMIAppIDMediaApp1 = nil
  local HMIAppIDMediaApp2 = nil
  local HMIAppIDNonMediaApp = nil

  local function RegisterApp(self, session, RegisterData, DEFLevel, isFirstApp)

    if isFirstApp ~= true then
      isFirstApp = false
    end
    local correlationId = session:SendRPC("RegisterAppInterface", RegisterData)
    if isFirstApp == true then
        --do
        timeOfRegistrationFirstApp = timestamp()
    end

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
        -- self.applications[RegisterData.appName] = data.params.application.appID
        if RegisterData.appName == "TestAppMedia1" then
          HMIAppIDMediaApp1 = data.params.application.appID
        elseif RegisterData.appName == "TestAppMedia2" then
          HMIAppIDMediaApp2 = data.params.application.appID
        elseif RegisterData.appName == "TestAppNonMedia" then
          HMIAppIDNonMediaApp = data.params.application.appID
        elseif RegisterData.appName == "TestAppNavigation" then
          HMIAppIDNaviApp = data.params.application.appID
        elseif RegisterData.appName == "TestAppCommunication" then
          HMIAppIDComApp = data.params.application.appID
        end
      end)

    session:ExpectResponse(correlationId, { success = true })

    session:ExpectNotification("OnHMIStatus", DEFLevel)

  end

  local function IGNITION_OFF(self)
    StopSDL()

    --[[if appNumber == nil then
    appNumber = 1
  end
  ]]
  -- hmi side: sends OnExitAllApplications (SUSPENDED)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  --[[-- hmi side: expect OnAppUnregistered notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(appNumber)
  ]]
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
      RAISE_EVENT(event, event)
      end, time)
end

local function ActivationApp(self, session, appID, expectedLevel)
  -- print("checked levels: " .. expectedLevel.hmiLevel .. expectedLevel.systemContext .. expectedLevel.audioStreamingState)

  if notificationState.VRSession == true then
    self.hmiConnection:SendNotification("VR.Stopped", {})
  elseif notificationState.EmergencyEvent == true then
    self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
  elseif notificationState.PhoneCall == true then
    self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
  end

    -- hmi side: sending SDL.ActivateApp request
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appID})
    -- print("P1")
    -- print(AppValuesOnHMIStatusFULL.hmiLevel, AppValuesOnHMIStatusFULL.systemContext, AppValuesOnHMIStatusFULL.audioStreamingState)

    -- hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
        -- In case when app is not allowed, it is needed to allow app
        if data.result.isSDLAllowed ~= true then
          -- print("P2")
          -- hmi side: sending SDL.GetUserFriendlyMessage request
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
            {language = "EN-US", messageCodes = {"DataConsent"}})

          -- hmi side: expect SDL.GetUserFriendlyMessage response
          -- TODO: comment until resolving APPLINK-16094
          -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          EXPECT_HMIRESPONSE(RequestId)
          :Do(function(_,data)

              -- hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
                {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

              -- hmi side: expect BasicCommunication.ActivateApp request
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data)
                -- print("P3")
                -- hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                end)
              :Times(1)
            end)
        end 
      end)

    -- print("P4")
    -- print("Checked values:" .. AppValuesOnHMIStatusFULL)
    --mobile side: expect notification
    -- session:ExpectNotification("OnHMIStatus", 
    --   { hmiLevel = AppValuesOnHMIStatusFULL.hmiLevel, 
    --     systemContext = AppValuesOnHMIStatusFULL.systemContext, 
    --     audioStreamingState = AppValuesOnHMIStatusFULL.audioStreamingState})
    -- session:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
    session:ExpectNotification("OnHMIStatus", expectedLevel)
    :Timeout(5000)
end

--Check pathToSDL, in case last symbol is not'/' add '/'
local function checkSDLPathValue()
  findresult = string.find (config.pathToSDL, '.$')

  if string.sub(config.pathToSDL,findresult) ~= "/" then
    config.pathToSDL = config.pathToSDL..tostring("/")
  end
end

local function SetAppToTargetLevelAndPerfromDisconnect(self, session, targetLevel, appID)
  if session == nil then
    print("Session is absent")
    return  false
  end
  if targetLevel == nil then
    session:Stop()
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  -- desired action: disconnect from FULL, but App is not in FULL
  elseif (targetLevel == "FULL" and self.hmiLevel ~= "FULL") then
    print("HMI appID: " .. appID)
    ActivationApp(self, session, appID)
    session:ExpectNotification("OnHMIStatus", AppValuesOnHMIStatusFULL)
    :Do(function(_,data)
        self.hmiLevel = data.payload.hmiLevel
        session:Stop()
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
      end)
    session:Stop()
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  -- desired action: disconnect from LIMITED, but App is not in LIMITED
  elseif (targetLevel == "LIMITED" and self.hmiLevel ~= "LIMITED") then
    -- App now is either in NONE or BACKGROUND, desired action: disconnect from LIMITED
    if self.hmiLevel ~= "FULL" then
      ActivationApp(self, session, appID)
      
      session:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
      :Do(function(exp,data)
            session:Stop()
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
        end)

      --hmi side: sending BasicCommunication.OnAppDeactivated notification
      self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = appID})
    -- App now in FULL, desired action: disconnect from LIMITED
    else
      --hmi side: sending BasicCommunication.OnAppDeactivated notification
      self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = appID})

      session:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
      :Do(function(exp,data)
          session:Stop()
          EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
        end)
    end
  -- desired action: disconnect from FULL/LIMITED, and actually App is in FULL/LIMITED
  elseif (targetLevel == "LIMITED" and self.hmiLevel == "LIMITED") or
         (targetLevel == "FULL" and self.hmiLevel == "FULL") then
          -- print("We are at FULL, FULL")
          -- print("HMI appID: " .. appID)
          -- os.execute("sleep 0.3")
          session:Stop()
          EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  end
end

local function RegisterAppAfterDisconnect(self, HMILevel, reason, session, resumptionTimeout)

  if HMILevel == "FULL" then
    local AppValuesOnHMIStatus = AppValuesOnHMIStatusFULL
  elseif HMILevel == "LIMITED" then
    local AppValuesOnHMIStatus = AppValuesOnHMIStatusLIMITED
  end

  local correlationId = session:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  -- got time after RAI request
  local timeOfRAI = timestamp()

  if reason == "IGN_OFF" then
    local RAIAfterOnReady = time - self.timeOnReady
    userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))
  end

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
      -- self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  session:ExpectResponse(correlationId, { success = true })

  if HMILevel == "FULL" then
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
  elseif HMILevel == "LIMITED" then
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  end

  EXPECT_NOTIFICATION("OnHMIStatus",
    AppValuesOnHMIStatusDEFAULT,
    AppValuesOnHMIStatus)
  :ValidIf(function(exp,data)
      if exp.occurences == 2 then
        local currentTime = timestamp()
        local timeToresumption = currentTime - timeOfRAI
        if timeToresumption >= resumptionTimeout and
        timeToresumption < (resumptionTimeout + 200) then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(resumptionTimeout))
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(resumptionTimeout))
          return false
        end

      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(2)

  --mobile side: expect OnHashChange notification
  -- EXPECT_NOTIFICATION("OnHashChange")
  session:ExpectNotification("OnHashChange", {hashID = ".*"})
  :Times(1)

end

--Precondition: Unregister registered app
local function UnregisterAppInterface_Success(self, sessionName, iappName)
  if sessionName == nil then
    sessionName = self.mobileSession
  end

  if iappName == nil then
    iappName = config.application1.registerAppInterfaceParams.appName
  end

  --mobile side: UnregisterAppInterface request
  local CorIdURAI = sessionName:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[iappName], unexpectedDisconnect = false})

  --mobile side: UnregisterAppInterface response
  sessionName:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  :Do(function()
      sessionName:Stop()
    end)

end

-- Stop SDL, optionaly changing values ApplicationResumingTimeout, start SDL, HMI initialization, create mobile connection
local function RestartSDL(self, prefix, ApplicationResumingTimeoutValueToReplace)

  checkSDLPathValue()

  SDLStoragePath = config.pathToSDL .. "storage/"

  local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

  Test["StopSDL_" .. tostring(prefix)] = function(self)
    StopSDL()
  end

  if ApplicationResumingTimeoutValueToReplace ~= nil then
    Test["Precondition_ApplicationResumingTimeoutChange_" .. tostring(prefix)] = function(self)
      local StringToReplace = "ApplicationResumingTimeout = " .. tostring(ApplicationResumingTimeoutValueToReplace) .. "\n"
      f = assert(io.open(SDLini, "r"))
      if f then
        fileContent = f:read("*all")
        local MatchResult = string.match(fileContent, "ApplicationResumingTimeout%s-=%s-.-%s-\n")
        if MatchResult ~= nil then
          fileContentUpdated = string.gsub(fileContent, MatchResult, StringToReplace)
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else
          userPrint(31, "Finding of 'ApplicationResumingTimeout = value' is failed. Expect string finding and replacing of value to " .. tostring(ApplicationResumingTimeoutValueToReplace))
        end
        f:close()
      end
    end
  end

  Test["StartSDL_" .. tostring(prefix)] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
    DelayedExp(1000)
  end

  Test["InitHMI_" .. tostring(prefix)] = function(self)
    self:initHMI()
  end

  Test["InitHMIonReady_" .. tostring(prefix)] = function(self)
    self:initHMI_onReady()
  end

  Test["ConnectMobile_" .. tostring(prefix)] = function(self)
    self:connectMobile()
  end
end


--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing session
-- covers TC_Configure_ResumingTimeout_01 - APPLINK-15887
-- Check that resuming HMI level starts after 3 second if no apps registered.
--////////////////////////////////////////////////////////////////////////////////////////////

function Test:ActivateApp(...)
   userPrint(33, "===================TC1:Preconditions===================")
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  self.hmiLevel = "FULL"
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

--Precondition: Set ApplicationResumingTimeout = 3000 in .ini file
   RestartSDL(self, "prefix", 3000)


function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end

--Resumption of FULL hmiLevel
function Test:CheckAppResumesToFullIn_3Sec()
  userPrint(34, "TC1:App resumes to FULL in 3 sec:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 3000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing session
-- covers TC_Configure_ResumingTimeout_02 - APPLINK-15890
-- Check that resuming HMI level starts after 6 second if no apps registered.
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 6000 in .ini file
function Test:RestartSDL2() 
  	userPrint(33, "===================TC2:Preconditions===================")
	RestartSDL(self, "prefix", 6000)
end

function Test:StartSession()
  self:startSession()
end

function Test:ActivateApp(...)
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  print("HMI appID: " .. tostring(HMIAppID))
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

function Test:StartSession()

  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)

end

function Test:CheckAppResumesToFullIn_6Sec()
  userPrint(34, "TC2:App resumes to FULL in 6 sec:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
    os.execute("sleep 0.3")
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 6000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_03 - APPLINK-15891
-- Check that resuming HMI levels of 3 apps starts after 3 second if no apps registered before. (Non-media =Full, Media = Background, Media = Limited)
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 3000 in .ini file
function Test:RestartSDL3() 
  	userPrint(33, "=================TC3:Preconditions==================")
	RestartSDL(self, "prefix", 3000)
end
-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession2, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()

  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)

end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)

end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)

end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)

end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_FULLnonmedia_LIMITEDmedia_NONEmedia_3_sec()
  userPrint(34, "TC3:Resuming FULL non-media, LIMITED media and NONE media in 3sec:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false})
  :Times(3)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_04 - APPLINK-15892
-- Check that resuming HMI levels of 3 apps starts after 6 second if no apps registered before (Non-media =Full, Media = Background, Media = Limited)
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 6000 in .ini file
function Test:RestartSDL4()
        userPrint(33, "=================TC4:Precondition==================")
	RestartSDL(self, "prefix", 6000)
end
-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession3, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
      -- got time after RAI request
      timeOfRegistrationFirstApp = timestamp()
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)

end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)

end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_FULLnonmedia_LIMITEDmedia_NONEmedia_6_sec()
  userPrint(34, "TC4:Resuming FULL non-media, LIMITED media and NONE media in 6sec:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end

      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false})
  :Times(3)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_05 - APPLINK-15893
-- Check that resuming HMI level starts after 3 second if some app already registered
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 3000 in .ini file
function Test:RestartSDL5()
    userPrint(33, "=================TC5:Precondition==================")
    RestartSDL(self, "prefix", 3000)
end
function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:Resumption_FULL_Some_App_already_registered_3_sec()
  userPrint(34, "TC5:Resuming FULL in 3sec if some App already registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDMediaApp1})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  self.mobileSession1:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(2)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_06 - APPLINK-15894
-- Check that resuming HMI level starts after 6 seconds if some app already registered
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 6000 in .ini file
function Test:RestartSDL6()
    userPrint(33, "=================TC6:Precondition==================")
    RestartSDL(self, "prefix", 6000)
end

function Test:StartSession1()
   self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
      -- got time after RAI request
      timeOfRegistrationFirstApp = timestamp()
    end)
end

function Test:Resumption_FULL_Some_App_already_registered_6_sec()
  userPrint(34, "TC6:Resuming FULL in 6sec if some App already registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDMediaApp1})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  self.mobileSession1:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(2)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_07 - APPLINK-15895
-- Check that resuming HMI levels of 3 apps starts after 3 seconds if some app registered before (App1=Full, app2=Background, app3=Limited).
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 3000 in .ini file
function Test:RestartSDL7()
    userPrint(33, "=================TC7:Precondition==================")
    RestartSDL(self, "prefix", 3000)
end

-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession3, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)

end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)

end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_FULLnonmedia_LIMITEDmedia_NONEmedia_3_sec_Some_App_registered()
  userPrint(34, "TC7:Resuming 3 Apps in 3sec if some App registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(4)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

function Test:CloseConnection2()
  self.mobileConnection2:Close()
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by closing connection
-- covers TC_Configure_ResumingTimeout_08 - APPLINK-15896
-- Check that resuming HMI levels of 3 apps starts after 6 seconds if some app registered before (App1=Full, app2=Background, app3=Limited).
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 6000 in .ini file

function Test:RestartSDL8()
    userPrint(33, "=================TC8:Precondition==================")
    RestartSDL(self, "prefix", 6000)
end

-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession3, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)

end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)

end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)

end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_FULLnonmedia_LIMITEDmedia_NONEmedia_6_sec_Some_App_registered()
  userPrint(34, "TC8:Resuming 3 Apps in 6sec if some App registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end

      elseif exp.occurences == 1 then
        return true
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(4)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

function Test:CloseConnection2()
  self.mobileConnection2:Close()
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by Ignition off
-- covers TC_Configure_ResumingTimeout_09 - APPLINK-15897
-- Check that resuming HMI levels of 3 apps starts after 3 second if some app registered after IGN_CYCLE (App1=Full, app2=Background, app3=Limited)
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 3000 in .ini file

function Test:RestartSDL9()
    userPrint(33, "=================TC9:Precondition==================")
    RestartSDL(self, "prefix", 3000)
end

-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession3, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:IGNITION_OFF()
  IGNITION_OFF(self)
end

function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI()
  self:initHMI()
end

function Test:InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_3_apps_IGN_OFF_3_sec_Some_App_registered()
  userPrint(34, "TC9:Resuming 3 apps after IGN_OFF in 3sec with App registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 3000 and
        timeToresumption < 3100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(4)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

function Test:CloseConnection2()
  self.mobileConnection2:Close()
end

--////////////////////////////////////////////////////////////////////////////////////////////
--Resumption of HMIlevel by Ignition off
-- covers TC_Configure_ResumingTimeout_10 - APPLINK-15898
-- Check that resuming HMI levels of 3 apps starts after 6 second if some app registered after IGN_CYCLE (App1=Full, app2=Background, app3=Limited)
--////////////////////////////////////////////////////////////////////////////////////////////

--Precondition: Set ApplicationResumingTimeout = 6000 in .ini file

function Test:RestartSDL10()
    userPrint(33, "=================TC10:Precondition==================")
    RestartSDL(self, "prefix", 6000)
end

-- Registration and activation of apps

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Precondition_ActivateMedia1()
  ActivationApp(self, self.mobileSession1, HMIAppIDMediaApp1, AppValuesOnHMIStatusFULL)
end

function Test:Precondition_ActivateMedia2()
  ActivationApp(self, self.mobileSession2, HMIAppIDMediaApp2, AppValuesOnHMIStatusFULL)
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateNonMedia()
  ActivationApp(self, self.mobileSession3, HMIAppIDNonMediaApp, {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(0)
end

function Test:CloseConnection()
  self.mobileConnection:Close()
end

function Test:IGNITION_OFF()
  IGNITION_OFF(self)
end

function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI()
  self:initHMI()
end

function Test:InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_OpenSecondConnectionCreateSession()
  local tcpConnection = tcp.Connection("192.168.100.199", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession4:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()

  self.mobileSession4:StartService(7)

end

function Test:Precondition_RegisterApp_SecondDevice()

  RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULT)

end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession1()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp1)
end

function Test:RegisterMediaApp1()
  self.mobileSession1:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession1, applicationData.mediaApp1, AppValuesOnHMIStatusDEFAULT, true)
    end)
end

function Test:StartSession2()
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.mediaApp2)
end

function Test:RegisterMediaApp2()
  self.mobileSession2:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession2, applicationData.mediaApp2, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:StartSession3()
  self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    applicationData.nonmediaApp)
end

function Test:RegisterNonMedia()
  self.mobileSession3:StartService(7)
  :Do(function()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULT)
    end)
end

function Test:Resumption_3_apps_IGN_OFF_6_sec_Some_App_registered()
  userPrint(34, "TC10: Resuming 3 apps after IGN_OFF in 6sec with App registered:")

  EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID = HMIAppIDNonMediaApp})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource",
    {appID = HMIAppIDMediaApp2})
  :Times(1)

  self.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession3:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :ValidIf(function(exp,data)
      if exp.occurences == 1 then
        local time = timestamp()
        local timeToresumption = time - timeOfRegistrationFirstApp
        if timeToresumption >= 6000 and
        timeToresumption < 6100 then
          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return true
        else
          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~6000 " )
          return false
        end
      end
    end)
  :Do(function(_,data)
      self.hmiLevel = data.payload.hmiLevel
    end)
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

  self.mobileSession4:ExpectNotification("OnHMIStatus",{})
  :Times(0)

  DelayedExp(1000)

end

--////////////////////////////////////////////////////////////////////////////////////////////
--Negative checks:
--ApplicationResumingTimeout = 0 in .ini file: SDL should use default value = 3sec
--ApplicationResumingTimeout =   in .ini file (value missing): SDL should use default value = 3sec
--ApplicationResumingTimeout = -3000  in .ini file (wrong value): SDL should use default value = 3sec
--ApplicationResumingTimeout is missing in .ini file: SDL should use default value = 3sec
--////////////////////////////////////////////////////////////////////////////////////////////

function Test:RestartSDL11() 
  	userPrint(33, "===================TC11:Preconditions===================")
        RestartSDL(self, "prefix", 0)
end

function Test:StartSession()
  self:startSession()
end

function Test:ActivateApp(...)
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  print("HMI appID: " .. tostring(HMIAppID))
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end

--Resumption of FULL hmiLevel
function Test:CheckAppResumesIfTimeoutIsZero()
  userPrint(34, "TC11:Negative check: ApplicationResumingTimeout = 0 in .ini:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
  os.execute("sleep 0.3")
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 3000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end


----------------------------------------------------------------------------------------------

function Test:ActivateApp(...)
   userPrint(33, "===================TC12:Preconditions===================")
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  self.hmiLevel = "FULL"
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

--Precondition: Set ApplicationResumingTimeout =  in .ini file
   RestartSDL(self, "prefix",'')


function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end

--Resumption of FULL hmiLevel
function Test:CheckAppResumesIfTimeoutIsEmptyValue()
  userPrint(34, "TC12:Negative check:ApplicationResumingTimeout =  (empty value) in .ini:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 3000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end

----------------------------------------------------------------------------------------------

function Test:ActivateApp(...)
   userPrint(33, "===================TC13:Preconditions===================")
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  self.hmiLevel = "FULL"
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

--Precondition: Set ApplicationResumingTimeout = -3000 in .ini file
   RestartSDL(self, "prefix", -3000)


function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end

--Resumption of FULL hmiLevel
function Test:CheckAppResumesIfTimeoutIsWrongValue()
  userPrint(34, "TC13:Negative check:ApplicationResumingTimeout is wrong value in .ini:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 3000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end

----------------------------------------------------------------------------------------------

function Test:ActivateApp(...)
   userPrint(33, "===================TC14:Preconditions===================")
  -- body
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  self.hmiLevel = "FULL"
  ActivationApp(self, self.mobileSession, HMIAppID, AppValuesOnHMIStatusFULL)
end

function Test:ActivateAppAndPerfromDisconnect()
  SetAppToTargetLevelAndPerfromDisconnect(self, self.mobileSession, "FULL", HMIAppID)
end

--Precondition: Remove ApplicationResumingTimeout param from .ini file
   RestartSDL(self, "prefix", nil)


function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
end

--Resumption of FULL hmiLevel
function Test:CheckAppResumesToFullIfTimeoutIsNil()
  userPrint(34, "TC13:Negative check:ApplicationResumingTimeout param is missing in .ini:")
  self.mobileSession:StartService(7)
  :Do(function(_,data)
      RegisterAppAfterDisconnect(self, "FULL", nil, self.mobileSession, 3000)
    end)

end

function Test:Postcondition_UnregisterApp_Gracefully()
  UnregisterAppInterface_Success(self, self.mobileSession, self.applications)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------

function Test:Postconditions() 
	userPrint(33, "===================Postconditions===================")
end

function Test:Postcondition_UnregisterApps_Gracefully()
  --mobile side: UnregisterAppInterface request
  self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = HMIAppIDMediaApp1, unexpectedDisconnect = false},
    {appID = HMIAppIDMediaApp2, unexpectedDisconnect = false},
    {appID = HMIAppIDNonMediaApp, unexpectedDisconnect = false},
    {appID = HMIAppIDComApp, unexpectedDisconnect = false})
  :Times(4)

  --mobile side: UnregisterAppInterface response
  self.mobileSession1:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession3:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession3:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

  --mobile side: UnregisterAppInterface request
  self.mobileSession4:SendRPC("UnregisterAppInterface", {})

  --mobile side: UnregisterAppInterface response
  self.mobileSession4:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end

function Test:CloseSession1()
  self.mobileSession1:Stop()
end

function Test:CloseSession2()
  self.mobileSession2:Stop()
end

function Test:CloseSession3()
  self.mobileSession3:Stop()
end

function Test:CloseConnection2()
  self.mobileConnection2:Close()
end

function Test:Postcondition_DeleteDummyConnectionForSecondDevice()
  os.execute("ifconfig lo:1 down")
end
