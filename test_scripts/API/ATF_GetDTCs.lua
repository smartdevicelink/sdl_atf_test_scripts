Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')
require('user_modules/AppTypes')

 
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "GetDTCs" -- set request name

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createResponse(Request)
--3. verify_SUCCESS_Case(Request)
--4. verify_SUCCESS_Response_Case(Response)
--5. verify_GENERIC_ERROR_Response_Case(Response)
---------------------------------------------------------------------------------------------

--Create default request
function Test:createRequest()


	return 	{
				ecuName = 0
			}
	
end

--Create VehicleInfo expected result based on parameters from the request
function Test:createResponse(Request)
	
	local Req = commonFunctions:cloneTable(Request)
	
	local Response = {}
	if Req["ecuName"] ~= nil then
		Response["ecuHeader"] = 2
	end
	
	if Req["dtcMask"] ~= nil then
		Response["dtc"] = {"line 0","line 1","line 2"}
	end
	
	return Response

end

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)
	
	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.GetDTCs request 
	local Response = self:createResponse(Request)
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: sending response		
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)
			
end

--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response)
	
	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.GetDTCs request 
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)
			
end

--This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
--TODO: Update after resolving APPLINK-14765
function Test:verify_GENERIC_ERROR_Response_Case(Response)
	
	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.GetDTCs request 
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Received invalid data on HMI response" })
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
			
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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})
	

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA: 
	--SDLAQ-CRS-105 (GetDTCs_Request_v2_0)
	--SDLAQ-CRS-106 (GetDTCs_Response_v2_0)
	--SDLAQ-CRS-630 (SUCCESS)
	--SDLAQ-CRS-631 (INVALID_DATA)
	
	
--Verification criteria: GetDTC request sends exact ECU(electronic control unit) name and dtcMask for getting the vehicle module diagnostic trouble code. The response with response resultCode, ecuHeader and an array of all reported DTCs on module is returned.

--List of parameters:
--1. ecuName: type=Integer, minvalue="0" maxvalue="65535" mandatory="true"
--2. dtcMask: type=Integer, minvalue="0" maxvalue="255" mandatory="false"
-----------------------------------------------------------------------------------------------

