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

APIName = "OnCommand" -- set API name
local TestCaseNumber = 0 --used to add sub-fix for test cases have the same name.

--Parameters for OnCommand notification
local appIDValue --appID on HMI side
local grammarIDValue
local cmdIDValue

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local storagePath = config.pathToSDL  .."storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local appNameValue = config.application1.registerAppInterfaceParams.appName 

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--Set AudioStreamingState
if commonFunctions:isMediaApp() then
	CurrentAudioStreamingState = "AUDIBLE"
else
	CurrentAudioStreamingState = "NOT_AUDIBLE"
end
	
	

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

local function SendOnSystemContext(self, Input_SystemContext)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appIDValue, systemContext = Input_SystemContext})
end

	
--AddCommand with id = cmdIDValue
--Return: grammarIDValue
local function AddCommand(cmdIDValue)
	TestCaseNumber = TestCaseNumber + 1
	Test["AddCommand_" .. tostring(TestCaseNumber)] = function(self)
				
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
												{
													cmdID = cmdIDValue,
													menuParams = 	
													{ 
														menuName ="Command1_onMenu" .. tostring(cmdIDValue)
													}, 
													vrCommands = 
													{ 
														"Command1_OnVR"  .. tostring(cmdIDValue),
														"Command2_OnVR"  .. tostring(cmdIDValue)
													}
												})
												
		--hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = cmdIDValue,
							menuParams = 
							{ 
								menuName ="Command1_onMenu"  .. tostring(cmdIDValue)
							}
						})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
			
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = cmdIDValue,
							type = "Command",
							vrCommands = 
							{
								"Command1_OnVR"  .. tostring(cmdIDValue), 
								"Command2_OnVR"  .. tostring(cmdIDValue)
							}
						})
		:Do(function(_,data)
			grammarIDValue = data.params.grammarID
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
	
	end
end		

local function DeleteCommand(cmdIDValue)
	TestCaseNumber = TestCaseNumber + 1
	Test["DeleteCommand_".. tostring(TestCaseNumber)] = function(self)
		--mobile side: sending DeleteCommand request
		local cid = self.mobileSession:SendRPC("DeleteCommand",
		{
			cmdID = cmdIDValue
		})
		
		--hmi side: expect UI.DeleteCommand request
		EXPECT_HMICALL("UI.DeleteCommand", 
		{ 
			cmdID = cmdIDValue
		})
		:Do(function(_,data)
			--hmi side: sending UI.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand", 
		{ 
			cmdID = cmdIDValue
		})
		:Do(function(_,data)
			--hmi side: sending VR.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
					
		--mobile side: expect DeleteCommand response 
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		EXPECT_NOTIFICATION("OnHashChange")
	end
end


local function OpenUIMenu()
	TestCaseNumber = TestCaseNumber + 1
	Test["OpenUIMenu_" .. tostring(TestCaseNumber)] = function(self)
	
		--hmi side: sending UI.OnSystemContext notification 
		SendOnSystemContext(self,"MENU")
		
		--mobile side: expected OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = CurrentAudioStreamingState })

	end
end	

local function CloseUIMenu()
	TestCaseNumber = TestCaseNumber + 1
	Test["CloseUIMenu_" .. tostring(TestCaseNumber)] = function(self)
	
		--hmi side: sending UI.OnSystemContext notification 
		SendOnSystemContext(self,"MAIN")
		
		--mobile side: expected OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = CurrentAudioStreamingState })
		
	end
end	

--Send UI.OnCommand with cmdIDValue and appIDValue parameters(TriggerSource=MENU).
local function SendUIOnCommand(TestCaseName)
	Test[TestCaseName] = function(self)
	
	
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue
		})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
		
	end
end		


local function OpenVRMenu()
	TestCaseNumber = TestCaseNumber + 1
	Test["OpenVRMenu_" .. tostring(TestCaseNumber)] = function(self)
		
		--hmi side: Start VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Started",{})
		SendOnSystemContext(self,"VRSESSION")

		--mobile side: expected OnHMIStatus notification		
		if commonFunctions:isMediaApp() then
			EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"	},
					{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"	})
			:Times(2)
		else
			EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
		end

	end
end	

local function CloseVRMenu()
	TestCaseNumber = TestCaseNumber + 1
	Test["CloseVRMenu_" .. tostring(TestCaseNumber)] = function(self)
	
		--hmi side: Stop VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Stopped",{})
		SendOnSystemContext(self,"MAIN")		

		--mobile side: expected OnHMIStatus notification
		
		if commonFunctions:isMediaApp() then
			EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "VRSESSION", 	hmiLevel = "FULL", audioStreamingState = "AUDIBLE"		},
					{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"		})
			:Times(2)
		else
			EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
		end
	end
end	

--Send VR.OnCommand with cmdIDValue, appIDValue and grammarIDValue parameters(TriggerSource=VR)
local function SendVROnCommand(TestCaseName)
	Test[TestCaseName] = function(self)
		
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			grammarID = grammarIDValue
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
	end
end	

local function SetTestingCommandID(id)
	Test["SetTestingCommandID_" .. id] = function(self)
		cmdIDValue = id
		print("")
		print("------------------------------------------------------------------")
	end
end



--Send UI.OnCommand and verify that SDL ignores this notification
local function UIOnCommand_IsIgnored(appIDValue, cmdIDValue, TestCaseName)
	Test[TestCaseName] = function(self)

		commonTestCases:DelayedExp(1000)
		
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue
		})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
		:Times(0)
		
	end
