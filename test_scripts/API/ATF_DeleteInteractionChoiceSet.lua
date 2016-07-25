Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
require('user_modules/AppTypes')
--------------------------------------------------------------------------------------------------

local infoMessage = "qqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'"
local appId3

function setChoiseSet(startID, size)
	if (size ~= nil) then
		temp = {}
		for i = 1, size do
		temp[i] = {
				choiceID =startID+i-1,
				menuName ="Choice" .. startID+i-1,
				vrCommands =
				{
					"Choice" .. startID+i-1,
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC",
				},
		  }
		end
	else
		temp =  {{
					choiceID =startID,
					menuName ="Choice" .. startID,
					vrCommands =
					{
						"Choice" .. startID,
					},
					image =
					{
						value ="icon.png",
						imageType ="STATIC",
					},
		}}
	end
	return temp
end
function setEXChoiseSet(startID, size)
	exChoiceSet = {}
	for i = 1, size do
	exChoiceSet[i] =  {
		cmdID = startID+i-1, type = "Choice", vrCommands = {"Choice"..startID+i-1}
	}
	end
	return exChoiceSet
end
function Test:createInteractionChoiceSetMultiChoice(choiceSetID)
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceSetID,
												choiceSet = setChoiseSet(choiceSetID, 5)
											})

	--hmi side: expect VR.AddCommand
	local expectChoiceSet = setEXChoiseSet(choiceSetID,5)
	EXPECT_HMICALL("VR.AddCommand",
								expectChoiceSet[1],
								expectChoiceSet[2],
								expectChoiceSet[3],
								expectChoiceSet[4],
								expectChoiceSet[5])
	:Times(5)
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:createInteractionChoiceSet(choiceSetID)
	local choiceID
	if choiceSetID == 2000000000 then
		choiceID = 65535
	else
		choiceID = choiceSetID
	end
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceSetID,
												choiceSet = setChoiseSet(choiceID),
												})

	--hmi side: expect VR.AddCommand
	EXPECT_HMICALL("VR.AddCommand",{
									cmdID = choiceID,
									type = "Choice",
									vrCommands =
									{
										"Choice" .. tostring(choiceID),
									}
								})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--Activation App by sending SDL.ActivateApp
	commonSteps:ActivationApp()


	--PutFiles
		function Test:PutFile()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true})
		end


	--CreateInteractionChoiceSet
		function Test:CreateInteractionChoiceSetWithMultiChoice()
			self:createInteractionChoiceSetMultiChoice(1)
		end


	-- CreateInteractionChoiceSet
		choiceSetIDValues = {0, 2000000000}
		for i=1, #choiceSetIDValues do
				Test["CreateInteractionChoiceSet" .. choiceSetIDValues[i]] = function(self)
					self:createInteractionChoiceSet(choiceSetIDValues[i])
				end
		end


	-- CreateInteractionChoiceSet
		for i=20, 60 do
			Test["CreateInteractionChoiceSet" .. i] = function(self)
					self:createInteractionChoiceSet(i)
			end
		end


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
		--Description:Positive case and in boundary conditions

			--Requirement id in JAMA:
					--SDLAQ-CRS-45
					--SDLAQ-CRS-471

			--Verification criteria:
					--DeleteInteractionChoiceSet removes previously created ChoiceSet by "interactionChoiceSetID" if ChoiceSet is currently not in use .
					--DeleteInteractionChoiceSet removes ChoiceSet previously created by "interactionChoiceSetID", "SUCCESS" resultCode is returned.
			function Test:DeleteInteractionChoiceSet_Positive()
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																					{
																						interactionChoiceSetID = 1
																					})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
							{cmdID = 1, type = "Choice"},
							{cmdID = 2, type = "Choice"},
							{cmdID = 3, type = "Choice"},
							{cmdID = 4, type = "Choice"},
							{cmdID = 5, type = "Choice"})
				:Times(5)
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description:with fake parameters

			--Requirement id in JAMA:
					--SDLAQ-CRS-45
					--APPLINK-4518

			--Verification criteria:
					--DeleteInteractionChoiceSet request removes the command with corresponding interactionChoiceSetID from the application and SDL.
					--In case SDL can't delete the command with corresponding interactionChoiceSetID from the application, SDL provides the appropriate data about error occured.

			--Begin Test case CommonRequestCheck.2.1
			--Description:DeleteInteractionChoiceSet with parameter not from protocol
				function Test:DeleteInteractionChoiceSet_WithFakeParam()
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 20,
						fakeParam ="fakeParam",
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 20,
						type = "Choice"
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, SUCCESS, {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
								print(" SDL re-sends fakeParam parameters to HMI in VR.DeleteCommand request")
								return false
						else
							return true
						end
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = SUCCESS })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description:DeleteInteractionChoiceSet with parameter from another request
				function Test:DeleteInteractionChoiceSet_ParamsAnotherRequest()
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 21,
						ttsChunks = {
										{
											text ="SpeakFirst",
											type ="TEXT",
										},
										{
											text ="SpeakSecond",
											type ="TEXT",
										},
									}
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 21,
						type = "Choice"
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, SUCCESS, {})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then
								print(" SDL re-sends interactionChoiceSetID parameters to HMI in VR.DeleteCommand request")
								return false
						else
							return true
						end
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = SUCCESS })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck.2.2
		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: Check processing request with invalid JSON syntax

			--Requirement id in JAMA:
					--SDLAQ-CRS-472

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
			function Test:DeleteInteractionChoiceSet_IncorrectJSON()

				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg =
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 11,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"interactionChoiceSetID" 22}'
				}
				self.mobileSession:Send(msg)
				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA:
					--SDLAQ-CRS-472

			--Verification criteria:
					--Send request with all parameters are missing

			function Test:DeleteInteractionChoiceSet_MissingAllParams()
				--mobile side: DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",{})

			    --mobile side: DeleteInteractionChoiceSet response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: different conditions of correlationID parameter (invalid, several the same etc.)
