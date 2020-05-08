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
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "PerformAudioPassThru" -- set request name

local infoMessage = string.rep("a", 1000)
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")
local function SendOnSystemContext(self, ctx)
	self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end
local function ExpectOnHMIStatusWithAudioStateChanged(self, level, isInitialPrompt,timeout)
	if timeout == nil then timeout = 20000 end
	if level == nil then  level = "FULL" end

	if
		level == "FULL" then
			if
				self.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then
				if isInitialPrompt == true then
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
							{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(4)
					:Timeout(timeout)
				else
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Timeout(timeout)
				end
			elseif
				self.isMediaApplication == false then
					EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Timeout(timeout)
			end
	elseif
		level == "LIMITED" then

			if
				self.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then
					if isInitialPrompt == true then
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						:Times(2)
						:Timeout(timeout)
					else
						EXPECT_NOTIFICATION("OnHMIStatus")
						:Times(0)
						:Timeout(timeout)
					end
			elseif
				self.isMediaApplication == false then

					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)

					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Times(0)

					DelayedExp(1000)
			end
	elseif
		level == "BACKGROUND" then

			EXPECT_NOTIFICATION("OnHMIStatus")
			:Times(0)

			EXPECT_NOTIFICATION("OnAudioPassThru")
			:Times(0)

			DelayedExp(1000)
	end
end
local function printError(errorMessage)
	print(" \27[36m " .. errorMessage .. " \27[0m ")
end
function DelayedExp(timeout)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, timeout)
end

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(RequestParams)
--3. verify_SUCCESS_Case(RequestParams)
--4. verify_INVALID_DATA_Case(RequestParams)
---------------------------------------------------------------------------------------------

--Create default request parameters
function createRequest()

	return {
		samplingRate ="8KHZ",
		maxDuration = 2000,
		bitsPerSample ="8_BIT",
		audioType = "PCM"
	}

end
---------------------------------------------------------------------------------------------

--Create TTS.Speak expected result based on parameters from the request
function Test:createTTSSpeakParameters(RequestParams)
	local param =  {}

	param["speakType"] =  "AUDIO_PASS_THRU"

	--initialPrompt
	if RequestParams["initialPrompt"]  ~= nil then
		param["ttsChunks"] =  {
								{
									text = RequestParams.initialPrompt[1].text,
									type = RequestParams.initialPrompt[1].type,
								},
							}
	end

	return param
end


--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)
	local param =  {}

	param["muteAudio"] =  Request["muteAudio"]
	param["maxDuration"] =  Request["maxDuration"]

	local j = 0
	--audioPassThruDisplayText1
	if Request["audioPassThruDisplayText1"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}
		end
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText1",
			fieldText = Request["audioPassThruDisplayText1"]
		}
	end

	--audioPassThruDisplayText2
	if Request["audioPassThruDisplayText2"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}
		end
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText2",
			fieldText = Request["audioPassThruDisplayText2"]
		}
	end

	return param
end
---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(RequestParams, level)
	if level == nil then  level = "FULL" end

	--mobile side: sending PerformAudioPassThru request
	local cid = self.mobileSession:SendRPC(APIName, RequestParams)

	--commonFunctions:printTable(RequestParams)

	UIParams = self:createUIParameters(RequestParams)
	TTSSpeakParams = self:createTTSSpeakParameters(RequestParams)

	if RequestParams["initialPrompt"]  ~= nil then
		--hmi side: expect TTS.Speak request
		EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
		:Do(function(_,data)
			--Send notification to start TTS
			self.hmiConnection:SendNotification("TTS.Started")

			local function ttsSpeakResponse()
				--hmi side: sending TTS.Speak response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

				--Send notification to stop TTS
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
			end

			RUN_AFTER(ttsSpeakResponse, 50)
		end)
	end

	--hmi side: expect UI.PerformAudioPassThru request
	EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
	:Do(function(_,data)
		SendOnSystemContext(self,"HMI_OBSCURED")


		local function uiResponse()
			--hmi side: sending UI.PerformAudioPassThru response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			SendOnSystemContext(self,"MAIN")
		end

		RUN_AFTER(uiResponse, 1500)
	end)

	ExpectOnHMIStatusWithAudioStateChanged(self, level, RequestParams["initialPrompt"]  ~= nil)

	--mobile side: expect OnAudioPassThru response
	EXPECT_NOTIFICATION("OnAudioPassThru")
	:Times(AtLeast(1))
	:Timeout(10000)

	--mobile side: expect PerformAudioPassThru response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--:ValidIf (function(_,data)
	--	if file_check(storagePath.."audio.wav") ~= true then
		--	print(" \27[36m Can not found file: audio.wav \27[0m ")
		--	return false
	--	else
		--	return true
	--	end
--	end)

	DelayedExp(1000)
end

--This function sends a request from mobile with INVALID_DATA and verify result on mobile.
function Test:verify_INVALID_DATA_Case(RequestParams)
	cid = self.mobileSession:SendRPC(APIName, RequestParams)

	--mobile side: expect PerformAudioPassThru response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	DelayedExp(1000)
end

--This function to create number of initialPrompt
function createInitialPrompt(n)
        temp = {}
        for i = 1, n do
        temp[i] = {
                text = tostring(i)..string.rep("a",500-string.len(tostring(i))),
				type = "TEXT",
			}
        end
        return temp
end

--Description: Update policy from specific file
	--policyFileName: Name of policy file
	--bAllowed: true if want to allowed New group policy
	--          false if want to disallowed New group policy
local groupID = 193465391
local groupName = "New"
function Test:policyUpdate(policyFileName, consent, bAllowed)
	--hmi side: sending SDL.GetURLS request
	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

	--hmi side: expect SDL.GetURLS response from HMI
	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	:Do(function(_,data)
		--print("SDL.GetURLS response is received")
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			{
				requestType = "PROPRIETARY",
				fileName = "filename"
			}
		)
		--mobile side: expect OnSystemRequest notification
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		:Do(function(_,data)
			--print("OnSystemRequest notification is received")
			--mobile side: sending SystemRequest request
			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				},
			"files/"..policyFileName)

			local systemRequestId
			--hmi side: expect SystemRequest request
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				--print("BasicCommunication.SystemRequest is received")

				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
					{
						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
					}
				)
				function to_run()
					--hmi side: sending SystemRequest response
					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
				end

				RUN_AFTER(to_run, 500)
			end)

			--hmi side: expect SDL.OnStatusUpdate
			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				:ValidIf(function(exp,data)
					if
						exp.occurences == 1 and
						data.params.status == "UP_TO_DATE" then
							return true
					elseif
						exp.occurences == 1 and
						data.params.status == "UPDATING" then
							return true
					elseif
						exp.occurences == 2 and
						data.params.status == "UP_TO_DATE" then
							return true
					else
						if
							exp.occurences == 1 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif exp.occurences == 2 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						end
						return false
					end
				end)
				:Times(Between(1,2))

			--mobile side: expect SystemRequest response
			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				--print("SystemRequest is received")
				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

				--hmi side: expect SDL.GetUserFriendlyMessage response
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
				:Do(function(_,data)
					--print("SDL.GetUserFriendlyMessage is received")
					if consent == true then
						--hmi side: sending SDL.GetListOfPermissions request to SDL
						local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})

						-- hmi side: expect SDL.GetListOfPermissions response
						-- TODO: update after resolving APPLINK-16094  EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = groupName}}}})
						EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
						:Do(function(_,data)
							--hmi side: sending SDL.OnAppPermissionConsent
							self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = bAllowed, id = groupID, name = groupName}}, source = "GUI"})
							end)
					end
				end)
			end)

		end)
	end)
end

--Description: Function used to check file is existed on expected path
	--file_name: file want to check
