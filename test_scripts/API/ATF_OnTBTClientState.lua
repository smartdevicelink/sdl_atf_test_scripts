Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')


APIName = "OnTBTClientState" -- set API name
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
NewTestSuiteNumber = 0 -- use as subfix of test case "NewTestSuite" to make different test case name.
Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 
Apps[2] = {}
Apps[2].appName = config.application2.registerAppInterfaceParams.appName 	
---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

--Test case: HMI sends OnTBTClientState and SDL forwards it to Mobile
local function OnTBTClientState_ValidValue_SUCCESS(Input_state, TestCaseName)
	Test[TestCaseName] = function(self)
	
		--hmi side: send request Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = Input_state})

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {state = Input_state})
	end
end


--Test case: HMI sends OnTBTClientState but SDL does not send it to Mobile
local function OnTBTClientState_IsIgnored(Input_state, TestCaseName)
	Test[TestCaseName] = function(self)
	
		commonTestCases:DelayedExp(1000)
	
		--hmi side: send request Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = Input_state})

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {state = Input_state})
		:Times(0)
	end
end



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Configure app params in config.lua to navigation application 
	config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	
	--1. Activate application
	commonSteps:ActivationApp()
	
	--2. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})

	--3. Postcondition: Restore_preloaded_pt
	policyTable:Restore_preloaded_pt()

	--List of state
	local TBTState = 
	{
		"ROUTE_UPDATE_REQUEST",
		"ROUTE_ACCEPTED",
		"ROUTE_REFUSED",
		"ROUTE_CANCELLED",
		"ETA_REQUEST",
		"NEXT_TURN_REQUEST",
		"ROUTE_STATUS_REQUEST",
		"ROUTE_SUMMARY_REQUEST",
		"TRIP_STATUS_REQUEST",
		"ROUTE_UPDATE_REQUEST_TIMEOUT"
	}	
	




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
----------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-181: OnTBTClientState_v2_0
	
	--Verification criteria: SDL sends OnTBTClientState to all mobile applications that have stated 'appHMItype: Navigation' in RegisterAppInterface_request IN CASE SDL receives Navigation.OnTBTClientState notification from HMI.
----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. state: type=TBTState
----------------------------------------------------------------------------------------------
	
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")


----------------------------------------------------------------------------------------------
--Test case #1: Checks OnTBTClientState is sent to application SDL after receiving Navigation.OnTBTClientState(state = valid_value)
----------------------------------------------------------------------------------------------

	for i = 1, #TBTState do
		OnTBTClientState_ValidValue_SUCCESS(TBTState[i], "OnTBTClientState_state_IsValidValue_".. TBTState[i] .. "_SUCCESS")
	end


----------------------------------------------------------------------------------------------
--Test case #2: Checks OnTBTClientState is NOT sent to application SDL after receiving Navigation.OnTBTClientState(state = invalid_value)
----------------------------------------------------------------------------------------------
	local Invalid_states = 	{	{value = "ANY", name = "IsNonexistent"},
								{value = 123, name = "IsWrongType"},
								{value = "", name = "IsEmpty"}}
							
	for i  = 1, #Invalid_states do		
		OnTBTClientState_IsIgnored(Invalid_states[i].value, "OnTBTClientState_state_IsInvalidValue_" .. Invalid_states[i].name .."_IsIgnored")
	end



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
	--5. MissedAllPArameters
	--6. SeveralNotifications with the same values
	--7. SeveralNotifications with different values
----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI notification")

	function Test:OnTBTClientState_InvalidJsonSyntax()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send Navigation.OnTBTClientState 
		--":" is changed by ";" after "jsonrpc"
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"Navigation.OnTBTClientState","params":{"state":"ROUTE_UPDATE_REQUEST"}}')
		  self.hmiConnection:Send('{"jsonrpc";"2.0","method":"Navigation.OnTBTClientState","params":{"state":"ROUTE_UPDATE_REQUEST"}}')
		

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {state = "ROUTE_UPDATE_REQUEST"})
		:Times(0)
		
	end
	
	function Test:OnTBTClientState_InvalidStructure()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send Navigation.OnTBTClientState 
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"Navigation.OnTBTClientState","params":{"state":"ROUTE_UPDATE_REQUEST"}}')
		  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"Navigation.OnTBTClientState","state":"ROUTE_UPDATE_REQUEST"}}')

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {})
		:Times(0)
		
	end
	
	function Test:OnTBTClientState_FakeParams()
	
		--hmi side: send Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1], fake = 123})

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {state = TBTState[1]})
		:ValidIf (function(_,data)
			if data.payload.fake then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
		
	end
	
	function Test:OnTBTClientState_FakeParameterIsFromAnotherAPI()
	
		--hmi side: send Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1], sliderPosition = 5})

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {state = TBTState[1]})
		:ValidIf (function(_,data)
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL resends sliderPosition parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
		
	end

	function Test:OnTBTClientState_MissedAllPArameters()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send Navigation.OnTBTClientState 
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"Navigation.OnTBTClientState","params":{"state":"ROUTE_UPDATE_REQUEST"}}')
		  self.hmiConnection:Send('{"jsonrpc":"2.0","method":"Navigation.OnTBTClientState","params":{}}')
		

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", {})
		:Times(0)
		
	end

	function Test:OnTBTClientState_SeveralNotifications_WithTheSameValues()
	
		--hmi side: send Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1]})
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1]})
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1]})
		

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", 
												{state = TBTState[1]},
												{state = TBTState[1]},
												{state = TBTState[1]}
		)
		:Times(3)
		
	end
	
	function Test:OnTBTClientState_SeveralNotifications_WithDifferentValues()
	
		--hmi side: send Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1]})
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[2]})

		--mobile side: expect OnTBTClientState notification
		EXPECT_NOTIFICATION("OnTBTClientState", 
												{state = TBTState[1]},
												{state = TBTState[2]}
		)
		:Times(2)
	end
		
