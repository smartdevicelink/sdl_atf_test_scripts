
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- Postcondition: removing user_modules/connecttest_resumption.lua
function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

--Precondition: backup smartDeviceLink.ini
commonPreconditions:BackupFile("smartDeviceLink.ini")

-- set  ApplicationResumingTimeout in .ini file to 3000;
commonFunctions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s?=%s-[%d]-%s-\n", "ApplicationResumingTimeout", 3000)

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local HMIAppIDNonMediaApp
local HMIAppIDMediaApp
local HMIAppIDNaviApp
local HMIAppIDComApp
local HMIAppID

local DefaulthmiLevel = "NONE"

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false, DeactivateHMI = false}

local timeFromRequestToNot = 0

local AppValuesOnHMIStatusFULL 
local AppValuesOnHMIStatusLIMITED 

local applicationData = 
{
    preregisteredApp = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "PreregisteredApp",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT"},
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

if 
  config.application1.registerAppInterfaceParams.isMediaApplication == true or 
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then 
    AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
    AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
elseif 
  config.application1.registerAppInterfaceParams.isMediaApplication == false then
    AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
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

local function RegisterApp(self)
  self.mobileSession5 = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      applicationData.preregisteredApp)


    self.mobileSession5:StartService(7)
    :Do(function(_,data)

      local correlationId = self.mobileSession5:SendRPC("RegisterAppInterface", applicationData.preregisteredApp)

      self.mobileSession5:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

      self.mobileSession5:ExpectNotification("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
    end)


end

local function IGNITION_OFF(self)

  StopSDL()
  --hmi side: sends OnExitAllApplications (SUSPENDED)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
   EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
end

local function IGNITION_OFF_2Apps(self)

  StopSDL()
  --hmi side: sends OnExitAllApplications (SUSPENDED)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
   EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
    :Times(2)
end

local function ActivationApp(self)

  if 
    notificationState.VRSession == true then
      self.hmiConnection:SendNotification("VR.Stopped", {})
  elseif 
    notificationState.EmergencyEvent == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
  elseif
    notificationState.PhoneCall == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
 elseif
    notificationState.DeactivateHMI == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
  end

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
                  --TODO: comment until resolving APPLINK-16094
                -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                      :Times(2)
                      end)

        end
          end)

  end

local function SUSPEND(self, targetLevel)

   if 
      targetLevel == "FULL" and
      self.hmiLevel ~= "FULL" then
            ActivationApp(self)
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
              :Do(function(_,data)
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                --hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
              end)
    elseif 
      targetLevel == "LIMITED" and
      self.hmiLevel ~= "LIMITED" then
        if self.hmiLevel ~= "FULL" then
          ActivationApp(self)
          EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
              if exp.occurences == 2 then
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                --hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
              end
            end)

            --hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        else 
            --hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

            EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                --hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
            end)
        end
    elseif 
      (targetLevel == "LIMITED" and
      self.hmiLevel == "LIMITED") or
      (targetLevel == "FULL" and
      self.hmiLevel == "FULL") or
      targetLevel == nil then
        self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
          {
            reason = "SUSPEND"
          })

        --hmi side: expect OnSDLPersistenceComplete notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
    end

end


local function CloseSessionCheckLevel(self, targetLevel)
  if 
    targetLevel == "FULL" and
    self.hmiLevel ~= "FULL" then
          ActivationApp(self)

          EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(_,data)
              self.mobileSession:Stop()
              EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
            end)
  elseif 
    targetLevel == "LIMITED" and
    self.hmiLevel ~= "LIMITED" then

      if self.hmiLevel ~= "FULL" then
        ActivationApp(self)
        EXPECT_NOTIFICATION("OnHMIStatus",
          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
          :Do(function(exp,data)
            if exp.occurences == 2 then
              self.mobileSession:Stop()
              EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
            end
          end)

          --hmi side: sending BasicCommunication.OnAppDeactivated notification
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
      else 
          --hmi side: sending BasicCommunication.OnAppDeactivated notification
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

          EXPECT_NOTIFICATION("OnHMIStatus",
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
          :Do(function(exp,data)
              self.mobileSession:Stop()
              EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
          end)
      end
  elseif 
    (targetLevel == "LIMITED" and
    self.hmiLevel == "LIMITED") or
    (targetLevel == "FULL" and
    self.hmiLevel == "FULL") then
      self.mobileSession:Stop()
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
  end

  DelayedExp(1000)
end

local function IGN_OFF_START_SDL_CONNECTION_SESSION(self, prefix, level)

  if level == nil then
    level = "FULL"
  end

  Test["SUSPEND_" .. tostring(prefix)] = function(self)
    userPrint(35, "================= Precondition ==================")
    SUSPEND(self, level)
  end

  Test["IGNITION_OFF_" .. tostring(prefix)] = function(self)
    IGNITION_OFF(self)
  end

  Test["StartSDL_" .. tostring(prefix)] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["InitHMI_" .. tostring(prefix)] = function(self)
    self:initHMI()
  end

  Test["InitHMI_onReady_" .. tostring(prefix)] = function(self)
    self:initHMI_onReady()
  end

  Test["ConnectMobile_" .. tostring(prefix)] = function(self)
    self:connectMobile()
  end

  Test["StartSession_" .. tostring(prefix)] = function(self)
     self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection,
        config.application1.registerAppInterfaceParams)
  end

end

local function CloseSessionStartSession(self, prefix, level)

  if level == nil then
    level = "FULL"
  end

  Test["CloseSession_" .. tostring(prefix)] = function(self)
    userPrint(35, "================= Precondition ==================")
    CloseSessionCheckLevel(self, level)
  end

  Test["StartSession_" .. tostring(prefix)] = function(self)
   self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
  end

end

--////////////////////////////////////////////////////////////////////////////////////////////--
--Resumption after ignition_off , FULL HMIlevel
--////////////////////////////////////////////////////////////////////////////////////////////--

  function Test:ActivationApp()
    userPrint(35, "================= Precondition ==================")

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
  		            	--TODO: comment until resolving APPLINK-16094
  	    			  	-- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
  							        :Times(2)
  			              	end)

  				end
  		      end)

  		--mobile side: expect OnHMIStatus notification
	  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})	
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)

  	end

  --======================================================================================--
  --Resumption without postponing
  --======================================================================================--

  --Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
  IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_FULL")

  function Test:Resumption_FULL()
    userPrint(34, "=================== Test Case ===================")

  	self.mobileSession:StartService(7)
     	:Do(function(_,data)
     		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
     		--got time after RAI request
     		local time =  timestamp()

     		local RAIAfterOnReady = time - self.timeOnReady
     		userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

     		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
     			:Do(function(_,data)
     				HMIAppID = data.params.application.appID
     				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
     			end)

        self.mobileSession:ExpectResponse(correlationId, { success = true })

        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        	:Do(function(_,data)
        		--hmi side: sending BasicCommunication.ActivateApp response
  	          	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        	end)

        EXPECT_NOTIFICATION("OnHMIStatus", 
        	{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        	AppValuesOnHMIStatusFULL)
        	:ValidIf(function(exp,data)
        		if	exp.occurences == 2 then 
        		local time2 =  timestamp()
        		local timeToresumption = time2 - time
  	      		if timeToresumption >= 3000 and
  	      		 timeToresumption < 3500 then 
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
  	      			return true
  	      		else 
  	      			userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

     	end)
  end

--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped in 3 seconds after RAI request
------------------------------------------------------------------------------------------

--Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionActive_VRStoppedIn3sec")

function Test:ResumptionHMIlevelFULL_VRsessionActive_VRStoppedIn3sec()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Stopped", {})
            notificationState.VRSession = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

--Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionActive_VRStoppedAfter30seconds")

function Test:ResumptionHMIlevelFULL_VRsessionActive_VRStoppedAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
              notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot))
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot))
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
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

--Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionActive_VRStoppedBefore30seconds")

function Test:ResumptionHMIlevelFULL_VRsessionActive_VRStoppedBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                  timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot))
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped in 3 seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec")

function Test:ResumptionHMIlevelFULL_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Started", {})
	           notificationState.VRSession = true
            local function to_run()
              self.hmiConnection:SendNotification("VR.Stopped", {})
	           notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 700)
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionStartedAfterDefaultHMILevel_VRStoppedAfter30seconds")

function Test:ResumptionHMIlevelFULL_VRsessionStartedAfterDefaultHMILevel_VRStoppedAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return false
               end

            elseif exp.occurences == 1 then
               return true
         end
         end)
        :Do(function(exp,data)
          self.hmiLevel = data.payload.hmiLevel
          if exp.occurences == 1 then
            local timeDefaultHMILevel = timestamp()
            timeFromRequestToNot = timeDefaultHMILevel - time
            self.hmiConnection:SendNotification("VR.Started", {})
	           notificationState.VRSession = true
            local function to_run()
              self.hmiConnection:SendNotification("VR.Stopped", {})
	           notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
            end
        end)
        :Times(2)
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionStartedAfterRAIResponse_VRStoppedBefore30seconds")

function Test:ResumptionHMIlevelFULL_VRsessionStartedAfterRAIResponse_VRStoppedBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("VR.Started", {})
	           notificationState.VRSession = true
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("VR.Stopped", {})
	           notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) ) 
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end
--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came in 3 seconds after registration
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventActive_falseIn3sec")

function Test:ResumptionHMIlevelFULL_EmergencyEventActive_falseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 3000 and
                timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return false
               end

            elseif exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
              return true
          end
         end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
        :Times(2)
      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventActive_falseAfter30seconds")

function Test:ResumptionHMIlevelFULL_EmergencyEventActive_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then 
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventActive_falseBefore30seconds")

function Test:ResumptionHMIlevelFULL_EmergencyEventActive_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) ) 
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came in seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseIn3sec")

function Test:ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseIn3sec()

  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            if exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
              local function to_run()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
              end

              RUN_AFTER(to_run, 700)
            end
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseAfter30seconds")

function Test:ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
            local function to_run()
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                timeToresumption < 46000 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseBefore30seconds")

function Test:ResumptionHMIlevelFULL_EmergencyEventAfterRAIResponse_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                  timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChanged(DEACTIVATE_HMI)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(DEACTIVATE_HMI=true) came before RAI request, OnEventChanged(DEACTIVATE_HMI=false) came in 3 seconds after RAI request after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionFULL_DeactivateHMIActiveAndfalseIn3sec")

function Test:ResumptionFULL_DeactivateHMIActiveAndfalseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
	notificationState.DeactivateHMI = true

   self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
	             notificationState.DeactivateHMI = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(DEACTIVATE_HMI=true) came before RAI request, OnEventChanged(DEACTIVATE_HMI=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionFULL_DeactivateHMIActiveAndfalseAfter30sec")

function Test:ResumptionFULL_DeactivateHMIActiveAndfalseAfter30sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
	 notificationState.DeactivateHMI = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
	             notificationState.DeactivateHMI = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)


      if 
         config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 44700 and
                   timeToresumption < 46000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
         :Timeout(47000)

      elseif
            config.application1.registerAppInterfaceParams.isMediaApplication == false then
           EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(DEACTIVATE_HMI=true) came before RAI request, OnEventChanged(DEACTIVATE_HMI=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionFULL_DeactivateHMIActiveAndfalseBefore30sec")

function Test:ResumptionFULL_DeactivateHMIActiveAndfalseBefore30sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
	   notificationState.DeactivateHMI = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
	             notificationState.DeactivateHMI = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

         if config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 14700 and
                      timeToresumption < 16000 + timeFromRequestToNot then
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
            :Timeout(17000)
       elseif
         config.application1.registerAppInterfaceParams.isMediaApplication == false then

            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came in 3 seconds after RAI request after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallActive_falseIn3sec")

function Test:ResumptionHMIlevelFULL_PhoneCallActive_falseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallActive_falseAfter30seconds")

function Test:ResumptionHMIlevelFULL_PhoneCallActive_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	 notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)


      if 
         config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 44700 and
                   timeToresumption < 46000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
         :Timeout(47000)

      elseif
            config.application1.registerAppInterfaceParams.isMediaApplication == false then
           EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallActive_falseBefore30seconds")