end
	
--Send VR.OnCommand and verify that SDL ignores this notification
local function VROnCommand_IsIgnored(appIDValue, cmdIDValue, grammarIDValue, TestCaseName)
	Test[TestCaseName] = function(self)
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			grammarID = grammarIDValue
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
		:Times(0)
		
	end
end

--Send both UI.OnCommand and VR.OnCommand and verify that SDL ignores this notification
local function OnCommand_IsIgnored(cmdIDValue1, TestCaseName)
	
	OpenUIMenu()
	UIOnCommand_IsIgnored(appIDValue, cmdIDValue1, "UI"..TestCaseName)
	CloseUIMenu()
	
	OpenVRMenu()
	VROnCommand_IsIgnored(appIDValue, cmdIDValue1, grammarIDValue, "VR"..TestCaseName)
	CloseVRMenu()	
end


--Send VR.OnCommand with invalid appID and verify that SDL ignores this notification
local function OnCommand_appID_IsInvalid_IsIgnored(appIDValue1, TestCaseName)
	
	OpenUIMenu()
	UIOnCommand_IsIgnored(appIDValue1, cmdIDValue, "UI"..TestCaseName)
	CloseUIMenu()
	
	OpenVRMenu()
	VROnCommand_IsIgnored(appIDValue1, cmdIDValue, grammarIDValue, "VR"..TestCaseName)
	CloseVRMenu()	
end

--Send VR.OnCommand with invalid grammarID and verify that SDL ignores this notification
local function OnCommand_grammarID_IsInvalid_IsIgnored(grammarIDValue1, TestCaseName)
	
	OpenVRMenu()
	VROnCommand_IsIgnored(appIDValue, cmdIDValue, grammarIDValue1, "VR"..TestCaseName)
	CloseVRMenu()	
end

--TriggerSource: MENU, VR (KEYBOARD is not used for OnCommand)
local function verifyOnCommandwithValidCommandID(id, TestCaseName)
	
	SetTestingCommandID(id)
	
	AddCommand(id)

	OpenUIMenu()
	SendUIOnCommand("UI" .. TestCaseName)
	CloseUIMenu()
				
	OpenVRMenu()
	SendVROnCommand("VR" .. TestCaseName)			
	CloseVRMenu()
	
	DeleteCommand(id)
	
end

	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()
	
	--2. Update policy to allow request
	local keep_context = true
	local steal_focus = true
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--policyTable:precondition_updatePolicyAndAllowFunctionGroup({"FULL", "LIMITED"}, keep_context, steal_focus)

    --TODO: Will be updated after policy flow implementation
	--policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"}) -- This function will create a policy table, backup sdl_preloaded_pt.json in sdl/bin folder, overwrite sdl_preloaded_pt.json by new policy table. 
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

			
	----Get appID Value on HMI side
	function Test:GetAppID()
		appIDValue = self.applications[appNameValue]
		print("appID value on HMI side: "..appIDValue)
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
----------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-177: OnCommand_v2_0
	
	--Verification criteria: 
		--1. When the user triggers any command on persistent display command menu, OnCommand notification is returned to the app with corresponding command identifier and MENU trigger source.
		--2. When the user triggers any command via VR, OnCommand notification is returned to the app with corresponding command identifier and VR trigger source.
----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. cmdID: type=Integer, minvalue=0, maxvalue=2000000000
	--2. triggerSource: type=TriggerSource: MENU, VR (KEYBOARD is not used for OnCommand)
----------------------------------------------------------------------------------------------
	
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")


----------------------------------------------------------------------------------------------
--Test case #1: Checks OnCommand is sent to application SDL after receiving UI.OnCommand and VR.OnCommand with CommandID is valid values
----------------------------------------------------------------------------------------------

	verifyOnCommandwithValidCommandID(0, "OnCommand_cmdID_IsLowerBound")
	verifyOnCommandwithValidCommandID(2000000000, "OnCommand_cmdID_IsUpperBound")



