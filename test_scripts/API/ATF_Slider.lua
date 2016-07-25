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
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arrayStringParameter = require('user_modules/shared_testcases/testCasesForArrayStringParameter')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
require('user_modules/AppTypes')


---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "Slider" -- set request name
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name

--Debug = {"ecuName"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.

--Process different audio states for media and non-media application
local audibleState

if commonFunctions:isMediaApp() then
	audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------



--Verify OnHMIStatus notification
function Test:expectOnHMIStatusWithAudioStateChanged(HMILevel, timeout, times)

--valid values for times parameter:
		--nil => times = 2
		--4: for duplicate request

	if HMILevel == nil then  HMILevel = "FULL" end
	if timeout == nil then timeout = 10000 end
	if times == nil then times = 2 end


	--mobile side: OnHMIStatus notification
	EXPECT_NOTIFICATION("OnHMIStatus",
							{systemContext = "HMI_OBSCURED", hmiLevel = HMILevel, audioStreamingState = audibleState},
							{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = audibleState})
	:Times(times)
	:Timeout(timeout)

end


--Create default request
function Test:createRequest()

	return 	{
				numTicks = 26,
				position = 1,
				sliderHeader ="sliderHeader"
			}

end


--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)

	local UIRequest = commonFunctions:cloneTable(Request)

	--process for default value of timeout parameter
	if UIRequest["timeout"]  == nil then
		UIRequest["timeout"] =  10000
	end

	return UIRequest

end
---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request, HMILevel)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	if Request.timeout == 1000 then
		itimeout = 500
	else
		itimeout = 1000
	end


	--hmi side: expect the request
	local UIRequest = self:createUIParameters(Request)
	EXPECT_HMICALL("UI.Slider", UIRequest)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

		local function sendReponse()

			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(sendReponse, itimeout)

	end)

	--mobile side: expect OnHashChange notification
	self:expectOnHMIStatusWithAudioStateChanged(HMILevel)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })

end


--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response, HMILevel)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect UI.Slider request
	local UIRequest = self:createUIParameters(Request)
	EXPECT_HMICALL("UI.Slider", UIRequest)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

		local function sendReponse()

			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(sendReponse, 1000)
	end)

	--mobile side: expect OnHashChange notification
	self:expectOnHMIStatusWithAudioStateChanged(HMILevel)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)

end

--TODO: Update after resolving APPLINK-15509
--This function is used to send default request and response with specific invalid data and verify INVALIDL_DATA resultCode
function Test:verify_GENERIC_ERROR_Response_Case(Response)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect UI.Slider request
	local UIRequest = self:createUIParameters(Request)
	EXPECT_HMICALL("UI.Slider", UIRequest)

	:Do(function(_,data)
		--HMI sends UI.OnSystemContext
		local function sendReponse()

			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)

		end
		RUN_AFTER(sendReponse, 1000)

	end)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})

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
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For Normal cases of Mobile request")

--Note: Completed this part

--Requirement id in JAMA:
	--SDLAQ-CRS-117 (Slider_Request_v2_0)
	--SDLAQ-CRS-118 (Slider_Response_v2_0)
	--SDLAQ-CRS-661 (SUCCESS)
	--SDLAQ-CRS-653 (INVALID_DATA)

--Verification criteria: Creates a full screen or pop-up overlay (depending on platform) with a single user controlled slider.
-----------------------------------------------------------------------------------------------

--List of parameters:
--1. numTicks: type=Integer, minvalue="2" maxvalue="26" mandatory="true"
--2. position: type=Integer, minvalue="1" maxvalue="26" mandatory="true"
--3. sliderHeader: type=String, maxlength="500" mandatory="true"
--4. sliderFooter: type=String, maxlength="500"  minsize="1" maxsize="26" array="true" mandatory="false"
--5. timeout: type=Integer, minvalue="1000" maxvalue="65535" defvalue="10000" mandatory="false"
-----------------------------------------------------------------------------------------------

