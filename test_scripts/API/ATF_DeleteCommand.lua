Test = require('connecttest')	
require('cardinalities')

local module = require("testbase")
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	

local groupID
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
			appID1 = self.applications["Test Application"]
			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
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

	-----------------------------------------------------------------------------------------

	--Begin Precondition.2
	--Description: Putting file(PutFiles)
		function Test:PutFile()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("PutFile",
				{			
					syncFileName = "icon.png",
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")
				
				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true})			
		end
	--End Precondition.2
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.3
	--Description: Adding SubMenu(AddSubMenus)
		local menuIDValues = {1, 10}
		for i=1,#menuIDValues do
			Test["AddSubMenuWithId"..menuIDValues[i]] = function(self)
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = menuIDValues[i],
					menuName = "SubMenu"..tostring(i)
				})
				
				--hmi side: expect UI.AddSubMenu request 
				EXPECT_HMICALL("UI.AddSubMenu", 
				{ 
					menuID = menuIDValues[i],
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
	--End Precondition.3
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.4
	--Description: AddCommand to Submenu with cmdID = 10
		function Test:AddCommand_11ToSubMenu10()
			--mobile side: sending request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 11,
				menuParams = { parentID = 10, position = 1000, menuName ="Command11"}, 
				vrCommands ={"VR11"}, 
				cmdIcon = { value ="icon.png", imageType ="DYNAMIC"	}
			})
			
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = 11,
				--cmdIcon = {value = storagePath.."icon.png",imageType = "DYNAMIC"}, --Verification is done below
				menuParams = {parentID = 10, position = 1000, menuName ="Command11"}
			})
			:ValidIf(function(_,data)
          				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
          				local value_Icon = path .. "action.png"
          
          				if(data.params.cmdIcon.imageType == "DYNAMIC") then
              				return true
          				else
              				print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. "\27[0m")
              				return false
          				end

          				if(string.find(data.params.cmdIcon.value, value_Icon) ) then
                  			return true
              			else
                  			print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
                  			return false
              			end
      				end)
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
				--hmi side: sending VR.DeleteCommand response
				grammarIDValue = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)			
			
			--mobile side: expect response and notification
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			EXPECT_NOTIFICATION("OnHashChange")
		end
	--End Precondition.4
	
	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.5
	--Description: Adding commands to both UI and VR
		local commandIDValues = { 0, 22, 33, 44, 55, 66, 77, 88, 99, 100, 101, 102, 103, 104, 333, 444, 555, 666, 777, 888, 999, 1010, 1111, 1212, 1313, 1234567890, 2000000000}
			for i=1,#commandIDValues do
				Test["AddCommandWithId"..commandIDValues[i]] = function(self)
					--mobile side: sending AddCommand request 
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = commandIDValues[i],
						menuParams = 	
						{
							menuName = "CommandID"..tostring(commandIDValues[i])
						},
						vrCommands = 
						{ 
							"VRCommand"..tostring(commandIDValues[i])
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = commandIDValues[i],
						menuParams = 
						{
							menuName ="CommandID"..tostring(commandIDValues[i])
						}
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)			

					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = commandIDValues[i],
						vrCommands = 
						{ 
							"VRCommand"..tostring(commandIDValues[i])
						}
					})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")	
			end
		end
	--End Precondition.5
	
	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.6
	--Description: Adding commands to UI only
		function Test:AddCommand_UIOnly()
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 1,
				menuParams = 	
				{
					menuName ="CommandID"..tostring(1)
				}
			})
			
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = 1,
				menuParams = 
				{
					menuName ="CommandID"..tostring(1)
				}
			})
			:Do(function(_,data)
				--hmi side: sending UI.DeleteCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)			
			
			--mobile side: expect DeleteCommand response 
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			EXPECT_NOTIFICATION("OnHashChange")	
		end
	--End Precondition.6
	
	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.7
	--Description: Adding commands to VR only
		function Test:AddCommand_VROnly()
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 2,
				vrCommands = 
				{ 
					"VRCommand"..tostring(2)
				}
			})
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
			{ 
				cmdID = 2,
				vrCommands = 
				{ 
					"VRCommand"..tostring(2)
				}
			})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect DeleteCommand response 
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			EXPECT_NOTIFICATION("OnHashChange")	
		end
	--End Precondition.7
	
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
		--Description:Positive case and in boundary conditions

			--Requirement id in JAMA: 
					--SDLAQ-CRS-25, 
					--SDLAQ-CRS-417

			--Verification criteria: 
					--DeleteCommand request removes the command with corresponding cmdID from the application and SDL.
					--In case SDL can't delete the command with corresponding cmdID from the application, SDL provides the appropriate data about error occured.
					--Deleting the command from VR command menu only is executed successfully. The SUCCESS response code is returned.
					--Deleting the command from UI Command menu only is executed successfully. The SUCCESS response code is returned.
					--Deleting the command from both UI and VR Command menu is executed successfully. The SUCCESS response code is returned.
			
			--Begin Test case CommonRequestCheck.1.1
			--Description: DeleteCommand from both UI and VR Command menu in main menu
				function Test:DeleteCommand_PositiveMainMenu()				
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 1234567890
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 1234567890
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 1234567890
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
								
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.1.1
			
			----------------------------------------------------------------------------------------- 
			
			--Begin Test case CommonRequestCheck.1.2
			--Description: DeleteCommand from both UI and VR Command menu in sub menu
				function Test:DeleteCommand_PositiveSubMenu()
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 11
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
								
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.1.3
			--Description: DeleteCommand from UI command menu only
				function Test:DeleteCommand_UICommandOnly()
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 1
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 1
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)			
								
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					EXPECT_NOTIFICATION("OnHashChange")
				end		
			--End Test case CommonRequestCheck.1.3
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.1.4
			--Description: DeleteCommand from VR command menu only
				function Test:DeleteCommand_VRCommandOnly()
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 2
					})
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 2
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)			
								
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					EXPECT_NOTIFICATION("OnHashChange")
				end		
			--End Test case CommonRequestCheck.1.4	
		
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description:with fake parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-25
					--APPLINK-4518
					
			--Verification criteria: 
					--DeleteCommand request removes the command with corresponding cmdID from the application and SDL.
					--In case SDL can't delete the command with corresponding cmdID from the application, SDL provides the appropriate data about error occured.
				
			--Begin Test case CommonRequestCheck.2.1
			--Description:DeleteCommand with parameter not from protocol
				function Test:DeleteCommand_WithFakeParam()
					
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 22,
						fakeParam ="fakeParam",
					})
					
					--hmi side: expect UI.DeleteCommand request 
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 22
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam ~= nil then
								print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
								return false
						else 
							return true
						end
					end)
					
					--hmi side: expect VR.DeleteCommand request 
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 22
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam ~= nil then
								print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
								return false
						else 
							return true
						end
					end)
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = SUCCESS })	
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")					
				end
			--End Test case CommonRequestCheck.2.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description:DeleteCommand with parameter from another request 
				function Test:DeleteCommand_ParamsAnotherRequest()
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						menuID = 33
					})		
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.2.2
			
		--End Test case CommonRequestCheck.2		
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: Check processing request with invalid JSON syntax 

			--Requirement id in JAMA: 
					--SDLAQ-CRS-418

			--Verification criteria:  
					--The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

			function Test:DeleteCommand_IncorrectJSON()

				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 6,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"cmdID" 104}'
				}
				self.mobileSession:Send(msg)
				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA:
					--SDLAQ-CRS-418

			--Verification criteria:  
					--Send request with all parameters are missing

			function Test:DeleteCommand_MissingAllParams()
				--mobile side: DeleteCommand request 
				local cid = self.mobileSession:SendRPC("DeleteCommand",{}) 
			 
			    --mobile side: DeleteCommand response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)				
			end
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: different conditions of correlationID parameter (invalid, several the same etc.)

			--Requirement id in JAMA:
			--Verification criteria: correlationID duplicate
						
				function Test:DeleteCommand_CorrelationIDDuplicateValue()
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 666
					})
					
					--request from mobile side
					local msg = 
					{
					  serviceType      = 7,
					  frameInfo        = 0,
					  rpcType          = 0,
					  rpcFunctionId    = 6,
					  rpcCorrelationId = cid,
					  payload          = '{"cmdID": 777}'
					}
				
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ cmdID = 666 },
					{ cmdID = 777 })
					:Do(function(exp,data)

						if exp.occurences ==1 then 
							self.mobileSession:Send(msg)
						end

						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(2)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ cmdID = 666}, 
					{ cmdID = 777})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(2)
					
					--response on mobile side
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Times(2)

					EXPECT_NOTIFICATION("OnHashChange")
					:Times(2)
				end			
		--End Test case CommonRequestCheck.5
	--Begin Test suit PositiveRequestCheck
	

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
							-- SDLAQ-CRS-25

				--Verification criteria: 
							-- DeleteCommand request removes the command with corresponding cmdID from the application and SDL.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: cmdID lower bound					
					function Test:DeleteCommand_cmdIDLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 0
						})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 0
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 0
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
									
						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						EXPECT_NOTIFICATION("OnHashChange")
					end				
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: cmdID upper bound				
					function Test:DeleteCommand_cmdIDUpperBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 2000000000
						})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 2000000000
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 2000000000
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
									
						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						EXPECT_NOTIFICATION("OnHashChange")							
					end						
				--End Test case PositiveRequestCheck.1.2				
			--End Test case PositiveRequestCheck.1
		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: Checking parameters boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA:
					--SDLAQ-CRS-26
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					
				--Begin PositiveResponseCheck.1.1
				--Description: UI response info parameter lower bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved						
					-- function Test: DeleteCommand_UIInfoLowerBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 888
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 888
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 888
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a"})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.2
				--Description: VR response info parameter lower bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: DeleteCommand_VRInfoLowerBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 999
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 999
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 999
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response							
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a"})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin PositiveResponseCheck.1.3
				--Description: UI & VR response info parameter lower bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: DeleteCommand_UIVRInfoLowerBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 1010
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1010
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1010
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response							
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b")
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a.b"})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.3

				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.4
				--Description: UI response info parameter Upper bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: DeleteCommand_UIInfoUpperBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 1111
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1111
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1111
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.5
				--Description: VR response info parameter upper bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: DeleteCommand_VRInfoUpperBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 1212
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1212
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1212
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response							
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.5
								
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.6
				--Description: UI & VR response info parameter upper bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: DeleteCommand_UIVRInfoUpperBound()
					-- 	--mobile side: sending DeleteCommand request
					-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
					-- 	{
					-- 		cmdID = 1313
					-- 	})
						
					-- 	--hmi side: expect UI.DeleteCommand request
					-- 	EXPECT_HMICALL("UI.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1313
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.DeleteCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
					-- 	end)
						
					-- 	--hmi side: expect VR.DeleteCommand request
					-- 	EXPECT_HMICALL("VR.DeleteCommand", 
					-- 	{ 
					-- 		cmdID = 1313
					-- 	})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.DeleteCommand response							
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
					-- 	end)
							
					-- 	--mobile side: expect DeleteCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.6
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
		--Description: Check of each request parameter value outbound conditions
			
			--Begin Test case NegativeRequestCheck.1
			--Description: cmdID with wrong type

				--Requirement id in JAMA:					
					-- SDLAQ-CRS-25,
					-- SDLAQ-CRS-418
				--Verification criteria:
					--The request with string data in "cmdID" value is sent, the response with INVALID_DATA result code is returned.
				function Test:DeleteCommand_cmdIDWrongType()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = "44"
					})		
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end				
			--End Test case NegativeRequestCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Checking cmdID value outbound

				--Requirement id in JAMA:					
					-- SDLAQ-CRS-25,
					-- SDLAQ-CRS-418
				--Verification criteria:
					--The request with "cmdID" value out of bounds is sent, the response with INVALID_DATA result code is returned.
				
				--Begin Test case NegativeRequestCheck.2.1
				--Description: cmdID out lower bound
					function Test:DeleteCommand_cmdIDOutLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = -1
						})

						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.2
				--Description: cmdID out upper bound
					function Test:DeleteCommand_cmdIDOutUpperBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 2000000001
						})

						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.2.2				
			--End Test case NegativeRequestCheck.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.3
			--Description: Provided cmdID  is not valid(does not  exist)

				--Requirement id in JAMA:					
					-- SDLAQ-CRS-25,
					-- SDLAQ-CRS-418
				--Verification criteria:
					--The request is sent with "cmdID" value which does not exist in SDL for the current application, the response comes with result code INVALID_ID.
					function Test:DeleteCommand_cmdIDNotExist()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 9999
						})

						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
			--End Test case NegativeRequestCheck.3
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Delete menuID which has just been deleted 

				--Requirement id in JAMA:					
					-- SDLAQ-CRS-25,
					-- SDLAQ-CRS-418
				--Verification criteria:
					--The response with SUCCESS result code is returned in case "cmdID" is existing.
					--The request is sent with "cmdID" value which does not exist in SDL for the current application, the response comes with result code INVALID_ID.
				local function DeleteCommand_DeleteJustDeleted()
					--Precondition: AddCommand
					function Test:AddCommand_Success()
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 502,
							menuParams = 	
							{
								menuName = "Command502"
							},
							vrCommands = 
							{ 
								"VRCommand502"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 502,
							menuParams = 
							{
								menuName ="Command502"
							}
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			

						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 502,
							vrCommands = 
							{ 
								"VRCommand502"
							}
						})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")	
						end
						
					--Description: Delete Command502
					function Test:Delete_cmdID502()				
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 502
						})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 502
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 502
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
									
						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						EXPECT_NOTIFICATION("OnHashChange")
					end
				
					----Description: Delete Command502 once more time 
					function Test:DeleteCommand_cmdID502NotExist()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 502
						})

						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end	
				end
				DeleteCommand_DeleteJustDeleted()
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
		--End Test suit NegativeRequestCheck

			

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
					--SDLAQ-CRS-26
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check UI response with nonexistent resultCode 
					function Test: DeleteCommand_UIResponseResultCodeNotExist()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check VR response with nonexistent resultCode 
					function Test: DeleteCommand_VRResponseResultCodeNotExist()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check UI response with empty string in method
					function Test: DeleteCommand_UIResponseMethodOutLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check VR response with empty string in method
					function Test: DeleteCommand_VRResponseMethodOutLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check UI response with empty string in resultCode
					function Test: DeleteCommand_UIResponseResultCodeOutLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.6
				--Description: Check VR response with empty string in resultCode
					function Test: DeleteCommand_VRResponseResultCodeOutLowerBound()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)							
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.6				
			--End Test case NegativeResponseCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-26
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check UI response without all parameters				
					function Test: DeleteCommand_UIResponseMissingAllPArameters()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:Send({})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check VR response without all parameters				
					function Test: DeleteCommand_VRResponseMissingAllPArameters()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send({})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check UI response without method parameter			
					function Test: DeleteCommand_UIResponseMethodMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check VR response without method parameter			
					function Test: DeleteCommand_VRResponseMethodMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check UI response without resultCode parameter
					function Test: DeleteCommand_UIResponseResultCodeMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteCommand"}}')
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check VR response without resultCode parameter
					function Test: DeleteCommand_VRResponseResultCodeMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.DeleteCommand"}}')
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check UI response without mandatory parameter
					function Test: DeleteCommand_UIResponseAllMandatoryMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.8
				--Description: Check VR response without mandatory parameter
					function Test: DeleteCommand_VRResponseAllMandatoryMissing()					
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.8				
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-26
					
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check UI response with wrong type of method
					function Test:DeleteCommand_UIResponseMethodWrongtype() 
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check VR response with wrong type of method
					function Test:DeleteCommand_VRResponseMethodWrongtype() 
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })						
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check UI response with wrong type of resultCode
					function Test:DeleteCommand_UIResponseResultCodeWrongtype() 
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteCommand", "code":true}}')
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check VR response with wrong type of resultCode
					function Test:DeleteCommand_VRResponseResultCodeWrongtype() 
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.DeleteCommand", "code":true}}')							
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.3.4				
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-26
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.4.1
				--Description: Check UI response with invalid json
					function Test: DeleteCommand_UIResponseInvalidJson()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteCommand", "code":0}}')
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.4.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.4.2
				--Description: Check VR response with invalid json
					function Test: DeleteCommand_VRResponseInvalidJson()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.DeleteCommand", "code":0}}')
						end)			
							
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.4.2
			--End Test case NegativeResponseCheck.4
	]]
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-26
					--APPLINK-13276
					--APPLINK-14551
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
	--[[TODO: update according to APPLINK-14551
				--Begin Test Case NegativeResponseCheck5.1
				--Description: UI response with empty info
					function Test:DeleteCommand_UIResponseInfoOutLowerBound()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response
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
				--Description: VR response with empty info
					function Test: DeleteCommand_VRResponseInfoOutLowerBound()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck5.3
				--Description: UI & VR response with empty info
					function Test: DeleteCommand_UIVRResponseInfoOutLowerBound()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--Description: UI response with empty info, VR response with inbound info
					function Test: DeleteCommand_UIInfoOutLowerBoundVRInfoInBound()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")
						end)
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck5.5
				--Description: VR response with empty info, UI response with inbound info
					function Test: DeleteCommand_VRInfoOutLowerBoundUIInfoInBound()	
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.5
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.6
				--Description: UI response info out of upper bound
					function Test: DeleteCommand_UIResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end
				--End Test Case NegativeResponseCheck5.6
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.7
				--Description: VR response info out of upper bound
					function Test: DeleteCommand_VRResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End Test Case NegativeResponseCheck5.7
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.8
				--Description: UI & VR response info out of upper bound
					function Test: DeleteCommand_UIVRResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect DeleteCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end
				--End Test Case NegativeResponseCheck5.8
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.9
				--Description: UI response with wrong type of info parameter
					function Test: DeleteCommand_UIResponseInfoWrongType()												
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.9
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.10
				--Description: VR response with wrong type of info parameter
					function Test: DeleteCommand_VRResponseInfoWrongType()												
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.10
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.10
				--Description: UI & VR response with wrong type of info parameter
					function Test: DeleteCommand_UIVRResponseInfoWrongType()												
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.10
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.11
				--Description: UI response with escape sequence \n in info parameter
					function Test: DeleteCommand_UIResponseInfoWithNewlineChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.11
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.12
				--Description: VR response with escape sequence \n in info parameter
					function Test: DeleteCommand_VRResponseInfoWithNewlineChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.12
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.13
				--Description: UI & VR response with escape sequence \n in info parameter
					function Test: DeleteCommand_UIVRResponseInfoWithNewlineChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.13
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.14
				--Description: UI response with escape sequence \t in info parameter
					function Test: DeleteCommand_UIResponseInfoWithNewTabChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.14
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.15
				--Description: VR response with escape sequence \t in info parameter
					function Test: DeleteCommand_VRResponseInfoWithNewTabChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.15
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.16
				--Description: UI & VR response with escape sequence \t in info parameter
					function Test: DeleteCommand_UIVRResponseInfoWithNewTabChar()						
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 888
																				})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 888
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response							
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect DeleteCommand response
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
				--End Test Case NegativeResponseCheck5.16						
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
				--SDLAQ-CRS-419
				--SDLAQ-CRS-422
				--SDLAQ-CRS-424
				--SDLAQ-CRS-425

			--Verification criteria:
				-- The DeleteCommand request is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned.
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.				
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				-- DeleteCommand request for a command related to a SubMenu currently opened on the screen is sent, the IN_USE result responseCode is returned.

			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}, { code = "UNSUPPORTED_REQUEST", name = "UnsupportedRequest"}}
			for i=1,#resultCodes do
				Test["DeleteCommand_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 66
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error message")
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error message")
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = resultCodes[i].code--[[ TODO APPLINK-14569, info = "Error message"]]})
											
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
		--End Test case ResultCodeCheck.1
		
