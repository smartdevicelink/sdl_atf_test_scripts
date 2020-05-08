Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "AlertManeuver" -- use for above required scripts.
----------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

config.SDLStoragePath = config.pathToSDL .. "storage/"
local pathToIconFolder =  config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")

local imageValues = {"a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"}
local imageTypes ={"STATIC", "DYNAMIC"}

local SBType = { "IMAGE", "BOTH", "TEXT" }

require('user_modules/AppTypes')

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
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

local function ExpectOnHMIStatusWithAudioStateChanged(self, request, timeout, level)

	if request == nil then  request = "TTS" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if 
		self.isMediaApplication == true or 
		Test.appHMITypes["NAVIGATION"] == true then 
			if request == "TTS" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			elseif request == "VR" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	elseif 
		self.isMediaApplication == false then

			--any OnHMIStatusNotifications
			EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
				:Timeout(timeout)

			DelayedExp(1000)
	end

end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
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
		            	--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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

	end

	--End Precondition.1

	--Begin Precondition.2
	--TODO: Will be updated after policy flow implementation
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"}) 

	--Description: Update Policy with AlertManeuver softButtons are true
	-- function Test:Precondition_PolicyUpdate()
		-- --hmi side: sending SDL.GetURLS request
		-- local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
		-- --hmi side: expect SDL.GetURLS response from HMI
		-- EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
		-- :Do(function(_,data)
			-- --print("SDL.GetURLS response is received")
			-- --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			-- self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
				-- {
					-- requestType = "PROPRIETARY",
					-- fileName = "filename"
				-- }
			-- )
			-- --mobile side: expect OnSystemRequest notification 
			-- EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
			-- :Do(function(_,data)
				-- --print("OnSystemRequest notification is received")
				-- --mobile side: sending SystemRequest request 
				-- local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
					-- {
						-- fileName = "PolicyTableUpdate",
						-- requestType = "PROPRIETARY"
					-- },
				-- "files/PTU_AlertManeuverSoftButtonsTrue.json")
				
				-- local systemRequestId
				-- --hmi side: expect SystemRequest request
				-- EXPECT_HMICALL("BasicCommunication.SystemRequest")
				-- :Do(function(_,data)
					-- systemRequestId = data.id
					-- --print("BasicCommunication.SystemRequest is received")
					
					-- --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					-- self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
						-- {
							-- policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
						-- }
					-- )
					-- function to_run()
						-- --hmi side: sending SystemRequest response
						-- self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
					-- end
					
					-- RUN_AFTER(to_run, 500)
				-- end)
				
				-- --hmi side: expect SDL.OnStatusUpdate
				-- EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				-- :ValidIf(function(exp,data)
					-- if 
						-- exp.occurences == 1 and
						-- data.params.status == "UP_TO_DATE" then
							-- return true
					-- elseif
						-- exp.occurences == 1 and
						-- data.params.status == "UPDATING" then
							-- return true
					-- elseif
						-- exp.occurences == 2 and
						-- data.params.status == "UP_TO_DATE" then
							-- return true
					-- else 
						-- if 
							-- exp.occurences == 1 then
								-- print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						-- elseif exp.occurences == 2 then
								-- print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						-- end
						-- return false
					-- end
				-- end)
				-- :Times(Between(1,2))
				
				-- --mobile side: expect SystemRequest response
				-- EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				-- :Do(function(_,data)
					-- --print("SystemRequest is received")
					-- --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					-- local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
					
					-- --hmi side: expect SDL.GetUserFriendlyMessage response
					-- -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
					-- EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
					-- :Do(function(_,data)
						-- print("SDL.GetUserFriendlyMessage is received")			
					-- end)
				-- end)
				
			-- end)
		-- end)
	-- end

	--End Precondition.2

	--Begin Precondition.3
	--Description: PutFile with file names "a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"
	
		for i=1,#imageValues do
			Test["Precondition_" .. "PutImage" .. tostring(imageValues[i])] = function(self)

				--mobile request
				local CorIdPutFile = self.mobileSession:SendRPC(
										"PutFile",
										{
											syncFileName =imageValues[i],
											fileType = "GRAPHIC_PNG",
											persistentFile = false,
											systemFile = false,	
										}, "files/icon.png")

				--mobile response
				EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
					:Timeout(12000)
			 
			end
		end
	--End Precondition.3



---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------------------------------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)-----------------------------------
---------------------------------------------------------------------------------------------

	--Begin Test suit <TestSuitName>
	--Description:
		-- request with all parameters
        -- request with only mandatory parameters
        -- request with all combinations of conditional-mandatory parameters (if exist)
        -- request with one by one conditional parameters (each case - one conditional parameter)
        -- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
        -- request with all parameters are missing
        -- request with fake parameters (fake - not from protocol, from another request)
        -- request is sent with invalid JSON structure
        -- different conditions of correlationID parameter (invalid, several the same etc.)
		
		
		--Begin Test case CommonRequestCheck.1
		--Description: Positive case and in boundary conditions (with conditional parameters) 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-125, SDLAQ-CRS-3075

			--Verification criteria:
			 -- The app notifies user about navigation maneuver via UI notification, TTS information or via both way at a time.
			 -- SDL must always include app's internal appID to Navigation.AlertManeuver request when transferring AlertManeuver from this app to HMI
		
			function Test:AlertManeuver_Positive() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{ 
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 821,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "BOTH",
																			text = "AnotherClose",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = false,
																			softButtonID = 822,
																			systemAction = "DEFAULT_ACTION",
																		},
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											text = "Close",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											text = "AnotherClose",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder.. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end

		--End Test case CommonRequestCheck.1

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-125

			--Verification criteria: The app notifies user about navigation maneuver via UI notification, TTS information or via both way at a time.

			--Begin Test case CommonRequestCheck.2.1
			--Description: only mandatory ttsChunks

				function Test:AlertManeuver_MandatoryOnlyTtsChunks()

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}
																	
																	})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{
									appID = self.applications["Test Application"]
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									speakType = "ALERT_MANEUVER",
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										}

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end


			--End Test case CommonRequestCheck.2.1

			--Begin Test case CommonRequestCheck.2.2
			--Description: only mandatory softButtons

				function Test:AlertManeuver_MandatoryOnlySoftButtons()

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}, 
																			
																			{ 
																				type = "BOTH",
																				text = "AnotherClose",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = false,
																				softButtonID = 822,
																				systemAction = "DEFAULT_ACTION",
																			},
																		}
																	
																	})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											text = "Close",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											text = "AnotherClose",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										},
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)


			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

				end

			--End Test case CommonRequestCheck.2.2

		--End Test case CommonRequestCheck.2

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-125, SDLAQ-CRS-675, SDLAQ-CRS-200

			--Verification criteria: 
					-- Mandatory parameters not provided
					-- The request without "ttsChunks" and without "softButtons" is sent, the response with INVALID_DATA code is returned.

			--Begin Test case CommonRequestCheck.3.1
			--Description: without all parameters

				function Test:AlertManeuver_MissingAllParams() 

					--mobile side: AlertManeuver request 
				  	local CorIdAlertM = self.mobileSession:SendRPC( "AlertManeuver", {})
			 
				  	--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	

			 	end

		 	--End Test case CommonRequestCheck.3.1

		 	--Begin Test case CommonRequestCheck.3.2
			--Description: ttsChunks: Text is missing 

				function Test:AlertManeuver_ttsChunksTextMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							ttsChunks = 
							{ 
								
								{ 
									type ="TEXT",
								}, 
							}, 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
 				end 

			--End Test case CommonRequestCheck.3.2

			--Begin Test case CommonRequestCheck.3.3
			--Description: ttsChunks: Type is missing

				function Test:AlertManeuver_ttsChunksTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							ttsChunks = 
							{ 
								
								{ 
									text ="FirstAlert",
								}, 
							}, 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.3

			--Begin Test case CommonRequestCheck.3.4
			--Description: softButtons: Type is missing

				function Test:AlertManeuver_SBTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							softButtons = 
							{ 
								
								{ 
									text ="Close",
									image =	
									{ 
										value ="icon.png",
										imageType ="DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 1234,
									systemAction ="DEFAULT_ACTION",
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.4

			--Begin Test case CommonRequestCheck.3.5
			--Description: softButtons: softButtonID is missing

				function Test:AlertManeuver_SBSoftButtonIDMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							softButtons = 
							{ 
								
								{ 
									type ="BOTH",
									text ="Close",
									image =	
									{ 
										value ="icon.png",
										imageType ="DYNAMIC",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.5

			--Begin Test case CommonRequestCheck.3.6
			--Description: softButtons: type "IMAGE", image value is missing

				function Test:AlertManeuver_SBIMAGEImageValueMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
							softButtons = 
							{ 
								
								{ 
									type ="IMAGE",
									text ="Close",
									image =	
									{ 
										imageType ="DYNAMIC",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
									softButtonID = 1
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.6

			--Begin Test case CommonRequestCheck.3.7
			--Description: softButtons: type "IMAGE", image type is missing

				function Test:AlertManeuver_SBIMAGEImageTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
							softButtons = 
							{ 
								
								{ 
									type ="IMAGE",
									text ="Close",
									image =	
									{ 
										value ="icon.png",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
									softButtonID = 1
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.7

			--Begin Test case CommonRequestCheck.3.7
			--Description: softButtons: type "IMAGE", image type is missing

				function Test:AlertManeuver_SBIMAGEImageTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
							softButtons = 
							{ 
								
								{ 
									type ="IMAGE",
									text ="Close",
									image =	
									{ 
										value ="icon.png",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
									softButtonID = 1
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.7

			--Begin Test case CommonRequestCheck.3.8
			--Description: softButtons: type "BOTH", image type is missing

				function Test:AlertManeuver_SBBOTHImageTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
							softButtons = 
							{ 
								
								{ 
									type ="BOTH",
									text ="Close",
									image =	
									{ 
										value ="icon.png",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
									softButtonID = 1
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.8

			--Begin Test case CommonRequestCheck.3.9
			--Description: softButtons: type "BOTH", image type is missing

				function Test:AlertManeuver_SBBOTHImageTypeMissing() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
							softButtons = 
							{ 
								
								{ 
									type ="BOTH",
									text ="Close",
									image =	
									{ 
										value ="icon.png",
									}, 
									isHighlighted = true,
									systemAction ="DEFAULT_ACTION",
									softButtonID = 1
								}
							} 
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
				end 

			--End Test case CommonRequestCheck.3.9

			--Begin Test case CommonRequestCheck.3.10
			--Description: softButtons: all type, isHighlighted is missing

				for i=1,#SBType do
					Test["AlertManeuver_SB".. tostring(SBType[i]) .."isHighlightedMissing"] = function(self)
						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = SBType[i],
										text = "Close",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										},
										systemAction ="DEFAULT_ACTION",
										softButtonID = 1
									}
								} 
							
							}) 
						local buttonText
						if SBType[i] == "IMAGE" then
							buttonText = nil 
						else
							buttonText = "Close"
						end

						EXPECT_HMICALL("Navigation.AlertManeuver",
										{
											appID = self.applications["Test Application"],
											softButtons = 
											{ 
												
												{ 
													type = SBType[i],
													text = buttonText,
													 --[[ TODO: update after resolving APPLINK-16052

													image =	
													{ 
														value = pathToIconFolder .. "icon.png",
														imageType ="DYNAMIC",
													},]]
													systemAction ="DEFAULT_ACTION",
													softButtonID = 1
												}
											}
										})
							:ValidIf(function(_,data)

								if data.params.softButtons[1].isHighlighted then 
									print ("\27[36m Navigation.AlertManeuver request came with isHighlighted parameter \27[0m")
									return false
								else
									self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
									return true
								end
							end)
						 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
							:Timeout(11000) 	

					end
				end 

			--End Test case CommonRequestCheck.3.10

		--End Test case CommonRequestCheck.3

		--Begin Test case CommonRequestCheck.4
		--Description: This part of tests is intended to verify receiving appropriate responses when request is sent with different fake parameters 

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck.4.1
			--Description: With fake parameters (SUCCESS) 

			function Test:AlertManeuver_FakeParam() 

					--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
					{
					  	 
						fakeParam ="fakeParam",
						ttsChunks = 
						{ 
							
							{ 
								text ="FirstAlert",
								type ="TEXT",
								fakeParam ="fakeParam",
							}, 
							
							{ 
								text ="SecondAlert",
								type ="TEXT",
							}, 
						}, 
					
					})

				EXPECT_HMICALL("Navigation.AlertManeuver")
					:ValidIf(function(_,data)

						if data.params.fakeParam then 
							print ("\27[35m Navigation.AlertManeuver request came with fake parameter \27[0m")
							return false
						else
							self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
							return true
						end
					end)


				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									speakType = "ALERT_MANEUVER",
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										}

								})
					:ValidIf(function(_,data)

						if 
							data.params.fakeParam or data.params.ttsChunks[1].fakeParam then
								print ("\27[35m TTS.Speak request came with fake params \27[0m")

								--mobile side: expect AlertManeuver response
				    			EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
				    				:Timeout(11000)
				    			:Timeout(11000)

								return false
						else
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 1000)

							return true
						end
					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)


			end

			--End Test case CommonRequestCheck.4.1

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request (INVALID_DATA)

				function Test:AlertManeuver_OnlyParamsAnotherRequest() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							mainField1 ="Show1",
							mainField2 ="Show2",
							mainField3 ="Show3",
							mainField4 ="Show4",
						
						}) 
					 
					--mobile side: expect AlertManeuver response
					EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						:Timeout(11000) 	
			 	end 

			--End Test case CommonRequestCheck.4.2

			--Begin Test case CommonRequestCheck.4.3
			--Description: Parameters from another request (SUCCESS)

				function Test:AlertManeuver_ParamsAnotherRequest()

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	},
																	mainField1 ="Show1",
																	mainField2 ="Show2",
																	mainField3 ="Show3",
																	mainField4 ="Show4"
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver")
					:ValidIf(function(_,data)

						if data.params.mainField1 or data.params.mainField2 or data.params.mainField3 or data.params.mainField4 or data.params.showStrings   then 
							print ("\27[35m Navigation.AlertManeuver request came with fake parameter \27[0m")
							return false
						else
							self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
							return true
						end
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									speakType = "ALERT_MANEUVER",
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										}

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)
			end

			--End Test case CommonRequestCheck.4.3

		--End Test case CommonRequestCheck.4

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-675

			--Verification criteria:  The request with wrong JSON syntax is sent, the response with INVALID_DATA code is returned. 

			function Test:AlertManeuver_InvalidJSON()

				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg = 
				  {
				    serviceType      = 7,
				    frameInfo        = 0,
				    rpcType          = 0,
				    rpcFunctionId    = 28,
				    rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':' after "softButtons"
				    payload          = '{"softButtons"  [{"softButtonID":3,"type":"BOTH","text":"Close","systemAction":"DEFAULT_ACTION","isHighlighted":true,"image":{"imageType":"DYNAMIC","value":"icon.png"}},{"softButtonID":4,"type":"TEXT","text":"Keep","systemAction":"KEEP_CONTEXT","isHighlighted":true},{"softButtonID":5,"type":"IMAGE","systemAction":"STEAL_FOCUS","image":{"imageType":"DYNAMIC","value":"icon.png"}}],"ttsChunks":{{"type":"TEXT","text":"TTSChunk"}}}'
				  }
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end

		--End Test case CommonRequestCheck.5

		--Begin Test case CommonRequestCheck.6
		--Description: correlationID: duplicate value
		--TODO: update requirements, verification criteria
			--Requirement id in JAMA/or Jira ID:

			--Verification criteria:

				function Test:AlertManeuver_correlationIDDuplicateValue()

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{ 
																		ttsChunks = 
																		{ 
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}
																		}
																	})
				  	local msg = 
				  	{
				    	serviceType      = 7,
				    	frameInfo        = 0,
				    	rpcType          = 0,
				    	rpcFunctionId    = 28,
				    	rpcCorrelationId = CorIdAlertM,
					--<<!-- missing ':' after "softButtons"
				    	payload          = '{"ttsChunks":[{"type":"TEXT","text":"Dup value"}]}'
				  	}


				  	local AlertId
					--hmi side: Navigation.AlertManeuver request
				  	EXPECT_HMICALL("Navigation.AlertManeuver")
				  		:Times(2)
				  		:Do(function(_,data)
				  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
				  		end)


					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak")
						:Times(2)
						:Do(function(exp,data)

							if exp.occurences == 1 then 

								self.mobileSession:Send(msg)

							end 

							self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { })
						end)

					--mobile side: expect AlertManeuver response
				  	self.mobileSession:ExpectResponse(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
				  	:Times(2)

				end


		--End Test case CommonRequestCheck.6

    --Begin Test case CommonRequestCheck.7
    --Description: Positive case and in boundary conditions (with conditional parameters) and invalid image
    
      function Test:AlertManeuver_InvalidImage() 

        --mobile side: AlertManeuver request 
        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                {
                                     
                                  ttsChunks = 
                                  { 
                                    
                                    { 
                                      text ="FirstAlert",
                                      type ="TEXT",
                                    }, 
                                    
                                    { 
                                      text ="SecondAlert",
                                      type ="TEXT",
                                    }, 
                                  }, 
                                  softButtons = 
                                  { 
                                    
                                    { 
                                      type = "BOTH",
                                      text = "Close",
                                       image = 
                                
                                      { 
                                        value = "icon.png",
                                        imageType = "DYNAMIC",
                                      }, 
                                      isHighlighted = true,
                                      softButtonID = 7821,
                                      systemAction = "DEFAULT_ACTION",
                                    }, 
                                    
                                    { 
                                      type = "BOTH",
                                      text = "AnotherClose",
                                       image = 
                                
                                      { 
                                        value = "notavailable.png",
                                        imageType = "DYNAMIC",
                                      }, 
                                      isHighlighted = false,
                                      softButtonID = 7822,
                                      systemAction = "DEFAULT_ACTION",
                                    },
                                  }
                                
                                })

        local AlertId
        --hmi side: Navigation.AlertManeuver request 
        EXPECT_HMICALL("Navigation.AlertManeuver", 
                { 
                  appID = self.applications["Test Application"],
                  softButtons = 
                  { 
                    
                    { 
                      type = "BOTH",
                      text = "Close",
                        --[[ TODO: update after resolving APPLINK-16052

                       image = 
                
                      { 
                        value = pathToIconFolder .. "/icon.png",
                        imageType = "DYNAMIC",
                      },]] 
                      isHighlighted = true,
                      softButtonID = 7821,
                      systemAction = "DEFAULT_ACTION",
                    }, 
                    
                    { 
                      type = "BOTH",
                      text = "AnotherClose",
                        --[[ TODO: update after resolving APPLINK-16052

                       image = 
                
                      { 
                        value = pathToIconFolder.. "/notavailable.png",
                        imageType = "DYNAMIC",
                      },]] 
                      isHighlighted = false,
                      softButtonID = 7822,
                      systemAction = "DEFAULT_ACTION",
                    } 
                  }
                })
          :Do(function(_,data)
            AlertId = data.id
            local function alertResponse()
              self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "WARNINGS", {info = "Requested image(s) not found."})
            end

            RUN_AFTER(alertResponse, 2000)
          end)

        local SpeakId
        --hmi side: TTS.Speak request 
        EXPECT_HMICALL("TTS.Speak", 
                { 
                  ttsChunks = 
                    { 
                      
                      { 
                        text ="FirstAlert",
                        type ="TEXT",
                      }, 
                      
                      { 
                        text ="SecondAlert",
                        type ="TEXT",
                      }
                    },
                  speakType = "ALERT_MANEUVER",

                })
          :Do(function(_,data)
            self.hmiConnection:SendNotification("TTS.Started")
            SpeakId = data.id

            local function speakResponse()
              self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

              self.hmiConnection:SendNotification("TTS.Stopped")
            end

            RUN_AFTER(speakResponse, 1000)

          end)
           

        --mobile side: OnHMIStatus notifications
        ExpectOnHMIStatusWithAudioStateChanged(self)

          --mobile side: expect AlertManeuver response
          EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })
            :Timeout(11000)

      end

    --End Test case CommonRequestCheck.7
    
    --Begin Test case CommonRequestCheck.8
    --Description: Positive case and in boundary conditions (with conditional parameters) and invalid image
    
      function Test:AlertManeuver_InvalidImage_SoftButton() 

        --mobile side: AlertManeuver request 
        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                {
                                     
                                  ttsChunks = 
                                  { 
                                    
                                    { 
                                      text ="FirstAlert",
                                      type ="TEXT",
                                    }, 
                                    
                                    { 
                                      text ="SecondAlert",
                                      type ="TEXT",
                                    }, 
                                  }, 
                                  softButtons = 
                                  { 
                                    
                                    { 
                                      type = "BOTH",
                                      text = "Close",
                                       image = 
                                
                                      { 
                                        value = "notavailable.png",
                                        imageType = "DYNAMIC",
                                      }, 
                                      isHighlighted = true,
                                      softButtonID = 8821,
                                      systemAction = "DEFAULT_ACTION",
                                    }, 
                                    
                                    { 
                                      type = "BOTH",
                                      text = "AnotherClose",
                                       image = 
                                
                                      { 
                                        value = "icon.png",
                                        imageType = "DYNAMIC",
                                      }, 
                                      isHighlighted = false,
                                      softButtonID = 8822,
                                      systemAction = "DEFAULT_ACTION",
                                    },
                                  }
                                
                                })

        local AlertId
        --hmi side: Navigation.AlertManeuver request 
        EXPECT_HMICALL("Navigation.AlertManeuver", 
                { 
                  appID = self.applications["Test Application"],
                  softButtons = 
                  { 
                    
                    { 
                      type = "BOTH",
                      text = "Close",
                        --[[ TODO: update after resolving APPLINK-16052

                       image = 
                
                      { 
                        value = pathToIconFolder .. "/notavailable.png",
                        imageType = "DYNAMIC",
                      },]] 
                      isHighlighted = true,
                      softButtonID = 8821,
                      systemAction = "DEFAULT_ACTION",
                    }, 
                    
                    { 
                      type = "BOTH",
                      text = "AnotherClose",
                        --[[ TODO: update after resolving APPLINK-16052

                       image = 
                
                      { 
                        value = pathToIconFolder.. "/icon.png",
                        imageType = "DYNAMIC",
                      },]] 
                      isHighlighted = false,
                      softButtonID = 8822,
                      systemAction = "DEFAULT_ACTION",
                    } 
                  }
                })
          :Do(function(_,data)
            AlertId = data.id
            local function alertResponse()
              self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "WARNINGS", {info = "Requested image(s) not found."})
            end

            RUN_AFTER(alertResponse, 2000)
          end)

        local SpeakId
        --hmi side: TTS.Speak request 
        EXPECT_HMICALL("TTS.Speak", 
                { 
                  ttsChunks = 
                    { 
                      
                      { 
                        text ="FirstAlert",
                        type ="TEXT",
                      }, 
                      
                      { 
                        text ="SecondAlert",
                        type ="TEXT",
                      }
                    },
                  speakType = "ALERT_MANEUVER",

                })
          :Do(function(_,data)
            self.hmiConnection:SendNotification("TTS.Started")
            SpeakId = data.id

            local function speakResponse()
              self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

              self.hmiConnection:SendNotification("TTS.Stopped")
            end

            RUN_AFTER(speakResponse, 1000)

          end)
           

        --mobile side: OnHMIStatus notifications
        ExpectOnHMIStatusWithAudioStateChanged(self)

          --mobile side: expect AlertManeuver response
          EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })
            :Timeout(11000)

      end

    --End Test case CommonRequestCheck.8

	--End Test suit CommonRequestCheck





