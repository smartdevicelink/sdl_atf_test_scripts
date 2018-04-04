--This script contains common functions that are used in many script.
--How to use:
	--1. local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
	--2. commonTestCases:createString(500) --example
---------------------------------------------------------------------------------------------

local commonTestCases = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local events = require('events')



---------------------------------------------------------------------------------------------
------------------------------------------ Functions ----------------------------------------
---------------------------------------------------------------------------------------------
--List of group functions:
--1. Test cases for request
--2. Test cases for HMI Level checks
--3. Test cases for resultCode check




---------------------------------------------------------------------------------------------
--1.Test cases for request
---------------------------------------------------------------------------------------------
--1.1. VerifyInvalidJsonRequest
--1.2. VerifyRequestIsMissedAllParameters
---------------------------------------------------------------------------------------------

--Verify request with invalid JSON
function commonTestCases:VerifyInvalidJsonRequest(RPCFunctionId, Payload, TestCaseName)

	if TestCaseName == nil or TestCaseName == "" then
		TestCaseName = APIName .."_InvalidJSON_INVALID_DATA"
	end

	Test[TestCaseName] = function(self)

		commonTestCases:DelayedExp(1000) --1 second

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = RPCFunctionId,
			rpcCorrelationId = self.mobileSession.correlationId,
			--payload          = '{"ttsChunks":{{"text":"a","type":"TEXT"}}}'
			payload          = Payload
		}
		self.mobileSession:Send(msg)

		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end

--Verify request missed all parameters
function commonTestCases:VerifyRequestIsMissedAllParameters()

	Test[APIName .."_IsMissedAllParameters_INVALID_DATA"] = function(self)

		--mobile side: sending request
		local cid = self.mobileSession:SendRPC(APIName, {} )

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	end

end


function commonTestCases:DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+5000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end


---------------------------------------------------------------------------------------------
--2. Test cases for HMI Level checks
---------------------------------------------------------------------------------------------
--2. 1. verifyDifferentHMIStatus
---------------------------------------------------------------------------------------------

--Send request, check HMI Status and resultCode
local function SendRequestInDifferentHMIStatus(HMIStatus, ResultCode)

	Test[APIName .. "_" .. HMIStatus .. "_HMILevel_" .. ResultCode] = function(self)

		--create default request
		local RequestParams = self.createRequest()


		if ResultCode == "DISALLOWED" then

			--mobile side: send request
			local cid = self.mobileSession:SendRPC(APIName, RequestParams)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})

		elseif ResultCode == "SUCCESS" then

			--mobile sends request receives SUCCESS result code
			self:verify_SUCCESS_Case(RequestParams, HMIStatus)
		else
			print("Error: ResultCode is not SUCCESS or DISALLOWED")
		end

	end

end

--Send request, check resultCode in NONE hmi level
local function VerifyRequestInNoneHmiLevel(ResultCode)

	--Precondition: Deactivate app to NONE HMI level
	commonSteps:DeactivateAppToNoneHmiLevel()

	--Send request, check HMI Status and resultCode
	SendRequestInDifferentHMIStatus("NONE", ResultCode)

	--Postcondition: Activate app
	commonSteps:ActivationApp()

end

--Send request, check resultCode in LIMITED hmi level
local function VerifyRequestInLimitedHmiLevel(ResultCode)

	-- Precondition: Change app to LIMITED
	commonSteps:ChangeHMIToLimited()

	--Send request, check HMI Status and resultCode
	SendRequestInDifferentHMIStatus("LIMITED", ResultCode)

end

function commonTestCases:ChangeAppToBackgroundHmiLevel()

	if commonFunctions:isMediaApp() then
		-- Precondition 1: Opening new session
		commonSteps:precondition_AddNewSession()

		-- Precondition 2: Register app2
		commonSteps:RegisterTheSecondMediaApp()

		-- Precondition 3: Activate an other media app to change app to BACKGROUND
		commonSteps:ActivateTheSecondMediaApp()

	else

		-- Precondition: Deactivate non-media app to BACKGROUND
		commonSteps:DeactivateToBackground()

	end

end

--Verify resultCode in NONE, LIMITED, BACKGROUND hmi level
function commonTestCases:verifyDifferentHMIStatus(NoneHmiResultCode, LimitedHmiResultCode, BackgroundHmiResultCode)

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
	----------------------------------------------------------------------------------------------

	--Test case 1: Check resultCode when HMI level is NONE
	VerifyRequestInNoneHmiLevel(NoneHmiResultCode)

	--Test case 2: Check resultCode when HMI level is LIMITED
	if commonFunctions:isMediaApp() then
		VerifyRequestInLimitedHmiLevel(LimitedHmiResultCode)
	end

	--Test case 3: Check resultCode when HMI level is BACKGROUND
	commonTestCases:ChangeAppToBackgroundHmiLevel()

	--Send request, check HMI Status and resultCode
	SendRequestInDifferentHMIStatus("BACKGROUND", BackgroundHmiResultCode)

	--VerifyRequestInBackgroundHmiLevel(BackgroundHmiResultCode)

end



---------------------------------------------------------------------------------------------
--3. Test cases for resultCode check
---------------------------------------------------------------------------------------------
--3.1. verifyResultCode_APPLICATION_NOT_REGISTERED
---------------------------------------------------------------------------------------------

--Verify APPLICATION_NOT_REGISTERED resultCode
function commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--Precondition
	function Test:Precondition_CreationNewSession()
		-- Connected expectation
		self.mobileSession2 = mobile_session.MobileSession(
																--self.expectations_list,
																self,
																self.mobileConnection
															)
	end

	Test[APIName .."_resultCode_APPLICATION_NOT_REGISTERED"] = function(self)

		--mobile side: sending the request
		local RequestParams = self.createRequest()
		local cid = self.mobileSession2:SendRPC(APIName, RequestParams)

		--mobile side: expect response
		self.mobileSession2:ExpectResponse(cid, {  success = false, resultCode = "APPLICATION_NOT_REGISTERED"})

	end

end


--Verify TOO_MANY_PENDING_REQUESTS resultCode
function commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)

	--Test[APIName .."_resultCode_TOO_MANY_PENDING_REQUESTS"] = function(self)

		commonTestCases:DelayedExp(1000)

		local n = 0

		--mobile side: expect response
		EXPECT_RESPONSE(APIName)
		:ValidIf(function(exp,data)
			if
				data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
				n = n+1
					print(" \27[32m "..APIName.." response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
					return true
			elseif
				exp.occurences == numberOfRequest-1 and n == 0 then
				print(" \27[36m Response "..APIName.." with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
				return false
			elseif
				data.payload.resultCode == "GENERIC_ERROR" then
					print(" \27[32m "..APIName.." response came with resultCode GENERIC_ERROR \27[0m")
				return true
			else
				print(" \27[36m "..APIName.." response came with resultCode "..tostring(data.payload.resultCode) .." \27[0m")
				return true
			end
		end)
		:Times(AtLeast(numberOfRequest))
		:Timeout(14000)

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

--	end

end


return commonTestCases
