
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local json  = require('json4lua/json/json')

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
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "ScrollableMessage" -- set request name
APIId = 25
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name

local storagePath = config.pathToSDL .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"

--[[

--Debug = {"softButtons", 1, "isHighlighted"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.


--Process different audio states for media and non-media application
local audibleState

if commonFunctions:isMediaApp() then
	audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end
 --]]


--Delayed expectation
function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(Request)
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------

--Create default request parameters
function Test:createRequest()

	return 	{
				scrollableMessageBody = "a",
				timeout = 10000
			}


end
---------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)

	local UIParams = {}
	if Request["scrollableMessageBody"] ~= nil then
		UIParams["messageText"] = {
			fieldName = "scrollableMessageBody",
			fieldText = Request["scrollableMessageBody"]
		}
	end

	if Request["timeout"] ~= nil then
		UIParams["timeout"] = Request["timeout"]
	else
		UIParams["timeout"] = 30000
	end

	--UIParams["softButtons"] = Request["softButtons"]

	--softButtons
	if Request["softButtons"]  ~= nil and #Request["softButtons"] >=1 then
		UIParams["softButtons"] =  Request["softButtons"]

		for i = 1, #UIParams["softButtons"] do

			--if type = TEXT, image = nil, else type = IMAGE, text = nil
			if UIParams["softButtons"][i].type == "TEXT" then
				UIParams["softButtons"][i].image =  nil
			elseif UIParams["softButtons"][i].type == "IMAGE" then
				UIParams["softButtons"][i].text =  nil
			end



			--if image.imageType ~=STATIC, add app folder to image value
			if UIParams["softButtons"][i].image ~= nil and
				UIParams["softButtons"][i].image.imageType ~= "STATIC" then
					UIParams["softButtons"][i].image.value = storagePath ..UIParams["softButtons"][i].image.value
			end


			--defvalue=DEFAULT_ACTION
			if UIParams["softButtons"][i].systemAction == nil then
					UIParams["softButtons"][i].systemAction =  "DEFAULT_ACTION"
			end
		end
	end

	return UIParams

end

---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request, HmiLevel)

	local cid = commonFunctions:sendRequest(self, Request, APIName, APIId)

	--TODO: update after resolving APPLINK-16052
	if Request.softButtons then
		for i=1,#Request.softButtons do
			if Request.softButtons[i].image then
				Request.softButtons[i].image = nil
			end
		end
	end

	local UIParams = self:createUIParameters(Request)

	--hmi side: expect UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
		scrollableMessageId = data.id

		local function scrollableMessageResponse()

			--hmi sends response
			self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)

	end)


	--mobile side: expect OnHMIStatus notification
	if HmiLevel == nil then
		HmiLevel = "FULL"
	end
	if
		HmiLevel == "BACKGROUND" or
		HmiLevel == "LIMITED" then
		EXPECT_NOTIFICATION("OnHMIStatus",{})
		:Times(0)
	else

		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
		)
		:Times(2)
	end

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

end

---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for WARNINGS resultCode cases.
function Test:verify_WARNINGS_Case(Request, HmiLevel)

  local cid = commonFunctions:sendRequest(self, Request, APIName, APIId)

  --TODO: update after resolving APPLINK-16052
  if Request.softButtons then
    for i=1,#Request.softButtons do
      if Request.softButtons[i].image then
        Request.softButtons[i].image = nil
      end
    end
  end

  local UIParams = self:createUIParameters(Request)

  --hmi side: expect UI.ScrollableMessage request
  EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
  :Do(function(_,data)

    --HMI sends UI.OnSystemContext
    self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
    scrollableMessageId = data.id

    local function scrollableMessageResponse()

      --hmi sends response
      self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "WARNINGS", {info = "Requested image(s) not found."})

      --HMI sends UI.OnSystemContext
      self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
    end
    RUN_AFTER(scrollableMessageResponse, 1000)

  end)


  --mobile side: expect OnHMIStatus notification
  if HmiLevel == nil then
    HmiLevel = "FULL"
  end
  if
    HmiLevel == "BACKGROUND" or
    HmiLevel == "LIMITED" then
    EXPECT_NOTIFICATION("OnHMIStatus",{})
    :Times(0)
  else

    EXPECT_NOTIFICATION("OnHMIStatus",
        {systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
        {systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
    )
    :Times(2)
  end

  --mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })

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

	--3. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------


--Requirement id in JAMA:
	--SDLAQ-CRS-109 (ScrollableMessage_Request_v2_0)
	--SDLAQ-CRS-110 (ScrollableMessage_Response_v2_0)
	--SDLAQ-CRS-642 (INVALID_DATA)
	--SDLAQ-CRS-641 (SUCCESS)

--Verification criteria: Creates a full screen overlay containing a large block of formatted text that can be scrolled with up to 8 SoftButtons defined

--List of parameters:
--1. scrollableMessageBody: type=String, minlength="1", maxlength="500", mandatory=true
--2. timeout: type=Integer, minvalue="1000", maxvalue="65535", defvalue="30000", mandatory=false
--3. softButtons: type=SoftButton, minsize="0", maxsize="8", mandatory=false, array=true

	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For Normal cases of Mobile request")

-----------------------------------------------------------------------------------------------

--Common Test cases check all parameters with lower bound and upper bound
--1. Positive request
--2. All parameters are lower bound
--3. All parameters are upper bound
--4. Positive request with invalid image