function file_check(file_name)
  local file_found=io.open(file_name, "r")

  if file_found==nil then
    return false
  else
    return true
  end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete Logs
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2. Activate application
	commonSteps:ActivationApp()

	--3. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"FULL", "LIMITED"})
	
	--4. Restore preloaded_pt.json after updating it and SDL had loaded it when starting.
	policyTable:Restore_preloaded_pt()

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For PositiveRequestCheck")

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
					--SDLAQ-CRS-81
					--SDLAQ-CRS-553
					--SDLAQ-CRS-2999

			--Verification criteria:
					-- PerformAudioPassThru takes audio from microphone connected to SDL platform. Audio data has been written into the directory on SDL (one level upper then app's directory). The audio stream starts transferring data from the stored file with OnAudioPassThru notification as soon as possible and playing it on the mobile device.
					--  In case SDL receives PerformAudioPassThru request with valid "initialPrompt" param from mobile app, SDL must send TTS.Speak with "speakType"=AUDIO_PASS_THRU param (and other values from app's "initialPrompt" and send UI.PerformAudioPassThru as assigned by previously-confirmed requirements).
			function Test:PerformAudioPassThru_Positive()
				local params = {
									initialPrompt =
									{
										{
											text ="Makeyourchoice",
											type ="TEXT",
										},
									},
									audioPassThruDisplayText1 ="DisplayText1",
									audioPassThruDisplayText2 ="DisplayText2",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true,
								  }
				self:verify_SUCCESS_Case(params)
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-81

			--Verification criteria: PerformAudioPassThru takes audio from microphone connected to SDL platform. Audio data has been written into the directory on SDL (one level upper then app's directory). The audio stream starts transferring data from the stored file with OnAudioPassThru notification as soon as possible and playing it on the mobile device.

			--Begin Test case CommonRequestCheck.2.1
			--Description: Request with only mandatory parameters
				function Test:PerformAudioPassThru_MandatoryOnly()
					local params = createRequest()
					self:verify_SUCCESS_Case(params)
				end
			--End Test case CommonRequestCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description: Request with conditional parameter: initialPrompt
				function Test:PerformAudioPassThru_WithConditional_initialPrompt()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												},
											}

					self:verify_SUCCESS_Case(params)
				end
			--End Test case CommonRequestCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.3
			--Description: Request with conditional parameter: audioPassThruDisplayText1
				function Test:PerformAudioPassThru_WithConditional_audioPassThruDisplayText1()
					local params = createRequest()
					params["audioPassThruDisplayText1"] = "audioPassThruDisplayText1"
					self:verify_SUCCESS_Case(params)
				end
			--End Test case CommonRequestCheck.2.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.4
			--Description: Request with conditional parameter: audioPassThruDisplayText2
				function Test:PerformAudioPassThru_WithConditional_audioPassThruDisplayText2()
					local params = createRequest()
					params["audioPassThruDisplayText2"] = "audioPassThruDisplayText2"
					self:verify_SUCCESS_Case(params)
				end
			--End Test case CommonRequestCheck.2.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.5
			--Description: Request with conditional parameter: muteAudio
				function Test:PerformAudioPassThru_WithConditional_muteAudio()
					local params = createRequest()
					params["muteAudio"] = true
					self:verify_SUCCESS_Case(params)
				end
			--End Test case CommonRequestCheck.2.5
		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA:
					--SDLAQ-CRS-554

			--Verification criteria:
					-- The request without "samplingRate" is sent, the response with INVALID_DATA result code is returned.
					-- The request without "maxDuration" is sent, the response with INVALID_DATA result code is returned.
					-- The request without "bitsPerSample" is sent, the response with INVALID_DATA result code is returned.
					-- The request without "audioType" is sent, the response with INVALID_DATA result code is returned.

			--Begin Test case CommonRequestCheck.3.1
			--Description: Mandatory missing - samplingRate
				function Test:PerformAudioPassThru_samplingRateMissing()
					local params = createRequest()
					params["samplingRate"] = nil
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2
			--Description: Mandatory missing - maxDuration
				function Test:PerformAudioPassThru_maxDurationMissing()
					local params = createRequest()
					params["maxDuration"] = nil
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.3
			--Description: Mandatory missing - bitsPerSample
				function Test:PerformAudioPassThru_bitsPerSampleMissing()
					local params = createRequest()
					params["bitsPerSample"] = nil
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.4
			--Description: Mandatory missing - audioType
				function Test:PerformAudioPassThru_audioTypeMissing()
					local params = createRequest()
					params["audioType"] = nil
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.5
			--Description: Mandatory missing - initialPrompt - text missing
				function Test:PerformAudioPassThru_initialPromptTextMissing()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													type ="TEXT",
												},
											}
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.5

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.6
			--Description: Mandatory missing - initialPrompt - type missing
				function Test:PerformAudioPassThru_initialPromptTypeMissing()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text = "ABC"
												},
											}
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.6

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.7
			--Description: Missing all params
				function Test:PerformAudioPassThru_AllParamsMissing()
					local params = {}
					self:verify_INVALID_DATA_Case(params)
				end
			--End Test case CommonRequestCheck.3.7
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
				function Test:PerformAudioPassThru_FakeParam()
					local params = {
									initialPrompt =
									{
										{
											text ="Makeyourchoice",
											type ="TEXT",
											fakeParam ="fakeParam",
										},
									},
									fakeParam ="fakeParam",
									audioPassThruDisplayText1 ="DisplayText1",
									audioPassThruDisplayText2 ="DisplayText2",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true,
								  }

					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)

					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam or
							data.params.ttsChunks[1].fakeParam then
								printError(" SDL re-sends fakeParam parameters to HMI in TTS.Speak request")
								return false
						else
							return true
						end
					end)

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
								printError(" SDL re-sends fakeParam parameters to HMI in TTS.Speak request")
								return false
						else
							return true
						end
					end)

					ExpectOnHMIStatusWithAudioStateChanged(self, level, true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					DelayedExp(1000)
				end
			--Begin Test case CommonRequestCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:PerformAudioPassThru_ParamsAnotherRequest()
					local params = {
									initialPrompt =
									{
										{
											text ="Makeyourchoice",
											type ="TEXT",
											gps = true
										},
									},
									gps = true,
									audioPassThruDisplayText1 ="DisplayText1",
									audioPassThruDisplayText2 ="DisplayText2",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true,
								  }

					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)

					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)
					:ValidIf(function(_,data)
						if data.params.gps or
							data.params.ttsChunks[1].gps then
								printError(" SDL re-sends fakeParam parameters to HMI in TTS.Speak request")
								return false
						else
							return true
						end
					end)

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)
					:ValidIf(function(_,data)
						if data.params.gps then
								printError(" SDL re-sends fakeParam parameters to HMI in UI.PerformAudioPassThru request")
								return false
						else
							return true
						end
					end)

					ExpectOnHMIStatusWithAudioStateChanged(self, level, true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					DelayedExp(1000)
				end
			--End Test case CommonRequestCheck.4.2
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-554

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:PerformAudioPassThru_IncorrectJSON()
			
				self.mobileSession.correlationId = self.mobileSession.correlationId + 1
				local msg =
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 16,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"bitsPerSample" "8_BIT","samplingRate":"8KHZ","audioType":"PCM","maxDuration":1000}'
				}
				self.mobileSession:Send(msg)
				EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.6
		--Description: Checking send request with duplicate correlationID

			--Requirement id in JAMA: SDLAQ-CRS-553
			--Verification criteria: The request is executed successfully.
				function Test:PerformAudioPassThru_CorrelationIdDuplicate()
					local level = "FULL"
					local params = createRequest()
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru",params)

					local msg =
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 16,
						rpcCorrelationId = cid,
						payload          = '{"bitsPerSample":"8_BIT","samplingRate":"8KHZ","audioType":"PCM","maxDuration":2000}'
					}

					UIParams = self:createUIParameters(params)

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(exp,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						local function sendSecondMsg()
							self.mobileSession:Send(msg)
						end
						if exp.occurences == 1 then
								RUN_AFTER(uiResponse, 1500)
								RUN_AFTER(sendSecondMsg, 2000)
						else
								RUN_AFTER(uiResponse, 3500)
						end
					end)
					:Times(2)

					--mobile side: Expected OnHMIStatus notification
					if
						self.isMediaApplication == true or
						Test.appHMITypes["NAVIGATION"] == true then

						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						:Times(4)
						:Timeout(10000)

						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Times(4)
						:Timeout(10000)

					elseif
						self.isMediaApplication == false then
							EXPECT_NOTIFICATION("OnHMIStatus",
									{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
									{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
									{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
									{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(4)
							:Timeout(10000)

							EXPECT_NOTIFICATION("OnAudioPassThru")
							:Times(4)
							:Timeout(10000)
					end

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
					:Times(2)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:Times(2)
					:Timeout(15000)
				end
			--End Test case CommonRequestCheck.6
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

			--Begin Test case PositiveRequestCheck.1
			--Description: Check parameter with lower and upper bound values

				--Requirement id in JAMA:
							-- SDLAQ-CRS-81
							-- SDLAQ-CRS-553

				--Verification criteria:
							-- PerformAudioPassThru takes audio from microphone connected to SDL platform. Audio data has been written into the directory on SDL (one level upper then app's directory). The audio stream starts transferring data from the stored file with OnAudioPassThru notification as soon as possible and playing it on the mobile device.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: lower bound all parameter
					function Test:PerformAudioPassThru_LowerBound()
						local params = {
											initialPrompt = {
												{
													text ="A",
													type ="TEXT",
												},
											},
											audioPassThruDisplayText1 ="A",
											audioPassThruDisplayText2 ="2",
											samplingRate ="8KHZ",
											maxDuration = 1000,
											bitsPerSample ="8_BIT",
											audioType ="PCM",
											muteAudio = true
										}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: upper bound all parameter
					function Test:PerformAudioPassThru_UpperBound()
						local params = {
											initialPrompt = createInitialPrompt(100),
											audioPassThruDisplayText1 = string.rep("a", 500),
											audioPassThruDisplayText2 = string.rep("a", 500),
											samplingRate ="8KHZ",
											maxDuration = 1000000,
											bitsPerSample ="8_BIT",
											audioType ="PCM",
											muteAudio = true
										}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: initialPrompt: array lower bound

					--Covered by CommonRequestCheck.2.2

				--End Test case PositiveRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: initialPrompt: array upper bound
					function Test:PerformAudioPassThru_initialPromptArrayUpperBound()
						local params = createRequest()
						params["initialPrompt"] = createInitialPrompt(100)
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: initialPrompt: text lower bound
					function Test:PerformAudioPassThru_initialPromptTextLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="A",
														type ="TEXT",
													},
												}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: initialPrompt: text upper bound
					function Test:PerformAudioPassThru_initialPromptTextUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text =string.rep("a",500),
														type ="TEXT",
													},
												}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: initialPrompt: text with spaces
					function Test:PerformAudioPassThru_initialPromptTextSpaces()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="   initialPrompt        with spaces      ",
														type ="TEXT",
													},
												}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: initialPrompt: type in bound
					local initialPromptType = {"SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE"}
					for i=1, #initialPromptType do
						Test["PerformAudioPassThru_initialPromptType" .. initialPromptType[i]] = function(self)
							local params = createRequest()
							params["initialPrompt"] = {
														{
															text ="Text",
															type =initialPromptType[i],
														},
													}
							self:verify_SUCCESS_Case(params)
						end
					end
				--End Test case PositiveRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.10
				--Description: samplingRate in bound
					local samplingRateValues = {"8KHZ", "16KHZ", "22KHZ", "44KHZ"}
					for i=1, #samplingRateValues do
						Test["PerformAudioPassThru_samplingRate" .. samplingRateValues[i]] = function(self)
							local params = createRequest()
							params["samplingRate"] = samplingRateValues[i]
							self:verify_SUCCESS_Case(params)
						end
					end
				--End Test case PositiveRequestCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.11
				--Description: maxDuration lower bound
					function Test:PerformAudioPassThru_maxDurationLowerBound()
						local params = createRequest()
						params["maxDuration"] = 1
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.11

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.12
				--Description: maxDuration upper bound
					function Test:PerformAudioPassThru_maxDurationUpperBound()
						local params = createRequest()
						params["maxDuration"] = 1000000
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.12

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.13
				--Description: bitsPerSample in bound
					local bitsPerSampleValues = {"8_BIT", "16_BIT"}
					for i=1, #bitsPerSampleValues do
						Test["PerformAudioPassThru_bitsPerSample" .. bitsPerSampleValues[i]] = function(self)
							local params = createRequest()
							params["bitsPerSample"] = bitsPerSampleValues[i]
							self:verify_SUCCESS_Case(params)
						end
					end
				--End Test case PositiveRequestCheck.1.13

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.14
				--Description: audioType in bound

					--Covered by CommonRequestCheck.2.1

				--End Test case PositiveRequestCheck.1.14

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.15
				--Description: muteAudio: value is True
					function Test:PerformAudioPassThru_muteAudioTrue()
						local params = createRequest()
						params["muteAudio"] = True
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.15

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.16
				--Description: muteAudio: value is false
					function Test:PerformAudioPassThru_muteAudiofalse()
						local params = createRequest()
						params["muteAudio"] = false
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.16

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.17
				--Description: muteAudio: value is False
					function Test:PerformAudioPassThru_muteAudioFalse()
						local params = createRequest()
						params["muteAudio"] = False
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.17

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.18
				--Description: audioPassThruDisplayText1 lower bound
					function Test:PerformAudioPassThru_audioPassThruDisplayText1LowerBound()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = "a"
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.18

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.19
				--Description: audioPassThruDisplayText1 upper bound
					function Test:PerformAudioPassThru_audioPassThruDisplayText1UpperBound()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = string.rep("a", 500)
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.19

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.20
				--Description: audioPassThruDisplayText1 with spaces
					function Test:PerformAudioPassThru_audioPassThruDisplayText1WithSpaces()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = "    Display   Text "
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.20

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.21
				--Description: audioPassThruDisplayText2 lower bound
					function Test:PerformAudioPassThru_audioPassThruDisplayText2LowerBound()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = "a"
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.21

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.22
				--Description: audioPassThruDisplayText2 upper bound
					function Test:PerformAudioPassThru_audioPassThruDisplayText2UpperBound()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = string.rep("a", 500)
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.22

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.23
				--Description: audioPassThruDisplayText1 with spaces
					function Test:PerformAudioPassThru_audioPassThruDisplayText2WithSpaces()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = "    Display   Text "
						self:verify_SUCCESS_Case(params)
					end
				--End Test case PositiveRequestCheck.1.23
			--End Test case PositiveRequestCheck.1
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions
--[[TODO: Check after APPLINK-14551 is resolved
			--Begin Test case PositiveResponseCheck.1
			--Description: Check process response with info parameter in bound

				--Requirement id in JAMA:
					--SDLAQ-CRS-82
					--APPLINK-14551

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				--Begin Test case PositiveResponseCheck.1.1
				--Description: TTS.Speak response info parameter lower bound
					function Test:PerformAudioPassThru_TTSResponseWithInfoLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a" })

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description: TTS.Speak response info parameter upper bound
					function Test:PerformAudioPassThru_TTSResponseWithInfoUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", string.rep("a",500))

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = string.rep("a",500)})

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.3
				--Description: UI.PerformAudioPassThru response info parameter lower bound
					function Test:PerformAudioPassThru_UIResponseWithInfoLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a"})

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.4
				--Description: UI.PerformAudioPassThru response info parameter upper bound
					function Test:PerformAudioPassThru_UIResponseWithInfoUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", string.rep("a", 500))

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = string.rep("a",500)})

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.5
				--Description: TTS.Speak and UI.PerformAudioPassThru response info parameter lower bound
					function Test:PerformAudioPassThru_TTSUIResponseWithInfoLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR","a")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR","b")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "a.b"})

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.6
				--Description: TTS.Speak and UI.PerformAudioPassThru response info parameter upper bound
					function Test:PerformAudioPassThru_TTSUIResponseWithInfoUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR",string.rep("a",500))

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR",string.rep("b",500))

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = string.rep("a",500)})

						DelayedExp(1000)
					end
				--End Test case PositiveResponseCheck.1.6
			--End Test case PositiveResponseCheck.1
		--End Test suit PositiveResponseCheck
