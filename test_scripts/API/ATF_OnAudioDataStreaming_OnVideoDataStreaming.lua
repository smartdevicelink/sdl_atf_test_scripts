-- ATF version: 2.2
-- Script is developed by Byanova Irina

Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
-------------------------------------------User functions------------------------------------
---------------------------------------------------------------------------------------------

local function ActivationApp(self, iappID)

	-- hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = iappID})

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
                      		-- {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

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

	self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
end


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

local function RestartSDL( prefix, UpdateAudioDataStoppedTimeout, ValueToUpdate, UpdateVideoDataStoppedTimeout, ValueToUpdateVideo)

	Test["StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "================= Precondition ==================")
		StopSDL()

		commonTestCases:DelayedExp(1000)
	end

	-- Updaete AudioDataStoppedTimeout value in .ini file
	if UpdateAudioDataStoppedTimeout then
		Test["UpdateAudioDataStoppedTimeout_" .. tostring(prefix) ] = function(self)
			commonFunctions:SetValuesInIniFile("%p?AudioDataStoppedTimeout%s?=%s-[%w%d,-]-%s-\n", "AudioDataStoppedTimeout", ValueToUpdate )
		end
	end

	-- Updaete VideoDataStoppedTimeout value in .ini file
	if UpdateVideoDataStoppedTimeout then
		Test["Precondition_UpdateVideoDataStoppedTimeout_" .. tostring(prefix) ] = function(self)
			commonFunctions:SetValuesInIniFile("%p?VideoDataStoppedTimeout%s?=%s-[%w%d,-]-%s-\n", "VideoDataStoppedTimeout", ValueToUpdateVideo )
		end
	end

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

-- Audio streaming 
local function StartAudioServiceAndStreaming(self)
	self.mobileSession:StartService(10)

	EXPECT_HMICALL("Navigation.StartAudioStream")
	    :Do(function(exp,data)
 	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
	     	function to_run2()
	     	-- os.execute( " sleep 1 " )
	     		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	     	end

	     	RUN_AFTER(to_run2, 1500)
	    end)
end

local StopAudioStreamingTime
local function StopAudioStreaming(self)
	 self.mobileSession:StopStreaming("files/Kalimba.mp3")
	 StopAudioStreamingTime = timestamp()
end


-- Video streaming 
local StopVideoStreamingTime
local function StopVideoStreaming(self)
	 self.mobileSession:StopStreaming("files/Wildlife.wmv")
	 StopVideoStreamingTime = timestamp()
end

local function StartVideoServiceAndStreaming(self)
	self.mobileSession:StartService(11)

	EXPECT_HMICALL("Navigation.StartStream")
	    :Do(function(_,data)
 	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
	     	function to_run2()
	     	-- os.execute( " sleep 1 " )
	     		self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
	     	end

	     	RUN_AFTER(to_run2, 1500)
	    end)
end

local function StreammingsAfterSDLRestart(self, prefix, AudioStream, VideoStream, UpdateAudioDataStoppedTimeout, ValueToUpdate, ValueToExpect, UpdateVideoDataStoppedTimeout, ValueToUpdateVideo, ValueToExpectVideo)

	RestartSDL(prefix,UpdateAudioDataStoppedTimeout, ValueToUpdate, UpdateVideoDataStoppedTimeout, ValueToUpdateVideo )

	--Precondition: Activate app
	Test["ActivateApp_" .. tostring(prefix)] = function(self)
		ActivationApp(self, self.appId)
	end

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


		Test["StopAudioStreaming_" .. tostring(prefix)] = function(self)

			StopAudioStreaming(self)

			EXPECT_HMICALL("Navigation.StopAudioStream")
		    :Times(0)

			EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})
			:Timeout(11000 + ValueToExpect)
		    :ValidIf(function(_,data)
		     	local currentTime = timestamp()
		     	local TimeToAvailableFalse = currentTime - StopAudioStreamingTime

		     	if TimeToAvailableFalse > ValueToExpect then
		     		commonFunctions:userPrint(31, "Time to OnAudioDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
		     		return false
		     	else
		     		commonFunctions:userPrint(33, "Time to OnAudioDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
		     		return true
		     	end
		    end)
		end

		Test["StopAudioService_" .. tostring(prefix)] = function(self)

			self.mobileSession:StopService(10)

			EXPECT_HMICALL("Navigation.StopAudioStream")
		    :Do(function(_,data)
		     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
		    end)
		end
	end

	-----------------------------------

	if VideoStream == true then
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


		Test["StopVideoStreaming_" .. tostring(prefix)] = function(self)

			StopVideoStreaming(self)

			EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = false})
		    :ValidIf(function(_,data)
		     	local currentTime = timestamp()
		     	local TimeToAvailableFalse = currentTime - StopAudioStreamingTime

		     	if TimeToAvailableFalse > ValueToExpectVideo then
		     		commonFunctions:userPrint(31, "Time to OnVideoDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
		     		return false
		     	else
		     		commonFunctions:userPrint(33, "Time to OnVideoDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
		     		return true
		     	end
		    end)
		end

		Test["StopAudioService_" .. tostring(prefix)] = function(self)

			self.mobileSession:StopService(11)

			EXPECT_HMICALL("Navigation.StopStream")
		    :Do(function(_,data)
		     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
		    end)
		end
	end

	Test["UnregisterApp_" .. tostring(prefix)] = function(self)

		--mobile side: UnregisterAppInterface request 
		local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

		--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
	 
		--mobile side: UnregisterAppInterface response 
		EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end

end

commonFunctions:userPrint(33, " Audio and Video time measured in script is approximate. Please check SDL log to make sure that time of audio and video timeout is correct. ") 

-- Precondition: Respore .ini file
function Test:RestoreIniFile()
	commonSteps:RestoreIniFile()
end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Audio streaming
--////////////////////////////////////////////////////////////////////////////////////////////--

-- TODO: APPLINK-22275: According to customer comment from APPLINK-11709 for now SDL does not validate wrong type of AudioDataStoppedTimeout. In case of adding implementation according to type validation please add test cases to set. 

-- APPLINK-18043: 12[P][MAN]_TC_SDL_initializes_ AudioDataStoppedTimeout_from_ini.file
-- APPLINK-18041: 10[P][MAN]_TC_SDL_sends_OnAudioDataStreaming_in_FULL
--======================================================================================--
-- AudioDataStoppedTimeout = 5000, SDL sends OnAudioDataStreaming(true) by streaming start, OnAudioDataStreaming(false) in 5 seconds after mobile stops send audio data
--======================================================================================--
commonFunctions:newTestCasesGroup(" AudioDataStoppedTimeout = 5000, SDL sends OnAudioDataStreaming(false) in 5 seconds after mobile stops send audio data")

StreammingsAfterSDLRestart(self, "OnAudioDataStreaming_in5sec_afterStopStreaming", true, _, true, "5000", 5000)

-- APPLINK-18043: 12[P][MAN]_TC_SDL_initializes_ AudioDataStoppedTimeout_from_ini.file
--======================================================================================--
-- AudioDataStoppedTimeout = 10000, SDL sends OnAudioDataStreaming(true) by streaming start, OnAudioDataStreaming(false) in 10 seconds after mobile stops send audio data
--======================================================================================--
commonFunctions:newTestCasesGroup(" AudioDataStoppedTimeout = 10000, SDL sends OnAudioDataStreaming(false) in 10 seconds after mobile stops send audio data")

StreammingsAfterSDLRestart(self, "OnAudioDataStreaming_in10sec_afterStopStreaming", true, _, true, "10000", 10000)

-- APPLINK-18043: 12[P][MAN]_TC_SDL_initializes_ AudioDataStoppedTimeout_from_ini.file
--======================================================================================--
-- AudioDataStoppedTimeout = -1, SDL apply default value 1 second and sends OnAudioDataStreaming(false) in 1 second after mobile stops send audio data
--======================================================================================--
commonFunctions:newTestCasesGroup(" AudioDataStoppedTimeout = -1, SDL sends OnAudioDataStreaming(false) in 1 second after mobile stops send audio data")

StreammingsAfterSDLRestart(self, "AudioTimeoutIsNegativeValue_OnAudioDataStreaming_in1sec_afterStopStreaming", true, _, true, "-1", 1000)

-- APPLINK-18043: 12[P][MAN]_TC_SDL_initializes_ AudioDataStoppedTimeout_from_ini.file
--======================================================================================--
-- AudioDataStoppedTimeout = 0, SDL apply value 0 second and sends OnAudioDataStreaming(false) right after mobile stops send audio data
--======================================================================================--
commonFunctions:newTestCasesGroup(" AudioDataStoppedTimeout = 0, SDL sends OnAudioDataStreaming(false) right after mobile stops send audio data")

StreammingsAfterSDLRestart(self, "AudioTimeoutIsNill_OnAudioDataStreaming_right_afterStopStreaming", true, _, true, "0", 0)

--======================================================================================--
-- AudioDataStoppedTimeout is commented, SDL apply default value 1 second and sends OnAudioDataStreaming(false) in 1 second after mobile stops send audio data
--======================================================================================--
commonFunctions:newTestCasesGroup(" AudioDataStoppedTimeout is commented, SDL sends OnAudioDataStreaming(false) in 1 second after mobile stops send audio data")

StreammingsAfterSDLRestart(self, "AudioTimeoutIsAbsentInIniFile_OnAudioDataStreaming_in1sec_afterStopStreaming", true, _, true, ";", 1000)

--======================================================================================--
-- AudioDataStoppedTimeout = 10000, SDL does not send OnAudioDataStreaming in case mobile app stops and resumes audio streaming before AudioDataStoppedTimeout is expired
--======================================================================================--
commonFunctions:newTestCasesGroup(" SDL does not send OnAudioDataStreaming in case mobile app stops and resumes audio streaming before AudioDataStoppedTimeout is expired ")

RestartSDL("SetAudioTimeout_to10000",true, "10000" )

--Precondition: Activate app
function Test:ActivateApp_AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()
	ActivationApp(self, self.appId)
end

function Test:StartAudioServiceStreaming_AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	StartAudioServiceAndStreaming(self)

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
		:Timeout(17000)

	commonTestCases:DelayedExp(7000)
end

function Test:AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	function StopStream1()
		self.mobileSession:StopStreaming("files/Kalimba.mp3")
	end

	function StartStream1()
		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	end

	function StopStream2()
		self.mobileSession:StopStreaming("files/Kalimba.mp3")
	end

	function StartStream2()
		self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	end

	RUN_AFTER(StopStream1,5000)
	RUN_AFTER(StartStream1,10000)
	RUN_AFTER(StopStream2,15000)
	RUN_AFTER(StartStream2,20000)

	commonTestCases:DelayedExp(25000)

end

function Test:StopAudioStreaming_AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()
	StopAudioStreaming(self)

	EXPECT_HMICALL("Navigation.StopAudioStream")
    :Times(0)

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})
	:Timeout(21000)
    :Do(function(_,data)

     	local currentTime = timestamp()
     	local TimeToAvailableFalse = currentTime - StopAudioStreamingTime

     	if TimeToAvailableFalse >  1000 then
     		commonFunctions:userPrint(31, "Time to OnAudioDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
     	else
     		commonFunctions:userPrint(33, "Time to OnAudioDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
     	end
    end)
end

function Test:StopAudioService_AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()

	self.mobileSession:StopService(10)

	EXPECT_HMICALL("Navigation.StopAudioStream")
    :Do(function(_,data)
     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function Test:UnregisterApp_AbsenceOnAudioDataStreamingByStartStopStreamingInAudioDataStoppedTimeout()
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
 
	--mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)

end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Video streaming
--////////////////////////////////////////////////////////////////////////////////////////////--

-- TODO: APPLINK-22275: According to customer comment from APPLINK-11709 for now SDL does not validate wrong type of VideoDataStoppedTimeout. In case of adding implementation according to type validation please add test cases to set.

-- APPLINK-18042: 11[P][MAN]_TC_SDL_initializes_VideoDataStoppedTimeout_from_ini.file
-- APPLINK-18039: 09[P][MAN]_TC_SDL_sends_OnVideoDataStreaming_in_FULL
--======================================================================================--
-- VideoDataStoppedTimeout = 5000, SDL sends OnVideoDataStreaming(true) by streaming start, OnVideoDataStreaming(false) in 5 seconds after mobile stops send video data
--======================================================================================--
commonFunctions:newTestCasesGroup(" VideoDataStoppedTimeout = 5000, SDL sends OnVideoDataStreaming(false) in 5 seconds after mobile stops send video data")

StreammingsAfterSDLRestart(self, "OnVideoDataStreaming_in5sec_afterStopStreaming", _, true, _, _, _, true, "5000", 5000)

-- APPLINK-18042: 11[P][MAN]_TC_SDL_initializes_VideoDataStoppedTimeout_from_ini.file
--======================================================================================--
-- VideoDataStoppedTimeout = 10000, SDL sends OnVideoDataStreaming(true) by streaming start, OnVideoDataStreaming(false) in 10 seconds after mobile stops send video data
--======================================================================================--
commonFunctions:newTestCasesGroup(" VideoDataStoppedTimeout = 10000, SDL sends OnVideoDataStreaming(false) in 10 seconds after mobile stops send video data")

StreammingsAfterSDLRestart(self, "OnVideoDataStreaming_in10sec_afterStopStreaming", _, true, _, _, _, true, "10000", 10000)

-- APPLINK-18042: 11[P][MAN]_TC_SDL_initializes_VideoDataStoppedTimeout_from_ini.file
--======================================================================================--
-- VideoDataStoppedTimeout = -1, SDL apply default value 1 second and sends OnVideoDataStreaming(false) in 1 second after mobile stops send video data
--======================================================================================--
commonFunctions:newTestCasesGroup(" VideoDataStoppedTimeout = -1, SDL sends OnVideoDataStreaming(false) in 1 second after mobile stops send video data")

StreammingsAfterSDLRestart(self, "VideoTimeoutIsNegativeValue_OnVideoDataStreaming_in1sec_afterStopStreaming", _, true, _, _, _, true, "-1", 1000)

-- APPLINK-18042: 11[P][MAN]_TC_SDL_initializes_VideoDataStoppedTimeout_from_ini.file
--======================================================================================--
-- VideoDataStoppedTimeout = 0, SDL apply value 0 second and sends OnVideoDataStreaming(false) right after mobile stops send video data
--======================================================================================--
commonFunctions:newTestCasesGroup(" VideoDataStoppedTimeout = 0, SDL sends OnVideoDataStreaming(false) right after mobile stops send video data")

StreammingsAfterSDLRestart(self, "VideoTimeoutIsNill_OnVideoDataStreaming_right_afterStopStreaming", _, true, _, _, _, true, "0", 0)

--======================================================================================--
-- VideoDataStoppedTimeout is commented, SDL apply default value 1 second and sends OnVideoDataStreaming(false) in 1 second after mobile stops send video data
--======================================================================================--
commonFunctions:newTestCasesGroup(" VideoDataStoppedTimeout is commented, SDL sends OnVideoDataStreaming(false) in 1 second after mobile stops send video data")

StreammingsAfterSDLRestart(self, "VideoTimeoutIsAbsentInIniFile_OnVideoDataStreaming_in1sec_afterStopStreaming", _, true, _, _, _, true, ";", 1000)

--======================================================================================--
-- VideoDataStoppedTimeout = 10000, SDL does not send OnVideoDataStreaming(false) in case mobile app stops and resumes video streaming before VideoDataStoppedTimeout is expired
--======================================================================================--
commonFunctions:newTestCasesGroup("  SDL does not send OnVideoDataStreaming(false) in case mobile app stops and resumes video streaming before VideoDataStoppedTimeout is expired ")

RestartSDL("SetVideoTimeout_to10000", _, _, true, "10000")

--Precondition: Activate app
function Test:ActivateApp_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()
	ActivationApp(self, self.appId)
end

function Test:StartVideoServiceStreaming_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()

	StartVideoServiceAndStreaming(self)

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})
		:Timeout(17000)

	commonTestCases:DelayedExp(7000)