--Common Test cases check all parameters with lower bound and upper bound
--1. PositiveRequest
--2. Only mandatory parameters
--3. All parameters are lower bound
--4. All parameters are upper bound

	
	Test["GetDTCs_PositiveRequest_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local Request = 
		{
			ecuName = 2,
			dtcMask = 3
		}
		
		self:verify_SUCCESS_Case(Request)
		
	end
	-----------------------------------------------------------------------------------------
		
	Test["GetDTCs_OnlyMandatoryParameters_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local Request = 
		{
			ecuName = 0
		}
		
		self:verify_SUCCESS_Case(Request)
		
	end
	-----------------------------------------------------------------------------------------
		
	Test["GetDTCs_AllParametersLowerBound_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local Request = 
		{
			ecuName = 0,
			dtcMask = 0
		}
		
		self:verify_SUCCESS_Case(Request)
		
	end
	-----------------------------------------------------------------------------------------
	
	Test["GetDTCs_AllParametersUpperBound_SUCCESS"] = function(self)
	
		--mobile side: request parameters
		local Request = 
		{
			ecuName = 65535,
			dtcMask = 255
		}
		
		self:verify_SUCCESS_Case(Request)
		
	end
	-----------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------
--Parameter 1: ecuName: type=Integer, minvalue="0" maxvalue="65535" mandatory="true"
--Parameter 2: dtcMask: type=Integer, minvalue="0" maxvalue="255" mandatory="false"
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------	

local Request1 = {dtcMask = 1}
integerParameter:verify_Integer_Parameter(Request1, {"ecuName"}, {0, 65535}, true)

local Request2 = {ecuName = 2}
integerParameter:verify_Integer_Parameter(Request2, {"dtcMask"}, {0, 255}, false)



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Begin Test case SpecialRequestChecks
--Description: Check special requests

	--Requirement id in JAMA: 
		--SDLAQ-CRS-105 (GetDTCs_Request_v2_0)
		--SDLAQ-CRS-106 (GetDTCs_Response_v2_0)
		--SDLAQ-CRS-630 (SUCCESS)
		--SDLAQ-CRS-631 (INVALID_DATA)
		
	--Verification criteria: GetDTCs request  notifies the user via VehicleInfo engine with some information that the app provides to HMI. After VehicleInfo has prompted, the response with SUCCESS resultCode is returned to mobile app.

local function SpecialRequestChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For Special Request Checks")

	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON
				
		--Requirement id in JAMA: SDLAQ-CRS-631
		--Verification criteria: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
		
		--local Payload = '{"ecuName":1, "dtcMask":2}'  -- valid JSON 
		  local Payload = '{"ecuName";1, "dtcMask":2}'
		commonTestCases:VerifyInvalidJsonRequest(24, Payload)	--GetDTCsID = 24	

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: CorrelationId check( duplicate value)

	
		function Test:GetDTCs_CorrelationID_IsDuplicated()
		
			--mobile side: sending GetDTCs request
			local Request = 
			{
				ecuName = 0,
				dtcMask = 0
			}
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--request from mobile side
			local msg = 
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 24,
			  rpcCorrelationId = cid,
			  payload          = '{"ecuName":0,"dtcMask":0}}'
			}
				
			--hmi side: expect VehicleInfo.GetDTCs request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", { ecuName = 0, dtcMask = 0} )
			:Do(function(exp,data)
				if exp.occurences == 1 then
					self.mobileSession:Send(msg)
				end
				
				--hmi side: sending response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
				
			end)
			:Times(2)
			
			--response on mobile side
			local ExpectedResponse = commonFunctions:cloneTable(Response)
			ExpectedResponse["success"] = true
			ExpectedResponse["resultCode"] = "SUCCESS"
			EXPECT_RESPONSE(cid, ExpectedResponse)
			:Times(2)
			
		end
	
	--End Test case NegativeRequestCheck.2

	
	--Begin Test case NegativeRequestCheck.3
		--Description: Fake parameters check
		
			--Requirement id in JAMA: APPLINK-14765
			--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

			--Begin Test case NegativeRequestCheck.3.1
			--Description: Fake parameters is not from any API
		
			function Test:GetDTCs_FakeParams_IsNotFromAnyAPI()						

				--mobile side: sending GetDTCs request		
				local FakeRequest  = 	
				{
					fakeParam = "abc",
					ecuName = 1,
					dtcMask = 2
				}
								
				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)
				
				local Request  = 	
				{
					ecuName = 1,
					dtcMask = 2
				}
				
				--hmi side: expect the request		
				local Response = self:createResponse(Request)				
				EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
				:ValidIf(function(_,data)
					if data.params.fakeParam then
							commonFunctions:printError(" SDL re-sends fakeParam parameters to HMI")
							return false
					else 
						return true
					end
				end)
				:Do(function(_,data)
					--hmi side: Sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
				end)

				--mobile side: expect the response
				local ExpectedResult = commonFunctions:cloneTable(Response)
				ExpectedResult["success"] = true
				ExpectedResult["resultCode"] = "SUCCESS"
				EXPECT_RESPONSE(cid, ExpectedResult)
				
			end						
			
			--End Test case NegativeRequestCheck.3.1
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3.2
			--Description: Fake parameters is not from another API
			
			function Test:GetDTCs_FakeParams_ParameterIsFromAnotherAPI()						

				--mobile side: sending GetDTCs request	
				local FakeRequest  = 	
				{
					syncFileName = "abc",
					ecuName = 1,
					dtcMask = 2
				}
					
				local Request  = 	
				{
					ecuName = 1,
					dtcMask = 2
				}
								
				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)
				
				
				--hmi side: expect the request
				local Response = self:createResponse(Request)
				EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
				:ValidIf(function(_,data)
					if data.params.syncFileName then
							commonFunctions:printError(" SDL re-sends fakeParam parameters to HMI")
							return false
					else 
						return true
					end
				end)
				:Do(function(_,data)
					--hmi side: Sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
				end)

				--mobile side: expect the response
				local ExpectedResult = commonFunctions:cloneTable(Response)
				ExpectedResult["success"] = true
				ExpectedResult["resultCode"] = "SUCCESS"
				EXPECT_RESPONSE(cid, ExpectedResult)
				
			end	

			--End Test case NegativeRequestCheck.3.2
			-----------------------------------------------------------------------------------------
			
			
			--Begin Test case NegativeRequestCheck.3.3
			--Description: Fake parameters is not from any API
		
			function Test:GetDTCs_WithFakeParamsAndInvalidRequest()						

				--mobile side: sending GetDTCs request		
				local FakeRequest  = 	
				{
					fakeParam = "abc",
					--ecuName = 1,
					dtcMask = 2
				}
								
				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)
				
				
				--hmi side: expect the request			
				EXPECT_HMICALL("VehicleInfo.GetDTCs", {})
				:Times(0)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				
			end						
			
			--End Test case NegativeRequestCheck.3.3
			-----------------------------------------------------------------------------------------
			
		--End Test case NegativeRequestCheck.3


	--Begin Test case NegativeRequestCheck.4
	--Description: All parameters missing	

		commonTestCases:VerifyRequestIsMissedAllParameters()

	--End Test case NegativeRequestCheck.4
	-----------------------------------------------------------------------------------------
	