--]]
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

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-554

				--Verification criteria:
				--[[
					2.1. The request with "initialPrompt" value out of bounds is sent, the response with INVALID_DATA result code is returned.
					2.2. The request with "audioPassThruDisplayText1" value out of bounds is sent, the response with INVALID_DATA result code is returned.
					2.3. The request with "audioPassThruDisplayText2" value out of bounds is sent, the response with INVALID_DATA result code is returned.
					2.4. The request with "maxDuration" value out of bounds is sent, the response with INVALID_DATA result code is returned.
				--]]

				--Begin Test case NegativeRequestCheck.1.1
				--Description: initialPrompt: array out lower bound
					function Test:PerformAudioPassThru_initialPromptArrayOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.2
				--Description: initialPrompt: array out upper bound
					function Test:PerformAudioPassThru_initialPromptArrayOutUpperBound()
						local params = createRequest()
						params["initialPrompt"] = createInitialPrompt(101)
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: initialPrompt: TTSChunk empty
					function Test:PerformAudioPassThru_initialPromptTTSChunkEmpty()
						local params = createRequest()
						params["initialPrompt"] = {{}}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.4
				--Description: initialPrompt: text empty
					function Test:PerformAudioPassThru_initialPromptTextEmpty()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="",
														type ="TEXT",
													},
												}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case NegativeRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: initialPrompt: text out upper bound
					function Test:PerformAudioPassThru_initialPromptTextOutUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text =string.rep("a", 501),
														type ="TEXT",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.6
				--Description:  audioPassThruDisplayText1: text empty
					function Test:PerformAudioPassThru_Text1Empty()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = ""
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.7
				--Description:  audioPassThruDisplayText1: text out upper bound
					function Test:PerformAudioPassThru_Text1OutUpperBound()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = string.rep("a", 501)
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.8
				--Description:  audioPassThruDisplayText2: text empty
					function Test:PerformAudioPassThru_Text2Empty()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = ""
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.9
				--Description:  audioPassThruDisplayText2: text out upper bound
					function Test:PerformAudioPassThru_Text2OutUpperBound()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = string.rep("a", 501)
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.10
				--Description:  maxDuration : out lower bound
					function Test:PerformAudioPassThru_maxDurationOutLowerBound()
						local params = createRequest()
						params["maxDuration"] = 0
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.11
				--Description:  maxDuration : out upper bound
					function Test:PerformAudioPassThru_maxDurationOutUpperBound()
						local params = createRequest()
						params["maxDuration"] = 1000001
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.1.11
			--Begin Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with wrong type value

				--Requirement id in JAMA:
						-- SDLAQ-CRS-554

				--Verification criteria:
				--[[
					4.1. The request with wrong data in "samplingRate" parameter (e.g. value not exists in enum) is sent, the response with INVALID_DATA result code is returned.
					4.2. The request with wrong data in "maxDuration" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					4.3. The request with wrong data in "bitsPerSample" parameter (e.g. value not exists in enum) is sent, the response with INVALID_DATA result code is returned.
					4.4. The request with wrong data in "audioType" parameter (e.g. value not exists in enum) is sent, the response with INVALID_DATA result code is returned.
					4.5. The request with wrong data in "muteAudio" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.
					4.6.  The request with wrong data in "audioPassThruDisplayText1" parameter (e.g. Integer data type) is sent, the response with INVALID_DATA result code is returned.
					4.7.  The request with wrong data in "audioPassThruDisplayText2" parameter (e.g. Integer data type) is sent, the response with INVALID_DATA result code is returned.
				--]]
				--Begin Test case NegativeRequestCheck.2.1
				--Description: initialPrompt: wrong type
				function Test:PerformAudioPassThru_initialPromptWrongType()
						local params = createRequest()
						params["initialPrompt"] = "1234"
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.2
				--Description: initialPrompt: text wrong type
					function Test:PerformAudioPassThru_initialPromptTextWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = 123,
														type ="TEXT",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.3
				--Description: audioPassThruDisplayText1: wrong type
					function Test:PerformAudioPassThru_Text1WrongType()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = 123
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.4
				--Description: audioPassThruDisplayText2: wrong type
					function Test:PerformAudioPassThru_Text2WrongType()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = 123
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.5
				--Description: maxDuration: wrong type
					function Test:PerformAudioPassThru_maxDurationWrongType()
						local params = createRequest()
						params["maxDuration"] = "123"
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.6
				--Description: muteAudio: wrong type
					function Test:PerformAudioPassThru_muteAudioWrongType()
						local params = createRequest()
						params["muteAudio"] = "123"
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.7
				--Description: initialPrompt element: wrong type
					function Test:PerformAudioPassThru_initialPromptElementWrongType()
						local params = createRequest()
						params["initialPrompt"] = {"123"}
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.8
				--Description: initialPrompt type: wrong type
					function Test:PerformAudioPassThru_initialPromptTypeWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type = 1234,
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.9
				--Description: samplingRate: wrong type
					function Test:PerformAudioPassThru_samplingRateWrongType()
						local params = createRequest()
						params["samplingRate"] = 1234
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.10
				--Description: bitsPerSample: wrong type
					function Test:PerformAudioPassThru_bitsPerSampleWrongType()
						local params = createRequest()
						params["bitsPerSample"] = 1234
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.10

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.11
				--Description: audioType: wrong type
					function Test:PerformAudioPassThru_audioTypeWrongType()
						local params = createRequest()
						params["audioType"] = 1234
						self:verify_INVALID_DATA_Case(params)
					end
				--Begin Test case NegativeRequestCheck.2.11
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with nonexistent values

				--Requirement id in JAMA:
						-- SDLAQ-CRS-554

				--Verification criteria:
						-- SDL must respond with INVALID_DATA resultCode in case request comes with enum out of range
				--Begin Test case NegativeRequestCheck.3.1
				--Description: initialPrompt: type not existed
					function Test:PerformAudioPassThru_initialPromptType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = 123,
														type ="ANY",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: samplingRate: value not existed
					function Test:PerformAudioPassThru_samplingRateNotExisted()
						local params = createRequest()
						params["samplingRate"] = "ANY"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.3
				--Description: bitsPerSample: value not existed
					function Test:PerformAudioPassThru_bitsPerSampleNotExisted()
						local params = createRequest()
						params["bitsPerSample"] = "ANY"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.4
				--Description: audioType: value not existed
					function Test:PerformAudioPassThru_audioTypeNotExisted()
						local params = createRequest()
						params["audioType"] = "ANY"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.3.4
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing requests with empty values

				--Requirement id in JAMA:
						-- SDLAQ-CRS-554
						-- SDLAQ-CRS-2910

				--Verification criteria:
						--[[
							-- In case the mobile application sends any RPC with 'text:""' (empty string) of 'ttsChunk' struct and other valid params, SDL must consider such RPC as valid and transfer it to HMI.
							-- The request with empty "samplingRate" value is sent, the response with INVALID_DATA result code is returned.
							-- The request with empty "maxDuration" is sent, the response with INVALID_DATA result code is returned.
							-- The request with empty "bitsPerSample" is sent, the response with INVALID_DATA result code is returned.
							-- The request with empty "audioType" is sent, the response with INVALID_DATA result code is returned.
							-- The request with empty "muteAudio" is sent, the response with INVALID_DATA result code is returned.
						--]]
				--Begin Test case NegativeRequestCheck.4.1
				--Description: initialPrompt: text is empty
					function Test:PerformAudioPassThru_initialPromptTextIsEmpty()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = "",
														type ="TEXT",
													},
												}
						self:verify_SUCCESS_Case(params)
					end
				--End Test case NegativeRequestCheck.4.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.2
				--Description: initialPrompt: type is empty
					function Test:PerformAudioPassThru_initialPromptTypeIsEmpty()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = "TEXT",
														type = "",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.4.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.3
				--Description: samplingRate: is empty
					function Test:PerformAudioPassThru_samplingRateIsEmpty()
						local params = createRequest()
						params["samplingRate"] = ""
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.4.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.4
				--Description: bitsPerSample: is empty
					function Test:PerformAudioPassThru_bitsPerSampleIsEmpty()
						local params = createRequest()
						params["bitsPerSample"] = ""
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.4.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.5
				--Description: audioType: is empty
					function Test:PerformAudioPassThru_audioTypeIsEmpty()
						local params = createRequest()
						params["audioType"] = ""
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.4.5
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing requests with special characters

				--Requirement id in JAMA:
						-- SDLAQ-CRS-554

				--Verification criteria:
					--[[
						5
						app->SDL: PerformAudioPassThru {TTSChunk{text: "abcd\nabcd"}, params}}    //then, PerformAudioPassThru {TTSChunk{text: "abcd\tabcd"}},   then PerformAudioPassThru {TTSChunk{text: "       "}}
						SDL-app: PerformAudioPassThru {INVALID_DATA}

						5.1.
						app->SDL: PerformAudioPassThru {audioPassThruDisplayText1: "abcd\nabcd"}, params}}    //then, PerformAudioPassThru {audioPassThruDisplayText1: "abcd\tabcd"}},   then PerformAudioPassThru {audioPassThruDisplayText1: "       "}}
						SDL-app: PerformAudioPassThru {INVALID_DATA}

						5.2.
						app->SDL: PerformAudioPassThru {audioPassThruDisplayText2: "abcd\nabcd"}, params}}    //then, PerformAudioPassThru {audioPassThruDisplayText2: "abcd\tabcd"}},   then PerformAudioPassThru {audioPassThruDisplayText2: "       "}}
						SDL-app: PerformAudioPassThru {INVALID_DATA}
					--]]

				--Begin Test case NegativeRequestCheck.5.1
				--Description: initialPrompt: text with new line character
					function Test:PerformAudioPassThru_initialPromptTextNewLineChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = "NewLine\n",
														type ="TEXT",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.2
				--Description: initialPrompt: text with tab character
					function Test:PerformAudioPassThru_initialPromptTextTabChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = "TabChar\t",
														type ="TEXT",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.3
				--Description: initialPrompt: text with white spaces only
					function Test:PerformAudioPassThru_initialPromptTextWhiteSpaceOnly()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = "       ",
														type ="TEXT",
													},
												}
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.4
				--Description: audioPassThruDisplayText1 with new line character
					function Test:PerformAudioPassThru_Text1NewLineChar()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = "Text\n"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.5
				--Description: audioPassThruDisplayText1 with tab character
					function Test:PerformAudioPassThru_Text1TabChar()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = "Text\t"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.6
				--Description: audioPassThruDisplayText1 with white spaces only
					function Test:PerformAudioPassThru_Text1WhiteSpaceOnly()
						local params = createRequest()
						params["audioPassThruDisplayText1"] = "    "
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.7
				--Description: audioPassThruDisplayText2 with new line character
					function Test:PerformAudioPassThru_Text2NewLineChar()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = "Text\n"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.8
				--Description: audioPassThruDisplayText2 with tab character
					function Test:PerformAudioPassThru_Text2TabChar()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = "Text\t"
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.9
				--Description: audioPassThruDisplayText2 with white spaces only
					function Test:PerformAudioPassThru_Text2WhiteSpaceOnly()
						local params = createRequest()
						params["audioPassThruDisplayText2"] = "    "
						self:verify_INVALID_DATA_Case(params)
					end
				--End Test case NegativeRequestCheck.5.9
			--End Test case NegativeRequestCheck.5
		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-82
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
--[[TODO: Check after APPLINK-14765 is resolved
				--Begin Test case NegativeResponseCheck.1.1
				--Description: TTS.Speak response with nonexistent resultCode
					function Test:PerformAudioPassThru_TTSResponseResultCodeNotExisted()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: UI.PerformAudioPassThru response with nonexistent resultCode
					function Test:PerformAudioPassThru_UIResponseResultCodeNotExisted()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.3
				--Description: TTS & UI response with nonexistent resultCode
					function Test:PerformAudioPassThru_TTSUIResponseResultCodeNotExisted()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.4
				--Description: TTS.Speak response with empty string in method
					function Test:PerformAudioPassThru_TTSResponseMethodOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.5
				--Description: UI.PerformAudioPassThru response with empty string in method
					function Test:PerformAudioPassThru_UIResponseMethodOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.6
				--Description: TTS & UI response with empty string in method
					function Test:PerformAudioPassThru_TTSUIResponseMethodOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.1.6
			--End Test case NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters
				--Requirement id in JAMA:
					--SDLAQ-CRS-82
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check TTS response without all parameters
					function Test:PerformAudioPassThru_TTSResponseMissingAllPArameters()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check UI response without all parameters
					function Test:PerformAudioPassThru_UIResponseMissingAllPArameters()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check TTS and UI response without all parameters
					function Test:PerformAudioPassThru_TTSUIResponseMissingAllPArameters()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.4
				--Description: Check TTS response without method parameter
					function Test:PerformAudioPassThru_TTSResponseMethodMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.5
				--Description: Check UI response without method parameter
					function Test:PerformAudioPassThru_UIResponseMethodMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.6
				--Description: Check TTS and UI response without method parameter
					function Test:PerformAudioPassThru_TTSUIResponseMethodMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
						:Timeout(12000)

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.7
				--Description: Check TTS response without resultCode parameter
					function Test:PerformAudioPassThru_TTSResponseResultCodeMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak"}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.8
				--Description: Check UI response without resultCode parameter
					function Test:PerformAudioPassThru_UIResponseResultCodeMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru"}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.9
				--Description: Check TTS and UI response without resultCode parameter
					function Test:PerformAudioPassThru_TTSUIResponseResultCodeMissing()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak"}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru"}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.2.9
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type
				--Requirement id in JAMA:
					--SDLAQ-CRS-82
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check TTS response with wrong type of method
					function Test:PerformAudioPassThru_TTSResponseMethodWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check UI response without wrong type of method
					function Test:PerformAudioPassThru_UIResponseMethodWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check TTS and UI response with wrong type of method
					function Test:PerformAudioPassThru_TTSUIResponseMethodWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check TTS response with wrong type of resultCode
					function Test:PerformAudioPassThru_TTSResponseResultCodeWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Started", "code":true}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check UI response without wrong type of resultCode
					function Test:PerformAudioPassThru_UIResponseResultCodeWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":true}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.6
				--Description: Check TTS and UI response with wrong type of resultCode
					function Test:PerformAudioPassThru_TTSUIResponseResultCodeWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":true}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":true}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.3.6
			--End Test case NegativeResponseCheck.3
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Check processing response with Invalid JSON
				--Requirement id in JAMA:
					--SDLAQ-CRS-82
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app

				--Begin Test case NegativeResponseCheck.4.1
				--Description: Check TTS response with invalid json
					function Test:PerformAudioPassThru_TTSResponseInvalidJson()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Started", "code":0}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.4.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.2
				--Description: Check UI response with invalid json
					function Test:PerformAudioPassThru_UIResponseInvalidJson()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.4.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.3
				--Description: Check TTS and UI response with invalid json
					function Test:PerformAudioPassThru_TTSUIResponseInvalidJson()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})

						DelayedExp(1000)
					end
				--End Test case NegativeResponseCheck.4.3
			--End Test case NegativeResponseCheck.4