end

function Test:AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
		:Times(0)

	function StopStream1()
		self.mobileSession:StopStreaming("files/Wildlife.wmv")
	end

	function StartStream1()
		self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
	end

	function StopStream2()
		self.mobileSession:StopStreaming("files/Wildlife.wmv")
	end

	function StartStream2()
		self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
	end

	RUN_AFTER(StopStream1,5000)
	RUN_AFTER(StartStream1,10000)
	RUN_AFTER(StopStream2,15000)
	RUN_AFTER(StartStream2,20000)

	commonTestCases:DelayedExp(25000)

end

function Test:StopVideoStreaming_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()
	StopVideoStreaming(self)

	EXPECT_HMICALL("Navigation.StopStream")
    :Times(0)

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = false})
	:Timeout(21000)
    :Do(function(_,data)

     	local currentTime = timestamp()
     	local TimeToAvailableFalse = currentTime - StopAudioStreamingTime

     	if TimeToAvailableFalse >  1000 then
     		commonFunctions:userPrint(31, "Time to OnVideoDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
     	else
     		commonFunctions:userPrint(33, "Time to OnVideoDataStreaming(available = false) is " .. tostring(TimeToAvailableFalse)) 
     	end
    end)
end

function Test:StopVideoService_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()

	self.mobileSession:StopService(11)

	EXPECT_HMICALL("Navigation.StopStream")
    :Do(function(_,data)
     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function Test:UnregisterApp_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
 
	--mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)

end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Video, Audio streaming
--////////////////////////////////////////////////////////////////////////////////////////////--

--======================================================================================--
-- Start Video streaming in case Audio streaming is in process 
--======================================================================================--
commonFunctions:newTestCasesGroup("  SDL sends OnVideoDataStreaming(available = true) in case audio streaming is processed ")

RestartSDL("SetVideoAudioTimeout_to5000", true, "5000", true, "5000")

function Test:ActivateApp_StartVideoService_WhenAudioDataProcesses()
	ActivationApp(self, self.appId)
end

function Test:StartAudioVideoServices()

	self.mobileSession:StartService(10)

	EXPECT_HMICALL("Navigation.StartAudioStream")
	    :Do(function(_,data)
	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
	    end)

	self.mobileSession:StartService(11)

	EXPECT_HMICALL("Navigation.StartStream")
	    :Do(function(_,data)
	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
	    end)

end

function Test:StartAudioStreaming()

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})