--[[TODO: update according to APPLINK-13169		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.2
		--Description: Checking result code responded from HMI when response from UI is SUCCESS but response from VR is ERROR

			--Requirement id in JAMA:
				--SDLAQ-CRS-419
				--SDLAQ-CRS-422
				--SDLAQ-CRS-424
				--SDLAQ-CRS-425

			--Verification criteria:
				-- The DeleteCommand request is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned.
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.				
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				-- DeleteCommand request for a command related to a SubMenu currently opened on the screen is sent, the IN_USE result responseCode is returned.
				
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}, { code = "UNSUPPORTED_REQUEST", name = "UnsupportedRequest"}}
			for i=1,#resultCodes do
				Test["DeleteCommand_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 66
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS", {})
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendError(data.id,data.method, resultCodes[i].code, "Error message")
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = resultCodes[i].code})
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
		--End Test case ResultCodeCheck.2
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.3
		--Description: Checking result code responded from HMI when response from UI is ERROR but response from VR is SUCCESS

			--Requirement id in JAMA:
				--SDLAQ-CRS-419
				--SDLAQ-CRS-422
				--SDLAQ-CRS-424
				--SDLAQ-CRS-425

			--Verification criteria:
				-- The DeleteCommand request is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned.
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.				
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				-- DeleteCommand request for a command related to a SubMenu currently opened on the screen is sent, the IN_USE result responseCode is returned.
				
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, {code = "REJECTED", name = "Reject"},{ code = "UNSUPPORTED_REQUEST", name = "UnsupportedRequest"}, { code = "IN_USE", name = "InUse"}}
			for i=1,#resultCodes do
				Test["DeleteCommand_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 66
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendError(data.id,data.method, resultCodes[i].code, "Error message")						
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 66			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = resultCodes[i].code})
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
		--End Test case ResultCodeCheck.3
