--Note: List of existing problems:
--1. SDLAQ-CRS-545: The UnsubscribeButton request is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned. 
	--=> ToDo: Need investigate how to make memory reach upper bound so that SDL responses OUT_OF_MEMORY

Test = require('connecttest')
--Test = require('user_modules/connecttestSubscribeSB')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

require('user_modules/AppTypes')

local iTimeout = 5000
local buttonName = {"OK","PLAY_PAUSE","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local buttonNameNonMediaApp = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
local UnsupportButtonName = {"PRESET_9", "SEARCH"}

local str1000Chars = 
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local OutBound = {"a", "nonexistButton", str1000Chars}
local OutBoundName = {"OneCharacter", "nonexistButton", "String1000Characters"}
local appID0, appId1, appId2

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


					
-- Check Result: 
	-- Mobile side: expects SubscribeButton response 
	-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS
	-- hmi side: expects OnButtonSubscription notification if SUCCESS			
local function checkResults(cid, blnSuccess, strResultCode)

	--mobile side: expect UnsubscribeButton response
	EXPECT_RESPONSE(cid, {success = blnSuccess, resultCode = strResultCode})
	:Timeout(iTimeout)
	
	if strResultCode == "SUCCESS" then
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(1)
		:Timeout(iTimeout)		
		
	else
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
		:Timeout(iTimeout)	

	end
end		

	
-- Precondition test case: If button have NOT subscribed yet (return IGNORED), precondition is considered as SUCCESS
local function Precondition_TC_UnsubscribeButton(self, btnName)

	Test["Precondition_TC_UnsubscribeButton_" .. tostring(btnName)] = function(self)
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = btnName
			}
		)

		--hmi side: expect OnButtonSubscription notification
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = btnName, isSubscribed = false})
		:Times(AtMost(1))

		--mobile side: expect UnsubscribeButton response
		EXPECT_RESPONSE("UnsubscribeButton")
		:ValidIf(function(_,data)
			if (data.payload.resultCode == "SUCCESS") then
				EXPECT_NOTIFICATION("OnHashChange")
				return true
			elseif (data.payload.resultCode == "IGNORED") then
				print(btnName .. " button has not subscribed yet. resultCode = "..tostring(data.payload.resultCode))
				return true
			else
				print("UnsubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode))
				return false
			end
		end)

		DelayedExp(1000)
		
	end
	
end

-- Precondition test case: If button have subscribed yet (return IGNORED), precondition is considered as SUCCESS
local function Precondition_TC_SubscribeButton(self, btnName)

	Test["Precondition_TC_SubscribeButton_" .. tostring(btnName)] = function(self)
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
			{
				buttonName = btnName
			}
		)

		--hmi side: expect OnButtonSubscription notification
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = btnName, isSubscribed = true})
		:Times(AtMost(1))

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE("SubscribeButton")
		:ValidIf(function(_,data)
			if 
				(data.payload.resultCode == "IGNORED") then
					print(btnName .. " button has already been subscribed. resultCode = "..tostring(data.payload.resultCode))
					return true
			elseif
				self.isMediaApplication == false and
				(btnName == "PLAY_PAUSE" or
				btnName == "SEEKLEFT" or 
				btnName == "SEEKRIGHT" or 
				btnName == "TUNEUP" or 
				btnName == "TUNEDOWN") then
					if data.payload.resultCode == "REJECTED" then
						print(btnName .. " button has rejected because app is non-media")
						return true
					else
						print("SubscribeButton response for non-media app came with wrong resultCode "..tostring(data.payload.resultCode))
						return false
					end
			elseif (data.payload.resultCode == "SUCCESS") then
				EXPECT_NOTIFICATION("OnHashChange")
				return true
			else
				print("SubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode))
				return false
			end
		end)

		DelayedExp(1000)
	end
	
end

-- Test case clicking on unsubscribed button on HMI and verify OnButtonEvent and OnButtonPress notifications
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
		
	    --Mobile expects OnButtonPress
		EXPECT_NOTIFICATION("OnButtonPress")
		:Times(0)

		DelayedExp(2000)
	end
	
end

-- Test case sending request and checking results in case SUCCESS
local function TC_UnsubscribeButtonSUCCESS(self, btnName, strTestCaseName)

	Test[strTestCaseName] = function(self)
	
		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = btnName
			}
		)

		if
			self.isMediaApplication == false and
			(btnName == "PLAY_PAUSE" or
			btnName == "SEEKLEFT" or 
			btnName == "SEEKRIGHT" or 
			btnName == "TUNEUP" or 
			btnName == "TUNEDOWN") then
				-- Check Result: 
				-- Mobile side: expects SubscribeButton response 
				checkResults(cid, false, "IGNORED")
		else
			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = btnName, isSubscribed = false})
			:Timeout(iTimeout)

			-- Check Result: 
			-- Mobile side: expects SubscribeButton response 
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS	
			checkResults(cid, true, "SUCCESS")
		end
		
	end
