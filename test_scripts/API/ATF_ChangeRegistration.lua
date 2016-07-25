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
local commonSteps=require('user_modules/shared_testcases/commonSteps')
local commonFunctions=require('user_modules/shared_testcases/commonFunctions')
local commonTestCases=require('user_modules/shared_testcases/commonTestCases')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------

local infoMessage = string.rep("a",1000)

---------------------------------------------------------------------------------------------

function changeRegistrationAllParams()
	local temp = {
		language ="EN-US",
		hmiDisplayLanguage ="EN-US",
		appName ="SyncProxyTester",
		ttsName =
		{
			{
				text ="SyncProxyTester",
				type ="TEXT",
			},
		},
		ngnMediaScreenAppName ="SPT",
		vrSynonyms =
		{
			"VRSyncProxyTester",
		},
	}
	return temp
end
function Test:changeRegistrationInvalidData(paramsSend)
        local cid = self.mobileSession:SendRPC("ChangeRegistration",paramsSend)
        EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
function Test:changeRegistrationSuccess(paramsSend)
	--mobile side: send ChangeRegistration request
	local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

	--hmi side: expect UI.ChangeRegistration request
	EXPECT_HMICALL("UI.ChangeRegistration",
	{
		appName = paramsSend.appName,
		language = paramsSend.hmiDisplayLanguage,
		ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
	})
	:Do(function(_,data)
		--hmi side: send UI.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect VR.ChangeRegistration request
	EXPECT_HMICALL("VR.ChangeRegistration",
	{
		language = paramsSend.language,
		vrSynonyms = paramsSend.vrSynonyms
	})
	:Do(function(_,data)
		--hmi side: send VR.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect TTS.ChangeRegistration request
	EXPECT_HMICALL("TTS.ChangeRegistration",
	{
		language = paramsSend.language,
		ttsName = paramsSend.ttsName
	})
	:Do(function(_,data)
		--hmi side: send TTS.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--mobile side: expect ChangeRegistration response
	EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })

	--Added for manual test cases
	--hmi side: expect BasicCommunication.UpdateAppList after changeRegistration successfully.
	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
	:Do(function(_,data)
		self.applications[paramsSend.appName] = data.params.applications[1].appID
	end)
	:Times(AnyNumber())

end
function Test:changeRegistrationWarning(paramsSend)
	--mobile side: send ChangeRegistration request
	local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

	--hmi side: expect UI.ChangeRegistration request
	EXPECT_HMICALL("UI.ChangeRegistration",
	{
		appName = paramsSend.appName,
		language = paramsSend.language,
		ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
	})
	:Do(function(_,data)
		--hmi side: send UI.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect VR.ChangeRegistration request
	EXPECT_HMICALL("VR.ChangeRegistration",
	{
		language = paramsSend.language,
		vrSynonyms = paramsSend.vrSynonyms
	})
	:Do(function(_,data)
		--hmi side: send VR.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect TTS.ChangeRegistration request
	EXPECT_HMICALL("TTS.ChangeRegistration",
	{
		language = paramsSend.language,
		ttsName = paramsSend.ttsName
	})
	:Do(function(_,data)
		--hmi side: send TTS.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS",{})
	end)

	--mobile side: expect ChangeRegistration response
	EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "WARNINGS" })
end
function setTTSName(size, textValue)
	if textValue == nil then
		textValue = "SyncProxyTesterTTS"
	else
	textValue = tostring(i)..string.rep("v",textValue-string.len(tostring(i)))
	end

	local temp = {}
	for i=1, size do
		temp[i] = {
				text =textValue,
				type ="TEXT",
			}
	end
	return temp
end
function setVRSynonyms(size, textValue)
	if textValue == nil then
		textValue =  "VRSyncProxyTester"
	else
		textValue = tostring(i)..string.rep("v",textValue-string.len(tostring(i)))
	end

	local temp = {}
	for i=1, size do
		temp[i] = textValue
	end
	return temp
end
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------


	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1.Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2. Activation off application
		function Test:ActivationApp()
			appID1 = self.applications["Test Application"]
			self.appID1 = appID1

			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

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
							--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							EXPECT_HMIRESPONSE(RequestId)
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

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

		end




---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck

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

    	--Begin Test case CommonRequestCheck.1
    	--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-133

			--Verification criteria: Changes VR+TTS and hmiDisplay languages of the application to the new requested ones.
								--Languages can be changed separately:  TTS+VR and hmiDisplayLanguage have different values.
			function Test:ChangeRegistration_Positive()
				self:changeRegistrationSuccess(changeRegistrationAllParams())
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-133

			--Verification criteria: Changes VR+TTS and hmiDisplay languages of the application to the new requested ones.
								--Languages can be changed separately:  TTS+VR and hmiDisplayLanguage have different values.
			function Test:ChangeRegistration_MandatoryOnly()
				local paramsSend = {
										language ="EN-US",
										hmiDisplayLanguage ="EN-US",
									}

				self:changeRegistrationSuccess(paramsSend)
			end
			--End Test case CommonRequestCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description: With conditional appName parameter
				function Test:ChangeRegistration_appNameConditional()
					local paramsSend = {
										language ="EN-US",
										hmiDisplayLanguage ="EN-US",
										appName = "SyncProxyTester"
									}

					self:changeRegistrationSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.3
			--Description: With conditional ttsName parameter
				function Test:ChangeRegistration_ttsNameConditional()
					local paramsSend = {
										language ="EN-US",
										hmiDisplayLanguage ="EN-US",
										ttsName = {
													{
														text ="SyncProxyTester",
														type ="TEXT",
													},
												}
									}

					self:changeRegistrationSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.4
			--Description: With conditional ngnMediaScreenAppName parameter
				function Test:ChangeRegistration_ngnMediaScreenAppNameConditional()
					local paramsSend = {
										language ="EN-US",
										hmiDisplayLanguage ="EN-US",
										ngnMediaScreenAppName = "SPT"
									}

					self:changeRegistrationSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.5
			--Description: With conditional vrSynonyms parameter
				function Test:ChangeRegistration_vrSynonymsConditional()
					local paramsSend = {
										language ="EN-US",
										hmiDisplayLanguage ="EN-US",
										vrSynonyms = {
														"VRSyncProxyTester",
													}
									}

					self:changeRegistrationSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.5
		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-697

			--Verification criteria:
				--The request without "language" is sent, INVALID_DATA response code is returned.
				--The request without "hmiDisplayLanguage" is sent, INVALID_DATA response code is returned.

			--Begin Test case CommonRequestCheck.3.1
			--Description: Request without any mandatory parameter (INVALID_DATA)
				function Test:ChangeRegistration_AllParamsMissing()
					self:changeRegistrationInvalidData({})
				end
			--End Test case CommonRequestCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2
			--Description: language is missing
				function Test:ChangeRegistration_languageMissing()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.language = nil

					self:changeRegistrationInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.3
			--Description: hmiDisplayLanguage is missing
				function Test:ChangeRegistration_hmiDisplayLanguageMissing()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.hmiDisplayLanguage = nil

					self:changeRegistrationInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.4
			--Description: ttsName: TTSChunk: text parameter is missing
				function Test:ChangeRegistration_ttsNameTTSChunkTextMissing()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName =
										{

											{
												type ="TEXT",
											},
										}

					self:changeRegistrationInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.5
			--Description: ttsName: TTSChunk: type parameter is missing
				function Test:ChangeRegistration_ttsNameTTSChunkTypeMissing()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName =
										{

											{
												text ="SyncProxyTester"
											},
										}

					self:changeRegistrationInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.5

		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters
				function Test:ChangeRegistration_FakeParams()
					local paramsSend = changeRegistrationAllParams()
					paramsSend["fakeParam"] = "fakeParam"
					local ttsNameWithoutFake =
						{
							{
								text ="SyncProxyTester",
								type ="TEXT",
							},
						}
					paramsSend.ttsName[1]["fakeParam"] = "fakeParam"

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.language,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
							return false
						else
							return true
						end
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
							return false
						else
							return true
						end
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = ttsNameWithoutFake
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsName[1].fakeParam or
							data.params.fakeParam then
							return false
						else
							return true
						end
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:ChangeRegistration_ParamsAnotherRequest()
					local paramsSend = changeRegistrationAllParams()
					paramsSend["ttsChunks"] = {
											{
												text ="SpeakFirst",
												type ="TEXT",
											},
											{
												text ="SpeakSecond",
												type ="TEXT",
											},
										}

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.language,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
							return false
						else
							return true
						end
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
							return false
						else
							return true
						end
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
							return false
						else
							return true
						end
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-697

			--Verification criteria:  The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
			function Test:ChangeRegistration_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg =
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 30,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"vrSynonyms" ["VRSyncProxyTester"],"ttsName":[{"text":"SyncProxyTester","type":"TEXT"}],"language":"EN-US","appName":"SyncProxyTester","ngnMediaScreenAppName":"SPT","hmiDisplayLanguage":"EN-US"}'
				  }
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
--[[TODO: Update CRQ ID and verification. Check if APPLINK-13892 is resolved
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with different conditions of correlationID

			--Requirement id in JAMA/or Jira ID:

			--Verification criteria:
				-- correlationID: duplicate value
			function Test:ChangeRegistration_correlationIdDuplicateValue()
				local paramsSend = changeRegistrationAllParams()

				--mobile side: send ChangeRegistration request
				local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration",
				{
					appName = paramsSend.appName,
					language = paramsSend.language,
					ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
				})
				:Do(function(_,data)
					--hmi side: send UI.ChangeRegistration response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)
				:Times(2)

				--hmi side: expect VR.ChangeRegistration request
				EXPECT_HMICALL("VR.ChangeRegistration",
				{
					language = paramsSend.language,
					vrSynonyms = paramsSend.vrSynonyms
				})
				:Do(function(_,data)
					--hmi side: send VR.ChangeRegistration response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)
				:Times(2)

				--hmi side: expect TTS.ChangeRegistration request
				EXPECT_HMICALL("TTS.ChangeRegistration",
				{
					language = paramsSend.language,
					ttsName = paramsSend.ttsName
				})
				:Do(function(_,data)
					--hmi side: send TTS.ChangeRegistration response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)
				:Times(2)

				--mobile side: expect ChangeRegistration response
				EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 30,
							rpcCorrelationId = CorIdChangeRegistration,
							payload          = '{"vrSynonyms":["VRSyncProxyTester"],"ttsName":[{"text":"SyncProxyTester","type":"TEXT"}],"language":"EN-US","appName":"SyncProxyTester","ngnMediaScreenAppName":"SPT","hmiDisplayLanguage":"EN-US"}'
						}
						self.mobileSession:Send(msg)
					end
				end)
			end
		--End Test case CommonRequestCheck.6
]]
	--End Test suit CommonRequestCheck

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
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA:
							-- SDLAQ-CRS-133,
							-- SDLAQ-CRS-685

				--Verification criteria:
							--Requested app languages has been changed successfully, resultCode "SUCCESS" is returned to mobile app.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: appName: lower bound = 1
							--appName type="String" maxlength="100" mandatory="false"
					function Test:ChangeRegistration_appNameLowerBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "S"

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: appName: upper bound = 100
							--appName type="String" maxlength="100" mandatory="false"
					function Test:ChangeRegistration_appNameUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg"

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: ttsName: Array lower bound
							--ttsName type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false"
					function Test:ChangeRegistration_ttsNameArrayLowerBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName = {
												{
													text ="SyncProxyTester",
													type ="TEXT",
												},
											}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: ttsName: Array upper bound
					function Test:ChangeRegistration_ttsNameArrayUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName = setTTSName(100)

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: ttsName: text lower and upper bound
					function Test:ChangeRegistration_ttsNameTextLowerUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName ={
												{
													text ="a",
													type ="TEXT",
												},
												{
													text ="aaaaa01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
													type ="TEXT",
												}
											}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: ngnMediaScreenAppName: lower bound
					function Test:ChangeRegistration_ngnNameLowerBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName ="a"

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: ngnMediaScreenAppName: upper bound
					function Test:ChangeRegistration_ngnNameUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgh",

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: vrSynonyms: Array lower bound
					function Test:ChangeRegistration_VRSynArrayLowerBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"VRSyncProxyTester",
												}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.9
				--Description: vrSynonyms: Array upper bound
					function Test:ChangeRegistration_VRSynArrayUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms = setVRSynonyms(100)

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.10
				--Description: vrSynonyms: synonym lower and upper bound
					function Test:ChangeRegistration_VVRSynLowerUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"a",
													"01234567890abcdASDF!@#$%^*()-_+|~{}[]:,a",
												}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.11
				--Description: lower bound of all parameters
					function Test:ChangeRegistration_LowerBound()
						local paramsSend = {
											language ="EN-US",
											hmiDisplayLanguage ="EN-US",
											appName ="S",
											ttsName =
											{

												{
													text ="S",
													type ="TEXT",
												},
											},
											ngnMediaScreenAppName ="S",
											vrSynonyms =
											{
												"S",
											}
										}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.11

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.12
				--Description: upper bound of all parameters
					function Test:ChangeRegistration_UpperBound()
						local paramsSend = {
											language ="EN-US",
											hmiDisplayLanguage ="EN-US",
											appName ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
											ttsName = setTTSName(100, 500),
											ngnMediaScreenAppName ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
											vrSynonyms = setVRSynonyms(100, 40)
										}

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.12
			--End Test case PositiveRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveRequestCheck.2
			--Description: Check processing request with all possible languages for language, hmiDisplayLanguage parameter

				--Requirement id in JAMA:
							-- SDLAQ-CRS-133,
							-- SDLAQ-CRS-685,
							-- SDLAQ-CRS-2548,
							-- SDLAQ-CRS-2549
							-- APPLINK-13745
							-- SDLAQ-CRS-701

				--Verification criteria:
							--For current implementation the result code for changing "EN_AU","ZH_CN" language on mobile app should be REJECTED to emulate the case when the the languages are not supported by HMI.
