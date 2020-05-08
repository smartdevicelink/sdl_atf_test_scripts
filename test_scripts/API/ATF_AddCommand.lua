Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local imageValues = {"i", "icon.png", "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTY"}
local grammarIDValue
local appId2
local infoMessage = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'"




local function SendOnSystemContext(self, ctx, appIDValue)
	if appIDValue == nil then
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
	else
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appIDValue, systemContext = ctx })
	end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
	--Begin Common.1
	--Description: AddCommand to specified position
		--iCmdID : unique ID of the command to add
		--iPosition: Position within the items that are are at top level of the in application menu.
		--bSucccess: Expected success (true, false)
		--sResultCode: Expected resultCode ("SUCCESS", "INVALID_DATA", ...)
		function AddCommand_Position(self, iCmdID, iPosition, bSucccess, sResultCode)
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = iCmdID,
				menuParams = 	
				{
					position = iPosition,
					menuName ="Command"..tostring(iCmdID)
				}
			})
			
			--hmi side: expect UI.AddCommand request 
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = iCmdID,		
				menuParams = 
				{
					position = iPosition,
					menuName ="Command"..tostring(iCmdID)
				}
			})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, sResultCode, {})
			end)	
			
			--mobile side: expect AddCommand response 
			EXPECT_RESPONSE(cid, {  success = bSucccess, resultCode = sResultCode  })
			if sResultCode == "SUCCESS" then
				EXPECT_NOTIFICATION("OnHashChange")
			end			
		end
	--End Common.1
	
	-----------------------------------------------------------------------------------------
	
	--Begin Common.2
	--Description: AddCommand with specified image name
		--iCmdID : unique ID of the command to add
		--sImageValue: name of picture
		--bSucccess: Expected success (true, false)
		--sResultCode: Expected resultCode ("SUCCESS", "INVALID_DATA", ...)
		function AddCommand_ImageValue(self, iCmdID, sImageValue, bSucccess, sResultCode, ImageType)
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = iCmdID,
				menuParams = 	
				{
					menuName ="CommandImageValue"..tostring(iCmdID)
				},
				cmdIcon = 	
				{ 
					value = sImageValue,
					imageType =ImageType
				}
			})
			
			if ImageType == "DYNAMIC" then
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = iCmdID,
					menuParams = 	
					{
						menuName ="CommandImageValue"..tostring(iCmdID)
					}
					-- Verification is done below
					-- ,cmdIcon = 
					-- {
					-- 	value = storagePath..sImageValue,
					-- 	imageType = ImageType
					-- }
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
					self.hmiConnection:SendResponse(data.id, data.method, sResultCode, {})
				end)	
			else
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = iCmdID,
					menuParams = 	
					{
						menuName ="CommandImageValue"..tostring(iCmdID)
					},
					cmdIcon = 
					{
						value = sImageValue,
						imageType = ImageType
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, sResultCode, {})
				end)
			end
			
			--mobile side: expect AddCommand response
			EXPECT_RESPONSE(cid, { success = bSucccess, resultCode = sResultCode })
			if sResultCode == "SUCCESS" then
				EXPECT_NOTIFICATION("OnHashChange")
			end
		end
	--End Common.2
	
	-----------------------------------------------------------------------------------------
	
	--Begin Common.3
	--Description: AddCommand with specified command id
		--iCmdID : id of command want to add
		--bSucccess: Expected success (true, false)
		--sResultCode: Expected resultCode ("SUCCESS", "INVALID_DATA", ...)
		function AddCommand_cmdID(self, iCmdID, bSucccess, sResultCode)
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = iCmdID,
				menuParams = 	
				{
					menuName ="CommandID"..tostring(iCmdID)
				}
			})
			
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = iCmdID,
				menuParams = 	
				{
					menuName ="CommandID"..tostring(iCmdID)
				}
			})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, sResultCode, {})
			end)			

			--mobile side: expect AddCommand response 
			EXPECT_RESPONSE(cid, { success = bSucccess, resultCode = sResultCode })
			EXPECT_NOTIFICATION("OnHashChange")			
		end
	--End Common.3

	-----------------------------------------------------------------------------------------

	--Begin Common.4
	--Description: AddCommand with specified parent menu id
		--iCmdID : id of command want to add
		--iParentID: Id of parent menu
		--bSucccess: Expected success (true, false)
		--sResultCode: Expected resultCode ("SUCCESS", "INVALID_DATA", ...)
		function AddCommand_parentID(self, iCmdID, iParentID, bSucccess, sResultCode)
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = iCmdID,
				menuParams = 	
				{
					menuName ="CommandID"..tostring(iCmdID),
					parentID = iParentID
				}
			})
			
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
			{ 
				cmdID = iCmdID,
				menuParams = 	
				{
					menuName ="CommandID"..tostring(iCmdID),
					parentID = iParentID
				}
			})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, sResultCode, {})
			end)			

			--mobile side: expect AddCommand response
			EXPECT_RESPONSE(cid, { success = bSucccess, resultCode = sResultCode })
			if sResultCode == "SUCCESS" then
				EXPECT_NOTIFICATION("OnHashChange")
			end	
		end
	--End Common.4

	-----------------------------------------------------------------------------------------
	
	--Begin Common.5
	--Description: DelayedExp
	function DelayedExp()
		local event = events.Event()
		event.matches = function(self, e) return self == e end
			EXPECT_EVENT(event, "Delayed event")
			RUN_AFTER(function()
				RAISE_EVENT(event, event)
		end, 5000)
	end
	--End Common.5
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Common.6
	--Description: Delete existed command by cmdID
	--				iCmdID : id of command want to delete
		function DeleteCommand(self, iCmdID)
			--mobile side: sending DeleteCommand request
			local cid = self.mobileSession:SendRPC("DeleteCommand",
			{
				cmdID = iCmdID
			})
			
			--hmi side: expect UI.DeleteCommand request
			EXPECT_HMICALL("UI.DeleteCommand", 
			{ 
				cmdID = iCmdID
			})
			:Do(function(_,data)
				--hmi side: sending UI.DeleteCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.DeleteCommand request
			EXPECT_HMICALL("VR.DeleteCommand", 
			{ 
				cmdID = iCmdID
			})
			:Do(function(_,data)
				--hmi side: sending VR.DeleteCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
						
			--mobile side: expect DeleteCommand response 
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")			
		end
	--End Common.6

	-----------------------------------------------------------------------------------------
	
	--Begin Common.7
	--Description: 
		-- In case VR.AddCommand gets any erroneous response except REJECTED from HMI - SDL must send AddCommand_response(GENERIC_ERROR) to mobile app.
		-- In case VR.AddCommand gets any REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.		
		function Test:addCommand_VRErroneousResponse (vrResultResponse)
			local resultCodeValue
			if vrResultResponse == "REJECTED" or vrResultResponse == "WARNINGS" then				
				resultCodeValue = vrResultResponse
			else				
				resultCodeValue = "GENERIC_ERROR"
			end
			
			--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
					{
														cmdID = 2006,
														menuParams = 	
														{ 																
															menuName ="Command2006"
														}, 
														vrCommands = 
														{ 
															"VRCommand2006"
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = 2006,
								menuParams = 
								{ 											
									menuName ="Command2006"
								}
							})
			:Do(function(exp,data)
				--hmi side: send UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = 2006,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand2006"
								}
							})
			:Do(function(exp,data)
				--hmi side: sending VR.AddCommand response
				self.hmiConnection:SendError(data.id, data.method, vrResultResponse, "Error Messages")
			end)
			
			if vrResultResponse ~= "WARNINGS" then
				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
				{cmdID = 2006})				
				:Timeout(15000)
				:Do(function(exp,data)
					--hmi side: sending UI.DeleteCommand response
					self.hmiConnection:SendResponse(data.id,"UI.DeleteCommand", "SUCCESS", {})
				end)
			
				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = false, resultCode = resultCodeValue })	
				:Timeout(12000)
							
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			else
				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true, resultCode = resultCodeValue })					
							
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")				
			end
		end
	--End Common.7
	
	-----------------------------------------------------------------------------------------
		
	--Begin Common.8
	--Description: 
		-- In case UI.AddCommand gets erroneous response except of WARNINGS and UNSUPPORTED_RESOURCE and REJECTED from HMI - SDL must send AddCommand_response(GENERIC_ERROR) to mobile app.
		-- In case UI.AddCommand gets REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.
		-- In case of WARNINGS or UNSUPPORTED_RESOURCE from HMI, SDL must transfer the resultCode from HMI's response with adding "success: true" to mobile app.
		function Test:addCommand_UIErroneousResponse (uiResultResponse, cmdIDValue)
			local resultCodeValue, succcessValue
			if uiResultResponse == "REJECTED" or uiResultResponse == "WARNINGS" or uiResultResponse == "UNSUPPORTED_RESOURCE" then				
				resultCodeValue = uiResultResponse
				if uiResultResponse ~= "REJECTED" then
					succcessValue = true
				end
			else				
				resultCodeValue = "GENERIC_ERROR"
				succcessValue = false
			end
			
			--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
					{
														cmdID = cmdIDValue,
														menuParams = 	
														{ 																
															menuName ="Command"..cmdIDValue
														}, 
														vrCommands = 
														{ 
															"VRCommand"..cmdIDValue
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = cmdIDValue,
								menuParams = 
								{ 											
									menuName ="Command"..cmdIDValue
								}
							})
			:Do(function(exp,data)
				--hmi side: send UI.AddCommand response
				self.hmiConnection:SendError(data.id, data.method, uiResultResponse, "Error Messages")
			end)
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = cmdIDValue,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand"..cmdIDValue
								}
							})
			:Do(function(exp,data)
				--hmi side: sending VR.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			if uiResultResponse ~= "WARNINGS" and uiResultResponse ~= "UNSUPPORTED_RESOURCE"  then				
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{cmdID = cmdIDValue})				
				:Timeout(15000)
				:Do(function(exp,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
				end)
				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			else
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{cmdID = cmdIDValue})				
				:Times(0)
				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
			
			--mobile side: expect response
			EXPECT_RESPONSE(cid, { success = succcessValue, resultCode = resultCodeValue })			
			:Timeout(12000)
			
			DelayedExp()
		end
	--End Common.8
	
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
	
	----------------------------------------------------------------------------------------- 
	
	--Begin Precondition.3
	--Description: Adding SubMenu(AddSubMenus)
		local menuIDValues = {1, 2, 10, 8888, 1999999999, 2000000000}
		for i=1,#menuIDValues do
			Test["AddSubMenuWithId"..menuIDValues[i]] = function(self)
				local cid = self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = menuIDValues[i],
					menuName = "SubMenu"..tostring(i)
				})
				
				EXPECT_HMICALL("UI.AddSubMenu", 
				{ 
					menuID = menuIDValues[i],
					menuParams = { menuName = "SubMenu"..tostring(i) }
				})
				:Do(function(_,data)
						--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				EXPECT_NOTIFICATION("OnHashChange")
			end
		end
	--End Precondition.3
	
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
		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA: 
					--SDLAQ-CRS-21
					
			--Verification criteria: 
					--AddCommand request adds the command to VR Menu, UI Command/SubMenu menu or to the both depending on the parameters sent (VR, UI commands or the both correspondingly);							
				function Test:AddCommand_PositiveCase()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 11,
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="Commandpositive"
																}, 
																vrCommands = 
																{ 
																	"VRCommandonepositive",
																	"VRCommandonepositivedouble"
																}, 
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 11,
										-- Verification is done below
										--cmdIcon = 
										-- {
										-- 	value = storagePath.."icon.png",
										-- 	imageType = "DYNAMIC"
										-- },
										menuParams = 
										{ 
											parentID = 1,	
											position = 0,
											menuName ="Commandpositive"
										}
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
										type = "Command",
										vrCommands = 
										{
											"VRCommandonepositive", 
											"VRCommandonepositivedouble"
										}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.1
						
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters
		
			--Requirement id in JAMA:
					--SDLAQ-CRS-21,
					--SDLAQ-CRS-747
					--SDLAQ-CRS-748
					--SDLAQ-CRS-757
					
			--Verification criteria:
					--AddCommand request adds the command to VR Menu, UI Command/SubMenu menu or to the both depending on the parameters sent (VR, UI commands or the both correspondingly).
					--AddCommand request with only VR command definitions and no MenuParams definitions adds the command only to VR menu. This command is accessible only from VR menu.
					--AddCommand request with only MenuParams and no VR command definitions adds the command only to UI Command menu. This command is accessible only from UI Command/SubMenu menu.
					--The request without "MenuParams" and with "vrCommands" is sent, the SUCCESS response code is returned in case if no errors.
					
			--Begin Test case CommonRequestCheck.2.1
			--Description: If the command has only VR command definitions and no MenuParams definitions, the command should be added only to VR menu.
				function Test:AddCommand_MandatoryVRCommandsOnly()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 1005,
						vrCommands = 
						{ 
							"OnlyVRCommand"
						}
					})
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 1005,
						type = "Command",
						vrCommands = 
						{
							"OnlyVRCommand"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case CommonRequestCheck.2.1
			
			-----------------------------------------------------------------------------------------
					
			--Begin Test case CommonRequestCheck.2.2
			--Description: If the command has only MenuParams definitions and no VR command definitions the command should be added only to UI Commands Menu/SubMenu. 
				function Test:AddCommand_MandatoryMenuParamsOnly()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 20,
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="Command20"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 20,										
										menuParams = 
										{ 
											parentID = 1,	
											position = 0,
											menuName ="Command20"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
										
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
			--End Test case CommonRequestCheck.2.1
						
		--End Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test in intended to check all combinations of conditional-mandatory parameters
		
			--Requirement id in JAMA:
					--SDLAQ-CRS-21

			--Verification criteria:
					--AddCommand request adds the command to VR Menu, UI Command/SubMenu menu or to the both depending on the parameters sent (VR, UI commands or the both correspondingly).
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: Only mandatory - with menuParams and with conditional parameters inside menuParam
				function Test:AddCommand_MenuParamsConditional()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 1001,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="menuParams"
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 1001				
					})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end			
			--End Test case CommonRequestCheck.3.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.2
			--Description: Only mandatory - with menuParams and without conditional parameters inside menuParam
				function Test:AddCommand_MandatoryMenuParamsWithoutConditional()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 1002,
						menuParams = 	
						{ 
							menuName ="menuParamswithoutconditional"
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 1002
					})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end		
			--End Test case CommonRequestCheck.3.2 
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.3
			--Description: Only mandatory - with menuParams and without only ParentID inside menuParam
				function Test:AddCommand_MandatoryMenuParamsWithoutParentID()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 1004,
						menuParams = 	
						{ 
							position = 0,
							menuName ="Command1004"
						},
						vrCommands = 
						{ 
							"VRCommandonezerozerofour",
							"VRCommandonezerozerofourdouble"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 1004,
						-- Verification is done below
						-- cmdIcon = 
						-- {
						-- 	value = storagePath.."icon.png",
						-- 	imageType = "DYNAMIC"
						-- },
						menuParams = 
						{ 					
							position = 0,
							menuName ="Command1004"
						}
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
						cmdID = 1004,
						type = "Command",
						vrCommands = 
						{
							"VRCommandonezerozerofour", 
							"VRCommandonezerozerofourdouble"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end							
			--End Test case CommonRequestCheck.3.3
			
		--End Test case CommonRequestCheck.3	

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: This test is intended to check processing requests without mandatory and optional parameters
		
			--Requirement id in JAMA:
					--SDLAQ-CRS-404,
					--SDLAQ-CRS-756,
					--SDLAQ-CRS-757

			--Verification criteria:
					--[[
						- The request without "menuParams" and "vrCommands" is sent, the INVALID_DATA response code is returned.
						- The request without "cmdID" is sent, the INVALID_DATA response code is returned.
						- The request without "menuName" and "vrCommands" is sent, the INVALID_DATA response code is returned.
						- The request with "menuParams" but without "menuName" is sent, the INVALID_DATA response code is returned.
						- The request without "MenuParams" and with "vrCommands" is sent, the SUCCESS response code is returned in case if no errors.						
					]]
				
			--Begin Test case CommonRequestCheck.4.1
			--Description: Mandatory missing - cmdID
				function Test:AddCommand_cmdIDMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="Command1"
						}, 
						vrCommands = 
						{ 
							"Voicerecognitioncommandone"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})		
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.4.1
			
			-----------------------------------------------------------------------------------------
							
			--Begin Test case CommonRequestCheck.4.2
			--Description: Mandatory missing - menuParams
				function Test:AddCommand_menuParamsMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 500,																
																vrCommands = 
																{ 
																	"VRCommand500"
																}, 
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC"
																}
															})
											
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 500,
										type = "Command",
										vrCommands = 
										{
											"VRCommand500"
										}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.4.2			
			
			-----------------------------------------------------------------------------------------
							
			--Begin Test case CommonRequestCheck.4.3
			--Description: Mandatory missing - vrCommands
				function Test:AddCommand_vrCommandsMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 501,																
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="Command501"
																},
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC"
																}
															})
											
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 501,
										menuParams = 	
										{ 
											parentID = 1,
											position = 0,
											menuName ="Command501"
										},
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.4.3		
			
			-----------------------------------------------------------------------------------------
					
			--Begin Test case CommonRequestCheck.4.4
			--Description: Mandatory missing - menuParams and vrCommands are not provided
				function Test:AddCommand_menuParamsVRCommandsMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 22,				
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})		
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end			
			--End Test case CommonRequestCheck.4.4
			
			-----------------------------------------------------------------------------------------
					
			--Begin Test case CommonRequestCheck.4.5
			--Description: Mandatory missing - menuName are not provided
				function Test:AddCommand_menuNameMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 123,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0
						}, 
						vrCommands = 
						{ 
							"VRCommandonepositive",
							"VRCommandonepositivedouble"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})		
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end					
			--End Test case CommonRequestCheck.4.5
			
			-----------------------------------------------------------------------------------------
								
			--Begin Test case CommonRequestCheck.4.6
			--Description: Optional missing - cmdIcon
				function Test:AddCommand_MandatoryVrCommandCmdIconMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 2000,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="cmdIcon"
						}, 
						vrCommands = 
						{ 
							"Withoutcommandicon"
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 2000,
						menuParams = 
						{ 		
							parentID = 1,
							position = 0,
							menuName ="cmdIcon"
						}
					})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 2000,						
						type = "Command",
						vrCommands = 
						{
							"Withoutcommandicon"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end			
			--End Test case CommonRequestCheck.4.6
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.4.7
			--Description: Mandatory missing - cmdIcon value missing
				function Test:AddCommand_cmdIconValueMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 224,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="Command224"
						}, 
						vrCommands = 
						{ 
							"CommandTwoTwoFour"
						},
						cmdIcon = 	
						{
							imageType ="DYNAMIC"
						}
					})
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end							
			--End Test case CommonRequestCheck.4.7
			
			-----------------------------------------------------------------------------------------
					
			--Begin Test case CommonRequestCheck.4.8
			--Description: Mandatory missing - cmdIcon imageType is missing
				function Test:AddCommand_cmdIconImageTypeMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 225,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="Command225"
						}, 
						vrCommands = 
						{ 
							"CommandTwoTwoFive"
						},
						cmdIcon = 	
						{
							value ="icon.png"
						}
					})
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end								
			--End Test case CommonRequestCheck.4.8
			
			-----------------------------------------------------------------------------------------
					
			--Begin Test case CommonRequestCheck.4.9
			--Description: All parameter missing
				function Test:AddCommand_AllParamsMissing()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
					})		
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end		
			--End Test case CommonRequestCheck.4.9
			
      -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.10
      --Description: Mandatory missing - vrCommands
        function Test:AddCommand_iconNotSent()
          --mobile side: sending AddCommand request
          local cid = self.mobileSession:SendRPC("AddCommand",
                              {
                                cmdID = 511,
                                menuParams =
                                {
                                  parentID = 1,
                                  position = 0,
                                  menuName ="Command511"
                                },
                                cmdIcon =
                                {
                                  value ="missed_icon.png",
                                  imageType ="DYNAMIC"
                                }
                              })

          --hmi side: expect UI.AddCommand request
          EXPECT_HMICALL("UI.AddCommand",
                  {
                    cmdID = 511,
                    menuParams =
                    {
                      parentID = 1,
                      position = 0,
                      menuName ="Command511"
                    },
                    cmdIcon =
                    {
                      value ="missed_icon.png",
                      imageType ="DYNAMIC"
                    }
                  })
          :Do(function(_,data)
            --hmi side: sending UI.AddCommand response
            self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {info = "Requested image(s) not found."})
          end)

          --mobile side: expect AddCommand response
          EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

          --mobile side: expect OnHashChange notification
          EXPECT_NOTIFICATION("OnHashChange")
        end
      --End Test case CommonRequestCheck.4.10
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-4518

			--Verification criteria:
					--According to xml tests by Ford team all fake params should be ignored by SDL
			
			--Begin Test case CommonRequestCheck.5.1
			--Description: Parameter not from protocol					
				function Test:AddCommand_FakeParam()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 3000,
																fakeParam ="fakeParam",
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="fakeparam",
																	fakeParam ="fakeParam"
																},
																vrCommands = 
																{ 
																	"vrCommand"																	
																}, 
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC",
																	fakeParam ="fakeParam"
																}
															})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 3000,
						-- Verification is done below
						-- cmdIcon = 
						-- {
						-- 	value = storagePath.."icon.png",
						-- 	imageType = "DYNAMIC",
						-- },
						menuParams = 
						{ 					
							parentID = 1,
							position = 0,
							menuName ="fakeparam"
						}
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
					:ValidIf(function(_,data)
						if data.params.fakeParam or 
							data.params.menuParams.fakeParam or							
							data.params.cmdIcon.fakeParam	then
								print(" SDL re-sends fakeParam parameters to HMI in UI.AddCommand request")
								return false
						else 
							return true
						end
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 3000,						
						type = "Command",
						vrCommands = 
						{
							"vrCommand"
						}
					})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
								print(" SDL re-sends fakeParam parameters to HMI in VR.AddCommand request")
								return false
						else 
							return true
						end
					end)					
					
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.5.2
			--Description: Parameters from another request
				function Test:AddCommand_ParamsAnotherRequest()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 3200,																
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="Menu3200"
																},
																vrCommands = 
																{ 
																	"VrMenu3200"
																}, 
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC"
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
																	}, 
															})
															
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 3200,
										-- Verification is done below
										-- cmdIcon = 
										-- {
										-- 	value = storagePath.."icon.png",
										-- 	imageType = "DYNAMIC",
										-- },
										menuParams = 
										{ 					
											parentID = 1,
											position = 0,
											menuName ="Menu3200"
										}
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
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								print(" SDL re-sends ttsChunks parameters to HMI in UI.AddCommand request")
								return false
						else 
							return true
						end
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 3200,						
									type = "Command",
									vrCommands = 
									{
										"VrMenu3200"
									}
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								print(" SDL re-sends ttsChunks parameters to HMI in VR.AddCommand request")
								return false
						else 
							return true
						end
					end)
								
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end			
			--End Test case CommonRequestCheck.5.2
			
		--End Test case CommonRequestCheck.5
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.6
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-404

			--Verification criteria:
					--The request with wrong JSON syntax  is sent, the response with INVALID_DATA result code is returned.
			function Test:AddCommand_IncorrectJSON()
				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 5,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"cmdID" 55,"vrCommands":["synonym1","synonym2"],"menuParams":{"position":1000,"menuName":"Item To Add"},"cmdIcon":{"value":"action.png","imageType":"DYNAMIC"}}'
				}
				self.mobileSession:Send(msg)
				EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)	
				
				DelayedExp(1000)
			end			
		--End Test case CommonRequestCheck.6
		
		-----------------------------------------------------------------------------------------