---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--[[
			 - name="ttsChunks" minsize="1" maxsize="100" array="true" mandatory="false":
			 	- name="text" minlength="0" maxlength="500" type="String"
			 	- name="type" : TEXT, SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, FILE
			 - name="softButtons" minsize="0" maxsize="3" array="true" mandatory="false" :
			 	- name="type" : TEXT, IMAGE, BOTH;
			 	- name="text" minlength="0" maxlength="500" type="String" mandatory="false";
			 	- name="image":
			 		- name="value" minlength="0" maxlength="65535" type="String";
			 		- name="imageType" : STATIC, DYNAMIC
			 	- name="isHighlighted" type="Boolean" defvalue="false" mandatory="false";
			 	- name="softButtonID" type="Integer" minvalue="0" maxvalue="65535";
			 	- name="systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false"
			]]

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA: SDLAQ-CRS-125, SDLAQ-CRS-674

				--Verification criteria:
				--[[- The app notifies user about navigation maneuver via UI notification, TTS information or via both way at a time.
				- If the requested for TTS AlertManuever has been spoken successfully on HMI,  "SUCCESS" resultCode is returned to mobile side.]]

				--Begin Test case PositiveRequestCheck.1.1
				--Description: ttsChunks: array lower bound 

					function Test:AlertManeuver_ttsChunksArrayLowerBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", 
																		{ 
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text ="FirstAlert",
																					type ="TEXT",
																				}, 
																			}, 
																		})



						--hmi side: Navigation.AlertManeuver request
						EXPECT_HMICALL("Navigation.AlertManeuver")
				  		:Do(function(_,data)
				  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
				  		end)


						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 1000)

							end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
	

					end

				--End Test case PositiveRequestCheck.1.1

				--Begin Test case PositiveRequestCheck.1.2
				--Description: ttsChunks: array upper bound 
					function Test:AlertManeuver_ArrayUpperBound() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							ttsChunks = 
							{ 
								
								{ 
									text ="1Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="2Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="3Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="4Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="5Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="6Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="7Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="8Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="9Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="10Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="11Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="12Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="13Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="14Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="15Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="16Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="17Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="18Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="19Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="20Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="21Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="22Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="23Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="24Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="25Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="26Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="27Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="28Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="29Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="30Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="31Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="32Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="33Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="34Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="35Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="36Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="37Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="38Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="39Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="40Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="41Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="42Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="43Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="44Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="45Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="46Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="47Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="48Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="49Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="50Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="51Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="52Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="53Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="54Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="55Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="56Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="57Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="58Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="59Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="60Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="61Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="62Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="63Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="64Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="65Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="66Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="67Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="68Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="69Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="70Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="71Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="72Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="73Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="74Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="75Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="76Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="77Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="78Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="79Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="80Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="81Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="82Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="83Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="84Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="85Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="86Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="87Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="88Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="89Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="90Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="91Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="92Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="93Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="94Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="95Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="96Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="97Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="98Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="99Speak",
									type ="TEXT",
								}, 
								
								{ 
									text ="100Speak",
									type ="TEXT",
								}, 
							}, 
						
						}) 

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
											{ 
												
												{ 
													text ="1Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="2Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="3Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="4Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="5Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="6Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="7Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="8Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="9Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="10Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="11Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="12Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="13Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="14Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="15Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="16Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="17Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="18Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="19Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="20Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="21Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="22Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="23Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="24Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="25Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="26Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="27Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="28Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="29Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="30Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="31Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="32Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="33Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="34Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="35Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="36Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="37Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="38Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="39Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="40Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="41Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="42Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="43Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="44Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="45Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="46Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="47Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="48Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="49Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="50Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="51Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="52Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="53Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="54Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="55Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="56Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="57Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="58Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="59Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="60Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="61Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="62Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="63Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="64Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="65Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="66Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="67Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="68Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="69Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="70Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="71Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="72Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="73Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="74Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="75Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="76Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="77Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="78Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="79Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="80Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="81Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="82Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="83Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="84Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="85Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="86Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="87Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="88Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="89Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="90Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="91Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="92Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="93Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="94Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="95Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="96Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="97Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="98Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="99Speak",
													type ="TEXT",
												}, 
												
												{ 
													text ="100Speak",
													type ="TEXT",
												}, 
											}

										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 1000)

							end)

						--hmi side: Navigation.AlertManeuver request
						EXPECT_HMICALL("Navigation.AlertManeuver")
				  		:Do(function(_,data)
				  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
				  		end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.2

				--Begin Test case PositiveRequestCheck.1.3
				--Description: ttsChunks: text lower and upper bound

					function Test:AlertManeuver_ttsChunksTextLowerUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text = "",
										type ="TEXT",
									}, 
									
									{ 
										text ="nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
										type ="TEXT",
									}, 
								}, 
							
							})

						--hmi side: Navigation.AlertManeuver request
						EXPECT_HMICALL("Navigation.AlertManeuver")
				  		:Do(function(_,data)
				  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
				  		end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="",
														type ="TEXT"
													},
													{ 
														text ="nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
														type ="TEXT"
													}
												}

										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 1000)

							end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.3

				--Begin Test case PositiveRequestCheck.1.4
				--Description: ttsChunks: text with spaces before, after and in the middle 

				function Test:AlertManeuver_ttsChunksTextSpaces() 

					--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
						{
						  	 
							ttsChunks = 
							{ 
								
								{ 
									text =" before",
									type ="TEXT",
								}, 
								
								{ 
									text ="after ",
									type ="TEXT",
								}, 
								
								{ 
									text ="in the middle",
									type ="TEXT",
								}, 
								
								{ 
									text =" before after and in the middle ",
									type ="TEXT",
								}, 
							}, 
						
						}) 

					--hmi side: Navigation.AlertManeuver request
					EXPECT_HMICALL("Navigation.AlertManeuver")
			  		:Do(function(_,data)
			  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
			  		end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										speakType = "ALERT_MANEUVER",
										ttsChunks = 
											{ 
												{ 
													text =" before",
													type ="TEXT",
												}, 
												
												{ 
													text ="after ",
													type ="TEXT",
												}, 
												
												{ 
													text ="in the middle",
													type ="TEXT",
												}, 
												
												{ 
													text =" before after and in the middle ",
													type ="TEXT",
												}, 
											}
									})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 1000)

						end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

				end

				--End Test case PositiveRequestCheck.1.4

				--Begin Test case PositiveRequestCheck.1.5
				--Description: SoftButtons: type = TEXT; text with spaces before, after and in the middle

					function Test:AlertManeuver_SBTEXTTextSpaces() 

						--mobile side: Alert request 	
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
											{
 
												softButtons = 
												{ 
													
													{ 
														type = "TEXT",
														text = " spaces before, after and in the middle ",
														softButtonID = 1041,
														systemAction = "DEFAULT_ACTION",
													}, 
												}, 
											
											})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = " spaces before, after and in the middle ",
													softButtonID = 1041,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.5

				--Begin Test case PositiveRequestCheck.1.6
				--Description: ttsChunks: available values of type

					local ttsChunksType = {{text = "4025",type = "PRE_RECORDED"},{ text = "Sapi",type = "SAPI_PHONEMES"}, {text = "LHplus", type = "LHPLUS_PHONEMES"}, {text = "Silence", type = "SILENCE"}, {text = "File.m4a", type = "FILE"}}
					for i=1,#ttsChunksType do
						Test["AlertManeuver_ttsChunksType" .. tostring(ttsChunksType[i].type)] = function(self)
							--mobile side: Alert request 	
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								ttsChunks = 
								{ 
									
									{ 
										text = ttsChunksType[i].text,
										type = ttsChunksType[i].type
									}, 
								}
							}) 

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
												{ 
													
													{ 
														text = ttsChunksType[i].text,
														type = ttsChunksType[i].type
													}, 
												},
												speakType = "ALERT_MANEUVER"
											})
								:Do(function(_,data)
									self.hmiConnection:SendNotification("TTS.Started")
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
									end

									RUN_AFTER(speakResponse, 1000)
								end)

							--hmi side: Navigation.AlertManeuver request
							EXPECT_HMICALL("Navigation.AlertManeuver")
					  		:Do(function(_,data)
					  			self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
					  		end)
						 

							--mobile side: OnHMIStatus notifications
							ExpectOnHMIStatusWithAudioStateChanged(self)

						    --mobile side: Alert response
						    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
						    	:Timeout(11000)

						end
					end

				--End Test case PositiveRequestCheck.1.6

				--Begin Test case PositiveRequestCheck.1.7
				--Description: SoftButtons: array lower bound = 0 Buttons

					function Test:AlertManeuver_SBArrayLowerBound() 

						--mobile side: AlertManeuver request 
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 28,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"softButtons":[],"ttsChunks":[{"type":"TEXT","text":"FirstAlert"},{"type":"TEXT","text":"SecondAlert"}]}'
						  }
						  self.mobileSession:Send(msg)


						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											appID = self.applications["Test Application"],
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)
							:ValidIf(function(_,data)
								if data.params.softButtons then
									print ( " \27[36m Navigation.AlertManeuver request came with softButtons array \27[0m " )
									return false
								else
									return true
								end
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}, 
													
													{ 
														text ="SecondAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 1000)

							end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
	

					end

				--End Test case PositiveRequestCheck.1.7

				--Begin Test case PositiveRequestCheck.1.8
				--Description: SoftButtons: array upper bound = 3 Buttons

					function Test:AlertManeuver_SBArrayUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = "IMAGE",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										softButtonID = 824,
										systemAction = "STEAL_FOCUS",
									},
									{ 
										type = "BOTH",
										text = "AnotherClose",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}, 
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 823,
										systemAction = "KEEP_CONTEXT",
									},
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											appID = self.applications["Test Application"],
											softButtons = 
											{ 
												{ 
													type = "IMAGE",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/icon.png",
														imageType = "DYNAMIC",
													},]] 
													softButtonID = 824,
													systemAction = "STEAL_FOCUS",
												},
												{ 
													type = "BOTH",
													text = "AnotherClose",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}, 
												{ 
													type = "TEXT",
													text = "Keep",
													isHighlighted = true,
													softButtonID = 823,
													systemAction = "KEEP_CONTEXT",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.8

				--Begin Test case PositiveRequestCheck.1.9
				--Description: SoftButtons:text lower bound 

					function Test:AlertManeuver_SBTextLowerBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "a",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											appID = self.applications["Test Application"],
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "a",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.9

				--Begin Test case PositiveRequestCheck.1.10
				--Description: SoftButtons:text upper bound 

					function Test:AlertManeuver_SBTextUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.10

				--Begin Test case PositiveRequestCheck.1.11
				--Description: SoftButtons:image value lower bound 

					function Test:AlertManeuver_SBImageValueLowerBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "a",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/a",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.11

				--Begin Test case PositiveRequestCheck.1.12
				--Description: SoftButtons:image value upper bound 

					function Test:AlertManeuver_SBImageValueUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder .. "/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.12

				--Begin Test case PositiveRequestCheck.1.13
				--Description:SoftButtons:type = TEXT; isHighlighted = true/TRUE/True and 

					function Test:AlertManeuver_SBisHighlightedtrueTrueTRUE() 

						--mobile side: Alert request 	
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 28,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"softButtons":[{"softButtonID":1051,"type":"TEXT","text":"isHighlighted-true","systemAction":"KEEP_CONTEXT","isHighlighted":true},{"softButtonID":1052,"type":"TEXT","text":"isHighlighted-True","systemAction":"DEFAULT_ACTION","isHighlighted":True}]}'
						}

						self.mobileSession:Send(msg)

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "isHighlighted-true", 
													isHighlighted = true,
													softButtonID = 1051,
													systemAction = "KEEP_CONTEXT",
												},
												{ 
													type = "TEXT",
													text = "isHighlighted-True", 
													isHighlighted = True,
													softButtonID = 1052,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.13

				--Begin Test case PositiveRequestCheck.1.14
				--Description: SoftButtons:type = TEXT; isHighlighted = false/FALSE/False and 

					function Test:AlertManeuver_SBisHighlightedfalseFalseFALSE() 

						--mobile side: Alert request 	
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 28,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"softButtons":[{"softButtonID":1051,"type":"TEXT","text":"isHighlighted-false","systemAction":"KEEP_CONTEXT","isHighlighted":false},{"softButtonID":1052,"type":"TEXT","text":"isHighlighted-False","systemAction":"DEFAULT_ACTION","isHighlighted":False}]}'
						}

						self.mobileSession:Send(msg)

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "isHighlighted-false", 
													isHighlighted = false,
													softButtonID = 1051,
													systemAction = "KEEP_CONTEXT",
												},
												{ 
													type = "TEXT",
													text = "isHighlighted-False", 
													isHighlighted = False,
													softButtonID = 1052,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.14

				--Begin Test case PositiveRequestCheck.1.15
				--Description: SoftButtons: type = IMAGE; image type is STATIC  

					function Test:AlertManeuver_SBIMAGETypeStatic() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "STATIC",
										}, 
										isHighlighted = false,
										softButtonID = 822,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = "icon.png",
														imageType = "STATIC",
													},]] 
													isHighlighted = false,
													softButtonID = 822,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.15

				--Begin Test case PositiveRequestCheck.1.16
				--Description: SoftButtons: softButtonID lower bound  

					function Test:AlertManeuver_SBsoftButtonIDLowerBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 0,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder.."/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 0,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.16

				--Begin Test case PositiveRequestCheck.1.17
				--Description: SoftButtons: softButtonID upper bound  

					function Test:AlertManeuver_SBsoftButtonIDUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 65535,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = pathToIconFolder.."/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 65535,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.17

				--Begin Test case PositiveRequestCheck.1.18
				--Description: Check lower bound of all params

					function Test:AlertManeuver_LowerBound() 
					--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{

																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "",
																					type = "TEXT",
																				}
																			},
																			softButtons = 
																			{
																				{ 
																					type = "BOTH",
																					text = "a",
																					 image = 
																		
																					{ 
																						value = "a",
																						imageType = "STATIC",
																					}, 
																					isHighlighted = false,
																					softButtonID = 0,
																					systemAction = "DEFAULT_ACTION",
																				}
																			}

																		})

						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver",
										{
											softButtons = 
											{
												{ 
													type = "BOTH",
													text = "a",
													 --[[ TODO: update after resolving APPLINK-16052

													image = 
										
													{ 
														value = "a",
														imageType = "STATIC",
													},]] 
													isHighlighted = false,
													softButtonID = 0,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
							end)

						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text = "",
														type = "TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { })

							end)
							 


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					end

				--End Test case PositiveRequestCheck.1.18

				--Begin Test case PositiveRequestCheck.1.19
				--Description: Check upper bound values of all parameters

					function Test:AlertManeuver_UpperBound() 
						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="1nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="2nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="3nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="4nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="5nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="6nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="7nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="8nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="9nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										type ="TEXT",
									}, 
									
									{ 
										text ="10nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="11nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="12nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="13nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="14nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="15nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="16nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="17nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="18nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="19nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="20nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="21nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="22nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="23nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="24nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="25nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="26nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="27nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="28nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="29nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="30nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="31nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="32nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="33nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="34nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="35nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="36nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="37nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="38nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="39nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="40nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="41nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="42nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="43nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="44nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="45nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="46nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="47nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="48nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="49nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="50nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="51nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="52nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="53nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="54nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="55nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="56nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="57nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="58nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="59nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="60nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="61nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="62nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="63nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="64nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="65nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="66nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="67nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="68nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="69nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="70nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="71nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="72nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="73nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="74nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="75nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="76nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="77nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="78nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="79nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="80nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="81nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="82nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="83nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="84nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="85nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="86nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="87nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="88nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="89nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="90nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="91nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="92nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="93nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="94nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="95nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="96nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="97nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="98nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="99nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
										type ="TEXT",
									}, 
									
									{ 
										text ="100nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asd",
										type ="TEXT",
									}, 
								}, 
								softButtons = 
									{ 
										
										{ 
											type = "IMAGE",
											 image = 
								
											{ 
												value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
												imageType = "STATIC",
											}, 
											softButtonID = 65533,
											systemAction = "STEAL_FOCUS",
										},
										{ 
											type = "BOTH",
											text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
											 image = 
								
											{ 
												value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
												imageType = "STATIC",
											}, 
											isHighlighted = false,
											softButtonID = 65534,
											systemAction = "DEFAULT_ACTION",
										}, 
										{ 
											type = "TEXT",
											text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
											isHighlighted = true,
											softButtonID = 65535,
											systemAction = "KEEP_CONTEXT",
										},
									}
							}) 

						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver",
										{
											softButtons = 
									{ 
										
										{ 
											type = "IMAGE",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
												imageType = "STATIC",
											},]] 
											softButtonID = 65533,
											systemAction = "STEAL_FOCUS",
										},
										{ 
											type = "BOTH",
											text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
												imageType = "STATIC",
											},]] 
											isHighlighted = false,
											softButtonID = 65534,
											systemAction = "DEFAULT_ACTION",
										}, 
										{ 
											type = "TEXT",
											text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123",
											isHighlighted = true,
											softButtonID = 65535,
											systemAction = "KEEP_CONTEXT",
										},
									}
										})
							:Do(function(_,data)

								self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", { })
							end)

						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
											{ 
												
												{ 
													text ="1nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="2nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="3nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="4nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="5nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="6nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="7nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="8nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="9nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}, 
												
												{ 
													text ="10nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="11nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="12nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="13nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="14nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="15nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="16nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="17nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="18nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="19nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="20nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="21nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="22nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="23nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="24nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="25nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="26nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="27nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="28nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="29nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="30nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="31nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="32nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="33nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="34nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="35nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="36nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="37nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="38nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="39nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="40nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="41nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="42nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="43nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="44nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="45nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="46nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="47nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="48nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="49nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="50nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="51nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="52nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="53nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="54nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="55nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="56nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="57nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="58nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="59nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="60nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="61nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="62nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="63nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="64nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="65nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="66nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="67nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="68nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="69nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="70nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="71nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="72nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="73nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="74nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="75nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="76nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="77nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="78nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="79nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="80nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="81nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="82nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="83nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="84nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="85nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="86nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="87nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="88nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="89nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="90nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="91nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="92nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="93nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="94nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="95nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="96nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="97nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="98nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="99nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdf",
													type ="TEXT",
												}, 
												
												{ 
													text ="100nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asd",
													type ="TEXT",
												}, 
											},

										})
							:Do(function(_,data)

								self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { })

							end)
							 


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.1.19

			--End Test case PositiveRequestCheck.1

			--Begin Test case PositiveRequestCheck.2
			--Description: Check processing AlertManeuver request with different softButtons types with omitted text, image parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

				--Verification criteria:
				--[[ - In case mobile app sends any-relevant-RPC with SoftButtons withType=TEXT and with valid or invalid or not-defined or omitted 'image'  parameter, SDL must ignore this 'image' parameter and transfer the corresponding RPC to HMI omitting 'image' parameter (in case of no other errors), the resultCode returned to mobile app must be dependent on resultCode from HMI`s response.
				-  In case mobile app sends any-relevant-RPC with SoftButtons withType=IMAGE and with valid or invalid or not-defined or omitted 'text'  parameter, SDL must ignore this 'text' parameter and transfer the corresponding RPC to HMI omitting 'text' parameter (in case of no other errors), the resultCode returned to mobile app must be dependent on resultCode from HMI`s response. 
				]]

				--Begin Test case PositiveRequestCheck.2.1
				--Description: SoftButtons: type = IMAGE, text is omitted (SUCCESS) 

					function Test:AlertManeuver_SBIMAGETextOmitted() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "IMAGE",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "IMAGE",							
													 --[[ TODO: update after resolving APPLINK-16052
							
													image = 
										
													{ 
														value = pathToIconFolder.."/icon.png",
														imageType = "DYNAMIC",
													},]] 
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:ValidIf(function(_,data)
								if 
									data.params.softButtons[1].text then
										print ("\27[35m Navigation.AlertManeuver request came with text parameter \27[0m")
										return false
								else
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
									end

									RUN_AFTER(alertResponse, 2000)

									return true
								end
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.2.1

				--Begin Test case PositiveRequestCheck.2.2
				--Description: SoftButtons: type = TEXT, image is omitted (SUCCESS) 

					function Test:AlertManeuver_SBTEXTImageOmitted() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close", 
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:ValidIf(function(_,data)
								if 
									data.params.softButtons[1].image then
										print ("\27[35m Navigation.AlertManeuver request came with image parameter \27[0m")
										return false
								else
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
									end

									RUN_AFTER(alertResponse, 2000)

									return true
								end
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)

					end

				--End Test case PositiveRequestCheck.2.2


			--End Test case PositiveRequestCheck.2

			--Begin Test case PositiveRequestCheck.3
			--Description: Check default systemAction value is case of systemAction absence

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-917

				--Verification criteria: SystemAction is set to "DEFAULT_ACTION" value if SystemAction parameter isn't provided in a request.

					for i=1,#SBType do
						Test["AlertManeuver_SB".. tostring(SBType[i]) .. "SystemActionMissing"] = function(self)

							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
								{
									softButtons = 
									{ 
										{ 
											type = SBType[i], 
											text ="SystemAction is Missing",
											image =	
											{ 
												value ="icon.png",
												imageType ="DYNAMIC",
											}, 
											isHighlighted = false,
											softButtonID = 111
										}
									}
								})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													{ 
														type = SBType[i],
														softButtonID = 111,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", {})
								end)


						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
						    	:Timeout(11000)
						end

					end


			--End Test case PositiveRequestCheck.3

		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: check info values boundary conditions

				--Requirement id in JAMA: SDLAQ-CRS-126

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case PositiveResponseCheck.1.1
				--Description: info lower bound in Navigation.AlertManeuver

					function Test:AlertManeuver_NavigationInfoLowerBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										image = 
											{
												value = "icon.png",
												imageType = "DYNAMIC"
											},
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													 --[[ TODO: update after resolving APPLINK-16052

													image = 
														{
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC"
														},]]
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "i"})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", info = "i" })
					    	:Timeout(11000)

					end

				--End Test case PositiveResponseCheck.1.1

				--Begin Test case PositiveResponseCheck.1.2
				--Description: info lower bound in TTS.Speak

					function Test:AlertManeuver_TTSInfoLowerBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								ttsChunks = 
								{
									{ 
										text = "Lower Bound value in TTS.Speak",
										type = "TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver")
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS", {})
							end)

						--hmi side: TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
											{
												{ 
													text ="Lower Bound value in TTS.Speak",
													type ="TEXT",
												}
											}

										})
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { message = "I" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", info = "I" })
					    	:Timeout(11000)

					end

				--End Test case PositiveResponseCheck.1.2

				--Begin Test case PositiveResponseCheck.1.3
				--Description: info upper bound in Navigation.AlertManeuver

					function Test:AlertManeuver_NavigationInfoUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "BOTH",
										text = "Close",
										image = 
											{
												value = "icon.png",
												imageType = "DYNAMIC"
											},
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "BOTH",
													text = "Close",
													 --[[ TODO: update after resolving APPLINK-16052

													image = 
														{
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC"
														},]]
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmn"})
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", info = "01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmn" })
					    	:Timeout(11000)

					end

				--End Test case PositiveResponseCheck.1.3
--[[
				--Begin Test case PositiveResponseCheck.1.4
				--Description: info upper bound in TTS.Speak

					function Test:AlertManeuver_TTSInfoUpperBound() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								ttsChunks = 
								{
									{ 
										text ="Lower Bound value in TTS.Speak",
										type ="TEXT",
									}
								}
							})

						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver")
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", "SUCCESS")
							end)

						--hmi side: TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													text ="Lower Bound value in TTS.Speak",
													type ="TEXT",
												}

										})
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { message = "01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmn" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", info = "01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890fghijklmn" })
					    	:Timeout(11000)

					end

				--End Test case PositiveResponseCheck.1.4
]]

				--Begin Test case PositiveResponseCheck.1.5
				--Description: joined info from Navigation.AlertManeuver and TTS.Speak 

					function Test:AlertManeuver_infoTTSSNavigation() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close",
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text ="Close",
													isHighlighted = true,
													softButtonID = 111,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {message = "Info  Navigation.AlertManeuver"})
								end

								RUN_AFTER(alertResponse, 2000)
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}, 
													
													{ 
														text ="SecondAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = "Info TTS.Speak" })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 1000)

							end)
							 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", info = "Info TTS.Speak. Info  Navigation.AlertManeuver" })
					    	:Timeout(11000)
	
					end

				--End Test case PositiveResponseCheck.1.5

			--End Test case PositiveResponseCheck.1


		--End Test suit PositiveResponseCheck


