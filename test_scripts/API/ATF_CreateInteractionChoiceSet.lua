local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end

    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

DeleteLog_app_info_dat_policy()

Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
config.SDLStoragePath = config.pathToSDL .. "storage/"

local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	
local imageValues = {"a", "icon.png", "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTY"}
local infoMessage = string.rep("a",1000)
local applicationID
local grammarIDValue

require('user_modules/AppTypes')

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end
	

function Test:setChoiseSet(n,startID)
	temp = {}
	for i = 1, n do
	temp[i] = { 
			choiceID =startID+i-1,
			menuName ="Choice" .. startID+i-1,
			vrCommands = 
			{ 
				"Choice" .. startID+i-1,
			}, 
			image =
			{ 
				value ="icon.png",
				imageType ="STATIC",
			}, 
	  } 
	end
	return temp
end
function Test:setExpectParameter(startID, numberOfVrCommand)
	local expectParmas = {}
	for i = 1, numberOfVrCommand do		
	expectParmas[i] = { 
				cmdID = i+startID,
				appID = applicationID,
				type = "Choice",
				vrCommands = self:setVrCommands(numberOfVrCommand, i),
			} 
	end
end
function Test:setMaxChoiseSet(numberOfChoiceSet, startID, numberOfVrCommand)
        temp = {}
        for i = 1, numberOfChoiceSet do
        temp[i] = { 
		        choiceID =startID+i-1,
		        menuName =tostring(i)..string.rep("v",500-string.len(tostring(i))),
		        vrCommands = self:setVrCommands(numberOfVrCommand,i),
		        image =
		        { 
			        value =string.rep("a",255),
			        imageType ="STATIC",
		        },
				secondaryImage =
		        { 
			        value =string.rep("a",255),
			        imageType ="STATIC",
		        },
				secondaryText = tostring(i)..string.rep("s",500-string.len(tostring(i))),
				tertiaryText = tostring(i)..string.rep("t",500-string.len(tostring(i)))
		  } 
        end	
        return temp
end
function Test:setVrCommands(n,r)
	vrCommandValues = {}
		for i = 1, n do
			vrCommandValues[i] = { 
				tostring(i)..string.rep("v",99-string.len(tostring(i))-string.len(tostring(r)))..tostring(r)	
			} 
		end
	return vrCommandValues
end
function Test:setEXChoiseSet(n, startID)
	exChoiceSet = {}
	for i = 1, n do		
	exChoiceSet[i] =  {
		cmdID = startID+i-1, type = "Choice", vrCommands = {"Choice"..startID+i-1}
	}
	end
	return exChoiceSet
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		function Test:ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			applicationID = self.applications["Test Application"]
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})
			
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
	--End Precondition.1

	-----------------------------------------------------------------------------------------

	--Begin Precondition.2
	--Description: Putting file(PutFiles)
		function Test:PutFile()
			for i=1,#imageValues do
				local cid = self.mobileSession:SendRPC("PutFile",
				{			
					syncFileName = imageValues[i],
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")	
				EXPECT_RESPONSE(cid, { success = true})
			end
		end
	--End Precondition.2	
	---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

	--Description: TC's checks processing 
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
		--Description:This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA: 
					--SDLAQ-CRS-37	
					--SDLAQ-CRS-2976
					--SDLAQ-CRS-449

			--Verification criteria: 
					--Mandatory parameters "interactionChoiceSetID" and "choiceSet" are provided, interaction choice set is created.
					--SDL must wait for corresponding VR.AddCommand responses from HMI before responding CreateInteractionChoiceSet to mobile app.
					--SDL must respond with (resultCode: SUCCESS, success:true) for CreateInteractionChoiceSet to mobile app in case SDL successfully stores UI-related choices and gets successful responses to corresponding VR.AddCommands (VR-related choices) from HMI
					
			function Test:CreateInteractionChoiceSet_PositiveCase()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1001,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1001,
																		menuName ="Choice1001",
																		vrCommands = 
																		{ 
																			"Choice1001",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="DYNAMIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 1001,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice1001" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						grammarIDValue = data.params.grammarID
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-37	
					--SDLAQ-CRS-2976
					--SDLAQ-CRS-449				

			--Verification criteria: 
					--Mandatory parameters "interactionChoiceSetID" and "choiceSet" are provided, interaction choice set is created.
					--SDL must wait for corresponding VR.AddCommand responses from HMI before responding CreateInteractionChoiceSet to mobile app.
					--SDL must respond with (resultCode: SUCCESS, success:true) for CreateInteractionChoiceSet to mobile app in case SDL successfu
					
			function Test:CreateInteractionChoiceSet_MandatoryOnly()
				--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1002,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1002,
																		menuName ="Choice1002",
																		vrCommands = 
																		{ 
																			"Choice1002",
																		}
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 1002,										
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice1002" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")				
			end			
		--Begin Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-450				

			--Verification criteria: 
					--The request without "interactionChoiceSetID" is sent, the INVALID_DATA response code is returned.
					--The request without "choiceSet" is sent, the INVALID_DATA response code is returned.
					--The request without "choiceID" is sent, the INVALID_DATA response code is returned.
					--The request without "menuName" is sent, the INVALID_DATA response code is returned.
					--The request without "vrCommands" is sent, the INVALID_DATA response code is returned.
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: Mandatory missing - interactionChoiceSetID
				function Test:CreateInteractionChoiceSet_interactionChoiceSetIDMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1003,
																		menuName ="Choice1003",
																		vrCommands = 
																		{ 
																			"Choice1003",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.1
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.2
			--Description: Mandatory missing - choiceID
				function Test:CreateInteractionChoiceSet_choiceSetMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1004															
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.2
						
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.3
			--Description: Mandatory missing - choiceID
				function Test:CreateInteractionChoiceSet_choiceIDMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1005,
																choiceSet = 
																{ 
																	
																	{ 
																		menuName ="Choice1005",
																		vrCommands = 
																		{ 
																			"Choice1005",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.3
						
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.4
			--Description: Mandatory missing - menuName
				function Test:CreateInteractionChoiceSet_menuNameMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1006,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1006,
																		vrCommands = 
																		{ 
																			"Choice1006"
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC"
																		}
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.4
						
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.5
			--Description: Mandatory missing - vrCommands
				function Test:CreateInteractionChoiceSet_vrCommandsMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1007,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1007,
																		menuName ="Choice1007",																		
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.5
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.6
			--Description: Mandatory missing - image value
				function Test:CreateInteractionChoiceSet_imageValueMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1007,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1007,
																		menuName ="Choice1007",																		
																		image =
																		{ 																			
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.6
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.7
			--Description: Mandatory missing - imageType
				function Test:CreateInteractionChoiceSet_imageTypeMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1007,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1007,
																		menuName ="Choice1007",																		
																		image =
																		{ 	
																			value="icon.png"																			
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.7
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.8
			--Description: Mandatory missing - secondaryImage value
				function Test:CreateInteractionChoiceSet_secondaryImageValueMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1007,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1007,
																		menuName ="Choice1007",																		
																		secondaryImage =
																		{ 																			
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.8
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.9
			--Description: Mandatory missing - secondaryImage imageType
				function Test:CreateInteractionChoiceSet_secondaryImageTypeMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1007,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1007,
																		menuName ="Choice1007",																		
																		secondaryImage =
																		{ 	
																			value="icon.png"																			
																		}, 
																	}
																}
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.9
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.10
			--Description: All parameter missing
				function Test:CreateInteractionChoiceSet_AllParamsMissing()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
															
															})
														
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.10
			
		  --Begin Test case CommonRequestCheck.4
   
      function Test:CreateInteractionChoiceSet_InvalidImage()
          --mobile side: sending CreateInteractionChoiceSet request
          local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                              {
                                interactionChoiceSetID = 1108,
                                choiceSet = 
                                { 
                                  
                                  { 
                                    choiceID = 1108,
                                    menuName ="Choice1108",
                                    vrCommands = 
                                    { 
                                      "Choice1108",
                                    }, 
                                    image =
                                    { 
                                      value ="notavailable.png",
                                      imageType ="DYNAMIC",
                                    }, 
                                  }
                                }
                              })
          
            
          --hmi side: expect VR.AddCommand request
          EXPECT_HMICALL("VR.AddCommand", 
                  { 
                    cmdID = 1108,
                    appID = applicationID,
                    type = "Choice",
                    vrCommands = {"Choice1108" }
                  })
          :Do(function(_,data)
            --hmi side: sending VR.AddCommand response
            grammarIDValue = data.params.grammarID
            self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {info="Requested image(s) not found."})
          end)
          
          --mobile side: expect CreateInteractionChoiceSet response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",info="Requested image(s) not found." })

          --mobile side: expect OnHashChange notification
          EXPECT_NOTIFICATION("OnHashChange")
        end
    --End Test case CommonRequestCheck.4
    
    -----------------------------------------------------------------------------------------
			
		--Begin Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-4518
					
			--Verification criteria:
					--According to xml tests by Ford team all fake params should be ignored by SDL
			
			--Begin Test case CommonRequestCheck.4.1
			--Description: Parameter not from protocol					
				function Test:CreateInteractionChoiceSet_WithFakeParam()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1008,
																fakeParam = "fake parameter",
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1008,
																		menuName ="Choice1008",
																		vrCommands = 
																		{ 
																			"Choice1008",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		},																		
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 1008,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice1008" }
									})
					:Do(function(_,data)
						--hmi side: sending UI.CreateInteractionChoiceSet response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
								print(" SDL re-sends fakeParam parameters to HMI in UI.CreateInteractionChoiceSet request")
								return false
						else 
							return true
						end
					end)
						
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--Begin Test case CommonRequestCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
			function Test:CreateInteractionChoiceSet_ParamsAnotherRequest()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 1009,
															choiceSet = 
															{ 
																
																{ 
																	choiceID = 1009,
																	menuName ="Choice1009",
																	vrCommands = 
																	{ 
																		"Choice1009",
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	} 
																}
															},															
															ttsChunks = 
															{ 
																TTSChunk = 
																{ 
																	text ="SpeakFirst",
																	type ="TEXT",
																}, 
																TTSChunk = 
																{ 
																	text ="SpeakSecond",
																	type ="TEXT",
																}, 
															}
														})
				
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 1009,
									appID = applicationID,
									type = "Choice",
									vrCommands = {"Choice1009" }
								})
				:Do(function(_,data)
					--hmi side: sending UI.CreateInteractionChoiceSet response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:ValidIf(function(_,data)
					if data.params.ttsChunks then
							print(" SDL re-sends parameters of another request to HMI in UI.CreateInteractionChoiceSet request")
							return false
					else 
						return true
					end
				end)
					
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")		
			end			
			--End Test case CommonRequestCheck.4.2
			
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-450

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:CreateInteractionChoiceSet_IncorrectJSON()
				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 9,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"choiceSet" [{"vrCommands":["Choice1009"],"image":{"value":"icon.png","imageType":"DYNAMIC"},"choiceID":1009,"menuName":"Choice1009"}],"interactionChoiceSetID":1009}'
				}
				self.mobileSession:Send(msg)
				EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })		
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)			
			end			
		--End Test case CommonRequestCheck.5
		
		
		-----------------------------------------------------------------------------------------
