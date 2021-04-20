--Note: N/A
---------------------------------------------------------------------------------------------
--Test result: Passed all test cases
---------------------------------------------------------------------------------------------


Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
APIName = "GenericResponse" -- use for above required scripts.


local iTimeout = 5000

local GenericResponseID = 31 --<element name="GenericResponseID" value="31" hexvalue="1F" />

--Main function	
function SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, intRPCFunctionId, strPayload)

	--mobile side: sending not existing request id
	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

	local msg = 
	{
		serviceType      = 7,
		frameInfo        = 0,
		rpcType          = 0,
		rpcFunctionId    = intRPCFunctionId, --0x0fffffff, 
		rpcCorrelationId = self.mobileSession.correlationId,
		payload          = strPayload --'{}'
	}
	self.mobileSession:Send(msg)
	
	
	--mobile side: expect GenericResponse response
	EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA", info = nil })	
	:ValidIf(function(_,data)
		if data.rpcFunctionId == GenericResponseID then 
			return true
		else
			print("Response is not correct. Expected: ".. GenericResponseID .." (GenericResponseID), actual: "..tostring(data.rpcFunctionId))
			return false
		end
	end)

	
end		

	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--1. Activate application
	commonSteps:ActivationApp()


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

		
		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139
		--Verification criteria: Generic Response is sent, when the name of a received msg cannot be retrieved. Only used in case of an error. Currently, only resultCode INVALID_DATA is used.		
		
		
		--Begin Test suit CommonRequestCheck.1
		--Description: Check request with all parameters
				
			--Begin Test case CommonRequestCheck.1.1
			--Description: Check request with RPC Function ID = 0x0200				
						
				function Test:GenericResponse_PositiveCase_INVALID_DATA()
				
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0200, '{}')	
					
				end		

			--End Test case CommonRequestCheck.1.1
				
		--End Test suit CommonRequestCheck.1

	
		--Begin Test suit PositiveRequestCheck.2
		--Description: Request with fake parameters (fake - not from protocol, from another request)				
				
			--Begin Test case CommonRequestCheck.2.1
			--Description: Check request with RPC Function ID = 0x0fffffff and fake parameter		
			
				function Test:GenericResponse_InCase_RPCFunctionId_0x0fffffff_And_payloadContainFakeParameter_INVALID_DATA()
					
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0fffffff, '{"fakeParameter" : "123"}')	
					
				end		

			--End Test case CommonRequestCheck.2.1		

			--Begin Test case CommonRequestCheck.2.2
			--Description: Check request with RPC Function ID = 0x0fffffff, parameter of SubscribeButton request		
			
				function Test:GenericResponse_InCase_RPCFunctionId_0x0fffffff_ParameterFromOtherRequest_INVALID_DATA()
					
					-- '{"buttonName":"OK"}' of SubscribeButton request
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0fffffff, '{"buttonName" : "OK"}')	
					
				end					
			
			--End Test case CommonRequestCheck.2.2	
			
		--End Test case CommonRequestCheck.2


		--Begin Test suit CommonRequestCheck.3
		--Description: request is sent with invalid JSON structure
				
			--Begin Test case CommonRequestCheck.3.1
			--Description: Check request with RPC Function ID = 0x0fffffff		
				
				function Test:GenericResponse_InCase_RPCFunctionId_0x0fffffff_And_payloadIsInvalidJSON_Structure_INVALID_DATA()
					
					-- '{"buttonName":"OK"}' of SubscribeButton request
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0fffffff, '{"buttonName" "OK"}')	
					
				end		

			--End Test case CommonRequestCheck.3.1
				
		--End Test suit CommonRequestCheck.3
		

		--Begin Test suit CommonRequestCheck.4
		--Description: different conditions of correlationID parameter (invalid, several the same etc.)
				
			--Begin Test case CommonRequestCheck.4.1
			--Description: Check request with correlationID = wrong type

				-- TODO: need to clarify about ATF usage
				-- function Test:GenericResponse_InvalidCorrelationID_WrongType__INVALID_DATA()
				
				-- 	--mobile side: sending not existing request id
				-- 	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				-- 	local msg = 
				-- 	{
				-- 		serviceType      = 7,
				-- 		frameInfo        = 0,
				-- 		rpcType          = 0,
				-- 		rpcFunctionId    = 0x0fffffff, 
				-- 		rpcCorrelationId = tostring(self.mobileSession.correlationId),
				-- 		payload          = '{}'
				-- 	}
				-- 	self.mobileSession:Send(msg)
					
					
				-- 	--mobile side: expect GenericResponse response
				-- 	EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA", info = nil })	
				-- 	:ValidIf(function(_,data)
				-- 		if data.rpcFunctionId == GenericResponseID then 
				-- 			return true
				-- 		else
				-- 			print("Response is not correct. Expected: ".. GenericResponseID .." (GenericResponseID), actual: "..tostring(data.rpcFunctionId))
				-- 			return false
				-- 		end
				-- 	end)					
				-- end		

			--End Test case CommonRequestCheck.4.1

				
			--Begin Test case CommonRequestCheck.4.2
			--Description: Check request with correlationID = not in sequence
				
				function Test:GenericResponse_InvalidCorrelationID_WrongID_INVALID_DATA()
				
					--mobile side: sending not existing request id
					self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					local msg = 
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 0x0fffffff, 
						rpcCorrelationId = self.mobileSession.correlationId + 5,
						payload          = '{}'
					}
					self.mobileSession:Send(msg)
					
					
					--mobile side: expect GenericResponse response
					EXPECT_RESPONSE(self.mobileSession.correlationId + 5, { success = false, resultCode = "INVALID_DATA", info = nil })	
					:ValidIf(function(_,data)
						if data.rpcFunctionId == GenericResponseID then 
							return true
						else
							print("Response is not correct. Expected: ".. GenericResponseID .." (GenericResponseID), actual: "..tostring(data.rpcFunctionId))
							return false
						end
					end)					
				end					

			--End Test case CommonRequestCheck.4.2
			
		--End Test suit CommonRequestCheck.4
		
	--End Test suit PositiveRequestCheck
		
		

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
			--Description: check RPCFunctionId parameter value is inbound

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

				--Verification criteria: Generic Response is sent, when the name of a received msg cannot be retrieved. Only used in case of an error. Currently, only resultCode INVALID_DATA is used.

					
				--Check request with RPC Function ID = 0x0 (minValue)
				function Test:GenericResponse_RPCFunctionId_LowerBound_INVALID_DATA()
					
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0, '{}')	
					
				end		
				
				--Check request with RPC Function ID = 0x0fffffff (maxValue)
				function Test:GenericResponse_RPCFunctionId_UpperBound_INVALID_DATA()
					
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x0fffffff, '{}')	
					
				end			

				--Check request with RPC Function ID = special id (GenericResponseID = 31)
				function Test:GenericResponse_RPCFunctionId_IsGenericResponseID_INVALID_DATA()
					
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 31, '{}')	
					
				end			

				
			--End Test case PositiveRequestCheck.1		
			
		--End Test suit PositiveRequestCheck
		
		
		
	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions
		
		--Note: SDL responses the request so that there is no response from HMI side. => Ignore this session.

		
		
