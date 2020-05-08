---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last modify date: 30/06/2016
--Author: I.Stoimenova
---------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnButtonSubscription.lua
	os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_OnButtonSubscription.lua')

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "r"))

	fileContent = f:read("*all")
	f:close()

	-- add "Buttons.OnButtonSubscription"
	local pattern1 = "registerComponent%s-%(%s-\"Buttons\"%s-[%w%s%{%}.,\"]-%)"
	local pattern1Result = fileContent:match(pattern1)

	if pattern1Result == nil then 
		print(" \27[31m Buttons registerComponent function is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern1, 'registerComponent("Buttons", {"Buttons.OnButtonSubscription"})')
	end

	local pattern2 = "%{%s-capabilities%s-=%s-%{.-%}"
	local pattern2Result = fileContent:match(pattern2)

	if pattern2Result == nil then 
		print(" \27[31m capabilities array is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern2, '{capabilities = {button_capability("PRESET_0"),button_capability("PRESET_1"),button_capability("PRESET_2"),button_capability("PRESET_3"),button_capability("PRESET_4"),button_capability("PRESET_5"),button_capability("PRESET_6"),button_capability("PRESET_7"),button_capability("PRESET_8"),button_capability("PRESET_9"),button_capability("OK", true, false, true),button_capability("PLAY_PAUSE"),button_capability("SEEKLEFT"),button_capability("SEEKRIGHT"),button_capability("TUNEUP"),button_capability("TUNEDOWN"),button_capability("CUSTOM_BUTTON")}')
	end

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "w+"))
	f:write(fileContent)
	f:close()

--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnButtonSubscription')
require('cardinalities')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps	  = require('user_modules/shared_testcases/commonSteps')
local mobile_session  = require('mobile_session')
local events 		  = require('events')


---------------------------------------------------------------------------------------------
------------------------------------------Common variables-----------------------------------
---------------------------------------------------------------------------------------------
local application       = config.application2.registerAppInterfaceParams


--Requirement id in JAMA/or Jira ID: APPLINK-20056
--Verification criteria:  Described buttons are defined according to enum "ButtonName" in HMI API
local AllbuttonName		= {"OK", "PLAY_PAUSE", "SEEKLEFT", "SEEKRIGHT", "TUNEUP", "TUNEDOWN", "PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3", "PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8"}
local NonMediaButton    = {"OK"}

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

--TODO: Clarification for requirement APPLINK-20116 is expected. See APPLINK-24371
--      After clarification, requirement shall be marked in appropriated tests.

local function startSession(self)
	
	self.MobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
	self.MobileSession1.version = 3
	--**************************************************************************
	--TODO: Commented because of APPLINK-16610. Will be used when the problem is fixed!
	--sessions[numberSession]:SetHeartbeatTimeout(7000)
	--sessions[numberSession]:StartHeartbeat()
	--**************************************************************************

	self.MobileSession1:StartService(7)	 
end

local function RegisterAppInterface(self)

 	local CorIdRAI, strAppName

 	CorIdRAI   = self.MobileSession1:SendRPC("RegisterAppInterface",application)
 	strAppName = application.appName
	
 	--hmi side: expected  BasicCommunication.OnAppRegistered
 	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
 	{
 		application = 
 		{
 			appName = strAppName
 		}
 	})
 	:Do(function(_,data)
 		local appId = data.params.application.appID
 		self.applications[strAppName] = appId
 	end)			
	
 	--mobile side: RegisterAppInterface response 
 	self.MobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
 	:Do(function(_,data)
 		
 		-- Issue of ATF, OnHMIStatus  is not verified correctly: APPLINK-17030
 		--mobile side: expect notification
 		self.MobileSession1:ExpectNotification("OnHMIStatus", {{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})

 		--hmi side: expect notification
 		--Requirement id in JAMA/or Jira ID: APPLINK-20056
 		--Verification criteria: Structure of HMI notification is verified according to HMI API
 		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications[strAppName], isSubscribed = true, name = "CUSTOM_BUTTON"})

 	end)
			
 	
end

