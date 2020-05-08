--Note: A lot of TCs are currently failing in script since APPLINK-14765 is not implemented yet.
---------------------------------------------------------
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
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local arrayIntergerParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayIntegerParameterInResponse')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "DiagnosticMessage" -- set request name
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local messageData = {1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62}

---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(Request)
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------

--Create default request parameters
function Test:createRequest()

	return 	{
				targetID = 42,
				messageLength = 8,
				messageData = {1}
			}


end

---------------------------------------------------------------------------------------------
--Create default response
function Test:createResponse()
	local response ={}

	response["messageDataResult"] = {200}

	return response

end

---------------------------------------------------------------------------------------------
--Create INVALID_DATA response
function Test:verify_INVALID_DATA_Case(paramsSend)
	--mobile side: sending ReadDID request
	local cid = self.mobileSession:SendRPC("DiagnosticMessage",paramsSend)

	--mobile side: expected ReadDID response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

---------------------------------------------------------------------------------------------
--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.DiagnosticMessage request
	local Response = self:createResponse()
	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

---------------------------------------------------------------------------------------------
--This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
function Test:verify_GENERIC_ERROR_Response_Case(Response)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.DiagnosticMessage request
	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Received invalid data on HMI response" })

end

---------------------------------------------------------------------------------------------
--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.DiagnosticMessage request
	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--policyTable:precondition_updatePolicyAndAllowFunctionGroup({"FULL", "LIMITED", "BACKGROUND"}, false, false)
          policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"}) 

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
---------------------------Check normal cases of Mobile request--------------------------------
-----------------------------------------------------------------------------------------------

	--Begin test suit PositiveRequestCheck
	--Description:
		-- request with all mandatory parameters
		-- request with lower/upper values
		-- request with out of lower/upper bound values
		-- request with valid/invalid value

		--Write TEST_BLOCK_I_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite I: common test cases for request ******************************")

			--Begin test case CommonRequestCheck.1
		    --Description: This test is intended to check positive cases and when all parameters. For this API, all params are mandatory

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642

				--Verification criteria: SDL re-sends the request to HMI via VehicleInfo.DiagnosticMessage IN CASE SDL receives the DiagnosticMessage request with valid params from mobile app then it reponds SUCCESS to mobile app

				Test["DiagnosticMessage_PositiveRequest_SUCCESS"] = function(self)

					--mobile side: request parameters
					local Request =
					{
						targetID = 42,
						messageLength = 8,
						messageData = {1,2}
					}

					self:verify_SUCCESS_Case(Request)

				end

			--End test case CommonRequestCheck.1
			-----------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.2
		    --Description: This test is intended to check positive cases and when all parameters are lower bound values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642

				--Verification criteria: SDL re-sends the request to HMI via VehicleInfo.DiagnosticMessage IN CASE SDL receives the DiagnosticMessage request with valid params from mobile app then it reponds SUCCESS to mobile app.

				Test["DiagnosticMessage_AllParametersLowerBound_SUCCESS"] = function(self)

					--mobile side: request parameters
					local Request =
					{
						targetID = 0,
						messageLength = 0,
						messageData = {1}
					}

					self:verify_SUCCESS_Case(Request)

				end

			--End test case CommonRequestCheck.2
			---------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.3
		    --Description: This test is intended to check positive cases and when all parameters are lower bound values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642

				--Verification criteria: SDL re-sends the request to HMI via VehicleInfo.DiagnosticMessage IN CASE SDL receives the DiagnosticMessage request with valid params from mobile app then it reponds SUCCESS to mobile app.

                               --TODO:to debug
