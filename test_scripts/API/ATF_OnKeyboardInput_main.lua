---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last modified date: 07/Dec/2015
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
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

APIName = "OnKeyboardInput" -- set API name

Apps = {}
Apps[1] = {}
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 


local KeyboardEvent = {"KEYPRESS", "ENTRY_SUBMITTED", "ENTRY_CANCELLED", "ENTRY_ABORTED", "ENTRY_VOICE"}


--Send notification and check it is ignored
local function TC_OnKeyboardInput_IsIgnored(TestCaseName)
	Test[TestCaseName] = function(self)

		commonTestCases:DelayedExp(1000)

		--hmi side: send OnKeyboardInput
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	{ event = "KEYPRESS", data = "a" })
					
		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput", {})
		:Times(0)
	end
end

		
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	commonSteps:DeleteLogsFileAndPolicyTable()
            
    --Print new line to separate new test cases group
    commonFunctions:newTestCasesGroup("Preconditions")
            
    --1. Activate application
    commonSteps:ActivationApp()

	--2. Get appID Value on HMI side
	function Test:GetAppID()
		Apps[1].appID = self.applications[Apps[1].appName]
	end
	
    --3. Update policy to allow request
    --TODO: Should be used testCasesForPolicyTable:updatePolicy(PTName) after defect APPLINK-19188 is fixed.

	--3. Create PT that allowed OnKeyboardInput in Base-4 group and update PT
	local PermissionLinesForBase4 = 
	[[					"OnKeyboardInput": {
						"hmi_levels": [
						  "FULL"
						]
					  },]] .. "\n"				  
					  
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	-- TODO: PT is blocked by ATF defect APPLINK-19188
	local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnKeyboardInput", "OnButtonPress", "Show", "SubscribeButton"})	
	testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)	
	
		
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
	--SDLAQ-N_CRS-3: OnKeyboardInput
		--SDLAQ-N_CRS-10: KeyboardEvent
		--SDLAQ-CRS-3118: ENTRY_VOICE
	
--Verification criteria: 
	--SDL sends OnKeyboardInput to mobile app IN CASE SDL receives UI.OnKeyboardInput notification from HMI. SDL just re-sends the values from HMI to mobile app.
	--Verifiable by performing PerformInteraction RPC of KEYBOARD layoutMode and MANUAL_ONLY interactionType from mobile app.

----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. event: type=KeyboardEvent (KEYPRESS,  ENTRY_SUBMITTED,  ENTRY_CANCELLED,  ENTRY_ABORTED,  ENTRY_VOICE), mandatory=true 
	--2. data: type=String, maxlength=500, mandatory=false


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: TEST BLOCK III: Check normal cases of HMI notification")

	--TODO: Script should be updated according to answer on question APPLINK-17596
-----------------------------------------------------------------------------------------
--Parameter #1: Checks event parameter: type=KeyboardEvent (KEYPRESS,  ENTRY_SUBMITTED,  ENTRY_CANCELLED,  ENTRY_ABORTED,  ENTRY_VOICE), mandatory=true 
----------------------------------------------------------------------------------------------
	local function TCs_verify_event_parameter()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check event parameter")
		
		
		--1. IsInBoundValues
		for i = 1, #KeyboardEvent  do
		
			Test["OnKeyboardInput_event_" .. KeyboardEvent[i]] = function(self)
			
				local parameter = {
								event = KeyboardEvent[i], 
								data = "abc"
							}
							
				--hmi side: send OnKeyboardInput
				self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter)
	

				--mobile side: expected OnKeyboardInput notification
				EXPECT_NOTIFICATION("OnKeyboardInput", parameter)
				
			end
		end
		
		
		--2. IsMissed
		--3. IsEmtpy
		--4. NonExist
		--5. WrongDataType
		local InvalidValues = {	{value = nil, name = "IsMissed"},
								{value = "", name = "IsEmtpy"},
								{value = "ANY", name = "NonExist"},
								{value = 123, name = "WrongDataType"}}
		
		for i = 1, #InvalidValues  do
			Test["OnKeyboardInput_event_" .. InvalidValues[i].name] = function(self)
			
				commonTestCases:DelayedExp(1000)
				
				local parameter = {
								event = InvalidValues[i].value, 
								data = "abc"
							}
				
				--hmi side: send OnKeyboardInput
				self.hmiConnection:SendNotification("UI.OnKeyboardInput", parameter)

				--mobile side: expected OnKeyboardInput notification
				EXPECT_NOTIFICATION("OnKeyboardInput")
				:Times(0)
			end
		end
		
		
	end
	
	TCs_verify_event_parameter()



