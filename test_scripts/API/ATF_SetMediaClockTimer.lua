--Note: List of existing defects:
--APPLINK-13417: SDL writes ERROR in log and ignore all responses after HMI send UI.SetMediaClockTimer response with fake parameter
--ToDO: will be updated according to APPLINK-14765
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

	--Activation App by sending SDL.ActivateApp

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


			for i=1,#updateModeCountUpDown do
				Test["SetMediaClockTimer_PositiveCase_" .. tostring(updateModeCountUpDown[i]).."_SUCCESS"] = function(self)
					countDown = 0
					if updateModeCountUpDown[i] == "COUNTDOWN" then
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
						updateMode = updateModeCountUpDown[i]
					})


					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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
						updateMode = updateModeCountUpDown[i]
					})

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
				Test["SetMediaClockTimer_OnlyMandatory_" .. tostring(updateModeNotRequireStartEndTime[i]).."_SUCCESS"] = function(self)

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						updateMode = updateModeNotRequireStartEndTime[i]
					})


					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer",
					{
						updateMode = updateModeNotRequireStartEndTime[i]
					})

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
					Test["SetMediaClockTimer_FakeParameters_" .. tostring(updateMode[i]).."_SUCCESS"] = function(self)
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


						--hmi side: expect UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:ValidIf(function(_,data)
							if data.params.fakeParameter then
								print("SDL resends fake parameter to HMI")
								return false
							else
								return true
							end
						end)


						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						:Timeout(iTimeout)

					end
				end

			--End test case CommonRequestCheck.7.1
			-----------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				for i=1,#updateMode do
					Test["SetMediaClockTimer_ParametersOfOtherRequest_" .. tostring(updateMode[i]).."_SUCCESS"] = function(self)
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


						--hmi side: expect UI.SetMediaClockTimer request
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:ValidIf(function(_,data)
							if data.params.syncFileName then
								print("SDL resends parameter of other request to HMI")
								return false
							else
								return true
							end
						end)


						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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

				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

			end

		--End test case CommonRequestCheck.8
		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.9
		--Description: CorrelationId is duplicated

			--Requirement id in JAMA/or Jira ID:

			--Verification criteria: response comes with SUCCESS result code.

			function Test:SetMediaClockTimer_CorrelationID_Duplicated_SUCCESS()

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


				--hmi side: expect UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer",
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
				:Times(2)
				:Do(function(_,data)
					--hmi side: sending UI.SetMediaClockTimer response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)


				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
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

		local function Task_APPLINK_15934()

		--Begin test case CommonRequestCheck.10
		--Description: StartTime without mandatory parameter

			--Requirement id in JAMA/or Jira ID:
											--SDLAQ-CRS-61
											--SDLAQ-CRS-515

			--Verification criteria: The request with "startTime" and without updateMode value is sent, the INVALID_DATA response code is returned.

			function Test:SetMediaClockTimer_StartTimeMandatoryMissing()
				--mobile side: sending SetMediaClockTimer request with values of startTime only
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 33
					}
				})

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
			end
		--End of TC CommonRequestCheck.10
		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.11
		--Description: check request with missing endTime

			--Requirement id in JAMA/or Jira ID:
											--SDLAQ-CRS-61
											--SDLAQ-CRS-515

			--Verification criteria: The request with "endTime" and without updateMode value is sent, the INVALID_DATA response code is returned.
			function Test:SetMediaClockTimer_EndTimeMandatoryMissing()
				--mobile side: sending SetMediaClockTimer request with values of endTime only
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					endTime =
					{
						hours = 0,
						minutes = 1,
						seconds = 35
					}
				})

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
			end
			--End of TC CommonRequestCheck.11
		-----------------------------------------------------------------------------------------
		--Begin test case CommonRequestCheck.12
		--Description: endTime less than startTime for COUNTUP

			--Requirement id in JAMA/or Jira ID:
											--SDLAQ-CRS-61
											--SDLAQ-CRS-515

			--Verification criteria: The request with "endTime" provided for COUNTUP is less than startTime , the INVALID_DATA response code is returned.

			function Test:SetMediaClockTimer_endTimeLessStartTimeCOUNTUP()
				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 0,
						minutes = 12,
						seconds = 34
					},
					endTime =
					{
						hours = 0,
						minutes = 10,
						seconds = 10
					},
					updateMode="COUNTUP"
				})

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
			end
			--End of TC CommonRequestCheck.12
		-----------------------------------------------------------------------------------------
		--Begin test case CommonRequestCheck.13
		--Description: endTime less than startTime for COUNTDOWN

			--Requirement id in JAMA/or Jira ID:
											--SDLAQ-CRS-61
											--SDLAQ-CRS-515

			--Verification criteria: The request with "endTime" provided for COUNTDOWN is greater than startTime , the INVALID_DATA response code is returned.

			function Test:SetMediaClockTimer_endTimeGreaterStartTimeCOUNTDOWN()
				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 0,
						minutes = 12,
						seconds = 34
					},
					endTime =
					{
						hours = 01,
						minutes = 20,
						seconds = 15
					},
					updateMode="COUNTDOWN"
				})

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
			end
			--End of TC CommonRequestCheck.13
		-------------------------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.14
		--Description: Resuming CountUp/CountDown Timer

			--Requirement id in JAMA/or Jira ID:
											--SDLAQ-CRS-61
											--SDLAQ-CRS-515

			--Verification criteria:
					--The request with "COUNTUP" or "COUNTDOWN" updateMode value is sent, the SUCCESS response code is returned.
					--The request with "RESUME" updateMode value is sent, the IGNORED response code is returned.

				function Test:SetMediaClockTimer_ResumingCountUpDownTimer()

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 00,
							minutes = 00,
							seconds = 01
						},
						updateMode = "COUNTUP"
					})

					local cid1 = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						updateMode = "RESUME"
					})

					local cid2 = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						startTime =
						{
							hours = 15,
							minutes = 15,
							seconds = 15
						},
						updateMode = "COUNTDOWN"
					})

					local cid3 = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
						updateMode = "RESUME"
					})

					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer")
					:Times(4)
					:Do(function(_,data)
						if data.params.updateMode == "RESUME" then
							--hmi side: sending UI.SetMediaClockTimer response IGNORED
							self.hmiConnection:SendResponse(data.id, data.method, "IGNORED", {})
						else
							--hmi side: sending UI.SetMediaClockTimer response SUCCESS
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						end
					end)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid1, { success = false, resultCode = "IGNORED", info = nil})
					:Timeout(iTimeout)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid2, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid3, { success = false, resultCode = "IGNORED", info = nil})
					:Timeout(iTimeout)

					end
				--End of TC CommonRequestCheck.14
		-------------------------------------------------------------------------------------------------------
	end
	Task_APPLINK_15934()

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
							Test["SetMediaClockTimer_startTime_seconds_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
							Test["SetMediaClockTimer_startTime_minutes_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
							Test["SetMediaClockTimer_startTime_hours_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
							Test["SetMediaClockTimer_endTime_seconds_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
							Test["SetMediaClockTimer_endTime_minutes_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
							Test["SetMediaClockTimer_endTime_hours_InBound_" .. tostring(InBound60[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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


								--hmi side: expect UI.SetMediaClockTimer request
								EXPECT_HMICALL("UI.SetMediaClockTimer",
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

								:Timeout(iTimeout)
								:Do(function(_,data)
									--hmi side: sending UI.SetMediaClockTimer response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)


								--mobile side: expect SetMediaClockTimer response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
		--Description: Check positive responses


			--Begin test case PositiveResponseCheck.1
			--Description: Check info parameter when UI.SetMediaClockTimer response with min-length, max-length

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

				--Verification criteria: verify SDL forward info parameter from HMI response to Mobile

				for i=1,#info do
					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_InBound_" .. tostring(infoName[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = info[i]})
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = info[i]})
							:Timeout(iTimeout)

						end
					end
				end

			--End test case CommonRequestCheck.1
			-----------------------------------------------------------------------------------------

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
		--Description: check negative response


			--Begin test case NegativeResponseCheck.1
			--Description: Check info parameter when UI.SetMediaClockTimer response with outbound values
--[[ToDO: will be updated according to APPLINK-14765: Processing invalid messages from HMI
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62, APPLINK-14551

				--Verification criteria: verify SDL truncates info parameter then forwards it to Mobile

				for i=1,#infoOutBound do
					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_OutBound_" .. tostring(infoOutBound[i]) .."_"..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoOutBound[i]})
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutBound[i])
							end)


							--mobile side: expect SetMediaClockTimer response
							--EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoOutBound_ToMobile[i]})
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoOutBound_ToMobile[i]})


						end
					end
				end

			--End test case CommonRequestCheck.1
			-----------------------------------------------------------------------------------------


			--Begin test case NegativeResponseCheck.2
			--Description: check negative response with invalid values(empty, missing, nonexistent, invalid characters)


				--Begin test case NegativeResponseCheck.2.1
				--Description: check negative response from UI with invalid values(info is empty)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL does not forward empty value of info to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_Empty_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" SDL resends empty value of info parameter to mobile app ")
									return false
								else
									return true
								end
							end)

						end
					end


				--End test case NegativeResponseCheck.2.1
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.2
				--Description: check negative response from UI with invalid values(resultCode is empty)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses INVALID_DATA to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_resultCode_Parameter_Empty_" ..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:SendResponse(data.id, data.method, "", {})
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						end
					end


				--End test case NegativeResponseCheck.2.2
				-----------------------------------------------------------------------------------------



				--Begin test case NegativeResponseCheck.2.3
				--Description: check negative response from UI with invalid values(info is missed)

					--It is covered by test case SetMediaClockTimer_PositiveCase

				--End test case NegativeResponseCheck.2.3
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.4
				--Description: check negative response from UI with invalid values(method is missed)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses GENERIC_ERROR to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_method_Parameter_Missed_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..data.id..',"result":{"code":0}}')

							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:Timeout(12000)

						end
					end


				--End test case NegativeResponseCheck.2.4
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.5
				--Description: check negative response from UI with invalid values(resultCode is missed)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses INVALID_DATA to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_resultCode_Parameter_Missed_" ..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..data.id..',"result":{"method":"UI.SetMediaClockTimer"}}')

							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						end
					end


				--End test case NegativeResponseCheck.2.5
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.6
				--Description: check negative response from UI with invalid values(mandatory parameters is missed)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses GENERIC_ERROR to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_Mandatory_Parameters_Missed_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..data.id..',"result":{}}')

							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:Timeout(12000)

						end
					end


				--End test case NegativeResponseCheck.2.6
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.7
				--Description: check negative response from UI with invalid values(all parameters is missed)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses INVALID_DATA to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_All_Parameters_Missed_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:Send('{}')

							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:Timeout(12000)

						end
					end


				--End test case NegativeResponseCheck.2.7
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.2.8
				--Description: check negative response from UI with invalid values(nonexistent of resultCode)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL responses INVALID_DATA to Mobile

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_resultCode_Parameter_nonexistent_" ..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..data.id..',"result":{"code": 555, "method":"UI.SetMediaClockTimer"}}')

							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(12000)

						end
					end


				--End test case NegativeResponseCheck.2.8
				-----------------------------------------------------------------------------------------


				--Begin test case NegativeResponseCheck.2.9
				--Description: check negative response from UI with invalid values(invalid characters)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL does not forward invalid characters value of info to Mobile

					-- Tab character
					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_Invalid_Character_Tab_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								--self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {info = "in\tfo"})
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "in\tfo")
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" SDL resends invalid value of info parameter to mobile app ")
									return false
								else
									return true
								end
							end)

						end
					end

					-- Newline character
					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_Invalid_Character_NewLine_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "in\nfo"})
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "in\nfo")
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" SDL resends invalid value of info parameter to mobile app ")
									return false
								else
									return true
								end
							end)

						end
					end

				--End test case NegativeResponseCheck.2.9
				-----------------------------------------------------------------------------------------

			--End test case NegativeResponseCheck.2


			--Begin test case NegativeResponseCheck.3
			--Description: check negative response with wrong type

				--Begin test case NegativeResponseCheck.3.1
				--Description: check info parameter is wrong type

					--Requirement id in JAMA/or Jira ID: APPLINK-13276

					--Verification criteria: SDL should not send "info" to app if received "message" is invalid

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_info_Parameter_WrongType_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" SDL resends info parameter which is wrong data type to mobile app ")
									return false
								else
									return true
								end
							end)


						end
					end


				--End test case NegativeResponseCheck.3.1
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.3.2
				--Description: check method parameter is wrong type

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL returns INVALID_DATA

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_method_Parameter_WrongType_" ..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:SendResponse(data.id, 123, "SUCCESS", {})
							end)

							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						end
					end


				--End test case NegativeResponseCheck.3.2
				-----------------------------------------------------------------------------------------

				--Begin test case NegativeResponseCheck.3.3
				--Description: Check resultCode parameter is wrong type

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

					--Verification criteria: SDL will response INVALID_DATA if HMI responses with invalid resultCode parameter

					for j =1, #updateMode do
						Test["UI_SetMediaClockTimer_Response_resultCode_Parameter_WrongType_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
							EXPECT_HMICALL("UI.SetMediaClockTimer",
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

							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetMediaClockTimer response
								self.hmiConnection:SendResponse(data.id, data.method, true, {})
							end)


							--mobile side: expect SetMediaClockTimer response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						end
					end


				--End test case NegativeResponseCheck.3.3
				-----------------------------------------------------------------------------------------

			--End test case NegativeResponseCheck.3

]]
			--Begin test case NegativeResponseCheck.4
			--Description: check negative response with invalid json from UI

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

				--Verification criteria:  The response with wrong JSON syntax is sent, the response comes to Mobile with INVALID_DATA result code.