function Test:ResumptionHMIlevelFULL_PhoneCallActive_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	   notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

         if config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 14700 and
                      timeToresumption < 16000 + timeFromRequestToNot then
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
            :Timeout(17000)
       elseif
         config.application1.registerAppInterfaceParams.isMediaApplication == false then

            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false) came in 3 seconds after RAI request after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falsein3sec")

function Test:ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falsein3sec()

   userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            if exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

	             notificationState.PhoneCall = true
              local function to_run()
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
              end

              RUN_AFTER(to_run, 700)
            end
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falseAfter30seconds")


function Test:ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falseAfter30seconds()

  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 35000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(37000)

        if 
          config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 34700 and
                      timeToresumption < 36000 +timeFromRequestToNot then 
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(35000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(35000+timeFromRequestToNot) )
                        return false
                     end

                  elseif exp.occurences == 1 then
                    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                     return true
                end
               end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(37000)
        elseif 
          config.application1.registerAppInterfaceParams.isMediaApplication == false then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
        end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false)) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falseBefore30seconds")

function Test:ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 15000)
         end)


      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 14700 and
                   timeToresumption < 16000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return false
                  end

               elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                  return true
              end
            end)
            :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(17000)
      elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            AppValuesOnHMIStatusFULL)
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return false
                end

              elseif exp.occurences == 1 then
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                return true
              end
            end)
            :Do(function(_,data)
              self.hmiLevel = data.payload.hmiLevel
            end)
            :Times(2)
      end

      end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true), OnEventChanged(EMERGENCY_EVENT=true), VR.Started, OnEventChange(PHONE_CALL=false) at the same time
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallEmergencyEventVRStarted_IGN_OFF")

function Test:ResumptionHMIlevelFULL_PhoneCallEmergencyEventVRStarted_IGN_OFF()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
     notificationState.PhoneCall = true

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
    notificationState.EmergencyEvent = true

  self.hmiConnection:SendNotification("VR.Started", {})
    notificationState.VRSession = true


   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run_PhoneCall()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
               notificationState.PhoneCall = false
            end

            local function to_run_VRStopped()
               self.hmiConnection:SendNotification("VR.Stopped", {})
                notificationState.VRSession = false
            end

            local function to_run_EmergencyEvent()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
               notificationState.EmergencyEvent = false
            end

          RUN_AFTER(to_run_VRStopped, 5000)
          RUN_AFTER(to_run_PhoneCall, 10000)
          RUN_AFTER(to_run_EmergencyEvent, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 14700 and
                      timeToresumption < 16000 + timeFromRequestToNot then
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
            :Timeout(17000)

      end)
end

if  
  config.application1.registerAppInterfaceParams.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then 

-- ////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption after ignition_off , LIMITED HMIlevel
-- ////////////////////////////////////////////////////////////////////////////////////////////--

function Test:Precondition_DeactivateToLimited_ResumptionByIGN_OFF()
  userPrint(35, "================= Precondition ==================")
  if 
    self.hmiLevel ~= "FULL" and
    self.hmiLevel ~= "LIMITED" then
      ActivationApp(self)

      EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
          :Times(2)
    else 
        EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
    end

   --hmi side: sending BasicCommunication.OnAppDeactivated notification
   self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
end


--======================================================================================--
--Resumption without postponing
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_LIMITED", "LIMITED")

function Test:Resumption_LIMITED()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end

--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped in 3 seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedIn3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedIn3sec()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedAfter30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
	  notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot))
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot))
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
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request, VR.Stopped came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedBefore30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_VRsessionActive_VRStoppedBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
	  notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                  timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot))
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped in 3 seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true
            local function to_run()
              self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 700)
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionStartedAfterDefaultHMILevel_VRStoppedAfter30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_VRsessionStartedAfterDefaultHMILevel_VRStoppedAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return false
               end

            elseif exp.occurences == 1 then
               return true
         end
         end)
        :Do(function(exp,data)
          self.hmiLevel = data.payload.hmiLevel
          if exp.occurences == 1 then
            local timeDefaultHMILevel = timestamp()
            timeFromRequestToNot = timeDefaultHMILevel - time
            self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true
            local function to_run()
              self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
            end
        end)
        :Times(2)
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionStartedAfterRAIResponse_VRStoppedBefore30seconds", "LIMITED")


function Test:ResumptionHMIlevelLIMITED_VRsessionStartedAfterRAIResponse_VRStoppedBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) ) 
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came in 3 seconds after registration
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventActive_falseIn3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventActive_falseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	  notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 3000 and
                timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return false
               end

            elseif exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
              return true
          end
         end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
        :Times(2)
      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventActive_falseAfter30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventActive_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	  notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then 
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request, OnEventChanged(EMERGENCY_EVENT=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventActive_falseBefore30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventActive_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	  notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                  timeToresumption < 16000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false came in seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseIn3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseIn3sec()

  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            if exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
              local function to_run()
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
              end

              RUN_AFTER(to_run, 700)
            end
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseAfter30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
            local function to_run()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                timeToresumption < 46000 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseBefore30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_EmergencyEventAfterRAIResponse_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
           notificationState.EmergencyEvent = true
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 14700 and
                timeToresumption < 16000 + timeFromRequestToNot then
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
        :Timeout(17000)

      end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came in 3 seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallActive_falseIn3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallActive_falseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	 notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallActive_falseAfter30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallActive_falseAfter30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	 notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
              HMIAppID = data.params.application.appID
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)


      if 
         config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 44700 and
                   timeToresumption < 46000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
         :Timeout(47000)

      elseif
            config.application1.registerAppInterfaceParams.isMediaApplication == false then
           EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallActive_falseBefore30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallActive_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	 notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
              HMIAppID = data.params.application.appID
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

         if config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 14700 and
                      timeToresumption < 16000 + timeFromRequestToNot then
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
            :Timeout(17000)
       elseif
         config.application1.registerAppInterfaceParams.isMediaApplication == false then

            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false) came in 3 seconds after RAI request
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falsein3sec", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falsein3sec()

   userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            if exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
              local function to_run()
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
              end

              RUN_AFTER(to_run, 700)
            end
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false) came after 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falseAfter30seconds", "LIMITED")