--]]
			-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14551 is resolved
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				--Requirement id in JAMA/or Jira ID:
					--SDLAQ-CRS-82
					--APPLINK-14551

				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.

				--Begin Test Case NegativeResponseCheck.5.1
				--Description: TTS response with empty info
					function Test: PerformAudioPassThru_TTSResponseInfoOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.2
				--Description: UI response with empty info
					function Test: PerformAudioPassThru_UIResponseInfoOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.2

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.3
				--Description: TTS & UI response with empty info
					function Test: PerformAudioPassThru_TTSUIResponseInfoOutLowerBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.3

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.4
				--Description: TTS response with empty info, UI response with inbound info
					function Test: PerformAudioPassThru_TTSInfoOutLowerBoundUIInfoInBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.4

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.5
				--Description: UI response with empty info, TTS response with inbound info
					function Test: PerformAudioPassThru_UIInfoOutLowerBoundTTSInfoInBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "abc")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "abc" })

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.5

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.6
				--Description: TTS response info out of upper bound
					function Test: PerformAudioPassThru_TTSResponseInfoOutUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage.."b")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.6

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.7
				--Description: UI response info out of upper bound
					function Test: PerformAudioPassThru_UIResponseInfoOutUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage.."b")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.7

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.8
				--Description: TTS & UI response info out of upper bound
					function Test: PerformAudioPassThru_TTSUIResponseInfoOutUpperBound()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage.."a")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage.."b")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMessage })

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.8

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.9
				--Description: TTS response with wrong type of info parameter
					function Test: PerformAudioPassThru_TTSResponseInfoWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.9

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.10
				--Description: UI response with wrong type of info parameter
					function Test: PerformAudioPassThru_UIResponseInfoWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.10

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.11
				--Description: TTS & UI response with wrong type of info parameter
					function Test: PerformAudioPassThru_TTSUIResponseInfoWrongType()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 1234)

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "SUCCESS", 1234)

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.11

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.12
				--Description: TTS response with escape sequence \n in info parameter
					function Test: PerformAudioPassThru_TTSResponseInfoWithNewlineChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \n")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.12

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.13
				--Description: UI response with escape sequence \n in info parameter
					function Test: PerformAudioPassThru_UIResponseInfoWithNewlineChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \n")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.13

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.14
				--Description: TTS & UI response with escape sequence \n in info parameter
					function Test: PerformAudioPassThru_TTSUIResponseInfoWithNewlineChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \n")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \n")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.14

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.15
				--Description: TTS response with escape sequence \t in info parameter
					function Test: PerformAudioPassThru_TTSResponseInfoWithNewTabChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \t")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.15

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.16
				--Description: UI response with escape sequence \t in info parameter
					function Test: PerformAudioPassThru_UIResponseInfoWithNewTabChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \t")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.16

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.17
				--Description: TTS & UI response with escape sequence \t in info parameter
					function Test: PerformAudioPassThru_TTSUIResponseInfoWithNewTabChar()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \t")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message \t")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.17

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.18
				--Description: TTS response with white space only in info parameter
					function Test: PerformAudioPassThru_TTSResponseInfoWithWhiteSpacesOnly()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "    ")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.18

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.19
				--Description: UI response with white space only in info parameter
					function Test: PerformAudioPassThru_UIResponseInfoWithWhiteSpacesOnly()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "    ")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.19

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.20
				--Description: TTS & UI response with white space only in info parameter
					function Test: PerformAudioPassThru_TTSUIResponseInfoWithWhiteSpacesOnly()
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "      ")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "       ")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
					end
				--End Test Case NegativeResponseCheck.5.20
			--End Test case NegativeResponseCheck.5