end

SpecialRequestChecks()

--End Test case NegativeRequestCheck


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA: 
	--SDLAQ-CRS-105 (GetDTCs_Request_v2_0)
	--SDLAQ-CRS-106 (GetDTCs_Response_v2_0)
	--SDLAQ-CRS-630 (SUCCESS)
	--SDLAQ-CRS-631 (INVALID_DATA)
	--SDLAQ-CRS-632 (OUT_OF_MEMORY)
	--SDLAQ-CRS-633 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-634 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-635 (REJECTED)
	--SDLAQ-CRS-636 (GENERIC_ERROR)
	--SDLAQ-CRS-637 (DISALLOWED)
	--SDLAQ-CRS-638 (USER_DISALLOWED)
	--SDLAQ-CRS-1096 (TRUNCATED_DATA)
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI ( response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app)
	--APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
	
--Verification Criteria: 
	--The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode".
	--"info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available. 

--List of parameters:
--Parameter 1: resultCode: type=String Enumeration(Integer), mandatory="true" 
--Parameter 2: method: type=String, mandatory="true" (main test case: method is correct or not) 
--Parameter 3: info: type=String, minlength="1" maxlength="10" mandatory="false" 
--Parameter 4: correlationID: type=Integer, mandatory="true" 
--Parameter 5: ecuHeader: type=Integer, minvalue="0" maxvalue="65535" mandatory="true"
--Parameter 6: dtc: type=String, minsize="1" maxsize="15" maxlength="10" array="true" mandatory="false" 
-----------------------------------------------------------------------------------------------


--Common Test cases for response
--1. Check all mandatory parameters are missed
--2. Check all parameters are missed

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup("Test suite: common test cases for response")

Test[APIName.."_Response_MissingMandatoryParameters_GENERIC_ERROR"] = function(self)		

	--mobile side: sending the request		
	local Request  = 	
	{
		ecuName = 1,
		dtcMask = 2
	}
					
	local cid = self.mobileSession:SendRPC(APIName, Request)
	
		
	--hmi side: expect the request		
	local Response = self:createResponse(Request)				
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: Sending response
		--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
		self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"dtc":["line 0","line 1","line 2"]}}')
		
	end)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)
	
end						
-----------------------------------------------------------------------------------------


Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)		

	--mobile side: sending the request		
	local Request  = 	
	{
		ecuName = 1,
		dtcMask = 2
	}
					
	local cid = self.mobileSession:SendRPC(APIName, Request)
	
		
	--hmi side: expect the request		
	local Response = self:createResponse(Request)				
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: Sending response
		--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
		self.hmiConnection:Send('{}')
		
	end)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)
	
end						
-----------------------------------------------------------------------------------------
		