function Test:ScrollableMessage_PositiveRequest()
	local Request =
	{
		scrollableMessageBody = "abc",
		softButtons =
		{
			{
				softButtonID = 1,
				text = "Button1",
				type = "IMAGE",
				image =
				{
					value = "action.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			},
			{
				softButtonID = 2,
				text = "Button2",
				type = "IMAGE",
				image =
				{
					value = "action.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			}
		},
		timeout = 5000
	}

	self:verify_SUCCESS_Case(Request)
end

function Test:ScrollableMessage_PositiveRequest_WithInvalidImage()
  local Request =
  {
    scrollableMessageBody = "abc",
    softButtons =
    {
      {
        softButtonID = 1,
        text = "Button1",
        type = "IMAGE",
        image =
        {
          value = "notavailable.png",
          imageType = "DYNAMIC"
        },
        isHighlighted = false,
        systemAction = "DEFAULT_ACTION"
      },
      {
        softButtonID = 2,
        text = "Button2",
        type = "IMAGE",
        image =
        {
          value = "action.png",
          imageType = "DYNAMIC"
        },
        isHighlighted = false,
        systemAction = "DEFAULT_ACTION"
      }
    },
    timeout = 5000
  }

  self:verify_WARNINGS_Case(Request)
end

function Test:ScrollableMessage_AllParametersLowerBound()
	local Request =
	{
		scrollableMessageBody = "a",
		softButtons =
		{
			{
				softButtonID = 1,
				text = "a",
				type = "IMAGE",
				image =
				{
					value = "a",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			}
		},
		timeout = 1000
	}

	self:verify_SUCCESS_Case(Request)
end

function Test:ScrollableMessage_AllParametersUpperBound()
	local Request =
	{
		scrollableMessageBody = commonFunctions:createString(500),
		softButtons =
		{
			{
				softButtonID = 1,
				text = commonFunctions:createString(500),
				type = "TEXT",
				image =
				{
					value = commonFunctions:createString(500),
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			}
		},
		timeout = 65535
	}

	self:verify_SUCCESS_Case(Request)
end



-----------------------------------------------------------------------------------------------
--Parameter 1: scrollableMessageBody: type=String, minlength="1", maxlength="500", mandatory=true
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. LowerBound
	--3. UpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
	--7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------

	local Request = Test:createRequest()
	stringParameter:verify_String_Parameter_AcceptSpecialCharacters(Request, {"scrollableMessageBody"}, {1, 500}, true)


-----------------------------------------------------------------------------------------------
--Parameter 2: timeout: type=Integer, minvalue="1000", maxvalue="65535", defvalue="30000", mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for timeout type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
-----------------------------------------------------------------------------------------------

local Request = Test:createRequest()
--defvalue = 30000 is set in createUIParameters function
integerParameter:verify_Integer_Parameter(Request, {"timeout"}, {1000, 65535}, false)



-----------------------------------------------------------------------------------------------
--Parameter 3: softButtons: type=SoftButton, minsize="0", maxsize="8", mandatory=false, array=true
-----------------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound
	--8. Check parameters in side a button
		--"type" type="SoftButtonType">
		--"text" minlength="0" maxlength="500" type="String" mandatory="false"
		--"image" type="Image" mandatory="false"
		--"isHighlighted" type="Boolean" defvalue="false" mandatory="false"
		--"softButtonID" type="Integer" minvalue="0" maxvalue="65535"
		--"systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false"
-----------------------------------------------------------------------------------------------

	local Request = Test:createRequest()
	arraySoftButtonsParameter:verify_softButtons_Parameter(Request, {"softButtons"}, {0, 8}, {"a", strMaxLengthFileName255}, false)




----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Requirement id in JAMA:
	--SDLAQ-CRS-109 (ScrollableMessage_Request_v2_0)
	--SDLAQ-CRS-642 (INVALID_DATA)
	--SDLAQ-CRS-641 (SUCCESS)
	--SDLAQ-CRS-921 (SoftButtons)

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJSON
	--2. CorrelationIdIsDuplicated
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllParameters
-----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()

--Begin Test case NegativeRequestCheck
--Description: Check negative request


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite for special cases of Mobile request")

	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON

		--replace ":' by ";"
		local Payload = '"scrollableMessageBody";"abc"'

		commonTestCases:VerifyInvalidJsonRequest(25, Payload)

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: Check CorrelationId duplicate value

		function Test:ScrollableMessage_CorrelationId_IsDuplicated()

			--mobile side: send the request
			local Request =
			{
				scrollableMessageBody = "abc"
			}

			local CorIdScrollableMessage = self.mobileSession:SendRPC(APIName, Request)

			local msg =
			  {
				serviceType      = 7,
				frameInfo        = 0,
				rpcType          = 0,
				rpcFunctionId    = 25,
				rpcCorrelationId = CorIdScrollableMessage,
				payload          = '{"scrollableMessageBody":"def"}'
			  }


			--hmi side: expect the request
			EXPECT_HMICALL("UI.ScrollableMessage",
				{messageText = {fieldName = "scrollableMessageBody", fieldText = "abc"}},
				{messageText = {fieldName = "scrollableMessageBody", fieldText = "def"}}
			)
			:Do(function(exp,data)

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })

				end

				local function sendTheSecondRequest()
					--send the second request
					self.mobileSession:Send(msg)
				end



				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

				--HMI sends responses
				RUN_AFTER(scrollableMessageResponse, 1000)

				--Mobile: send the second request
				if exp.occurences == 1 then
					RUN_AFTER(sendTheSecondRequest, 3000)
				end

			end)
			:Times(2)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(4)

			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdScrollableMessage, { success = true, resultCode = "SUCCESS" })
			:Times(2)
		end


	--End Test case NegativeRequestCheck.2


	--Begin Test case NegativeRequestCheck.3
	--Description: Fake parameters check

		--Requirement id in JAMA: APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

		--Begin Test case NegativeRequestCheck.3.1
		--Description: Fake parameters is not from any API

		function Test:ScrollableMessage_WithFakeParams_IsNotFromAnyAPI()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "Replay",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION",
						fakeParam ="fakeParam"
					}
				},
				timeout = 30000,
				fakeParam ="fakeParam"
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			Request.fakeParam = nil
			Request.softButtons[1].fakeParam = nil

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)
			end)
			:ValidIf(function(_,data)
				if data.params.fakeParam or
					data.params.softButtons[1].fakeParam then
						commonFunctions:printError("SDL re-sends fake parameters to HMI")
						return false
				else
					return true
				end
			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		end


		--End Test case NegativeRequestCheck.3.1
		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3.2
		--Description: Fake parameters is from another API

		function Test:ScrollableMessage_WithFakeParameter_IsFromAnotherAPI()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "Replay",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION",
						ttsChunks =
						{
							{
								text = "TTSChunk",
								type = "TEXT"
							}
						}
					}
				},
				timeout = 30000,
				ttsChunks =
				{
					{
						text = "TTSChunk",
						type = "TEXT"
					}
				}
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			Request.ttsChunks = nil
			Request.softButtons[1].ttsChunks = nil

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)
			end)
			:ValidIf(function(_,data)
				if data.params.ttsChunks or
					data.params.softButtons[1].ttsChunks then
						commonFunctions:printError("SDL re-sends fake parameters to HMI")
						return false
				else
					return true
				end
			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


		end

		--End Test case NegativeRequestCheck.3.2
		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3.3
		--Description: Fake parameters and invalid request

		function Test:ScrollableMessage_WithFakeParamsAndInvalidRequest()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons =
				{
					{
						--softButtonID = 1, --missed softButtonID
						text = "Replay",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION",
						fakeParam ="fakeParam"
					}
				},
				timeout = 30000,
				fakeParam ="fakeParam"
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


		--End Test case NegativeRequestCheck.3.3
		-----------------------------------------------------------------------------------------
	--End Test case NegativeRequestCheck.3


	--Begin Test case NegativeRequestCheck.4
	--Description: All parameters missing

		commonTestCases:VerifyRequestIsMissedAllParameters()

	--End Test case NegativeRequestCheck.4

----------------------------------------------------------------------------------------------------

     --Start Test case NegativeRequestCheck.5

        -- SDLAQ-CRS-921->1
	--Begin Test case NegativeRequestCheck.5.1
	--Description: SoftButtonType is IMAGE and image paramer is wrong -> the request will be rejected as INVALID_DATA

		function Test:SM_SoftButtonTypeIMAGEAndParamIsWrong ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
						text = "Replay",
						type = "IMAGE",
                                                image =
                                                       {
                                                         value = 123,                   ---123 is wrong, "icon.png" is correct
                                                         imageType = "DYNAMIC"
                                         },
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	--End Test case NegativeRequestCheck.5.1

        --Begin Test case NegativeRequestCheck.5.2
	--Description: SoftButtonType is IMAGE and image paramer is not defined -> the request will be rejected as INVALID_DATA

		function Test:SM_SoftButtonTypeIMAGEAndParamNotDefined ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
						text = "Replay",
						type = "IMAGE",
                                                                              ---"image" param is not defined
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	--End Test case NegativeRequestCheck.5.2


        -- SDLAQ-CRS-921->2
	--Begin Test case NegativeRequestCheck.5.3
	--Description:  Mobile sends SoftButtons with Text=“” (empty string) and Type=TEXT, SDL rejects it as INVALID_DATA
		function Test:SM_SoftButtonTypeTEXTAndTextIsEmpty ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
						text = "",               --"text" is empty, RPC should be rejected
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	--End Test case NegativeRequestCheck.5.3

        -- SDLAQ-CRS-921->3
	--Begin Test case NegativeRequestCheck.5.4
	--Description:  Mobile sends SoftButtons with Type=TEXT that exclude 'Text' parameter, SDL rejects it as INVALID_DATA
		function Test:SM_SoftButtonTypeTEXTAndTextExcluded ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
						                    --"text" param excluded, RPC should be rejected
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	--End Test case NegativeRequestCheck.5.4


        -- SDLAQ-CRS-921->4
	--Description:  Mobile sends SoftButtons with Type=BOTH and with one of the parameters ('text' and 'image') wrong, SDL rejects it as INVALID_DATA

	--Begin Test case NegativeRequestCheck.5.5.1
	--Description:  Mobile sends SoftButtons with Type=BOTH and with wrong 'text', SDL rejects it as INVALID_DATA

		function Test:SM_SoftButtonTypeBOTHAndTextParamIsWrong ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = 12,                  --"text" param is wrong, RPC should be rejected
						image =
                                                       {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                        },
						type = "BOTH",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end

	--End Test case NegativeRequestCheck.5.5.1


        --Begin Test case NegativeRequestCheck.5.5.2
	--Description:  Mobile sends SoftButtons with Type=BOTH and with 'text' is not defined, SDL rejects it as INVALID_DATA

		function Test:SM_SoftButtonTypeBOTHAndTextParamIsNotDefined()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1, --"text" param is not defined, RPC should be rejected
                                                image =
                                                       {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                        },
						type = "BOTH",
                                                text,
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


	--End Test case NegativeRequestCheck.5.5.2


        --Begin Test case NegativeRequestCheck.5.6
	--Description:  Mobile sends SoftButtons with Type=BOTH and with wrong 'image', SDL rejects it as INVALID_DATA

		function Test:SM_SoftButtonTypeBOTHAndImageParamIsWrong()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = "Last",
                                                image =
                                                       {
                                                         value = "icon.png",
                                                         imageType = "SomeType" ---image type is wrong
                                                        },
						type = "BOTH",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


	--End Test case NegativeRequestCheck.5.6


        -- SDLAQ-CRS-921->8
	--Begin Test case NegativeRequestCheck.5.7
	--Description:  Mobile sends SoftButtons with Type=IMAGE and with invalid value of 'text' parameter, SDL rejects it as INVALID_DATA

		function Test:SM_SoftButtonTypeIMAGEAndInvalidTextParam ()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = 12,                  --"text" param is wrong, RPC should be rejected
						image =
                                                       {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                        },
						type = "IMAGE",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	 --End Test case NegativeRequestCheck.5.7

        -- SDLAQ-CRS-921->9
	--Begin Test case NegativeRequestCheck.5.8
	--Description:  Mobile sends SoftButtons with Type=TEXT and with invalid value of 'image', SDL rejects it as INVALID_DATA
		function Test:SM_SoftButtonTypeTEXTAndInvalidImageValue()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = "test5.8",
						image =
                                                       {
                                                         value = 15,            --"image" value is invalid, RPC should be rejected
                                                         imageType = "DYNAMIC"
                                                        },
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end
	 --End Test case NegativeRequestCheck.5.8


     --End Test case NegativeRequestCheck.5

------------------------------------------------------------------------------------------------

--End Test case NegativeRequestCheck

---------------------------------------

--Begin Test case PositiveRequestCheck
--Description: Check special positive request


     --Start Test case PositiveRequestCheck.1

          -- SDLAQ-CRS-921->5
	  --Begin Test case PositiveRequestCheck.1.1
	  --Description:  Mobile sends SoftButtons with Text=“” (empty string) and Type=BOTH, SDL must transfer to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:SM_SoftButtonTypeBOTHAndEmptyTextValue()

       		 --mobile side: sending ScrollableMessage request
			  local cid = self.mobileSession:SendRPC("ScrollableMessage",
                                {
                                   scrollableMessageBody = "atest",
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                text = "",
						image =
                                                       {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                        },
						type = "BOTH",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })


			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage",
                                {
                                   messageText = {
			                          fieldName = "scrollableMessageBody",
			                          fieldText = "atest"
	                                         },
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                text = "",
						image =
                                                      {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                      },
						type = "BOTH",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })
			:Do(function(_,data)

	    		--HMI sends UI.OnSystemContext
           		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })
            		  scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
                      		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			if HmiLevel == nil then
				HmiLevel = "FULL"
			end
			if
				HmiLevel == "BACKGROUND" or
				HmiLevel == "LIMITED" then
				EXPECT_NOTIFICATION("OnHMIStatus",{})
				:Times(0)
			else

				EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
				)
				:Times(2)
			end

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

 		 end

          --End Test case PositiveRequestCheck.1.1

          -- SDLAQ-CRS-921->6
	  --Begin Test case PositiveRequestCheck.1.2
	  --Description:  Mobile sends SoftButtons with Type=TEXT and omitted or not defined image, SDL must omit image in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:SM_SoftButtonTypeTEXTAndOmittedImageParam()

       		 --mobile side: sending ScrollableMessage request
			  local cid = self.mobileSession:SendRPC("ScrollableMessage",
                                {
                                   scrollableMessageBody = "atest",
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                text = "SBtext1",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })


			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage",
                                {
                                   messageText = {
			                          fieldName = "scrollableMessageBody",
			                          fieldText = "atest"
	                                         },
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                text = "SBtext1",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })
			:Do(function(_,data)

	    		--HMI sends UI.OnSystemContext
           		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })
            		  scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
                      		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			if HmiLevel == nil then
				HmiLevel = "FULL"
			end
			if
				HmiLevel == "BACKGROUND" or
				HmiLevel == "LIMITED" then
				EXPECT_NOTIFICATION("OnHMIStatus",{})
				:Times(0)
			else

				EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
				)
				:Times(2)
			end

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

 		 end

          --End Test case PositiveRequestCheck.1.2

          -- SDLAQ-CRS-921->7
	  --Begin Test case PositiveRequestCheck.1.3
	  --Description:  Mobile sends SoftButtons with Type=IMAGE and omitted text, SDL must omit text in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

         	function Test:SM_SoftButtonTypeIMAGEAndOmittedTexParam()

       		 --mobile side: sending ScrollableMessage request
			  local cid = self.mobileSession:SendRPC("ScrollableMessage",
                                {
                                   scrollableMessageBody = "atest",
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                image =
                                                      {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                      },
						type = "IMAGE",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })


			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage",
                                {
                                   messageText = {
			                          fieldName = "scrollableMessageBody",
			                          fieldText = "atest"
	                                         },
                                   softButtons = 				{
					{
						softButtonID = 1,
                                                image =
                                                      {
                                                         value = "icon.png",
                                                         imageType = "DYNAMIC"
                                                      },
						type = "IMAGE",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				   timeout = 10000
                                })
			:Do(function(_,data)

	    		--HMI sends UI.OnSystemContext
           		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })
            		  scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
                      		  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			if HmiLevel == nil then
				HmiLevel = "FULL"
			end
			if
				HmiLevel == "BACKGROUND" or
				HmiLevel == "LIMITED" then
				EXPECT_NOTIFICATION("OnHMIStatus",{})
				:Times(0)
			else

				EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
				)
				:Times(2)
			end

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

 		 end

          --End Test case PositiveRequestCheck.1.3

     --End Test case PositiveRequestCheck.1