--]]
		--End Test suit NegativeResponseCheck

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin Test suit ResultCodeCheck
	--Description: TC's check all resultCodes values in pair with success value
		--Begin Test case ResultCodeCheck.1
		--Description: Checking result code responded from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-558
				--SDLAQ-CRS-559
				--SDLAQ-CRS-560
				--SDLAQ-CRS-562
				--SDLAQ-CRS-1031

			--Verification criteria:
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- Used when the user chooses to cancel the current Audio Pass Thru session and audio streaming
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				-- PerformAudioPassThru is finished being interrupted by the user who chooses to repeat the attempt from UI (e.g. by pressing the "Retry" button). The audio file written to the app's directory on SDL is cleaned up. The audio stream stops playing on mobile device. The resultCode of the request is returned as "RETRY". Success=true.
				-- When "ttsChunks" are sent in the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
			--Begin Test case ResultCodeCheck.1.1
			--Description: Success resultCode from TTS, error resultCode from UI
				local resultCodes = {{code = "GENERIC_ERROR", success = false}, { code = "ABORTED", success  = false}, { code = "REJECTED", success  = false}, { code = "RETRY", success  = true}, { code = "WARNINGS", success  = true}}
				for i=1,#resultCodes do
					Test["PerformAudioPassThru_UI_" .. tostring(resultCodes[i].code) .."_TTSSuccess"] = function(self)
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error Message")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].code })

						DelayedExp(1000)
					end
				end
			--End Test case ResultCodeCheck.1.1

			-----------------------------------------------------------------------------------------