----------------------------------------------------------------------------------------------
--Test case #2: Checks OnCommand is NOT sent to application SDL after receiving UI.OnCommand and VR.OnCommand with CommandID, appID, grammarID  are invalid values
----------------------------------------------------------------------------------------------

	--Precondition
	local CommandID = 1
	SetTestingCommandID(CommandID)
	AddCommand(CommandID)
	
	--Verify CommandID is invalid
	local InvalidcmdIDs = 	{	{value = -1, 			name = "IsOutLowerBound_IsNegative"},
								{value = 2000000001, 	name = "IsOutUpperBound"},
								{value = 2, 			name = "IsNonExist"},
								{value = "1", 			name = "IsWrongType"}}
								
	for i =1, #InvalidcmdIDs do
		OnCommand_IsIgnored(InvalidcmdIDs[i].value, "OnCommand_cmdID_" ..InvalidcmdIDs[i].name .. "_IsIgnored")	
	end
	----------------------------------------------------------------------------------------------
	
	
	--Verify appID is invalid: nonexistent, empty, wrong type values
	local Invalid_appIDs = 	{	{value = 123321, 	name = "IsNonexistent"},
								{value = "", 		name = "IsEmpty"}}
								
	for i =1, #Invalid_appIDs do
		OnCommand_appID_IsInvalid_IsIgnored(Invalid_appIDs[i].value, "OnCommand_appID_" ..Invalid_appIDs[i].name .. "_IsIgnored")	
	end

	--Verify appIDValue is wrong type
	--{value = tostring(appIDValue), 			name = "IsWrongType"}
	OpenUIMenu()
	
	Test["UIOnCommand_appID_IsWrongType_IsIgnored"] = function(self)

		commonTestCases:DelayedExp(1000)
		
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = tostring(appIDValue)
		})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
		:Times(0)
		
	end
	
	CloseUIMenu()
	
	OpenVRMenu()

	Test["VROnCommand_appID_IsWrongType_IsIgnored"] = function(self)
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = 2,
			appID = tostring(appIDValue),
			grammarID = grammarIDValue
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
		:Times(0)
		
	end	
	CloseVRMenu()	
	
	
	----------------------------------------------------------------------------------------------
	
	--Verify grammarID is invalid: nonexistent, empty, wrong type values
	local Invalid_grammarIDs = 	{	{value = 123321, 	name = "IsNonexistent"},
									{value = "", 		name = "IsEmpty"}}
								
	for i =1, #Invalid_grammarIDs do
		OnCommand_grammarID_IsInvalid_IsIgnored(Invalid_grammarIDs[i].value, "OnCommand_grammarID_" ..Invalid_grammarIDs[i].name .. "_IsIgnored")	
	end	
	
	
	--Verify appIDValue is wrong type
	--{value = tostring(grammarIDValue), 		name = "IsWrongType"}
	OpenVRMenu()
	
	Test["VROnCommand_grammarID_IsWrongType_IsIgnored"] = function(self)
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = 2,
			appID = appIDValue,
			grammarID = tostring(grammarIDValue)
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
		:Times(0)
		
	end
	
	CloseVRMenu()	
	----------------------------------------------------------------------------------------------

	
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


	
	--1.1. Verify UI.OnCommand with invalid Json syntax
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_InvalidJsonSyntax()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		--":" is changed by ";" after "jsonrpc"
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1}}')
		  self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1}}')
	
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseUIMenu()
	
	

	--1.2. Verify VR.OnCommand with invalid Json syntax
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_InvalidJsonSyntax()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		--":" is changed by ";" after "jsonrpc"
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"VR.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1,"grammarID":'..grammarIDValue..'}}')
		  self.hmiConnection:Send('{"jsonrpc";"2.0","method":"VR.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1,"grammarID":'..grammarIDValue..'}}')
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()
	
	
	
	--2.1. Verify UI.OnCommand with invalid structure
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_InvalidStructure()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1}}')
		  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnCommand","appID":'.. appIDValue ..',"cmdID":1}}')
	
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseUIMenu()
	
	

	--2.2. Verify VR.OnCommand with invalid structure
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_InvalidStructure()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"VR.OnCommand","params":{"appID":'.. appIDValue ..',"cmdID":1,"grammarID":'..grammarIDValue..'}}')
		  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"VR.OnCommand","appID":'.. appIDValue ..',"cmdID":1,"grammarID":'..grammarIDValue..'}}')
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()
	
	
	
	
	--3.1. Verify UI.OnCommand with FakeParams
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_FakeParams()
	
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			fake = 123
		})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
		:ValidIf (function(_,data)
			if data.payload.fake then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
	
	end
	
	CloseUIMenu()
	
	

	--3.2. Verify VR.OnCommand with FakeParams
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_FakeParams()
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			grammarID = grammarIDValue,
			fake = 123
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
		:ValidIf (function(_,data)
			if data.payload.fake then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)
		
	end
	
	CloseVRMenu()
	
	

	
	--3.1. Verify UI.OnCommand with FakeParameterIsFromAnotherAPI
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_FakeParameterIsFromAnotherAPI()
	
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			sliderPosition = 5
		})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "MENU"})
		:ValidIf (function(_,data)
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL resends sliderPosition parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
	
	end
	
	CloseUIMenu()
	
	

	--3.2. Verify VR.OnCommand with FakeParameterIsFromAnotherAPI
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_FakeParameterIsFromAnotherAPI()
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue,
			grammarID = grammarIDValue,
			sliderPosition = 5
		})
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = cmdIDValue, triggerSource= "VR"})
		:ValidIf (function(_,data)
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL resends sliderPosition parameter to mobile app ")
				return false
			else 
				return true
			end
		end)
		
	end
	
	CloseVRMenu()
	
	--4.1. Verify UI.OnCommand mandatory parameter
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_cmdID_IsMissed()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			--cmdID = cmdIDValue,
			appID = appIDValue
		})
	
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseUIMenu()
	
	OpenUIMenu()
	function Test:UIOnCommand_appID_IsMissed()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			cmdID = cmdIDValue
			--appID = appIDValue
		})
	
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseUIMenu()
	
	

	--4.2. Verify VR.OnCommand mandatory parameter
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_cmdID_IsMissed()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			--cmdID = cmdIDValue,
			appID = appIDValue,
			grammarID = grammarIDValue
		})
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()
	
	OpenVRMenu()
	function Test:VROnCommand_appID_IsMissed()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			--appID = appIDValue,
			grammarID = grammarIDValue
		})
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()
	
	OpenVRMenu()
	
	function Test:VROnCommand_grammarID_IsMissed()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			cmdID = cmdIDValue,
			appID = appIDValue
			--grammarID = grammarIDValue
		})
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()
		

	--5.1. Verify UI.OnCommand MissedAllPArameters
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_MissedAllPArameters()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("UI.OnCommand",
		{
			--cmdID = cmdIDValue,
			--appID = appIDValue
		})
	
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseUIMenu()
	
	

	--5.2. Verify VR.OnCommand MissedAllPArameters
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_MissedAllPArameters()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send UI.OnCommand 
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			--cmdID = cmdIDValue,
			--appID = appIDValue,
			--grammarID = grammarIDValue
		})
		   
		--mobile side: expect OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", {})
		:Times(0)
	end
	
	CloseVRMenu()


	
	
	--6.1. Verify UI.OnCommand with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------
	OpenUIMenu()
	
	function Test:UIOnCommand_SeveralNotifications_WithTheSameValues()
	
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 1, appID = appIDValue})
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 1, appID = appIDValue})
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 1, appID = appIDValue})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", 
										{cmdID = 1, triggerSource= "MENU"},
										{cmdID = 1, triggerSource= "MENU"},
										{cmdID = 1, triggerSource= "MENU"})
		:Times(3)
		
	
	end
	
	CloseUIMenu()
	
	

	--6.2. Verify VR.OnCommand with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_SeveralNotifications_WithTheSameValues()
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 1, appID = appIDValue,grammarID = grammarIDValue})
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 1, appID = appIDValue,grammarID = grammarIDValue})
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 1, appID = appIDValue,grammarID = grammarIDValue})
		
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", 
										{cmdID = 1, triggerSource= "VR"},
										{cmdID = 1, triggerSource= "VR"},
										{cmdID = 1, triggerSource= "VR"})
		:Times(3)
		
	end
	
	CloseVRMenu()
	
	
	
	--7.1. Verify UI.OnCommand with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------
	AddCommand(2)
	AddCommand(3)
	
	OpenUIMenu()
	
	function Test:UIOnCommand_SeveralNotifications_WithDifferentValues()
	
		--hmi side: sending UI.OnCommand notification			
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 1, appID = appIDValue})
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 2, appID = appIDValue})
		self.hmiConnection:SendNotification("UI.OnCommand", {cmdID = 3, appID = appIDValue})
				
		--mobile side: expected OnCommand notification
		EXPECT_NOTIFICATION("OnCommand", 
										{cmdID = 1, triggerSource= "MENU"},
										{cmdID = 2, triggerSource= "MENU"},
										{cmdID = 3, triggerSource= "MENU"})
		:Times(3)
		
	
	end
	
	CloseUIMenu()
	
	

	--7.2. Verify VR.OnCommand with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------
	OpenVRMenu()
	
	function Test:VROnCommand_SeveralNotifications_WithDifferentValues()
		--hmi side: sending VR.OnCommand notification			
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 1, appID = appIDValue,grammarID = grammarIDValue})
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 2, appID = appIDValue,grammarID = grammarIDValue})
		self.hmiConnection:SendNotification("VR.OnCommand", {cmdID = 3, appID = appIDValue,grammarID = grammarIDValue})
		
	
		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", 
										{cmdID = 1, triggerSource= "VR"},
										{cmdID = 2, triggerSource= "VR"},
										{cmdID = 3, triggerSource= "VR"})
		:Times(3)
		
	end
	
	CloseVRMenu()
	
	

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

		--Precondition: Build policy table file
		local PTName = policyTable:createPolicyTableWithoutAPI(APIName)
		
		--Precondition: Update policy table
		policyTable:updatePolicy(PTName)

		OnCommand_IsIgnored(1, "OnCommand_IsNotInPolicyTable_IsIgnored")
		

		
	----------------------------------------------------------------------------------------------
	--Test case #2: API is in policy table but user has not consented yet, SDL does not send it to mobile
	----------------------------------------------------------------------------------------------
		
		
		--Precondition: Build policy table file
		local keep_context = true
		local steal_focus = true
		local PTName = policyTable:createPolicyTable(APIName, {"FULL", "LIMITED"}, keep_context, steal_focus)
		
		--Precondition: Update policy table
		policyTable:updatePolicy(PTName)

		OnCommand_IsIgnored(1, "OnCommand_UserHasNotConsentedYet_IsIgnored")
		

	----------------------------------------------------------------------------------------------
	--Test case #3: API is in policy table but user disallows, SDL does not send it to mobile
	----------------------------------------------------------------------------------------------
			
		--Precondition: User does not allow function group
		policyTable:userConsent(false)		
		
		OnCommand_IsIgnored(1, "OnCommand_UserDisallowed_IsIgnored")
		
		--Postcondition: User allows function group
		policyTable:userConsent(true)	