--End Test case PositiveRequestCheck


end

SpecialRequestChecks()



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA:
	--SDLAQ-CRS-110 (ScrollableMessage_Response_v2_0)
	--SDLAQ-CRS-641 (SUCCESS)
	--SDLAQ-CRS-642 (INVALID_DATA)
	--SDLAQ-CRS-643 (OUT_OF_MEMORY)
	--SDLAQ-CRS-644 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-645 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-646 (REJECTED)
	--SDLAQ-CRS-647 (GENERIC_ERROR)
	--SDLAQ-CRS-648 (DISALLOWED)
	--SDLAQ-CRS-649 (ABORTED)
	--SDLAQ-CRS-650 (CHAR_LIMIT_EXCEEDED)
	--SDLAQ-CRS-1036 (UNSUPPORTED_RESOURCE)



--Verification Criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

--Common Test cases for response
--1. Check all mandatory parameters are missed
--2. Check all parameters are missed

--Print new line to separate new test cases group
commonFunctions:newTestCasesGroup("Test suite common test cases for response")

Test[APIName.."_Response_MissingMandatoryParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = Test:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	local UIParams = self:createUIParameters(Request)

	--hmi side: expect UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
		scrollableMessageId = data.id

		local function scrollableMessageResponse()

			--hmi sends response
			--self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
			self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)

	end)


	--mobile side: expect OnHMIStatus notification
	EXPECT_NOTIFICATION("OnHMIStatus",
			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	)
	:Times(2)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)