--Common Test cases check all parameters with lower bound and upper bound
--1. Positive request
--1. Mandatory only
--2. All parameters are lower bound
--3. All parameters are upper bound
--4. Verify specific cases:
	--Slider_position_Over_numTicks_INVALID_DATA
	--Slider_Footer_Less_NumTicks_INVALID_DATA
	--Slider_Footer_More_NumTicks_INVALID_DATA


	Test["Slider_PositiveRequest_SUCCESS"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 3,
			position = 2,
			sliderHeader ="sliderHeader",
			sliderFooter = {"1", "2", "3"},
			timeout = 5000
		}

		self:verify_SUCCESS_Case(Request)

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_OnlyMandatoryParameters_SUCCESS"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 7,
			position = 6,
			sliderHeader ="sliderHeader"
		}

		self:verify_SUCCESS_Case(Request)

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_AllParametersLowerBound_SUCCESS"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 2,
			position = 1,
			sliderHeader ="sliderHeader",
			sliderFooter = {"a","a"},
			timeout = 1000
		}

		self:verify_SUCCESS_Case(Request)

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_AllParametersUpperBound_SUCCESS"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 26,
			position = 26,
			sliderHeader = commonFunctions:createString(500),
			sliderFooter = commonFunctions:createArrayString(26, 500),
			timeout = 65535
		}

		self:verify_SUCCESS_Case(Request)

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_position_Over_numTicks_INVALID_DATA"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 5,
			position = 6,
			sliderHeader ="sliderHeader",
			timeout = 3000
		}

		commonFunctions:verify_Unsuccess_Case(self, Request, "INVALID_DATA")

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_Footer_Less_NumTicks_INVALID_DATA"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 3,
			position = 2,
			sliderHeader ="sliderHeader",
			sliderFooter =
			{
				"Footer1",
				"Footer2"
			},
			timeout = 3000
		}

		commonFunctions:verify_Unsuccess_Case(self, Request, "INVALID_DATA")

	end
	-----------------------------------------------------------------------------------------

	Test["Slider_Footer_More_NumTicks_INVALID_DATA"] = function(self)

		--mobile side: request parameters
		local Request =
		{
			numTicks = 3,
			position = 2,
			sliderHeader ="sliderHeader",
			sliderFooter =
			{
				"Footer1",
				"Footer2",
				"Footer3",
				"Footer4"
			},
			timeout = 3000
		}

		commonFunctions:verify_Unsuccess_Case(self, Request, "INVALID_DATA")

	end
	-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
--Parameter 1: numTicks: type=Integer, minvalue="2" maxvalue="26" mandatory="true"
--Parameter 2: position: type=Integer, minvalue="1" maxvalue="26" mandatory="true"
--Parameter 5: timeout: type=Integer, minvalue="1000" maxvalue="65535" defvalue="10000" mandatory="false"
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------

local Request = Test:createRequest()
integerParameter:verify_Integer_Parameter(Request, {"numTicks"}, {2, 26}, true)
integerParameter:verify_Integer_Parameter(Request, {"position"}, {1, 26}, true)
integerParameter:verify_Integer_Parameter(Request, {"timeout"}, {1000, 65535}, false)



-----------------------------------------------------------------------------------------------
--Parameter 3: sliderHeader: type=String, maxlength="500" mandatory="true"
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound
	--7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------

local Request = Test:createRequest()
stringParameter:verify_String_Parameter(Request, {"sliderHeader"}, {1, 500}, true)


-----------------------------------------------------------------------------------------------
--Parameter 4: sliderFooter: type=String, maxlength="500"  minsize="1" maxsize="26" array="true" mandatory="false"
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound

-----------------------------------------------------------------------------------------------
local Request = Test:createRequest()
arrayStringParameter:verify_Array_String_Parameter_Only(Request, {"sliderFooter"}, {1, 26},  {1, 500}, false)

--Verify an element in a string array. It includes test case 2-7 of string parameter
--2. IsWrongType
--3. IsLowerBound/IsEmpty
--4. IsOutLowerBound/IsEmpty
--5. IsUpperBound
--6. IsOutUpperBound
--7. IsInvalidCharacters
local Request = Test:createRequest()
Request["sliderFooter"] = {}
stringParameter:verify_String_Element_InArray_Parameter(Request, {"sliderFooter", 1}, {1, 500})



----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Begin Test case SpecialRequestChecks
--Description: Check special requests

	--Requirement id in JAMA:
		--SDLAQ-CRS-117 (Slider_Request_v2_0)
		--SDLAQ-CRS-118 (Slider_Response_v2_0)
		--SDLAQ-CRS-661 (SUCCESS)
		--SDLAQ-CRS-653 (INVALID_DATA)

	--Verification criteria: Slider request  notifies the user via UI engine with some information that the app provides to HMI. After UI has prompted, the response with SUCCESS resultCode is returned to mobile app.

local function SpecialRequestChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForMobileNegativeCases")

	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON

		--Requirement id in JAMA: SDLAQ-CRS-653
		--Verification criteria: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.

		--local Payload = '{"numTicks":26, "position":1, "sliderHeader":"a"}' -- valid JSON
		  local Payload = '{"numTicks";26, "position":1, "sliderHeader":"a"}'
		commonTestCases:VerifyInvalidJsonRequest(26, Payload)	--SliderID = 26

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: CorrelationId check( duplicate value)

		function Test:Slider_CorrelationID_IsDuplicated()

			--mobile side: sending Slider request
			local Request =
			{
				numTicks = 26,
				position = 1,
				sliderHeader = "a"
			}
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--request from mobile side
			local msg =
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 26,
			  rpcCorrelationId = cid,
			  payload          = '{"numTicks":26, "position":1, "sliderHeader":"a"}'
			}

			--hmi side: expect UI.Slider request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(exp,data)


				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()
					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

				--mobile: sends the second request
				local function sendTheSeondRequest()
					self.mobileSession:Send(msg)
				end

				if exp.occurences == 1 then
					RUN_AFTER(sendTheSeondRequest, 3000)
				end

			end)
			:Times(2)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHMIStatus",
									{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
									{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState},
									{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
									{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState})
			:Times(4)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
			:Times(2)

		end

	--End Test case NegativeRequestCheck.2


	--Begin Test case NegativeRequestCheck.3
		--Description: Fake parameters check

			--Requirement id in JAMA: APPLINK-14765
			--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

			--Begin Test case NegativeRequestCheck.3.1
			--Description: Fake parameters is not from any API

			function Test:Slider_FakeParams_IsNotFromAnyAPI_SUCCESS()

				--mobile side: sending Slider request
				local FakeRequest  =
				{
					fakeParam = "abc",
					numTicks = 26,
					position = 1,
					sliderHeader = "a"
				}

				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)

				local Request  =
				{
					numTicks = 26,
					position = 1,
					sliderHeader = "a"
				}

				--hmi side: expect the request
				local UIRequest = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Slider", UIRequest)
				:ValidIf(function(_,data)
					if data.params.fakeParam then
							Print(" SDL re-sends fakeParam parameters to HMI")
							return false
					else
						return true
					end
				end)
				:Do(function(_,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

					local function sendReponse()

						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end
					RUN_AFTER(sendReponse, 1000)

				end)

				--mobile side: expect OnHashChange notification
				self:expectOnHMIStatusWithAudioStateChanged()

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })

			end

			--End Test case NegativeRequestCheck.3.1
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3.2
			--Description: Fake parameters is from another API

			function Test:Slider_FakeParams_ParameterIsFromAnotherAPI_SUCCESS()

				--mobile side: sending Slider request
				local FakeRequest  =
				{
					syncFileName = "abc",
					numTicks = 26,
					position = 1,
					sliderHeader = "a"
				}

				local Request  =
				{
					numTicks = 26,
					position = 1,
					sliderHeader = "a"
				}

				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)


				--hmi side: expect the request
				local UIRequest = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Slider", UIRequest)
				:ValidIf(function(_,data)
					if data.params.syncFileName then
							Print(" SDL re-sends fakeParam parameters to HMI")
							return false
					else
						return true
					end
				end)
				:Do(function(_,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

					local function sendReponse()

						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end
					RUN_AFTER(sendReponse, 1000)
				end)

				--mobile side: expect OnHashChange notification
				self:expectOnHMIStatusWithAudioStateChanged()

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })

			end

			--End Test case NegativeRequestCheck.3.2
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3.3
			--Description: Fake parameters and invalid request

			function Test:Slider_FakeParamsAndInvalidRequest_GENERIC_ERROR()

				--mobile side: sending Slider request
				local FakeRequest  =
				{
					fakeParam = "abc",
					numTicks = 26,
					sliderHeader = "a"
				}

				local cid = self.mobileSession:SendRPC(APIName, FakeRequest)


				--hmi side: expect the request
				EXPECT_HMICALL("UI.Slider")
				:Times(0)

				--mobile side: expect OnHashChange notification
				self:expectOnHMIStatusWithAudioStateChanged(nil, nil, 0)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

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

--Note: Completed this part

--Requirement id in JAMA:
	--SDLAQ-CRS-117 (Slider_Request_v2_0)
	--SDLAQ-CRS-118 (Slider_Response_v2_0)
	--SDLAQ-CRS-661 (SUCCESS)
	--SDLAQ-CRS-653 (INVALID_DATA)
	--SDLAQ-CRS-654 (OUT_OF_MEMORY)
	--SDLAQ-CRS-655 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-656 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-657 (REJECTED)
	--SDLAQ-CRS-658 (ABORTED)
	--SDLAQ-CRS-659 (GENERIC_ERROR)
	--SDLAQ-CRS-660 (DISALLOWED)
	--SDLAQ-CRS-1032 (UNSUPPORTED_RESOURCE)
	--SDLAQ-CRS-2904 (TIMED_OUT)

	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI (INVALID response => GENERIC_ERROR resultCode)
	--APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

--Verification Criteria:
	--The response contains 3 mandatory parameters "success", "resultCode" and current "sliderPosition" value returned. "info" is sent if there is any additional information about the resultCode.

-----------------------------------------------------------------------------------------------
--List of parameters:
--Parameter 1: resultCode: type=String Enumeration(Integer), mandatory="true"
--Parameter 2: method: type=String, mandatory="true" (main test case: method is correct or not)
--Parameter 3: info: type=String, minlength="1" maxlength="10" mandatory="false"
--Parameter 4: correlationID: type=Integer, mandatory="true"
--Parameter 5: sliderPosition: type=Integer, minvalue="1" maxvalue="26" mandatory="false"

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

local function verify_resultCode_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForResultCodeParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0,"sliderPosition":1}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","sliderPosition":1}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		-- TODO: update after APPLINK-14765 is resolved
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

	end

	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":4,"message":"abc"}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"message":"abc"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		-- TODO: update after APPLINK-14765 is resolved
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

	end
	-----------------------------------------------------------------------------------------

	--SDLAQ-CRS-661 (SUCCESS)
	--SDLAQ-CRS-653 (INVALID_DATA)
	--SDLAQ-CRS-654 (OUT_OF_MEMORY)
	--SDLAQ-CRS-655 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-656 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-657 (REJECTED)
	--SDLAQ-CRS-658 (ABORTED)
	--SDLAQ-CRS-659 (GENERIC_ERROR)
	--SDLAQ-CRS-660 (DISALLOWED)
	--SDLAQ-CRS-1032 (UNSUPPORTED_RESOURCE)
	--SDLAQ-CRS-2904 (TIMED_OUT)

	--2. IsValidValue
	local resultCodes = {
		{resultCode = "SUCCESS", success =  true},
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "ABORTED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "USER_DISALLOWED", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  false},
		{resultCode = "TIMED_OUT", success =  false}
	}

	for i =1, #resultCodes do

		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

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
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			-- TODO: update after APPLINK-14765 is resolved
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_resultCode_" .. testData[i].name .."_GENERIC_ERROR_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, testData[i].value)

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			-- TODO: update after APPLINK-14765 is resolved
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
	--7. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

--ToDo: Update according to APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_method_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForMethodParameter")


	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end

	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":4,"message":"abc"}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{},"code":4,"message":"abc"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					  self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

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
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "info")
					  self.hmiConnection:SendError(data.id, Methods[i].method, "REJECTED", "info")

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

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
	--7. InvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_info_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForInfoParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_info_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)


		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		-- TODO: Update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
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
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})

		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------

--[[ TODO: uncomment after resolvin APPLINK-14551
	--4. IsOutUpperBound
	Test[APIName.."_Response_info_IsOutUpperBound_SendResponse"] = function(self)

		local infoMaxLength = commonFunctions:createString(1000)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMaxLength .. "1"})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_info_IsOutUpperBound_SendError"] = function(self)

		local infoMaxLength = commonFunctions:createString(1000)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)

		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})

	end]]
	-----------------------------------------------------------------------------------------

	-- TODO: update after resolving APPLINK-14551

	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t

	-- local testData = {
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"}}

	-- for i =1, #testData do

	-- 	Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local Request = self:createRequest()
	-- 		local cid = self.mobileSession:SendRPC(APIName, Request)

	-- 		--hmi side: expect the request
	-- 		local UIRequest = self:createUIParameters(Request)
	-- 		EXPECT_HMICALL("UI.Slider", UIRequest)
	-- 		:Do(function(_,data)
	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

	-- 			local function sendReponse()

	-- 				--hmi side: sending the response
	-- 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})

	-- 				--HMI sends UI.OnSystemContext
	-- 				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 			end
	-- 			RUN_AFTER(sendReponse, 1000)

	-- 		end)

	-- 		--mobile side: expect OnHashChange notification
	-- 		self:expectOnHMIStatusWithAudioStateChanged()

	-- 		--mobile side: expect the response
	-- 		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
	-- 		local UIRequest = self:createUIParameters(Request)
	-- 		EXPECT_HMICALL("UI.Slider", UIRequest)
	-- 		:Do(function(_,data)
	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

	-- 			local function sendReponse()

	-- 				--hmi side: sending the response
	-- 				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)

	-- 				--HMI sends UI.OnSystemContext
	-- 				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 			end
	-- 			RUN_AFTER(sendReponse, 1000)

	-- 		end)

	-- 		--mobile side: expect OnHashChange notification
	-- 		self:expectOnHMIStatusWithAudioStateChanged()

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
--ToDo: Update according to APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.Slider", "code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Slider", Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)


		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)


		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Slider", Request)


		--hmi side: expect the request
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {info = "info message"})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(tostring(data.id), data.method, "REJECTED", "error message")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {info = "info message"})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')
				  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

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
		local UIRequest = self:createUIParameters(Request)
		EXPECT_HMICALL("UI.Slider", UIRequest)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function sendReponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')
				  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","error":{"data":{"method":"UI.Slider"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(sendReponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		self:expectOnHMIStatusWithAudioStateChanged()

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

end

verify_correlationID_parameter()



-----------------------------------------------------------------------------------------------
--Parameter 5: sliderPosition: type=Integer, minvalue="1" maxvalue="26" mandatory="false"
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------
local Response = {}
integerParameterInResponse:verify_Integer_Parameter(Response, {"sliderPosition"}, {1, 26}, false)







----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------


--Begin Test case SpecialResponseChecks
--Description: Check all negative response cases

	--Requirement id in JAMA:
		--SDLAQ-CRS-118 (Slider_Response_v2_0)
		--SDLAQ-CRS-659 (GENERIC_ERROR)

--ToDo: Update according to APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function SpecialResponseChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Special Response Checks")
	----------------------------------------------------------------------------------------------


	--Begin Test case NegativeResponseCheck.1
	--Description: Invalid JSON


		--Requirement id in JAMA: SDLAQ-CRS-118
		--Verification criteria:

		--[[ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

		function Test:Slider_Response_IsInvalidJson()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending the response
					--":" is changed by ";" after {"id"
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0,"sliderPosition":1}}')
					self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0,"sliderPosition":1}}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)

		end
		]]
	--End Test case NegativeResponseCheck.1



	--Begin Test case NegativeResponseCheck.2
	--Description: Check processing response with fake parameters

		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter

		--Begin Test case NegativeResponseCheck.2.1
		--Description: Parameter is not from API

		function Test:Slider_Response_FakeParams_IsNotFromAnyAPI_SUCCESS()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{sliderPosition = 1, fake = 123})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)


			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1})
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
		--Description: Parameter is from another API

		function Test:Slider_Response_FakeParams_IsFromAnotherAPI()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending response
					 self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1, IsReady = true})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1})
			:ValidIf (function(_,data)
				if data.payload.IsReady then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case NegativeResponseCheck.2.2

		--Begin Test case NegativeResponseCheck.2.3
		--Description: Fake parameter and invalid response

		function Test:Slider_Response_FakeParamsAndInvalidResponse()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0,"sliderPosition":1}}')
					  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","fake":0,"sliderPosition":1}}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case NegativeResponseCheck.2.3

	--End Test case NegativeResponseCheck.2


	--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters
	--Begin NegativeResponseCheck.5
	--Description: Check processing response without all parameters

		function Test:Slider_Response_IsMissedAllPArameters()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)


			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending UI.Slider response
					self.hmiConnection:Send('{}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end

	--End NegativeResponseCheck.5
]]

	--Begin Test case NegativeResponseCheck.6
	--Description: Request without responses from HMI

		--Requirement id in JAMA: SDLAQ-CRS-636
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.

		function Test:Slider_NoResponse()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending UI.Slider response
					--Does not send response

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)

		end

	--End NegativeResponseCheck.6


	--Begin Test case NegativeResponseCheck.7
	--Description: Invalid structure of response



		--Requirement id in JAMA: SDLAQ-CRS-118
		--Verification criteria: The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode". "info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available.