--TODO: Requirement and Verification criteria need to be updated. 	
		--Begin Test case CommonRequestCheck.7
		--Description: different conditions of correlationID parameter (invalid, several the same etc.)

			--Requirement id in JAMA:
			--Verification criteria:
				function Test:AddCommand_DuplicateCorrelationId()

					local 	CorIdAddCommand = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 3300,																
																menuParams = 	
																{ 
																	parentID = 1,
																	position = 0,
																	menuName ="Menu3300"
																},
																vrCommands = 
																{ 
																	"VrMenu3300"
																}, 
																cmdIcon = 	
																{ 
																	value ="icon.png",
																	imageType ="DYNAMIC"
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
																	}, 
															})

					self.mobileSession.correlationId = CorIdAddCommand

					local msg = 
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 5,
						rpcCorrelationId = self.mobileSession.correlationId,					
						payload          = '{"cmdID":3400,"vrCommands":["VRCommand3400"],"menuParams":{"position":1000,"menuName":"Command3400"},"cmdIcon":{"value":"icon.png","imageType":"DYNAMIC"}}'
					}


					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{cmdID = 3300},
									{cmdID = 3400})
					:Times(2)
					:Do(function(exp,data)
						if exp.occurences == 1 then 
							self.mobileSession:Send(msg)
						end
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								print(" \27[36m SDL re-sends ttsChunks parameters to HMI in UI.AddCommand request \27[0m ")
								return false
						else 
							return true
						end
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand")
					:Times(2)
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								print(" \27[36m SDL re-sends ttsChunks parameters to HMI in VR.AddCommand request \27[0m ")
								return false
						else 
							return true
						end
					end)

					--mobile side: receiving response
					EXPECT_RESPONSE(CorIdAddCommand, { success = true, resultCode = "SUCCESS" })
					:Times(2)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(2)
					:Timeout(5000)
				end
			
		--End Test case CommonRequestCheck.7
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
			--Description: Check parameter with lower bound, in bound and upper bound values 

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-21,
							-- SDLAQ-CRS-2554

				--Verification criteria: 
							-- AddCommand request adds the command to VR Menu, UI Command/SubMenu menu or to the both depending on the parameters sent (VR, UI commands or the both correspondingly);
							-- SDL does NOT send UI.AddCommand to HMI at all IN CASE SDL receives AddCommand without MenuParams parameter from mobile application.
							-- SDL re-sends MenuParams values within UI.AddCommand (menuParams) to HMI IN CASE SDL receives valid parameter of menuParams within AddCommand from mobile application;
							-- SDL sends VR.AddCommand to HMI IN CASE SDL receives AddCommand without MenuParams parameter and with other valid parameters from mobile application.
								
				--Begin Test case PositiveRequestCheck.1.1
				--Description: cmdID - lower bound					
					function Test:AddCommand_cmdIDLowerBound()						
						--/* AddCommand lower bound */--
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 0,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Null"
							}, 
							vrCommands = 
							{ 
								"Null"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 0,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Null"
							}
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
							cmdID = 0,							
							type = "Command",
							vrCommands = 
							{
								"Null"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.2
				--Description: menuParams - parentID lower bound					
					function Test:AddCommand_MenuParamParentIDLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 113,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command113"
							}, 
							vrCommands = 
							{ 
								"CommandOneOneThree"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 113,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command113"
							}
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
							cmdID = 113,							
							type = "Command",
							vrCommands = 
							{
								"CommandOneOneThree"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.3
				--Description: menuParams - position lower bound					
					function Test:AddCommand_MenuParamPosLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 116,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command116"
							}, 
							vrCommands = 
							{ 
								"CommandOneOneSix"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 116,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command116"
							}
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
							cmdID = 116,							
							type = "Command",
							vrCommands = 
							{
								"CommandOneOneSix"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.4
				--Description: menuParams - menuName lower bound					
					function Test:AddCommand_MenuParamNameLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 120,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="A"
							}, 
							vrCommands = 
							{ 
								"CommandA"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 120,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="A"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 120,							
							type = "Command",
							vrCommands = 
							{
								"CommandA"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.5
				--Description: vrCommands - lower and upper bound					
					function Test:AddCommand_vrCommandsLowerUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 123,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command123"
							}, 
							vrCommands = 
							{ 
								"L",
								"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 123,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command123"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 123,							
							type = "Command",
							vrCommands = 
							{ 
								"L",
								"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.6
				--Description: vrCommands - array lower bound					
					function Test:AddCommand_vrCommandsArrayLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 124,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command124"
							}, 
							vrCommands = 
							{ 
								"CommandOneTwoFour"
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 124,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command124"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 124,							
							type = "Command",
							vrCommands = 
							{ 
								"CommandOneTwoFour"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end		
				--End Test case PositiveRequestCheck.1.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.7
				--Description: Lower bound of all parameters					
					function Test: DeleteCommand_ID0()
						DeleteCommand(self, 0)
					end					
					
					function Test:AddCommand_LowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 0,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="a"
							},
							vrCommands = 
							{ 
								"V"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 0,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="a"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 0,							
							type = "Command",
							vrCommands = 
							{
								"V"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")				
					end		
				--End Test case PositiveRequestCheck.1.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: cmdID - in bound
					local cmdIDValues = {5000,1999999999}
						for i=1,#cmdIDValues do
							Test["AddCommand_cmdIDInBound"..tostring(cmdIDValues[i])] = function(self)
								AddCommand_cmdID(self, tonumber("112"..(tostring(i))), true, "SUCCESS")
						end
					end
				--End Test case PositiveRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.9
				--Description: menuParams - position in bound
					local positionValues = {10,500,999}	
						for i=1,#positionValues do
						Test["AddCommand_PositionInBound"..tostring(positionValues[i])] = function(self)
							AddCommand_Position(self, tonumber("118"..(tostring(i))), positionValues[i], true, "SUCCESS")
						end
					end
				--End Test case PositiveRequestCheck.1.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.10
				--Description: menuParams - parentID in bound
					local parentIDValue = {10, 8888, 1999999999}
						for i=1,#parentIDValue do
							Test["AddCommand_parentIDInBound"..tostring(parentIDValue[i])] = function(self)
								AddCommand_parentID(self, tonumber("115"..(tostring(i))), parentIDValue[i], true, "SUCCESS")
						end
					end
				--End Test case PositiveRequestCheck.1.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.11
				--Description: imageValues - inbound
					for i=1,#imageValues + 1 do
						Test["AddCommand_ImageValuesInBound"..tostring(i)] = function(self)
							if i == #imageValues + 1 then
								AddCommand_ImageValue(self, tonumber("127"..(tostring(i))), "001234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdf", true, "SUCCESS", "STATIC")
							else

								AddCommand_ImageValue(self, tonumber("127"..(tostring(i))), imageValues[i], true, "SUCCESS", "DYNAMIC")

							end
						end
					end
				--End Test case PositiveRequestCheck.1.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.12
				--Description: cmdID upper bound					
					function Test:AddCommand_cmdIDUpperBound()	
						--/* AddCommand upper bound */--
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 2000000000,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Upper"
							}, 
							vrCommands = 
							{ 
								"Upper"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 2000000000,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Upper"
							}
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
							cmdID = 2000000000,							
							type = "Command",
							vrCommands = 
							{
								"Upper"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.12
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.13
				--Description: menuParams - parentID upper bound
					function Test:AddCommand_MenuParamParentIDUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 114,
							menuParams = 	
							{ 
								parentID = 2000000000,
								position = 0,
								menuName ="Command114"
							}, 
							vrCommands = 
							{ 
								"CommandOneOneFour"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 114,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 2000000000,
								position = 0,
								menuName ="Command114"
							}
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
							cmdID = 114,							
							type = "Command",
							vrCommands = 
							{
								"CommandOneOneFour"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.14
				--Description: menuParams - position upper bound
					function Test:AddCommand_MenuParamPosUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 117,
							menuParams = 	
							{ 
								parentID = 1,
								position = 1000,
								menuName ="Command117"
							}, 
							vrCommands = 
							{ 
								"CommandOneOneSeven"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 117,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 1000,
								menuName ="Command117"
							}
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
							cmdID = 117,							
							type = "Command",
							vrCommands = 
							{
								"CommandOneOneSeven"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.15
				--Description: menuParams - menuName upper bound
					function Test:AddCommand_MenuParamNameUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 121,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="aaaa\\{\\b\\r\\}\\u\\f01234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN!@"
							}, 
							vrCommands = 
							{ 
								"Commandnameupper"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 121,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="aaaa\\{\\b\\r\\}\\u\\f01234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN!@"
							}
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
							cmdID = 121,							
							type = "Command",
							vrCommands = 
							{
								"Commandnameupper"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.15
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.16
				--Description: vrCommands - array upper bound
					function Test:AddCommand_vrCommandsArrayUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 125,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command125"
							}, 
							vrCommands = 
							{ 
								"1CommandOneTwoFive",
								"2CommandOneTwoFive",
								"3CommandOneTwoFive",
								"4CommandOneTwoFive",
								"5CommandOneTwoFive",
								"6CommandOneTwoFive",
								"7CommandOneTwoFive",
								"8CommandOneTwoFive",
								"9CommandOneTwoFive",
								"10CommandOneTwoFive",
								"11CommandOneTwoFive",
								"12CommandOneTwoFive",
								"13CommandOneTwoFive",
								"14CommandOneTwoFive",
								"15CommandOneTwoFive",
								"16CommandOneTwoFive",
								"17CommandOneTwoFive",
								"18CommandOneTwoFive",
								"19CommandOneTwoFive",
								"20CommandOneTwoFive",
								"21CommandOneTwoFive",
								"22CommandOneTwoFive",
								"23CommandOneTwoFive",
								"24CommandOneTwoFive",
								"25CommandOneTwoFive",
								"26CommandOneTwoFive",
								"27CommandOneTwoFive",
								"28CommandOneTwoFive",
								"29CommandOneTwoFive",
								"30CommandOneTwoFive",
								"31CommandOneTwoFive",
								"32CommandOneTwoFive",
								"33CommandOneTwoFive",
								"34CommandOneTwoFive",
								"35CommandOneTwoFive",
								"36CommandOneTwoFive",
								"37CommandOneTwoFive",
								"38CommandOneTwoFive",
								"39CommandOneTwoFive",
								"40CommandOneTwoFive",
								"41CommandOneTwoFive",
								"42CommandOneTwoFive",
								"43CommandOneTwoFive",
								"44CommandOneTwoFive",
								"45CommandOneTwoFive",
								"46CommandOneTwoFive",
								"47CommandOneTwoFive",
								"48CommandOneTwoFive",
								"49CommandOneTwoFive",
								"50CommandOneTwoFive",
								"51CommandOneTwoFive",
								"52CommandOneTwoFive",
								"53CommandOneTwoFive",
								"54CommandOneTwoFive",
								"55CommandOneTwoFive",
								"56CommandOneTwoFive",
								"57CommandOneTwoFive",
								"58CommandOneTwoFive",
								"59CommandOneTwoFive",
								"60CommandOneTwoFive",
								"61CommandOneTwoFive",
								"62CommandOneTwoFive",
								"63CommandOneTwoFive",
								"64CommandOneTwoFive",
								"65CommandOneTwoFive",
								"66CommandOneTwoFive",
								"67CommandOneTwoFive",
								"68CommandOneTwoFive",
								"69CommandOneTwoFive",
								"70CommandOneTwoFive",
								"71CommandOneTwoFive",
								"72CommandOneTwoFive",
								"73CommandOneTwoFive",
								"74CommandOneTwoFive",
								"75CommandOneTwoFive",
								"76CommandOneTwoFive",
								"77CommandOneTwoFive",
								"78CommandOneTwoFive",
								"79CommandOneTwoFive",
								"80CommandOneTwoFive",
								"81CommandOneTwoFive",
								"82CommandOneTwoFive",
								"83CommandOneTwoFive",
								"84CommandOneTwoFive",
								"85CommandOneTwoFive",
								"86CommandOneTwoFive",
								"87CommandOneTwoFive",
								"88CommandOneTwoFive",
								"89CommandOneTwoFive",
								"90CommandOneTwoFive",
								"91CommandOneTwoFive",
								"92CommandOneTwoFive",
								"93CommandOneTwoFive",
								"94CommandOneTwoFive",
								"95CommandOneTwoFive",
								"96CommandOneTwoFive",
								"97CommandOneTwoFive",
								"98CommandOneTwoFive",
								"99CommandOneTwoFive",
								"100CommandOneTwoFive"
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 125,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command125"
							}
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
							cmdID = 125,							
							type = "Command",
							vrCommands = 
							{ 
								"1CommandOneTwoFive",
								"2CommandOneTwoFive",
								"3CommandOneTwoFive",
								"4CommandOneTwoFive",
								"5CommandOneTwoFive",
								"6CommandOneTwoFive",
								"7CommandOneTwoFive",
								"8CommandOneTwoFive",
								"9CommandOneTwoFive",
								"10CommandOneTwoFive",
								"11CommandOneTwoFive",
								"12CommandOneTwoFive",
								"13CommandOneTwoFive",
								"14CommandOneTwoFive",
								"15CommandOneTwoFive",
								"16CommandOneTwoFive",
								"17CommandOneTwoFive",
								"18CommandOneTwoFive",
								"19CommandOneTwoFive",
								"20CommandOneTwoFive",
								"21CommandOneTwoFive",
								"22CommandOneTwoFive",
								"23CommandOneTwoFive",
								"24CommandOneTwoFive",
								"25CommandOneTwoFive",
								"26CommandOneTwoFive",
								"27CommandOneTwoFive",
								"28CommandOneTwoFive",
								"29CommandOneTwoFive",
								"30CommandOneTwoFive",
								"31CommandOneTwoFive",
								"32CommandOneTwoFive",
								"33CommandOneTwoFive",
								"34CommandOneTwoFive",
								"35CommandOneTwoFive",
								"36CommandOneTwoFive",
								"37CommandOneTwoFive",
								"38CommandOneTwoFive",
								"39CommandOneTwoFive",
								"40CommandOneTwoFive",
								"41CommandOneTwoFive",
								"42CommandOneTwoFive",
								"43CommandOneTwoFive",
								"44CommandOneTwoFive",
								"45CommandOneTwoFive",
								"46CommandOneTwoFive",
								"47CommandOneTwoFive",
								"48CommandOneTwoFive",
								"49CommandOneTwoFive",
								"50CommandOneTwoFive",
								"51CommandOneTwoFive",
								"52CommandOneTwoFive",
								"53CommandOneTwoFive",
								"54CommandOneTwoFive",
								"55CommandOneTwoFive",
								"56CommandOneTwoFive",
								"57CommandOneTwoFive",
								"58CommandOneTwoFive",
								"59CommandOneTwoFive",
								"60CommandOneTwoFive",
								"61CommandOneTwoFive",
								"62CommandOneTwoFive",
								"63CommandOneTwoFive",
								"64CommandOneTwoFive",
								"65CommandOneTwoFive",
								"66CommandOneTwoFive",
								"67CommandOneTwoFive",
								"68CommandOneTwoFive",
								"69CommandOneTwoFive",
								"70CommandOneTwoFive",
								"71CommandOneTwoFive",
								"72CommandOneTwoFive",
								"73CommandOneTwoFive",
								"74CommandOneTwoFive",
								"75CommandOneTwoFive",
								"76CommandOneTwoFive",
								"77CommandOneTwoFive",
								"78CommandOneTwoFive",
								"79CommandOneTwoFive",
								"80CommandOneTwoFive",
								"81CommandOneTwoFive",
								"82CommandOneTwoFive",
								"83CommandOneTwoFive",
								"84CommandOneTwoFive",
								"85CommandOneTwoFive",
								"86CommandOneTwoFive",
								"87CommandOneTwoFive",
								"88CommandOneTwoFive",
								"89CommandOneTwoFive",
								"90CommandOneTwoFive",
								"91CommandOneTwoFive",
								"92CommandOneTwoFive",
								"93CommandOneTwoFive",
								"94CommandOneTwoFive",
								"95CommandOneTwoFive",
								"96CommandOneTwoFive",
								"97CommandOneTwoFive",
								"98CommandOneTwoFive",
								"99CommandOneTwoFive",
								"100CommandOneTwoFive"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.17
				--Description: Upper bound of all parameters
					function Test: DeleteCommand_ID2000000000()
						DeleteCommand(self, 2000000000)
					end	
					
					function Test:AddCommand_UpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 2000000000,
							menuParams = 	
							{
								parentID = 2000000000,
								position = 1000,
								menuName ="aaaa\\{\\b\\r\\}\\u\\f01234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN!@"
							},
							vrCommands = 
							{ 
								"1vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"2vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"3vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"4vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"5vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"6vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"7vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"8vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"9vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"10vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"11vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"12vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"13vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"14vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"15vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"16vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"17vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"18vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"19vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"20vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"21vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"22vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"23vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"24vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"25vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"26vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"27vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"28vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"29vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"30vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"31vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"32vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"33vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"34vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"35vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"36vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"37vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"38vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"39vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"40vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"41vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"42vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"43vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"44vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"45vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"46vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"47vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"48vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"49vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"50vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"51vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"52vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"53vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"54vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"55vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"56vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"57vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"58vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"59vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"60vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"61vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"62vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"63vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"64vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"65vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"66vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"67vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"68vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"69vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"70vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"71vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"72vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"73vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"74vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"75vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"76vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"77vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"78vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"79vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"80vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"81vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"82vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"83vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"84vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"85vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"86vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"87vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"88vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"89vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"90vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"91vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"92vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"93vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"94vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"95vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"96vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"97vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"98vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"99vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"100vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 2000000000,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC"
							-- },
							menuParams = 	
							{
								position = 1000,
								menuName ="aaaa\\{\\b\\r\\}\\u\\f01234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN!@"
							}
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
							cmdID = 2000000000,							
							type = "Command",
							vrCommands = 
							{ 
								"1vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"2vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"3vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"4vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"5vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"6vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"7vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"8vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"9vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"10vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"11vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"12vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"13vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"14vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"15vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"16vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"17vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"18vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"19vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"20vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"21vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"22vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"23vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"24vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"25vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"26vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"27vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"28vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"29vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"30vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"31vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"32vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"33vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"34vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"35vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"36vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"37vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"38vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"39vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"40vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"41vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"42vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"43vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"44vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"45vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"46vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"47vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"48vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"49vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"50vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"51vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"52vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"53vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"54vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"55vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"56vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"57vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"58vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"59vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"60vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"61vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"62vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"63vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"64vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"65vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"66vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"67vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"68vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"69vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"70vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"71vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"72vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"73vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"74vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"75vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"76vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"77vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"78vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"79vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"80vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"81vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"82vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"83vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"84vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"85vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"86vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"87vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"88vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"89vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"90vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"91vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"92vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"93vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"94vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"95vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"96vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"97vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"98vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"99vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
								"100vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
							},
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end				
				--End Test case PositiveRequestCheck.1.17
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.18
				--Description: menuParams - position already existed 				
					function Test:AddCommand_MenuParamPosAlreadyExisted()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
							{
							cmdID = 119,
							menuParams = 	
							{ 
								parentID = 1,
								position = 500,
								menuName ="Command119"
							}, 
							vrCommands = 
							{ 
								"CommandOneOneNine"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 119,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 500,
								menuName ="Command119"
							}
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
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 119,							
							type = "Command",
							vrCommands = 
							{
								"CommandOneOneNine"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.18
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.19
				--Description: menuParams - menuName with spaces before, after and in the middle
					function Test:AddCommand_MenuParamNameSpaces()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 122,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="   With     spaces       "
							}, 
							vrCommands = 
							{ 
								"Commandonetwotwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 122,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="   With     spaces       "
							}
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
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 122,							
							type = "Command",
							vrCommands = 
							{
								"Commandonetwotwo"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.19
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.20
				--Description: vrCommands - with spaces before, after and in the middle			
					function Test:AddCommand_vrCommandsSpaces()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 126,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command126"
							}, 
							vrCommands = 
							{ 
								"  Command One  Two Six   "
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 126,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command126"
							}
						})

						:Do(function(_,data)
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
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

						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 126,							
							type = "Command",
							vrCommands = 
							{ 
								"  Command One  Two Six   "
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.20
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
					--SDLAQ-CRS-22
					
				--Verification criteria:
					-- The response contains information about additional "info" if exists.
	
				--Begin PositiveResponseCheck.1.1
				--Description: UI response info parameter lower bound	

				--TODO: Should be uncommented when APPLINK-24450 is resolved				
					-- function Test: AddCommand_UIResponseInfoLowerBound()
					-- 	--mobile side: sending AddCommand request
					-- 	local cid = self.mobileSession:SendRPC("AddCommand",
					-- 											{
					-- 												cmdID = 71,
					-- 												menuParams = 	
					-- 												{ 
					-- 													parentID = 1,
					-- 													position = 0,
					-- 													menuName ="Command71"
					-- 												}, 
					-- 												vrCommands = 
					-- 												{ 
					-- 													"VRCommand71"
					-- 												}, 
					-- 												cmdIcon = 	
					-- 												{ 
					-- 													value ="icon.png",
					-- 													imageType ="DYNAMIC"
					-- 												}
					-- 											})
					-- 	--hmi side: expect UI.AddCommand request
					-- 	EXPECT_HMICALL("UI.AddCommand", 
					-- 					{ 
					-- 						cmdID = 71,
					-- 						-- Verification is done below
					-- 						-- cmdIcon = 
					-- 						-- {
					-- 						-- 	value = storagePath.."icon.png",
					-- 						-- 	imageType = "DYNAMIC"
					-- 						-- },
					-- 						menuParams = 
					-- 						{ 
					-- 							parentID = 1,	
					-- 							position = 0,
					-- 							menuName ="Command71"
					-- 						}
					-- 					})
					-- 	:ValidIf(function(_,data)
     --      				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
     --      				local value_Icon = path .. "action.png"
          
     --      				if(data.params.cmdIcon.imageType == "DYNAMIC") then
     --          				return true
     --      				else
     --          				print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. "\27[0m")
     --          				return false
     --      				end

     --      				if(string.find(data.params.cmdIcon.value, value_Icon) ) then
     --              			return true
     --          			else
     --              			print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
     --              			return false
     --          			end
     --  				end)
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.AddCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
					-- 	end)
							
					-- 	--hmi side: expect VR.AddCommand request
					-- 	EXPECT_HMICALL("VR.AddCommand", 
					-- 					{ 
					-- 						cmdID = 71,
					-- 						type = "Command",
					-- 						vrCommands = 
					-- 						{
					-- 							"VRCommand71"
					-- 						}
					-- 					})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.AddCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)
						
					-- 	--mobile side: expect AddCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a" })
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin PositiveResponseCheck.1.2
				--Description: VR response info parameter lower bound					
					function Test: AddCommand_VRResponseInfoLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 72,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command72"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand72"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 72,
											-- Verification is done below
											-- cmdIcon = 
											-- {
											-- 	value = storagePath.."icon.png",
											-- 	imageType = "DYNAMIC"
											-- },
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command72"
											}
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
											cmdID = 72,
											type = "Command",
											vrCommands = 
											{
												"VRCommand72"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End PositiveResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin PositiveResponseCheck.1.3
				--Description: UI & VR response info parameter lower bound
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: AddCommand_UIVRResponseInfoLowerBound()
					-- 	--mobile side: sending AddCommand request
					-- 	local cid = self.mobileSession:SendRPC("AddCommand",
					-- 											{
					-- 												cmdID = 73,
					-- 												menuParams = 	
					-- 												{ 
					-- 													parentID = 1,
					-- 													position = 0,
					-- 													menuName ="Command73"
					-- 												}, 
					-- 												vrCommands = 
					-- 												{ 
					-- 													"VRCommand73"
					-- 												}, 
					-- 												cmdIcon = 	
					-- 												{ 
					-- 													value ="icon.png",
					-- 													imageType ="DYNAMIC"
					-- 												}
					-- 											})
					-- 	--hmi side: expect UI.AddCommand request
					-- 	EXPECT_HMICALL("UI.AddCommand", 
					-- 					{ 
					-- 						cmdID = 73,
					-- 						-- Verification is done below
					-- 						-- cmdIcon = 
					-- 						-- {
					-- 						-- 	value = storagePath.."icon.png",
					-- 						-- 	imageType = "DYNAMIC"
					-- 						-- },
					-- 						menuParams = 
					-- 						{ 
					-- 							parentID = 1,	
					-- 							position = 0,
					-- 							menuName ="Command73"
					-- 						}
					-- 					})
					-- 	:ValidIf(function(_,data)
     --      				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
     --      				local value_Icon = path .. "action.png"
          
     --      				if(data.params.cmdIcon.imageType == "DYNAMIC") then
     --          				return true
     --      				else
     --          				print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. "\27[0m")
     --          				return false
     --      				end

     --      				if(string.find(data.params.cmdIcon.value, value_Icon) ) then
     --              			return true
     --          			else
     --              			print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
     --              			return false
     --          			end
     --  				end)
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.AddCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
					-- 	end)
							
					-- 	--hmi side: expect VR.AddCommand request
					-- 	EXPECT_HMICALL("VR.AddCommand", 
					-- 					{ 
					-- 						cmdID = 73,
					-- 						type = "Command",
					-- 						vrCommands = 
					-- 						{
					-- 							"VRCommand73"
					-- 						}
					-- 					})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.AddCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b")
					-- 	end)
						
					-- 	--mobile side: expect AddCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a.b" })
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.4
				--Description: UI response info parameter upper bound 
				--TODO: Should be uncommented when APPLINK-24450 is resolved					
					-- function Test: AddCommand_UIResponseInfoUpperBound()
					-- 	--mobile side: sending AddCommand request
					-- 	local cid = self.mobileSession:SendRPC("AddCommand",
					-- 											{
					-- 												cmdID = 74,
					-- 												menuParams = 	
					-- 												{ 
					-- 													parentID = 1,
					-- 													position = 0,
					-- 													menuName ="Command74"
					-- 												}, 
					-- 												vrCommands = 
					-- 												{ 
					-- 													"VRCommand74"
					-- 												}, 
					-- 												cmdIcon = 	
					-- 												{ 
					-- 													value ="icon.png",
					-- 													imageType ="DYNAMIC"
					-- 												}
					-- 											})
					-- 	--hmi side: expect UI.AddCommand request
					-- 	EXPECT_HMICALL("UI.AddCommand", 
					-- 					{ 
					-- 						cmdID = 74,
					-- 						-- Verification is done below
					-- 						-- cmdIcon = 
					-- 						-- {
					-- 						-- 	value = storagePath.."icon.png",
					-- 						-- 	imageType = "DYNAMIC"
					-- 						-- },
					-- 						menuParams = 
					-- 						{ 
					-- 							parentID = 1,	
					-- 							position = 0,
					-- 							menuName ="Command74"
					-- 						}
					-- 					})
					-- 	:ValidIf(function(_,data)
     --      				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
     --      				local value_Icon = path .. "action.png"
          
     --      				if(data.params.cmdIcon.imageType == "DYNAMIC") then
     --          				return true
     --      				else
     --          				print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. "\27[0m")
     --          				return false
     --      				end

     --      				if(string.find(data.params.cmdIcon.value, value_Icon) ) then
     --              			return true
     --          			else
     --              			print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
     --              			return false
     --          			end
     --  				end)
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.AddCommand response
					-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
					-- 	end)
							
					-- 	--hmi side: expect VR.AddCommand request
					-- 	EXPECT_HMICALL("VR.AddCommand", 
					-- 					{ 
					-- 						cmdID = 74,
					-- 						type = "Command",
					-- 						vrCommands = 
					-- 						{
					-- 							"VRCommand74"
					-- 						}
					-- 					})
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending VR.AddCommand response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					-- 	end)
						
					-- 	--mobile side: expect AddCommand response
					-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
					-- 	--mobile side: expect OnHashChange notification is not send to mobile
					-- 	EXPECT_NOTIFICATION("OnHashChange")
					-- 	:Times(0)
					-- end
				--End PositiveResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.5
				--Description: VR response info parameter upper bound 					
					function Test: AddCommand_VRResponseInfoUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 75,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command75"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand75"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 75,
											-- Verification is done below
											-- cmdIcon = 
											-- {
											-- 	value = storagePath.."icon.png",
											-- 	imageType = "DYNAMIC"
											-- },
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command75"
											}
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
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 75,
											type = "Command",
											vrCommands = 
											{
												"VRCommand75"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End PositiveResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.6
				--Description: UI & VR response info parameter upper bound 					
					function Test: AddCommand_UIVRResponseInfoUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 76,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command76"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand76"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 76,
											-- Verification is done below
											-- cmdIcon = 
											-- {
											-- 	value = storagePath.."icon.png",
											-- 	imageType = "DYNAMIC"
											-- },
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command76"
											}
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
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 76,
											type = "Command",
											vrCommands = 
											{
												"VRCommand76"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
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
		--Description: Check processing requests with out of lower and upper bound values 

			--Begin Test case NegativeRequestCheck.1
			--Description:

				--Requirement id in JAMA:
					--SDLAQ-CRS-404
					--SDLAQ-CRS-757
					
					
				--Verification criteria:
				--[[
						- The request with "cmdID" value out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with "vrCommands" value out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with "vrCommands" array items out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with "Image" value out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with "parentID" value out of bound is sent, the response with INVALID_DATA result code is returned.
						- The request with "position" value out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with "menuName" value out of bounds is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "vrCommands" array is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "vrCommands" value is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "position" value is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "Image" structure is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "Image" value is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "menuParams" structure is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "parentID" is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "cmdID" is sent, the response with INVALID_DATA result code is returned.
						- The request with empty "menuName" is sent, the response with INVALID_DATA result code is returned.						
				]]
				
				--Begin Test case NegativeRequestCheck.1.1
				--Description: cmdID - out lower bound 				
				function Test:AddCommand_cmdIDOutLowerBound()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = -1,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="Command1"
						}, 
						vrCommands = 
						{ 
							"Voicerecognitioncommandone"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})
					
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end					
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.2
				--Description: cmdID - out upper bound 
					function Test:AddCommand_cmdIDOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 2000000001,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Upper"
							}, 
							vrCommands = 
							{ 
								"Upper"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.3
				--Description: menuParams - parent id out lower bound
					function Test:AddCommand_MenuParamParentIDOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 603,
							menuParams = 	
							{ 
								parentID = -1,
								position = 0,
								menuName ="Command603"
							}, 
							vrCommands = 
							{ 
								"Commandsixzerothree"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.4
				--Description: menuParams - parent id out upper bound
					function Test:AddCommand_MenuParamParentIDOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 606,
							menuParams = 	
							{ 
								parentID = 2000000001,
								position = 0,
								menuName ="Commandsixzerosix"
							}, 
							vrCommands = 
							{ 
								"Commandsixzerosix"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.5
				--Description: menuParams - position out lower bound
					function Test:AddCommand_MenuParamPosOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 213,
							menuParams = 	
							{ 
								parentID = 1,
								position = -1,
								menuName ="Command703"
							}, 
							vrCommands = 
							{ 
								"Commandsevenzerothree"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.6
				--Description: menuParams - position out upper bound
					function Test:AddCommand_MenuParamPosOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 214,
							menuParams = 	
							{ 
								parentID = 1,
								position = 1001,
								menuName ="Command214"
							}, 
							vrCommands = 
							{ 
								"Commandtwoonefour"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.7
				--Description: menuParams - menuname out lower bound
					function Test:AddCommand_MenuParamNameOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 215,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName =""
							}, 
							vrCommands = 
							{ 
								"Commandtwoonefive"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.7
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.8
				--Description: menuParams - menuname out upper bound
					function Test:AddCommand_MenuParamNameOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 217,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="111111111111111111111111111111111111111111111111111111111111111111101234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg012"
							}, 
							vrCommands = 
							{ 
								"Voicerecognitioncommandone"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.8
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.9
				--Description: vrCommands - array out lower bound (empty)
					function Test:AddCommand_vrCommandsEmptyArray()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 218,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command218"
							}, 
							vrCommands = 
							{
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.9
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.10
				--Description: vrCommands - empty value (out lower bound)
					function Test:AddCommand_vrCommandsEmptyValue()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 219,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command219"
							}, 
							vrCommands = 
							{
								""
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.10
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.11
				--Description: vrCommands - out upper bound
					function Test:AddCommand_vrCommandsOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 222,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command222"
							}, 
							vrCommands = 
							{
								"1100012\\345/678'90abc!def@ghi#jkl$mno%pqr^stu*vwx:yz()ABC-DEF_GHIJKL+MNO|PQR~STU{}WXY[]Z,012345678900"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.12
				--Description: vrCommands - array out upper bound
					function Test:AddCommand_vrCommandsOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 223,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command223"
							}, 
							vrCommands = 
							{ 
								"1CommandTwoTwoThree",
								"2CommandTwoTwoThree",
								"3CommandTwoTwoThree",
								"4CommandTwoTwoThree",
								"5CommandTwoTwoThree",
								"6CommandTwoTwoThree",
								"7CommandTwoTwoThree",
								"8CommandTwoTwoThree",
								"9CommandTwoTwoThree",
								"10CommandTwoTwoThree",
								"11CommandTwoTwoThree",
								"12CommandTwoTwoThree",
								"13CommandTwoTwoThree",
								"14CommandTwoTwoThree",
								"15CommandTwoTwoThree",
								"16CommandTwoTwoThree",
								"17CommandTwoTwoThree",
								"18CommandTwoTwoThree",
								"19CommandTwoTwoThree",
								"20CommandTwoTwoThree",
								"21CommandTwoTwoThree",
								"22CommandTwoTwoThree",
								"23CommandTwoTwoThree",
								"24CommandTwoTwoThree",
								"25CommandTwoTwoThree",
								"26CommandTwoTwoThree",
								"27CommandTwoTwoThree",
								"28CommandTwoTwoThree",
								"29CommandTwoTwoThree",
								"30CommandTwoTwoThree",
								"31CommandTwoTwoThree",
								"32CommandTwoTwoThree",
								"33CommandTwoTwoThree",
								"34CommandTwoTwoThree",
								"35CommandTwoTwoThree",
								"36CommandTwoTwoThree",
								"37CommandTwoTwoThree",
								"38CommandTwoTwoThree",
								"39CommandTwoTwoThree",
								"40CommandTwoTwoThree",
								"41CommandTwoTwoThree",
								"42CommandTwoTwoThree",
								"43CommandTwoTwoThree",
								"44CommandTwoTwoThree",
								"45CommandTwoTwoThree",
								"46CommandTwoTwoThree",
								"47CommandTwoTwoThree",
								"48CommandTwoTwoThree",
								"49CommandTwoTwoThree",
								"50CommandTwoTwoThree",
								"51CommandTwoTwoThree",
								"52CommandTwoTwoThree",
								"53CommandTwoTwoThree",
								"54CommandTwoTwoThree",
								"55CommandTwoTwoThree",
								"56CommandTwoTwoThree",
								"57CommandTwoTwoThree",
								"58CommandTwoTwoThree",
								"59CommandTwoTwoThree",
								"60CommandTwoTwoThree",
								"61CommandTwoTwoThree",
								"62CommandTwoTwoThree",
								"63CommandTwoTwoThree",
								"64CommandTwoTwoThree",
								"65CommandTwoTwoThree",
								"66CommandTwoTwoThree",
								"67CommandTwoTwoThree",
								"68CommandTwoTwoThree",
								"69CommandTwoTwoThree",
								"70CommandTwoTwoThree",
								"71CommandTwoTwoThree",
								"72CommandTwoTwoThree",
								"73CommandTwoTwoThree",
								"74CommandTwoTwoThree",
								"75CommandTwoTwoThree",
								"76CommandTwoTwoThree",
								"77CommandTwoTwoThree",
								"78CommandTwoTwoThree",
								"79CommandTwoTwoThree",
								"80CommandTwoTwoThree",
								"81CommandTwoTwoThree",
								"82CommandTwoTwoThree",
								"83CommandTwoTwoThree",
								"84CommandTwoTwoThree",
								"85CommandTwoTwoThree",
								"86CommandTwoTwoThree",
								"87CommandTwoTwoThree",
								"88CommandTwoTwoThree",
								"89CommandTwoTwoThree",
								"90CommandTwoTwoThree",
								"91CommandTwoTwoThree",
								"92CommandTwoTwoThree",
								"93CommandTwoTwoThree",
								"94CommandTwoTwoThree",
								"95CommandTwoTwoThree",
								"96CommandTwoTwoThree",
								"97CommandTwoTwoThree",
								"98CommandTwoTwoThree",
								"99CommandTwoTwoThree",
								"100CommandTwoTwoThree",
								"101CommandTwoTwoThree"
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.12
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.13
				--Description: cmdIcon - value is empty
					function Test:AddCommand_cmdIconValueEmpty()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 226,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command226"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoSix"
							},
							cmdIcon = 	
							{
								value ="",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.14
				--Description: cmdIcon - imageType is empty
					function Test:AddCommand_cmdIconImageTypeEmpty()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 227,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command227"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoSeven"
							},
							cmdIcon = 	
							{
								value ="icon.png",
								imageType =""
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.14
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.15
				--Description: cmdIcon - out upper bound of value
					function Test:AddCommand_cmdIconValueOutUpperBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 229,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command229"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoNine"
							},
							cmdIcon = 	
							{
								value ="111111001234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg)-_+|~{}[]:,01234567890asdfgaa.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.15
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.16
				--Description: imageType - out of enum value
					function Test:AddCommand_imageTypeNotExisted()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 230,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command230"
							}, 
							vrCommands = 
							{ 
								"VRCommand230"
							},
							cmdIcon = 	
							{
								value ="icon.png",
								imageType ="ANY"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.16
									
			--End Test case NegativeRequestCheck.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing request with duplicate values

				--Requirement id in JAMA:
					--SDLAQ-CRS-407,
					--APPLINK-9020
				--Verification criteria:
				--[[
					- In case the app sends the AddCommnad RPC with the same 'menuName' value as the already requested one (that is, SDL has already received AddCommand with 'menuName' of such value from this mobile app), SDL must respond with "resultCode "DUPLICATE_NAME" and general result succcess=false" and not transfer this RPC to HMI. This rule excludes commands with the same names but which relates to different menus/submenus.
					- In case the app sends the AddCommnad RPC with the same 'vrSynonym' value as the already requested one (that is, SDL has already received AddCommand with 'menuName' of such value from this mobile app), SDL must respond with "resultCode "DUPLICATE_NAME" and general result succcess=false" and not transfer this RPC to HMI.
				]]
						
				--Begin Test case NegativeRequestCheck.2.1
				--Description: menuParams - menuName is already existed
					function Test:AddCommand_MenuParamNameDuplicate()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 411,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Duplicate"
							}, 
							vrCommands = 
							{ 
								"CommandDuplicate01"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 411,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Duplicate"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 411,							
							type = "Command",
							vrCommands = 
							{
								"CommandDuplicate01"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
						
						--/* Add Duplicate command */--
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 412,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Duplicate"
							}, 
							vrCommands = 
							{ 
								"CommandDuplicate02"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })		
					end
				--End Test case NegativeRequestCheck.2.1
				
				-----------------------------------------------------------------------------------------
						
				--Begin Test case NegativeRequestCheck.2.2
				--Description: vrCommand is already existed
					function Test:AddCommand_vrCommandsDuplicate()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 421,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command421"
							}, 
							vrCommands = 
							{ 
								"CommandFourTwo"
							},
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 421,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command421"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 421,							
							type = "Command",
							vrCommands = 
							{ 
								"CommandFourTwo"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)	
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
						
						--/*AddCommand duplicate vrCommand */--
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 422,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command422"
							}, 
							vrCommands = 
							{ 
								"CommandFourTwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
										
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })		
					end
				--End Test case NegativeRequestCheck.2.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.3
				--Description: vrCommands - one of VrCommands is already existed
					function Test:AddCommand_vrCommandsDuplicateOne()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 43,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command43"
							}, 
							vrCommands = 
							{ 
								"CommandFourTwo",
								"ABC"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})										
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeRequestCheck.2.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.4
				--Description: vrCommands is already existed - case non-sensitive
					function Test:AddCommand_vrCommandsDuplicateDiffCase()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 44,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command44"
							}, 
							vrCommands = 
							{ 
								"commandfourtwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
										
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeRequestCheck.2.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.5
				--Description: AddCommand requests at the same time with the duplicate MenuName
					function Test:AddCommand_duplicateMenuNameSameTime()
						--mobile side: sending AddCommand request
						local cid1= self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 451,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command45"
							}, 
							vrCommands = 
							{ 
								"CommandFourFiveOne"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--mobile side: sending AddCommand request
						local cid2 = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 452,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command45"
							}, 
							vrCommands = 
							{ 
								"CommandFourFiveTwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})		
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 451,
							-- Verification is done below
							-- cmdIcon = 
							-- {
							-- 	value = storagePath.."icon.png",
							-- 	imageType = "DYNAMIC",
							-- },
							menuParams = 
							{ 					
								parentID = 1,
								position = 0,
								menuName ="Command45"
							}
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
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 451,							
							type = "Command",
							vrCommands = 
							{ 
								"CommandFourFiveOne"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })			
						EXPECT_RESPONSE(cid2, { success = false, resultCode = "DUPLICATE_NAME" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
					end
				--End Test case NegativeRequestCheck.2.5
								
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.6
				--Description: AddCommand requests at the same time with the duplicate vrCommands
					function Test:AddCommand_duplicateVrCommandsSameTime()
						--mobile side: sending AddCommand request
						local cid1= self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 471,			
							vrCommands = 
							{ 
								"CommandFourSevenOne"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						--/*Add second command that has same vrCommands*/
						--mobile side: sending AddCommand request
						local cid2 = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 472,			
							vrCommands = 
							{ 
								"CommandFourSevenOne"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})		
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 471,							
							type = "Command",
							vrCommands = 
							{ 
								"CommandFourSevenOne"
							}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })			
						EXPECT_RESPONSE(cid2, { success = false, resultCode = "DUPLICATE_NAME" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
					end
				--End Test case NegativeRequestCheck.2.6
								
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.7
				--Description: Sequentially AddCommand requests with the duplicate MenuName and vrSynonym
					function Test:AddCommand_duplicateMenuNamevrCommandsSequentially()
						--mobile side: sending AddCommand request
						local cid1= self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 481,
							menuParams = {menuName = "Command481"},
							vrCommands = {"CommandFourEightOne"}, 			
						})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 481,
							menuParams = {menuName = "Command481"}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 481,							
							type = "Command",
							vrCommands = { "CommandFourEightOne"}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						
						EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })
						:Do(function(_,data)
						
							--/*Add second command that has same menuParams, vrCommands*/
							--mobile side: sending AddCommand request
							local cid2= self.mobileSession:SendRPC("AddCommand",
							{
								cmdID = 482,
								menuParams = {menuName = "Command481"},
								vrCommands = {"CommandFourEightOne"}, 			
							})
							
							EXPECT_RESPONSE(cid2, { success = false, resultCode = "DUPLICATE_NAME" })							
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
					end
				--End Test case NegativeRequestCheck.2.7
								
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.8
				--Description: AddCommand requests at the same time with the duplicate MenuName
					function Test:AddCommand_duplicateMenuNamevrCommandsSameTime()
						--mobile side: sending AddCommand request
						local cid1= self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 491,
							menuParams = {menuName = "Command491"},
							vrCommands = {"CommandFourNineOne"}, 			
						})
						
						--/*Add second command that has same menuParams, vrCommands*/
						--mobile side: sending AddCommand request
						local cid2= self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 492,
							menuParams = {menuName = "Command491"},
							vrCommands = {"CommandFourNineOne"}, 			
						})
						
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 491,
							menuParams = {menuName = "Command491"}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 491,							
							type = "Command",
							vrCommands = { "CommandFourNineOne"}
						})
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" })			
						EXPECT_RESPONSE(cid2, { success = false, resultCode = "DUPLICATE_NAME" })						
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(1)
					end
				--End Test case NegativeRequestCheck.2.8
				
			--End Test case NegativeRequestCheck.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing request with invalid id

				--Requirement id in JAMA:
					--SDLAQ-CRS-414
				--Verification criteria:
					--In case of adding a command with cmdID which is already registered for the current application, the response with INVALID_ID resultCode is sent.
					--In case of adding a command with ParentID that doesn't exist for the current application, the response with INVALID_ID resultCode is sent.
				
				--Begin Test case NegativeRequestCheck.3.1
				--Description: cmdID is not valid (already existed), submenu is the same
					function Test:AddCommand_cmdIDNotValid()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 11,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="CommandDifferent"
							}, 
							vrCommands = 
							{ 
								"CommandDifferent"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.3.2
				--Description: cmdID is valid, parentID is not valid
					function Test:AddCommand_cmdIDNotValidSubmenuDifferent()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 32,
							menuParams = 	
							{ 
								parentID = 320,
								position = 0,
								menuName ="CommandDifferent"
							}, 
							vrCommands = 
							{ 
								"CommandDifferent"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.2
				
			--End Test case NegativeRequestCheck.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				--Requirement id in JAMA:
					--SDLAQ-CRS-404
					--SDLAQ-CRS-757
					
				--Verification criteria:
				--[[
					- SDL responds with INVALID_DATA resultCode in case AddCommand request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "value" parameter of "Image" struct of cmdIcon param.
					- SDL responds with INVALID_DATA resultCode in case AddCommand request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "menuName" parameter of "menuParams" struct
					- SDL responds with INVALID_DATA resultCode in case AddCommand request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "vrCommands" parameter
				]]
				
				--Begin Test case NegativeRequestCheck.4.1
				--Description: vrCommands whitespace only
					function Test:AddCommand_vrCommandsWhitespace()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 220,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command220"
							}, 
							vrCommands = 
							{
								"      "
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.4.2
				--Description: vrCommands - Escape sequence \n in vrCommands
					function Test:AddCommand_vrCommandsNewLineChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 235,
							vrCommands = 
							{ 
								"VRCommandonepositive\n",
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.4.3
				--Description: vrCommands - Escape sequence \n in vrCommands
					function Test:AddCommand_vrCommandsTabChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 236,
							vrCommands = 
							{ 
								"VRCommandonepositive\t",
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.4.4
				--Description: cmdIcon - whitespace only in cmdIcon image value
					function Test:AddCommand_cmdIconValueWhiteSpace()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 232,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command232"
							}, 
							vrCommands = 
							{ 
								"CommandTwoThreeTwo"
							},
							cmdIcon = 	
							{
								value ="      ",
								imageType ="STATIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.5
				--Description: cmdIcon - Escape sequence \n in cmdIcon image value
					function Test:AddCommand_cmdIconValueNewLineChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 231,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command231"
							}, 
							vrCommands = 
							{ 
								"CommandTwoThreeOne"
							},
							cmdIcon = 	
							{
								value ="ico\n.png",
								imageType ="STATIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.6
				--Description: cmdIcon - Escape sequence \t in cmdIcon image value
					function Test:AddCommand_cmdIconValueNewTabChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 232,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command232"
							}, 
							vrCommands = 
							{ 
								"CommandTwoThreeTwo"
							},
							cmdIcon = 	
							{
								value ="ico\tn.png",
								imageType ="STATIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.7
				--Description: menuName - whitespace only in menuName
					function Test:AddCommand_menuNameWhiteSpace()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 234,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="     ",
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.7

				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.4.8
				--Description: menuName - Escape sequence \n in menuName
					function Test:AddCommand_menuNameNewLineChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 233,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Commandpositive\n",
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.9
				--Description: menuName - Escape sequence \t in menuName
					function Test:AddCommand_menuNameTabChar()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 234,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Commandpositive\t",
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.4.9				
				
			--End Test case NegativeRequestCheck.4		
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-404
				--Verification criteria:
				--[[
					- The request with wrong type of data in "position" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					- The request with wrong type of data in "parentID" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					- The request with wrong type of data in "cmdID" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					- The request with wrong type of menuName parameter (e.g. Integer type) is sent, the response with INVALID_DATA result code is returned.
					- The request with wrong type of "vrCommand" parameter (e.g. Integer type) is sent, the response with INVALID_DATA result code is returned.
					- The request with wrong type of "cmdIcon" parameter (e.g. Integer type) is sent, the response with INVALID_DATA result code is returned.
				]]
				
				--Begin Test case NegativeRequestCheck.5.1
				--Description: cmdID Wrong Type
					function Test:AddCommand_cmdIDWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = "123",
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command1"
							}, 
							vrCommands = 
							{ 
								"Voicerecognitioncommandone"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.1
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.2
				--Description: menuParams parent id Wrong Type
					function Test:AddCommand_MenuParamParentIDWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 602,
							menuParams = 	
							{ 
								parentID = "1",
								position = 0,
								menuName ="Command602"
							}, 
							vrCommands = 
							{ 
								"Commandsixzerotwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.2
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.3
				--Description: menuParams position wrong type
					function Test:AddCommand_MenuParamPosWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 212,
							menuParams = 	
							{ 
								parentID = 1,
								position = "1",
								menuName ="Command702"
							}, 
							vrCommands = 
							{ 
								"Commandsevenzerotwo"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.3
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.4
				--Description: menuParams menuName wrong type
					function Test:AddCommand_MenuParamNameWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 216,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName = 802
							}, 
							vrCommands = 
							{ 
								"Commandtwoonesix"
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.4
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.5
					--Description: menuParams wrong type
						function Test:AddCommand_MenuParamsWrongType()
							--mobile side: sending AddCommand request
							local cid = self.mobileSession:SendRPC("AddCommand",
							{
								cmdID = 216,
								menuParams = "menu Param", 
								vrCommands = 
								{ 
									"Commandtwoonesix"
								}, 
								cmdIcon = 	
								{ 
									value ="icon.png",
									imageType ="DYNAMIC"
								}
							})
							
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
							--mobile side: expect OnHashChange notification is not send to mobile
							EXPECT_NOTIFICATION("OnHashChange")
							:Times(0)
						end
				--End Test case NegativeRequestCheck.5.5
					
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.6
				--Description: vrCommands wrong type of parameter
					function Test:AddCommand_vrCommandsValueWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 221,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command221"
							}, 
							vrCommands = 
							{
								12300123
							}, 
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.6
					
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.7
				--Description: vrCommands wrong type
					function Test:AddCommand_vrCommandsWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 221,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command221"
							}, 
							vrCommands = "vrCommand",
							cmdIcon = 	
							{ 
								value ="icon.png",
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.7
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.8
				--Description: cmdIcon - value wrong type
					function Test:AddCommand_cmdIconValueWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 228,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command228"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoEight"
							},
							cmdIcon = 	
							{
								value =123,
								imageType ="DYNAMIC"
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.8
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.9
				--Description: cmdIcon wrong type
					function Test:AddCommand_cmdIconWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 228,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command228"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoEight"
							},
							cmdIcon = "icon.png"
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.9
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.10
				--Description: cmdIcon - imageType wrong type
					function Test:AddCommand_cmdIconImageTypeWrongType()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 228,
							menuParams = 	
							{ 
								parentID = 1,
								position = 0,
								menuName ="Command228"
							}, 
							vrCommands = 
							{ 
								"CommandTwoTwoEight"
							},
							cmdIcon = 	
							{
								value ="icon.png",
								imageType =123
							}
						})
						
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.10
			--End Test case NegativeRequestCheck.5			
		--End Test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.
--[[TODO update after resolving APPLINK-14765
			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-22
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check UI response with nonexistent resultCode 
					function Test:AddCommand_UIResponseResultCodeNotExist()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 77,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command77"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand77"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 77,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":111, "method":"UI.AddCommand"}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 77,
											type = "Command",
											vrCommands = 
											{
												"VRCommand77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check VR response with nonexistent resultCode 
					function Test:AddCommand_VRResponseResultCodeNotExist()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 77,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command77"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand77"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 77,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 77,
											type = "Command",
											vrCommands = 
											{
												"VRCommand77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":111, "method":"VR.AddCommand"}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check UI & VR response with nonexistent resultCode 
					function Test:AddCommand_UIVRResponseResultCodeNotExist()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 77,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command77"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand77"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 77,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":111, "method":"UI.AddCommand"}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 77,
											type = "Command",
											vrCommands = 
											{
												"VRCommand77"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":111, "method":"VR.AddCommand"}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End Test case NegativeResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check UI response with empty string in method
					function Test:AddCommand_UIResponseMethodOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 78,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command78"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand78"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 78,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 78,
											type = "Command",
											vrCommands = 
											{
												"VRCommand78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check VR response with empty string in method
					function Test: AddCommand_VRResponseMethodOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 78,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command78"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand78"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 78,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 78,
											type = "Command",
											vrCommands = 
											{
												"VRCommand78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.6
				--Description: Check UI & VR response with empty string in method
					function Test:AddCommand_UIVRResponseMethodOutLowerBound()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 78,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command78"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand78"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 78,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 78,
											type = "Command",
											vrCommands = 
											{
												"VRCommand78"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
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
					--SDLAQ-CRS-22
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check UI response without all parameters				
					function Test:AddCommand_UIResponseMissingAllPArameters()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)			
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.2
				--Description: Check VR response without all parameters				
					function Test:AddCommand_VRResponseMissingAllPArameters()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.3
				--Description: Check UI & VR response without all parameters				
					function Test: AddCommand_UIVRResponseMissingAllParameters()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send({})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check UI response without method parameter			
					function Test: AddCommand_UIResponseMethodMissing()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check VR response without method parameter			
					function Test: AddCommand_VRResponseMethodMissing()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check UI & VR response without method parameter			
					function Test:AddCommand_UIVRResponseMethodMissing()					
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check UI response without resultCode parameter
					function Test: AddCommand_UIResponseResultCodeMissing()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand"}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.8
				--Description: Check VR response without resultCode parameter
					function Test: AddCommand_VRResponseResultCodeMissing()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand"}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.9
				--Description: Check UI & VR response without resultCode parameter
					function Test: AddCommand_UIVRResponseResultCodeMissing()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand"}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand"}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.9				
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-29
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check UI response with wrong type of method
					function Test:AddCommand_UIResponseMethodWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check VR response with wrong type of method
					function Test:AddCommand_VRResponseMethodWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check UI & VR response with wrong type of method
					function Test:AddCommand_UIVRResponseMethodWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check UI response with wrong type of resultCode
					function Test:AddCommand_UIResponseResultCodeWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand", "code":true}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check VR response with wrong type of resultCode
					function Test:AddCommand_VRResponseResultCodeWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":true}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.3.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.6
				--Description: Check UI & VR response with wrong type of resultCode
					function Test:AddCommand_VRResponseResultCodeWrongtype() 
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand", "code":true}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":true}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.3.6
			--End Test case NegativeResponseCheck.3
]]
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-22
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
	--[[TODO: update after resolving APPLINK-13418
				--Begin Test case NegativeResponseCheck.4.1
				--Description: Check UI response with invalid json				
					function Test: AddCommand_UIResponseInvalidJson()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand", "code":0}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.4.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.4.2
				--Description: Check VR response with invalid json				
					function Test: AddCommand_VRResponseInvalidJson()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":0}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.4.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.4.3
				--Description: Check UI & VR response with invalid json				
					function Test: AddCommand_UIVRResponseInvalidJson()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddCommand", "code":0}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.AddCommand", "code":0}}')
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end				
				--End Test case NegativeResponseCheck.4.3				
			--End Test case NegativeResponseCheck.4
			]]
			-----------------------------------------------------------------------------------------
	--[[TODO: uodate after resolving APPLINK-14551
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-22
					--APPLINK-13276
					--APPLINK-14551
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					
				--Begin Test Case NegativeResponseCheck5.1
				--Description: UI response with empty info
					function Test: AddCommand_UIResponseInfoOutLowerBound()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_VRResponseInfoOutLowerBound()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIVRResponseInfoOutLowerBound()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIInfoOutLowerBoundVRInfoInBound()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck5.5
				--Description: VR response with empty info, UI response with inbound info
					function Test: AddCommand_VRInfoOutLowerBoundUIInfoInBound()	
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test Case NegativeResponseCheck5.5
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.6
				--Description: UI response info out of upper bound
					function Test: AddCommand_UIResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End Test Case NegativeResponseCheck5.6
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.7
				--Description: VR response info out of upper bound
					function Test: AddCommand_VRResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End Test Case NegativeResponseCheck5.7
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.8
				--Description: UI & VR response info out of upper bound
					function Test: AddCommand_UIVRResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End Test Case NegativeResponseCheck5.8
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.9
				--Description: UI response with wrong type of info parameter
					function Test: AddCommand_UIResponseInfoWrongType()												
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_VRResponseInfoWrongType()												
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIVRResponseInfoWrongType()												
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIResponseInfoWithNewlineChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_VRResponseInfoWithNewlineChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIVRResponseInfoWithNewlineChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIResponseInfoWithNewTabChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_VRResponseInfoWithNewTabChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect AddCommand response
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
					function Test: AddCommand_UIVRResponseInfoWithNewTabChar()						
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 79,
																	menuParams = 	
																	{ 
																		parentID = 1,
																		position = 0,
																		menuName ="Command79"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand79"
																	}, 
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 79,
											cmdIcon = 
											{
												value = storagePath.."icon.png",
												imageType = "DYNAMIC"
											},
											menuParams = 
											{ 
												parentID = 1,	
												position = 0,
												menuName ="Command79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 79,
											type = "Command",
											vrCommands = 
											{
												"VRCommand79"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect AddCommand response
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
				--SDLAQ-CRS-405
				--SDLAQ-CRS-410
				--SDLAQ-CRS-412
				
			--Verification criteria:
				-- The request AddCommand is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned. 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}}
			for i=1,#resultCodes do
				Test["AddCommand_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = tonumber("6"..tostring(i)),
																menuParams = 	
																{ 
																	menuName ="Command6"..tostring(i)
																}, 
																vrCommands = 
																{ 
																	"VRCommand6"..tostring(i)
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = tonumber("6"..tostring(i)),
										menuParams = 	
										{ 
											menuName ="Command6"..tostring(i)
										}, 
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error Messages")
					end)
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = tonumber("6"..tostring(i)),							
										type = "Command",
										vrCommands = 
										{ 
											"VRCommand6"..tostring(i)
										}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response						
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error Messages")
					end)
					
					--mobile side: expect AddCommand response
					EXPECT_RESPONSE(cid, { success = false, resultCode = resultCodes[i].code, info = "Error Messages" })
											
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: Limit of position items in UI list is exhausted (should be managed by HMI)

			--Requirement id in JAMA:
				--SDLAQ-CRS-410

			--Verification criteria:
				--In case the limit of position items in UI list is exhausted while adding commands to Command Menu, HMi rejects the request with the resultCode REJECTED.
			function Test: AddCommand_REJECTED()				
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = 1812,
					menuParams = 	
					{ 
						position = 0,
						menuName ="Command1812"
					}, 
					vrCommands = 
					{ 
						"VRCommand1812"
					}, 
					cmdIcon = 	
					{ 
						value ="icon.png",
						imageType ="DYNAMIC"
					}
				})		
				
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = 1812,
					-- Verification is done below
					-- cmdIcon = 
					-- {
					-- 	value = storagePath.."icon.png",
					-- 	imageType = "DYNAMIC"
					-- },
					menuParams = 
					{ 	
						position = 0,
						menuName ="Command1812"
					}
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
					--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)
				
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = 1812,							
					type = "Command",
					vrCommands = 
					{ 
						"VRCommand1812"
					}
				})
				:Do(function(_,data)
					--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)	
				
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case ResultCodeCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: 
			-- Used if VR isn't avaliable now (not supported).
			-- If images or image type(DYNAMIC, STATIC) aren't supported on HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-1023

			--Verification criteria:
				--[[
					1.1. When "vrCommands" is sent and VR isn't supported on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
					1.2. When "vrCommands" is sent and VR isn't avaliable at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 

					2.1. When images aren't supported on HMI at all, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
					2.2. When "STATIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
					2.3. When "DYNAMIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
				]] 
			
			--Begin Test case ResultCodeCheck.3.1
			--Description: VR isn't supported
				function Test:AddCommand_VrCommandsNotSupported()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 1813,																
																vrCommands = 
																{ 
																	"VRCommand1813"
																}
															})
										
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 1813,							
										type = "Command",
										vrCommands = 
										{
											"VRCommand1813"
										}
									})
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_RESOURCE", {})
					end)					
					
					--mobile side: expect response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case ResultCodeCheck.3.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.3.2
			--Description: Static image isn't supported
				function Test:AddCommand_ImageNotSupported()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 1814,
																menuParams = 	
																{ 																
																	menuName ="Command1814"
																},
																cmdIcon = 	
																{
																	value ="icon.png",
																	imageType ="STATIC"
																}
															})
										
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 1814,							
										menuParams = 	
										{ 																
											menuName ="Command1814"
										},
										cmdIcon = 	
										{
											value ="icon.png",
											imageType ="STATIC"
										}
									})
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_RESOURCE", {})
					end)					
					
					--mobile side: expect response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case ResultCodeCheck.3.2			
		--End Test case ResultCodeCheck.3		
		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: A command can not be executed because no application has been registered with RegisterApplication. 

			--Requirement id in JAMA:
				--SDLAQ-CRS-409

			--Verification criteria:
				-- SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Unregister application
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			--Description: Send AddCommand when application not registered yet.
			function Test:AddCommand_AppNotRegistered()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession1:SendRPC("AddCommand",
					{
						cmdID = 61,
						menuParams = 	
						{ 
							parentID = 1,
							position = 0,
							menuName ="Command61"
						}, 
						vrCommands = 
						{ 
							"CommandSixOne"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})
					
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
					
				--mobile side: expect OnHashChange notification is not send to mobile
				self.mobileSession1:ExpectNotification("OnHashChange",{})
				:Times(0)
			end
		--End Test case ResultCodeCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.5
		--Description: 
				--SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				--SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.
				
			--Requirement id in JAMA:
				--SDLAQ-CRS-413
				--SDLAQ-CRS-752
				
			--Verification criteria:
				--[[1. Pre-conditions:
						a) app is running on the consented device
						b) app has received the updated policies from Ford's backend (record in PT: "app_policies" -> "<appID>" -> "groups": group_1)
						c) AddCommand is omitted in "group_1"
						
						1) Send AddCommand from mobile app.
						2) SDL->app: AddCommand_response (DISALLOWED)
					2. SDL disallowed AddCommand request with DISALLOWED resultCode when current HMI level is NONE.
				]]
				
			--Begin Test case ResultCodeCheck.5.1
			--Description: SDL send DISALLOWED when HMI level is NONE
				function Test:Precondition_DeactivateApp()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				function Test:AddCommand_DisallowedHMINone()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 110,
						menuParams = 	
						{ 			
							position = 0,
							menuName ="Command110"
						}, 
						vrCommands = 
						{ 
							"CommandOneOneZero"
						}, 
						cmdIcon = 	
						{ 
							value ="icon.png",
							imageType ="DYNAMIC"
						}
					})	
						
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					
					DelayedExp()
				end	
			
			--Begin Test case ResultCodeCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.5.2
			--Description: AddCommand is omitted in the PolicyTable group(s)
			
			commonSteps:ActivationApp()
			--TODO: Should be uncommented when APPLINK-25363 is resolved 
				--Description: Update Policy with AddCommand is DISALLOWED by user
				function Test:Precondition_OmittedAddCommandPolicyUpdate()
					--hmi side: sending SDL.GetURLS request
					local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
					
					-- --hmi side: expect SDL.GetURLS response from HMI
					-- EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
					-- :Do(function(_,data)
					-- 	--print("SDL.GetURLS response is received")
					-- 	--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					-- 	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
					-- 		{
					-- 			requestType = "PROPRIETARY",
					-- 			fileName = "filename"
					-- 		}
					-- 	)
						--mobile side: expect OnSystemRequest notification 
					-- 	EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
					-- 	:Do(function(_,data)
					-- 		--print("OnSystemRequest notification is received")
					-- 		--mobile side: sending SystemRequest request 
					-- 		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
					-- 			{
					-- 				fileName = "PolicyTableUpdate",
					-- 				requestType = "PROPRIETARY"
					-- 			},
					-- 		"files/PTU_OmittedAddCommand.json")
							
					-- 		local systemRequestId
					-- 		--hmi side: expect SystemRequest request
					-- 		EXPECT_HMICALL("BasicCommunication.SystemRequest")
					-- 		:Do(function(_,data)
					-- 			systemRequestId = data.id
					-- 			--print("BasicCommunication.SystemRequest is received")
								
					-- 			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
					-- 			self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
					-- 				{
					-- 					policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
					-- 				}
					-- 			)
					-- 			function to_run()
					-- 				--hmi side: sending SystemRequest response
					-- 				self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
					-- 			end
								
					-- 			RUN_AFTER(to_run, 500)
					-- 		end)
							
					-- 		--hmi side: expect SDL.OnStatusUpdate
					-- 		EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
					-- 		:ValidIf(function(exp,data)
					-- 			if 
					-- 				exp.occurences == 1 and
					-- 				data.params.status == "UP_TO_DATE" then
					-- 					return true
					-- 			elseif
					-- 				exp.occurences == 1 and
					-- 				data.params.status == "UPDATING" then
					-- 					return true
					-- 			elseif
					-- 				exp.occurences == 2 and
					-- 				data.params.status == "UP_TO_DATE" then
					-- 					return true
					-- 			else 
					-- 				if 
					-- 					exp.occurences == 1 then
					-- 						print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
					-- 				elseif exp.occurences == 2 then
					-- 						print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
					-- 				end
					-- 				return false
					-- 			end
					-- 		end)
					-- 		:Times(Between(1,2))
							
					-- 		--mobile side: expect SystemRequest response
					-- 		EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					-- 		:Do(function(_,data)
					-- 			--print("SystemRequest is received")
					-- 			--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					-- 			local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
					-- 			--hmi side: expect SDL.GetUserFriendlyMessage response
					-- 			-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
					-- 			EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
					-- 			:Do(function(_,data)
					-- 				print("SDL.GetUserFriendlyMessage is received")			
					-- 			end)
					-- 		end)
							
					-- 	end)
					-- end)
				end
				--TODO: Should be uncommented when APPLINK-25363 is resolved 		
				-- --Check of DISALLOWED response code
				-- function Test:AddCommand_UserDisallowed()
				-- 	--mobile side: sending AddCommand request
				-- 	local cid = self.mobileSession:SendRPC("AddCommand",
				-- 	{
				-- 		cmdID = 112,
				-- 		menuParams = 	
				-- 		{ 			
				-- 			position = 0,
				-- 			menuName ="Command112"
				-- 		}, 
				-- 		vrCommands = 
				-- 		{ 
				-- 			"CommandOneOneTwo"
				-- 		}, 
				-- 		cmdIcon = 	
				-- 		{ 
				-- 			value ="icon.png",
				-- 			imageType ="DYNAMIC"
				-- 		}
				-- 	})	
						
				-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
				-- 	:Timeout(20000)
						
				-- 	--mobile side: expect OnHashChange notification is not send to mobile
				-- 	EXPECT_NOTIFICATION("OnHashChange")
				-- 	:Times(0)
				-- end
			--Begin Test case ResultCodeCheck.5.2			
		--End Test case ResultCodeCheck.5
		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.6
		--Description: USER-DISALLOWED response code is sent by SDL when the request isn't allowed by user.

			--Requirement id in JAMA:
				--SDLAQ-CRS-413

			--Verification criteria:
				-- SDL sends USER-DISALLOWED code when the request isn't allowed by user.
				--Description: Update Policy with AddCommand is DISALLOWED by user
		--TODO: Should be uncommented when APPLINK-25363 is resolved 
		-- 		local idGroup
		-- 		function Test:Precondition_UserDisallowedPolicyUpdate()
		-- 			--hmi side: sending SDL.GetURLS request
		-- 			local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
		-- 			--hmi side: expect SDL.GetURLS response from HMI
		-- 			EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
		-- 			:Do(function(_,data)
		-- 				--print("SDL.GetURLS response is received")
		-- 				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		-- 				self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
		-- 					{
		-- 						requestType = "PROPRIETARY",
		-- 						fileName = "filename"
		-- 					}
		-- 				)
		-- 				--mobile side: expect OnSystemRequest notification 
		-- 				EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		-- 				:Do(function(_,data)
		-- 					--print("OnSystemRequest notificfation is received")
		-- 					--mobile side: sending SystemRequest request 
		-- 					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
		-- 						{
		-- 							fileName = "PolicyTableUpdate",
		-- 							requestType = "PROPRIETARY"
		-- 						},
		-- 					"files/PTU_ForAddCommand.json")
							
		-- 					local systemRequestId
		-- 					--hmi side: expect SystemRequest request
		-- 					EXPECT_HMICALL("BasicCommunication.SystemRequest")
		-- 					:Do(function(_,data)
		-- 						systemRequestId = data.id
		-- 						--print("BasicCommunication.SystemRequest is received")
								
		-- 						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		-- 						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
		-- 							{
		-- 								policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
		-- 							}
		-- 						)
		-- 						function to_run()
		-- 							--hmi side: sending SystemRequest response
		-- 							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
		-- 						end
								
		-- 						RUN_AFTER(to_run, 500)
		-- 					end)
							
		-- 					--hmi side: expect SDL.OnStatusUpdate
		-- 					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
		-- 					:ValidIf(function(exp,data)
		-- 						if 
		-- 							exp.occurences == 1 and
		-- 							data.params.status == "UP_TO_DATE" then
		-- 								return true
		-- 						elseif
		-- 							exp.occurences == 1 and
		-- 							data.params.status == "UPDATING" then
		-- 								return true
		-- 						elseif
		-- 							exp.occurences == 2 and
		-- 							data.params.status == "UP_TO_DATE" then
		-- 								return true
		-- 						else 
		-- 							if 
		-- 								exp.occurences == 1 then
		-- 									print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
		-- 							elseif exp.occurences == 2 then
		-- 									print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
		-- 							end
		-- 							return false
		-- 						end
		-- 					end)
		-- 					:Times(Between(1,2))
							
		-- 					--mobile side: expect SystemRequest response
		-- 					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		-- 					:Do(function(_,data)
		-- 						--print("SystemRequest is received")
		-- 						--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
		-- 						local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
		-- 						--hmi side: expect SDL.GetUserFriendlyMessage response
		-- 						EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
		-- 						:Do(function(_,data)
		-- 							print("SDL.GetUserFriendlyMessage is received")
		-- 							--hmi side: sending SDL.GetListOfPermissions request to SDL
		-- 								local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
										
		-- 								-- hmi side: expect SDL.GetListOfPermissions response
		-- 								-- -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions"}})
		-- 								EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
		-- 								:Do(function(_,data)
		-- 									print("SDL.GetListOfPermissions response is received")

		-- 									idGroup = data.result.allowedFunctions[1].id								
		-- 									--hmi side: sending SDL.OnAppPermissionConsent
		-- 									self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = idGroup, name = "New"}}, source = "GUI"})
		-- 									end)				
		-- 						end)
		-- 					end)
		-- 					:Timeout(2000)

							
		-- 				end)
		-- 			end)
		-- 		end
		
		-- 		--Check of USER_DISALLOWED response code
		-- 		function Test:AddCommand_UserDisallowed()
		-- 			--mobile side: sending AddCommand request
		-- 			local cid = self.mobileSession:SendRPC("AddCommand",
		-- 			{
		-- 				cmdID = 11333,
		-- 				menuParams = 	
		-- 				{ 			
		-- 					position = 0,
		-- 					menuName ="Command113"
		-- 				}, 
		-- 				vrCommands = 
		-- 				{ 
		-- 					"CommandOneOneThree"
		-- 				}, 
		-- 				cmdIcon = 	
		-- 				{ 
		-- 					value ="icon.png",
		-- 					imageType ="DYNAMIC"
		-- 				}
		-- 			})	
						
		-- 			EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
		-- 			:Timeout(20000)
						
		-- 			--mobile side: expect OnHashChange notification is not send to mobile
		-- 			EXPECT_NOTIFICATION("OnHashChange")
		-- 			:Times(0)
		-- 		end

		-- 		--Description: Update Policy with AddCommand is Allowed by user
		-- 		function Test:AllowedAddCommand()
		-- 			DelayedExp()
		-- 			self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = idGroup, name = "New"}}, source = "GUI"})		  
		-- 		end			
		-- --End Test case ResultCodeCheck.6
		
	--End Test suit ResultCodeCheck

	