-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsValidValue
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
-----------------------------------------------------------------------------------------------
--ToDo: Update according to APPLINK-16141: Clarify behaviors of SDL when receiving SUCCESS resultCode in erroneous response and non SUCCESS resultCode in response
local function verify_resultCode_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"resultCode"})
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
				 
			self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
						
		end)
		
		--mobile side: expect the response
		--TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
	end
	
	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":4,"message":"abc"}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"message":"abc"}}')
		end)
		
		--mobile side: expect the response
		--TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
	end
	-----------------------------------------------------------------------------------------
	
	
	--2. IsValidValue
	local resultCodes = {
		{resultCode = "SUCCESS", success =  true},
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},		
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "USER_DISALLOWED", success =  false},		
		{resultCode = "TRUNCATED_DATA", success =  true}
	}
		
	for i =1, #resultCodes do
	
		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending response
				self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, Response)
			end)
			
						
			--mobile side: expect the response
			local ExpectedResponse = commonFunctions:cloneTable(Response)
			ExpectedResponse["success"] = resultCodes[i].success
			ExpectedResponse["resultCode"] = resultCodes[i].resultCode
			EXPECT_RESPONSE(cid, ExpectedResponse)
			
		end		
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")								
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode, info = "info"})
		end	
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------

	
	
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	local testData = {	
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"}}
	
	for i =1, #testData do
	
		Test[APIName.."_Response_resultCode_" .. testData[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, Response)				
			end)

			--mobile side: expect the response
			--TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_resultCode_" .. testData[i].name .."_GENERIC_ERROR_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, testData[i].value)
			end)
			
			--mobile side: expect the response
			--TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
		
end	

verify_resultCode_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 2: method
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsValidResponse
	--3. IsNotValidResponse
	--4. IsOtherResponse
	--5. IsEmpty
	--6. IsWrongType
	--7. IsInvalidCharacter - \n, \t, only spaces
-----------------------------------------------------------------------------------------------
	
--ToDo: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_method_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"method"})
	
	
	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
		
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
		end)
		
		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
		
			--hmi side: sending the response		  
			 --self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":4,"message":"abc"}}')
			 self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{},"code":4,"message":"abc"}}')
			  
		end)
		
		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------
	
	--2. IsValidResponse Covered by many test cases	
	-----------------------------------------------------------------------------------------

	
	--3. IsNotValidResponse
	--4. IsOtherResponse
	--5. IsEmpty
	--6. IsWrongType
	--7. IsInvalidCharacter - \n, \t, spaces	
	local Methods = {	
		{method = "ANY", name = "IsNotValidResponse"},
		{method = "GetCapabilities", name = "IsOtherResponse"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"},
		{method = "  ", name = "IsSpaces"},
	}
	
	for i =1, #Methods do
	
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				  self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", Response)
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)			
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "info")
				  self.hmiConnection:SendError(data.id, Methods[i].method, "REJECTED", "info")			
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)
						

		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
		
end	

verify_method_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 3: info
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. IsOutUpperBound
	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t, only spaces
-----------------------------------------------------------------------------------------------

