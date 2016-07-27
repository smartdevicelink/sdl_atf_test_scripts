----------------------------------------------------------------------------------------------------------
--These TCs are created by APPLINK-8535
----------------------------------------------------------------------------------------------------------
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

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
----------------------------------- Common Fuctions------------------------------------------
function Test:onEventChanged(enable,hmilevel,case)
	
	--hmi side: send OnEventChanged (ON/OFF) notification to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= enable, eventName="EMERGENCY_EVENT"})
	
	--Set default HMILevel = FULL
	if hmilevel ==nil then hmilevel= "FULL" end

	if enable==true then
	
		--Case: There are 3 applications
		if case== nil then
	
			--mobile side: expected OnHMIStatus 
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
		--Case: There is one application
		if case== 1 then 
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
	end
	
	if enable==false then
	
		--Case: There are 3 applications
		if case==nil then 
			--mobile side: expected OnHMIStatus 	
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end 
		
		--Case: There is one application
		if case== 1 then 
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end
	end
	
end
-----------------------------------------------------------------------------------------

function Test:change_App_Params(appName,appType,isMedia)

   if appName == config.application1.registerAppInterfaceParams.appName then
	
		config.application1.registerAppInterfaceParams.isMediaApplication = isMedia
		
		if appType=="" then 
			config.application1.registerAppInterfaceParams.appHMIType = nil 
		else 
			config.application1.registerAppInterfaceParams.appHMIType = appType
		end
	end
	
	
	if appName == config.application2.registerAppInterfaceParams.appName then
	
		config.application2.registerAppInterfaceParams.isMediaApplication=isMedia
		
		if appType=="" then 
			config.application2.registerAppInterfaceParams.appHMIType = nil 
		else 
		
			config.application2.registerAppInterfaceParams.appHMIType = appType
		end
    end
	 
	if appName == config.application3.registerAppInterfaceParams.appName then 
	
		config.application3.registerAppInterfaceParams.isMediaApplication = isMedia
		
	    if appType=="" then 
			config.application3.registerAppInterfaceParams.appHMIType = nil
  		else 
		
			config.application3.registerAppInterfaceParams.appHMIType = appType
		end
	end
end
-----------------------------------------------------------------------------------------

function Test:registerAppInterface2()
		--mobile side: sending request 
		local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = config.application2.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID					
			end)

		--mobile side: expect response
		self.mobileSession1:ExpectResponse(CorIdRegister, 
			{
				syncMsgVersion = config.syncMsgVersion
			})
			:Timeout(2000)

		--mobile side: expect notification
		self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Timeout(2000)
end	
------------------------------------------------------------------------------------------------

function Test:registerAppInterface3()

		--mobile side: sending request 
		local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)

		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
					{
						appName = config.application3.registerAppInterfaceParams.appName
					}
			})
			:Do(function(_,data)
				self.applications[config.application3.registerAppInterfaceParams.appName] = data.params.application.appID					
		end)

		--mobile side: expect response
		self.mobileSession2:ExpectResponse(CorIdRegister, 
			{
				syncMsgVersion = config.syncMsgVersion
			})
			:Timeout(2000)

		--mobile side: expect notification
		self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:Timeout(2000)
end		
------------------------------------------------------------------------------------------------

function Test:unregisterAppInterface(appName) 

	if appName == config.application2.registerAppInterfaceParams.appName then
	
		local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
		
		self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		
	end 
	
	if appName == config.application3.registerAppInterfaceParams.appName then
	
		local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
		
		self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		
	end 
	
	if appName == config.application1.registerAppInterfaceParams.appName then
	
		local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
		
		self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		
	end 
	