function Test:ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falseAfter30seconds()

  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 35000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(37000)

        if 
          config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 34700 and
                      timeToresumption < 36000 +timeFromRequestToNot then 
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(35000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(35000+timeFromRequestToNot) )
                        return false
                     end

                  elseif exp.occurences == 1 then
                    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                     return true
                end
               end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(37000)
        elseif 
          config.application1.registerAppInterfaceParams.isMediaApplication == false then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000" )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                 self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
        end

      end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request, OnEventChange(PHONE_CALL=false) came before 30 seconds after IGNITION_OFF
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falseBefore30seconds", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse_falseBefore30seconds()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
         userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 15000)
         end)


      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 14700 and
                   timeToresumption < 16000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return false
                  end

               elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                  return true
              end
            end)
            :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(17000)
      elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return false
                end

              elseif exp.occurences == 1 then
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = true
                return true
              end
            end)
            :Do(function(_,data)
              self.hmiLevel = data.payload.hmiLevel
            end)
            :Times(2)
      end

      end)
  end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true), OnEventChanged(EMERGENCY_EVENT=true), VR.Started, OnEventChange(PHONE_CALL=false) at the same time
------------------------------------------------------------------------------------------

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallEmergencyEventVRStarted_IGN_OFF", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallEmergencyEventVRStarted_IGN_OFF()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run_PhoneCall()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
               notificationState.PhoneCall = false
            end

            local function to_run_VRStopped()
               self.hmiConnection:SendNotification("VR.Stopped", {})
                notificationState.VRSession = false
            end

            local function to_run_EmergencyEvent()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
               notificationState.EmergencyEvent = false
            end

          RUN_AFTER(to_run_VRStopped, 5000)
          RUN_AFTER(to_run_PhoneCall, 10000)
          RUN_AFTER(to_run_EmergencyEvent, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

            EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 14700 and
                   timeToresumption < 16000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return false
                  end

               elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
                  notificationState.PhoneCall = true

                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
                  notificationState.EmergencyEvent = true

                  self.hmiConnection:SendNotification("VR.Started", {})
                  notificationState.VRSession = true
                  return true
              end
            end)
            :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(17000)

      end)
end
end

--////////////////////////////////////////////////////////////////////////////////////////////--
--Resumption after disconnect , FULL HMIlevel
--////////////////////////////////////////////////////////////////////////////////////////////--

function Test:ActivationApp()
  userPrint(35, "================= Precondition ==================")

    if self.hmiLevel ~= "FULL" then
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
                    --TODO: comment until resolving APPLINK-16094
                  -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                        :Times(2)
                        end)

          end
            end)

      --mobile side: expect OnHMIStatus notification
        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
    end

  end


--======================================================================================--
--Resumption without postponing
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "Resumption_FULL_disconnect")
-----------------------------------------------------------------------------------------

function Test:Resumption_FULL_disconnect() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then
             userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end


--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_VRsessionActive")

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_VRsessionActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
	 notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
            notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then 
             userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_VRsessionStartedAfterRAIResponse")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_VRsessionStartedAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Timeout(37000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 34700 and
             timeToresumption < 36000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " ) 
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true
            return true
          end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
        :Times(2)
        :Timeout(37000)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request, VR.Stopped in 3 seconds after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_VRsessionStartedAfterDefaultHMILevel_VRStoppedIn3sec()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Started", {})
            notificationState.VRSession = true
            local function to_run()
              self.hmiConnection:SendNotification("VR.Stopped", {})
              notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 700)
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_EmergencyEventActive")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_EmergencyEventActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	notificationState.EmergencyEvent = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_EmergencyEventAfterRAIResponse")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_EmergencyEventAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Timeout(37000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 34700 and
             timeToresumption < 36000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
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
        :Timeout(37000)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request, OnEventChanged(EMERGENCY_EVENT=false) came in seconds after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_EmergencyEventAfterRAIResponse_falseIn3sec")

-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_EmergencyEventAfterRAIResponse_falseIn3sec()

  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            if exp.occurences == 1 then
              self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
              notificationState.EmergencyEvent = true
              local function to_run()
                self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
                notificationState.EmergencyEvent = false
              end

              RUN_AFTER(to_run, 700)
            end
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end



--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_PhoneCallActive")
------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_PhoneCallActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	notificationState.PhoneCall = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)


      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
        EXPECT_NOTIFICATION("OnHMIStatus", 
          {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
          AppValuesOnHMIStatusFULL)
          :ValidIf(function(exp,data)
            if  exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
              if timeToresumption >= 4900 and
               timeToresumption < 6000 then
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
                return true
              else 
                userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
          :Timeout(37000)
     elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then

           EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            AppValuesOnHMIStatusFULL)
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
    end

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request, OnEventChange(PHONE_CALL=false) came in 3 seconds after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_PhoneCallActive_falseIn3sec")

-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_PhoneCallActive_falseIn3sec()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
  notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
            notificationState.PhoneCall = false
            return true
        end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
      :Times(2)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true)) came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_PhoneCallAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Timeout(37000)

        if 
          config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              AppValuesOnHMIStatusFULL)
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 34700 and
                   timeToresumption < 36000 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
              :Timeout(37000)
        elseif 
          config.application1.registerAppInterfaceParams.isMediaApplication == false then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              AppValuesOnHMIStatusFULL)
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
        end

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true), OnEventChanged(EMERGENCY_EVENT=true), VR.Started, OnEventChange(PHONE_CALL=false) at the same time
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_PhoneCallEmergencyEventVRStarted_Disconnect")
-----------------------------------------------------------------------------------------


