Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')


---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
APIName = "ReadDID" -- use for above required scripts.
local infoMessageValue = string.rep("a",1000)


--Description: Update policy from specific file
	--policyFileName: Name of policy file
	--bAllowed: true if want to allowed New group policy
	--          false if want to disallowed New group policy
	local idGroup
function Test:policyUpdate(policyFileName, bAllowed)
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
			"files/"..policyFileName)
			
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
					EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = "New"}}}})
					:Do(function(_,data)
						--print("SDL.GetListOfPermissions response is received")

						idGroup = data.result.allowedFunctions[1].id
						
						--hmi side: sending SDL.OnAppPermissionConsent
						self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = bAllowed, id = idGroup, name = "New"}}, source = "GUI"})
						end)
				end)
			end)
			
		end)
	end)
end
function setReadDIDRequest()
	return { 
			ecuName = 2000,
			didLocation = 
			{ 
				56832
			}
		} 
end
function setReadDIDResponse(didLocationValues, vehicleDataResultCodeValues, dataValues)
	local temp = {didResult = {}}
	
	for i = 1, #didLocationValues do		
		temp.didResult[i] = {					
				resultCode = vehicleDataResultCodeValues[i], 
				didLocation = didLocationValues[i],
				data = dataValues[i]
			}		
	end	
	return temp
end
function setReadDIDSuccessResponse(didLocationValues)
	local temp = {didResult = {}}
	
	for i = 1, #didLocationValues do		
		temp.didResult[i] = {					
				resultCode = "SUCCESS", 
				didLocation = didLocationValues[i],
				data = "123"
			}		
	end	
	return temp
end
function setReadDIDDefaultResponse()
	local temp = {}
	temp = {
				didResult =	{{				
					resultCode = "SUCCESS", 
					didLocation = 56832,
					data = "123"
				}}
			}
	return temp
end
function createSuccessExpectedResult(response)
	local tmp = commonFunctions:cloneTable(response)
	tmp["success"] = true
	tmp["resultCode"] = "SUCCESS"
	
	return tmp
end
function createExpectedResult(bSuccess, sResultCode, infoMessage, response)
	local tmp = commonFunctions:cloneTable(response)
	tmp["success"] = bSuccess
	tmp["resultCode"] = sResultCode
	
	return tmp
end
function Test:readDIDSuccess(paramsSend, infoMessage)	
	local response = setReadDIDSuccessResponse(paramsSend.didLocation)
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	--mobile side: sending ReadDID request
	local cid = self.mobileSession:SendRPC("ReadDID",paramsSend)
	
	--hmi side: expect ReadDID request
	EXPECT_HMICALL("VehicleInfo.ReadDID",paramsSend)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.ReadDID response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	
	local expectedResult = createSuccessExpectedResult(response)
	
	--mobile side: expect ReadDID response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--commonTestCases:DelayedExp(1000)
end
function Test:readDIDResponseSuccess(response)	
	--mobile side: sending ReadDID request
	local cid = self.mobileSession:SendRPC("ReadDID",setReadDIDRequest())
	
	--hmi side: expect ReadDID request
	EXPECT_HMICALL("VehicleInfo.ReadDID",setReadDIDRequest())
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.ReadDID response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	if response.didResult[1] and 
		response.didResult[1].resultCode == nil and
		response.didResult[1].didLocation == nil and
		response.didResult[1].data == nil then
		response.didResult = nil
	end
	
	local expectedResult = createSuccessExpectedResult(response)
	
	--mobile side: expect ReadDID response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--commonTestCases:DelayedExp(1000)