local function verify_info_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"info"})
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_info_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		local Response = self:createResponse(Request)
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)			
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)			
		end)


		--mobile side: expect the response
		local ExpectedResponse = commonFunctions:cloneTable(Response)
		ExpectedResponse["success"] = true
		ExpectedResponse["resultCode"] = "SUCCESS"
		
		EXPECT_RESPONSE(cid, ExpectedResponse)
		:ValidIf (function(_,data)
			    		if data.payload.info then
			    			commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_info_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
		end)


		--mobile side: expect the response
		--TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
	end
	-----------------------------------------------------------------------------------------

	--2. IsLowerBound
	--3. IsUpperBound
	local testData = {	
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}
	
	for i =1, #testData do
	
		Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				Response["info"] = testData[i].value
				
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
			end)

			--mobile side: expect response
			local ExpectedResponse = commonFunctions:cloneTable(Response)
			ExpectedResponse["success"] = true
			ExpectedResponse["resultCode"] = "SUCCESS"
			EXPECT_RESPONSE(cid, ExpectedResponse)
			

		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})					

		end
		-----------------------------------------------------------------------------------------
		
	end
	-----------------------------------------------------------------------------------------
	
	--TODO: update after resolving APPLINK-14551
	-- --4. IsOutUpperBound
	-- Test[APIName.."_Response_info_IsOutUpperBound_SendResponse"] = function(self)
	
	-- 	local infoMaxLength = commonFunctions:createString(1000)
		
	-- 	--mobile side: sending the request
	-- 	local Request = self:createRequest()
	-- 	local cid = self.mobileSession:SendRPC(APIName, Request)
		
	-- 	--hmi side: expect the request
	-- 	local Response = self:createResponse(Request)
	-- 	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	-- 	:Do(function(_,data)
	-- 		--hmi side: sending the response
	-- 		Response["info"] = infoMaxLength .. "1"
	-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	-- 	end)

	-- 	--mobile side: expect the response
	-- 	local ExpectedResponse = commonFunctions:cloneTable(Response)
	-- 	ExpectedResponse["success"] = true
	-- 	ExpectedResponse["resultCode"] = "SUCCESS"
	-- 	ExpectedResponse["info"] = infoMaxLength
				
	-- 	EXPECT_RESPONSE(cid, ExpectedResponse)
		
	-- end
	-- -----------------------------------------------------------------------------------------
	
	-- Test[APIName.."_Response_info_IsOutUpperBound_SendError"] = function(self)
	
	-- 	local infoMaxLength = commonFunctions:createString(1000)
		
	-- 	--mobile side: sending the request
	-- 	local Request = self:createRequest()
	-- 	local cid = self.mobileSession:SendRPC(APIName, Request)
		
	-- 	--hmi side: expect the request
	-- 	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	-- 	:Do(function(_,data)
	-- 		--hmi side: sending the response
	-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
	-- 	end)

	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})
		
	-- end
	-- -----------------------------------------------------------------------------------------
		

	-- --5. IsEmpty/IsOutLowerBound	
	-- --6. IsWrongType
	-- --7. InvalidCharacter - \n, \t, only spaces
	
	-- local testData = {	
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"},
	-- 	{value = " ", name = "IsInvalidCharacter_OnlySpaces"}}
	
	-- for i =1, #testData do
	
	-- 	Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
	-- 		--mobile side: sending the request
	-- 		local Request = self:createRequest()
	-- 		local cid = self.mobileSession:SendRPC(APIName, Request)
			
	-- 		--hmi side: expect the request
	-- 		local Response = self:createResponse(Request)
	-- 		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	-- 		:Do(function(_,data)
	-- 			--hmi side: sending the response
	-- 			Response["info"] = testData[i].value
	-- 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	-- 		end)

	-- 		--mobile side: expect the response
	-- 		local ExpectedResponse = commonFunctions:cloneTable(Response)
	-- 		ExpectedResponse["success"] = true
	-- 		ExpectedResponse["resultCode"] = "SUCCESS"
	-- 		ExpectedResponse["info"] = nil					
	-- 		EXPECT_RESPONSE(cid, ExpectedResponse)			
	-- 		:ValidIf (function(_,data)
	-- 						if data.payload.info then
	-- 							commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
	-- 							return false
	-- 						else 
	-- 							return true
	-- 						end
	-- 					end)				

	-- 	end
	-- 	-----------------------------------------------------------------------------------------
		
	-- 	Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)
			
	-- 		--mobile side: sending the request
	-- 		local Request = self:createRequest()
	-- 		local cid = self.mobileSession:SendRPC(APIName, Request)
			
	-- 		--hmi side: expect the request
	-- 		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	-- 		:Do(function(_,data)
	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
	-- 		end)

	-- 		--mobile side: expect the response
	-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	-- 		:ValidIf (function(_,data)
	-- 						if data.payload.info then
	-- 							commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
	-- 							return false
	-- 						else 
	-- 							return true
	-- 						end
							
	-- 					end)				

	-- 	end
	-- 	-----------------------------------------------------------------------------------------
		
	-- end
	-----------------------------------------------------------------------------------------
	
end	

verify_info_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID 
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. IsMissed
	--2. IsNonexistent
	--3. IsWrongType
	--4. IsNegative 
-----------------------------------------------------------------------------------------------
--ToDo: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method