function Test:ResumptionHMIlevelFULL_PhoneCallEmergencyEventVRStarted_Disconnect()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
     notificationState.PhoneCall = true

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
    notificationState.EmergencyEvent = true

  self.hmiConnection:SendNotification("VR.Started", {})
    notificationState.VRSession = true


   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run_PhoneCall()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
               notificationState.PhoneCall = false
            end

            local function to_run_VRStopped()
               self.hmiConnection:SendNotification("VR.Stopped", {})
                notificationState.VRSession = false
            end

            local function to_run_EmergencyEvent()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
               notificationState.EmergencyEvent = false
            end

          RUN_AFTER(to_run_VRStopped, 5000)
          RUN_AFTER(to_run_PhoneCall, 10000)
          RUN_AFTER(to_run_EmergencyEvent, 15000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

            EXPECT_NOTIFICATION("OnHMIStatus", 
               {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
               {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
               :ValidIf(function(exp,data)
                  if exp.occurences == 2 then 
                  local time2 =  timestamp()
                  local timeToresumption = time2 - time
                     if timeToresumption >= 14700 and
                      timeToresumption < 16000 + timeFromRequestToNot then
                        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                        return true
                     else 
                        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
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
            :Timeout(17000)

      end)
end


if 
  config.application1.registerAppInterfaceParams.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then 
--======================================================================================--
--Resumption without postponing
--======================================================================================--
function Test:Precondition_DeactivateToLimited()
  userPrint(35, "================= Precondition ==================")
  if 
    self.hmiLevel ~= "FULL" and
    self.hmiLevel ~= "LIMITED" then
      ActivationApp(self)

      EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
          :Times(2)
    else 
        EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
    end

     --hmi side: sending BasicCommunication.OnAppDeactivated notification
     self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
end

--Precondition: Close session, open session
CloseSessionStartSession(self, "Resumption_LIMITED_disconnect", "LIMITED")

function Test:Resumption_LIMITED_disconnect() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end


--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_VRsessionActive", "LIMITED")

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_VRsessionActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
	notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then 
             userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_VRsessionStartedAfterRAIResponse", "LIMITED")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_VRsessionStartedAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
	             notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(37000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 34700 and
             timeToresumption < 36000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " ) 
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
              return false
            end

          elseif exp.occurences == 1 then
            self.hmiConnection:SendNotification("VR.Started", {})
	             notificationState.VRSession = true
            return true
          end
        end)
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
        :Times(2)
        :Timeout(37000)

    end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventActive", "LIMITED")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	notificationState.EmergencyEvent = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventAfterRAIResponse", "LIMITED")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = true
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
	             notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(37000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 34700 and
             timeToresumption < 36000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
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
        :Timeout(37000)

    end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_PhoneCallActive", "LIMITED")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_PhoneCallActive()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	 notificationState.PhoneCall = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})


      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
        EXPECT_NOTIFICATION("OnHMIStatus", 
          {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
          AppValuesOnHMIStatusLIMITED)
          :ValidIf(function(exp,data)
            if  exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
              if timeToresumption >= 4900 and
               timeToresumption < 6000 then
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
                return true
              else 
                userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
          :Timeout(37000)
     elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then

           EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            AppValuesOnHMIStatusLIMITED)
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
    end

    end)
end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came after RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse", "LIMITED")
-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_PhoneCallAfterRAIResponse()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	             notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 35000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(37000)

        if 
          config.application1.registerAppInterfaceParams.isMediaApplication == true then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              AppValuesOnHMIStatusLIMITED)
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 34700 and
                   timeToresumption < 36000 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~35000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
              :Timeout(37000)
        elseif 
          config.application1.registerAppInterfaceParams.isMediaApplication == false then
            EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              AppValuesOnHMIStatusLIMITED)
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                    return false
                  end

                elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
	                 notificationState.PhoneCall = true
                  return true
                end
              end)
              :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
              :Times(2)
        end

    end)
  end


------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true), OnEventChanged(EMERGENCY_EVENT=true), VR.Started, OnEventChange(PHONE_CALL=false) at the same time
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_PhoneCallEmergencyEventVRStarted_Disconnect", "LIMITED")

-----------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_PhoneCallEmergencyEventVRStarted_Disconnect()
  userPrint(34, "=================== Test Case ===================")

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run_PhoneCall()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
               notificationState.PhoneCall = false
            end

            local function to_run_VRStopped()
               self.hmiConnection:SendNotification("VR.Stopped", {})
                notificationState.VRSession = false
            end

            local function to_run_EmergencyEvent()
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
               notificationState.EmergencyEvent = false
            end

          RUN_AFTER(to_run_VRStopped, 5000)
          RUN_AFTER(to_run_PhoneCall, 10000)
          RUN_AFTER(to_run_EmergencyEvent, 15000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(17000)

            EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 14700 and
                   timeToresumption < 16000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(15000+timeFromRequestToNot) )
                     return false
                  end

               elseif exp.occurences == 1 then
                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
                  notificationState.PhoneCall = true

                  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
                  notificationState.EmergencyEvent = true

                  self.hmiConnection:SendNotification("VR.Started", {})
                  notificationState.VRSession = true
                  return true
              end
            end)
            :Do(function(_,data)
                self.hmiLevel = data.payload.hmiLevel
              end)
            :Times(2)
            :Timeout(17000)

      end)
end

end


------------------------------------------------------------------------------------------
--Resumption is abcent in case app is disconnected in more then 30 before ignition_off
------------------------------------------------------------------------------------------

function Test:SUSPEND_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  userPrint(35, "================= Precondition ==================")
  if self.hmiLevel ~= "FULL" then
    ActivationApp(self)

    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
      :Do(function(_,data)
        self.mobileSession:Stop()
      end)
  else 
    self.mobileSession:Stop()
  end

    local function to_run()
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
          {
            reason = "SUSPEND"
          })
    end

    RUN_AFTER(to_run, 33000)

    --hmi side: expect OnSDLPersistenceComplete notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
      :Timeout(36000)

end

function Test:IGNITION_OFF_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  StopSDL()
  --hmi side: sends OnExitAllApplications (SUSPENDED)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
   EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
   :Times(0)

end

function Test:StartSDL_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  print("Start SDL")
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  self:initHMI()
end

function Test:InitHMI_onReady_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  self:initHMI_onReady()
end

function Test:ConnectMobile_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
  self:connectMobile()
end

function Test:StartSession_Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
   self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)

end

--======================================================================================--
--Resumption is absent because App is disconnected in more than 30 seconds before IGNITION_OFF
--======================================================================================--
function Test:Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      print(" Time after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Times(0)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)

      DelayedExp(5000)

    end)