--APPLINK-13418: SDL ignores all responses from HMI after received response with invalid JSON syntax
--Solution: After run this test case, remove it and run next test cases again.
--[[
				for j =1, #updateMode do
					Test["UI_SetMediaClockTimer_Response_Invalid_JSON_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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

						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})

							--change ":" by " " after "code"
							--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetMediaClockTimer"}}')
							  self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result" {"code":0,"method":"UI.SetMediaClockTimer"}}')
						end)


						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
						:Timeout(15000)

					end
				end
]]--
			--End test case NegativeResponseCheck.4
			-----------------------------------------------------------------------------------------

		--End test suit NegativeResponseCheck



----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile


		--Begin test case ResultCodeCheck.1
		--Description: Check UI returns different resultCode to SDL

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-513, SDLAQ-CRS-514, SDLAQ-CRS-515, SDLAQ-CRS-516, SDLAQ-CRS-517, SDLAQ-CRS-518, SDLAQ-CRS-519, SDLAQ-CRS-520, SDLAQ-CRS-521, SDLAQ-CRS-2629

			--Verification criteria: SDL forwards resultCode to Mobile

			for i = 1, #resultCode do
				for j =1, #updateMode do
					Test["UI_SetMediaClockTimer_Response_resultCode_".. tostring(resultCode[i]) .."_"..tostring(updateMode[j]).."_"..tostring(resultCode[i]) ] = function(self)
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
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							self.hmiConnection:SendResponse(data.id, data.method, resultCode[i], {})
						end)

						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = success[i], resultCode = resultCode[i]})
						:Timeout(iTimeout)

					end
				end
			end

		--End test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.2
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


					--mobile side: expect SetMediaClockTimer response
					self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				end

			end

		--End test case ResultCodeCheck.2

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
	--Description: Check negative response from HMI

		--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode


		--Begin test case HMINegativeCheck.1
		--Description: check requests without responses from HMI

			for j =1, #updateMode do
				Test["SetMediaClockTimer_RequestWithoutUIResponsesFromHMI_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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
					:Timeout(iTimeout)

					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
					:Timeout(15000)

				end
			end


		--End test case HMINegativeCheck.1
		-----------------------------------------------------------------------------------------


		--Begin test case HMINegativeCheck.2
		--Description: invalid structure of response

			for j =1, #updateMode do
				Test["SetMediaClockTimer_UI_InvalidStructureOfResponse_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response	--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetMediaClockTimer"}}')
						self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0}, "method":"UI.SetMediaClockTimer"}')


					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
					:Timeout(15000)

				end
			end


		--End test case HMINegativeCheck.2.1
		-----------------------------------------------------------------------------------------


		--Begin test case HMINegativeCheck.3
		--Description: several responses from HMI to one request

			for j =1, #updateMode do
				Test["SetMediaClockTimer_UI_SeveralResponseToOneRequest_" ..tostring(updateMode[j]).."_INVALID_DATA"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)

				end
			end

		--End test case HMINegativeCheck.3
		-----------------------------------------------------------------------------------------


		--Begin test case HMINegativeCheck.4
		--Description: check response with fake parameters

			--Begin test case HMINegativeCheck.4.1
			--Description: Check responses from HMI (UI) with fake parameter

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

				--Verification criteria: SDL does not resend fake parameters to mobile.

				for j =1, #updateMode do
					Test["SetMediaClockTimer_UI_ResponseWithFakeParamater" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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

						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{fake = "fake"})
						end)


						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:ValidIf (function(_,data)
							if data.payload.fake then
								print(" SDL resends fake parameter to mobile app ")
								return false
							else
								return true
							end
						end)

					end
				end

			--End test case HMINegativeCheck.4.1
			-----------------------------------------------------------------------------------------

			--Begin test case HMINegativeCheck.4.2
			--Description: Check responses from HMI (UI) with parameters of other request

				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

				for j =1, #updateMode do
					Test["SetMediaClockTimer_UI_ResponseWithParamatersOfOtherRequest" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
						EXPECT_HMICALL("UI.SetMediaClockTimer",
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

						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetMediaClockTimer response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{sliderPosition = 5})
						end)


						--mobile side: expect SetMediaClockTimer response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" SDL resends sliderPosition parameter to mobile app ")
								return false
							else
								return true
							end
						end)

					end
				end

			--End test case HMINegativeCheck.4.2
			-----------------------------------------------------------------------------------------

		--End test case HMINegativeCheck.4


		--Begin test case HMINegativeCheck.5
		--Description: Check UI wrong response with wrong HMI correlation id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

			--Verification criteria: SDL responses GENERIC_ERROR to mobile

			for j =1, #updateMode do
				Test["SetMediaClockTimer_UI_ResponseWithWrongHMICorrelationId_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}
						self.hmiConnection:SendResponse(data.id + 1, data.method, "SUCCESS", {})
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
					:Timeout(12000)

				end
			end

		--End test case HMINegativeCheck.5
		----------------------------------------------------------------------------------------


		--Begin test case HMINegativeCheck.6
		--Description: Check UI wrong response with correct HMI id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-62

			--Verification criteria: SDL responses GENERIC_ERROR to mobile

			for j =1, #updateMode do
				Test["SetMediaClockTimer_UI_WrongResponseWithCorrectHMICorrelationId_" ..tostring(updateMode[j]).."_GENERIC_ERROR"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", {})
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
					:Timeout(12000)

				end
			end

		--End test case HMINegativeCheck.6
		----------------------------------------------------------------------------------------


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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: returns SUCCESS

			--Precondition: Clear SetMediaClockTimer to change UI Media clock timer is in default state (empty)
			function Test:SetMediaClockTimer_TC_SetMediaClockTimer_06_Precondition()

				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 01,
						minutes = 02,
						seconds = 03,
					},
					updateMode = "CLEAR"
				})


				--hmi side: expect UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer",
				{
					startTime =
					{
						hours = 01,
						minutes = 02,
						seconds = 03,
					},
					updateMode = "CLEAR"
				})

				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetMediaClockTimer response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}	)
				end)


				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
				:Timeout(iTimeout)
			end

			function Test:SetMediaClockTimer_TC_SetMediaClockTimer_06_CLEAR_SUCCESS()

				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 04,
						minutes = 04,
						seconds = 04,
					},
					updateMode = "CLEAR"
				})


				--hmi side: expect UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer",
				{
					startTime =
					{
						hours = 04,
						minutes = 04,
						seconds = 04,
					},
					updateMode = "CLEAR"
				})

				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetMediaClockTimer response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}	)
				end)


				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
				:Timeout(iTimeout)
			end

		--End test case SequenceCheck.6
		-----------------------------------------------------------------------------------------


		--Begin test case SequenceCheck.7
		--Description: When SetMediaClockTimer with updateMode="RESUME" is sent and the media clock timer is already cleared with the previous request, the IGNORED result code is returned by SDL. General result success=false.

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-520

			--Verification criteria: returns IGNORED

			function Test:SetMediaClockTimer_RESUME_IGNORED()

				--mobile side: sending SetMediaClockTimer request
				local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
				{
					startTime =
					{
						hours = 01,
						minutes = 02,
						seconds = 03,
					},
					updateMode = "RESUME"
				})


				--hmi side: expect UI.SetMediaClockTimer request
				EXPECT_HMICALL("UI.SetMediaClockTimer",
				{
					startTime =
					{
						hours = 01,
						minutes = 02,
						seconds = 03,
					},
					updateMode = "RESUME"
				})

				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetMediaClockTimer response
					self.hmiConnection:SendResponse(data.id, data.method, "IGNORED", {}	)
				end)


				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "IGNORED", info = nil})
				:Timeout(iTimeout)
			end

		--End test case SequenceCheck.7
		-----------------------------------------------------------------------------------------


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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-782

			--Verification criteria: SetMediaClockTimer is allowed in LIMITED HMI level according to policy

			-- Precondition: Change app to LIMITED HMI status
			function Test:ChangeHMIToLimited()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

			end

			for j =1, #updateMode do
				Test["SetMediaClockTimer_LIMITED_" ..tostring(updateMode[j]).."_SUCCESS"] = function(self)
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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}	)
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
					:Timeout(iTimeout)

				end
			end

		--End test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------

		--Begin test case DifferentHMIlevel.2
		--Description: Check SetMediaClockTimer request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-782

			--Verification criteria: SetMediaClockTimer is NOT allowed in NONE HMI level


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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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

			--Precondition: Create the second session
			function Test:CreateTheSecondSession()
				--mobile side: start new session
				self.mobileSession1 = mobile_session.MobileSession(
					self,
					self.mobileConnection)

			end

			--Precondition: Register application the second session
			function Test:RegisterAppInTheSecondSession()
				--mobile side: start new
				self.mobileSession1:StartService(7)
				:Do(function()
						local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
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
						  appID = "1"
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
						  appId2 = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
						:Timeout(2000)
					end)

			end

			--Precondition: Activate second app
			function Test:ActivateSecondApp()
				--hmi side: sending SDL.ActivateApp request
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = appId2})
				EXPECT_HMIRESPONSE(rid)

				--mobile side: expect notification from 2 app
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

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
					EXPECT_HMICALL("UI.SetMediaClockTimer",
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
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}	)
					end)
					:Timeout(iTimeout)



					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
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