--TODO: update req ID and verification:

			--Requirement id in JAMA:
			--Verification criteria: correlationID: duplicate value

--[[TODO: update according to  APPLINK-13892
				function Test:DeleteInteractionChoiceSet_CorrelationIDDuplicateValue()
					--mobile side: sending DeleteInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 23
					})

					--request from mobile side
					local msg =
					{
					  serviceType      = 7,
					  frameInfo        = 0,
					  rpcType          = 0,
					  rpcFunctionId    = 11,
					  rpcCorrelationId = cid,
					  payload          = '{"interactionChoiceSetID": 24}'
					}
					self.mobileSession:Send(msg)

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{ cmdID = 23, type = "Choice"},
					{ cmdID = 24, type = "Choice"})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(2)

					--response on mobile side
					EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})
					:Times(2)

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(2)
				end
		--End Test case CommonRequestCheck.5
]]
	--Begin Test suit PositiveRequestCheck


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
						-- SDLAQ-CRS-45

				--Verification criteria:
						-- DeleteInteractionChoiceSet request removes the command with corresponding interactionChoiceSetID from the application and SDL.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: interactionChoiceSetID lower bound
					function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDLowerBound()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 0
						})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 0
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: interactionChoiceSetID upper bound
					function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDUpperBound()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 2000000000
						})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 65535
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case PositiveRequestCheck.1.2

			--End Test case PositiveRequestCheck.1.2
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
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: Check of each request parameter value outbound conditions

			--Begin Test case NegativeRequestCheck.1
			--Description: Mandatory missing - interactionChoiceSetID

				--Requirement id in JAMA:
					-- SDLAQ-CRS-45,
					-- SDLAQ-CRS-472

				--Verification criteria:
					--The request without "interactionChoiceSetID" value is sent, the response with INVALID_DATA result code is returned.
				function Test:DeleteInteractionChoiceSet_MandatoryMissing()
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",{})

					--mobile side: expect DeleteInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: interactionChoiceSetID with wrong type

				--Requirement id in JAMA:
					-- SDLAQ-CRS-45,
					-- SDLAQ-CRS-472
				--Verification criteria:
					--The request with string data in "interactionChoiceSetID" value is sent, the response with INVALID_DATA result code is returned.
				function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDWrongType()
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = "44"
					})

					--mobile side: expect response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Checking interactionChoiceSetID value outbound

				--Requirement id in JAMA:
					-- SDLAQ-CRS-45,
					-- SDLAQ-CRS-472
				--Verification criteria:
					--The request with "interactionChoiceSetID" value out of bounds is sent, the response with INVALID_DATA result code is returned.

				--Begin Test case NegativeRequestCheck.3.1
				--Description: interactionChoiceSetID out lower bound
					function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDOutLowerBound()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = -1
						})

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: interactionChoiceSetID out upper bound
					function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDOutUpperBound()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 2000000001
						})

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.3.2
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Provided interactionChoiceSetID  is not valid(does not  exist)

				--Requirement id in JAMA:
					-- SDLAQ-CRS-45,
					-- SDLAQ-CRS-472
				--Verification criteria:
					--The request with empty "interactionChoiceSetID" value is sent, the response with INVALID_DATA result code is returned.
				function Test:DeleteInteractionChoiceSet_IncorrectJSON()

					self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					local msg =
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 11,
						rpcCorrelationId = self.mobileSession.correlationId,
						payload          = '{"interactionChoiceSetID"=}'
					}
					self.mobileSession:Send(msg)
					self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Provided interactionChoiceSetID is not valid(does not  exist)

				--Requirement id in JAMA:
					-- SDLAQ-CRS-45,
					-- SDLAQ-CRS-475
				--Verification criteria:
					--The request is sent with "interactionChoiceSetID" value that does not exist in SDL for the current application, the response comes with INVALID_ID result code.

				--Begin Test case NegativeRequestCheck.5.1
				--Description: interactionChoiceSetID not existed
					function Test:DeleteInteractionChoiceSet_interactionChoiceSetIDNotExist()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 9999
						})

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.2
				--Description: interactionChoiceSetID already deleted
					function Test:DeleteInteractionChoiceSet_ChoiceID28()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																{
																	interactionChoiceSetID = 28
																})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
									{cmdID = 28, type = "Choice"})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end

					function Test:DeleteInteractionChoiceSet_DeleteAlreadyDeleted()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 28
						})

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeRequestCheck.5.2
			--End Test case NegativeRequestCheck.5
		--End Test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
