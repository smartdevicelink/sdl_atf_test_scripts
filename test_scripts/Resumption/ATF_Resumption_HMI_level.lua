-- Script is developed by Byanova Irina
-- for ATF version 2.2

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
local commonSteps	  = require('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')

-- Postcondition: removing user_modules/connecttest_resumption.lua
function Test:Postcondition_remove_user_connecttest()
 	os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

local AppValuesOnHMIStatusFULL 
local AppValuesOnHMIStatusLIMITED
local AppValuesOnHMIStatusDEFAULT
local DefaultHMILevel = "NONE"
local HMIAppID

AppValuesOnHMIStatusDEFAULT = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}

local mobileSessionForBackground = 
	{
		syncMsgVersion =
	    {
	      majorVersion = 3,
	      minorVersion = 3
	    },
	    appName = "AppForBackground",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "NAVIGATION", "COMMUNICATION" },
	    appID = "11223344",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
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

local function BringAppToNoneLevel(self)
	if self.hmiLevel ~= "NONE" then
		-- hmi side: sending BasicCommunication.OnExitApplication request
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName],
				reason = "USER_EXIT"
			})

		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
	end
end

local function CreateSession( self)
	self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

local function IGNITION_OFF(self, appNumber)
	StopSDL()

	if appNumber == nil then 
		appNumber = 1
	end

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "IGNITION_OFF"
		})

	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
		:Times(appNumber)
end

local function ActivationApp(self)

  if 
    notificationState.VRSession == true then
      self.hmiConnection:SendNotification("VR.Stopped", {})
  elseif 
    notificationState.EmergencyEvent == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
  elseif
    notificationState.PhoneCall == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
  end

    -- hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

    -- hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      	:Do(function(_,data)
        -- In case when app is not allowed, it is needed to allow app
          	if
              data.result.isSDLAllowed ~= true then

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

	                          -- hmi side: sending BasicCommunication.ActivateApp response
	                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

	                      end)
	                      :Times(2)
                      end)

        	end
        end)

end

local function BringAppToLimitedLevel(self)
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

 	self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], reason = "GENERAL"})
end

local function BringAppToBackgroundLevel(self)
	if  
	  config.application1.registerAppInterfaceParams.isMediaApplication == true or
	  self.appHMITypes["NAVIGATION"] == true or
	  self.appHMITypes["COMMUNICATION"] == true then 

		  	if 
			    self.hmiLevel == "NONE" then
		      		ActivationApp(self)
		      		EXPECT_NOTIFICATION("OnHMIStatus", 
		      			AppValuesOnHMIStatusFULL,
		      			{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
			      		:Do(function()
			    			local cidUnregister = self.mobileSessionForBackground:SendRPC("UnregisterAppInterface",{})

							EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[mobileSessionForBackground.appName]})

							self.mobileSessionForBackground:ExpectResponse(cidUnregister, { success = true, resultCode = "SUCCESS"})
								:Timeout(2000)
								:Do(function() self.mobileSessionForBackground:Stop() end)
			    		end)
		    else 
		    	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
		    		:Do(function()
		    			local cidUnregister = self.mobileSessionForBackground:SendRPC("UnregisterAppInterface",{})

		    			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[mobileSessionForBackground.appName]})

						self.mobileSessionForBackground:ExpectResponse(cidUnregister, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)
							:Do(function() self.mobileSessionForBackground:Stop() end)
		    		end)
		    end

		    self.mobileSessionForBackground = mobile_session.MobileSession(
	        self,
	        self.mobileConnection,
	        mobileSessionForBackground)


	        self.mobileSessionForBackground:Start()
	        	:Do(function()
	        		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		     			:Do(function(_,data)
		     				self.applications[mobileSessionForBackground.appName] = data.params.application.appID
		     			end)

		     		self.mobileSessionForBackground:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
		     			{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
		     			:Do(function()
		     				-- hmi side: sending SDL.ActivateApp request
						    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[mobileSessionForBackground.appName]})
						 
						 	-- hmi side: expect SDL.ActivateApp response
						    EXPECT_HMIRESPONSE(RequestId)

		     			end)
		     			:Times(2)
	        	end)
	elseif
		config.application1.registerAppInterfaceParams.isMediaApplication == false then

			  	if 
				    self.hmiLevel == "NONE" then
			      		ActivationApp(self)
			      		EXPECT_NOTIFICATION("OnHMIStatus", 
			      			AppValuesOnHMIStatusFULL,
			      			{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
			    else 
			    	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
			    end

			    -- hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						reason = "GENERAL"
					})
	end
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

                -- hmi side: expect OnSDLPersistenceComplete notification
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

                -- hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
              end
            end)

            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        else 
            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

            EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                -- hmi side: expect OnSDLPersistenceComplete notification
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

        -- hmi side: expect OnSDLPersistenceComplete notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
    end

end

local function RegisterApp_HMILevelResumption(self, HMILevel, reason)

	if HMILevel == "FULL" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusFULL
	elseif HMILevel == "LIMITED" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusLIMITED
	end

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	-- got time after RAI request
	local time =  timestamp()

	if reason == "IGN_OFF" then
		local RAIAfterOnReady = time - self.timeOnReady
		userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))
	end

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

	self.mobileSession:ExpectResponse(correlationId, { success = true })

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

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)

end

local function RegisterApp_WithoutHMILevelResumption(self, reason)

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	-- got time after RAI request
	local time =  timestamp()

	if reason == "IGN_OFF" then
		local RAIAfterOnReady = time - self.timeOnReady
		userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))
	end

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

	self.mobileSession:ExpectResponse(correlationId, { success = true })


	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Do(function(_,data)
		    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		end)
		:Times(0)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		:Times(0)

	EXPECT_NOTIFICATION("OnHMIStatus", 
			AppValuesOnHMIStatusDEFAULT)
		:Do(function(_,data)
			self.hmiLevel = data.payload.hmiLevel
		end)

	DelayedExp(5000)

