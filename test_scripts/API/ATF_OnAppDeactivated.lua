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
require('user_modules/AppTypes')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "OnAppDeactivated" -- set request name

--Debug = {"ecuName"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.


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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For mandatory/conditional request's parameters (mobile protocol)")

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
		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA:

			--Verification criteria:
					-- All available reason
			local reasonValue = {"AUDIO", "PHONECALL", "NAVIGATIONMAP", "PHONEMENU", "SYNCSETTINGS", "GENERAL"}
			for i=1,#reasonValue do
				Test["OnAppDeactivated_Reason_" .. reasonValue[i]] = function(self)
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = reasonValue[i]
					})

					if 	reasonValue[i] == "AUDIO" or
						reasonValue[i] == "PHONECALL" then

						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					else
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = hmiLevelValue, audioStreamingState = audibleState, systemContext = "MAIN"})
					end
				end

				commonSteps:ActivationApp()
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters

			-- Not Applicable

		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters
			function Test:OnAppDeactivated_WithoutMandatoryReason()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
			end

			function Test:OnAppDeactivated_WithoutMandatoryAppID()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
			end
		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-14765
			--Verification criteria:
					--SDL must cut off the fake parameters from requests, responses and notifications received from HMI

			--Begin Test case CommonRequestCheck.4.1
			--Description: Parameter not from protocol
				function Test:OnAppDeactivated_FakeParam()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL",
						fakeParam = "fakeParam"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = hmiLevelValue, audioStreamingState = audibleState, systemContext = "MAIN"})
					:ValidIf (function(_,data)
						if data.payload.fakeParam ~= nil then
							print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
							return false
						else
							return true
						end
					end)
				end

				commonSteps:ActivationApp()
			--Begin Test case CommonRequestCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:OnAppDeactivated_ParamsAnotherRequest()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL",
						syncFileName = "a"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = hmiLevelValue, audioStreamingState = audibleState, systemContext = "MAIN"})
					:ValidIf (function(_,data)
						if data.payload.syncFileName ~= nil then
							print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
							return false
						else
							return true
						end
					end)
				end

				commonSteps:ActivationApp()
			--End Test case CommonRequestCheck.4.2
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			function Test:OnAppDeactivated_InvalidJsonSyntax()
				--hmi side: send BasicCommunication.OnAppDeactivated
				--":" is changed by ";" after "jsonrpc"
				self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnAppDeactivated","params":{"appID":'..self.applications["Test Application"]..',"reason":"GENERAL"}}')

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
			end

			function Test:OnAppDeactivated_InvalidStructure()
				--hmi side: send BasicCommunication.OnAppDeactivated
				self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnAppDeactivated", "appID":'..self.applications["Test Application"]..',"reason":"GENERAL"}}')

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
			end
		--End Test case CommonRequestCheck.5
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: Check of each request parameter value in bound and boundary conditions

			-- Not Applicable

		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			-- Not Applicable

		--End Test suit PositiveRequestCheck