----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound, empty values

				--Requirement id in JAMA: SDLAQ-CRS-125
						-- SDLAQ-CRS-675

				--Verification criteria:
					--[[
						- The request with "ttsChunks" element value out of bounds is sent, the response with INVALID_DATA code is returned. 
						- The request with "ttsChunks" array size out of bounds is sent, the response with INVALID_DATA code is returned. 
						- The request with "softButtons" element value out of bounds is sent, the response with INVALID_DATA code is returned. 
						- The request with "softButtons" array size out of bounds is sent, the response with INVALID_DATA code is returned. 

						. The request with empty "ttsChunks" array element value is sent, the response with INVALID_DATA code is returned. 
						6.2. The request with empty "ttsChunks" array value is sent, the response with INVALID_DATA code is returned. 
						6.3. The request with empty "text" value of softButton is sent, the response with INVALID_DATA code is returned.
						6.4. The request with empty "image" value of softButton is sent, the response with INVALID_DATA code is returned.
						6.5. The request with empty "type" value of softButton is sent, the response with INVALID_DATA code is returned.
						6.6. The request with empty "softButtonID" value is sent, the response with INVALID_DATA code is returned.

					]]

				--Begin Test case NegativeRequestCheck.1.1
				--Description: ttsChunks: array is empty (out lower bound) 

					function Test:AlertManeuver_ttsChunksArrayEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{ 
																			}, 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end 

				--End Test case NegativeRequestCheck.1.1

				--Begin Test case NegativeRequestCheck.1.2
				--Description: ttsChunks: array out upper bound 

					function Test:AlertManeuver_ArrayOutUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text ="1Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="2Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="3Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="4Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="5Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="6Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="7Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="8Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="9Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="10Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="11Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="12Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="13Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="14Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="15Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="16Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="17Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="18Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="19Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="20Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="21Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="22Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="23Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="24Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="25Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="26Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="27Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="28Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="29Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="30Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="31Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="32Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="33Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="34Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="35Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="36Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="37Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="38Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="39Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="40Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="41Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="42Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="43Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="44Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="45Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="46Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="47Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="48Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="49Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="50Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="51Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="52Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="53Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="54Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="55Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="56Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="57Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="58Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="59Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="60Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="61Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="62Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="63Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="64Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="65Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="66Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="67Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="68Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="69Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="70Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="71Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="72Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="73Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="74Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="75Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="76Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="77Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="78Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="79Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="80Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="81Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="82Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="83Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="84Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="85Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="86Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="87Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="88Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="89Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="90Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="91Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="92Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="93Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="94Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="95Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="96Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="97Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="98Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="99Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="100Speak",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="101Speak",
																					type ="TEXT",
																				}, 
																			}, 
																		
																		}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end

				--End Test case NegativeRequestCheck.1.2

				--Begin Test case NegativeRequestCheck.1.3
				--Description: ttsChunks: text out upper bound 

					function Test:AlertManeuver_ttsChunksTextOutUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text ="01234567890ann\b\f\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,012345678",
																					type ="TEXT",
																				}, 
																			}, 
																		
																		}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end

				--End Test case NegativeRequestCheck.1.3

				--Begin Test case NegativeRequestCheck.1.4
				--Description: softButtons: array is out upper bound = 4

					function Test:AlertManeuver_SBArrayOutUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = 3,
																					systemAction = "DEFAULT_ACTION"
																				}, 
																				
																				{ 
																					type = "TEXT",
																					text = "Keep",
																					isHighlighted = true,
																					softButtonID = 4,
																					systemAction = "KEEP_CONTEXT",
																				}, 
																				
																				{ 
																					type = "TEXT",
																					text = "Steal",
																					softButtonID = 5,
																					systemAction = "STEAL_FOCUS",
																				}, 

																				{ 
																					type = "TEXT",
																					text = "Steal focus",
																					softButtonID = 6,
																					systemAction = "STEAL_FOCUS",
																				}, 
																			} 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end 

				--End Test case NegativeRequestCheck.1.4

				--Begin Test case NegativeRequestCheck.1.5
				--Description: softButtons.softButtonID: out lower bound 

					function Test:AlertManeuver_SBSoftButtonIDOutLowerBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = -1,
																					systemAction = "DEFAULT_ACTION"
																				}
																			} 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end 

				--End Test case NegativeRequestCheck.1.5

				--Begin Test case NegativeRequestCheck.1.6
				--Description: softButtons.softButtonID: out upper bound 

					function Test:AlertManeuver_SBSoftButtonIDOutUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = 65536,
																					systemAction = "DEFAULT_ACTION"
																				}
																			} 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end

				--End Test case NegativeRequestCheck.1.6

				--Begin Test case NegativeRequestCheck.1.7
				--Description: softButtons.text: out lower bound 

					function Test:AlertManeuver_SBTextOutLowerBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "TEXT",
																					text = " ", 
																					isHighlighted = true,
																					softButtonID = 5,
																					systemAction = "DEFAULT_ACTION"
																				}
																			} 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end 

				--End Test case NegativeRequestCheck.1.7

				--Begin Test case NegativeRequestCheck.1.8
				--Description: softButtons.text: out upper bound 

					function Test:AlertManeuver_SBTextOutUpperBound() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "TEXT",
																					text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234", 
																					isHighlighted = true,
																					softButtonID = 5,
																					systemAction = "DEFAULT_ACTION"
																				}
																			} 
																		
																		}) 
					 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end 

				--End Test case NegativeRequestCheck.1.8

				--Begin Test case NegativeRequestCheck.1.9
				--Description: ttsChunks: type is empty

					function Test:AlertManeuver_ttsChunksTypeEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="",
									}, 
								}, 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.9

				--Begin Test case NegativeRequestCheck.1.10
				--Description: ttsChunks: array element  is empty

					function Test:AlertManeuver_ttsChunksArrayElementEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{} 
								}, 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.10

				--Begin Test case NegativeRequestCheck.1.11
				--Description: softButtons: type  is empty

					function Test:AlertManeuver_SBTypeEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								softButtons = 
								{ 
									
									{ 
										type ="",
										text ="Close",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								} 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.11

				--Begin Test case NegativeRequestCheck.1.12
				--Description: softButtons: image  is empty

					function Test:AlertManeuver_SBimageEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	{ }, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								} 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.12

				--Begin Test case NegativeRequestCheck.1.13
				--Description: softButtons: image value is empty

					function Test:AlertManeuver_SBimageValueEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value =" ",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								} 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.13


				--Begin Test case NegativeRequestCheck.1.14
				--Description: softButtons: systemAction is empty

					function Test:AlertManeuver_SBsystemActionEmpty() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="",
									}, 
								} 
							
							}) 
						 
						--mobile side: AlertManeuver response 
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.1.14
				
				--End Test case NegativeRequestCheck.1

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with wrong type

				--Requirement id in JAMA: SDLAQ-CRS-125
						-- SDLAQ-CRS-675

				--Verification criteria:
				--[[
					- The request with wrong type of text parameter of ttsChunk structure is sent , the response with INVALID_DATA code is returned. 
					- The request with wrong data in "softButtons" parameter is sent , the response with INVALID_DATA code is returned. 
					- The request with not found file for softButton image is sent, the response with INVALID_DATA code is returned. 
				]]

				--Begin Test case NegativeRequestCheck.2.1
				--Description: ttsChunks: array with wrong type 

					function Test:AlertManeuver_ttsChunksArrayWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = "ttsChunks" 
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end 

				--End Test case NegativeRequestCheck.2.1

				--Begin Test case NegativeRequestCheck.2.2
				--Description: ttsChunks: array element with wrong type 

					function Test:AlertManeuver_ttsChunksArrayElementWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{
																				123
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end 

				--End Test case NegativeRequestCheck.2.2

				--Begin Test case NegativeRequestCheck.2.3
				--Description: ttsChunks: text with wrong type 
 

					function Test:AlertManeuver_ttsChunksTextWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{
																				{ 
																					text = 123,
																					type ="TEXT",
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.3

				--Begin Test case NegativeRequestCheck.2.4
				--Description: ttsChunks: type with wrong type 

					function Test:AlertManeuver_ttsChunksTypeWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{
																				{ 
																					text = "ttsChunks",
																					type = 123,
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.4

				--Begin Test case NegativeRequestCheck.2.5
				--Description: softButtons: array type with wrong type 
 
					function Test:AlertManeuver_SBArrayWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 123
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.5

				--Begin Test case NegativeRequestCheck.2.6
				--Description:  softButtons: array element type with wrong type 
 
					function Test:AlertManeuver_SBArrayElementWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = { 123 }
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.6

				--Begin Test case NegativeRequestCheck.2.7
				--Description: softButtons.type: wrong type 

					function Test:AlertManeuver_SBTypeWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				{ 
																					type = 123,
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = 5,
																					systemAction = "DEFAULT_ACTION"
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.7

				--Begin Test case NegativeRequestCheck.2.8
				--Description: softButtons.text: wrong type 

					function Test:AlertManeuver_SBTextWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				{ 
																					type = "TEXT",
																					text = 123, 
																					isHighlighted = true,
																					softButtonID = 5,
																					systemAction = "DEFAULT_ACTION"
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.8

				--Begin Test case NegativeRequestCheck.2.9
				--Description: softButtons.isHighlighted: wrong type 

					function Test:AlertManeuver_SBIsHighlightedWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = 123,
																					softButtonID = 5,
																					systemAction = "DEFAULT_ACTION"
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.9

				--Begin Test case NegativeRequestCheck.2.10
				--Description: softButtons.softButtonID: wrong type 

					function Test:AlertManeuver_SBSoftButtonIDWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = true,
																					systemAction = "DEFAULT_ACTION"
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.10

				--Begin Test case NegativeRequestCheck.2.11
				--Description: softButtons.systemAction: wrong type 

					function Test:AlertManeuver_SBSystemActionWrongType() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			softButtons = 
																			{ 
																				{ 
																					type = "TEXT",
																					text = "Close", 
																					isHighlighted = true,
																					softButtonID = 5,
																					systemAction = 123
																				}
																			}
																		
																		}) 
				 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.2.11

			--End Test case NegativeRequestCheck.2

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with nonexistent values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-675

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case AlertManeuver request comes with enum out of range

				--Begin Test case NegativeRequestCheck.3.1
				--Description: ttsChunks: type is not exist 

					function Test:AlertManeuver_TypeNotExist() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="ANY",
									}, 
								}, 
							
							}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.3.1

				--Begin Test case NegativeRequestCheck.3.2
				--Description: SoftButtons: type of SoftButton is not exist 
					function Test:AlertManeuver_SBTypeNotExist() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = "ANY",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 861,
										systemAction = "DEFAULT_ACTION",
									}, 
								}
							}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.3.2

				--Begin Test case NegativeRequestCheck.3.3
				--Description: SoftButtons: systemAction is not exist 

					function Test:AlertManeuver_SBSystemActionNotExist() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 861,
										systemAction = "ANY",
									}, 
								}
							}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.3.3

				--Begin Test case NegativeRequestCheck.3.4
				--Description: SoftButtons: type = IMAGE; image type is not exist 

					function Test:AlertManeuver_SBIMAGETypeNotExist() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = "IMAGE",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "ANY",
										}, 
										softButtonID = 861,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.3.4

				--Begin Test case NegativeRequestCheck.3.5
				--Description: SoftButtons: type = BOTH; image type is not exist 

					function Test:AlertManeuver_SBBOTHTypeNotExist() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type = "IMAGE",
										text = "Close",
										 image = 
							
										{ 
											value = "icon.png",
											imageType = "ANY",
										}, 
										softButtonID = 861,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							}) 
					 
						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.3.5

			--End Test case NegativeRequestCheck.3

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-125, SDLAQ-CRS-675,SDLAQ-CRS-921, APPLINK-14276

				--Verification criteria:
					--[[- SDL must respond with INVALID_DATA resultCode in case AlertManeuver request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "SoftButton" struct.
					-SDL must respond with INVALID_DATA resultCode in case AlertManeuver request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "TTSChunk" struct.
					-SDL must respond with INVALID_DATA resultCode in case AlertManeuver request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "value" parameter of "Image" struct.]]

					--[[- In case mobile app sends any-relevant-RPC with SoftButtons withType=BOTH and with one of the parameters ('text' and 'image') wrong or not defined, SDL must reject it with INVALID_DATA result code and not transfer to HMI.]]

					--[[- In case mobile app sends any-relevant-RPC with SoftButtons with Type=IMAGE and with invalid value of 'text' parameter SDL must respond INVALID_DATA to mobile app
					- In case mobile app sends any-relevant-RPC with SoftButtons with Type=TEXT and with invalid value of 'image' parameter SDL must respond INVALID_DATA to mobile app
					]]

				--Begin Test case NegativeRequestCheck.4.1
				--Description: Escape sequence \n in TTSChunk text

					function Test:AlertManeuver_TTSChunkTextNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert\n",
										type ="TEXT",
									}, 
								}, 
							
							}) 

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.4.1

				--Begin Test case NegativeRequestCheck.4.2
				--Description: Escape sequence \t in TTSChunk text

					function Test:AlertManeuver_TTSChunkTextTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="First\tAlert",
										type ="TEXT",
									}, 
								}, 
							
							}) 

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.4.2

				--Begin Test case NegativeRequestCheck.4.3
				--Description: Only spacesin TTSChunk text

					function Test:AlertManeuver_TTSChunkTextOnlySpaces() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="        ",
										type ="TEXT",
									}, 
								}, 
							
							}) 

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
				 	end

				--End Test case NegativeRequestCheck.4.3

				--Begin Test case NegativeRequestCheck.4.4
				--Description: Escape sequence \n in SoftButton text with type = BOTH

					function Test:AlertManeuver_SBBOTHTextNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close\n",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.4

				--Begin Test case NegativeRequestCheck.4.5
				--Description: Escape sequence \n in SoftButton text with type = TEXT

					function Test:AlertManeuver_SBTEXTTextNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close\n",
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.5

				--Begin Test case NegativeRequestCheck.4.6
				--Description: Escape sequence \n in SoftButton text with type = IMAGE

					function Test:AlertManeuver_SBIMAGETextNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close\n", 
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										},
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)

					end

				--End Test case NegativeRequestCheck.4.6

				--Begin Test case NegativeRequestCheck.4.7
				--Description: Escape sequence \t in SoftButton text with type = BOTH

					function Test:AlertManeuver_SBBOTHTextTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close\t",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.7

				--Begin Test case NegativeRequestCheck.4.8
				--Description: Escape sequence \t in SoftButton text with type = TEXT

					function Test:AlertManeuver_SBTEXTTextTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close\t",
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.8

				--Begin Test case NegativeRequestCheck.4.9
				--Description: Escape sequence \t in SoftButton text with type = IMAGE

					function Test:AlertManeuver_SBIMAGETextTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close\t", 
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										},
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)

					end

				--End Test case NegativeRequestCheck.4.9

				--Begin Test case NegativeRequestCheck.4.10
				--Description: Only spaces in SoftButton text with type = BOTH

					function Test:AlertManeuver_SBBOTHTextOnlySpacesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="        ",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.10

				--Begin Test case NegativeRequestCheck.4.11
				--Description: Only spaces in SoftButton text with type = TEXT

					function Test:AlertManeuver_SBTEXTTextOnlySpacesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="        ",
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.11

				--Begin Test case NegativeRequestCheck.4.12
				--Description: Only spaces in SoftButton text with type = IMAGE

					function Test:AlertManeuver_SBIMAGETextOnlySpacesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="        ", 
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										},
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)

					end

				--End Test case NegativeRequestCheck.4.12

				--Begin Test case NegativeRequestCheck.4.13
				--Description: Escape sequence \n in SoftButton image value with type = BOTH

					function Test:AlertManeuver_SBBOTHImageValueNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value ="ico\nn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.13

				--Begin Test case NegativeRequestCheck.4.14
				--Description: Escape sequence \n in SoftButton image value with type = IMAGE

					function Test:AlertManeuver_SBIMAGEImageValueNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close",
										image =	
										{ 
											value ="ico\nn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.4.14

				--Begin Test case NegativeRequestCheck.4.15
				--Description: Escape sequence \n in SoftButton image value with type = TEXT

					function Test:AlertManeuver_SBTEXTImageValueNewLineChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close",
										image =	
										{ 
											value ="ico\nn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)
	

					end

				--End Test case NegativeRequestCheck.4.15

				--Begin Test case NegativeRequestCheck.4.16
				--Description: Escape sequence \t in SoftButton image value with type = BOTH

					function Test:AlertManeuver_SBBOTHImageValueTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value ="ico\tn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					 end

				--End Test case NegativeRequestCheck.4.16

				--Begin Test case NegativeRequestCheck.4.17
				--Description: Escape sequence \t in SoftButton image value with type = IMAGE

					function Test:AlertManeuver_SBIMAGEImageValueTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close",
										image =	
										{ 
											value ="ico\tn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.4.17

				--Begin Test case NegativeRequestCheck.4.18
				--Description: Escape sequence \t in SoftButton image value with type = TEXT

					function Test:AlertManeuver_SBTEXTImageValueTabChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close",
										image =	
										{ 
											value ="ico\tn.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)
	

					end

				--End Test case NegativeRequestCheck.4.18

				--Begin Test case NegativeRequestCheck.4.19
				--Description: Only spaces in SoftButton image value with type = BOTH

					function Test:AlertManeuver_SBBOTHImageValueOnlySpecesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value ="          ",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	
					end


				--End Test case NegativeRequestCheck.4.19

				--Begin Test case NegativeRequestCheck.4.20
				--Description: Only spaces in SoftButton image value with type = IMAGE

					function Test:AlertManeuver_SBIMAGEImageValueOnlySpacesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close",
										image =	
										{ 
											value ="          ",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
							EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
								:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.4.20

				--Begin Test case NegativeRequestCheck.4.21
				--Description: Only spaces in SoftButton image value with type = TEXT

					function Test:AlertManeuver_SBTEXTImageValueOnlySpacesChar() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
							  	 
								ttsChunks = 
								{ 
									
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}, 
									
									{ 
										text ="SecondAlert",
										type ="TEXT",
									}, 
								}, 

								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="Close",
										image =	
										{ 
											value ="          ",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
					    	:Timeout(11000)
	

					end

				--End Test case NegativeRequestCheck.4.21

			--End Test case NegativeRequestCheck.4

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing requests with different sofyButtons types and without text, image, omitted text, image, emty text, image,  with wrong text, image perams 
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921 

				--Verification criteria:
				--[[ - If SoftButtonType is IMAGE and image paramer is wrong/not defined the request will be rejected with "INVALID_DATA" response code.

				-  In case mobile app sends any-relevant-RPC with SoftButtons that include Text=“” (that is, empty string) and Type=TEXT, SDL must reject it with INVALID_DATA result code and not transfer to HMI.

				- In case mobile app sends any-relevant-RPC with SoftButtons withType=TEXT that exclude 'Text' parameter, SDL must reject it with INVALID_DATA result code and not transfer to HMI.

				- In case mobile app sends any-relevant-RPC with SoftButtons that include Text=“” (that is, empty string) and Type=BOTH, SDL must transfer to HMI (in case of no other errors), the resultCode returned to mobile app must be dependent on resultCode from HMI`s response.]]

				--Begin Test case NegativeRequestCheck.5.1
				--Description: SoftButton: type is IMAGE, image is not existed (INVALID_DATA) 

					function Test:AlertManeuver_SBIMAGEWrongImage() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type ="IMAGE",
										text ="Close",
										image =	
										{ 
											value ="NotExistentImage.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.5.1

				--Begin Test case NegativeRequestCheck.5.2
				--Description: SoftButton: type is BOTH, image is not existed (INVALID_DATA) 

					function Test:AlertManeuver_SBBOTHWrongImage() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										image =	
										{ 
											value ="NotExistentImage.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.5.2

				--Begin Test case NegativeRequestCheck.5.3
				--Description: SoftButton: type is TEXT, text is empty(INVALID_DATA) 

					function Test:AlertManeuver_SBTEXTEmptyText() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										text ="",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.5.3

				--Begin Test case NegativeRequestCheck.5.4
				--Description: SoftButton: type is TEXT, text is omitted (INVALID_DATA) 

					function Test:AlertManeuver_SBTEXTOmittedText() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type ="TEXT",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.5.4

				--Begin Test case NegativeRequestCheck.5.5
				--Description: SoftButton: type is BOTH, text is empty (INVALID_DATA) 

					function Test:AlertManeuver_SBBOTHEmptyText() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text = "",
										image =	
										{ 
											value ="icon.png",
											imageType ="DYNAMIC",
										}, 
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}, 
								}
							})

						--mobile side: expect AlertManeuver response
						EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
							:Timeout(11000) 	

					end

				--End Test case NegativeRequestCheck.5.5

			--End Test case NegativeRequestCheck.5

			-- .........

		--End Test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--Begin Test suit NegativeResponseCheck
		--Description: check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA: SDLAQ-CRS-126

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
--[[TODO: update according to APPLINK-14765
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing Navigation.AlertManeuver response with nonexistent resultCode

					function Test:AlertManeuver_resultCodeNotExistNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "ANY", { })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.1

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing TTS.Speak response with nonexistent resultCode

					function Test:AlertManeuver_resultCodeNotExistTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "ANY", {} )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.2

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver response with nonexistent resultCode

					function Test:AlertManeuver_resultCodeNotExistTTSNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "ANY", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "ANY", {} )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.3

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check processing Navigation.AlertManeuver response with empty string in method

					function Test:AlertManeuver_methodOutLowerBoundNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "", "SUCCESS", { })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.4

				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check processing TTS.Speak response with empty string in method

					function Test:AlertManeuver_methodOutLowerBoundTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, "", "SUCCESS", {} )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.5

				--Begin Test case NegativeResponseCheck.1.6
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses with empty string in method

					function Test:AlertManeuver_methodOutLowerBoundTTSNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION"
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, "", "SUCCESS", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, "", "SUCCESS", {} )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.1.6
]]
				--Begin Test case NegativeResponseCheck.1.7
				--Description: Check processing Navigation.AlertManeuver response with out lower bound of info
--[[TODO: update after resolving APPLINK-14551
					function Test:AlertManeuver_infoOutLowerBoundNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "" })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.7

				--Begin Test case NegativeResponseCheck.1.8
				--Description: Check processing TTS.Speak response with out lower bound of info

					function Test:AlertManeuver_infoOutLowerBoundTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, data.method, "SUCCESS", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, data.method, "SUCCESS", { message = "" } )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.8

				--Begin Test case NegativeResponseCheck.1.9
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses with out lower bound of info

					function Test:AlertManeuver_infoOutLowerBoundTTSNavigaton() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, data.method, "SUCCESS", { message = "" })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, data.method, "SUCCESS", { message = "" } )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent in info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.9


				--Begin Test case NegativeResponseCheck.1.10
				--Description: Check processing Navigation.AlertManeuver response with out upper bound of info

					function Test:AlertManeuver_infoOutUpperBoundNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!" })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.10

				--Begin Test case NegativeResponseCheck.1.11
				--Description: Check processing TTS.Speak response with out upper bound of info

					function Test:AlertManeuver_infoOutUpperBoundTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, data.method, "SUCCESS", { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, data.method, "SUCCESS", { message = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!" } )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.11

				--Begin Test case NegativeResponseCheck.1.12
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses with out upper bound of info

					function Test:AlertManeuver_infoOutUpperBoundTTSNavigaton() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								},
								ttsChunks =
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id

								self.hmiConnection:SendResponse(AlertId, data.method, "SUCCESS", { message = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!" })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}
										})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, data.method, "SUCCESS", { message = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!" } )

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then
					    			print (" \27[36m SDL resent in info value to mobile app \27[0m ")
					    			return false
					    		else
					    			return true
					    		end
					    	end)

					end

				--End Test case NegativeResponseCheck.1.12
		]]
			--End Test case NegativeResponseCheck.1
--[[TODO: update according to APPLINK-14765
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA: SDLAQ-CRS-126

				--Verification criteria:

				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check processing Navigation.AlertManeuver response without all parameters

					function Test:AlertManeuver_NavigationResponseMissingAllParameters() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:Send('{}')
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.2.1

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check processing TTS.Speak response without all parameters

					function Test:AlertManeuver_TTSResponseMissingAllParameters() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:Send('{}')

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.2.2

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses without all parameters

					function Test:AlertManeuver_TTSNavigationResponseMissingAllParameters() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								self.hmiConnection:Send('{}')

							end)

						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:Send('{}')

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.2.3

				--Begin Test case NegativeResponseCheck.2.4
				--Description: Check processing Navigation.AlertManeuver response without method parameter

					function Test:AlertManeuver_NavigationResponseMethodMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"code":0}}')
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.2.4

				--Begin Test case NegativeResponseCheck.2.5
				--Description: Check processing TTS.Speak response without method parameter

					function Test:AlertManeuver_TTSResponseMethodMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:Send('{"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"code":0}}')

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end
				--End Test case NegativeResponseCheck.2.5

				--Begin Test case NegativeResponseCheck.2.6
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses without method parameter

					function Test:AlertManeuver_TTSNavigationResponseMethodMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"code":0}}')

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:Send('{"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"code":0}}')

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end
				--End Test case NegativeResponseCheck.2.6

				--Begin Test case NegativeResponseCheck.2.7
				--Description: Check processing Navigation.AlertManeuver response without resultCode parameter

					function Test:AlertManeuver_NavigationResponseResultCodeMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"method":"Navigation.AlertManeuver"}}')
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end


				--End Test case NegativeResponseCheck.2.7

				--Begin Test case NegativeResponseCheck.2.8
				--Description: Check processing TTS.Speak response without resultCode parameter

					function Test:AlertManeuver_TTSResponseResultCodeMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								self.hmiConnection:Send('{"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak"}}')

							end)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end


				--End Test case NegativeResponseCheck.2.8

				--Begin Test case NegativeResponseCheck.2.9
				--Description: Check processing TTS.Speak and Navigation.AlertManeuver responses without resultCode parameter

					function Test:AlertManeuver_TTSNavigationResponseResultCodeMissing() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"method":"Navigation.AlertManeuver"}}')


							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)

								SpeakId = data.id
								self.hmiConnection:Send('{"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak"}}')

							end)

					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS", })
					    	:Timeout(11000)

					end


				--End Test case NegativeResponseCheck.2.9

			--End Test case NegativeResponseCheck.2

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

				--Begin Test case NegativeResponseCheck.3.1
				--Description: method wrong type in Navigation.AlertManeuver

					function Test:AlertManeuver_methodWrongTypeNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, 1234, "SUCCESS", { })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.1

				--Begin Test case NegativeResponseCheck.3.2
				--Description: method wrong type in TTS.Speak

					function Test:AlertManeuver_methodWrongTypeTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, 1234, "SUCCESS", { })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.2

				--Begin Test case NegativeResponseCheck.3.3
				--Description: method wrong type in TTS.Speak and Navigation.AlertManeuver

					function Test:AlertManeuver_methodWrongTypeTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, 1234, "SUCCESS", { })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.3

				--Begin Test case NegativeResponseCheck.3.4
				--Description: resultCode wrong type in Navigation.AlertManeuver

					function Test:AlertManeuver_resultCodeWrongTypeNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", 1234, { })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.4

				--Begin Test case NegativeResponseCheck.3.5
				--Description: resultCode wrong type in TTS.Speak

					function Test:AlertManeuver_resultCodeWrongTypeTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", 1234, { })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.5

				--Begin Test case NegativeResponseCheck.3.6
				--Description: resultCode wrong type in TTS.Speak and Navigation.AlertManeuver

					function Test:AlertManeuver_resultCodeWrongTypeTTSNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", 1234, { })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", 1234, { })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA", })
					    	:Timeout(11000)

					end

				--End Test case NegativeResponseCheck.3.6

				--Begin Test case NegativeResponseCheck.3.7
				--Description: info wrong type in Navigation.AlertManeuver

					function Test:AlertManeuver_infoWrongTypeNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = 12345 })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.3.7


				--Begin Test case NegativeResponseCheck.3.7
				--Description: info wrong type in TTS.Speak

					function Test:AlertManeuver_infoWrongTypeTTS()

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = 12345 })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then 
					    			print ("\27[36m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)

					end
				--End Test case NegativeResponseCheck.3.7

				--Begin Test case NegativeResponseCheck.3.8
				--Description: info wrong type in TTS.Speak and Navigation.AlertManeuver

					function Test:AlertManeuver_infoWrongTypeTTSNavigation()

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = 12345 })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = 12345 })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)
					    		if data.payload.info then 
					    			print ("\27[36m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)

					end
				--End Test case NegativeResponseCheck.3.8


			--End Test case NegativeResponseCheck.3
]]
			--Begin Test case NegativeResponseCheck.4
			--Description: Check processing response with values with with Special characters 

				--Requirement id in JAMA/or Jira ID: APPLINK-13276

				--Verification criteria: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.

				--Begin Test case NegativeResponseCheck.4.1
				--Description:  Escape sequence \n in info in Navigation.AlertManeuver


					function Test:AlertManeuver_infoNewLineCharNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										image = 
											{
												value = "icon.png",
												imageType = "DYNAMIC"
											},
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "Navigation.AlertManeuver \ninfo" })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.1

				--Begin Test case NegativeResponseCheck.4.2
				--Description:  Escape sequence \n in info in TTS.Speak


					function Test:AlertManeuver_infoNewLineCharTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = "TTS.Speak \ninfo" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.2

				--Begin Test case NegativeResponseCheck.4.3
				--Description:  Escape sequence \n in info in TTS.Speak and Navigation.AlertManeuver


					function Test:AlertManeuver_infoNewLineCharTTSNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {   message = "Navigation.AlertManeuver \ninfo"})

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = "TTS.Speak \ninfo" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.3

				--Begin Test case NegativeResponseCheck.4.4
				--Description:  Escape sequence \t in info in Navigation.AlertManeuver

					function Test:AlertManeuver_infoTabCharNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													softButtonID = 123,
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)
								AlertId = data.id
								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { message = "Navigation.AlertManeuver \tinfo" })
								end

								RUN_AFTER(alertResponse, 2000)
							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.4

				--Begin Test case NegativeResponseCheck.4.5
				--Description:  Escape sequence \t in info in TTS.Speak


					function Test:AlertManeuver_infoTabCharTTS() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {  })

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = "TTS.Speak \tinfo" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.5

				--Begin Test case NegativeResponseCheck.4.6
				--Description:  Escape sequence \t in info in TTS.Speak and Navigation.AlertManeuver


					function Test:AlertManeuver_infoTabCharTTSNavigation() 

						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
							{
								softButtons = 
								{ 
									{ 
										type = "TEXT",
										text = "Close",	
										isHighlighted = false,
										softButtonID = 123,
										systemAction = "DEFAULT_ACTION"
									}
								}, 
								ttsChunks = 
								{
									{ 
										text ="FirstAlert",
										type ="TEXT",
									}
								}
							})

						local AlertId
						--hmi side: Navigation.AlertManeuver request 
						EXPECT_HMICALL("Navigation.AlertManeuver", 
										{	
											softButtons = 
											{ 
												{ 
													type = "TEXT",
													text = "Close",
													isHighlighted = false,
													softButtonID = 123,
													systemAction = "DEFAULT_ACTION",
												}
											}
										})
							:Do(function(_,data)

								AlertId = data.id
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {   message = "Navigation.AlertManeuver \tinfo"})

							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT_MANEUVER",
											ttsChunks = 
												{ 
													
													{ 
														text ="FirstAlert",
														type ="TEXT",
													}
												}

										})
							:Do(function(_,data)
								SpeakId = data.id
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { message = "TTS.Speak \tinfo" })

							end)


					    --mobile side: expect AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
					    	:Timeout(11000)
					    	:ValidIf(function(_,data)

					    		if data.payload.info then 
					    			print ("\27[35m AlertManeuver response contains info parameter, value is " .. tostring(data.payload.info) .." \27[0m")
					    			return false
					    		else 
					    			return true
					    		end

					    	end)
					end

				--End Test case NegativeResponseCheck.4.6


			--End Test case NegativeResponseCheck.4


		--End Test suit NegativeResponseCheck

		----------------------------------------------------------------------------------------------
		----------------------------------------IV TEST BLOCK-----------------------------------------
		---------------------------------------Result codes check--------------------------------------
		----------------------------------------------------------------------------------------------

				--------Checks-----------
				-- сheck all pairs resultCode+success
				-- check should be made sequentially (if it is possible):
				-- case resultCode + success true
				-- case resultCode + success false
					--For example:
						-- first case checks ABORTED + true
						-- second case checks ABORTED + false
					    -- third case checks REJECTED + true
						-- fourth case checks REJECTED + false

			--Begin Test suit ResultCodeCheck
			--Description:TC's check all resultCodes values in pair with success value

				--Begin Test case ResultCodeCheck.1
				--Description: check OUT_OF_MEMORY + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-676

					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- The AlertManeuver request is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response codeis returned]]

						function Test:AlertManeuver_OutOfMemory() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "OUT_OF_MEMORY", "OutOfMemory result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "OUT_OF_MEMORY", info = "OutOfMemory result code" })
						    	:Timeout(11000)

						end

					
				--End Test case ResultCodeCheck.1

				--Begin Test case ResultCodeCheck.2
				--Description: check APPLICATION_NOT_REGISTERED + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-678

					--Verification criteria: 
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.]]

						function Test:Precondition_CreationNewSession()
							-- Connected expectation
						  	self.mobileSession1 = mobile_session.MobileSession(
						    self,
						    self.mobileConnection)

						    self.mobileSession1:StartService(7)
						end

						function Test:AlertManeuver_ApplicationNotRegisterSuccessFalse() 

							local CorIdAlertM = self.mobileSession1:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			}) 
								 
						    --mobile side: Alert response
						    self.mobileSession1:ExpectResponse(CorIdAlertM, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						    :Timeout(11000)

						end

				--End Test case ResultCodeCheck.2

				--Begin Test case ResultCodeCheck.3
				--Description: check REJECTED + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-679

					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.]]

						function Test:AlertManeuver_Rejected() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "REJECTED", "Rejected result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "REJECTED", info = "Rejected result code" })
						    	:Timeout(11000)

						end

				--End Test case ResultCodeCheck.3

				--Begin Test case ResultCodeCheck.4
				--Description: check REJECTED + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-680, APPLINK-9751

					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- In case the user interrupts the AlertManuever by Voice recognition activation when it hasn't finished speaking yet, SDL sends a response with resultCode ABORTED. General resultCode is success=false
						-  In case the user interrupts displaying the AlertManuever by switching to another application when the time for display hasn't out yet, SDL sends a response with resultCode ABORTED. General resultCode is success=false]]

						function Test:AlertManeuver_AbortedByVR() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									self.hmiConnection:SendNotification("VR.Started")

									self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

									self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS",{})

								end)

							--mobile side: OnHMIStatus notifications
							ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "ABORTED", info = "Speak is aborted"})
						    	:Timeout(11000)
						    	:Do(function(_,data)

						    		self.hmiConnection:SendNotification("VR.Stopped")

						    	end)

						end

				--End Test case ResultCodeCheck.4

				--Begin Test case ResultCodeCheck.5
				--Description: check IGNORED + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-683
				--[[TODO: Update Verification criteria]]
					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.]]

						function Test:AlertManeuver_Ignored() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "IGNORED", "IGNORED result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "IGNORED", info = "IGNORED result code" })
						    	:Timeout(11000)

						end

				--End Test case ResultCodeCheck.5

				--Begin Test case ResultCodeCheck.6
				--Description: check GENERIC_ERROR + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-681
				--[[TODO: Update Verification criteria]]
					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.]]

					--Begin Test case ResultCodeCheck.6.1
					--Description: Without TTS.Speak response

						function Test:AlertManeuver_GenericErrorWithoutTTSResponse() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "IGNORED", "IGNORED result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
						    	:Timeout(12000)

						end

					--End Test case ResultCodeCheck.6.1

					--Begin Test case ResultCodeCheck.6.2
					--Description: Without Navigation.AlertManeuver response

						function Test:AlertManeuver_GenericErrorWithoutNavResponse() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
						    	:Timeout(12000)

						end

					--End Test case ResultCodeCheck.6.2

					--Begin Test case ResultCodeCheck.6.3
					--Description: Without TTS.Speak and Navigation.AlertManeuver responses

						function Test:AlertManeuver_GenericErrorWithoutTTSNavResponses() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
						    	:Timeout(12000)

						end

					--End Test case ResultCodeCheck.6.3


				--End Test case ResultCodeCheck.6

				--Begin Test case ResultCodeCheck.7
				--Description: Check DISALLOWED result code wirh success false

					--Requirement id in JAMA: SDLAQ-CRS-682

					--Verification criteria: --[[TODO: update]]

					function Test:Precondition_DeactivateApp()

						--hmi side: sending BasicCommunication.OnExitApplication notification
						self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

						EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

					end

					function Test:AlertManeuver_DisallowedSuccessFalse() 

						--mobile side: AlertManeuver request 
						local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																		{
																		  	 
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text ="FirstAlert",
																					type ="TEXT",
																				}, 
																				
																				{ 
																					text ="SecondAlert",
																					type ="TEXT",
																				}, 
																			}, 
																			softButtons = 
																			{ 
																				
																				{ 
																					type = "BOTH",
																					text = "Close",
																					 image = 
																		
																					{ 
																						value = "icon.png",
																						imageType = "DYNAMIC",
																					}, 
																					isHighlighted = true,
																					softButtonID = 821,
																					systemAction = "DEFAULT_ACTION",
																				}
																			}
																		
																		})
							 

					    --mobile side: AlertManeuver response
					    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "DISALLOWED" })


					end
					
				--End Test case ResultCodeCheck.7

				--Begin Test case ResultCodeCheck.8
				--Description: Check DISALLOWED result code with success false
				--[[TODO: update  Requirement, Verification criteria]]
					--Requirement id in JAMA: SDLAQ-CRS-682

					--Verification criteria: 

					function Test:Precondition_WaitActivation()
					  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN" })

					  local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					  
					  EXPECT_HMIRESPONSE(rid)
					  :Do(function(_,data)
					  		if data.result.code ~= 0 then
					  		quit()
					  		end
						end)
					end

				--Begin Test case ResultCodeCheck.10
				--Description: check UNSUPPORTED_RESOURCE + true resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-1034

					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- If TTS/UI is the only source for request processing (e.g. no TTS/UI) then the genaral response parameter should be success=false, if not the only one than success=true.
						- If HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data.]]

					--Begin Test case ResultCodeCheck.10.1
					--Description: UNSUPPORTED_RESOURCE resultCode + true

						function Test:AlertManeuver_UnsupportedResourceTrue() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														--[[ TODO: update after resolving APPLINK-16052
														text = "Close",
														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "UNSUPPORTED_RESOURCE", "UNSUPPORTED_RESOURCE result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "UNSUPPORTED_RESOURCE result code" })
						    	:Timeout(11000)

						end

					--End Test case ResultCodeCheck.10.1

					--Begin Test case ResultCodeCheck.10.2
					--Description: UNSUPPORTED_RESOURCE resultCode + false

						function Test:AlertManeuver_UnsupportedResourceFalse() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "UNSUPPORTED_RESOURCE", "UNSUPPORTED_RESOURCE result code")
									end

									RUN_AFTER(alertResponse, 2000)
								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = "UNSUPPORTED_RESOURCE result code" })
						    	:Timeout(11000)

						end

					--End Test case ResultCodeCheck.10.2


				--End Test case ResultCodeCheck.10

				--Begin Test case ResultCodeCheck.11
				--Description: check WARNINGS + true resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-1068

					--Verification criteria:
						--[[- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
						- When this error code is issued, ttsChunks are not processed, but the RPC should be otherwise successful..]]

						function Test:AlertManeuver_WarningsTrue()  

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									local function alertResponse()
										self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

									end

									RUN_AFTER(alertResponse, 2000)
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendError(SpeakId, "TTS.Speak", "UNSUPPORTED_RESOURCE", "ttsChunks types are not supported")

									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS", info = "ttsChunks types are not supported" })
						    	:Timeout(11000)

						end

				--End Test case ResultCodeCheck.11

				--Begin Test case ResultCodeCheck.12
				--Description: check UNSUPPORTED_REQUEST + false resultCode

					--Requirement id in JAMA: SDLAQ-CRS-126, SDLAQ-CRS-1038

					--Verification criteria:
						--[[- The platform doesn't support navi requests, the responseCode UNSUPPORTED_REQUEST is returned. General request result success=false..]]

						function Test:AlertManeuver_UnsupportedRequest()  

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
									self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "UNSUPPORTED_REQUEST", "Request is not supported")
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "UNSUPPORTED_REQUEST", info = "Request is not supported" })

						end

				--End Test case ResultCodeCheck.12


			--End Test suit ResultCodeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- requests without responses from HMI
		-- invalid structure of response
		-- several responses from HMI to one request
		-- fake parameters
		-- HMI correlation id check
		-- wrong response with correct HMI correlation id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid sctructure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: Check processing 2 equal responses

			--Requirement id in JAMA: SDLAQ-CRS-126

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

			--Begin Test case HMINegativeCheck.1.1
			--Description: 2 responsens to TTS.Speak request

				function Test:AlertManeuver_TwoResponsesToTTSSpeak() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}, 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })
							end

							RUN_AFTER(alertResponse, 2000)
						end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
											{ 
												
												{ 
													text ="FirstAlert",
													type ="TEXT",
												}, 
												
												{ 
													text ="SecondAlert",
													type ="TEXT",
												}
											},
										speakType = "ALERT_MANEUVER",

									})
						:Do(function(_,data)
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
							end

							RUN_AFTER(speakResponse, 1000)

							RUN_AFTER(speakResponse, 1500)

						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
				    	:Timeout(11000)

				    DelayedExp(1000)

				end
			--End Test case HMINegativeCheck.1.1

			--Begin Test case HMINegativeCheck.1.2
			--Description: 2 responsens to Navigation.AlertManeuver request
				function Test:AlertManeuver_TwoResponsesToNavigationAlertMan() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}, 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })
							end

							RUN_AFTER(alertResponse, 2000)
							RUN_AFTER(alertResponse, 2500)
						end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
											{ 
												
												{ 
													text ="FirstAlert",
													type ="TEXT",
												}, 
												
												{ 
													text ="SecondAlert",
													type ="TEXT",
												}
											},
										speakType = "ALERT_MANEUVER",

									})
						:Do(function(_,data)
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
							end

							RUN_AFTER(speakResponse, 1000)

						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
				    	:Timeout(11000)

				    DelayedExp(1000)

				end
			--End Test case HMINegativeCheck.1.2
			
		--End Test case HMINegativeCheck.1

		--Begin Test case HMINegativeCheck.2
		--Description: Check processing responses with invalid structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-126

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

			--Begin Test case HMINegativeCheck.2.1
			--Description: TTS.Speak response with invalid structure
--[[TODO update according to APPLINK-14765
	
			function Test:AlertManeuver_InvalidResponseTTSSpeak() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}, 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
							end

							RUN_AFTER(alertResponse, 2000)
						end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
											{ 
												
												{ 
													text ="FirstAlert",
													type ="TEXT",
												}, 
												
												{ 
													text ="SecondAlert",
													type ="TEXT",
												}
											},
										speakType = "ALERT_MANEUVER",

									})
						:Do(function(_,data)
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:Send('{"error":{"code":4,"message":"Speak is REJECTED"},"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')	
							end

							RUN_AFTER(speakResponse, 1000)

						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "OUT_OF_MEMORY", info = "OutOfMemory result code" })
				    	:Timeout(11000)

				    DelayedExp(1000)

				end
			--End Test case HMINegativeCheck.2.1

			--Begin Test case HMINegativeCheck.2.2
			--Description: Navigation.AlertManeuver response with invalid structure
	
			function Test:AlertManeuver_InvalidResponseTTSSpeak() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}, 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:Send('{"error":{"code":4,"message":"AlertManeuver is REJECTED"},"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.AlertManeuver"}}')
							end

							RUN_AFTER(alertResponse, 2000)
						end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
											{ 
												
												{ 
													text ="FirstAlert",
													type ="TEXT",
												}, 
												
												{ 
													text ="SecondAlert",
													type ="TEXT",
												}
											},
										speakType = "ALERT_MANEUVER",

									})
						:Do(function(_,data)
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", {})
							end

							RUN_AFTER(speakResponse, 1000)

						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "OUT_OF_MEMORY", info = "OutOfMemory result code" })
				    	:Timeout(11000)

				    DelayedExp(1000)

				end
			--End Test case HMINegativeCheck.2.2

		--End Test case HMINegativeCheck.2

		--Begin Test case HMINegativeCheck.3
		--Description: HMI correlation id check

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: 

			--Begin Test case HMINegativeCheck.3.1
			--Description: Navigation.AlertManeuver response with empty correlation id

				function Test:AlertManeuver_HMIcorrelationIDEmpty() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:Send('"id":,"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.AlertManeuver"}}')
							end

							RUN_AFTER(alertResponse, 2000)
						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
				    	:Timeout(11000)

				end

			--End Test case HMINegativeCheck.3.1

			--Begin Test case HMINegativeCheck.3.2
			--Description: Navigation.AlertManeuver response with nonexistent HMI correlation id

				function Test:AlertManeuver_HMIcorrelationIDEmpty() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()

								self.hmiConnection:SendResponse(5555, "Navigation.AlertManeuve", "SUCCESS", {})

							RUN_AFTER(alertResponse, 2000)
						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
				    	:Timeout(11000)

				end

			--End Test case HMINegativeCheck.3.2

			--Begin Test case HMINegativeCheck.3.3
			--Description: Navigation.AlertManeuver response with wrong type of correlation id

				function Test:AlertManeuver_HMIcorrelationIDWrongType() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = tostring(data.id)
							local function alertResponse()
								
								self.hmiConnection:SendResponse(5555, "Navigation.AlertManeuve", "SUCCESS", {})

							RUN_AFTER(alertResponse, 2000)
						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
				    	:Timeout(11000)

				end

			--End Test case HMINegativeCheck.3.3

			--Begin Test case HMINegativeCheck.3.4
			--Description: TTS.Speak response with correlation id of Navigation.AlertManeuver request, Navigation.AlertManeuver response with with correlation id of TTS.Speak request

				function Test:AlertManeuver_ResponseTTSWithCorrelationIdNavigation() 

				 			--mobile side: AlertManeuver request 
							local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																			{
																			  	 
																				ttsChunks = 
																				{ 
																					
																					{ 
																						text ="FirstAlert",
																						type ="TEXT",
																					}, 
																					
																					{ 
																						text ="SecondAlert",
																						type ="TEXT",
																					}, 
																				}, 
																				softButtons = 
																				{ 
																					
																					{ 
																						type = "BOTH",
																						text = "Close",
																						 image = 
																			
																						{ 
																							value = "icon.png",
																							imageType = "DYNAMIC",
																						}, 
																						isHighlighted = true,
																						softButtonID = 821,
																						systemAction = "DEFAULT_ACTION",
																					}
																				}
																			
																			})

							local AlertId
							--hmi side: Navigation.AlertManeuver request 
							EXPECT_HMICALL("Navigation.AlertManeuver", 
											{	
												softButtons = 
												{ 
													
													{ 
														type = "BOTH",
														text = "Close",
														  --[=[ TODO: update after resolving APPLINK-16052

														 image = 
											
														{ 
															value = pathToIconFolder .. "/icon.png",
															imageType = "DYNAMIC",
														},]=] 
														isHighlighted = true,
														softButtonID = 821,
														systemAction = "DEFAULT_ACTION",
													}
												}
											})
								:Do(function(_,data)
									AlertId = data.id
								end)

							local SpeakId
							--hmi side: TTS.Speak request 
							EXPECT_HMICALL("TTS.Speak", 
											{	
												ttsChunks = 
													{ 
														
														{ 
															text ="FirstAlert",
															type ="TEXT",
														}, 
														
														{ 
															text ="SecondAlert",
															type ="TEXT",
														}
													},
												speakType = "ALERT_MANEUVER",

											})
								:Do(function(_,data)
									SpeakId = data.id

									local function speakResponse()
										self.hmiConnection:SendResponse(AlertId, "TTS.Speak", "SUCCESS", { })

										self.hmiConnection:SendResponse(SpeakId, "Navigation.AlertManeuver", "SUCCESS", { })
									end

									RUN_AFTER(speakResponse, 1000)

								end)
								 

						    --mobile side: expect AlertManeuver response
						    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })
						    	:Timeout(11000)

						end

			--End Test case HMINegativeCheck.3.4
]]
			--Begin Test case HMINegativeCheck.3.5
			--Description: Navigation.AlertManeuver response after timeout is expired
	
				function Test:AlertManeuver_SendingNavResponseAfterTimeoutExpired() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																	  	 
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text ="FirstAlert",
																				type ="TEXT",
																			}, 
																			
																			{ 
																				text ="SecondAlert",
																				type ="TEXT",
																			}, 
																		}, 
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
							end

							RUN_AFTER(alertResponse, 12000)
						end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
											{ 
												
												{ 
													text ="FirstAlert",
													type ="TEXT",
												}, 
												
												{ 
													text ="SecondAlert",
													type ="TEXT",
												}
											},
										speakType = "ALERT_MANEUVER",

									})
						:Do(function(_,data)
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", {})
							end

							RUN_AFTER(speakResponse, 1000)

						end)
						 

				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
				    	:Timeout(14000)

				    DelayedExp(1000)

				end
			--End Test case HMINegativeCheck.3.5


		--End Test case HMINegativeCheck.3

		--Begin Test case HMINegativeCheck.4
		--Description: Check processing response with fake parameters(not from API)
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-126, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--[[In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters]]

				function Test:AlertManeuver_FakeParamsInResponse() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { fake = "fake"})
							end

							RUN_AFTER(alertResponse, 2000)
						end)


				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
				    	:Timeout(11000)
				    	:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)


				end

		--End Test case HMINegativeCheck.4

		--Begin Test case HMINegativeCheck.5
		--Description: Check processing response with fake parameters from another API
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-126, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--[[In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters]]

				function Test:AlertManeuver_ParamsFromAnotherAPIInResponse() 

		 			--mobile side: AlertManeuver request 
					local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																	{
																		softButtons = 
																		{ 
																			
																			{ 
																				type = "BOTH",
																				text = "Close",
																				 image = 
																	
																				{ 
																					value = "icon.png",
																					imageType = "DYNAMIC",
																				}, 
																				isHighlighted = true,
																				softButtonID = 821,
																				systemAction = "DEFAULT_ACTION",
																			}
																		}
																	
																	})

					local AlertId
					--hmi side: Navigation.AlertManeuver request 
					EXPECT_HMICALL("Navigation.AlertManeuver", 
									{	
										softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 821,
												systemAction = "DEFAULT_ACTION",
											}
										}
									})
						:Do(function(_,data)
							AlertId = data.id
							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { sliderPosition = 5 })
							end

							RUN_AFTER(alertResponse, 2000)
						end)


				    --mobile side: expect AlertManeuver response
				    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
				    	:Timeout(11000)
				    	:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend sliderPosition parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)


				end

		--End Test case HMINegativeCheck.5


	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	--[[TODO: update Requirement, Verification criteria]]
		--Begin Test case SequenceCheck.1
		--Description: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout (SUCCESS)notification received from HMI

			--Requirement id in JAMA:

			--Verification criteria:

			function Test:AlertManeuver_OnResetTimeoutWithSuccessResponse() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{ 
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 821,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "BOTH",
																			text = "AnotherClose",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = false,
																			softButtonID = 822,
																			systemAction = "DEFAULT_ACTION",
																		},
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											text = "Close",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											text = "AnotherClose",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = pathToIconFolder.. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function OnResetTimeoutNot()

							self.hmiConnection:SendNotification("TTS.OnResetTimeout",
															{
																appID = self.applications["Test Application"],
																methodName = "TTS.Speak"
															})

						end

						local function speakAlertResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")

							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

						end

						RUN_AFTER(OnResetTimeoutNot, 5000)
						RUN_AFTER(OnResetTimeoutNot, 10000)
						RUN_AFTER(OnResetTimeoutNot, 15000)
						RUN_AFTER(OnResetTimeoutNot, 20000)

						RUN_AFTER(speakAlertResponse, 25000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self,_,31000)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(31000)

			end
			
		--End Test case SequenceCheck.1

		--[[TODO: update Requirement, Verification criteria]]
		--Begin Test case SequenceCheck.2
		--Description: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout (GENERIC_ERROR)notification received from HMI

			--Requirement id in JAMA:

			--Verification criteria:

			function Test:AlertManeuver_OnResetTimeoutWithGenericErrorResponse() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
												
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{ 
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 821,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "BOTH",
																			text = "AnotherClose",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = false,
																			softButtonID = 822,
																			systemAction = "DEFAULT_ACTION",
																		},
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											--[[ TODO: update after resolving APPLINK-16052
											text = "Close",
											image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]]
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											--[[ TODO: update after resolving APPLINK-16052
											text = "AnotherClose",
											 image = 
								
											{ 
												value = pathToIconFolder.. "/icon.png",
												imageType = "DYNAMIC",
											},]]
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function OnResetTimeoutNot()

							self.hmiConnection:SendNotification("TTS.OnResetTimeout",
															{
																appID = self.applications["Test Application"],
																methodName = "TTS.Speak"
															})

						end

						local function speakAlertResponse()

							self.hmiConnection:SendNotification("TTS.Stopped")

							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

						end

						RUN_AFTER(OnResetTimeoutNot, 5000)
						RUN_AFTER(OnResetTimeoutNot, 10000)
						RUN_AFTER(OnResetTimeoutNot, 15000)
						RUN_AFTER(OnResetTimeoutNot, 20000)

						RUN_AFTER(speakAlertResponse, 25000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self,_,36000)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "GENERIC_ERROR" })
			    	:Timeout(36000)

			end
			
		--End Test case SequenceCheck.2

--------------------------------------------------------------------------------------------------------------------------------------------------------------

     --Begin Test case SequenceCheck.3

     --Description: reflecting on UI Alert with soft buttons when different params are defined; different conditions of long and short press action
        --TC_SoftButtons_01: short and long click on TEXT soft button , reflecting on UI only if text is defined
        --TC_SoftButtons_02: short and long click on IMAGE soft button, reflecting on UI only if image is defined   
        --TC_SoftButtons_03: short click on BOTH soft button, reflecting on UI
	--TC_SoftButtons_04: long click on BOTH soft button
			
      --Requirement id in JAMA: mentioned in each test case
      --Verification criteria: mentioned in each test case
				
			
		--Begin Test case SequenceCheck.3.1
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on TEXT soft button
			
			function Test:AlertManeuver_TEXTSoftButtons_ShortClick()

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
																			text = "First",
																			type = "TEXT",
																			isHighlighted = false,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 2,
																			text = "Second",
																			type = "TEXT",
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		},
																		{
																			softButtonID = 3,
																			text = "Third",
																			type = "TEXT",      
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1,
												text = "First",
												type = "TEXT",
												isHighlighted = false,
												systemAction = "KEEP_CONTEXT"
											},
											{
												softButtonID = 2,
												text = "Second",
												type = "TEXT",
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											},
											{
												softButtonID = 3,
												text = "Third",
												type = "TEXT",      
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 2})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 

		--End Test case SequenceCheck.3.1
	


		--Begin Test case SequenceCheck.3.2
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on TEXT soft button

			 function Test:AlertManeuver_TEXTSoftButtons_LongClick()  

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
																			text = "First",
																			type = "TEXT",
																			isHighlighted = false,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 2,
																			text = "Second",
																			type = "TEXT",
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		},
																		{
																			softButtonID = 3,
																			text = "Third",
																			type = "TEXT",      
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1,
												text = "First",
												type = "TEXT",
												isHighlighted = false,
												systemAction = "KEEP_CONTEXT"
											},
											{
												softButtonID = 2,
												text = "Second",
												type = "TEXT",
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											},
											{
												softButtonID = 3,
												text = "Third",
												type = "TEXT",      
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 3})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 

		 --End Test case SequenceCheck.3.2
	


		--Begin Test case SequenceCheck.3.3
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined


			--Begin Test case SequenceCheck.3.3.1

			 function Test:AM_SoftButtonTypeTEXTAndTextWithWhitespace()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																			softButtonID = 1, 
																			text = "  ",                  
																			type = "TEXT",                 
																			isHighlighted = false,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1, 
												text = "  ",                  
												type = "TEXT",                 
												isHighlighted = false,
												systemAction = "DEFAULT_ACTION"
									        }
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end		

		--End Test case SequenceCheck.3.3.1


		--Begin Test case SequenceCheck.3.3.2

		 function Test:AM_SoftButtonTypeTEXTAndTextEpmty()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																			softButtonID = 1, 
																			text = "",                  
																			type = "TEXT",                 
																			isHighlighted = false,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1, 
												text = "",                  
												type = "TEXT",                 
												isHighlighted = false,
												systemAction = "DEFAULT_ACTION"
									        }
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end				

                --End Test case SequenceCheck.3.3.2


                --Begin Test case SequenceCheck.3.3.3

		 function Test:AM_SoftButtonTypeTEXTAndTextUndefined()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																			softButtonID = 1, 
																			text,                  
																			type = "TEXT",                 
																			isHighlighted = false,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1, 
												text,                  
												type = "TEXT",                 
												isHighlighted = false,
												systemAction = "DEFAULT_ACTION"
									        }
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end		

		--End Test case SequenceCheck.3.3.3

	--End Test case SequenceCheck.3.3
	


		--Begin Test case SequenceCheck.3.4
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
		--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on IMAGE soft button

			function Test:AlertManeuver_IMAGESoftButtons_ShortClick()   

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
                                                                            text = "First",
																			type = "IMAGE",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 2,
																			text = "Second",
																			type = "IMAGE",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}		
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
											softButtonID = 1,
											type = "IMAGE",
											--[[ TODO: update after resolving APPLINK-16052
                                            text = "First",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },   ]]    
											isHighlighted = true,
											systemAction = "KEEP_CONTEXT"
										},
										{
											softButtonID = 2,
											--[[ TODO: update after resolving APPLINK-16052
										    text = "Second",
											type = "IMAGE",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },       ]]
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 2})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 

		--End Test case SequenceCheck.3.4
	


		--Begin Test case SequenceCheck.3.5
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	 	--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on IMAGE soft button

			function Test:AlertManeuver_IMAGESoftButtons_LongClick()  

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
                                                                                                                                                        text = "First",
																			type = "IMAGE",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 2,
																			text = "Second",
																			type = "IMAGE",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}		
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
											softButtonID = 1,
											type = "IMAGE",
											--[[ TODO: update after resolving APPLINK-16052
											text = "First",
											image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },       ]]
											isHighlighted = true,
											systemAction = "KEEP_CONTEXT"
										},
										{
											softButtonID = 2,
											--[[ TODO: update after resolving APPLINK-16052
										    text = "Second",
											type = "IMAGE",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },       ]]
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 2})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 

		--End Test case SequenceCheck.3.5

	


		--Begin Test case SequenceCheck.3.6
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined 

			function Test:AM_SoftButtonTypeIMAGEAndImageNotExists()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																			softButtonID = 1,
																			text = "First", 
																			type = "IMAGE",       
																			isHighlighted = false,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 2,
																			type = "IMAGE",
																			image = 
																			 {
																				value = "aaa.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "KEEP_CONTEXT"
																		}
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
													softButtonID = 1,
													text = "First", 
													type = "IMAGE",       
													isHighlighted = false,
													systemAction = "KEEP_CONTEXT"
												},
												{
													softButtonID = 2,
													type = "IMAGE",
													image = 
													 {
														value = "aaa.png",
														imageType = "DYNAMIC"
													  },       
													isHighlighted = true,
													systemAction = "KEEP_CONTEXT"
												}
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end

	 	--End Test case SequenceCheck.3.6
	       


		--Begin Test case SequenceCheck.3.7
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
		--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on BOTH soft button

			function Test:AlertManeuver_SoftButtonTypeBOTH_ShortClick() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
																			text = "First",
																			type = "BOTH",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },
																			isHighlighted = false,
																			systemAction = "DEFAULT_ACTION"
																		},
																		{
																			softButtonID = 2,
																			text = "Second",
																			type = "BOTH",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },                    
																			isHighlighted = true,
																			systemAction = "KEEP_CONTEXT"
																		},
																		{
																			softButtonID = 3,
																			text = "Third",
																			type = "BOTH",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}		
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
											softButtonID = 1,
											--[[ TODO: update after resolving APPLINK-16052
											text = "First",
											type = "BOTH",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },]]
											isHighlighted = false,
											systemAction = "DEFAULT_ACTION"
										},
										{
											softButtonID = 2,
											--[[ TODO: update after resolving APPLINK-16052
											text = "Second",
											type = "BOTH",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },         ]]           
											isHighlighted = true,
											systemAction = "KEEP_CONTEXT"
										},
										{
											softButtonID = 3,
											--[[ TODO: update after resolving APPLINK-16052
										    text = "Third",
											type = "BOTH",
										        image = 
											 {
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC"
											  },       ]]
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										}
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 3})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 	

	 	--End Test case SequenceCheck.3.7
	


		--Begin Test case SequenceCheck.3.8
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

			function Test:AM_SoftButtonTypeBOTHAndTextIsEmpty()

				                    local RequestParams =
														{
															 
															ttsChunks = 
															{ 
																
																{ 
																	text ="FirstAlert",
																	type ="TEXT",
																}, 
																
																{ 
																	text ="SecondAlert",
																	type ="TEXT",
																}, 
															}, 
															softButtons = 
															{ 
																{
																	softButtonID = 1,
																	type = "BOTH",
																	text = "",            --text is empty
																	image = 
																	 {
																		value = "icon.png",
																		imageType = "DYNAMIC"
																	  },       
																	isHighlighted = false,
																	systemAction = "DEFAULT_ACTION"
																  }
															}
														
														}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										  {
										softButtonID = 1,
										type = "BOTH",
										text = "",            --text is empty
										image = 
										 {
											value = pathToIconFolder .. "/icon.png",
											imageType = "DYNAMIC"
										  },    
										isHighlighted = false,
										systemAction = "DEFAULT_ACTION"
									  }
                                    }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end
		
		--End Test case SequenceCheck.6.8
	      


		--Begin Test case SequenceCheck.6.9
		--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
		--Info: This TC will be failing till resolving APPLINK-16052
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on BOTH soft button

			function Test:AlertManeuver_SoftButtonBOTHType_LongClick() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
																			type = "BOTH",
																			text = "First text",
																			image = 
																			 {
																				value = "icon.png",
																				imageType = "DYNAMIC"
																			  },       
																			isHighlighted = true
																		}
																	}		
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										{
												softButtonID = 1,
												type = "BOTH",
												--[[ TODO: update after resolving APPLINK-16052
												text = "First text",
												image = 
												 {
													value = pathToIconFolder .. "/icon.png",
													imageType = "DYNAMIC"
												  },      ]] 
												isHighlighted = true
											}
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 	

		--End Test case SequenceCheck.3.9

	


		--Begin Test case SequenceCheck.3.10
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

			 function Test:AM_SoftButtonBOTHTypeAndNoImage()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																				softButtonID = 1,
																				type = "BOTH",
																				text = "First",                 --image is not defined
																				isHighlighted = false,
																				systemAction = "DEFAULT_ACTION"
																		 } 
											 
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										              {
													softButtonID = 1,
													type = "BOTH",
													text = "First",                 --image is not defined
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION"
											     } 
											 
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end

	 	--End Test case SequenceCheck.3.10


	   
	     	--Begin Test case SequenceCheck.3.11
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
		--Info: This TC will be failing till resolving APPLINK-16052
	
			--Requirement id in JAMA: SDLAQ-CRS-2912

			--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed 

		
		function Test:SubscribeButton_CUSTOM_BUTTON_SUCCESS()
	
			--mobile side: send UnsubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = "CUSTOM_BUTTON"
				})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = true})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response 
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS	
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		
	    end
		
        function Test:UnsubscribeButton_CUSTOM_BUTTON_SUCCESS()
	
			--mobile side: send UnsubscribeButton request
			local cid = self.mobileSession:SendRPC("UnsubscribeButton",
				{
					buttonName = "CUSTOM_BUTTON"
				})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = false})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response 
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS	
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		
	    end

		function Test:AlertManeuver_SoftButton_AfterUnsubscribe()  

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{
																			softButtonID = 1,
																			type = "TEXT",
																			text = "First",      
																			isHighlighted = true,
																			systemAction = "DEFAULT_ACTION"
																		}
																	}		
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										        {
												softButtonID = 1,
												type = "TEXT",
												text = "First",      
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											}
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
						
						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)


						local function ButtonEventPress()
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
						end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
				:Times(0)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
				:Times(0)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end 		 

	 --End Test case SequenceCheck.3.11

         --Begin Test case SequenceCheck.3.12
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

			function Test:AM_SoftButtonBOTHTypeAndImageandTextUndefined()

				                    local RequestParams =

	 			
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		{
																				softButtonID = 1,
																				type = "BOTH",                
																				isHighlighted = false,
																				systemAction = "DEFAULT_ACTION"
																		 } 
											 
																	}
																
																}

				--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver", RequestParams)

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									appID = self.applications["Test Application"],
									softButtons = 
									{ 
										
										              {
													softButtonID = 1,
													type = "BOTH",
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION"
											     } 
											 
                                                                         }
								})
                                 :Times(0) 

          
			    --mobile side: AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = false, resultCode = "INVALID_DATA" })	

			end


         --End Test case SequenceCheck.3.12
 
 --End Test suit SequenceCheck
      

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: Processing AlertManeuver request in LIMITED HMI level (executed in case on navigation or media app)

			--Requirement id in JAMA: SDLAQ-CRS-806

			--Verification criteria: SDL doesn't reject AlertManeuver request when current HMI is LIMITED.

		if 
			Test.isMediaApplication == true or 
			Test.appHMITypes["NAVIGATION"] == true then

			function Test:Presondition_DeactivateToLimited()

				--hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

			end

			function Test:AlertManeuver_LimitedHMILevel() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{ 
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 821,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "BOTH",
																			text = "AnotherClose",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = false,
																			softButtonID = 822,
																			systemAction = "DEFAULT_ACTION",
																		},
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											 --[[ TODO: update after resolving APPLINK-16052
											text = "Close",											 
											image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											--[[ TODO: update after resolving APPLINK-16052
											text = "AnotherClose",
											
											 image = 
								
											{ 
												value = pathToIconFolder.. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)

					end)
					 

				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    })
			    	:Times(2)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			end

			
		--End Test case DifferentHMIlevel.1

		--Begin Test case DifferentHMIlevel.2
		--Description: Processing Alert request in Background HMI level

			--Requirement id in JAMA: SDLAQ-CRS-806

			--Verification criteria: SDL doesn't reject AlertManeuver request when current HMI is BACKGROUND.

			--Preocdition for media/navigation application
				--Precondition: Start second session
					function Test:Case_SecondSession()
					  self.mobileSession1 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end
				
				--Precondition: "Register second app"
					function Test:Case_AppRegistrationInSecondSession()
						self.mobileSession1:StartService(7)
						:Do(function()
								local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
								{
								  syncMsgVersion =
								  {
									majorVersion = 3,
									minorVersion = 0
								  },
								  appName = "Test Application2",
								  isMediaApplication = true,
								  languageDesired = 'EN-US',
								  hmiDisplayLanguageDesired = 'EN-US',
								  appHMIType = { "NAVIGATION" },
								  appID = "1"
								})

								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								{
								  application = 
								  {
									appName = "Test Application2"
								  }
								})
								:Do(function(_,data)
								  	local appId2 = data.params.application.appID
									self.appId2 = appId2
								end)

								self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
							end)
						end
					
				--Precondition: Activate second app
					function Test:ActivateSecondApp()
						local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appId2})
						EXPECT_HMIRESPONSE(rid)
						
						self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end

			elseif
				Test.isMediaApplication == false then

				function Test:Presondition_DeactivateToBackground()

				--hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

				end

			end

			function Test:AlertManeuver_BackgroundHMILevel() 

	 			--mobile side: AlertManeuver request 
				local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text ="FirstAlert",
																			type ="TEXT",
																		}, 
																		
																		{ 
																			text ="SecondAlert",
																			type ="TEXT",
																		}, 
																	}, 
																	softButtons = 
																	{ 
																		
																		{ 
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 821,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "BOTH",
																			text = "AnotherClose",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = false,
																			softButtonID = 822,
																			systemAction = "DEFAULT_ACTION",
																		},
																	}
																
																})

				local AlertId
				--hmi side: Navigation.AlertManeuver request 
				EXPECT_HMICALL("Navigation.AlertManeuver", 
								{	
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											 --[[ TODO: update after resolving APPLINK-16052
											text = "Close",
											
											 image = 
								
											{ 
												value = pathToIconFolder .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 821,
											systemAction = "DEFAULT_ACTION",
										}, 
										
										{ 
											type = "BOTH",
											--[[ TODO: update after resolving APPLINK-16052
											text = "AnotherClose",
										
											 image = 
								
											{ 
												value = pathToIconFolder.. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = false,
											softButtonID = 822,
											systemAction = "DEFAULT_ACTION",
										} 
									}
								})
					:Do(function(_,data)
						AlertId = data.id
						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
										{ 
											
											{ 
												text ="FirstAlert",
												type ="TEXT",
											}, 
											
											{ 
												text ="SecondAlert",
												type ="TEXT",
											}
										},
									speakType = "ALERT_MANEUVER",

								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 1000)

					end)
					 
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then
						--mobile side: OnHMIStatus notifications
						self.mobileSession1:ExpectNotification("OnHMIStatus",
										    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
										    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
					    	:Times(2)

					    self.mobileSession:ExpectNotification("OnHMIStatus", {})
					    	:Times(0)
				elseif
					self.isMediaApplication == false then
						self.mobileSession:ExpectNotification("OnHMIStatus", {})
					    	:Times(0)
				end


			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

			    DelayedExp(1000)

			end

		--End Test case DifferentHMIlevel.2
	--End Test suit DifferentHMIlevel
	
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()                   