end
function Test:readDIDInvalidData(paramsSend)
	--mobile side: sending ReadDID request
	local cid = self.mobileSession:SendRPC("ReadDID",paramsSend)
	
	--mobile side: expected ReadDID response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()

	--Begin Precondition.2
	--Description: Update Policy with OnKeyboardInputOnlyGroup
	
	--4. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})
	
	function Test_Precondition_PolicyUpdate()
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
				"files/ptu_general.json")
				
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
					-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
					:Do(function(_,data)
						print("SDL.GetUserFriendlyMessage is received")			
					end)
				end)
				
			end)
		end)
	end
	--End Precondition.2

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
    	--Description: This test is intended to check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-101, SDLAQ-CRS-619

			--Verification criteria: 
				--ReadDID request sends exact ECU (electronic control unit) name and didLocation for receiving ECU data for the known DID (data identifiers) from addressed memory locations of the ECU on IVI. The response with resultCode for requested DID, location and corresponding values for every requested location is returned.
				--ReadDID request provides valid ECU name and didLocations. DID data is received for all requested locatons, VehicleDataResultCode values for all DIDs are "SUCCESS". General request resultCode is "SUCCESS", parameter success=true.
			function Test:ReadDID_Positive() 				
				self:readDIDSuccess(setReadDIDRequest())				
			end
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters
			
			-- Covered by CommonRequestCheck.1
			
		--End Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-620

			--Verification criteria: 
				--The request without "ecuName" is sent, the response with INVALID_DATA result code is returned.
				--The request without "didLocation" is sent, the response with INVALID_DATA result code is returned.
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: Mandatory missing - ecuName 
				function Test:ReadDID_MissingEcuName()
					local request = setReadDIDRequest()
					request.ecuName = nil
					self:readDIDInvalidData(request)				
				end
			--End Test case CommonRequestCheck.3.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.2
			--Description: Mandatory missing - didLocation 
				function Test:ReadDID_MissingDidLocation()
					local request = setReadDIDRequest()
					request.didLocation = nil
					self:readDIDInvalidData(request)				
				end
			--End Test case CommonRequestCheck.3.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.3.3
			--Description: All parameters are missing
				function Test:ReadDID_AllParamsMissing()					
					self:readDIDInvalidData({})				
				end
			--End Test case CommonRequestCheck.3.3
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-14776

			--Verification criteria: 
				--In case HMI sends response/request/notification with fake parameters that SDL should transfer to mobile app -> SDL must:cut off fake parameters -> message is valid -> transfer it to mobile app
				--In case HMI sends response/request/notification with fake parameters that SDL should use internally -> SDL must:cut off fake parameters -> message is valid -> process message

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters				
				function Test:ReadDID_FakeParams()										
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,
																		fakeParam ="fakeParam",
																		didLocation = 
																		{ 
																			25535,
																		}, 
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,															
															didLocation = 
															{ 
																25535,
															}, 
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					
					commonTestCases:DelayedExp(1000)
				end
			--End Test case CommonRequestCheck4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:ReadDID_ParamsAnotherRequest()
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,																		
																		didLocation = 
																		{ 
																			25535
																		},
																		ttsChunks = 
																		{	
																			{ 
																				text ="SpeakFirst",
																				type ="TEXT",
																			}
																		}
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,
															didLocation = 
															{ 
																25535,
															}
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then							
							print(" \27[36m SDL re-sends ttsChunks parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					
					commonTestCases:DelayedExp(1000)
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-620

			--Verification criteria:  The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:ReadDID_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 23,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"ecuName" 2000,"didLocation":[56832]}'
				  }
				  
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
--TODO: Requirement and Verification criteria need to be updated.
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with duplicate correlationID value

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-619

			--Verification criteria: 
				--ReadDID request provides valid ECU name and didLocations. DID data is received for all requested locatons, VehicleDataResultCode values for all DIDs are "SUCCESS". General request resultCode is "SUCCESS", parameter success=true.
			function Test:ReadDID_correlationIdDuplicateValue()
				--mobile side: send ReadDID request 
				local CorIdReadDID = self.mobileSession:SendRPC("ReadDID", setReadDIDRequest())
				
				local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 23,
					rpcCorrelationId = CorIdReadDID,				
					payload          = '{"ecuName":2000,"didLocation":[25535]}'
				  }
				
				--hmi side: expect ReadDID request
				EXPECT_HMICALL("VehicleInfo.ReadDID",
					{
						ecuName = 2000,
						didLocation = 
						{ 
							56832,
						}
					},
					{
						ecuName = 2000,
						didLocation = 
						{ 
							25535,
						}
					}
				)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
						
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}})
					else
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {didResult = {{data = "456", didLocation = 25535, resultCode = "SUCCESS"}}})
					end				
				end)
				:Times(2)
								
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(CorIdReadDID, 
					{success = true, resultCode = "SUCCESS", didResult = {{data = "123", didLocation = 56832, resultCode = "SUCCESS"}}},
					{success = true, resultCode = "SUCCESS", didResult = {{data = "456", didLocation = 25535, resultCode = "SUCCESS"}}})       
				:Times(2)
				
				commonTestCases:DelayedExp(1000)
			end
		--End Test case CommonRequestCheck.6
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
					-- SDLAQ-CRS-101,
					-- SDLAQ-CRS-619
				
				--Verification criteria: 
					--ReadDID request sends exact ECU (electronic control unit) name and didLocation for receiving ECU data for the known DID (data identifiers) from addressed memory locations of the ECU on IVI. The response with resultCode for requested DID, location and corresponding values for every requested location is returned.
					--ReadDID request provides valid ECU name and didLocations. DID data is received for all requested locations, VehicleDataResultCode values for all DIDs are "SUCCESS". General request resultCode is "SUCCESS", parameter success=true.
					
				--Begin Test case PositiveRequestCheck.1.1
				--Description: ecuName: value lower bound
					function Test:ReadDID_ecuNameLowerBound()
						local request = setReadDIDRequest()
						request.ecuName = 0
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case PositiveRequestCheck.1.2
				--Description: ecuName: value upper bound
					function Test:ReadDID_ecuNameUpperBound()
						local request = setReadDIDRequest()
						request.ecuName = 65535
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: didLocation: array lower bound
					-- Covered by ReadDID_Positive
				--End Test case PositiveRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case PositiveRequestCheck.1.4
				--Description: didLocation: array upper bound
					function Test:ReadDID_didLocationArrayUpperBound()
						--Create upper bound didLocation
						local temp = {}
						for i = 1, 1000 do
							temp[i] = i
						end
						
						--Send ReadDID request
						local request = setReadDIDRequest()
						request.didLocation = temp
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.4				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: didLocation: value lower bound
					function Test:ReadDID_didLocationLowerBound()						
						local request = setReadDIDRequest()
						request.didLocation = {0}
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: didLocation: value upper bound
					function Test:ReadDID_didLocationUpperBound()						
						local request = setReadDIDRequest()
						request.didLocation = {65535}
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: lower bound all parameter
					function Test:ReadDID_LowerBound()												
						local request = {
											ecuName = 0,
											didLocation = 
											{ 
												0,
											}
										}							
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: upper bound all parameter
					function Test:ReadDID_UpperBound()						
						--Create upper bound didLocation
						local temp = {}
						for i = 1, 1000 do
							temp[i] = 65535-i
						end
						
						--Send ReadDID request
						local request = {
											ecuName = 65535,
											didLocation = temp
										}							
						self:readDIDSuccess(request)				
					end
				--End Test case PositiveRequestCheck.1.8						
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
					--SDLAQ-CRS-102
					--SDLAQ-CRS-1049
					--SDLAQ-CRS-1050
					--SDLAQ-CRS-625
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned.  	
					-- ReadDID requests the data which value exceeds platform maximum. VehicleData component returned only a part of the data in a response, resultCode is "TRUNCATED_DATA". General result parameter success=true.
					
				--Begin Test case PositiveResponseCheck.1.1
				--Description: Response with info parameter lower bound
					function Test: ReadDID_Response_InfoLowerBound()						
						self:readDIDSuccess(setReadDIDRequest(), "a")
					end					
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description:  Response with info parameter upper bound
					function Test: ReadDID_Response_InfoUpperBound()						
						self:readDIDSuccess(setReadDIDRequest(), string.rep("a",1000))						
					end
				--End Test case PositiveResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.3
				--Description:  Response with didLocation lower bound
					function Test: ReadDID_Response_didLocationLowerBound()
						local response = setReadDIDDefaultResponse()
						response.didResult[1].didLocation = 0						
						self:readDIDResponseSuccess(response)						
					end
				--End Test case PositiveResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.4
				--Description:  Response with didLocation upper bound
					function Test: ReadDID_Response_didLocationUpperBound()
						local response = setReadDIDDefaultResponse()
						response.didResult[1].didLocation = 65535
						self:readDIDResponseSuccess(response)						
					end
				--End Test case PositiveResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.5
				--Description:  Response with all possible of VehicleDataResultCode of DIDResult parameter
					local vehicleDataResultCodeValues = {"SUCCESS", "TRUNCATED_DATA", "DISALLOWED", "USER_DISALLOWED", "INVALID_ID", "VEHICLE_DATA_NOT_AVAILABLE", "DATA_ALREADY_SUBSCRIBED", "DATA_NOT_SUBSCRIBED", "IGNORED"}
					for i=1, #vehicleDataResultCodeValues do
						Test["ReadDID_Response_DIDResult_ResultCode_"..vehicleDataResultCodeValues[i]] = function(self)
							local response = setReadDIDDefaultResponse()
							response.didResult[1].resultCode = vehicleDataResultCodeValues[i]
							self:readDIDResponseSuccess(response)
							commonTestCases:DelayedExp(1000)
						end
					end
				--End Test case PositiveResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.6
				--Description:  Response with data value lower bound
					function Test: ReadDID_Response_dataLowerBound()						
						local response = setReadDIDDefaultResponse()
						response.didResult[1].data = "a"
						self:readDIDResponseSuccess(response)						
					end
				--End Test case PositiveResponseCheck.1.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.7
				--Description:  Response with data value upper bound
					function Test: ReadDID_Response_dataUpperBound()						
						local response = setReadDIDDefaultResponse()
						response.didResult[1].data = string.rep("a", 5000)						
						self:readDIDResponseSuccess(response)						
					end
				--End Test case PositiveResponseCheck.1.7	
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.8
				--Description: didResult: array lower bound
					function Test:ReadDID_didResultArrayLowerBound()						
						--Create upper bound didLocation
						local tmp = {didResult ={{}}}
						
						self:readDIDResponseSuccess(tmp)				
					end
				--End Test case PositiveResponseCheck.1.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.9
				--Description: didResult: array upper bound
					function Test:ReadDID_didResultArrayUpperBound()						
						--Create upper bound didLocation
						local tmp = {didResult ={}}
						
						for i =1,1000 do						
							tmp.didResult[i] = {				
								resultCode = "SUCCESS", 
								didLocation = i,
								data = tostring(i)
							}
						end
						self:readDIDResponseSuccess(tmp)				
					end
				--End Test case PositiveResponseCheck.1.9
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
				--Requirement id in JAMA:
					--SDLAQ-CRS-101
					--SDLAQ-CRS-620
					
				--Verification criteria:
					-- The request with out of bound "ecuName" value is sent, the response with INVALID_DATA result code is returned.
					-- The request with out of bound "didLocation" value is sent, the response with INVALID_DATA result code is returned.
					-- The request with out of bound "didLocation" array value is sent, the response with INVALID_DATA result code is returned.
					
				--Begin Test case NegativeRequestCheck.1.1
				--Description: ecuName: value out lower bound
					function Test:ReadDID_ecuNameOutLowerBound()
						local request = setReadDIDRequest()
						request.ecuName = -1
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case NegativeRequestCheck.1.2
				--Description: ecuName: value out upper bound
					function Test:ReadDID_ecuNameOutUpperBound()
						local request = setReadDIDRequest()
						request.ecuName = 65536
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: didLocation: array out lower bound
					function Test:ReadDID_didLocationArrayOutLowerBound()
						local request = setReadDIDRequest()
						request.didLocation = {}
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.3
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case NegativeRequestCheck.1.4
				--Description: didLocation: array out of upper bound
					function Test:ReadDID_didLocationArrayOutUpperBound()
						--Create upper bound didLocation
						local temp = {}
						for i = 1, 1001 do
							temp[i] = i
						end
						
						--Send ReadDID request
						local request = setReadDIDRequest()
						request.didLocation = temp
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.4				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: didLocation: value out lower bound
					function Test:ReadDID_didLocationOutLowerBound()						
						local request = setReadDIDRequest()
						request.didLocation = -1
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.6
				--Description: didLocation: value out upper bound
					function Test:ReadDID_didLocationOutUpperBound()						
						local request = setReadDIDRequest()
						request.didLocation = 65536
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.1.6								
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-620

				--Verification criteria: 
					-- The request with empty "ecuName" value is sent, the response with INVALID_DATA result code is returned.
					-- The request with empty "didLocation" array element is sent, the response with INVALID_DATA result code is returned.
				
				--Covered by ReadDID_InvalidJSON
									
			--End Test case NegativeRequestCheck.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-620

				--Verification criteria: 
					-- The request with wrong data in "ecuName" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					-- The request with wrong data in "didLocation" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned
				
				--Begin Test case NegativeRequestCheck.3.1
				--Description: ecuName: value wrong type
					function Test:ReadDID_ecuNameWrongType()						
						local request = setReadDIDRequest()
						request.ecuName = "2000"
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.3.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: didLocation: value wrong type
					function Test:ReadDID_didLocationWrongType()						
						local request = setReadDIDRequest()
						request.didLocation = {"25535"}
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.3.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.3
				--Description: didLocation: array wrong type
					function Test:ReadDID_didLocationArrayWrongType()						
						local request = setReadDIDRequest()
						request.didLocation = "25535"
						self:readDIDInvalidData(request)				
					end
				--End Test case NegativeRequestCheck.3.3				
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				-- Not applicable
			
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with value not existed
			
				-- Not applicable
				
			--End Test case NegativeRequestCheck.5			
		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-102
					--APPLINK-14765
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned. 					
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
					
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check response with nonexistent resultCode 
					function Test: ReadDID_ResponseResultCodeNotExist()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check response with nonexistent didResult resultCode parameter 
					function Test: ReadDID_ResponseDidResultCodeNotExist()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																								didResult =	{{				
																									resultCode = "ANY", 
																									didLocation = 56832,
																									data = "123"
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check response out lower bound of didLocation
					function Test: ReadDID_ResponseDidLocationOutLowerBound()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																								didResult =	{{				
																									resultCode = "SUCCESS", 
																									didLocation = -1,
																									data = "123"
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check response out upper bound of didLocation
					function Test: ReadDID_ResponseDidLocationOutUpperBound()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																								didResult =	{{				
																									resultCode = "SUCCESS", 
																									didLocation = 65536,
																									data = "123"
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check response out lower bound of data
					function Test: ReadDID_ResponseDataOutLowerBound()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																								didResult =	{{				
																									resultCode = "SUCCESS", 
																									didLocation = 25535,
																									data = ""
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.6
				--Description: Check response out upper bound of data
					function Test: ReadDID_ResponseDataOutUpperBound()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																								didResult =	{{				
																									resultCode = "SUCCESS", 
																									didLocation = 25535,
																									data = string.rep("a", 5001)
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.7
				--Description: didResult: array out upper bound
					function Test:ReadDID_didResultArrayOutUpperBound()						
						--Create upper bound didLocation
						local tmp = {didResult ={}}
						
						for i =1,1001 do						
							tmp.didResult[i] = {				
								resultCode = "SUCCESS", 
								didLocation = i,
								data = tostring(i)
							}
						end
												
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", tmp)	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.7
			--End Test case NegativeResponseCheck.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses with invalid values (empty, missing, nonexistent, invalid characters)

				--Requirement id in JAMA:
					--SDLAQ-CRS-102
					--APPLINK-14765
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned. 
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
					
				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check response with empty method
					function Test: ReadDID_ResponseEmptyMethod()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {
																								didResult =	{{				
																									resultCode = "SUCCESS", 
																									didLocation = 25535,
																									data = "123"
																								}}
																							})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check response with empty resultCode
					function Test: ReadDID_ResponseEmptyResultCode()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.2	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check response with empty didResult resultCode
					function Test: ReadDID_ResponseEmptyDidResultCode()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																						didResult =	{{				
																							resultCode = "", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.4
				--Description: Check response with empty data
					function Test: ReadDID_ResponseEmptyData()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = ""
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})				
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.5
				--Description: Check response missing all parameter
					function Test: ReadDID_ResponseMissingAllParams()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send({})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.6
				--Description: Check response without method
					function Test: ReadDID_ResponseMissingMethod()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}]}')							
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})						
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.7
				--Description: Check response without resultCode
					function Test: ReadDID_ResponseMissingResultCode()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}],"method":"VehicleInfo.ReadDID"}}')
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})							
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.8
				--Description: Check response without didResult ResultCode
					function Test: ReadDID_ResponseMissingDidResultCode()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{
																						didResult =	{{																							
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.9
				--Description: Check response without didLocation
					function Test: ReadDID_ResponseMissingDidLocation()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{
																						didResult =	{{				
																							resultCode = "SUCCESS", 																							
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})		
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.9				
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.10
				--Description: Check response without data
					function Test: ReadDID_ResponseMissingData()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{
																						didResult =	{{				
																							resultCode = "SUCCESS", 																							
																							didLocation = 25535,
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																							resultCode = "SUCCESS", 																							
																							didLocation = 25535,
																						}}})
																						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.10			
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.11
				--Description: Check response without mandatory parameter
					function Test: ReadDID_ResponseMissingMandatory()					
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')						
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.11
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-102					
					--APPLINK-14765
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned. 
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
					
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check response with wrong type of method
					function Test:ReadDID_ResponseWrongTypeMethod() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, 1234,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check response with wrong type of resultCode
					function Test:ReadDID_ResponseWrongTypeResultCode() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method, 1234, {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check response with wrong type of didResult
					function Test:ReadDID_ResponseWrongTypeDidResult() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	1234
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check response with wrong type of didResult ResultCode
					function Test:ReadDID_ResponseWrongTypeDidResultCode() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = 1234, 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check response with wrong type of didLocation
					function Test:ReadDID_ResponseWrongTypeDidLocation() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = "1234",
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.6
				--Description: Check response with wrong type of data
					function Test:ReadDID_ResponseWrongTypeData() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = 123
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.6	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.7
				--Description: Check response with wrong type of didResult
					function Test:ReadDID_ResponseWrongTypeDidResult() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	"1234"
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end				
				--End Test case NegativeResponseCheck.3.7			
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-102					
					--APPLINK-14765
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned. 
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app	
					function Test: ReadDID_ResponseInvalidJson()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
								ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code" 0,"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}],"method":"VehicleInfo.ReadDID"}}')
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})										
						
						commonTestCases:DelayedExp(1000)
					end				
				
			--End Test case NegativeResponseCheck.4