end

-- Function to activate an application via app name
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

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 
	:Timeout(12000)

end

-- Function to register application via application number from config file
function RegisterAppInterface(self, appNumber)				
		--mobile side: sending request 
		local CorIdRegister, strAppName
		
		if appNumber ==1 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			strAppName = config.application1.registerAppInterfaceParams.appName
		elseif appNumber ==2 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application2_nonmedia.registerAppInterfaceParams)
			strAppName = config.application2_nonmedia.registerAppInterfaceParams.appName
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
				majorVersion = 4,
				minorVersion = 1
			}
		})
		:Timeout(12000)

		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
		})
		:Timeout(12000)

	
		--hmi side: expect OnButtonSubscription request
		EXPECT_HMICALL("OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed=true})
		:Timeout(12000)
		
		DelayedExp(2000)
	end
	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp

		function Test:Activate_Media_Application()
			--HMI send ActivateApp request			
			ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
		end

	--End Precondition.1

	-----------------------------------------------------------------------------------------
	

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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-73

			--Verification criteria: Sets the initial media clock value and automatic update method for HMI media screen with all parameters

			for i=1,#buttonName do	

				-- Precondition: Subscribe button
				Precondition_TC_SubscribeButton(self, buttonName[i])
				
				strTestCaseName = "UnsubscribeButton_PositiveCase_".. tostring(buttonName[i]).."_SUCCESS"
				TC_UnsubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)
			end						
			
		--End test case CommonRequestCheck.1
		-----------------------------------------------------------------------------------------		



		--Begin test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters  

			--It is covered by CommonRequestCheck.1
			
		--End Test case CommonRequestCheck.2
		-----------------------------------------------------------------------------------------	


		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)

		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.5
		--Description: This test is intended to check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-544

			--Verification criteria: SDL responses invalid data
			
			function Test:UnsubscribeButton_missing_mandatory_parameters_updateMode_INVALID_DATA()
					
				--mobile side: sending UnsubscribeButton request
				local cid = self.mobileSession:SendRPC("UnsubscribeButton",
				{
				
				})
			
				--Check results on mobile side (and HMI if it is applicable)
				checkResults(cid, false, "INVALID_DATA")
			end					

			
		--End test case CommonRequestCheck.5
		-----------------------------------------------------------------------------------------		
	
				
		--Begin test case CommonRequestCheck.6
		--Description: check request with all parameters are missing

			-- It is covered by UnsubscribeButton_missing_mandatory_parameters_updateMode_INVALID_DATA

		--End test case CommonRequestCheck.6
		-----------------------------------------------------------------------------------------



		--Begin test suit CommonRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Begin test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters

				--Requirement id in JAMA/or Jira ID: APPLINK-4518, APPLINK-12241

				--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL
					
				for i=1,#buttonName do
					--Precondition for this test case
					Precondition_TC_SubscribeButton(self, buttonName[i])
					
					Test["UnsubscribeButton_FakeParameters_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
						
						--mobile side: sending UnsubscribeButton request
						local cid = self.mobileSession:SendRPC("UnsubscribeButton",
						{
							fakeParameter = "fakeParameter",
							buttonName = buttonName[i]

						})

						if
							self.isMediaApplication == false and
							(buttonName[i] == "PLAY_PAUSE" or
							buttonName[i] == "SEEKLEFT" or 
							buttonName[i] == "SEEKRIGHT" or 
							buttonName[i] == "TUNEUP" or 
							buttonName[i] == "TUNEDOWN") then
								-- Check Result: 
								-- Mobile side: expects SubscribeButton response 
								checkResults(cid, false, "IGNORED")

                                                     --hmi side: request, response
	                                             EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		                                     :Timeout(1000)
		                                     :Times(0)

						else

							--Check results on mobile side and notification to HMI
							EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})

							EXPECT_NOTIFICATION("OnHashChange")
								
							--hmi side: expect OnButtonSubscription notification
							EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name =  buttonName[i], isSubscribed = false})
							:ValidIf(function(_,data)
								if data.params.fakeParameter then
									print("SDL forwards fake parameter to HMI in OnButtonSubscription notification")
									return false
								else 
									return true
								end

                                                          

							end)
						end
						
					end
				end						

			--End test case CommonRequestCheck.7.1
			-----------------------------------------------------------------------------------------

			--Begin test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				--Requirement id in JAMA/or Jira ID: APPLINK-4518, APPLINK-12241

				--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL
					
				for i=1,#buttonName do
					--Precondition for this test case
					Precondition_TC_SubscribeButton(self, buttonName[i])
					
					Test["UnsubscribeButton_FakeParameters_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
						
						--mobile side: sending UnsubscribeButton request
						local cid = self.mobileSession:SendRPC("UnsubscribeButton",
						{
							syncFileName = "icon.png", --parameter of DeleteFile request
							buttonName = buttonName[i]

						})

						if
							self.isMediaApplication == false and
							(buttonName[i] == "PLAY_PAUSE" or
							buttonName[i] == "SEEKLEFT" or 
							buttonName[i] == "SEEKRIGHT" or 
							buttonName[i] == "TUNEUP" or 
							buttonName[i] == "TUNEDOWN") then
								-- Check Result: 
								-- Mobile side: expects SubscribeButton response 
								checkResults(cid, false, "IGNORED")

                                                     --hmi side: request, response
	                                             EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		                                     :Timeout(1000)
		                                     :Times(0)

						else
							--Check results on mobile side and notification to HMI
							EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})

							EXPECT_NOTIFICATION("OnHashChange")
								
							--hmi side: expect OnButtonSubscription notification
							EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name =  buttonName[i], isSubscribed = false})
							:ValidIf(function(_,data)
								if data.params.syncFileName then
									print("SDL forwards parameters of other request to HMI in OnButtonSubscription notification")
									return false
								else 
									return true
								end
							end)
						end
						
					end
				end						

			--End test case CommonRequestCheck.7.2
			-----------------------------------------------------------------------------------------
			
		--End test suit CommonRequestCheck.7	

		
		
		--Begin test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-544

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

			function Test:UnsubscribeButton_InvalidJSON_INVALID_DATA()
			
				self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 19, --UnsubscribeButtonID
					rpcCorrelationId = self.mobileSession.correlationId,
					-- missing ':' after buttonName
					--payload          = '{"buttonName":"OK"}'
					  payload          = '{"buttonName" "OK"}'
				}
				self.mobileSession:Send(msg)
				
				self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })						
			end

		--End test case CommonRequestCheck.8
		-----------------------------------------------------------------------------------------
			


		--Begin test case CommonRequestCheck.9
		--Description: check request with duplicated correlation Id

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: the response comes with SUCCESS result code.

			-- Precondition: Subscribe button
			Precondition_TC_SubscribeButton(self, "OK")
			Precondition_TC_SubscribeButton(self, "PRESET_0")

			function Test:UnsubscribeButton_Duplicated_CorrelationID_SUCCESS()
			
				--mobile side: send UnsubscribeButton request
				local cid = self.mobileSession:SendRPC("UnsubscribeButton",
					{
						buttonName = "OK"
					}
				)

				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 19, --UnsubscribeButtonID
					rpcCorrelationId = cid,
					payload          = '{"buttonName":"PRESET_0"}'
				}
				
				--mobile side: expect UnsubscribeButton response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
					end
				end)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(2)
			end

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
		
			-- It is covered by CommonRequestCheck.1

		--End test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		
		--Begin test suit PositiveResponseCheck
		--Description: Check positive responses 

			--SDL responses to mobile directly without response from HMI so that this kind of test cases are not applicable.
				
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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-73, SDLAQ-CRS-544

			--Verification criteria: SDL returns INVALID_DATA

			for i=1,#OutBound do
				Test["UnsubscribeButton_buttonName_OutBound_" .. tostring(OutBoundName[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
					{
						buttonName = OutBound[i]
					})

					--Check results on mobile side (and HMI if it is applicable)
					checkResults(cid, false, "INVALID_DATA")
				 
				end
			end						


		--End test case NegativeRequestCheck.1
		-----------------------------------------------------------------------------------------
			

		--Begin test case NegativeRequestCheck.2
		--Description: Check properties parameter is -- invalid values(empty) - The request with empty "buttonName" is sent

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-73, SDLAQ-CRS-544

			--Verification criteria: SDL responses with INVALID_DATA result code. 

			function Test:UnsubscribeButton_buttonName_IsInvalidValue_Empty_INVALID_DATA()
			
				--mobile side: sending UnsubscribeButton request
				local cid = self.mobileSession:SendRPC("UnsubscribeButton",
				{
					buttonName = ""
				})

				--Check results on mobile side (and HMI if it is applicable)
				checkResults(cid, false, "INVALID_DATA")
							
			end
		
		--End test case NegativeRequestCheck.2
		-----------------------------------------------------------------------------------------		
				

			

		--Begin test case NegativeRequestCheck.3
		--Description: Check the request with nonexistent value is sent, the INVALID_DATA response code is returned.

			--It is covered by UnsubscribeButton_buttonName_OutBound
		
		--End test case NegativeRequestCheck.3
		-----------------------------------------------------------------------------------------	


		--Begin test case NegativeRequestCheck.4
		--Description: Check the request with wrong data type in buttonName parameter


				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-544

				--Verification criteria: The response with INVALID DATA result code is returned.

				function Test:UnsubscribeButton_buttonName_IsInvalidValue_WrongDataType_INVALID_DATA()
				
					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
					{
						buttonName = 123
					})

					--Check results on mobile side (and HMI if it is applicable)
					checkResults(cid, false, "INVALID_DATA")
								
				end						

		--End test case NegativeRequestCheck.4
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

		--> These checks are not applicable for UnsubscribeButton request. There is no response from HMI to SDL.

		
		
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

			--It is recovered by CommonRequestCheck.1
			
		--End test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.2
		--Description: Check resultCode: INVALID_DATA

			--It is recovered by UnsubscribeButton_buttonName_IsInvalidValue_nonexistent_INVALID_DATA
			
		--End test case ResultCodeCheck.2
		-----------------------------------------------------------------------------------------


		--Begin test case ResultCodeCheck.3
		--Description: Check resultCode: OUT_OF_MEMORY

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-545

			--Verification criteria: A UnsubscribeButton request is sent under conditions of RAM deficit for executing it. The response code OUT_OF_MEMORY is returned
			
			--ToDo: Can not check this case.	
			
		--End test case ResultCodeCheck.3
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.4
		--Description: Check resultCode: TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-546

			--Verification criteria: SDL response TOO_MANY_PENDING_REQUESTS resultCode
			
			--Move to another script: ATF_UnsubscribeButton_TOO_MANY_PENDING_REQUESTS.lua
			
		--End test case ResultCodeCheck.4
		-----------------------------------------------------------------------------------------

		--Begin test case ResultCodeCheck.5
		--Description: Check resultCode: APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-547

			--Verification criteria: SDL responses APPLICATION_NOT_REGISTERED resultCode 			
					
			--Description: Unregister application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end 
			
			--Description: Send UnsubscribeButton when application not registered yet.
			
			for i=1,#buttonName do
			
				--Precondition for this test case
				--Precondition_TC_SubscribeButton(self, buttonName[i])
								
				Test["UnsubscribeButton_resultCode_APPLICATION_NOT_REGISTERED_" .. tostring(buttonName[i]).."_APPLICATION_NOT_REGISTERED"] = function(self)
				
					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
						{
							buttonName = buttonName[i]
						}
					)

					--mobile side: expect UnsubscribeButton response
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

			--Removed: by answer in APPLINK-13589: Per CRS APPLINK-14503 REJECTED result code is not applicable for UnsubscribeButton_response

		--End test case ResultCodeCheck.6
		-----------------------------------------------------------------------------------------
		
		--Begin test case ResultCodeCheck.7
		--Description: Check resultCode: IGNORED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-549

			--Verification criteria: In case an application sends UnsubscribeButton request for a button which hasn't been previously subscribed,  SDL sends IGNORED resultCode to mobile side. General result is success=false.


