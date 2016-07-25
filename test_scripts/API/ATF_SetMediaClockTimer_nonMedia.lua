--Note: List of existing defects:
--APPLINK-13417: SDL writes ERROR in log and ignore all responses after HMI send UI.SetMediaClockTimer response with fake parameter
--ToDO: will be updated according to APPLINK-14765
---------------------------------------------------------------------------------------------
config.application1 =
{
  registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "Test Application",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0000001",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }
}

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
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
---------------------------------------------------------------------------------------------

APIName = "SetMediaClockTimer" -- set request name
local iTimeout = 5000
local updateModeNotRequireStartEndTime = {"PAUSE", "RESUME", "CLEAR"}
local updateMode = {"COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR"}
local updateModeCountUpDown = {"COUNTUP", "COUNTDOWN"}
local countDown = 0
local InBound60 = {0, 30, 59}
local OutBound60 = {-1, 60}
local str1000Chars = "1_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz" .. string.rep("a",935)
local str1000Chars2 = "2_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz" .. string.rep("a",935)


local info = {"a", str1000Chars}
local infoName = {"LowerBound", "UpperBound"}
local infoOutBound = {str1000Chars .. "A"}
local infoOutBound_ToMobile = {str1000Chars}

resultCode = {"SUCCESS", "INVALID_DATA", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "APPLICATION_NOT_REGISTERED", "REJECTED", "IGNORED", "GENERIC_ERROR", "UNSUPPORTED_RESOURCE", "DISALLOWED"}