end
-----------------------------------------------------------------------------------------


Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)

	--mobile side: sending the request
	local Request = Test:createRequest()
	local cid = self.mobileSession:SendRPC(APIName, Request)

	local UIParams = self:createUIParameters(Request)

	--hmi side: expect UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
		scrollableMessageId = data.id

		local function scrollableMessageResponse()

			--hmi sends response
			--self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
			self.hmiConnection:Send('{}')

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)

	end)


	--mobile side: expect OnHMIStatus notification
	EXPECT_NOTIFICATION("OnHMIStatus",
			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	)
	:Times(2)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	:Timeout(13000)


end
-----------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsValidValues
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
-----------------------------------------------------------------------------------------------

local function verify_resultCode_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite resultCode parameter in response")
	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

		local UIParams = self:createUIParameters(Request)

		--hmi side: expect UI.ScrollableMessage request
		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi sends response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(scrollableMessageResponse, 1000)

		end)


		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)


		--mobile side: expect the response
		-- TODO update after resolving APPLINK-14765 EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info  = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_resultCode_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

		local UIParams = self:createUIParameters(Request)

		--hmi side: expect UI.ScrollableMessage request
		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi sends response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"message":"info","code":4}}') --REJECTED
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"message":"info"}}') --REJECTED

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(scrollableMessageResponse, 1000)

		end)


		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		-- TODO update after resolving APPLINK-14765 EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info  = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

	end
	-----------------------------------------------------------------------------------------

	--2. IsValidValue
	local resultCodes = {
		{resultCode = "SUCCESS", success =  true},
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "ABORTED", success =  false},
		{resultCode = "CHAR_LIMIT_EXCEEDED", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  true}
	}

	for i =1, #resultCodes do

		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})


		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------



	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	local testData = {
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"}}

	for i =1, #testData do

		Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			-- TODO update after resolving APPLINK-14765 EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info  = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("ScrollableMessage", Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendError(data.id, data.method, testData[i].value)

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			-- TODO update after resolving APPLINK-14765 EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info  = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})


		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------

end