local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"correlationID"})
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed	
	Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
	
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	
	--2. IsNonexistent
	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
	
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
	-----------------------------------------------------------------------------------------

	
	--3. IsWrongType
	Test[APIName.."_Response_CorrelationID_IsWrongType_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		local Response = self:createResponse(Request)
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
			Response["info"] = "info" 
			  self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", Response)
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
				
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
			  self.hmiConnection:SendError(tostring(data.id), data.method, "REJECTED", "error message")
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--4. IsNegative 
	Test[APIName.."_Response_CorrelationID_IsNegative_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		local Response = self:createResponse(Request)
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
			Response["info"] = "info" 
			  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", Response)
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
				
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
			  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--5. IsNull
	Test[APIName.."_Response_CorrelationID_IsNull_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		local Response = self:createResponse(Request)
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			  		
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
				
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_CorrelationID_IsNull_SendError"] = function(self)
	
		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		
		--hmi side: expect the request
		EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
			
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------
		
end	

verify_correlationID_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 5: ecuHeader: type=Integer, minvalue="0" maxvalue="65535" mandatory="true"
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local Response = {ecuHeader = 0, dtc = {"a"}}
integerParameterInResponse:verify_Integer_Parameter(Response, {"ecuHeader"}, {0, 65535}, true)


-----------------------------------------------------------------------------------------------
--Parameter 6: dtc: type=String, minsize="1" maxsize="15" maxlength="10" array="true" mandatory="false" 
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local IsSupportedSpecialCharacters = true
arrayStringParameterInResponse:verify_Array_String_Parameter(Response, {"dtc"}, {1, 15},  {1, 10}, false, IsSupportedSpecialCharacters)


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

--Begin Test case SpecialResponseChecks
--Description: Check all negative response cases
	
	--Requirement id in JAMA: 
		--SDLAQ-CRS-106 (GetDTCs_Response_v2_0)
		--SDLAQ-CRS-636 (GENERIC_ERROR)
		
	
local function SpecialResponseChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For Special Response Checks")
	----------------------------------------------------------------------------------------------
	

	--Begin Test case NegativeResponseCheck.1
	--Description: Invalid JSON

		
		--Requirement id in JAMA: SDLAQ-CRS-106
		--Verification criteria: The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode". "info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available. 
		
		--[[ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		
		function Test:GetDTCs_Response_IsInvalidJson()
		
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
			
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
			end)
				
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)
			
		end	
		
	--End Test case NegativeResponseCheck.1


	--Begin Test case NegativeResponseCheck.2
	--Description: Check processing response with fake parameters
	
		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter			
		
		--Begin Test case NegativeResponseCheck.2.1
		--Description: Parameter is not from API
		
		function Test:GetDTCs_Response_FakeParams_IsNotFromAnyAPI()
		
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
								
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
			:Do(function(exp,data)
				--hmi side: sending the response
				Response["fake"] = "fake"
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
			end)
			
						
			--mobile side: expect the response
			local ExpectedResponse = commonFunctions:cloneTable(Response)
			ExpectedResponse["success"] = true
			ExpectedResponse["resultCode"] = "SUCCESS"
			ExpectedResponse["fake"] = nil
			EXPECT_RESPONSE(cid, ExpectedResponse)
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)
						
		end								
		
		--End Test case NegativeResponseCheck.2.1
		
		
		--Begin Test case NegativeResponseCheck.2.2
		--Description: Parameter is not from another API
		
		function Test:GetDTCs_Response_FakeParams_IsFromAnotherAPI()
		
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
								
			--hmi side: expect the request
			local Response = self:createResponse(Request)
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
			:Do(function(exp,data)
				--hmi side: sending the response
				Response["sliderPosition"] = 5
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
			end)
			
						
			--mobile side: expect the response
			local ExpectedResponse = commonFunctions:cloneTable(Response)
			ExpectedResponse["success"] = true
			ExpectedResponse["resultCode"] = "SUCCESS"
			ExpectedResponse["sliderPosition"] = nil
			EXPECT_RESPONSE(cid, ExpectedResponse)
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)
						
		end								
		
		--End Test case NegativeResponseCheck.2.2
		
	--End Test case NegativeResponseCheck.2
]]

	--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters
	--Begin NegativeResponseCheck.3
	--Description: Check processing response without all parameters		
			
		function Test:GetDTCs_Response_IsMissedAllPArameters()	
		
			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.GetDTCs response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
				self.hmiConnection:Send('{}')
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)
			
		end

	--End NegativeResponseCheck.3
]]

	--Begin Test case NegativeResponseCheck.4
	--Description: Request without responses from HMI

		--Requirement id in JAMA: SDLAQ-CRS-636
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.

		function Test:GetDTCs_NoResponse()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
								
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
			
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
		
		end
		
	--End NegativeResponseCheck.4
		

	--Begin Test case NegativeResponseCheck.5
	--Description: Invalid structure of response
	


		--Requirement id in JAMA: SDLAQ-CRS-106
		--Verification criteria: The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode". "info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available. 
		