end

function Test:StartVideoService_WhenAudioDataProcesses()

	self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})

end

--======================================================================================--
-- Start Audio streaming in case Video streaming is in process 
--======================================================================================--
commonFunctions:newTestCasesGroup("  SDL sends OnAudioDataStreaming(available = true) in case video streaming is processed ")

function Test:StopAudioService()

	self.mobileSession:StopStreaming("files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})

end

function Test:StartAudioStreaming_WhenVideoDataProcesses()

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})

end


function Test:StopVideoAudioServices()

	self.mobileSession:StopService(11)
	self.mobileSession:StopService(10)

	EXPECT_HMICALL("Navigation.StopStream")
    :Do(function(_,data)
     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

    EXPECT_HMICALL("Navigation.StopAudioStream")
    :Do(function(_,data)
     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function Test:UnregisterApp_AbsenceOnVideoDataStreamingByStartStopStreamingInVideoDataStoppedTimeout()
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
 
	--mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)

end

--======================================================================================--
-- SDL does not sends OnVideoDataStreaming, OnAudioDataStreaming to HMI in case mobile app starts streaming without opened service
--======================================================================================--
commonFunctions:newTestCasesGroup(" SDL does not sends OnVideoDataStreaming, OnAudioDataStreaming to HMI in case mobile app starts streaming without opened service ")

RestartSDL("SetVideoAudioTimeout_to5000", true, "5000", true, "5000")

function Test:ActivateApp_WihoutStartingService()
	ActivationApp(self, self.appId)
end

function Test:StartAudioStreaming_WihoutStartingService()

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	commonTestCases:DelayedExp(1000)

end

function Test:StartVideoService_WhenAudioDataProcesses_WihoutStartingService()

	self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
		:Times(0)

	commonTestCases:DelayedExp(1000)

end

--======================================================================================--
-- SDL sends OnVideoDataStreaming, OnAudioDataStreaming in LIMITED HMI level
--======================================================================================--

commonFunctions:newTestCasesGroup(" SDL sends OnVideoDataStreaming, OnAudioDataStreaming in LIMITED HMI level ")

RestartSDL("SetVideoAudioTimeout_to5000", true, "5000", true, "5000")

function Test:BringAppToLimited()
	-- hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appId})

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
                      		-- {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

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

	self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
        { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
		:Do(function(_, data)
			-- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.appId})
		end)
		:Times(2)
