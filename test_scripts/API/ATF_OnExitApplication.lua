---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Created date: 03/Nov/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

require('user_modules/AppTypes')


	---------------------------------------------------------------------------------------------
	-------------------------------------------Preconditions-------------------------------------
	---------------------------------------------------------------------------------------------

	commonSteps:DeleteLogsFileAndPolicyTable()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp(_, "Preconditions_ActivationApp_1")
	
	--2. Get appID Value on HMI side
	--Get_HMI_AppID("Get_HMI_AppID_1")


	--3. Update policy table
	local PermissionLinesForBase4 = 
[[					"OnExitApplication": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  },
					  "GetDTCs": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  },
					  "AddCommand": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  },
					  "OnCommand": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  },]]
		
	
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnExitApplication", "GetDTCs", "AddCommand", "OnCommand"})	
	local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnExitApplication", "GetDTCs", "AddCommand", "OnCommand"})	

	--testCasesForPolicyTable:updatePolicy(PTName)
	testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
	
		


----------------------------------------------------------------------------------------------
--PART1: Common test cases for OnExitApplication requirements: 
		--SDLAQ-CRS-885: OnExitApplication(USER_EXIT) moves the app to NONE
		--SDLAQ-CRS-888: DRIVER_DISTRACTION_VIOLATION
		--SDLAQ-CRS-3100: OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION, appID)
----------------------------------------------------------------------------------------------

