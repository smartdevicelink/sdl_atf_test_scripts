Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Begin Precondition.1 
--Description: Activation of applivation

	function Test:ActivationApp()
		  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
		    	if
		        	data.result.isSDLAllowed ~= true then
		            	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

		    			  --EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
		    			  	  EXPECT_HMIRESPONSE(RequestId)
			              :Do(function(_,data)
			    			    --hmi side: send request SDL.OnAllowSDLFunctionality
			    			    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

			    			    --hmi side: expect BasicCommunication.ActivateApp
			    			    EXPECT_HMICALL("BasicCommunication.ActivateApp")
		            				:Do(function(_,data)
				          				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				        			end)
				        			:Times(2)
			              end)
				end
		      end)

		  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})	

	end

--End Precondition.1
---------------------------------------------------------------------------------------------

--Description: CRQ APPLINK-14806 - SDL must send StopStream/StopAudioStream to HMI in case HMI does not respond at least to one StartStream_request
--Test.1: checked that SDL send to HMI StopStream and StopAudioStream to HMI if for StartStream HMI responded SUCCESS but for StartAudioStream retry sequence was unsuccessful
		
	function Test:REJECT_StartAudioStream()
		
		-- start video service 
		self.mobileSession:StartService(11)
	    	:Do(function()
	     	 	print ("\27[32m Video service is started \27[0m ")
	      	end)
	
	    EXPECT_HMICALL("Navigation.StartStream")
  			:Do(function(_,data)
  				-- successful StartStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StartStream", "SUCCESS", {})
    		end)
  	
		-- start AudioService
		self.mobileSession:StartService(10)
	    	:Do(function()
	     	 	print ("\27[32m Audio service is started \27[0m ")
	    	end)
	
		EXPECT_HMICALL("Navigation.StartAudioStream")
  			:Do(function(_,data)
				--hmi side: sending the error response
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
	    	end)
	       	:Times(4) --assumed that StartStreamRetry = 3, 1000 in .ini file by default
	       	--:Times(3) --W/A due to defect APPLINK-13457. Comment this line and uncomment line above after defect fix

  		--after unsuccessfull retry sequence SDL should send StopAudioStream to HMIz
		EXPECT_HMICALL("Navigation.StopAudioStream")
  			:Do(function(_,data)  				
  				-- successful StopAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
			end)							

  		--after unsuccessfull retry sequence SDL should send StopStream to HMI
  		EXPECT_HMICALL("Navigation.StopStream")
  			:Do(function(_,data)
  				-- successful StopStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
	    	end)

  		-- Event: EndService from SDL for audion and video services
 		local event = events.Event()
 		event.matches = function(_, data)
    	    return data.frameType   == 0 and
            	(data.serviceType == 11 or data.serviceType == 10) and
                 data.sessionId   == self.mobileSession.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
 		self.mobileSession:ExpectEvent(event, "EndService")
    	:Timeout(60000)
    	:Times(2)
    	:ValidIf(function(s, data)
               if data.frameInfo == 4  and data.serviceType == 11 
               	then
               	--Mobile side: mobile send EndVideoService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 11,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true

    			elseif data.frameInfo == 4  and data.serviceType == 10 
               	then
               	--Mobile side: mobile send EndAudioService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 10,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true
            
               else return false, "End Service not received" end
        end)    	

	end
		
							
------------------------------------------------------------------------------------------------------------------------------------------------

--Test.2: checked that SDL send to HMI StopStream and StopAudioStream to HMI if for StartAudioStream HMI responded SUCCESS but for StartStream retry sequence was unsuccessful
		
	function Test:REJECT_StartStream()
		
		-- start video service 
		self.mobileSession:StartService(10)
	    	:Do(function()
	     	 	print ("\27[32m Audio service is started \27[0m ")
	      	end)
	
	    EXPECT_HMICALL("Navigation.StartAudioStream")
  			:Do(function(_,data)
  				-- successful StartAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StartAudioStream", "SUCCESS", {})
    		end)
  	
		-- start VideoService
		self.mobileSession:StartService(11)
	    	:Do(function()
	     	 	print ("\27[32m Video service is started \27[0m ")
	    	end)
	
		EXPECT_HMICALL("Navigation.StartStream")
  			:Do(function(_,data)
				--hmi side: sending the error response
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
	    	end)	    	
	    	--:Times(4) --assumed that StartStreamRetry = 3, 1000 in .ini file by default
	       	:Times(3) --W/A due to defect APPLINK-13457. Comment this line and uncomment line above after defect fix


  		--after unsuccessfull retry sequence SDL should send StopAudioStream to HMI
		EXPECT_HMICALL("Navigation.StopAudioStream")
  			:Do(function(_,data)
  				-- successful StopAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
 	    	end)

  		--after unsuccessfull retry sequence SDL should send StopStream to HMI
  		EXPECT_HMICALL("Navigation.StopStream")
  			:Do(function(_,data)
  				-- successful StopStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
	    	end)

	   	-- Event: EndService from SDL for audion and video services
 		local event = events.Event()
 		event.matches = function(_, data)
    	    return data.frameType   == 0 and
            	(data.serviceType == 11 or data.serviceType == 10) and
                 data.sessionId   == self.mobileSession.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
 		self.mobileSession:ExpectEvent(event, "EndService")
    	:Timeout(60000)
    	:Times(2)
    	:ValidIf(function(s, data)
               if data.frameInfo == 4  and data.serviceType == 11 
               	then
               	--Mobile side: mobile send EndVideoService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 11,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true

    			elseif data.frameInfo == 4  and data.serviceType == 10 
               	then
               	--Mobile side: mobile send EndAudioService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 10,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true
            
               else return false, "End Service not received" end
        end)    	

	end

