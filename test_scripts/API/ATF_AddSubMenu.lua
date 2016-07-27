Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

local infoMessage = string.rep("a",1000)
APIName = "AddSubMenu"

require('user_modules/AppTypes')



local AddedSubMenus = {}


---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createResponse(Request)
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------

--Use this variable in createRequest function
icreasingNumber = 1

--Create default request
function Test:createRequest()
	icreasingNumber = icreasingNumber + 1
	return 	{
		menuID = 520+ icreasingNumber,
		position = 520 + icreasingNumber,
		menuName ="SubMenupositive999_" .. tostring(icreasingNumber)
	}	
end

--Create UI.AddSubMenu expected result based on parameters from the request
function Test:createResponse(Request)
	
	--local Req = commonFunctions:cloneTable(Request)
	
	local Response = {}
	if Request["menuID"] ~= nil then
		Response["menuID"] = Request["menuID"]
	end
	
	if Request["menuName"] ~= nil then
		Response["menuParams"] = 
		{
			position = Request["position"],
			menuName = Request["menuName"]
		}
	end
	
	return Response
	
end

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)
	
	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect UI.AddSubMenu request 
	local Response = self:createResponse(Request)
	EXPECT_HMICALL("UI.AddSubMenu", Response)
	:Do(function(_,data)
		--hmi side: sending response		
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect AddSubMenu response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end

	
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})

	
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
					--SDLAQ-CRS-30				

			--Verification criteria: 
					--AddSubMenu request with MenuParams and VR synonym definitions adds the command to the both UI and VR Command menu. This command is accessible from VR and UI Command menu.
				function Test:AddSubMenu_Positive()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 1000,
																position = 500,
																menuName ="SubMenupositive"
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = 1000,
										menuParams = {
											position = 500,
											menuName ="SubMenupositive"
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
			--End Test case CommonRequestCheck.1
						
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters
			--Requirement id in JAMA:
					--SDLAQ-CRS-30	

			--Verification criteria:
					--AddSubMenu request adds the command to VR Menu, UI Command/SubMenu menu or to the both depending on the parameters sent (VR, UI commands or the both correspondingly).
			function Test:AddSubMenu_MandatoryOnly()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 11,
															menuName ="SubMenumandatoryonly"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 11,
									menuParams = {
										menuName ="SubMenumandatoryonly"
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
		--End Test case CommonRequestCheck.2
				
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA:
					--SDLAQ-CRS-429

			--Verification criteria:
					--The request without "menuID" is sent, the response with INVALID_DATA result code is returned.
					--The request without "menuName" is sent, the response with INVALID_DATA result code is returned.
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: without "menuID"
				function Test:AddSubMenu_menuIDMissing()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																position = 1,
																menuName ="SubMenu1"
															})
													
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.1
			
			-----------------------------------------------------------------------------------------
		
			--Begin Test case CommonRequestCheck.3.2
			--Description: without "menuName"
				function Test:AddSubMenu_menuNameMissing()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 2001,
																position = 1
															})			
									
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case CommonRequestCheck.3.2
			
			-----------------------------------------------------------------------------------------
		
			--Begin Test case CommonRequestCheck.3.3
			--Description: Missing all parameter
				function Test:AddSubMenu_MissingAllParams()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{															
															})
										
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end	
			--End Test case CommonRequestCheck.3.3
			
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-4518
					
			--Verification criteria:
					--According to xml tests by Ford team all fake params should be ignored by SDL
			
			--Begin Test case CommonRequestCheck.4.1
			--Description: Parameter not from protocol					
			function Test:AddSubMenu_WithFakeParam()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 3001,
															position = 1,
															menuName = "SubMenufakeparam",
															fakeParam = "fakeParam"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 3001,
									menuParams = {
										position = 1,
										menuName = "SubMenufakeparam"
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
			--Begin Test case CommonRequestCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
			function Test:AddSubMenu_ParamsAnotherRequest()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
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
									
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
			--End Test case CommonRequestCheck.4.2
			
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-429

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:AddSubMenu_IncorrectJSON()
				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 7,
					rpcCorrelationId = self.mobileSession.correlationId,
					payload          = '{"menuID":3003,"position"=1, "menuName"="invalidJson"}}'
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
				function Test:AddSubMenu_correlationIdDuplicateValue()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 1005,
																position = 500,
																menuName ="SubMenupositive"
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = 1005,
										menuParams = {
											position = 500,
											menuName ="SubMenupositive"
										}
									},
									{ 
										menuID = 1006,
										menuParams = {
											position = 1,
											menuName ="SubMenu1006"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(2)
						
					--mobile side: expect AddSubMenu response
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
								payload          = '{"menuID":1006,"position"=1, "menuName"="SubMenu1006"}}'
							}
							self.mobileSession:Send(msg)
						end
					end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(2)
			end
		--End Test case CommonRequestCheck.6
]]
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
							-- SDLAQ-CRS-30,
							-- SDLAQ-CRS-428

				--Verification criteria: 
							-- AddSubMenu request adds a submenu to Commands Menu list on UI. Mandatory fields menuID and menuName are provided.
							-- Adding SubMenu to UI command menu is executed successfully. The SUCCESS response code is returned.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: lower bound of all parameters					
					function Test:AddSubMenu_LowerBound()	
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1,
																	position = 0,
																	menuName ="0"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 1,
											menuParams = {
												position = 0,
												menuName ="0"
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
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: upper bound of all parameters
					function Test:AddSubMenu_UpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 2000000000,
																	position = 1000,
																	menuName = string.rep("a",500)
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 2000000000,
											menuParams = {
												position = 1000,
												menuName = string.rep("a",500)
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
				--End Test case PositiveRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Description: DeleteSubMenu 1, 2000000000				
				local subMenuIdValues = {1, 2000000000}
				for i=1, #subMenuIdValues do
					Test["DeleteSubMenuWithId"..subMenuIdValues[i]] = function(self)						
						--mobile side: sending DeleteSubMenu request
						local cid = self.mobileSession:SendRPC("DeleteSubMenu",
																{
																	menuID = subMenuIdValues[i]
																})
						--hmi side: expect UI.DeleteSubMenu request
						EXPECT_HMICALL("UI.DeleteSubMenu", 
										{ 
											menuID = subMenuIdValues[i]							
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
				end
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: menuID lower bound
					function Test:AddSubMenu_menuIDLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1,
																	position = 1000,
																	menuName ="SubMenu"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 1,
											menuParams = {
												position = 1000,
												menuName ="SubMenu"
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
				--End Test case PositiveRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.4
				--Description: menuID positive and in bound
					function Test:AddSubMenu_menuIDInBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1000000000,
																	position = 1000,
																	menuName ="SubMenu1000000000"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 1000000000,
											menuParams = {
												position = 1000,
												menuName ="SubMenu1000000000"
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
				--End Test case PositiveRequestCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.5
				--Description: menuID upper bound
					function Test:AddSubMenu_menuIDUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 2000000000,
																	position = 1000,
																	menuName ="SubMenu2000000000"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 2000000000,
											menuParams = {
												position = 1000,
												menuName ="SubMenu2000000000"
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
				--End Test case PositiveRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.6
				--Description: Position - lower bound 
					function Test:AddSubMenu_PositionLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6004,
																	position = 0,
																	menuName ="SubMenu6004"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 6004,
											menuParams = {
												position = 0,
												menuName ="SubMenu6004"
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
				--End Test case PositiveRequestCheck.1.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.7
				--Description: Position - positive and in bound
					function Test:AddSubMenu_PositionInBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6007,
																	position = 501,
																	menuName ="SubMenu6007"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 6007,
											menuParams = {
												position = 501,
												menuName ="SubMenu6007"
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
				--End Test case PositiveRequestCheck.1.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.8
				--Description: Position - upper bound 	
					function Test:AddSubMenu_PositionUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6005,
																	position = 1000,
																	menuName ="SubMenu6005"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 6005,
											menuParams = {
												position = 1000,
												menuName ="SubMenu6005"
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
				--End Test case PositiveRequestCheck.1.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.9
				--Description: menuName - lower bound 
					function Test:AddSubMenu_menuNameLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7003,
																	position = 1000,
																	menuName ="L"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 7003,
											menuParams = {
												position = 1000,												
												menuName ="L"
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
				--End Test case PositiveRequestCheck.1.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.10
				--Description: menuName - in bound 
					function Test:AddSubMenu_menuNameInBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7004,
																	position = 1000,
																	menuName ="MenuName"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 7004,
											menuParams = {
												position = 1000,
												menuName ="MenuName"
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
				--End Test case PositiveRequestCheck.1.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.11
				--Description: menuName - upper bound 
					function Test:AddSubMenu_menuNameUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7005,
																	position = 1000,
																	menuName = string.rep("a",500)
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 7005,
											menuParams = {
												position = 1000,
												menuName = string.rep("a",500)
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
				--End Test case PositiveRequestCheck.1.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.12
				--Description: menuName with spaces before, after and in the middle
					function Test:AddSubMenu_menuNameSpaces()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7006,
																	position = 20,
																	menuName ="   SubMenu  with  spaces    "
																})
						
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 7006,
											menuParams = {
												position = 20,
												menuName ="   SubMenu  with  spaces    "
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
				--End Test case PositiveRequestCheck.1.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.13
				--Description: Position - already existed 
					function Test:AddSubMenu_PositionAlreadyExisted()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7007,
																	position = 20,
																	menuName ="SubMenu7007"
																})
						
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 7007,
											menuParams = {
												position = 20,
												menuName ="SubMenu7007"
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
				--End Test case PositiveRequestCheck.1.13
				
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
					--SDLAQ-CRS-29
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					
				--Begin PositiveResponseCheck.1.1
				--Description: info parameter lower bound					
					function Test: AddSubMenu_InfoLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1001,
																	position = 500,
																	menuName ="SubMenu1001"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 1001,
											menuParams = {
												position = 500,
												menuName ="SubMenu1001"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info="a"})
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info="a"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin PositiveResponseCheck.1.2
				--Description: info parameter upper bound 					
					function Test: AddSubMenu_InfoUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1002,
																	position = 500,
																	menuName ="SubMenu1002"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 1002,
											menuParams = {
												position = 500,
												menuName ="SubMenu1002"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMessage})
						end)
							
						--mobile side: expect AddSubMenu response
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
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: Check processing requests with out of lower and upper bound values 

			--Begin Test case NegativeRequestCheck.1
			--Description:

				--Requirement id in JAMA:
					--SDLAQ-CRS-429
					
				--Verification criteria:
					-- The request with "menuID" value out of bounds is sent, the response with INVALID_DATA result code is returned.
					-- The request with "position" value out of bounds is sent, the response with INVALID_DATA result code is returned.
					-- The request with "menuName" value out of boundsis sent, the response with INVALID_DATA result code is returned.					
								
				--Begin Test case NegativeRequestCheck.1.1
				--Description: menuID - out lower bound  				
					function Test:AddSubMenu_menuIDOutLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 0,
																	position = 1000,
																	menuName ="SubMenu"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end					
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.2
				--Description: menuID - out upper bound 
					function Test:AddSubMenu_menuIDOutUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 2000000001,
																	position = 1000,
																	menuName ="SubMenu"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.3
				--Description: Position - out lower bound
					function Test:AddSubMenu_PositionOutLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6003,
																	position = -1,
																	menuName ="SubMenu"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.4
				--Description: Position - out upper bound
					function Test:AddSubMenu_PositionOutUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6006,
																	position = 1001,
																	menuName ="SubMenu6006"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.5
				--Description: menuName - out upper bound 
					function Test:AddSubMenu_menuNameOutUpperBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7006,
																	position = 1000,
																	menuName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_=+|~{}[]:,01234567890asdfgg"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.1.5
				
			--End Test case NegativeRequestCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values
			
				--Requirement id in JAMA:
					--SDLAQ-CRS-429
					
				--Verification criteria:
					-- The request with empty "position" value is sent, the response with INVALID_DATA result code is returned. 
					-- The request with empty "menuName" is sent, the response with INVALID_DATA result code is returned. 
					-- The request with empty "menuID" is sent, the response with INVALID_DATA result code is returned. 
				
				--Begin Test case NegativeRequestCheck.2.1
				--Description: position empty
					-- Covered by invalid json check.
				--End Test case NegativeRequestCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.2
				--Description: menuName empty
					function Test:AddSubMenu_menuNameEmpty()
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

						local msg = 
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 7,
							rpcCorrelationId = self.mobileSession.correlationId,
							payload          = '{"menuID"=1003,"position"=500, "menuName"=""}}'
						}
						self.mobileSession:Send(msg)					
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.2.3
				--Description: menuName empty
					function Test:AddSubMenu_menuIdEmpty()
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

						local msg = 
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 7,
							rpcCorrelationId = self.mobileSession.correlationId,
							payload          = '{"menuID"=,"position"=500, "menuName"="SubMenu1004"}}'
						}
						self.mobileSession:Send(msg)					
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.2.3
				
			--End Test case NegativeRequestCheck.2
						
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: The code should be returned in case there was a conflict with an registered submenu name if a submenu with the same name has already been registered for this app

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-433

				--Verification criteria: 
							-- In case of adding a sub menu with menuName that is already registered for the current application, the response with DUPLICATE_NAME resultCode is sent.
							
				function Test:AddSubMenu_menuNameDuplicate()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 7008,
																position = 1000,
																menuName ="SubMenu"
															})
										
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false , resultCode = "DUPLICATE_NAME" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.3
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Provided menuID  is not valid (already exists)

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-432

				--Verification criteria: 
							-- In case of adding sub menu with "menuID" which is already registered for the current application, the response with INVALID_ID resultCode is sent.
							
				function Test:AddSubMenu_menuIDAlreadyExist()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 1000,
																position = 1000,
																menuName ="SubMenuInvalidID"
															})
											
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case PositiveRequestCheck.4
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-429
					
				--Verification criteria:
					-- The request with wrong data in "menuID" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					-- The request with wrong data in "position" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					-- The request with wrong data in "menuName" parameter (e.g. Integer data type) is sent, the response with INVALID_DATA result code is returned..
								
				--Begin Test case NegativeRequestCheck.5.1
				--Description: menuID Wrong Type
					function Test:AddSubMenu_menuIDWrongType()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = "123",
																	position = 1000,
																	menuName ="SubMenu"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.1
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.2
				--Description: Position Wrong Type
					function Test:AddSubMenu_PositionWrongType()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 6002,
																	position = "123",
																	menuName ="SubMenu6002"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.2
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.5.3
				--Description: menuName Wrong Type
					function Test:AddSubMenu_menuNameWrongType()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 7002,
																	position = 1000,
																	menuName = 123
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.3
				
			--End Test case NegativeRequestCheck.5
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.6
			--Description: Check processing request with Special characters

				--Jira ID:
					--APPLINK-8083
					
				--Verification criteria:
					--SDL must return INVALID_DATA success:false to mobile app IN CASE any of the above requests comes with '\n' and '\t'
				
				--Begin Test case NegativeRequestCheck.6.1
				--Description: Escape sequence \n in menuName
					function Test:AddSubMenu_menuNameNewLineChar()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1435,
																	position = 500,
																	menuName ="SubMenupositive\n"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.6.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.2
				--Description: Escape sequence \t in menuName
					function Test:AddSubMenu_menuNameTabChar()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1445,
																	position = 500,
																	menuName ="SubMenupositive\t"
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.6.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.3
				--Description: White space only in menuName
					function Test:AddSubMenu_menuNameWhiteSpaceOnly()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 1446,
																	position = 500,
																	menuName ="          "
																})
												
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.6.3
			--End Test case NegativeRequestCheck.6						
		--End Test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