local function part1()

	APIName = "OnExitApplication" -- set API name
	Apps = {}
	Apps[1] = {}
	Apps[1].storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
	Apps[1].appName = config.application1.registerAppInterfaceParams.appName 


	if commonFunctions:isMediaApp() then
		AudioStreamingState = "AUDIBLE"
	else
		AudioStreamingState = "NOT_AUDIBLE"
	end

	local function Get_HMI_AppID(TestCaseName)
		if TestCaseName == nil then
			TestCaseName = Get_HMI_AppID
		end
		
		Test[TestCaseName] = function(self)
			Apps[1].appID = self.applications[Apps[1].appName]
		end
	end

	local function Open_UIMenu(TestCaseName)		
		Test[TestCaseName] = function(self)
			--hmi side: send OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MENU"})
			
			--mobile side: expected OnHMIStatus 
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = AudioStreamingState})
		end
	end	

	local function Select_OnExitApplication_USER_EXIT(TestCaseName)		
		Test[TestCaseName] = function(self)
			--hmi side: send OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID})
			
			--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MENU", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		end
	end

	local function Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION(TestCaseName)	
		
		Test[TestCaseName] = function(self)
								
			--hmi side: send OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "DRIVER_DISTRACTION_VIOLATION", appID = Apps[1].appID})

			--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MENU", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		end
	end

	local function Close_UIMenu(TestCaseName)		
		Test[TestCaseName] = function(self)
			--hmi side: send OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MAIN", appID = Apps[1].appID})
			
			--mobile side: expected OnHMIStatus 
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		end
	end

	local function Open_VRMenu(TestCaseName)	
		Test[TestCaseName] = function(self)
		
			commonTestCases:DelayedExp(1000)
								
			--hmi side: send OnSystemContext
			self.hmiConnection:SendNotification("VR.Started")
			self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION"})
			
			--mobile side: SDL does not send OnHMIStatus to NONE hmi level app
			EXPECT_NOTIFICATION("OnHMIStatus", {})
			:Times(0)
		end
	end

	local function Select_VRSynonym(TestCaseName)	
		Test[TestCaseName] = function(self)
								
			local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = Apps[1].appID})
			self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MAIN"})
			
			EXPECT_HMIRESPONSE(cid)
				
			--mobile side: expected OnHMIStatus 
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
		
		end
	end

	local function Close_VRMenu(TestCaseName)		
		Test[TestCaseName] = function(self)
		
			self.hmiConnection:SendNotification("VR.Stopped")
			
			--mobile side: expected OnHMIStatus 
			EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = AudioStreamingState})
		end
	end	
		

	local function OnExitApplication_reason_UNAUTHORIZED_TRANSPORT_REGISTRATION()	
	

		function Test:Precondition_AddCommand_1()
					
			--mobile side: sending AddCommand request
			local cid = self.mobileSession:SendRPC("AddCommand",
													{
														cmdID = 1,
														menuParams = 	
														{ 
															menuName ="Command1_onMenu1"
														}, 
														vrCommands = 
														{ 
															"Command1_OnVR",
															"Command2_OnVR"
														}
													})
													
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = 1,
								menuParams = 
								{ 
									menuName ="Command1_onMenu1"
								}
							})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
				
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = 1,
								type = "Command",
								vrCommands = 
								{
									"Command1_OnVR",
									"Command2_OnVR"
								}
							})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect AddCommand response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		
		end

		function Test:OnExitApplication_reason_UNAUTHORIZED_TRANSPORT_REGISTRATION()
			
			commonTestCases:DelayedExp(1000)
			
			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("GetDTCs", {ecuName = 2, dtcMask = 3})

			--hmi side: expect VehicleInfo.GetDTCs request 
			EXPECT_HMICALL("VehicleInfo.GetDTCs", {ecuName = 2, dtcMask = 3})
			:Do(function(_,data)
			
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = Apps[1].appID})
				
				local ID = data.id
				
				function to_run()
					--hmi side: sending response		
					self.hmiConnection:SendResponse(ID, data.method, "SUCCESS", {ecuHeader = 2, dtc = {"line 0","line 1","line 2"}})
				end
				
				RUN_AFTER(to_run, 2000)
				
			end)

			
			--mobile side: expected OnAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
						
			--hmi side: expected  BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
			
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", ecuHeader = 2, dtc = {"line 0","line 1","line 2"}})
			:Times(0)

		end
		
		function Test:OnCommand_IsIgnoredAfterSDLReceved_OnExitApplication_reason_UNAUTHORIZED_TRANSPORT_REGISTRATION()
		
			commonTestCases:DelayedExp(1000)
						
			--hmi side: sending UI.OnCommand notification after SDL receved OnExitApplication with reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION"	
			self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 1, appID = Apps[1].appID})
			
			--mobile side: OnCommand notification is ignored
			EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
			:Times(0)
		end
		
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

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")
		
	local function TCs_verify_normal_cases()	

		
		--TCs_verify_normal_cases.1: verify OnExitApplication with reason = USER_EXIT
		-----------------------------------------------------------------------------------------------		
			--Requirement id in JAMA or JIRA: 	
				--SDLAQ-CRS-885: OnExitApplication(USER_EXIT) moves the app to NONE

			--Verification criteria: 
				--1. HMI->SDL: BasicCommunication.OnExitApplication(USER_EXIT, appID)
				--2. SDL -> app: OnHMIStatus (NONE, NOT_AUDIBLE)

			Open_UIMenu("Open_UIMenu_1")
			Select_OnExitApplication_USER_EXIT("Select_OnExitApplication_USER_EXIT_1")
			Close_UIMenu("Close_UIMenu_1")
			
			--PostCondition
			commonSteps:ActivationApp(_, "ActivationApp_2")
			

		
		--TCs_verify_normal_cases.2: verify OnExitApplication with reason = DRIVER_DISTRACTION_VIOLATION
		-----------------------------------------------------------------------------------------------		
		--Requirement id in JAMA or JIRA: 	
			--SDLAQ-CRS-888: DRIVER_DISTRACTION_VIOLATION

		--Verification criteria: 
			--1. HMI->SDL: BasicCommunication.OnExitApplication(DRIVER_DISTRACTION_VIOLATION, appID)
			--2. SDL -> app: OnHMIStatus (NONE, NOT_AUDIBLE)

			Open_UIMenu("Open_UIMenu_2")
			Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION("Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION_1")
			Close_UIMenu("Close_UIMenu_2")
			
			--PostCondition
			commonSteps:ActivationApp(_, "ActivationApp_3")
			
			
		--TCs_verify_normal_cases.3: verify OnExitApplication with reason = UNAUTHORIZED_TRANSPORT_REGISTRATION
		-----------------------------------------------------------------------------------------------			
				
			--Requirement id in JAMA or JIRA: 	
				--SDLAQ-CRS-3100: OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION, appID)

			--Verification criteria: 
				--1. In case SDL receives OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION, appID_1) notification from HMI SDL must:
				--1.1. - unregister application with appID_1 via OnAppInterfaceUnregistered(APP_UNATHORIZED) notification
				--1.2.- clear its internal information about app's non-responded RPCs,
				--1.3. - ignore all responses and notifications from HMI associated with appID_1

				--HMI expected behavior:
				--1. In case device connected over BT and navigation application with appID_1 is running on this device HMI is expected:
				--1.1. - to ignore all requests from SDL associated with this appID_1
				--1.2. - to reject registration for this navigation application with appID_1 via OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION, appID_1) notification

				OnExitApplication_reason_UNAUTHORIZED_TRANSPORT_REGISTRATION()	
				
				--PostCondition
				commonSteps:RegisterAppInterface("RegisterAppInterface1")
				commonSteps:RegisterAppInterface("RegisterAppInterface1")
				--1. Activate application
				commonSteps:ActivationApp(_, "ActivationApp_4")
				
				--2. Get appID Value on HMI side
				Get_HMI_AppID("Get_HMI_AppID_2")
				
			
		--TCs_verify_normal_cases.4: Verify invalid cases of reason parameter
		-----------------------------------------------------------------------------------------------			
			--1. IsMissed
			--2. IsEmtpy
			--3. NonExist
			--4. WrongDataType
			local InvalidValues = {	{value = nil, name = "IsMissed"},
									{value = "", name = "IsEmtpy"},
									{value = "ANY", name = "NonExist"},
									{value = 123, name = "WrongDataType"}}
			
			for i = 1, #InvalidValues  do
				Test["OnExitApplication_reason_" .. InvalidValues[i].name .."_IsIgnored"] = function(self)
				
					commonTestCases:DelayedExp(1000)
					
					--hmi side: send OnExitApplication
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = InvalidValues[i].value, appID = Apps[1].appID})

					--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
					EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
					:Times(0)
					
					--mobile side: expected OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
					:Times(0)
					
					--hmi side: expected  BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
					:Times(0)
					
				end
			end
			
			
				
		--TCs_verify_normal_cases.5: Verify invalid cases of appID parameter
		-----------------------------------------------------------------------------------------------
			--1. IsMissed
			--2. IsEmtpy
			--3. NonExist
			--4. WrongDataType
			local InvalidValues = {	{value = nil, name = "IsMissed"},
									{value = "", name = "IsEmtpy"},
									{value = "ANY", name = "NonExist"},
									{value = 123, name = "WrongDataType"}}
									
			local reasons = {	{value = "USER_EXIT", name = "USER_EXIT"},
								{value = "DRIVER_DISTRACTION_VIOLATION", name = "DRIVER_DISTRACTION_VIOLATION"},
								{value = "UNAUTHORIZED_TRANSPORT_REGISTRATION", name = "UNAUTHORIZED_TRANSPORT_REGISTRATION"}}
			
			for i = 1, #reasons do	
				for j = 1, #InvalidValues  do
					Test["OnExitApplication_reason_"..reasons[i].name .."_appID_" .. InvalidValues[j].name .."_IsIgnored"] = function(self)
					
						commonTestCases:DelayedExp(1000)
						
						--hmi side: send OnExitApplication
						self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = reasons[i].value, appID = InvalidValues[j].value})

						--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
						EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
						:Times(0)
						
						--mobile side: expected OnAppInterfaceUnregistered notification
						EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
						:Times(0)
						
						--hmi side: expected  BasicCommunication.OnAppUnregistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
						:Times(0)
						
					end
				end
			end
			
	end

	TCs_verify_normal_cases()	

	----------------------------------------------------------------------------------------------
	-----------------------------------------TEST BLOCK IV----------------------------------------
	----------------------------Check special cases of HMI notification---------------------------
	----------------------------------------------------------------------------------------------
	--Requirement id in JAMA or JIRA: 	
		--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

	-----------------------------------------------------------------------------------------------

	--List of test cases for special cases of HMI notification:
		--1. InvalidJsonSyntax
		--2. InvalidStructure
		--3. FakeParams 
		--4. FakeParameterIsFromAnotherAPI
		--5. MissedmandatoryParameters
		--6. MissedAllPArameters
		--7. SeveralNotifications with the same values
		--8. SeveralNotifications with different values
	----------------------------------------------------------------------------------------------
		
	local function SpecialResponseChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI notification")


		
		--SpecialResponseChecks.1. Verify OnExitApplication with invalid Json syntax
		----------------------------------------------------------------------------------------------
			function Test:OnExitApplication_InvalidJsonSyntax()
				
				commonTestCases:DelayedExp(1000)
				
				--hmi side: send OnExitApplication 
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnExitApplication","params":{"reason":"USER_EXIT","appID":'..Apps[1].appID..'}}')
				  self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnExitApplication","params":{"reason":"USER_EXIT","appID":'..Apps[1].appID..'}}')
				  
				EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
							
			end
			
		
		--SpecialResponseChecks.2. Verify OnExitApplication with invalid structure
		----------------------------------------------------------------------------------------------	
			function Test:OnExitApplication_InvalidStructure()
			
				commonTestCases:DelayedExp(1000)
				
				--hmi side: send OnExitApplication 
				--method is moved into params parameter
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnExitApplication","params":{"reason":"USER_EXIT","appID":'..Apps[1].appID..'}}')
				  self.hmiConnection:Send('{"jsonrpc";"2.0","params":{"method":"BasicCommunication.OnExitApplication","reason":"USER_EXIT","appID":'..Apps[1].appID..'}}')
			
				EXPECT_NOTIFICATION("OnExitApplication")
				:Times(0)
			end
			
		
		
		--SpecialResponseChecks.3. Verify OnExitApplication with FakeParams
		----------------------------------------------------------------------------------------------
			function Test:OnExitApplication_FakeParams()
									
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID, fake = 123})

				--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				:ValidIf(function(_,data)
					if data.payload.fake then
						print(" SDL forwards fake parameter to mobile ")
						return false
					else 
						return true
					end
				end)
				
			end
			
			--PostCondition
			commonSteps:ActivationApp(_, "ActivationApp_5")
			
			
		--SpecialResponseChecks.4. Verify OnExitApplication with FakeParameterIsFromAnotherAPI
			function Test:OnExitApplication_FakeParameterIsFromAnotherAPI()
			
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID, sliderPosition = 123})

				--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				:ValidIf(function(_,data)
					if data.payload.sliderPosition then
						print(" SDL forwards fake parameter to mobile ")
						return false
					else 
						return true
					end
				end)
				
			end
			
			--PostCondition
			commonSteps:ActivationApp(_, "ActivationApp_6")
			
		--SpecialResponseChecks.5. Verify OnExitApplication misses mandatory parameter
		----------------------------------------------------------------------------------------------
			--It is covered when verifying each parameter
			
			
		--SpecialResponseChecks.6. Verify OnExitApplication MissedAllPArameters
		----------------------------------------------------------------------------------------------
			function Test:OnExitApplication_AllParameters_AreMissed()
			
				commonTestCases:DelayedExp(1000)
				
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{})
			
				--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				:Times(0)
				
				--mobile side: expected OnAppInterfaceUnregistered notification
				EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
				:Times(0)
				
				--hmi side: expected  BasicCommunication.OnAppUnregistered
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
				:Times(0)
						
			end
			
			--SpecialResponseChecks.7. Verify OnExitApplication with SeveralNotifications_WithTheSameValues
			----------------------------------------------------------------------------------------------	
			function Test:OnExitApplication_SeveralNotifications_WithTheSameValues()
			
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID})
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID})
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID})


				--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				:Times(1)
				
			end
			
			--PostCondition
			commonSteps:ActivationApp(_, "ActivationApp_7")
			
				
		--SpecialResponseChecks.8. Verify OnExitApplication with SeveralNotifications_WithDifferentValues
		----------------------------------------------------------------------------------------------
			function Test:OnExitApplication_SeveralNotifications_WithDifferentValues()
			
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = Apps[1].appID})
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "DRIVER_DISTRACTION_VIOLATION", appID = Apps[1].appID})
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = Apps[1].appID})

				--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
				EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

				--mobile side: expected OnAppInterfaceUnregistered notification
				EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})		
				
				--hmi side: expected  BasicCommunication.OnAppUnregistered
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
				
			end
			
			--PostCondition
			commonSteps:RegisterAppInterface("RegisterAppInterface2")
			
			--1. Activate application
			commonSteps:ActivationApp(_, "ActivationApp_8")
			
			--2. Get appID Value on HMI side
			Get_HMI_AppID("Get_HMI_AppID_3")

	end

	SpecialResponseChecks()	

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


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")
			
		local function SequenceCheck()

			
			--Requirement id in JAMA or JIRA: SDLAQ-TC-312: TC_OnExitApplication_01
				
			--Verification criteria: 
				-- Checking changing of HMI level to NONE and audioStreaming State to NOT_AUDIBLE after Exit App from In-App menu and  possibility to activate this app again. Checked two reason of exit application ("DRIVER_DISTRACTION_VIOLATION" and "USER_EXIT").
			
				--It is covered by TC_OnExitApplication_04
			----------------------------------------------------------------------------------------------
			
			
			
			--Requirement id in JAMA or JIRA: SDLAQ-TC-313: TC_OnExitApplication_02
				
			--Verification criteria: 
				--1. Checking processing of RPC requests after  Exit App from In-App menu (According policy table). Checked two reason of exit application ("DRIVER_DISTRACTION_VIOLATION" and "USER_EXIT").
				
				local function TC_OnExitApplication_02()
				
					Open_UIMenu("Open_UIMenu_02_1")
					Select_OnExitApplication_USER_EXIT("Select_OnExitApplication_USER_EXIT_02")
					Close_UIMenu("Close_UIMenu_02_1")
										
					local function Alert_inNoneHmiLevel_Disallowed(TestCaseName) 
						Test[TestCaseName] = function(self)

							 --mobile side: Alert request 	
							local CorIdAlert = self.mobileSession:SendRPC("Alert",
							{
								 
								alertText1 = "alertText1",
								ttsChunks = 
								{ 
									
									{ 
										text = "TTSChunk",
										type = "TEXT",
									}, 
								}, 
								duration = 3000,
								softButtons = 
								{ 
									
									{ 
										type = "TEXT",
										text = "BUTTON1",
										softButtonID = 1171,
										systemAction = "DEFAULT_ACTION",
									}, 
								}, 
							
							}) 
						 

							--mobile side: Alert response
							EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "DISALLOWED" })


						end
					end
					
					Alert_inNoneHmiLevel_Disallowed("Alert_inNoneHmiLevel_Disallowed_02_1")
					
					--PostCondition
					commonSteps:ActivationApp(_, "ActivationApp_9")
					----------------------------------------------------------------------------------------------
					
					Open_UIMenu("Open_UIMenu_02_2")
					Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION("Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION_02")
					Close_UIMenu("Close_UIMenu_02_2")
					
					Alert_inNoneHmiLevel_Disallowed("Alert_inNoneHmiLevel_Disallowed_02_2")
					
					--PostCondition
					commonSteps:ActivationApp(_, "ActivationApp_10")
				end
				
				TC_OnExitApplication_02()
			----------------------------------------------------------------------------------------------

			
			--Requirement id in JAMA or JIRA: SDLAQ-TC-314: TC_OnExitApplication_03
				
			--Verification criteria: 
				--1. Checking possibility activating app after Exit App from In-App menu via VR synonym of application. Checked two reason of exit application ("DRIVER_DISTRACTION_VIOLATION" and "USER_EXIT").
					
				local function TC_OnExitApplication_03()	
					--Exit application
					Open_UIMenu("Open_UIMenu_03_1")
					Select_OnExitApplication_USER_EXIT("Select_OnExitApplication_USER_EXIT_03")
					Close_UIMenu("Close_UIMenu_03_1")
					
					--Activate application via VR menu
					Open_VRMenu("Open_UIMenu_03_1")
					Select_VRSynonym("Select_VRSynonym_To_ActivateApp_03_1")
					Close_VRMenu("Close_VRMenu_1")
					
					--Exit application
					Open_UIMenu("Open_UIMenu_03_2")
					Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION("Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION_03")
					Close_UIMenu("Close_UIMenu_03_2")
					
					--Activate application via VR menu
					Open_VRMenu("Open_UIMenu_03_3")
					Select_VRSynonym("Select_VRSynonym_To_ActivateApp_03_2")
					Close_VRMenu("Close_VRMenu_3")
				end

				TC_OnExitApplication_03()
			----------------------------------------------------------------------------------------------
				
			--Requirement id in JAMA or JIRA: SDLAQ-TC-347: TC_OnExitApplication_04
				
			--Verification criteria: 
				--1. Check that core handle OnExitApplication notification from HMI. Checked two reason of exit application ("DRIVER_DISTRACTION_VIOLATION" and "USER_EXIT").
				
				local function TC_OnExitApplication_04()
					--Exit application
					Open_UIMenu("Open_UIMenu_04_1")
					Select_OnExitApplication_USER_EXIT("Select_OnExitApplication_USER_EXIT_04")
					Close_UIMenu("Close_UIMenu_04_1")
					
					commonSteps:ActivationApp(_, "ActivationApp_11")
					
					--Exit application
					Open_UIMenu("Open_UIMenu_04_2")
					Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION("Select_OnExitApplication_DRIVER_DISTRACTION_VIOLATION_04")
					Close_UIMenu("Close_UIMenu_04_2")
				end
				
				TC_OnExitApplication_04()
			----------------------------------------------------------------------------------------------
		end
			
		SequenceCheck()

	----------------------------------------------------------------------------------------------
	-----------------------------------------TEST BLOCK VII---------------------------------------
	--------------------------------------Different HMIStatus-------------------------------------
	----------------------------------------------------------------------------------------------

	--Description: Check different HMIStatus

	--Not Applicable