--[[
				Test["DiagnosticMessages_AllParametersUpperBound_SUCCESS"] = function(self)
				-- create upper bound of messageData
				   local temp = {}
						temp[1]=1
						for i = 2, 65535 do
							temp[i] = math.random(0,255)
						end
					--mobile side: request parameters
					local Request =
					{
						targetID = 65535,
						messageLength = 65535,
						messageData = temp
					}

					self:verify_SUCCESS_Case(Request)

				end
--]]
			--End test case CommonRequestCheck.3
			--------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.4
			--Description: This test is intended to check in case parameter "targetID" value:
				--1. IsMissed
				--2. IsWrongType
				--3. IsLowerBound
				--4. IsUpperBound
				--5. IsOutLowerBound
				--6. IsOutUpperBound

				-----------------------------------------------------------------------------------------------
				--"targetID": type = Integer, minvalue =" 0", maxvalue="65535", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				local Request1 = {messageLength = 1,messageData={1,2} }
				integerParameter:verify_Integer_Parameter(Request1, {"targetID"}, {0, 65535}, true)

			--End test case CommonRequestCheck.4
			-----------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.5
			--Description: This test is intended to check in case parameter "messageData" value:
				--1. IsMissed
				--2. IsWrongType
				--3. IsLowerBound
				--4. IsUpperBound
				--5. IsOutLowerBound
				--6. IsOutUpperBound

				-------------------------------------------------------------------------------------------------------------
				--"messageLength": type = Integer, minvalue="0", maxvalue="65535", mandatory="true"
				-------------------------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				local Request2 = {targetID = 8,messageData={1,2} }
				integerParameter:verify_Integer_Parameter(Request2, {"messageLength"}, {0, 65535}, true)

			--End test case CommonRequestCheck.5
			-----------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.6
			--Description: This test is intended to check when parameter messageDataArray is out of lower bound, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				function Test:DiagnosticMessage_messageDataArrayOutOfLowerBound()
					local Request= {
						messageData={},
						targetID=12,
						messageLength=9
						}
					self:verify_INVALID_DATA_Case(Request)
				end

			--End test case CommonRequestCheck.6
			----------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.7
			--Description: This test is intended to check when parameter messageDataArray is out of upper bound, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641
				--TODO: to debug