--]]			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-102					
					--APPLINK-14551
					--APPLINK-14765
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
					
				--Begin Test Case NegativeResponseCheck5.1
				--Description: Check response with empty info
					function Test: ReadDID_ResponseInfoOutLowerBound()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = "",
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						commonTestCases:DelayedExp(1000)
					end					
				--End Test Case NegativeResponseCheck5.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck5.2
				--Description: Check response with info out upper bound
					function Test: ReadDID_ResponseInfoOutUpperBound()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = infoMessageValue.."a",
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", info = infoMessageValue, didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}})
																						
						commonTestCases:DelayedExp(1000)													
					end					
				--End Test Case NegativeResponseCheck5.2
						
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.3
				--Description: Check response with wrong type info
					function Test: ReadDID_ResponseInfoWrongType()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = 1234,
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						commonTestCases:DelayedExp(1000)
					end					
				--End Test Case NegativeResponseCheck5.3
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.4
				--Description: Check response with info have escape sequence \n 
					function Test: ReadDID_ResponseInfoNewLineChar()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = "New line \n",
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						commonTestCases:DelayedExp(1000)
					end					
				--End Test Case NegativeResponseCheck5.4
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.5
				--Description: Check response with info have escape sequence \t
					function Test: ReadDID_ResponseInfoNewTabChar()	
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
							{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = "New line \t",
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						commonTestCases:DelayedExp(1000)
					end					
				--End Test Case NegativeResponseCheck5.5								
			--End Test case NegativeResponseCheck.5
			
			-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test case NegativeResponseCheck.6
			--Description: Check processing response with parameters with special characters

				--Requirement id in JAMA:								
					--APPLINK-14765
					
				--Verification criteria:
					-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app 
					
				--Begin Test case NegativeResponseCheck.6.1
				--Description: Check response with escape sequence \n in data parameter
					function Test:ReadDID_Response_DataNewLineChar() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123\n"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.6.1
				
				-----------------------------------------------------------------------------------------
									
				--Begin Test case NegativeResponseCheck.6.2
				--Description: Check response with escape sequence \t in data parameter
					function Test:ReadDID_Response_DataNewTabChar() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123\t"
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.6.2
				
				-----------------------------------------------------------------------------------------
													
				--Begin Test case NegativeResponseCheck.6.3
				--Description: Check response with white space only in data parameter
					function Test:ReadDID_Response_DataWhiteSpacesOnly() 
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "    "
																						}}
																					})	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.6.3				
			--End Test case NegativeResponseCheck.6
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.7
			--Description: Check processing response with correlationID

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
			
				--Begin Test case NegativeResponseCheck.7.1
				--Description: CorrelationID is missing
					function Test:ReadDID_Response_CorrelationIDMissing()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send('{"jsonrpc":"2.0","code":0,"result":{"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}], "method":"VehicleInfo.ReadDID"}')	
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.7.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.7.2
				--Description: CorrelationID is wrong type
					function Test:ReadDID_Response_CorrelationIDWrongType()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(tostring(data.id), data.method,"SUCCESS", {didResult =	{{				
																					resultCode = "SUCCESS", 
																					didLocation = 25535,
																					data = "123"
																				}}
																			})
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.7.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.7.3
				--Description: CorrelationID is not existed
					function Test:ReadDID_Response_CorrelationIDNotExisted()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(5555, data.method,"SUCCESS", {didResult =	{{				
																					resultCode = "SUCCESS", 
																					didLocation = 25535,
																					data = "123"
																				}}
																			})
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.7.3	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.7.4
				--Description: CorrelationID is negative
					function Test:ReadDID_Response_CorrelationIDNegative()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:SendResponse(-1, data.method,"SUCCESS", {didResult =	{{				
																					resultCode = "SUCCESS", 
																					didLocation = 25535,
																					data = "123"
																				}}
																			})
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.7.4
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test case NegativeResponseCheck.7.5
				--Description: CorrelationID is null
					function Test:ReadDID_Response_CorrelationIDNull()
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",
																		{
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}, 
																		})
						
						--hmi side: expect ReadDID request
						EXPECT_HMICALL("VehicleInfo.ReadDID",{
																ecuName = 2000,															
																didLocation = 
																{ 
																	25535,
																}, 
															})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.ReadDID response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"VehicleInfo.ReadDID"}}')							
						end)
						
						--mobile side: expect ReadDID response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						commonTestCases:DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.7.5				
			--End Test case NegativeResponseCheck.7