--[[TODO: Update according to APPLINK-15276
			--Begin Test case ResultCodeCheck.1.2
			--Description: Success resultCode from UI, error resultCode from TTS
				for i=1,#resultCodes do
					Test["PerformAudioPassThru_TTS" .. tostring(resultCodes[i].code) .."_UISuccess"] = function(self)
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error Message")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})


								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].code })

						DelayedExp(1000)
					end
				end
			--End Test case ResultCodeCheck.1.2
--]]

			-----------------------------------------------------------------------------------------
			--Begin Test case ResultCodeCheck.1.3
			--Description: Different resultCodes to requests without initialPrompt.
				for i=1,#resultCodes do
					Test["PerformAudioPassThru_" .. tostring(resultCodes[i].code) .."_RequestWithOutTTS"] = function(self)
						local params = createRequest()

						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error Message")

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--mobile side: expect PerformAudioPassThru response
						if resultCodes[i].code ~= WARNINGS then
							EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].code })
						else
							EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = "UNSUPPORTED_RESOURCE" })
						end
						DelayedExp(1000)
					end
				end
			--End Test case ResultCodeCheck.1.3
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-557

			--Verification criteria:
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent  within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			function Test:PerformAudioPassThru_AppNotRegistered()
				--mobile side: sending PerformAudioPassThru request
				cid = self.mobileSession1:SendRPC(APIName, createRequest())

				--mobile side: expect PerformAudioPassThru response
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				:Timeout(50)
			end
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.3
		--Description: Check DISALLOWED result code with success false

			--Requirement id in JAMA:
				--SDLAQ-CRS-561

			--Verification criteria:
				-- SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				-- SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.
	--[[ TODO:  Need to debugg
			--Begin Test case ResultCodeChecks.3.1
			--Description: Check resultCode DISALLOWED when RPC is omitted in the PolicyTable
				function Test:Precondition_PolicyUpdate()
					self:policyUpdate("PTU_OmittedPerformAudioPassThru.json", false)
				end

				function Test:PerformAudioPassThru_resultCode_DISALLOWED_RPCOmitted()
					--mobile side: sending the request
					local RequestParams = createRequest()
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
				end
			--End Test case ResultCodeChecks.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeChecks.3.2
			--Description: Check resultCode USER_DISALLOWED when RPC has not yet received user's consents
				function Test:Precondition_PolicyUpdate()
					self:policyUpdate("PTU_ForPerformAudioPassThru.json", true, false)

					DelayedExp(1000)
				end

				function Test:PerformAudioPassThru_resultCode_USER_DISALLOWED()
					--mobile side: sending the request
					local RequestParams = createRequest()
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "USER_DISALLOWED"})

					DelayedExp(1000)
				end

				function Test:Postcondition_PolicyUpdate()
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = groupID, name = groupName}}, source = "GUI"})

					DelayedExp(1000)
				end]]
			--End Test case ResultCodeChecks.3.2
		--End Test case ResultCodeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: Checking cases where ttsChunks is sent but is not supported

			--Requirement id in JAMA:
				--SDLAQ-CRS-1031

			--Verification criteria:
				-- When "ttsChunks" are sent in the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
--[[TODO: Update according to APPLINK-15261
			local ttsChunksType = {{text = "4025",type = "PRE_RECORDED"},{ text = "Sapi",type = "SAPI_PHONEMES"}, {text = "LHplus", type = "LHPLUS_PHONEMES"}, {text = "Silence", type = "SILENCE"}, {text = "File.m4a", type = "FILE"}}
			for i=1,#ttsChunksType do
					Test["PerformAudioPassThru_ttsChunksType" .. tostring(ttsChunksType[i].type)] = function(self)
						local params = createRequest()
						params["initialPrompt"] = {
													{
														text = ttsChunksType[i].text,
														type = ttsChunksType[i].type
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendError(data.id, data.method, "WARNING", "ttsChunks type is unsupported")

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "ttsChunks type is unsupported"})

						DelayedExp(1000)
					end
				end
		--End Test case ResultCodeCheck.4
--]]
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
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI
		--Begin Test case HMINegativeCheck.1
		--Description: Check SDL behavior in case of absence of responses from HMI

			--Requirement id in JAMA: SDLAQ-CRS-560

			--Verification criteria:
				-- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			--Begin Test case HMINegativeCheck.1.1
			--Description: Without TTS response from HMI
				function Test:PerformAudioPassThru_WithoutTTSResponse()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT"
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {})
								:Times(0)
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(15000)

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.1.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.2
			--Description: Without UI response from HMI
				function Test:PerformAudioPassThru_WithoutUIResponse()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(15000)

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.1.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.3
			--Description: Without TTS & UI response from HMI
				function Test:PerformAudioPassThru_WithoutTTSUIResponse()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {})
								:Times(0)
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(15000)

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.1.3

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.4
			--Description: Without response to request without initialPrompt
				function Test:PerformAudioPassThru_WithoutResponseToRequestWithoutInitialPrompt()
					local params = createRequest()
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(15000)

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.1.4
		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: Check processing 2 equal responses

			--Requirement id in JAMA: SDLAQ-CRS-82

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

			--Begin Test case HMINegativeCheck.2.1
			--Description: 2 responses to TTS.Speak request
				function Test:PerformAudioPassThru_TwoResponsesToTTSSpeak()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.2
			--Description: 2 responses to UI.PerformAudioPassThru request
				function Test:PerformAudioPassThru_TwoResponsesToUI()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.3
			--Description: 2 responses to TTS.Speak and UI.PerformAudioPassThru request
				function Test:PerformAudioPassThru_TwoResponsesToTTSUI()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.2.3
		--End Test case HMINegativeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description: Check processing response with fake parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-82, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--[[ - In case HMI sends request (response, notification) with fake parameters that SDL should use internally -> SDL must:
					- validate received response
					- cut off fake parameters
					- process received request (response, notification)
				]]
			--Begin Test case HMINegativeCheck.3.1
			--Description: TTS response with fake parameter
				function Test:PerformAudioPassThru_FakeParamsInTTSResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.fake then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: UI response with fake parameter
				function Test:PerformAudioPassThru_FakeParamsInUIResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.fake then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.3
			--Description: TTS & UI response with fake parameter
				function Test:PerformAudioPassThru_FakeParamsInTTSUIResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.fake then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.3

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.4
			--Description: TTS response with parameter from another API
				function Test:PerformAudioPassThru_ParamsAnotherAPIInTTSResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.4

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.5
			--Description: UI response with parameter from another API
				function Test:PerformAudioPassThru_ParamsAnotherAPIInUIResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.5

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.6
			--Description: TTS & UI response with parameter from another API
				function Test:PerformAudioPassThru_ParamsAnotherAPIInTTSUIResponse()
					local params = createRequest()
						params["initialPrompt"] = {
													{
														text ="Makeyourchoice",
														type ="TEXT",
													}
												}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC(APIName, params)

						UIParams = self:createUIParameters(params)
						TTSSpeakParams = self:createTTSSpeakParameters(params)


						--hmi side: expect TTS.Speak request
						EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
						:Do(function(_,data)
							--Send notification to start TTS
							self.hmiConnection:SendNotification("TTS.Started")

							local function ttsSpeakResponse()
								--hmi side: sending TTS.Speak response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

								--Send notification to stop TTS
								self.hmiConnection:SendNotification("TTS.Stopped")

								--hmi side: expect UI.OnRecordStart
								EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
							end

							RUN_AFTER(ttsSpeakResponse, 50)
						end)


						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							local function uiResponse()
								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

								SendOnSystemContext(self,"MAIN")
							end

							RUN_AFTER(uiResponse, 1500)
						end)

						--mobile side: expect OnHMIStatus notification
						ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)

						DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.3.6
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
		--Begin Test case HMINegativeCheck.4
		--Description: Check processing with different condition of correlationID

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-82, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
			--Begin Test case HMINegativeCheck.4.1
			--Description: TTS response with correlationID is missed
				function Test:PerformAudioPassThru_TTSResponse_CorrelationIDMissing()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: UI response with correlationID is missed
				function Test:PerformAudioPassThru_UIResponse_CorrelationIDMissing()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.3
			--Description: TTS & UI response with correlationID is missed
				function Test:PerformAudioPassThru_TTSUIResponse_CorrelationIDMissing()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":0}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":0}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.3

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.4
			--Description: TTS response with correlationID is wrong type
				function Test:PerformAudioPassThru_TTSResponse_CorrelationIDWrongType()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.4

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.5
			--Description: UI response with correlationID is wrong type
				function Test:PerformAudioPassThru_UIResponse_CorrelationIDWrongType()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.5

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.6
			--Description: TTS & UI response with correlationID is wrong type
				function Test:PerformAudioPassThru_TTSUIResponse_CorrelationIDWrongType()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.6

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.7
			--Description: TTS response with correlationID is not existed
				function Test:PerformAudioPassThru_TTSResponse_CorrelationIDNotExisteded()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.7

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.8
			--Description: UI response with correlationID is not existed
				function Test:PerformAudioPassThru_UIResponse_CorrelationIDNotExisteded()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.8

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.9
			--Description: TTS & UI response with correlationID is not existed
				function Test:PerformAudioPassThru_TTSUIResponse_CorrelationIDNotExisteded()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.9

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.10
			--Description: TTS response with correlationID is negative
				function Test:PerformAudioPassThru_TTSResponse_CorrelationIDNegative()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.10

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.11
			--Description: UI response with correlationID is negative
				function Test:PerformAudioPassThru_UIResponse_CorrelationIDNegative()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.11

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.12
			--Description: TTS & UI response with correlationID is negative
				function Test:PerformAudioPassThru_TTSUIResponse_CorrelationIDNegative()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.12

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.13
			--Description: TTS response with correlationID is null
				function Test:PerformAudioPassThru_TTSResponse_CorrelationIDNull()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.13

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.14
			--Description: UI response with correlationID is null
				function Test:PerformAudioPassThru_UIResponse_CorrelationIDNull()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"UI.PerformAudioPassThru"}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.14

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.15
			--Description: TTS & UI response with correlationID is null
				function Test:PerformAudioPassThru_TTSUIResponse_CorrelationIDNull()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"UI.PerformAudioPassThru"}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

					DelayedExp(1000)
				end
			--End Test case HMINegativeCheck.4.15
		--Begin Test case HMINegativeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description:
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-82

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			--Begin Test case HMINegativeCheck.5.1
			--Description: TTS response to correlationID of UI and vice versa
				function Test:PerformAudioPassThru_WrongResponseToCorrectID()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

					DelayedExp(1000)
				end
			--Begin Test case HMINegativeCheck.5.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.2
			--Description: TTS response with two contractions of result in response
				function Test:PerformAudioPassThru_TTSWrongResponseToCorrectID()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:Send('{"error":{"code":4,"message":"Speak is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

					DelayedExp(1000)
				end
			--Begin Test case HMINegativeCheck.5.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.3
			--Description: UI response with two contractions of result in response
				function Test:PerformAudioPassThru_UIWrongResponseToCorrectID()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", {})

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:Send('{"error":{"code":4,"message":"PerformAudioPassThru is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.PerformAudioPassThru"}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

					DelayedExp(1000)
				end
			--Begin Test case HMINegativeCheck.5.3

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.4
			--Description: TTS & UI response with two contractions of result in response
				function Test:PerformAudioPassThru_TTSUIWrongResponseToCorrectID()
					local params = createRequest()
					params["initialPrompt"] = {
												{
													text ="Makeyourchoice",
													type ="TEXT",
												}
											}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC(APIName, params)

					UIParams = self:createUIParameters(params)
					TTSSpeakParams = self:createTTSSpeakParameters(params)


					--hmi side: expect TTS.Speak request
					EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
					:Do(function(_,data)
						--Send notification to start TTS
						self.hmiConnection:SendNotification("TTS.Started")

						local function ttsSpeakResponse()
							--hmi side: sending TTS.Speak response
							self.hmiConnection:Send('{"error":{"code":4,"message":"Speak is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"TTS.Speak"}}')

							--Send notification to stop TTS
							self.hmiConnection:SendNotification("TTS.Stopped")

							--hmi side: expect UI.OnRecordStart
							EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
						end

						RUN_AFTER(ttsSpeakResponse, 50)
					end)


					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						local function uiResponse()
							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:Send('{"error":{"code":4,"message":"PerformAudioPassThru is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.PerformAudioPassThru"}}')

							SendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(uiResponse, 1500)
					end)

					--mobile side: expect OnHMIStatus notification
					ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

					DelayedExp(1000)
				end
			--Begin Test case HMINegativeCheck.5.4
		--End Test case HMINegativeCheck.5
--]]
	--End Test suit HMINegativeCheck


