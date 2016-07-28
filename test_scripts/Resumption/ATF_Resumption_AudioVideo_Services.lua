-------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
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

AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
AppValuesOnHMIStatusDEFAULT = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
---------------------------------------------------------------------------------------------
-------------------------------------------User functions------------------------------------
---------------------------------------------------------------------------------------------
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

--Open session and register application 

local function OpenSessionRegisterApp(self)
	config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

	self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)

	self.mobileSession:StartService(7)
    :Do(function()
      local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				      {
				        application = 
				        {
				          appName = config.application1.registerAppInterfaceParams.appName
				        }
				      })
      	:Do(function(_,data)
        	local appId = data.params.application.appID
        	self.appId = appId
        end)

  	self.mobileSession:ExpectResponse(CorIdRAI, {
      	success = true,
      	resultCode = "SUCCESS"
  	})
      	:Timeout(2000)

    self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
      	:Timeout(2000)
  	commonTestCases:DelayedExp(1000)
   end)
end

--Activation of Application

local function ActivationApp(self, iappID)
	--print("iappID = " ..iappID)
	-- hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = iappID})

    -- hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
    	if(data.result.isSDLAllowed == true) then
    		--print ("TRUE")
    	end
    		--print("Received response!")
        -- In case when app is not allowed, it is needed to allow app
          	if (data.result.isSDLAllowed ~= true ) then
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

	-- --self.mobileSession:ExpectNotification("OnHMIStatus", 
	-- EXPECT_NOTIFICATION("OnHMIStatus",
 --        --{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
 --        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
end


-- Audio streaming 
local function StartAudioServiceAndStreaming(self)
	--Start Audio Sevice
	self.mobileSession:StartService(10)

	EXPECT_HMICALL("Navigation.StartAudioStream")
	    :Do(function(exp,data)
	    	--Send ACK
 	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
	     	function to_run2()
	     	-- os.execute( " sleep 1 " )
	     		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	     	end

	     	RUN_AFTER(to_run2, 1500)
		end)
		:Timeout(20000)
end

-- Video streaming 
local function StartVideoServiceAndStreaming(self)
	self.mobileSession:StartService(11)

	EXPECT_HMICALL("Navigation.StartStream")
	    :Do(function(_,data)
	    	--Send ACK
 	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
	     	function to_run2()
	     	-- os.execute( " sleep 1 " )
	     		self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
	     	end

	     	RUN_AFTER(to_run2, 1500)
	    end)
end

-- Resumption of Streaming after disconnect
local function StreammingResumption(self, prefix, AudioStream, VideoStream, UpdateAudioDataStoppedTimeout, ValueToUpdate, ValueToExpect, UpdateVideoDataStoppedTimeout, ValueToUpdateVideo, ValueToExpectVideo)

	if AudioStream == true then
		Test["StartAudioServiceStreaming_" .. tostring(prefix)] = function(self)

			self.mobileSession:StartService(10)

			EXPECT_HMICALL("Navigation.StartAudioStream")
			    :Do(function(exp,data)
		 	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
			     	function to_run2()
			     	-- os.execute( " sleep 1 " )
			     		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
			     	end

			     	RUN_AFTER(to_run2, 300)
			    end)

			EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})

			commonTestCases:DelayedExp(2000)
		end
	-----------------------------------
	elseif VideoStream == true then
		Test["StartVideoServiceStreaming_" .. tostring(prefix)] = function(self)

			self.mobileSession:StartService(11)

			EXPECT_HMICALL("Navigation.StartStream")
		    :Do(function(_,data)
		     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
		     	self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
		    end)

			EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})
				:Timeout(11000 + ValueToExpectVideo)

			commonTestCases:DelayedExp(2000)
		end
	end 
end 

-- Register App and resume HMI Level
local function RegisterApp_HMILevelResumption(self, HMILevel, reason)

	if HMILevel == "FULL" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusFULL
	elseif HMILevel == "LIMITED" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusLIMITED
	end

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	-- got time after RAI request
	local time =  timestamp()

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

local function RestartSDL( self)

   Test["StartSDL_" .. tostring(prefix) ] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["InitHMI_" .. tostring(prefix) ] = function(self)
    self:initHMI()
  end

  Test["InitHMI_onReady_" .. tostring(prefix) ] = function(self)
    self:initHMI_onReady()
  end

  Test["ConnectMobile_" .. tostring(prefix) ] = function(self)
      self:connectMobile()
  end

    Test["RegisterApp_" .. tostring(prefix)] = function(self)
    OpenSessionRegisterApp(self)
  end

end

commonFunctions:userPrint(33, " Start test") 

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Use case described in APPLINK-16324 Resumption of Audio Service FULL
--////////////////////////////////////////////////////////////////////////////////////////////--