------------------------------------------------------------------------------------------------------------------------------------------------

--Test.3: checked that SDL send to HMI StopStream and StopAudioStream  if for StartStream HMI responded SUCCESS but does not responded for StartAudioStream request
		
	function Test:NoResponse_StartAudioStream()
		
		-- start video service 
		self.mobileSession:StartService(11)
	    	:Do(function()
	     	 	print ("\27[32m Video service is started \27[0m ")
	      	end)
	
	    EXPECT_HMICALL("Navigation.StartStream")
  			:Do(function(_,data)
  				-- successful StartStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StartStream", "SUCCESS", {})
    		end)

		-- start AudioService
		self.mobileSession:StartService(10)
	    	:Do(function()
	     	 	print ("\27[32m Audio service is started \27[0m ")
	    	end)
	
		EXPECT_HMICALL("Navigation.StartAudioStream")
  			:Do(function(_,data)
	    	end)
  		:Timeout(6000)
  		--:Times(4) --assumed that StartStreamRetry = 3, 1000 in .ini file by default
	    :Times(3) --W/A due to defect APPLINK-13457. Comment this line and uncomment line above after defect fix
  		
  		--after unsuccessfull retry sequence SDL should send StopAudioStream to HMI
		EXPECT_HMICALL("Navigation.StopAudioStream")
  			:Do(function(_,data)
  				-- successful StopAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
	    	end)

  		--after unsuccessfull retry sequence SDL should send StopStream to HMI
  		EXPECT_HMICALL("Navigation.StopStream")
  			:Do(function(_,data)
  				-- successful StopStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
	    	end)

	    -- Event: EndService from SDL for audion and video services
 		local event = events.Event()
 		event.matches = function(_, data)
    	    return data.frameType   == 0 and
            	(data.serviceType == 11 or data.serviceType == 10) and
                 data.sessionId   == self.mobileSession.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
 		self.mobileSession:ExpectEvent(event, "EndService")
    	:Timeout(60000)
    	:Times(2)
    	:ValidIf(function(s, data)
               if data.frameInfo == 4  and data.serviceType == 11 
               	then
               	--Mobile side: mobile send EndVideoService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 11,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true

    			elseif data.frameInfo == 4  and data.serviceType == 10 
               	then
               	--Mobile side: mobile send EndAudioService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 10,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true            
                else return false, "End Service not received" end
        end)    	

	end


------------------------------------------------------------------------------------------------------------------------------------------------

--Test.4: checked that SDL send to HMI StopStream and StopAudioStream to HMI if for StartAudioStream HMI responded SUCCESS but does not respond for StartStream request
		
	function Test:NoResponse_StartStream()
		
		-- start video service 
		self.mobileSession:StartService(10)
	    	:Do(function()
	     	 	print ("\27[32m Audio service is started \27[0m ")
	      	end)
	
	    EXPECT_HMICALL("Navigation.StartAudioStream")
  			:Do(function(_,data)
  				-- successful StartAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StartAudioStream", "SUCCESS", {})
    		end)
  		
		-- start VideoService
		self.mobileSession:StartService(11)
	    	:Do(function()
	     	 	print ("\27[32m Video service is started \27[0m ")
	    	end)
	
		EXPECT_HMICALL("Navigation.StartStream")
  			:Do(function(_,data)
	    	end)
    	:Timeout(6000)
  		--:Times(4) --assumed that StartStreamRetry = 3, 1000 in .ini file by default
	    :Times(3) --W/A due to defect APPLINK-13457. Comment this line and uncomment line above after defect fix
  		
  		--after unsuccessfull retry sequence SDL should send StopAudioStream to HMI
		EXPECT_HMICALL("Navigation.StopAudioStream")
  			:Do(function(_,data)
  				-- successful StopAudioStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
	    	end)

  		--after unsuccessfull retry sequence SDL should send StopStream to HMI
  		EXPECT_HMICALL("Navigation.StopStream")
  			:Do(function(_,data)
  				-- successful StopStream on HMI side
    			self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
	    	end)

	    -- Event: EndService from SDL for audion and video services
 		local event = events.Event()
 		event.matches = function(_, data)
    	    return data.frameType   == 0 and
            	(data.serviceType == 11 or data.serviceType == 10) and
                 data.sessionId   == self.mobileSession.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
 		self.mobileSession:ExpectEvent(event, "EndService")
    	:Timeout(60000)
    	:Times(2)
    	:ValidIf(function(s, data)
               if data.frameInfo == 4  and data.serviceType == 11 
               	then
               	--Mobile side: mobile send EndVideoService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 11,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true

    			elseif data.frameInfo == 4  and data.serviceType == 10 
               	then
               	--Mobile side: mobile send EndAudioService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 10,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true
            
               else return false, "End Service not received" end
        end)    	

	end