verify_resultCode_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 2: method
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsValidValue
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------
--ToDo: Update according to answer on question APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_method_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite method parameter in response")
	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)

			local scrollableMessageId = data.id

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })


			local function scrollableMessageResponse()

				--hmi sends response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end

	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)

			local scrollableMessageId = data.id

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

			local function scrollableMessageResponse()

				--hmi sends response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')
			  self.hmiConnection:Send('{"id":'..tostring(scrollableMessageId)..',"jsonrpc":"2.0","error":{"data":{},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end
			RUN_AFTER(scrollableMessageResponse, 1000)

		end)


		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--2. IsValidValue: Covered by many test cases

	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
	local Methods = {
		{method = "ANY", name = "IsNotExist"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"}}

	for i =1, #Methods do

		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)

			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					  self.hmiConnection:SendResponse(scrollableMessageId, Methods[i].method, "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)

			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
				  self.hmiConnection:SendError(scrollableMessageId, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")

			end)

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)


		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------

end

verify_method_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 3: info
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA: APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
--List of test cases:
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. IsOutUpperBound
	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

local function verify_info_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForInfoParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_info_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				self.hmiConnection:SendResponse(scrollableMessageId, data.method, "SUCCESS", {})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			    		if data.payload.info then
			    			commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
			    			return false
			    		else
			    			return true
			    		end
			    	end)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_info_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				self.hmiConnection:SendError(scrollableMessageId, data.method, "GENERIC_ERROR", nil)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		-- TODO: Update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})

	end
	-----------------------------------------------------------------------------------------

	--2. IsLowerBound
	--3. IsUpperBound
	local testData = {
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}

	for i =1, #testData do

		Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)

			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					self.hmiConnection:SendResponse(scrollableMessageId, data.method, "SUCCESS", {info = testData[i].value})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)

			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					self.hmiConnection:SendError(scrollableMessageId, data.method, "GENERIC_ERROR", testData[i].value)

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect ScrollableMessage response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})

		end
		-----------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------

	-- TODO: update after resolving APPLINK-14551

	-- --4. IsOutUpperBound
	-- Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)

	-- 	local infoMaxLength = commonFunctions:createString(1000)

	-- 	--mobile side: sending the request
	-- 	local Request = Test:createRequest()
	-- 	local cid = self.mobileSession:SendRPC(APIName, Request)

	-- 	--hmi side: expect the request
	-- 	UIParams = self:createUIParameters(Request)

	-- 	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	-- 	:Do(function(_,data)
	-- 		--HMI sends UI.OnSystemContext
	-- 		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
	-- 		scrollableMessageId = data.id

	-- 		local function scrollableMessageResponse()

	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendResponse(scrollableMessageId, data.method, "SUCCESS", {info = infoMaxLength .. "1"})

	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 		end

	-- 		RUN_AFTER(scrollableMessageResponse, 1000)

	-- 	end)

	-- 	--mobile side: expect OnHMIStatus notification
	-- 	EXPECT_NOTIFICATION("OnHMIStatus",
	-- 			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	-- 			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	-- 	)
	-- 	:Times(2)

	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})

	-- end
	-- -----------------------------------------------------------------------------------------

	-- Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)

	-- 	local infoMaxLength = commonFunctions:createString(1000)

	-- 	--mobile side: sending the request
	-- 	local Request = Test:createRequest()
	-- 	local cid = self.mobileSession:SendRPC(APIName, Request)

	-- 	--hmi side: expect the request
	-- 	UIParams = self:createUIParameters(Request)

	-- 	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	-- 	:Do(function(_,data)

	-- 		--HMI sends UI.OnSystemContext
	-- 		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
	-- 		scrollableMessageId = data.id

	-- 		local function scrollableMessageResponse()

	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendError(scrollableMessageId, data.method, "GENERIC_ERROR", infoMaxLength .."1")

	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 		end

	-- 		RUN_AFTER(scrollableMessageResponse, 1000)

	-- 	end)

	-- 	--mobile side: expect OnHMIStatus notification
	-- 	EXPECT_NOTIFICATION("OnHMIStatus",
	-- 			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	-- 			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	-- 	)
	-- 	:Times(2)

	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})

	-- end
	-- -----------------------------------------------------------------------------------------


	-- --5. IsEmpty/IsOutLowerBound
	-- --6. IsWrongType
	-- --7. InvalidCharacter - \n, \t

	-- local testData = {
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"}}

	-- for i =1, #testData do

	-- 	Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local Request = Test:createRequest()
	-- 		local cid = self.mobileSession:SendRPC(APIName, Request)

	-- 		--hmi side: expect the request
	-- 		UIParams = self:createUIParameters(Request)

	-- 		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	-- 		:Do(function(_,data)
	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
	-- 			scrollableMessageId = data.id

	-- 			local function scrollableMessageResponse()

	-- 				--hmi side: sending the response
	-- 				self.hmiConnection:SendResponse(scrollableMessageId, data.method, "SUCCESS", {info = testData[i].value})

	-- 				--HMI sends UI.OnSystemContext
	-- 				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 			end

	-- 			RUN_AFTER(scrollableMessageResponse, 1000)

	-- 		end)

	-- 		--mobile side: expect OnHMIStatus notification
	-- 		EXPECT_NOTIFICATION("OnHMIStatus",
	-- 				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	-- 				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	-- 		)
	-- 		:Times(2)

	-- 		--mobile side: expect the response
	-- 		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	-- 		:ValidIf (function(_,data)
	-- 						if data.payload.info then
	-- 							commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
	-- 							return false
	-- 						else
	-- 							return true
	-- 						end
	-- 					end)

	-- 	end
	-- 	-----------------------------------------------------------------------------------------

	-- 	Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local Request = Test:createRequest()
	-- 		local cid = self.mobileSession:SendRPC(APIName, Request)

	-- 		--hmi side: expect the request
	-- 		UIParams = self:createUIParameters(Request)

	-- 		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	-- 		:Do(function(_,data)

	-- 			--HMI sends UI.OnSystemContext
	-- 			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
	-- 			scrollableMessageId = data.id

	-- 			local function scrollableMessageResponse()

	-- 				--hmi side: sending the response
	-- 				self.hmiConnection:SendError(scrollableMessageId, data.method, "GENERIC_ERROR", testData[i].value)

	-- 				--HMI sends UI.OnSystemContext
	-- 				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
	-- 			end

	-- 			RUN_AFTER(scrollableMessageResponse, 1000)

	-- 		end)

	-- 		--mobile side: expect OnHMIStatus notification
	-- 		EXPECT_NOTIFICATION("OnHMIStatus",
	-- 				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	-- 				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	-- 		)
	-- 		:Times(2)

	-- 		--mobile side: expect the response
	-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	-- 		:ValidIf (function(_,data)
	-- 						if data.payload.info then
	-- 							commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
	-- 							return false
	-- 						else
	-- 							return true
	-- 						end

	-- 					end)

	-- 	end
	-- 	-----------------------------------------------------------------------------------------

	-- end
	-----------------------------------------------------------------------------------------

end

verify_info_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsNonexistent
	--3. IsWrongType
	--4. IsNegative
-----------------------------------------------------------------------------------------------
--ToDo: Update according to answer on question APPLINK-16111: Clarify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)

			 --HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("UI.ScrollableMessage", Request)
		:Do(function(_,data)

			 --HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------


	--2. IsNonexistent
	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			 --HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)

		--mobile side: sending the request
		local Request = self:createRequest()
		local cid = self.mobileSession:SendRPC("Speak", Request)


		--hmi side: expect the request
		EXPECT_HMICALL("UI.ScrollableMessage", Request)
		:Do(function(_,data)
			 --HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------


	--3. IsWrongType
	Test[APIName.."_Response_CorrelationID_IsWrongType_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(tostring(scrollableMessageId), data.method, "SUCCESS", {info = "info message"})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)


		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()

				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(tostring(scrollableMessageId), data.method, "REJECTED", "error message")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--4. IsNegative
	Test[APIName.."_Response_CorrelationID_IsNegative_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
				  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {info = "info message"})

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	--5. IsNull
	Test[APIName.."_Response_CorrelationID_IsNull_SendResponse"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')
				  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')


				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		-- TODO: Update after APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_CorrelationID_IsNull_SendError"] = function(self)

		--mobile side: sending the request
		local Request = Test:createRequest()
		local cid = self.mobileSession:SendRPC(APIName, Request)


		--hmi side: expect the request
		UIParams = self:createUIParameters(Request)

		EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
		:Do(function(_,data)
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
			scrollableMessageId = data.id

			local function scrollableMessageResponse()
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')
				  self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
			end

			RUN_AFTER(scrollableMessageResponse, 1000)

		end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
		)
		:Times(2)

		--mobile side: expect the response
		-- TODO: Update after APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)

	end
	-----------------------------------------------------------------------------------------

end

verify_correlationID_parameter()




----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-110 (ScrollableMessage_Response_v2_0)
	--SDLAQ-CRS-641 (SUCCESS)
	--SDLAQ-CRS-642 (INVALID_DATA)
	--SDLAQ-CRS-647 (GENERIC_ERROR)


-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllPArameters
	--5. NoResponse
	--6. SeveralResponsesToOneRequest with the same and different resultCode
	--7.
-----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

--Begin Test case SpecialResponseChecks
--Description: Check all negative response cases


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite special cases of HMI response")

	--Begin Test case SpecialResponseChecks.1
	--Description: Invalid JSON

		--ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

		function Test:ScrollableMessage_InvalidJsonSyntaxResponse()

			--mobile side: sending the request
			local Request = self:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					--":" is changed by ";" after {"id"
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
					  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect the response
			-- TODO: Update after APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end

	--End Test case SpecialResponseChecks.1

	--Begin Test case SpecialResponseChecks.2
	--Description: Invalid structure of response

		--Requirement id in JAMA: SDLAQ-CRS-58
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode

		function Test:ScrollableMessage_InvalidStructureResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
					  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"UI.ScrollableMessage"}}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect response
			-- TODO: Update after APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
			:Timeout(13000)

		end

	--End Test case SpecialResponseChecks.2


	--Begin Test case SpecialResponseChecks.3
	--Description: Check processing response with fake parameters

		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter
		--[[ToDo: Update after implemented CRS APPLINK-14756: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

		--Begin Test case SpecialResponseChecks.3.1
		--Description: Parameter is not from API

		function Test:ScrollableMessage_Response_WithFakeParams()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case SpecialResponseChecks.3.1


		--Begin Test case SpecialResponseChecks.3.2
		--Description: Parameter is from another API

		function Test:ScrollableMessage_Response_WithParameterOfOtherResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case SpecialResponseChecks.3.2

		--Begin Test case SpecialResponseChecks.3.3
		--Description: Parameter is not from API

		function Test:ScrollableMessage_Response_WithFakeParamsAndInvalidResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(exp,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending the response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code1":0, "fake":"fake"}}')


					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			:Timeout(13000)
			:ValidIf (function(_,data)
				if data.payload.fake or
					data.payload.code1 then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end

		--End Test case SpecialResponseChecks.3.3
		]]
	--End Test case SpecialResponseChecks.3



	--Begin SpecialResponseChecks.4
	--Description: Check processing response without all parameters
	--[[ToDo: Uncomment when APPLINK-13418 (SDL ignores all responses from HMI after received response with invalid JSON syntax) is closed
		function Test:ScrollableMessage_Response_MissedAllPArameters()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)


			--hmi side: expect the request
			UIParams = self:createUIParameters(Request)

			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: sending UI.ScrollableMessage response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')
					self.hmiConnection:Send('{}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end

	--End SpecialResponseChecks.4


	--Begin Test case SpecialResponseChecks.5
	--Description: Request without responses from HMI

		--Requirement id in JAMA: SDLAQ-CRS-647
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.


		function Test:ScrollableMessage_NoResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC(APIName, Request)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(Request)
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)
				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				local function scrollableMessageResponse()

					--hmi side: does not send UI.ScrollableMessage response
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage", "code":0}}')

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 1000)

			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)

		end

	--End SpecialResponseChecks.5
	]]

	--Begin Test case SpecialResponseChecks.6
	--Description: Several response to one request

		--Begin Test case SpecialResponseChecks.6.1
		--Description: Several response to one request

			function Test:ScrollableMessage_SeveralResponsesToOneRequest()

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
				:Do(function(exp,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
					scrollableMessageId = data.id

					local function scrollableMessageResponse()

						--hmi side: sending the response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end

					RUN_AFTER(scrollableMessageResponse, 1000)

				end)

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
						{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
				)
				:Times(2)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})

			end

		--End Test case SpecialResponseChecks.6.1



		--Begin Test case SpecialResponseChecks.6.2
		--Description: One response with different resultCodes

			function Test:ScrollableMessage_Response_WithConstractionsOfResultCodes()

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC(APIName, Request)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(Request)
				EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
				:Do(function(exp,data)
					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
					scrollableMessageId = data.id

					local function scrollableMessageResponse()

						--hmi side: sending the response
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0}}')
						--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

						--response both SUCCESS and GENERIC_ERROR resultCodes
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ScrollableMessage","code":0},						"error":{"data":{"method":"UI.ScrollableMessage"},"code":22,"message":"The unknown issue occurred"}}')

						--HMI sends UI.OnSystemContext
						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
					end

					RUN_AFTER(scrollableMessageResponse, 1000)

				end)

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
						{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
				)
				:Times(2)

				-- TODO: Update after APPLINK-14765
				-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(13000)

			end

		--End Test case SpecialResponseChecks.6.2
		-----------------------------------------------------------------------------------------

	--End Test case SpecialResponseChecks.6

