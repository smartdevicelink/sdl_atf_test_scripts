-- Note: List of existing problems:
---Known defects:
 	-- APPLINK-11135: SDL does not send notifications OnButtonEvent to mobile app for "OK" in FULL
 	-- APPLINK-14082: SDL doesn't resend OnButtonPress notification for "OK" in LIMITED.
 	-- APPLINK-14054: Redundant resumption procedure occurs right after manual activation. 


---------------------------------------------------------------------------------------------
--Test result: This test script has 8 failed test cases. It related to subscribe OK button (APPLINK-11135), CUSTOM_BUTTON and SEARCH buttons (UNSUPPORT_RESOURCE)
---------------------------------------------------------------------------------------------


--Test = require('user_modules/connecttestSubscribeSB')

--use protocol 2 to avoid disconnect.
config.defaultProtocolVersion = 2

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
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

APIName = "SubscribeButton" -- set request name

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local iTimeout = 5000
local buttonName = {"OK","PLAY_PAUSE","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local buttonNameNonMediaApp = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local UnsupportButtonName = {"PRESET_9", "SEARCH"}


local str1000Chars = 
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	

local info = {nil, "unused"}
local OutBound = {"a", "nonexistButton", str1000Chars}
local OutBoundName = {"OneCharacter", "nonexistButton", "String1000Characters"}

local resultCode = {"SUCCESS", "INVALID_DATA", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "APPLICATION_NOT_REGISTERED", "REJECTED", "IGNORED", "GENERIC_ERROR", "UNSUPPORTED_RESOURCE", "DISALLOWED"}

local success = {true, false, false, false, false, false, false, false, false, false}

local appID0, appId1, appId2

local application2_nonmedia =
{
  registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "Test Application_nonmadia",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0000005",
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

-- Common functions

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

local function SendOnSystemContextOnAppID(self, ctx, strAppID)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = strAppID, systemContext = ctx })
end

local function Precondition_TC_UnsubscribeButton(self, btnName)

	Test["Precondition_TC_UnsubscribeButton_" .. tostring(btnName)] = function(self)
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = btnName
			}
		)

		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {isSubscribed = false, name = btnName})
		:Times(AtMost(1))

		--mobile side: expect UnsubscribeButton response
		EXPECT_RESPONSE("UnsubscribeButton")
		:ValidIf(function(_,data)
			if data.payload.resultCode == "SUCCESS" then
				--mobile side: OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")

				return true
			elseif (data.payload.resultCode == "IGNORED") then
				print("\27[32m" .. btnName .. " button has not subscribed yet. resultCode = "..tostring(data.payload.resultCode) .. "\27[0m")
				return true
			else
				print(" \27[36m UnsubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode) .. "\27[0m")
				return false
			end
		end)

		DelayedExp(1000)
		
	end
	
end

local function Precondition_TC_SubscribeButton(self, btnName)

	Test["Precondition_TC_SubscribeButton_" .. tostring(btnName)] = function(self)
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
			{
				buttonName = btnName
			}
		)

		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = btnName})

		--mobile side: expect UnsubscribeButton response
		EXPECT_RESPONSE("SubscribeButton")
		:ValidIf(function(_,data)
			if (data.payload.resultCode == "SUCCESS") then
				EXPECT_NOTIFICATION("OnHashChange")
				return true
			elseif (data.payload.resultCode == "IGNORED") then
				print(btnName .. " button has already been subscribed. resultCode = "..tostring(data.payload.resultCode))
				return true
			else
				print("SubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode))
				return false
			end
		end)
	end
	
end

local function TC_OnButtonEvent_OnButtonPress_When_SubscribedButton(self, btnName, strMode, strTestCaseName)

	Test[strTestCaseName] = function(self)


		--hmi side: send request Buttons.OnButtonEvent
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
											{
												name = btnName, 
												mode = "BUTTONDOWN"
											})

		
		
		local function OnButtonEventBUTTONUP()
			--hmi side: send request Buttons.OnButtonEvent
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
												{
													name = btnName, 
													mode = "BUTTONUP"
												})
		end
		
		--hmi side: send request Buttons.OnButtonPress
		local function OnButtonPress()
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
												{
													name = btnName, 
													mode = strMode
												})
		end
		
		if strMode == "LONG" then	
			--hmi side: send request Buttons.OnButtonPress
			RUN_AFTER(OnButtonPress, 50)
												
			--hmi side: send request Buttons.OnButtonEvent
			RUN_AFTER(OnButtonEventBUTTONUP, 100)
											
		else
			--hmi side: send request Buttons.OnButtonEvent
			RUN_AFTER(OnButtonEventBUTTONUP, 50)
												
			--hmi side: send request Buttons.OnButtonPress
			RUN_AFTER(OnButtonPress, 100)								
		end
		
	    --Mobile expects OnButtonEvent
		EXPECT_NOTIFICATION("OnButtonEvent", 
			{buttonName = btnName, buttonEventMode = "BUTTONDOWN"},
			{buttonName = btnName, buttonEventMode = "BUTTONUP"}
		)
		:Times(2)
		
	    --Mobile expects OnButtonEvent
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = btnName, buttonPressMode = strMode})

		DelayedExp(2000)
		
	end
	
end