--[[
				function Test:DiagnosticMessage_messageDataArrayOutOfUpperBound()
					--create upper bound of messageData
					   local temp = {}
							temp[1]=1
							for i = 2, 65356 do
								temp[i] = math.random(0,255)
							end
						--mobile side: request parameters
						local Request =
						{
							targetID = 42,
							messageLength = 8,
							messageData = temp
						}

					self:verify_INVALID_DATA_Case(Request)
				end
--]]
			--End test case CommonRequestCheck.7
			---------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.8
			--Description: This test is intended to check when parameter messageData value is out of lower bound, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				function Test:DiagnosticMessage_messageDataValueOutOfLowerBound()
					local Request= {
						messageData={1,-1},
						targetID=12,
						messageLength=9
						}
					self:verify_INVALID_DATA_Case(Request)
				end

			--End test case CommonRequestCheck.8
			---------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.9
			--Description: This test is intended to check when parameter messageData value is out of upper bound, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				function Test:DiagnosticMessage_messageDataValueOutOfUpperBound()
					local Request= {
						messageData={1,256},
						targetID=12,
						messageLength=9
						}
					self:verify_INVALID_DATA_Case(Request)
				end
			--End test case CommonRequestCheck.9
			--------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.10
			--Description: This test is intended to check when messageData element value is wrong type, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				function Test:DiagnosticMessage_messageData_Element_IsWrongType()
					local Request= {
						messageData={"1","test"},
						targetID=12,
						messageLength=9
						}
					self:verify_INVALID_DATA_Case(Request)
				end

			--End test case CommonRequestCheck.10
			--------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.11
			--Description: This test is intended to check that the first element of 'messageData' according with allowed 'supportedDiagModes' param of .ini file.
			--In .ini file: SupportedDiagModes = 0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E (in hex, which corresponds with dec: 1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62)

				--Requirement id in JAMA/or Jira ID: CRQ APPLINK-13293
				--Verification criteria: SDL responds with SUCCESS

				local randomElement = {}
				for i=1,#messageData do
					randomElement = math.random(255)

					Test["DiagnosticMessage_with_specified_messageData_"..messageData[i]] = function(self)

						--mobile side: sending DiagnosticMessage request
						local cid = self.mobileSession:SendRPC("DiagnosticMessage",
																{
																	targetID = 1000,
																	messageLength = 500,
																	messageData = {messageData[i], randomElement}
																})
						--hmi side: expect VehicleInfo.DiagnosticMessage request
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
										{
											appID = self.applications["Test Application"],
											targetID = 1000,
											messageLength = 500,
											messageData = {messageData[i], randomElement}
										})
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.DiagnosticMessage response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {55}})
						end)

						--mobile side: expect DiagnosticMessage response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					end

				end

			--End test case CommonRequestCheck.11
			------------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.12
			--Description: This test is intended to check that the first element of 'messageData' according with allowed 'supportedDiagModes' param of .ini file.
			--In .ini file: SupportedDiagModes = 0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E (in hex, which corresponds with dec: 1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62)

				--Requirement id in JAMA/or Jira ID: CRQ APPLINK-13293
				--Verification criteria: SDL responds with REJECTED

		        for i = 1, 255 do

					local IsValidValue = false

					--look for "i" value in valid values list
					for j = 1, #messageData do
						if i == messageData[j] then
							IsValidValue = true
							break
						end
					end

					--Create test case if "i" is not valid value
					if IsValidValue ~=  true then

						Test["DiagnosticMessage_with_non_specified_messageData_"..tostring(i)] = function(self)

							--mobile side: sending DiagnosticMessage request
							local cid = self.mobileSession:SendRPC("DiagnosticMessage",
																	{
																		targetID = 1000,
																		messageLength = 500,
																		messageData = {i}
																	})

							--mobile side: expect DiagnosticMessage response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

						end
					end
			    end


			--End test case CommonRequestCheck.12
			------------------------------------------------------------------------------------------

			--------------------------------------------------------------------------------------------
			--Begin test case CommonRequestCheck.13
			--Description: This test is intended to check when parameter messageData value is wrong type, SDL returns INVALID_DATA

				-----------------------------------------------------------------------------------------------
				--messageData: type =Integer, minvalue="0", maxvalue="255", minsize="1", maxsize="65535", array="true", mandatory="true"
				-----------------------------------------------------------------------------------------------

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642,SDLAQ-CRS-2641

				function Test:DiagnosticMessage_messageData_IsWrongType()
					local Request= {
						messageData="test",
						targetID=12,
						messageLength=9
						}
					self:verify_INVALID_DATA_Case(Request)
				end

			--End test case CommonRequestCheck.13

	--End Test suit PositiveRequestCheck
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK II---------------------------------------
--------------------------------Check special cases of Mobile request--------------------------
-----------------------------------------------------------------------------------------------
	--Begin test suit for checking special cases of Mobile request
	--Description:
		-- request with Invalid Json Request
		-- request with CorrelationID is duplicated
		-- request with fake parameters (fake - not from protocol, from another API)
		-- request is missed one or all mandatory parameters

		--Write TEST_BLOCK_II_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite II: Check special cases of Mobile request *****************")

			--Begin test case SpecialRequestCheck2.1
			--Description: This test is intend to check when Json syntax is invalid

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

				--local Payload = '{"targetID":42, {"messageLength":2},"messageData":[1,12]}'  = -- valid JSON
				local Payload = '{"targetID";42, "messageLength":2,"messageData":[1,12]}'
				commonTestCases:VerifyInvalidJsonRequest(37, Payload)	--DiagnosticMessage = 37
				--add more

			--End test case SpecialRequestCheck2.1
			-----------------------------------------------------------------------------------

			--Begin test case SpecialRequestCheck2.2
			--Description: This test is intend to check when CorrelationID is duplicated

				--Requirement id in JAMA/or Jira ID: APPLINK-14293
				--Verification criteria: The request with CorrelationID is duplicated, the response should come with SUCCESS result code.

				function Test:DiagnosticMessage_CorrelationID_IsDuplicated()
					--mobile side: sending DiagnosticMessage request
					local Request =
					{
						targetID = 42,
						messageLength = 8,
						messageData= {1,2}
					}
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--request from mobile side
					local msg =
					{
					  serviceType      = 7,
					  frameInfo        = 0,
					  rpcType          = 0,
					  rpcFunctionId    = 37,
					  rpcCorrelationId = cid,
					  payload          = '{"targetID":42,"messageLength":8,"messageData":[1,2]}'
					}

					--hmi side: expect VehicleInfo.DiagnosticMessage request
					local Response = self:createResponse(Request)

					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

			--End test case SpecialRequestCheck2.2
			-----------------------------------------------------------------------------------

			--Begin test case SpecialRequestCheck2.3
			--Description: This test is intend to check request with fake params

				--Requirement id in JAMA/or Jira ID: APPLINK-4518
				--Verification criteria: According to xml tests by Ford team all fake parameter should be ignored by SDL, SDL should responds SUCCESS to mobile app

				function Test:DiagnosticMessage_FakeParams_IsNotFromAnyAPI()
					--mobile side: sending DiagnosticMessage request
					local FakeRequest  =
					{
						fakeParam = "abc",
						targetID = 42,
						messageLength = 8,
						messageData= {1,2}
					}

					local cid = self.mobileSession:SendRPC(APIName, FakeRequest)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

			--End test case SpecialRequestCheck2.3
			--------------------------------------------------------------------------------------------

			--Begin test case SpecialRequestCheck2.4
			--Description: This test is intend to check request with fake params with param from another API

				--Requirement id in JAMA/or Jira ID: APPLINK-4518
				--Verification criteria: According to xml tests by Ford team all fake parameter should be ignored by SDL, SDL should responds SUCCESS to mobile app

				function Test:DiagnosticMessage_FakeParams_FromAnotherAPI()
					--mobile side: sending DiagnosticMessage request
					local FakeRequest  =
					{
						syncFileName = "abc",
						targetID = 42,
						messageLength = 8,
						messageData= {1,2}
					}

					local cid = self.mobileSession:SendRPC(APIName, FakeRequest)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

			--End test case SpecialRequestCheck2.4
			-------------------------------------------------------------------------------------------

			--Begin test case SpecialRequestCheck2.5
			--Description: This test is intend to check request missing MessageData

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL should responds INVALID_DATA

				function Test:DiagnosticMessage_MessageData_IsMissed()
					--create Request
					local Request =
						{
							targetID = 42,
							messageLength = 8
						}
					--Send request
					self:verify_INVALID_DATA_Case(Request)
				end

			--End test case SpecialRequestCheck2.5
			----------------------------------------------------------------------------------------

			--Begin test case SpecialRequestCheck2.6
			--Description: This test is intend to check request missing all params

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL should responds INVALID_DATA

				commonTestCases:VerifyRequestIsMissedAllParameters()

			--End test case SpecialRequestCheck2.6

	--End Test suit SpecialRequestCheck
