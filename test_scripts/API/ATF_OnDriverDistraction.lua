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
require('user_modules/AppTypes')


---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "OnDriverDistraction" -- set request name

--Debug = {"ecuName"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------


--Create default request
function Test:createRequest()

	return 	{
				state = "DD_ON"
			}

end

---------------------------------------------------------------------------------------------

--This function sends a valid notification from HMI and then the notification is sent to mobile
function Test:verify_SUCCESS_Case(Request)
	--hmi side: sending OnDriverDistraction notification
	self.hmiConnection:SendNotification("UI.OnDriverDistraction",Request)

	if
		Request.fake or
		Request.syncFileName then
		local state = Request.state
		Request = {}
		Request =
			{
				state = state
			}
	end

	--mobile side: expect the response
	EXPECT_NOTIFICATION("OnDriverDistraction", Request)
	:ValidIf (function(_,data)
		if data.payload.fake ~= nil or data.payload.syncFileName ~= nil then
			print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
			return false
		else
			return true
		end
	end)
end

--This function sends a invalid notification from HMI and then the notification is not sent to mobile
function Test:verify_INVALID_Case(Request)
	--hmi side: sending OnDriverDistraction notification
	self.hmiConnection:SendNotification("UI.OnDriverDistraction",Request)

	--mobile side: expect the response
	EXPECT_NOTIFICATION("OnDriverDistraction")
	:Times(0)
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


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For mandatory/conditional request's parameters (mobile protocol)")

	--Begin Test suit PositiveRequestCheck

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
					-- SDLAQ-CRS-182
					-- SDLAQ-CRS-909

			--Verification criteria:
					-- When DD_ON notification is invoked, SDL sends notification to all connected applications on any device if current app HMI Level corresponds to the allowed one in policy table.
					-- When DD_OFF notification is invoked, SDL sends notification to all connected applications on any device if current app HMI Level corresponds to the allowed one in policy table.
					-- DriverDistractionState describes possible states of driver distraction.
						-- DD_ON
						-- DD_OFF
			local onDriverDistractionValue = {"DD_ON", "DD_OFF"}
			for i=1,#onDriverDistractionValue do
				Test["OnDriverDistraction_State_" .. onDriverDistractionValue[i]] = function(self)
					local request = {state = onDriverDistractionValue[i]}
					self:verify_SUCCESS_Case(request)
				end
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
			function Test:OnDriverDistraction_WithoutState()
				self:verify_INVALID_Case({})
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
				function Test:OnDriverDistraction_FakeParam()
					local request = {
										state = "DD_ON",
										fake = "fake"
									}
					self:verify_SUCCESS_Case(request)
				end
			--Begin Test case CommonRequestCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:OnDriverDistraction_ParamsAnotherRequest()
					local request = {
										state = "DD_ON",
										syncFileName = "a"
									}
					self:verify_SUCCESS_Case(request)
				end
			--End Test case CommonRequestCheck.4.2
		--End Test case CommonRequestCheck.4
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			function Test:OnDriverDistraction_InvalidJsonSyntax()
				--hmi side: send UI.OnDriverDistraction
				--":" is changed by ";" after "jsonrpc"
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')
				self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')

				--mobile side: expect OnDriverDistraction notification
				EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
				:Times(0)
			end

			function Test:OnDriverDistraction_InvalidStructure()

				--hmi side: send UI.OnDriverDistraction
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnDriverDistraction","state":"DD_ON"}}')

				--mobile side: expect OnDriverDistraction notification
				EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
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
			--Description: Request with nonexistent state
				function Test:OnDriverDistraction_NonexistentState()
					local request = {
										state = "DD_STATE",
									}
					self:verify_INVALID_Case(request)
				end
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Request without method
				function Test:OnDriverDistraction_WithoutMethod()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"state":"DD_ON"}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
					:Times(0)
				end
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Request without params
				function Test:OnDriverDistraction_WithoutParams()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction"}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Request without state
				function Test:OnDriverDistraction_WithoutState()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: Request with state is empty
				function Test:OnDriverDistraction_StateEmpty()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":""}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.5
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
		--Description:
			--Requirement id in JAMA:
					-- SDLAQ-CRS-182

			--Verification criteria:
					-- When the state is changed (DD_ON/DD_OFF) the notification is sent to all applicabe apps (according to policy table restrictions).

			commonFunctions:newTestCasesGroup("Test case: Check OnDriverDistraction notification with several app")
			-- Precondition 1: Register new media app
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession3 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession3:StartService(7)
			end

			function Test:RegisterAppInterface_MediaApp()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface",
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
																appID ="6",
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
				self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 2: Register new non-media app 1
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession4 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession4:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp1()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp1",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="3",
																ttsName =
																{
																	{
																		text ="NonMediaApp1",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp1",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp1"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp1"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 3: Register new non-media app 2
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession5 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession5:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp2()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession5:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp2",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="4",
																ttsName =
																{
																	{
																		text ="NonMediaApp2",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp2",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp2"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp2"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession5:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 4: Register new non-media app 3
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession6 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession6:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp3()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession6:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp3",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="5",
																ttsName =
																{
																	{
																		text ="NonMediaApp3",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp3",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp3"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp3"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession6:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession6:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end


			--Precondition 5: Activate application to make sure HMI status of 4 apps: FULL, BACKGOUND, LIMITED and NONE
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

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:ChangeMediaAppToLimited()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["MediaApp"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
			end

			function Test:Activate_NonMedia_App1()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp1"]})

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

				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:Activate_NonMedia_App2()
			--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp2"]})

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
				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGOUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			--Sending OnDriverDistraction notification
			function Test:OnDriverDistraction_SeveralApp()
				--hmi side: sending OnDriverDistraction notification
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",{state = "DD_ON"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})
			end
		--End Test case SequenceCheck.1
	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	commonFunctions:newTestCasesGroup("Test case: Check OnDriverDistraction notification in different HMILevel")
		--Begin Test case DifferentHMIlevel.1
		--Description: Check OnDriverDistraction notification when HMI level is NONE

			--Requirement id in JAMA:
				-- SDLAQ-CRS-1309

			--Verification criteria:
				-- SDL doesn't send OnDriverDistraction notification to the app when current app's HMI level is NONE.

			commonSteps:DeactivateAppToNoneHmiLevel()

			function Test:OnDriverDistraction_HMIStatus_NONE()
				local request = {
									state = "DD_ON",
								}
				self:verify_INVALID_Case(request)
			end

			--Postcondition: Activate app
			commonSteps:ActivationApp()
		--End Test case DifferentHMIlevel.1

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.2
		--Description: Check OnDriverDistraction notification when HMI level is LIMITED
			if commonFunctions:isMediaApp() then
				--Precondition: Deactivate app to LIMITED HMI level
				commonSteps:ChangeHMIToLimited()

				for i=1,#onDriverDistractionValue do
					Test["OnDriverDistraction_LIMITED_State_" .. onDriverDistractionValue[i]] = function(self)
						local request = {state = onDriverDistractionValue[i]}
						self:verify_SUCCESS_Case(request)
					end
				end
		--End Test case DifferentHMIlevelChecks.2

		-- Precondition 1: Opening new session
			function Test:AddNewSession()
			  -- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession2:StartService(7)
			end
			-- Precondition 2: Register app2
			function Test:RegisterAppInterface_App2()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="SPT2",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2",
																ttsName =
																{
																	{
																		text ="SyncProxyTester2",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrSPT2",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "SPT2"
					}
				})
				:Do(function(_,data)
					appId2 = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 3: Activate an other media app to change app to BACKGROUND
			function Test:Activate_Media_App2()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})

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

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			end

		elseif Test.isMediaApplication == false then
			--Precondition: Deactivate app to BACKGOUND HMI level
			commonSteps:DeactivateToBackground(self)
		end
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.3
		--Description: Check OnDriverDistraction notification when HMI level is BACKGOUND
			for i=1,#onDriverDistractionValue do
				Test["OnDriverDistraction_BACKGROUND_State_" .. onDriverDistractionValue[i]] = function(self)
					local request = {state = onDriverDistractionValue[i]}
					self:verify_SUCCESS_Case(request)
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