-----------------------------------------------------------------------------------------
--Parameter #2: Checks data parameter: type=String, maxlength=500, mandatory=false
----------------------------------------------------------------------------------------------
	local function TCs_verify_data_parameter()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check data parameter")
		
		--1. IsLowerBound
		--2. IsMiddle
		--3. IsUpperBound
		--4. IsMissed
		--5. IsOutLowerBound: Not applicable because minlength is 0.
		--6. IsOnlyWhiteSpaces
		--7. IsTabBar
		--8. IsNewLine
		local ValidValues = {	{value = "", 		name = "IsLowerBound_IsEmpty"},
					{value = "abcdef", 				name = "IsMiddle"},
					{value = string.rep("b", 500), 	name = "IsUpperBound"},
					{value = nil, 					name = "IsMissed"},
					{value = " ", 					name = "IsOnlyWhiteSpaces"},
					{value = "a\tb", 				name = "IsTabBar"},
					{value = "a\nb", 				name = "IsNewLine"}}
							
		for i =1, #KeyboardEvent do
			for j = 1, #ValidValues  do
				Test["OnKeyboardInput_event_" ..KeyboardEvent[i] .. "_data_" .. ValidValues[j].name] = function(self)
				
					local parameter = {
									event = KeyboardEvent[i], 
									data = ValidValues[j].value
								}
									
					--hmi side: send OnKeyboardInput
					self.hmiConnection:SendNotification("UI.OnKeyboardInput", parameter)

					--mobile side: expected OnKeyboardInput notification
					EXPECT_NOTIFICATION("OnKeyboardInput", parameter)
					
				end
			end
		end
		
		
		--9. IsOutUpperBound
		--10. IsWrongType
		local InvalidValues = {	
								{value = string.rep("b", 501), 	name = "IsOutUpperBound"},
								{value = 2, 					name = "IsWrongDataType"}}

		for i =1, #KeyboardEvent do
			for j = 1, #InvalidValues  do
				Test["OnKeyboardInput_event_"..KeyboardEvent[i].."_data_" .. InvalidValues[j].name] = function(self)
					
					commonTestCases:DelayedExp(1000)
					
					local parameter = {
									event = KeyboardEvent[i], 
									data = InvalidValues[j].value
								}
									
					--hmi side: send OnKeyboardInput
					self.hmiConnection:SendNotification("UI.OnKeyboardInput", parameter)

					--mobile side: expected OnKeyboardInput notification
					EXPECT_NOTIFICATION("OnKeyboardInput")
					:Times(0)
				end
			end
		end
		
	end

	TCs_verify_data_parameter()


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
	commonFunctions:newTestCasesGroup("Test suite: TEST BLOCK IV: Check special cases of HMI notification")


	
	--1. Verify OnKeyboardInput with invalid Json syntax
	----------------------------------------------------------------------------------------------
	function Test:OnKeyboardInput_InvalidJsonSyntax()
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send OnKeyboardInput 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnKeyboardInput","params":{"event":"KEYPRESS","data":"a"}}')
	
		EXPECT_NOTIFICATION("OnKeyboardInput")
		:Times(0)
					
	end
	
	
	--2. Verify OnKeyboardInput with invalid structure
	----------------------------------------------------------------------------------------------	
	function Test:OnKeyboardInput_InvalidStructure()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send OnKeyboardInput 
		--method is moved into params parameter
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnKeyboardInput","event":"KEYPRESS","data":"a"}}')
	
		EXPECT_NOTIFICATION("OnKeyboardInput")
		:Times(0)
	end
	
	
	
	--3. Verify OnKeyboardInput with FakeParams
	----------------------------------------------------------------------------------------------
	function Test:OnKeyboardInput_FakeParams()

		--hmi side: send OnKeyboardInput
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	
					{
						event = "KEYPRESS", 
						data = "a",
						fake = 123
					})

		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput", 
					{
						event = "KEYPRESS", 
						data = "a"
					})
		:ValidIf(function(_,data)
								
			if data.payload.fake then
					print(" SDL forwards fake parameter to mobile ")
					return false
			else 
					return true
			end
		end)
				
	end
	
	
	--4. Verify OnKeyboardInput with FakeParameterIsFromAnotherAPI
	function Test:OnKeyboardInput_FakeParameterIsFromAnotherAPI()
	
		--hmi side: send OnKeyboardInput
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	
					{
						event = "KEYPRESS", 
						data = "a",
						sliderPosition = 123
					})

		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput", 
					{
						event = "KEYPRESS", 
						data = "a",
					})
		:ValidIf(function(_,data)
								
			if data.payload.sliderPosition then
					print(" SDL forwards fake parameter to mobile ")
					return false
			else 
					return true
			end
		end)
		
	end
	
		
	
	--5. Verify OnKeyboardInput misses mandatory parameter
	----------------------------------------------------------------------------------------------
	--It is covered when verifying each parameter: 
		--Missed event parameter: TCs_verify_event_parameter()
			--2. IsMissed
		--Missed data parameter: TCs_verify_data_parameter()
			--4. IsMissed
	
	
	--6. Verify OnKeyboardInput MissedAllPArameters
	----------------------------------------------------------------------------------------------
	function Test:OnKeyboardInput_AllParameters_AreMissed()
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send OnKeyboardInput
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",{})

		
		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput")
		:Times(0)
				
	end
	
	--7. Verify OnKeyboardInput with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------	
	function Test:OnKeyboardInput_SeveralNotifications_WithTheSameValues()
	
		--hmi side: send OnKeyboardInput
		local parameter = { event = "KEYPRESS", data = "a" }
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter)
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter)
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter)

		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput", parameter)
		:Times(3)
		
	end
	
		
	--8. Verify OnKeyboardInput with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------
	function Test:OnKeyboardInput_SeveralNotifications_WithDifferentValues()
	
		--hmi side: send OnKeyboardInput
		local parameter1 = { event = "KEYPRESS", data = "a" }
		local parameter2 = { event = "KEYPRESS", data = "b" }
		local parameter3 = { event = "KEYPRESS", data = "c" }
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter1)
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter2)
		self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter3)

		--mobile side: expected OnKeyboardInput notification
		EXPECT_NOTIFICATION("OnKeyboardInput", parameter1, parameter2, parameter3)
		:Times(3)
		
	end
	
	