local function TC_OnButtonEvent_OnButtonPress_When_UnsubscribedButton(self, btnName, strMode, strTestCaseName)

	Test[strTestCaseName] = function(self)


		--hmi side: send request Buttons.OnButtonEvent
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
											{
												name = btnName, 
												mode = "BUTTONDOWN"
											})

		
		
		local function OnButtonEventBUTTONUP()
			--hmi side: send request Buttons.OnButtonEvent
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
												{
													name = btnName, 
													mode = "BUTTONUP"
												})
		end
		
		--hmi side: send request Buttons.OnButtonPress
		local function OnButtonPress()
			self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
												{
													name = btnName, 
													mode = strMode
												})
		end
		
		if strMode == "LONG" then	
			--hmi side: send request Buttons.OnButtonPress
			RUN_AFTER(OnButtonPress, 50)
												
			--hmi side: send request Buttons.OnButtonEvent
			RUN_AFTER(OnButtonEventBUTTONUP, 100)
											
		else
			--hmi side: send request Buttons.OnButtonEvent
			RUN_AFTER(OnButtonEventBUTTONUP, 50)
												
			--hmi side: send request Buttons.OnButtonPress
			RUN_AFTER(OnButtonPress, 100)								
		end
		
	    --Mobile expects OnButtonEvent
		EXPECT_NOTIFICATION("OnButtonEvent")
		:Times(0)
		
	    --Mobile expects OnButtonEvent
		EXPECT_NOTIFICATION("OnButtonPress")
		:Times(0)

		DelayedExp(2000)
	end
	
end

local function TC_SubscribeButtonSUCCESS(self, btnName, strTestCaseName)

	Test[strTestCaseName] = function(self)
	
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
			{
				buttonName = btnName
			}
		)

		--hmi side: receiving Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = btnName})
		
		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE(cid, {resultCode = "SUCCESS", success = true})
		
		EXPECT_NOTIFICATION("OnHashChange")
	end
end

function ActivateApplication(self, strAppName)
	--HMI send ActivateApp request

	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[strAppName]})
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		if data.result.isSDLAllowed ~= true then
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
	:Timeout(12000)

end
	