----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure os response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behaviour in case of absence of responses from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-412
				--APPLINK-10501
				--APPLINK-8585
				--SDLAQ-CRS-2928
				--SDLAQ-CRS-2929
				
			--Verification criteria:
				-- no UI response during SDL`s watchdog.
				-- In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND UI.AddCommand gets successful response from HMI in return AND VR.AddCommand gets no response from HMI during SDL's default timeout - SDL must send UI.DeleteCommand for the successfully added cmdID to HMI.
				-- In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND VR.AddCommand gets successful response from HMI in return AND UI.AddCommand gets no response from HMI during SDL's default timeout - SDL must send VR.DeleteCommand for the successfully added cmdID to HMI.
				-- SDL must return (GENERIC_ERROR, success:false) to mobile app in case app's request was split into several HMI interfaces by SDL and HMI does not respond at least one of them.
				
			--Begin HMINegativeCheck.1.1
			--Description: No response from UI
				function Test:AddCommand_NoResponseFromUI()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 301,
																	menuParams = 	
																	{ 
																		menuName ="Command301"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 301,
											menuParams = 	
											{ 
												menuName ="Command301"
											}
										})
										
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.1
			
			-----------------------------------------------------------------------------------------
	
			--Begin HMINegativeCheck.1.2
			--Description: Response from UI but no response from VR
				function Test:AddCommand_ResponseFromUINoResponseFromVR()					
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 302,
																menuParams = 	
																{ 																
																	menuName ="Command302"
																}, 
																vrCommands = 
																{ 
																	"VRCommand302"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 302,
										menuParams = 
										{ 											
											menuName ="Command302"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 302,							
										type = "Command",
										vrCommands = 
										{
											"VRCommand302"
										}
									})					
					:Do(function(_,data)
						--Do nothing
					end)
					
					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand",
					{cmdID = 302})				
					:Timeout(12000)
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id,"UI.DeleteCommand", "SUCCESS", {})
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
			--Description: Response from VR but no response from UI
				function Test:AddCommand_ResponseFromVRNoResponseFromUI()					
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
							{
																cmdID = 303,
																menuParams = 	
																{ 																
																	menuName ="Command303"
																}, 
																vrCommands = 
																{ 
																	"VRCommand303"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 303,
										menuParams = 
										{ 											
											menuName ="Command303"
										}
									})
					:Do(function(_,data)
						--Do nothing
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 303,							
										type = "Command",
										vrCommands = 
										{
											"VRCommand303"
										}
									})
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})
					end)
					
					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{cmdID = 303})				
					:Timeout(12000)
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
					end)
					
					--mobile side: expect response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.3
			
			-----------------------------------------------------------------------------------------

			--Begin HMINegativeCheck.1.4
			--Description: No Response from UI and VR
				function Test:AddCommand_NoResponseFromUIVR()					
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
							{
																cmdID = 303,
																menuParams = 	
																{ 																
																	menuName ="Command303"
																}, 
																vrCommands = 
																{ 
																	"VRCommand303"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 303,
										menuParams = 
										{ 											
											menuName ="Command303"
										}
									})
					:Do(function(_,data)
						--Do nothing
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 303,							
										type = "Command",
										vrCommands = 
										{
											"VRCommand303"
										}
									})
					:Do(function(exp,data)
						--Do nothing
					end)
					
					--mobile side: expect response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End HMINegativeCheck.1.4			
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Invalid structure of response

			--Requirement id in JAMA:
				--SDLAQ-CRS-22
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
			
			--Begin Test case HMINegativeCheck.2.1
			--Description: UI&VR.AddCommand response with invalid structure
				function Test: AddCommand_ResponseInvalidStructure()
					local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 303,
																	menuParams = 	
																	{ 																
																		menuName ="Command303"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand303"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 303,
											menuParams = 
											{ 											
												menuName ="Command303"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"UI.AddCommand"}}')						
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 303,							
											type = "Command",
											vrCommands = 
											{
												"VRCommand303"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"VR.AddCommand"}}')
						end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case HMINegativeCheck.2.1								
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.2.2
			--Description: UI.AddCommand response with invalid structure
				function Test: AddCommand_InvalidResponseUI()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 304,
																	menuParams = 	
																	{ 																
																		menuName ="Command304"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand304"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 304,
											menuParams = 
											{ 											
												menuName ="Command304"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{"error":{"code":4,"message":"UI.AddCommand is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.AddCommand"}}')
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 304,							
											type = "Command",
											vrCommands = 
											{
												"VRCommand304"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
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
			--Description: VR.AddCommand response with invalid structure
				function Test: AddCommand_InvalidResponseVR()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 304,
																	menuParams = 	
																	{ 																
																		menuName ="Command304"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand304"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 304,
											menuParams = 
											{ 											
												menuName ="Command304"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 304,							
											type = "Command",
											vrCommands = 
											{
												"VRCommand304"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:Send('{"error":{"code":4,"message":"UI.AddCommand is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"VR.AddCommand"}}')						
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
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-22
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:AddCommand_SeveralResponseToOneRequest()
				--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 222,
																	menuParams = 	
																	{ 
																		menuName ="Command222"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 222,
											menuParams = 	
											{ 
												menuName ="Command222"
											}
										})
				:Do(function(_,data)
					--hmi side: sending response					
					self.hmiConnection:SendResponse( data.id , "UI.AddCommand" , "INVALID_DATA", {})
					self.hmiConnection:SendResponse( data.id , "UI.AddCommand" , "SUCCESS", {})					
					self.hmiConnection:SendResponse( data.id , "UI.AddCommand" , "INVALID_ID", {})
				end)
				
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end									
			
		--End Test case HMINegativeCheck.3
				
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-22
				
			--Verification criteria:
				-- When expected HMI function is received, send responses from HMI with fake parameter			
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:AddCommand_FakeParamsInResponse()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 305,
																menuParams = 	
																{ 
																	menuName ="Command305"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 305,
										menuParams = 	
										{ 
											menuName ="Command305"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
					end)
					
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
				function Test:AddCommand_ParamsFromOtherAPIInResponse()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 306,
																menuParams = 	
																{ 
																	menuName ="Command306"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 306,
										menuParams = 	
										{ 
											menuName ="Command306"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
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
				--SDLAQ-CRS-22
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.5.1
			--Description: Send response to VR.AddCommand instead of UI.AddCommand			
				function Test:AddCommand_WrongResponseToUI()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 2004,
																menuParams =
																{
																	menuName ="Command2004"
																}
															})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 2004,
										menuParams =
										{
											menuName ="Command2004"
										}
									})
					:Do(function(_,data)
						--hmi side: sending response					
						self.hmiConnection:SendResponse( data.id , "VR.AddCommand" , "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})		
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case HMINegativeCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.5.2
			--Description: Send response to UI.AddCommand instead of VR.AddCommand			
				function Test:AddCommand_WrongResponseToVR()
					--mobile side: sending request 
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 2005,
																menuParams =
																{
																	menuName ="Command2005"
																},
																vrCommands = 
																{
																	"VRCommand2005"
																}
															})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 2005,
										menuParams =
										{
											menuName ="Command2005"
										}
									})
					:Do(function(_,data)
						--hmi side: sending response					
						self.hmiConnection:SendResponse( data.id , "UI.AddCommand" , "SUCCESS", {})
					end)
					
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 2005,							
										type = "Command",
										vrCommands = 
										{
											"VRCommand2005"
										}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse( data.id , "UI.AddCommand" , "SUCCESS", {})
					end)

					--hmi side: expect UI.DeleteCommand request
					EXPECT_HMICALL("UI.DeleteCommand",
					{cmdID = 2005})				
					:Timeout(15000)
					:Do(function(exp,data)
						self.hmiConnection:SendResponse(data.id,"UI.DeleteCommand", "SUCCESS", {})
					end)
					
					--mobile side: expect response 
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})		
					:Timeout(12000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case HMINegativeCheck.5.2			
		--End Test case HMINegativeCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.6
		--Description: 
			-- Checking in case UI & VR gets any erroneous response from HMI

			--Requirement id in JAMA:
				--APPLINK-10501
				--SDLAQ-CRS-2930
				--SDLAQ-CRS-2931
				--SDLAQ-CRS-2932
				--SDLAQ-CRS-2933
				
			--Verification criteria:
				--In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND UI.AddCommand gets successful response from HMI in return AND VR.AddCommand gets any erroneous response (except REJECTED) from HMI - SDL must send UI.AddCommand for the successfully added cmdID to HMI.
				--In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND UI.AddCommand gets successful response from HMI in return AND VR.AddCommand gets any REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.
				--In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND VR.AddCommand gets successful response from HMI in return AND UI.AddCommand gets erroneous response except of WARNINGS and UNSUPPORTED_RESOURCE and REJECTED from HMI - SDL must send AddCommand_response(GENERIC_ERROR) to mobile app.
				--In case SDL sends both UI.AddCommand and VR.AddCommand with one and the same cmdID to HMI AND VR.AddCommand gets successful response from HMI in return AND UI.AddCommand gets REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.
			
			--Begin Test case HMINegativeCheck.6.1
			--Description: UI.AddCommand gets successful response AND VR.AddCommand gets any erroneous response
				local erroneousValues = {"INVALID_DATA", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "INVALID_ID", "DUPLICATE_NAME", "APPLICATION_NOT_REGISTERED", "GENERIC_ERROR", "REJECTED", "DISALLOWED", "UNSUPPORTED_RESOURCE", "WARNINGS"}
				for i = 1, #erroneousValues do
					Test["AddCommand_VRErroneousResponse" .. tostring(erroneousValues[i])] = function(self)
						self:addCommand_VRErroneousResponse(erroneousValues[i])
					end
				end
			--End Test case HMINegativeCheck.6.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.6.2
			--Description: VR.AddCommand gets successful response AND UI.AddCommand gets any erroneous response
				for i = 1, #erroneousValues do
					Test["AddCommand_UIErroneousResponse" .. tostring(erroneousValues[i])] = function(self)
						self:addCommand_UIErroneousResponse(erroneousValues[i], 2010+i)
					end				
				end
			--End Test case HMINegativeCheck.6.2
		--End Test case HMINegativeCheck.6
	--End Test case HMINegativeCheck
----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	
		--Begin Test case SequenceCheck.1
		--Description: Checking execution of command

			--Requirement id in JAMA:
				--SDLAQ-CRS-177
			--Verification criteria:
				-- When the user triggers any command on persistent display command menu, OnCommand notification is returned to the app with corresponding command identifier and MENU trigger source.
				-- When the user triggers any command via VR, OnCommand notification is returned to the app with corresponding command identifier and VR trigger source.
			
			--Description: Add command for execution
				function Test:AddCommand_PositiveCase()
					--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 4001,
																	menuParams = 	
																	{ 	
																		position = 0,
																		menuName ="Command4001"
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand4001"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 4001,										
											menuParams = 
											{
												menuName ="Command4001"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 4001,							
											type = "Command",
											vrCommands = 
											{
												"VRCommand4001"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							grammarIDValue = data.params.grammarID
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					
			--Begin Test case SequenceCheck.1.1
			--Description: Execution command via HMI
				function Test:AddCommand_ExecutionCommandViaHMI()
					--hmi side: sending UI.OnSystemContext notification 
					SendOnSystemContext(self,"MENU")				
					
					--hmi side: sending UI.OnCommand notification			
					self.hmiConnection:SendNotification("UI.OnCommand",
					{
						cmdID = 4001,
						appID = self.applications["Test Application"],
						grammarID = grammarIDValue
					})
					
					--hmi side: sending UI.OnSystemContext notification 
					SendOnSystemContext(self,"MAIN")		
					
					
					--mobile side: expected OnHMIStatus notification
					if 
						self.isMediaApplication == true or
						self.appHMITypes["NAVIGATION"] == true then
							EXPECT_NOTIFICATION("OnHMIStatus", 
								{ systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
								{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
							:Times(2)
					elseif
						self.isMediaApplication == true then

							EXPECT_NOTIFICATION("OnHMIStatus", 
								{ systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
							:Times(2)

					end
					--mobile side: expected OnCommand notification
					EXPECT_NOTIFICATION("OnCommand", {cmdID = 4001, triggerSource= "MENU"})
				end
			--End Test case SequenceCheck.1.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.1.2
			--Description: Execution command via VR
				function Test:AddCommand_ExecutionCommandViaVR()
					--hmi side: Start VR and sending UI.OnSystemContext notification 
					self.hmiConnection:SendNotification("VR.Started",{})
					SendOnSystemContext(self,"VRSESSION")
					
					--hmi side: sending UI.OnCommand notification			
					self.hmiConnection:SendNotification("VR.OnCommand",
					{
						cmdID = 4001,
						appID = self.applications["Test Application"],
						grammarID = grammarIDValue
					})
					
					--hmi side: Stop VR and sending UI.OnSystemContext notification 
					self.hmiConnection:SendNotification("VR.Stopped",{})
					SendOnSystemContext(self,"MAIN")		

					--mobile side: expected OnHMIStatus notification
					if 
						self.isMediaApplication == true or 
						self.appHMITypes["NAVIGATION"] == true then
							EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
								{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
								{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
								{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
							:Times(4)
					elseif
						self.isMediaApplication == false then
							EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
								{ systemContext = "MAIN", 	hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  })
							:Times(2)
					end
					
					--mobile side: expect OnCommand notification 
					EXPECT_NOTIFICATION("OnCommand", {cmdID = 4001, triggerSource= "VR"})
				end
			--End Test case SequenceCheck.1.2
		--End Test case SequenceCheck.1
		
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.2
		--Description: 
				-- GrammarID should be generated by SDL for every application.
				-- All top-level commands added by the application (via AddCommand) must have the same GrammarID value.
				-- GrammarID values should be unique across all the applications top-level Commands and ChoiceSet GrammarIDs.
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-2797
				--APPLINK-6474
				
			--Verification criteria:
				-- SDL generates GrammarID for all VR application commands.
				-- All top-level commands have the same GrammarID values.
				-- GrammarID values of the commands and ChoiceSets of different applications are unique across all the applications.
				for i=1, 10 do
					Test["AddCommand_CheckGeneratedGrammarID"..tostring(i)] = function(self)
						local idValue = i + 5000
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = idValue,
																	menuParams = 	
																	{ 																	
																		position = 0,
																		menuName ="Command"..tostring(idValue)
																	}, 
																	vrCommands = 
																	{ 
																		"VRCommand"..tostring(idValue).."1",
																		"VRCommand"..tostring(idValue).."2",
																		"VRCommand"..tostring(idValue).."3"
																	}
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = idValue,										
											menuParams = 
											{
												menuName ="Command"..tostring(idValue)
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = idValue,							
											type = "Command",
											vrCommands = 
											{
												"VRCommand"..tostring(idValue).."1",
												"VRCommand"..tostring(idValue).."2",
												"VRCommand"..tostring(idValue).."3"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							if data.params.grammarID ~= grammarIDValue then
								print("GrammarID is generated not the same")							
							end						
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				end
		--End Test case SequenceCheck.2
		
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.3
		--Description: Cover TC_GrammarID_01

			--Requirement id in JAMA:
				--SDLAQ-TC-343
			--Verification criteria:
				--SDL assign grammarID parameter for all added commands.
			-- Precondition 1: Register new media app
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession2:StartService(7)
			end
					
			function Test:RegisterAppInterface_MediaApp2()
				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="MediaApp2",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appHMIType = {"COMMUNICATION","NAVIGATION"},
																appID ="6",
																ttsName = 
																{ 
																	{ 
																		text ="MediaApp2",
																		type ="TEXT",
																	}, 
																}, 
																vrSynonyms = 
																{ 
																	"vrMediaApp2",
																}
															}) 
			 
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "MediaApp2"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp2"] = data.params.application.appID					
				end)
				
				--mobile side: RegisterAppInterface response 
				self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
			
			function Test:Activate_App2()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp2"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
				
				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
				:Timeout(12000)				
			end
			
			function Test:AddCommand_FirstCommandApp2()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession2:SendRPC("AddCommand",
														{
															cmdID = 2001,
															menuParams = 	
															{ 	
																position = 1000,
																menuName ="Item to add"
															}, 
															vrCommands = 
															{ 
																"synonym1","synonym2"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 2001,										
									menuParams = 
									{
										menuName ="Item to add"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2001,							
									type = "Command",
									vrCommands = 
									{
										"synonym1","synonym2"
									}
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					grammarIDApp2 = data.params.grammarID
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:ValidIf(function(_,data)
					if grammarIDValue == data.params.grammarID then
						commonFunctions:printError("GrammarID of application2 is similar with grammarID of application1")
						return false
					else
						return true
					end
				end)
				--mobile side: expect AddCommand response
				self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				self.mobileSession2:ExpectNotification("OnHashChange",{})
			end
			
			function Test:AddCommand_SecondCommandApp2()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession2:SendRPC("AddCommand",
														{
															cmdID = 2002,
															menuParams = 	
															{ 	
																position = 1000,
																menuName ="Item"
															}, 
															vrCommands = 
															{ 
																"Synonym"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 2002,										
									menuParams = 
									{
										menuName ="Item"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2002,							
									type = "Command",
									vrCommands = 
									{
										"Synonym"
									}
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response					
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:ValidIf(function(_,data)
					if grammarIDApp2 ~= data.params.grammarID  then
						commonFunctions:printError("GrammarID is differrence for the same app")
						return false
					else
						return true
					end
				end)
				--mobile side: expect AddCommand response
				self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				self.mobileSession2:ExpectNotification("OnHashChange",{})
			end			
		--End Test case SequenceCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.4
		--Description: Cover TC_GrammarID_04

			--Requirement id in JAMA:
				--SDLAQ-TC-1247
			--Verification criteria:
				--The goal is to test that SDL calculates appID depending on proper grammarID provided by HMI in case multiple apps are registered
			
			-- Precondition 1: Register new media app
			commonFunctions:newTestCasesGroup("Test case: Precondition TC_GrammarID_04")
			
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession3 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession3:StartService(7)
			end
					
			function Test:RegisterAppInterface_MediaApp3()
				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="MediaApp3",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="3",
																ttsName = 
																{ 
																	{ 
																		text ="MediaApp3",
																		type ="TEXT",
																	}, 
																}, 
																vrSynonyms = 
																{ 
																	"vrMediaApp3",
																}
															}) 
			 
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "MediaApp3"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp3"] = data.params.application.appID					
				end)
				
				--mobile side: RegisterAppInterface response 
				self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
			
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession4 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession4:StartService(7)
			end
					
			function Test:RegisterAppInterface_MediaApp4()
				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="MediaApp4",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="4",
																ttsName = 
																{ 
																	{ 
																		text ="MediaApp4",
																		type ="TEXT",
																	}, 
																}, 
																vrSynonyms = 
																{ 
																	"vrMediaApp4",
																}
															}) 
			 
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "MediaApp4"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp4"] = data.params.application.appID					
				end)
				
				--mobile side: RegisterAppInterface response 
				self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
			
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession5 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession5:StartService(7)
			end
					
			function Test:RegisterAppInterface_MediaApp5()
				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession5:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="MediaApp5",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="5",
																ttsName = 
																{ 
																	{ 
																		text ="MediaApp5",
																		type ="TEXT",
																	}, 
																}, 
																vrSynonyms = 
																{ 
																	"vrMediaApp5",
																}
															}) 
			 
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "MediaApp5"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp5"] = data.params.application.appID					
				end)
				
				--mobile side: RegisterAppInterface response 
				self.mobileSession5:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
			
			function Test:Activate_App3()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp3"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
				:Timeout(12000)				
			end
			
			function Test:AddCommand_App3()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession3:SendRPC("AddCommand",
														{
															cmdID = 2003,
															menuParams = 	
															{ 	
																position = 1000,
																menuName ="Item to add App3"
															}, 
															vrCommands = 
															{ 
																"synonym  App3"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 2003,										
									menuParams = 
									{
										menuName ="Item to add App3"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2003,							
									type = "Command",
									vrCommands = 
									{
										"synonym  App3"
									}
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					grammarIDApp3 = data.params.grammarID
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect AddCommand response
				self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				self.mobileSession3:ExpectNotification("OnHashChange",{})
			end
			
			function Test:Activate_App4()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp4"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
				:Timeout(12000)				
			end
			
			function Test:AddCommand_App4()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession4:SendRPC("AddCommand",
														{
															cmdID = 2004,
															menuParams = 	
															{ 	
																position = 1000,
																menuName ="Item to add App4"
															}, 
															vrCommands = 
															{ 
																"synonym  App4"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 2004,										
									menuParams = 
									{
										menuName ="Item to add App4"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2004,							
									type = "Command",
									vrCommands = 
									{
										"synonym  App4"
									}
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					grammarIDApp4 = data.params.grammarID
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect AddCommand response
				self.mobileSession4:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				self.mobileSession4:ExpectNotification("OnHashChange",{})
			end
			
			function Test:Activate_App5()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp5"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
				:Timeout(12000)				
			end
			
			function Test:AddCommand_App5()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession5:SendRPC("AddCommand",
														{
															cmdID = 2005,
															menuParams = 	
															{ 	
																position = 1000,
																menuName ="Item to add App5"
															}, 
															vrCommands = 
															{ 
																"synonym  App5"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 2005,										
									menuParams = 
									{
										menuName ="Item to add App5"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
					
				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
								{ 
									cmdID = 2005,							
									type = "Command",
									vrCommands = 
									{
										"synonym  App5"
									}
								})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					grammarIDApp5 = data.params.grammarID
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect AddCommand response
				self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				self.mobileSession5:ExpectNotification("OnHashChange",{})
			end
			
			commonFunctions:newTestCasesGroup("Test case: TC_GrammarID_04")    
			
			function Test:Activate_App1()
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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 				
			end
			
			function Test:AddCommand_ExecutionCommandViaVR_App1()				
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION")
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 4001,
					appID = self.applications["Test Application"],
					grammarID = grammarIDValue
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN")		

				--mobile side: expected OnHMIStatus notification
				if 
					self.isMediaApplication == true or 
					self.appHMITypes["NAVIGATION"] == true then
						EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
							{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
							{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
							{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
						:Times(4)
				elseif
					self.isMediaApplication == false then
						EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
							{ systemContext = "MAIN", 	hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  })
						:Times(2)
				end
				
				--mobile side: expect OnCommand notification 
				EXPECT_NOTIFICATION("OnCommand", {cmdID = 4001, triggerSource= "VR"})
			end
			
			function Test:Activate_App2()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp2"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
			end
			
			function Test:AddCommand_ExecutionCommandViaVR_App2()				
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION", self.applications["MediaApp2"])
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 2001,
					appID = self.applications["MediaApp2"],
					grammarID = grammarIDApp2
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN", self.applications["MediaApp2"])
				
				self.mobileSession2:ExpectNotification("OnHMIStatus",
					{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
					{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
					{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
					{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
				:Times(4)
				
				--mobile side: expect OnCommand notification 
				self.mobileSession2:ExpectNotification("OnCommand", {cmdID = 2001, triggerSource= "VR"})
			end
					
			function Test:Activate_App3()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp3"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Timeout(11000)
									end)

						end
					end)
				
				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 				
			end
			
			function Test:AddCommand_ExecutionCommandViaVR_App3()
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION", self.applications["MediaApp3"])
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 2003,
					appID = self.applications["MediaApp3"],
					grammarID = grammarIDApp3
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN", self.applications["MediaApp3"])
				
				self.mobileSession3:ExpectNotification("OnHMIStatus",
					{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
					{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
					{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
					{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
				:Times(4)
				
				--mobile side: expect OnCommand notification 
				self.mobileSession3:ExpectNotification("OnCommand", {cmdID = 2003, triggerSource= "VR"})
			end
				
			function Test:Activate_App4()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp4"]})

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
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
									:Timeout(11000)
								end)						
						end
					end)
				
				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 				
			end
			
			function Test:AddCommand_ExecutionCommandViaVR_App4()
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION", self.applications["MediaApp4"])
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 2004,
					appID = self.applications["MediaApp4"],
					grammarID = grammarIDApp4
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN", self.applications["MediaApp4"])
				
				self.mobileSession4:ExpectNotification("OnHMIStatus",
					{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
					{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
					{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
					{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
				:Times(4)
				
				--mobile side: expect OnCommand notification 
				self.mobileSession4:ExpectNotification("OnCommand", {cmdID = 2004, triggerSource= "VR"})
			end
			
			function Test:Activate_App5()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp5"]})

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
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
									:Timeout(11000)
								end)						
						end
					end)
				
				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
			end
			
			function Test:AddCommand_ExecutionCommandViaVR_App5()
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION", self.applications["MediaApp5"])
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 2005,
					appID = self.applications["MediaApp5"],
					grammarID = grammarIDApp5
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN", self.applications["MediaApp5"])
				
				self.mobileSession5:ExpectNotification("OnHMIStatus",
					{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
					{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
					{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
					{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
				:Times(4)
				
				--mobile side: expect OnCommand notification 
				self.mobileSession5:ExpectNotification("OnCommand", {cmdID = 2005, triggerSource= "VR"})
			end			
		--End Test case SequenceCheck.4
		
		-----------------------------------------------------------------------------------------
		commonFunctions:newTestCasesGroup("Test case: Precondition TC_GrammarID_05")
		--Begin Test case SequenceCheck.5
		--Description: Cover TC_GrammarID_05

			--Requirement id in JAMA:
				--SDLAQ-TC-1248
			--Verification criteria:
				--The goal is to test that commandID is calculated properly from grammarID if command is chosen by VR			
			function Test:Activate_App1()
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
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
									:Timeout(11000)
								end)

						end
					end)
				
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 				
			end
--[[TODO: Check after APPLINK-17207 is resolved	
			function Test:AddCommand_ExecutionCommandViaVR_WithOutAppID()
				--hmi side: Start VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Started",{})
				SendOnSystemContext(self,"VRSESSION")
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("VR.OnCommand",
				{
					cmdID = 4001,						
					grammarID = grammarIDValue
				})
				
				--hmi side: Stop VR and sending UI.OnSystemContext notification 
				self.hmiConnection:SendNotification("VR.Stopped",{})
				SendOnSystemContext(self,"MAIN")		

				--mobile side: expected OnHMIStatus notification
				if 
					self.isMediaApplication == true or 
					self.appHMITypes["NAVIGATION"] == true then
						EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  },
							{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
							{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    	  },
							{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"        })
						:Times(4)
				elseif
					self.isMediaApplication == false then
						EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"        },
							{ systemContext = "MAIN", 	hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    	  })
						:Times(2)
				end
				
				--mobile side: expect OnCommand notification 
				EXPECT_NOTIFICATION("OnCommand", {cmdID = 4001, triggerSource= "VR"})
			end			
		--End Test case SequenceCheck.5		
--]]

	--------------------------------------------------------------------------------------------
	--Begin Test case SequenceCheck.6
		--Description: Covers TC APPLINK-18308. 

			--Requirement id in JAMA: 
					--SDLAQ-CRS-1305
					
			--Verification criteria: 
					--This test is to check the ability to add commands with same names to different menus (root/submenu). 
	local function APPLINK_18308()
		--Begin Precondition
			--Description: Adding SubMenu(AddSubMenus)
				local menuIDValues = {11, 22, 33}
				for i=1,#menuIDValues do
					Test["AddSubMenuWithId"..menuIDValues[i]] = function(self)
						local cid = self.mobileSession:SendRPC("AddSubMenu",
						{
							menuID = menuIDValues[i],
							menuName = "SubMenu_0"..tostring(i)
						})
						
						EXPECT_HMICALL("UI.AddSubMenu", 
						{ 
							menuID = menuIDValues[i],
							menuParams = { menuName = "SubMenu_0"..tostring(i) }
						})
						:Do(function(_,data)
								--hmi side: sending response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									--commonFunctions:printTable(data)
						end)
						
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						EXPECT_NOTIFICATION("OnHashChange")
					end
				end
		--End Precondition
	
		--Send AddCommand "Command_01" VrSynonyms = command1
			function Test:AddCommand_CommandID01_NoSubmenu()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 01,
						menuParams = 	
						{ 
							menuName ="Command_01"
						},
						vrCommands = 
						{ 
							"command1"
						}
					})
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 01,
						type = "Command",
						vrCommands = 
						{
							"command1"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 01,
						menuParams = 	
						{ 
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
			
		--Send AddCommand "Command_01" + addItem to "Submenu_02" VrSynonyms = disabled
			function Test:AddCommand_SameCommandID01_DifferentSubmenu_VrSynonymsDisabled()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 03,
						menuParams = 	
						{ 
							parentID = 22,
							position = 1000,
							menuName ="Command_01"
						}
					})
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 03,
						menuParams = 	
						{ 
							parentID = 22,
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
				
		--Send AddCommand "Command_01" + addItem to "Submenu_03" VrSynonyms = command3
			
				function Test:AddCommand_SameCommandID01_DifferentSubmenu_VrSynonumEnabled()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 04,
						menuParams = 	
						{ 
							parentID = 33,	
							position = 1000,
							menuName ="Command_01"
						},
						vrCommands = 
						{ 
							"command3"
						}
					})
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 04,
						type = "Command",
						vrCommands = 
						{
							"command3"
						}
					})
					:Do(function(_,data)
						--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)	
					
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
					{ 
						cmdID = 04,
						menuParams = 	
						{ 
							parentID = 33,
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
		
	end
	APPLINK_18308()
	
	--End Test case SequenceCheck.6
	-------------------------------------------------------------------------------------------
	--End Test suit SequenceCheck

	
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: Default values taken from Policy Table

			--Requirement id in JAMA:
				--SDLAQ-CRS-752
			--Verification criteria:
				-- SDL doesn't reject AddCommand request when current HMI is FULL.
				-- SDL doesn't reject AddCommand request when current HMI is LIMITED.
				-- SDL doesn't reject AddCommand request when current HMI is BACKGROUND.
			
			--Begin Test case DifferentHMIlevel.1.1
			--Description: SDL doesn't reject AddCommand request when current HMI is LIMITED.
			
			if 
				Test.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] then 
				
				function Test:ChangeHMIToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end
				
				function Test:AddCommand_HMILevelLimited()
					AddCommand_cmdID(self, 1125, true, "SUCCESS")
				end			
			--End Test case DifferentHMIlevel.1.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case DifferentHMIlevel.1.2
			--Description: SDL doesn't reject AddCommand request when current HMI is BACKGROUND.
					
				--Description: Activate second app					
				function Test:Activate_App2()
					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp2"]})

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
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Times(AnyNumber())										
										:Timeout(11000)
									end)							
							end
						end)
					
					self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				--Description: AddCommand when HMI level BACKGROUND
					function Test:AddCommand_HMILevelBackground()
						AddCommand_cmdID(self, 1126, true, "SUCCESS")
					end
			elseif Test.isMediaApplication == false then

				function Test:ChangeHMIToBackground()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				function Test:AddCommand_HMILevelBackground()
					AddCommand_cmdID(self, 1125, true, "SUCCESS")
				end	

			end
			--End Test case DifferentHMIlevel.1.2
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel


	
---------------------------------------------------------------------------------------------------------------------
---------------------------VIII ADD COVERAGE TO ATF_AddCmmand(SDLAQ-TC-1375)-----------------------------------------
-------AddCommand: [RTC 525037] No VR/UI deletecommand request sent when one of them times out (Job-1)---------------
---------------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: APPLINK-10501	
	--SDLAQ-CRS-2928: UI.AddCommand - success, VR.AddCommand - no response
	--SDLAQ-CRS-2929: VR.AddCommand - success, UI.AddCommand - no response
	--SDLAQ-CRS-2930: UI.AddCommand - success, VR.AddCommand - error (except of REJECTED)
	--SDLAQ-CRS-2931: UI.AddCommand - success, VR.AddCommand - REJECTED (SDLAQ-CRS-2931)
	--SDLAQ-CRS-2932: VR.AddCommand - success, UI.AddCommand - error (except of WARNINGS, UNSUPPORTED_RESOURCE, REJECTED)
	--SDLAQ-CRS-2933: VR.AddCommand - success, UI.AddCommand - REJECTED (SDLAQ-CRS-2933)
---------------------------------------------------------------------------------------------------------------------

local function SequenceAddCoverageAPPLINK_10501()

----------------------------------------------------------------------------------------------------------------------
---------------------------------------------------Common function----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
		
		--Description: 
			-- In case VR.AddCommand gets any erroneous response except REJECTED from HMI - SDL must send AddCommand_response(GENERIC_ERROR) to mobile app.
			-- In case VR.AddCommand gets any REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.
			-- In case SDL sends UI.DeleteCommand to HMI
		function Test:addCommand_VRErroneousResponseUpdated (vrResultResponse, cmdIDValue)
			local resultCodeValue
			if vrResultResponse == "REJECTED" or vrResultResponse == "WARNINGS" then				
				resultCodeValue = vrResultResponse
			else				
				resultCodeValue = "GENERIC_ERROR"
			end
			
			--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
					{
														cmdID = cmdIDValue,
														menuParams = 	
														{ 																
															menuName ="Command"..cmdIDValue
														}, 
														vrCommands = 
														{ 
															"VRCommand"..cmdIDValue
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = cmdIDValue,
								menuParams = 
								{ 											
									menuName ="Command"..cmdIDValue
								}
							})
			:Do(function(exp,data)
				--hmi side: send UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = cmdIDValue,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand"..cmdIDValue
								}
							})
			:Do(function(exp,data)
				if (vrResultResponse ~= "TIMED_OUT") then
					--hmi side: sending VR.AddCommand response
					self.hmiConnection:SendError(data.id, data.method, vrResultResponse, "Error Messages")
				end
			end)
			
			if vrResultResponse ~= "WARNINGS" then
				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand", {cmdID = cmdIDValue})
				:Timeout(15000)
				:Do(function(exp,data)
					--hmi side: sending UI.DeleteCommand response
					self.hmiConnection:SendResponse(data.id,"UI.DeleteCommand", "SUCCESS", {})
				end)
			
				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = false, resultCode = resultCodeValue })	
				:Timeout(12000)
							
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			else
				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true, resultCode = resultCodeValue })					
							
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				
				commonTestCases:DelayedExp(1000)
				
			end
		end
		
		--------------------------------------------------------------------------------------------------------------
	
		--Description: 
			-- In case UI.AddCommand gets erroneous response except of WARNINGS and UNSUPPORTED_RESOURCE and REJECTED from HMI - SDL must send AddCommand_response(GENERIC_ERROR) to mobile app.
			-- In case UI.AddCommand gets REJECTED from HMI - SDL must send AddCommand_response(REJECTED) to mobile app.
			-- In case of WARNINGS or UNSUPPORTED_RESOURCE from HMI, SDL must transfer the resultCode from HMI's response with adding "success: true" to mobile app.
			-- In case SDL sends VR.DeleteCommand to HMI
		function Test:addCommand_UIErroneousResponseUpdated (uiResultResponse, cmdIDValue)
			local resultCodeValue, succcessValue
			if uiResultResponse == "REJECTED" or uiResultResponse == "WARNINGS" or uiResultResponse == "UNSUPPORTED_RESOURCE" then				
				resultCodeValue = uiResultResponse
				if uiResultResponse ~= "REJECTED" then
					succcessValue = true
				else
					succcessValue = false
				end
			else				
				resultCodeValue = "GENERIC_ERROR"
				succcessValue = false
			end
			
			--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
					{
														cmdID = cmdIDValue,
														menuParams = 	
														{ 																
															menuName ="Command"..cmdIDValue
														}, 
														vrCommands = 
														{ 
															"VRCommand"..cmdIDValue
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = cmdIDValue,
								menuParams = 
								{ 											
									menuName ="Command"..cmdIDValue
								}
			})
			:Do(function(exp,data)
				if (uiResultResponse ~= "TIMED_OUT") then --no response
					--hmi side: send UI.AddCommand response
					self.hmiConnection:SendError(data.id, data.method, uiResultResponse, "Error Messages")
				end
			end)
			
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = cmdIDValue,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand"..cmdIDValue
								}
							})
			:Do(function(exp,data)
				--hmi side: sending VR.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			if uiResultResponse ~= "WARNINGS" and uiResultResponse ~= "UNSUPPORTED_RESOURCE"  then				
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand", {cmdID = cmdIDValue})
				:Timeout(15000)
				:Do(function(exp,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id,"VR.DeleteCommand", "SUCCESS", {})
				end)
				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			else
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand", {cmdID = cmdIDValue})
				:Times(0)
				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
			
			--mobile side: expect response
			EXPECT_RESPONSE(cid, { success = succcessValue, resultCode = resultCodeValue })			
			:Timeout(12000)
			
			commonTestCases:DelayedExp(1000)
		end
	
		-------------------------------------------------------------------------------------------------------------
		
---------------------------------------------------------------------------------------------------------------------
------------------------------------------------End Common function--------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------VIII ADD COVERAGE TO ATF_AddCmmand(SDLAQ-TC-1375)------------------------------")
	
	local function APPLINK_10501()

		-------------------------------------------------------------------------------------------------------------	
	
		-- Description: Activation app
		commonSteps:ActivationApp( _, "APPLINK_10501_ActivationApp")

		-------------------------------------------------------------------------------------------------------------
	
		-- Description: UI.AddCommand - success, VR.AddCommand - no response (TIMED_OUT)
						--JamaID: SDLAQ-CRS-2928
		function Test:APPLINK_10501_UISuccess_VRTIMED_OUT()

			self:addCommand_VRErroneousResponseUpdated("TIMED_OUT", 2015)
			
		end
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: UI.AddCommand - success, VR.AddCommand - no response (TIMED_OUT)
						--JamaID: SDLAQ-CRS-2929
		function Test:APPLINK_10501_VRSuccess_UITIMED_OUT()

			self:addCommand_UIErroneousResponseUpdated("TIMED_OUT", 2016)
			
		end
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: UI.AddCommand - success, VR.AddCommand - error except REJECTED (GENERIC_ERROR)
						--JamaID: SDLAQ-CRS-2930
		function Test:APPLINK_10501_UISuccess_VRGENERIC_ERROR()

			self:addCommand_VRErroneousResponseUpdated("GENERIC_ERROR", 2017)
			
		end
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: UI.AddCommand - success, VR.AddCommand - response REJECTED
						--JamaID: SDLAQ-CRS-2931
		function Test:APPLINK_10501_UISuccess_VRREJECTED()

			self:addCommand_VRErroneousResponseUpdated("REJECTED", 2018)
			
		end
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: VR.AddCommand - success, UI.AddCommand - error except of WARNINGS, UNSUPPORTED_RESOURCE, REJECTED (GENERIC_ERROR)
						--JamaID: SDLAQ-CRS-2932
		function Test:APPLINK_10501_VRSuccess_UIGENERIC_ERROR()

			self:addCommand_UIErroneousResponseUpdated("GENERIC_ERROR", 2019)
			
		end
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: VR.AddCommand - success, UI.AddCommand - REJECTED
						--JamaID: SDLAQ-CRS-2933
		function Test:APPLINK_10501_VRSuccess_UIREJECTED()

			self:addCommand_UIErroneousResponseUpdated("REJECTED", 2014)
			
		end
		
		-------------------------------------------------------------------------------------------------------------
	end
	
	--Main to execute test cases
	APPLINK_10501()
	
end

SequenceAddCoverageAPPLINK_10501()