--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters
		
		function Test:GetDTCs_Response_IsInvalidStructure()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)
								
			--hmi side: expect the request
			EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"VehicleInfo.GetDTCs"}}')
			end)							
		
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
			:Timeout(12000)
					
		end
		]]
	--End Test case NegativeResponseCheck.5							

	
	--Begin Test case NegativeResponseCheck.6
	--Description: Several response to one request

		--Requirement id in JAMA: SDLAQ-CRS-106
			
		--Verification criteria: The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode". "info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available. 
		
		
		--Begin Test case NegativeResponseCheck.6.1
		--Description: Several response to one request
			
			function Test:GetDTCs_Response_SeveralResponseToOneRequest()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)
									
				--hmi side: expect the request
				local Response = self:createResponse(Request)
				EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", Response)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
					
				end)
				
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				
			end									
			
		--End Test case NegativeResponseCheck.6.1
		
		
		
		--Begin Test case NegativeResponseCheck.6.2
		--Description: Several response to one request
		--Requirement: APPLINK-15509 have not been implemented yet.
		
			function Test:GetDTCs_Response_WithConstractionsOfResultCodes()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)
									
				--hmi side: expect the request
				local Response = self:createResponse(Request)
				EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)		
				:Do(function(exp,data)
					--hmi side: sending the response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
					
					--response both SUCCESS and GENERIC_ERROR resultCodes
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.GetDTCs", "code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}, "error":{"data":{"method":"VehicleInfo.GetDTCs"},"code":22,"message":"The unknown issue occurred"}}')
					
				end)
				
							
				--mobile side: expect response 
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				:Timeout(13000)
				
			end									
			
		--End Test case NegativeResponseCheck.6.2
		-----------------------------------------------------------------------------------------

	--End Test case NegativeResponseCheck.6
	
end

SpecialResponseChecks()

--End Test case NegativeResponseCheck	

	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks
--Description: Check all resultCodes

	--Requirement id in JAMA: 
		--SDLAQ-CRS-630 (SUCCESS)
		--SDLAQ-CRS-631 (INVALID_DATA)
		--SDLAQ-CRS-632 (OUT_OF_MEMORY)
		--SDLAQ-CRS-633 (TOO_MANY_PENDING_REQUESTS)
		--SDLAQ-CRS-634 (APPLICATION_NOT_REGISTERED)
		--SDLAQ-CRS-635 (REJECTED)
		--SDLAQ-CRS-636 (GENERIC_ERROR)
		--SDLAQ-CRS-637 (DISALLOWED)
		--SDLAQ-CRS-638 (USER_DISALLOWED)
		--SDLAQ-CRS-1096 (TRUNCATED_DATA)

		
local function ResultCodeChecks()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For resultCodes Checks")
	----------------------------------------------------------------------------------------------
	
	--SUCCESS: Covered by many test cases.
	--INVALID_DATA: Covered by many test cases.
	--OUT_OF_MEMORY: ToDo: Wait until requirement is clarified
	--TOO_MANY_PENDING_REQUESTS: It is moved to other script.		
	--GENERIC_ERROR: Covered by test case GetDTCs_NoResponse
	--REJECTED, TRUNCATED_DATA: Covered by test case resultCode_IsValidValue
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: SDLAQ-CRS-634
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
				
		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()
		
	--End Test case ResultCodeChecks.1

	-----------------------------------------------------------------------------------------
	
end

ResultCodeChecks()

--End Test case ResultCodeChecks


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit SequenceChecks
--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	
	
local function SequenceChecks()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For Sequence Checks")
	----------------------------------------------------------------------------------------------
	
	--Test case TC_GetDTCs_01 is covered by GetDTCs_PositiveRequest_SUCCESS
	
end

SequenceChecks()

--End Test suit SequenceChecks  		
		

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--SDLAQ-CRS-802: HMI Status Requirements for GetDTCs
--Verification Criteria:
	--SDL rejects GetDTCs request with REJECTED resultCode when current HMI level is NONE.
	--SDL doesn't reject GetDTCs request when current HMI is FULL.
	--SDL doesn't reject GetDTCs request when current HMI is LIMITED.
	--SDL doesn't reject GetDTCs request when current HMI is BACKGROUND.

--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")

	
policyTable:Restore_preloaded_pt()
	

return Test