--]]		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.4
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-423

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Unregistered application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			--Description: Send DeleteCommand when application not registered yet.
			function Test:DeleteCommand_AppNotRegistered()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
				{
					cmdID = iCmdID
				})

				--mobile side: expect DeleteCommand response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
		--End Test case ResultCodeCheck.4	
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.5
		--Description: DISALLOWED response code is sent by SDL when the request isn't authorized in policy table.

			--Requirement id in JAMA:
				--SDLAQ-CRS-766

			--Verification criteria:
				--SDL sends DISALLOWED code when the request isn't authorized in policy table.			
			--TODO: Please note that TC fails due to APPLINK-25528, remove this comment once it is fixed 
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
					self.applications["Test Application"] = data.params.application.appID
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

				--ToDo: Should be uncommented when APPLINK-24902 is resolved 
				-- --mobile side: expect notification
				-- self.mobileSession:ExpectNotification("OnHMIStatus", 
				-- { 
				-- 	systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
				-- })
				-- :Timeout(2000)

				DelayedExp()
			end
			
			--ToDo: Remove when APPLINK-24902 is resolved 
			--TODO: Please note that TC fails due to APPLINK-25528 remove this comment once it is fixed  
			function Test:ReRegisterAppInterface()				
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
					self.applications["Test Application"] = data.params.application.appID
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

			--Description: Send AddCommand when HMI level is NONE
			function Test:DeleteCommand_DisallowedHMINone()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
				{
					cmdID = 1234567890
				})

				--mobile side: expect DeleteCommand response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
		--End Test case ResultCodeCheck.5
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.6
		--Description: USER-DISALLOWED response code is sent by SDL when the request isn't allowed by user.

			--Requirement id in JAMA:
				--SDLAQ-CRS-766

			--Verification criteria:
				--SDL sends USER-DISALLOWED code when the request isn't allowed by user.	
			
			--Description: Activate application
			function Test:Precondition_ActivationApp()
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
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
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

			--Description: Disallowed DeleteCommand
			--TODO: Should be uncommented when APPLINK-25363 is resolved 
			-- local groupID
			-- function Test:Precondition_UserDisallowedPolicyUpdate()
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
			-- 			"files/PTU_ForDeleteCommand.json")
						
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
			-- 				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
			-- 				:Do(function(_,data)
			-- 					--print("SDL.GetUserFriendlyMessage is received")
								
			-- 					--hmi side: sending SDL.GetListOfPermissions request to SDL
			-- 					local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
								
			-- 					-- hmi side: expect SDL.GetListOfPermissions response
			-- 					-- TODO:  EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ name = "New"}}}})
			-- 					EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
			-- 					:Do(function(_,data)
			-- 						print("SDL.GetListOfPermissions response is received")
									
			-- 						groupID = data.result.allowedFunctions[1].id

			-- 						--hmi side: sending SDL.OnAppPermissionConsent
			-- 						self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = groupID, name = "New"}}, source = "GUI"})
			-- 						end)
			-- 						EXPECT_NOTIFICATION("OnPermissionsChange")                    
			-- 				end)
			-- 			end)
						
			-- 		end)
			-- 	end)	
			-- end
			
			--Description: Send DeleteCommand when user not allowed
			--TODO: Should be uncommented when APPLINK-25363 is resolved 
			-- function Test:DeleteCommand_UserDisallowed()
			-- 	--mobile side: sending DeleteCommand request
			-- 	local cid = self.mobileSession:SendRPC("DeleteCommand",
			-- 	{
			-- 		cmdID = 1234567890
			-- 	})

			-- 	--mobile side: expect DeleteCommand response 
			-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })	
						
			-- 	--mobile side: expect OnHashChange notification is not send to mobile
			-- 	EXPECT_NOTIFICATION("OnHashChange")
			-- 	:Times(0)
			-- end
			
		--End Test case ResultCodeCheck.6
		
	--End Test suit ResultCodeCheck

	

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Allowed DeleteCommand for another test cases	
		function Test:AllowedDeleteCommand()
			self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = groupID, name = "New"}}, source = "GUI"})		  
		end		
	--End Precondition.1

	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.2
	--Description: Adding commands to both UI and VR
		local commandIDValues = {11, 22, 33, 44, 55, 66, 77, 88, 99, 100, 110, 120}
			for i=1,#commandIDValues do
				Test["AddCommandWithId"..commandIDValues[i]] = function(self)
					--mobile side: sending AddCommand request 
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = commandIDValues[i],
						menuParams = 	
						{
							menuName = "CommandID"..tostring(commandIDValues[i])
						},
						vrCommands = 
						{ 
							"VRCommand"..tostring(commandIDValues[i])
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = commandIDValues[i],
						menuParams = 
						{
							menuName ="CommandID"..tostring(commandIDValues[i])
						}
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)			

					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = commandIDValues[i],
						vrCommands = 
						{ 
							"VRCommand"..tostring(commandIDValues[i])
						}
					})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
			end
		end
	--End Precondition.2	
	
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
	--Description: 

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Provided data is valid but something went wrong in the lower layers.
			-- Unknown issue (other result codes can't be applied )
			-- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			--Requirement id in JAMA:
				--SDLAQ-CRS-425
				
			--Verification criteria:				
				-- no UI response during SDL`s watchdog.
			
			--Begin HMINegativeCheck.1.1
			--Description: Response from UI but no response from VR
				function Test:DeleteCommand_ResponseFromUINoResponseFromVR()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 11
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
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.1
			
			-----------------------------------------------------------------------------------------

			--Begin HMINegativeCheck.1.2
			--Description: Response from VR but no response from UI
				function Test:DeleteCommand_ResponseFromVRNoResponseFromUI()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 11
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						
					end)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.2	
			-----------------------------------------------------------------------------------------

			--Begin HMINegativeCheck.1.3
			--Description: No response from UI & VR
				function Test:DeleteCommand_NoResponseFromUIVR()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 11
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						
					end)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.3
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Invalid structure of response

			--Requirement id in JAMA:
				--SDLAQ-CRS-26
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
--[[TODO: update according to APPLINK-14765		
			--Begin Test case HMINegativeCheck.2.1
			--Description: UI&VR.DeleteCommand response with invalid structure
				function Test: DeleteCommand_ResponseInvalidStructure()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 55
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"UI.DeleteCommand"}}')
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"VR.DeleteCommand"}}')
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case HMINegativeCheck.2.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.2
			--Description: UI.DeleteCommand response with invalid structure
				function Test:DeleteCommand_UIResponseInvalidStructure()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 55
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response					
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"UI.DeleteCommand"}}')						
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response					
						self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "SUCCESS", {})						
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end									
			--End Test case HMINegativeCheck.2.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.2.3
			--Description: VR.DeleteCommand response with invalid structure
				function Test:DeleteCommand_VRResponseInvalidStructure()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 55
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response					
						self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "SUCCESS", {})						
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 55			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"VR.DeleteCommand"}}')						
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end									
			--End Test case HMINegativeCheck.2.3
		--End Test case HMINegativeCheck.2
]]	
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Send responses from HMI with fake parameter

			--Requirement id in JAMA:
				--SDLAQ-CRS-26
				
			--Verification criteria:
				-- --The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.		
			
			--Begin Test case HMINegativeCheck.3.1
			--Description: Parameter not from API
				function Test:DeleteCommand_FakeParamsInResponse()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 100
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 100		
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 100		
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.fake then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)

					EXPECT_NOTIFICATION("OnHashChange")
				end								
			--End Test case HMINegativeCheck.3.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: Parameter from another API
				function Test:DeleteCommand_ParamsFromOtherAPIInResponse()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 110
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 110			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 110		
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})		
					:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" SDL resend fake parameter to mobile app ")
								return false
							else 
								return true
							end
					end)

					EXPECT_NOTIFICATION("OnHashChange")
				end								
			--End Test case HMINegativeCheck.3.2
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-26
				
			--Verification criteria:
				--Send several response to one request	
			
			function Test:DeleteCommand_SeveralResponseToOneRequest()
				--mobile side: sending request 
				local cid = self.mobileSession:SendRPC("DeleteCommand",
				{
					cmdID = 120
				})
				
				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand", 
				{ 
					cmdID = 120			
				})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteCommand response					
					self.hmiConnection:SendError( data.id , "UI.DeleteCommand" , "GENERIC_ERROR", "UI.DeleteCommand error")
					self.hmiConnection:SendResponse( data.id , "UI.DeleteCommand" , "INVALID_DATA", {})
				end)	
				
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand", 
				{ 
					cmdID = 120			
				})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response					
					self.hmiConnection:SendError( data.id , "VR.DeleteCommand" , "GENERIC_ERROR", "VR.DeleteCommand error")
					self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "INVALID_DATA", {})
				end)
				
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end									
			
		--End Test case HMINegativeCheck.4
	
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- HMI correlation id check

			--Requirement id in JAMA:
				--SDLAQ-CRS-26
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				function Test:DeleteCommand_WrongResponseToCorrectID()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 77
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 77			
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response					
						self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "SUCCESS", {})
					end)	
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 77			
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response					
						self.hmiConnection:SendResponse( data.id , "UI.DeleteCommand" , "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})		
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
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
				--SDLAQ-CRS-766
			--Verification criteria: 
				--SDL doesn't reject DeleteCommand request when current HMI is FULL.
				--SDL doesn't reject DeleteCommand request when current HMI is LIMITED.
				--SDL doesn't reject DeleteCommand request when current HMI is BACKGROUND.
		if 
			Test.isMediaApplication == true or 
			appHMITypes["NAVIGATION"] == true then				
			--Begin Test case DifferentHMIlevel.1.1
			--Description: SDL doesn't reject DeleteCommand request when current HMI is LIMITED.
				function Test:Precondition_ChangeHMIToLimited()					
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end
				
				function Test:DeleteCommand_HMILevelLimited()
					--mobile side: sending DeleteCommand request
					local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
						cmdID = 22
					})
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand", 
					{ 
						cmdID = 22
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand", 
					{ 
						cmdID = 22
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
								
					--mobile side: expect DeleteCommand response 
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case DifferentHMIlevel.1.1
			
			--Begin Test case DifferentHMIlevel.1.2
			--Description: SDL doesn't reject DeleteCommand request when current HMI is BACKGROUND.
				
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

								self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

							end)
						end
					
				--Description: Activate second app
					function Test:Precondition_ActivateSecondApp()
						local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application2"]})
						EXPECT_HMIRESPONSE(rid)
						
						self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
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
					
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end

		end			
				--Description: DeleteCommand when HMI level BACKGROUND
					function Test:DeleteCommand_HMILevelBackground()
						--mobile side: sending DeleteCommand request
						local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
							cmdID = 33
						})
						
						--hmi side: expect UI.DeleteCommand request
						EXPECT_HMICALL("UI.DeleteCommand", 
						{ 
							cmdID = 33
						})
						:Do(function(_,data)
							--hmi side: sending UI.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand", 
						{ 
							cmdID = 33
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
									
						--mobile side: expect DeleteCommand response 
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						EXPECT_NOTIFICATION("OnHashChange")
					end
			--End Test case DifferentHMIlevel.1.2			
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel
