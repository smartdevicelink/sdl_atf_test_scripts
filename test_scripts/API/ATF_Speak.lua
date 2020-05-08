Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local module = require('testbase')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
local arrayTTSChunks = require('user_modules/shared_testcases/testCasesForArrayTTSChunksParameter')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "Speak" -- set request name
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name

local storagePath = config.pathToSDL .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"

--Debug = {"graphic", "value"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------

local function ExpectOnHMIStatusWithAudioStateChanged(self, HMILevel, timeout, times)

--valid values for times parameter:
		--nil => times = 2
		--4: for duplicate request

	if HMILevel == nil then  HMILevel = "FULL" end
	if timeout == nil then timeout = 10000 end
	if times == nil then times = 2 end


	if commonFunctions:isMediaApp() then
		--mobile side: OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "ATTENUATED"},
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "AUDIBLE"})
		:Times(times)
		:Timeout(timeout)
	else
		--mobile side: OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "NOT_AUDIBLE"},
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "NOT_AUDIBLE"})
		:Times(times)
		:Timeout(timeout)
	end

end


--Create default request
function Test:createRequest()

	return 	{
				ttsChunks =
				{
					{
						text ="a",
						type ="TEXT"
					}
				}
			}

end

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request, HMILevel)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC("Speak", Request)

	--hmi side: expect TTS.Speak request
	EXPECT_HMICALL("TTS.Speak", Request)
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		SpeakId = data.id

		local function speakResponse()
			self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

			self.hmiConnection:SendNotification("TTS.Stopped")
		end
		RUN_AFTER(speakResponse, 1000)
	end)


	--mobile side: expect OnHashChange notification
	ExpectOnHMIStatusWithAudioStateChanged(self, HMILevel)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

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
	--TODO: Will be updated after policy flow implementation
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"FULL", "LIMITED"})


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA:
	--SDLAQ-CRS-54 (Speak_Request_v2_0)
	--SDLAQ-CRS-55 (Speak_Response_v2_0)
	--SDLAQ-CRS-505 (INVALID_DATA)
	--SDLAQ-CRS-504 (SUCCESS)

--Verification criteria: Speak request  notifies the user via TTS engine with some information that the app provides to HMI. After TTS has prompted, the response with SUCCESS resultCode is returned to mobile app.

--List of parameters:
--1. ttsChunks: type=TTSChunk, minsize="1", maxsize="100", array="true"
-----------------------------------------------------------------------------------------------

--Common Test cases check all parameters with lower bound and upper bound
--1. All parameters are lower bound
--2. All parameters are upper bound
--Skip these test cases because this API only has one parameter and these test cases will be checked in Lower/Upper bounds of this parameter.


-----------------------------------------------------------------------------------------------
--Parameter 1: ttsChunks: type=TTSChunk, minsize="1", maxsize="100", array="true"
-----------------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound
	--8. Check children parameters:
		--text: minlength="0" maxlength="500" type="String"
		--type: type="SpeechCapabilities": "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE"
-----------------------------------------------------------------------------------------------

local Request = Test:createRequest()
local Boundary = {1, 100}

arrayTTSChunks:verify_TTSChunks_Parameter(Request, {"ttsChunks"}, Boundary, true)




----------------------------------------------------------------------------------------------
----------------------------------------TEST BLOCK II-----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Begin Test case SpecialRequestChecks
--Description: Check special requests

	--Requirement id in JAMA:
		--SDLAQ-CRS-54 (Speak_Request_v2_0)
		--SDLAQ-CRS-55 (Speak_Response_v2_0)
		--SDLAQ-CRS-505 (INVALID_DATA)
		--SDLAQ-CRS-504 (SUCCESS)
		--SDLAQ-CRS-509 (REJECTED)
		--SDLAQ-CRS-510 (ABORTED)
		--SDLAQ-CRS-512 (DISALLOWED)
		--SDLAQ-CRS-1027 (UNSUPPORTED_RESOURCE)
		--SDLAQ-CRS-1030 (WARNINGS)

	--Verification criteria: Speak request  notifies the user via TTS engine with some information that the app provides to HMI. After TTS has prompted, the response with SUCCESS resultCode is returned to mobile app.

local function SpecialRequestChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForMobileNegativeCases")

	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON

		--Requirement id in JAMA: SDLAQ-CRS-505
		--Verification criteria: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.

		--local Payload = '{"ttsChunks":{{"text":"a","type":"TEXT"}}}'  -- valid JSON
		  local Payload = '{"ttsChunks";{{"text":"a","type":"TEXT"}}}'
		commonTestCases:VerifyInvalidJsonRequest(14, Payload)	--SpeakID = 14

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: CorrelationId check( duplicate value)

	--ToDo: Update after fixed ATF defect: APPLINK-13101 ATF sends string in notification with  escaped slash character

		function Test:Speak_CorrelationID_IsDuplicated()

			--mobile side: sending Speak request
			local cid = self.mobileSession:SendRPC("Speak",
			{
				ttsChunks =
				{
					{
						text ="a",
						type ="TEXT"
					}
				}
			})
			self.mobileSession.correlationId = cid
			--request from mobile side
			local msg =
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 14,
			  rpcCorrelationId = self.mobileSession.correlationId,
			  payload          = '{"ttsChunks":[{"text":"a","type":"TEXT"}]}'
			}

			--hmi side: expect TTS.Speak request
			EXPECT_HMICALL("TTS.Speak", { ttsChunks = {{text ="a", type ="TEXT"}}} )
			:Do(function(exp,data)

				local function speakResponse(RequestId)
					self.hmiConnection:SendResponse(RequestId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
				end

				if exp.occurences == 1 then
					self.mobileSession:Send(msg)
					SpeakId1 = data.id
					RUN_AFTER(function() speakResponse(SpeakId1) end, 1000)
				elseif
					exp.occurences == 2 then
					SpeakId2 = data.id
					RUN_AFTER(function() speakResponse(SpeakId2) end, 1000)
				end

				self.hmiConnection:SendNotification("TTS.Started")
			end)
			:Times(2)

			ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", nil, 4)


			--response on mobile side
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Times(2)

		end

	--End Test case NegativeRequestCheck.2


	--Begin Test case NegativeRequestCheck.3
		--Description: Fake parameters check

			--Requirement id in JAMA: APPLINK-4518
			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case NegativeRequestCheck.3.1
			--Description: Fake parameters is not from any API

			function Test:Speak_FakeParams_IsNotFromAnyAPI()

				--mobile side: sending Speak request
				local Request  = 	{
									fakeParam = "abc",
									ttsChunks =
									{
										{
											fakeParam = "abc",
											text ="a",
											type ="TEXT"
										}
									}
								}

				local cid = self.mobileSession:SendRPC("Speak", Request)

				Request.fakeParam = nil
				Request.ttsChunks[1].fakeParam = nil

				--hmi side: expect the request
				EXPECT_HMICALL("TTS.Speak", Request)
				:ValidIf(function(_,data)
					if data.params.fakeParam or
						data.params.ttsChunks[1].fakeParam then
							Print(" SDL re-sends fakeParam parameters to HMI")
							return false
					else
						return true
					end
				end)
				:Do(function(_,data)
					self.hmiConnection:SendNotification("TTS.Started")
					SpeakId = data.id

					local function speakResponse()
						self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

						self.hmiConnection:SendNotification("TTS.Stopped")
					end
					RUN_AFTER(speakResponse, 1000)
				end)


				--mobile side: expect OnHashChange notification
				ExpectOnHMIStatusWithAudioStateChanged(self)


				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

			end

			--End Test case NegativeRequestCheck.3.1
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3.2
			--Description: Fake parameters is not from another API

			function Test:Speak_FakeParams_ParameterIsFromAnotherAPI()

				--mobile side: sending Speak request
				local param  = 	{
									syncFileName = "abc",
									ttsChunks =
									{
										{
											syncFileName = "abc",
											text ="a",
											type ="TEXT"
										}
									}
								}

				local cid = self.mobileSession:SendRPC("Speak", param)

				param.syncFileName = nil
				param.ttsChunks[1].syncFileName = nil


				--hmi side: expect the request
				EXPECT_HMICALL("TTS.Speak", param)
				:ValidIf(function(_,data)
					if data.params.syncFileName or
						data.params.ttsChunks[1].syncFileName then
							Print(" SDL re-sends syncFileName parameters to HMI")
							return false
					else
						return true
					end
				end)
				:Do(function(_,data)
					self.hmiConnection:SendNotification("TTS.Started")
					SpeakId = data.id

					local function speakResponse()
						self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

						self.hmiConnection:SendNotification("TTS.Stopped")
					end
					RUN_AFTER(speakResponse, 1000)
				end)


				--mobile side: expect OnHashChange notification
				ExpectOnHMIStatusWithAudioStateChanged(self)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


			end

			--End Test case NegativeRequestCheck.3.2
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
	--SDLAQ-CRS-55 (Speak_Response)
	--SDLAQ-CRS-505 (INVALID_DATA)
	--SDLAQ-CRS-504 (SUCCESS)
	--SDLAQ-CRS-509 (REJECTED)
	--SDLAQ-CRS-510 (ABORTED)
	--SDLAQ-CRS-512 (DISALLOWED)
	--SDLAQ-CRS-1027 (UNSUPPORTED_RESOURCE)
	--SDLAQ-CRS-1030 (WARNINGS)
	--SDLAQ-CRS-388 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-385 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-384 (OUT_OF_MEMORY)
	--SDLAQ-CRS-391 (GENERIC_ERROR)
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI (INVALID response => GENERIC_ERROR resultCode)
	--APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

--Verification Criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode


--Common Test cases for Response
--1. Check all mandatory parameters are missed
--2. Check all parameters are missed

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup("TestCaseGroupForCommonTestCaseForResponse")

--[=[ToDo: update according to APPLINK-13101
Test[APIName.."_Response_MissingMandatoryParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC("Speak", Request)


	--hmi side: expect the request
	EXPECT_HMICALL("TTS.Speak", Request)
	:Do(function(_,data)

		self.hmiConnection:SendNotification("TTS.Started")
		SpeakId = data.id

		local function speakResponse()

			self.hmiConnection:SendNotification("TTS.Stopped")

			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')

		end
		RUN_AFTER(speakResponse, 1000)

	end)

	--mobile side: expect OnHashChange notification
	ExpectOnHMIStatusWithAudioStateChanged(self)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)

end
-----------------------------------------------------------------------------------------


Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = self:createRequest()
	local cid = self.mobileSession:SendRPC("Speak", Request)


	--hmi side: expect the request
	EXPECT_HMICALL("TTS.Speak", Request)
	:Do(function(_,data)

		self.hmiConnection:SendNotification("TTS.Started")
		SpeakId = data.id

		local function speakResponse()

			self.hmiConnection:SendNotification("TTS.Stopped")

			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
			  self.hmiConnection:Send('{}')

		end
		RUN_AFTER(speakResponse, 1000)

	end)

	--mobile side: expect OnHashChange notification
	ExpectOnHMIStatusWithAudioStateChanged(self)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)

end
-----------------------------------------------------------------------------------------

]=]

-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsValidValue
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_resultCode_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForResultCodeParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)

			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()

				self.hmiConnection:SendNotification("TTS.Stopped")

				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak"}}')

			end
			RUN_AFTER(speakResponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)


		--mobile side: expect the response
		--TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)

			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()

				self.hmiConnection:SendNotification("TTS.Stopped")
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.Speak"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.Speak"},"message":"The unknown issue occurred"}}')


			end
			RUN_AFTER(speakResponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)


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
		{resultCode = "REJECTED", success =  false},
		{resultCode = "ABORTED", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "WARNINGS", success =  true}
	}

	for i =1, #resultCodes do

		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
				end
				RUN_AFTER(speakResponse, 1000)

			end)


			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

			if
				resultCodes[i].resultCode == "UNSUPPORTED_RESOURCE" then
				resultCodes[i].resultCode = "WARNINGS"
				resultCodes[i].success = true
			end


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_resultCode_IsValidValue_" .. resultCodes[i].resultCode .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")
				end
				RUN_AFTER(speakResponse, 1000)




			end)

			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

			if
				resultCodes[i].resultCode == "UNSUPPORTED_RESOURCE" then
				resultCodes[i].resultCode = "WARNINGS"
				resultCodes[i].success = true
			end

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode, info = "info"})

		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------



	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
	local testData = {
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"},
		{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{value = "a\tb", name = "IsInvalidCharacter_Tab"}}

	for i =1, #testData do

		Test[APIName.."_Response_resultCode_" .. testData[i].name .."_SendResponse_GENERIC_ERROR"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
				end
				RUN_AFTER(speakResponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

			--mobile side: expect the response
			--TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_resultCode_" .. testData[i].name .."_SendError_GENERIC_ERROR"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)

				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, testData[i].value)
				end
				RUN_AFTER(speakResponse, 1000)


			end)

			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

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
	--7. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------


local function verify_method_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForMethodParameter")


	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)

			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()

				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

			end
			RUN_AFTER(speakResponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end

	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)

			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()

				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"TTS.Speak"},"code":22,"message":"The unknown issue occurred"}}')

				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{},"code":22,"message":"The unknown issue occurred"}}')


			end
			RUN_AFTER(speakResponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--2. IsValidResponse: Covered by many test cases

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
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					--hmi side: sending the response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					  self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})
				end
				RUN_AFTER(speakResponse, 1000)

			end)

			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)

				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")

					--hmi side: sending the response
					--self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
					  self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")
				end
				RUN_AFTER(speakResponse, 1000)



			end)

			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self)

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
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			end
			RUN_AFTER(speakResponse, 1000)


		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			    		if data.payload.info then
			    			Print(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
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
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
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
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_info_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
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
	-- 	local cid = self.mobileSession:SendRPC("Speak", Request)

	-- 	--hmi side: expect the request
	-- 	EXPECT_HMICALL("TTS.Speak", Request)
	-- 	:Do(function(_,data)
	-- 		--hmi side: sending the response
	-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMaxLength .. "1"})
	-- 	end)

	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})

	-- end
	-- -----------------------------------------------------------------------------------------

	-- Test[APIName.."_Response_info_IsOutUpperBound_SendError"] = function(self)

	-- 	local infoMaxLength = commonFunctions:createString(1000)

	-- 	--mobile side: sending the request
	-- 	local Request = self:createRequest()
	-- 	local cid = self.mobileSession:SendRPC("Speak", Request)

	-- 	--hmi side: expect the request
	-- 	EXPECT_HMICALL("TTS.Speak", Request)
	-- 	:Do(function(_,data)
	-- 		--hmi side: sending the response
	-- 		self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
	-- 	end)

	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})

	-- end
	-----------------------------------------------------------------------------------------


	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t

	--TODO: update after resolving APPLINK-14551
	-- local testData = {
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"}}

	-- for i =1, #testData do

	-- 	Test[APIName.."_Response_info_" .. testData[i].name .."_SendResponse"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local Request = self:createRequest()
	-- 		local cid = self.mobileSession:SendRPC("Speak", Request)

	-- 		--hmi side: expect the request
	-- 		EXPECT_HMICALL("TTS.Speak", Request)
	-- 		:Do(function(_,data)
	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = testData[i].value})
	-- 		end)

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
	-- 		local cid = self.mobileSession:SendRPC("Speak", Request)

	-- 		--hmi side: expect the request
	-- 		EXPECT_HMICALL("TTS.Speak", Request)
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

local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')

			end
			RUN_AFTER(speakResponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"code":0,"message":"error message","data":{"method":"TTS.Speak"}}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"code":0,"message":"error message","data":{"method":"TTS.Speak"}}}')

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
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				 self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')

			end
			RUN_AFTER(speakResponse, 1000)

		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"code":0,"message":"error message","data":{"method":"TTS.Speak"}}}')
			self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"code":0,"message":"error message","data":{"method":"TTS.Speak"}}}')

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
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {info = "info message"})

			end
			RUN_AFTER(speakResponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
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
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {info = "info message"})

			end
			RUN_AFTER(speakResponse, 1000)


		end)

		--mobile side: expect OnHashChange notification
		ExpectOnHMIStatusWithAudioStateChanged(self)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("TTS.Speak", Request)
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


end

verify_correlationID_parameter()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

--Begin Test case SpecialResponseChecks
--Description: Check all negative response cases

	--Requirement id in JAMA:
		--SDLAQ-CRS-55 (Speak_Response_v2_0)
		--SDLAQ-CRS-505 (INVALID_DATA)
		--SDLAQ-CRS-504 (SUCCESS)
		--SDLAQ-CRS-509 (REJECTED)
		--SDLAQ-CRS-510 (ABORTED)
		--SDLAQ-CRS-512 (DISALLOWED)
		--SDLAQ-CRS-1027 (UNSUPPORTED_RESOURCE)
		--SDLAQ-CRS-1030 (WARNINGS)