--End Test case SpecialResponseChecks

end

SpecialResponseChecks()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Requirement id in JAMA:
	--SDLAQ-CRS-642 (INVALID_DATA)
	--SDLAQ-CRS-643 (OUT_OF_MEMORY)
	--SDLAQ-CRS-644 (TOO_MANY_PENDING_REQUESTS)
	--SDLAQ-CRS-645 (APPLICATION_NOT_REGISTERED)
	--SDLAQ-CRS-646 (REJECTED)
	--SDLAQ-CRS-647 (GENERIC_ERROR)
	--SDLAQ-CRS-648 (DISALLOWED)
	--SDLAQ-CRS-649 (ABORTED)
	--SDLAQ-CRS-650 (CHAR_LIMIT_EXCEEDED)
	--SDLAQ-CRS-1036 (UNSUPPORTED_RESOURCE)


local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: resultCode checks")


	--Check resultCode SUCCESS. It is checked by other test cases.
	--Check resultCode INVALID_DATA. It is checked by other test cases.
	--Check resultCode REJECTED, UNSUPPORTED_RESOURCE, ABORTED, CHAR_LIMIT_EXCEEDED: Covered by test case resultCode_IsValidValues
	--Check resultCode GENERIC_ERROR. It is covered in Test:ScrollableMessage_NoResponse
	--Check resultCode OUT_OF_MEMORY. ToDo: Wait until requirement is clarified
	--Check resultCode TOO_MANY_PENDING_REQUESTS. It is moved to other script.
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: SDLAQ-CRS-645
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

	--End Test case ResultCodeChecks.1
	-----------------------------------------------------------------------------------------


	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED

		--Requirement id in JAMA: SDLAQ-CRS-648
		--Verification criteria:
			--1. SDL must return "DISALLOWED, success:false" for ScrollableMessage RPC to mobile app IN CASE ScrollableMessage RPC is not included to policies assigned to this mobile app.
			--2. SDL must return "DISALLOWED, success:false" for ScrollableMessage RPC to mobile app IN CASE ScrollableMessage RPC contains softButton with SystemAction disallowed by policies assigned to this mobile app.

		--[=[TODO debug after resolving APPLINK-13101

		--Begin Test case ResultCodeChecks.2.1
		--Description: Check resultCode DISALLOWED when request is not assigned to app

			policyTable:checkPolicyWhenAPIIsNotExist()

		--End Test case ResultCodeChecks.2.1

		--Begin Test case ResultCodeChecks.2.2
		--Description: Check resultCode DISALLOWED when request is assigned to app but user does not allow
			local keep_context = true
			local steal_focus = true
			policyTable:checkPolicyWhenUserDisallowed({"FULL"}, keep_context, steal_focus)
			--> postcondition of this script: user allows the function group

		--End Test case ResultCodeChecks.2.2

		--Begin Test case ResultCodeChecks.2.3
		--Description: Check resultCode DISALLOWED when request is assigned to app, user allows but "keep_context" : false, "steal_focus" : false

			--Postcondition: Update PT to allow ScrollableMessage request
			local keep_context = false
			local steal_focus = false
			policyTable:updatePolicyAndAllowFunctionGroup({"FULL"}, keep_context, steal_focus)

			function Test:ScrollableMessage_DisallowedKeepContext()

				--mobile side: sending ScrollableMessage request
				local cid = self.mobileSession:SendRPC("ScrollableMessage",
					{
						scrollableMessageBody = "abc",
						softButtons =
						{
							{
								softButtonID = 1,
								text = "Button1",
								type = "TEXT",
								isHighlighted = false,
								systemAction = "KEEP_CONTEXT"
							}
						},
						timeout = 30000
					}
				)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
			end

			function Test:ScrollableMessage_DisallowedStealFocus()

				--mobile side: sending ScrollableMessage request
				local cid = self.mobileSession:SendRPC("ScrollableMessage",
					{
						scrollableMessageBody = "abc",
						softButtons =
						{
							{
								softButtonID = 1,
								text = "Button1",
								type = "TEXT",
								isHighlighted = false,
								systemAction = "STEAL_FOCUS"
							}
						},
						timeout = 30000
					}
				)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
			end


			--Postcondition: Update PT to allow ScrollableMessage request
			local keep_context = true
			local steal_focus = true
			policyTable:updatePolicyAndAllowFunctionGroup({"FULL"}, keep_context, steal_focus)

		--End Test case ResultCodeChecks.2.4

	--End Test case ResultCodeChecks.2

	-----------------------------------------------------------------------------------------
]=]
end

ResultCodeChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions

--Requirement id in JAMA: Mentions in each test case

local function SequenceChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")

	--TC_ScrollableMessage_01, TC_ScrollableMessage_05, TC_ScrollableMessage_07: Covered by ABORTED resultCode in resultCode_IsValidValues test case
	--TC_ScrollableMessage_04: Covered when verify timeout parameter with minvalue
        --TC_SoftButtons_01: short and long click on TEXT soft button , reflecting on UI only if text is defined
        --TC_SoftButtons_02: short and long click on IMAGE soft button, reflecting on UI only if image is defined
        --TC_SoftButtons_03: short click on BOTH soft button, reflecting on UI
	--TC_SoftButtons_04: long click on BOTH soft button

	--Begin Test case SequenceCheck.1
	--Description: Check for test case TC_ScrollableMessage_02

		--Requirement id in JAMA: SDLAQ-TC-70

		--Verification criteria:
			--Call ScrollableMessage request from mobile app on HMI with one and maximum (8) SoftButtons
			--Check DEFAUL_ACTION and KEEP_CONTEXT SoftButton's actions as applied to ScrollableMessage pop-up

		function Test:ScrollableMessage_DEFAUL_ACTION_And_KEEP_CONTEXT()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "Close",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 2,
						text = "Break",
						type = "TEXT",
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 3,
						text = "Keep",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 4,
						text = "Stay",
						type = "TEXT",
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 5,
						type = "IMAGE",
						image =
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 6,
						type = "IMAGE",
						image =
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 7,
						type = "IMAGE",
						image =
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 8,
						type = "IMAGE",
						image =
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					}
				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Press button Keep (3)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 1000)

				--Press button Close (1)
				local function ButtonEventPress2()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress2, 3000)

				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
			:Times(4)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 3},
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
			:Times(2)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end
	--End Test case SequenceCheck.1
	-----------------------------------------------------------------------------------------


	--Begin Test case SequenceCheck.2
	--Description: Check for test case TC_ScrollableMessage_06

		--Requirement id in JAMA: SDLAQ-TC-249

		--Verification criteria: Checking that the scrolling message resets timeout. SDLAQ-CRS-109.
			--Scrolling down message body.
			--Checking renewing timeout.

		function Test:ScrollableMessage_OnResetTimeout()

			--mobile side: sending ScrollableMessage request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", {scrollableMessageBody = "abc"})



			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", {messageText={fieldName="scrollableMessageBody",fieldText="abc"}})
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id


				local function SendOnResetTimeout()
					self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "UI.ScrollableMessage"})
				end

				--send UI.OnResetTimeout notification after 2 seconds
				RUN_AFTER(SendOnResetTimeout, 2000)

				--send UI.OnResetTimeout notification after 10 seconds
				RUN_AFTER(SendOnResetTimeout, 10000)


				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end
				--RUN_AFTER(scrollableMessageResponse, 19000)
				RUN_AFTER(scrollableMessageResponse, 30000)


			end)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)
			:Timeout(21000)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(21000)

		end
	--End Test case SequenceCheck.2
	-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.3
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-869, SDLAQ-CRS-921->6

		--Verification criteria:
		-- Checking short click on TEXT soft button
		-- Mobile sends SoftButtons with Type=TEXT and valid image, SDL must omit image in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

           function Test:SM_TEXTSoftButtons_ShortClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "First",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 2,
						text = "Second",
						type = "TEXT",
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 3,
						text = "Third",
						type = "TEXT",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Press button "Second" (id=2)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 2})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.3
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.4
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on TEXT soft button

          function Test:SM_TEXTSoftButtons_LongClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "First",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 2,
						text = "Second",
						type = "TEXT",
						isHighlighted = true,
						systemAction = "STEAL_FOCUS"
					},
					{
						softButtonID = 3,
						text = "Third",
						type = "TEXT",
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Long press button "Third" (id=3)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 3})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.4
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.5
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

                function Test:SM_SoftButtonTypeTEXTAndTextWithWhitespace()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = " ",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


         --End Test case SequenceCheck.5
	-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.6
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
        --Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869, SDLAQ-CRS-921->7

		--Verification criteria:
		-- Checking short click on IMAGE soft button
		-- Mobile sends SoftButtons with Type=IMAGE and valid text, SDL must omit text in request to HMI, the resultCode returned to mobile app must depend on resultCode from HMI`s response.

           function Test:SM_IMAGESoftButtons_ShortClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{

					{
						softButtonID = 1,
						type = "IMAGE",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					},
                                        {
						softButtonID = 2,
                                                text = "Second",
						type = "IMAGE",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Press button "action.png" (id=2)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 2})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.6
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.7
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
 	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on IMAGE soft button

          function Test:SM_IMAGESoftButtons_LongClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						type = "IMAGE",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					},
                                        {
						softButtonID = 2,
						type = "IMAGE",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Long press button "action" (id=2)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 2, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 3})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.7

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.8
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined

                function Test:SM_SoftButtonTypeIMAGEAndImageNotExists()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{
					{
						softButtonID = 1,
                                                text = "First",
						type = "IMAGE",
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
                                        {
						softButtonID = 2,
						type = "IMAGE",
                                                image =
				                 {
							value = "aaa.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


         --End Test case SequenceCheck.8
       ----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.9
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on BOTH soft button

           function Test:SM_SoftButtonTypeBOTH_ShortClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						text = "First",
						type = "BOTH",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					},
					{
						softButtonID = 2,
						text = "Second",
						type = "BOTH",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					},
					{
						softButtonID = 3,
                                                text = "Third",
						type = "BOTH",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					}


				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Press button "Third" (id=3)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 3})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.9
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.10
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

		--Requirement id in JAMA: SDLAQ-CRS-200


		--Begin Test case SequenceCheck.10.1

                function Test:SM_SoftButtonTypeBOTHAndTextUndefined()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{

                                        {
						softButtonID = 1,
						type = "BOTH",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


            --End Test case SequenceCheck.10.1


	    --Begin Test case SequenceCheck.10.2

                function Test:SM_SoftButtonTypeBOTHAndImageUndefined()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{

                                        {
						softButtonID = 1,
						type = "BOTH",
                                                text = "Sometext",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end

	    --End Test case SequenceCheck.10.2

            --Begin Test case SequenceCheck.10.3

                function Test:SM_SoftButtonTypeBOTHImageAndTextUndefined()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{

                                        {
						softButtonID = 1,
						type = "BOTH",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end

	    --End Test case SequenceCheck.10.3


      --End Test case SequenceCheck.10

       ----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.11
	--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on BOTH soft button

          	function Test:SM_SoftButtonBOTHType_LongClick()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						type = "BOTH",
                                                text = "First text",
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Long press button "First text" (id=1)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)



			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
			:Times(2)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
			:Times(1)


			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus",
					{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
					{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
			)
			:Times(2)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end

         --End Test case SequenceCheck.11

	-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.12
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

                function Test:SM_SoftButtonBOTHAndImageParamIsNotDefined()

			--mobile side: sending the request
			local Request =
			{
				scrollableMessageBody = "abc",
				softButtons = 				{

                                        {
						softButtonID = 1,
						type = "BOTH",
                                                image,
                                                text = "First",                 --image is not defined
                                                isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				},
				timeout = 30000
			}

			local cid = self.mobileSession:SendRPC(APIName, Request)

			local UIParams = self:createUIParameters(Request)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		end


         --End Test case SequenceCheck.12


	end

  -------------------------------------------------------------------------

     	--Begin Test case SequenceCheck.13
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-2912

		--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed

     		 function Test:UnsubscribeButton_CUSTOM_BUTTON_SUCCESS()

		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = "CUSTOM_BUTTON"
			})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = false})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	                --:Timeout(13000)

	end

        	   function Test:SM_SoftButton_AfterUnsubscribe()
			RequestParams =
			{
				scrollableMessageBody = "a",
				softButtons =
				{
					{
						softButtonID = 1,
						type = "BOTH",
                                                text = "First",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
                                                systemAction = "DEFAULT_ACTION"
					}

				}
			}

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

			local UIParams = self:createUIParameters(RequestParams)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
			:Do(function(_,data)

				--HMI sends UI.OnSystemContext
				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
				scrollableMessageId = data.id

				--Long press button "First" (id=1)
				local function ButtonEventPress()
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
				end

				RUN_AFTER(ButtonEventPress, 3000)


				--Send ScrollableMessage response
				local function scrollableMessageResponse()

					--hmi sends response
					self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "ABORTED", {})

					--HMI sends UI.OnSystemContext
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
				end

				RUN_AFTER(scrollableMessageResponse, 5000)

			end)


			--mobile side: OnButtonEvent notifications
			EXPECT_NOTIFICATION("OnButtonEvent",
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
			{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
			:Times(0)

			--mobile side: OnButtonPress notifications
			EXPECT_NOTIFICATION("OnButtonPress",
			{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
			:Times(0)



			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED" })

		end


 --End Test case SequenceCheck.13

SequenceChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA:
	--SDLAQ-CRS-803: HMI Status Requirement for ScrollableMessage
	--Verification criteria: ScrollableMessage request is allowed in FULL, LIMITED, BACKGROUND HMI level

--Verify resultCode in NONE, LIMITED and BACKGROUND hmi levels
commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")


-- TODO: need to debug
--Begin Test case DifferentHMIlevel.1
--Description: Check ScrollableMessage in BACKGROUND with STEAL_FOCUS softButton

	--Requirement id in JAMA: SDLAQ-CRS-2259 STEAL_FOCUS

	--Verification criteria: For the app which is in HMI_BACKGROUND and policy rules allow to call ScrollableMessage from BACKGROUND, pressing a SoftButton with SystemAction STEAL_FOCUS for ScrollableMessage causes bringing an application to HMI_FULL mode and closing the ScrollableMessage dialog on HMI with resultCode SUCCESS. OnButtonPress/OnButtonEvent is sent to SDL from HMI and then transmitted to mobile app if the application is subscribed to CUSTOM_BUTTON.

	-- if commonFunctions:isMediaApp() == true then
	-- --[[TODO debug after resolving APPLINK-13101
	-- 	--Precondition 1: activate application 1 to update policy
	-- 	commonSteps:ActivationApp()

	-- 	--Precondition 2: Update PT to allow ScrollableMessage request in FULL and BACKGROUND
	-- 	local keep_context = true
	-- 	local steal_focus = true
	-- 	policyTable:updatePolicyAndAllowFunctionGroup({"FULL", "BACKGROUND"}, keep_context, steal_focus)


	-- 	--Precondition 3: Activate the second media application to change application 1 to BACKGDOUND
	-- 	commonSteps:ActivateTheSecondMediaApp()
	-- 	]]

	-- else
	-- 	--[[TODO debug after resolving APPLINK-13101
	-- 	--Precondition 4: Update PT to allow ScrollableMessage request in FULL and BACKGROUND
	-- 	local keep_context = true
	-- 	local steal_focus = true
	-- 	policyTable:updatePolicyAndAllowFunctionGroup({"FULL", "BACKGROUND"}, keep_context, steal_focus)
	-- 	]]
	-- 	--Precondition 5: Create new session
	-- 	commonSteps:precondition_AddNewSession()

	-- 	--Precondition 6: register new app
	-- 	commonSteps:RegisterTheSecondMediaApp()
	-- end

	-- function Test:ScrollableMessage_BACKGROUND_SUCCESS()
	-- 	RequestParams =
	-- 	{
	-- 		scrollableMessageBody = "a",
	-- 		softButtons =
	-- 		{
	-- 			{
	-- 				softButtonID = 1,
	-- 				text = "Close",
	-- 				type = "TEXT",
	-- 				isHighlighted = false,
	-- 				systemAction = "STEAL_FOCUS"
	-- 			}
	-- 		}
	-- 	}

	-- 	--mobile side: sending the request
	-- 	local cid = self.mobileSession:SendRPC("ScrollableMessage", RequestParams)

	-- 	local UIParams = self:createUIParameters(RequestParams)

	-- 	--hmi side: expect UI.ScrollableMessage request
	-- 	EXPECT_HMICALL("UI.ScrollableMessage", UIParams)
	-- 	:Do(function(_,data)

	-- 		--HMI sends UI.OnSystemContext for app2
	-- 		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appId2, systemContext = "HMI_OBSCURED" })


	-- 		--Press button 1
	-- 		local function ButtonEventPress()
	-- 			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
	-- 			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
	-- 			self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

	-- 			--Send ScrollableMessage response
	-- 			local function scrollableMessageResponse()

	-- 				--hmi sends response
	-- 				self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})

	-- 				--HMI sends UI.OnSystemContext for app2
	-- 				self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appId2, systemContext = "MAIN" })
	-- 			end


	-- 			RUN_AFTER(scrollableMessageResponse, 200)
	-- 		end

	-- 		RUN_AFTER(ButtonEventPress, 1000)

	-- 		local function deactivatedApp2()

	-- 			--hmi side: sending BasicCommunication.OnAppDeactivated notification for app2

	-- 			self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = appId2, reason = "GENERAL"})

	-- 		end

	-- 		RUN_AFTER(deactivatedApp2, 3000)


	-- 		local function activateApp1()

	-- 			--hmi side: sending SDL.ActivateApp request
	-- 			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
	-- 			EXPECT_HMIRESPONSE(RequestId)

	-- 		end

	-- 		RUN_AFTER(activateApp1, 3500)

	-- 	end)

	-- 	--mobile side: OnButtonEvent notifications
	-- 	EXPECT_NOTIFICATION("OnButtonEvent",
	-- 	{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
	-- 	{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
	-- 	:Times(2)

	-- 	--mobile side: OnButtonPress notifications
	-- 	EXPECT_NOTIFICATION("OnButtonPress",
	-- 	{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})


	-- 	--mobile side (On App1): expect OnHMIStatus notification
	-- 	EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState} )

	-- 	self.mobileSession2:ExpectNotification("OnHMIStatus",
	-- 			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
	-- 			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
	-- 			{systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"}
	-- 	)
	-- 	:Times(3)


	-- 	--mobile side: expect the response
	-- 	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	-- 	DelayedExp(5000)

	-- end


--End Test case DifferentHMIlevel.1


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test