-- Description:

--Resumption of Navi App in FULL HMI Level with Audio Streaming on that closed unexpectedly due to transport disconnect

commonFunctions:newTestCasesGroup(" Resumption Navi App in FULL with Audio Streaming ")

-- After registration application is brought to FULL HMI level

	Test["Activate_FULLAppAudio"] = function(self)
			if self.hmiLevel ~= "FULL" then	
				appid = self.applications[config.application1.registerAppInterfaceParams.appName]
				--print("appid = " .. appid)
				ActivationApp(self, appid)
				
				EXPECT_NOTIFICATION("OnHMIStatus", 
									{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})	
			    :Do(function(_,data)
			    	--print("HMILEVEL = " ..data.payload.hmiLevel)
			    	--print("systemContext = " ..data.payload.systemContext)
			    	--print("audioStreamingState = " ..data.payload.audioStreamingState)
			        self.hmiLevel = data.payload.hmiLevel
			    end)
			    :ValidIf(function(_,data)
			    	local result= true
			    	if (data.payload.hmiLevel ~= "FULL") then
			    		--print("HMILEVEL = " ..data.payload.hmiLevel .. "; expected: FULL")
			    		result = false
			    	end
			    	if (data.payload.systemContext ~= "MAIN") then
			    		--print("systemContext = " ..data.payload.systemContext .. "; expected: MAIN")
			    		result = false 
			    	end 
			    	if (data.payload.audioStreamingState ~= "AUDIBLE") then
			    		--print("audioStreamingState = " ..data.payload.audioStreamingState .. "; expected: AUDIBLE")
			    		result = false
			    	end
			    	return result
			    end)
			end
	end

--Start Audio Service and Streaming 
function Test:FULLApp_StartStreamingAudio ()
	StartAudioServiceAndStreaming(self)
end