local function SpecialResponseChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForHMINegativeCases")
	----------------------------------------------------------------------------------------------


	--Begin Test case SpecialResponseChecks.1
	--Description: Invalid JSON


		--Requirement id in JAMA: SDLAQ-CRS-58
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

		--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters

		function Test:Speak_Response_IsInvalidJson_GENERIC_ERROR()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)

		end
		]]
	--End Test case SpecialResponseChecks.1


	--Begin Test case SpecialResponseChecks.2
	--Description: Check processing response with fake parameters

		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter

		--Begin Test case SpecialResponseChecks.2.1
		--Description: Parameter is not from API

		function Test:Speak_Response_FakeParams_IsNotFromAnyAPI_SUCCESS()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case SpecialResponseChecks.2.1


		--Begin Test case SpecialResponseChecks.2.2
		--Description: Parameter is not from another API

		function Test:Speak_Response_FakeParams_IsFromAnotherAPI_SUCCESS()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case SpecialResponseChecks.2.2

	--End Test case SpecialResponseChecks.2



	--Begin SpecialResponseChecks.3
	--Description: Check processing response without all parameters
	--[[ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters
		function Test:Speak_Response_IsMissedAllPArameters_GENERIC_ERROR()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)


			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				--hmi side: sending TTS.Speak response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				self.hmiConnection:Send('{}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
	]]
	--End SpecialResponseChecks.3


	--Begin Test case SpecialResponseChecks.4
	--Description: Request without responses from HMI

		--Requirement id in JAMA: SDLAQ-CRS-500
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.

		function Test:Speak_NoResponse_GENERIC_ERROR()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)

		end

	--End SpecialResponseChecks.4


	--Begin Test case SpecialResponseChecks.5
	--Description: Invalid structure of response



		--Requirement id in JAMA: SDLAQ-CRS-58
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode

		--ToDo: Update when APPLINK resolving APPLINK-14776 SDL behavior in case HMI sends invalid message or message with fake parameters

		function Test:Speak_Response_IsInvalidStructure_GENERIC_ERROR()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect the request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"TTS.Speak"}}')
			end)

			--mobile side: expect response
			--TODO update according to APPLINK-14765
			-- EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
			:Timeout(12000)

		end

	--End Test case SpecialResponseChecks.5


	--Begin Test case SpecialResponseChecks.6
	--Description: Several response to one request

		--Requirement id in JAMA: SDLAQ-CRS-58

		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.


		--Begin Test case SpecialResponseChecks.6.1
		--Description: Several response to one request

			function Test:Speak_Response_SeveralResponseToOneRequest()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC("Speak", Request)

				--hmi side: expect the request
				EXPECT_HMICALL("TTS.Speak", Request)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

				end)


				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})

			end

		--End Test case SpecialResponseChecks.6.1



		--Begin Test case SpecialResponseChecks.6.2
		--Description: Several response to one request

			function Test:Speak_Response_SeveralResponse_WithConstractionsOfResult()

				--mobile side: sending the request
				local Request = self:createRequest()
				local cid = self.mobileSession:SendRPC("Speak", Request)

				--hmi side: expect the request
				EXPECT_HMICALL("TTS.Speak", Request)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)


				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})

			end

		--End Test case SpecialResponseChecks.6.2
		-----------------------------------------------------------------------------------------

	--End Test case SpecialResponseChecks.6