local function ActivateApplication(self)
 	
 	--HMI send ActivateApp request
 	local strAppName = application.appName	
 	local RequestId  = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[strAppName]})
	
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
 			end)
 		end
 	end)

 	--EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
 	if(application.isMediaApplication == true) then
 		self.MobileSession1:ExpectNotification("OnHMIStatus", {{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
 		:Timeout(12000)
 	else
 		if(application.appHMIType == "NAVIGATION" or application.appHMIType == "COMMUNICATION") then
			self.MobileSession1:ExpectNotification("OnHMIStatus", {{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
 			:Timeout(12000) 		
 		else
 			self.MobileSession1:ExpectNotification("OnHMIStatus", {{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
 			:Timeout(12000)
 		end
 	end
end

local function DelayedExp(time)

 	local event = events.Event()
   	event.matches = function(self, e) return self == e end
   	
   	EXPECT_EVENT(event, "Delayed event")
   	:Timeout(time+1000)
   	
   	RUN_AFTER(function()
         RAISE_EVENT(event, event)
     		  end, time)
end

function ExitApplication(self)

	local strAppName = application.appName

	local function SendOnSystemContextOnAppID(self, ctx, strAppID)
	  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID =  strAppID, systemContext = ctx })
	end

	local function sendUserExit()
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
		{
			appID = self.applications[strAppName],
			reason = "USER_EXIT"
		})

	end

	local function SendOnSystemContext1()
		--hmi side: sending UI.OnSystemContext request
		SendOnSystemContextOnAppID(self,"MAIN", self.applications[strAppName])
	end

	local function sendOnAppDeactivate()
		--hmi side: sending BasicCommunication.OnAppDeactivated request
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[strAppName]
		})
	end		


	--hmi side: sending BasicCommunication.OnSystemContext request
	SendOnSystemContextOnAppID(self,"MENU", self.applications[strAppName])
				
	--hmi side: sending BasicCommunication.OnExitApplication request
	RUN_AFTER(sendUserExit, 1000)
				
	--hmi side: sending UI.OnSystemContext request = MAIN
	RUN_AFTER(SendOnSystemContext1, 2000)
				
	--hmi side: sending BasicCommunication.OnAppDeactivated request
	RUN_AFTER(sendOnAppDeactivate, 3000)
					
	DelayedExp(5000)
		
	--mobile side: OnHMIStatus notifications
	self.MobileSession1:ExpectNotification("OnHMIStatus",
		{ systemContext = "MENU", hmiLevel = "FULL"},
		{ systemContext = "MENU", hmiLevel = "NONE"},
		{ systemContext = "MAIN", hmiLevel = "NONE"})
	:Times(3)	
	:Timeout(5000)	
end


local function SubscribeBtn(self, btn)
 	local strAppName = application.appName
				
 	--mobile side: sending SubscribeButton request
 	local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = btn})

 	--mobile side: expect SubscribeButton response
 	self.MobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
 	:Do(function(_,data) 

 		--mobile side: expect notification
 		self.MobileSession1:ExpectNotification("OnHashChange",{})

 		--hmi side: expect Buttons.OnButtonSubscription
 		--Requirement id in JAMA/or Jira ID: APPLINK-20056; APPLINK-20118
 		--Verification criteria:  SDL must notify HMI via OnButtonSubscription (appID, <buttonName>, isSubscribed:true) on successful subscription on the button; 
 		--                        Structure of HMI notification shall be verified according to HMI API
 		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications[strAppName], isSubscribed = true, name = buttonName})

 	end)
					
 	
end

local function UnSubscribeBtn(self, btn)
	
 	local strAppName = application.appName
					
 	--mobile side: sending SubscribeButton request
 	local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = btn})
								
 	--mobile side: expect SubscribeButton response
 	self.MobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
 	:Do(function(_,data) 

 		--mobile side: expect notification
 		self.MobileSession1:ExpectNotification("OnHashChange",{})

 		-- HMI side: expect OnButtonSubscription notification
 		--Requirement id in JAMA/or Jira ID: APPLINK-20056; APPLINK-20194
 		--Verification criteria:  SDL must notify HMI via OnButtonSubscription (appID, <buttonName>, isSubscribed:false) on successful unsubscription on the button; 
 		--                        Structure of HMI notification shall be verified according to HMI API
 		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications[strAppName], isSubscribed = false, name = buttonName})

 	end)
					
 	
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	-- Begin Precondition.1
	-- Description: General: Parameters shall be updated according to type of executed application ( media / non-media )
	print("\27[33m================================================================================================================================\27[0m")
	--print("\27[33mUsed application in script is config.application2. Update parameter isMediaApplication = TRUE / FALSE according to need of test.\27[0m")

	if(application.isMediaApplication == true) then
		print("\27[33mAll tests will be run for MEDIA application \27[0m")
	else
	 	print("\27[33mAll tests will be run for NON-MEDIA application \27[0m")
	end
	print("\27[33m================================================================================================================================\27[0m")
	-- End Precondition.1

	-- Begin Precondition.2
	-- Description: Delete policy table, app_info.dat and log files
	commonSteps:DeleteLogsFileAndPolicyTable()
	-- End Precondition.2

	-- Begin Precondition.3
	-- Description: removing user_modules/connecttest_OnButtonSubscription.lua
		function Test:Postcondition_remove_user_connecttest()
		  os.execute( "rm -f ./user_modules/connecttest_OnButtonSubscription.lua" )
		end
	-- Begin Precondition.3


	
	