--[[TODO: Only check all languages when APPLINK-13745 is resolved
				local languageValues = {"AR-SA", "CS-CZ", "DA-DK", "DE-DE", "EN-AU",
										"EN-GB", "EN-US", "ES-ES", "ES-MX", "FR-CA",
										"FR-FR", "IT-IT", "JA-JP", "KO-KR", "NL-NL",
										"NO-NO", "PL-PL", "PT-PT", "PT-BR", "RU-RU",
										"SV-SE", "TR-TR", "ZH-CN", "ZH-TW", "NL-BE",
										"EL-GR", "HU-HU", "FI-FI", "SK-SK"}
]]
				local languageValues = {"AR-SA", "CS-CZ", "DA-DK", "DE-DE", "EN-AU",
										"EN-GB", "EN-US", "ES-ES", "ES-MX", "FR-CA",
										"FR-FR", "IT-IT", "JA-JP", "KO-KR", "NL-NL",
										"NO-NO", "PL-PL", "PT-PT", "PT-BR", "RU-RU",
										"SV-SE", "TR-TR", "ZH-CN", "ZH-TW", "NL-BE",
										"EL-GR", "HU-HU", "FI-FI", "SK-SK"}
				--Begin Test case PositiveRequestCheck.2.1
				--Description:	All possible languages for language parameter
				--Note: During SDL-HMI starting SDL should request HMI UI.GetSupportedLanguages, VR.GetSupportedLanguages, TTS.GetSupportedLanguages and HMI should respond with all languages
				--specified in this test (added new languages which should be supported by SDL - APPLINK-13745: "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK")
					for i=1,#languageValues do
						if languageValues[i] ~= "EN-AU" and languageValues[i] ~= "ZH-CN" then
							Test["ChangeRegistration_Languages" .. tostring(languageValues[i])] = function(self)
								local paramsSend = changeRegistrationAllParams()
								paramsSend.language = languageValues[i]

								self:changeRegistrationSuccess(paramsSend)
							end
						else
							Test["ChangeRegistration_Languages" .. tostring(languageValues[i])] = function(self)
								local paramsSend = changeRegistrationAllParams()
								paramsSend.language = languageValues[i]

								--mobile side: send ChangeRegistration request
								local cid = self.mobileSession:SendRPC("ChangeRegistration",paramsSend)

								--mobile side: Expected ChangeRegistration response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
							end
						end
					end
				--End Test case PositiveRequestCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.2.2
				--Description:	All possible languages for hmiDisplayLanguage parameter
					for i=1,#languageValues do
						if languageValues[i] ~= "EN-AU" and languageValues[i] ~= "ZH-CN" then
							Test["ChangeRegistration_HMILanguage" .. tostring(languageValues[i])] = function(self)
								local paramsSend = changeRegistrationAllParams()
								paramsSend.hmiDisplayLanguage = languageValues[i]

								self:changeRegistrationSuccess(paramsSend)
							end
						else
							Test["ChangeRegistration_Languages" .. tostring(languageValues[i])] = function(self)
								local paramsSend = changeRegistrationAllParams()
								paramsSend.hmiDisplayLanguage = languageValues[i]

								--mobile side: send ChangeRegistration request
								local cid = self.mobileSession:SendRPC("ChangeRegistration",paramsSend)

								--mobile side: Expected ChangeRegistration response
								EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
							end
						end
					end
				--End Test case PositiveRequestCheck.2.2
			--End Test case PositiveRequestCheck.2
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
--[[TODO: update according to APPLINK-14551
		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA: SDLAQ-CRS-134

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode..

				--Begin Test case PositiveResponseCheck.1.1
				--Description: UI response with info parameter lower bound
					function Test:ChangeRegistration_UIResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a" })
					end
				--End Test case PositiveResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description: VR response with info parameter lower bound
					function Test:ChangeRegistration_VRResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a" })
					end
				--End Test case PositiveResponseCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.3
				--Description: TTS response with info parameter lower bound
					function Test:ChangeRegistration_TTSResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a" })
					end
				--End Test case PositiveResponseCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.4
				--Description: UI & VR & TTS response with info parameter lower bound
					function Test:ChangeRegistration_UIVRTTSResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "c")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a.b.c" })
					end
				--End Test case PositiveResponseCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.5
				--Description: UI & VR response with info parameter lower bound
					function Test:ChangeRegistration_UIVRResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a.b" })
					end
				--End Test case PositiveResponseCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.6
				--Description: UI & TTS response with info parameter lower bound
					function Test:ChangeRegistration_UITTSResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "c")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a.c" })
					end
				--End Test case PositiveResponseCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.7
				--Description: VR & TTS response with info parameter lower bound
					function Test:ChangeRegistration_UITTSResponseInfoLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "c")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "b.c" })
					end
				--End Test case PositiveResponseCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.8
				--Description: UI response with info parameter upper bound
					function Test:ChangeRegistration_UIResponseInfoUpperBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= infoMessage })
					end
				--End Test case PositiveResponseCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.9
				--Description: VR response with info parameter upper bound
					function Test:ChangeRegistration_VRResponseInfoUpperBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= infoMessage })
					end
				--End Test case PositiveResponseCheck.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.10
				--Description: TTS response with info parameter upper bound
					function Test:ChangeRegistration_TTSResponseInfoUpperBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= infoMessage })
					end
				--End Test case PositiveResponseCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.11
				--Description: UI & VR & TTS response with info parameter upper bound
					function Test:ChangeRegistration_UIVRTTSResponseInfoUpperBound()
						local infoMessage = string.rep("a",999)
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a"..infoMessage)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "b"..infoMessage)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "c"..infoMessage)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info= "a"..infoMessage })
					end
				--End Test case PositiveResponseCheck.1.11
			--End Test case PositiveResponseCheck.1
		--End Test suit PositiveResponseCheck
]]
----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

	--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-697

				--Verification criteria:
					--The request with values out of bounds is sent, the response comes with INVALID DATA result code.

				--Begin Test case NegativeRequestCheck.1.1
				--Description: appName: out of upper bound = 101
					function Test:ChangeRegistration_appNameOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "1234567890001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,0123456"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.2
				--Description: ttsName: Array out upper bound
					function Test:ChangeRegistration_ttsNameArrayOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName = setTTSName(101)

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: ttsName: text out upper bound
					function Test:ChangeRegistration_ttsNameTextOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = "67890001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.4
				--Description: ngnMediaScreenAppName: out upper bound
					function Test:ChangeRegistration_ngnNameOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName ="123456789001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: vrSynonyms: Array out upper bound
					function Test:ChangeRegistration_VRSynArrayOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms = setVRSynonyms(101)

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.6
				--Description: vrSynonyms: synonym out upper bound
					function Test:ChangeRegistration_VRSynOutUpperBound()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"12345678900123abcdASDF!@#$%^*()-_+|~{}[]:",
												}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.6

			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID:
					--SDLAQ-CRS-697
					--APPLINK-9011

				--Verification criteria:
					--The request with empty "language" value is sent, the response with INVALID_DATA code is returned.
					--The request with empty "hmiDisplayLanguage" value is sent, the response with INVALID_DATA code is returned.
					--The request with empty "ttsName" is sent, the response with INVALID_DATA code is returned.
					--The request with empty "appName" is sent, the response with INVALID_DATA code is returned.
					--SDL must allow (transfer to HMI) 'ttsChunk' with 'text:""' (empty string)

				--Begin Test case NegativeRequestCheck.2.1
				--Description: appName: is empty (out lower bound)
					function Test:ChangeRegistration_appNameEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = ""

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.2
				--Description: ttsName: Array is empty (out lower bound)
					function Test:ChangeRegistration_ttsNameArrayEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName = {}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.3
				--Description: ttsName: TTSChunk is empty
					function Test:ChangeRegistration_ttsNameArrayEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName = {{}}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.4
				--Description: ttsName: text is empty
					function Test:ChangeRegistration_ttsNameArrayEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = ""

						self:changeRegistrationSuccess(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.5
				--Description: ttsName: type is empty
					function Test:ChangeRegistration_ttsNameArrayEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].type = ""

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.6
				--Description: ngnMediaScreenAppName: empty (out lower bound)
					function Test:ChangeRegistration_ngnNameEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName =""

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.7
				--Description: vrSynonyms: Array out lower bound (empty)
					function Test:ChangeRegistration_VRSynArrayEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms = {}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.8
				--Description: vrSynonyms: synonym is empty (out lower bound)
					function Test:ChangeRegistration_VRSynEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms = {""}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.9
				--Description: language empty
					function Test:ChangeRegistration_languageEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.language = ""

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.10
				--Description: hmiDisplayLanguage empty
					function Test:ChangeRegistration_hmiDisplayLanguageEmpty()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.hmiDisplayLanguage = ""

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.10


			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-697

				--Verification criteria:
					--The request with wrong data in "language" parameter (e.g. doesn't exist in enum) is sent , the response with INVALID_DATA code is returned.
					--The request with wrong data in "hmiDisplayLanguage" parameter (e.g. doesn't exist in enum) is sent , the response with INVALID_DATA code is returned.

				--Begin Test case NegativeRequestCheck.3.1
				--Description: appName: wrong type
					function Test:ChangeRegistration_appNameWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = 111

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: ttsName: text parameter with wrong type
					function Test:ChangeRegistration_ttsNameTextWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = 123

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.3
				--Description: ngnMediaScreenAppName: wrong type
					function Test:ChangeRegistration_ngnNameWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName = 123

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.4
				--Description: vrSynonyms: synonym wrong type
					function Test:ChangeRegistration_VRSynWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													123
												}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.5
				--Description: language wrong type
					function Test:ChangeRegistration_VRSynWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.language = "English"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.6
				--Description: hmiDisplayLanguage wrong type
					function Test:ChangeRegistration_VRSynWrongType()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.hmiDisplayLanguage = "English"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.6
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				--Requirement id in JAMA/or Jira ID:
					-- SDLAQ-CRS-697
					-- APPLINK-8687

				--Verification criteria:
					--[[The request with the only whitespace symbol in "appName" is sent, the response with INVALID_DATA code is returned.
						The request with the only whitespace symbol in "ttsName" is sent, the response with INVALID_DATA code is returned.
						The request with the only whitespace symbol in "vrSynonyms" is sent, the response with INVALID_DATA code is returned.
						The request with a new line character in "ttsName" is sent, the response with INVALID_DATA code is returned.
						The request with a new line character in "appName" is sent, the response with INVALID_DATA code is returned.
					]]

				--Begin Test case NegativeRequestCheck.4.1
				--Description: appName: Escape sequence \n
					function Test:ChangeRegistration_appNameNewLineChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "Sy\ncProxyTester"
						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.2
				--Description: appName: Escape sequence \t
					function Test:ChangeRegistration_appNameNewTabChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "SyncProxyTes\ter"
						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.3
				--Description: appName: White space only
					function Test:ChangeRegistration_appNameWhitespaceOnly()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "        "
						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.4
				--Description: ttsName: text with escape sequence \n
					function Test:ChangeRegistration_ttsNameTextNewLineChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = "Sync\nProxyTester"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.5
				--Description: ttsName: text with escape sequence \t
					function Test:ChangeRegistration_ttsNameTextNewTabChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = "SyncnProxyTes\ter"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.6
				--Description: ttsName: text with whitespace only
					function Test:ChangeRegistration_ttsNameTextWhiteSpaceOnly()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].text = "       "

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.7
				--Description: ngnMediaScreenAppName: Escape sequence \n
					function Test:ChangeRegistration_ngnNameNewLineChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName ="Sy\ncProxyTester"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.8
				--Description: ngnMediaScreenAppName: Escape sequence \t
					function Test:ChangeRegistration_ngnNameNewTabChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName ="SyncProxyTes\ter"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.9
				--Description: ngnMediaScreenAppName: White space only
					function Test:ChangeRegistration_ngnNameWhiteSpaceOnly()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ngnMediaScreenAppName ="     "

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.10
				--Description: vrSynonyms: Escape sequence \n
					function Test:ChangeRegistration_VRSyNewLineChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"Sy\nonym",
												}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.10

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.8
				--Description: vrSynonyms: Escape sequence \t
					function Test:ChangeRegistration_VRSyNewTabChar()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"Syn\tonym",
												}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.9
				--Description: vrSynonyms: White space only
					function Test:ChangeRegistration_VRSyWhiteSpaceOnly()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.vrSynonyms =
												{
													"     "
												}

						self:changeRegistrationInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.9

			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with value not existed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-697

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case value not existed

				--Begin Test case NegativeRequestCheck.5.1
				--Description:  ttsName: type is not existed
					function Test:ChangeRegistration_ttsNameTypeNotExist()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.ttsName[1].type = "ANY"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.2
				--Description:  language is not exist
					function Test:ChangeRegistration_languageNotExist()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.language = "AA-AA"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.3
				--Description:  hmiDisplayLanguage is not exist
					function Test:ChangeRegistration_hmiDisplayLanguageNotExist()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.hmiDisplayLanguage = "AA-AA"

						self:changeRegistrationInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.3

			--End Test case NegativeRequestCheck.5

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.6
			--Description: Check processing request with value is duplicate

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-696

				--Verification criteria: Requested app languages has been changed successfully, resultCode "SUCCESS" is returned to mobile app.

				--Begin Test case NegativeRequestCheck.6.1
				--Description:  appName, vrSynonym is duplicated with current appName, vrSynonym
					function Test:ChangeRegistration_Positive()
						self:changeRegistrationSuccess(changeRegistrationAllParams())
					end

					function Test:ChangeRegistration_DuplicateCurrentAppNameVRSynonym()
						self:changeRegistrationSuccess(changeRegistrationAllParams())
					end
				--Begin Test case NegativeRequestCheck.6.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.2
				--Description:  appName, vrSynonym is duplicated with current vrSynonym, appName
					function Test:ChangeRegistration_Positive()
						self:changeRegistrationSuccess(changeRegistrationAllParams())
					end

					function Test:ChangeRegistration_DuplicateCurrentAppNameVRSynonym()
						local paramsSend = changeRegistrationAllParams()
						paramsSend.appName = "VRSyncProxyTester"
						paramsSend.vrSynonyms = {"SyncProxyTester"}

						self:changeRegistrationSuccess(changeRegistrationAllParams())
					end
				--Begin Test case NegativeRequestCheck.6.2
			--End Test case NegativeRequestCheck.6

		--End Test suit NegativeRequestCheck