-- -------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
--------------------------------Check normal cases of HMI response--------------------------
-----------------------------------------------------------------------------------------------
	--Begin test suit HMIResponseCheck
	--Description:
		-- response without any parameters
		-- response with mandatory parameter is missed
		-- response with pamameter is valid/invalid/not existed/empty/wrongtype
		-- response with inbound/outbound value

		--Write TEST_BLOCK_III_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite III: HMIResponseCheck ******************************")

			--Begin test case HMIResponseCheck3.1
		    --Description: This test is intended to check when HMI response without any params

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2955, APPLINK-14765
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app
				Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)

					--mobile side: sending the request
					local Request  =
					{
						targetID = 42,
						messageLength = 8,
						messageData= {1,2}
					}
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: Sending response
						--"jsonrpc":"2.0","id":36,"result":{"messageDataResult":[200],"code":0,"method":"VehicleInfo.DiagnosticMessage"}}
						self.hmiConnection:Send('{}')

					end)

					--mobile side: expect the response

					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end

			--End test case HMIResponseCheck3.1
			-----------------------------------------------------------------------------------------------

			-----------------------------------------------------------------------------------------------
			--Parameter 1: Result code
			-----------------------------------------------------------------------------------------------
			--Description:
				-- response without ResultCode
				-- response with valid ResultCode
				-- response with invalid ResultCode (empty, not existed, wrongtype)
			-----------------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.2
				--Description: This test is intended to check when HMI response with ResultCode is missed

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2955, APPLINK-14765
					--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

					Test[APIName.."_Response_MissingResultCodeParameters_GENERIC_ERROR"] = function(self)
						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						local Response = self:createResponse(Request)
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
						:Do(function(_,data)
							--hmi side: Sending response

							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"messageDataResult":[200],"method":"VehicleInfo.DiagnosticMessage"}}')

						end)

						--mobile side: expect the response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(13000)

					end

				--End test case HMIResponseCheck3.2
				-----------------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.3
				--Description: This test is intended to check when HMI response with ResultCode is valid
					--Result codes: SUCCESS, INVALID_DATA, OUT_OF_MEMORY, TOO_MANY_PENDING_REQUESTS, APPLICATION_NOT_REGISTERED, REJECTED, GENERIC_ERROR, DISALLOWED,DISALLOWED, TRUNCATED_DATA
				----------------------------------------------------------------------------------------------
					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
					--Verification criteria: SDL reponds valid Result codes to mobile app ()

					local resultCodes = {
						{resultCode = "SUCCESS", success =  true},
						{resultCode = "INVALID_DATA", success =  false},
						{resultCode = "OUT_OF_MEMORY", success =  false},
						{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
						{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
						{resultCode = "REJECTED", success =  false},
						{resultCode = "GENERIC_ERROR", success =  false},
						{resultCode = "DISALLOWED", success =  false},
						{resultCode = "TRUNCATED_DATA", success =  true}
					}

					for i =1, #resultCodes do

						Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse()
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(_,data)
								--hmi side: sending response
								self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, Response)
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
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
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(_,data)
								--hmi side: sending the response
								self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info", Response)
							end)

							--mobile side: expect the response
							EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode, info = "info"})
						end
						-----------------------------------------------------------------------------------------
					end

				--End test case HMIResponseCheck3.3
				-----------------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.4
				--Description: This test is intended to check when HMI response with ResultCode is not existed/empty/wrong value
				----------------------------------------------------------------------------------------------

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765
					--Verification criteria: SDL reponds Generic_error code to mobile app ()

				local testData = {
									{value = "ANY", name = "IsNotExist"},
									{value = "", name = "IsEmpty"},
									{value = 123, name = "IsWrongType"}
								}

				for i =1, #testData do

					Test[APIName.."_Response_resultCode_IsValidValue_" .. testData[i].name .."_SendResponse"] = function(self)

						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						local Response = self:createResponse()
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
						:Do(function(_,data)
							--hmi side: sending response
							self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, Response)
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
						end)

						--mobile side: expect the response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

					end
					-----------------------------------------------------------------------------------------

					Test[APIName.."_Response_resultCode_IsValidValue_" .. testData[i].name .."_SendError"] = function(self)

						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
						:Do(function(_,data)
							--hmi side: sending the response
							self.hmiConnection:SendError(data.id, data.method, testData[i].value, "info", Response)
						end)

						--mobile side: expect the response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "info"})
					end
					-----------------------------------------------------------------------------------------
				end

			--End test case HMIResponseCheck3.4
			------------------------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------------
		--End check for Parameter 1: Result code
		-----------------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------------
		--Parameter 2: MessageDataResult
		--messageDataResult[]: minvalue="0" maxvalue="255" minsize="1" maxsize="65535" array="true" mandatory="true"
		-----------------------------------------------------------------------------------------------
		--Description:
			-- Response without MessageDataResult
			-- Response with MessageDataResult array size is IsLowerBound
			-- Response with MessageDataResult array size is IsOutOfLowerBound
			-- Response with MessageDataResult array size is IsUpperBound
			-- Response with MessageDataResult array size is IsOutOfUpperBound
			-- Response with MessageDataResult IsLowerBoundValue
			-- Response with MessageDataResult IsOutOfLowerBoundValue
			-- Response with MessageDataResult IsUpperBoundValue
			-- Response with MessageDataResult IsOutOfUpperBoundValue
			-- Response with MessageDataResult IsWrongType
		-----------------------------------------------------------------------------------------------
	--TODO: to debug
     --[[
			local Response = {messageDataResult = {12}}
			arrayIntergerParameterInResponse:verify_Array_Integer_Parameter(Response, {"messageDataResult"},{1,65535}, {0,255},true)
     --]]
		-----------------------------------------------------------------------------------------------
		--End check for Parameter 2: MessageDataResult
		-----------------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------------
		--Parameter 3: Method
		-----------------------------------------------------------------------------------------------
		--Description:
			-- Response with Method IsMissed
			-- Response with Method IsValidResponse
			-- Response with Method IsNotValidResponse
			-- Response with Method IsOtherResponse
			-- Response with Method IsEmpty
			-- Response with MethodIsWrongType
			-- Response with Method IsInvalidCharacter - \n, \t
		-------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.5
			--Description: This test is intended to check when HMI response with Method is missed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_MissingMethodParameter_GENERIC_ERROR"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: Sending response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "messageDataResult":[200]}}')

					end)

					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
			--End test case HMIResponseCheck3.5
			-------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.6
			--Description: This test is intended to check when HMI response with Method is IsNotValidResponse/IsOtherResponse/IsEmpty/IsWrongType/IsInvalidCharacter - \n, \t

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

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
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(_,data)
								--hmi side: Sending response
								self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", Response)

							end)

							--mobile side: expect the response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:Timeout(13000)

						end
				end

			--End test case HMIResponseCheck3.6
			-----------------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------------
		--End check for Parameter 3: Method
		-----------------------------------------------------------------------------------------------

		----------------------------------------------------------------------------------------------
		--Parameter 4: Info
		-----------------------------------------------------------------------------------------------
		--Description:
			--Response with Info IsMissed
			--Response with Info IsValidResponse
			--Response with Info IsNotValidResponse
			--Response with Info IsOtherResponse
			--Response with Info IsEmpty
			--Response with Info IsWrongType
			--Response with Info IsInvalidCharacter - \n, \t
		-------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.7
			--Description: This test is intended to check when HMI response with Info is missed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL reponds SUCCESS to mobile app

				Test[APIName.."_Response_info_IsMissed_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

			--End test case HMIResponseCheck3.7
			-----------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.8
			--Description: This test is intended to check when HMI reponds SendError with Info is missed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_info_IsMissed_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:ValidIf (function(_,data)
									if data.payload.info then
										commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
										return false
									else
										return true
									end
								end)
				end

				--End test case HMIResponseCheck3.8
				-----------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.9
				--Description: This test is intended to check when HMI reponds with Info is lower/upper bound
				--or respond SendError with Info is lower/upper bound

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955

					local testData = {
						{value = "a", name = "IsLowerBound"},
						{value = commonFunctions:createString(1000), name = "IsUpperBound"}}

					--Verification criteria: SDL reponds SUCCESS to mobile app
					for i =1, #testData do

						Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse(Request)
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

						--Verification criteria: SDL reponds GENERIC_ERROR to mobile app
						Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse(Request)
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

				--Begin test case HMIResponseCheck3.9
				----------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.10
				--Description: This test is intended to check when HMI reponds with Info is out of upper bound
				--or respond SendError with Info is out of upper bound

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955
					--Verification criteria: SDL reponds SUCCESS to mobile app

					Test[APIName.."_Response_info_IsOutUpperBound_SendResponse"] = function(self)

						local infoMaxLength = commonFunctions:createString(1000)

						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						local Response = self:createResponse(Request)
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
						:Do(function(_,data)
							--hmi side: sending the response
							Response["info"] = infoMaxLength .. "1"
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
						end)

						--mobile side: expect the response
						local ExpectedResponse = commonFunctions:cloneTable(Response)
						ExpectedResponse["success"] = true
						ExpectedResponse["resultCode"] = "SUCCESS"
						ExpectedResponse["info"] = infoMaxLength

						EXPECT_RESPONSE(cid, ExpectedResponse)

					end
					-----------------------------------------------------------------------------------------

					--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

					Test[APIName.."_Response_info_IsOutUpperBound_SendError"] = function(self)

						local infoMaxLength = commonFunctions:createString(1000)

						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
						:Do(function(_,data)
							--hmi side: sending the response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
						end)

						--mobile side: expect the response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})

					end

				--End test case HMIResponseCheck3.10
				-----------------------------------------------------------------------------------------

				--Begin test case HMIResponseCheck3.11
				--Description: This test is intended to check when HMI reponds with Info is IsEmpty/IsOutLowerBound/IsWrongType/InvalidCharacter - \n, \t, only spaces
				--or respond SendError Info is IsEmpty/IsOutLowerBound/IsWrongType/InvalidCharacter - \n, \t, only spaces

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642, APPLINK-14765 and SDLAQ-CRS-2955

					local testData = {
						{value = "", name = "IsEmpty_IsOutLowerBound"},
						{value = 123, name = "IsWrongType"},
						{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
						{value = "a\tb", name = "IsInvalidCharacter_Tab"},
						{value = " ", name = "IsInvalidCharacter_OnlySpaces"}}


					for i =1, #testData do

						--Verification criteria: SDL reponds SUCCESS to mobile app
						Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse(Request)
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(_,data)
								--hmi side: sending the response
								Response["info"] = testData[i].value
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
							end)

							--mobile side: expect the response
							local ExpectedResponse = commonFunctions:cloneTable(Response)
							ExpectedResponse["success"] = true
							ExpectedResponse["resultCode"] = "SUCCESS"
							ExpectedResponse["info"] = nil
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

						--Verification criteria: SDL reponds GENERIC_ERROR to mobile app
						Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(_,data)
								--hmi side: sending the response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
							end)

							--mobile side: expect the response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
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

						end
			-----------------------------------------------------------------------------------------
			--End test case HMIResponseCheck3.11

		----------------------------------------------------------------------------------------------
		--End check for Parameter 4: Info
		-----------------------------------------------------------------------------------------------

		----------------------------------------------------------------------------------------------
		--Parameter 5: correlationID
		-----------------------------------------------------------------------------------------------
		--Description:
			--Response with correlationID IsMissed
			--Response with correlationID IsWrongType
			--Response with correlationID IsNonexistent
			--Response with correlationID IsNegative
			--Response with correlationID IsNull
		-------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.12
			--Description: This test is intended to check when HMI response with correlationID IsMissed or response SendError with correlationId IsMissed

				--Requirement id in JAMA/or Jira ID: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"messageDataResult":[200],"method":"VehicleInfo.DiagnosticMessage", "code": 0}}')
					end)

					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
				-----------------------------------------------------------------------------------------

				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app when SDL received response SendError with correlationId IsMissed from HMI
				Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.DiagnosticMessage"},"code":22,"message":"The unknown issue occurred"}}')

					end)

					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end

			--End test case HMIResponseCheck3.12
			-----------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.13
			--Description: This test is intended to check when HMI response with correlationID IsNonexistent or response SendError with correlationId IsNonexistent

				--Requirement id in JAMA/or Jira ID: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_CorrelationID_IsNonexistent_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"code":0, "method":"VehicleInfo.DiagnosticMessage","messageDataResult":[200]}}')
					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
				-----------------------------------------------------------------------------------------

				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app when SDL received response SendError with correlationId IsNonexistent from HMI

				Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.DiagnosticMessage"},"code":22,"message":"The unknown issue occurred"}}')

						self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.DiagnosticMessage"},"code":22,"message":"The unknown issue occurred"}}')

					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
				-----------------------------------------------------------------------------------------
			--Begin test case HMIResponseCheck3.13
			----------------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.14
			--Description: This test is intended to check when HMI response with correlationID IsWrongType or response SendError with correlationId IsWrongType

				--Requirement id in JAMA/or Jira ID: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_CorrelationID_IsWrongType_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app when SDL received response SendError with correlationId IsWrongType from HMI

				Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response

						  self.hmiConnection:SendError(tostring(data.id), data.method, "SUCCESS", "error message")

					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
			    -----------------------------------------------------------------------------------------

			--End test case HMIResponseCheck3.14
			----------------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.15
			--Description: This test is intended to check when HMI response with correlationID IsNegative or response SendError with correlationId IsNegative

				--Requirement id in JAMA/or Jira ID: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_CorrelationID_IsNegative_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app when SDL received response SendError with correlationId IsNegative from HMI

				Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")

					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
			-----------------------------------------------------------------------------------------
			--End test case HMIResponseCheck3.15
			----------------------------------------------------------------------------------------------------

			--Begin test case HMIResponseCheck3.16
			--Description: This test is intended to check when HMI response with correlationID IsNull or response SendError with correlationId IsNull

				--Requirement id in JAMA/or Jira ID: Update according to answer on APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app

				Test[APIName.."_Response_CorrelationID_IsNull_SendResponse"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VehicleInfo.DiagnosticMessage","code":0, "dtc":["line 0","line 1","line 2"],"ecuHeader":2}}')
						  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","result":{"code":0, "method":"VehicleInfo.DiagnosticMessage","messageDataResult":[200]}}')

					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
				-----------------------------------------------------------------------------------------

				--Verification criteria: SDL reponds GENERIC_ERROR to mobile app when SDL received response SendError with correlationId IsNull from HMI

				Test[APIName.."_Response_CorrelationID_IsNull_SendError"] = function(self)

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)


					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.DiagnosticMessage"},"code":22,"message":"The unknown issue occurred"}}')
						self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","error":{"data":{"method":"VehicleInfo.DiagnosticMessage"},"code":22,"message":"The unknown issue occurred"}}')

					end)


					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(13000)

				end
				-----------------------------------------------------------------------------------------

			--End test case HMIResponseCheck3.16

	--End Test suit SpecialRequestCheck