end

  function Test:ActivationApp()
    userPrint(35, "================= Precondition ==================")

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
                  --TODO: comment until resolving APPLINK-16094
                -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                      :Times(2)
                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)

  end


--======================================================================================--
--Resumption is absent because App is disconnected in more than 30 seconds after IGNITION_OFF
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecAfterIGNOFF")
------------------------------------------------------------------------------------------

function Test:Resumption_FULL_is_absent_AppIsDisconnectedInMoreThen30SecAfterIGNOFF() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)

      local function to_run()
        local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

        self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      end

      RUN_AFTER(to_run, 33000)


      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)
        :Timeout(35000)


      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Times(0)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
        :Timeout(35000)

      DelayedExp(50000)

    end)
end

if 
  config.application1.registerAppInterfaceParams.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then 

    function Test:BringAppToLimited_CheckResumptionByIGN_OFF()
      userPrint(35, "================= Precondition ==================")

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
                      --TODO: comment until resolving APPLINK-16094
                    -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                          :Times(2)
                          end)

            end
              end)

        --mobile side: expect OnHMIStatus notification
          EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 
            :Do(function(exp,data)  
              if exp.occurences == 1 then
                --hmi side: sending BasicCommunication.OnAppDeactivated notification
                self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
              end
                self.hmiLevel = data.payload.hmiLevel
            end)
            :Times(2)

      end

      function Test:SUSPEND_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      if self.hmiLevel ~= "FULL" and
        self.hmiLevel ~= "LIMITED" then
        ActivationApp(self)

        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 
            :Do(function(exp,data)  
              if exp.occurences == 1 then
                --hmi side: sending BasicCommunication.OnAppDeactivated notification
                self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
              elseif
                exp.occurences == 2 then
                  self.hmiLevel = data.payload.hmiLevel
                  self.mobileSession:Stop()
              end
                self.hmiLevel = data.payload.hmiLevel
            end)
            :Times(2)
      elseif self.hmiLevel == "FULL" then
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 
            :Do(function(exp,data)  
                self.hmiLevel = data.payload.hmiLevel
                self.mobileSession:Stop()
            end)

      else 
        self.mobileSession:Stop()
      end

        local function to_run()
          self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
              {
                reason = "SUSPEND"
              })
        end

        RUN_AFTER(to_run, 33000)

        --hmi side: expect OnSDLPersistenceComplete notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
          :Timeout(36000)

    end

    function Test:IGNITION_OFF_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      StopSDL()
      --hmi side: sends OnExitAllApplications (SUSPENDED)
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
        {
          reason = "IGNITION_OFF"
        })

      -- hmi side: expect OnSDLClose notification
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

      -- hmi side: expect OnAppUnregistered notification
       EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
       :Times(0)

    end

    function Test:StartSDL_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      print("Start SDL")
      StartSDL(config.pathToSDL, config.ExitOnCrash)
    end

    function Test:InitHMI_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      self:initHMI()
    end

    function Test:InitHMI_onReady_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      self:initHMI_onReady()
    end

    function Test:ConnectMobile_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      self:connectMobile()
    end

    function Test:StartSession_Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
       self.mobileSession = mobile_session.MobileSession(
          self,
          self.mobileConnection,
          config.application1.registerAppInterfaceParams)

    end

    --======================================================================================--
    --Resumption is absent because App is disconnected in more than 30 seconds before IGNITION_OFF
    --======================================================================================--
    function Test:Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF()
      userPrint(34, "=================== Test Case ===================")

      self.mobileSession:StartService(7)
        :Do(function(_,data)
          local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

          EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
            :Do(function(_,data)
              HMIAppID = data.params.application.appID
              self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

          self.mobileSession:ExpectResponse(correlationId, { success = true })

          EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
            :Times(0)

          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
            :Do(function(_,data)
              self.hmiLevel = data.payload.hmiLevel
            end)

          DelayedExp(5000)

        end)
    end

    function Test:BringAppToLimited_AbsenceResumptionByIGN_OFF()
      userPrint(35, "================= Precondition ==================")

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
                      --TODO: comment until resolving APPLINK-16094
                    -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                          :Times(2)
                          end)

            end
              end)

        --mobile side: expect OnHMIStatus notification
          EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 
            :Do(function(exp,data)  
              if exp.occurences == 1 then
                --hmi side: sending BasicCommunication.OnAppDeactivated notification
                self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
              end
                self.hmiLevel = data.payload.hmiLevel
            end)
            :Times(2)

      end

    -- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
    IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecAfterIGNOFF", "LIMITED")

    --======================================================================================--
    --Resumption is absent because App is disconnected in more than 30 seconds after IGNITION_OFF
    --======================================================================================--
    function Test:Resumption_LIMITED_is_absent_AppIsDisconnectedInMoreThen30SecAfterIGNOFF()
      userPrint(34, "=================== Test Case ===================")

      self.mobileSession:StartService(7)
        :Do(function(_,data)

          local function to_run()
            local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
          end

          RUN_AFTER(to_run, 33000)


          EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
            :Do(function(_,data)
              HMIAppID = data.params.application.appID
              self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)
            :Timeout(35000)


          EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
            :Times(0)

          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
            :Do(function(_,data)
              self.hmiLevel = data.payload.hmiLevel
            end)
            :Timeout(35000)

          DelayedExp(40000)

        end)
    end
end

 function Test:ActivationApp()
    userPrint(35, "================= Precondition ==================")

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
                  --TODO: comment until resolving APPLINK-16094
                -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                      :Times(2)
                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)

  end

function Test:UnregisterAppInterface_Success() 

  --mobile side: UnregisterAppInterface request 
  local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

  --hmi side: expected  BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})

  --mobile side: UnregisterAppInterface response 
  EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})

end