----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Begin Test case SequenceCheck.1
		--Description: Check OnAudioPassThru notifications is send every 1 second.

			--Requirement id in JAMA:
				-- SDLAQ-CRS-186

			--Verification criteria:
				--Alert request notifies the user via TTS/UI or both with some information.
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
			function Test:PerformAudioPassThru_OnAudioPassThruSendEverySecond()
				local params = createRequest()
				params["initialPrompt"] = {
											{
												text ="Makeyourchoice",
												type ="TEXT",
											}
										}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC(APIName, params)

				UIParams = self:createUIParameters(params)
				TTSSpeakParams = self:createTTSSpeakParameters(params)


				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
				:Do(function(_,data)
					--Send notification to start TTS
					self.hmiConnection:SendNotification("TTS.Started")

					local function ttsSpeakResponse()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--Send notification to stop TTS
						self.hmiConnection:SendNotification("TTS.Stopped")

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					end

					RUN_AFTER(ttsSpeakResponse, 1000)
				end)


				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					local function uiResponse()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(uiResponse, 12000)
				end)

				--mobile side: expect OnHMIStatus notification
				ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Times(AtLeast(10))
				:Timeout(15000)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(15000)

				DelayedExp(1000)
			end
		--End Test case SequenceCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.2
		--Description: Call PerformAudioPassThru request and check TTS.OnResetTimeout notification for TTS.Speak with consecutive response from TTS then.

			--Requirement id in JAMA:
				-- SDLAQ-TC-783

			--Verification criteria:
				--SDL must renew the default timeout for the RPC defined in TTS.OnResetTimeout notification received from HMI.
			function Test:PerformAudioPassThru_OnResetTimeout()
				local params = createRequest()
				params["initialPrompt"] = {
											{
												text ="Makeyourchoice",
												type ="TEXT",
											}
										}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC(APIName, params)

				UIParams = self:createUIParameters(params)
				TTSSpeakParams = self:createTTSSpeakParameters(params)


				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
				:Do(function(_,data)
					--Send notification to start TTS
					self.hmiConnection:SendNotification("TTS.Started")

					local function OnResetTimeoutSending()
						self.hmiConnection:SendNotification("TTS.OnResetTimeout",
														{
															appID = self.applications["Test Application"],
															methodName = "TTS.Speak"
														})
					end

					local function ttsSpeakResponse()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--Send notification to stop TTS
						self.hmiConnection:SendNotification("TTS.Stopped")

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
					end

					RUN_AFTER(OnResetTimeoutSending, 4000)
					RUN_AFTER(OnResetTimeoutSending, 8000)
					RUN_AFTER(OnResetTimeoutSending, 12000)
					RUN_AFTER(OnResetTimeoutSending, 16000)

					RUN_AFTER(ttsSpeakResponse, 20000)
				end)


				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					local function uiResponse()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(uiResponse, 26000)
				end)
				:Timeout(30000)

				--mobile side: expect OnHMIStatus notification
				ExpectOnHMIStatusWithAudioStateChanged(self, "FULL", true, 30000)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Times(AtLeast(5))
				:Timeout(30000)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(30000)

				DelayedExp(1000)
			end
		--End Test case SequenceCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.3
		--Description: Checking RETRY sequence

			--Requirement id in JAMA:
				-- SDLAQ-TC-46

			--Verification criteria:
				--Call PerformAudioPassThru request from mobile app and retry PerformAudioPassThru session via "Retry" option on UI
			function Test:PerformAudioPassThru_RETRY()
				local level = "FULL"
				local params = createRequest()
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru",params)

				local msg =
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 16,
					rpcCorrelationId = cid,
					payload          = '{"bitsPerSample":"8_BIT","samplingRate":"8KHZ","audioType":"PCM","maxDuration":2000}'
				}

				UIParams = self:createUIParameters(params)

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(exp,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					local function uiResponseRETRY()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "RETRY", {})

						SendOnSystemContext(self,"MAIN")
					end

					local function uiResponseSUCCESS()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end

					if exp.occurences == 1 then
						RUN_AFTER(uiResponseRETRY, 1500)
					else
						RUN_AFTER(uiResponseSUCCESS, 3500)
					end
				end)
				:Times(2)

				--mobile side: Expected OnHMIStatus notification
				if
					self.isMediaApplication == true or
					Test.appHMITypes["NAVIGATION"] == true then

					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(4)
					:Timeout(10000)

					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Times(AtLeast(1))
					:Timeout(10000)

				elseif
					self.isMediaApplication == false then
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
						:Times(4)
						:Timeout(10000)

						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Times(AtLeast(2))
						:Timeout(10000)
				end

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
				:Times(2)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "RETRY" }, { success = true, resultCode = "SUCCESS" })
				:Do(function(exp,data)
					if exp.occurences == 1 then
						self.mobileSession:Send(msg)
					end
				end)
				:Times(2)
				:Timeout(15000)
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
		--Requirement id in JAMA:
				-- SDLAQ-CRS-796
			--Verification criteria:
				-- SDL rejects PerformAudioPassThru request with REJECTED resultCode when current HMI level is NONE or BACKGROUND with system context not MAIN.
				-- SDL doesn't reject PerformAudioPassThru request when current HMI is FULL and SystemContext MAIN.
				-- SDL doesn't reject PerformAudioPassThru request when current HMI is LIMITED and SystemContext MAIN.

		--Begin Test case DifferentHMIlevelChecks.1
		--Description: Check request is disallowed in NONE HMI level
			function Test:Precondition_DeactivateApp()
				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end

			function Test:PerformAudioPassThru_HMIStatus_NONE()
				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
			end

			--Postcondition: Activate app
			commonSteps:ActivationApp(self)

		--End Test case DifferentHMIlevelChecks.1
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.2
		--Description: Check HMI level Full

			--It is covered by above test cases

		--End Test case DifferentHMIlevelChecks.2
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.3
		--Description: Check HMI level LIMITED
		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then

				--Precondition: Deactivate app to LIMITED HMI level
				commonSteps:ChangeHMIToLimited(self)

				function Test:PerformAudioPassThru_HMIStatus_LIMITED()
					local RequestParams = createRequest()
					self:verify_SUCCESS_Case(RequestParams, "LIMITED")
				end

		--End Test case DifferentHMIlevelChecks.3

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
				local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
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

				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
				  application =
				  {
					appName = "Test Application2"
				  }
				})
				:Do(function(_,data)
					local appId2 = data.params.application.appID
					self.appId2 = appId2
				end)

				self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
				:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 3: Activate an other media app to change app to BACKGROUND
			function Test:Activate_Media_App2()
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appId2})
				EXPECT_HMIRESPONSE(rid)

				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN"})
			end


		elseif Test.isMediaApplication == false then
			--Precondition: Deactivate app to BACKGOUND HMI level
			commonSteps:DeactivateToBackground(self)
		end

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.4
		--Description: Check HMI level BACKGOUND
		function Test:PerformAudioPassThru_HMIStatus_BACKGOUND()
			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
		end
		--End Test case DifferentHMIlevelChecks.4

	----------------------------------------------------------------------------------------------
	local function APPLINK_16126()

		--Begin Test case DifferentHMIlevelChecks.5
		--Description: Check OnAudioPassThru is not received when HMI level NONE
			--Requirement id in JAMA:
				-- SDLAQ-CRS-1311
			--Verification criteria:
				-- SDL doesn't send OnAudioPassThru notification to the app when current app's HMI level is NONE.

			--Precondition: Activate app
			commonSteps:ActivationApp(self)

			--Send PerformAudioPassThru from default App
			function Test:PerformAudioPassThru_notreceivedOnAudioPassThru_NONE()

				level = "FULL"
				local params = createRequest()
				params["initialPrompt"] = {
											{
												text ="Makeyourchoice",
												type ="TEXT",
											}
										}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC(APIName, params)

				UIParams = self:createUIParameters(params)
				TTSSpeakParams = self:createTTSSpeakParameters(params)

				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
				:Do(function(_,data)
					--Send notification to start TTS
					self.hmiConnection:SendNotification("TTS.Started")

					local function ttsSpeakResponse()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--Send notification to stop TTS
						self.hmiConnection:SendNotification("TTS.Stopped")

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
					end
					RUN_AFTER(ttsSpeakResponse, 50)
				end)

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					local function uiResponse()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						SendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 12000)
				end)

				--mobile side: expect OnHMIStatus notification
				if
					Test.isMediaApplication == true or
					Test.appHMITypes["NAVIGATION"] == true then

					EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
								)
					:Times(5)
					:Timeout(15000)
				else
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Timeout(15000)

				end

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Times(AtLeast(3))
				:Timeout(15000)
				:ValidIf (function(_,data)
					if level == "NONE" then
						print(" \27[36m Expected Result: No OnAudioPassThru notification received at HMILevel NONE \27[0m ")
						return false
					else
						return true
					end
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(15000)

				DelayedExp(1000)

				--Deactivate app by USER_EXIT to change app to NONE
				local function DeactivateApp()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
				end
				RUN_AFTER(DeactivateApp, 5001)
			end

			--Postcondition: Activate app
			function Test:Activation_App_DifferentHMIlevelChecks5()
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application"]})
					EXPECT_HMIRESPONSE(rid)
			end

		--End Test case DifferentHMIlevelChecks.5

		----------------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.6
		--Description: Check OnAudioPassThru is received when HMI level BACKGROUND
			--Requirement id in JAMA:
				-- SDLAQ-CRS-1311
			--Verification criteria:
				-- SDL sends OnAudioPassThru notification to the app when current app's HMI level  is BACKGROUND.
		if
				Test.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then

			--Precondition 1: Add new session
			function Test:AddNewSession()
			--	Connected expectation
				self.mobileSession3 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession3:StartService(7)
			end

			-- Precondition 2: Register App3
			function Test:RegisterAppInterface_App3()
				local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
				{
				  syncMsgVersion =
				  {
					majorVersion = 3,
					minorVersion = 0
				  },
				  appName = "Test Application3",
				  isMediaApplication = true,
				  languageDesired = 'EN-US',
				  hmiDisplayLanguageDesired = 'EN-US',
				  appHMIType = { "NAVIGATION" },
				  appID = "3"
				})

				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
				  application =
				  {
					appName = "Test Application3"
				  }
				})
				:Do(function(_,data)
					local appId3 = data.params.application.appID
					self.appId3 = appId3
				end)

				self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
				:Timeout(2000)

				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