end

SpecialResponseChecks()

--End Test case SpecialResponseChecks


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks
--Description: Check all resultCodes

	--Requirement id in JAMA:
		--1. SUCCESS: SDLAQ-CRS-504
		--2. INVALID_DATA: SDLAQ-CRS-505
		--3. OUT_OF_MEMORY: SDLAQ-CRS-506
		--4. TOO_MANY_PENDING_REQUESTS: SDLAQ-CRS-507
		--5. APPLICATION_NOT_REGISTERED: SDLAQ-CRS-508
		--6. REJECTED: SDLAQ-CRS-509
		--7. ABORTED: SDLAQ-CRS-510
		--8. GENERIC_ERROR: SDLAQ-CRS-511
		--9. DISALLOWED: SDLAQ-CRS-512
		--10. UNSUPPORTED_RESOURCE: SDLAQ-CRS-1027
		--11. WARNINGS: SDLAQ-CRS-1030


local function ResultCodeChecks()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForAllResultCodesVerification")
	----------------------------------------------------------------------------------------------


	--Check resultCode SUCCESS. It is checked by other test cases.
	--Check resultCode INVALID_DATA. It is checked by other test cases.
	--Check resultCode REJECTED, UNSUPPORTED_RESOURCE, ABORTED, WARNINGS: Covered by test case resultCode_IsValidValue
	--Check resultCode GENERIC_ERROR. It is covered in Test:Speak_NoResponse
	--Check resultCode OUT_OF_MEMORY. ToDo: Wait until requirement is clarified
	--Check resultCode TOO_MANY_PENDING_REQUESTS. It is moved to other script.


	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED: SDLAQ-CRS-508

		--Requirement id in JAMA: SDLAQ-CRS-508
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--End Test case ResultCodeChecks.1
	-----------------------------------------------------------------------------------------


	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED: SDLAQ-CRS-512

		--Requirement id in JAMA: SDLAQ-CRS-512
		--Verification criteria:
			--1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
			--2. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.

		--[[TODO debug after resolving APPLINK-13101

		--Begin Test case ResultCodeChecks.2.1
		--Description: 1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.

			policyTable:checkPolicyWhenAPIIsNotExist()

		--End Test case ResultCodeChecks.2.1


		--Begin Test case ResultCodeChecks.2.2
		--Description: 2. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.

			policyTable:checkPolicyWhenUserDisallowed({"FULL", "LIMITED"})

		--End Test case ResultCodeChecks.2.2
	]]
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
	commonFunctions:newTestCasesGroup("TestCaseGroupForSequenceChecks")
	----------------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.1
	--Description: 	Check for manual test case TC_Speak_01

		--Requirement id in JAMA: SDLAQ-TC-120
		--Verification criteria: Call Speak request from mobile app on HMI


		function Test:Speak_TC_Speak_01()

			--verify type = TEXT
			local Request = {
				ttsChunks =
				{
					{text ="Text1", type ="TEXT"},
					{text ="Text2", type ="TEXT"},
					{text ="Text3", type ="TEXT"},
				}
			}

			self:verify_SUCCESS_Case(Request)

			--verify type = TEXT, text = "  ": it is covered by verify_String_Parameter_WithOut_Madatory_Check (7. IsInvalidCharacters: "\n", "\t", "  ")
		end

	--End Test case SequenceChecks.1

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.2
	--Description:
		--Check for manual test case TC_Speak_02:

		--Requirement id in JAMA: SDLAQ-TC-777
		--Verification criteria: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout notification received from HMI

		function Test:Speak_TC_Speak_02_Step1()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect TTS.Speak request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
				end

				local function SendOnResetTimeout()
					self.hmiConnection:SendNotification("TTS.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "TTS.Speak"})
				end

				--send TTS.OnResetTimeout notification after 9 seconds
				RUN_AFTER(SendOnResetTimeout, 9000)

				--send TTS.Speak response after 9 seconds after reset timeout
				RUN_AFTER(speakResponse, 18000)
			end)


			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", 20000)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:Timeout(20000)


		end


		function Test:Speak_TC_Speak_02_Step2()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect TTS.Speak request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
				end

				local function SendOnResetTimeout()
					self.hmiConnection:SendNotification("TTS.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "TTS.Speak"})
				end

				--send TTS.OnResetTimeout notification after 9 seconds
				RUN_AFTER(SendOnResetTimeout, 9000)

				--send TTS.OnResetTimeout notification after 9 seconds
				RUN_AFTER(SendOnResetTimeout, 18000)

				--send TTS.OnResetTimeout notification after 9 seconds
				RUN_AFTER(SendOnResetTimeout, 24000)

				--send TTS.Speak response after 9 seconds after reset timeout
				RUN_AFTER(speakResponse, 33000)
			end)


			--mobile side: expect OnHashChange notification
			ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", 35000)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:Timeout(35000)


		end



	--End Test case SequenceChecks.2

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.3
	--Description: Check for manual test case TC_Speak_03

		--Requirement id in JAMA: SDLAQ-TC-778
		--Verification criteria: Call Speak request from mobile app on HMI and check TTS.OnResetTimeout notification received from HMI

		function Test:Speak_TC_Speak_03()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect TTS.Speak request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function SendOnResetTimeout()
					self.hmiConnection:SendNotification("TTS.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "TTS.Speak"})
				end

				--send TTS.OnResetTimeout notification after 9 seconds
				RUN_AFTER(SendOnResetTimeout, 9000)

			end)


			--mobile side: expect OnHashChange notification
			if commonFunctions:isMediaApp() then
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
			else
				EXPECT_NOTIFICATION("OnHMIStatus", {})
				:Times(0)
			end

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(22000)


		end

		function Test:PostCondition()

			self.hmiConnection:SendNotification("TTS.Stopped")

			--mobile side: expect OnHashChange notification
			if commonFunctions:isMediaApp() then
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			else
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
			end
		end

	--End Test case SequenceChecks.3

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceChecks.4
	--Description: Check for manual test case TC_Speak_04

		--Requirement id in JAMA: SDLAQ-TC-1085
		--Verification criteria: This test case is check that Speak response with "success"="false" when ResultCode is "ABORTED"

		function Test:Speak_TC_Speak_04()


			local Request = {
				ttsChunks =
				{
					{text ="Text1", type ="TEXT"},
					{text ="Text2", type ="TEXT"},
					{text ="Text3", type ="TEXT"},
				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("Speak", Request)

			--hmi side: expect TTS.Speak request
			EXPECT_HMICALL("TTS.Speak", Request)
			:Do(function(_,data)
				self.hmiConnection:SendNotification("TTS.Started")
				SpeakId = data.id

				local function speakResponse()

					--HMI sends TTS.Speak: ABORTED
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "ABORTED", { })

					--HMI sends TTS.Stopped
					self.hmiConnection:SendNotification("TTS.Stopped")

					--HMI sends VR.Started
					self.hmiConnection:SendNotification("VR.Started")

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "VRSESSION" })

				end


				--HMI sends response and notifications
				RUN_AFTER(speakResponse, 1000)
			end)


			--mobile side: expect OnHashChange notification
			if commonFunctions:isMediaApp() then
				EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
				:Times(4)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
				:Times(4)
			end


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

		function Test:PostCondition()


			--HMI sends VR.Started
			self.hmiConnection:SendNotification("VR.Stopped")

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })


			--mobile side: expect OnHashChange notification
			if commonFunctions:isMediaApp() then
				EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
				:Times(2)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
				:Times(0)
			end



		end


	--End Test case SequenceChecks.4

	-----------------------------------------------------------------------------------------

end

SequenceChecks()

--End Test suit SequenceChecks


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--SDLAQ-CRS-778: HMI Status Requirements for Speak
	--SDL rejects Speak request with REJECTED resultCode when current HMI level is NONE or BACKGROUND.
	--SDL doesn't reject Speak request when current HMI is FULL.
	--SDL doesn't reject Speak request when current HMI is LIMITED.

--Verify resultCode in NONE, LIMITED, BACKGROUND hmi level
commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "DISALLOWED")


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