---------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

	--Begin test suit SpecialResponseCheck
	--Description:
		--InvalidJsonSyntax
		--InvalidStructure
		--FakeParams
		--FakeParameterIsFromAnotherAPI
		--No response
		--Several Different Responses To One Request
		--Several Same Responses To One Request
		--MissedmandatoryParameters: Already checked in Block III
		--MissedAllPArameters: Already checked in Block III

		--Write TEST_BLOCK_I_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite IV: Check special cases of HMI response ***************")

			--Begin test case SpecialResponseCheck4.1
			--Description: This test is intended to check when response from HMI with invalidJson

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2955
				--Verification criteria: SDL sends GENERIC_ERROR to mobile app

				function Test:DiagnosticMessage_Response_IsInvalidJson()

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						--":" is changed by ";" after {"id"
						  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"VehicleInfo.DiagnosticMessage","messageDataResult":[200]}}')
					end)

					--mobile side: expect the response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)

				end
			--End test case SpecialResponseCheck4.1
			--------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.2
			--Description: This test is intended to check when response from HMI with invalidStructure

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL sends INVALID_DATA to mobile app

				function Test:DiagnosticMessage_Response_IsInvalidStructure()

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
					:Do(function(_,data)
						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"VehicleInfo.DiagnosticMessage","messageDataResult":[200]}}')
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"VehicleInfo.DiagnosticMessage"}}')
					end)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
					:Timeout(12000)

				end
			--End test case SpecialResponseCheck4.2
			--------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.3
			--Description: This test is intended to check when response from HMI with fake params from other API

				--Requirement id in JAMA/or Jira ID: APPLINK-14765
				--Verification criteria: SDL sends SUCCESS to mobile app

				function Test:DiagnosticMessage_Response_FakeParams_IsFromAnotherAPI()

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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

			--End test case SpecialResponseCheck4.3
			--------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.4
			--Description: This test is intended to check when response from HMI with fake params not from other API

				--Requirement id in JAMA/or Jira ID: APPLINK-14765
				--Verification criteria: SDL sends SUCCESS to mobile app

				function Test:DiagnosticMessage_Response_FakeParams_IsNotFromAnyAPI()

					--mobile side: sending the request
					local Request = self:createRequest()
					local cid = self.mobileSession:SendRPC(APIName, Request)

					--hmi side: expect the request
					local Response = self:createResponse(Request)
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
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
			--End test case SpecialResponseCheck4.4
			--------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.5
		    --Description: This test is intended to check when no response from HMI

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2955
				--Verification criteria: SDL sends GENERIC_ERROR to mobile app

				Test[APIName.."_NoResponse"] = function(self)

						--mobile side: sending the request
						local Request = self:createRequest()
						local cid = self.mobileSession:SendRPC(APIName, Request)

						--hmi side: expect the request
						EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)


						--mobile side: expect the response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

				end

			--End test case SpecialResponseCheck4.5
			------------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.6
		    --Description: This test is intended to check when several diffirent responses to one request from HMI

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL sends INVALID_DATA to mobile app

				Test[APIName.."_SeveralDifferentResponsesToOneRequest"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse(Request)
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(exp,data)
								--hmi side: sending the response
								self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", Response)
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)

							end)

							--mobile side: expect response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

				end
			--End test case SpecialResponseCheck4.6
		    -------------------------------------------------------------------------------------------------

			--Begin test case SpecialResponseCheck4.7
		    --Description: This test is intended to check when several diffirent responses to one request from HMI

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL sends INVALID_DATA to mobile app

				Test[APIName.."_SeveralSameResponsesToOneRequest"] = function(self)

							--mobile side: sending the request
							local Request = self:createRequest()
							local cid = self.mobileSession:SendRPC(APIName, Request)

							--hmi side: expect the request
							local Response = self:createResponse(Request)
							EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", Request)
							:Do(function(exp,data)
								--hmi side: sending the response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)

							end)

							--mobile side: expect response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

				end
			--End test case SpecialResponseCheck4.7

	--End Test suit SpecialRequestCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes-------------------------------------