end

local function CloseSessionCheckLevel(self, targetLevel)
    if 
    	targetLevel == nil then
        self.mobileSession:Stop()
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
    elseif
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
  end

local function UnregisterApplication(self)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
 

	 --mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000) 
end

local function RestartSDL( prefix, level, appNumberForIGNOFF)

	Test["Precondition_SUSPEND_" .. tostring(prefix)] = function(self)
		SUSPEND(self, level)
	end

	Test["Precondition_IGNITION_OFF_" .. tostring(prefix)] = function(self)
		IGNITION_OFF(self,appNumberForIGNOFF)
	end

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

	Test["Precondition_StartSession_" .. tostring(prefix)] = function(self)
		CreateSession(self)
	end
end

local function Precondition_for_custom_ResumptionDelayBeforeIgn_ResumptionDelayAfterIgn( prefix, ResumptionDelayBeforeIgn, ResumptionDelayAfterIgn, ApplicationResumingTimeout, UseDBForResumption)

  	SDLStoragePath = config.pathToSDL .. "storage/"

	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

  	Test["Precondition_UnregisterApplication_" .. tostring(prefix)] = function(self)
  		UnregisterApplication(self)
  	end

  	Test["Precondition_SUSPEND_" .. tostring(prefix)] = function(self)
		SUSPEND(self)
	end

	Test["Precondition_IGNITION_OFF_" .. tostring(prefix)] = function(self)
		IGNITION_OFF(self,0)
	end

	if ResumptionDelayBeforeIgn then
		Test["Precondition_ResumptionDelayBeforeIgn_" .. tostring(prefix)] = function(self)
			local StringToReplace = "ResumptionDelayBeforeIgn = " .. tostring(ResumptionDelayBeforeIgn) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")

				fileContentUpdated  =  string.gsub(fileContent, "%p?ResumptionDelayBeforeIgn%s-=%s?[%w%d;]-\n", StringToReplace)

				if fileContentUpdated then
					f = assert(io.open(SDLini, "w"))
					f:write(fileContentUpdated)
				else 
					userPrint(31, "Finding of 'ResumptionDelayBeforeIgn = value' is failed. Expect string finding and replacing of value to true")
				end
				f:close()
			end
		end
	end

	if ResumptionDelayAfterIgn then
		Test["Precondition_ResumptionDelayAfterIgn_" .. tostring(prefix)] = function(self)
			local StringToReplace = "ResumptionDelayAfterIgn = " .. tostring(ResumptionDelayAfterIgn) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")

				fileContentUpdated  =  string.gsub(fileContent, "%p?ResumptionDelayAfterIgn%s-=%s?[%w%d;]-\n", StringToReplace)

				if fileContentUpdated then
					f = assert(io.open(SDLini, "w"))
					f:write(fileContentUpdated)
				else 
					userPrint(31, "Finding of 'ResumptionDelayAfterIgn = value' is failed. Expect string finding and replacing of value to true")
				end
				f:close()
			end
		end
	end

	if ApplicationResumingTimeout then
		Test["Precondition_ApplicationResumingTimeout_" .. tostring(prefix)] = function(self)
			local StringToReplace = "ApplicationResumingTimeout = " .. tostring(ApplicationResumingTimeout) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")

				fileContentUpdated  =  string.gsub(fileContent, "%p?ApplicationResumingTimeout%s-=%s?[%w%d;]-\n", StringToReplace)

				if fileContentUpdated then
					f = assert(io.open(SDLini, "w"))
					f:write(fileContentUpdated)
				else 
					userPrint(31, "Finding of 'ApplicationResumingTimeout = value' is failed. Expect string finding and replacing of value to true")
				end
				f:close()
			end
		end
	end

	if 
		UseDBForResumption == false or
		UseDBForResumption == true then
			Test["Precondition_UseDBForResumption_" .. tostring(prefix)] = function(self)
				local StringToReplace = "UseDBForResumption = " .. tostring(UseDBForResumption) .. "\n"
				f = assert(io.open(SDLini, "r"))
				if f then
					fileContent = f:read("*all")

					fileContentUpdated  =  string.gsub(fileContent, "%p?UseDBForResumption%s-=%s?[%w;]-\n", StringToReplace)

					if fileContentUpdated then
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'UseDBForResumption = value' is failed. Expect string finding and replacing of value to true")
					end
					f:close()
				end
			end
	end

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

	Test["Precondition_StartSession_" .. tostring(prefix)] = function(self)
		CreateSession(self)
	end

	Test["Precondition_RegisterApp_" .. tostring(prefix)] = function(self)
		self.mobileSession:StartService(7)
			:Do(function(_,data)
				RegisterApp_WithoutHMILevelResumption(self)
			end)
	end

  end