--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			function Test:Precondition_ActivateFirstApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				
				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})										
			end
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


			-- register media application 1
			-- function Test:Register_Media_AppInterface()				
			-- 	RegisterAppInterface(self, 1)
			-- end	
			
			
			-- function Test:Activate_Media_Application()
			-- 	--HMI send ActivateApp request
			-- 	ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			-- end	
			
			
			for i=1,#buttonName do
			
				--Precondition for this test case
				Precondition_TC_UnsubscribeButton(self, buttonName[i])
								
				Test["UnsubscribeButton_resultCode_IGNORED_" .. tostring(buttonName[i]).."_IGNORED"] = function(self)
				
					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
						{
							buttonName = buttonName[i]
						}
					)

					--mobile side: expect UnsubscribeButton response
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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-550

			--Verification criteria: A button that was requested for unsubscription is not supported under the current system.
			
			for i=1,#UnsupportButtonName do
										
				Test["UnsubscribeButton_resultCode_UNSUPPORTED_RESOURCE_" .. tostring(UnsupportButtonName[i])] = function(self)
				
					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
						{
							buttonName = UnsupportButtonName[i]
						}
					)

					--mobile side: expect UnsubscribeButton response
					EXPECT_RESPONSE(cid, {resultCode = "UNSUPPORTED_RESOURCE", success = false})
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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-551

			--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
			
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
	
	
	-- UnsubscribeButton API does not have any response from HMI. This test suit is not applicable => Ignore
	
		--Write TEST_BLOCK_V_Begin to ATF log
		function Test:TEST_BLOCK_V_Begin()
			print("********************************************************************")
			print("***TEST_BLOCK_V: HMI negative cases are not applicable for UnsubscribeButton***")
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

		--Write TEST_BLOCK_VII-_Begin to ATF log
		function Test:TEST_BLOCK_VI_Begin()
			print("********************************************************************")
		end		
		
		--Begin test case SequenceCheck.1-5
		--Description: check scenario in test case TC_UnsubscribeButton_01 - 05:

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-73, SDLAQ-CRS-74, SDLAQ-CRS-171, SDLAQ-CRS-175

			--Verification criteria: UnsubscribeButton option check for OK, SEEKRIGHT, SEEKLEFT,.. . Make actions on UI to check the subscription on buttons (Long/Short press)
			
			local buttonName1 = buttonName
			local mode = {"SHORT", "LONG"}
			for i=1,#buttonName1 do

				--Precondition for this test case: Unsubscribe button
				Precondition_TC_SubscribeButton(self, buttonName1[i])
							
				--Subscribe button
				strTestCaseName = "TC_UnsubscribeButton_01_05_UnsubscribeButton_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_UnsubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)		
				
				for j=1,#mode do
					--check OnButtonEvent and OnButtonPress when clicking on this button
					strTestCaseName = "TC_UnsubscribeButton_01_05_Click_UnsubscribedButton_"..buttonName1[i] .."_".. mode[j]
					TC_OnButtonEvent_OnButtonPress_When_UnsubscribedButton(self, buttonName1[i], mode[j], strTestCaseName)
				end
			end	

		--End test case SequenceCheck.1-5
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

		

		--Begin test case DifferentHMIlevel.1
		--Description: Check UnsubscribeButton request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-794

			--Verification criteria: UnsubscribeButton is allowed in LIMITED HMI level(only for media app)
		if 
			Test.isMediaApplication == true or 
			Test.appHMITypes["NAVIGATION"] == true then

			-- Precondition: Change app to LIMITED
			function Test:ChangeHMIToLimited()
				
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					--appID = self.applications["Test Application"],
					appID = appId0,
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

			end

			-- Body
			for i=1,#buttonName do			
				--Precondition for this test case
				Precondition_TC_SubscribeButton(self, buttonName[i])
				
				strTestCaseName = "UnsubscribeButton_LIMITED_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_UnsubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)						
			end	
				
		
		--End test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------

		
		--Begin test case DifferentHMIlevel.2
		--Description: Check UnsubscribeButton request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-794

			--Verification criteria: UnsubscribeButton is NOT allowed in NONE HMI level
		
			-- Precondition 1: Activate app
			function Test:Activate_Media_Application()
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end	
			
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
					:Times(2)	

			end		
			
			-- Body
			for i=1,#buttonName do
				Test["UnsubscribeButton_NONE_" ..tostring(buttonName[i]).."_DISALLOWED"] = function(self)
					--mobile side: sending UnsubscribeButton request
					local cid = self.mobileSession:SendRPC("UnsubscribeButton",
					{
						buttonName = buttonName[i]
					})

					--mobile side: expect UnsubscribeButton response
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
		--Description: Check UnsubscribeButton request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID:  SDLAQ-CRS-794

			--Verification criteria: UnsubscribeButton is NOT allowed in BACKGOUND HMI level
		
			-- Precondition 1: Change all to FULL
			function Test:ActivateApplication_ChangeTo_FULL_HMILEVEL()
				ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
			end	
			
		if 
			Test.isMediaApplication == true or 
			Test.appHMITypes["NAVIGATION"] == true then

			-- Precondition 3: Opening new session
			function Test:AddNewSession()
			  -- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self.expectations_list,
				self.mobileConnection)
				
				self.mobileSession2:StartService(7)
			end	
	
			-- Precondition 4: Register app2
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
																appHMIType = { "NAVIGATION"},
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

			-- Precondition 5: Activate an other media app to change app to BACKGROUND
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

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}) 
				:Timeout(12000)
				
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"}) 
				
			end	

		elseif
				Test.isMediaApplication == false then

					-- Precondition for non-media app
					function Test:Precondition_DeactivateToBackground()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["Test Application"],
							reason = "GENERAL"
						})
						
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
					end
			end
		
			-- Body
			for i=1,#buttonName do
			
				--Precondition for this test case
				Precondition_TC_SubscribeButton(self, buttonName[i])
				
				strTestCaseName = "UnsubscribeButton_BACKGOUND_" .. tostring(buttonName[i]).."_SUCCESS"
				TC_UnsubscribeButtonSUCCESS(self, buttonName[i], strTestCaseName)						
			end	

		--End test case DifferentHMIlevel.3
		-----------------------------------------------------------------------------------------

		--Write TEST_BLOCK_VII_End to ATF log
		function Test:TEST_BLOCK_VII_End()
			print("********************************************************************")
		end		
		
	--End test suit DifferentHMIlevel


		
return Test