--[[TODO: Requirement and Verification criteria need to be updated. Check if APPLINK-13892 is resolved
		--Begin Test case CommonRequestCheck.6
		--Description: different conditions of correlationID parameter

			--Requirement id in JAMA:
			--Verification criteria: duplicate correlationID
			
				function Test:CreateInteractionChoiceSet_DuplicateCorrelationId()					
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 150,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 150,
																		menuName ="Choice150",
																		vrCommands = 
																		{ 
																			"Choice150",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="DYNAMIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 150,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice150" }
									},
									{ 
										cmdID = 151,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice151" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						grammarIDValue = data.params.grammarID
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(2)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:Times(2)
					:Do(function(exp,data)
						if exp.occurrences == 1 then	
							local msg = 
							{
								serviceType      = 7,
								frameInfo        = 0,
								rpcType          = 0,
								rpcFunctionId    = 9,
								rpcCorrelationId = cid,					
								payload          = '{"choiceSet":[{"vrCommands":["Choice151"],"image":{"value":"icon.png","imageType":"DYNAMIC"},"choiceID":151,"menuName":"Choice151"}],"interactionChoiceSetID":151}'
							}
							self.mobileSession:Send(msg)								
						end
					end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(2)						
				end
				
]]			
		--End Test case CommonRequestCheck.6		
	--End Test suit PositiveRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: Check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check parameter with lower and upper bound values 

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-37
							-- SDLAQ-CRS-449

				--Verification criteria: 
							-- Mandatory parameters "interactionChoiceSetID" and "choiceSet" are provided, interaction choice set is created.
							-- SDL must respond with (resultCode: SUCCESS, success:true) for CreateInteractionChoiceSet to mobile app in case SDL successfully stores UI-related choices and gets successful responses to corresponding VR.AddCommands (VR-related choices) from HMI

				--Begin Test case PositiveRequestCheck.1.1
				--Description: lower bound all parameter
					function Test:CreateInteractionChoiceSet_LowerBoundAllParams()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 0,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 0,
																			menuName ="A",
																			vrCommands = 
																			{ 
																				"V",
																			}, 
																			image =
																			{ 
																				value ="a",
																				imageType ="STATIC",
																			},
																			secondaryText = "S",
																			tertiaryText = "T",
																			secondaryImage =
																			{ 
																				value ="a",
																				imageType ="STATIC",
																			}
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 0,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"V" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					
					function Test:PostCondition_DeleteChoiceSet()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet", 
						{ 
							interactionChoiceSetID = 0,
						})
						
						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")						
					end
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: choice set ID lower bound
					function Test:CreateInteractionChoiceSet_ChoiceSetIDLowerBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 0,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1012,
																			menuName ="Choice1012",
																			vrCommands = 
																			{ 
																				"Choice1012",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1012,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1012" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.2
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: choice set ID in bound
					function Test:CreateInteractionChoiceSet_ChoiceSetIDInBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1000000000,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1013,
																			menuName ="Choice1013",
																			vrCommands = 
																			{ 
																				"Choice1013",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1013,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1013" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.3
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: choice set ID upper bound
					function Test:CreateInteractionChoiceSet_ChoiceSetIDUpperBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 2000000000,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1014,
																			menuName ="Choice1014",
																			vrCommands = 
																			{ 
																				"Choice1014",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1014,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1014" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
									
					function Test:PostCondition_DeleteChoiceSet()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet", 
						{ 
							interactionChoiceSetID = 2000000000,
						})
						
						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.4
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: choice ID lower bound
					function Test:CreateInteractionChoiceSet_ChoiceIDLowerBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1015,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 0,
																			menuName ="Choice1015",
																			vrCommands = 
																			{ 
																				"Choice1015",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 0,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1015" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.5
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: choice ID in bound
					function Test:CreateInteractionChoiceSet_ChoiceIDInBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1016,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 3333,
																			menuName ="Choice1016",
																			vrCommands = 
																			{ 
																				"Choice1016",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 3333,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1016" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.6
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: choice ID upper bound
					function Test:CreateInteractionChoiceSet_ChoiceIDUpperBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1017,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 65535,
																			menuName ="Choice1017",
																			vrCommands = 
																			{ 
																				"Choice1017",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 65535,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1017" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.7
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.8
				--Description: menu name lower bound
					function Test:CreateInteractionChoiceSet_MenuNameLowerBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1018,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1018,
																			menuName ="m",
																			vrCommands = 
																			{ 
																				"Choice1018",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1018,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1018" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.8
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.9
				--Description: menu name in bound
					function Test:CreateInteractionChoiceSet_MenuNameInBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1019,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1019,
																			menuName ="Menu Name",
																			vrCommands = 
																			{ 
																				"Choice1019",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1019,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1019" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.9
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.10
				--Description: menu name upper bound
					function Test:CreateInteractionChoiceSet_MenuNameUpperBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1020,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1020,
																			menuName ="nnn\\b\\rnt\\u\\f'cdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgaaaa",
																			vrCommands = 
																			{ 
																				"Choice1020",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1020,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1020" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.10
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.11
				--Description: vrCommandsArray lower bound
					function Test:CreateInteractionChoiceSet_vrCommandsArrayLowerBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1021,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1021,
																			menuName ="Choice1021",
																			vrCommands = 
																			{ 
																				"Choice1021",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1021,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1021" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.11
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.12
				--Description: vrCommandsArray in bound
					function Test:CreateInteractionChoiceSet_vrCommandsArrayInBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1022,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1022,
																			menuName ="Choice1022",
																			vrCommands = 
																			{ 
																				"Choice10221",
																				"Choice10222",
																				"Choice10223",
																				"Choice10224",
																				"Choice10225"																				
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1022,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice10221", "Choice10222", "Choice10223", "Choice10224", "Choice10225" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.12
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.13
				--Description: vrCommandsArray upper bound
					function Test:CreateInteractionChoiceSet_vrCommandsArrayUpperBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1023,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1023,
																			menuName ="Choice1023",
																			vrCommands = 
																			{ 
																				"1Choice1023",
																				"2Choice1023",
																				"3Choice1023",
																				"4Choice1023",
																				"5Choice1023",
																				"6Choice1023",
																				"7Choice1023",
																				"8Choice1023",
																				"9Choice1023",
																				"10Choice1023",
																				"11Choice1023",
																				"12Choice1023",
																				"13Choice1023",
																				"14Choice1023",
																				"15Choice1023",
																				"16Choice1023",
																				"17Choice1023",
																				"18Choice1023",
																				"19Choice1023",
																				"20Choice1023",
																				"21Choice1023",
																				"22Choice1023",
																				"23Choice1023",
																				"24Choice1023",
																				"25Choice1023",
																				"26Choice1023",
																				"27Choice1023",
																				"28Choice1023",
																				"29Choice1023",
																				"30Choice1023",
																				"31Choice1023",
																				"32Choice1023",
																				"33Choice1023",
																				"34Choice1023",
																				"35Choice1023",
																				"36Choice1023",
																				"37Choice1023",
																				"38Choice1023",
																				"39Choice1023",
																				"40Choice1023",
																				"41Choice1023",
																				"42Choice1023",
																				"43Choice1023",
																				"44Choice1023",
																				"45Choice1023",
																				"46Choice1023",
																				"47Choice1023",
																				"48Choice1023",
																				"49Choice1023",
																				"50Choice1023",
																				"51Choice1023",
																				"52Choice1023",
																				"53Choice1023",
																				"54Choice1023",
																				"55Choice1023",
																				"56Choice1023",
																				"57Choice1023",
																				"58Choice1023",
																				"59Choice1023",
																				"60Choice1023",
																				"61Choice1023",
																				"62Choice1023",
																				"63Choice1023",
																				"64Choice1023",
																				"65Choice1023",
																				"66Choice1023",
																				"67Choice1023",
																				"68Choice1023",
																				"69Choice1023",
																				"70Choice1023",
																				"71Choice1023",
																				"72Choice1023",
																				"73Choice1023",
																				"74Choice1023",
																				"75Choice1023",
																				"76Choice1023",
																				"77Choice1023",
																				"78Choice1023",
																				"79Choice1023",
																				"80Choice1023",
																				"81Choice1023",
																				"82Choice1023",
																				"83Choice1023",
																				"84Choice1023",
																				"85Choice1023",
																				"86Choice1023",
																				"87Choice1023",
																				"88Choice1023",
																				"89Choice1023",
																				"90Choice1023",
																				"91Choice1023",
																				"92Choice1023",
																				"93Choice1023",
																				"94Choice1023",
																				"95Choice1023",
																				"96Choice1023",
																				"97Choice1023",
																				"98Choice1023",
																				"99Choice1023",
																				"100Choice1023"																		
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1023,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"1Choice1023",
														"2Choice1023",
														"3Choice1023",
														"4Choice1023",
														"5Choice1023",
														"6Choice1023",
														"7Choice1023",
														"8Choice1023",
														"9Choice1023",
														"10Choice1023",
														"11Choice1023",
														"12Choice1023",
														"13Choice1023",
														"14Choice1023",
														"15Choice1023",
														"16Choice1023",
														"17Choice1023",
														"18Choice1023",
														"19Choice1023",
														"20Choice1023",
														"21Choice1023",
														"22Choice1023",
														"23Choice1023",
														"24Choice1023",
														"25Choice1023",
														"26Choice1023",
														"27Choice1023",
														"28Choice1023",
														"29Choice1023",
														"30Choice1023",
														"31Choice1023",
														"32Choice1023",
														"33Choice1023",
														"34Choice1023",
														"35Choice1023",
														"36Choice1023",
														"37Choice1023",
														"38Choice1023",
														"39Choice1023",
														"40Choice1023",
														"41Choice1023",
														"42Choice1023",
														"43Choice1023",
														"44Choice1023",
														"45Choice1023",
														"46Choice1023",
														"47Choice1023",
														"48Choice1023",
														"49Choice1023",
														"50Choice1023",
														"51Choice1023",
														"52Choice1023",
														"53Choice1023",
														"54Choice1023",
														"55Choice1023",
														"56Choice1023",
														"57Choice1023",
														"58Choice1023",
														"59Choice1023",
														"60Choice1023",
														"61Choice1023",
														"62Choice1023",
														"63Choice1023",
														"64Choice1023",
														"65Choice1023",
														"66Choice1023",
														"67Choice1023",
														"68Choice1023",
														"69Choice1023",
														"70Choice1023",
														"71Choice1023",
														"72Choice1023",
														"73Choice1023",
														"74Choice1023",
														"75Choice1023",
														"76Choice1023",
														"77Choice1023",
														"78Choice1023",
														"79Choice1023",
														"80Choice1023",
														"81Choice1023",
														"82Choice1023",
														"83Choice1023",
														"84Choice1023",
														"85Choice1023",
														"86Choice1023",
														"87Choice1023",
														"88Choice1023",
														"89Choice1023",
														"90Choice1023",
														"91Choice1023",
														"92Choice1023",
														"93Choice1023",
														"94Choice1023",
														"95Choice1023",
														"96Choice1023",
														"97Choice1023",
														"98Choice1023",
														"99Choice1023",
														"100Choice1023"}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.13
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.14
				--Description: vrCommands boundary check (maxlength=99)
					function Test:CreateInteractionChoiceSet_vrCommandsBoundary()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1024,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1024,
																			menuName ="Choice1024",
																			vrCommands = 
																			{ 
																				"J",
																				"fdlkhjksdahfkjhsakjfh",
																				"nnn01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY'!@#$%^*()-_+|~{}[]:,nn\\b\\rnt\\uaaa",																	
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1024,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"J",
												"fdlkhjksdahfkjhsakjfh",
												"nnn01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY'!@#$%^*()-_+|~{}[]:,nn\\b\\rnt\\uaaa",
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.14
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.15
				--Description: imageValue boundary check
					function Test:CreateInteractionChoiceSet_imageValueBoundary()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1025,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1025,
																			menuName ="Choice1025",
																			vrCommands = 
																			{ 
																				"Choice1025"
																			}, 
																			image =
																			{ 
																				value ="a",
																				imageType ="STATIC",
																			}, 
																		},
																		{ 
																			choiceID = 1026,
																			menuName ="Choice1026",
																			vrCommands = 
																			{ 
																				"Choice1026"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		},
																		{ 
																			choiceID = 1027,
																			menuName ="Choice1027",
																			vrCommands = 
																			{ 
																				"Choice1027"
																			}, 
																			image =
																			{ 
																				value ="qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTY",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1025,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1025"
											}
										},
										{ 
											cmdID = 1026,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1026"
											}
										},										
										{ 
											cmdID = 1027,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1027"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(3)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.15
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.16
				--Description: secondaryText boundary check
					function Test:CreateInteractionChoiceSet_secondaryTextBoundary()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1028,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1028,
																			menuName ="Choice1028",
																			vrCommands = 
																			{ 
																				"Choice1028"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "s"
																		},
																		{ 
																			choiceID = 1029,
																			menuName ="Choice1029",
																			vrCommands = 
																			{ 
																				"Choice1029"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "secondaryText"
																		},
																		{ 
																			choiceID = 1030,
																			menuName ="Choice1030",
																			vrCommands = 
																			{ 
																				"Choice1030"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																			secondaryText = "aaaannn\\b\\rnt\\u\\f'cdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg"
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1028,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1028"
											}
										},
										{ 
											cmdID = 1029,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1029"
											}
										},										
										{ 
											cmdID = 1030,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1030"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(3)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.16
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.17
				--Description: tertiaryText boundary check
					function Test:CreateInteractionChoiceSet_tertiaryTextBoundary()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1031,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1031,
																			menuName ="Choice1031",
																			vrCommands = 
																			{ 
																				"Choice1031"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "s"
																		},
																		{ 
																			choiceID = 1032,
																			menuName ="Choice1032",
																			vrCommands = 
																			{ 
																				"Choice1032"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "secondaryText"
																		},
																		{ 
																			choiceID = 1033,
																			menuName ="Choice1033",
																			vrCommands = 
																			{ 
																				"Choice1033"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																			tertiaryText = "aaaannn\\b\\rnt\\u\\f'cdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg"
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1031,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1031"
											}
										},
										{ 
											cmdID = 1032,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1032"
											}
										},										
										{ 
											cmdID = 1033,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1033"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(3)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.17
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.18
				--Description: secondaryImage boundary check
					function Test:CreateInteractionChoiceSet_secondaryImageBoundary()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1034,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1034,
																			menuName ="Choice1034",
																			vrCommands = 
																			{ 
																				"Choice1034"
																			}, 
																			secondaryImage =
																			{ 
																				value ="a",
																				imageType ="STATIC",
																			}, 
																		},
																		{ 
																			choiceID = 1035,
																			menuName ="Choice1035",
																			vrCommands = 
																			{ 
																				"Choice1035"
																			}, 
																			secondaryImage =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		},
																		{ 
																			choiceID = 1036,
																			menuName ="Choice1036",
																			vrCommands = 
																			{ 
																				"Choice1036"
																			}, 
																			secondaryImage =
																			{ 
																				value ="qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTY",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1034,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1034"
											}
										},
										{ 
											cmdID = 1035,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1035"
											}
										},										
										{ 
											cmdID = 1036,
											appID = applicationID,
											type = "Choice",
											vrCommands = 
											{
												"Choice1036"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(3)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end				
				--End Test case PositiveRequestCheck.1.18
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.19
				--Description: choiceSet - array lower bound  				
					function Test:CreateInteractionChoiceSet_ChoiceSetArrayLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1035,
																	choiceSet = self:setChoiseSet(1,600),
																})
						
						EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 600,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice600" }
									})
						:Do(function(_,data)						
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end					
				--End Test case PositiveRequestCheck.1.19
				
				-------------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.20
				--Description: choiceSet - array upper bound  				
					function Test:CreateInteractionChoiceSet_ChoiceSetArrayUpperBound()
						local startID = 700
						local numberOfVrCommand = 1
						local numberOfChoiceSet = 100
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1036,
																	choiceSet = self:setChoiseSet(numberOfChoiceSet,startID,numberOfVrCommand),
																})
						
						EXPECT_HMICALL("VR.AddCommand", self:setExpectParameter(startID, numberOfVrCommand))
						:Do(function(_,data)						
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(100)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end					
				--End Test case PositiveRequestCheck.1.20

				-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13468	 Move ATC_CreateInteractionChoiceSet_UpperBound(SDLAQ-TC-173) to folser ManualAutomatedTC_covered_byATFscripts(APPLINK-12704)			
				--Begin Test case PositiveRequestCheck.1.20
				--Description: upper bound all parameters
					function Test:CreateInteractionChoiceSet_UpperBoundAllParams()
						local numberOfVrCommand = 100
						local numberOfChoiceSet = 100
						local startID = 65435
						
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", 
						{ 
							interactionChoiceSetID = 65535,
							choiceSet = self:setMaxChoiseSet(numberOfChoiceSet, startID, numberOfVrCommand)
						})
								
						EXPECT_HMICALL("VR.AddCommand",self:setExpectParameter(startID, numberOfVrCommand))
						:Do(function(_,data)			
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(numberOfChoiceSet)
								
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end					
				--End Test case PositiveRequestCheck.1.20				
			--End Test case PositiveRequestCheck.1			
		--End Test suit PositiveRequestCheck
]]

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA: SDLAQ-CRS-38

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case PositiveResponseCheck.1.1
				--Description: info parameter lower bound	
					function Test:CreateInteractionChoiceSet_InfoLowerBound() 
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 128,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 128,
																			menuName ="Choice128",
																			vrCommands = 
																			{ 
																				"Choice128",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="DYNAMIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 128,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice128" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							grammarIDValue = data.params.grammarID
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR","a")
						end)
						
						--UPDATED: according to APPLINK-16281
						--mobile side: expect CreateInteractionChoiceSet response
						--EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a" })
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")	
						:Times(0)
					end
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.2
				--Description: info parameter upper bound
					function Test:CreateInteractionChoiceSet_InfoUpperBound()						
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 127,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 127,
																			menuName ="Choice127",
																			vrCommands = 
																			{ 
																				"Choice127",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="DYNAMIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 127,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice127" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							grammarIDValue = data.params.grammarID
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)
						
						--UPDATED: according to APPLINK-16281
						--mobile side: expect CreateInteractionChoiceSet response
						--EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")	
						:Times(0)				
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

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values 

				--Requirement id in JAMA:
					--SDLAQ-CRS-450
					
				--Verification criteria:
					-- The request with "interactionChoiceSetID" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "interactionChoiceSetID" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "choiceSet" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "choiceID" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "menuName" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrCommands" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "image" value parameter out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrCommands" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "image type" out of enum is sent, the INVALID_DATA response code is returned.
					-- The request with empty "choiceSet" is sent, the INVALID_DATA response code is returned.
					-- The request with empty "menuName" is sent, the INVALID_DATA response code is returned.
					-- The request with empty "vrCommands" is sent, the INVALID_DATA response code is returned.
					-- The request with empty "image" value is sent, the INVALID_DATA response code is returned.
					
				--Begin Test case NegativeRequestCheck.1.1
				--Description: interactionChoiceSetID - out lower bound  				
					function Test:CreateInteractionChoiceSet_ChoiceSetIDOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = -1,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1039,
																			menuName ="Choice1039",
																			vrCommands = 
																			{ 
																				"Choice1039",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.2
				--Description: interactionChoiceSetID - out upper bound  				
					function Test:CreateInteractionChoiceSet_ChoiceSetIDOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 2000000001,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1039,
																			menuName ="Choice1039",
																			vrCommands = 
																			{ 
																				"Choice1039",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.2			
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.3
				--Description: choiceSet - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_ChoiceSetOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1040,
																	choiceSet = 
																	{ 
																	},
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.4
				--Description: choiceSet - out upper bound  				
					function Test:CreateInteractionChoiceSet_ChoiceSetOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1040,
																	choiceSet = self:setChoiseSet(101,700),
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.4		
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.5
				--Description: choice - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_ChoiceEmpty()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1040,
																	choiceSet =
																	{
																		{},
																	},
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.6
				--Description: choiceID - out upper bound  				
					function Test:CreateInteractionChoiceSet_ChoiceIDOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = -1,
																			menuName ="Choice1041",
																			vrCommands = 
																			{ 
																				"Choice1041",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.6	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.7
				--Description: choiceID - out upper bound  				
					function Test:CreateInteractionChoiceSet_ChoiceIDOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 65536,
																			menuName ="Choice1041",
																			vrCommands = 
																			{ 
																				"Choice1041",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.8
				--Description: menuName - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_MenuNameOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="",
																			vrCommands = 
																			{ 
																				"Choice1041",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.9
				--Description: menuName - out upper bound
					function Test:CreateInteractionChoiceSet_MenuNameOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="34567890123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
																			vrCommands = 
																			{ 
																				"Choice1041",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.10
				--Description: vrCommandArray - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_vrCommandsArrayOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{ 
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.11
				--Description: vrCommandArray - out upper bound
					function Test:CreateInteractionChoiceSet_vrCommandsArrayOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"1Choice904",
																				"2Choice904",
																				"3Choice904",
																				"4Choice904",
																				"5Choice904",
																				"6Choice904",
																				"7Choice904",
																				"8Choice904",
																				"9Choice904",
																				"10Choice904",
																				"11Choice904",
																				"12Choice904",
																				"13Choice904",
																				"14Choice904",
																				"15Choice904",
																				"16Choice904",
																				"17Choice904",
																				"18Choice904",
																				"19Choice904",
																				"20Choice904",
																				"21Choice904",
																				"22Choice904",
																				"23Choice904",
																				"24Choice904",
																				"25Choice904",
																				"26Choice904",
																				"27Choice904",
																				"28Choice904",
																				"29Choice904",
																				"30Choice904",
																				"31Choice904",
																				"32Choice904",
																				"33Choice904",
																				"34Choice904",
																				"35Choice904",
																				"36Choice904",
																				"37Choice904",
																				"38Choice904",
																				"39Choice904",
																				"40Choice904",
																				"41Choice904",
																				"42Choice904",
																				"43Choice904",
																				"44Choice904",
																				"45Choice904",
																				"46Choice904",
																				"47Choice904",
																				"48Choice904",
																				"49Choice904",
																				"50Choice904",
																				"51Choice904",
																				"52Choice904",
																				"53Choice904",
																				"54Choice904",
																				"55Choice904",
																				"56Choice904",
																				"57Choice904",
																				"58Choice904",
																				"59Choice904",
																				"60Choice904",
																				"61Choice904",
																				"62Choice904",
																				"63Choice904",
																				"64Choice904",
																				"65Choice904",
																				"66Choice904",
																				"67Choice904",
																				"68Choice904",
																				"69Choice904",
																				"70Choice904",
																				"71Choice904",
																				"72Choice904",
																				"73Choice904",
																				"74Choice904",
																				"75Choice904",
																				"76Choice904",
																				"77Choice904",
																				"78Choice904",
																				"79Choice904",
																				"80Choice904",
																				"81Choice904",
																				"82Choice904",
																				"83Choice904",
																				"84Choice904",
																				"85Choice904",
																				"86Choice904",
																				"87Choice904",
																				"88Choice904",
																				"89Choice904",
																				"90Choice904",
																				"91Choice904",
																				"92Choice904",
																				"93Choice904",
																				"94Choice904",
																				"95Choice904",
																				"96Choice904",
																				"97Choice904",
																				"98Choice904",
																				"99Choice904",
																				"100Choice904",
																				"101Choice904"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.12
				--Description: vrCommand - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_vrCommandsOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				""
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.13
				--Description: vrCommand - out upper bound
					function Test:CreateInteractionChoiceSet_vrCommandsOutUpperBound()
					local vrUpperBound = string.rep("a", 101)
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				vrUpperBound
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.13
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.14
				--Description: imageValue - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_imageValueOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"Choice1041"
																			}, 
																			image =
																			{ 
																				value ="",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.15
				--Description: secondaryText - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_secondaryTextOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"Choice1041"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = ""
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.15
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.16
				--Description: secondaryText - out upper bound
					function Test:CreateInteractionChoiceSet_secondaryTextOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"Choice1041"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.17
				--Description: tertiaryText - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_tertiaryTextOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"Choice1041"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = ""
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.17
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.18
				--Description: tertiaryText - out upper bound
					function Test:CreateInteractionChoiceSet_tertiaryTextOutUpperBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1041,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1041,
																			menuName ="Choice1041",
																			vrCommands = 
																			{
																				"Choice1041"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.18
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.20
				--Description: secondaryImage - empty (out lower bound)
					function Test:CreateInteractionChoiceSet_secondaryImageValueOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{
																				"Choice1042"
																			}, 
																			secondaryImage =
																			{ 
																				value ="",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.20
				
				
			--End Test case NegativeRequestCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values
			
				--Requirement id in JAMA:
					--SDLAQ-CRS-450
					
				--Verification criteria:
						-- The request with empty "interactionChoiceSetID" value is sent, the INVALID_DATA response code is returned. 						
						-- The request with empty "choiceID" is sent, the INVALID_DATA response code is returned.						
						-- The request with empty "image" structure is sent, the INVALID_DATA response code is returned.
				
				--Begin Test case NegativeRequestCheck.2.1
				--Description: "image" structure - empty
					function Test:CreateInteractionChoiceSet_imageStructureEmpty()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{
																				"Choice1042"
																			}, 
																			image =
																			{ 																				
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.2
				--Description: imageType empty
					function Test:CreateInteractionChoiceSet_imageTypeEmpty()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{
																				"Choice1042"
																			}, 
																			image =
																			{ 	
																				value = "icon.png",
																				imageType = ""
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.2.2
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.3
				--Description: "secondaryImage" structure - empty
					function Test:CreateInteractionChoiceSet_secondaryImageStructureEmpty()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{
																				"Choice1042"
																			}, 
																			secondaryImage =
																			{ 																				
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.2.3
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.4
				--Description: "secondaryImage" type - empty
					function Test:CreateInteractionChoiceSet_secondaryImageTypeEmpty()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{
																				"Choice1042"
																			}, 
																			secondaryImage =
																			{ 			
																				value = "icon.png",
																				imageType = ""
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.2.4
				
			--End Test case NegativeRequestCheck.2
						
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.3
			--Description: check processing requests with wrong type of parameters

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-450

				--Verification criteria: 
							-- The request with wrong data in "interactionChoiceSetID" parameter (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
							-- The request with wrong data in "choiceID" parameter (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
							-- The request with wrong data in "Choice" structure (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
							-- The request with wrong data in "menuName" parameter (e.g. Integer data type) is sent, the INVALID_DATA response code is returned.
							-- The request with wrong data in "vrCommand" value (e.g. Integer data type) is sent, the INVALID_DATA response code is returned.
				
				--Begin Test case NegativeRequestCheck.3.1
				--Description: interactionChoiceSetID wrong type
					function Test:CreateInteractionChoiceSet_interactionChoiceSetIDWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = "1042",
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.2
				--Description: choiceID wrong type
					function Test:CreateInteractionChoiceSet_choiceIDWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = "1042",
																			menuName ="Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.3
				--Description: menuName wrong type
					function Test:CreateInteractionChoiceSet_menuNameWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = 1042,
																			vrCommands = 
																			{ 
																				"Choice1042",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.4
				--Description: vrCommand wrong type
					function Test:CreateInteractionChoiceSet_vrCommandWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				1042
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.5
				--Description: choice structure wrong type
					function Test:CreateInteractionChoiceSet_choiceStructureWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		},
																		"Choice 2"
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.6
				--Description: image value wrong type
					function Test:CreateInteractionChoiceSet_imageValueWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = 123,
																				imageType ="STATIC",
																			}, 
																		},
																		"Choice 2"
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.7
				--Description: secondaryImage value wrong type
					function Test:CreateInteractionChoiceSet_secondaryImageValueWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			secondaryImage =
																			{ 
																				value = 123,
																				imageType ="STATIC",
																			}, 
																		},
																		"Choice 2"
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.8
				--Description: secondaryText value wrong type
					function Test:CreateInteractionChoiceSet_secondaryTextWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = 123
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.9
				--Description: tertiaryText value wrong type
					function Test:CreateInteractionChoiceSet_tertiaryTextWrongType()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = 123
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.9
								
			--End Test case PositiveRequestCheck.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing requests with nonexistent values

				--Requirement id in JAMA:
					--SDLAQ-CRS-450
					
				--Verification criteria:
					--  SDL must respond with INVALID_DATA resultCode in case CreateInteractionChoiceSet request comes with parameters out of bounds (number or enum range)
				
				--Begin Test case NegativeRequestCheck.4.1
				--Description: imageType non existed
					function Test:CreateInteractionChoiceSet_imageTypeNonExisted()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="ANY",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.4.2
				--Description: secondaryImage imageType non existed
					function Test:CreateInteractionChoiceSet_secondaryImageTypeNonExisted()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			secondaryImage =
																			{ 
																				value = "icon.png",
																				imageType ="ANY",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.2
				
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with Special characters

				--Requirement id in JAMA:
					--SDLAQ-CRS-450
					
				--Verification criteria:
					--  SDL responds with INVALID_DATA resultCode in case CreateInteractionChoiceSet request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in  "menuName" parameter of "Choice" structure.
					--  SDL responds with INVALID_DATA resultCode in case CreateInteractionChoiceSet request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in  "vrCommands" parameter of "Choice" structure.
					--  SDL responds with INVALID_DATA resultCode in case CreateInteractionChoiceSet request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in  "secondaryText" parameter of "Choice" structure.
					--  SDL responds with INVALID_DATA resultCode in case CreateInteractionChoiceSet request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in  "tertiaryText" parameter of "Choice" structure.
				
				--Begin Test case NegativeRequestCheck.5.1
				--Description: Escape sequence \n in menuName 
					function Test:CreateInteractionChoiceSet_menuNameNewLineChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042\n",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.2
				--Description: Escape sequence \t in menuName 
					function Test:CreateInteractionChoiceSet_menuNameNewTabChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042\t",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.3
				--Description: whitespace only in menuName
					function Test:CreateInteractionChoiceSet_menuNameWhiteSpaceOnly()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "      ",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.4
				--Description: Escape sequence \n in vrCommands 
					function Test:CreateInteractionChoiceSet_vrCommandsNewLineChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042\n"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.5
				--Description: Escape sequence \t in vrCommands 
					function Test:CreateInteractionChoiceSet_vrCommandsNewTabChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042\t"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.6
				--Description: whitespace only in vrCommands
					function Test:CreateInteractionChoiceSet_vrCommandsWhiteSpaceOnly()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"        "
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			}
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.7
				--Description: Escape sequence \n in secondaryText 
					function Test:CreateInteractionChoiceSet_secondaryTextNewLineChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "secondaryText\n"
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.8
				--Description: Escape sequence \t in secondaryText 
					function Test:CreateInteractionChoiceSet_vrCommandsNewTabChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "secondaryText\t"
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.9
				--Description: whitespace only in secondaryText
					function Test:CreateInteractionChoiceSet_secondaryTextWhiteSpaceOnly()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			secondaryText = "        "
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.10
				--Description: Escape sequence \n in tertiaryText 
					function Test:CreateInteractionChoiceSet_tertiaryTextNewLineChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "tertiaryText\n"
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.11
				--Description: Escape sequence \t in tertiaryText 
					function Test:CreateInteractionChoiceSet_tertiaryTextNewTabChar()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "tertiaryText\t"
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.12
				--Description: whitespace only in tertiaryText
					function Test:CreateInteractionChoiceSet_tertiaryTextWhiteSpaceOnly()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName = "Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042"
																			}, 
																			image =
																			{ 
																				value = "icon.png",
																				imageType ="STATIC",
																			},
																			tertiaryText = "        "
																		},																		
																	}
																})
															
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.12
				
			--End Test case NegativeRequestCheck.5
			
	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
--[[TODO update according to APPLINK-14765
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-29
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with nonexistent resultCode 
					function Test: CreateInteractionChoiceSet_ResultCodeNotExist()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1042,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1042,
																			menuName ="Choice1042",
																			vrCommands = 
																			{ 
																				"Choice1042",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1042,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1042" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test: CreateInteractionChoiceSet_MethodOutLowerBound()
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1043,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1043,
																			menuName ="Choice1043",
																			vrCommands = 
																			{ 
																				"Choice1043",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1043,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1043" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.2
				
			--End Test case NegativeResponseCheck.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-29
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters				
					function Test: CreateInteractionChoiceSet_ResponseMissingAllPArameters()					
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1045,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1045,
																			menuName ="Choice1045",
																			vrCommands = 
																			{ 
																				"Choice1045",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1042,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1042" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{}')
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter			
					function Test: CreateInteractionChoiceSet_MethodMissing()					
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1046,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1046,
																			menuName ="Choice1046",
																			vrCommands = 
																			{ 
																				"Choice1046",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1046,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1046" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter
					function Test: CreateInteractionChoiceSet_ResultCodeMissing()					
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1047,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1047,
																			menuName ="Choice1047",
																			vrCommands = 
																			{ 
																				"Choice1047",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1047,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1047" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand"}}')
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.4
				--Description: Check processing response without mandatory parameters				
					function Test: CreateInteractionChoiceSet_ResponseMissingAllMandatory()					
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
																{
																	interactionChoiceSetID = 1045,
																	choiceSet = 
																	{ 
																		
																		{ 
																			choiceID = 1045,
																			menuName ="Choice1045",
																			vrCommands = 
																			{ 
																				"Choice1045",
																			}, 
																			image =
																			{ 
																				value ="icon.png",
																				imageType ="STATIC",
																			}, 
																		}
																	}
																})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1042,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1042" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.4
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-29
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check processing response with wrong type of method
					function Test:CreateInteractionChoiceSet_MethodWrongtype() 
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1048,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1048,
													menuName ="Choice1048",
													vrCommands = 
													{ 
														"Choice1048",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1048,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1048" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", { })
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check processing response with wrong type of resultCode
					function Test:CreateInteractionChoiceSet_ResultCodeWrongtype() 
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1049,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1049,
													menuName ="Choice1049",
													vrCommands = 
													{ 
														"Choice1049",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1049,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1049" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":true}}')
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end				
				--End Test case NegativeResponseCheck.3.2				
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-29
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				function Test: CreateInteractionChoiceSet_ResponseInvalidJson()	
					--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1051,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1051,
													menuName ="Choice1051",
													vrCommands = 
													{ 
														"Choice1051",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1051,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1051" }
										})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						--<<!-- missing ':'
						self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":0}}')
					end)
						
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end				
			--End Test case NegativeResponseCheck.4
			]]
			-----------------------------------------------------------------------------------------
	--[[TODO: Update after resolving APPLINK-14551
			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-29, APPLINK-13276, APPLINK-14551
				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type
				
				--Begin Test Case NegativeResponseCheck5.1
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: CreateInteractionChoiceSet_InfoOutLowerBound()	
						--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1055,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1055,
													menuName ="Choice1055",
													vrCommands = 
													{ 
														"Choice1055",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1055,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1055" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.1
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.2
				--Description: In case info out of upper bound it should truncate to 1000 symbols
					function Test: CreateInteractionChoiceSet_InfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1056,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1056,
													menuName ="Choice1056",
													vrCommands = 
													{ 
														"Choice1056",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1056,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1056" }
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(CorIdCreateInteractionChoiceSet, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End Test Case NegativeResponseCheck5.2
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.3
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: CreateInteractionChoiceSet_InfoWrongType()												
						--mobile side: send CreateInteractionChoiceSet request 	 	
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1057,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1057,
													menuName ="Choice1057",
													vrCommands = 
													{ 
														"Choice1057",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1057,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1057" }
										})
						:Do(function(_,data)
							--hmi side: send Navigation.CreateInteractionChoiceSet response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(CorIdCreateInteractionChoiceSet, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.3
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.4
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: CreateInteractionChoiceSet_InfoWithNewlineChar()						
						--mobile side: send CreateInteractionChoiceSet request 	 	
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1058,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1058,
													menuName ="Choice1058",
													vrCommands = 
													{ 
														"Choice1058",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1058,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1058" }
										})
						:Do(function(_,data)
							--hmi side: send Navigation.CreateInteractionChoiceSet response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(CorIdCreateInteractionChoiceSet, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.4
												
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.5
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: CreateInteractionChoiceSet_InfoWithTabChar()						
						--mobile side: send CreateInteractionChoiceSet request 	 	
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1059,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1059,
													menuName ="Choice1059",
													vrCommands = 
													{ 
														"Choice1059",
													}, 
													image =
													{ 
														value ="icon.png",
														imageType ="STATIC",
													}, 
												}
											}
										})
						
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 1059,
											appID = applicationID,
											type = "Choice",
											vrCommands = {"Choice1059" }
										})
						:Do(function(_,data)
							--hmi side: send Navigation.CreateInteractionChoiceSet response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(CorIdCreateInteractionChoiceSet, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.5				
			--End Test case NegativeResponseCheck.5
		--End Test suit NegativeResponseCheck
]]

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin Test suit ResultCodeCheck
	--Description: TC's check all resultCodes values in pair with success value
		
		--Begin Test case ResultCodeCheck.1
		--Description: 
			--ChoiceID for current choiceSet or interactionChoiceSetID already exists in the system
			--ChoiceIDs within the ChoiceSet have duplicate IDs
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-453

			--Verification criteria:
				-- In case of creating interactionChoiceSet with "interactionChoiceSetID"  that is already registered for the current application, the response with INVALID_ID resultCode is sent.
				-- In case of creating interactionChoiceSet with "ChoiceID " that is already registered for the current application, the response with INVALID_ID resultCode is sent.
				-- In case of creating interactionChoiceSet with "ChoiceID" which duplicates within the current ChoiceSet, the response with INVALID_ID resultCode is sent.
			
			--Begin Test case ResultCodeCheck.1.1
			--Description: interactionChoiceSetID already exist
				function Test: CreateInteractionChoiceSet_ChoiceSetIDAlreadyExist()	
					--mobile side: sending CreateInteractionChoiceSet request
							local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = 1000000000,
												choiceSet = 
												{ 
													
													{ 
														choiceID = 1052,
														menuName ="Choice1052",
														vrCommands = 
														{ 
															"Choice1052",
														}, 
														image =
														{ 
															value ="icon.png",
															imageType ="STATIC",
														}, 
													}
												}
											})						

							

						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end	
			--End Test case ResultCodeCheck.1.1
			
			-----------------------------------------------------------------------------------------
			
			--UPDATED: Test is removed because according to APPLINK-19260; APPLINK-17063 "INVALID_ID" is not returned for duplicated choiceID
			-- SDL correct generated VR.AddCommand
			-- --Begin Test case ResultCodeCheck.1.2
			-- --Description: ChoiceID already exist
			-- 	function Test: CreateInteractionChoiceSet_ChoiceIDAlreadyExist()	
			-- 		--mobile side: sending CreateInteractionChoiceSet request
			-- 				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			-- 								{
			-- 									interactionChoiceSetID = 1052,
			-- 									choiceSet = 
			-- 									{ 
													
			-- 										{ 
			-- 											choiceID = 1013,
			-- 											menuName ="Choice1052",
			-- 											vrCommands = 
			-- 											{ 
			-- 												"Choice1052",
			-- 											}, 
			-- 											image =
			-- 											{ 
			-- 												value ="icon.png",
			-- 												imageType ="STATIC",
			-- 											}, 
			-- 										}
			-- 									}
			-- 								})						
							
			

			-- 			--mobile side: expect CreateInteractionChoiceSet response
			-- 			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
			-- 			--mobile side: expect OnHashChange notification is not send to mobile
			-- 			EXPECT_NOTIFICATION("OnHashChange")
			-- 			:Times(0)
			-- 		end	
			-- --End Test case ResultCodeCheck.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.1.3
			--Description: "ChoiceID" which duplicates within the current ChoiceSet
				function Test: CreateInteractionChoiceSet_ChoiceIDAlreadyExist()	
					--mobile side: sending CreateInteractionChoiceSet request
							local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = 1053,
												choiceSet = 
												{ 
													
													{ 
														choiceID = 1053,
														menuName ="Choice1053a",
														vrCommands = 
														{ 
															"Choice1053a",
														}, 
														image =
														{ 
															value ="icon.png",
															imageType ="STATIC",
														}, 
													},
													{ 
														choiceID = 1053,
														menuName ="Choice1053b",
														vrCommands = 
														{ 
															"Choice1053b",
														}, 
														image =
														{ 
															value ="icon.png",
															imageType ="STATIC",
														}, 
													}
												}
											})						
							
						--mobile side: expect CreateInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end	
			--End Test case ResultCodeCheck.1.3
			
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: MenuName or vrCommands synonym of elements have duplicate names
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-455
				-- APPLINK-13476

			--Verification criteria:
				-- In case of creating interactionChoiceSet with "MenuName" that is duplicated between the current ChoiceSet, the response with DUPLICATE_NAME resultCode is sent.
				-- In case of creating interactionChoiceSet with "vrCommands" that is duplicated between current ChoiceSet, the response with DUPLICATE_NAME resultCode is sent.
				-- In case SDL successfully creates choiseSet_1 (vrCommands1, menuName1) via CreateInteractionChoiceSet request AND app sends CreateInteractionChoiceSet request with choiseSet_2 (vrCommands1, menuName1) SDL must allow such request and return SUCCESS result code via CreateInteractionChoiceSet response
				
			--Begin Test case ResultCodeCheck.2.1
			--Description: menuName duplicated between the current ChoiceSet
				function Test: CreateInteractionChoiceSet_menuNameAlreadyExist()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1054,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1054,
																		menuName ="ChoiceAlreadyExist",
																		vrCommands = 
																		{ 
																			"Choice1054",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	},
																	{ 
																		choiceID = 1055,
																		menuName ="ChoiceDifferent",
																		vrCommands = 
																		{ 
																			"Choice1055",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	},
																	{ 
																		choiceID = 1056,
																		menuName ="ChoiceAlreadyExist",
																		vrCommands = 
																		{ 
																			"Choice1056",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}})						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand")
					:Times(AnyNumber())
					:Do(function(_,data)
						if data.params.cmdID == 1054 or
							data.params.cmdID == 1055 then
								self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})												
						else
							self.hmiConnection:SendError(data.id,"VR.AddCommand", "DUPLICATE_NAME", " Command is duplicated ")
						end
					end)

					--hmi side: absence of VR.DeleteCommand requests
					EXPECT_HMICALL("VR.DeleteCommand")
					:Do(function()
						self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
					end)
					:Times(2)
					:Timeout(12000)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end	
			--End Test case ResultCodeCheck.2.1
			
			-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13476		
			--Begin Test case ResultCodeCheck.2.2
			--Description: duplicated between the different ChoiceSet
				function Test: CreateInteractionChoiceSet_menuNameExistDiffSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1057,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1057,
																		menuName ="Choice1001",
																		vrCommands = 
																		{ 
																			"Choice1057",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})	
															
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case ResultCodeCheck.2.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.3
			--Description: menuName case-sensitive different in choice set
				function Test: CreateInteractionChoiceSet_vrCommandsDiffCaseChoiceSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1066,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1066,
																		menuName ="Choice1066",
																		vrCommands = 
																		{ 
																			"Choice1066",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	},
																	{ 
																		choiceID = 1067,
																		menuName ="ChoICE1066",
																		vrCommands = 
																		{ 
																			"Choice1067",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
					
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false , resultCode = "DUPLICATE_NAME" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end	
			--End Test case ResultCodeCheck.2.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.4
			--Description: menuName case-sensitive different choice set
				function Test: CreateInteractionChoiceSet_menuNameDiffCaseDiffSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1068,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1068,
																		menuName ="ChOICE1001",
																		vrCommands = 
																		{ 
																			"Choice1068",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
					
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS" })
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case ResultCodeCheck.2.4
]]			
			-----------------------------------------------------------------------------------------

			--UPDATED: According to APPLINK-17038 and APPLINK-17013 test is not correct.
			-- --Begin Test case ResultCodeCheck.2.5
			-- --Description: vrCommand duplicate inside choice
			-- 	function Test: CreateInteractionChoiceSet_vrCommandsDuplicateInsideChoice()	
			-- 		--mobile side: sending CreateInteractionChoiceSet request
			-- 		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			-- 												{
			-- 													interactionChoiceSetID = 1058,
			-- 													choiceSet = 
			-- 													{ 
																	
			-- 														{ 
			-- 															choiceID = 1058,
			-- 															menuName ="Choice1058",
			-- 															vrCommands = 
			-- 															{ 
			-- 																"Choice1058a",
			-- 																"Choice1058a",
			-- 															}, 
			-- 															image =
			-- 															{ 
			-- 																value ="icon.png",
			-- 																imageType ="STATIC",
			-- 															}, 
			-- 														}
			-- 													}
			-- 												})						
										
			-- 		--mobile side: expect CreateInteractionChoiceSet response
			-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
						
			-- 		--mobile side: expect OnHashChange notification is not send to mobile
			-- 		EXPECT_NOTIFICATION("OnHashChange")
			-- 		:Times(0)
			-- 	end	
			-- --End Test case ResultCodeCheck.2.5
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.2.6
			--Description: vrCommand duplicate inside choice set
				function Test: CreateInteractionChoiceSet_vrCommandsDuplicateInsideChoiceSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1059,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1059,
																		menuName ="Choice1059",
																		vrCommands = 
																		{ 
																			"Choice1059"
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	},
																	{ 
																		choiceID = 1060,
																		menuName ="Choice1060",
																		vrCommands = 
																		{ 
																			"Choice1059"
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
										
					--print("\27[31m DEFECT: APPLINK-25597\27[0m")										
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end	
			--End Test case ResultCodeCheck.2.6
			
			-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13476			
			--Begin Test case ResultCodeCheck.2.7
			--Description: vrCommand duplicate different choice set
				function Test: CreateInteractionChoiceSet_vrCommandsDuplicateDiffSets()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1061,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1061,
																		menuName ="Choice1061",
																		vrCommands = 
																		{ 
																			"Choice1001",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
					
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS" })					
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case ResultCodeCheck.2.7		
]]			
			-----------------------------------------------------------------------------------------

			--UPDATED: According to APPLINK-17038 and APPLINK-17013 test is not correct.
			-- --Begin Test case ResultCodeCheck.2.8
			-- --Description: vrCommand case-sensitive different in choice
			-- 	function Test: CreateInteractionChoiceSet_vrCommandsDiffCaseChoice()	
			-- 		--mobile side: sending CreateInteractionChoiceSet request
			-- 		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			-- 												{
			-- 													interactionChoiceSetID = 1062,
			-- 													choiceSet = 
			-- 													{ 																	
			-- 														{ 
			-- 															choiceID = 1062,
			-- 															menuName ="Choice1062",
			-- 															vrCommands = 
			-- 															{ 
			-- 																"choiceNONsensitive",
			-- 																"CHOICEnonSENSITIVE"
			-- 															}, 
			-- 															image =
			-- 															{ 
			-- 																value ="icon.png",
			-- 																imageType ="STATIC",
			-- 															}, 
			-- 														}
			-- 													}
			-- 												})						
					
					
			-- 		--mobile side: expect CreateInteractionChoiceSet response
			-- 		EXPECT_RESPONSE(cid, { success = false , resultCode = "DUPLICATE_NAME" })
						
			-- 		--mobile side: expect OnHashChange notification is not send to mobile
			-- 		EXPECT_NOTIFICATION("OnHashChange")
			-- 		:Times(0)
			-- 	end	
			-- --End Test case ResultCodeCheck.2.8
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.9
			--Description: vrCommand case-sensitive different in choice set
				function Test: CreateInteractionChoiceSet_vrCommandsDiffCaseChoiceSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1063,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1063,
																		menuName ="Choice1063",
																		vrCommands = 
																		{ 
																			"choiceNONsensitiveSET",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	},
																	{ 
																		choiceID = 1064,
																		menuName ="Choice1064",
																		vrCommands = 
																		{ 
																			"ChOICEnonsENSITIVEset",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
					
					--print("\27[31m DEFECT: APPLINK-25597\27[0m")
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false , resultCode = "DUPLICATE_NAME" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end	
			--End Test case ResultCodeCheck.2.9
			
			-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13476
			--Begin Test case ResultCodeCheck.2.10
			--Description: vrCommand case-sensitive different choice set
				function Test: CreateInteractionChoiceSet_vrCommandsDiffCaseDiffSet()	
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1065,
																choiceSet = 
																{ 																	
																	{ 
																		choiceID = 1065,
																		menuName ="Choice1065",
																		vrCommands = 
																		{ 
																			"CHoiCE1001",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})						
					
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS" })
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case ResultCodeCheck.2.10
]]			
		--End Test case ResultCodeCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: Check that SDL resend result code of HMI response in case when HMI sends VR.AddCommand response with error code
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-451
				--SDLAQ-CRS-457
				--SDLAQ-CRS-1024
				
			--Verification criteria:
				-- The request CreateInteractionChoiceSet is sent under conditions of RAM definite for executing it. The response code OUT_OF_MEMORY is returned. 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- If images or image type (DYNAMIC, STATIC) aren't supported on HMI SDL should return resultCode UNSUPPORTED_RESOURCE.
			
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "UNSUPPORTED_RESOURCE", name = "UnsupportedResource"}}
			for i=1,#resultCodes do
				Test["CreateInteractionChoiceSet" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
						--request from mobile side
						local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
						{
						   interactionChoiceSetID = 2,
						   choiceSet =
							{
							   {
							   choiceID = 201,
							   menuName = "vrChoice201",
							   vrCommands = {"vrChoice201"}
							   }
							}
						})

						--hmi side: request, response VR.AddCommand
						EXPECT_HMICALL("VR.AddCommand", 
						{cmdID = 201, type = "Choice", vrCommands = {"vrChoice201"}})
						:Times(1)
						:Do(function(_,data)
							self.hmiConnection:SendError(data.id,"VR.AddCommand", resultCodes[i].resultCode, "message")
						end)

						--hmi side: absence of VR.DeleteCommand requests
						EXPECT_HMICALL("VR.DeleteCommand")
						:Timeout(12000)
						:Times(0)

						--response on mobile side
						EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = resultCodes[i].resultCode})
						:Timeout(12000)

						--notification on mobile side
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(2000)
				end
			end
			
		--End Test case ResultCodeCheck.3
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.4
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-454

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Creat new session
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end
			
			--Description: Send CreateInteractionChoiceSet when application not registered yet.
			function Test:CreateInteractionChoiceSet_AppNotRegistered()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 1001,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 1001,
																		menuName ="Choice1001",
																		vrCommands = 
																		{ 
																			"Choice1001",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})

				--mobile side: expect CreateInteractionChoiceSet response 
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				:Timeout(2000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
		--End Test case ResultCodeCheck.4
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.5
		--Description: Policies manager must validate an RPC request as "disallowed" if it is not allowed by the backend.

			--Requirement id in JAMA:
				--SDLAQ-CRS-2396
				--SDLAQ-CRS-767

			--Verification criteria:
				--An RPC request is not allowed by the backend. Policies Manager validates it as "disallowed".
				--SDL rejects CreateInteractionChoiceSet request with REJECTED resultCode when current HMI level is NONE.
			function Test:Precondition_DeactivateApp()
				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end
			
			function Test:CreateInteractionChoiceSet_DisallowedHMINone()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2001,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2001,
																		menuName ="Choice2001",
																		vrCommands = 
																		{ 
																			"Choice2001",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
				self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
				:Timeout(2000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
			
			function Test:Precondition_WaitActivation()
			  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL"})

			  local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			  
			  EXPECT_HMIRESPONSE(rid)
			  :Do(function(_,data)
			  		if data.result.code ~= 0 then
			  		quit()
			  		end
				end)
			end
		--End Test case ResultCodeCheck.5
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.6
		--Description: Policies Manager must validate an RPC request as "userDisallowed" if the request is allowed by the backend but disallowed by the use

			--Requirement id in JAMA:
				--SDLAQ-CRS-2394

			--Verification criteria:
				--An RPC request is allowed by the backend but disallowed by the user. Policy Manager validates it as "userDisallowed"
				
			--TODO: UnComment after APPLINK-13101 is resolved  - Fixed ToDo 
			--Description: Disallowed CreateInteractionChoiceSet

			--ToDo: Uncomment when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			local GroupId
			-- function Test:Precondition_UserDisallowedPolicyUpdate()
			-- 		--hmi side: sending SDL.GetURLS request
			-- 		local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
			-- 		--hmi side: expect SDL.GetURLS response from HMI
			-- 		EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
			-- 		:Do(function(_,data)
			-- 			--print("SDL.GetURLS response is received")
			-- 			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			-- 			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			-- 				{
			-- 					requestType = "PROPRIETARY",
			-- 					fileName = "filename"
			-- 				}
			-- 			)
			-- 			--mobile side: expect OnSystemRequest notification 
			-- 			EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
			-- 			:Do(function(_,data)
			-- 				--print("OnSystemRequest notificfation is received")
			-- 				--mobile side: sending SystemRequest request 
			-- 				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
			-- 					{
			-- 						fileName = "PolicyTableUpdate",
			-- 						requestType = "PROPRIETARY"
			-- 					},
			-- 				"files/PTU_ForCreateInteractionChoiceSet.json")
							
			-- 				local systemRequestId
			-- 				--hmi side: expect SystemRequest request
			-- 				EXPECT_HMICALL("BasicCommunication.SystemRequest")
			-- 				:Do(function(_,data)
			-- 					systemRequestId = data.id
			-- 					--print("BasicCommunication.SystemRequest is received")
								
			-- 					--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			-- 					self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
			-- 						{
			-- 							policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
			-- 						}
			-- 					)
			-- 					function to_run()
			-- 						--hmi side: sending SystemRequest response
			-- 						self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
			-- 					end
								
			-- 					RUN_AFTER(to_run, 500)
			-- 				end)
							
			-- 				--hmi side: expect SDL.OnStatusUpdate
			-- 				EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
			-- 				:ValidIf(function(exp,data)
			-- 					if 
			-- 						exp.occurences == 1 and
			-- 						data.params.status == "UP_TO_DATE" then
			-- 							return true
			-- 					elseif
			-- 						exp.occurences == 1 and
			-- 						data.params.status == "UPDATING" then
			-- 							return true
			-- 					elseif
			-- 						exp.occurences == 2 and
			-- 						data.params.status == "UP_TO_DATE" then
			-- 							return true
			-- 					else 
			-- 						if 
			-- 							exp.occurences == 1 then
			-- 								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
			-- 						elseif exp.occurences == 2 then
			-- 								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
			-- 						end
			-- 						return false
			-- 					end
			-- 				end)
			-- 				:Times(Between(1,2))
							
			-- 				--mobile side: expect SystemRequest response
			-- 				EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
			-- 				:Do(function(_,data)
			-- 					--print("SystemRequest is received")
			-- 					--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
			-- 					local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
			-- 					--hmi side: expect SDL.GetUserFriendlyMessage response
			-- 					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
			-- 					:Do(function(_,data)
			-- 						print("SDL.GetUserFriendlyMessage is received")
			-- 						--hmi side: sending SDL.GetListOfPermissions request to SDL
			-- 							local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
										
			-- 							-- hmi side: expect SDL.GetListOfPermissions response
			-- 							-- -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions"}})
			-- 							EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
			-- 							:Do(function(_,data)
			-- 								print("SDL.GetListOfPermissions response is received")

			-- 								GroupId = data.result.allowedFunctions[1].id								
			-- 								--hmi side: sending SDL.OnAppPermissionConsent
			-- 								self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = GroupId, name = "New"}}, source = "GUI"})
			-- 								end)				
			-- 					end)
			-- 				end)
			-- 				:Timeout(2000)

							
			-- 			end)
			-- 		end)
			-- 	end
			--ToDo: Uncomment when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			--Description: Send CreateInteractionChoiceSet when user not allowed
			-- function Test:CreateInteractionChoiceSet_UserDisallowed()
			-- 	--mobile side: sending CreateInteractionChoiceSet request
			-- 	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			-- 												{
			-- 													interactionChoiceSetID = 2042,
			-- 													choiceSet = 
			-- 													{ 
																	
			-- 														{ 
			-- 															choiceID = 2042,
			-- 															menuName ="Choice2042",
			-- 															vrCommands = 
			-- 															{ 
			-- 																"Choice2042",
			-- 															}, 
			-- 															image =
			-- 															{ 
			-- 																value ="icon.png",
			-- 																imageType ="STATIC",
			-- 															}, 
			-- 														}
			-- 													}
			-- 												})
			-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
						
			-- 	--mobile side: expect OnHashChange notification is not send to mobile
			-- 	EXPECT_NOTIFICATION("OnHashChange")
			-- 	:Times(0)	
			-- end
			
			--Description: Allowed CreateInteractionChoiceSet for another test cases	
			function Test:AllowedCreateInteractionChoiceSet()
				self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = GroupId, name = "New"}}, source = "GUI"})		  
			end
		
		--End Test case ResultCodeCheck.6
		
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
	-- wrong response with correct HMI id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid sctructure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behavior in case of absence of responses from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-457
				--APPLINK-8585
				--APPLINK-10795
			
			--Verification criteria:
				--[[
						1. Provided data is valid but something went wrong in the lower layers.

						2. Unknown issue (other result codes can't be applied )

						3. In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

						4. In case SDL gets no response(s) to one or more of corresponding VR.AddCommands (VR-related choices) from HMI, SDL must
						-> clear internally stored UI-related choices
						-> + send VR.DeleteCommands for successfully added VR-choices
						-> and respond with (resultCode: GENERIC_ERROR, success:false) for CreateInteractionChoiceSet to mobile app.

						5. In case SDL fails to store UI-related choices, SDL must
						-> NOT send VR.AddCommands to corresponding VR-related choices (that is, SDL must first store UI-choices and in case all UI-choices are stored successfully - send VR-choices to HMI)
						-> and respond with (resultCode: GENERIC_ERROR, success:false) for CreateInteractionChoiceSet to mobile app.
				]]
			
			--Begin Test case HMINegativeCheck.1.1
			--Description: Check that SDL respond to mobile GENERIC_ERROR in case when does not receive VR.AddCommand responsevrCommand duplicate inside choice set
				function Test:CreateInteractionChoiceSet_WithoutResponseVRAddCommandOneChoice()
					--request from mobile side
					local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
					{
					   interactionChoiceSetID = 10,
					   choiceSet =
						{
						   {
							   choiceID = 201,
							   menuName = "vrChoice201",
							   vrCommands = {"vrChoice201"}
						   }
						}
					})

					--hmi side: request, response VR.AddCommand
					EXPECT_HMICALL("VR.AddCommand", 
					{
						cmdID = 201,
						type = "Choice",
						vrCommands = {"vrChoice201"}
					  })

					--hmi side: Absence of VR.DeleteCommand
					EXPECT_HMICALL("VR.DeleteCommand")
					:Timeout(12000)
					:Times(0)

					--response on mobile side
					EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					--notification on mobile side
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(2000)
					:Times(0)
				end
			--End Test case HMINegativeCheck.1.1
			
			-----------------------------------------------------------------------------------------
	
			--Begin Test case HMINegativeCheck.1.2
			--Description: Check that SDL responds to mobile GENERIC_ERROR and deletes successfully added choice vr commands
				function Test:CreateInteractionChoiceSet_WithoutResponseVRAddCommandSeveralChoices()
					--request from mobile side
					local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
					{
					   interactionChoiceSetID = 2,
					   choiceSet =
						{
						   {
							   choiceID = 202,
							   menuName = "vrChoice202",
							   vrCommands = {"vrChoice202"}
						   },
						   {
							   choiceID = 203,
							   menuName = "vrChoice203",
							   vrCommands = {"vrChoice203"}
						   },
						   {
							   choiceID = 204,
							   menuName = "vrChoice204",
							   vrCommands = {"vrChoice204"}
						   }
						}
					})

					--hmi side: request, response VR.AddCommand
					EXPECT_HMICALL("VR.AddCommand", 
					{cmdID = 202, type = "Choice", vrCommands = {"vrChoice202"}},
					{cmdID = 203, type = "Choice", vrCommands = {"vrChoice203"}},
					{cmdID = 204, type = "Choice", vrCommands = {"vrChoice204"}})
					:Times(3)
					:Do(function(exp,data)
						if exp.occurences == 3 then 
							--Do nothing
						else 
							self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})
						end
					end)

					--hmi side: request, response VR.DeleteCommand
					EXPECT_HMICALL("VR.DeleteCommand",
					{cmdID = 202},
					{cmdID = 203})
					:Times(2)
					:Timeout(25000)
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
					end)

					--response on mobile side
					EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(25000)

					--notification on mobile side
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(25000)

				end
			--End Test case ResultCodeCheck.1.2			
	
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.1.3
			--Description: CreateInteractionChoiceSet request with one choice with error VR.AddCommand response
 				local resultCodeValues = {{resultCode = "UNSUPPORTED_RESOURCE", code = 2}, {resultCode = "REJECTED", code = 4}, {resultCode = "ABORTED", code = 5}, {resultCode = "IGNORED", code = 6}, {resultCode = "TIMED_OUT", code = 10}, {resultCode = "INVALID_ID", code = 13}, {resultCode = "DUPLICATE_NAME", code = 14}, {resultCode = "WARNINGS", code = 21}, {resultCode = "GENERIC_ERROR", code = 22}, {resultCode = "USER_DISALLOWED", code = 23}, {resultCode = "DISALLOWED", code = 3}}

				for i=1,#resultCodeValues do
					Test["CreateInteractionChoiceSet_OneChoiceErrorResponseFromHMI" .. resultCodeValues[i].resultCode ]= function(self)
						--request from mobile side
						local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
						{
						   interactionChoiceSetID = 3+resultCodeValues[i].code,
						   choiceSet =
							{
							   {
								   choiceID = 301+resultCodeValues[i].code,
								   menuName = "vrChoice301",
								   vrCommands = {"vrChoice301"}
							   }
							}
						})

						--hmi side: request, response VR.AddCommand
						EXPECT_HMICALL("VR.AddCommand", 
						{cmdID = 301+resultCodeValues[i].code, type = "Choice", vrCommands = {"vrChoice301"}})
						:Times(1)
						:Do(function(_,data)
						  -- self.hmiConnection:SendError(data.id,"VR.AddCommand", resultCodeValues[i].resultCode, "message")
							self.hmiConnection:SendError(data.id,"VR.AddCommand", resultCodeValues[i].resultCode, "Some error is occured, resultCode "..resultCodeValues[i].resultCode)
						end)

						--hmi side: absence of VR.DeleteCommand requests
						EXPECT_HMICALL("VR.DeleteCommand")
						:Timeout(12000)
						:Times(0)

						if resultCodeValues[i].resultCode ~= "WARNINGS" then
							--response on mobile side
							EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = resultCodeValues[i].resultCode})
							:Timeout(12000)

							--notification on mobile side
							EXPECT_NOTIFICATION("OnHashChange")
							:Times(0)
						else
							--response on mobile side
							EXPECT_RESPONSE(CorIdCICS, { success = true, resultCode = "SUCCESS"--[[ TODO SDL issue APPLINK-14569 , info = " Some error is occured, resultCode "..resultCodeValues[i].resultCode]]})
							:Timeout(12000)

							--notification on mobile side
							EXPECT_NOTIFICATION("OnHashChange")
						end

						DelayedExp(15000)				
					end
				end			
			--End Test case ResultCodeCheck.1.3		
			
			-----------------------------------------------------------------------------------------
				
			--Begin Test case HMINegativeCheck.1.4
			--Description: CreateInteractionChoiceSet request with several choice with error VR.AddCommand response to one				
				for i=1,#resultCodeValues do
					Test["CreateInteractionChoiceSet_SeveralChoiceErrorResponseFromHMI_" .. resultCodeValues[i].resultCode ]= function(self)						
							local startID = 200+i*5
							--request from mobile side
							local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
							{
							   interactionChoiceSetID = 4+i,
							   choiceSet = self:setChoiseSet(5,startID)
							})

							--hmi side: request, response VR.AddCommand
							expectChoiceSet = self:setEXChoiseSet(5,startID)
							EXPECT_HMICALL("VR.AddCommand", 
								expectChoiceSet[1],
								expectChoiceSet[2],
								expectChoiceSet[3],
								expectChoiceSet[4],
								expectChoiceSet[5])
							:Times(AtMost(5))
							--AddCommand 1,3 error, AddCommand 2 successfully 
							:Do(function(exp,data)
								if exp.occurences == 1 or 
									exp.occurences == 3 then 
										self.hmiConnection:SendError(data.id,"VR.AddCommand", resultCodeValues[i].resultCode, "message")
								elseif exp.occurences == 2 then 
									self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})

									if resultCodeValues[i].resultCode ~= "WARNINGS" then
									--hmi side: request, response VR.DeleteCommand
										EXPECT_HMICALL("VR.DeleteCommand",
										{cmdID = startID+1})					
										:Timeout(25000)
										:Do(function(exp,data)
											self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
										end)
									end
								end
							end)

							if resultCodeValues[i].resultCode == "WARNINGS" then
								EXPECT_HMICALL("VR.DeleteCommand",
								{cmdID = startID},
								{cmdID = startID+1},
								{cmdID = startID+2})					
								:Timeout(25000)
								:Do(function(exp,data)
									self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
								end)
								:Times(3)
							end
							
							if resultCodeValues[i].resultCode ~= "WARNINGS" then
								--response on mobile side
								EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = resultCodeValues[i].resultCode})
								:Timeout(15000)
							else
								--response on mobile side
								EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = "GENERIC_ERROR"})
								:Timeout(15000)
							end

							--notification on mobile side
							EXPECT_NOTIFICATION("OnHashChange")
							:Times(0)
							:Timeout(15000)

							DelayedExp(5000)
					end
				end			
			--End Test case ResultCodeCheck.1.4	

			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.1.5
			--Description: Check that SDL delete all successfully added command 
				function Test:CreateInteractionChoiceSet_SuccessCodesAfterError()
					local startID = 350
					--request from mobile side
					local CorIdCICS = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
					{
					   interactionChoiceSetID = 555,
					   choiceSet = self:setChoiseSet(20,startID)
					})
					
					local addCommandIds = {}
					--hmi side: request, response VR.AddCommand					
					EXPECT_HMICALL("VR.AddCommand")
					:Times(20)					
					:Do(function(exp,data)
						if exp.occurences == 5 then
							local function to_run()
								self.hmiConnection:SendError(data.id,"VR.AddCommand", "REJECTED", " Command is rejected ")
							end
							RUN_AFTER(to_run, 5000)	
						else
							self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})
						end
					end)
					
					--hmi side: request, response VR.DeleteCommand
					EXPECT_HMICALL("VR.DeleteCommand")
					:Timeout(20000)
					:Times(19)
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
					end)

					--response on mobile side
					EXPECT_RESPONSE(CorIdCICS, { success = false, resultCode = "REJECTED"})
					:Timeout(12000)

					--notification on mobile side
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(20000)
				end		
			--End Test case ResultCodeCheck.1.5			
			
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-38
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.			
			function Test: CreateInteractionChoiceSet_ResponseInvalidStructure()
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2043,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2043,
																		menuName ="Choice2043",
																		vrCommands = 
																		{ 
																			"Choice2043",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2043,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2043" }
									})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response.
					--Correct struture: self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"VR.AddCommand"}}')	
					self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"VR.AddCommand"}}')	
				end)
					
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
				:Timeout(12000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end						
		--End Test case HMINegativeCheck.2
]]		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-38
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:CreateInteractionChoiceSet_SeveralResponseToOneRequest()
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2044,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2044,
																		menuName ="Choice2044",
																		vrCommands = 
																		{ 
																			"Choice2044",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2044,
									appID = applicationID,
									type = "Choice",
									vrCommands = {"Choice2044" }
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)
					
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end									
		--End Test case HMINegativeCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-38
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:CreateInteractionChoiceSet_FakeParamsInResponse()
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2045,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2045,
																		menuName ="Choice2045",
																		vrCommands = 
																		{ 
																			"Choice2045",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2045,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2045" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
					end)
						
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.2
			--Description: Parameter from another API
				function Test:CreateInteractionChoiceSet_ParamsFromOtherAPIInResponse()
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2046,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2046,
																		menuName ="Choice2046",
																		vrCommands = 
																		{ 
																			"Choice2046",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2046,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2046" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)
						
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case HMINegativeCheck.4.2			
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-38
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:CreateInteractionChoiceSet_WrongResponseToCorrectID()
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2049,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2049,
																		menuName ="Choice2049",
																		vrCommands = 
																		{ 
																			"Choice2049",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2049,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2049" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})						
					end)
						
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
			end
		--End Test case HMINegativeCheck.5		
	--End Test suit HMINegativeCheck


----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	
		--Begin Test case SequenceCheck.1
		--Description: GrammarID should be generated by SDL for every application and assigned to every VR choiceSet.

			--Requirement id in JAMA:
				--SDLAQ-CRS-2799
				
			--Verification criteria:
				--  One unique grammarID across all apps and commands is assigned for a choice set.
				--  Every choice of a choiceSet has the same grammarID, but different unique choiceIDs.
			local grammarID01, grammarID02, grammarID03, grammarID04, grammarID05, grammarID06, grammarID07
			function Test:CreateInteractionChoiceSet_SameGrammarIDForEveryChoiceOfAChoiceSet()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 1,
															choiceSet = 
															{ 
																
																{ 
																	choiceID = 9000,
																	menuName ="Choice9000",
																	vrCommands = 
																	{ 
																		"super","best"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																},
																{ 
																	choiceID = 9001,
																	menuName ="Choice9001",
																	vrCommands = 
																	{ 
																		"magnificant","incredible"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																}
															}
														})
				
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 9000,
									appID = applicationID,
									type = "Choice",									
									vrCommands = {"super","best"}
								},
								{ 
									cmdID = 9001,
									appID = applicationID,
									type = "Choice",									
									vrCommands = {"magnificant","incredible"}
								})							
				:Times(2)
				:Do(function(exp,data)
					--hmi side: sending VR.AddCommand response
					if (exp.occurences == 1) then 
						grammarID01 = data.params.grammarID					
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
					else
						grammarID02 = data.params.grammarID						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end					
				end)
				
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
			    		if (grammarID01 == grammarID02) then			    			
			    			return true
			    		else 
							print("GrammarID is different between choice of a choiceSet")
			    			return false
			    		end
			    	end)
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			
			end
			
			function Test:CreateInteractionChoiceSet_DiffGrammarIDForDiffChoiceSet()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 2,
															choiceSet = 
															{ 
																
																{ 
																	choiceID = 9002,
																	menuName ="Choice9002",
																	vrCommands = 
																	{ 
																		"something","else"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																}
															}
														})
				
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 9002,
									appID = applicationID,
									type = "Choice",									
									vrCommands = {"something","else"}
								})		
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response					
					grammarID03 = data.params.grammarID					
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})											
				end)
				
				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
			    		if (grammarID03 ~= grammarID02) then			    			
			    			return true
			    		else 
							print("GrammarID is the same for different choiceSet")
			    			return false
			    		end
			    	end)
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			
			end
						
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end
						
			function Test:RegisterSecondApp()				
				--mobile side: sending request 
				local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
				
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "Test Application2"
					}
				})
				:Do(function(_,data)
					self.applications["Test Application2"] = data.params.application.appID					
				end)
				
				--print("\27[31m DEFECT: APPLINK-24359\27[0m")
				--mobile side: expect response
				self.mobileSession1:ExpectResponse(CorIdRegister, 
				{
					syncMsgVersion = 
					{
						majorVersion = 3,
						minorVersion = 0
					}
				})
				:Timeout(2000)

				--mobile side: expect notification
				self.mobileSession1:ExpectNotification("OnHMIStatus", 
				{ 
					systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
				})
				:Timeout(2000)
			end
						
			function Test:Precondition_ActivateApp2()
				
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
				
				EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
					if data.result.code ~= 0 then
						quit()
						end
					end)
					
				--mobile side: expect notification
				self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
			end
		
			function Test:CreateInteractionChoiceSet_SameVrCommandDiffApp()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 1,
															choiceSet = 
															{ 
																
																{ 
																	choiceID = 9004,
																	menuName ="Choice9004",
																	vrCommands = 
																	{ 
																		"super","best"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																},
																{ 
																	choiceID = 9005,
																	menuName ="Choice9005",
																	vrCommands = 
																	{ 
																		"magnificant","incredible"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																}
															}
														})
				
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 9004,
									appID = self.applications["Test Application2"] ,
									type = "Choice",									
									vrCommands = {"super","best"}
								},
								{ 
									cmdID = 9005,
									appID = self.applications["Test Application2"] ,
									type = "Choice",									
									vrCommands = {"magnificant","incredible"}
								})							
				:Times(2)
				:Do(function(exp,data)
					--hmi side: sending VR.AddCommand response
					if (exp.occurences == 1) then 
						grammarID04 = data.params.grammarID					
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
					else
						grammarID05 = data.params.grammarID						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end					
				end)
				
				--mobile side: expect CreateInteractionChoiceSet response
				self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
			    		if (grammarID04 == grammarID05) then			    			
			    			return true
			    		else 
							print("GrammarID is different between choice of a choiceSet")
			    			return false
			    		end
						
						if (grammarID04 ~= grammarID02 and grammarID04 ~= grammarID03) then			    			
			    			return true
			    		else 
							print("GrammarID is not unique  across all apps")
			    			return false
			    		end
			    	end)
					
				--mobile side: expect OnHashChange notification
				self.mobileSession1:ExpectNotification("OnHashChange",{})
			
			end
			
			function Test:CreateInteractionChoiceSet_SameVrCommandDiffChoiceSetDiffApp()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 2,
															choiceSet = 
															{ 
																
																{ 
																	choiceID = 9006,
																	menuName ="The Show",
																	vrCommands = 
																	{ 
																		"something", "else"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																},
																{ 
																	choiceID = 9007,
																	menuName ="The",
																	vrCommands = 
																	{ 
																		"some"
																	}, 
																	image =
																	{ 
																		value ="icon.png",
																		imageType ="STATIC",
																	}, 
																}
															}
														})
				
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 9006,
									appID = self.applications["Test Application2"] ,
									type = "Choice",									
									vrCommands = {"something", "else"}
								},
								{ 
									cmdID = 9007,
									appID = self.applications["Test Application2"] ,
									type = "Choice",									
									vrCommands = {"some"}
								})							
				:Times(2)
				:Do(function(exp,data)
					--hmi side: sending VR.AddCommand response
					if (exp.occurences == 1) then 
						grammarID06 = data.params.grammarID					
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})						
					else
						grammarID07 = data.params.grammarID						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end					
				end)
				
				--mobile side: expect CreateInteractionChoiceSet response
				self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
			    		if (grammarID06 == grammarID07) then			    			
			    			return true
			    		else 
							print("GrammarID is different between choice of a choiceSet")
			    			return false
			    		end
						
						if (grammarID06 ~= grammarID04) then			    			
			    			return true
			    		else 
							print("GrammarID is not unique  across all apps")
			    			return false
			    		end
			    	end)
				--mobile side: expect OnHashChange notification
				self.mobileSession1:ExpectNotification("OnHashChange",{})
			
			end
									
			function Test:Precondition_ActivateApp1()
				
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				
				EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
					if data.result.code ~= 0 then
						quit()
						end
					end)
					
				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
			end
					
			function Test:Precondition_PerformInteractionApp1() 
				local cid = self.mobileSession:SendRPC("PerformInteraction",
													{	
														initialText = "StartPerformInteraction",
														initialPrompt = { 
															{
																text = "Makeyourchoice",
																type = "TEXT"
															}
														},
														interactionMode = "BOTH",
														interactionChoiceSetIDList = { 2 },
														timeout = 5000
													})
				
				EXPECT_HMICALL("VR.PerformInteraction", 
				{ 
					grammarID = {grammarID03}
				})
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 9002})					
				end)
				
				EXPECT_HMICALL("UI.PerformInteraction", 
				{ })
				:Do(function(_,data)
					self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
				end)
				
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = 9002 })
				
			end
			
			function Test:Precondition_ActivateApp2()
				
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
				
				EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
					if data.result.code ~= 0 then
						quit()
						end
					end)
					
				--mobile side: expect notification
				self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
			end
						
			function Test:Precondition_PerformInteractionApp2() 
				local cid = self.mobileSession1:SendRPC("PerformInteraction",
													{	
														initialText = "StartPerformInteraction",
														initialPrompt = { 
															{
																text = "Makeyourchoice",
																type = "TEXT"
															}
														},
														interactionMode = "BOTH",
														interactionChoiceSetIDList = { 1, 2 },
														timeout = 5000
													})
				
				EXPECT_HMICALL("VR.PerformInteraction", 
				{ 
					grammarID = {grammarID04, grammarID06}
				})
				:Do(function(_,data)				
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 9004})					
				end)
				
				EXPECT_HMICALL("UI.PerformInteraction")
				:Do(function(_,data)
					self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
				end)
				
				self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", choiceID = 9004 })		
				
			end
			
	--End Test suit SequenceCheck
	
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: 

			--Requirement id in JAMA:
				--SDLAQ-CRS-768
				
			--Verification criteria: 
				--SDL doesn't reject CreateInteractionChoiceSet request when current HMI is FULL.
				--SDL doesn't reject CreateInteractionChoiceSet request when current HMI is LIMITED.
				--SDL doesn't reject CreateInteractionChoiceSet request when current HMI is BACKGROUND.
		
		if 
			Test.isMediaApplication == true or 
			Test.appHMITypes["NAVIGATION"] == true then

			--Begin DifferentHMIlevel.1.1
			--Description: SDL doesn't reject CreateInteractionChoiceSet request when current HMI is LIMITED (only for media, navi app)
				function Test:Precondition_ActivateApp1()
				
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					
					EXPECT_HMIRESPONSE(rid)
					:Do(function(_,data)
						if data.result.code ~= 0 then
							quit()
							end
						end)
						
					--mobile side: expect notification
					self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 

					self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})

				end			
				
				function Test:Precondition_DeactivateToLimited()

					--hmi side: sending BasicCommunication.OnAppDeactivated notification
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

				end
				
				function Test:CreateInteractionChoiceSet_HMILevelLimited()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2050,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2050,
																		menuName ="Choice2050",
																		vrCommands = 
																		{ 
																			"Choice2050",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2050,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2050" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")				
				end
			--End DifferentHMIlevel.1.1
		
			--Begin DifferentHMIlevel.1.2
			--Description: SDL doesn't reject CreateInteractionChoiceSet request when current HMI is BACKGROUND.
				
				--Description:Change HMI to BACKGROUND
				function Test:Precondition_ActivateApp2()
					
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
					
					EXPECT_HMIRESPONSE(rid)
					:Do(function(_,data)
						if data.result.code ~= 0 then
							quit()
							end
						end)
						
					--mobile side: expect notification
					self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}) 

					self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
		end
				--Description: CreateInteractionChoiceSet when HMI level BACKGROUND
					function Test:CreateInteractionChoiceSet_HMILevelBackground()
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
																interactionChoiceSetID = 2051,
																choiceSet = 
																{ 
																	
																	{ 
																		choiceID = 2051,
																		menuName ="Choice2051",
																		vrCommands = 
																		{ 
																			"Choice2051",
																		}, 
																		image =
																		{ 
																			value ="icon.png",
																			imageType ="STATIC",
																		}, 
																	}
																}
															})
					
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2051,
										appID = applicationID,
										type = "Choice",
										vrCommands = {"Choice2051" }
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")						
				end
			--End Test case DifferentHMIlevel.1.2			
		--End Test case DifferentHMIlevel.1		
	--End Test suit DifferentHMIlevel