end
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("****************************** Preconditions ******************************")
	
	--1.Delete Policy and Log Files
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--2. Unregister app
	commonSteps:UnregisterApplication()

	--3.Set new value for app1
	function Test:Change_App1_Params()
		--Chaneg app1's params
		self:change_App_Params(config.application1.registerAppInterfaceParams.appName, {"MEDIA"}, true)
	end
	
	--4.Register app1
	commonSteps:RegisterAppInterface()
	
	--5. Activate application
	commonSteps:ActivationApp()
	
	--6. Create second session
	function Test:Precondition_SecondSession()
	
		-- Connected expectation
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
		
	end		
	
	--7. Create third Session
	function Test:Precondition_ThirdSession()
		--mobile side: start new session
		self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession2:StartService(7)
	end	

	--8. Changed app2 to Non Media Navigation
	function Test:Register_Non_Media_Navigation_App()
		 --Change app2's params
		self:change_App_Params(config.application2.registerAppInterfaceParams.appName, {"NAVIGATION"}, false)
		
		--Register app2
		self:registerAppInterface2()
	end
	
	--9. Register app3
	function Test:Register_Non_Media_Communication_App()
		 --Change app2's params
		self:change_App_Params(config.application3.registerAppInterfaceParams.appName, {"COMMUNICATION"}, false)
		
		--Register app2
		self:registerAppInterface3()
	end
	
	--10. Activate app2
	function Test:Activate_App2()
	
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end
	
	--11. Activate app3
	function Test:Activate_App3()
	
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)
		
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end
	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Not Applicable


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
	--Begin test suit HMIResponseCheck
	--Description: Verify OnEventChanged():
		--with valid "enabled" values (true/false)
		--without "enabled" value
		--with "enabled" is invalid/not existed/empty/wrongtype
			
		--Write TEST BLOCK III to ATF log
		commonFunctions:newTestCasesGroup("****************************** TEST BLOCK III: Check normal cases of HMI notification ******************************")							
				
			--Begin test case HMIResponseCheck3.1
		    --Description: This test is intended to check when HMI response with "enabled":true
			
				--Verification criteria: SDL must change the AudioStreamingState of all apps to NOT_AUDIBLE in case SDL receives notification OnEventChanged(ON,Emergency_Event) from HMI.
				
				function Test:Emergency_Event_ON_AudioStreamingState_NOT_AUDIBLE()
					self:onEventChanged(true, "LIMITED")
				end
				
			--End test case HMIResponseCheck3.1
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMIResponseCheck3.2
			--Description: This test is intended to check when HMI response with "enabled":false
			
				--Verification criteria: SDL must return AudioStreamingState of all apps to previous state(AUDIBLE) in case SDL receives notification notification Emergency_Event(OFF) from HMI.
				
				function Test:Emergency_Event_OFF_AudioStreamingState_AUDIBLE()
					self:onEventChanged(false, "LIMITED")
				end
				
			--End test case HMIResponseCheck3.2
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMIResponseCheck3.3
		    --Description: This test is intended to check when HMI response with "enabled" is valid/invalid/not existed/empty/wrongtype
			
				--Verification criteria: SDL doesn't change the AudioStreamingState of all apps to NOT_AUDIBLE 
				
				local InvalidValues = {	{value = nil, name = "IsMissed"},
								{value = "", name = "IsEmtpy"},
								{value = "ANY", name = "NonExist"},
								{value = 123, name = "WrongDataType"}}
								
					for i = 1, #InvalidValues  do
						Test["Emergency_Event_isActive_" .. InvalidValues[i].name .."_IsIgnored"] = function(self)
						
							commonTestCases:DelayedExp(1000) 
							--hmi side: send OnExitApplication
							self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= InvalidValues[i].value, eventName="EMERGENCY_EVENT"})
				
							
							--mobile side: not expected OnHMIStatus 
							self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(0)
							
							self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(0)
							
							self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(0)
							
						end
					end
				
			--End test case HMIResponseCheck3.3
				
			---------------------------------------------------------------------------------------------------------
		
	--End Test suit PositiveRequestCheck	
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK IV--------------------------------------
----------------------------------Check special cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
	--Begin test suit HMISpecialResponseCheck
	--Description: Verify OnEventChanged():
		--InvalidJsonSyntax
		--InvalidStructure
		--Fake Params 
		--Fake Parameter Is From Another API
		--Missed mandatory Parameters
		--Missed All PArameters
		--Several Notifications with the same values
		--Several otifications with different values
		
		--Write TEST BLOCK IV to ATF log
		commonFunctions:newTestCasesGroup("****************************** TEST BLOCK IV: Check special cases of HMI notification ******************************")							
			
			--Begin test case HMISpecialResponseCheck4.1
		    --Description: This test is intended to check when HMI sends notification with InvalidJsonSyntax
			
				--Verification criteria: SDL doesn't change the AudioStreamingState of all apps to NOT_AUDIBLE 
				
				function Test:Emergency_Event_ON_InvalidJSonSyntax()
					
					commonTestCases:DelayedExp(1000) 
					
					--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMERGENCY_EVENT"}}')
					self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMERGENCY_EVENT"}}')
					
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)			
					
				end
				
			--End test case HMISpecialResponseCheck4.1
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMISpecialResponseCheck4.2
		    --Description: This test is intended to check when HMI sends notification with InvalidStructure
			
				--Verification criteria: SDL doesn't change the AudioStreamingState of all apps to NOT_AUDIBLE 
				
		        function Test:Emergency_Event_ON_InvalidStructure()
					
					commonTestCases:DelayedExp(1000) 
					--method is moved into params parameter
					--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMERGENCY_EVENT"}}')
					self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnEventChanged","isActive":true,"eventName":"EMERGENCY_EVENT"}}')
					  
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)	
					
				end
			--End test case HMISpecialResponseCheck4.2
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMISpecialResponseCheck4.3
		    --Description: This test is intended to check when HMI sends notification with fake param
			
				--Verification criteria: SDL must change the AudioStreamingState of all apps to NOT_AUDIBLE 
				
		        function Test:Emergency_Event_ON_FakeParams()
					
					--HMI side: sending BasicCommunication.OnEventChanged with fake param
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMERGENCY_EVENT","fakeparam":123}}')
					  
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					
				end
				
				--Verification criteria: SDL must change the AudioStreamingState of all apps to AUDIBLE 
				
				function Test:PostCondition_Emergency_Event_OFF()
				
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					  
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

				end
				
			--End test case HMISpecialResponseCheck4.3
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMISpecialResponseCheck4.4
		    --Description: This test is intended to check when HMI sends notification without any params
			
				--Verification criteria: SDL doesn't change the AudioStreamingState of all apps to NOT_AUDIBLE 
				function Test:Emergency_Event_ON_Without_Any_Params()
					
					commonTestCases:DelayedExp(1000) 
					--HMI side: sending BasicCommunication.OnEventChanged without any param
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{}}')
					 
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					
					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					
				end
			--End test case HMISpecialResponseCheck4.4
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMISpecialResponseCheck4.5
		    --Description: This test is intended to check when HMI sends the same several notifications to SDL
			
				--Verification criteria: SDL must change the AudioStreamingState of all apps to NOT_AUDIBLE 
				function Test:Several_Emergency_Event_ON_To_SDL()
					
					--HMI side: sending several BasicCommunication.OnEventChanged without any param
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
					
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					
				end
				
				--Verification criteria: SDL must change the AudioStreamingState of all apps to AUDIBLE 
				function Test:Several_Emergency_Event_OFF_To_SDL()
					
					--HMI side: sending several BasicCommunication.OnEventChanged without any param
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

					
				end
			--End test case HMISpecialResponseCheck4.5
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case HMISpecialResponseCheck4.6
		    --Description: This test is intended to check when HMI sends notification with different values
			
				--Verification criteria: SDL must change the AudioStreamingState of all apps to NOT_AUDIBLE 
				
				function Test:Several_Emergency_Event_WithDifferentValues_To_SDL()
			
					--HMI side: sending several BasicCommunication.OnEventChanged without any param
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
						
					--mobile side: not expected OnHMIStatus 
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
																	:Times(3)
																	
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
																	:Times(3)
	
					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
																	:Times(3)
				end
				
			--Begin test case HMISpecialResponseCheck4.6
			
			function Test:Postcondition_Unregister_All_Apps()
			
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
				
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
				self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
				
				local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
				self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
				
				local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
				self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
				
			end
		
				
	--End Test suit PositiveRequestCheck	
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Not Applicable
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	