end

function Test:StartAudioVideoServices_Limited()

	self.mobileSession:StartService(10)

	EXPECT_HMICALL("Navigation.StartAudioStream")
	    :Do(function(_,data)
	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
	    end)

	self.mobileSession:StartService(11)

	EXPECT_HMICALL("Navigation.StartStream")
	    :Do(function(_,data)
	     	self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
	    end)

end


function Test:StartAudioVideoStreaming_Limited()

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})

end

function Test:StopStreamings_Limited()
	self.mobileSession:StopStreaming("files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})

	self.mobileSession:StopStreaming("files/Wildlife.wmv")

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = false})

end

-- APPLINK-18037: 07[N][MAN]_TC_Video_streaming_is_not_available_in_BACKGROUND
-- APPLINK-18038: 08[N][MAN]_TC_Audio_streaming_is_not_available_in_BACKGROUND
--======================================================================================--
-- SDL doe not send OnVideoDataStreaming, OnAudioDataStreaming in Background HMI level
--======================================================================================--
commonFunctions:newTestCasesGroup(" SDL doe not send OnVideoDataStreaming, OnAudioDataStreaming in Background HMI level ")

function Test:BringAppToBackground()
	config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

	self.mobileSession1 = mobile_session.MobileSession(
        self,
        self.mobileConnection)

	self.mobileSession1:StartService(7)
    :Do(function()
      	local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

	  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					      {
					        application = 
					        {
					          	appName = config.application2.registerAppInterfaceParams.appName
					        }
					      })
	      	:Do(function(_,data)
	        	local appId = data.params.application.appID
	        	self.appId2 = appId
	        end)

	  	self.mobileSession1:ExpectResponse(CorIdRAI, {
	      	success = true,
	      	resultCode = "SUCCESS"
	  	})
      	:Timeout(2000)

	    self.mobileSession1:ExpectNotification("OnHMIStatus", 
	        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},
	        { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
	    :Times(2)
	    :DoOnce(function(_,data)
	    	-- hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appId2 })

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
		                      		-- {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

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

			self.mobileSession:ExpectNotification("OnHMIStatus", 
		        { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
	    end)

    end)
end

function Test:StartAudioVideoStreaming_Background()

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
	self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming")
		:Times(0)


	local event = events.Event()
	 event.matches = function(_, data)
	                   return data.frameType   == 0 and
	                          (data.serviceType == 11 or
	                          data.serviceType == 10) and
	                          data.sessionId   == self.mobileSession.sessionId and
	                         (data.frameInfo   == 5 or -- End Service ACK
	                          data.frameInfo   == 6)   -- End Service NACK
	                 end
	 self.mobileSession:ExpectEvent(event, "EndService ACK")
	    :Timeout(60000)
	    :Times(2)
	    :ValidIf(function(s, data)
	               if data.frameInfo == 5 then return true
	               else return false, "EndService NACK received" end
	             end)

	commonTestCases:DelayedExp(1000)

end

function Test:StopStreamings_Background()
	self.mobileSession:StopStreaming("files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

	self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")

	EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming")
		:Times(0)

end



