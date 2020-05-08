Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
require('user_modules/AppTypes')

local infoMessage = string.rep("a",1000)


function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end
	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
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
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
	--End Precondition.1

	-----------------------------------------------------------------------------------------

	--Begin Precondition.2
	--Description: Putting file(PutFiles)
		function Test:PutFile()			
			local cid = self.mobileSession:SendRPC("PutFile",
			{			
				syncFileName = "icon.png",
				fileType	= "GRAPHIC_PNG",
				persistentFile = false,
				systemFile = false
			}, "files/icon.png")	
			EXPECT_RESPONSE(cid, { success = true})
		end
	--End Precondition.2	
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.3
	--Description: Adding SubMenu(AddSubMenus)
		local menuIDValues = {1, 500000, 2000000000}
		for i=1,#menuIDValues do
			Test["AddSubMenuWithId"..menuIDValues[i]] = function(self)
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = menuIDValues[i],
															menuName = "SubMenu"..tostring(menuIDValues[i])
														})
				
				--hmi side: expect UI.AddSubMenu request 
				EXPECT_HMICALL("UI.AddSubMenu", 
				{ 
					menuID = menuIDValues[i],
					menuParams = { menuName = "SubMenu"..tostring(menuIDValues[i]) }
				})
				:Do(function(_,data)
					--hmi side: expect UI.AddSubMenu response 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect response and notification
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				EXPECT_NOTIFICATION("OnHashChange")
			end
		end
	--End Precondition.3
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.4
	--Description: Adding SubMenu(AddSubMenus)		
		for i=18,30 do
			Test["AddSubMenuWithId"..i] = function(self)
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = i,
															menuName = "SubMenu"..tostring(i)
														})
				
				--hmi side: expect UI.AddSubMenu request 
				EXPECT_HMICALL("UI.AddSubMenu", 
				{ 
					menuID = i,
					menuParams = { menuName = "SubMenu"..tostring(i) }
				})
				:Do(function(_,data)
					--hmi side: expect UI.AddSubMenu response 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect response and notification
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				EXPECT_NOTIFICATION("OnHashChange")
			end
		end
	--End Precondition.4
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.5
	--Description: AddCommand id = 11 to Submenu with cmdID = 19
		function Test:AddCommand_11ToSubMenu19()
			--mobile side: sending request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 11,
				menuParams = { parentID = 19, position = 1000, menuName ="Command11"}, 
				vrCommands ={"VR11"}, 
				--cmdIcon = { value ="icon.png", imageType ="DYNAMIC"	}
			})
			
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = 11,
				--cmdIcon = {value = storagePath.."icon.png",imageType = "DYNAMIC"},
				menuParams = {parentID = 19, position = 1000, menuName ="Command11"}
			})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
			{ 
				cmdID = 11,
				vrCommands = {"VR11"}
			})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response
				grammarIDValue = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)			
			
			--mobile side: expect response and notification
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			EXPECT_NOTIFICATION("OnHashChange")
		end
	--End Precondition.5
		

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
					--SDLAQ-CRS-33				

			--Verification criteria: 
					--Deleting the SubMenu from UI command menu and SDL is executed successfully. The SUCCESS response code is returned.
				
			--Begin Test case CommonRequestCheck.1.1
			--Description: DeleteSubMenu without Command in it 
				function Test:DeleteSubMenu_WithoutCommand()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 18
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 18
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
			--End Test case CommonRequestCheck.1.1
			
			-----------------------------------------------------------------------------------------
				
			--Begin Test case CommonRequestCheck.1.2
			--Description: DeleteSubMenu with Command in it 
				function Test:DeleteSubMenu_WithCommand()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 19
																})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 11
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 11
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
												
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 19
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					
					-----
			--Send AddCommand "Command_01" + addItem to "Submenu_01" VrSynonyms = command2
			
				function Test:AddCommand_SameCommandID01_Submenu()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 02,
						menuParams = 	
						{ 
							parentID = 11,	
							position = 1000,
							menuName ="Command_01"
						},
						vrCommands = 
						{ 
							"command2"
						}
					})
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 02,
						type = "Command",
						vrCommands = 
						{
							"command2"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 02,
						menuParams = 	
						{ 
							parentID = 11,
							position = 1000,
							menuName ="Command_01"
						}
					})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end		
			--End 
					
			--End Test case CommonRequestCheck.1.2
			
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-440				

			--Verification criteria: 
					--The request without "menuID" is sent,  the response with INVALID_DATA result code is returned.			
			function Test:DeleteSubMenu_MissingAllParams()
				--mobile side: DeleteSubMenu request 
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",{}) 
			 
			    --mobile side: DeleteSubMenu response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)				
			end			
		--Begin Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-4518
					
			--Verification criteria:
					--According to xml tests by Ford team all fake params should be ignored by SDL
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: Parameter not from protocol					
				function Test:DeleteSubMenu_WithFakeParam()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 20,																
																fakeParam = "fakeParam"
															})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
									{ 
										menuID = 20																										
									})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
								print(" SDL re-sends fakeParam parameters to HMI in UI.DeleteSubMenu request")
								return false
						else 
							return true
						end
					end)
						
					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--Begin Test case CommonRequestCheck.3.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.2
			--Description: Parameters from another request
			function Test:DeleteSubMenu_ParamsAnotherRequest()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
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
															}, 
														})
									
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
			--End Test case CommonRequestCheck.3.2			
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-440

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:DeleteSubMenu_IncorrectJSON()

				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 8,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"menuID" 21}'
				}
				self.mobileSession:Send(msg)
				EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })	
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)				
			end			
		--End Test case CommonRequestCheck.4
		
		
		-----------------------------------------------------------------------------------------