end

SpecialResponseChecks()	

	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Policy table does not allow notification send to mobile")

		
	----------------------------------------------------------------------------------------------
	--Test case #1: API is not in policy table, SDL does not send it to mobile
	----------------------------------------------------------------------------------------------

		--ToDo: Due to changing in implementation of policy update flow, these test case cannot executed.
		
		-- --Precondition: Build policy table file
		-- local PTName = policyTable:createPolicyTableWithoutAPI(APIName)
		
		-- --Precondition: Update policy table
		-- policyTable:updatePolicy(PTName)

		-- for i = 1, #TBTState do
			-- OnTBTClientState_IsIgnored(TBTState[i], "OnTBTClientState_IsNotInPolicyTable_IsIgnored_state_".. TBTState[i])
		-- end



		
	----------------------------------------------------------------------------------------------
	--Test case #2: API is in policy table but user has not consented yet, SDL does not send it to mobile
	----------------------------------------------------------------------------------------------
		--For Genivi version, SDL do not support user consent function. => These test cases are not applicable. REMOVED
		
	----------------------------------------------------------------------------------------------
	--Test case #3: API is in policy table but user disallows, SDL does not send it to mobile
	----------------------------------------------------------------------------------------------
		
		--For Genivi version, SDL do not support user consent function. => These test cases are not applicable. REMOVED
		
end

ResultCodeChecks()
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

--Requirement id in JAMA: SDLAQ-CRS-181

--Verification criteria: Notifications should be sent to all applications which would be impacted by the change (which supports Navi).

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")

	-- Precondition 1: Opening new session, register app, activate
	function Test:AddNewSession2()
	
	  -- Connected expectation
		self.mobileSession2 = mobile_session.MobileSession(Test,Test.mobileConnection)
		
		self.mobileSession2:StartService(7)
	end	
	
	function Test:Register_Non_Navi_App2()

		--mobile side: RegisterAppInterface request 
		config.application2.registerAppInterfaceParams.isMediaApplication = false
		config.application2.registerAppInterfaceParams.appHMIType = nil

		local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = config.application2.registerAppInterfaceParams.appName,
				isMediaApplication = false
			}
		})
		:Do(function(_,data)
			Apps[2].appID = data.params.application.appID
			self.applications[Apps[2].appName] = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	function Test:Activate_Non_Navi_App2()
		
		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Apps[2].appID})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if
				data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage message response
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
					:Times(AnyNumber())
				end)

			end
		end)
		
		--mobile side: expect notification
		self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	
	end

	function Test:OnTBTClientState_Not_Send_To_Non_Navi_App()
	
		commonTestCases:DelayedExp(1000)
	
		--hmi side: send request Navigation.OnTBTClientState 
		self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = TBTState[1]})

		--mobile side: expect OnTBTClientState notification
		self.mobileSession2:ExpectNotification("OnTBTClientState", {})
		:Times(0)
	end
	
	--Postcondition:
	function Test:Unregister_Non_Navi_App2()
	
		local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})

		self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
	end 
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-1308: HMI Status Requirements for OnTBTClientState (FULL, LIMITED or BACKGROUND)
	
	--Verification criteria: 
		--1. SDL doesn't send OnTBTClientState notification to the app when current app's HMI level is NONE.
		--2. SDL sends OnTBTClientState notification to the app when current app's HMI is FULL.
		--3. SDL sends OnTBTClientState notification to the app when current app's HMI is LIMITED.
		--4. SDL sends OnTBTClientState notification to the app when current app's HMI is BACKGROUND.


local function verifyDifferentHMIStatus()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
	----------------------------------------------------------------------------------------------


	--1. HMI level is NONE

	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel()

	for i = 1, #TBTState do
		OnTBTClientState_IsIgnored(TBTState[i], "OnTBTClientState_InNONE_HmiLevel_IsIgnored_state_"..TBTState[i])
	end
	

	--Postcondition: Activate app
	commonSteps:ActivationApp()	
	----------------------------------------------------------------------------------------------


	--2. HMI level is LIMITED
	if commonFunctions:isMediaApp() then
		-- Precondition: Change app to LIMITED
		commonSteps:ChangeHMIToLimited()
		
		for i = 1, #TBTState do
			OnTBTClientState_ValidValue_SUCCESS(TBTState[i], "OnTBTClientState_InLIMITED_HmiLevel_SUCCESS_state_"..TBTState[i])
		end
		
	end
	----------------------------------------------------------------------------------------------


	--3. HMI level is BACKGROUND
	commonTestCases:ChangeAppToBackgroundHmiLevel()

	for i = 1, #TBTState do
		OnTBTClientState_ValidValue_SUCCESS(TBTState[i], "OnTBTClientState_InBACKGROUND_HmiLevel_SUCCESS_state"..TBTState[i])
	end
	----------------------------------------------------------------------------------------------	
end

verifyDifferentHMIStatus()
----------------------------------------------------------------------------------------------



return Test