--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters

		function Test:Slider_Response_IsInvalidStructure()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function sendReponse()

					--hmi side: sending response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0,"sliderPosition":1}}')
					  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"method":"UI.Slider","sliderPosition":1}}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(sendReponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			:Timeout(12000)

		end
		]]
	--End Test case NegativeResponseCheck.7


	--Begin Test case NegativeResponseCheck.8
	--Description: Several response to one request

		--Requirement id in JAMA: SDLAQ-CRS-118

		--Verification criteria: The response contains 3 mandatory parameters "success", "ecuHeader" and "resultCode". "info" is sent if there is any additional information about the resultCode. Array of "dtc" data is returned if available.


		--Begin Test case NegativeResponseCheck.8.1
		--Description: Several response to one request

			function Test:Slider_Response_SeveralResponseToOneRequest()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)

				--hmi side: expect the request
				local UIRequest = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Slider", UIRequest)
				:Do(function(exp,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

					local function sendReponse()

						--hmi side: sending the response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {sliderPosition = 1})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end
					RUN_AFTER(sendReponse, 1000)

				end)

				--mobile side: expect OnHashChange notification
				self:expectOnHMIStatusWithAudioStateChanged()

				--mobile side: expect response
				local ExpectedResponse = commonFunctions:cloneTable(Response)
				ExpectedResponse["success"] = true
				ExpectedResponse["resultCode"] = "SUCCESS"
				EXPECT_RESPONSE(cid, ExpectedResponse)

			end

		--End Test case NegativeResponseCheck.8.1



		--Begin Test case NegativeResponseCheck.8.2
		--Description: Several response to one request

			function Test:Slider_Response_WithConstractionsOfResultCodes()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)

				--hmi side: expect the request
				local UIRequest = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.Slider", UIRequest)
				:Do(function(exp,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

					local function sendReponse()

						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0}}')
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

						--response both SUCCESS and GENERIC_ERROR resultCodes
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Slider","code":0},"error":{"data":{"method":"UI.ScrollableMessage"},"code":5,"message":"The unknown issue occurred"}}')

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end
					RUN_AFTER(sendReponse, 1000)

				end)

				--mobile side: expect OnHashChange notification
				self:expectOnHMIStatusWithAudioStateChanged()

				--mobile side: expect response
				-- TODO: update after resolving APPLINK-14765
				-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(13000)

			end

		--End Test case NegativeResponseCheck.8.2
		-----------------------------------------------------------------------------------------

	--End Test case NegativeResponseCheck.8

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
		--SDLAQ-CRS-661 (SUCCESS)
		--SDLAQ-CRS-653 (INVALID_DATA)
		--SDLAQ-CRS-654 (OUT_OF_MEMORY)
		--SDLAQ-CRS-655 (TOO_MANY_PENDING_REQUESTS)
		--SDLAQ-CRS-656 (APPLICATION_NOT_REGISTERED)
		--SDLAQ-CRS-657 (REJECTED)
		--SDLAQ-CRS-658 (ABORTED)
		--SDLAQ-CRS-659 (GENERIC_ERROR)
		--SDLAQ-CRS-660 (DISALLOWED)
		--SDLAQ-CRS-1032 (UNSUPPORTED_RESOURCE)
		--SDLAQ-CRS-2904 (TIMED_OUT)