----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

	--Begin Test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.
	
		--Begin Test case NegativeRequestCheck.1	
		--Description: check RPCFunctionId parameter value is outbound

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: Generic Response is sent, when the name of a received msg cannot be retrieved. Only used in case of an error. Currently, only resultCode INVALID_DATA is used.

			--Check request with RPC Function ID = -1 
			function Test:GenericResponse_RPCFunctionId_OutLowerBound_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, -1, '{}')	
				
			end		

			--Check request with RPC Function ID = 0xffffffffffff
			function Test:GenericResponse_RPCFunctionId_OutUpperBound_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0xffffffffffff, '{}')	
				
			end	

		--End Test case NegativeRequestCheck.1
		-----------------------------------------------------------------------------------------			
	
	--End Test suit NegativeRequestCheck
	


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--> These checks are not applicable. There is no response from HMI to SDL.

		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin Test suit ResultCodeCheck
	--Description: check result code of response to Mobile	
	
		--Begin Test case ResultCodeCheck.1
		--Description: Check resultCode: INVALID_DATA

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: SDL response INVALID_DATA resultCode to Mobile	

			--Check response with resultCode INVALID_DATA
			function Test:GenericResponse_resultcode_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x500, '{}')	
				
			end				
			
		--End Test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------	

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
	
	
	-- SubscribeButton API does not have any response from HMI. This test suit is not applicable => Ignore



----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Begin Test case SequenceCheck.1
		--Description: check scenario in test case TC_GenericResponse_01.vsd

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: SDL responses GenericResponse with INVALID resultCode

			function Test:GenericResponse_mobile_send_non_existing_request_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x501, '{}')	
				
			end	

		--End Test case SequenceCheck.1
		-----------------------------------------------------------------------------------------

		--Note: These is only INVALID_DATA resultCode. No other resultCode is used for GenericResponse response.
		
	--End Test suit SequenceCheck
			



	
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel


		--Begin Test case DifferentHMIlevel.1
		--Description: Check GenericRequest request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: SDL responses GenericResponse in NONE HMI level
		
			-- Precondition: Change app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()
		
			function Test:GenericResponse_Different_HMIStatus_NONE_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x500, '{}')	
				
			end	
				
			--Postcondition: Activate app
			commonSteps:ActivationApp()
		
		--End Test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------
		
		--Begin Test case DifferentHMIlevel.1
		--Description: Check GenericRequest request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: SDL responses GenericResponse in LIMITED HMI level
			
			if commonFunctions:isMediaApp() then
				
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()	
					
				function Test:GenericResponse_Different_HMIStatus_LIMITED_INVALID_DATA()
					
					SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x500, '{}')	
					
				end	
			
			end
			
		--End Test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------

		
		

		
		--Begin Test case DifferentHMIlevel.3
		--Description: Check GenericRequest request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-139

			--Verification criteria: SDL responses GenericResponse in BACKGOUND HMI level
		
			-- Precondition 1: Change app to BACKGOUND HMI level
			commonTestCases:ChangeAppToBackgroundHmiLevel()
		
			function Test:GenericResponse_Different_HMIStatus_BACKGROUND_INVALID_DATA()
				
				SendUnsupportedRequestAndVerifyGenericResponse_INVALID_DATA(self, 0x500, '{}')	
				
			end	
				
		--End Test case DifferentHMIlevel.3
		-----------------------------------------------------------------------------------------

	--End Test suit DifferentHMIlevel

			
			
return Test
	