---------------------------------------------------------------------------------------------
--Begin test suit AllResultCodeCheck
	--Description:
	--SUCCESS: Already checked by several TCs in the TEST BLOCK I
	--INVALID_DATA:	Already checked by HMIResponseCheck3.3, CommonRequestCheck.6...
	--OUT_OF_MEMORY: ToDo: Wait until requirement is clarified
	--TOO_MANY_PENDING_REQUESTS: Check in the separated TC
	--GENERIC_ERROR: Already checked by HMIResponseCheck3.3, HMIResponseCheck3.1...
	--APPLICATION_NOT_REGISTERED
	--REJECTED: Already checked by TC CommonRequestCheck.12

	--Write TEST_BLOCK_I_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite VI: Check result codes ******************************")


		    --Description: This test is intended to check sending request if app is not registered

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2642
				--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED to mobile app
				commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--End Test suit AllResultCodeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Begin Check with Different HMIStatus
	--Description: Check when HMILevel is
		--LIMITED
		--NONE
		--BACKGROUND
	--Write TEST_BLOCK_I_Begin to ATF log
		commonFunctions:newTestCasesGroup("****************************** Test suite VII: Check with Different HMIStatus ******************")
			--Begin test case Different HMIStatus7.1
			--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level

			commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")

			--End test case Different HMIStatus7.1

	--End Test suit Different HMIStatus


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test