--]]
		--End Test suit NegativeResponseCheck

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- check all pairs resultCode+success
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
		--Description: Check OUT_OF_MEMORY result code

			--Requirement id in JAMA: SDLAQ-CRS-621

			--Verification criteria: 
				--A request ReadDID is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned. 
			
			--Not applicable
			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: Check of TOO_MANY_PENDING_REQUESTS result code

			--Requirement id in JAMA: SDLAQ-CRS-622

			--Verification criteria: 
				--The system has more than N requests  at a time that haven't been responded yet.
				--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than N requests at a time that haven't been responded by the system yet.
			
			--Moved to ATF_ReadDID_TOO_MANY_PENDING_REQUESTS.lua
			
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: Check APPLICATION_NOT_REGISTERED result code 

			--Requirement id in JAMA: SDLAQ-CRS-623

			--Verification criteria: 
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)			   
			end
			
			function Test: ReadDID_ApplicationNotRegister()				
				--mobile side: sending ReadDID request					
				local cid = self.mobileSession2:SendRPC("ReadDID",setReadDIDRequest())
				
				--mobile side: expected ReadDID response
				self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
			end						
		--End Test case ResultCodeCheck.3			
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.4
		--Description: Check REJECTED result code 

			--Requirement id in JAMA: SDLAQ-CRS-626

			--Verification criteria: 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- In case the data isn't available for current ECU, SDL rejects the request with the resultCode REJECTED resultCode. Success=false
			
			--Begin Test case ResultCodeCheck.4.1
			--Description: Check REJECTED resultCode from HMI
				function Test: ReadDID_HMIREJECTED()				
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,																		
																		didLocation = 
																		{ 
																			25535,
																		}, 
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,															
															didLocation = 
															{ 
																25535,
															}, 
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendError(data.id, data.method,"REJECTED", "Error Message")
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", info = "Error Message"})
				end
			--End Test case ResultCodeCheck.4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.4.2
			--Description: Check REJECTED resultCode when the data isn't available for current ECU
				
				--Not applicable
				
			--End Test case ResultCodeCheck.4.2		
		--End Test case ResultCodeCheck.4
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.5
		--Description: Check GENERIC_ERROR result code 

			--Requirement id in JAMA: SDLAQ-CRS-627, APPLINK-8585

			--Verification criteria: 
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.
				-- SDL requests to provide the known DIDs to ECU and ECU does not respond during timeout
			
			--Begin Test case ResultCodeCheck.5.1
			--Description: Check GENERIC_ERROR resultCode from HMI
				function Test: ReadDID_GENERIC_ERROR()				
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,																		
																		didLocation = 
																		{ 
																			25535,
																		}, 
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,															
															didLocation = 
															{ 
																25535,
															}, 
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendError(data.id, data.method,"GENERIC_ERROR", "Error Message")
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Error Message"})
				end
			--End Test case ResultCodeCheck.5.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.5.2
			--Description: SDL requests to provide the known DIDs to ECU and ECU does not respond during timeout
				function Test: ReadDID_NoResponseFromHMI()				
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,
																		didLocation = { 
																			25535
																		}
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,
															didLocation = { 
																			25535
																		}
														})				
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(15000)
				end
			--End Test case ResultCodeCheck.5.2		
		--End Test case ResultCodeCheck.5
		
		-----------------------------------------------------------------------------------------