end

SpecialResponseChecks()	
		
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Requirement id in JAMA: 
	--N/A
	
--Verification criteria: Verify SDL behaviors in different states of policy table: 
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	--4. Notification is exist in PT and user allow function group that contains this notification
----------------------------------------------------------------------------------------------

	local function ResultCodeChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: TEST BLOCK V: Checks All Result Codes")
		
		
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PTFileName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnKeyboardInput")
		
		--Precondition: Update policy table
		--testCasesForPolicyTable:updatePolicy(PTFileName)
		
		TC_OnKeyboardInput_IsIgnored("OnKeyboardInput_IsNotExistInPT_DISALLOWED")
		
	----------------------------------------------------------------------------------------------
	end
	
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--ResultCodeChecks()
	

	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-N_CRS-3: OnKeyboardInput
	--SDLAQ-CRS-3118: ENTRY_VOICE
	
--Verification criteria: 
	--1. OnKeyboardInput is allowed in FULL hmi level only
----------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: TEST BLOCK VII: Check different HMIStatus")
	----------------------------------------------------------------------------------------------
	
	--1. HMI level is NONE
	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel("DeactivateAppToNoneHmiLevel_5_1")
	
	TC_OnKeyboardInput_IsIgnored("OnKeyboardInput_IsIgnored_InNoneHmiLevel")
	
	--Postcondition:
	commonSteps:ActivationApp(_, "Activation_App_5_1")	
	----------------------------------------------------------------------------------------------
	
	--2. HMI level is LIMITED	
	if commonFunctions:isMediaApp() then
		-- Precondition: Change app to LIMITED
		commonSteps:ChangeHMIToLimited("ChangeHMIToLimited_5_2")
			
		TC_OnKeyboardInput_IsIgnored("OnButtonPress_InLimitedHmiLevel_IsIgnored")
		
		--Postcondition:
		commonSteps:ActivationApp(_, "Activation_App_5_2")	
	end
	----------------------------------------------------------------------------------------------
	
	--3. HMI level is BACKGROUND
	commonTestCases:ChangeAppToBackgroundHmiLevel()
	TC_OnKeyboardInput_IsIgnored("OnButtonPress_InBackgoundHmiLevel_IsIgnored")
	
----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-------------------------------------------Post-conditions-----------------------------
---------------------------------------------------------------------------------------------

--Postcondition: restore sdl_preloaded_pt.json
testCasesForPolicyTable:Restore_preloaded_pt()                   

return Test	
	
		