success = {true, false, false, false, false, false, false, false, false, false}

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1. Activation App by sending SDL.ActivateApp


		function Test:ActivateApplication()
			--HMI send ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				if data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					 -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					 EXPECT_HMIRESPONSE(RequestId)
						:Do(function(_,data)
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

							EXPECT_HMICALL("BasicCommunication.ActivateApp")
								:Do(function(_,data)
									self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
								end)
								:Times(2)
						end)

				end
			end)

			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

		end



	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin test suit CommonRequestCheck


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For CommonRequestCheck")

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

		--Begin test case CommonRequestCheck.1
		--Description: check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: Sets the initial media clock value and automatic update method for HMI media screen with all parameters


			for i=1,#updateMode do
				Test["SetMediaClockTimer_PositiveCase_" .. tostring(updateMode[i]).."_REJECTED"] = function(self)
					countDown = 0
					if updateMode[i] == "COUNTDOWN" then
						countDown = -1
					end

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 0,
							minutes = 1,
							seconds = 33
						},
						endTime =
						{
							hours = 0,
							minutes = 1 + countDown,
							seconds = 35
						},
						updateMode = updateMode[i]
					})

					--hmi side: expect absence of UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					:Timeout(iTimeout)

				end
			end

		--End test case CommonRequestCheck.1
		-----------------------------------------------------------------------------------------


		--Begin test case CommonRequestCheck.2
		--Description: check request with only mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: Check request with mandatory parameter only: updateMode = "PAUSE", "RESUME" and "CLEAR"

			for i=1,#updateModeNotRequireStartEndTime do
				Test["SetMediaClockTimer_OnlyMandatory_" .. tostring(updateModeNotRequireStartEndTime[i]).."REJECTED"] = function(self)

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						updateMode = updateModeNotRequireStartEndTime[i]
					})

					--hmi side: expect absence of UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					:Timeout(iTimeout)

				end
			end

		--End test case CommonRequestCheck.2
		-----------------------------------------------------------------------------------------

		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)
		-----------------------------------------------------------------------------------------


		--Begin test case CommonRequestCheck.5
		--Description: check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-515

			--Verification criteria: The request without "updateMode" is sent, the INVALID_DATA response code is returned.

			function Test:SetMediaClockTimer_missing_mandatory_parameters_updateMode_INVALID_DATA()

				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 33
					},
					endTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 35
					}
				})

				--hmi side: expect absence of UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer")
				:Timeout(iTimeout)
				:Times(0)

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)

			end

		--End test case CommonRequestCheck.5
		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.6
		--Description: check request with all parameters are missing

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: SDL responses invalid data

			function Test:SetMediaClockTimer_AllParameterAreMissed_INVALID_DATA()

				--mobile side: sending ReSetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{

				})

				--hmi side: expect absence of UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer")
				:Timeout(iTimeout)
				:Times(0)

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)

			end

		--End test case CommonRequestCheck.6
		-----------------------------------------------------------------------------------------


		--Begin test case CommonRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL

			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters

				for i=1,#updateMode do
					Test["SetMediaClockTimer_FakeParameters_" .. tostring(updateMode[i]).."_REJECTED"] = function(self)
						countDown = 0
						if updateMode[i] == "COUNTDOWN" then
							countDown = -1
						end

						--mobile side: sending SetMediaClockTimer request
						local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
						{
							fakeParameter = "fakeParameter",
							startTime =
							{
								hours = 0,
								minutes = 1,
								seconds = 33
							},
							endTime =
							{
								hours = 0,
								minutes = 1 + countDown,
								seconds = 35
							},
							updateMode = updateMode[i]
						})

						--hmi side: expect absence of UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer")
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
						:Timeout(iTimeout)

					end
				end

			--End test case CommonRequestCheck.7.1
			-----------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				for i=1,#updateMode do
					Test["SetMediaClockTimer_ParametersOfOtherRequest_" .. tostring(updateMode[i]).."_REJECTED"] = function(self)
						countDown = 0
						if updateMode[i] == "COUNTDOWN" then
							countDown = -1
						end

						--mobile side: sending SetMediaClockTimer request
						local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
						{
							syncFileName = "icon.png", --PutFile request
							startTime =
							{
								hours = 0,
								minutes = 1,
								seconds = 33
							},
							endTime =
							{
								hours = 0,
								minutes = 1 + countDown,
								seconds = 35
							},
							updateMode = updateMode[i]
						})

						--hmi side: expect absence of UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer")
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
						:Timeout(iTimeout)

					end
				end

			--End test case CommonRequestCheck.7.2
			-----------------------------------------------------------------------------------------

		--End test case CommonRequestCheck.7


		--Begin test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure


			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-395

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

			function Test:SetMediaClockTimer_InvalidJSON_INVALID_DATA()

				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg =
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 15, --SetMediaClockTimerID
					rpcCorrelationId = self.mobileSession.correlationId,
					-- missing ':' after startTime
					--payload          = '{"startTime":{"seconds":34,"hours":0,"minutes":12},"endTime":{"seconds":33,"hours":11,"minutes":22},"updateMode":"COUNTUP"}'
					payload          = '{"startTime" {"seconds":34,"hours":0,"minutes":12},"endTime":{"seconds":33,"hours":11,"minutes":22},"updateMode":"COUNTUP"}'
				}
				self.mobileSession:Send(msg)

				--hmi side: expect absence of UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer")
				:Timeout(iTimeout)
				:Times(0)

				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

			end

		--End test case CommonRequestCheck.8
		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.9
		--Description: CorrelationId is duplicated

			--Requirement id in JAMA/or Jira ID:

			--Verification criteria: response comes with SUCCESS result code.

			function Test:SetMediaClockTimer_CorrelationID_Duplicated_REJECTED()

				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 33
					},
					endTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 35
					},
					updateMode = "COUNTUP"
				})

				--hmi side: expect absence of UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer")
				:Timeout(iTimeout)
				:Times(0)

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 15, --SetMediaClockTimerID
							rpcCorrelationId = cid,
							payload          = '{"startTime":{"seconds":33,"hours":0,"minutes":1},"endTime":{"seconds":35,"hours":0,"minutes":1},"updateMode":"COUNTUP"}'
						}
						self.mobileSession:Send(msg)
					end
				end)

			end

		--End test case CommonRequestCheck.9
		-----------------------------------------------------------------------------------------

	--End test suit CommonRequestCheck



