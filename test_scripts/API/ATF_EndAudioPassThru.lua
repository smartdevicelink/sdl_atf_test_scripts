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
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "EndAudioPassThru" -- set request name
local infoMessage = string.rep("a", 1000)
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local storagePath = config.pathToSDL .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"
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
--1. createTTSSpeakParameters(RequestParams)
--2. createUIParameters(RequestParams)
--3. policyUpdate()
---------------------------------------------------------------------------------------------

--Create TTS.Speak expected result based on parameters from the request
function Test:createTTSSpeakParameters(RequestParams)
	local param =  {}

	param["speakType"] =  "AUDIO_PASS_THRU"

	--initialPrompt
	if RequestParams["initialPrompt"]  ~= nil then
		param["ttsChunks"] =  RequestParams["initialPrompt"]
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

--Description: Update policy from specific file
	--policyFileName: Name of policy file
	--bAllowed: true if want to allowed New group policy
	--          false if want to disallowed New group policy
local groupID
local groupName = "New"
function Test:policyUpdate(policyFileName, bAllowed)
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

					--hmi side: sending SDL.GetListOfPermissions request to SDL
					local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})

					-- hmi side: expect SDL.GetListOfPermissions response
					 -- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = groupName}}}})
					EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
					:Do(function(_,data)
						if data.result.allowedFunctions[1] ~= nil then
							groupID = data.result.allowedFunctions[1].id
							--print("SDL.GetListOfPermissions response is received")
						end

						--hmi side: sending SDL.OnAppPermissionConsent
						self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = bAllowed, id = groupID, name = groupName}}, source = "GUI"})
						end)
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
  os.remove(file_name)
    return true
  end
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


	--2. PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
	commonSteps:PutFile("PutFile_MinLength", "a")
	commonSteps:PutFile("PutFile_icon.png", "icon.png")
	commonSteps:PutFile("PutFile_icon.png", "action.png")
	commonSteps:PutFile("PutFile_MaxLength_255Characters", strMaxLengthFileName255)

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
					-- SDLAQ-CRS-83

			--Verification criteria:
					-- EndAudioPassThru finishes the previously activated PerfromAudioPassThu. First EndAudioPassThru is responded by SDL, then the relevant PerfromAudioPassThu gets the response.
			function Test:EndAudioPassThru_Positive()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				UIParams = self:createUIParameters(params)

				ExpectOnHMIStatusWithAudioStateChanged(self,_, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function(_,data)
					local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

					EXPECT_HMICALL("UI.EndAudioPassThru")
					:Do(function(_,data)
						--hmi side: sending UI.EndAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end)

					--mobile side: expect EndAudioPassThru response
					EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if file_check(storagePath.."/".."audio.wav") ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
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

			-- Not Applicable

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
				function Test:EndAudioPassThru_FakeParam()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {fakeParam = "fakeParam"})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)
						:ValidIf(function(_,data)
							if data.params ~= nil then
									print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
									return false
							else
								return true
							end
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--Begin Test case CommonRequestCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:EndAudioPassThru_ParamsAnotherRequest()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {syncFileName = "icon.png",})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)
						:ValidIf(function(_,data)
							if data.params ~= nil then
									print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
									return false
							else
								return true
							end
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case CommonRequestCheck.4.2
		--End Test case CommonRequestCheck.4
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-565

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:EndAudioPassThru_IncorrectJSON()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				UIParams = self:createUIParameters(params)

				ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function(_,data)
					self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 17,
							rpcCorrelationId = self.mobileSession.correlationId,
							--<<!-- missing '{'
							payload          = '{'
						}
					self.mobileSession:Send(msg)
					EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

					--hmi side: sending UI.PerformAudioPassThru response
					self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

					SendOnSystemContext(self,"MAIN")
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if file_check(storagePath.."/".."audio.wav") ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.6
		--Description: Checking send request with duplicate correlationID

			--Requirement id in JAMA: SDLAQ-CRS-564, SDLAQ-CRS-569
			--Verification criteria:
				--The request is executed successfully.
				--In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				function Test:EndAudioPassThru_CorrelationIdDuplicate()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(exp,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						self.mobileSession.correlationId = cidEndAudioPassThru
						local msg =
							{
								serviceType      = 7,
								frameInfo        = 0,
								rpcType          = 0,
								rpcFunctionId    = 17,
								rpcCorrelationId = self.mobileSession.correlationId,
								payload          = '{}'
							}

						--hmi side: expected UI.EndAudioPassThru request
						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(exp,data)
							if exp.occurences == 1 then
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")

								--Send second EndAudioPassThru request
								self.mobileSession:Send(msg)

								DelayedExp(1000)
							else
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message")

								DelayedExp(1000)
							end
						end)
						:Times(2)
						:Timeout(5000)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" },
															{ success = false, resultCode = "REJECTED", info = "Error Message" })
						:Times(2)
						:Timeout(10000)
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
					:Timeout(10000)
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

			-- Not Applicable

		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Check process response with info parameter in bound

				--Requirement id in JAMA:
					--SDLAQ-CRS-84
					--APPLINK-14551

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				--Begin Test case PositiveResponseCheck.1.1
				--Description: Response info parameter lower bound
					function Test:EndAudioPassThru_ResponseWithInfoLowerBound()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "a")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED", info = "a" })
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case PositiveResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description: Response info parameter upper bound
					function Test:EndAudioPassThru_ResponseWithInfoUpperBound()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", infoMessage)

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED", info = infoMessage})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case PositiveResponseCheck.1.2
			--End Test case PositiveResponseCheck.1
		--End Test suit PositiveResponseCheck

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

			-- Not Applicable

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
					--SDLAQ-CRS-84
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
--[[TODO: Check after APPLINK-14765 is resolved
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Response with nonexistent resultCode
					function Test:EndAudioPassThru_ResponseResultCodeNotExist()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Response with empty string in method
					function Test:EndAudioPassThru_ResponseMethodOutLowerBound()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.1.2
			--End Test case NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters
				--Requirement id in JAMA:
					--SDLAQ-CRS-84
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
				--Begin Test case NegativeResponseCheck.2.1
				--Description: Response without all parameters
					function Test:EndAudioPassThru_ResponseMissingAllPArameters()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:Send('{}')

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR"})
							:Timeout(12000)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Response without method parameter
					function Test:EndAudioPassThru_ResponseMethodMissing()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}')

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Response without resultCode parameter
					function Test:EndAudioPassThru_ResponseResultCodeMissing()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.EndAudioPassThru"}}')

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.4
				--Description: Response missing all mandatory parameter
					function Test:EndAudioPassThru_ResponseMissingMandatory()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.2.4
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type
				--Requirement id in JAMA:
					--SDLAQ-CRS-84
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Response with wrong type of method
					function Test:EndAudioPassThru_ResponseMethodWrongType()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Response with wrong type of resultCode
					function Test:EndAudioPassThru_ResponseResultCodeWrongType()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendResponse(data.id, data.method, 1234, {})

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case NegativeResponseCheck.3.2
			--End Test case NegativeResponseCheck.3
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Check processing response with Invalid JSON
				--Requirement id in JAMA:
					--SDLAQ-CRS-84
					--APPLINK-14765

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app

				function Test:EndAudioPassThru_ResponseInvalidJson()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code" 0,"method":"UI.EndAudioPassThru"}}')

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end

			--End Test case NegativeResponseCheck.4
--]]
			-----------------------------------------------------------------------------------------
	--[[TODO: update after resolving APPLINK-14551

			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
				--Requirement id in JAMA/or Jira ID:
					--SDLAQ-CRS-84
					--APPLINK-14551

				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.

				--Begin Test Case NegativeResponseCheck.5.1
				--Description: Response with empty info
					function Test: EndAudioPassThru_ResponseInfoOutLowerBound()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" \27[36m SDL resend invalid info to mobile app \27[0m")
									return false
								else
									return true
								end
							end)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.2
				--Description: Response info out of upper bound
					function Test: EndAudioPassThru_ResponseInfoOutUpperBound()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", infoMessage.."b")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED", info = infoMessage})
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.2

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.3
				--Description: Response with wrong type of info parameter
					function Test: EndAudioPassThru_ResponseInfoWrongType()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", 1234)

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" \27[36m SDL resend invalid info to mobile app \27[0m")
									return false
								else
									return true
								end
							end)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.3

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.4
				--Description: Response with escape sequence \n in info parameter
					function Test: EndAudioPassThru_ResponseInfoWithNewlineChar()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message \n")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" \27[36m SDL resend invalid info to mobile app \27[0m")
									return false
								else
									return true
								end
							end)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.4

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.5
				--Description: TTS response with escape sequence \t in info parameter
					function Test: EndAudioPassThru_ResponseInfoWithTabChar()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message \t")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" \27[36m SDL resend invalid info to mobile app \27[0m")
									return false
								else
									return true
								end
							end)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.5

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.5.6
				--Description: Response with white space only in info parameter
					function Test: EndAudioPassThru_ResponseInfoWithWhiteSpaceOnly()
						local uiPerformID
						local params ={
										samplingRate ="8KHZ",
										maxDuration = 5000,
										bitsPerSample ="8_BIT",
										audioType ="PCM",
									}
						--mobile side: sending PerformAudioPassThru request
						local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

						UIParams = self:createUIParameters(params)

						ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

						--hmi side: expect UI.OnRecordStart
						EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

						--hmi side: expect UI.PerformAudioPassThru request
						EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
						:Do(function(_,data)
							SendOnSystemContext(self,"HMI_OBSCURED")

							uiPerformID = data.id
						end)

						--mobile side: expect OnAudioPassThru response
						EXPECT_NOTIFICATION("OnAudioPassThru")
						:Do(function(_,data)
							local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

							EXPECT_HMICALL("UI.EndAudioPassThru")
							:Do(function(_,data)
								--hmi side: sending UI.EndAudioPassThru response
								self.hmiConnection:SendError(data.id, data.method, "REJECTED", "        ")

								--hmi side: sending UI.PerformAudioPassThru response
								self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

								SendOnSystemContext(self,"MAIN")
							end)

							--mobile side: expect EndAudioPassThru response
							EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
							:ValidIf (function(_,data)
								if data.payload.info then
									print(" \27[36m SDL resend invalid info to mobile app \27[0m")
									return false
								else
									return true
								end
							end)
						end)

						--mobile side: expect PerformAudioPassThru response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(storagePath.."/".."audio.wav") ~= true then
								print(" \27[36m Can not found file: audio.wav \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck.5.6
			--End Test case NegativeResponseCheck.5
		--End Test suit NegativeResponseCheck
		]]

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
				--SDLAQ-CRS-569

			--Verification criteria:
				-- Per HMI-matrix HMI must reject EndAudioPassThru IN CASE no PerformAudioPassThru is now active. SDL must transfer this result to mobile app.
				-- SDL always transfers EndAudioPassThru to HMI.
			function Test: EndAudioPassThru_WithOutPerformAudioPassThru()
				local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

				EXPECT_HMICALL("UI.EndAudioPassThru")
				:Do(function(_,data)
					--hmi side: sending UI.EndAudioPassThru response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
				end)

				--mobile side: expect EndAudioPassThru response
				EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED"})
			end

		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				-- SDLAQ-CRS-568

			--Verification criteria:
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent  within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			function Test:EndAudioPassThru_AppNotRegistered()
				--mobile side: sending PerformAudioPassThru request
				cid = self.mobileSession1:SendRPC("EndAudioPassThru", {})

				--mobile side: expect PerformAudioPassThru response
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				:Timeout(50)
			end
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------

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

			--Requirement id in JAMA: SDLAQ-CRS-571

			--Verification criteria:
				-- No UI response during SDL`s watchdog
			function Test:EndAudioPassThru_WithoutResponse()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				UIParams = self:createUIParameters(params)

				ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function(_,data)
					local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

					EXPECT_HMICALL("UI.EndAudioPassThru")
					:Do(function(_,data)
						--hmi side: sending UI.EndAudioPassThru response

						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end)

					--mobile side: expect EndAudioPassThru response
					EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if file_check(storagePath.."/".."audio.wav") ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: Check processing 2 equal responses

			--Requirement id in JAMA: SDLAQ-CRS-84

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:EndAudioPassThru_TwoResponsesToOneRequest()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				UIParams = self:createUIParameters(params)

				ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function(_,data)
					local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

					EXPECT_HMICALL("UI.EndAudioPassThru")
					:Do(function(_,data)
						--hmi side: sending UI.EndAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error")

						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end)

					--mobile side: expect EndAudioPassThru response
					EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS"})
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if file_check(storagePath.."/".."audio.wav") ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case HMINegativeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description: Check processing response with fake parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-84, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--[[ - In case HMI sends request (response, notification) with fake parameters that SDL should use internally -> SDL must:
					- validate received response
					- cut off fake parameters
					- process received request (response, notification)
				]]
			--Begin Test case HMINegativeCheck.3.1
			--Description: Response with fake parameter
				function Test:EndAudioPassThru_FakeParamsInResponse()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS"})
						:ValidIf (function(_,data)
							if data.payload.fakeParam then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: Response with parameter from another API
				function Test:EndAudioPassThru_ParamsAnotherAPIInResponse()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS"})
						:ValidIf (function(_,data)
							if data.payload.sliderPosition then
								print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
								return false
							else
								return true
							end
						end)
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.3.2
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
		--Begin Test case HMINegativeCheck.4
		--Description: Check processing with different condition of correlationID

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-84, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				--In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
			--Begin Test case HMINegativeCheck.4.1
			--Description: Response with correlationID is missed
				function Test:EndAudioPassThru_Response_CorrelationIDMissing()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.EndAudioPassThru", "code":0}}')
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.EndAudioPassThru", "code":0}}')

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: Response with correlationID is wrong type
				function Test:EndAudioPassThru_Response_CorrelationIDWrongType()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.4.2

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.3
			--Description: Response with correlationID is not existed
				function Test:EndAudioPassThru_Response_CorrelationIDNotExisted()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.4.3

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.4
			--Description: Response with correlationID is negative
				function Test:EndAudioPassThru_Response_CorrelationIDNegative()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.4.4

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.5
			--Description: Response with correlationID is null
				function Test:EndAudioPassThru_Response_CorrelationIDNull()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"UI.EndAudioPassThru"}}')

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case HMINegativeCheck.4.5
		--Begin Test case HMINegativeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description:
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-84

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:EndAudioPassThru_WrongResponseToCorrectID()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				UIParams = self:createUIParameters(params)

				ExpectOnHMIStatusWithAudioStateChanged(self, _, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function(_,data)
					local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

					EXPECT_HMICALL("UI.EndAudioPassThru")
					:Do(function(_,data)
						--hmi side: sending UI.EndAudioPassThru response
						self.hmiConnection:Send('{"error":{"code":4,"message":"EndAudioPassThru is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"UI.EndAudioPassThru"}}')

						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

						SendOnSystemContext(self,"MAIN")
					end)

					--mobile side: expect EndAudioPassThru response
					EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if file_check(storagePath.."/".."audio.wav") ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case HMINegativeCheck.5
--]]
	--End Test suit HMINegativeCheck


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
		--Requirement id in JAMA:
				-- SDLAQ-CRS-797
			--Verification criteria:
				-- SDL rejects EndAudioPassThru request with REJECTED resultCode when the current HMI level is NONE.
				-- SDL doesn't reject EndAudioPassThru request when current HMI is FULL.
				-- SDL doesn't reject EndAudioPassThru request when current HMI is LIMITED.
				-- SDL doesn't reject EndAudioPassThru request when current HMI is BACKGROUND.

		--Begin Test case DifferentHMIlevelChecks.1
		--Description: Check request is disallowed in NONE HMI level
			function Test:Precondition_DeactivateApp()
				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end

			function Test:EndAudioPassThru_HMIStatus_NONE()
				--mobile side: Send EndAudioPassThru request
				local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

				--mobile side: expect EndAudioPassThru response
				EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "DISALLOWED"})
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

				function Test:EndAudioPassThru_HMIStatus_LIMITED()
					local uiPerformID
					local params ={
									samplingRate ="8KHZ",
									maxDuration = 5000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
								}
					--mobile side: sending PerformAudioPassThru request
					local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

					UIParams = self:createUIParameters(params)

					ExpectOnHMIStatusWithAudioStateChanged(self, "LIMITED", false)

					--hmi side: expect UI.OnRecordStart
					EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

					--hmi side: expect UI.PerformAudioPassThru request
					EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
					:Do(function(_,data)
						SendOnSystemContext(self,"HMI_OBSCURED")

						uiPerformID = data.id
					end)

					--mobile side: expect OnAudioPassThru response
					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Do(function(_,data)
						local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

						EXPECT_HMICALL("UI.EndAudioPassThru")
						:Do(function(_,data)
							--hmi side: sending UI.EndAudioPassThru response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--hmi side: sending UI.PerformAudioPassThru response
							self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

							SendOnSystemContext(self,"MAIN")
						end)

						--mobile side: expect EndAudioPassThru response
						EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
					end)

					--mobile side: expect PerformAudioPassThru response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if file_check(storagePath.."/".."audio.wav") ~= true then
							print(" \27[36m Can not found file: audio.wav \27[0m ")
							return false
						else
							return true
						end
					end)
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

		--Begin Test case DifferentHMIlevelChecks.4
		--Description: Check HMI level BACKGOUND
		function Test:EndAudioPassThru_HMIStatus_BACKGROUND()
			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("EndAudioPassThru", {})

			EXPECT_HMICALL("UI.EndAudioPassThru")
			:Do(function(_,data)
				--hmi side: sending UI.EndAudioPassThru response
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message")
			end)

			--mobile side: expect EndAudioPassThru response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "REJECTED", info = "Error Message"})
		end
		--End Test case DifferentHMIlevelChecks.4
	--End Test suit DifferentHMIlevel


 return Test