--Begin Test suit SequenceChecks
--Description: TC's checks SDL behavior by processing
		
		--Write TEST BLOCK VI to ATF log
		commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VI: Sequence with emulating of user's action(s) ******************************")
			
			--Begin test case SequenceChecks6.1
		    --Description: This test is intended to check that SDL changes the AudioStreamingState application in case SDL receives OnEventChanged(ON/OFF) from HMI
			
			--Requirement id in JAMA/or Jira ID: APPLINK-16838
			--Verification: SDL must change AudioStreamingState to NOT_AUDIBLE when receives OnEventChanged(Emergency_Event, isActive= true) and returns AUDIBLE when received OnEventChanged(Emergency_Event, isActive= false)
			
				commonFunctions:newTestCasesGroup("********************APPLINK-16838_TC_SDL_changes_audio_state(playing_audio)_upon_Emergency_Event******************")
				--Register app
				commonSteps:RegisterAppInterface("APPLINK_16838_RegisterAppInterface")
				
				--Activate app
				commonSteps:ActivationApp(_, "APPLINK_16838_ActivationApp")
			
				--Send OnEventChanged(Emergency_Event, isActive= true) to SDL
				function Test:APPLINK_16838_Emergency_Event_ON()
				
					self:onEventChanged(true, "FULL",1)
					
				end
				
				--Send OnEventChanged(Emergency_Event, isActive= fase) to SDL
				function Test:APPLINK_16838_Emergency_Event_OFF()
				
					self:onEventChanged(false, "FULL",1)
				
				end
			
			--End test case SequenceChecks6.1
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case SequenceChecks6.2
		    --Description: This test is intended to check that SDL changes the AudioStreamingState application in case SDL receives OnEventChanged(Emergency_Event, isActive= true/false)from HMI while phone call
			
				--Requirement id in JAMA/or Jira ID: APPLINK-16840
				--Verification: SDL must change AudioStreamingState to NOT_AUDIBLE when receives OnEventChanged(Emergency_Event, isActive= true) and returns AUDIBLE when received OnEventChanged(Emergency_Event, isActive= false) when it is in VRSESSION

				commonFunctions:newTestCasesGroup("********************APPLINK-16840_TC_SDL_changes_audio_state(OnPhoneCall)_upon_Emergency_Event******************")
				
				--Start Phone Call
				function Test:Start_PhoneCall()
				
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], reason = "PHONEMENU"})
					
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					
				end
				
				--Send OnEventChanged(Emergency_Event, isActive= true) to SDL
				function Test:Emergency_Event_ON_While_PhoneCall()
				
					self:onEventChanged(true, "LIMITED", 1)
				
				end
					
				--Send OnEventChanged(Emergency_Event, isActive= false) to SDL
				function Test:Emergency_Event_OFF_While_PhoneCall()
				
					self:onEventChanged(false, "LIMITED", 1)
							
				end
				
			--End test case SequenceChecks6.2
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case SequenceChecks6.3
		    --Description: This test is intended to check that SDL changes the AudioStreamingState application in case SDL receives Emergency_Event(ON/OFF) from HMI in case app is at VRSESSION
			
				--Requirement id in JAMA/or Jira ID: APPLINK-16841
				--Verification: SDL must change AudioStreamingState to NOT_AUDIBLE when receives Emergency_Event(ON) and returns AUDIBLE when received Emergency_Event(OFF)
				
				commonFunctions:newTestCasesGroup("********************APPLINK-16841_TC_SDL_changes_audio_state(VR_session)_upon_Emergency_Event******************")

				commonSteps:ActivationApp(_, "Step1_Precondition_Activation_App")
				
				
				--Start VRSESSION
				function Test:Step2_Start_VRSESSION()
					
					--hmi side: send OnSystemContext
					self.hmiConnection:SendNotification("VR.Started")
					self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
					
					--mobile side: SDL send two notifications to mobile app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
																		{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
																		:Times(2)
					
				end
				
				--Send Emergency_Event(ON) to SDL
				function Test:Step3_Send_Emergency_Event_ON_While_VRSESSION()
					
					commonTestCases:DelayedExp(1000) 
					--hmi side:send Emergency_Event (ON) notification to SDL
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})
										
					--mobile side: SDL doesn't send any notifications to mobile app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					
				end
				
				--Stop VRSESSION
				function Test:Stop_VRSESSION()
					
					--hmi side: send OnSystemContext
					self.hmiConnection:SendNotification("VR.Stopped")
					self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MAIN",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
					
					--mobile side: SDL send 1 notification to mobile app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
											
				end
					
				--Send Emergency_Event(OFF) to SDL
				function Test:Send_Emergency_Event_OFF_After_Stopped_VRSESSION() 
				
				    self:onEventChanged(false, "FULL", 1)
				
				end
				
			--End test case SequenceChecks6.3
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case SequenceChecks6.4
		    --Description: This test is intended to check that SDL changes the AudioStreamingState application in case SDL receives Emergency_Event(ON/OFF) from HMI during tts session
			
				--Requirement id in JAMA/or Jira ID: APPLINK-16842
				--Verification: SDL must change AudioStreamingState to NOT_AUDIBLE when receives Emergency_Event(ON) and returns AUDIBLE when received Emergency_Event(OFF)
				
				commonFunctions:newTestCasesGroup("********************APPLINK-16842_TC_SDL_changes_audio_state(tts_session)_upon_Emergency_Event******************")
				
				local CorIdAlert
				local AlertId
				local SpeakId
				
				--Send Emergency_Event(ON) during Alert()
				function Test:Send_Alert() 

						--mobile side: Alert request 	
						CorIdAlert = self.mobileSession:SendRPC("Alert",
											{
												alertText1 = "alertText1",
												alertText2 = "alertText2",
												alertText3 = "alertText3",
												ttsChunks = 
												{ 
													
													{ 
														text = "TTSChunk",
														type = "TEXT",
													} 
												}, 
												duration = 5000,
												playTone = false,
												progressIndicator = true
											})

						
						--hmi side: UI.Alert request 
						EXPECT_HMICALL("UI.Alert", 
									{	
										alertStrings = 
										{
											{fieldName = "alertText1", fieldText = "alertText1"},
											{fieldName = "alertText2", fieldText = "alertText2"},
											{fieldName = "alertText3", fieldText = "alertText3"}
										},
										alertType = "BOTH",
										duration = 5000,
										progressIndicator = true
									})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="ALERT"})
								
								--store id for response in next Test.
								AlertId = data.id

							end)
						
						--hmi side: TTS.Speak request 
						EXPECT_HMICALL("TTS.Speak", 
									{	
										ttsChunks = 
										{ 
											
											{ 
												text = "TTSChunk",
												type = "TEXT"
											}
										},
										speakType = "ALERT"
									})
							:Do(function(_,data)
							
								--store id for response in next Test.
								SpeakId = data.id 
								
								local function TTS_Started()
									self.hmiConnection:SendNotification("TTS.Started")
								end

								RUN_AFTER(TTS_Started, 500)

							end)
							:ValidIf(function(_,data)
								if #data.params.ttsChunks == 1 then
									return true
								else
									print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
									return false
								end
							end)
					 
						--mobile side: Expected OnHMIStatus() notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
								{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
							:Times(2)
														
				end

				--Send Emergency_Event(ON) during Alert()
				function Test:Send_Emergency_Event_ON_During_Alert() 
						
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})	
					
					--mobile side: Expected OnHMIStatus() notification
					EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "ALERT",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
					
								
				end
				
				--Send Emergency_Event(ON) during Alert()
				function Test:HMI_Response_Alert() 

					
					--UI response
					self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
					
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="MAIN"})
					--SendOnSystemContext(self,"MAIN")


					--TTS response
					self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

					self.hmiConnection:SendNotification("TTS.Stopped")
					
					--HMI receiced StopSpeaking
				    EXPECT_HMICALL("TTS.StopSpeaking")
					:Do(function(_,data)
							 						
								 --TTS StopSpeaking response
								self.hmiConnection:SendResponse(data.id,"TTS.StopSpeaking", "SUCCESS",{})
							end)
					
					--mobile side: Expected OnHMIStatus() notification
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})

					--mobile side: Alert response
					EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
							
				end
				
				
				--Send Emergency_Event(OFF) 
				function Test:Send_Emergency_Event_OFF()
				
					self:onEventChanged(false, "FULL", 1)
				
				end
				
			--End test case SequenceChecks6.4
			---------------------------------------------------------------------------------------------------------
			
			--Begin test case SequenceChecks6.5
		    --Description: This test is intended to check that SDL changes the AudioStreamingState only of "audible" application.
			
				--Requirement id in JAMA/or Jira ID: APPLINK-16843
				--Verification: SDL must change AudioStreamingState only of "audible" application to NOT_AUDIBLE when receives Emergency_Event(ON) 
				
				commonFunctions:newTestCasesGroup("********************APPLINK-16843_TC_SDL_changes_audio_state_for_audible_app_only******************")
				
				--Register second media app
				function Test:Register_Second_Media_App()
					 --Change app2's params
					self:change_App_Params(config.application2.registerAppInterfaceParams.appName, {"MEDIA"}, true)
					
					--Register app2
					self:registerAppInterface2()
				end
				
				--Send Emergency_Event(ON) and SDL must change AudioStreamingState only of first application to NOT_AUDIBLE 
				function Test:Send_Emergency_Event_ON()
					
					commonTestCases:DelayedExp(1000) 
					
					self:onEventChanged(true, "FULL", 1)
					
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(0)
					
				end
				
				--PostCondition: Unregister all apps
				function Test:Postcondition_Unregister_All_Apps()
			
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMERGENCY_EVENT"})
					
					local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
					self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)
					
					local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)
				
				end
		
			--End test case SequenceChecks6.5
			---------------------------------------------------------------------------------------------------------
			