---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Test block is not applicable, becuase notification is checked according to the sent message by SDL
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


---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

--=================================================================================--
--------------------------------Positive request check-------------------------------
--=================================================================================--
	--Begin Test suit PositiveRequestCheck
		commonFunctions:newTestCasesGroup("========== Test cases group: PositiveRequestCheck ==========")

	--Begin test case PositiveRequestCheck.1
		--Description: This test is intended to check positive cases when correct SubscribeButton is sent from mobile side
		--SDL sends HMI Notification with isSubscribed: TRUE

		--Requirement id in JAMA/or Jira ID: APPLINK-12241
		--Verification criteria:  SDL notifies HMI when CUSTOM_BUTTON is subscribed by default after each app registration
		
		function Test:AddNewSession()
			startSession(self)
		end
		
 		function Test:TC_OnAppRegistered_default_OnButtonSubscription() 
 			RegisterAppInterface(self)			
 		end
 	--End test case PositiveRequestCheck.1

 	--Begin test case PositiveRequestCheck.2
 		--Description: This test is intended to check positive cases when correct SubscribeButton is sent from mobile side
 		--SDL sends HMI Notification with isSubscribed: TRUE

 		--Requirement id in JAMA/or Jira ID: APPLINK-12241
 		--Verification criteria: SDL must notify HMI after the button is successfully subscribed for the given app - via 
 		--                       OnButtonSubscription (appID, buttonName, isSubscribed:true)
 		function Test:ActivateApp()
 			ActivateApplication(self)
 		end
		
 		if(application.isMediaApplication == true)
 		then
 			for i=1,#AllbuttonName do					
 				Test["TC_OnButtonSubscription_" .. tostring(AllbuttonName[i]).."_isSubscribed_TRUE"] = function(self)
 					SubscribeBtn(self, AllbuttonName[i])
 				end
 			end	
 		else
 			--non-media application
 			for i=1,#NonMediaButton do					
 				Test["TC_OnButtonSubscription_" .. tostring(NonMediaButton[i]).."_isSubscribed_TRUE"] = function(self)
 					SubscribeBtn(self, NonMediaButton[i])
 				end
 			end	
 		end		
 	--End test case PositiveRequestCheck.2


 	--Begin test case PositiveRequestCheck.3
 		--Description: This test is intended to check positive cases when correct SubscribeButton is sent from mobile side
 		--SDL sends HMI Notification with isSubscribed: FALSE

 		--Requirement id in JAMA/or Jira ID: APPLINK-12241
 		--Verification criteria: SDL must notify HMI after the button is successfully un-subscribed for the given app - via 
 		--                       OnButtonSubscription (appID, buttonName, isSubscribed:false)		
 		if(application.isMediaApplication == true)
 		then
 			for i=1,#AllbuttonName do					
 				Test["TC_OnButtonSubscription_" .. tostring(AllbuttonName[i]).."_isSubscribed_FALSE"] = function(self)
 					UnSubscribeBtn(self, AllbuttonName[i])
 				end
 			end	
 		else
 			-- non-media application
 			for i=1,#NonMediaButton do					
 				Test["TC_OnButtonSubscription_" .. tostring(NonMediaButton[i]).."_isSubscribed_FALSE"] = function(self)
 					UnSubscribeBtn(self, NonMediaButton[i])
 				end
 			end	
 			
 		end		
 	--End test case PositiveRequestCheck.3


 	--End Test suit PositiveRequestCheck

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

 	--=================================================================================--
 	---------------------------------Negative request check------------------------------
 	--=================================================================================--
 	--Begin Test suit NegativeRequestCheck
 	commonFunctions:newTestCasesGroup("========== Test cases group: NegativeRequestCheck ==========")
 		--------Checks-----------
 		-- outbound values
 		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
 		-- parameters with wrong type
 		-- invalid json


 		--Begin test case NegativeRequestCheck.1
 		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is REJECTED

 		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-14516, APPLINK-20148
 		--Verification criteria:  In case non-media app sends SubscribeButton (<name_of media button>) SDL must respond REJECTED result code to this mobile app.
 		--                        SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed

 		for i=1,#AllbuttonName do	
			
 			if(
 				application.isMediaApplication == false and
 				AllbuttonName[i] ~= "OK"
 				) 
 			then				
 				Test["TC_REJECTED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)

 					local strAppName = application.appName
 					--mobile side: sending SubscribeButton request
 					local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = AllbuttonName[i]})
				
		
 					--mobile side: expect SubscribeButton response
 					self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
				
 					--mobile side: expect notification
 					self.MobileSession1:ExpectNotification("OnHashChange",{})
 					:Times(0)

 					-- HMI side: expect OnButtonSubscription notification
 					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
 					:Times(0)

 					DelayedExp(1000)
 				end
 			end
 		end				
 		--End test case NegativeRequestCheck.1

		--Begin test case NegativeRequestCheck.2
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is IGNORED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20158, APPLINK-20122, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		--                         SDL must send OnButtonSubscription to HMI only in case button subscription status is changed.  

		if(application.isMediaApplication == true)
		then
			for i=1,#AllbuttonName do					
				Test["Precondition_IGNORED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)
					SubscribeBtn(self, AllbuttonName[i])
				end

				Test["TC_IGNORED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)
					local strAppName = application.appName
					
					--mobile side: sending SubscribeButton request
					local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = AllbuttonName[i]})

					--mobile side: expect SubscribeButton response
					self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
					
					--mobile side: expect notification
					self.MobileSession1:ExpectNotification("OnHashChange",{})
					:Times(0)

					--hmi side: expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
					:Times(0)

					DelayedExp(1000)
				end

				Test["Postcondition_IGNORED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)
					UnSubscribeBtn(self, AllbuttonName[i])
				end
			end	
		else
			-- non-media application 
			for i=1,#NonMediaButton do					
				Test["Precondition_IGNORED_SubscribedButton_" .. tostring(NonMediaButton[i]).."_NoNotification"] = function(self)
					SubscribeBtn(self, NonMediaButton[i])
				end
				Test["TC_IGNORED_SubscribedButton_" .. tostring(NonMediaButton[i]).."_NoNotification"] = function(self)
					local strAppName = application.appName
				
					--mobile side: sending SubscribeButton request
					local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = NonMediaButton[i]})

					--mobile side: expect SubscribeButton response
					self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
					
					--mobile side: expect notification
					self.MobileSession1:ExpectNotification("OnHashChange",{})
					:Times(0)

					--hmi side: expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
					:Times(0)

					DelayedExp(1000)
				end

				Test["Postcondition_IGNORED_SubscribedButton_" .. tostring(NonMediaButton[i]).."_NoNotification"] = function(self)
					UnSubscribeBtn(self, NonMediaButton[i])
				end
			end	
		end		
		--End test case NegativeRequestCheck.2

		--Begin test case NegativeRequestCheck.3
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is IGNORED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20158, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		Test["TC_IGNORED_SubscribedButton_CUSTOM_BUTTON_NoNotification"] = function(self)
			local strAppName = application.appName
				
			--mobile side: sending SubscribeButton request
			local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = "CUSTOM_BUTTON"})

			--mobile side: expect SubscribeButton response
			self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
					
			--mobile side: expect notification
			self.MobileSession1:ExpectNotification("OnHashChange",{})
			:Times(0)

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(1000)
		end
		--End test case NegativeRequestCheck.3

		--Begin test case NegativeRequestCheck.4
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of UnsubscribeButton is IGNORED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20179, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		if(application.isMediaApplication == true)
		then
			for i=1,#AllbuttonName do
				Test["TC_IGNORED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)
					local strAppName = application.appName
					
					--mobile side: sending SubscribeButton request
					local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = AllbuttonName[i]})

					--mobile side: expect SubscribeButton response
					self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
					
					--mobile side: expect notification
					self.MobileSession1:ExpectNotification("OnHashChange",{})
					:Times(0)

					--hmi side: expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
					:Times(0)

					DelayedExp(1000)
				end
			end
		else
			-- non-media application
			for i=1,#NonMediaButton do
				Test["TC_IGNORED_SubscribedButton_" .. tostring(NonMediaButton[i]).."_NoNotification"] = function(self)
					local strAppName = application.appName
				
					--mobile side: sending SubscribeButton request
					local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = NonMediaButton[i]})

					--mobile side: expect SubscribeButton response
					self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
					
					--mobile side: expect notification
					self.MobileSession1:ExpectNotification("OnHashChange",{})
					:Times(0)

					--hmi side: expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
					:Times(0)
					DelayedExp(1000)
				end
			end
		end