local function SUSPEND_closeSessionBeforeIGN_OFF(self, timeToSuspend, targetLevel)

	if 
      targetLevel == "FULL" and
      self.hmiLevel ~= "FULL" then
            ActivationApp(self)
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
              :Do(function(_,data)

                self.mobileSession:Stop()

			    local function to_run()
			      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
			          {
			            reason = "SUSPEND"
			          })
			    end

			    RUN_AFTER(to_run, timeToSuspend)

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

				    local function to_run()
				      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
				          {
				            reason = "SUSPEND"
				          })
				    end

				    RUN_AFTER(to_run, timeToSuspend)
              end
            end)

            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        else 
            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

            EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
                self.mobileSession:Stop()

			    local function to_run()
			      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
			          {
			            reason = "SUSPEND"
			          })
			    end

			    RUN_AFTER(to_run, timeToSuspend)

            end)
        end
    elseif 
      (targetLevel == "LIMITED" and
      self.hmiLevel == "LIMITED") or
      (targetLevel == "FULL" and
      self.hmiLevel == "FULL") or
      targetLevel == nil then
        self.mobileSession:Stop()

			    local function to_run()
			      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
			          {
			            reason = "SUSPEND"
			          })
			    end

			    RUN_AFTER(to_run, timeToSuspend)
    end

    --hmi side: expect OnSDLPersistenceComplete notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
      :Timeout(timeToSuspend + 15000)

end

local function RestartSDLWithDelayBeforeIGNOFF( prefix, timeToDelay, targetLevel)

	Test["Precondition_SUSPEND_" .. tostring(prefix)] = function(self)
		userPrint(35, "================= Precondition ==================")
		SUSPEND_closeSessionBeforeIGN_OFF(self, timeToDelay, targetLevel)
	end

	Test["Precondition_IGNITION_OFF_" .. tostring(prefix)] = function(self)
		IGNITION_OFF(self,0)
	end

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

	Test["Precondition_StartSession_" .. tostring(prefix)] = function(self)
		CreateSession(self)
	end
end

-- Values for UseDBForResumption parameter in .ini file
local UseDBForResumptionArray = {false, true}


commonPreconditions:BackupFile("smartDeviceLink.ini")

commonSteps:DeleteLogsFileAndPolicyTable()