--[[TODO: Requirement and Verification criteria need to be updated. Check if APPLINK-13892 is resolved
		--Begin Test case CommonRequestCheck.5
		--Description: different conditions of correlationID parameter 

			--Requirement id in JAMA:
			--Verification criteria: duplicate correlationID			
			
			function Test:DeleteSubMenu_correlationIdDuplicateValue() 
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 21
														})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu", 
								{ 
									menuID = 21
								},
								{ 
									menuID = 22
								})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:Times(2)
					
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:Times(2)
				:Do(function(exp,data)
					if exp.occurrences == 1 then						
						local msg = 
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 7,
							rpcCorrelationId = cid,					
							payload          = '{"menuID":22}'
						}
						self.mobileSession:Send(msg)
					end
				end)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(2)
			end
]]			
		--End Test case CommonRequestCheck.5
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
							-- SDLAQ-CRS-33

				--Verification criteria: 
							-- Deleting the SubMenu from UI command menu and SDL is executed successfully. The SUCCESS response code is returned.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: menuID lower bound					
					function Test:DeleteSubMenu_menuIDLowerBound()	
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 1
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 1
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: menuID upper bound
					function Test:DeleteSubMenu_menuIDUpperBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 2000000000
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 2000000000
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: menuID in bound
					function Test:DeleteSubMenu_menuIDInBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 500000
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 500000
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.3
								
			--End Test case PositiveRequestCheck.1			
		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions


		--Begin Test suit PositiveResponseCheck
		--Description: Checking parameters boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA:
					--SDLAQ-CRS-34
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					
				--Begin PositiveResponseCheck.1.1
				--Description: info parameter lower bound					
					function Test: DeleteSubMenu_InfoLowerBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 23
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 23
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info="a"})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info= "a"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.2
				--Description: info parameter upper bound 					
					function Test: DeleteSubMenu_InfoUpperBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 24
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 24
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMessage})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info= infoMessage})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End PositiveResponseCheck.1.2
				
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
		-- invalid values(empty, missing, non existent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: Check processing requests with out of lower and upper bound values 

			--Begin Test case NegativeRequestCheck.1
			--Description:

				--Requirement id in JAMA:
					--SDLAQ-CRS-440
					
				--Verification criteria:
					-- The request with "menuID" value out of bounds is sent, the response with INVALID_DATA result code is returned.
								
				--Begin Test case NegativeRequestCheck.1.1
				--Description: menuID - out lower bound  				
					function Test:DeleteSubMenu_menuIDOutLowerBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 0
																})
												
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.2
				--Description: menuID - out upper bound 
					function Test:DeleteSubMenu_menuIDOutUpperBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 2000000001
																})
												
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.2				
				
			--End Test case NegativeRequestCheck.1
			
				
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Provided menuID  is not valid (does not exist)

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-443

				--Verification criteria: 
							-- The request is sent with "menuID " value which doesn't exist in SDL for current application, the response with INVALID_ID result code is returned.
				function Test:DeleteSubMenu_menuIDNotExist()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 5555
															})
											
					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			
			--End Test case PositiveRequestCheck.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-440
					
				--Verification criteria:
					--  The request with wrong data in "menuID" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					function Test:DeleteSubMenu_menuIDWrongType()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = "25"
																})
												
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
								
			--End Test case NegativeRequestCheck.3
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Delete menuID which has just been deleted 

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-443

				--Verification criteria: 
							--The response with SUCCESS result code is returned in case "menuID" is existing.
							--The request is sent with "menuID " value which doesn't exist in SDL for current application, the response with INVALID_ID result code is returned.
				
			local function DeleteSubMenu_DeleteJustDeleted()
				
				--Precondition: AddSubMenu
				function Test:AddSubMenu()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 55,
															menuName ="SubMenu55"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 55,
									menuParams = {
										menuName ="SubMenu55"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				end			
				
				--Delete SubMenu55
				function Test:DeleteSubMenu()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 55
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 55
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				
				--Delete SubMenu55 again
				function Test:DeleteSubMenu_DeleteJustDeleted()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 55
															})
											
					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
			DeleteSubMenu_DeleteJustDeleted()
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
--[[TODO: update according to APPLINK-14765
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, non existent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-34
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with non existent resultCode 
					function Test: DeleteSubMenu_ResultCodeNotExist()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 25
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 25
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)					
									
						--mobile side: expect DeleteSubMenu response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test: DeleteSubMenu_MethodOutLowerBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 25
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 25
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)					
									
						--mobile side: expect DeleteSubMenu response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with empty string in resultCode
					function Test: DeleteSubMenu_ResultCodeOutLowerBound()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 25
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 25
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)					
									
						--mobile side: expect DeleteSubMenu response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.3				
			--End Test case NegativeResponseCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-34
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters				
					function Test: DeleteSubMenu_ResponseMissingAllPArameters()					
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{}')
						end)
							
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter			
					function Test: DeleteSubMenu_MethodMissing()					
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter
					function Test: DeleteSubMenu_ResultCodeMissing()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteSubMenu"}}')
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check processing response without mandatory parameter
					function Test: DeleteSubMenu_AllMandatoryMissing()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.2.4				
			--End Test case NegativeResponseCheck.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-34
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check processing response with wrong type of method
					function Test:DeleteSubMenu_MethodWrongtype() 
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", { })
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check processing response with wrong type of resultCode
					function Test:DeleteSubMenu_ResultCodeWrongtype() 
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 26
															})
					
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteSubMenu", "code":true}}')
						end)
							
						--mobile side: expect DeleteSubMenu response
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
					--SDLAQ-CRS-34
					
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.				

				function Test: DeleteSubMenu_ResponseInvalidJson()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 27
															})
					
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
					{ 
						menuID = 27			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0 "method":"UI.DeleteSubMenu"}}')
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(12000)
				end				
			--End Test case NegativeResponseCheck.4
		]]	
			-----------------------------------------------------------------------------------------
	--[[TODO: update after resolving APPLINK-14551
			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-29, APPLINK-13276, APPLINK-14551
				--Verification criteria: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				
				--Begin Test Case NegativeResponseCheck5.1
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: DeleteSubMenu_InfoOutLowerBound()	
						--mobile side: sending request 
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 27
																})
						
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 27			
						})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
							
						--mobile side: expect DeleteSubMenu response
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
					function Test: DeleteSubMenu_InfoOutLowerBound()						
						local infoOutUpperBound = infoUpperBound.."b"
						--mobile side: sending request 
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 27
																})
						
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 27			
						})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoUpperBound })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end
				--End Test Case NegativeResponseCheck5.2
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.3
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: DeleteSubMenu_InfoWrongType()												
						--mobile side: sending request 
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 27
																})
						
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 27			
						})
						:Do(function(_,data)
							--hmi side: send Navigation.DeleteSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)
						
						--mobile side: expect DeleteSubMenu response
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
				--End Test Case NegativeResponseCheck5.3
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.4
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: DeleteSubMenu_InfoWithNewlineChar()						
						--mobile side: sending request 
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 27
																})
						
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 27			
						})
						:Do(function(_,data)
							--hmi side: send Navigation.DeleteSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect DeleteSubMenu response
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
				--End Test Case NegativeResponseCheck5.4
												
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.5
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: DeleteSubMenu_InfoWithTabChar()						
						--mobile side: sending request 
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 27
																})
						
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
						{ 
							menuID = 27			
						})
						:Do(function(_,data)
							--hmi side: send Navigation.DeleteSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect DeleteSubMenu response
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
		--Description: Checking result code responded from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-441
				--SDLAQ-CRS-445
				--SDLAQ-CRS-446
				--SDLAQ-CRS-447
				--APPLINK-8585

			--Verification criteria:
				-- The request DeleteSubMenu is sent under conditions of RAM definite for executing it. The response code OUT_OF_MEMORY is returned. 
				-- When DeleteSubMenu request for a submenu that is currently open on the screen is sent, IN_USE code is returned as a resultCode for a request.
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occurred.
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}, { code = "UNSUPPORTED_REQUEST", name = "UnsupportedRequest"}, { code = "IN_USE", name = "InUse"}}
			for i=1,#resultCodes do
				Test["DeleteSubMenu_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 28															
															})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
									{ 
										menuID = 28				
									})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error message")
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = resultCodes[i].code, info = "Error message"})
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-444

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Unregistered application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			--Description: Send DeleteSubMenu when application not registered yet.
			function Test:DeleteSubMenu_AppNotRegistered()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
				{
					menuID = 29
				})

				--mobile side: expect DeleteSubMenu response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
		--End Test case ResultCodeCheck.2	
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.3
		--Description: Policies manager must validate an RPC request as "disallowed" if it is not allowed by the back-end.

			--Requirement id in JAMA:
				--SDLAQ-CRS-2396
				--SDLAQ-CRS-767

			--Verification criteria:
				--An RPC request is not allowed by the back-end. Policies Manager validates it as "disallowed".
				--SDL rejects DeleteSubMenu request with REJECTED resultCode when current HMI level is NONE.
				
			function Test:RegisterAppInterface()				
				--mobile side: sending request 
				local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
				
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "Test Application"
					}
				})
				:Do(function(_,data)
					appID1 = data.params.application.appID
				end)
				
				--mobile side: expect response
				self.mobileSession:ExpectResponse(CorIdRegister, 
				{
					syncMsgVersion = 
					{
						majorVersion = 3,
						minorVersion = 0
					}
				})
				:Timeout(2000)

				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus", 
				{ 
					systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
				})
				:Timeout(2000)

				DelayedExp()
			end
			
			--Description: Send DeleteSubMenu when HMI level is NONE
			function Test:DeleteSubMenu_DisallowedHMINone()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 30
														})
										
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				
				DelayedExp()
			end			
		--End Test case ResultCodeCheck.3
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.4
		--Description: Policies Manager must validate an RPC request as "userDisallowed" if the request is allowed by the back-end but disallowed by the use

			--Requirement id in JAMA:
				--SDLAQ-CRS-2394

			--Verification criteria:
				--An RPC request is allowed by the backend but disallowed by the user. Policy Manager validates it as "userDisallowed"
			
			--Description: Activate application
			function Test:ActivationApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appID1})
				
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					if					
						data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						
						--hmi side: expect SDL.GetUserFriendlyMessage message response
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)						
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
						end)

						--hmi side: expect BasicCommunication.ActivateApp request
						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							--hmi side: sending BasicCommunication.ActivateApp response
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(Any)
					end
				end)				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
			end
								
			--Description: Adding SubMenu(AddSubMenus)		
				for i=30,42 do
					Test["AddSubMenuWithId"..i] = function(self)
						--mobile side: sending request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = i,
																	menuName = "SubMenu"..tostring(i)
																})
						
						--hmi side: expect UI.AddSubMenu request 
						EXPECT_HMICALL("UI.AddSubMenu", 
						{ 
							menuID = i,
							menuParams = { menuName = "SubMenu"..tostring(i) }
						})
						:Do(function(_,data)
							--hmi side: expect UI.AddSubMenu response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect response and notification
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				end
--[[TODO: UnComment after APPLINK-13101 is resolved
			
			--Description: Disallowed DeleteSubMenu
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
						--print("OnSystemRequest notification is received")
						--mobile side: sending SystemRequest request 
						local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
							{
								fileName = "PolicyTableUpdate",
								requestType = "PROPRIETARY"
							},
						"files/PTU_ForDeleteSubMenu.json")
						
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
								--print("SDL.GetUserFriendlyMessage is received")
								
								--hmi side: sending SDL.GetListOfPermissions request to SDL
								local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
								
								-- hmi side: expect SDL.GetListOfPermissions response
								EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
								:Do(function(_,data)
									--print("SDL.GetListOfPermissions response is received")
									
									--hmi side: sending SDL.OnAppPermissionConsent
									self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
									end)
									EXPECT_NOTIFICATION("OnPermissionsChange")                    
							end)
						end)						
					end)
				end)	
			end
			
			--Description: Send DeleteSubMenu when user not allowed
			function Test:DeleteSubMenu_UserDisallowed()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 31
														})
										
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)	
			end
			
			--Description: Allowed DeleteSubMenu for another test cases	
			function Test:AllowedDeleteSubMenu()
				self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})		  
			end
		
		--End Test case ResultCodeCheck.4
]]		
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
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behaviour in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behaviour in case of absence of responses from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-447
				--APPLINK-8585
				
			--Verification criteria:				
				-- no UI response during SDL`s watchdog.
			
			function Test:DeleteSubMenu_NoResponseFromUI()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 32
														})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu", 
								{ 
									menuID = 32
								})
				
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(12000)
			end
						
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-34
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.		
				
			function Test: DeleteSubMenu_ResponseInvalidStructure()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 33
														})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu", 
								{ 
									menuID = 33
								})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubMenu response
					self.hmiConnection:Send('{"error":{"code":4,"message":"DeleteSubMenu is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.DeleteSubMenu"}}')	
				end)
					
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
				:Timeout(12000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(12000)
			end						
		--End Test case HMINegativeCheck.2
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-34
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:DeleteSubMenu_SeveralResponseToOneRequest()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 34
														})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu", 
								{ 
									menuID = 34
								})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)
					
				--mobile side: expect DeleteSubMenu response
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
				--SDLAQ-CRS-34
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:DeleteSubMenu_FakeParamsInResponse()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 35
															})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
									{ 
										menuID = 35
									})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
					end)
						
					--mobile side: expect DeleteSubMenu response
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
				function Test:DeleteSubMenu_ParamsFromOtherAPIInResponse()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 36
															})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
									{ 
										menuID = 36
									})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)
						
					--mobile side: expect DeleteSubMenu response
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
				--SDLAQ-CRS-34
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:DeleteSubMenu_WrongResponseToCorrectID()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
															menuID = 40
														})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu", 
								{ 
									menuID = 40
								})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubMenu response
					self.hmiConnection:SendResponse(data.id, "VR.DeleteSubMenu", "SUCCESS", {})						
				end)
					
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
				:Timeout(12000)
					
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.5
		
	--End Test suit HMINegativeCheck

	
	
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
				--SDLAQ-CRS-767
				
			--Verification criteria: 
				--SDL doesn't reject DeleteSubMenu request when current HMI is FULL.
				--SDL doesn't reject DeleteSubMenu request when current HMI is LIMITED.
				--SDL doesn't reject DeleteSubMenu request when current HMI is BACKGROUND.
			
		if Test.isMediaApplication == true or 
		Test.appHMITypes["NAVIGATION"] == true then
			--Begin DifferentHMIlevel.1.1
			--Description: SDL doesn't reject DeleteSubMenu request when current HMI is LIMITED.
				function Test:ChangeHMIToLimited()
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end
				
				function Test:DeleteSubMenu_HMILevelLimited()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
															{
																menuID = 41
															})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu", 
									{ 
										menuID = 41
									})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
						
					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")					
				end
			--End DifferentHMIlevel.1.1
			
			--Begin DifferentHMIlevel.1.2
			--Description: SDL doesn't reject DeleteSubMenu request when current HMI is BACKGROUND.
				
				--Description:Start second session
					function Test:Precondition_SecondSession()
					  self.mobileSession1 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end
				
				--Description "Register second app"
					function Test:Precondition_AppRegistrationInSecondSession()
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
								  self.applications["Test Application2"] = data.params.application.appID
								end)

								self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })

							end)
						end
					
				--Description: Activate second app
					function Test:ActivateSecondApp()
						local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application2"]})
						EXPECT_HMIRESPONSE(rid)
						
						self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end
		elseif
				Test.isMediaApplication == false then
				--Precondition for non-media app type

				function Test:ChangeHMIToBackground()
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

		end		
				--Description: DeleteSubMenu when HMI level BACKGROUND
					function Test:DeleteSubMenu_HMILevelBackground()
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = 42
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = 42
										})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--mobile side: expect DeleteSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")						
					end
			--End DifferentHMIlevel.1.2			
		--End Test case DifferentHMIlevel.1		

	--End Test suit DifferentHMIlevel