----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, non existent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Request with nonexistent reason
				function Test:OnAppDeactivated_NonexistentReason()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "REASON"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Request without method
				function Test:OnAppDeactivated_WithoutMethod()
					--hmi side: send BasicCommunication.OnAppDeactivated
					self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"appID":'..self.applications["Test Application"]..',"reason":"GENERAL"}}')

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Request without params
				function Test:OnAppDeactivated_WithoutParams()
					--hmi side: send BasicCommunication.OnAppDeactivated
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnAppDeactivated"}')

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Request with reason is empty
				function Test:OnAppDeactivated_ReasonEmpty()
					--hmi side: send BasicCommunication.OnAppDeactivated
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnAppDeactivated","params":{"appID":'..self.applications["Test Application"]..',"reason":""}}')

					--mobile side: expect OnAppDeactivated notification
					EXPECT_NOTIFICATION("OnAppDeactivated")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.4
		--End Test suit NegativeRequestCheck

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------


	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Begin Test case SequenceCheck.1
		--Description: Cover TC_OnAppDeactivated_01

			--Requirement id in JAMA:
					-- SDLAQ-TC-392

			--Verification criteria:
					-- Check changing HMI level of app from FULL to BACKGROUND if reason of
					-- OnAppDeactivated is "AUDIO" (when user switches to one of media entertainment screen i.e FM, CD, AM ... e.t.c)

				-- Cover by CommonRequestCheck.1

		--End Test case SequenceCheck.1

		-----------------------------------------------------------------------------------------
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppDeactivated_02")
		--Begin Test case SequenceCheck.2
		--Description: Cover TC_OnAppDeactivated_02

			--Requirement id in JAMA:
					-- SDLAQ-TC-393

			--Verification criteria:
					-- Check changing HMI level of app from LIMITED to BACKGROUND if reason of
					-- OnAppDeactivated is "AUDIO" (when user switches to one of media entertainment screen i.e FM, CD, AM ... e.t.c)
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession2:StartService(7)
			end

			function Test:RegisterAppInterface_MediaApp()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="MediaApp",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2",
																ttsName =
																{
																	{
																		text ="MediaApp",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrMediaApp",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "MediaApp"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			function Test:Activate_MediaApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
									:Do(function(_,data)

										--hmi side: send request SDL.OnAllowSDLFunctionality
										self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
											{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:OnAppDeactivated_PressIButton()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["MediaApp"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			end

			function Test:OnAppDeactivated_GoToCD()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["MediaApp"],
					reason = "AUDIO"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
		--End Test case SequenceCheck.2

		-----------------------------------------------------------------------------------------
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppDeactivated_03")
		--Begin Test case SequenceCheck.3
		--Description: Cover TC_OnAppDeactivated_03

			--Requirement id in JAMA:
					-- SDLAQ-TC-394

			--Verification criteria:
					-- Check changing HMI levels of apps from LIMITED and FULL to BACKGROUND if reason of
					-- OnAppDeactivated is "AUDIO" (when user switches to one of media entertainment screen i.e FM, CD, AM ... e.t.c)
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession3 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession3:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="3",
																ttsName =
																{
																	{
																		text ="NonMediaApp",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			function Test:Activate_MediaApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
									:Do(function(_,data)

										--hmi side: send request SDL.OnAllowSDLFunctionality
										self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
											{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:OnAppDeactivated_PressIButton()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["MediaApp"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			end

			function Test:Activate_NonMediaApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
									:Do(function(_,data)

										--hmi side: send request SDL.OnAllowSDLFunctionality
										self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
											{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:OnAppDeactivated_GoToCD()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["NonMediaApp"],
					reason = "AUDIO"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
		--End Test case SequenceCheck.3
	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	commonFunctions:newTestCasesGroup("Test case: Check OnAppDeactivated notification in different HMILevel")
		--Begin Test case DifferentHMIlevel.1
		--Description: Check OnAppDeactivated notification when HMI level is NONE

			--Requirement id in JAMA:

			--Verification criteria:
				-- There is no notification send to mobile app

			commonSteps:DeactivateAppToNoneHmiLevel()

			for i=1,#reasonValue do
				Test["OnAppDeactivated_NONE_Reason_" .. reasonValue[i]] = function(self)
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = reasonValue[i]
					})

					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
				end
			end

			--Postcondition: Activate app
			commonSteps:ActivationApp()
		--End Test case DifferentHMIlevel.1

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.2
		--Description: Check OnAppDeactivated notification when HMI level is LIMITED
			if commonFunctions:isMediaApp() then

			-- Precondition 3: Activate an other media app to change app to BACKGROUND
			function Test:Activate_MediaApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

							--hmi side: sending SDL.GetUserFriendlyMessage request
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
												{language = "EN-US", messageCodes = {"DataConsent"}})

							--hmi side: expect SDL.GetUserFriendlyMessage response
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
								:Do(function(_,data)

									--hmi side: send request SDL.OnAllowSDLFunctionality
									self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
										{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
		else
			--Precondition: Deactivate app to BACKGOUND HMI level
			commonSteps:DeactivateToBackground()
		end
		-----------------------------------------------------------------------------------------
--TODO: Need to be update according to APPLINK-17253
		--Begin Test case DifferentHMIlevelChecks.3
		--Description: Check OnAppDeactivated notification when HMI level is BACKGOUND
			for i=1,#reasonValue do
				Test["OnAppDeactivated_BACKGROUND_Reason_" .. reasonValue[i]] = function(self)
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = reasonValue[i]
					})

					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)
				end
			end
		--End Test case DifferentHMIlevelChecks.3
	--End Test suit DifferentHMIlevel


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