end

part1()



----------------------------------------------------------------------------------------------
--PART2: Specific script for requirement:
		--SDLAQ-CRS-885: OnExitApplication(USER_EXIT) moves the app to NONE
----------------------------------------------------------------------------------------------
--Note: This part is the same as previous revision (no change). 

local function part2()

	local application1 =
	{
	  registerAppInterfaceParams =
	  {
		syncMsgVersion =
		{
		  majorVersion = 3,
		  minorVersion = 0
		},
		appName = "Test Application",
		isMediaApplication = true,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "NAVIGATION"},
		appID = "8675308",
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

	local application2 =
	{
	  registerAppInterfaceParams =
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
	  appID = "8675310",
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

	local function AppRegistration(self, session, params)
		local CorIdRegister = session:SendRPC("RegisterAppInterface", params)
		
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
		  self.applications[data.params.application.appName] = data.params.application.appID
		end)
		
		--mobile side: expect response
		session:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

		session:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end 

	local function DelayedExp(time)
		local event = events.Event()
	  event.matches = function(self, e) return self == e end
	  EXPECT_EVENT(event, "Delayed event")
	  :Timeout(time + 1000)
	  RUN_AFTER(function()
				  RAISE_EVENT(event, event)
				end, time)
	end
			
	local function ActivationApp(self, appID, session)			
		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appID})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if
				data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage message response
				--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)						
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
		
		--mobile side: expect notification
		session:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	end



	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration of app by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION).

		function Test:Case_OnExitApplicationAfterRegistration()

			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})

			DelayedExp(2000)

		end


	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration of app by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) during processing API, SDL does not resends messages to mobile side after unregistration.

		function Test:Precondition_RegisterAppSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end

		function Test:Precondition_ActivateApp()
			ActivationApp(self, self.applications["Test Application"], self.mobileSession)
		end

		function Test:Case_OnExitApplicationduringProcessingAPI()

			--mobile side: sending Speak request
			local cid = self.mobileSession:SendRPC("Speak",
			{
				ttsChunks = 
				{
					{
						text = "Speak text",
						type = "TEXT"
					}
				}
			})


			--hmi side: TTS.Speak request
			EXPECT_HMICALL("TTS.Speak",
				{
					ttsChunks = 
					{
						{
							text = "Speak text",
							type = "TEXT"
						}
					}
				})
				:Do(function(_,data)
					function to_run()
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end

					RUN_AFTER(to_run,2000)

					--hmi side: send request BasicCommunication.OnExitApplication
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

					--mobile side: expect onAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
					:Do(function(_,data)

						EXPECT_NOTIFICATION("OnHMIStatus", {})
							:Times(0)

						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MENU" })

						self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })

						DelayedExp(4000)

					end)

					--hmi side: expect BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})


				end)


		end


	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration of app by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) during Streamings.

		function Test:Precondition_RegisterAppSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end

		function Test:Precondition_ActivateApp()
			ActivationApp(self, self.applications["Test Application"], self.mobileSession)
		end

		function Test:Precondition_StartAudioVideoService()
			self.mobileSession:StartService(11)
				:Do(function()
					print ("\27[32m Video service is started \27[0m ")
				end)
			self.mobileSession:StartService(10)
				:Do(function()
					print ("\27[32m Audio service is started \27[0m ")
				end)
		end

		function Test:Precondition_StartAudioVidoeStreaming()
			self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
			self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
		end

		function Test:Case_OnExitApplicationduringProcessingStremings()

			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
				:Do(function(_,data)
					DelayedExp(4000)

				end)

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})

		end

		function Test:Postcondition_StopStreamings()
			local function StopVideo()
			 print(" \27[32m Stopping video streaming \27[0m ")
			 self.mobileSession:StopStreaming("files/Wildlife.wmv")
			 self.mobileSession:Send(
			   {
				 frameType   = 0,
				 serviceType = 11,
				 frameInfo   = 4,
				 sessionId   = self.mobileSession.sessionId
			   })
		   end 
			local function StopAudio()
				 print(" \27[32m Stopping audio streaming \27[0m ")
				 self.mobileSession:StopStreaming("files/Kalimba.mp3")
				 self.mobileSession:Send(
				   {
					 frameType   = 0,
					 serviceType = 10,
					 frameInfo   = 4,
					 sessionId   = self.mobileSession.sessionId
				   })
		   end 
		 RUN_AFTER(StopVideo, 2000)
		 RUN_AFTER(StopAudio, 2500)
		 local event = events.Event()
		 event.matches = function(_, data)
						   return data.frameType   == 0 and
								  (data.serviceType == 11 or
								  data.serviceType == 10) and
								  data.sessionId   == self.mobileSession.sessionId and
								 (data.frameInfo   == 5 or -- End Service ACK
								  data.frameInfo   == 6)   -- End Service NACK
						 end
		 self.mobileSession:ExpectEvent(event, "EndService ACK")
			:Timeout(60000)
			:Times(2)
			:ValidIf(function(s, data)
					   if data.frameInfo == 5 then return true
					   else return false, "EndService NACK received" end
					 end)
		end

	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration of app by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) and response APPLICATION_NOT_REGISTERED to request after OnAppInterfaceUnregistered(APP_UNAUTHORIZED) notification.

		function Test:Precondition_RegisterAppSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)

			DelayedExp(1000)
		end

		function Test:Precondition_ActivateApp()
			ActivationApp(self, self.applications["Test Application"], self.mobileSession)
		end

		function Test:Case_RequestsAfterOnExitApplication()

			commonTestCases:DelayedExp(2000)
			
			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
			:Do(function(_,data)

				--mobile side: sending Speak request
				local cid = self.mobileSession:SendRPC("Speak",
				{
					ttsChunks = 
					{
						{
							text = "Speak text",
							type = "TEXT"
						}
					}
				})


				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak")
					:Times(0)

				--mobile side: expect Speak response
				EXPECT_RESPONSE(cid, {resultCode = "APPLICATION_NOT_REGISTERED"})

			end)

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})
		end


	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration of corresponding app by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) in case 2 apps are registered.

		function Test:Precondition_StartSession2()
		  -- Connected expectation
			self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection,
				application1.registerAppInterfaceParams)
		end

		function Test:Precondition_RegisterAppFirstSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end

		function Test:Precondition_RegisterAppSecondSession()
			self.mobileSession2:StartService(7)
				:Do(function(_,data)
					AppRegistration(self, self.mobileSession2, application2.registerAppInterfaceParams)
				end)
		end

		function Test:Precondition_ActivateApp()
			ActivationApp(self, self.applications["Test Application2"], self.mobileSession2)
		end

		function Test:Case_OnExitApplicationForOneApp()

			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
			:Do(function(_,data)

				--mobile side: sending Speak request in first session
				local cidFirstSession = self.mobileSession:SendRPC("Speak",
				{
					ttsChunks = 
					{
						{
							text = "Speak text in first session",
							type = "TEXT"
						}
					}
				})


				--mobile side: Speak response in first session
				EXPECT_RESPONSE(cidFirstSession, {resultCode = "APPLICATION_NOT_REGISTERED", success = false})

				--mobile side: sending Speak request in second session
				local cidSecondSession = self.mobileSession2:SendRPC("Speak",
						{
							ttsChunks = 
							{
								{
									text = "Speak text in second session",
									type = "TEXT"
								}
							}
						})


				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak",
							{
								ttsChunks = 
								{
									{
										text = "Speak text in second session",
										type = "TEXT"
									}
								}
							})
					:Do(function(_,data)
						--hmi side: sending TTS.Speak response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--mobile side: Speak response in second session
				self.mobileSession2:ExpectResponse(cidSecondSession,{resultCode = "SUCCESS", success = true})


			end)

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})

		end


	---------------------------------------------------------------------------------------------
	--Description: TC checks absence of unregistration by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) without appId.

		function Test:Precondition_RegisterAppFirstSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end


		function Test:Case_OnExitApplicationWithoutAppId()
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION"})

			EXPECT_ANY_SESSION_NOTIFICATION("OnAppInterfaceUnregistered")
				:Times(0)

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
				:Times(0)

			DelayedExp(3000)
		end

	---------------------------------------------------------------------------------------------
	--Description: TC checks absence of unregistration by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) with appId of not registered app.

		function Test:Case_OnExitApplicationWithNotExistentAppID()
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = 1111})

			EXPECT_ANY_SESSION_NOTIFICATION("OnAppInterfaceUnregistered")
				:Times(0)

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
				:Times(0)

			DelayedExp(3000)
		end

	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) of 2 registered apps.

		function Test:Case_OnExitApplicationToTwoRegisteredApps()

			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application2"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})

			self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
				{ appID = self.applications["Test Application"], unexpectedDisconnect = false},
				{ appID = self.applications["Test Application2"], unexpectedDisconnect = false})
				:Times(2)

			DelayedExp(1000)

		end

	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) in limited.

		function Test:Precondition_RegisterApp()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end

		function Test:Precondition_ActivateApp()
			ActivationApp(self, self.applications["Test Application"], self.mobileSession)
		end

		function Test:Case_OnExitApplicationInLimited()

			--hmi side: sending BasicCommunication.OnExitApplication notification
			self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

			EXPECT_NOTIFICATION("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
				:Do(function(_,data)
					--hmi side: send request BasicCommunication.OnExitApplication
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

					--mobile side: expect onAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})

					--hmi side: expect BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})
				end)
		end
		
	---------------------------------------------------------------------------------------------
	--Description: TC checks unregistration by SDL after receiving BasicCommunication.OnExitApplication(UNAUTHORIZED_TRANSPORT_REGISTRATION) in background.
		
		function Test:Precondition_RegisterAppFirstSession()
			AppRegistration(self, self.mobileSession, application1.registerAppInterfaceParams)
		end

		function Test:Precondition_RegisterAppSecondSession()
			AppRegistration(self, self.mobileSession2, application2.registerAppInterfaceParams)
		end

		function Test:Precondition_ActivateAppFirstApp()
			ActivationApp(self, self.applications["Test Application"], self.mobileSession)
		end

		function Test:Precondition_ActivateAppSendApp()
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				if
					data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					
					--hmi side: expect SDL.GetUserFriendlyMessage message response
					EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					:Do(function(_,data)						
						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
		
			--mobile side: expect notification
			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

			EXPECT_NOTIFICATION("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
		end

		function Test:Case_OnExitApplicationInBackground()

			--hmi side: send request BasicCommunication.OnExitApplication
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = self.applications["Test Application"]})

			--mobile side: expect onAppInterfaceUnregistered notification
			EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications["Test Application"], unexpectedDisconnect = false})

		end
end

part2()

---------------------------------------------------------------------------------------------
-------------------------------------------Post-conditions-----------------------------
---------------------------------------------------------------------------------------------

--Postcondition: restore sdl_preloaded_pt.json
testCasesForPolicyTable:Restore_preloaded_pt()                   

return Test	
	
	