--[[ TODO: update according to APPLINK-14765
	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--Begin Test suit NegativeResponseCheck
		--Description: check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA: SDLAQ-CRS-134

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check UI response with nonexistent resultCode
					function Test:ChangeRegistration_UIResponseResultCodeNotExist()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check VR response with nonexistent resultCode
					function Test:ChangeRegistration_VRResponseResultCodeNotExist()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check TTS response with nonexistent resultCode
					function Test:ChangeRegistration_TTSResponseResultCodeNotExist()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check UI response with empty string in method
					function Test:ChangeRegistration_UIResponseMethodOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check VR response with empty string in method
					function Test:ChangeRegistration_VRResponseMethodOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.6
				--Description: Check TTS response with empty string in method
					function Test:ChangeRegistration_TTSResponseMethodOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.1.6
			--End Test case NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-134

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode..

				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check UI response without all parameters
					function Test:ChangeRegistration_UIResponseMissingAllPArameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:Send('{}')
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check VR response without all parameters
					function Test:ChangeRegistration_VRResponseMissingAllPArameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:Send('{}')
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check TTS response without all parameters
					function Test:ChangeRegistration_TTSResponseMissingAllPArameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:Send('{}')
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.4
				--Description: Check UI response without method parameter
					function Test:ChangeRegistration_UIResponseMethodMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.5
				--Description: Check VR response without method parameter
					function Test:ChangeRegistration_VRResponseMethodMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.6
				--Description: Check TTS response without method parameter
					function Test:ChangeRegistration_TTSResponseMethodMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.7
				--Description: Check UI response without resultCode parameter
					function Test:ChangeRegistration_UIResponseResultCodeMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ChangeRegistration"}}')
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.8
				--Description: Check VR response without resultCode parameter
					function Test:ChangeRegistration_VRResponseResultCodeMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.ChangeRegistration"}}')
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.2.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.9
				--Description: Check TTS response without resultCode parameter
					function Test:ChangeRegistration_TTSResponseResultCodeMissing()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ChangeRegistration"}}')
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA"})
					end
				--End Test case NegativeResponseCheck.2.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.10
				--Description: Check UI response without mandatory parameter
					function Test:ChangeRegistration_UIResponseMissingMandatoryParameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.10

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.11
				--Description: Check VR response without mandatory parameter
					function Test:ChangeRegistration_VRResponseMissingMandatoryParameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.11

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.12
				--Description: Check TTS response without mandatory parameter
					function Test:ChangeRegistration_TTSResponseMissingMandatoryParameters()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.2.12
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-134

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check UI response with wrong type of method
					function Test:ChangeRegistration_UIResponseMethodWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check VR response with wrong type of method
					function Test:ChangeRegistration_VRResponseMethodWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check TTS response with wrong type of method
					function Test:ChangeRegistration_TTSResponseMethodWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check UI response with wrong type of resultCode
					function Test:ChangeRegistration_UIResponseResultCodeWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.3.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check VR response with wrong type of resultCode
					function Test:ChangeRegistration_VRResponseResultCodeWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.3.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.6
				--Description: Check TTS response with wrong type of resultCode
					function Test:ChangeRegistration_TTSResponseResultCodeWrongtype()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.3.6
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-134

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.4.1
				--Description: Check UI response with invalid JSON
					function Test: ChangeRegistration_UIResponseInvalidJson()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ChangeRegistration", "code":0}}')
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.4.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.2
				--Description: Check VR response with invalid JSON
					function Test: ChangeRegistration_VRResponseInvalidJson()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.ChangeRegistration", "code":0}}')
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.4.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.3
				--Description: Check TTS response with invalid JSON
					function Test: ChangeRegistration_TTSResponseInvalidJson()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.ChangeRegistration", "code":0}}')
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.4.3
			--End Test case NegativeResponseCheck.4
			]]
			-----------------------------------------------------------------------------------------
	--[[TODO: update after resolving APPLINK-14551
			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters

				--Requirement id in JAMA/or Jira ID:
					--SDLAQ-CRS-697
					--APPLINK-13276
					--APPLINK-14551

				--Verification criteria:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.

				--Begin Test Case NegativeResponseCheck5.1
				--Description: UI response with info parameter out of lower bound
					function Test: ChangeRegistration_UIResponseInfoOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend empty info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.1

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.2
				--Description: VR response with info parameter out of lower bound
					function Test: ChangeRegistration_VRResponseInfoOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend empty info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.2

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.3
				--Description: TTS response with info parameter out of lower bound
					function Test: ChangeRegistration_TTSResponseInfoOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend empty info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.3

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.4
				--Description: UI & VR & TTS response with info parameter out of lower bound
					function Test: ChangeRegistration_UIVRTTSResponseInfoOutLowerBound()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend empty info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.4

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.5
				--Description: UI response with info parameter out of upper bound
					function Test: ChangeRegistration_UIResponseInfoOutUpperBound()
						local infoOutUpperBound = infoMessage.."b"
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
					end
				--End Test Case NegativeResponseCheck5.5

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.6
				--Description: VR response with info parameter out of upper bound
					function Test: ChangeRegistration_VRResponseInfoOutUpperBound()
						local infoOutUpperBound = infoMessage.."b"
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
					end
				--End Test Case NegativeResponseCheck5.6

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.7
				--Description: TTS response with info parameter out of upper bound
					function Test: ChangeRegistration_TTSResponseInfoOutUpperBound()
						local infoOutUpperBound = infoMessage.."b"
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
					end
				--End Test Case NegativeResponseCheck5.7

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.8
				--Description: UI & VR & TTS response with info parameter out of upper bound
					function Test: ChangeRegistration_UIVRTTSResponseInfoOutUpperBound()
						local infoOutUpperBound = infoMessage.."b"
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })
					end
				--End Test Case NegativeResponseCheck5.8

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.9
				--Description: UI response with info parameter wrong type
					function Test: ChangeRegistration_UIResponseInfoWrongType()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.9

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.10
				--Description: VR response with info parameter wrong type
					function Test: ChangeRegistration_VRResponseInfoWrongType()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.10

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.11
				--Description: TTS response with info parameter wrong type
					function Test: ChangeRegistration_TTSResponseInfoWrongType()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.11

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.12
				--Description: UI & VR & TTS response with info parameter wrong type
					function Test: ChangeRegistration_UIVRTTSResponseInfoWrongType()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.12

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.13
				--Description: UI response with escape sequence \n
					function Test: ChangeRegistration_UIResponseInfoWithNewLineChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.13

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.14
				--Description: VR response with escape sequence \n
					function Test: ChangeRegistration_VRResponseInfoWithNewLineChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.14

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.15
				--Description: TTS response with escape sequence \n
					function Test: ChangeRegistration_TTSResponseInfoWithNewLineChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.15

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.16
				--Description: UI & VR & TTS response with escape sequence \n
					function Test: ChangeRegistration_UIVRTTSResponseInfoWithNewLineChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.16

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.17
				--Description: UI response with escape sequence \t
					function Test: ChangeRegistration_UIResponseInfoWithNewTabChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.17

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.18
				--Description: VR response with escape sequence \t
					function Test: ChangeRegistration_VRResponseInfoWithNewTabChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.18

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.19
				--Description: TTS response with escape sequence \t
					function Test: ChangeRegistration_TTSResponseInfoWithNewTabChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.19

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.20
				--Description: UI & VR & TTS response with escape sequence \t
					function Test: ChangeRegistration_UIVRTTSResponseInfoWithNewTabChar()
						local paramsSend = changeRegistrationAllParams()

						--mobile side: send ChangeRegistration request
						local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

						--hmi side: expect UI.ChangeRegistration request
						EXPECT_HMICALL("UI.ChangeRegistration",
						{
							appName = paramsSend.appName,
							language = paramsSend.hmiDisplayLanguage,
							ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
						})
						:Do(function(_,data)
							--hmi side: send UI.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--hmi side: expect VR.ChangeRegistration request
						EXPECT_HMICALL("VR.ChangeRegistration",
						{
							language = paramsSend.language,
							vrSynonyms = paramsSend.vrSynonyms
						})
						:Do(function(_,data)
							--hmi side: send VR.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--hmi side: expect TTS.ChangeRegistration request
						EXPECT_HMICALL("TTS.ChangeRegistration",
						{
							language = paramsSend.language,
							ttsName = paramsSend.ttsName
						})
						:Do(function(_,data)
							--hmi side: send TTS.ChangeRegistration response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--mobile side: expect ChangeRegistration response
						EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.20
			--End Test case NegativeResponseCheck.5
		--End Test suit NegativeResponseCheck
]]

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- сheck all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check DUPLICATE_NAME result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-2915, APPLINK-8687

			--Verification criteria:
				--[[VC1:
					Pre-conditions:
					SDL and HMI are running
					app_1 is registered with "appName_1" and "VrSynonim_1" with SDL.

					Scenario:
					New app_2 ->SDL: ChangeRegistration("appName_2", VRSynonyms: "appName_1", "VrSynonim_2", params}
					SDL->app_2: ChangeRegistration(DUPLICATE_NAME, success: false)

					VC2:
					Pre-conditions:
					SDL and HMI are running
					app_1 is registered with "appName_1" and "VrSynonim_1" with SDL.

					Scenario:
					1.   New app_2 ->SDL: ChangeRegistration(appName: "appName_1", VRSynonyms: "VrSynonim_2", params}
					2. SDL->app_2: ChangeRegistration(DUPLICATE_NAME, success: false)

					VC3:
					Pre-conditions:
					SDL and HMI are running
					app_1 is registered with "appName_1" and "VrSynonim_1" with SDL.

					Scenario:
					1.   New app_2 ->SDL: ChangeRegistration(appName: "VrSynonim_1", VRSynonyms: "VrSynonim_2", params}
					2. SDL->app_2: ChangeRegistration(DUPLICATE_NAME, success: false)
				]]

				function Test:Precondition_ChangeRegistrationApp1()
					self:changeRegistrationSuccess(changeRegistrationAllParams())
				end

				function Test:Precondition_CreationNewSession()
					-- Connected expectation
					self.mobileSession1 = mobile_session.MobileSession(
					self,
					self.mobileConnection)
				end

				function Test:Precondition_AppRegistrationInSecondSession()
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
							  appID = "2"
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
								appID2 = data.params.application.appID
								self.appID2 = appID2
							end)

							--mobile side: expect response
							self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

							self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
				end

				--[[
					Application 1:
						+ appName = SyncProxyTester
						+ vrSynonyms = 	VRSyncProxyTester
				]]
			--Begin Test case ResultCodeCheck.1.1
			--Description: VRSynonyms app2 duplicate with appName app1
				function Test:ChangeRegistration_VRSynonymsDuplicateWithApp1AppName()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.appName = "SyncProxyTester2"
					paramsSend.vrSynonyms =
											{
												"SyncProxyTester"
											}

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession1:SendRPC("ChangeRegistration", paramsSend)

					--mobile side: ChangeRegistration response
					self.mobileSession1:ExpectResponse(CorIdChangeRegistration, { success = false, resultCode = "DUPLICATE_NAME"})
				end
			--End Test case ResultCodeCheck.1.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.1.2
			--Description:  vrSynonym is duplicated with registered vrSynonym
				function Test:ChangeRegistration_VRSynonymDuplicateRegisteredVRSynonym()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.vrSynonyms = {"VRSyncProxyTester"}

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession1:SendRPC("ChangeRegistration", paramsSend)

					--mobile side: ChangeRegistration response
					self.mobileSession1:ExpectResponse(CorIdChangeRegistration, { success = false, resultCode = "DUPLICATE_NAME"})
				end
			--End Test case ResultCodeCheck.1.2

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.1.3
			--Description: appName app2 duplicate with appName app1
				function Test:ChangeRegistration_AppNameDuplicateWithApp1AppName()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.appName = "SyncProxyTester"
					paramsSend.vrSynonyms =
											{
												"VRSyncProxyTester2"
											}

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession1:SendRPC("ChangeRegistration", paramsSend)

					--mobile side: ChangeRegistration response
					self.mobileSession1:ExpectResponse(CorIdChangeRegistration, { success = false, resultCode = "DUPLICATE_NAME"})
				end
			--End Test case ResultCodeCheck.1.3

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.1.4
			--Description: appName app2 duplicate with vrSynonyms app1
				function Test:ChangeRegistration_AppNameDuplicateWithApp2VRSynonyms()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.appName = "VRSyncProxyTester"
					paramsSend.vrSynonyms =
											{
												"VRSyncProxyTester2"
											}


					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession1:SendRPC("ChangeRegistration", paramsSend)

					--mobile side: ChangeRegistration response
					self.mobileSession1:ExpectResponse(CorIdChangeRegistration, { success = false, resultCode = "DUPLICATE_NAME"})
				end
			--End Test case ResultCodeCheck.1.4
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: Check of WARNINGS respons

			--Requirement id in JAMA: SDLAQ-CRS-1047, SDLAQ-CRS-2678

			--Verification criteria:
				--The request result is success but the result code is WARNING when ttsName is recieved as a SAPI_PHONEMES or LHPLUS_PHONEMES or PRE_RECORDED or SILENCE. ttsName has not been sent to TTS component for futher processing, the other parts of the request are sent to HMI. The response's "Info" parameter provides the information that not supported TTSChunk type is used.

			--Begin Test case ResultCodeCheck.2.1
			--Description: ttsName: type = PRE_RECORDED
				function Test:ChangeRegistration_ttsNameTypePRE_RECORDED()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName[1].type = "PRE_RECORDED"

					self:changeRegistrationWarning(paramsSend)
				end
			--End Test case ResultCodeCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.2
			--Description: ttsName: type = SAPI_PHONEMES
				function Test:ChangeRegistration_ttsNameTypeSAPI_PHONEMES()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName[1].type = "SAPI_PHONEMES"

					self:changeRegistrationWarning(paramsSend)
				end
			--End Test case ResultCodeCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.3
			--Description: ttsName: type = LHPLUS_PHONEMES
				function Test:ChangeRegistration_ttsNameTypeLHPLUS_PHONEMES()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName[1].type = "LHPLUS_PHONEMES"

					self:changeRegistrationWarning(paramsSend)
				end
			--End Test case ResultCodeCheck.2.3

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.2.4
			--Description: ttsName: type = SILENCE
				function Test:ChangeRegistration_ttsNameTypeSILENCE()
					local paramsSend = changeRegistrationAllParams()
					paramsSend.ttsName[1].type = "SILENCE"

					self:changeRegistrationWarning(paramsSend)
				end
			--End Test case ResultCodeCheck.2.4
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.3
		--Description: Check REJECTED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-701

			--Verification criteria:
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.

			--Begin Test case ResultCodeCheck.3.1
			--Description: Checking UI response with REJECTED resultCode
				function Test: ChangeRegistration_UIRejectedSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "REJECTED" })

				end
			--End Test case ResultCodeCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.3.2
			--Description: Checking VR response with REJECTED resultCode
				function Test: ChangeRegistration_VRRejectedSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "REJECTED" })
				end
			--End Test case ResultCodeCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.3.3
			--Description: Checking TTS response with REJECTED resultCode
				function Test: ChangeRegistration_TTSRejectedSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "REJECTED" })
				end
			--End Test case ResultCodeCheck.3.3
		--End Test case ResultCodeCheck.3
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: Check GENERIC_ERROR result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-702

			--Verification criteria:
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.

			--Begin Test case ResultCodeCheck.4.1
			--Description: Checking UI response with GENERIC_ERROR resultCode
				function Test: ChangeRegistration_UIGenericErrorSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })

				end
			--End Test case ResultCodeCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.4.2
			--Description: Checking VR response with GENERIC_ERROR resultCode
				function Test: ChangeRegistration_VRGenericErrorSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
				end
			--End Test case ResultCodeCheck.4.2

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.4.3
			--Description: Checking TTS response with GENERIC_ERROR resultCode
				function Test: ChangeRegistration_TTSGenericErrorSuccessFalse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
				end
			--End Test case ResultCodeCheck.4.3
		--End Test case ResultCodeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.5
		--Description: Check APPLICATION_NOT_REGISTERED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-689

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)
			end

			function Test:ChangeRegistration_ApplicationNotRegisterSuccessFalse()
				local paramsSend = changeRegistrationAllParams()

				--mobile side: send ChangeRegistration request
				local CorIdChangeRegistration = self.mobileSession2:SendRPC("ChangeRegistration", paramsSend)

				--mobile side: expect ChangeRegistration response
				self.mobileSession2:ExpectResponse(CorIdChangeRegistration, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
			end
		--End Test case ResultCodeCheck.5

	--End Test suit ResultCodeCheck


----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- requests without responses from HMI
		-- invalid structure of response
		-- several responses from HMI to one request
		-- fake parameters
		-- HMI correlation id check
		-- wrong response with correct HMI correlation id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid sctructure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI


		--Begin Test case HMINegativeCheck.1
		--Description: Check SDL behavior in case of absence of responses from HMI

			--Requirement id in JAMA: SDLAQ-CRS-702, APPLINK-8585

			--Verification criteria:
				-- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.
			--Begin Test case HMINegativeCheck.1.1
			--Description: no UI response during SDL`s watchdog:
				function Test:ChangeRegistration_NoResponseFromUI()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--No Response
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.1.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.2
			--Description: no VR response during SDL`s watchdog:
				function Test:ChangeRegistration_NoResponseFromVR()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send ui.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						-- No Response
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.1.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.3
			--Description: no TTS response during SDL`s watchdog:
				function Test:ChangeRegistration_NoResponseFromTTS()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						-- No Response
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.1.3

                        -----------------------------------------------------------------------------------------

                        --Begin Test case HMINegativeCheck.1.4
                        --Description: no TTS,VR,UI responses during SDL`s watchdog:
                                function Test:ChangeRegistration_NoResponseFromTTS_VR_UI()
                                        local paramsSend = changeRegistrationAllParams()

                                        --mobile side: send ChangeRegistration request
                                        local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

                                        --hmi side: expect UI.ChangeRegistration request
                                        EXPECT_HMICALL("UI.ChangeRegistration",
                                        {
                                                appName = paramsSend.appName,
                                                language = paramsSend.hmiDisplayLanguage,
                                                ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
                                        })
                                        :Do(function(_,data)
                                                -- No Response
                                        end)

                                        --hmi side: expect VR.ChangeRegistration request
                                        EXPECT_HMICALL("VR.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                vrSynonyms = paramsSend.vrSynonyms
                                        })
                                        :Do(function(_,data)
                                                -- No Response
                                        end)

                                        --hmi side: expect TTS.ChangeRegistration request
                                        EXPECT_HMICALL("TTS.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                ttsName = paramsSend.ttsName
                                        })
                                        :Do(function(_,data)
                                                -- No Response
                                        end)

                                        --mobile side: expect ChangeRegistration response
                                        EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
                                        :Timeout(12000)
                                end
                        --End Test case HMINegativeCheck.1.4

                        --Begin Test case HMINegativeCheck.1.5
                        --Description: no UI and TTS response during SDL`s watchdog:
                                function Test:ChangeRegistration_NoResponseFromUI_TTS()
                                        local paramsSend = changeRegistrationAllParams()

                                        --mobile side: send ChangeRegistration request
                                        local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

                                        --hmi side: expect UI.ChangeRegistration request
                                        EXPECT_HMICALL("UI.ChangeRegistration",
                                        {
                                                appName = paramsSend.appName,
                                                language = paramsSend.hmiDisplayLanguage,
                                                ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
                                        })
                                        :Do(function(_,data)
                                                --No Response
                                        end)

                                        --hmi side: expect VR.ChangeRegistration request
                                        EXPECT_HMICALL("VR.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                vrSynonyms = paramsSend.vrSynonyms
                                        })
                                        :Do(function(_,data)
                                                --hmi side: send VR.ChangeRegistration response
                                                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
                                        end)

                                        --hmi side: expect TTS.ChangeRegistration request
                                        EXPECT_HMICALL("TTS.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                ttsName = paramsSend.ttsName
                                        })
                                        :Do(function(_,data)
                                                -- No Response
                                        end)

                                        --mobile side: expect ChangeRegistration response
                                        EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
                                        :Timeout(12000)
                                end
                        --End Test case HMINegativeCheck.1.5

                        --Begin Test case HMINegativeCheck.1.6
                        --Description: no UI and VR response during SDL`s watchdog:
                                function Test:ChangeRegistration_NoResponseFromUI_VR()
                                        local paramsSend = changeRegistrationAllParams()

                                        --mobile side: send ChangeRegistration request
                                        local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

                                        --hmi side: expect UI.ChangeRegistration request
                                        EXPECT_HMICALL("UI.ChangeRegistration",
                                        {
                                                appName = paramsSend.appName,
                                                language = paramsSend.hmiDisplayLanguage,
                                                ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
                                        })
                                        :Do(function(_,data)
                                                --No Response
                                        end)

                                        --hmi side: expect VR.ChangeRegistration request
                                        EXPECT_HMICALL("VR.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                vrSynonyms = paramsSend.vrSynonyms
                                        })
                                        :Do(function(_,data)
                                                --No Response
                                        end)

                                        --hmi side: expect TTS.ChangeRegistration request
                                        EXPECT_HMICALL("TTS.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                ttsName = paramsSend.ttsName
                                        })
                                        :Do(function(_,data)
                                        --hmi side: send TTS.ChangeRegistration response
                                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
                                        end)

                                        --mobile side: expect ChangeRegistration response
                                        EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
                                        :Timeout(12000)
                                end
                        --End Test case HMINegativeCheck.1.6

                        --Begin Test case HMINegativeCheck.1.7
                        --Description: no TTS and VR response during SDL`s watchdog:
                                function Test:ChangeRegistration_NoResponseFromTTS_VR()
                                        local paramsSend = changeRegistrationAllParams()

                                        --mobile side: send ChangeRegistration request
                                        local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

                                        --hmi side: expect UI.ChangeRegistration request
                                        EXPECT_HMICALL("UI.ChangeRegistration",
                                        {
                                                appName = paramsSend.appName,
                                                language = paramsSend.hmiDisplayLanguage,
                                                ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
                                        })
                                        :Do(function(_,data)
                                        --hmi side: send UI.ChangeRegistration response
                                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
                                        end)

                                        --hmi side: expect VR.ChangeRegistration request
                                        EXPECT_HMICALL("VR.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                vrSynonyms = paramsSend.vrSynonyms
                                        })
                                        :Do(function(_,data)
                                                --No Response
                                        end)

                                        --hmi side: expect TTS.ChangeRegistration request
                                        EXPECT_HMICALL("TTS.ChangeRegistration",
                                        {
                                                language = paramsSend.language,
                                                ttsName = paramsSend.ttsName
                                        })
                                        :Do(function(_,data)
                                                 --No Response
                                        end)

                                        --mobile side: expect ChangeRegistration response
                                        EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
                                        :Timeout(12000)
                                end
                        --End Test case HMINegativeCheck.1.7


		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------


		--Begin Test case HMINegativeCheck.2
		--Description:
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-134
	--[[TODO: Update after resolving APPLINK-13073
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			--Begin Test case HMINegativeCheck.2.1
			--Description: UI response with invalid structure
				function Test:ChangeRegistration_UIResponseWithInvalidStructure()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--Correct structure
						-- self.hmiConnection:Send('{"id" :'..tostring(data.id)..',"jsonrpc" : "2.0","result" : {"code" : 0,"method" : "UI.ChangeRegistration"}}')
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"UI.ChangeRegistration"}')
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.2
			--Description: VR response with invalid structure
				function Test:ChangeRegistration_VRResponseWithInvalidStructure()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send ui.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--Correct structure
						--self.hmiConnection:Send('{"id" :'..tostring(data.id)..',"jsonrpc" : "2.0","result" : {"code" : 0,"method" : "VR.ChangeRegistration"}}')')
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"VR.ChangeRegistration"}')
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.3
			--Description: TTS response with invalid structure
				function Test:ChangeRegistration_TTSResponseWithInvalidStructure()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--Correct structure
						--self.hmiConnection:Send('{"id" :'..tostring(data.id)..',"jsonrpc" : "2.0","result" : {"code" : 0,"method" : "TTS.ChangeRegistration"}}')')
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"TTS.ChangeRegistration"}')
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.2.3
		--End Test case HMINegativeCheck.2
		]]

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description:
			-- Check processing responses with have several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-134

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			--Begin Test case HMINegativeCheck.3.1
			--Description: Several response to UI request
				function Test:ChangeRegistration_SeveralResponseToUIRequest()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case HMINegativeCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: Several response to VR request
				function Test:ChangeRegistration_SeveralResponseToVRRequest()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA",{})
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case HMINegativeCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.3
			--Description: Several response to TTS request
				function Test:ChangeRegistration_SeveralResponseToTTSRequest()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA",{})
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case HMINegativeCheck.3.3
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------
--TODO update according to APPLINK-11511
		--Begin Test case HMINegativeCheck.4
		--Description: Check processing response with fake parameters(not from API)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-134

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode..

			--Begin Test case HMINegativeCheck.4.1
			--Description: UI response with fake parameter
				function Test:ChangeRegistration_FakeParamsInUIResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{fake = "fake"})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: VR response with fake parameter
				function Test:ChangeRegistration_FakeParamsInVRResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{fake = "fake"})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.3
			--Description: TTS response with fake parameter
				function Test:ChangeRegistration_FakeParamsInTTSResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{fake = "fake"})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.3
		--End Test case HMINegativeCheck.4

		-----------------------------------------------------------------------------------------
--TODO update according to APPLINK-11511
		--Begin Test case HMINegativeCheck.5
		--Description: Check processing response with parameters from another API

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-134

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode..

			--Begin Test case HMINegativeCheck.5.1
			--Description: UI response with parameter from another API
				function Test:ChangeRegistration_ParamsFromOtherAPIInUIResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{sliderPosition = 5})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend parameter from another API to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.5.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.2
			--Description: VR response with parameter from another API
				function Test:ChangeRegistration_ParamsFromOtherAPIInVRResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend parameter from another API to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.5.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.3
			--Description: TTS response with parameter from another API
				function Test:ChangeRegistration_FakeParamsInTTSResponse()
					local paramsSend = changeRegistrationAllParams()

					--mobile side: send ChangeRegistration request
					local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

					--hmi side: expect UI.ChangeRegistration request
					EXPECT_HMICALL("UI.ChangeRegistration",
					{
						appName = paramsSend.appName,
						language = paramsSend.hmiDisplayLanguage,
						ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
					})
					:Do(function(_,data)
						--hmi side: send UI.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect VR.ChangeRegistration request
					EXPECT_HMICALL("VR.ChangeRegistration",
					{
						language = paramsSend.language,
						vrSynonyms = paramsSend.vrSynonyms
					})
					:Do(function(_,data)
						--hmi side: send VR.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--hmi side: expect TTS.ChangeRegistration request
					EXPECT_HMICALL("TTS.ChangeRegistration",
					{
						language = paramsSend.language,
						ttsName = paramsSend.ttsName
					})
					:Do(function(_,data)
						--hmi side: send TTS.ChangeRegistration response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--mobile side: expect ChangeRegistration response
					EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend parameter from another API to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.5.3
		--End Test case HMINegativeCheck.5
	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Begin Test case DifferentHMIlevel.1
		--Description:

			--Requirement id in JAMA:
				-- SDLAQ-CRS-808

			--Verification criteria:
				-- SDL process ChangeRegistration request on any HMI level (NONE, FULL, LIMITED, BACKGROUND).

               --TODO: to debug
              --[[

		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then

			--Begin DifferentHMIlevel.1.1
			--Description: SDL process ChangeRegistration request on NONE HMI level
				function Test:Precondition_DeactivateToNone()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.appID1, reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end

				function Test:ChangeRegistration_HMILevelNone()
					self:changeRegistrationSuccess(changeRegistrationAllParams())
				end
			--End DifferentHMIlevel.1.1

			-----------------------------------------------------------------------------------------

			--Begin DifferentHMIlevel.1.2
			--Description: SDL process ChangeRegistration request on LIMITED HMI level(only for media/navi)
				function Test:ActivateFirstApp()
					--hmi side: sending SDL.ActivateApp request
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appID1})
					EXPECT_HMIRESPONSE(rid)

					--mobile side: expect notification
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				end

				function Test:Precondition_DeactivateToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.appID1,
						reason = "GENERAL"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				end

				function Test:ChangeRegistration_HMILevelLimited()
					self:changeRegistrationSuccess(changeRegistrationAllParams())
				end
			--End DifferentHMIlevel.1.2

			-----------------------------------------------------------------------------------------

			--Begin DifferentHMIlevel.1.3
			--Description: SDL process ChangeRegistration request on BACKGROUND HMI level

				--Precondition for media app
				function Test:ActivateSecondApp()
					--hmi side: sending SDL.ActivateApp request
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appID2})
					EXPECT_HMIRESPONSE(rid)

					--mobile side: expect notification from 2 app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				end
			elseif
				Test.isMediaApplication == false then

					--Precondition for non-media app
					function Test:Precondition_DeactivateToBackground()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.appID1,
							reason = "GENERAL"
						})

						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end
			end

				function Test:ChangeRegistration_HMILevelBackground()
					self:changeRegistrationSuccess(changeRegistrationAllParams())
				end
--]]
			--End DifferentHMIlevel.1.3
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel

 return Test

