function RegisterAppInterface(self, appNumber)				
		--mobile side: sending request 
		local CorIdRegister, strAppName
		
		if appNumber ==1 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			strAppName = config.application1.registerAppInterfaceParams.appName
		elseif appNumber ==2 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", application2_nonmedia.registerAppInterfaceParams)
			strAppName = application2_nonmedia.registerAppInterfaceParams.appName
		end
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = strAppName
			}
		})
		:Do(function(_,data)
			local appId = data.params.application.appID
			self.appId = appId
			appId0 = appId
			self.appName = data.params.application.appName
			self.applications[strAppName] = appId
		end)
		
		--mobile side: expect response
		self.mobileSession:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = 
			{
				majorVersion = 3,
				minorVersion = 0
			}
		})
		:Timeout(12000)

		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		})
		:Timeout(12000)


		DelayedExp(1000)
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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"FULL", "LIMITED", "BACKGROUND"})

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin test suit CommonRequestCheck
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

		--Write TEST_BLOCK_I_Begin to ATF log
		function Test:TEST_BLOCK_I_Begin()
			print("********************************************************************")
		end					

				
	
		--Begin test case CommonRequestCheck.1
		--Description: This test is intended to check positive cases and when all parameters 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: Sets the initial media clock value and automatic update method for HMI media screen with all parameters

			for i=1,#buttonName do					
				Test["SubscribeButton_PositiveCase_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)

					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = buttonName[i]

					})

					--expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = btnName})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					
				end
			end						
			
		--End test case CommonRequestCheck.1
		-----------------------------------------------------------------------------------------		
			

		--Begin test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters  

			--It is covered by CommonRequestCheck.1				
			
		--End test case CommonRequestCheck.2
		-----------------------------------------------------------------------------------------	
	

		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)

		-----------------------------------------------------------------------------------------


		--Begin test case CommonRequestCheck.5
		--Description: This test is intended to check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-534

			--Verification criteria: SDL responses invalid data
	
			function Test:SubscribeButton_missing_mandatory_parameters_updateMode_INVALID_DATA()
					
				--mobile side: sending SubscribeButton request
				local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
				
				})

				--mobile side: expect SubscribeButton response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)			 
			end					

		--End test case CommonRequestCheck.5
		-----------------------------------------------------------------------------------------		


				
		--Begin test case CommonRequestCheck.6
		--Description: check request with all parameters are missing

			--It is covered by SubscribeButton_missing_mandatory_parameters_updateMode_INVALID_DATA

		--End test case CommonRequestCheck.6
		-----------------------------------------------------------------------------------------




		--Begin test case CommonRequestCheck.7
		--Description: Check request with fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL
				
			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters
				
				for i=1,#buttonName do
					--Precondition for this test case
					Precondition_TC_UnsubscribeButton(self, buttonName[i])
					
					Test["SubscribeButton_FakeParameters_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
						
						--mobile side: sending SubscribeButton request
						local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							fakeParameter = "fakeParameter",
							buttonName = buttonName[i]

						})

						--expect Buttons.OnButtonSubscription
						EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = buttonName[i]})

						--mobile side: expect SubscribeButton response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})						
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")

					end
				end	
			--End test case CommonRequestCheck.7.1
			
			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameter of other API
				for i=1,#buttonName do
					--Precondition for this test case
					Precondition_TC_UnsubscribeButton(self, buttonName[i])
					
					Test["SubscribeButton_ParametersOfOtherAPI_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
						
						--mobile side: sending SubscribeButton request
						local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							syncFileName = "icon.png", --SetAppIcon
							buttonName = buttonName[i]

						})

						EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = buttonName[i]})

						--mobile side: expect SubscribeButton response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")

					end
				end
			--End test case CommonRequestCheck.7.2

		--End test case CommonRequestCheck.7
		-----------------------------------------------------------------------------------------

		
		
		--Begin test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-534

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

			function Test:SubscribeButton_InvalidJSON_INVALID_DATA()
			
				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 18, --SubscribeButtonID
					rpcCorrelationId = self.mobileSession.correlationId,
					-- missing ':' after buttonName
					--payload          = '{"buttonName":"OK"}'
					  payload          = '{"buttonName" "OK"}'
				}
				self.mobileSession:Send(msg)
				
				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })		
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)				
			end

		--End test case CommonRequestCheck.8
		-----------------------------------------------------------------------------------------


		--Begin test case CommonRequestCheck.9
		--Description: check correlationID parameter is duplicated
			
			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: the response comes with SUCCESS result code.

			Precondition_TC_UnsubscribeButton(self, "PRESET_0")
			Precondition_TC_UnsubscribeButton(self, "PRESET_1")


			--ToDo: Need update according to APPLINK-19834
			-- function Test:SubscribeButton_DuplicatedCorrelationID_SUCCESS()
			
				-- --mobile side: sending SubscribeButton request
				-- local cid = self.mobileSession:SendRPC("SubscribeButton",
				-- {
					-- buttonName = "PRESET_0"

				-- })
			

				-- --The second message with the same correlationID
				-- local msg = 
			 	-- {
			 		-- serviceType      = 7,
			 		-- frameInfo        = 0,
			 		-- rpcType          = 0,
			 		-- rpcFunctionId    = 18, --SubscribeButtonID
			 		-- rpcCorrelationId = cid,
			 		-- payload          = '{"buttonName":"PRESET_1"}'
			 	-- }

			 	-- self.mobileSession:Send(msg)
				

				-- --mobile side: expect SubscribeButton response
				-- EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
				-- :Timeout(iTimeout)
				-- :Times(2)
				
				
				
				-- EXPECT_NOTIFICATION("OnHashChange")
				-- :Times(2)
								
			-- end

		--End test case CommonRequestCheck.9
		-----------------------------------------------------------------------------------------
				
		
		--Write TEST_BLOCK_I_End to ATF log
		function Test:TEST_BLOCK_I_End()
			print("********************************************************************")
		end					
		
	--End test suit CommonRequestCheck	
	

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

		--Write TEST_BLOCK_II_Begin to ATF log
		function Test:TEST_BLOCK_II_Begin()
			print("********************************************************************")
		end		
	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--


		--Begin test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions
		
			--It is covered by CommonRequestCheck.2 (checking request with mandatory parameter)

		--End test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		
		--Begin test suit PositiveResponseCheck
		--Description: Check positive responses 

			--It is covered by CommonRequestCheck.1							
				
		--End test suit PositiveResponseCheck

		--Write TEST_BLOCK_II_End to ATF log
		function Test:TEST_BLOCK_II_End()
			print("********************************************************************")
		end		

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

		--Write TEST_BLOCK_III_Begin to ATF log
		function Test:TEST_BLOCK_III_Begin()
			print("********************************************************************")
		end		
		
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
		--Description: check of each request parameter value in bound and boundary conditions of buttonName

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-69, SDLAQ-CRS-534

			--Verification criteria: SDL returns INVALID_DATA

			for i=1,#OutBound do
				Test["SubscribeButton_buttonName_OutBound_" .. tostring(OutBoundName[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = OutBound[i]
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
					
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)				 
				end
			end						


		--End test case NegativeRequestCheck.1
		-----------------------------------------------------------------------------------------


		--Begin test case NegativeRequestCheck.2
		--Description: invalid values(empty, missing, nonexistent, duplicate, invalid characters)

		
			--Begin test case NegativeRequestCheck.2.1
			--Description: Check properties parameter is -- invalid values(empty) - The request with empty "buttonName" is sent

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-69, SDLAQ-CRS-534

				--Verification criteria: SDL responses with INVALID_DATA result code. 

				function Test:SubscribeButton_buttonName_IsInvalidValue_Empty_INVALID_DATA()
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = ""
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)								
				end
			
			--End test case NegativeRequestCheck.2.1
			-----------------------------------------------------------------------------------------		
	

			--Begin test case NegativeRequestCheck.2.2
			--Description: invalid values(missing)

				--It is covered by CommonRequestCheck.6: missed parameter

			--End test case NegativeRequestCheck.2.2


			--Begin test case NegativeRequestCheck.2.3
			--Description: Check the request with nonexistent value is sent, the INVALID_DATA response code is returned.

				--It is covered by  SubscribeButton_buttonName_OutBound
			
			--End test case NegativeRequestCheck.2.3
			-----------------------------------------------------------------------------------------	


			--Begin test case NegativeRequestCheck.2.4
			--Description: invalid values(duplicate)	
				
				--This check is not applicable for SubscribeButton
				
			--End test case NegativeRequestCheck.2.4


			--Begin test case NegativeRequestCheck.2.5
			--Description: Check the request with invalid characters is sent, the INVALID_DATA response code is returned.

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-69, SDLAQ-CRS-534

				--Verification criteria: SDL responses with INVALID_DATA result code. 

				function Test:SubscribeButton_buttonName_IsInvalidValue_InvalidCharacters_NewLine_INVALID_DATA()
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = "a\nb"
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
								
				end
				
				function Test:SubscribeButton_buttonName_IsInvalidValue_InvalidCharacters_Tab_INVALID_DATA()
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = "a\tb"
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
								
				end

				function Test:SubscribeButton_buttonName_IsInvalidValue_InvalidCharacters_OnlySpaces_INVALID_DATA()
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = "  "
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
								
				end					
			--End test case NegativeRequestCheck.2.5
			-----------------------------------------------------------------------------------------	
	

		--End test case NegativeRequestCheck.2


		--Begin test case NegativeRequestCheck.3
		--Description: Check the request with wrong data type in buttonName parameter

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-534

				--Verification criteria: The response with INVALID DATA result code is returned.

				function Test:SubscribeButton_buttonName_IsInvalidValue_WrongDataType_INVALID_DATA()
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = 123
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
								
				end						

		--End test case NegativeRequestCheck.3
		-----------------------------------------------------------------------------------------		
		
	
	--End test suit NegativeRequestCheck



	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--> These checks are not applicable for SubscribeButton request. There is no response from HMI to SDL.

		
		
		--Write TEST_BLOCK_III_End to ATF log
		function Test:TEST_BLOCK_III_End()
			print("********************************************************************")
		end		
		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin test suit ResultCodeCheck
	--Description: check result code of response to Mobile (SDLAQ-CRS-532)

		--Write TEST_BLOCK_IV_Begin to ATF log
		function Test:TEST_BLOCK_IV_Begin()
			print("********************************************************************")
		end		
		
		--Begin test case ResultCodeCheck.1
		--Description: Check resultCode: SUCCESS

			--It is covered by CommonRequestCheck.2 (checking request with mandatory parameter)
			
		--End test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.2
		--Description: Check resultCode: INVALID_DATA

			--It is covered by SubscribeButton_buttonName_IsInvalidValue_nonexistent_INVALID_DATA		
			
		--End test case ResultCodeCheck.2
		-----------------------------------------------------------------------------------------


		--Begin test case ResultCodeCheck.3
		--Description: Check resultCode: OUT_OF_MEMORY

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-535

			--Verification criteria: A SubscribeButton request is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned
			
			--ToDo: Can not check this case.	
			
		--End test case ResultCodeCheck.3
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.4
		--Description: Check resultCode: TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-536

			--Verification criteria: SDL response TOO_MANY_PENDING_REQUESTS resultCode
			
			--Move to another script: ATF_SubscribeButton_TOO_MANY_PENDING_REQUESTS.lua
			
		--End test case ResultCodeCheck.4
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.5
		--Description: Check resultCode: APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-537

			--Verification criteria: SDL responses APPLICATION_NOT_REGISTERED resultCode 			
					
			--Description: Unregister application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			--Description: Send SubscribeButton when application not registered yet.
			
			for i=1,#buttonName do
			
				--Precondition for this test case
				--Precondition_TC_UnsubscribeButton(self, buttonName[i])
								
				Test["SubscribeButton_resultCode_APPLICATION_NOT_REGISTERED_" .. tostring(buttonName[i]).."_APPLICATION_NOT_REGISTERED"] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							buttonName = buttonName[i]
						}
					)

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "APPLICATION_NOT_REGISTERED", info = nil})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(iTimeout)
				end
				
			end	
			
		--End test case ResultCodeCheck.5
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.6
		--Description: Check resultCode: REJECTED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-538

			--Verification criteria: 
				--1. SDL must return "resultCode: REJECTED, success: false" to SubscribeButton (PLAY_PAUSE) in case such RPC comes from non-media app.
				--2. SDL must return "resultCode: REJECTED, success: false" to SubscribeButton (SEEKLEFT) in case such RPC comes from non-media app.
				--3. SDL must return "resultCode: REJECTED, success: false" to SubscribeButton (SEEKRIGHT) in case such RPC comes from non-media app.
				--4. SDL must return "resultCode: REJECTED, success: false" to SubscribeButton (TUNEUP) in case such RPC comes from non-media app.
				--5. SDL must return "resultCode: REJECTED, success: false" to SubscribeButton (TUNEDOWN) in case such RPC comes from non-media app.						
			
	
			-- register non-media application 2
			function Test:RegisterNon_Media_AppInterface()				
				RegisterAppInterface(self, 2)
			end	
			
			function Test:Activate_Non_Media_Application()
				--HMI send ActivateApp request
				--ActivateApplication(self)
				ActivateApplication(self, application2_nonmedia.registerAppInterfaceParams.appName)
			end
			
			buttonName1 = {"PLAY_PAUSE", "SEEKLEFT", "SEEKRIGHT", "TUNEUP", "TUNEDOWN"}
			for i=1,#buttonName1 do
										
				Test["SubscribeButton_resultCode_REJECTED_" .. tostring(buttonName1[i]).."_REJECTED"] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							buttonName = buttonName1[i]
						}
					)

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", info = nil})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(iTimeout)
				end
				
			end	

			--Description: Unregister non-media application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 	

			-- register media application 1
			function Test:Register_Media_AppInterface()				
				RegisterAppInterface(self, 1)
			end	
			
			
			function Test:Activate_Media_Application()
				--HMI send ActivateApp request
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end		
			
		--End test case ResultCodeCheck.6
		-----------------------------------------------------------------------------------------
		
		--Begin test case ResultCodeCheck.7
		--Description: Check resultCode: IGNORED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-539

			--Verification criteria: In case the application sends a SubscribeButton request for a button previously subscribed,  SDL sends the IGNORED resultCode to mobile side. General result success=false.
				
			for i=1,#buttonName do
			
				--Precondition for this test case
				Precondition_TC_SubscribeButton(self, buttonName[i])
								
				Test["SubscribeButton_resultCode_IGNORED_" .. tostring(buttonName[i]).."_IGNORED"] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							buttonName = buttonName[i]
						}
					)

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", info = nil})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(iTimeout)
				end
				
			end	
			
		--End test case ResultCodeCheck.7
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.8
		--Description: Check resultCode: UNSUPPORTED_RESOURCE

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-541

			--Verification criteria: If subscribe for CUSTOM_BUTTON button which isn't supported on the HMI the response with the resultCode UNSUPPORTED_RESOURCE is returned. General request result success=false.
			
			for i=1,#UnsupportButtonName do
										
				Test["SubscribeButton_resultCode_UNSUPPORTED_RESOURCE_" .. tostring(UnsupportButtonName[i]).."_result_UNSUPPORTED_RESOURCE"] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
						{
							buttonName = UnsupportButtonName[i]
						}
					)

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE", info = nil})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(iTimeout)
				end
				
			end	
			
		--End test case ResultCodeCheck.8
		-----------------------------------------------------------------------------------------	

		--Begin test case ResultCodeCheck.9
		--Description: Check resultCode: GENERIC_ERROR

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-540

			--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.
			
				--ToDo: Can not check this case
			
		--End test case ResultCodeCheck.9
		-----------------------------------------------------------------------------------------	
		
		
		--Write TEST_BLOCK_IV_End to ATF log
		function Test:TEST_BLOCK_IV_End()
			print("********************************************************************")
		end		
		
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
	
	
	-- SubscribeButton API does not have any response from HMI. This test suit is not applicable => Ignore
	
		--Write TEST_BLOCK_V_Begin to ATF log
		function Test:TEST_BLOCK_V_Begin()
			print("********************************************************************")
		end		

		--Write TEST_BLOCK_V_End to ATF log
		function Test:TEST_BLOCK_V_End()
			print("********************************************************************")
		end		