--TODO: to debug
			--[[
			--Send PerformAudioPassThru from default App
			function Test:PerformAudioPassThru_receivedOnAudioPassThru_BACKGROUND()
				local params = createRequest()
				params["initialPrompt"] = {
											{
												text ="Makeyourchoice",
												type ="TEXT",
											}
										}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC(APIName, params)

				UIParams = self:createUIParameters(params)
				TTSSpeakParams = self:createTTSSpeakParameters(params)


				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
				:Do(function(_,data)
					--Send notification to start TTS
					self.hmiConnection:SendNotification("TTS.Started")

					local function ttsSpeakResponse()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--Send notification to stop TTS
						self.hmiConnection:SendNotification("TTS.Stopped")

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					end
					RUN_AFTER(ttsSpeakResponse, 50)

				end)


				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					local function uiResponse()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(uiResponse, 12000)
				end)

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
							{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"} --Reference: APPLINK-16313
							)
				:Times(5)
				:Timeout(10000)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Times(AtLeast(10))
				:Timeout(15000)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(15000)

				DelayedExp(1000)

				--Activate another app to change app to BACKGROUND
				local function ActivateApp3()
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.appId3})
					EXPECT_HMIRESPONSE(rid)

					self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
					--Set Timeout to make sure application is changed to BACKGROUND after 7 seconds, so that application can receive OnAudioPassThru during BACKGROUND
					:Timeout(2000)
				end
				RUN_AFTER(ActivateApp3, 5000)

		end

		else
			--Deactivate App1 => BACKGROUND
			--Send PerformAudioPassThru from default App
			function Test:PerformAudioPassThru_receivedOnAudioPassThru_BACKGROUND()

				local params = createRequest()
				params["initialPrompt"] = {
											{
												text ="Makeyourchoice",
												type ="TEXT",
											}
										}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC(APIName, params)
				UIParams = self:createUIParameters(params)
				TTSSpeakParams = self:createTTSSpeakParameters(params)

				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
				:Do(function(_,data)
					--Send notification to start TTS
					self.hmiConnection:SendNotification("TTS.Started")

					local function ttsSpeakResponse()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--Send notification to stop TTS
						self.hmiConnection:SendNotification("TTS.Stopped")

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					end
					RUN_AFTER(ttsSpeakResponse, 50)

				end)

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")
					local function uiResponse()
						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						SendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(uiResponse, 12000)
				end)

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"} --Reference: APPLINK-16313
								)
				:Times(3)
				:Timeout(15000)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Times(AtLeast(10))
				:Timeout(15000)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(15000)
				DelayedExp(1000)

				--Deactivate another app to change app to BACKGROUND
				local function DeactivateToBackground()
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",{appID = self.applications["Test Application"], reason = "GENERAL"})
				end
				RUN_AFTER(DeactivateToBackground, 5000)
			end
			--]]
		end

		--Postcondition: Activate app
			function Test:Activation_App_App_DifferentHMIlevelChecks6()
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application"]})
					EXPECT_HMIRESPONSE(rid)
			end

		--End Test case DifferentHMIlevelChecks.6

	end
	APPLINK_16126()

	--End Test suit DifferentHMIlevel

 return Test