--[[TODO: check after ATF defect APPLINK-13101 is resolved
		--Begin Test case ResultCodeCheck.6
		--Description: Check DISALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-624, SDLAQ-CRS-2396, SDLAQ-CRS-2397

			--Verification criteria: 
				-- SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				
			function Test:Precondition_PolicyUpdate()
				self:policyUpdate("PTU_OmittedReadDID.json", true)
			end
			function Test:ReadDID_DISALLOWED()				
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
									
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
			end			
		--End Test case ResultCodeCheck.6
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.7
		--Description: Check USER_DISALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-628, SDLAQ-CRS-2394

			--Verification criteria: 
				-- SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.
				
			function Test:Precondition_PolicyUpdate()
				self:policyUpdate("PTU_ForReadDID.json", false)
			end
			function Test:ReadDID_USER_DISALLOWED()				
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
									
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED"})
			end
			function Test:Precondition_UserAllowedReadDID()					
				--hmi side: sending SDL.OnAppPermissionConsent
				self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = idGroup, name = "New"}}, source = "GUI"})							
			end
		--End Test case ResultCodeCheck.7
--]]	

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.8
		--Description: Check TRUNCATED_DATA result code with success true

			--Requirement id in JAMA: SDLAQ-CRS-625

			--Verification criteria: 
				-- ReadDID requests the data which value exceeds platform maximum. VehicleData component returnes only a part of the data in a response, resultCode is "TRUNCATED_DATA". General result parameter success=true.
			
			function Test:ReadDID_TRUNCATED_DATA()
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",{																			
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}
														})
				
				--hmi side: expect ReadDID request
				EXPECT_HMICALL("VehicleInfo.ReadDID",{																			
														ecuName = 2000,																		
														didLocation = 
														{ 
															25535,
														}
													})
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.ReadDID response
					self.hmiConnection:SendResponse(data.id, data.method,"TRUNCATED_DATA", {
																						didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})
				end)
				
				
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "TRUNCATED_DATA", didResult =	{{				
																							resultCode = "SUCCESS", 
																							didLocation = 25535,
																							data = "123"
																						}}
																					})
																					
				--commonTestCases:DelayedExp(1000)
			end
		--End Test case ResultCodeCheck.8
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
			
			--Covered by ReadDID_NoResponseFromHMI
			
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-102
				--APPLINK-14765
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned. The corresponding DID results with data if available are returned.  
				--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app 
				
			function Test: ReadDID_ResponseInvalidStructure()
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
				
				--hmi side: expect ReadDID request
				EXPECT_HMICALL("VehicleInfo.ReadDID",{
														ecuName = 2000,															
														didLocation = 
														{ 
															25535,
														}, 
													})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.ReadDID response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}], "method":"VehicleInfo.ReadDID"}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"didResult":[{"data":"a","didLocation":56832,"resultCode":"SUCCESS"}], "method":"VehicleInfo.ReadDID"}')							
				end)
				
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				commonTestCases:DelayedExp(1000)
			end						
		--End Test case HMINegativeCheck.2