---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--


		--Begin test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin test case PositiveRequestCheck.1
			--Description: check of each request parameter value in bound and boundary conditions startTime parameter

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2635

				--Verification criteria:  SDL re-sends startTime value to HMI within startTime parameter of UI.SetMediaClockTimer in case of any updateMode value that mobile app sends to SDL (that is, it is HMI`s responsibility to ignore startTime for PAUSE, RESUME, CLEAR and display the values correctly for COUNTUP and COUNTDOWN updateMode values).

				--Begin test case PositiveRequestCheck.1.1
				--Description: check startTime.seconds parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_startTime_seconds_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = 0,
										minutes = 1,
										seconds = InBound60[i]
									},
									endTime =
									{
										hours = 1 + countDown,
										minutes = 1 + countDown,
										seconds = 35
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)

								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end

				--End test case PositiveRequestCheck.1.1
				-----------------------------------------------------------------------------------------

				--Begin test case PositiveRequestCheck.1.2
				--Description: check startTime.minutes parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_startTime_minutes_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = 0,
										minutes = InBound60[i],
										seconds = 3
									},
									endTime =
									{
										hours = 1 + countDown,
										minutes = 0,
										seconds = 1
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)

								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end

				--End test case PositiveRequestCheck.1.2
				-----------------------------------------------------------------------------------------

				--Begin test case PositiveRequestCheck.1.3
				--Description: check startTime.hours parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_startTime_hours_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = InBound60[i],
										minutes = 1,
										seconds = 33,
									},
									endTime =
									{
										hours = InBound60[i],
										minutes = 1 + countDown,
										seconds = 35
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end

				--End test case PositiveRequestCheck.1.3
				-----------------------------------------------------------------------------------------

				--Begin test case PositiveRequestCheck.1.4
				--Description: check endTime.seconds parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_endTime_seconds_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = 0,
										minutes = 1,
										seconds = 0
									},
									endTime =
									{
										hours = 0,
										minutes = 1 + countDown,
										seconds = InBound60[i]
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end

				--End test case PositiveRequestCheck.1.4
				-----------------------------------------------------------------------------------------

				--Begin test case PositiveRequestCheck.1.5
				--Description: check endTime.minutes parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_endTime_minutes_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = 1,
										minutes = 0,
										seconds = 3
									},
									endTime =
									{
										hours = 1 + countDown,
										minutes = InBound60[i],
										seconds = 4
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)

								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end

				--End test case PositiveRequestCheck.1.5
				-----------------------------------------------------------------------------------------

				--Begin test case PositiveRequestCheck.1.6
				--Description: check endTime.hours parameter value is in bound

					for i=1,#InBound60 do
						for j =1, #updateMode do
							Test["SetMediaClockTimer_endTime_hours_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_REJECTED"] = function(self)
								countDown = 0
								if updateMode[j] == "COUNTDOWN" then
									countDown = -1
								end

								--mobile side: sending SetMediaClockTimer request
								local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
								{
									startTime =
									{
										hours = InBound60[i],
										minutes = 1,
										seconds = 33,
									},
									endTime =
									{
										hours = InBound60[i],
										minutes = 1 + countDown,
										seconds = 35
									},
									updateMode = updateMode[j]
								})

								--hmi side: expect absence of UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer")
								:Timeout(iTimeout)
								:Times(0)

								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
								:Timeout(iTimeout)

							end
						end
					end


				--End test case PositiveRequestCheck.1.6
				-----------------------------------------------------------------------------------------

			--End test case PositiveRequestCheck.1

		--End test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions


		--Begin test suit PositiveResponseCheck
		--Description:

			--not applicable for non-media app

		--End test suit PositiveResponseCheck


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

	--Begin test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.


		--Begin test case NegativeRequestCheck.1
		--Description: check of each request parameter value out bound and boundary conditions

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2635, SDLAQ-CRS-515

			--Verification criteria:
				--2.1. The request with "hours" value out of bounds is sent, the response comes with INVALID_DATA result code (even if updateMode is not COUNTUP/COUNTDOWN).
				--2.2. The request with "minutes" value out of bounds is sent, the response comes with INVALID_DATA result code (even if updateMode is not COUNTUP/COUNTDOWN).
				--2.3. The request with "seconds" value out of bounds is sent, the response comes with INVALID_DATA result code (even if updateMode is not COUNTUP/COUNTDOWN).
				--2.4. The request with wrong data in "updateMode" parameter (e.g. value which doesn't exist in "UpdateMode" enum) is sent , the response with INVALID_DATA result code is returned.

			--Begin test case NegativeRequestCheck.1.1
			--Description: Check startTime.seconds parameter value is in outbound


				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_seconds_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = 1,
									seconds = OutBound60[i]
								},
								endTime =
								{
									hours = 0,
									minutes = 1 + countDown,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end


			--End test case NegativeRequestCheck.1.1
			-----------------------------------------------------------------------------------------


			--Begin test case NegativeRequestCheck.1.2
			--Description: Check startTime.minutes parameter value is in outbound

				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_minutes_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = OutBound60[i],
									seconds = 3
								},
								endTime =
								{
									hours = 1 + countDown,
									minutes = 0,
									seconds = 1
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end


			--End test case NegativeRequestCheck.1.2
			-----------------------------------------------------------------------------------------

			--Begin test case NegativeRequestCheck.1.3
			--Description: Check startTime.hours parameter value is in outbound

				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_hours_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = OutBound60[i],
									minutes = 1,
									seconds = 33,
								},
								endTime =
								{
									hours = OutBound60[i],
									minutes = 1 + countDown,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end

			--End test case NegativeRequestCheck.1.3
			-----------------------------------------------------------------------------------------


			--Begin test case NegativeRequestCheck.1.4
			--Description: Check endTime.seconds parameter value is in outbound

				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_seconds_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = 1,
									seconds = 0
								},
								endTime =
								{
									hours = 0,
									minutes = 1 + countDown,
									seconds = OutBound60[i]
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end

			--End test case NegativeRequestCheck.1.4
			-----------------------------------------------------------------------------------------


			--Begin test case NegativeRequestCheck.1.5
			--Description: Check endTime.minutes parameter value is in outbound

				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_minutes_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 0,
									seconds = 3
								},
								endTime =
								{
									hours = 1 + countDown,
									minutes = OutBound60[i],
									seconds = 4
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end

			--End test case NegativeRequestCheck.1.5
			-----------------------------------------------------------------------------------------

			--Begin test case NegativeRequestCheck.1.6
			--Description: Check endTime.hours parameter value is in outbound

				for i=1,#OutBound60 do
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_hours_OutBound_" .. tostring(OutBound60[i]) .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
							countDown = 0
							if updateMode[j] == "COUNTDOWN" then
								countDown = -1
							end

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = OutBound60[i],
									minutes = 1,
									seconds = 33,
								},
								endTime =
								{
									hours = OutBound60[i],
									minutes = 1 + countDown,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end
				end

			--End test case NegativeRequestCheck.1.6
			-----------------------------------------------------------------------------------------

			--Begin test case NegativeRequestCheck.1.7
			--Description: check of each request parameter value out bound and boundary conditions updateMode parameter

				function Test:SetMediaClockTimer_updateMode_IsInvalidValue_WrongValue_Or_nonexistent_INVALID_DATA()

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 1,
							minutes = 1,
							seconds = 33,
						},
						endTime =
						{
							hours = 1,
							minutes = 1,
							seconds = 35
						},
						updateMode = "updateMode"
					})

					--hmi side: expect absence of UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)

				end

			--End test case NegativeRequestCheck.1.7
			-----------------------------------------------------------------------------------------

		--End test case NegativeRequestCheck.1



		--Begin test case NegativeRequestCheck.2
		--Description: invalid values(empty, missing, nonexistent, duplicate, invalid characters)

			--Begin test case NegativeRequestCheck.2.1
			--Description: invalid values(empty)

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-515

				--Verification criteria:
					--5.1.The request with empty "updateMode" is sent , the response with INVALID_DATA result code is returned.
					--5.2.The request with empty "hours" value is sent , the response with INVALID_DATA result code is returned.
					--5.3.The request with empty "minutes" value is sent, the response with INVALID_DATA result code is returned.
					--5.4.The request with empty "seconds" value is sent, the response with INVALID_DATA result code is returned.

				--Begin test case NegativeRequestCheck.2.1.1
				--Description: 5.1.The request with empty "updateMode" is sent , the response with INVALID_DATA result code is returned.

					function Test:SetMediaClockTimer_updateMode_IsInvalidValue_Empty_INVALID_DATA()

						--mobile side: sending SetMediaClockTimer request
						local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
						{
							startTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 33,
							},
							endTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 35
							},
							updateMode = ""
						})

						--hmi side: expect absence of UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer")
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)

					end

				--End test case NegativeRequestCheck.2.1.1
				-----------------------------------------------------------------------------------------


				--Begin test case NegativeRequestCheck.2.1.2
				--Description: 5.2.The request with empty "hours" value is sent , the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_hours_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = "",
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_hours_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = "",
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end


				--End test case NegativeRequestCheck.2.1.2
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeRequestCheck.2.1.3
				--Description: 5.3.The request with empty "minutes" value is sent, the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_minutes_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = "",
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_minutes_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = "",
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

				--End test case NegativeRequestCheck.2.1.3
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeRequestCheck.2.1.4
				--Description: 5.4.The request with empty "seconds" value is sent, the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_seconds_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = 1,
									seconds = ""
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_seconds_IsInvalidValue_Empty" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 0,
									minutes = 1,
									seconds = 1
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = ""
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

				--End test case NegativeRequestCheck.2.1.4
				-----------------------------------------------------------------------------------------

			--End test case NegativeRequestCheck.2.1


			--Begin test case NegativeRequestCheck.2.2
			--Description: invalid values(missing)

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-515

				--Verification criteria:
					--3.1. The request without "updateMode" is sent, the INVALID_DATA response code is returned.
					--3.2. The request without "startTime" and with "COUNTUP" updateMode value is sent, the INVALID_DATA response code is returned.
					--3.3. The request without "startTime" and with "COUNTDOWN" updateMode value is sent, the INVALID_DATA response code is returned.

				--Begin test case NegativeRequestCheck.2.2.1
				--Description: 3.1. The request without "updateMode" is sent, the INVALID_DATA response code is returned.

					function Test:SetMediaClockTimer_updateMode_IsInvalidValue_missing_INVALID_DATA()

						--mobile side: sending SetMediaClockTimer request
						local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
						{
							startTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 33,
							},
							endTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 35
							}
						})

						--hmi side: expect absence of UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer")
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)

					end

				--End test case NegativeRequestCheck.2.2.1
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeRequestCheck.2.2.2
				--Description:
						--3.2. The request without "startTime" and with "COUNTUP" updateMode value is sent, the INVALID_DATA response code is returned.
						--3.3. The request without "startTime" and with "COUNTDOWN" updateMode value is sent, the INVALID_DATA response code is returned.

					--startTime
					for j =1, #updateModeCountUpDown do
						Test["SetMediaClockTimer_startTime_IsInvalidValue_missing" .."_"..tostring(updateModeCountUpDown[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateModeCountUpDown[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

				--End test case NegativeRequestCheck.2.2.2
				-----------------------------------------------------------------------------------------

			--End test case NegativeRequestCheck.2.2

		--End test case NegativeRequestCheck.2


		--Begin test case NegativeRequestCheck.3
		--Description: parameters with wrong type

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-515

			--Verification criteria:
				--4.1. The request with wrong data in "hours" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.
				--4.2. The request with wrong data in "minutes" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.
				--4.3. The request with wrong data in "seconds" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.
				--4.4. The request with wrong data in "updateMode" parameter (e.g. inetger value) is sent , the response with INVALID_DATA result code is returned.

				--Begin test case NegativeRequestCheck.3.1
				--Description: 4.1. The request with wrong data in "hours" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_hours_IsInvalidValue_wrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = "1",
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_hours_IsInvalidValue_WrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = "1",
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end


				--End test case NegativeRequestCheck.3.1
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeRequestCheck.3.2
				--Description: 4.2. The request with wrong data in "minutes" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_minutes_IsInvalidValue_wrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = "1",
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_minutes_IsInvalidValue_WrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = "1",
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end


				--End test case NegativeRequestCheck.3.2
				-----------------------------------------------------------------------------------------


				--Begin test case NegativeRequestCheck.3.2
				--Description: 4.3. The request with wrong data in "seconds" parameter (e.g. string value) is sent , the response with INVALID_DATA result code is returned.

					--startTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_startTime_seconds_IsInvalidValue_wrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 1,
									seconds = "33"
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 35
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end

					--endTime
					for j =1, #updateMode do
						Test["SetMediaClockTimer_endTime_seconds_IsInvalidValue_WrongType" .."_"..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)

							--mobile side: sending SetMediaClockTimer request
							local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
							{
								startTime =
								{
									hours = 1,
									minutes = 1,
									seconds = 33
								},
								endTime =
								{
									hours = 1,
									minutes = 1,
									seconds = "35"
								},
								updateMode = updateMode[j]
							})

							--hmi side: expect absence of UI.SetMediaClockTimer request
							EXPECT_HMICALL("UI.SetMediaClockTimer")
							:Timeout(iTimeout)
							:Times(0)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(iTimeout)

						end
					end


				--End test case NegativeRequestCheck.3.2
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeRequestCheck.3.3
				--Description: 4.4. The request with wrong data in "updateMode" parameter (e.g. integer value) is sent , the response with INVALID_DATA result code is returned.

					function Test:SetMediaClockTimer_updateMode_IsInvalidValue_WrongType_INVALID_DATA()

						--mobile side: sending SetMediaClockTimer request
						local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
						{
							startTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 33,
							},
							endTime =
							{
								hours = 1,
								minutes = 1,
								seconds = 35
							},
							updateMode = 1
						})

						--hmi side: expect absence of UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer")
						:Timeout(iTimeout)
						:Times(0)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)

					end

				--End test case NegativeRequestCheck.3.3
				-----------------------------------------------------------------------------------------

		--End test case NegativeRequestCheck.3


	--End test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin test suit NegativeResponseCheck
		--Description:


			--not applicable for non-media app

		--End test suit NegativeResponseCheck


----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile

		--Begin test case ResultCodeCheck.1
		--Description: A command can not be executed because no application has been registered with RegisterAppInterface.

			--Requirement id in JAMA: SDLAQ-CRS-518

			--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

			--Precondition: Create new session
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)
			end


			for j =1, #updateMode do
				Test["UI_SetMediaClockTimer_resultCode_APPLICATION_NOT_REGISTERED".."_"..tostring(updateMode[j])] = function(self)
					countDown = 0
					if updateMode[j] == "COUNTDOWN" then
						countDown = -1
					end

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession2:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 0,
							minutes = 1,
							seconds = 33,
						},
						endTime =
						{
							hours = 0,
							minutes = 1 + countDown,
							seconds = 35
						},
						updateMode = updateMode[j]
					})

					--hmi side: expect absence of UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetMediaClockTimer response
					self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				end

			end

		--End test case ResultCodeCheck.1

	--End test suit ResultCodeCheck

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


	--Begin test suit HMINegativeCheck
	--Description:

		--not applicable for non-media

	--End test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions


		--Begin test case SequenceCheck.1-5
		--Description: check scenario in test cases:
			--TC_SetMediaClockTimer_01: Call SetMediaClockTimer request from mobile app on HMI with COUNTUP parameter
			--TC_SetMediaClockTimer_02: Call SetMediaClockTimer request from mobile app on HMI with COUNTDOWN parameter
			--TC_SetMediaClockTimer_03: Call SetMediaClockTimer request from mobile app on HMI with PAUSE parameter
			--TC_SetMediaClockTimer_04: Call SetMediaClockTimer request from mobile app on HMI with RESUME parameter
			--TC_SetMediaClockTimer_05: Call SetMediaClockTimer request from mobile app on HMI with CLEAR parameter

			--It is covered by TC SetMediaClockTimer_PositiveCase

		--End test case SequenceCheck.1-5
		-----------------------------------------------------------------------------------------

		--Begin test case SequenceCheck.6
		--Description: check scenario in test case TC_SetMediaClockTimer_06: Call SetMediaClockTimer request from mobile app on HMI with CLEAR parameter when UI Media clock timer is in default state (empty)

			--not applicable for non-media app

	--End test suit SequenceCheck




----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Begin test case DifferentHMIlevel.1
		--Description: Check SetMediaClockTimer request when application is in LIMITTED HMI level

			--not applicable for non-media app

		--End test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------

		--Begin test case DifferentHMIlevel.2
		--Description: Check SetMediaClockTimer request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-782

			--Verification criteria: SetMediaClockTimer is NOT allowed in NONE HMI level


			-- --Precondition: Change app to FULL HMI status
			-- function Test:ActivateApplication()
			-- 	--HMI send ActivateApp request
			-- 	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			-- 	EXPECT_HMIRESPONSE(RequestId)
			-- 	:Do(function(_,data)
			-- 		if data.result.isSDLAllowed ~= true then
			-- 			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			-- 			EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			-- 			:Do(function(_,data)
			-- 				--hmi side: send request SDL.OnAllowSDLFunctionality
			-- 				self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
			-- 			end)

			-- 			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			-- 			:Do(function(_,data)
			-- 				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			-- 			end)
			-- 			:Times(2)
			-- 		end
			-- 	end)

			-- 	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

			-- end

			--Precondition: Change app to None HMI status
			function Test:ExitApplication()

				local function sendUserExit()
					--hmi side: sending BasicCommunication.OnExitApplication request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
					{
						appID = self.applications["Test Application"],
						reason = "USER_EXIT"
					})
				end

				local function SendOnSystemContext1()
					--hmi side: sending UI.OnSystemContext request
					SendOnSystemContext(self,"MAIN")
				end

				local function sendOnAppDeactivate()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
				end

				--hmi side: sending BasicCommunication.OnSystemContext request
				SendOnSystemContext(self,"MENU")

				--hmi side: sending BasicCommunication.OnExitApplication request
				RUN_AFTER(sendUserExit, 1000)

				--hmi side: sending UI.OnSystemContext request = MAIN
				RUN_AFTER(SendOnSystemContext1, 2000)

				--hmi side: sending BasicCommunication.OnAppDeactivated request
				RUN_AFTER(sendOnAppDeactivate, 3000)


				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MENU", hmiLevel = "FULL"},
						{ systemContext = "MENU", hmiLevel = "NONE"},
						{ systemContext = "MAIN", hmiLevel = "NONE"})
					:Times(3)

			end


			for j =1, #updateMode do
				Test["SetMediaClockTimer_NONE_" ..tostring(updateMode[j]).."_DISALLOWED"] = function(self)
					countDown = 0
					if updateMode[j] == "COUNTDOWN" then
						countDown = -1
					end

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 0,
							minutes = 1,
							seconds = 33,
						},
						endTime =
						{
							hours = 0,
							minutes = 1 + countDown,
							seconds = 35
						},
						updateMode = updateMode[j]
					})


					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = nil})
					:Timeout(iTimeout)

				end
			end

		--End test case DifferentHMIlevel.2
		-----------------------------------------------------------------------------------------

		--Begin test case DifferentHMIlevel.3
		--Description: Check SetMediaClockTimer request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-782

			--Verification criteria: SetMediaClockTimer is allowed in BACKGOUND HMI level according to policy

			--Precondition: Change app to FULL HMI status
			function Test:ActivateApplication()
				--HMI send ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					if data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
						end)

						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
					end
				end)

				EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

			end

			--Precondition: Set app in BACKGROUND HMI level
			function Test:ChangeHMIToLimited()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			end

			for j =1, #updateMode do
				Test["SetMediaClockTimer_BACKGROUND_" ..tostring(updateMode[j])] = function(self)
					countDown = 0
					if updateMode[j] == "COUNTDOWN" then
						countDown = -1
					end

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 0,
							minutes = 1,
							seconds = 33,
						},
						endTime =
						{
							hours = 0,
							minutes = 1 + countDown,
							seconds = 35
						},
						updateMode = updateMode[j]
					})


					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Timeout(iTimeout)
					:Times(0)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					--:Timeout(iTimeout)
					:Timeout(11000)

				end
			end


		--End test case DifferentHMIlevel.3
		-----------------------------------------------------------------------------------------

	--End test suit DifferentHMIlevel



---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test