----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Write TEST_BLOCK_VI-_Begin to ATF log
		function Test:TEST_BLOCK_VI_Begin()
			print("********************************************************************")
		end		
		
		--Begin test case SequenceCheck.1-5
		--Description: check scenario in test case TC_SubscribeButton_01 - 05:

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61, SDLAQ-CRS-175

			--Verification criteria: SubscribeButton option check for OK, SEEKRIGHT, SEEKLEFT,.. . Make actions on UI to check the subscription on buttons (Long/Short press)
			
			local buttonName1 = buttonName
			local mode = {"SHORT", "LONG"}
			for i=1,#buttonName1 do

				--Precondition for this test case: Unsubscribe button
				Precondition_TC_UnsubscribeButton(self, buttonName1[i])
					
				for j=1,#mode do					
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_01_05_Click_UnsubscribedButton_"..buttonName1[i] .."_".. mode[j]
					TC_OnButtonEvent_OnButtonPress_When_UnsubscribedButton(self, buttonName1[i], mode[j], strTestCaseName)					
				end
					
				--Subscribe button
				strTestCaseName = "TC_SubscribeButton_01_05_SubscribeButton_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_SubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)		
				
				for j=1,#mode do
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_01_05_Click_SubscribedButton_"..buttonName1[i] .."_".. mode[j]
					TC_OnButtonEvent_OnButtonPress_When_SubscribedButton(self, buttonName1[i], mode[j], strTestCaseName)
				end
			end	

		--End test case SequenceCheck.1-5
		-----------------------------------------------------------------------------------------	

		--Begin test case SequenceCheck.6
		--Description: check scenario in test case TC_SubscribeButton_06

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61

			--Verification criteria: SDL must send media-buttons related notifications to one MEDIA app only (of FULL or LIMITED HMILevel)
			
			-- Write TC_SubscribeButton_06_Begin to ATF log 
			function Test:TC_SubscribeButton_06_Begin()
				--Just write to log of ATF a test case to mark as begin of this manual test case
			end		
			
			-- Change App0 to Limited to allow change App1 to FULL
			function Test:TC_SubscribeButton_06_Change_App0_To_LIMITED_HMI_LEVEL()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				appId0 = self.applications["Test Application"]
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

			end
			
			--Precondition: Opening new session 1
			function Test:TC_SubscribeButton_06_AddNewSession()
			  -- Connected expectation
				self.mobileSession1 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession1:StartService(7)
			end

			-- Register app1 
			function Test:TC_SubscribeButton_06_Register_Non_Media_App1() 

				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SPT1",
																--isMediaApplication = true,
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="1",
																ttsName = 
																{ 
																	{ 
																		text ="SyncProxyTester1",
																		type ="TEXT",
																	}, 
																}, 
																vrSynonyms = 
																{ 
																	"vrSPT1",
																}
															}) 
			 
				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = "SPT1"
					}
				})
				:Do(function(_,data)
					self.appId1 = data.params.application.appID
				end)
				
				--mobile side: RegisterAppInterface response 
				self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Activate app1
			function Test:TC_SubscribeButton_06_Activate_App1()
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appId1})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)

					if data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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

				self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
				:Timeout(12000)
				
			end			
			
			-- Subscribe buttons on App1
			for i=1,#buttonNameNonMediaApp do			
				
				strTestCaseName = "TC_SubscribeButton_06_SubscribeButton_for_App1_" .. tostring(buttonNameNonMediaApp[i]).."_SUCCESS"		
				Test[strTestCaseName] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession1:SendRPC("SubscribeButton",
						{
							buttonName = buttonNameNonMediaApp[i]
						}
					)

					--mobile side: expect SubscribeButton response
					self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS", info = nil})
					:Timeout(iTimeout)
					
					self.mobileSession:ExpectResponse("SubscribeButton", {})
					:Times(0)
					
					self.mobileSession1:ExpectNotification("OnHashChange", {})
					
					self.mobileSession:ExpectNotification("OnHashChange", {})
					:Times(0)

					DelayedExp(2000)

				end
			end		
			
			function Test:TC_SubscribeButton_06_Exit_App1_Change_To_NONE_HMI_LEVEL()

				local function sendUserExit()
					--hmi side: sending BasicCommunication.OnExitApplication request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
					{
						appID = self.appId1,
						reason = "USER_EXIT"
					})
				end
			
				local function SendOnSystemContext1()
					--hmi side: sending UI.OnSystemContext request
					SendOnSystemContextOnAppID(self,"MAIN", self.appId1)
				end

				local function sendOnAppDeactivate()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.appId1,
						reason = "GENERAL"
					})
				end			
				
				--hmi side: sending BasicCommunication.OnSystemContext request
				SendOnSystemContextOnAppID(self,"MENU", self.appId1)
				
				--hmi side: sending BasicCommunication.OnExitApplication request
				RUN_AFTER(sendUserExit, 1000)
				
				--hmi side: sending UI.OnSystemContext request = MAIN
				RUN_AFTER(SendOnSystemContext1, 2000)
				
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				RUN_AFTER(sendOnAppDeactivate, 3000)
					
		
				--mobile side: OnHMIStatus notifications
				self.mobileSession1:ExpectNotification("OnHMIStatus",
						{ systemContext = "MENU", hmiLevel = "FULL"},
						{ systemContext = "MENU", hmiLevel = "NONE"},
						{ systemContext = "MAIN", hmiLevel = "NONE"})
					:Times(3)	
					:Timeout(15000)

			end		
		
			-- Opening new session 2
			function Test:TC_SubscribeButton_06_AddNewSession()
			  -- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				--self.expectations_list,
				self,
				self.mobileConnection)
				
				
				self.mobileSession2:StartService(7)
			end

			-- Register app2
			function Test:TC_SubscribeButton_06_RegisterAppInterface_App2() 

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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end

			-- Activate app2
			function Test:TC_SubscribeButton_06_Activate_App2()
				
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"}) 
				:Timeout(12000)
								
			end
			
			-- Subscribe buttons on App2
			for i=1,#buttonName do			
				
				strTestCaseName = "TC_SubscribeButton_06_SubscribeButton_for_App2_" .. tostring(buttonName[i]).."_SUCCESS"
			
				Test[strTestCaseName] = function(self)
				
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession2:SendRPC("SubscribeButton",
						{
							buttonName = buttonName[i]
						}
					)

					--mobile side: expect SubscribeButton response
					self.mobileSession2:ExpectResponse(cid, {success = true, resultCode = "SUCCESS", info = nil})
					:Timeout(iTimeout)
					
					self.mobileSession2:ExpectNotification("OnHashChange", {})
				end
	
			end		

			-- Activate App0
			function Test:TC_SubscribeButton_06_Activate_App0()
				--HMI send ActivateApp request				
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end			
			
			-- Subscribe buttons
			for i=1,#buttonName do			
				--Precondition for this test case
				Precondition_TC_UnsubscribeButton(self, buttonName[i])
				
				strTestCaseName = "TC_SubscribeButton_06_SubscribeButton_for_App0_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_SubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)						
			end	


			local buttonName1 = buttonName
			local mode = {"SHORT", "LONG"}
			
			--Click SubScribedButtons on HMI => SDL only send notifications to FULL application, does not send to NONE, BACKGROUND
			for i=1,#buttonName1 do
				for j=1,#mode do
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_06_ClickSubscribedButton_Incase_FULL_BACKGOUND_NONE_Applications_"..buttonName1[i] .."_".. mode[j]
					Test[strTestCaseName] = function(self)

							--hmi side: send request Buttons.OnButtonEvent
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																{
																	name = buttonName1[i], 
																	mode = "BUTTONDOWN"
																})
							
							local function OnButtonEventBUTTONUP()
								--hmi side: send request Buttons.OnButtonEvent
								self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																	{
																		name = buttonName1[i], 
																		mode = "BUTTONUP"
																	})
							end
							
							--hmi side: send request Buttons.OnButtonPress
							local function OnButtonPress()
								self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
																	{
																		name = buttonName1[i], 
																		mode = mode[j]
																	})
							end
							
							if strMode == "LONG" then	
								--hmi side: send request Buttons.OnButtonPress
								RUN_AFTER(OnButtonPress, 50)
																	
								--hmi side: send request Buttons.OnButtonEvent
								RUN_AFTER(OnButtonEventBUTTONUP, 100)
																
							else
								--hmi side: send request Buttons.OnButtonEvent
								RUN_AFTER(OnButtonEventBUTTONUP, 50)
																	
								--hmi side: send request Buttons.OnButtonPress
								RUN_AFTER(OnButtonPress, 100)								
							end
							---------------------------------------------
							
							--Verify result on app0							
							--Mobile expects OnButtonEvent
							EXPECT_NOTIFICATION("OnButtonEvent", 
								{buttonName = buttonName1[i], buttonEventMode = "BUTTONDOWN"},
								{buttonName = buttonName1[i], buttonEventMode = "BUTTONUP"}
							)
							:Times(2)
							
							--Mobile expects OnButtonEvent
							EXPECT_NOTIFICATION("OnButtonPress", {buttonName = buttonName1[i], buttonPressMode = mode[j]})---------------------------------------------
							
							--Verify result on app1
							--mobile side: expect notification
							self.mobileSession1:ExpectNotification("OnButtonEvent", {})	
							:Times(0)
							
							self.mobileSession1:ExpectNotification("OnButtonPress", {})	
							:Times(0)
							---------------------------------------------

							--Verify result on app2
							--mobile side: expect notification
							self.mobileSession2:ExpectNotification("OnButtonEvent", {})	
							:Times(0)
							
							self.mobileSession2:ExpectNotification("OnButtonPress", {})	
							:Times(0)							
							---------------------------------------------
							
						end					
				end
			end	
			
			--Change application to LIMITED
			function Test:TC_SubscribeButton_06_ChangeHMIToLimited()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED"})

			end	

			--Click SubScribedButtons on HMI => SDL only send notifications to LIMITED application, does not send to NONE, BACKGROUND
			for i=1,#buttonName1 do
				for j=1,#mode do
									
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_06_ClickSubscribedButton_Incase_LIMITED_BACKGOUND_NONE_Applications_"..buttonName1[i] .."_".. mode[j]				
					Test[strTestCaseName] = function(self)


							--hmi side: send request Buttons.OnButtonEvent
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																{
																	name = buttonName1[i], 
																	mode = "BUTTONDOWN",
																	appID = self.applications["Test Application"]
																})
							
							
							local function OnButtonEventBUTTONUP()
								--hmi side: send request Buttons.OnButtonEvent
								self.hmiConnection:SendNotification("Buttons.OnButtonEvent", 
																	{
																		name = buttonName1[i], 
																		mode = "BUTTONUP",
																		appID = self.applications["Test Application"]
																	})
							end
							
							--hmi side: send request Buttons.OnButtonPress
							local function OnButtonPress()
								self.hmiConnection:SendNotification("Buttons.OnButtonPress", 
																	{
																		name = buttonName1[i], 
																		mode = mode[j],
																		appID = self.applications["Test Application"]
																	})
							end
							
							if strMode == "LONG" then	
								--hmi side: send request Buttons.OnButtonPress
								RUN_AFTER(OnButtonPress, 50)
																	
								--hmi side: send request Buttons.OnButtonEvent
								RUN_AFTER(OnButtonEventBUTTONUP, 100)
																
							else
								--hmi side: send request Buttons.OnButtonEvent
								RUN_AFTER(OnButtonEventBUTTONUP, 50)
																	
								--hmi side: send request Buttons.OnButtonPress
								RUN_AFTER(OnButtonPress, 100)								
							end
							---------------------------------------------
							
							--Verify result on app0							
							--Mobile expects OnButtonEvent
							EXPECT_NOTIFICATION("OnButtonEvent", 
								{buttonName = buttonName1[i], buttonEventMode = "BUTTONDOWN"},
								{buttonName = buttonName1[i], buttonEventMode = "BUTTONUP"}
							)
							:Times(2)
							
							--Mobile expects OnButtonEvent
							EXPECT_NOTIFICATION("OnButtonPress", {buttonName = buttonName1[i], buttonPressMode = mode[j]})
							---------------------------------------------
							
							--Verify result on app1
							--mobile side: expect notification
							self.mobileSession1:ExpectNotification("OnButtonEvent", {})	
							:Times(0)
							
							self.mobileSession1:ExpectNotification("OnButtonPress", {})	
							:Times(0)
							---------------------------------------------

							--Verify result on app2
							--mobile side: expect notification
							self.mobileSession2:ExpectNotification("OnButtonEvent", {})	
							:Times(0)
							
							self.mobileSession2:ExpectNotification("OnButtonPress", {})	
							:Times(0)							
							---------------------------------------------
							
						end					
				end
			end	
						
			--Print TC_SubscribeButton_06_End in ATF log
			function Test:TC_SubscribeButton_06_End()
				--Just write to log of ATF a test case to mark as the end of this manual test case
			end				

		--End test case SequenceCheck.6
		-----------------------------------------------------------------------------------------	

		--Begin test case SequenceCheck.7
		--Description: check scenario in test case TC_SubscribeButton_07

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2975, SDLAQ-CRS-61

			--Verification criteria: SubscribeButton option check for CUSTOM_BUTTON and SEARCH
			
			-- Unregister application
			function Test:TC_SubscribeButton_07_UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			-- Register application
			function Test:TC_SubscribeButton_07_RegisterAppInterface_And_Check_OnButtonSubscription()				
		
				--mobile side: sending request 
				local CorIdRegister, strAppName
				
				CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
				strAppName = config.application1.registerAppInterfaceParams.appName

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				{
					application = 
					{
						appName = strAppName
					}
				})
				:Do(function(_,data)
					local appId = data.params.application.appID
					self.appId = appId
					appId0 = appId
					self.appName = data.params.application.appName
					self.applications[strAppName] = appId
					
					--hmi side: expect OnButtonSubscription request due to APPLINK-12241
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = appId0, name = "CUSTOM_BUTTON", isSubscribed=true})
					:Timeout(12000)
				end)
				
				--mobile side: expect response
				self.mobileSession:ExpectResponse(CorIdRegister, 
				{
					syncMsgVersion = 
					{
						majorVersion = 3,
						minorVersion = 0
					}
				})
				:Timeout(12000)

				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus", 
				{ 
					systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
				})
				:Timeout(12000)

			end			
			
			--Activate application
			function Test:TC_SubscribeButton_07_Activate_Application()
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId0})
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

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"}) 
				:Timeout(12000)
				
			end	
					
			
			--Subscribe CUSTOM_BUTTON button => IGNORE
			function Test:TC_SubscribeButton_07_SubscribeButton_CUSTOM_BUTTON_IGNORE_Without_OnButtonSubscription()	
			
				--mobile side: sending SubscribeButton request
				local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = "CUSTOM_BUTTON"
					}
				)
				
				--mobile side: expect SubscribeButton response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", info = nil})
				:Timeout(iTimeout)
			  
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				
			end			
	
			--Subscribe SEARCH button
			function Test:TC_SubscribeButton_07_SubscribeButton_SEARCH_SUCCESS_With_OnButtonSubscription()	
			
				--mobile side: sending SubscribeButton request
				local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = "SEARCH"
					}
				)
				
				--mobile side: expect SubscribeButton response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE", info = nil})
				:Timeout(iTimeout)
			  
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				
			end		
		
		--End test case SequenceCheck.7
		-----------------------------------------------------------------------------------------

		
		--Begin test case SequenceCheck.8
		--Description: check scenario in test case TC_SubscribeButton_08

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-61, SDLAQ-CRS-2974, APPLINK-12241

			--Verification criteria: Check that SDL doesn't send OnButtonSubscription(false) after app was unregistered or disconnected unexpectedly.
			
			-- Precondition: Unregister application
			function Test:TC_SubscribeButton_08_UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			-- Precondition: Register media application 1
			function Test:TC_SubscribeButton_08_RegisterAppInterfaceAndCheckOnButtonSubscription()				
				RegisterAppInterface(self, 1)
			end			
			
			-- Precondition: Activate app
			function Test:TC_SubscribeButton_08_Activate_Application()
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId0})
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

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"}) 
				:Timeout(12000)				
				
			end	
				
			--Subscribe PRESET_1 button
			strTestCaseName = "TC_SubscribeButton_08_SubscribeButton_PRESET_1_SUCCESS_With_OnButtonSubscription"
			TC_SubscribeButtonSUCCESS(self, "PRESET_1", strTestCaseName)
	
			-- Unregister application: check that SDL doesn't send OnButtonSubscription(false) after app was unregistered or disconnected unexpectedly.
			function Test:TC_SubscribeButton_08_UnregisterAppInterface_Without_OnButtonSubscription()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
				
				--hmi side: expect OnButtonSubscription request
				EXPECT_HMICALL("OnButtonSubscription")
				:Times(0)
			end 
	
			local function TC_SubscribeButton_08_Steps_From_4_To_9()
			-- Register the same App again 
			function Test:TC_SubscribeButton_08_RegisterAppInterfaceAndCheckOnButtonSubscription()
				RegisterAppInterface(self, 1)
			end			
			
			-- Precondition: Activate app
			function Test:TC_SubscribeButton_08_Activate_Application()
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId0})
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

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"}) 
				:Timeout(12000)				
				
			end	

			-- Verification that SDL doesn't resend appropriate OnButtonPress and OnButtonEvent notifications to App
			local mode = {"SHORT", "LONG"}
				for j=1,#mode do					
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_08_Click_UnsubscribedButton_PRESET_1".. mode[j]
					TC_OnButtonEvent_OnButtonPress_When_UnsubscribedButton(self, "PRESET_1", mode[j], strTestCaseName)
				end

			--Subscribe PRESET_1 button
			strTestCaseName = "TC_SubscribeButton_08_SubscribeButton_PRESET_1_SUCCESS_With_OnButtonSubscription"
			TC_SubscribeButtonSUCCESS(self, "PRESET_1", strTestCaseName)
			
			--Turn off transport
			function Test:TC_SubscribeButton_08_TurnOffTransport()
				self.mobileSession:Stop()
				
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appId, unexpectedDisconnect = true})
				:Timeout(2000)
				
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
				:Times(0)
				
			end

			--Turn on transport: Opening new session 
			function Test:TC_SubscribeButton_08_TurnOnTransportAddNewSession()
			  -- Connected expectation
				self.mobileSession = mobile_session.MobileSession(
				self,
				self.mobileConnection)
				
				self.mobileSession:StartService(7)
			end
 
			--RegisterAppInterface
			function Test:TC_SubscribeButton_08_RegisterAppInterfaceAndCheckOnButtonSubscription()				
				RegisterAppInterface(self, 1)
				--ToDo: Register again to avoid error: app is unregistered 
				--RegisterAppInterface(self, 1)
			end			
			
			--Verification that SDL resend OnButtonEvent and OnButtionPress notifications to App
			--local mode = {"SHORT", "LONG"}
			for j=1,#mode do
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_SubscribeButton_08_Click_SubscribedButton_PRESET_1_".. mode[j]
					TC_OnButtonEvent_OnButtonPress_When_SubscribedButton(self, "PRESET_1", mode[j], strTestCaseName)
			end
		end
			--Steps_4_9()
			TC_SubscribeButton_08_Steps_From_4_To_9()
			
		--End test case SequenceCheck.8
		-----------------------------------------------------------------------------------------			
		
		--Write TEST_BLOCK_VI_End to ATF log
		function Test:TEST_BLOCK_VI_End()
			print("********************************************************************")
		end		

	--End test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin test suit DifferentHMIlevel
	--Description: processing API in different HMILevel

		--Write TEST_BLOCK_VII_Begin to ATF log
		function Test:TEST_BLOCK_VII_Begin()
			print("********************************************************************")
		end		
		
		-- Precondition: Register and activate application again 
		function Test:RegisterAppInterface()				
			RegisterAppInterface(self, 1)
		end	

		function Test:ActivateApplication_FULL()
			--HMI send ActivateApp request
			ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
		end
		
		--Begin test case DifferentHMIlevel.1
		--Description: Check SubscribeButton request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-790

			--Verification criteria: SubscribeButton is allowed in LIMITED HMI level
			
			-- Precondtion: Change app to LIMITED
			function Test:ChangeHMIToLimited()
				
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					--appID = self.applications["Test Application"],
					appID = appId0,
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED"})

			end

			-- Body
			for i=1,#buttonName do
			
				--Precondition for this test case
				Precondition_TC_UnsubscribeButton(self, buttonName[i])
				
				strTestCaseName = "SubscribeButton_LIMITED_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_SubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)						
			end	
				
		--End test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------

		
		--Begin test case DifferentHMIlevel.4
		--Description: Check SubscribeButton request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-790

			--Verification criteria: SubscribeButton is NOT allowed in NONE HMI level
		
			-- Precondition 1: Activate app
			function Test:Activate_Media_Application()
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end	
			
			-- Precondition 2: Change app to NONE HMI level
			function Test:ExitApplication_ChangeTo_NONE_HMILEVEL()

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
			
			-- Body
			for i=1,#buttonName do
				Test["SubscribeButton_NONE_" ..tostring(buttonName[i]).."_DISALLOWED"] = function(self)
					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = buttonName[i]
					})

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					:Timeout(iTimeout)
				end
			end	
			
		--End test case DifferentHMIlevel.2
		-----------------------------------------------------------------------------------------

		
		--Begin test case DifferentHMIlevel.3
		--Description: Check SubscribeButton request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-790

			--Verification criteria: SubscribeButton is allowed in BACKGOUND HMI level
		
			-- Precondition 1: Change all to FULL
			function Test:ActivateApplication_ChangeTo_FULL_HMILEVEL()
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end	
			
			-- Precondition 2: Change all to LIMITED
			function Test:ChangeHMIToLimited()			
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					--appID = self.applications["Test Application"],
					appID = appId0,
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED"})
			end			

			-- Precondition 3: Activate an other media app to change app to BACKGROUND
			function Test:Activate_Media_App2()
				--HMI send ActivateApp request			
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"}) 
				:Timeout(12000)
				
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND"}) 
				
			end	
		
			-- Body
			for i=1,#buttonName do
			
				--Precondition for this test case
				Precondition_TC_UnsubscribeButton(self, buttonName[i])
				
				strTestCaseName = "SubscribeButton_BACKGOUND_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_SubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)						
			end	

		--End test case DifferentHMIlevel.3
		-----------------------------------------------------------------------------------------

		--Write TEST_BLOCK_VII_End to ATF log
		function Test:TEST_BLOCK_VII_End()
			print("********************************************************************")
		end		
		
	--End test suit DifferentHMIlevel


		
return Test