-- 		--End test case NegativeRequestCheck.4


		--Begin test case NegativeRequestCheck.5
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is INVALID_DATA

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-16739, APPLINK-16118, APPLINK-16115, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		Test["TC_INVALID_DATA_SubscribedButton_NoNotification"] = function(self)
			local strAppName = application.appName
					
			--mobile side: sending SubscribeButton request
			local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = "xzx"})

			--mobile side: expect SubscribeButton response
			self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
					
			--mobile side: expect notification
			self.MobileSession1:ExpectNotification("OnHashChange",{})
			:Times(0)

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(1000)
		end

		--End test case NegativeRequestCheck.5

		--Begin test case NegativeRequestCheck.6
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of UnsubscribeButton is INVALID_DATA

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-16739, APPLINK-16118, APPLINK-16115, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		Test["TC_INVALID_DATA_UnsubscribeButton_NoNotification"] = function(self)
			local strAppName = application.appName
					
			--mobile side: sending SubscribeButton request
			local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = "xzx"})

			--mobile side: expect SubscribeButton response
			self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
					
			--mobile side: expect notification
			self.MobileSession1:ExpectNotification("OnHashChange",{})
			:Times(0)

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(1000)
		end

		--End test case NegativeRequestCheck.6

		--Begin test case NegativeRequestCheck.7
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is UNSUPPORTED_RESOURCE

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20028, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		Test["TC_UNSUPPORTED_RESOURCE_SubscribedButton_NoNotification"] = function(self)
			local strAppName = application.appName
		    			
			--mobile side: sending SubscribeButton request
			local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = "SEARCH"})

			--mobile side: expect SubscribeButton response
			self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
					
			--mobile side: expect notification
			self.MobileSession1:ExpectNotification("OnHashChange",{})
			:Times(0)

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(1000)
		end

 		--End test case NegativeRequestCheck.7

 		--Begin test case NegativeRequestCheck.8
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of UnSubscribeButton is UNSUPPORTED_RESOURCE

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20028, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed

		Test["TC_UNSUPPORTED_RESOURCE_UnSubscribedButton_NoNotification"] = function(self)
			local strAppName = application.appName
		    			
			--mobile side: sending UnsubscribeButton request
			local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = "SEARCH"})
			
			--mobile side: expect UnsubscribeButton response
			self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
					
			--mobile side: expect notification
			self.MobileSession1:ExpectNotification("OnHashChange",{})
			:Times(0)

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(1000)
		end

 		--End test case NegativeRequestCheck.8

		function Test:UserExitApp()
			ExitApplication(self)
		end

		--Begin test case NegativeRequestCheck.9
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is DISALLOWED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-19314, APPLINK-20148
		--Verification criteria: Policy Table verification in state NONE. 
		--                       SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed

		for i=1,#AllbuttonName do
			Test["TC_DISALLOWED_SubscribedButton_" .. tostring(AllbuttonName[i]).."_NoNotification"] = function(self)
				local strAppName = application.appName
					
				--mobile side: sending SubscribeButton request
				local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = AllbuttonName[i]})

				--mobile side: expect SubscribeButton response
				self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
					
				--mobile side: expect notification
				self.MobileSession1:ExpectNotification("OnHashChange",{})
				:Times(0)

				--hmi side: expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
				:Times(0)
				DelayedExp(1000)
			end
		end

 		--End test case NegativeRequestCheck.9

		--Begin test case NegativeRequestCheck.10
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of UnsubscribeButton is DISALLOWED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-19314, APPLINK-20148
		--Verification criteria: Policy Table verification in state NONE
		--                       SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed

		for i=1,#AllbuttonName do
			Test["TC_DISALLOWED_UnsubscribedButton_NoNotification"] = function(self)
				local strAppName = application.appName
					
				--mobile side: sending SubscribeButton request
				local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = AllbuttonName[i]})

				--mobile side: expect SubscribeButton response
				self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
					
				--mobile side: expect notification
				self.MobileSession1:ExpectNotification("OnHashChange",{})
				:Times(0)

				--hmi side: expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
				:Times(0)

				DelayedExp(1000)
			end
		end
		--End test case NegativeRequestCheck.10


		--Begin test case NegativeRequestCheck.11
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when application is unregistered

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20195
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case application is unregistered via UnregisterAppInterface
		function Test:UnregisterAppInterface()
			local strAppName = application.appName

			local cid = self.MobileSession1:SendRPC("UnregisterAppInterface",{})

			-- mobile side: expect UnregisterAppInterface response
			self.MobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})

			--hmi side: expected  BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["strAppName"], unexpectedDisconnect = false})

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)
		end 
		--End test case NegativeRequestCheck.11

		--Begin test case NegativeRequestCheck.12
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of SubscribeButton is APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-16746, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		for i=1,#AllbuttonName do
			Test["TC_APP_NOT_REGISTERED_SubscribedButton_NoNotification"] = function(self)
				local strAppName = application.appName
					
				--mobile side: sending SubscribeButton request
				local cid = self.MobileSession1:SendRPC("SubscribeButton",{buttonName = AllbuttonName[i]})

				--mobile side: expect SubscribeButton response
				self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
					
				--mobile side: expect notification
				self.MobileSession1:ExpectNotification("OnHashChange",{})
				:Times(0)

				--hmi side: expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
				:Times(0)

				DelayedExp(1000)
			end
		end
		--End test case NegativeRequestCheck.12


		--Begin test case NegativeRequestCheck.13
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when result of UnsubscribeButton is APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-16746, APPLINK-20148
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case the related app's subscription or unsubscription request failed
		for i=1,#AllbuttonName do
			Test["TC_APP_NOT_REGISTERED_UnSubscribedButton_NoNotification"] = function(self)
				local strAppName = application.appName
					
				--mobile side: sending SubscribeButton request
				local cid = self.MobileSession1:SendRPC("UnsubscribeButton",{buttonName = AllbuttonName[i]})

				--mobile side: expect SubscribeButton response
				self.MobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
					
				--mobile side: expect notification
				self.MobileSession1:ExpectNotification("OnHashChange",{})
				:Times(0)

				--hmi side: expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
				:Times(0)

				DelayedExp(1000)
			end
		end
		--End test case NegativeRequestCheck.13

		--Begin test case NegativeRequestCheck.14
		--Description: This test is intended to check absence of OnButtonSubscription notification from HMI when application is unexpected disconnected

		--Requirement id in JAMA/or Jira ID: APPLINK-12241, APPLINK-20195
		--Verification criteria:   SDL must NOT send OnButtonSubscription to HMI in case application is closed unexpectedly.
		function Test:Precondition_OnAppRegistered() 
			RegisterAppInterface(self)
		end

		--ToDo: Shall be removed when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
		function Test:Precondition_ReRegisterApplication() 
			RegisterAppInterface(self)
		end

		function Test:TC_CloseApplication()
			local strAppName = application.appName

			self.MobileSession1:Stop()
			
			--hmi side: expected  BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[strAppName], unexpectedDisconnect = true})

			--hmi side: expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {})
			:Times(0)

			DelayedExp(5000)
		end
		--End test case NegativeRequestCheck.14

	--End Test suit NegativeRequestCheck
	----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------
	-- Test block is not applicable, becuase notification is checked according to the sent 
	-- message by SDL
	-- Result code of SubscribeButton / UnsubscribeButton is checked in separate script
	-- Check all uncovered pairs resultCodes+success
	

----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------
	-- Test block is not applicable, becuase notification OnButtonSubscription does not 
	-- provoke other HMI notifications

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------
	-- Test block is not applicable, because user's action(s) provoke results for 
	-- SubscribeButton / UnsubscribeButton


----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	-- Test block is not applicable, becuase notification is checked according to the sent 
	-- message by SDL
	-- Behavior of SubscribeButton / UnsubscribeButton in Different HMIStatus is checked in 
	-- separate script 
	

		
	
--Postconditions
function Test:Postcondition_StopSDL_IfItIsStillRunning()
	print("----------------------------------------------------------------------------------------------")
	StopSDL()
end
	
return Test