--[[TODO update after resolving APPLINK-14765
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
					function Test: AddSubMenu_ResultCodeNotExist()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 101,
																	position = 500,
																	menuName ="SubMenu101"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 101,
											menuParams = {
												position = 500,
												menuName ="SubMenu101"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":111, "method":"UI.AddSubMenu"}}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test: AddSubMenu_MethodOutLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 102,
																	position = 500,
																	menuName ="SubMenu102"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 102,
											menuParams = {
												position = 500,
												menuName ="SubMenu102"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with empty string in resultCode
					function Test: AddSubMenu_ResultCodeOutLowerBound()
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 102,
																	position = 500,
																	menuName ="SubMenu102"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 102,
											menuParams = {
												position = 500,
												menuName ="SubMenu102"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
						
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
					--SDLAQ-CRS-29
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters				
					function Test: AddSubMenu_ResponseMissingAllPArameters()					
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 103,
																	position = 500,
																	menuName ="SubMenu103"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 103,
											menuParams = {
												position = 500,
												menuName ="SubMenu103"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter			
					function Test: AddSubMenu_MethodMissing()					
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 104,
																	position = 500,
																	menuName ="SubMenu104"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 104,
											menuParams = {
												position = 500,
												menuName ="SubMenu104"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter
					function Test: AddSubMenu_ResultCodeMissing()					
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 105,
																	position = 500,
																	menuName ="SubMenu105"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 105,
											menuParams = {
												position = 500,
												menuName ="SubMenu105"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddSubMenu"}}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.2.3
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check processing response without mandatory parameter
					function Test: AddSubMenu_AllMandatoryMissing()					
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 106,
																	position = 500,
																	menuName ="SubMenu106"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 106,
											menuParams = {
												position = 500,
												menuName ="SubMenu106"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
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
					function Test:AddSubMenu_MethodWrongtype() 
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 106,
																	position = 500,
																	menuName ="SubMenu106"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 106,
											menuParams = {
												position = 500,
												menuName ="SubMenu106"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", { })
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check processing response with wrong type of resultCode
					function Test:AddSubMenu_ResultCodeWrongtype() 
						--mobile side: sending AddSubMenu request
						local cid = self.mobileSession:SendRPC("AddSubMenu",
																{
																	menuID = 107,
																	position = 500,
																	menuName ="SubMenu107"
																})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 107,
											menuParams = {
												position = 500,
												menuName ="SubMenu107"
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddSubMenu response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddSubMenu", "code":true}}')
						end)
							
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
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
				function Test: AddSubMenu_ResponseInvalidJson()	
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 109,
																position = 500,
																menuName ="SubMenu109"
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = 109,
										menuParams = {
											position = 500,
											menuName ="SubMenu109"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddSubMenu response
						self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.AddSubMenu", "code":0}}')
					end)
						
					--mobile side: expect AddSubMenu response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end				
			--End Test case NegativeResponseCheck.4
			]]
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters
		--[[TODO: update after resolving APPLINK-14551
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-29, APPLINK-13276, APPLINK-14551
				--Verification criteria: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				
				--Begin Test Case NegativeResponseCheck5.1
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: AddSubMenu_InfoOutLowerBound()	
						local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 110,
																position = 500,
																menuName ="SubMenu110"
															})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 110,
											menuParams = {
												position = 500,
												menuName ="SubMenu110"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "SUCCESS", "")
						end)
							
						--mobile side: expect AddSubMenu response
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
					function Test: AddSubMenu_InfoOutUpperBound()						
						local infoOutUpperBound = infoMessage.."b"
						local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 111,
																position = 500,
																menuName ="SubMenu111"
															})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 111,
											menuParams = {
												position = 500,
												menuName ="SubMenu111"
											}
										})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response
							self.hmiConnection:SendError(data.id, data.method, "SUCCESS", infoOutUpperBound)
						end)
						
						--mobile side: expect AddSubMenu response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoUpperBound })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end
				--End Test Case NegativeResponseCheck5.2
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.3
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: AddSubMenu_InfoWrongType()												
						local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 112,
																position = 500,
																menuName ="SubMenu112"
															})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 112,
											menuParams = {
												position = 500,
												menuName ="SubMenu112"
											}
										})
						:Do(function(_,data)
							--hmi side: send Navigation.AddSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)
						
						--mobile side: expect AddSubMenu response
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
					function Test: AddSubMenu_InfoWithNewlineChar()						
						local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 113,
																position = 500,
																menuName ="SubMenu113"
															})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 113,
											menuParams = {
												position = 500,
												menuName ="SubMenu113"
											}
										})
						:Do(function(_,data)
							--hmi side: send Navigation.AddSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)
						
						--mobile side: expect AddSubMenu response
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
					function Test: AddSubMenu_InfoWithTabChar()						
						local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 114,
																position = 500,
																menuName ="SubMenu114"
															})
						--hmi side: expect UI.AddSubMenu request
						EXPECT_HMICALL("UI.AddSubMenu", 
										{ 
											menuID = 114,
											menuParams = {
												position = 500,
												menuName ="SubMenu114"
											}
										})
						:Do(function(_,data)
							--hmi side: send Navigation.AddSubMenu response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)
						
						--mobile side: expect AddSubMenu response
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
				--SDLAQ-CRS-429
				--SDLAQ-CRS-430
				--SDLAQ-CRS-435
				--SDLAQ-CRS-436

			--Verification criteria:
				-- The request AddSubMenu is sent under conditions of RAM definite for executing it. The response code OUT_OF_MEMORY is returned. 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
				
			local resultCodes = {{code = "INVALID_DATA", name = "InvalidData"}, {code = "OUT_OF_MEMORY", name = "OutOfMemory"}, {code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}}
			for i=1,#resultCodes do
				Test["AddSubMenu_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = tonumber("33"..tostring(i)),																
																menuName ="SubMenu33"..tostring(i)
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = tonumber("33"..tostring(i)),	
										menuParams = {
											menuName ="SubMenu33"..tostring(i)
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddSubMenu response
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
		--Description: Limit of position items in UI list is exhausted (should be managed by HMI)

			--Requirement id in JAMA:
				--SDLAQ-CRS-435

			--Verification criteria:
				--In case the limit of position items in UI list is exhausted while adding sub menu to Command Menu, HMi rejects the request with the resultCode REJECTED.
			
				
			--Description: Add 1000 SubMenu
			for i=7111,8111 do
				Test["AddSubMenuWithId"..tostring(i)] = function(self)
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = i,
																position = 500,
																menuName ="SubMenu"..tostring(i)
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = i,
										menuParams = {
											position = 500,
											menuName ="SubMenu"..tostring(i)
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
			end
	
			function Test:AddSubMenu_REJECTED()				
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 222,
															position = 500,
															menuName ="SubMenu222"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 222,
									menuParams = {
										position = 500,
										menuName ="SubMenu222"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)
					
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
					
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
				
		--End Test case ResultCodeCheck.2
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.3
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-434

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Unregistered application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			--Description: Send AddSubMenu when application not registered yet.
			function Test:AddSubMenu_AppNotRegistered()
				--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 223,
																position = 500,
																menuName ="SubMenu223"
															})

				--mobile side: expect DeleteCommand response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end			
		--End Test case ResultCodeCheck.3	
		
		----------------------------------------------------------------------------------------- 
		
		--Begin Test case ResultCodeCheck.4
		--Description: Policies manager must validate an RPC request as "disallowed" if it is not allowed by the backend.

			--Requirement id in JAMA:
				--SDLAQ-CRS-2396

			--Verification criteria:
				--An RPC request is not allowed by the backend. Policies Manager validates it as "disallowed".
			
			commonSteps:RegisterAppInterface("RegisterAppInterface1")
			commonSteps:RegisterAppInterface("RegisterAppInterface_WorkAround")
			
			--Description: Send AddSubMenu when HMI leve is NONE
			function Test:AddSubMenu_DisallowedHMINone()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 201,
															position = 50,
															menuName ="SubMenu201"
														})
										
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				
				commonTestCases:DelayedExp(2000)
			end			
		--End Test case ResultCodeCheck.4
		
		----------------------------------------------------------------------------------------- 
	
		--Begin Test case ResultCodeCheck.5
		--Description: Policies Manager must validate an RPC request as "userDisallowed" if the request is allowed by the backend but disallowed by the use

			--Requirement id in JAMA:
				--SDLAQ-CRS-2394

			--Verification criteria:
				--An RPC request is allowed by the backend but disallowed by the user. Policy Manager validates it as "userDisallowed"
			
			--Description: Activate application
			commonSteps:ActivationApp()
			
			--Check AddSubMenu is Disallowed when it is not in PT
			policyTable:checkPolicyWhenAPIIsNotExist()
			
			--Check AddSubMenu is DISALLOWED/USER_DISALLOWED when it is in PT and it has not been allowed yet/user disallows. 
			policyTable:checkPolicyWhenUserDisallowed({"FULL", "LIMITED", "BACKGROUND"})
			
		--End Test case ResultCodeCheck.5

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
				--SDLAQ-CRS-436
				--APPLINK-8585
				
			--Verification criteria:				
				-- no UI response during SDL`s watchdog.
			
			function Test:AddSubMenu_NoResponseFromUI()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 204,
															position = 500,
															menuName ="SubMenu204"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 204,
									menuParams = {
										position = 500,
										menuName ="SubMenu204"
									}
								})
				
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
						
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-29
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.		
				
			function Test: AddSubMenu_ResponseInvalidStructure()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 205,
															position = 500,
															menuName ="SubMenu205"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 205,
									menuParams = {
										position = 500,
										menuName ="SubMenu205"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:Send('{"error":{"code":4,"message":"AddSubMenu is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.AddSubMenu"}}')	
				end)
					
				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
				:Timeout(12000)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end						
		--End Test case HMINegativeCheck.2
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-29
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:AddSubMenu_SeveralResponseToOneRequest()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 206,
															position = 500,
															menuName ="SubMenu206"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 206,
									menuParams = {
										position = 500,
										menuName ="SubMenu206"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end)
					
				--mobile side: expect AddSubMenu response
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
				--SDLAQ-CRS-29
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:AddSubMenu_FakeParamsInResponse()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 207,
																position = 500,
																menuName ="SubMenu207"
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = 207,
										menuParams = {
											position = 500,
											menuName ="SubMenu207"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
					end)
						
					--mobile side: expect AddSubMenu response
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
				function Test:AddSubMenu_ParamsFromOtherAPIInResponse()
					--mobile side: sending AddSubMenu request
					local cid = self.mobileSession:SendRPC("AddSubMenu",
															{
																menuID = 208,
																position = 500,
																menuName ="SubMenu208"
															})
					--hmi side: expect UI.AddSubMenu request
					EXPECT_HMICALL("UI.AddSubMenu", 
									{ 
										menuID = 208,
										menuParams = {
											position = 500,
											menuName ="SubMenu208"
										}
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)
						
					--mobile side: expect AddSubMenu response
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
				--SDLAQ-CRS-29
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			function Test:AddSubMenu_WrongResponseToCorrectID()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 212,
															position = 500,
															menuName ="SubMenu212"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 212,
									menuParams = {
										position = 500,
										menuName ="SubMenu212"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})						
				end)
					
				--mobile side: expect AddSubMenu response
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
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	
		--Begin Test case SequenceCheck.1
		--Description: 
				--Execution of command in submenu
				
			--Requirement id in JAMA: 				

			--Verification criteria:
					--Adding "SubMenu500" to Options Menu
					--Create Command1 and assign it to SubMenu500
					--Execution Command1 via HMI UI
			
			function Test:AddSubMenu_SubMenu500()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 500,
															position = 500,
															menuName ="SubMenu500"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu", 
								{ 
									menuID = 500,
									menuParams = {
										position = 500,
										menuName ="SubMenu500"
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
			
			function Test:AddCommand_Command1()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 1,
																menuParams = 	
																{ 
																	parentID = 500,
																	position = 0,
																	menuName ="TestCommand1"
																}, 
																vrCommands = 
																{ 
																	"Test Command 1"
																}
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 1,
										menuParams = 	
										{ 
											parentID = 500,
											position = 0,
											menuName ="TestCommand1"
										},
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 1,
										vrCommands = 
										{ 
											"Test Command 1"
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
		
			function Test:AddSubMenu_ExecutionCommandInSubmenu()
				--hmi side: sending UI.OnSystemContext notification 
				SendOnSystemContext(self,"MENU")	
				
				--hmi side: sending UI.OnCommand notification			
				self.hmiConnection:SendNotification("UI.OnCommand",
				{
					cmdID = 1,
					appID = self.applications["Test Application"]
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
				
				--mobile side: expect OnCommand notification 
				EXPECT_NOTIFICATION("OnCommand", {cmdID = 1, triggerSource= "MENU"})		
			end
		--End Test case SequenceCheck.1
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
				--SDLAQ-CRS-766
			--Verification criteria: 
				--SDL doesn't reject AddSubMenu request when current HMI is FULL.
				--SDL doesn't reject AddSubMenu request when current HMI is LIMITED.
				--SDL doesn't reject AddSubMenu request when current HMI is BACKGROUND.
		
		--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
		commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")	
		
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()

return Test	