--[[TODO: update according to APPLINK-14765
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
					-- SDLAQ-CRS-46

				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with nonexistent resultCode
					function Test: DeleteInteractionChoiceSet_ResultCodeNotExist()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 25
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 25
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test: DeleteInteractionChoiceSet_MethodOutLowerBound()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 25
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 25
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with info values out of bound
					function Test: DeleteInteractionChoiceSet_InfoOutUpperBound()
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																{
																	interactionChoiceSetID = 25
																})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 25
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMessage.."a"})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMessage.."a"})

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test case NegativeResponseCheck.1.3
			--End Test case NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-46
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters
					function Test: DeleteInteractionChoiceSet_ResponseMissingAllPArameters()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:Send('{}')
						end)

						--mobile side: expect AddCommand response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter
					function Test: DeleteInteractionChoiceSet_MethodMissing()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter
					function Test: DeleteInteractionChoiceSet_ResultCodeMissing()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.DeleteCommand"}}')
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.4
				--Description: Check processing response without mandatory parameter
					function Test: DeleteInteractionChoiceSet_MandatoryParametersMissing()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 31
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.4
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing response with parameters with wrong data type

				--Requirement id in JAMA:
					--SDLAQ-CRS-46

				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check processing response with wrong type of method
					function Test:DeleteInteractionChoiceSet_MethodWrongtype()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", { })
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check processing response with wrong type of resultCode
					function Test:DeleteInteractionChoiceSet_ResultCodeWrongtype()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 26
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.DeleteCommand", "code":true}}')
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check processing response with wrong type of info
				function Test: DeleteInteractionChoiceSet_InfoWrongType()
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 26
															})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 26
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 102 })
					end)

					--mobile side: expect DeleteInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf(function(_,data)
						if data.payload.info then
							return false
						else
							return true
						end
					end)

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				--End Test case NegativeResponseCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check processing response with empty of info
				function Test: DeleteInteractionChoiceSet_InfoWrongType()
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 29
															})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 26
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "" })
					end)

					--mobile side: expect DeleteInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf(function(_,data)
						if data.payload.info then
							return false
						else
							return true
						end
					end)

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				--End Test case NegativeResponseCheck.3.4
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-46

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.


				function Test: DeleteInteractionChoiceSet_ResponseInvalidJson()
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
															{
																interactionChoiceSetID = 27
															})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 27
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0 "method":"VR.DeleteCommand"}}')
					end)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(12000)
				end
			--End Test case NegativeResponseCheck.4
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
				--SDLAQ-CRS-477
				--SDLAQ-CRS-478

			--Verification criteria:
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- GENERIC_ERROR comes as a result code on response when all other codes aren't applicable or the unknown issue occured.
				-- When DeleteInteractionChoiceSet for a ChoiceSet, that is currently open on the screen, request is sent, IN_USE code is returned as a resultCode for a request.
