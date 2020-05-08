Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')


require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local imageValues = {"action.png", "a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"}
local imageTypes ={"STATIC", "DYNAMIC"}

local function ExpectOnHMIStatusWithAudioStateChanged(self, request, timeout, level)

	if request == nil then  request = "BOTH" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if 
		self.isMediaApplication == true or 
		Test.appHMITypes["NAVIGATION"] == true then 

			if request == "BOTH" then
				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
					    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(4)
				    :Timeout(timeout)
			elseif request == "speak" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			elseif request == "alert" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	elseif 
		self.isMediaApplication == false then

			if request == "BOTH" then
				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
					    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
				    :Times(2)
				    :Timeout(timeout)
			elseif request == "speak" then
				--any OnHMIStatusNotifications
				EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
					:Timeout(timeout)
			elseif request == "alert" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	end

end

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Allow GetVehicleData in all levels
	function Test:StopSDLToBackUpPreloadedPt( ... )
		-- body
		StopSDL()
		DelayedExp(1000)
	end

	function Test:BackUpPreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
	end

	function Test:ModifyPreloadedPt(pathToFile)
		-- body
		pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
		local file  = io.open(pathToFile, "r")
		local json_data = file:read("*all") -- may be abbreviated to "*a";
		file:close()

		local json = require("modules/json")
		 
		local data = json.decode(json_data)
		for k,v in pairs(data.policy_table.functional_groupings) do
			if (data.policy_table.functional_groupings[k].rpcs == nil) then
			    --do
			    data.policy_table.functional_groupings[k] = nil
			else
			    --do
			    local count = 0
			    for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
			    if (count < 30) then
			        --do
					data.policy_table.functional_groupings[k] = nil
			    end
			end
		end

		data.policy_table.functional_groupings.AlertGroup = {}
		data.policy_table.functional_groupings.AlertGroup.rpcs = {}
		data.policy_table.functional_groupings.AlertGroup.rpcs.Alert = {}
		data.policy_table.functional_groupings.AlertGroup.rpcs.Alert.hmi_levels = {'FULL', 'LIMITED', 'BACKGROUND'}

		data.policy_table.app_policies.default.keep_context = true
		data.policy_table.app_policies.default.steal_focus = true
		data.policy_table.app_policies.default.priority = "NORMAL"
		data.policy_table.app_policies.default.groups = {"Base-4", "AlertGroup"}
		
		data = json.encode(data)
		-- print(data)
		-- for i=1, #data.policy_table.app_policies.default.groups do
		-- 	print(data.policy_table.app_policies.default.groups[i])
		-- end
		file = io.open(pathToFile, "w")
		file:write(data)
		file:close()
	end

	local function StartSDLAfterChangePreloaded()
		-- body

		Test["Precondition_StartSDL"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
			DelayedExp(1000)
		end

		Test["Precondition_InitHMI_1"] = function(self)
			self:initHMI()
		end

		Test["Precondition_InitHMI_onReady_1"] = function(self)
			self:initHMI_onReady()
		end

		Test["Precondition_ConnectMobile_1"] = function(self)
			self:connectMobile()
		end

		Test["Precondition_StartSession_1"] = function(self)
			self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
		end

	end

	StartSDLAfterChangePreloaded()

	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end
	--End Precondition.1

	--Begin Precondition.2
	--Description: Activation application			
	local GlobalVarAppID = 0
	function RegisterApplication(self)
		-- body
		local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function (_, data)
			-- body
			GlobalVarAppID = data.params.application.appID
		end)

		EXPECT_RESPONSE(corrID, {success = true})

		-- delay - bug of ATF - it is not wait for UpdateAppList and later
		-- line appID = self.applications["Test Application"]} will not assign appID
		DelayedExp(1000)
	end

	function Test:RegisterApp()
		-- body
		self.mobileSession:StartService(7)
		:Do(function (_, data)
			-- body
			RegisterApplication(self)
		end)
	end
	--End Precondition.2

	--Begin Precondition.1
	--Description: Activation application		
		function Test:ActivationApp()			
			--hmi side: sending SDL.ActivateApp request
			-- local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = GlobalVarAppID})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				if
					data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					
					--hmi side: expect SDL.GetUserFriendlyMessage message response
					 --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)						
						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
	--End Precondition.1

	-- --Begin Precondition.2
	-- --Description: Update Policy with Alert softButtons are true
	-- function Test:Precondition_PolicyUpdate()
	-- 	--hmi side: sending SDL.GetURLS request
	-- 	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
	-- 	--hmi side: expect SDL.GetURLS response from HMI
	-- 	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	-- 	:Do(function(_,data)
	-- 		--print("SDL.GetURLS response is received")
	-- 		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	-- 		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
	-- 			{
	-- 				requestType = "PROPRIETARY",
	-- 				fileName = "filename"
	-- 			}
	-- 		)
	-- 		--mobile side: expect OnSystemRequest notification 
	-- 		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
	-- 		:Do(function(_,data)
	-- 			--print("OnSystemRequest notification is received")
	-- 			--mobile side: sending SystemRequest request 
	-- 			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
	-- 				{
	-- 					fileName = "PolicyTableUpdate",
	-- 					requestType = "PROPRIETARY"
	-- 				},
	-- 			"files/PTU_AlertSoftButtonsTrue.json")
				
	-- 			local systemRequestId
	-- 			--hmi side: expect SystemRequest request
	-- 			EXPECT_HMICALL("BasicCommunication.SystemRequest")
	-- 			:Do(function(_,data)
	-- 				systemRequestId = data.id
	-- 				--print("BasicCommunication.SystemRequest is received")
					
	-- 				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	-- 				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
	-- 					{
	-- 						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
	-- 					}
	-- 				)
	-- 				function to_run()
	-- 					--hmi side: sending SystemRequest response
	-- 					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
	-- 				end
					
	-- 				RUN_AFTER(to_run, 500)
	-- 			end)
				
	-- 			--hmi side: expect SDL.OnStatusUpdate
	-- 			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
	-- 			:ValidIf(function(exp,data)
	-- 				if 
	-- 					exp.occurences == 1 and
	-- 					data.params.status == "UP_TO_DATE" then
	-- 						return true
	-- 				elseif
	-- 					exp.occurences == 1 and
	-- 					data.params.status == "UPDATING" then
	-- 						return true
	-- 				elseif
	-- 					exp.occurences == 2 and
	-- 					data.params.status == "UP_TO_DATE" then
	-- 						return true
	-- 				else 
	-- 					if 
	-- 						exp.occurences == 1 then
	-- 							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
	-- 					elseif exp.occurences == 2 then
	-- 							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
	-- 					end
	-- 					return false
	-- 				end
	-- 			end)
	-- 			:Times(Between(1,2))
				
	-- 			--mobile side: expect SystemRequest response
	-- 			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
	-- 			:Do(function(_,data)
	-- 				--print("SystemRequest is received")
	-- 				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
	-- 				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
					
	-- 				--hmi side: expect SDL.GetUserFriendlyMessage response
	-- 				-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
	-- 				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
	-- 				:Do(function(_,data)
	-- 					print("SDL.GetUserFriendlyMessage is received")			
	-- 				end)
	-- 			end)
				
	-- 		end)
	-- 	end)
	-- end
	-- --End Precondition.2

	--Begin Precondition.3
	--Description: PutFile with file names "a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"
	
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
	--End Precondition.4

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck
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
    	--Description: This test is intended to check positive cases and when all parameters 
			-- are in boundary conditions (ABORTED because of SoftButtons presence) 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-49

			--Verification criteria: Alert request notifies the user via TTS/UI or both with some information. 
		
			function Test:Alert_Positive() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052


										 image = 
							
										{ 
											value = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.."/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)

				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			
		end

	--End Test case CommonRequestCheck.1

	
	--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters  

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-49

			--Verification criteria: Alert request notifies the user via TTS/UI or both with some information.

			--Begin Test case CommonRequestCheck.2.1
			--Description: Check request with  alertText1 only  

				function Test:Alert_MandatoryAlertText1Only() 

					--mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
																	{
																	  	 
																		alertText1 = "alertText1",
																	
																	})

					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}

									})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)


					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
					
				end

			--End Test case CommonRequestCheck.2.1

			
			--Begin Test case CommonRequestCheck.2.2
			--Description: Check request with  alertText1 only  

				function Test:Alert_MandatoryAlertText2Only() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	alertText2 = "alertText2",
																
																}) 

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = {{fieldName = "alertText2", fieldText = "alertText2"}}

								})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end

		--End Test case CommonRequestCheck.2.2


		--Begin Test case CommonRequestCheck.2.3
		--Description: Check request with  TTSChunks only  

			function Test:Alert_MandatoryTTSChunksOnly() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text = "TTSChunkOnly",
																			type = "TEXT",
																		}, 
																	}, 
																
																}) 
			 

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
									{ 
										
										{ 
											text = "TTSChunkOnly",
											type = "TEXT",
										}, 
									},
									speakType = "ALERT"
								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self, "speak")

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end

		--End Test case CommonRequestCheck.2.3


	--End Test case CommonRequestCheck.2

	--Begin Test case CommonRequestCheck.3
	--Description: This test is intended to check processing requests without mandatory parameters

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

		--Verification criteria:  The request without "ttsChunks" and without any "alertText" is sent, INVALID_DATA response code is returned.

		--Begin Test case CommonRequestCheck.3.1
		--Description: Request without any mandatory parameter (INVALID_DATA)

			function Test:Alert_WithoutMandatory() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	alertText3 = "alertText3",
																	duration = 3000,
																	playTone = true,
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
																			softButtonID = 3,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																		
																		{ 
																			type = "TEXT",
																			text = "Keep",
																			isHighlighted = true,
																			softButtonID = 4,
																			systemAction = "KEEP_CONTEXT",
																		}, 
																		
																		{ 
																			type = "IMAGE",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			softButtonID = 5,
																			systemAction = "STEAL_FOCUS",
																		}, 
																	}, 
																
																}) 
			 

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end

		--End Test case CommonRequestCheck.3.1

		--Begin Test case CommonRequestCheck.3.2
		--Description: All parameters are missing (INVALID_DATA)

			function Test:Alert_MissingAllParams() 

				--mobile side: Alert request 
				local CorIdAlert = self.mobileSession:SendRPC("Alert",{}) 
			 
			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end

		--Begin Test case CommonRequestCheck.3.2

		--Begin Test case CommonRequestCheck.3.3
		--Description: ttsChunks: text is missing

			 function Test:Alert_ttsChunksTextMissing() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									type = "TEXT"
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		


					end

		--Begin Test case CommonRequestCheck.3.3


		--Begin Test case CommonRequestCheck.3.4
		--Description: ttsChunks: type is missing 

			function Test:Alert_ttsChunksTypeMissing() 

				 --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
				{
				  	 
					alertText1 = "alertText1",
					alertText2 = "alertText2",
					alertText3 = "alertText3",
					ttsChunks = 
					{ 
						
						{ 
							text = "TTSChunk",
						}, 
					}, 
					duration = 6000,
				
				}) 
			 

				--mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		

			end

		--Begin Test case CommonRequestCheck.3.4

		--Begin Test case CommonRequestCheck.3.5
		--Description: SoftButtons: type of SoftButton is missing 

			function Test:Alert_SoftButtonsTypeMissing() 

				 --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
				{
				  	 
					alertText1 = "alertText1",
					ttsChunks = 
					{ 
						{ 
							text = "TTSChunk",
							type = "TEXT",
						}, 
					}, 
					duration = 3000,
					softButtons = 
					{ 
						
						{ 
							text = "Close",
							 image = 
				
							{ 
								value = "icon.png",
								imageType = "DYNAMIC",
							}, 
							isHighlighted = true,
							softButtonID = 841,
							systemAction = "DEFAULT_ACTION",
						}, 
					}, 
				
				}) 

				--mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end

		--Begin Test case CommonRequestCheck.3.5

		--Begin Test case CommonRequestCheck.3.6
		--Description:SoftButtons: softButtonID missing 

			function Test:Alert_SoftButtonsIDMissing() 

				 --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
				{
				  	 
					alertText1 = "alertText1",
					ttsChunks = 
					{ 
						
						{ 
							text = "TTSChunk",
							type = "TEXT",
						}, 
					}, 
					duration = 3000,
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
							systemAction = "DEFAULT_ACTION",
						}, 
					}, 
				
				}) 
			 

				--mobile side: Alert response
				EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


			end

		--Begin Test case CommonRequestCheck.3.6

		--Begin Test case CommonRequestCheck.3.7
		--Description:SoftButtons: type = IMAGE; image value is missing 

			function Test:Alert_SoftButtonIMAGEValueMissing() 

				 --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
				{
				  	 
					alertText1 = "alertText1",
					ttsChunks = 
					{ 
						
						{ 
							text = "TTSChunk",
							type = "TEXT",
						}, 
					}, 
					duration = 3000,
					softButtons = 
					{ 
						
						{ 
							type = "IMAGE",
							 image = 
				
							{ 
								imageType = "DYNAMIC",
							}, 
							softButtonID = 1131,
							systemAction = "STEAL_FOCUS",
						}, 
					}, 
				
				}) 
			 

				--mobile side: Alert response
				EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


			end

		--Begin Test case CommonRequestCheck.3.7

		--Begin Test case CommonRequestCheck.3.8
		--Description: SoftButtons: type = IMAGE; image type is missing 

			function Test:Alert_SoftButtonIMAGETypeMissing() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
				{
				  	 
					alertText1 = "alertText1",
					ttsChunks = 
					{ 
						
						{ 
							text = "TTSChunk",
							type = "TEXT",
						}, 
					}, 
					duration = 3000,
					softButtons = 
					{ 
						
						{ 
							type = "IMAGE",
							 image = 
				
							{ 
								value = "icon.png",
							}, 
							softButtonID = 1141,
							systemAction = "STEAL_FOCUS",
						}, 
					}, 
				
				}) 
			 

				--mobile side: Alert response
				EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


			end

		--Begin Test case CommonRequestCheck.3.8

		--Begin Test case CommonRequestCheck
		--Description: SoftButtons: type = TEXT; without text and with image (INVALID_DATA) 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

			--Verification criteria:
				--Mobile app sends any-relevant-RPC with SoftButtons withType=TEXT that exclude 'Text' parameter, SDL must reject it with INVALID_DATA result code and not transfer to HMI.

			function Test:Alert_SoftButtonsTEXTWithoutText() 

			 --mobile side: Alert request 	
			local CorIdAlert = self.mobileSession:SendRPC("Alert",
			{
			  	 
				alertText1 = "alertText1",
				ttsChunks = 
				{ 
					
					{ 
						text = "TTSChunk",
						type = "TEXT",
					}, 
				}, 
				duration = 3000,
				softButtons = 
				{ 
					
					{ 
						type = "TEXT",
						 image = 
			
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						isHighlighted = true,
						softButtonID = 1081,
						systemAction = "KEEP_CONTEXT",
					}, 
				}, 
			
			}) 
		 

			--mobile side: Alert response
			EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


		end

		--End Test case CommonRequestCheck


	--End Test case CommonRequestCheck.3


	--Begin Test case CommonRequestCheck.4
	--Description: Check processing request with different fake parameters

		--Requirement id in JAMA/or Jira ID: APPLINK-4518

		--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

		--Begin Test case CommonRequestCheck4.1
		--Description: With fake parameters (ABORTED because of SoftButtons presence) 

			function Test:Alert_FakeParams() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	alertText1 = "alertText1",
																	alertText2 = "alertText2",
																	alertText3 = "alertText3",
																	fakeParam = "fakeParam",
																	ttsChunks = 
																	{ 
																		
																		{ 
																			text = "TTSChunk",
																			type = "TEXT",
																			fakeParam = "fakeParam",
																		}, 
																	}, 
																	duration = 3000,
																	playTone = true,
																	softButtons = 
																	{ 
																		
																		{ 
																			fakeParam = "fakeParam",
																			type = "BOTH",
																			text = "Close",
																			 image = 
																
																			{ 
																				value = "icon.png",
																				imageType = "DYNAMIC",
																			}, 
																			isHighlighted = true,
																			softButtonID = 3,
																			systemAction = "DEFAULT_ACTION",
																		}, 
																	}
																
																}) 
			 
				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = 
									{
										{fieldName = "alertText1", fieldText = "alertText1"},
								        {fieldName = "alertText2", fieldText = "alertText2"},
								        {fieldName = "alertText3", fieldText = "alertText3"}
								    },
									duration = 0,
									softButtons = 
									{ 
										
										{ 
											type = "BOTH",
											text = "Close",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
												imageType = "DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 3,
											systemAction = "DEFAULT_ACTION",
										}, 
									}
								})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)
					:ValidIf(function(_,data)
						if 
							data.params.fakeParam or
							data.params.softButtons[1].fakeParam then
								print(" SDL re-sends fakeParam parameters to HMI in UI.Alert request")
								return false
						else 
							return true
						end
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
								{	
									ttsChunks = 
									{ 
										
										{ 
											text = "TTSChunk",
											type = "TEXT",
										}
									},
									speakType = "ALERT",
									playTone = true
								})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks[1].fakeParam then
							print(" SDL re-sends fakeParam parameter to HMI in TTS.Speak request")
							return false
						else
							return true
						end
					end)
			 
				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end

		--End Test case CommonRequestCheck4.1

		--Begin Test case CommonRequestCheck.4.2
		--Description: Parameters from another request (INVALID_DATA)

			function Test:Alert_ParamsAnotherRequest() 

				 --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	initialText = "StartPerformInteraction",
																	interactionMode = "BOTH",
																	interactionChoiceSetIDList = 
																	{ 
																		100,
																		200,
																	}, 
																
																}) 
			 

				--mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	


			end

		--End Test case CommonRequestCheck4.2


	--End Test case CommonRequestCheck.4

	--Begin Test case CommonRequestCheck.5
	--Description: Check processing request with invalid JSON syntax 

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

		--Verification criteria:  The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

		function Test:Alert_InvalidJSON()

			  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

			  local msg = 
			  {
			    serviceType      = 7,
			    frameInfo        = 0,
			    rpcType          = 0,
			    rpcFunctionId    = 12,
			    rpcCorrelationId = self.mobileSession.correlationId,
			--<<!-- missing ':'
			    payload          = '{"softButtons":[{"softButtonID":3,"type":"BOTH","text":"Close","systemAction":"DEFAULT_ACTION","isHighlighted":true,"image":{"imageType":"DYNAMIC","value":"icon.png"}},{"softButtonID":4,"type":"TEXT","text":"Keep","systemAction":"KEEP_CONTEXT","isHighlighted":true},{"softButtonID":5,"type":"IMAGE","systemAction":"STEAL_FOCUS","image":{"imageType":"DYNAMIC","value":"icon.png"}}],"ttsChunks":{{"type":"TEXT","text":"TTSChunk"}},"progressIndicator":true,"playTone":true,"alertText2":"alertText2","alertText1":"alertText1","duration":3000,"alertText3" "alertText3"}'
			  }
			  self.mobileSession:Send(msg)
			  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
		end


	--End Test case CommonRequestCheck.5

	--Begin Test case CommonRequestCheck.6
	--Description: Check processing request with SoftButtons: type = TEXT; with and without image (ABORTED because of SoftButtons presence)

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

		--Verification criteria: 
			--Mobile app sends any-relevant-RPC with SoftButtons withType=TEXT and with valid or invalid or not-defined or omitted 'image'  parameter, SDL transfers the corresponding RPC to HMI omitting 'image' parameter, the resultCode returned to mobile app depends on resultCode from HMI`s response.

		function Test:Alert_SoftButtonsTEXTWithWithoutImage() 

			 --mobile side: Alert request 	
			local CorIdAlert = self.mobileSession:SendRPC("Alert",
			{
			  	 
				alertText1 = "alertText1",
				ttsChunks = 
				{ 
					
					{ 
						text = "TTSChunk",
						type = "TEXT",
					}, 
				}, 
				duration = 3000,
				softButtons = 
				{ 
		--<!-- with image parameter 
					
					{ 
						type = "TEXT",
						text = "withimage",
						image =
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						softButtonID = 1011,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- without image parameter 
					
					{ 
						type = "TEXT",
						text = "withoutimage",
						softButtonID = 1012,
						systemAction = "DEFAULT_ACTION",
					}, 
				}, 
			}) 
		 
			local AlertId
			--hmi side: UI.Alert request 
			EXPECT_HMICALL("UI.Alert", 
			{	
				duration = 0,
				softButtons = 
				{ 
		--<!-- with image parameter 
					
					{ 
						type = "TEXT",
						text = "withimage",
						softButtonID = 1011,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- without image parameter 
					
					{ 
						type = "TEXT",
						text = "withoutimage",
						softButtonID = 1012,
						systemAction = "DEFAULT_ACTION",
					}, 
				}
			})
			:Do(function(_,data)
				SendOnSystemContext(self,"ALERT")
				AlertId = data.id

				local function alertResponse()
					self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

					SendOnSystemContext(self,"MAIN")
				end

				RUN_AFTER(alertResponse, 3000)
			end)
			:ValidIf(function(_,data)

					if data.params.softButtons[1].image then
						print(" \27[36m UI.Alert request contains imge struct in first softButton \27[0m ")
						return false
					else
						return true
					end

				end)


			local SpeakId
			--hmi side: TTS.Speak request 
			EXPECT_HMICALL("TTS.Speak", 
			{	
				speakType = "ALERT"
			})
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
				end

				RUN_AFTER(speakResponse, 2000)

			end)
			:ValidIf(function(_,data)
				if #data.params.ttsChunks == 1 then
					return true
				else
					print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
					return false
				end
			end)
		 

			--mobile side: OnHMIStatus notifications
			ExpectOnHMIStatusWithAudioStateChanged(self)

		    --mobile side: Alert response
		    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
			
		end

	--End Test case CommonRequestCheck.6

	--Begin Test case CommonRequestCheck.7
	--Description: Check processing request with SoftButtons: type = IMAGE; with and without text, with and without isHighlighted parameter (ABORTED because of SoftButtons presence) 

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

		--Verification criteria: 
			--Mobile app sends any-relevant-RPC with SoftButtons withType=IMAGE and with valid or invalid or not-defined or omitted 'text'  parameter, SDL transfers the corresponding RPC to HMI omitting 'text' parameter, the resultCode returned to mobile app depends on resultCode from HMI`s response.

		function Test:Alert_IMAGEWithWithoutTextisHighlighted() 

			 --mobile side: Alert request 	
			local CorIdAlert = self.mobileSession:SendRPC("Alert",
			{
			  	 
				alertText1 = "alertText1",
				ttsChunks = 
				{ 
					
					{ 
						text = "TTSChunk",
						type = "TEXT",
					}, 
				}, 
				duration = 3000,
				softButtons = 
				{ 
		--<!-- without text and without isHighLighted 
					
					{ 
						type = "IMAGE",
						 image = 
			
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						softButtonID = 1111,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- without text and with isHighLighted = true 
					
					{ 
						type = "IMAGE",
						 image = 
			
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						isHighlighted = true,
						softButtonID = 1112,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- with text and without isHighLighted 
					
					{ 
						type = "IMAGE",
						text = "Close",
						 image = 
			
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						softButtonID = 1113,
						systemAction = "DEFAULT_ACTION",
					}, 
		--<!-- with text and with isHighLighted = false 
					
					{ 
						type = "IMAGE",
						text = "Close",
						 image = 
			
						{ 
							value = "icon.png",
							imageType = "DYNAMIC",
						}, 
						isHighlighted = false,
						softButtonID = 1114,
						systemAction = "DEFAULT_ACTION",
					}, 
				}, 
			
			}) 
		 
			local AlertId
			--hmi side: UI.Alert request 
			EXPECT_HMICALL("UI.Alert", 
			{	
				duration = 0,
				softButtons = 
				{ 
		--<!-- without text and without isHighLighted 
					
					{ 
						type = "IMAGE",
						  --[[ TODO: update after resolving APPLINK-16052

						 image = 
			
						{ 
							value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
							imageType = "DYNAMIC",
						},]] 
						softButtonID = 1111,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- without text and with isHighLighted = true 
					
					{ 
						type = "IMAGE",
						  --[[ TODO: update after resolving APPLINK-16052

						 image = 
			
						{ 
							value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
							imageType = "DYNAMIC",
						},]] 
						isHighlighted = true,
						softButtonID = 1112,
						systemAction = "KEEP_CONTEXT",
					}, 
		--<!-- with text and without isHighLighted 
					
					{ 
						type = "IMAGE",
						  --[[ TODO: update after resolving APPLINK-16052

						 image = 
			
						{ 
							value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
							imageType = "DYNAMIC",
						},]] 
						softButtonID = 1113,
						systemAction = "DEFAULT_ACTION",
					}, 
		--<!-- with text and with isHighLighted = false 
					
					{ 
						type = "IMAGE",
						  --[[ TODO: update after resolving APPLINK-16052

						 image = 
			
						{ 
							value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
							imageType = "DYNAMIC",
						},]] 
						isHighlighted = false,
						softButtonID = 1114,
						systemAction = "DEFAULT_ACTION",
					}, 
				}
			})
			:Do(function(_,data)
				SendOnSystemContext(self,"ALERT")
				AlertId = data.id

				local function alertResponse()
					self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

					SendOnSystemContext(self,"MAIN")
				end

				RUN_AFTER(alertResponse, 3000)
			end)

			local SpeakId
			--hmi side: TTS.Speak request 
			EXPECT_HMICALL("TTS.Speak", 
			{	
				speakType = "ALERT"
			})
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
				end

				RUN_AFTER(speakResponse, 2000)

			end)
		 

			--mobile side: OnHMIStatus notifications
		    ExpectOnHMIStatusWithAudioStateChanged(self)

		    --mobile side: Alert response
		    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })	

		end

	--End Test case CommonRequestCheck.7


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

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-49,
							-- SDLAQ-CRS-481
							-- SDLAQ-CRS-2923
							-- SDLAQ-CRS-2910

				--Verification criteria: 
							--Alert request notifies the user via TTS/UI or both with some information.
							--[[ app->SDL: Alert {with UI-related-params & with TTSChunks}
								SDL->HMI: UI.Alert
								SDL->HMI: TTS.Speak
								requested params are displayed on the Alert dialog
								requested text is heard from the HU speakers
								HMI->SDL: TTS.Speak{SUCCESS} - after HMI finishes speaking
								HMI->SDL: UI.ALert{SUCCESS} - after timeout for Alert without SoftButtons OR after DEFAULT_ACTION or STEAL_FOCUS Alert-button press for Alert with SoftButtons
								SDL->app: Alert{resultCode: SUCCESS, success:true}]]
							-- SDL must send BC.PlayTone with "methodName"=ALERT and appID params
							--In case the mobile application sends any RPC with 'text:""' (empty string) of 'ttsChunk' struct and other valid params, SDL must consider such RPC as valid and transfer it to HMI.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: alertText1, alertText2, alertText3 lower bound

					function Test:Alert_alertText123LowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																		  	 
																			alertText1 = "a",
																			alertText2 = "1",
																			alertText3 = "_",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "TTSChunk",
																					type = "TEXT"
																				}
																			}, 
																			duration = 6000
																		}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "a"},
										        {fieldName = "alertText2", fieldText = "1"},
										        {fieldName = "alertText3", fieldText = "_"}
										    },
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT"
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 2000)

							end)
					 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						
					end	

				--End Test case PositiveRequestCheck.1.1

				--Begin Test case PositiveRequestCheck.1.2
				--Description: ttsChunks: array lower bound = 1 TTSChunk 

					function Test:Alert_ttsChunksArrayLowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																		  	 
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "OneTTSChunk",
																					type = "TEXT",
																				}
																			}, 
																			duration = 6000,
																			playTone = true,
																		
																		}) 
					 	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											ttsChunks = 
											{ 
												{ 
													text = "OneTTSChunk",
													type = "TEXT"
												}
											},
											speakType = "ALERT",
											playTone = true
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 2000)

							end)
							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)
						 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						
					end

				--End Test case PositiveRequestCheck.1.2

				--Begin Test case PositiveRequestCheck.1.3
				--Description: duration: lower bound 

					function Test:Alert_durationLowerBound() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																		  	 
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "TTSChunk",
																					type = "TEXT",
																				}, 
																			}, 
																			duration = 3000
																		}) 

					 	local AlertId

						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
										{	
											duration = 3000
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 2500)
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT"
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

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.3

				--Begin Test case PositiveRequestCheck.1.4
				--Description: SoftButtons: array is empty (lower bound) 

					function Test:Alert_SoftButtonsArrayEmpty() 

						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					  local msg = 
					  {
					    serviceType      = 7,
					    frameInfo        = 0,
					    rpcType          = 0,
					    rpcFunctionId    = 12,
					    rpcCorrelationId = self.mobileSession.correlationId,
					    payload          = '{"softButtons":[],"duration":3000,"alertText3":"alertText3","alertText2":"alertText2","ttsChunks":[{"text":"TTSChunk","type":"TEXT"}],"alertText1":"alertText1"}'
					  }
					  self.mobileSession:Send(msg)

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 2000)
							end)
							:ValidIf(function(_,data)
								if data.params.softButtons then
									print ( " \27[36m UI.Alert request came with softButtons arrat \27[0m " )
									return false
								else
									return true
								end
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT"
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

					    --mobile side: Alert response
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })

					end					

				--End Test case PositiveRequestCheck.1.4

				--Begin Test case PositiveRequestCheck.1.5
				--Description: check that timeout from request is applicable in case  SoftButtons array is empty (lower bound)

				--TODO: test case need to be updated according to ansver for APPLINK-19926

					function Test:Alert_SoftButtonsArrayEmptyTimeoutApplicable() 

						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					  local msg = 
					  {
					    serviceType      = 7,
					    frameInfo        = 0,
					    rpcType          = 0,
					    rpcFunctionId    = 12,
					    rpcCorrelationId = self.mobileSession.correlationId,
					    payload          = '{"softButtons":[],"duration":3000,"alertText3":"alertText3","alertText2":"alertText2","ttsChunks":[{"text":"TTSChunk","type":"TEXT"}],"alertText1":"alertText1"}'
					  }
					  self.mobileSession:Send(msg)

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
							:Do(function(_,data)
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								end

								RUN_AFTER(alertResponse, 6000)
							end)
							:ValidIf(function(_,data)
								if data.params.softButtons then
									print ( " \27[36m UI.Alert request came with softButtons array \27[0m " )
									return false
								else
									return true
								end
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT"
										})
							:Do(function(_,data)
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
								end

								RUN_AFTER(speakResponse, 4000)

							end)
					 
					    --mobile side: Alert response
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })

					end					

				--End Test case PositiveRequestCheck.1.5

				--Begin Test case PositiveRequestCheck.1.6
				--Description: alertText1, alertText2, alertText3 upper bound 

					function Test:Alert_alertText123UpperBound() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "\\bnn\\fddhjhr567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab",
							alertText2 = "\\bnn\\f\\rtt/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab",
							alertText3 = "\\bnn\\f\\rtt/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = "\\bnn\\fddhjhr567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab"},
						        {fieldName = "alertText2", fieldText = "\\bnn\\f\\rtt/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab"},
						        {fieldName = "alertText3", fieldText = "\\bnn\\f\\rtt/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0ab"}
						    },
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
					 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
					end

				--End Test case PositiveRequestCheck.1.6

				--Begin Test case PositiveRequestCheck.1.7
				--Description: array upper bound = 100 TTSChunks 

					function Test:Alert_ttsChunksArrayUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{ 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "1TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "2TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "3TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "4TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "5TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "6TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "7TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "8TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "9TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "10TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "11TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "12TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "13TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "14TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "15TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "16TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "17TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "18TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "19TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "20TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "21TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "22TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "23TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "24TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "25TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "26TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "27TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "28TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "29TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "30TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "31TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "32TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "33TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "34TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "35TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "36TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "37TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "38TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "39TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "40TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "41TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "42TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "43TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "44TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "45TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "46TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "47TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "48TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "49TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "50TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "51TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "52TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "53TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "54TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "55TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "56TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "57TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "58TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "59TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "60TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "61TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "62TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "63TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "64TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "65TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "66TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "67TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "68TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "69TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "70TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "71TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "72TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "73TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "74TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "75TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "76TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "77TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "78TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "79TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "80TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "81TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "82TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "83TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "84TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "85TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "86TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "87TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "88TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "89TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "90TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "91TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "92TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "93TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "94TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "95TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "96TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "97TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "98TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "99TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "100TTSChunk",
									type = "TEXT",
								}
							}, 
							duration = 6000,
							playTone = true
						}) 


						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							ttsChunks = 
							{ 
								{ 
									text = "1TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "2TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "3TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "4TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "5TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "6TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "7TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "8TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "9TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "10TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "11TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "12TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "13TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "14TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "15TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "16TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "17TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "18TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "19TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "20TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "21TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "22TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "23TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "24TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "25TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "26TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "27TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "28TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "29TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "30TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "31TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "32TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "33TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "34TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "35TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "36TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "37TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "38TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "39TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "40TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "41TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "42TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "43TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "44TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "45TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "46TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "47TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "48TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "49TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "50TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "51TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "52TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "53TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "54TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "55TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "56TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "57TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "58TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "59TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "60TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "61TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "62TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "63TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "64TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "65TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "66TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "67TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "68TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "69TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "70TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "71TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "72TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "73TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "74TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "75TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "76TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "77TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "78TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "79TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "80TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "81TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "82TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "83TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "84TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "85TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "86TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "87TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "88TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "89TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "90TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "91TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "92TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "93TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "94TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "95TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "96TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "97TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "98TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "99TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "100TTSChunk",
									type = "TEXT",
								}, 
							}, 
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 100 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 100, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.7

				--Begin Test case PositiveRequestCheck.1.8
				--Description: duration: upper bound 

					function Test:Alert_durationUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 10000,
						
						}) 

					  	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 10000
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 9000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

				end

				--End Test case PositiveRequestCheck.1.8

				--Begin Test case PositiveRequestCheck.1.9
				--Description: SoftButtons: array upper bound = 4 Buttons (ABORTED because of SoftButtons presence)

					function Test:Alert_SoftButtonsArrayUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT"
								}
							}, 
							duration = 3000,
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
								
								{ 
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 823,
									systemAction = "KEEP_CONTEXT",
								}, 
								
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
							}
						
						}) 
					 
					local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "Close",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
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
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
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
								}, 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 824,
									systemAction = "STEAL_FOCUS",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 10000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
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
						ExpectOnHMIStatusWithAudioStateChanged(self,_,12000)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					    :Timeout(12000)
					end

				--End Test case PositiveRequestCheck.1.9

				--Begin Test case PositiveRequestCheck.1.10
				--Description: ttsChunks: text lower and upper bound 

					function Test:Alert_ttsChunksTextLowerUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3",
												ttsChunks = 
												{ 
													
													{ 
														text = "",
														type = "TEXT",
													}, 
													
													{ 
														text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
														type = "TEXT",
													}, 
												}, 
												duration = 6000,
											
											}) 
					 	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
										{ 
											
											{ 
												text = "",
												type = "TEXT",
											}, 
											
											{ 
												text = "\bmm\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
												type = "TEXT",
											}, 
										},
										speakType = "ALERT"
									})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function speakResponse()
									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end

								RUN_AFTER(speakResponse, 2000)

							end)
							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 2 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 2, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)
					 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
					end

				--End Test case PositiveRequestCheck.1.10

				--Begin Test case PositiveRequestCheck.1.11
				--Description: SoftButtons: softButtonID lower and upper bound (ABORTED because of SoftButtons presence)

					function Test:Alert_SoftButtonsIDLowerUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = 0,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "Close",
									isHighlighted = true,
									softButtonID = 65535,
									systemAction = "KEEP_CONTEXT",
								}, 
							}, 
						
						}) 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "Close",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 0,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "Close",
									isHighlighted = true,
									softButtonID = 65535,
									systemAction = "KEEP_CONTEXT",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 9000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					
				end

				--End Test case PositiveRequestCheck.1.11

				--Begin Test case PositiveRequestCheck.1.12
				--Description: SoftButtons: type = TEXT; text lower and upper bound (ABORTED because of SoftButtons presence) 

					function Test:Alert_SoftButtonsTEXTTextLowerUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
					--<!-- text lower bound 
								
								{ 
									type = "TEXT",
									text = "a",
									softButtonID = 1032,
									systemAction = "KEEP_CONTEXT",
								}, 
					--<!-- text upper bound 
								
								{ 
									type = "TEXT",
									text = "\bnn\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
									softButtonID = 1033,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
					--<!-- text lower bound 
								
								{ 
									type = "TEXT",
									text = "a",
									softButtonID = 1032,
									systemAction = "KEEP_CONTEXT",
								}, 
					--<!-- text upper bound 
								
								{ 
									type = "TEXT",
									text = "\bnn\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0",
									softButtonID = 1033,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 2000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
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

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })

					end

				--End Test case PositiveRequestCheck.1.12

				--Begin Test case PositiveRequestCheck.1.13
				--Description: SoftButtons: type = IMAGE; image value lower and upper bound (ABORTED because of SoftButtons presence) 

					function Test:Alert_IMAGEValueLowerUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
					--<!-- image value lower bound 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "a",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 1124,
									systemAction = "DEFAULT_ACTION",
								}, 
					--<!-- image value upper bound 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 1125,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{
							duration = 0,
							softButtons = 
							{ 
					--<!-- image value lower bound 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/a",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 1124,
									systemAction = "DEFAULT_ACTION",
								}, 
					--<!-- image value upper bound 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 1125,
									systemAction = "DEFAULT_ACTION",
								}, 
							}	
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })

					end

				--End Test case PositiveRequestCheck.1.13

				--Begin Test case PositiveRequestCheck.1.14
				--Description: Alert: lower bound of all parameters (ABORTED because of SoftButtons presence)

					function Test:Alert_LowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "a",
							alertText2 = "b",
							alertText3 = "c",
							ttsChunks = 
							{ 
								
								{ 
									text = "T",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "C",
									 image = 
						
									{ 
										value = "a",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 0,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "K",
									isHighlighted = true,
									softButtonID = 1,
									systemAction = "KEEP_CONTEXT",
								}, 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "a",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 2,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = "a"},
						        {fieldName = "alertText2", fieldText = "b"},
						        {fieldName = "alertText3", fieldText = "c"}
						    },
						    duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "C",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/a",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 0,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "K",
									isHighlighted = true,
									softButtonID = 1,
									systemAction = "KEEP_CONTEXT",
								}, 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/a",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 2,
									systemAction = "STEAL_FOCUS",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							ttsChunks = 
							{ 
								
								{ 
									text = "T",
									type = "TEXT",
								}, 
							},
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					end

				--End Test case PositiveRequestCheck.1.14

				--Begin Test case PositiveRequestCheck.1.15
				--Description: Alert: upper bound of all parameters (ABORTED because of SoftButtons presence)

					function Test:Alert_UpperBound() 

						--mobile side: Alert request 
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{ 
							alertText1 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
							alertText2 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
							alertText3 = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
							ttsChunks = 
							{ 
								
								{ 
									text = "1ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "2ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "3ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "4ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "5ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "6ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "7ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "8ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "9ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "10tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "11tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "12tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "13tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "14tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "15tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "16tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "17tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "18tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "19tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "20tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "21tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "22tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "23tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "24tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "25tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "26tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "27tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "28tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "29tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "30tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "31tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "32tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "33tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "34tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "35tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "36tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "37tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "38tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "39tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "40tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "41tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "42tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "43tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "44tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "45tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "46tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "47tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "48tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "49tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "50tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "51tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "52tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "53tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "54tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "55tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "56tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "57tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "58tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "59tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "60tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "61tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "62tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "63tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "64tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "65tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "66tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "67tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "68tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "69tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "70tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "71tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "72tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "73tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "74tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "75tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "76tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "77tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "78tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "79tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "80tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "81tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "82tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "83tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "84tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "85tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "86tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "87tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "88tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "89tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "90tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "91tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "92tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "93tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "94tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "95tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "96tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "97tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "98tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "99tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "100ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
							}, 
							duration = 10000,
							playTone = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
									 image = 
						
									{ 
										value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 65532,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
									isHighlighted = true,
									softButtonID = 65533,
									systemAction = "KEEP_CONTEXT",
								}, 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 65534,
									systemAction = "STEAL_FOCUS",
								}, 
								
								{ 
									type = "BOTH",
									text = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
									 image = 
						
									{ 
										value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 65535,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						} 
						) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
						        {fieldName = "alertText2", fieldText = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},
						        {fieldName = "alertText3", fieldText = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}
						    },	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 65532,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
									isHighlighted = true,
									softButtonID = 65533,
									systemAction = "KEEP_CONTEXT",
								}, 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 65534,
									systemAction = "STEAL_FOCUS",
								}, 
								
								{ 
									type = "BOTH",
									text = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 65535,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							ttsChunks = 
							{ 
								
								{ 
									text = "1ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "2ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "3ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "4ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "5ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "6ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "7ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "8ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "9ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "10tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "11tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "12tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "13tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "14tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "15tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "16tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "17tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "18tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "19tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "20tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "21tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "22tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "23tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "24tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "25tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "26tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "27tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "28tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "29tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "30tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "31tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "32tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "33tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "34tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "35tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "36tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "37tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "38tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "39tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "40tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "41tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "42tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "43tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "44tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "45tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "46tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "47tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "48tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "49tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "50tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "51tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "52tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "53tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "54tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "55tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "56tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "57tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "58tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "59tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "60tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "61tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "62tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "63tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "64tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "65tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "66tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "67tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "68tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "69tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "70tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "71tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "72tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "73tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "74tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "75tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "76tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "77tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "78tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "79tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "80tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "81tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "82tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "83tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "84tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "85tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "86tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "87tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "88tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "89tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "90tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "91tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "92tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "93tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "94tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "95tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "96tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "97tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "98tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "99tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
								
								{ 
									text = "100ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
									type = "TEXT",
								}, 
							},
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 100 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 100, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
						
						
					end

				--End Test case PositiveRequestCheck.1.15

				--Begin Test case PositiveRequestCheck.1.16
				--Description: ttsChunks: available values of type

					local ttsChunksType = {{text = "4025",type = "PRE_RECORDED"},{ text = "Sapi",type = "SAPI_PHONEMES"}, {text = "LHplus", type = "LHPLUS_PHONEMES"}, {text = "Silence", type = "SILENCE"}, {text = "File.m4a", type = "FILE"}}
					for i=1,#ttsChunksType do
						Test["Alert_ttsChunksType" .. tostring(ttsChunksType[i].type)] = function(self)
							--mobile side: Alert request 	
							local CorIdAlert = self.mobileSession:SendRPC("Alert",
							{
							  	 
								alertText1 = "alertText1",
								alertText2 = "alertText2",
								alertText3 = "alertText3",
								ttsChunks = 
								{ 
									
									{ 
										text = ttsChunksType[i].text,
										type = ttsChunksType[i].type
									}, 
								}, 
								duration = 6000,
							}) 

							local AlertId
							--hmi side: UI.Alert request 
							EXPECT_HMICALL("UI.Alert", 
							{	
							})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 5000)
							end)

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
								speakType = "ALERT"
							})
							:Do(function(_,data)
								SpeakId = data.id

								self.hmiConnection:SendError(SpeakId, "TTS.Speak", "UNSUPPORTED_RESOURCE", "ttsChunks type is unsupported")

							end)
							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)
						 

							--mobile side: OnHMIStatus notifications
							ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

						    --mobile side: Alert response
						    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS" })

						end
					end

				--End Test case PositiveRequestCheck.1.16

				--Begin Test case PositiveRequestCheck.1.17
				--Description: playTone: is false 

					function Test:Alert_playTonefalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = false,
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = false
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone")
						-- :Times(0)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.17

				--Begin Test case PositiveRequestCheck.1.18
				--Description: playTone: is True 

					function Test:Alert_playToneTrue() 

						--mobile side: Alert request 	
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 12,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"playTone":True,"alertText2":"alertText2","alertText1":"alertText1","duration":3000,"alertText3":"alertText3"}'
						}

						self.mobileSession:Send(msg)

						--hmi side: UI.Alert
					  	EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									duration = 3000
								})
						:Do(function(_,data)
							local function alertResponse()
								self.hmiConnection:SendResponse(data.id, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 2000)
						end)

						EXPECT_HMICALL("TTS.Speak", {playTone = true})

						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT" , appID = self.applications["Test Application"]})

						--mobile side:Alert response
					  	self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.18

				--Begin Test case PositiveRequestCheck.1.19
				--Description: playTone: is true

					function Test:Alert_playTonetrue() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT", appID = self.applications["Test Application"]})
						-- :Times(1)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.19

				--Begin Test case PositiveRequestCheck.1.20
				--Description: progressIndicator: is true 

					function Test:Alert_progressIndicatortrue() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = false,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type ="BOTH",
									text ="Close",
									 image = 
						
									{ 
										value = "icon.png",
										imageType ="DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 1,
									systemAction ="DEFAULT_ACTION",
								}
							}

						
						})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type ="BOTH",
									text ="Close",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType ="DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 1,
									systemAction ="DEFAULT_ACTION",
								}
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)


						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.20

				--Begin Test case PositiveRequestCheck.1.21
				--Description: progressIndicator: is True

					function Test:Alert_progressIndicatorTue() 

						--mobile side: Alert request 	
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 12,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"progressIndicator":True,"alertText2":"alertText2","alertText1":"alertText1","duration":5000,"alertText3":"alertText3"}'
						}

						self.mobileSession:Send(msg)

						--hmi side: UI.Alert
					  	EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									duration = 5000,
									progressIndicator = true
								})
						:Do(function(_,data)
							local function alertResponse()
								self.hmiConnection:SendResponse(data.id, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 4000)
						end)


						--mobile side:Alert response
					  	self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
						
					end

				--End Test case PositiveRequestCheck.1.21

				--Begin Test case PositiveRequestCheck.1.22
				--Description: progressIndicator: is false 

					function Test:Alert_progressIndicatorfalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = false,
							progressIndicator = false,
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							progressIndicator = false
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)


						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.22

				--Begin Test case PositiveRequestCheck.1.23
				--Description: SoftButtons: all types and all SystemActions of SoftButton in one array (ABORTED because of SoftButtons presence) 
					function Test:Alert_SoftButtonsAllTypesAllSystemActions() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							softButtons = 
							{ 
					--<!-- BOTH and DEFAULT_ACTION 
								
								{ 
									type = "BOTH",
									text = "Close",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 871,
									systemAction = "DEFAULT_ACTION",
								}, 
					--<!-- TEXT and KEEP_CONTEXT 
								
								{ 
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 872,
									systemAction = "KEEP_CONTEXT",
								}, 
					--<!-- IMAGE and STEAL_FOCUS 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 873,
									systemAction = "STEAL_FOCUS",
								}, 
							} 
						}) 

					 	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							softButtons = 
							{ 
					--<!-- BOTH and DEFAULT_ACTION 
								
								{ 
									type = "BOTH",
									text = "Close",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 871,
									systemAction = "DEFAULT_ACTION",
								}, 
					--<!-- TEXT and KEEP_CONTEXT 
								
								{ 
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 872,
									systemAction = "KEEP_CONTEXT",
								}, 
					--<!-- IMAGE and STEAL_FOCUS 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 873,
									systemAction = "STEAL_FOCUS",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 10000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self,_,12000)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					    :Timeout(12000)
						
					end
				--End Test case PositiveRequestCheck.1.23

				--Begin Test case PositiveRequestCheck.1.24
				--Description: duration: default value = 5000

					function Test:Alert_durationDefaultValue() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							},
							default = 5000
						
						}) 

					  	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 5000
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 4000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.24

				--Begin Test case PositiveRequestCheck.1.25
				--Description: alertText1, alertText2, alertText3 with spaces before, after and in the middle 

					function Test:Alert_alertText123Spaces() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = " alertText1 with spaces ",
							alertText2 = " alertText2 with spaces ",
							alertText3 = " alertText3 withs paces ",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 	local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = " alertText1 with spaces "},
						        {fieldName = "alertText2", fieldText = " alertText2 with spaces "},
						        {fieldName = "alertText3", fieldText = " alertText3 withs paces "}
						    },
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
					 

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						
					end

				--End Test case PositiveRequestCheck.1.25


				--Begin Test case PositiveRequestCheck.1.26
				--Description:  SoftButtons: type = TEXT; text with spaces before, after and in the middle (ABORTED because of SoftButtons presence) 

					function Test:Alert_SoftButtonsTEXTTextSpaces() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												ttsChunks = 
												{ 
													
													{ 
														text = "TTSChunk",
														type = "TEXT",
													}, 
												}, 
												duration = 3000,
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
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										duration = 0,
										softButtons = 
										{ 
											
											{ 
												type = "TEXT",
												text = " spaces before, after and in the middle ",
												softButtonID = 1041,
												systemAction = "DEFAULT_ACTION",
											}, 
										}
									})
									:Do(function(_,data)
										SendOnSystemContext(self,"ALERT")
										AlertId = data.id

										local function alertResponse()
											self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

											SendOnSystemContext(self,"MAIN")
										end

										RUN_AFTER(alertResponse, 2000)
									end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
									{	
										speakType = "ALERT"
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

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					end

				--End Test case PositiveRequestCheck.1.26

				--Begin Test case PositiveRequestCheck.1.27
				--Description: oftButtons: type = TEXT; isHighlighted = true/TRUE and isHighlighted = false/False (ABORTED because of SoftButtons presence)

					function Test:Alert_SoftButtonsTEXTisHighlighted() 

						--mobile side: Alert request 	
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 12,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"softButtons":[{"softButtonID":1051,"type":"TEXT","text":"isHighlighted-true","systemAction":"KEEP_CONTEXT","isHighlighted":true},{"softButtonID":1052,"type":"TEXT","text":"isHighlighted-false","systemAction":"DEFAULT_ACTION","isHighlighted":false},{"softButtonID":1053,"type":"TEXT","text":"isHighlighted-False","systemAction":"STEAL_FOCUS","isHighlighted":False}],"progressIndicator":False,"alertText2":"alertText2","alertText1":"alertText1","duration":5000,"alertText3":"alertText3"}'
						}

						self.mobileSession:Send(msg)

						--hmi side: UI.Alert
					  	EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									duration = 0,
									softButtons = 
									{ 
							--<!-- isHighlighted - true 
										{ 
											type = "TEXT",
											text = "isHighlighted-true",
											isHighlighted = true,
											softButtonID = 1051,
											systemAction = "KEEP_CONTEXT",
										},  
							--<!-- isHighlighted - false 
										{ 
											type = "TEXT",
											text = "isHighlighted-false",
											isHighlighted = false,
											softButtonID = 1052,
											systemAction = "DEFAULT_ACTION",
										}, 
							--<!-- isHighlighted - False 
										{ 
											type = "TEXT",
											text = "isHighlighted-False",
											isHighlighted = false,
											softButtonID = 1053,
											systemAction = "STEAL_FOCUS",
										}
									}
								})
						:Do(function(_,data)
							local function alertResponse()
								self.hmiConnection:SendResponse(data.id, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 4000)
						end)


						--mobile side:Alert response
					  	self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
						
					end

				--End Test case PositiveRequestCheck.1.27

				--Begin Test case PositiveRequestCheck.1.28
				--Description: SoftButtons: type = IMAGE; image type is STATIC  

					function Test:Alert_SoftButtonsIMAGETypeStatic() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "ImagetypeSTATIC,PRESSSoftButtontohaveUNSUPPORTED_RESOURCEresultCode!!!",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									}, 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									--[[ TODO: update after resolving APPLINK-16052
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									},]] 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

				--End Test case PositiveRequestCheck.1.28


			--End Test case PositiveRequestCheck.1

			--Begin Test case PositiveRequestCheck.2
			--Description: Check duration default value 5000 seconds in case of absence parameter in request

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-49, SDLAQ-CRS-3048

				--Verification criteria: 
					-- Alert request notifies the user via TTS/UI or both with some information.
					-- SDL must omit the ‘duration’ parameter within UI.Alert to HMI in case it is absent in corresponding Alert request from mobile app

				function Test:Alert_durationDefaultValueMissing() 

					--mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
					
					}) 
				 
					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
					{	
						duration = 5000
					})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 4000)
					end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
					{	
						speakType = "ALERT"
					})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)

					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
					
				end


			--End Test case PositiveRequestCheck.2

			--Begin Test case PositiveRequestCheck.3
			--Description: Check default systemAction value is case of systemAction absence 

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-917

				--Verification criteria: SystemAction is set to "DEFAULT_ACTION" value if SystemAction parameter isn't provided in a request.

				function Test:Alert_SoftButtonsSystemActionMissing() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 3000,
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
								softButtonID = 8151,
							}, 
						}, 
					
					}) 
				 
					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
					{
						duration = 3000,
						softButtons = 
						{ 
							
							{ 
								type = "BOTH",
								text = "Close",
								  --[[ TODO: update after resolving APPLINK-16052

								 image = 
					
								{ 
									value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
									imageType = "DYNAMIC",
								},]] 
								isHighlighted = false,
								softButtonID = 8151,
								systemAction = "DEFAULT_ACTION"
							}, 
						},
						duration = 0	
					})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 2000)
					end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
					{	
						speakType = "ALERT"
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

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })

				end

			--End Test case PositiveRequestCheck.3


		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description:

				--Requirement id in JAMA: SDLAQ-CRS-50

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

				--Begin Test case PositiveResponseCheck.1.1
				--Description: tryAgainTime lower bound

					function Test:Alert_tryAgainTimeLowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {tryAgainTime = 0})

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS", tryAgainTime = 0})
					
					end
				--End Test case PositiveResponseCheck.1.1

				--Begin Test case PositiveResponseCheck.1.2
				--Description: tryAgainTime upper bound

					function Test:Alert_tryAgainTimeUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {tryAgainTime = 2000000000})

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS", tryAgainTime = 2000000000})
					
					end
				--End Test case PositiveResponseCheck.1.2

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
			--Description: Check processing requests with out of lower and upper bound values 

				--Requirement id in JAMA: SDLAQ-CRS-482
					-- SDLAQ-CRS-2910

				--Verification criteria:
					--[[- The request with "alertText1" value out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "alertText2" value out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "alertText3" value out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "ttsChunks" value out of bounds is sent, the response comes with INVALID_DATA result code.
					-. The request with "duration" value out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "timeout" value out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "softButtons" array out of bounds is sent, the response comes with INVALID_DATA result code.
					-  The request with "ttsChunks" array out of bounds is sent, the response comes with INVALID_DATA result code.
					-  The request with "ttsChunks" text parameter out of bounds is sent, the response comes with INVALID_DATA result code.
					- The request with "ttsChunks" type parameter out of enums is sent, the response comes with INVALID_DATA result code.
					-  The request with "softButtonID" parameter of SoftButtons out of bounds is sent, the response comes with INVALID_DATA result code.
					-  The request with "text" parameter of SoftButtons out of bounds is sent, the response comes with INVALID_DATA result code.]]
					--[[ In case the mobile application sends any RPC with 'text:"  "' (whitespace(s)) of 'ttsChunk' struct and other valid params, SDL must consider such RPC as invalid , not transfer it to HMI and respond with INVALID_DATA result code + success:false]]

				--Begin Test case NegativeRequestCheck.1.1
				--Description: alertText1 is empty (out lower bound) 

					function Test:Alert_alertText1Empty() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	


					end

				--End Test case NegativeRequestCheck1.1

				--Begin Test case NegativeRequestCheck.1.2
				--Description: alertText2 is empty (out lower bound) 

					function Test:Alert_alertText2Empty() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

					end

				--End Test case NegativeRequestCheck.1.2

				--Begin Test case NegativeRequestCheck.1.3
				--Description: alertText3 is empty (out lower bound) 

					function Test:Alert_alertText3Empty() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	


					end

				--End Test case NegativeRequestCheck.1.3

				--Begin Test case NegativeRequestCheck.1.4
				--Description: alertText1 out upper bound 

					function Test:Alert_alertText1OutUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "ann\\b\\f\\rtt//'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890aa",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.1.4

				--Begin Test case NegativeRequestCheck.1.5
				--Description: alertText2 out upper bound 

					function Test:Alert_alertText2OutUpperBound() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "ann\\b\\f\\rtt//'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890aa",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

					end

				--End Test case NegativeRequestCheck.1.5

				--Begin Test case NegativeRequestCheck.1.6
				--Description: alertText3 out upper bound 

					function Test:Alert_alertText3OutUpperBound() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "ann\\b\\f\\rtt//'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890aa",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.1.6

				--Begin Test case NegativeRequestCheck.1.7
				--Description: ttsChunks: array empty (out lower bound) 

					function Test:Alert_ttsChunksArrayEmpty() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
							}, 
							duration = 6000,
							playTone = true

						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


				end

				--End Test case NegativeRequestCheck.1.7

				--Begin Test case NegativeRequestCheck.1.8
				--Description: ttsChunks: array out upper bound = 101 TTSChunks 

					function Test:Alert_ttsChunksArrayOutUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{ 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "1TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "2TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "3TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "4TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "5TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "6TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "7TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "8TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "9TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "10TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "11TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "12TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "13TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "14TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "15TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "16TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "17TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "18TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "19TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "20TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "21TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "22TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "23TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "24TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "25TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "26TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "27TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "28TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "29TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "30TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "31TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "32TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "33TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "34TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "35TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "36TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "37TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "38TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "39TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "40TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "41TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "42TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "43TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "44TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "45TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "46TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "47TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "48TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "49TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "50TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "51TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "52TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "53TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "54TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "55TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "56TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "57TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "58TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "59TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "60TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "61TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "62TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "63TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "64TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "65TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "66TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "67TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "68TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "69TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "70TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "71TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "72TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "73TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "74TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "75TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "76TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "77TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "78TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "79TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "80TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "81TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "82TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "83TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "84TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "85TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "86TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "87TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "88TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "89TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "90TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "91TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "92TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "93TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "94TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "95TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "96TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "97TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "98TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "99TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "100TTSChunk",
									type = "TEXT",
								}, 
								
								{ 
									text = "101TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
						} 
						) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.1.8

				--Begin Test case NegativeRequestCheck.1.9
				--Description: ttsChunks: text is empty (out lower bound) 

					function Test:Alert_ttsChunksTextEmpty() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = " ",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		

					end

				--End Test case NegativeRequestCheck.1.9

				--Begin Test case NegativeRequestCheck.1.10
				--Description: duration: out lower bound 

					function Test:Alert_durationOutLowerBound() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 2999,
					
					}) 
				 

					--mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

				end

				--End Test case NegativeRequestCheck.1.10

				--Begin Test case NegativeRequestCheck.1.11
				--Description: duration: out upper bound 

					function Test:Alert_durationOutUpperBound() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 10001,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.1.11

				--Begin Test case NegativeRequestCheck.1.12
				--Description:SoftButtons: array out upper bound = 5 Buttons  

					function Test:Alert_SoftButtonsArrayOutUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = 831,
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
									softButtonID = 832,
									systemAction = "DEFAULT_ACTION",
								}, 
								
								{ 
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 833,
									systemAction = "KEEP_CONTEXT",
								}, 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 834,
									systemAction = "STEAL_FOCUS",
								}, 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 835,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

					end

				--End Test case NegativeRequestCheck.1.12

				--Begin Test case NegativeRequestCheck.1.13
				--Description: SoftButtons: softButtonID out lower bound 

					function Test:Alert_SoftButtonsIDOutLowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = -1,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.1.13

				--Begin Test case NegativeRequestCheck.1.14
				--Description: SoftButtons: softButtonID out upper bound 

					function Test:Alert_SoftButtonsIDOutUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 65536,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


				end


				--End Test case NegativeRequestCheck.1.14

				--Begin Test case NegativeRequestCheck.1.15
				--Description: SoftButtons: type = TEXT; text out upper bound 

					function Test:Alert_SoftButtonsTEXTTextOutUpperBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												ttsChunks = 
												{ 
													
													{ 
														text = "TTSChunk",
														type = "TEXT",
													}, 
												}, 
												duration = 3000,
												softButtons = 
												{ 
													
													{ 
														type = "TEXT",
														text = "01234567890123456789ann\b\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,012",
														softButtonID = 1031,
														systemAction = "DEFAULT_ACTION",
													}, 
												}, 
											
											}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end
				
			--End Test case NegativeRequestCheck.1

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

				--Verification criteria: 
					--[[- The request with empty "alertText1" value is sent,  the response with INVALID_DATA code is returned. 
					- The request with empty "alertText2" is sent, the response with INVALID_DATA code is returned. 
					- The request with empty "alertText3" is sent, the response with INVALID_DATA code is returned.
					- The request with empty "ttsChunks" value is sent, the response with INVALID_DATA code is returned. 
					- The request with empty "duration" is sent, the response with INVALID_DATA code is returned. 
					- The request with empty "playTone" is sent, the response with INVALID_DATA code is returned. 
					- The request with empty "text" parameter of SoftButtons is sent, the response with INVALID_DATA code is returned.
					- The request with empty "type" parameter of SoftButtons is sent, the response with INVALID_DATA code is returned.
					-  The request with empty "image" parameter of SoftButtons is sent, the response with INVALID_DATA code is returned.
					- The request with empty "softButtonID" parameter of SoftButtons is sent, the response with INVALID_DATA code is returned.
					- The request with empty "softButton" array is sent, the response with INVALID_DATA code is returned.]]

				--Begin Test case NegativeRequestCheck.2.1
				--Description: ttsChunks: empty TTSChunk 

					function Test:Alert_ttsChunksEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
								}
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	 	


					end

				--End Test case NegativeRequestCheck.2.1

				--Begin Test case NegativeRequestCheck.2.2
				--Description: ttsChunks: type is empty 

					function Test:Alert_ttsChunksTypeEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "EmptyType",
									type = "",
								}, 
							}, 
							duration = 6000
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

					end

				--End Test case NegativeRequestCheck.2.2

				--Begin Test case NegativeRequestCheck.2.3
				--Description: SoftButtons: type of SoftButton is empty 

					function Test:Alert_SoftButtonsTypeEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "",
									text = "Close",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 851,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

				--End Test case NegativeRequestCheck.2.3

				--Begin Test case NegativeRequestCheck.2.4
				--Description: SoftButtons: systemAction is empty 

					function Test:Alert_SoftButtonsSystemActionEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = 8161,
									systemAction = "",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.2.4

				--Begin Test case NegativeRequestCheck.2.5
				--Description: SoftButtons: type = BOTH, text is empty (ABORTED because of SoftButtons presence) 
					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

					--Verification criteria: Mobile app sends any-relevant-RPC with SoftButtons that include Text=“” (that is, empty string) and Type=BOTH, SDL transfers to HMI, the resultCode returned to mobile app depends on resultCode from HMI`s response.

					--bug APPLINK 9168

					function Test:Alert_SoftButtonsBOTHEmptyText() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
					--<!-- text is empty 
								
								{ 
									type = "BOTH",
									text = "",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 931,
									systemAction = "KEEP_CONTEXT",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{
							duration = 0,
							softButtons = 
							{ 
					--<!-- text is empty 
								
								{ 
									type = "BOTH",
									text = "",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value =  config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									softButtonID = 931,
									systemAction = "KEEP_CONTEXT",
								}, 
							}	
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 5000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
					end

				--End Test case NegativeRequestCheck.2.5

				--Begin Test case NegativeRequestCheck.2.6
				--Description: SoftButtons: type = BOTH, image is empty (INVALID_DATA)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

					--Verification criteria: Mobile app sends any-relevant-RPC with SoftButtons withType=BOTH and with one of the parameters ('text' and 'image') wrong or not defined, SDL returns INVALID_DATA result code and does not transfer to HMI.

					function Test:Alert_SoftButtonsBOTHEmptyImage() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
					--<!-- image value is empty 
								
								{ 
									type = "BOTH",
									text = "text",
									 image = 
						
									{ 
										value = "",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 932,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.2.6

				--Begin Test case NegativeRequestCheck.2.7
				--Description: SoftButtons: type = TEXT; text is empty (SUCCESS because SoftButton is not sent) 

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

					--Verification criteria: Mobile app sends any-relevant-RPC with SoftButtons that include Text=“” (that is, empty string) and Type=TEXT, SDL responds with INVALID_DATA result code and does not transfer it to HMI.


					function Test:Alert_SoftButtonsTEXTTextEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
					--<!-- text is empty 
								
								{ 
									type = "TEXT",
									text = "",
									softButtonID = 1031,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					end

				--End Test case NegativeRequestCheck.2.7

				--Begin Test case NegativeRequestCheck.2.8
				--Description: SoftButtons: type = IMAGE; image value is empty - INVALID_DATA 

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

					--Verification criteria: The request with IMAGE SoftButtonType and the wrong or not defined image parameter is sent, response returns "INVALID_DATA" response code and parameter success="false".

					function Test:Alert_IMAGEValueEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									image = 
						
									{ 
										value = "",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 1121,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.2.8

				--Begin Test case NegativeRequestCheck.2.9
				--Description: SoftButtons: type = IMAGE; image type is empty 

					function Test:Alert_SoftButtonIMAGETypeEmpty() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "",
									}, 
									softButtonID = 1151,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.2.9


			--End Test case NegativeRequestCheck.2

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

				--Verification criteria: 
					--[[- The request with wrong data in "duration" parameter (e.g. String data type) is sent , the response with INVALID_DATA code is returned. 
					- The request with wrong data in "playTone" parameter (e.g. String data type) is sent , the response with INVALID_DATA code is returned. 
					-  The request with wrong data in "alertText" parameter (e.g. Integer data type) is sent , the response with INVALID_DATA code is returned.
					-  The request with wrong data in "text" parameter (e.g. Integer data type) is sent , the response with INVALID_DATA code is returned.
					- The request with wrong data in "softButtonID" parameter (e.g. String data type) is sent , the response with INVALID_DATA code is returned.
					-  The request with wrong data in "timage" parameter (e.g. Integer data type) is sent , the response with INVALID_DATA code is returned.
					-  The request with wrong data in "type" parameter (e.g. Integer data type) is sent , the response with INVALID_DATA code is returned.]]


				--Begin Test case NegativeRequestCheck.3.1
				--Description: alertText1 with wrong type 

					function Test:Alert_alertText1WrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = 123,
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT"
								}
							}, 
							duration = 6000
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	 	


					end

				--End Test case NegativeRequestCheck.3.1

				--Begin Test case NegativeRequestCheck.3.2
				--Description: alertText2 with wrong type 

					function Test:Alert_alertText2WrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = 123,
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT"
								}
							}, 
							duration = 6000
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" }) 	

					end

				--End Test case NegativeRequestCheck.3.2

				--Begin Test case NegativeRequestCheck.3.3
				--Description: alertText3 with wrong type 

					function Test:Alert_alertText3WrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = 123,
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT"
								}
							}, 
							duration = 6000
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.3.3

				--Begin Test case NegativeRequestCheck.3.4
				--Description: ttsChunks: text with wrong type 

					function Test:Alert_ttsChunksTextWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = 123,
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.3.4

				--Begin Test case NegativeRequestCheck.3.5
				--Description: duration: wrong type 

					function Test:Alert_durationWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							duration = "123",
						
						}) 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.3.5

				--Begin Test case NegativeRequestCheck.3.6
				--Description: playTone: wrong type 

					function Test:Alert_playToneWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = "True",
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.3.6

				--Begin Test case NegativeRequestCheck.3.7
				--Description: progressIndicator: wrong type 

					function Test:Alert_progressIndicatorWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = "false",
							progressIndicator = "True",
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.3.7

				--Begin Test case NegativeRequestCheck.3.8
				--Description: SoftButtons: softButtonID with wrong type 

					function Test:Alert_SoftButtonsIDWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = "891",
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.3.8

				--Begin Test case NegativeRequestCheck.3.9
				--Description: SoftButtons: type = TEXT; isHighlighted with wrong type

					function Test:Alert_SoftButtonsTEXTisHighlightedWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = "Keep",
									isHighlighted = "true",
									softButtonID = 1061,
									systemAction = "KEEP_CONTEXT",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.3.9

				--Begin Test case NegativeRequestCheck.3.10
				--Description: SoftButtons: type = TEXT; text with wrong type 

					function Test:Alert_SoftButtonsTEXTTextWrongType() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = 123,
									softButtonID = 1021,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.3.10

			--End Test case NegativeRequestCheck.3

			--Begin Test case NegativeRequestCheck.4
				--Description: Check processing requests with nonexistent values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case Alert request comes with parameters out of bounds (number or enum range)

				--Begin Test case NegativeRequestCheck.4.1
				--Description: ttsChunks: type is not exist 

					function Test:Alert_ttsChunksTypeNotExist() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "any",
									type = "ANY",
								}, 
							}, 
							duration = 6000,
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

				--End Test case NegativeRequestCheck.4.1

				--Begin Test case NegativeRequestCheck.4.2
				--Description: SoftButtons: type of SoftButton is not exist  

					function Test:Alert_SoftButtonsTypeNotExist() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
							}, 
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

				--End Test case NegativeRequestCheck.4.2

				--Begin Test case NegativeRequestCheck.4.3
				--Description: SoftButtons: systemAction is not exist 

					function Test:Alert_SoftButtonsSystemActionNotExist() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
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
									softButtonID = 8171,
									systemAction = "ANY",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.4.3

				--Begin Test case NegativeRequestCheck.4.4
				--Description: SoftButtons: type = IMAGE; image type is not exist 

					function Test:Alert_SoftButtonsIMAGETypeNotExist() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "ANY",
									}, 
									softButtonID = 1161,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.4.4


			--End Test case NegativeRequestCheck.4

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with Special characters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482
					-- SDLAQ-CRS-2910

				--Verification criteria: 
					--[[- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "SoftButton" struct.
					- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "TTSChunk" struct.
					- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "value" parameter of "Image" struct.
					- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "alertText1"
					- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "alertText2"
					- SDL must respond with INVALID_DATA resultCode in case Alert request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "alertText3"]]

					--[[ - In case the mobile application sends any RPC with 'text' param of 'ttsChunk' struct containing newline (that is, '\n' symbol) and other valid params, SDL must consider such RPC as invalid , not transfer it to HMI and respond with INVALID_DATA result code + success:false.

					- In case the mobile application sends any RPC with 'text' param of 'ttsChunk' struct containing tab (that is, '\t' symbol) and other valid params, SDL must consider such RPC as invalid , not transfer it to HMI and respond with INVALID_DATA result code + success:false.]]


				--Begin Test case NegativeRequestCheck.5.1
				--Description: Escape sequence \n in alertText1 

					function Test:Alert_alertText1NewLineChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1\n",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 
						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.5.1

				--Begin Test case NegativeRequestCheck.5.2
				--Description:Escape sequence \t in alertText1 

					function Test:Alert_alertText1TabChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1\t",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.5.2

				--Begin Test case NegativeRequestCheck.5.3
				--Description:Escape sequence \n in alertText2 

					function Test:Alert_alertText2NewLineChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "\nalertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		


					end

				--End Test case NegativeRequestCheck.5.3

				--Begin Test case NegativeRequestCheck.5.4
				--Description:Escape sequence \t in alertText2 

					function Test:Alert_alertText2TabChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "\talertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 
						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	 	

					end

				--End Test case NegativeRequestCheck.5.4

				--Begin Test case NegativeRequestCheck.5.5
				--Description:Escape sequence \n in alertText3 

					function Test:Alert_alertText3NewLineChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alert\nText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		


					end

				--End Test case NegativeRequestCheck.5.5

				--Begin Test case NegativeRequestCheck.5.6
				--Description:Escape sequence \t in alertText3 

					function Test:Alert_alertText3TabChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alert\tText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })		


					end

				--End Test case NegativeRequestCheck.5.6

				--Begin Test case NegativeRequestCheck.5.7
				--Description: Escape sequence \n in TTSChunk text

					function Test:Alert_TTSChunkTextNewLineChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "\nTTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.5.7

				--Begin Test case NegativeRequestCheck.5.8
				--Description:Escape sequence \t in TTSChunk text

					function Test:Alert_TTSChunkTextTabChar() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "\tTTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 6000,
							playTone = true,
							progressIndicator = true,
						
						}) 
					 

						--mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


					end

				--End Test case NegativeRequestCheck.5.8

				--Begin Test case NegativeRequestCheck.5.9
				--Description:Escape sequence \n in SoftButton text

					function Test:Alert_SBTextNewLineCharSBTypeBOTH() 

						--mobile side: Alert request 
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "\nClose",
									image = 
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						}) 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end


					function Test:Alert_SBTextNewLineCharSBTypeTEXT()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = "Ke\nep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

					function Test:Alert_SBTextNewLineCharSBTypeIMAGE()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									text = "Ke\nep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
									image = 
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}
								}
							}
						}) 

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
									 --[[ TODO: update after resolving APPLINK-16052

									image = 
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									}]]
								}
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
					    --hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })	

					end

				--End Test case NegativeRequestCheck.5.9

				--Begin Test case NegativeRequestCheck.5.10
				--Description:Escape sequence \t in SoftButton text 

					function Test:Alert_SBTextTabCharSBTypeBOTH() 

						--mobile side: Alert request 
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "\tClose",
									image = 
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						}) 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end	

					function Test:Alert_SBTextTabCharSBTypeTEXT()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = "Ke\tep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

					function Test:Alert_SBTextTabCharSBTypeIMAGE()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									text = "Ke\tep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
									image = 
									{ 
										value = "icon.png",
										imageType = "DYNAMIC",
									}
								}
							}
						}) 

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
									 --[[ TODO: update after resolving APPLINK-16052

									image = 
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									}]]
								}
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is ABORTED")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    -- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
					    --hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is ABORTED" })	

					end

				--End Test case NegativeRequestCheck.5.10

				--Begin Test case NegativeRequestCheck.5.11
				--Description: Escape sequence \n in SoftButton image value

					function Test:Alert_SBImageValueNewLineCharSBTypeBOTH()

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "Close",
									 image = 
						
									{ 
										value = "ico\n.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						}) 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	
					end

					function Test:Alert_SBImageValueNewLineCharSBTypeIMAGE()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "ico\n.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end


					function Test:Alert_SBImageValueNewLineCharSBTypeTEXT()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = "Close",
									image = 
						
									{ 
										value = "ico\n.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.5.11

				--Begin Test case NegativeRequestCheck.5.12
				--Description: Escape sequence \t in SoftButton image value

					function Test:Alert_SBImageValueTabCharSBTypeBOTH()

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "Close",
									 image = 
						
									{ 
										value = "ico\t.png",
										imageType = "DYNAMIC",
									}, 
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						}) 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	
					end

					function Test:Alert_SBImageValueTabCharSBTypeIMAGE()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "ico\t.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end


					function Test:Alert_SBImageValueTabCharSBTypeTEXT()
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "TEXT",
									text = "Close",
									image = 
						
									{ 
										value = "ico\t.png",
										imageType = "DYNAMIC",
									}, 
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

						--mobile side: Alert response
						EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

					end

				--End Test case NegativeRequestCheck.5.12


			--End Test case NegativeRequestCheck.5

			--Begin Test case NegativeRequestCheck.6
			--Description: Check processing requet with duplicate softButtonID (ABORTED because of SoftButtons presence) 
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-200

				--Verification criteria:  SDL re-sends the parameters sent within SoftButton structure of the corresponding RPC to HMI IN CASE all of requested parameters are valid.

				function Test:Alert_SoftButtonsIDDuplicate() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 3000,
						softButtons = 
						{ 
							
							{ 
								type = "IMAGE",
								 image = 
					
								{ 
									value = "icon.png",
									imageType = "DYNAMIC",
								}, 
								softButtonID = 12345,
								systemAction = "DEFAULT_ACTION",
							}, 
							
							{ 
								type = "TEXT",
								text = "Close",
								isHighlighted = true,
								softButtonID = 12345,
								systemAction = "KEEP_CONTEXT",
							}, 
						}, 
					
					}) 
				 
					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
					{
						softButtons = 
						{ 
							
							{ 
								type = "IMAGE",
								  --[[ TODO: update after resolving APPLINK-16052

								 image = 
					
								{ 
									value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
									imageType = "DYNAMIC",
								},]] 
								softButtonID = 12345,
								systemAction = "DEFAULT_ACTION",
							}, 
							
							{ 
								type = "TEXT",
								text = "Close",
								isHighlighted = true,
								softButtonID = 12345,
								systemAction = "KEEP_CONTEXT",
							}, 
						},
						duration = 0	
					})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 2000)
					end)

					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
					{	
						speakType = "ALERT"
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

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
				end

			--End Test case NegativeRequestCheck.6

			--Begin Test case NegativeRequestCheck.7
			--Description: Check processing request with SoftButtons: type = BOTH, with text and image, without text, without image 

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

				--Verification criteria: Mobile app sends any-relevant-RPC with SoftButtons withType=BOTH and with one of the parameters ('text' and 'image') wrong or not defined, SDL returns INVALID_DATA result code and does not transfer to HMI.

				function Test:Alert_SoftButtonsBOTHWithWithoutTextImage() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 3000,
						softButtons = 
						{ 
				--<!-- with both text and image 
							
							{ 
								type = "BOTH",
								text = "Close",
								 image = 
					
								{ 
									value = "icon.png",
									imageType = "DYNAMIC",
								}, 
								isHighlighted = true,
								softButtonID = 911,
								systemAction = "DEFAULT_ACTION",
							}, 
				--<!-- without text and with image 
							
							{ 
								type = "BOTH",
								 image = 
					
								{ 
									value = "icon.png",
									imageType = "DYNAMIC",
								}, 
								softButtonID = 912,
								systemAction = "STEAL_FOCUS",
							}, 
				--<!-- with text and without image 
							
							{ 
								type = "BOTH",
								text = "text",
								softButtonID = 913,
								systemAction = "KEEP_CONTEXT",
							}, 
						}, 
					
					}) 
				 

					--mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


				end

			--End Test case NegativeRequestCheck.7

			--Begin Test case NegativeRequestCheck.8
			--Description: Check processing request with SoftButtons: type = BOTH, image is not exist (no such file was put via PutFile request) (INVALID_DATA) 

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

				--Verification criteria: Mobile app sends any-relevant-RPC with SoftButtons withType=BOTH and with one of the parameters ('text' and 'image') wrong or not defined, SDL returns INVALID_DATA result code and does not transfer to HMI.

				function Test:Alert_SoftButtonsBOTHImageNotExist() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 3000,
						softButtons = 
						{ 
							
							{ 
								type = "BOTH",
								text = "text",
								 image = 
					
								{ 
									value = "aaa.aaa",
									imageType = "DYNAMIC",
								}, 
								softButtonID = 921,
								systemAction = "KEEP_CONTEXT",
							}, 
						}, 
					
					}) 
				 

					--mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	


				end

			--End Test case NegativeRequestCheck.8



			--Begin Test case NegativeRequestCheck.9
			--Description: Check processing request with SoftButtons: type = IMAGE; image value is not exist - INVALID_DATA 

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

				--Verification criteria: The request with IMAGE SoftButtonType and the wrong or not defined image parameter is sent, response returns "INVALID_DATA" response code and parameter success="false".

				function Test:Alert_IMAGEValueNotExist() 

					 --mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
					  	 
						alertText1 = "alertText1",
						ttsChunks = 
						{ 
							
							{ 
								text = "TTSChunk",
								type = "TEXT",
							}, 
						}, 
						duration = 3000,
						softButtons = 
						{ 
							
							{ 
								type = "IMAGE",
								 image = 
					
								{ 
									value = "aaa.aaa",
									imageType = "DYNAMIC",
								}, 
								softButtonID = 1124,
								systemAction = "DEFAULT_ACTION",
							}, 
						}, 
					
					}) 
				 

					--mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

				end

			--End Test case NegativeRequestCheck.9


		--End Test suit NegativeRequestCheck
--[[ TODO: APPLINK-14765
	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--Begin Test suit NegativeResponseCheck
		--Description: check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA: SDLAQ-CRS-50

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with nonexistent resultCode 

					function Test:Alert_ResultCodeNotExist() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "ANY", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
				end

				--End Test case NegativeResponseCheck.1.1

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method

					function Test:Alert_MethodOutLowerBound() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")


					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
					end

				--End Test case NegativeResponseCheck.1.2

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with empty string in method

					function Test:Alert_tryAgainTimeOutLowerBound()

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {tryAgainTime = -1})

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					end

				--End Test case NegativeResponseCheck.1.3

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check processing response with empty string in method

					function Test:Alert_tryAgainTimeOutUpperBound()

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {tryAgainTime = 2000000001})

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					end

				--End Test case NegativeResponseCheck.1.4

				
			--End Test case NegativeResponseCheck.1

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50

				--Verification criteria: 
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.


				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters
--[[
					function Test:Alert_ResponseMissingAllPArameters() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:Send('{}')

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
					end

				--End Test case NegativeResponseCheck.2.1

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter

					function Test:Alert_MethodMissing() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"code":0}}')

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
					end

				--End Test case NegativeResponseCheck.2.2

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter

					function Test:Alert_ResultCodeMissing() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"method":"UI.Alert"}}')

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
					end

				--End Test case NegativeResponseCheck.2.3


			--End Test case NegativeResponseCheck.2

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-482

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type

				--Begin Test case NegativeResponseCheck.3.1
				--Description: 

					function Test:Alert_MethodWrongtype() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, 1234, "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					
					end

				--End Test case NegativeResponseCheck.3.1

				--Begin Test case NegativeResponseCheck.3.2
				--Description: 

					function Test:Alert_ResultCodeWrongtype() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:Send('{"id":'..tostring(AlertId)..',"jsonrpc":"2.0","result":{"method":"UI.Alert", "code":true}}')

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					end

				--End Test case NegativeResponseCheck.3.2

				--Begin Test case NegativeResponseCheck.3.3
				--Description: 

					function Test:Alert_tryAgainTimeWrongtype() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3", 
												duration = 7000
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "UI",
										duration = 7000,
									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {tryAgainTime = "tryAgainTime"})

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)

					 
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })
					
					end

				--End Test case NegativeResponseCheck.3.3

			--End Test case NegativeResponseCheck.3

		--End Test suit NegativeResponseCheck

]]

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
		--Description: Check UNSUPPORTED_RESOURCE result code wirh success true

			--Requirement id in JAMA: SDLAQ-CRS-1025

			--Verification criteria: 
				--When "STATIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components

			function Test:Alert_UnsupportedResourceSuccessTrue() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									}, 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									},]] 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendError(AlertId, "UI.Alert", "UNSUPPORTED_RESOURCE", " Resource is not unsupported ")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "UNSUPPORTED_RESOURCE" })

					end
			
		--End Test case ResultCodeCheck.1

		--Begin Test case ResultCodeCheck.2
		--Description: Check WARNINGS result code wirh success false

			--Requirement id in JAMA: SDLAQ-CRS-1029

			--Verification criteria: 
				--When "ttsChunks" are sent within the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result of request. Info parameter provides additional information about the case. General request result success=false in case of TTS is the only component which processes a request. 

			function Test:Alert_WarningsSuccessFalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}
						
						}) 
				

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}
							}
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendError(SpeakId, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Resource is not supported")

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "speak")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "WARNINGS" })

					end
			
		--End Test case ResultCodeCheck.2

		--Begin Test case ResultCodeCheck.3
		  --Begin Test case ResultCodeCheck.3.1
		--Description: Check WARNINGS result code wirh success true

			--Requirement id in JAMA: SDLAQ-CRS-1029

			--Verification criteria: 
				--When "ttsChunks" are sent within the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 

			function Test:Alert_WarningsSuccessTrue() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									}, 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							duration = 0,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									},]] 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendError(SpeakId, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Resource is not supported")

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS" })

					end
			
    	  --Begin Test case ResultCodeCheck.3.2
        --Description:SoftButtons: type = IMAGE; image value is missing 
    
        function Test:Alert_SoftButtonIMAGEValueNotAvailanbleInStorage() 
    
        --mobile side: Alert request  
        local CorIdAlert = self.mobileSession:SendRPC("Alert",
                  {
                       
                    alertText1 = "alertText1",
                    alertText2 = "alertText2",
                    alertText3 = "alertText3",
                    ttsChunks = 
                    { 
                      
                      { 
                        text = "TTSChunk",
                        type = "TEXT",
                      } 
                    }, 
                    duration = 3000,
                    playTone = true,
                    progressIndicator = true,
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
                        softButtonID = 3,
                        systemAction = "DEFAULT_ACTION",
                      }, 
                      
                      { 
                        type = "TEXT",
                        text = "Keep",
                        isHighlighted = true,
                        softButtonID = 4,
                        systemAction = "KEEP_CONTEXT",
                      }, 
                      
                      { 
                        type = "IMAGE",
                         image = 
                  
                        { 
                          value = "icon.png",
                          imageType = "DYNAMIC",
                        }, 
                        softButtonID = 5,
                        systemAction = "STEAL_FOCUS",
                      }, 
                    }
                  
                  })

        local AlertId
        --hmi side: UI.Alert request 
        EXPECT_HMICALL("UI.Alert", 
              { 
                alertStrings = 
                {
                  {fieldName = "alertText1", fieldText = "alertText1"},
                      {fieldName = "alertText2", fieldText = "alertText2"},
                      {fieldName = "alertText3", fieldText = "alertText3"}
                  },
                  alertType = "BOTH",
                duration = 0,
                progressIndicator = true,
                softButtons = 
                { 
                  
                  { 
                    type = "BOTH",
                    text = "Close",
                      --[[ TODO: update after resolving APPLINK-16052


                     image = 
              
                    { 
                      value = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.."/icon.png",
                      imageType = "DYNAMIC",
                    },]] 
                    isHighlighted = true,
                    softButtonID = 3,
                    systemAction = "DEFAULT_ACTION",
                  }, 
                  
                  { 
                    type = "TEXT",
                    text = "Keep",
                    isHighlighted = true,
                    softButtonID = 4,
                    systemAction = "KEEP_CONTEXT",
                  }, 
                  
                  { 
                    type = "IMAGE",
                      --[[ TODO: update after resolving APPLINK-16052

                     image = 
              
                    { 
                      value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.appID .. "_" .. config.deviceMAC .. "/icon.png",
                      imageType = "DYNAMIC",
                    },]] 
                    softButtonID = 5,
                    systemAction = "STEAL_FOCUS",
                  }, 
                }
              })
          :Do(function(_,data)
            SendOnSystemContext(self,"ALERT")
            AlertId = data.id

            local function alertResponse()
              self.hmiConnection:SendResponse(AlertId, "UI.Alert", "WARNINGS", {info="Requested image(s) not found."})

              SendOnSystemContext(self,"MAIN")
            end

            RUN_AFTER(alertResponse, 3000)
          end)

        local SpeakId
        --hmi side: TTS.Speak request 
        EXPECT_HMICALL("TTS.Speak", 
              { 
                ttsChunks = 
                { 
                  
                  { 
                    text = "TTSChunk",
                    type = "TEXT"
                  }
                },
                speakType = "ALERT",
                playTone = true
              })
          :Do(function(_,data)
            self.hmiConnection:SendNotification("TTS.Started")
            SpeakId = data.id

            local function speakResponse()
              self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

              self.hmiConnection:SendNotification("TTS.Stopped")
            end

            RUN_AFTER(speakResponse, 2000)

          end)
          :ValidIf(function(_,data)
            if #data.params.ttsChunks == 1 then
              return true
            else
              print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
              return false
            end
          end)

        -- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
        --hmi side: BC.PalayTone request 
        -- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

        ExpectOnHMIStatusWithAudioStateChanged(self)

          --mobile side: Alert response
          EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS", info="Requested image(s) not found." })
          end

        --End Test case ResultCodeCheck.3.2
		--End Test case ResultCodeCheck.3

		--Begin Test case ResultCodeCheck.4
		--Description: Check APPLICATION_NOT_REGISTERED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-487

			--Verification criteria: 
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			function Test:Alert_ApplicationNotRegisterSuccessFalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession1:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									}, 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 
					    --mobile side: Alert response
					    self.mobileSession1:ExpectResponse(CorIdAlert, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })

			end
			
		--End Test case ResultCodeCheck.4

		--Begin Test case ResultCodeCheck.5
		--Description: 

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-483
				-- SDLAQ-CRS-488
				-- SDLAQ-CRS-489
				-- SDLAQ-CRS-490
				-- 

			--Verification criteria:
				-- The Alert request is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned.
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- SDL must return success="false" for Alert response ABORTED 
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				--If a higher priority request is currently being displayed on HMI, Alert request gets the response with REJECTED resultCode from HMI.


			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"},  { code = "ABORTED", name = "Aborted"}, { code = "UNSUPPORTED_REQUEST", name = "UnsupportedRequest"}}
			for i=1,#resultCodes do
				Test["Alert_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{ 
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3"
					})

					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
					{	
					})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendError(AlertId, "UI.Alert", resultCodes[i].code, "Error code")

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = resultCodes[i].code, info = "Error code" })

				end
			end
		--End Test case ResultCodeCheck.5

		--Begin Test case ResultCodeCheck.6
		--Description: Check WARNINGS result code wirh success true

			--Requirement id in JAMA: SDLAQ-CRS-488

			--Verification criteria: 
				-- If a higher priority request is currently being displayed on HMI, Alert request gets the response with REJECTED resultCode from HMI.
			function Test:Alert_RejectedSuccessFalse() 

				--mobile side: Alert request
				local CorIdAlert2 	
				local CorIdAlert1 = self.mobileSession:SendRPC("Alert",
																{
																  	 
																	alertText1 = "alertText1", 
																	alertText2 = "alertText2",
																	alertText3 = "alertText3",
																	duration = 10000
																
																}) 
					 
				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
								{alertStrings = 
									{
										{fieldName = "alertText1", fieldText = "alertText1"},
								        {fieldName = "alertText2", fieldText = "alertText2"},
								        {fieldName = "alertText3", fieldText = "alertText3"}
								    }},
									{alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertTextRejected1"},
									        {fieldName = "alertText2", fieldText = "alertTextRejected2"},
									        {fieldName = "alertText3", fieldText = "alertTextRejected3"}
									    }})
					:Times(2)
					:Do(function(exp,data)

						if exp.occurences == 1 then

							SendOnSystemContext(self,"ALERT")
							AlerId = data.id
							local CorIdAlert2 = self.mobileSession:SendRPC("Alert",
																			{
																			  	 
																				alertText1 = "alertTextRejected1", 
																				alertText2 = "alertTextRejected2",
																				alertText3 = "alertTextRejected3",
																			
																			})
						elseif 
							exp.occurences == 2 then 
								self.hmiConnection:SendError(data.id, "UI.Alert", "REJECTED", "Higher priority request is currently being displayed on HMI" )

								local function alertResponse()
								self.hmiConnection:SendResponse(AlerId, "UI.Alert", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
								end

							RUN_AFTER(alertResponse, 3000)

						end
				end)

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

			    --mobile side: Alert response
			    EXPECT_RESPONSE("Alert", 
						    	{ success = false, resultCode = "REJECTED", info = "Higher priority request is currently being displayed on HMI" },
						    	{ success = true, resultCode = "SUCCESS" })
			    :Times(2)

			end
			
		--End Test case ResultCodeCheck.6

		--Begin Test case ResultCodeCheck.7
		--Description: Check DISALLOWED result code wirh success false

			--Requirement id in JAMA: SDLAQ-CRS-485

			--Verification criteria: 
				-- SDL must return "DISALLOWED, success:false" fo Alert RPC to mobile app IN CASE Alert RPC is not included to policies assigned to this mobile app. 

			function Test:Precondition_DeactivateApp()

				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

			end

			function Test:Alert_DisallowedSuccessFalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							softButtons = 
							{ 
								
								{ 
									type = "IMAGE",
									 image = 
						
									{ 
										value = "icon.png",
										imageType = "STATIC",
									}, 
									softButtonID = 1171,
									systemAction = "DEFAULT_ACTION",
								}, 
							}, 
						
						}) 
					 

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "DISALLOWED" })


					end
			
		--End Test case ResultCodeCheck.7

		--Begin Test case ResultCodeCheck.8
		--Description: Check USER_DISALLOWED result code wirh success false

			--Requirement id in JAMA: SDLAQ-CRS-486

			--Verification criteria: SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.

			function Test:ActivationApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					if					
						data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						
						--hmi side: expect SDL.GetUserFriendlyMessage message response
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)						
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
						end)

						--hmi side: expect BasicCommunication.ActivateApp request
						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							--hmi side: sending BasicCommunication.ActivateApp response
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
					end
				end)				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
			end

--TODO debbug after resolving APPLINK-13101
                --[[
			local idGroup
				function Test:Precondition_UserDisallowedPolicyUpdate()
					--hmi side: sending SDL.GetURLS request
					local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
					--hmi side: expect SDL.GetURLS response from HMI
					EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
					:Do(function(_,data)
						--print("SDL.GetURLS response is received")
						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
							{
								requestType = "PROPRIETARY",
								fileName = "filename"
							}
						)
						--mobile side: expect OnSystemRequest notification 
						EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
						:Do(function(_,data)
							--print("OnSystemRequest notificfation is received")
							--mobile side: sending SystemRequest request 
							local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
								{
									fileName = "PolicyTableUpdate",
									requestType = "PROPRIETARY"
								},
							"files/PTU_ForAlertSoftButtonsFalseWithAlertGroup.json")
							
							local systemRequestId
							--hmi side: expect SystemRequest request
							EXPECT_HMICALL("BasicCommunication.SystemRequest")
							:Do(function(_,data)
								systemRequestId = data.id
								--print("BasicCommunication.SystemRequest is received")
								
								--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
								self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
									{
										policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
									}
								)
								function to_run()
									--hmi side: sending SystemRequest response
									self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
								end
								
								RUN_AFTER(to_run, 500)
							end)
							
							--hmi side: expect SDL.OnStatusUpdate
							EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
							:ValidIf(function(exp,data)
								if 
									exp.occurences == 1 and
									data.params.status == "UP_TO_DATE" then
										return true
								elseif
									exp.occurences == 1 and
									data.params.status == "UPDATING" then
										return true
								elseif
									exp.occurences == 2 and
									data.params.status == "UP_TO_DATE" then
										return true
								else 
									if 
										exp.occurences == 1 then
											print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
									elseif exp.occurences == 2 then
											print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
									end
									return false
								end
							end)
							:Times(Between(1,2))
							
							--mobile side: expect SystemRequest response
							EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
							:Do(function(_,data)
								--print("SystemRequest is received")
								--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
								local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
								:Do(function(_,data)
									print("SDL.GetUserFriendlyMessage is received")
									--hmi side: sending SDL.GetListOfPermissions request to SDL
										local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
										
										-- hmi side: expect SDL.GetListOfPermissions response
										-- -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions"}})
										EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
										:Do(function(_,data)
											print("SDL.GetListOfPermissions response is received")

											idGroup = data.result.allowedFunctions[1].id								
											--hmi side: sending SDL.OnAppPermissionConsent
											self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = idGroup, name = "AlertGroup"}}, source = "GUI"})
											end)				
								end)
							end)

							
						end)
					end)
				end
           --]]

			-- function Test:Alert_UserDisallowedSuccessFalse() 

			-- 			 --mobile side: Alert request 	
			-- 			local CorIdAlert = self.mobileSession:SendRPC("Alert",
			-- 			{
						  	 
			-- 				alertText1 = "alertText1",
			-- 				ttsChunks = 
			-- 				{ 
								
			-- 					{ 
			-- 						text = "TTSChunk",
			-- 						type = "TEXT",
			-- 					}, 
			-- 				}, 
			-- 				duration = 3000,
			-- 				softButtons = 
			-- 				{ 
								
			-- 					{ 
			-- 						type = "IMAGE",
			-- 						 image = 
						
			-- 						{ 
			-- 							value = "icon.png",
			-- 							imageType = "STATIC",
			-- 						}, 
			-- 						softButtonID = 1171,
			-- 						systemAction = "DEFAULT_ACTION",
			-- 					}, 
			-- 				}, 
						
			-- 			}) 
					 
			-- 		    --mobile side: Alert response
			-- 		    self.mobileSession:ExpectResponse(CorIdAlert, { success = false, resultCode = "USER_DISALLOWED" })

			-- end
		--End Test case ResultCodeCheck.8

		--Begin Test case ResultCodeCheck.9
		--Description: 

			--Requirement id in JAMA: SDLAQ-CRS-485

			--Verification criteria: SDL must return "DISALLOWED, success:false" fo Alert RPC to mobile app IN CASE Alert RPC contains softButton with SystemAction disallowed by policies assigned to this mobile app.

			-- function Test:Precondition_DisallowedsoftButtons()
			-- 	--hmi side: sending SDL.OnAppPermissionConsent
			-- 	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = idGroup, name = "AlertGroup"}}, source = "GUI"})
			-- 	-- end)
			-- 	EXPECT_NOTIFICATION("OnPermissionsChange")
			-- end

			--Begin Precondition.1
			--Description: Allow GetVehicleData in all levels
			function Test:StopSDLToBackUpPreloadedPt( ... )
				-- body
				StopSDL()
				DelayedExp(1000)
			end

			function Test:BackUpPreloadedPt()
				-- body
				os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
				os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
			end

			function Test:ModifyPreloadedPtAgain(pathToFile)
				-- body
				pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
				local file  = io.open(pathToFile, "r")
				local json_data = file:read("*all") -- may be abbreviated to "*a";
				file:close()

				local json = require("modules/json")
				 
				local data = json.decode(json_data)
				for k,v in pairs(data.policy_table.functional_groupings) do
					if (data.policy_table.functional_groupings[k].rpcs == nil) then
					    --do
					    data.policy_table.functional_groupings[k] = nil
					else
					    --do
					    local count = 0
					    for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
					    if (count < 30) then
					        --do
							data.policy_table.functional_groupings[k] = nil
					    end
					end
				end

				data.policy_table.functional_groupings.AlertGroup = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs.Alert = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs.Alert.hmi_levels = {'FULL', 'LIMITED', 'BACKGROUND'}

				data.policy_table.app_policies.default.keep_context = false
				data.policy_table.app_policies.default.steal_focus = false
				data.policy_table.app_policies.default.groups = {"Base-4", "AlertGroup"}
				
				data = json.encode(data)
				-- print(data)
				-- for i=1, #data.policy_table.app_policies.default.groups do
				-- 	print(data.policy_table.app_policies.default.groups[i])
				-- end
				file = io.open(pathToFile, "w")
				file:write(data)
				file:close()
			end

			local function StartSDLAfterChangePreloaded()
				-- body

				Test["Precondition_StartSDL"] = function(self)
					StartSDL(config.pathToSDL, config.ExitOnCrash)
					DelayedExp(1000)
				end

				Test["Precondition_InitHMI_1"] = function(self)
					self:initHMI()
				end

				Test["Precondition_InitHMI_onReady_1"] = function(self)
					self:initHMI_onReady()
				end

				Test["Precondition_ConnectMobile_1"] = function(self)
					self:connectMobile()
				end

				Test["Precondition_StartSession_1"] = function(self)
					self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
				end

			end

			StartSDLAfterChangePreloaded()

			function Test:RestorePreloadedPt()
				-- body
				os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
				os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
			end
			--End Precondition.1

			--Begin Precondition.2
			--Description: Activation application			
			GlobalVarAppID = 0
			function RegisterApplication(self)
				-- body
				local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function (_, data)
					-- body
					GlobalVarAppID = data.params.application.appID
				end)

				EXPECT_RESPONSE(corrID, {success = true})

				-- delay - bug of ATF - it is not wait for UpdateAppList and later
				-- line appID = self.applications["Test Application"]} will not assign appID
				DelayedExp(1000)
			end

			function Test:RegisterApp()
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_, data)
					-- body
					RegisterApplication(self)
				end)
			end
			--End Precondition.2

			--Begin Precondition.1
			--Description: Activation application		
				function Test:ActivationApp()			
					--hmi side: sending SDL.ActivateApp request
					-- local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = GlobalVarAppID})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						if
							data.result.isSDLAllowed ~= true then
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
							
							--hmi side: expect SDL.GetUserFriendlyMessage message response
							 --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							EXPECT_HMIRESPONSE(RequestId)
							:Do(function(_,data)						
								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
					
					--mobile side: expect notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
				end
			--End Precondition.1

			--Begin Precondition.3
			--Description: PutFile with file names "a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"
			
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
			--End Precondition.

			-- Begin Test case ResultCodeCheck.9.1
			-- Description: Check Disallowed resultCode by receiving Alert request with softButton systemAction = "KEEP_CONTEXT"

			function Test:Alert_DisallowedKeepContext() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}
										}
									
									})
				
				local AlertId
				EXPECT_HMICALL("UI.Alert")
				:Do(function(_,data)
					SendOnSystemContext(self,"ALERT")
					AlertId = data.id

					local function alertResponse()
						self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(alertResponse, 3000)
				end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
					
			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			
			end
			--End Test case ResultCodeCheck.9.1

			-- Begin Test case ResultCodeCheck.9.2
			-- Description: Check Disallowed resultCode by receiving Alert request with softButton systemAction = "STEAL_FOCUS"

			function Test:Alert_DisallowedStealFocus() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											},
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})
				
				local AlertId
				EXPECT_HMICALL("UI.Alert")
				:Do(function(_,data)
					SendOnSystemContext(self,"ALERT")
					AlertId = data.id

					local function alertResponse()
						self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(alertResponse, 3000)
				end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			end

			--End Test case ResultCodeCheck.9.2

			-- Begin Test case ResultCodeCheck.9.3
			-- Description: Check SUCCESS resultCode by receiving Alert request with softButton systemAction = "DEFAULT_ACTION"

			function Test:Alert_SuccessDefaultAction() 

				local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{ 
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3",
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}
										}
					})

					local AlertId
					--hmi side: UI.Alert request 
					EXPECT_HMICALL("UI.Alert", 
					{	
						softButtons = 
										{ 
											
											{ 
												type = "BOTH",
												text = "Close",
												  --[=[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
													imageType = "DYNAMIC",
												},]=] 
												isHighlighted = true,
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}
										}
					})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

					--mobile side: OnHMIStatus notifications
					-- ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			end

			--Begin Precondition.1
			--Description: Allow GetVehicleData in all levels
			function Test:StopSDLToBackUpPreloadedPt( ... )
				-- body
				StopSDL()
				DelayedExp(1000)
			end

			function Test:BackUpPreloadedPt()
				-- body
				os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
				os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
			end

			function Test:ModifyPreloadedPtAgainAgain(pathToFile)
				-- body
				pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
				local file  = io.open(pathToFile, "r")
				local json_data = file:read("*all") -- may be abbreviated to "*a";
				file:close()

				local json = require("modules/json")
				 
				local data = json.decode(json_data)
				for k,v in pairs(data.policy_table.functional_groupings) do
					if (data.policy_table.functional_groupings[k].rpcs == nil) then
					    --do
					    data.policy_table.functional_groupings[k] = nil
					else
					    --do
					    local count = 0
					    for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
					    if (count < 30) then
					        --do
							data.policy_table.functional_groupings[k] = nil
					    end
					end
				end

				data.policy_table.functional_groupings.AlertGroup = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs.Alert = {}
				data.policy_table.functional_groupings.AlertGroup.rpcs.Alert.hmi_levels = {'FULL', 'LIMITED', 'BACKGROUND'}

				data.policy_table.app_policies.default.keep_context = true
				data.policy_table.app_policies.default.steal_focus = true
				data.policy_table.app_policies.default.priority = "NORMAL"
				data.policy_table.app_policies.default.groups = {"Base-4", "AlertGroup"}
				
				data = json.encode(data)
				-- print(data)
				-- for i=1, #data.policy_table.app_policies.default.groups do
				-- 	print(data.policy_table.app_policies.default.groups[i])
				-- end
				file = io.open(pathToFile, "w")
				file:write(data)
				file:close()
			end

			local function StartSDLAfterChangePreloaded()
				-- body

				Test["Precondition_StartSDL"] = function(self)
					StartSDL(config.pathToSDL, config.ExitOnCrash)
					DelayedExp(1000)
				end

				Test["Precondition_InitHMI_1"] = function(self)
					self:initHMI()
				end

				Test["Precondition_InitHMI_onReady_1"] = function(self)
					self:initHMI_onReady()
				end

				Test["Precondition_ConnectMobile_1"] = function(self)
					self:connectMobile()
				end

				Test["Precondition_StartSession_1"] = function(self)
					self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
				end

			end

			StartSDLAfterChangePreloaded()

			function Test:RestorePreloadedPt()
				-- body
				os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
				os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
			end
			--End Precondition.1

			--Begin Precondition.2
			--Description: Activation application			
			GlobalVarAppID = 0
			function RegisterApplication(self)
				-- body
				local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function (_, data)
					-- body
					GlobalVarAppID = data.params.application.appID
				end)

				EXPECT_RESPONSE(corrID, {success = true})

				-- delay - bug of ATF - it is not wait for UpdateAppList and later
				-- line appID = self.applications["Test Application"]} will not assign appID
				DelayedExp(1000)
			end

			function Test:RegisterApp()
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_, data)
					-- body
					RegisterApplication(self)
				end)
			end
			--End Precondition.2

			--Begin Precondition.1
			--Description: Activation application		
				function Test:ActivationApp()			
					--hmi side: sending SDL.ActivateApp request
					-- local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = GlobalVarAppID})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						if
							data.result.isSDLAllowed ~= true then
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
							
							--hmi side: expect SDL.GetUserFriendlyMessage message response
							 --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							EXPECT_HMIRESPONSE(RequestId)
							:Do(function(_,data)						
								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
					
					--mobile side: expect notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
				end
			--End Precondition.1

			--Begin Precondition.3
			--Description: PutFile with file names "a", "icon.png", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"
			
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
			--End Precondition.

		--End Test case ResultCodeCheck.9

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
		--Description: Check SDL behavior in case of absence of responses from HMI 

			--Requirement id in JAMA: SDLAQ-CRS-490, APPLINK-7484

			--Verification criteria: 
				--In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.
				--SDL should re-send the resultCode obtained from HMI in general Alert response to mobile app

			--Begin Test case HMINegativeCheck.1.1
			--Description: Alert with TTS and UI interfaces, TTS without response from HMI


				function Test:Alert_UITTSWithoutResponseToTTSSpeak()

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 5000,
																			playTone = false,
																			progressIndicator = true
																		})


						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)

						--hmi side: UI.Alert request 
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 5000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 3000)
							end)


						EXPECT_HMICALL("TTS.StopSpeaking")
							:Do(function(_,data)
								self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

								self.hmiConnection:SendNotification("TTS.Stopped")

								self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)


					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED" })
					    	:Timeout(11000)

					end

			--End Test case HMINegativeCheck.1.1

			--Begin Test case HMINegativeCheck.1.2
			--Description: Alert with TTS and UI interfaces, UI without response

				function Test:Alert_UITTSWithoutResponseToUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 5000,
																			playTone = false,
																			progressIndicator = true
																		})


						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)

						--hmi side: UI.Alert request 
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 5000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })
					    	:Timeout(7000)
					    	:Do(function(_,data)
					    		self.hmiConnection:SendNotification("TTS.Stopped")
					    		SendOnSystemContext(self,"MAIN")
					    	end)

					end

			--End Test case HMINegativeCheck.1.2

			--Begin Test case HMINegativeCheck.1.3
			--Description: Alert with UI interface, UI without response

				function Test:Alert_UIWithoutResponseToUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3", 
																			duration = 5000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: UI.Alert request 
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "UI",
											duration = 5000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })
					    	:Timeout(7000)
					    	:Do(function(_,data)
					    		SendOnSystemContext(self,"MAIN")
					    	end)

					end

			--End Test case HMINegativeCheck.1.3

			--Begin Test case HMINegativeCheck.1.4
			--Description: Alert with TTS and UI interfaces, UI and TTS without response

				function Test:Alert_UITTSWithoutResponseToUIAlertTTSSpeak()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 5000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 5000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })
					    	:Timeout(7000)
					    	:Do(function(_,data)
					    		self.hmiConnection:SendNotification("TTS.Stopped")
					    		SendOnSystemContext(self,"MAIN")
					    	end)

					end

			--End Test case HMINegativeCheck.1.4
			
			
		--End Test case HMINegativeCheck.1

		--Begin Test case HMINegativeCheck.2
		--Description: Check processing 2 equal responses

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

			--Begin Test case HMINegativeCheck.2.1
			--Description: 2 responsens to TTS.Speak request

				function Test:Alert_UITTSTwoResponsesToTTSSpeak()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 10000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								function SendingFirstTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								function SendingSecondTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })	

								end

								RUN_AFTER(SendingFirstTTSSpeakResponse, 1000)
								RUN_AFTER(SendingSecondTTSSpeakResponse, 1500)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local  AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 10000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = data.id

								local function SendingUIAlerResponse()

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)


					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					    DelayedExp()

					end

			--End Test case HMINegativeCheck.2.1

			--Begin Test case HMINegativeCheck.2.2
			--Description: 2 responsens to UI.Alert request 

				function Test:Alert_UITTSTwoResponsesToUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local  AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = data.id

								local function SendingFirstUIAlerResponse()

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")	

								end

								local function SendingSecondUIAlerResponse()

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingFirstTTSSpeakResponse, 5000)
								RUN_AFTER(SendingSecondUIAlerResponse, 5300)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					    DelayedExp()

					end

			--End Test case HMINegativeCheck.2.2

		--End Test case HMINegativeCheck.2


		--Begin Test case HMINegativeCheck.3
		--Description: Check processing responses with invalid structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

			--Begin Test case HMINegativeCheck.3.1
			--Description: TTS.Speak response with invalid structure
--[[TODO update according to APPLINK-14765
				function Test:Alert_UITTSInvalidResponseTTSSpeak()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:Send('{"error":{"code":4,"message":"Speak is REJECTED"},"id":'..tostring(SpeakId)..',"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local  AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = data.id

								local function SendingUIAlerResponse()

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {})

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })

					end

			--End Test case HMINegativeCheck.3.1

			--Begin Test case HMINegativeCheck.3.2
			--Description: UI.Alert with invalid structure

				function Test:Alert_UITTSInvalidResponseUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local  AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								local function SendingUIAlerResponse()

									self.hmiConnection:Send('{"error":{"code":4,"message":"Alert is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.Alert"}}')

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

			--End Test case HMINegativeCheck.3.2

		--End Test case HMINegativeCheck.3


		--Begin Test case HMINegativeCheck.4
		--Description: HMI correlation id check

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: 

			--Begin Test case HMINegativeCheck.4.1
			--Description: UI.Alert response with empty correlation id

				function Test:Alert_EmptyHMIcorrelationIDUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", {})	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								local function SendingUIAlerResponse()

									self.hmiConnection:Send('"id":,"jsonrpc":"2.0","result":{"code":0,"method":"UI.Alert"}}')

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

			--End Test case HMINegativeCheck.4.1

			--Begin Test case HMINegativeCheck.4.2
			--Description: UI.Alert response with nonexistent HMI correlation id

				function Test:Alert_NonexistentHMIcorrelationIDUIAlert()
					--mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
																	{
																		alertText1 = "alertText1",
																		alertText2 = "alertText2",
																		alertText3 = "alertText3",
																		ttsChunks = 
																		{ 
																			
																			{ 
																				text = "Hello!",
																				type = "TEXT",
																			} 
																		}, 
																		duration = 7000,
																		playTone = false,
																		progressIndicator = true
																	})


					--hmi side: TTS.Speak request 
					local SpeakId
					EXPECT_HMICALL("TTS.Speak", 
									{	
										speakType = "ALERT",
										ttsChunks = 
											{ 
												
												{ 
													text = "Hello!",
													type = "TEXT",
												} 
											}
									})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function SendingTTSSpeakResponse()

								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", {})	

								self.hmiConnection:SendNotification("TTS.Stopped")

							end

							RUN_AFTER(SendingTTSSpeakResponse, 1000)

						end)

						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)


					--hmi side: UI.Alert request
					EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
									        {fieldName = "alertText2", fieldText = "alertText2"},
									        {fieldName = "alertText3", fieldText = "alertText3"}
									    },
									    alertType = "BOTH",
										duration = 5000,
										progressIndicator = true
									})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")

							local function SendingUIAlerResponse()

								self.hmiConnection:SendResponse(5555, "UI.Alert", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")	

							end

							RUN_AFTER(SendingUIAlerResponse, 5000)

						end)



					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

				end

			--End Test case HMINegativeCheck.4.2

			--Begin Test case HMINegativeCheck.4.3
			--Description: UI.Alert response with wrong type of correlation id 

				function Test:Alert_WrongTypeHMIcorrelationIDUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", {})	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 5000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = tostring(data.id)

								local function SendingUIAlerResponse()

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {})

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

					end

			--End Test case HMINegativeCheck.4.3
]]
			--Begin Test case HMINegativeCheck.4.4
			--Description: TTS.Speak response with correlation id of UI.Alert request, UI.Alert response with with correlation id of TTS.Speak request

				function Test:Alert_ResponseTTSSpeakWithCorrelationIdUIAlert()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3",
																			ttsChunks = 
																			{ 
																				
																				{ 
																					text = "Hello!",
																					type = "TEXT",
																				} 
																			}, 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: TTS.Speak request 
						local SpeakId
						EXPECT_HMICALL("TTS.Speak", 
										{	
											speakType = "ALERT",
											ttsChunks = 
												{ 
													
													{ 
														text = "Hello!",
														type = "TEXT",
													} 
												}
										})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")
								SpeakId = data.id

							end)

							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)


						--hmi side: UI.Alert request
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "BOTH",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = data.id

								local function SendingTTSSpeakResponse()

									self.hmiConnection:SendResponse(AlertId, "TTS.Speak", "SUCCESS", {})	

									self.hmiConnection:SendNotification("TTS.Stopped")

								end

								RUN_AFTER(SendingTTSSpeakResponse, 1000)

								local function SendingUIAlerResponse()

									self.hmiConnection:SendResponse(SpeakId, "UI.Alert", "SUCCESS", {})

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 5000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })

					end

			--End Test case HMINegativeCheck.4.4

			--Begin Test case HMINegativeCheck.4.5
			--Description: UI.Alert response after timeout is expired

				function Test:Alert_SendingUIAlertAfterTimeoutExpired()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
																		{
																			alertText1 = "alertText1",
																			alertText2 = "alertText2",
																			alertText3 = "alertText3", 
																			duration = 7000,
																			playTone = false,
																			progressIndicator = true
																		})


						--hmi side: UI.Alert request
						local AlertId
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    alertType = "UI",
											duration = 7000,
											progressIndicator = true
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")

								AlertId = data.id

								local function SendingUIAlerResponse()

									self.hmiConnection:SendResponse(AlerId, "UI.Alert", "SUCCESS", {})

									SendOnSystemContext(self,"MAIN")	

								end

								RUN_AFTER(SendingUIAlerResponse, 8000)

							end)



						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })


					end

			--End Test case HMINegativeCheck.4.5

		--End Test case HMINegativeCheck.4

		--Begin Test case HMINegativeCheck.5
		--Description: Check processing response with fake parameters(not from API)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
				--[[ - In case HMI sends request (response, notification) with fake parameters that SDL should use internally -> SDL must:
					- validate received response
					- cut off fake parameters
					- process received request (response, notification)
				]]

			function Test:Alert_FakeParamsInResponse() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value =config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { fake = "fake" })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 
				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			    	:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
			
			
		end


		--End Test case HMINegativeCheck.5

		--Begin Test case HMINegativeCheck.6
		--Description: Check processing response with parameters from another API
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
				--[[ - In case HMI sends request (response, notification) with fake parameters that SDL should use internally -> SDL must:
					- validate received response
					- cut off fake parameters
					- process received request (response, notification)
				]]

			function Test:Alert_ParamsFromOtherAPIInResponse() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value =config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { sliderPosition = 5 })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 
				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			    	:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
			
			
		end

		--End Test case HMINegativeCheck.6
		

	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	
		--Begin Test case SequenceCheck.1
		--Description: Call Alert pop-up with and without "Play Tone" option and without SoftButtons from mobile application on HMI

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-49
				-- SDLAQ-CRS-50

			--Verification criteria:
				--Alert request notifies the user via TTS/UI or both with some information.
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

			--Begin Test case SequenceCheck.1.1
			--Description: Alert with TTSChunk and with playTone = true

				function Test:Alert_playToneTrueWithTttsChunks()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
												alertText1 = "ALERT!",
												alertText2 = "Attention!",
												alertText3 = "This is Alert!",
												ttsChunks = 
													{ 
														
														{ 
															text = "Hello!",
															type = "TEXT",
														} 
													}, 
												duration = 5000,
												playTone = true
											})


						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = "ALERT!"},
						        {fieldName = "alertText2", fieldText = "Attention!"},
						        {fieldName = "alertText3", fieldText = "This is Alert!"}
						    },
							duration = 5000
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							ttsChunks = 
								{ 
									
									{ 
										text = "Hello!",
										type = "TEXT",
									} 
								},
							speakType = "ALERT",
							playTone = true
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

			--End Test case SequenceCheck.1.1

			--Begin Test case SequenceCheck.1.2
			--Description:  Alert with TTSChunk and with playTone = false
			
				function Test:Alert_playTonefalse() 

						 --mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks = 
							{ 
								
								{ 
									text = "TTSChunk",
									type = "TEXT",
								}, 
							}, 
							duration = 3000,
							playTone = false,
						
						}) 
					 
						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert")
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id

							local function alertResponse()
								self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(alertResponse, 3000)
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							playTone = false
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function speakResponse()
								self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

								self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(speakResponse, 2000)

						end)
					 
						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone")
						-- :Times(0)

						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self)

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

					end

			--End Test case SequenceCheck.1.2

			--Begin Test case SequenceCheck.1.3
			--Description: Alert without TTSChunk and with playTone = true

				function Test:Alert_playToneTrueWithoutTtsChunks() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3",
												playTone = true
											
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
											{fieldName = "alertText2", fieldText = "alertText2"},
											{fieldName = "alertText3", fieldText = "alertText3"}
										}

									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 2000)
							end)

						EXPECT_HMICALL("TTS.Speak", {playTone = true})

						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone")


						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						
					end			

			--End Test case SequenceCheck.1.3

			--Begin Test case SequenceCheck.1.4
			--Description: Alert without TTSChunk and with playTone = false
			
				function Test:Alert_playToneFalseWithoutTtsChunks() 

						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
											  	 
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3",
												playTone = false
											
											})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
											{fieldName = "alertText2", fieldText = "alertText2"},
											{fieldName = "alertText3", fieldText = "alertText3"}
										}

									})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id

								local function alertResponse()
									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
								end

								RUN_AFTER(alertResponse, 2000)
							end)

						EXPECT_HMICALL("TTS.Speak", {playTone = false})

						-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
						--hmi side: BC.PalayTone request 
						-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone")
						-- :Times(0)


						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "alert")

					    --mobile side: Alert response
					    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						
					end

			--End Test case SequenceCheck.1.4
			
			
		--End Test case SequenceCheck.1

		--Begin Test case SequenceCheck.2
		--Description: Call Alert pop-up with one SoftButton from mobile application on HMI.
			-- SoftButton with DEFAULT_ACTION system action is used.
			-- Check: behavior of Alert pop-up by pressing SoftButton with DEFAULT_ACTION system action

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-49
				-- SDLAQ-CRS-50
				-- SDLAQ-CRS-923
				-- SDLAQ-CRS-914
				-- SDLAQ-CRS-3046

			--Verification criteria:
				-- Alert request notifies the user via TTS/UI or both with some information.

				-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

				-- Pressing a SoftButton with SystemAction DEFAULT_ACTION for Alert request on HMI causes closing of Alert notification on UI and sending response with resultCode SUCCESS to mobile application. OnButtonPress/OnButtonEvent is sent to SDL and then transmitted to mobile app if the application is subscribed to CUSTOM_BUTTON.

				-- DEFAULT_ACTION applicable for each command is platform specific and must be checked for each command separately (see exact API related requirements).

				--  App sends Alert {<UI-related params WITH softButtons >, <TTS-related params>} : SDL must return SUCCESS in case TTS engine has successfully spoken TTS-related values and HMI has successfully displayed a message with UI-related values and closed it by DEFAULT_ACTION or STEAL_FOCUS button press.


				function Test:PressDefaultActionButton()
						--mobile side: Alert request 	
						local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
						  	 
							alertText1 = "ALERT!",
							alertText2 = "Attention!",
							alertText3 = "This is Alert!",
							ttsChunks = 
							{ 
								
								{ 
									text = "Hello!",
									type = "TEXT",
								} 
							}, 
							duration = 5000,
							playTone = false,
							progressIndicator = true,
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
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}
							}
						
						})

						local AlertId
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
						{	
							alertStrings = 
							{
								{fieldName = "alertText1", fieldText = "ALERT!"},
						        {fieldName = "alertText2", fieldText = "Attention!"},
						        {fieldName = "alertText3", fieldText = "This is Alert!"}
						    },
						    alertType = "BOTH",
							duration = 0,
							progressIndicator = true,
							softButtons = 
							{ 
								
								{ 
									type = "BOTH",
									text = "Close",
									  --[[ TODO: update after resolving APPLINK-16052

									 image = 
						
									{ 
										value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
										imageType = "DYNAMIC",
									},]] 
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								}
							}
						})
						:Do(function(_,data)
							SendOnSystemContext(self,"ALERT")
							AlertId = data.id
						end)

						local SpeakId
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
						{	
							ttsChunks = 
							{ 
								
								{ 
									text = "Hello!",
									type = "TEXT"
								}
							},
							speakType = "ALERT"
						})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function ButtonEventPress()
								self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
								self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
								self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ButtonEventPress, 1000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
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

							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end)

						EXPECT_HMICALL("TTS.StopSpeaking")
						:Do(function(_,data)
							self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

							self.hmiConnection:SendNotification("TTS.Stopped")

							self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

						    --mobile side: Alert response
							EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
						end)

						--mobile side: OnHMIStatus notifications
						if 
							self.isMediaApplication == true or 
							self.appHMITypes["NAVIGATION"] == true then 

									--mobile side: OnHMIStatus notifications
									EXPECT_NOTIFICATION("OnHMIStatus",
										    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
										    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
										    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
										    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
									    :Times(4)
									   
						elseif 
							self.isMediaApplication == false then

								
									--mobile side: OnHMIStatus notifications
									EXPECT_NOTIFICATION("OnHMIStatus",
										    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
										    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
									    :Times(2)
									    
						end

					end
			
		--End Test case SequenceCheck.2

		--Begin Test case SequenceCheck.3
		--Description: Call Alert request with two SoftButtons from mobile app on HMI
			-- SoftButtons with DEFAULT_ACTION and KEEP_CONTEXT system actions are used.
			-- Check: behavior of Alert pop-up by pressing SoftButton with KEEP_CONTEXT system action

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-924

			--Verification criteria:
				-- Pressing a SoftButton with SystemAction KEEP_CONTEXT for Alert request on HMI causes a renew of the timeout that applies to Alert notification on HMI.  OnButtonPress/OnButtonEvent is sent if the application is subscribed on CUSTOM_BUTTON.
				--Pressing the button with KEEP_CONTEXT SystemAction causes a renew of a timeout that applies to dialog/overlay on HMI. OnButtonPress/OnButtonEvent is sent to SDL and then transmitted to mobile app if the application is subscribed to CUSTOM_BUTTON.

			function Test:PressKeepContextButton()

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 ="alertText1",
										alertText2 ="alertText2",
										alertText3 ="alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text ="TTSChunk",
												type ="TEXT",
											} 
										}, 
										duration = 5000,
										playTone = false,
										progressIndicator = false,
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
												softButtonID = 3,
												systemAction ="DEFAULT_ACTION",
											}, 
											{ 
												type ="TEXT",
												text ="Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction ="KEEP_CONTEXT",
											}
										}
													
									})

				local AlertId

				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
								{	
									alertStrings = 
									{
										{fieldName = "alertText1", fieldText = "alertText1"},
								        {fieldName = "alertText2", fieldText = "alertText2"},
								        {fieldName = "alertText3", fieldText = "alertText3"}
								    },
								    duration = 0,
									progressIndicator = false,
									softButtons = 
									{ 
										
										{ 
											type ="BOTH",
											text ="Close",
											  --[[ TODO: update after resolving APPLINK-16052

											 image = 
								
											{ 
												value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
												imageType ="DYNAMIC",
											},]] 
											isHighlighted = true,
											softButtonID = 3,
											systemAction ="DEFAULT_ACTION",
										}, 
										{ 
											type ="TEXT",
											text ="Keep",
											isHighlighted = true,
											softButtonID = 4,
											systemAction ="KEEP_CONTEXT",
										}
									}
								})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id
					end)

				local SpeakId

				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function SpeakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end


						local function ButtonEventPress()
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																{
																	name = "CUSTOM_BUTTON", 
																	mode = "BUTTONDOWN", 
																	customButtonID = 4, 
																	appID = self.applications["Test Application"]
																})
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																{
																	name = "CUSTOM_BUTTON", 
																	mode = "BUTTONUP", 
																	customButtonID = 4, 
																	appID = self.applications["Test Application"]
																})
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
																{
																	name = "CUSTOM_BUTTON", 
																	mode = "SHORT", 
																	customButtonID = 4, 
																	appID = self.applications["Test Application"]
																})
						end

						RUN_AFTER(ButtonEventPress, 1000)
						RUN_AFTER(SpeakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)

					--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 4},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 4})
					:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
						{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 4})
					:Do(function(_, data)

						self.hmiConnection:SendNotification("UI.OnResetTimeout",
															{
																appID = self.applications["Test Application"],
																methodName = "UI.Alert"
															})

						local function AlertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(AlertResponse, 5000 )
					end)

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end
			
		--End Test case SequenceCheck.3

		--Begin Test case SequenceCheck.4
		--Description:Call Alert request with three SoftButtons from mobile application on HMI.
			-- SoftButtons with DEFAULT_ACTION, KEEP_CONTEXT and STEAL_FOCUS system actions are used.
			-- Check: behavior of Alert pop-up by pressing SoftButton with STEAL_FOCUS system action in HMIlevel = LIMITED and FULL mode.

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-925
				-- SDLAQ-CRS-915
				-- SDLAQ-CRS-3046

			--Verification criteria: 
				--For the app that is not in HMI_FULL, pressing a SoftButton with SystemAction STEAL_FOCUS for Alert causes bringing an application to HMI_FULL mode and closing the Alert notification on HMI with resultCode SUCCESS. OnButtonPress/OnButtonEvent is sent if the application is subscribed to CUSTOM_BUTTON.
				-- STEAL_FOCUS is applied only for Alert/AlertManeuver request. For other requests there's no specific action occured on HMI if the button with STEAL_FOCUS SystemAction is pressed
				--  Pressing the button with STEAL_FOCUS SystemAction for Alert brings the app into HMI_FULL. Alert user dialog is closed
				-- App sends Alert {<UI-related params WITH softButtons >} : SDL must return SUCCESS in case HMI has successfully displayed a message with UI-related values and closed it it by DEFAULT_ACTION or STEAL_FOCUS button press..
			
		if 
			Test.isMediaApplication == true or 
			Test.appHMITypes["NAVIGATION"] == true then
				function Test:PressStealFocusButton()
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
													{
														appID = self.applications["Test Application"],
														reason = "GENERAL"
													})

						local AlertId

						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    duration = 0,
											progressIndicator = false,
											softButtons = 
											{ 
												
												{ 
													type ="BOTH",
													text ="Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
														imageType ="DYNAMIC",
													},]] 
													isHighlighted = true,
													softButtonID = 3,
													systemAction ="DEFAULT_ACTION",
												}, 
												{ 
													type ="TEXT",
													text ="Keep",
													isHighlighted = true,
													softButtonID = 4,
													systemAction ="KEEP_CONTEXT",
												},									{ 
													type ="IMAGE",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
														imageType ="DYNAMIC",
													},]] 
													softButtonID = 2,
													systemAction ="STEAL_FOCUS",
												}
											}
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id


								local function ButtonEventPress()
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "BUTTONDOWN", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "BUTTONUP", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
									self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "SHORT", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
								end

								RUN_AFTER(ButtonEventPress, 3000)


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

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
							end)


						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    },
							    { systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
						    :Times(4)
						 	:Do(function(exp,data)
						 		if exp.occurences == 1 then 
						 			--mobile side: Alert request 	
									local CorIdAlert = self.mobileSession:SendRPC("Alert",
														{
														  	 
															alertText1 ="alertText1",
															alertText2 ="alertText2",
															alertText3 ="alertText3", 
															duration = 5000,
															playTone = false,
															progressIndicator = false,
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
																	softButtonID = 3,
																	systemAction ="DEFAULT_ACTION",
																}, 
																{ 
																	type ="TEXT",
																	text ="Keep",
																	isHighlighted = true,
																	softButtonID = 4,
																	systemAction ="KEEP_CONTEXT",
																},
																{ 
																type ="IMAGE",
																image = 
													
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC",
																}, 
																softButtonID = 2,
																systemAction ="STEAL_FOCUS",
																}
															}
														
														})
									--mobile side: Alert response
								    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
								        :Do(function(_,data)
								        	local function ActivateApplication()
												local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
												-- TODO: update after resolving APPLINK-16094
												-- EXPECT_HMIRESPONSE(rid, {code = 0})
												EXPECT_HMIRESPONSE(rid)
											end

											RUN_AFTER(ActivateApplication, 1000)
									    end)

								end
						 	end)
				end

			elseif Test.isMediaApplication == false then

				function Test:PressStealFocusButton()
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
													{
														appID = self.applications["Test Application"],
														reason = "GENERAL"
													})

						local AlertId

						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
										{	
											alertStrings = 
											{
												{fieldName = "alertText1", fieldText = "alertText1"},
										        {fieldName = "alertText2", fieldText = "alertText2"},
										        {fieldName = "alertText3", fieldText = "alertText3"}
										    },
										    duration = 0,
											progressIndicator = false,
											softButtons = 
											{ 
												
												{ 
													type ="BOTH",
													text ="Close",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
														imageType ="DYNAMIC",
													},]] 
													isHighlighted = true,
													softButtonID = 3,
													systemAction ="DEFAULT_ACTION",
												}, 
												{ 
													type ="TEXT",
													text ="Keep",
													isHighlighted = true,
													softButtonID = 4,
													systemAction ="KEEP_CONTEXT",
												},									{ 
													type ="IMAGE",
													  --[[ TODO: update after resolving APPLINK-16052

													 image = 
										
													{ 
														value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
														imageType ="DYNAMIC",
													},]] 
													softButtonID = 2,
													systemAction ="STEAL_FOCUS",
												}
											}
										})
							:Do(function(_,data)
								SendOnSystemContext(self,"ALERT")
								AlertId = data.id


								local function ButtonEventPress()
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "BUTTONDOWN", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "BUTTONUP", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
									self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
																		{
																			name = "CUSTOM_BUTTON", 
																			mode = "SHORT", 
																			customButtonID = 2, 
																			appID = self.applications["Test Application"]
																		})
								end

								RUN_AFTER(ButtonEventPress, 3000)


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

									self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

									SendOnSystemContext(self,"MAIN")
							end)


						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"    },
							    { systemContext = "ALERT", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    })
						    :Times(4)
						 	:Do(function(exp,data)
						 		if exp.occurences == 1 then 
						 			--mobile side: Alert request 	
									local CorIdAlert = self.mobileSession:SendRPC("Alert",
														{
														  	 
															alertText1 ="alertText1",
															alertText2 ="alertText2",
															alertText3 ="alertText3", 
															duration = 5000,
															playTone = false,
															progressIndicator = false,
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
																	softButtonID = 3,
																	systemAction ="DEFAULT_ACTION",
																}, 
																{ 
																	type ="TEXT",
																	text ="Keep",
																	isHighlighted = true,
																	softButtonID = 4,
																	systemAction ="KEEP_CONTEXT",
																},
																{ 
																type ="IMAGE",
																image = 
													
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC",
																}, 
																softButtonID = 2,
																systemAction ="STEAL_FOCUS",
																}
															}
														
														})
									--mobile side: Alert response
								    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
								        :Do(function(_,data)
								        	local function ActivateApplication()
												local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

												EXPECT_HMIRESPONSE(rid, {code = 0})
											end

											RUN_AFTER(ActivateApplication, 1000)
									    end)

								end
						 	end)
				end

			end
			
		--End Test case SequenceCheck.4

		--Begin Test case SequenceCheck.5
		--Description: Call Alert request with four SoftButtons from mobile application on HMI.
			-- SoftButtons with DEFAULT_ACTION, KEEP_CONTEXT and STEAl_FOCUS are used.
			-- Check reflecting of DEFAULT_ACTION, KEEP_CONTEXT and STEAl_FOCUS SoftButtons on UI.

			--Requirement id in JAMA/or Jira ID: 
				-- SDLAQ-CRS-923
				-- SDLAQ-CRS-914
				-- SDLAQ-CRS-916

			--Verification criteria: 
				--Pressing a SoftButton with SystemAction DEFAULT_ACTION for Alert request on HMI causes closing of Alert notification on UI and sending response with resultCode SUCCESS to mobile application. OnButtonPress/OnButtonEvent is sent to SDL and then transmitted to mobile app if the application is subscribed to CUSTOM_BUTTON
				-- DEFAULT_ACTION applicable for each command is platform specific and must be checked for each command separately (see exact API related requirements).
				-- Pressing the button with KEEP_CONTEXT SystemAction causes a renew of a timeout that applies to dialog/overlay on HMI. OnButtonPress/OnButtonEvent is sent to SDL and then transmitted to mobile app if the application is subscribed to CUSTOM_BUTTON.

			function Test:PressDefaultActionButton4SB()
				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "ALERT!",
										alertText2 = "Attention!",
										alertText3 = "This is Alert!",
										ttsChunks = 
										{ 
											
											{ 
												text = "Hello!",
												type = "TEXT",
											} 
										}, 
										duration = 5000,
										playTone = false,
										progressIndicator = true,
										softButtons = 
										{ 
											
											{ 
												type ="BOTH",
												text ="Close",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="DEFAULT_ACTION",
											}, 
											{ 
												type ="TEXT",
												text ="Keep",
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="KEEP_CONTEXT",
											},
											{ 
												type ="IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												softButtonID = 3,
												systemAction ="STEAL_FOCUS",
											},
											{ 
												type ="BOTH",
												text ="Decline",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 4,
												systemAction ="DEFAULT_ACTION",
											}
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
				{	
					alertStrings = 
					{
						{fieldName = "alertText1", fieldText = "ALERT!"},
				        {fieldName = "alertText2", fieldText = "Attention!"},
				        {fieldName = "alertText3", fieldText = "This is Alert!"}
				    },
				    alertType = "BOTH",
					duration = 0,
					progressIndicator = true,
					softButtons = 
										{ 
											
											{ 
												type ="BOTH",
												text ="Close",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
													imageType ="DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="DEFAULT_ACTION",
											}, 
											{ 
												type ="TEXT",
												text ="Keep",
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="KEEP_CONTEXT",
											},
											{ 
												type ="IMAGE",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
													imageType ="DYNAMIC",
												},]] 
												softButtonID = 3,
												systemAction ="STEAL_FOCUS",
											},
											{ 
												type ="BOTH",
												text ="Decline",
												  --[[ TODO: update after resolving APPLINK-16052

												 image = 
									
												{ 
													value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
													imageType ="DYNAMIC",
												},]] 
												isHighlighted = true,
												softButtonID = 4,
												systemAction ="DEFAULT_ACTION",
											}
										}
				})
				:Do(function(_,data)
					SendOnSystemContext(self,"ALERT")
					AlertId = data.id
				end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
				{	
					ttsChunks = 
					{ 
						
						{ 
							text = "Hello!",
							type = "TEXT"
						}
					},
					speakType = "ALERT"
				})
				:Do(function(_,data)
					self.hmiConnection:SendNotification("TTS.Started")
					SpeakId = data.id

					local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 4, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 4, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 4, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
				end)

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 4},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 4})
				:Times(2)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 4})
				:Do(function(_, data)

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end


		--End Test case SequenceCheck.5

--------------------------------------------------------------------------------------------------------------------------------------------------------------

     --Begin Test case SequenceCheck.6

     --Description: reflecting on UI Alert with soft buttons when different params are defined; different conditions of long and short press action
        --TC_SoftButtons_01: short and long click on TEXT soft button , reflecting on UI only if text is defined
        --TC_SoftButtons_02: short and long click on IMAGE soft button, reflecting on UI only if image is defined   
        --TC_SoftButtons_03: short click on BOTH soft button, reflecting on UI
	--TC_SoftButtons_04: long click on BOTH soft button
			
      --Requirement id in JAMA: mentioned in each test case
      --Verification criteria: mentioned in each test case
				
			
		--Begin Test case SequenceCheck.6.1
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on TEXT soft button
			
			 function Test:Alert_TEXTSoftButtons_ShortClick()  

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
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
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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
										}}
							           })	
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

		--End Test case SequenceCheck.6.1
	

		--Begin Test case SequenceCheck.6.2
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on TEXT soft button

			function Test:Alert_TEXTSoftButtons_LongClick()  

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
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
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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
										}}
							           })	
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

		 --End Test case SequenceCheck.6.2
	

		--Begin Test case SequenceCheck.6.3
		--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

			function Test:Alert_SoftButtonTypeTEXTAndTextWithWhitespace() 
	
				local RequestParams =
										{
																  	 
											alertText1 = "alertText1",
											ttsChunks = 
											 { 
											
											     { 
												text = "TTSChunk",
												type = "TEXT",
											     } 
											 }, 
											 duration = 3000,
											 progressIndicator = true,
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

			        --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end

		--End Test case SequenceCheck.6.3
	

		--Begin Test case SequenceCheck.6.4
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
		--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on IMAGE soft button

			function Test:Alert_IMAGESoftButtons_ShortClick()  

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
										softButtons = 
										{ 
											
											{
												softButtonID = 1,
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
													value = "action.png",
													imageType = "DYNAMIC"
												  },       
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											}
										}
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									        {
											softButtonID = 1,
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
												value = "action.png",
												imageType = "DYNAMIC"
											  },       
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										}
                                                                    }
							           })	
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

		--End Test case SequenceCheck.6.4
	

		--Begin Test case SequenceCheck.6.5
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	 	--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on IMAGE soft button

			function Test:Alert_IMAGESoftButtons_LongClick() 

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
										softButtons = 
										{ 
											
											{
												softButtonID = 1,
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
													value = "action.png",
													imageType = "DYNAMIC"
												  },       
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											}
										}
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									        {
											softButtonID = 1,
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
												value = "action.png",
												imageType = "DYNAMIC"
											  },       
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										}
                                                                    }
							           })	
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 2, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

		--End Test case SequenceCheck.6.5


		--Begin Test case SequenceCheck.6.6
		--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined 

			function Test:Alert_SoftButtonTypeIMAGEAndImageNotExists()
	
				local RequestParams =
										{
																  	 
											alertText1 = "alertText1",
											ttsChunks = 
											 { 
											
											     { 
												text = "TTSChunk",
												type = "TEXT",
											     } 
											 }, 
											 duration = 3000,
											 progressIndicator = true,
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

			        --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end
                  
	 	--End Test case SequenceCheck.6.6
	       

		--Begin Test case SequenceCheck.6.7
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
		--Info: This TC will be failing till resolving APPLINK-16052 
	
			--Requirement id in JAMA: SDLAQ-CRS-869

			--Verification criteria: Checking short click on BOTH soft button

			 function Test:Alert_SoftButtonTypeBOTH_ShortClick() 

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
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
													value = "action.png",
													imageType = "DYNAMIC"
												  },       
												isHighlighted = true,
												systemAction = "DEFAULT_ACTION"
											}
										}
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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
												value = "action.png",
												imageType = "DYNAMIC"
											  },       
											isHighlighted = true,
											systemAction = "DEFAULT_ACTION"
										}
                                                                    }
							           })	
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

	 	--End Test case SequenceCheck.6.7
	

		--Begin Test case SequenceCheck.6.8
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

		       function Test:Alert_SoftButtonTypeBOTHAndTextIsNotDefined()

				local RequestParams =
										{
																  	 
											alertText1 = "alertText1",
											ttsChunks = 
											 { 
											
											     { 
												text = "TTSChunk",
												type = "TEXT",
											     } 
											 }, 
											 duration = 3000,
											 progressIndicator = true,
											 softButtons = 
											 { 
																		
											     {
													softButtonID = 1,
													type = "BOTH",
													text,            --text is not defined
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

			        --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									        {
											softButtonID = 1,
											type = "BOTH",
										        text, 
										        image = 
											 {
												value = "icon.png",
												imageType = "DYNAMIC"
											  },       
											isHighlighted = false,
											systemAction = "DEFAULT_ACTION"
										} 
                                                                }
							  })
			    :Times(0)


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end



		--End Test case SequenceCheck.6.8


		--Begin Test case SequenceCheck.6.9
		--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
		--Info: This TC will be failing till resolving APPLINK-16052
	
			--Requirement id in JAMA: SDLAQ-CRS-870

			--Verification criteria: Checking long click on BOTH soft button

			function Test:Alert_SoftButtonBOTHType_LongClick() 

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
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
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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
                                      				

					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
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

					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

					SendOnSystemContext(self,"MAIN")
				end)

				EXPECT_HMICALL("TTS.StopSpeaking")
				:Do(function(_,data)
					self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, "TTS.StopSpeaking", "SUCCESS", { })

				    --mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: OnHMIStatus notifications
				if 
					self.isMediaApplication == true or 
					Test.appHMITypes["NAVIGATION"] == true then 

							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							    :Times(4)
							   
				elseif 
					self.isMediaApplication == false then

						
							--mobile side: OnHMIStatus notifications
							EXPECT_NOTIFICATION("OnHMIStatus",
								    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
								    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
							    :Times(2)
							    
				end

			end

		--End Test case SequenceCheck.6.9


		--Begin Test case SequenceCheck.6.10
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

			function Test:Alert_SoftButtonBOTHTypeImageIsNotDefined()

                            local RequestParams =
										{
																  	 
											alertText1 = "alertText1",
											ttsChunks = 
											 { 
											
											     { 
												text = "TTSChunk",
												type = "TEXT",
											     } 
											 }, 
											 duration = 3000,
											 progressIndicator = true,
											 softButtons = 
											 { 
																		
											     {
													softButtonID = 1,
													type = "BOTH",
													text = "First",
                                                                                                        image,                
													isHighlighted = false,
													systemAction = "DEFAULT_ACTION"
											     } 
											 }
																
										}

			        --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									       {
											softButtonID = 1,
											type = "BOTH",
										        text = "First",
											image,                
										        isHighlighted = false,
											systemAction = "DEFAULT_ACTION"
								               } 
                                                                }
							  })
			    :Times(0)


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end
   
	 	--End Test case SequenceCheck.6.10


	     	--Begin Test case SequenceCheck.6.11
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
		--Info: This TC will be failing till resolving APPLINK-16052
	
			--Requirement id in JAMA: SDLAQ-CRS-2912

			--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed 

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
	                --:Timeout(13000)
	
	    end


    	  		 function Test:Alert_SoftButton_AfterUnsubscribe()  

				local RequestParams =
									{
									  	 
										alertText1 = "alertText1",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										progressIndicator = true,
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
									
									}

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

				local function ButtonEventPress()
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})
					end

					RUN_AFTER(ButtonEventPress, 1000)

				

				--mobile side: OnButtonEvent notifications
				EXPECT_NOTIFICATION("OnButtonEvent",
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
				{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
				:Times(0)

				--mobile side: OnButtonPress notifications
				EXPECT_NOTIFICATION("OnButtonPress",
				{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 3})
                                :Times(0)

				

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)

				ExpectOnHMIStatusWithAudioStateChanged(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			
		end

	 --End Test case SequenceCheck.6.11


	--Begin Test case SequenceCheck.6.12
		--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	
			--Requirement id in JAMA: SDLAQ-CRS-200

			--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined 

			function Test:Alert_SoftButtonBOTHTypeImageAndTextNotDefined()

                            local RequestParams =
										{
																  	 
											alertText1 = "alertText1",
											ttsChunks = 
											 { 
											
											     { 
												text = "TTSChunk",
												type = "TEXT",
											     } 
											 }, 
											 duration = 3000,
											 progressIndicator = true,
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

			        --mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert", RequestParams)    
				
                                local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert",
							 {	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"}
							        },
							        alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
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


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })	

			end
   
	 	--End Test case SequenceCheck.6.12
 
	--End Test suit SequenceCheck
           
       
-------------------------------------------------------------------------------------------------------------------------------------------------------------- 

		--Begin Test case SequenceCheck.7
		--Description: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout notification received from HMI

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2920

			--Verification criteria: SDL must renew the default timeout for the RPC defined in TTS.OnResetTimeout notification received from HMI.

			--Begin Test case SequenceCheck.7.1
			--Description: Request without softButtons, one OnResetTimeout notification

				function Test:Alert_WithoutSBOneOnResetTimeout()
					--mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
										{
											ttsChunks = 
											{ 
												
												{ 
													text = "Hello!",
													type = "TEXT",
												} 
											}, 
											duration = 5000,
											playTone = false,
											progressIndicator = true
										})


					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
							{	
								speakType = "ALERT",
								ttsChunks = 
									{ 
										
										{ 
											text = "Hello!",
											type = "TEXT",
										} 
									}
							})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function OnResetTimeoutSending()
								self.hmiConnection:SendNotification("UI.OnResetTimeout",
																{
																	appID = self.applications["Test Application"],
																	methodName = "UI.Alert"
																})
							end

							local function SpeakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(OnResetTimeoutSending, 4000)

							RUN_AFTER(SpeakResponse, 8000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)


					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "speak")

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

				end

			--End Test case SequenceCheck.7.1

			--Begin Test case SequenceCheck.7.2
			--Description: Request without softButtons, four OnResetTimeout notification

				function Test:Alert_WithoutSBFourOnResetTimeout()
					--mobile side: Alert request 	
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
										{
											ttsChunks = 
											{ 
												
												{ 
													text = "Hello!",
													type = "TEXT",
												} 
											}, 
											duration = 5000,
											playTone = false,
											progressIndicator = true
										})


					local SpeakId
					--hmi side: TTS.Speak request 
					EXPECT_HMICALL("TTS.Speak", 
							{	
								speakType = "ALERT",
								ttsChunks = 
									{ 
										
										{ 
											text = "Hello!",
											type = "TEXT",
										} 
									}
							})
						:Do(function(_,data)
							self.hmiConnection:SendNotification("TTS.Started")
							SpeakId = data.id

							local function OnResetTimeoutSending()
								self.hmiConnection:SendNotification("TTS.OnResetTimeout",
																{
																	appID = self.applications["Test Application"],
																	methodName = "TTS.Speak"
																})
							end

							local function SpeakResponse()
										self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
							end

							RUN_AFTER(OnResetTimeoutSending, 4000)
							RUN_AFTER(OnResetTimeoutSending, 8000)
							RUN_AFTER(OnResetTimeoutSending, 12000)
							RUN_AFTER(OnResetTimeoutSending, 16000)

							RUN_AFTER(SpeakResponse, 20000)

						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
								return false
							end
						end)

					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "speak", 24000)

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
				    :Timeout(23000)

				end

			--End Test case SequenceCheck.7.2

		--End Test case SequenceCheck.7

		--Begin Test case SequenceCheck.8
		--Description: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout notification received from HMI

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2920

			--Verification criteria: SDL must renew the default timeout for the RPC defined in TTS.OnResetTimeout notification received from HMI.

			function Test:Alert_WithoutResponseToTTSSpeak()
				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
										ttsChunks = 
										{ 
											
											{ 
												text = "Hello!",
												type = "TEXT",
											} 
										}, 
										duration = 5000,
										playTone = false,
										progressIndicator = true
									})


				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
						{	
							speakType = "ALERT",
							ttsChunks = 
								{ 
									
									{ 
										text = "Hello!",
										type = "TEXT",
									} 
								}
						})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id
					end)

					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)


				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self, "speak", 14000)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })
			    	:Timeout(12000)
			    	:Do(function(_,data)
			    		self.hmiConnection:SendNotification("TTS.Stopped")
			    	end)

			end

		--End Test case SequenceCheck.8

		--Begin Test case SequenceCheck.9
		--Description: Alert is interrupted by VR.Started

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-3047

			--Verification criteria: HMI is expected to return 'ABORTED' result code in case of HMI has successfully displayed a message with UI-related values and closed by HU System event of higher priority.

		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then			

			function Test:Alert_AbortResultCodeByVrStarted()
				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
										alertText1 = "ALERT!",
										alertText2 = "Attention!",
										alertText3 = "This is Alert!",
										ttsChunks = 
										{ 
											
											{ 
												text = "Hello!",
												type = "TEXT",
											} 
										}, 
										duration = 5000,
										playTone = true,
										progressIndicator = true,
										softButtons = 
										{ 
											
											{ 
												type ="BOTH",
												text ="Close",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="DEFAULT_ACTION",
											}, 
											{ 
												type ="TEXT",
												text ="Keep",
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="KEEP_CONTEXT",
											},
											{ 
												type ="IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												softButtonID = 3,
												systemAction ="STEAL_FOCUS",
											},
											{ 
												type ="BOTH",
												text ="Decline",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 4,
												systemAction ="DEFAULT_ACTION",
											}
										}
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "ALERT!"},
							        {fieldName = "alertText2", fieldText = "Attention!"},
							        {fieldName = "alertText3", fieldText = "This is Alert!"}
							    },
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 1,
										systemAction ="DEFAULT_ACTION",
									}, 
									{ 
										type ="TEXT",
										text ="Keep",
										isHighlighted = true,
										softButtonID = 1,
										systemAction ="KEEP_CONTEXT",
									},
									{ 
										type ="IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										softButtonID = 3,
										systemAction ="STEAL_FOCUS",
									},
									{ 
										type ="BOTH",
										text ="Decline",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 4,
										systemAction ="DEFAULT_ACTION",
									}
								}
							})
				:Do(function(_,data)
					SendOnSystemContext(self,"ALERT")
					AlertId = data.id
				end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								speakType = "ALERT",
								ttsChunks = 
									{ 
										
										{ 
											text = "Hello!",
											type = "TEXT",
										} 
									},
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						self.hmiConnection:SendNotification("VR.Started")

					end)

				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
					    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
					    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
					    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			    	:Times(5)
			    	:Do(function(exp,data)
			    		if exp.occurences == 2 then 
			    			self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

			    			self.hmiConnection:SendNotification("TTS.Stopped")

			    			self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

							SendOnSystemContext(self,"MAIN")
						elseif exp.occurences == 4 then
							self.hmiConnection:SendNotification("VR.Stopped")
			    		end
			    	end)

			    -- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
			    --hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED" })

			end

		elseif
			Test.isMediaApplication == false then			

			function Test:Alert_AbortResultCodeByVrStarted()
				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
										alertText1 = "ALERT!",
										alertText2 = "Attention!",
										alertText3 = "This is Alert!",
										ttsChunks = 
										{ 
											
											{ 
												text = "Hello!",
												type = "TEXT",
											} 
										}, 
										duration = 5000,
										playTone = true,
										progressIndicator = true,
										softButtons = 
										{ 
											
											{ 
												type ="BOTH",
												text ="Close",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="DEFAULT_ACTION",
											}, 
											{ 
												type ="TEXT",
												text ="Keep",
												isHighlighted = true,
												softButtonID = 1,
												systemAction ="KEEP_CONTEXT",
											},
											{ 
												type ="IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												softButtonID = 3,
												systemAction ="STEAL_FOCUS",
											},
											{ 
												type ="BOTH",
												text ="Decline",
												 image = 
									
												{ 
													value = "icon.png",
													imageType ="DYNAMIC",
												}, 
												isHighlighted = true,
												softButtonID = 4,
												systemAction ="DEFAULT_ACTION",
											}
										}
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "ALERT!"},
							        {fieldName = "alertText2", fieldText = "Attention!"},
							        {fieldName = "alertText3", fieldText = "This is Alert!"}
							    },
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type ="BOTH",
										text ="Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 1,
										systemAction ="DEFAULT_ACTION",
									}, 
									{ 
										type ="TEXT",
										text ="Keep",
										isHighlighted = true,
										softButtonID = 1,
										systemAction ="KEEP_CONTEXT",
									},
									{ 
										type ="IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										softButtonID = 3,
										systemAction ="STEAL_FOCUS",
									},
									{ 
										type ="BOTH",
										text ="Decline",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType ="DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 4,
										systemAction ="DEFAULT_ACTION",
									}
								}
							})
				:Do(function(_,data)
					SendOnSystemContext(self,"ALERT")
					AlertId = data.id
				end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								speakType = "ALERT",
								ttsChunks = 
									{ 
										
										{ 
											text = "Hello!",
											type = "TEXT",
										} 
									},
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						self.hmiConnection:SendNotification("VR.Started")

						local function to_run()

							self.hmiConnection:SendError(SpeakId, "TTS.Speak", "ABORTED", "Speak is aborted")

			    			self.hmiConnection:SendNotification("TTS.Stopped")

			    			self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

							SendOnSystemContext(self,"MAIN")

						end

						RUN_AFTER(to_run, 1000)

					end)

				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
					    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
			    	:Times(2)
			    	:Do(function(exp,data)
			    		if  exp.occurences == 2 then
							self.hmiConnection:SendNotification("VR.Stopped")
			    		end
			    	end)

			    -- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
			    --hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED" })

			end
		end

              --End Test case SequenceCheck.9

	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: Processing Alert request in LIMITED HMI level

			--Requirement id in JAMA: SDLAQ-CRS-770

			--Verification criteria: SDL doesn't reject Alert request when current HMI is LIMITED

		if 
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then

			function Test:Presondition_DeactivateToLimited()

				--hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

			end

			function Test:Alert_LimitedHMILevel() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value =config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 
				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    },
					    { systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED" },
					    { systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    },
					    { systemContext = "MAIN",  hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"    })
				    :Times(4)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end	
		end
			
		--End Test case DifferentHMIlevel.1

		--Begin Test case DifferentHMIlevel.1
		--Description: Processing Alert request in Background HMI level

			--Requirement id in JAMA: SDLAQ-CRS-770

			--Verification criteria: SDL doesn't reject Alert request when current HMI is BACKGROUND
 
 		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then

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
								  appHMIType = { "NAVIGATION", "COMMUNICATION" },
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

								self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

							end)
						end
					
			--Precondition: Activate second app
				function Test:ActivateSecondApp()
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appId2})
					EXPECT_HMIRESPONSE(rid)
					
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN"})
				end

			function Test:Alert_BackgroundHMILevel() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value =config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 
			 	-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				self.mobileSession1:ExpectNotification("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    },
					    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    })
				    :Times(2)

				self.mobileSession:ExpectNotification("OnHMIStatus", {})
					:Times(0)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
			
			end

		elseif
			Test.isMediaApplication == false then

			function Test:Presondition_DeactivateToBackground()

				--hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

			end

			function Test:Alert_BackgroundHMILevel() 

				--mobile side: Alert request 	
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	 
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT",
											} 
										}, 
										duration = 3000,
										playTone = true,
										progressIndicator = true,
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
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION",
											}, 
											
											{ 
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}, 
											
											{ 
												type = "IMAGE",
												 image = 
									
												{ 
													value = "icon.png",
													imageType = "DYNAMIC",
												}, 
												softButtonID = 5,
												systemAction = "STEAL_FOCUS",
											}, 
										}
									
									})

				local AlertId
				--hmi side: UI.Alert request 
				EXPECT_HMICALL("UI.Alert", 
							{	
								alertStrings = 
								{
									{fieldName = "alertText1", fieldText = "alertText1"},
							        {fieldName = "alertText2", fieldText = "alertText2"},
							        {fieldName = "alertText3", fieldText = "alertText3"}
							    },
							    alertType = "BOTH",
								duration = 0,
								progressIndicator = true,
								softButtons = 
								{ 
									
									{ 
										type = "BOTH",
										text = "Close",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value =config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										isHighlighted = true,
										softButtonID = 3,
										systemAction = "DEFAULT_ACTION",
									}, 
									
									{ 
										type = "TEXT",
										text = "Keep",
										isHighlighted = true,
										softButtonID = 4,
										systemAction = "KEEP_CONTEXT",
									}, 
									
									{ 
										type = "IMAGE",
										  --[[ TODO: update after resolving APPLINK-16052

										 image = 
							
										{ 
											value = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/icon.png",
											imageType = "DYNAMIC",
										},]] 
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									}, 
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 3000)
					end)

				local SpeakId
				--hmi side: TTS.Speak request 
				EXPECT_HMICALL("TTS.Speak", 
							{	
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT"
									}
								},
								speakType = "ALERT",
								playTone = true
							})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 2000)

					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)
			 
				-- due to CRQ APPLINK-17388 this notification is commented out, playTone parameter is moved to TTS.Speak
				--hmi side: BC.PalayTone request 
				-- EXPECT_HMINOTIFICATION("BasicCommunication.PlayTone",{ methodName = "ALERT"})

				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self,_,_,"BACKGROUND")

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end	

		end

	--End Test suit DifferentHMIlevel
