local function ResultCodeChecks()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite: resultCodes Checks")
	----------------------------------------------------------------------------------------------

	--SUCCESS: Covered by many test cases.
	--INVALID_DATA: Covered by many test cases.
	--OUT_OF_MEMORY: ToDo: Wait until requirement is clarified
	--TOO_MANY_PENDING_REQUESTS: It is moved to other script.
	--GENERIC_ERROR: Covered by test case Slider_NoResponse
	--REJECTED, ABORTED, UNSUPPORTED_RESOURCE, TIMED_OUT: Covered by test case resultCode_IsValidValue
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: SDLAQ-CRS-656
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--End Test case ResultCodeChecks.1
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED

		--Requirement id in JAMA: SDLAQ-CRS-660
		--Verification criteria:
			--1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
			--2. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.
			--SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.

		--[[TODO debug after resolving APPLINK-13101
		--Begin Test case ResultCodeChecks.2.1
		--Description: 1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.

			policyTable:checkPolicyWhenAPIIsNotExist()

		--End Test case ResultCodeChecks.2.1


		--Begin Test case ResultCodeChecks.2.2
		--Description:
			--SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.
			--SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.

			policyTable:checkPolicyWhenUserDisallowed({"FULL"})
			]]
		--End Test case ResultCodeChecks.2.2

	--End Test case ResultCodeChecks.2

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

	--List of test cases covered by others:
	----------------------------------------------------------------------------------------------
		--TC_Slider_01: SDLAQ-TC-39: Call Slider request from mobile app on HMI and close it on HMI (SUCCESS resultCode and sliderPosition is in response).
			-->Covered by test case lower bound and upper bound of sliderPosition.
		--TC_Slider_02: SDLAQ-TC-40: Call Slider request from mobile app on HMI and close it by click on Back button on UI (ABORTED response code).
			-->Covered by test case resultCode_IsValidValue ABORTED
		--TC_Slider_04: SDLAQ-TC-138: Call Slider request from mobile app on HMI with timeout min value=1000.
			-->Covered by test case timeout IsLowerBound.
		--TC_Slider_06: SDLAQ-TC-247: Checking Text footer displaying. It is test case to check HMI.
			-->It is out of scope of ATF script.


	--List of new developing test cases:
	----------------------------------------------------------------------------------------------
		--TC_Slider_03: SDLAQ-TC-137: Call Slider request from mobile app on HMI while another Slider is active (REJECTED response code)
		--TC_Slider_05: SDLAQ-TC-246: Checking that the sliding control resets timeout. Scrolling control, waiting 5 seconds, scrolling control again, checking renewing timeout.



	--Begin Test case SequenceChecks.1
	--Description: 	Check for manual test case TC_Slider_03

		--Requirement id in JAMA: SDLAQ-TC-137
		--Verification criteria: Call Slider request from mobile app on HMI while another Slider is active (REJECTED response code)

		function Test:Slider_TC_Slider_03()

			--mobile side: sending the request
			local Request = {
								numTicks = 26,
								position = 1,
								sliderHeader ="Slider header 1",
								sliderFooter = {"Slider Footer 1"},
								timeout = 60000
							}

			local cid = self.mobileSession:SendRPC("Slider", Request)

			local Request2 = {
								numTicks = 10,
								position = 3,
								sliderHeader ="Slider header 2",
								sliderFooter = {"Slider Footer 2"},
								timeout = 15000
							}

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			local UIRequest2 = self:createUIParameters(Request2)
			EXPECT_HMICALL("UI.Slider", UIRequest, UIRequest2)
			:Do(function(_,data)

				if exp.occurences == 1 then
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

					local function sendSecondRequest()
						local cid2 = self.mobileSession:SendRPC("Slider", Request2)

						EXPECT_RESPONSE(cid2, { success = false, resultCode = "REJECTED"})
					end
					RUN_AFTER(sendSecondRequest, 1000)

					local function sendReponse()

						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "TIMED_OUT", {})

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end
					RUN_AFTER(sendReponse, 2000)

				else
					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
				end

			end)
			:Times(2)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged()

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})

	end

	--End Test case SequenceChecks.1
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.2
	--Description: 	Check for manual test case TC_Slider_05

		--Requirement id in JAMA: SDLAQ-TC-246
		--Verification criteria: Checking that the sliding control resets timeout. Scrolling control, waiting 5 seconds, scrolling control again, checking renewing timeout.

		function Test:Slider_TC_Slider_05()

			--mobile side: sending the request
			local Request = {
								numTicks = 26,
								position = 1,
								sliderHeader ="Slider header",
								sliderFooter = {"Slider Footer"},
								timeout = 10000
							}

			local cid = self.mobileSession:SendRPC("Slider", Request)

			--hmi side: expect the request
			local UIRequest = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.Slider", UIRequest)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				local function SendOnResetTimeout()
					self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "UI.Slider"})
				end

				--send UI.OnResetTimeout notification after 1 seconds
				RUN_AFTER(SendOnResetTimeout, 1000)

				--send UI.OnResetTimeout notification after +5 seconds
				RUN_AFTER(SendOnResetTimeout, 6000)


				local function sendReponse()

					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "TIMED_OUT", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				--hmi side: sending response after + 10 seconds
				RUN_AFTER(sendReponse, 15000)

			end)

			--mobile side: expect OnHashChange notification
			self:expectOnHMIStatusWithAudioStateChanged("FULL", 20000, 2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
			:Timeout(20000)

	end

	--End Test case SequenceChecks.2
	-----------------------------------------------------------------------------------------

end

SequenceChecks()

--End Test suit SequenceChecks




----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--SDLAQ-CRS-804: HMI Status Requirement for Slider
--Verification Criteria:
	--SDL rejects Slider request with REJECTED resultCode when current HMI level is NONE or BACKGROUND or LIMITED.
	--SDL doesn't reject Slider request when current HMI is FULL.

--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "DISALLOWED", "DISALLOWED")



---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