--[[TODO: update according to APPLINK-13849
			local resultCodes = {{code = "GENERIC_ERROR", name = "GenericError"}, { code = "REJECTED", name  = "Rejected"}, { code = "IN_USE", name = "InUse"}}
			for i=1,#resultCodes do
				Test["DeleteInteractionChoiceSet_" .. tostring(resultCodes[i].name) .. tostring("SuccessFalse")] = function(self)
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 30+i
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 30+i
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendError(data.id, data.method, resultCodes[i].code, "Error message")
					end)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = resultCodes[i].code})

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			end
		--End Test case ResultCodeCheck.1
]]
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-467

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

			--Description: Creat new session
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			--Description: Send DeleteInteractionChoiceSet when application not registered yet.
			function Test:DeleteInteractionChoiceSet_AppNotRegistered()
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession1:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 36
				})

				--mobile side: expect DeleteInteractionChoiceSet response
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				:Timeout(2000)

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(2000)
			end
		--End Test case ResultCodeCheck.2

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
	-- wrong response with correct HMI id

	--Begin Test suit HMINegativeCheck
	--Description:

		--Begin Test case HMINegativeCheck.1
		--Description:
			-- Provided data is valid but something went wrong in the lower layers.
			-- Unknown issue (other result codes can't be applied )
			-- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			--Requirement id in JAMA:
				--SDLAQ-CRS-479
				--APPLINK-8585
--[[TODO: update according to APPLINK-13849
			--Verification criteria:
				-- no UI response during SDL`s watchdog.
				function Test:DeleteInteractionChoiceSet_NoResponseFromHMI()
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 40
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 40
					})

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(12000)
				end

		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description:
			-- Invalid structure of response

			--Requirement id in JAMA:
				--SDLAQ-CRS-46

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
			function Test: DeleteInteractionChoiceSet_ResponseInvalidStructure()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 41
				})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{
					cmdID = 41
				})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					--<<!-- missing ':'
					self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0 "method":"VR.DeleteCommand"}}')
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.2
]]
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description:
			-- Send responses from HMI with fake parameter

			--Requirement id in JAMA:
				--APPLINK-14765

			--Verification criteria:
				-- In case HMI sends request (response, notification) with fake parameters that SDL should use internally -> SDL must cut off fake parameters

			--Begin Test case HMINegativeCheck.3.1
			--Description: Parameter out of protocol
			function Test:DeleteInteractionChoiceSet_ResponseWithFakeParamater()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 42
				})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{
					cmdID = 42
				})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
				:ValidIf (function(_,data)
			    		if data.payload.fakeParam then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
				end)

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
			--End Test case HMINegativeCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: Parameter from another API
			function Test:DeleteInteractionChoiceSet_ParamsFromOtherAPIInResponse()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 43
				})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{
					cmdID = 43
				})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse( data.id, data.method, "SUCCESS", {sliderPosition = 5})
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
				:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else
			    			return true
			    		end
				end)

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
			--End Test case HMINegativeCheck.3.2
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description:
			-- Several response to one request

			--Requirement id in JAMA:
				--SSDLAQ-CRS-479

			--Verification criteria:
				--Send several response to one request

			function Test:DeleteInteractionChoiceSet_SeveralResponseToOneRequest()
				--mobile side: sending request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 44
				})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
				{
					cmdID = 44
				})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "SUCCESS", {})
					self.hmiConnection:SendResponse( data.id , "VR.DeleteCommand" , "INVALID_DATA", {})
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

		--End Test case HMINegativeCheck.4
--[[TODO: update according to APPLINK-13849
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description:
			-- HMI correlation id check

			--Requirement id in JAMA:
				--SDLAQ-CRS-46

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

			--Begin Test case HMINegativeCheck.5.1
			--Description: Send response to nonexistent HMI correlation id
				function Test:DeleteInteractionChoiceSet_ResponseToWrongCorrelation()
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 47
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 47
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse( 5555, data.method, "SUCCESS", {})
					end)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.5.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.2
			--Description: Response to another method
				function Test:DeleteInteractionChoiceSet_WrongResponse()
					--mobile side: sending request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 49
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 49
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse( data.id , "UI.DeleteCommand" , "SUCCESS", {})
					end)

					--mobile side: expect response
					EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(12000)
				end
			--End Test case HMINegativeCheck.5.2
		--End Test case HMINegativeCheck.5
	--End Test suit HMINegativeCheck
]]
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
				--SDLAQ-CRS-769

			--Verification criteria:
				--SDL rejects DeleteInteractionChoiceSet request with REJECTED resultCode when current HMI level is NONE.
				--SDL doesn't reject DeleteInteractionChoiceSet request when current HMI is FULL.
				--SDL doesn't reject DeleteInteractionChoiceSet request when current HMI is LIMITED.
				--SDL doesn't reject DeleteInteractionChoiceSet request when current HMI is BACKGROUND.

			--Begin DifferentHMIlevel.1.1
			--Description: SDL reject DeleteInteractionChoiceSet request when current HMI is NONE.
				function Test:Precondition_DeactivateToNone()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end

				function Test:DeleteInteractionChoiceSet_HMILevelNone()
					--mobile side: sending DeleteInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 50
					})

					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End DifferentHMIlevel.1.1

			-----------------------------------------------------------------------------------------
		if Test.isMediaApplication == true or
			appHMITypes["NAVIGATION"] == true then
			--Begin DifferentHMIlevel.1.2
			--Description: SDL doesn't reject DeleteInteractionChoiceSet request when current HMI is LIMITED.
				function Test:Precondition_ActivateFirstApp()
					--hmi side: sending SDL.ActivateApp request
					local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application"]})
					EXPECT_HMIRESPONSE(rid)

					--mobile side: expect notification from 2 app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end

				function Test:Precondition_DeactivateToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
				end

				function Test:DeleteInteractionChoiceSet_HMILevelLimited()
					--mobile side: sending DeleteInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
					{
						interactionChoiceSetID = 50
					})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand",
					{
						cmdID = 50
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect DeleteInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End DifferentHMIlevel.1.2

			-----------------------------------------------------------------------------------------

			--Begin DifferentHMIlevel.1.3
			--Description: SDL doesn't reject DeleteInteractionChoiceSet request when current HMI is BACKGROUND.

				--Description:Start third session
					function Test:Precondition_StartThirdSession()
					--mobile side: start new session
					  self.mobileSession2 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end

				--Description "Register third app"
					function Test:Precondition_RegisterThirdApp()
						--mobile side: start new
						self.mobileSession2:StartService(7)
						:Do(function()
								local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
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

								--hmi side: expect BasicCommunication.OnAppRegistered request
								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
								{
								  application =
								  {
									appName = "Test Application3"
								  }
								})
								:Do(function(_,data)
								  self.applications["Test Application3"] = data.params.application.appID
								end)

								--mobile side: expect response
								self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

							end)
						end

				--Description: Activate third app
					function Test:Precondition_ActivateThirdApp()
						--hmi side: sending SDL.ActivateApp request
						local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = self.applications["Test Application3"]})
						EXPECT_HMIRESPONSE(rid)

						--mobile side: expect notification from 2 app
						self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
					end
		elseif
				Test.isMediaApplication == false then
				--Precondition for non-media app type

				function Test:ChangeHMIToBackground()
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
		end
				--Description: DeleteInteractionChoiceSet when HMI level BACKGROUND
					function Test:DeleteInteractionChoiceSet_HMILevelBackground()
						--mobile side: sending DeleteInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 51
						})

						--hmi side: expect VR.DeleteCommand request
						EXPECT_HMICALL("VR.DeleteCommand",
						{
							cmdID = 51
						})
						:Do(function(_,data)
							--hmi side: sending VR.DeleteCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect DeleteInteractionChoiceSet response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
			--End Test case DifferentHMIlevel.1.3
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