--End Test suit SequenceChecks
----------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

	--Begin Check with Different HMIStatus
	--Description: 	Check when HMILevel is
		--LIMITED: Already check by some TCs such as HMIResponseCheck3.1 and SequenceChecks6.2
		--NONE: Already check by SequenceChecks6.5 (APPLINK-16843)
		--BACKGROUND
	
		--Write TEST BLOCK VII to ATF log
		commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VII: Check with Different HMIStatus ******************************")				

		--Begin test case HMIStatus7.1
		--Description: This test is intended to check that SDL changes the AudioStreamingState only of "audible" application.

			--Verification: SDL must change AudioStreamingState only of "audible" application to NOT_AUDIBLE when receives Emergency_Event(ON) 
			
		
            --Precondition1: Register the first app
			commonSteps:RegisterAppInterface(_, "Case_Background_RegisterAppInterface")
			
			--Precondition2: Activate the first app
			commonSteps:ActivationApp(_, "Case_Background_ActivationApp")
			
			--Precondition3: Activate the second media app
			function Test:Precondition_Register_Second_Media_App()
				 --Change app2's params
				self:change_App_Params(config.application2.registerAppInterfaceParams.appName, config.application1.registerAppInterfaceParams.appHMIType, config.application1.registerAppInterfaceParams.isMediaApplication)
				
				--Register app2
				self:registerAppInterface2()
			end
			
			--Precondition4: Activate the second media app, the first app is changed to Background
			function Test:Precondition_Change_App1_To_BACKGROUND()
			
			    local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
				EXPECT_HMIRESPONSE(rid)
					:Do(function(_,data)
							if data.result.code ~= 0 then
							quit()
							end
					end)
		
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
								
			end
			
			--Send BasicCommunication.OnEventChanged(isActive= true, eventName="EMERGENCY_EVENT)
			function Test:Emergency_Event_In_BACKGROUND()
							
				--hmi side: send OnEventChanged(Emergency_Event, isActive= true) notification to SDL
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMERGENCY_EVENT"})	
				
				--nHMIStatus notification is sent to FULL app
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				
				--Expectation: OnHMIStatus notification is not sent to BACKGROUND app
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(0)
				commonTestCases:DelayedExp(1000) 
				
				
			end
		--End test case Different HMIStatus7.1
		

	--End Test suit Different HMIStatus
	
return Test