--Unexpected Disconnect followed by re-connect and level resumption 

		Test["CloseConnection_FULLAudio"] = function(self)
		  	self.mobileConnection:Close() 
		end

		Test["ConnectMobile_FULLAudio"] = function(self)	
			self:connectMobile()
		end
		
		Test["Resumption_FULLAudio"] = function(self)		
		 	-- self.mobileSession:StartService(7)
		 	-- 	:Do(function(_,data)
		 			self.mobileSession = mobile_session.MobileSession(
		      															self,
		      															self.mobileConnection,
		      															config.application1.registerAppInterfaceParams
		      														)
		 			
		 			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
					:Do(function(_,data)
						HMIAppID = data.params.application.appID
						self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID

						self.mobileSession:ExpectEvent(event, "EndService NACK")

						self.mobileSession:ExpectNotification("OnHMIStatus", 
														{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
												)
					end)
		 		end															
		--end
		
-- 	Start audio streaming again 
function Test:FULLApp_ResumesAudioStreaming ()
	StreammingResumption(self)
	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
		:Timeout(17000)
	commonTestCases:DelayedExp(7000)
end

--Verify that SDL does not send OnAudioDataStreaming in case mobile app stops and resumes audio streaming before AudioDataStoppedTimeout is expired

function Test:AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	function StopStream1()
		self.mobileSession:StopStreaming("files/Kalimba.mp3")
	end

	function StartStream1()
		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	end

	RUN_AFTER(StopStream1,5000)
	RUN_AFTER(StartStream1,10000)

	commonTestCases:DelayedExp(25000)
end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Use case described in APPLINK-16239 Resumption of Video Service FULL
--////////////////////////////////////////////////////////////////////////////////////////////--

-- Description:

--Resumption of Navi App in FULL HMI Level with Video Streaming on that closed unexpectedly due to transport disconnect

commonFunctions:newTestCasesGroup(" Resumption Navi App in FULL with Video Streaming")

--Preconditions: SDL is restarted

function Test:RestartSDL ()
	RestartSDL()
end

-- After registration application is brought to FULL HMI level

	Test["Activate_FULLAppVideo"] = function(self)
			if self.hmiLevel ~= "FULL" then	
				appid = self.applications[config.application1.registerAppInterfaceParams.appName]
				--print("appid = " .. appid)
				ActivationApp(self, appid)
				
				EXPECT_NOTIFICATION("OnHMIStatus", 
									{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})	
			    :Do(function(_,data)
			    	--print("HMILEVEL = " ..data.payload.hmiLevel)
			    	--print("systemContext = " ..data.payload.systemContext)
			    	--print("audioStreamingState = " ..data.payload.audioStreamingState)
			        self.hmiLevel = data.payload.hmiLevel
			    end)
			    :ValidIf(function(_,data)
			    	local result= true
			    	if (data.payload.hmiLevel ~= "FULL") then
			    		--print("HMILEVEL = " ..data.payload.hmiLevel .. "; expected: FULL")
			    		result = false
			    	end
			    	if (data.payload.systemContext ~= "MAIN") then
			    		--print("systemContext = " ..data.payload.systemContext .. "; expected: MAIN")
			    		result = false 
			    	end 
			    	if (data.payload.audioStreamingState ~= "AUDIBLE") then
			    		--print("audioStreamingState = " ..data.payload.audioStreamingState .. "; expected: AUDIBLE")
			    		result = false
			    	end
			    	return result
			    end)
			end
	end

--Start Video Service and Streaming 
function Test:FULLApp_StartStreamingVideo ()
	StartVideoServiceAndStreaming(self)
end

--Unexpected Disconnect followed by re-connect and level resumption 

		Test["CloseConnection_FULLVideo"] = function(self)
		  	self.mobileConnection:Close() 
		end

		Test["ConnectMobile_FULLVideo"] = function(self)	
			self:connectMobile()
		end
		
		Test["Resumption_FULLVideo"] = function(self)		
		 	-- self.mobileSession:StartService(7)
		 	-- 	:Do(function(_,data)
		 			self.mobileSession = mobile_session.MobileSession(
		      															self,
		      															self.mobileConnection,
		      															config.application1.registerAppInterfaceParams
		      														)
		 			
		 			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
					:Do(function(_,data)
						HMIAppID = data.params.application.appID
						self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID

						self.mobileSession:ExpectEvent(event, "EndService NACK")

						self.mobileSession:ExpectNotification("OnHMIStatus", 
														{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
												)
					end)
		 		end															
		--end
		
-- 	Start video streaming again 
function Test:FULLApp_ResumesVideoStreaming ()
	StreammingResumption(self)
	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})
		:Timeout(17000)
	commonTestCases:DelayedExp(7000)
end

--Verify that SDL does not send OnAudioDataStreaming in case mobile app stops and resumes audio streaming before AudioDataStoppedTimeout is expired

function Test:AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
		:Times(0)

	function StopStream1()
		self.mobileSession:StopStreaming("files/Wildlife.wmv")
	end

	function StartStream1()
		self.mobileSession:StopStreaming("files/Wildlife.wmv")
	end

	RUN_AFTER(StopStream1,5000)
	RUN_AFTER(StartStream1,10000)

	commonTestCases:DelayedExp(25000)

end


--////////////////////////////////////////////////////////////////////////////////////////////--
-- Use case described in APPLINK-16329 Resumption of Audio Service LIMITED 
--////////////////////////////////////////////////////////////////////////////////////////////--

-- Description:

--Resumption of Navi App in LIMITED HMI Level with Audio Streaming on that closed unexpectedly due to transport disconnect

commonFunctions:newTestCasesGroup(" Resumption Navi App in Limited with Audio Streaming ")

-- After registration application is brought to Limited HMI level

function Test:AppInLimited ()
	BringAppToLimitedLevel(self)
end


--Start Audio Service and Streaming 
function Test:LIMITEDApp_StartStreamingAudio ()
	StartAudioServiceAndStreaming(self)
end

--Unexpected Disconnect followed by re-connect and level resumption 

		Test["CloseConnection_LIMITEDAudio"] = function(self)
		  	self.mobileConnection:Close() 
		end

		Test["ConnectMobile_LIMITEDAudio"] = function(self)	
			self:connectMobile()
		end
		
		Test["Resumption_LIMITEDAudio"] = function(self)		
		 	-- self.mobileSession:StartService(7)
		 	-- 	:Do(function(_,data)
		 			self.mobileSession = mobile_session.MobileSession(
		      															self,
		      															self.mobileConnection,
		      															config.application1.registerAppInterfaceParams
		      														)
		 			
		 			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
					:Do(function(_,data)
						HMIAppID = data.params.application.appID
						self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID

						self.mobileSession:ExpectEvent(event, "EndService NACK")

						self.mobileSession:ExpectNotification("OnHMIStatus", 
														{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"}
												)
					end)
		 		end															
		
-- 	Start audio streaming again 
function Test:FULLApp_ResumesAudioStreaming ()
	StreammingResumption(self)
	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
		:Timeout(17000)
	commonTestCases:DelayedExp(7000)
end

--Verify that SDL does not send OnAudioDataStreaming in case mobile app stops and resumes audio streaming before AudioDataStoppedTimeout is expired

function Test:AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	function StopStream1()
		self.mobileSession:StopStreaming("files/Kalimba.mp3")
	end

	function StartStream1()
		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	end

	RUN_AFTER(StopStream1,5000)
	RUN_AFTER(StartStream1,10000)

	commonTestCases:DelayedExp(25000)
end