--]]		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-102
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned.
			function Test:ReadDID_SeveralResponseToOneRequest()
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
				
				--hmi side: expect ReadDID request
				EXPECT_HMICALL("VehicleInfo.ReadDID",{
														ecuName = 2000,															
														didLocation = 
														{ 
															25535,
														}, 
													})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.ReadDID response
					self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {info = 1234,
																				didResult =	{{				
																					resultCode = "SUCCESS", 
																					didLocation = 25535,
																					data = "123"
																				}}
																			})
					self.hmiConnection:SendError(data.id, data.method,"REJECTED", "Error Message")
					self.hmiConnection:SendError(data.id, data.method,"GENERIC_ERROR", "Error Message")													
				end)
				
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																					resultCode = "SUCCESS", 
																					didLocation = 25535,
																					data = "123"
																				}}})
				commonTestCases:DelayedExp(1000)
			end
		--End Test case HMINegativeCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-102
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:ReadDID_FakeParamsInResponse()
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,																		
																		didLocation = 
																		{ 
																			25535,
																		}, 
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,															
															didLocation = 
															{ 
																25535,
															}, 
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {fakeParam = "fakeParam",
																					didResult =	{{				
																						resultCode = "SUCCESS", 
																						didLocation = 25535,
																						data = "123"
																					}}
																				})														
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																						resultCode = "SUCCESS", 
																						didLocation = 25535,
																						data = "123"
																					}}})		
					:ValidIf (function(_,data)
			    		if data.payload.fakeParam then
			    			print("\27[36m SDL resend fake parameter to mobile app \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					commonTestCases:DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.2
			--Description: Parameter from another API
				function Test:ReadDID_ParamsFromOtherAPIInResponse()
					--mobile side: sending ReadDID request
					local cid = self.mobileSession:SendRPC("ReadDID",
																	{
																		ecuName = 2000,																		
																		didLocation = 
																		{ 
																			25535,
																		}, 
																	})
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{
															ecuName = 2000,															
															didLocation = 
															{ 
																25535,
															}, 
														})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {sliderPosition = 5,
																					didResult =	{{				
																						resultCode = "SUCCESS", 
																						didLocation = 25535,
																						data = "123"
																					}}
																				})														
					end)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", didResult =	{{				
																						resultCode = "SUCCESS", 
																						didLocation = 25535,
																						data = "123"
																					}}})				
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print("\27[36m SDL resend parameter from another API to mobile app \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					commonTestCases:DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.2			
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-102
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding DID results with data if available are returned.			
			function Test:ReadDID_WrongResponseToCorrectID()
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
				
				--hmi side: expect ReadDID request
				EXPECT_HMICALL("VehicleInfo.ReadDID",{
														ecuName = 2000,															
														didLocation = 
														{ 
															25535,
														}, 
													})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.ReadDID response
					self.hmiConnection:Send('{"error":{"code":4,"message":"ReadDID is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"VehicleInfo.ReadDID"}}')
				end)		
					
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
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
		--Description: Checking ReadDID frequency
		
			--Requirement id in JAMA: 
				-- APPLINK-7616 

			--Verification criteria:
				-- The System must not allow an application to request a single piece of data more frequently than once per second or what is allowed by the policy table.
				local readDIDRequest = 6
				local readDIDRejectedCount = 0
				local readDIDSuccessCount = 0
				function Test:ReadDID_FrequencyREJECTED() 
					for i=1, readDIDRequest do
						--mobile side: sending ReadDID request
						local cid = self.mobileSession:SendRPC("ReadDID",{																			
																			ecuName = 2000,																		
																			didLocation = 
																			{ 
																				25535,
																			}
																		})
					end
					
					--hmi side: expect ReadDID request
					EXPECT_HMICALL("VehicleInfo.ReadDID",{																			
															ecuName = 2000,																		
															didLocation = 
															{ 
																25535,
															}
														})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.ReadDID response
						self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {
																							didResult =	{{				
																								resultCode = "SUCCESS", 
																								didLocation = 25535,
																								data = "123"
																							}}
																						})
					end)
					:Times(5)
					
					--mobile side: expect ReadDID response
					EXPECT_RESPONSE("ReadDID")
					:ValidIf(function(exp,data)					
						if 
							exp.occurences == readDIDRequest and
							(data.payload.resultCode == "SUCCESS" or
							data.payload.resultCode == "REJECTED") then
								if 
									data.payload.resultCode == "SUCCESS" then
									readDIDSuccessCount = readDIDSuccessCount + 1
								else 
									readDIDRejectedCount = readDIDRejectedCount + 1	
								end

							if readDIDRejectedCount ~= 1 or readDIDSuccessCount ~= readDIDRequest - 1 then 
								print(" \27[36m Expected ReadDID responses with resultCode  REJECTED 1 time, actual - "..tostring(readDIDRejectedCount) .. ", expected with resultCodes SUCCESS " .. tostring(readDIDRequest) .. " times, actual - " .. tostring(readDIDSuccessCount) .. " \27[0m" )
								return false
							else
								return true
							end
						elseif
							data.payload.resultCode == "REJECTED" then
							readDIDRejectedCount = readDIDRejectedCount+1
							print(" \27[32m ReadDID response came with resultCode REJECTED \27[0m")
							return true

						elseif 
							exp.occurences == readDIDRequest and readDIDRejectedCount == 0 then 
							print(" \27[36m Response ReadDID with resultCode REJECTED did not came \27[0m")
							return false

						elseif 
							data.payload.resultCode == "SUCCESS" then
							readDIDSuccessCount = readDIDSuccessCount + 1
							print(" \27[32m ReadDID response came with resultCode SUCCESS \27[0m")
							return true	
						else
							print(" \27[36m ReadDID response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
							return false
							end		
					end)
					:Times(6)
					
					DelayedExp(1000)
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
		--Description: Check ReadDID when current HMI is NONE

			--Requirement id in JAMA:
				-- 	SDLAQ-CRS-801
				
			--Verification criteria: 
				-- SDL rejects ReadDID request with REJECTED resultCode when current HMI level is NONE.				
				
			function Test:Precondition_DeactivateToNone()
				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end
			
			function Test:ReadDID_HMILevelNone()
				--mobile side: sending ReadDID request
				local cid = self.mobileSession:SendRPC("ReadDID",
																{
																	ecuName = 2000,																		
																	didLocation = 
																	{ 
																		25535,
																	}, 
																})
					
				--mobile side: expect ReadDID response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
				:Timeout(12000)
			end
			
			function Test:Postcondition_ActivateFirstApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				if Test.isMediaApplication == true then
					--mobile side: expect notification
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				else
					--mobile side: expect notification
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end
			end
				
		--End Test case DifferentHMIlevel.1
	
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.2
		--Description: Check ReadDID when current HMI is LIMITED

			--Requirement id in JAMA:
				-- SDLAQ-CRS-801
				
			--Verification criteria: 
				-- SDL doesn't rejects ReadDID when current HMI level is LIMITED.				
			if 
				Test.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then						
				
					function Test:Precondition_DeactivateToLimited()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["Test Application"],
							reason = "GENERAL"
						})
						
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					end
					
					function Test:ReadDID_HMILevelLIMITED()
						self:readDIDSuccess(setReadDIDRequest())
					end
			
		--End Test case DifferentHMIlevel.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case DifferentHMIlevel.3
		--Description: Check ReadDID when current HMI is BACKGROUND

			--Requirement id in JAMA:
				-- SDLAQ-CRS-801
				
			--Verification criteria: 
				-- SDL doesn't rejects ReadDID when current HMI level is BACKGROUND.
					function Test:Precondition_AppRegistrationInSecondSession()
						--mobile side: start new 
						self.mobileSession2:StartService(7)
						:Do(function()
							local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
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
							  appID = "456"
							})
							
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
							
							--mobile side: expect response
							self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

							self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})					
						end)
					end
			
					function Test:Precondition_ActivateSecondApp()
						--hmi side: sending SDL.ActivateApp request
						local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})

						--hmi side: expect SDL.ActivateApp response
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
						
						--mobile side: expect notification from 2 app
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
						self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})					
					end				
			else
				if Test.isMediaApplication == false then
					function Test:Precondition_DeactivateToBackground()

						--hmi side: sending BasicCommunication.OnAppDeactivated notification
						self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

						EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
					end
				end
			end
			
			function Test:ReadDID_HMILevelBACKGROUND()
				self:readDIDSuccess(setReadDIDRequest())
			end
		--End Test case DifferentHMIlevel.3		
	--End Test suit DifferentHMIlevel
	
	
	policyTable:Restore_preloaded_pt()