--======================================================================================--
--Resumption is absent after expected disconnect
--======================================================================================--
function Test:Resumption_is_absent_AfterExpectedDisconnect()
  userPrint(34, "=================== Test Case ===================") 

    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

    self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })


    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
        HMIAppID = data.params.application.appID
        self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
      end)


    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
      :Times(0)

    EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Times(0)

    EXPECT_NOTIFICATION("OnHMIStatus", 
      {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
      :Do(function(_,data)
        self.hmiLevel = data.payload.hmiLevel
      end)

    DelayedExp(5000)

end

--======================================================================================--
--Resumption with postponing in case registered app already exist
--======================================================================================--

-- ////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption after ignition_off , FULL HMIlevel
-- ////////////////////////////////////////////////////////////////////////////////////////////--

function Test:ActivationApp()
    userPrint(35, "================= Precondition ==================")

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
                    --TODO: comment until resolving APPLINK-16094
                  -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                        :Times(2)
                        end)

          end
            end)

      --mobile side: expect OnHMIStatus notification
        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)

    end

  --======================================================================================--
  --Resumption without postponing
  --======================================================================================--
  -- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
    IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_FULL_withRegisteredApp")

  function Test:Resumption_FULL_withRegisteredApp()
    userPrint(34, "=================== Test Case ===================")

    self.mobileSession:StartService(7)
      :Do(function(_,data)
        local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
        --got time after RAI request
        local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
          :Do(function(_,data)
            HMIAppID = data.params.application.appID
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
          end)

        self.mobileSession:ExpectResponse(correlationId, { success = true })

        EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)

        EXPECT_NOTIFICATION("OnHMIStatus", 
          {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
          AppValuesOnHMIStatusFULL)
          :ValidIf(function(exp,data)
            if  exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
              if timeToresumption >= 3000 and
               timeToresumption < 3500 then 
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                return true
              else 
                userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

      end)
  end


--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_VRsessionActive_withRegisteredApp")

function Test:ResumptionHMIlevelFULL_VRsessionActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
  notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
              notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_EmergencyEventActive_withRegisteredApp")

function Test:ResumptionHMIlevelFULL_EmergencyEventActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
    notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
                notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusFULL)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then 
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelFULL_PhoneCallActive_withRegisteredApp")

function Test:ResumptionHMIlevelFULL_PhoneCallActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
    notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
                notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(47000)


      if 
         config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 44700 and
                   timeToresumption < 46000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
         :Timeout(47000)

      elseif
            config.application1.registerAppInterfaceParams.isMediaApplication == false then
           EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
end

if 
  config.application1.registerAppInterfaceParams.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then 

-- ////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption after ignition_off , LIMITED HMIlevel
-- ////////////////////////////////////////////////////////////////////////////////////////////--

function Test:Precondition_DeactivateToLimited()
  userPrint(35, "================= Precondition ==================")
  if 
    self.hmiLevel ~= "FULL" and
    self.hmiLevel ~= "LIMITED" then
      ActivationApp(self)

      EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
          :Times(2)
    else 
        EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
    end

   --hmi side: sending BasicCommunication.OnAppDeactivated notification
   self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
end

--======================================================================================--
--Resumption without postponing
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "Resumption_LIMITED_withRegisteredApp", "LIMITED")

function Test:Resumption_LIMITED_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end

--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_VRsessionActive_withRegisteredApp", "LIMITED")


function Test:ResumptionHMIlevelLIMITED_VRsessionActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("VR.Started", {})
    notificationState.VRSession = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

        local RAIAfterOnReady = time - self.timeOnReady
        userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
              self.hmiConnection:SendNotification("VR.Stopped", {})
                notificationState.VRSession = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_EmergencyEventActive_withRegisteredApp", "LIMITED")