end
--TODO: PT is blocked by ATF defect APPLINK-19188	
--ResultCodeChecks()
	
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
	---------------------------------------------------------------------------------------------------------------------------------------------

	
	--TC_GrammarID_03 (SDLAQ-TC-1246) is covered by TC OnCommand_cmdID_IsLowerBound, OnCommand_cmdID_IsUpperBound,..
	
	--39[P][MAN]_TC_CommandID_is_calculated_from_grammarID(APPLINK-18431) is covered by TC TC OnCommand_cmdID_IsLowerBound, OnCommand_cmdID_IsUpperBound,..
	
	--TC_AddCommand_01(SDLAQ-TC-31): is covered by AddCommand_PositiveCase (BLOCK VI) of ATF_AddCommand.lua
			
	-----------------------------------------------------------------------------------------------------------------------------------------
	
	-----------------------------------------------------------------------------------------------------------------------------------------
	-- Functions and variables.
	-----------------------------------------------------------------------------------------------------------------------------------------

	local GetAppID_Number = 0
	local function GetAppID(AppName)
		GetAppID_Number = GetAppID_Number + 1
		Test["GetAppID_" .. tostring(GetAppID_Number)]=function(self)
			appIDValue = self.applications[AppName]
			print("appID value on HMI side: "..appIDValue)
		end
		
	end

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
			self.mobileSession1:ExpectResponse(CorIdRegister, {syncMsgVersion = config.syncMsgVersion})
			:Timeout(2000)

			--mobile side: expect notification
			self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:Timeout(2000)
	end	
	
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
			self.mobileSession2:ExpectResponse(CorIdRegister, {syncMsgVersion = config.syncMsgVersion})
			:Timeout(2000)

			--mobile side: expect notification
			self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:Timeout(2000)
	end	
	
	function Test:registerAppInterface4()
			--mobile side: sending request 
			local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface", config.application4.registerAppInterfaceParams)

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
			application = 
			{
				appName = config.application4.registerAppInterfaceParams.appName
			}
			})
			:Do(function(_,data)
			self.applications[config.application4.registerAppInterfaceParams.appName] = data.params.application.appID					
			end)

			--mobile side: expect response
			self.mobileSession3:ExpectResponse(CorIdRegister, {syncMsgVersion = config.syncMsgVersion})
			:Timeout(2000)

			--mobile side: expect notification
			self.mobileSession3:ExpectNotification("OnHMIStatus", 
			{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
			})
			:Timeout(2000)
	end	
	
	function Test:registerAppInterface5()
			--mobile side: sending request 
			local CorIdRegister = self.mobileSession4:SendRPC("RegisterAppInterface", config.application5.registerAppInterfaceParams)

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
			application = 
			{
				appName = config.application5.registerAppInterfaceParams.appName
			}
			})
			:Do(function(_,data)
				self.applications[config.application5.registerAppInterfaceParams.appName] = data.params.application.appID					
			end)

			--mobile side: expect response
			self.mobileSession4:ExpectResponse(CorIdRegister, {syncMsgVersion = config.syncMsgVersion})
			:Timeout(2000)

			--mobile side: expect notification
			self.mobileSession4:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:Timeout(2000)
	end	

		
	-----------------------------------------------------------------------------------------------------------------------------------------
	-- Preconditions.
	-----------------------------------------------------------------------------------------------------------------------------------------
	
	--Create second session
	function Test:Precondition_SecondSession()
	
		-- Connected expectation
		--mobile side: start new session
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
		
	end		
	
	--Create third Session
	function Test:Precondition_ThirdSession()
		--mobile side: start new session
		self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession2:StartService(7)
	end	
	
	--Create fourth Session
	function Test:Precondition_Fourth_Session()
		--mobile side: start new session
		self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession3:StartService(7)
	end	
	
	--Create fiffth Session
	function Test:Precondition_Fiffth_Session()
		--mobile side: start new session
		self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession4:StartService(7)
	end	
	

	function Test:Precondition_Register_Second_App()
		self:registerAppInterface2()
	end
	
	function Test:Precondition_Register_Third_App()
		self:registerAppInterface3()
	end
	
	function Test:Precondition_Register_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:Precondition_Register_Fiffth_App()
		self:registerAppInterface5()
	end
		
	AddCommand(1001)
	
	------------------------------------------------------------------------------------------------------
	
	
	commonFunctions:newTestCasesGroup("***APPLINK-18430:SDL calculates appID depending on proper grammarID provided by HMI in case multiple apps are registered***")
	
	
	commonFunctions:newTestCasesGroup("******************************Step1:Sends VR.OnCommand() to App1******************************")
	
	OpenVRMenu()
	
	--Send VR.OnCommand() to App1
	function Test:Send_VROnCommand_To_App1()
				
		--hmi side: sending UI.OnCommand notification					
		self.hmiConnection:SendNotification("VR.OnCommand",
		{
			
			cmdID = 1001,
			appID = appIDValue,
			grammarID = grammarIDValue

		})
		

		--mobile side: expect OnCommand notification 
		EXPECT_NOTIFICATION("OnCommand", {cmdID = 1001, triggerSource= "VR"})
	
	end
	
	CloseVRMenu()
	-------------------------------------------------------------------------------------------------------------------------

	commonFunctions:newTestCasesGroup("******************************Step2:Sends VR.OnCommand() to App2******************************")
	
	--Activate App2
	function Test:Step2_Activate_App2()

		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)
		 
		if  config.application2.registerAppInterfaceParams.isMediaApplication == true or
			 config.application2.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
			 config.application2.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" 
		then
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		else
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
	end
	-------------------------------------------------------------------------------------------------------
	
	--Add a command to App2
	function Test:Step2_AddCommand_To_App2()
	
		--mobile side: sending AddCommand request
		local cid = self.mobileSession1:SendRPC("AddCommand",
												{
													cmdID = 2001,
													menuParams = 	
													{ 	
														position = 0,
														menuName ="Command2001"
													}, 
													vrCommands = 
													{ 
														"VRCommand2001"
													}
												})
		--hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 2001,										
							menuParams = 
							{
								menuName ="Command2001"
							}
						})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
			
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 2001,							
							type = "Command",
							vrCommands = 
							{
								"VRCommand2001"
							}
						})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			grammarIDValue2 = data.params.grammarID
			
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		-- --mobile side: expect AddCommand response
		self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		self.mobileSession1:ExpectNotification("OnHashChange",{})
	end
	-------------------------------------------------------------------------------------------			
	GetAppID(config.application2.registerAppInterfaceParams.appName)
	-------------------------------------------------------------------------------------------
	
	--Send VR.OnCommand() to App2
	function Test:Send_VROnCommand_To_App2()
	
		--hmi side: Start VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Started",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application2.registerAppInterfaceParams.appName], systemContext = "VRSESSION" })
		
		--hmi side: sending several VR.OnCommand notifications			
			self.hmiConnection:SendNotification("VR.OnCommand",
			{
				cmdID = 2001,
				appID = appIDValue,
				grammarID = grammarIDValue2,
			})
			
		--hmi side: Stop VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Stopped",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application2.registerAppInterfaceParams.appName], systemContext = "MAIN" })		

		-- --mobile side: expected OnHMIStatus notification
	   if   config.application2.registerAppInterfaceParams.isMediaApplication == true or
			config.application2.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
			config.application2.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" then
				 
				self.mobileSession1:ExpectNotification("OnHMIStatus",
					{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
					{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
					{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
				:Times(4)
		else 

				self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"} ): Times(2)
		end
		--mobile side: expect OnCommand notification 
		self.mobileSession1:ExpectNotification("OnCommand", {cmdID = 2001, triggerSource= "VR"})

	
	end
	-------------------------------------------------------------------------------------------------------------------------
	
	commonFunctions:newTestCasesGroup("******************************Step3:Sends VR.OnCommand() to App3******************************")
	
	--Activate App3
	function Test:Step3_Activate_App3()

			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			if   config.application3.registerAppInterfaceParams.isMediaApplication == true or
				 config.application3.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
				 config.application3.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" then
			
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			
			else
			
				self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				
			end
	end
	-------------------------------------------------------------------------------------------------------
	
	--Add a Command for App3
	function Test:Step3_AddCommand_To_App3()
	
			--mobile side: sending AddCommand request
			local cid = self.mobileSession2:SendRPC("AddCommand",
													{
														cmdID = 3001,
														menuParams = 	
														{ 	
															position = 0,
															menuName ="Command3001"
														}, 
														vrCommands = 
														{ 
															"VRCommand3001"
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = 3001,										
								menuParams = 
								{
									menuName ="Command3001"
								}
							})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
				
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = 3001,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand3001"
								}
							})
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response
				grammarIDValue3 = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			-- --mobile side: expect AddCommand response
			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

			--mobile side: expect OnHashChange notification
			self.mobileSession2:ExpectNotification("OnHashChange",{})
	end
	
	------------------------------------------------------------------------------------------------------------
	GetAppID(config.application3.registerAppInterfaceParams.appName)
	------------------------------------------------------------------------------------------------------------
	
	--Send VR.OnCommand() to App3
	function Test:Send_VR_OnCommand_To_App3()
	
		--hmi side: Start VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Started",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application3.registerAppInterfaceParams.appName], systemContext = "VRSESSION" })
		
		--hmi side: sending several VR.OnCommand notifications			
			self.hmiConnection:SendNotification("VR.OnCommand",
			{
				cmdID = 3001,
				appID = appIDValue,
				grammarID = grammarIDValue3,
			})
			
		--hmi side: Stop VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Stopped",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application3.registerAppInterfaceParams.appName], systemContext = "MAIN" })		

		--mobile side: expected OnHMIStatus notification
		if  config.application3.registerAppInterfaceParams.isMediaApplication == true or
			config.application3.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
			config.application3.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION"then
			
			self.mobileSession2:ExpectNotification("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			:Times(4)
			
		else 

			self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"} ): Times(2)
		end
		
		--mobile side: expect OnCommand notification 
		self.mobileSession2:ExpectNotification("OnCommand", {cmdID = 3001, triggerSource= "VR"})
	
	end
	-------------------------------------------------------------------------------------------------------------------------
	
	commonFunctions:newTestCasesGroup("******************************Step4:Sends VR.OnCommand() to App4******************************")
	
	--Activate App4
	function Test:Step4_Activate_App4()

			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application4.registerAppInterfaceParams.appName]})

			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			if   config.application4.registerAppInterfaceParams.isMediaApplication == true or
				 config.application4.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
				 config.application4.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" then
			
				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			
			else
			
				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				
			end
	end
	-------------------------------------------------------------------------------------------------------
	
	--Add a Command for App4
	function Test:Step4_AddCommand_To_App4()
	
			--mobile side: sending AddCommand request
			local cid = self.mobileSession3:SendRPC("AddCommand",
													{
														cmdID = 4001,
														menuParams = 	
														{ 	
															position = 0,
															menuName ="Command4001"
														}, 
														vrCommands = 
														{ 
															"VRCommand4001"
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = 4001,										
								menuParams = 
								{
									menuName ="Command4001"
								}
							})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
				
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = 4001,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand4001"
								}
							})
			:Do(function(_,data)
			
				--hmi side: sending VR.AddCommand response
				grammarIDValue4 = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect AddCommand response
			self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

			--mobile side: expect OnHashChange notification
			self.mobileSession3:ExpectNotification("OnHashChange",{})
	end
	
	------------------------------------------------------------------------------------------------------------
	GetAppID(config.application4.registerAppInterfaceParams.appName)
	------------------------------------------------------------------------------------------------------------
	
	--Send VR.OnCommand() to App4
	function Test:Send_VR_OnCommand_To_App4()
	
		--hmi side: Start VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Started",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application4.registerAppInterfaceParams.appName], systemContext = "VRSESSION" })
		
		--hmi side: sending several VR.OnCommand notifications			
			self.hmiConnection:SendNotification("VR.OnCommand",
			{
				cmdID = 4001,
				appID = appIDValue,
				grammarID = grammarIDValue4,
			})
			
		--hmi side: Stop VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Stopped",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application4.registerAppInterfaceParams.appName], systemContext = "MAIN" })		

		--mobile side: expected OnHMIStatus notification
		if  config.application4.registerAppInterfaceParams.isMediaApplication == true or
			config.application4.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
			config.application4.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION"then
			
			self.mobileSession3:ExpectNotification("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			:Times(4)
			
		else 

			self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"} ): Times(2)
		end
		
		--mobile side: expect OnCommand notification 
		self.mobileSession3:ExpectNotification("OnCommand", {cmdID = 4001, triggerSource= "VR"})
		:Times(1)
	
	end
--------------------------------------------------------------------------------------------------------------------------
	
	commonFunctions:newTestCasesGroup("******************************Step5:Sends VR.OnCommand() to App5******************************")
	
	--Activate App5
	function Test:Step5_Activate_App5()

			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application5.registerAppInterfaceParams.appName]})

			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			if   config.application5.registerAppInterfaceParams.isMediaApplication == true or
				 config.application5.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
				 config.application5.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" then
	
				self.mobileSession4:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			
			else
			
				self.mobileSession4:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				
			end
	end
	-------------------------------------------------------------------------------------------------------
	
	--Add a Command for App5
	function Test:Step5_AddCommand_To_App5()
	
			--mobile side: sending AddCommand request
			local cid = self.mobileSession4:SendRPC("AddCommand",
													{
														cmdID = 5001,
														menuParams = 	
														{ 	
															position = 0,
															menuName ="Command5001"
														}, 
														vrCommands = 
														{ 
															"VRCommand5001"
														}
													})
			--hmi side: expect UI.AddCommand request
			EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = 5001,										
								menuParams = 
								{
									menuName ="Command5001"
								}
							})
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
				
			--hmi side: expect VR.AddCommand request
			EXPECT_HMICALL("VR.AddCommand", 
							{ 
								cmdID = 5001,							
								type = "Command",
								vrCommands = 
								{
									"VRCommand5001"
								}
							})
			:Do(function(_,data)
			
				--hmi side: sending VR.AddCommand response
				grammarIDValue5 = data.params.grammarID
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect AddCommand response
			self.mobileSession4:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

			--mobile side: expect OnHashChange notification
			self.mobileSession4:ExpectNotification("OnHashChange",{})
	end
	
	------------------------------------------------------------------------------------------------------------
	GetAppID(config.application5.registerAppInterfaceParams.appName)
	------------------------------------------------------------------------------------------------------------
	
	--Send VR.OnCommand() to App5
	function Test:Send_VR_OnCommand_To_App5()
	
		--hmi side: Start VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Started",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application5.registerAppInterfaceParams.appName], systemContext = "VRSESSION" })
		
		--hmi side: sending several VR.OnCommand notifications			
			self.hmiConnection:SendNotification("VR.OnCommand",
			{
				cmdID = 5001,
				appID = appIDValue,
				grammarID = grammarIDValue5,
			})
			
		--hmi side: Stop VR and sending UI.OnSystemContext notification 
		self.hmiConnection:SendNotification("VR.Stopped",{})
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application5.registerAppInterfaceParams.appName], systemContext = "MAIN" })		

		--mobile side: expected OnHMIStatus notification
		if  config.application5.registerAppInterfaceParams.isMediaApplication == true or
			config.application5.registerAppInterfaceParams.appHMIType[1]=="NAVIGATION" or  
			config.application5.registerAppInterfaceParams.appHMIType[1]=="COMMUNICATION" 
		then
			self.mobileSession4:ExpectNotification("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
				{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
				{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			:Times(4)
			
		else 

			self.mobileSession4:ExpectNotification("OnHMIStatus",{ systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"} )
			:Times(2)
		end
		
		--mobile side: expect OnCommand notification 
		self.mobileSession4:ExpectNotification("OnCommand", {cmdID = 5001, triggerSource= "VR"})
	
	end
	---------------------------------------------------------------------------------------------------------------------------
	function Test:PostCondition_UnregisterApps()
			
		--Unregister App3
		local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
		self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		
		--Unregister App4
		local cid = self.mobileSession3:SendRPC("UnregisterAppInterface",{})
		self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		
		--Unregister App5
		local cid = self.mobileSession4:SendRPC("UnregisterAppInterface",{})
		self.mobileSession4:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		
	end

	--------------------------------------------------------------------------------------------------------------------------
	--Postcondition: 
	function Test:Postcondition_GetAppID1()
		appIDValue = self.applications[appNameValue]
		print("appID value on HMI side: "..appIDValue)
	end
end
	
SequenceChecks()


	
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-1305: HMI Status Requirements for OnCommand (FULL, LIMITED)
	
	--Verification criteria: 
		--1. None of the applications in HMI NONE or BACKGROUND receives OnCommand request.
		--2. The applications in HMI FULL don't reject OnCommand request.
		--3. The applications in HMI LIMITED don't reject OnCommand request.


local function verifyDifferentHMIStatus()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
	----------------------------------------------------------------------------------------------
	

	--1. HMI level is NONE

	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel()

	UIOnCommand_IsIgnored(appIDValue, cmdIDValue, "UIOnCommand_InNONE_HmiLevel_IsIgnored")
	VROnCommand_IsIgnored(appIDValue, cmdIDValue, grammarIDValue, "VROnCommand_InNONE_HmiLevel_IsIgnored")

	--Postcondition: Activate app
	commonSteps:ActivationApp(_, "ActivationApp_NONE_postcondition")	
	----------------------------------------------------------------------------------------------


	--2. HMI level is LIMITED
	if commonFunctions:isMediaApp() then
		-- Precondition: Change app to LIMITED
		commonSteps:ChangeHMIToLimited()
		
		SendUIOnCommand("UIOnCommand_InLIMITED_HmiLevel_IsIgnored")
					
		Test["OpenVRMenu_LIMITED"] = function(self)
		
			commonTestCases:DelayedExp(1000)
			
			--hmi side: Start VR and sending UI.OnSystemContext notification 
			self.hmiConnection:SendNotification("VR.Started",{})

			--mobile side: expected OnHMIStatus notification		
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE"})
		
		end
		
		SendVROnCommand("VROnCommand_InLIMITED_HmiLevel_IsIgnored")			
		
		Test["CloseVRMenu_LIMITED"] = function(self)
	
			commonTestCases:DelayedExp(1000)
			
			--hmi side: Stop VR and sending UI.OnSystemContext notification 
			self.hmiConnection:SendNotification("VR.Stopped",{})

			--mobile side: expected OnHMIStatus notification	
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
		end
			
		--Postcondition: Activate app
		commonSteps:ActivationApp(_, "ActivationApp_LIMITED_postcondition")	
	end
	----------------------------------------------------------------------------------------------


	--3. HMI level is BACKGROUND
	commonTestCases:ChangeAppToBackgroundHmiLevel()

	UIOnCommand_IsIgnored(appIDValue, cmdIDValue, "UIOnCommand_InBACKGROUND_HmiLevel_IsIgnored")
	VROnCommand_IsIgnored(appIDValue, cmdIDValue, grammarIDValue, "VROnCommand_InBACKGROUND_HmiLevel_IsIgnored")
	----------------------------------------------------------------------------------------------	
end

verifyDifferentHMIStatus()

	---------------------------------------------------------------------------------------------
	-------------------------------------------Post-conditions-----------------------------------
	---------------------------------------------------------------------------------------------

	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()                   

return Test