-- Test cases are executed with UseDBForResumptionArray=false in first iteration and with UseDBForResumptionArray=true in second one
for u=1, #UseDBForResumptionArray do

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Precondition: Set ResumptionDelayBeforeIgn = 30 , ResumptionDelayAfterIgn = 30
	--////////////////////////////////////////////////////////////////////////////////////////////--
	  Precondition_for_custom_ResumptionDelayBeforeIgn_ResumptionDelayAfterIgn( "GeneralPrecondition_UseDB_" .. tostring(UseDBForResumptionArray[u]), 30, 30, 3000, UseDBForResumptionArray[u])

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel by ignition off
	--////////////////////////////////////////////////////////////////////////////////////////////--


		--======================================================================================--
		--Resumption of FULL hmiLevel 
		--======================================================================================--

		Test["Precondition_ActivationApp_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			print("")
			userPrint(33, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" )
			userPrint(33, " Test cases are executed with  UseDBForResumption=" .. tostring(UseDBForResumptionArray[u]))
			userPrint(33, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" )
			print("")
	    	userPrint(35, "================= Precondition ==================")

			-- hmi side: sending SDL.ActivateApp request
		  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		  	-- hmi side: expect SDL.ActivateApp response
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

	  	RestartSDL("Resumption_FULL_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u]), "FULL")

		Test["Resumption_FULL_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF")
				end)

		end


		--======================================================================================--
		--Resumption of LIMITED hmiLevel 
		--======================================================================================--
		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)

				end

				RestartSDL( "Resumption_LIMITED_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u]), "LIMITED")


				Test["Resumption_LIMITED_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")

					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
						end)

				end
		end

		--======================================================================================--
		--Resumption of BACKGROUND hmiLevel 
		--======================================================================================--

		Test["Precondition_DeactivateToBackGround_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
		  	BringAppToBackgroundLevel(self)
		end


		RestartSDL( "Resumption_BACKGROUND_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u]))

		Test["Resumption_BACKGROUND_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
				end)

		end

		--======================================================================================--
		--Resumption of NONE hmiLevel 
		--======================================================================================--

		if DefaultHMILevel == "NONE" then
			Test["Precondition_DeactivateToNone_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(35, "================= Precondition ==================")
				BringAppToNoneLevel(self)
			end

			RestartSDL( "Resumption_NONE_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u]))

			Test["Resumption_NONE_ByIGN_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)
						RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
					end)

			end
		end


	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel by closing session
	--////////////////////////////////////////////////////////////////////////////////////////////--
		
		Test["Precondition_Activate_Resumption_FULL_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevefAwakeSDLl ~= "FULL" then
				ActivationApp(self)

			  	EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
			      :Do(function(_,data)
			        self.hmiLevel = data.payload.hmiLevel
			      end)
			end

		end

		Test["CloseSession_Resumption_FULL_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  CloseSessionCheckLevel(self, "FULL")
		end

		Test["StartSession_Resumption_FULL_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		--======================================================================================--
		--Resumption of FULL hmiLevel 
		--======================================================================================--
		Test["Resumption_FULL_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_HMILevelResumption(self, "FULL")
				end)

		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel 
		--======================================================================================--

		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_Resumption_LIMITED_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)

				end

				Test["CloseSession_Resumption_LIMITED_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  CloseSessionCheckLevel(self, "LIMITED")
				end

				Test["StartSession_Resumption_LIMITED_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")

					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_HMILevelResumption(self, "LIMITED")
						end)

				end
		end

		--======================================================================================--
		--Resumption of BACKGROUND hmiLevel 
		--======================================================================================--

		Test["Precondition_DeactivateToBackGround_Resumption_BACKGROUND_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
		  	BringAppToBackgroundLevel(self)
		end

		Test["CloseSession_Resumption_BACKGROUND_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  CloseSessionCheckLevel(self)
		end

		Test["StartSession_Resumption_BACKGROUND_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		Test["Resumption_BACKGROUND_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self)
				end)

		end

		--======================================================================================--
		--Resumption of NONE hmiLevel 
		--======================================================================================--

		if DefaultHMILevel == "NONE" then
			Test["Precondition_DeactivateToNone_Resumption_NONE_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(35, "================= Precondition ==================")
				BringAppToNoneLevel(self)
			end

			Test["CloseSession_Resumption_NONE_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			  CloseSessionCheckLevel(self)
			end

			Test["StartSession_Resumption_NONE_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			   self.mobileSession = mobile_session.MobileSession(
			      self,
			      self.mobileConnection,
			      config.application1.registerAppInterfaceParams)
			end

			Test["Resumption_NONE_ByClosing_Session_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)
						RegisterApp_WithoutHMILevelResumption(self)
					end)

			end
		end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel by closing connection
	--////////////////////////////////////////////////////////////////////////////////////////////--
		
		--======================================================================================--
		--Resumption of FULL hmiLevel 
		--======================================================================================--

		Test["Precondition_Activate_Resumption_FULL_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
			      :Do(function(_,data)
			        self.hmiLevel = data.payload.hmiLevel
			      end)
			end

		end

		Test["CloseConnection_Resumption_FULL_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self.mobileConnection:Close() 
		end

		Test["ConnectMobile_Resumption_FULL_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			self:connectMobile()
		end

		Test["StartSession_Resumption_FULL_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		Test["Resumption_FULL_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_HMILevelResumption(self, "FULL")
				end)

		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel 
		--======================================================================================--
		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_Resumption_LIMITED_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)

				end

				Test["CloseConnection_Resumption_LIMITED_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self.mobileConnection:Close() 
				end

				Test["ConnectMobile_Resumption_LIMITED_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					self:connectMobile()
				end

				Test["StartSession_Resumption_LIMITED_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")

					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_HMILevelResumption(self, "LIMITED")
						end)

				end
		end

		--======================================================================================--
		--Resumption of BACKGROUND hmiLevel 
		--======================================================================================--

		Test["Precondition_DeactivateToBackGround_Resumption_BACKGROUND_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
		  	BringAppToBackgroundLevel(self)
		end

		Test["CloseConnection_Resumption_BACKGROUND_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self.mobileConnection:Close() 
		end

		Test["ConnectMobile_Resumption_BACKGROUND_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			self:connectMobile()
		end

		Test["StartSession_Resumption_BACKGROUND_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		Test["Resumption_BACKGROUND_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self)
				end)

		end

		--======================================================================================--
		--Resumption of NONE hmiLevel 
		--======================================================================================--

		if DefaultHMILevel == "NONE" then
			Test["Precondition_DeactivateToNone_Resumption_NONE_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(35, "================= Precondition ==================")
				BringAppToNoneLevel(self)
			end

			Test["CloseConnection_Resumption_NONE_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			  	self.mobileConnection:Close()
			  	print("Close connection")
			end

			Test["ConnectMobile_Resumption_NONE_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				self:connectMobile()
			end

			Test["StartSession_Resumption_NONE_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			   self.mobileSession = mobile_session.MobileSession(
			      self,
			      self.mobileConnection,
			      config.application1.registerAppInterfaceParams)
			end

			Test["Resumption_NONE_ByClose_Connection_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)
						RegisterApp_WithoutHMILevelResumption(self)
					end)

			end
		end


	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel by HB dissconnect
	--////////////////////////////////////////////////////////////////////////////////////////////--
		--TODO: Umcommencted after resolving APPLINK-16610
		-- --======================================================================================--
		-- --Resumption of FULL hmiLevel 
		-- --======================================================================================--

		-- Test["CloseSession_Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	userPrint(35, "================= Precondition ==================")

		-- 	self.mobileSession:Stop()
	 --        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
		-- end

		-- Test["StartSession_Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	self.mobileSession = mobile_session.MobileSession(
		--       self,
		--       self.mobileConnection,
		--       config.application1.registerAppInterfaceParams)
	 --    	self.mobileSession.version = 3
		--     self.mobileSession:StartHeartbeat()
	 --        self.mobileSession.sendHeartbeatToSDL = false
	 --        self.mobileSession.answerHeartBeatFromSDL = false
		-- end

		-- Test["RegisterApplication_Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	self.mobileSession:StartService(7)
		-- 		:Do(function(_,data)
		-- 			RegisterApp_WithoutHMILevelResumption(self)
		-- 		end)
		-- end

		-- Test["Precondition_ActivateToFull_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	if self.hmiLevel ~= "FULL" then
		-- 		ActivationApp(self)
		-- 		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		-- 	      :Do(function(_,data)
		-- 	        self.hmiLevel = data.payload.hmiLevel
		-- 	      end)
		-- 	end

		-- end

		-- Test["CloseConnectionByHB_Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)	
		-- 	self.mobileSession:StopHeartbeat()
		--   	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIAppID, unexpectedDisconnect = true })
		--   	:Timeout(20000)
		-- end

		-- Test["ConnectMobile_Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	self:connectMobile()
		-- end

		-- Test["StartSession_Resumption_FULL_ByHB_Disconnect_2_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		--    self.mobileSession = mobile_session.MobileSession(
		--       self,
		--       self.mobileConnection,
		--       config.application1.registerAppInterfaceParams)

		-- end

		-- Test["Resumption_FULL_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	userPrint(34, "=================== Test Case ===================")

		-- 	self.mobileSession:StartService(7)
		-- 		:Do(function(_,data)
		-- 			RegisterApp_HMILevelResumption(self, "FULL")
		-- 		end)

		-- end

		-- --======================================================================================--
		-- --Resumption of LIMITED hmiLevel 
		-- --======================================================================================--

		-- if
		-- 	config.application1.registerAppInterfaceParams.isMediaApplication == true or
		--   	Test.appHMITypes["NAVIGATION"] == true or
		--   	Test.appHMITypes["COMMUNICATION"] == true then

		-- 		Test["DeactivateToNone_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			userPrint(35, "================= Precondition ==================")
		-- 			BringAppToNoneLevel(self)
		-- 		end

		-- 		Test["CloseSession_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			self.mobileSession:Stop()
		-- 	        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
		-- 		end

		-- 		Test["StartSession_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			self.mobileSession = mobile_session.MobileSession(
		-- 		      self,
		-- 		      self.mobileConnection,
		-- 		      config.application1.registerAppInterfaceParams)
		-- 	    	self.mobileSession.version = 3
		-- 		    self.mobileSession:StartHeartbeat()
		-- 	        self.mobileSession.sendHeartbeatToSDL = false
		-- 	        self.mobileSession.answerHeartBeatFromSDL = false
		-- 		end

		-- 		Test["RegisterApplication_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			self.mobileSession:StartService(7)
		-- 				:Do(function(_,data)
		-- 					RegisterApp_WithoutHMILevelResumption(self)
		-- 				end)
		-- 		end

		-- 		Test["Precondition_DeactivateToLimited_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 		  	BringAppToLimitedLevel(self)
		-- 		end

		-- 		Test["CloseConnectionByHB_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)	
		-- 		  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIAppID, unexpectedDisconnect = true })
		-- 		  	:Timeout(20000)
		-- 		end

		-- 		Test["ConnectMobile_Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			self:connectMobile()
		-- 		end

		-- 		Test["StartSession_Resumption_LIMITED_ByHB_Disconnect_2_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 		   print("Start Session enter")
		-- 			self.mobileSession = mobile_session.MobileSession(
		-- 		      self,
		-- 		      self.mobileConnection,
		-- 		      config.application1.registerAppInterfaceParams)

		-- 			self.mobileSession.version = 3

		-- 		end

		-- 		Test["Resumption_LIMITED_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 			userPrint(34, "=================== Test Case ===================")

		-- 			self.mobileSession:StartService(7)
		-- 				:Do(function(_,data)
		-- 					RegisterApp_HMILevelResumption(self, "LIMITED")
		-- 				end)

		-- 		end
		-- end

		-- --======================================================================================--
		-- --Resumption of BACKGROUND hmiLevel 
		-- --======================================================================================--

		-- Test["Precondition_DeactivateToBackGround_Resumption_BACKGROUND_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	userPrint(35, "================= Precondition ==================")
		--   	BringAppToBackgroundLevel(self)
		-- end

		-- Test["CloseConnectionByHB_Resumption_BACKGROUND_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		--   	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIAppID, unexpectedDisconnect = true })
		--   	:Timeout(20000)
		-- end

		-- Test["ConnectMobile_Resumption_BACKGROUND_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	self:connectMobile()
		-- end

		-- Test["StartSession_Resumption_BACKGROUND_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	self.mobileSession = mobile_session.MobileSession(
		--       self,
		--       self.mobileConnection,
		--       config.application1.registerAppInterfaceParams)
	 --    	self.mobileSession.version = 3
		--     self.mobileSession:StartHeartbeat()
	 --        self.mobileSession.sendHeartbeatToSDL = false
	 --        self.mobileSession.answerHeartBeatFromSDL = false
		--    	print("Start Session exit")

		-- end

		-- Test["Resumption_BACKGROUND_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	userPrint(34, "=================== Test Case ===================")

		-- 	self.mobileSession:StartService(7)
		-- 		:Do(function(_,data)
		-- 			RegisterApp_WithoutHMILevelResumption(self)
		-- 		end)

		-- end

		-- --======================================================================================--
		-- --Resumption of NONE hmiLevel 
		-- --======================================================================================--

		-- if DefaultHMILevel == "NONE" then
		-- 	Test["Precondition_DeactivateToNone_Resumption_NONE_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 		userPrint(35, "================= Precondition ==================")
		-- 		BringAppToNoneLevel(self)
		-- 	end

		-- 	Test["CloseConnectionByHB_Resumption_NONE_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIAppID, unexpectedDisconnect = true })
		-- 	  	:Timeout(20000)
		-- 	end

		-- 	Test["ConnectMobile_Resumption_NONE_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 		self:connectMobile()
		-- 	end

		-- 	Test["StartSession_Resumption_NONE_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 	   self.mobileSession = mobile_session.MobileSession(
		-- 	      self,
		-- 	      self.mobileConnection,
		-- 	      config.application1.registerAppInterfaceParams)

		-- 	   	self.mobileSession.version = 3

		-- end

		-- 	Test["Resumption_NONE_ByHB_Disconnect_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		-- 		userPrint(34, "=================== Test Case ===================")

		-- 		self.mobileSession:StartService(7)
		-- 			:Do(function(_,data)
		-- 				RegisterApp_WithoutHMILevelResumption(self)
		-- 			end)

		-- 	end
		-- end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel is absent in case RAI requeat came in more then 30 seconds before or after IGN_OFF
	--////////////////////////////////////////////////////////////////////////////////////////////--

		--======================================================================================--
		--Resumption is absent because App is disconnected in more than 30 seconds before IGNITION_OFF
		--======================================================================================--

		Test["DeactivateToNone_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			BringAppToNoneLevel(self)
		end

		Test["CloseSession_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")

			self.mobileSession:Stop()
	        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
		end

		Test["StartSession_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)

		end

		Test["RegisterApplication_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self)
				end)
		end

		Test["ActivateApplication_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)

				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      		:Do(function(_,data)
		        		self.hmiLevel = data.payload.hmiLevel
		      	end)
		     end
		end

		Test["SUSPEND_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
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

		Test["IGNITION_OFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  IGNITION_OFF(self, 0)
		end

		Test["StartSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  print("Start SDL")
		  StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		Test["InitHMI_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI()
		end

		Test["InitHMI_onReady_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI_onReady()
		end

		Test["ConnectMobile_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:connectMobile()
		end

		Test["StartSession_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   	self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)

		end

		Test["Resumption_FULL_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")
			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
				end)
		end

		--======================================================================================--
		--Resumption is absent because App is disconnected in more than 30 seconds after IGNITION_OFF
		--======================================================================================--

		RestartSDL( "Resumption_FULL_AppIsDisconnectedInMoreThen30SecAfterIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u]), "FULL")

		Test["Resumption_FULL_AppIsDisconnectedInMoreThen30SecAfterIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")
			self.mobileSession:StartService(7)
				:Do(function(_,data)
					function to_run()
						RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
					end

					RUN_AFTER(to_run, 35000)

				end)

				DelayedExp(50000)
		end

		--======================================================================================--
		--Resumption is absent because App is disconnected in more than 30 seconds before IGNITION_OFF
		--======================================================================================--

		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end


				Test["SUSPEND_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
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

				RestartSDL( "Resumption_FULL_AppIsDisconnectedInMoreThen30SecAfterIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u]), "LIMITED", 0)


				Test["Resumption_LIMITED_AppIsDisconnectedInMoreThen30SecBeforeIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")
					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
						end)
				end


		--======================================================================================--
		--Resumption is absent because App is disconnected in more than 30 seconds after IGNITION_OFF
		--======================================================================================--

				Test["Precondition_DeactivateToLimited_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end

				RestartSDL( "Resumption_FULL_AppIsDisconnectedInMoreThen30SecAfterIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u]), "LIMITED")


				Test["Resumption_LIMITED_AppIsDisconnectedInMoreThen30SecAfterIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")
					self.mobileSession:StartService(7)
						:Do(function(_,data)
							function to_run()
								RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
							end

							RUN_AFTER(to_run, 35000)

						end)

						DelayedExp(50000)
				end
		end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMIlevel is absent in second ignition cycle.
	--////////////////////////////////////////////////////////////////////////////////////////////--
		--======================================================================================--
		--FULL hmiLevel 
		--======================================================================================--
		Test["ActivateApplication_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      		:Do(function(_,data)
		        		self.hmiLevel = data.payload.hmiLevel
		      		end)
		    end
		end

		Test["SUSPEND_Resumption_FULL_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	SUSPEND(self,"FULL")
		end

		Test["IGNITION_OFF_FULL_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	IGNITION_OFF(self)
		end

		Test["StartSDL_FULL_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	print("Start SDL")
		  	StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		Test["InitHMI_FULL_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI()
		end

		Test["InitHMI_onReady_FULL_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI_onReady()
		end

		Test["SUSPEND_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	SUSPEND(self)
		end

		Test["IGNITION_OFF_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	IGNITION_OFF(self,0)
		end

		Test["StartSDL_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	print("Start SDL")
		  	StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		Test["InitHMI_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI()
		end

		Test["InitHMI_onReady_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:initHMI_onReady()
		end

		Test["ConnectMobile_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:connectMobile()
		end

		Test["StartSession_FULL_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   	self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		Test["Resumption_FULL_InSecondIGNCycle_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")
			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
				end)
		end

		--======================================================================================--
		--LIMITED hmiLevel 
		--======================================================================================--

		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end

				Test["SUSPEND_LIMITED_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	SUSPEND(self,"LIMITED")
				end

				Test["IGNITION_OFF_LIMITED_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	IGNITION_OFF(self)
				end

				Test["StartSDL_LIMITED_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	print("Start SDL")
				  	StartSDL(config.pathToSDL, config.ExitOnCrash)
				end

				Test["InitHMI_LIMITED_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:initHMI()
				end

				Test["InitHMI_onReady_LIMITED_InSecondIGNCycle_FirstIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:initHMI_onReady()
				end

				Test["SUSPEND_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	SUSPEND(self)
				end

				Test["IGNITION_OFF_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	IGNITION_OFF(self,0)
				end

				Test["StartSDL_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	print("Start SDL")
				  	StartSDL(config.pathToSDL, config.ExitOnCrash)
				end

				Test["InitHMI_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:initHMI()
				end

				Test["InitHMI_onReady_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:initHMI_onReady()
				end

				Test["ConnectMobile_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:connectMobile()
				end

				Test["StartSession_LIMITED_InSecondIGNCycle_SecondIGNOFF_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   	self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_InSecondIGNCycle_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")
					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
						end)
				end
		end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption after on AwakeSDL 
	--////////////////////////////////////////////////////////////////////////////////////////////--

		--======================================================================================--
		--FULL hmiLevel 
		--======================================================================================--
		Test["ActivateApplication_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
			      :Do(function(_,data)
			        self.hmiLevel = data.payload.hmiLevel
			      end)
			end
		end

		Test["CloseConnection_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self.mobileConnection:Close()
		  	print("Close connection")
		end

		Test["SUSPEND_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	SUSPEND(self)
		end

		Test["OnAwakeSDL_FULL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			local function to_run()
				self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
			end

			RUN_AFTER(to_run, 35000)

			DelayedExp(40000)
		end

		Test["ConnectMobile_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		  	self:connectMobile()
		end

		Test["StartSession_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
		   	self.mobileSession = mobile_session.MobileSession(
		      self,
		      self.mobileConnection,
		      config.application1.registerAppInterfaceParams)
		end

		Test["Resumption_FULL_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")
			self.mobileSession:StartService(7)
				:Do(function(_,data)
					RegisterApp_HMILevelResumption(self, "FULL")
				end)
		end

		--======================================================================================--
		--LIMITED hmiLevel 
		--======================================================================================--

		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end

				Test["CloseConnection_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self.mobileConnection:Close()
				  	print("Close connection")
				end

				Test["SUSPEND_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	SUSPEND(self)
				end

				Test["OnAwakeSDL_LIMITED_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					local function to_run()
						self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
					end

					RUN_AFTER(to_run, 35000)

					DelayedExp(40000)
				end

				Test["ConnectMobile_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  	self:connectMobile()
				end

				Test["StartSession_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   	self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_AfterAwakeSDL_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")
					self.mobileSession:StartService(7)
						:Do(function(_,data)
							RegisterApp_HMILevelResumption(self, "LIMITED")
						end)
				end
		end


	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMI level independently of media type of App (isMediaApplication parameter in RegisterAppInterface)
	--////////////////////////////////////////////////////////////////////////////////////////////--

		--======================================================================================--
		--FULL hmiLevel 
		--======================================================================================--

		Test["ActivateApplication_Resumption_FULL_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      		:Do(function(_,data)
		        		self.hmiLevel = data.payload.hmiLevel
		      		end)
		    end
		end

		RestartSDL( "Resumption_FULL_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u]))


		Test["Resumption_FULL_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)

					local currentIsMediaApplicationValue = config.application1.registerAppInterfaceParams.isMediaApplication
					local currentAppValuesOnHMIStatusFULL = AppValuesOnHMIStatusFULL

					if
						currentIsMediaApplicationValue == true then
							config.application1.registerAppInterfaceParams.isMediaApplication = false
							AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
					else 
						config.application1.registerAppInterfaceParams.isMediaApplication = true
						AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
					end

					RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF")
					config.application1.registerAppInterfaceParams.isMediaApplication = currentIsMediaApplicationValue
					AppValuesOnHMIStatusFULL = currentAppValuesOnHMIStatusFULL

				end)

		end

		--======================================================================================--
		--LIMITED hmiLevel 
		--======================================================================================--

		if
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_LIMITED_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end

				Test["CloseSession_LIMITED_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  CloseSessionCheckLevel(self)
				end

				Test["StartSession_LIMITED_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_App_independently_of_media_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")

					self.mobileSession:StartService(7)
						:Do(function(_,data)

							local currentIsMediaApplicationValue = config.application1.registerAppInterfaceParams.isMediaApplication

							if
								currentIsMediaApplicationValue == true then
									config.application1.registerAppInterfaceParams.isMediaApplication = false
							else 
								config.application1.registerAppInterfaceParams.isMediaApplication = true
							end

							RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
							config.application1.registerAppInterfaceParams.isMediaApplication = currentIsMediaApplicationValue
							
						end)

				end
		end


	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMI level independently of AppHMIType
	--////////////////////////////////////////////////////////////////////////////////////////////--
		--======================================================================================--
		--FULL hmiLevel 
		--======================================================================================--

		Test["ActivateApplication_Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      		:Do(function(_,data)
		        		self.hmiLevel = data.payload.hmiLevel
		      	end)
		     end
		end

		RestartSDL( "Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u]))

		Test["Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			local currentTypes =  config.application1.registerAppInterfaceParams.appHMIType

			self.mobileSession:StartService(7)
				:Do(function(_,data)

					if self.appHMITypes["DEFAULT"] == false then
							config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
					else 
						config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
					end

					RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF")
					config.application1.registerAppInterfaceParams.appHMIType = currentTypes
				end)

		end

		Test["ActivateApplication_Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(35, "================= Precondition ==================")
			if self.hmiLevel ~= "FULL" then
				ActivationApp(self)
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      		:Do(function(_,data)
		        		self.hmiLevel = data.payload.hmiLevel
		      	end)
		     end
		end

		RestartSDL( "Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u]), 60000)


		Test["Resumption_FULL_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			local currentTypes =  config.application1.registerAppInterfaceParams.appHMIType

			self.mobileSession:StartService(7)
				:Do(function(_,data)

					if self.appHMITypes["DEFAULT"] == false then
							config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
					else 
						config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
					end

					RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF")
					config.application1.registerAppInterfaceParams.appHMIType = currentTypes
				end)

		end

		--======================================================================================--
		--LIMITED hmiLevel 
		--======================================================================================--

		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

				Test["Precondition_DeactivateToLimited_Resumption_LIMITED_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  userPrint(35, "================= Precondition ==================")
				  	BringAppToLimitedLevel(self)
				end

				Test["CloseSession_Resumption_LIMITED_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				  CloseSessionCheckLevel(self)
				end

				Test["StartSession_Resumption_LIMITED_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				   self.mobileSession = mobile_session.MobileSession(
				      self,
				      self.mobileConnection,
				      config.application1.registerAppInterfaceParams)
				end

				Test["Resumption_LIMITED_App_independently_of_hmi_type_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
					userPrint(34, "=================== Test Case ===================")

					local currentTypes =  config.application1.registerAppInterfaceParams.appHMIType

					self.mobileSession:StartService(7)
						:Do(function(_,data)

							if self.appHMITypes["NAVIGATION"] == true then
									config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
							else 
								config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
							end

							RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
							config.application1.registerAppInterfaceParams.appHMIType = currentTypes
						end)

				end
		end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Resumption of HMI level with custom values of ResumptionDelayBeforeIgn, ResumptionDelayAfterIgn
	--////////////////////////////////////////////////////////////////////////////////////////////--

		--======================================================================================--
		--Resumption of FULL hmiLevel 
		--======================================================================================--

		-- Precondition: Restart SDL, set ResumptionDelayBeforeIgn = 55 sec, ResumptionDelayAfterIgn = 85 sec.
		Precondition_for_custom_ResumptionDelayBeforeIgn_ResumptionDelayAfterIgn( "Set_ResumptionDelayBeforeIgn55_ResumptionDelayAfterIgn85_UseDB_" .. tostring(UseDBForResumptionArray[u]), 55, 85)

		--Precondition: Activation app
		Test["Precondition_ActivationApp_Resumption_FULL_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
	    	userPrint(35, "================= Precondition ==================")

			-- hmi side: sending SDL.ActivateApp request
		  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		  	-- hmi side: expect SDL.ActivateApp response
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

	  	--Precondition: Restart SDL, close sessions in 50 secs before "suspend"
	  	RestartSDLWithDelayBeforeIGNOFF( "Resumption_FULL_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 50000, "FULL")

	  	-- Resumption by registration application with delay in 80 secs after SDL start
		Test["Resumption_FULL_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					function to_run()
						RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF")
					end

					RUN_AFTER(to_run, 80000)

				end)

			DelayedExp(85000)

		end

		--Precondition: Restart SDL, close sessions in 60 secs before "suspend"
		RestartSDLWithDelayBeforeIGNOFF( "Resumption_FULL_ByIGN_OFF_withDelayBeforeIGNOFFMoreThenCustomDelayBeforeIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 60000, "FULL")

		-- Resumption by registration application with delay in 5 secs after SDL start
		Test["Resumption_FULL_ByIGN_OFF_withDelayBeforeIGNOFFMoreThenCustomDelayBeforeIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					function to_run()
						RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
					end

					RUN_AFTER(to_run, 5000)

				end)

			DelayedExp(10000)

		end

		-- Precondition: Restart SDL, close sessions in 5 secs before "suspend"
		RestartSDLWithDelayBeforeIGNOFF( "Resumption_FULL_ByIGN_OFF_withDelayAfterIGNOFFMoreThenCustomDelayAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 5000, "FULL")

		-- Resumption by registration application with delay in 85 secs after SDL start
		Test["Resumption_FULL_ByIGN_OFF_withDelayAfterIGNOFFMoreThenCustomDelayAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			userPrint(34, "=================== Test Case ===================")

			self.mobileSession:StartService(7)
			:Do(function(_,data)
				function to_run()
					RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
				end

				RUN_AFTER(to_run, 85000)

			end)

			DelayedExp(90000)

		end


		--======================================================================================--
		--Resumption of LIMITED hmiLevel 
		--======================================================================================--
		if
			config.application1.registerAppInterfaceParams.isMediaApplication == true or
		  	Test.appHMITypes["NAVIGATION"] == true or
		  	Test.appHMITypes["COMMUNICATION"] == true then

		  	-- Precondition: Restart SDL, set ResumptionDelayBeforeIgn = 10 sec, ResumptionDelayAfterIgn = 20 sec.
		  	Precondition_for_custom_ResumptionDelayBeforeIgn_ResumptionDelayAfterIgn( "Set_ResumptionDelayBeforeIgn10_ResumptionDelayAfterIgn20_UseDB_" .. tostring(UseDBForResumptionArray[u]), 10, 20)

			Test["Precondition_DeactivateToLimited_Resumption_LIMITED_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
			  userPrint(35, "================= Precondition ==================")
			  	BringAppToLimitedLevel(self)

			end

			--Precondition: Restart SDL, close sessions in 5 secs before "suspend"
		  	RestartSDLWithDelayBeforeIGNOFF( "Resumption_LIMITED_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 5000, "LIMITED")

		  	-- Resumption by registration application with delay in 14 secs after SDL start
			Test["Resumption_LIMITED_ByIGN_OFF_withCustomDelayBeforeIgnAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)

						function to_run()
							RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
						end

						RUN_AFTER(to_run, 15000)

					end)

				DelayedExp(20000)

			end

			--Precondition: Restart SDL, close sessions in 12 secs before "suspend"
			RestartSDLWithDelayBeforeIGNOFF( "Resumption_LIMITED_ByIGN_OFF_withDelayBeforeIGNOFFMoreThenCustomDelayBeforeIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 12000, "LIMITED")

			-- Register app in 5 secs after SDL started
			Test["Resumption_LIMITED_ByIGN_OFF_withDelayBeforeIGNOFFMoreThenCustomDelayBeforeIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)
						function to_run()
							RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
						end

						RUN_AFTER(to_run, 5000)

					end)

				DelayedExp(10000)

			end

			--Precondition: Restart SDL, close sessions in 5 secs before "suspend"
			RestartSDLWithDelayBeforeIGNOFF( "Resumption_LIMITED_ByIGN_OFF_withDelayAfterIGNOFFMoreThenCustomDelayAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u]), 5000, "LIMITED")

			-- Register app in 22 secs after SDL started
			Test["Resumption_LIMITED_ByIGN_OFF_withDelayAfterIGNOFFMoreThenCustomDelayAfterIgn_UseDB_" .. tostring(UseDBForResumptionArray[u])] = function(self)
				userPrint(34, "=================== Test Case ===================")

				self.mobileSession:StartService(7)
					:Do(function(_,data)
						function to_run()
							RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF")
						end

						RUN_AFTER(to_run, 22000)

					end)

				DelayedExp(27000)

			end

	end
end

function Test:Postcondition_restoringIniFile()
	commonPreconditions:RestoreFile("smartDeviceLink.ini")
end