function Test:ResumptionHMIlevelLIMITED_EmergencyEventActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
    notificationState.EmergencyEvent = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
                notificationState.EmergencyEvent = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)

      EXPECT_NOTIFICATION("OnHMIStatus", 
         {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
         AppValuesOnHMIStatusLIMITED)
         :ValidIf(function(exp,data)
            if exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
               if timeToresumption >= 44700 and
                  timeToresumption < 46000 + timeFromRequestToNot then 
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
                  return true
               else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
        :Timeout(47000)

      end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

-- Precondition:IGN_OFF, start SDL, HMI initialization, start mobile connection, session
IGN_OFF_START_SDL_CONNECTION_SESSION(self, "ResumptionHMIlevelLIMITED_PhoneCallActive_withRegisteredApp", "LIMITED")

function Test:ResumptionHMIlevelLIMITED_PhoneCallActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

   self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
    notificationState.PhoneCall = true

   self.mobileSession:StartService(7)
      :Do(function(_,data)
         local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
         --got time after RAI request
         local time =  timestamp()

         local RAIAfterOnReady = time - self.timeOnReady
          userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

         EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
            :Do(function(_,data)
               self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
         :Do(function(_,data)
            local timeRAIResponse = timestamp()
            local function to_run()
              timeFromRequestToNot = timeRAIResponse - time
               self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
                notificationState.PhoneCall = false
            end

            RUN_AFTER(to_run, 45000)
         end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        :Timeout(47000)


      if 
         config.application1.registerAppInterfaceParams.isMediaApplication == true then
          EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :ValidIf(function(exp,data)
               if exp.occurences == 2 then 
               local time2 =  timestamp()
               local timeToresumption = time2 - time
                  if timeToresumption >= 44700 and
                   timeToresumption < 46000 + timeFromRequestToNot then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) ) 
                     return true
                  else 
                     userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~" .. tostring(45000+timeFromRequestToNot) )
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
         :Timeout(47000)

      elseif
            config.application1.registerAppInterfaceParams.isMediaApplication == false then
           EXPECT_NOTIFICATION("OnHMIStatus", 
              {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
              {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
              :ValidIf(function(exp,data)
                if  exp.occurences == 2 then 
                local time2 =  timestamp()
                local timeToresumption = time2 - time
                  if timeToresumption >= 3000 and
                   timeToresumption < 3500 then
                    userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
                    return true
                  else 
                    userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
      end

      end)
  end

end

--////////////////////////////////////////////////////////////////////////////////////////////--
--Resumption after disconnect , FULL HMIlevel
--////////////////////////////////////////////////////////////////////////////////////////////--

function Test:ActivationApp()
  userPrint(35, "================= Precondition ==================")

  if self.hmiLevel ~= "FULL" then
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
                    --TODO: comment until resolving APPLINK-16094
                  -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
                        :Times(2)
                        end)

          end
            end)

      --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
        :Do(function(_,data)
          self.hmiLevel = data.payload.hmiLevel
        end)
    end

  end


--======================================================================================--
--Resumption without postponing
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "Resumption_FULL_disconnect_withRegisteredApp")
-----------------------------------------------------------------------------------------

function Test:Resumption_FULL_disconnect_withRegisteredApp() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      local RAIAfterOnReady = time - self.timeOnReady
      print(" Time after OnReady notification " ..tostring(RAIAfterOnReady))

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end


--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_VRsessionActive_withRegisteredApp")

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_VRsessionActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
  notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
            notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then 
             userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_EmergencyEventActive_withRegisteredApp")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_EmergencyEventActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
  notificationState.EmergencyEvent = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
            notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusFULL)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end


--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelFULL_Disconnect_PhoneCallActive_withRegisteredApp")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelFULL_Disconnect_PhoneCallActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
  notificationState.PhoneCall = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
            notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          --hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)


      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
        EXPECT_NOTIFICATION("OnHMIStatus", 
          {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
          AppValuesOnHMIStatusFULL)
          :ValidIf(function(exp,data)
            if  exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
              if timeToresumption >= 4900 and
               timeToresumption < 6000 then
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
                return true
              else 
                userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
          :Timeout(37000)
     elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then

           EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            AppValuesOnHMIStatusFULL)
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
    end

    end)
end

if 
  config.application1.registerAppInterfaceParams.isMediaApplication == true or
  Test.appHMITypes["NAVIGATION"] == true or
  Test.appHMITypes["COMMUNICATION"] == true then


--======================================================================================--
--Resumption without postponing
--======================================================================================--
function Test:Precondition_DeactivateToLimited_ResumptionByTMDisconnect()
  userPrint(35, "================= Precondition ==================")
  if 
    self.hmiLevel ~= "FULL" and
    self.hmiLevel ~= "LIMITED" then
      ActivationApp(self)

      EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
          :Times(2)
    else 
        EXPECT_NOTIFICATION("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Do(function(_,data)
            self.hmiLevel = data.payload.hmiLevel
          end)
    end

   --hmi side: sending BasicCommunication.OnAppDeactivated notification
   self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
end

-----------------------------------------------------------------------------------------
--Precondition:Close, creation session
CloseSessionStartSession(self, "Resumption_LIMITED_disconnect_withRegisteredApp", "LIMITED")

function Test:Resumption_LIMITED_disconnect_withRegisteredApp() 
  userPrint(34, "=================== Test Case ===================")

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()


      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 3000 and
             timeToresumption < 3500 then 
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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

    end)
end


--======================================================================================--
--Resumption with postponing because of VR.Started 
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_VRsessionActive_withRegisteredApp", "LIMITED")

------------------------------------------------------------------------------------------
--Resumption with postponing: VR.Started came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_VRsessionActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("VR.Started", {})
  notificationState.VRSession = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("VR.Stopped", {})
            notificationState.VRSession = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then 
             userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChanged(EMERGENCY_EVENT)
--======================================================================================--

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventActive_withRegisteredApp", "LIMITED")

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChanged(EMERGENCY_EVENT=true) came before RAI request
------------------------------------------------------------------------------------------

function Test:ResumptionHMIlevelLIMITED_Disconnect_EmergencyEventActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
  notificationState.EmergencyEvent = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
            notificationState.EmergencyEvent = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      EXPECT_NOTIFICATION("OnHMIStatus", 
        {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
        AppValuesOnHMIStatusLIMITED)
        :ValidIf(function(exp,data)
          if  exp.occurences == 2 then 
          local time2 =  timestamp()
          local timeToresumption = time2 - time
            if timeToresumption >= 4900 and
             timeToresumption < 6000 then
              userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
              return true
            else 
              userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
        :Timeout(37000)

    end)
end

--======================================================================================--
--Resumption with postponing because of OnEventChange(PHONE_CALL)
--======================================================================================--

------------------------------------------------------------------------------------------
--Resumption with postponing: OnEventChange(PHONE_CALL=true) came before RAI request
------------------------------------------------------------------------------------------

--Precondition:Close, creation session
CloseSessionStartSession(self, "ResumptionHMIlevelLIMITED_Disconnect_PhoneCallActive_withRegisteredApp", "LIMITED")


function Test:ResumptionHMIlevelLIMITED_Disconnect_PhoneCallActive_withRegisteredApp()
  userPrint(34, "=================== Test Case ===================")

  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
  notificationState.PhoneCall = true

  self.mobileSession:StartService(7)
    :Do(function(_,data)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      --got time after RAI request
      local time =  timestamp()

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
        :Do(function(_,data)
          HMIAppID = data.params.application.appID
          self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
        end)

      self.mobileSession:ExpectResponse(correlationId, { success = true })
        :Do(function(_,data)
          local function to_run()
            self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
            notificationState.PhoneCall = false
          end

          RUN_AFTER(to_run, 5000)
        end)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})


      if 
        config.application1.registerAppInterfaceParams.isMediaApplication == true then
        EXPECT_NOTIFICATION("OnHMIStatus", 
          {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
          AppValuesOnHMIStatusLIMITED)
          :ValidIf(function(exp,data)
            if  exp.occurences == 2 then 
            local time2 =  timestamp()
            local timeToresumption = time2 - time
              if timeToresumption >= 4900 and
               timeToresumption < 6000 then
                userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
                return true
              else 
                userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000 " )
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
          :Timeout(37000)
     elseif
        config.application1.registerAppInterfaceParams.isMediaApplication == false then

           EXPECT_NOTIFICATION("OnHMIStatus", 
            {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
            AppValuesOnHMIStatusLIMITED)
            :ValidIf(function(exp,data)
              if  exp.occurences == 2 then 
              local time2 =  timestamp()
              local timeToresumption = time2 - time
                if timeToresumption >= 3000 and
                 timeToresumption < 3500 then
                  userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
                  return true
                else 
                  userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
    end

    end)
  end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

function Test:Postcondition_RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end
