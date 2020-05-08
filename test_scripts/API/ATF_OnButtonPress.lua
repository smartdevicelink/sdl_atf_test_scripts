---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last modified date: 03/Dec/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnButton.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnButton.lua")
commonPreconditions:Connecttest_OnButtonSubscription("connecttest_OnButton.lua")
--Precondition: preparation connecttest_OnButton.lua
	f = assert(io.open('./user_modules/connecttest_OnButton.lua', "r"))

	fileContent = f:read("*all")
	f:close()

	local pattern2 = "%{%s-capabilities%s-=%s-%{.-%}"
	local pattern2Result = fileContent:match(pattern2)

	if pattern2Result == nil then 
		print(" \27[31m capabilities array is not found in /user_modules/connecttest_OnButton.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern2, '{capabilities = {button_capability("PRESET_0"),button_capability("PRESET_1"),button_capability("PRESET_2"),button_capability("PRESET_3"),button_capability("PRESET_4"),button_capability("PRESET_5"),button_capability("PRESET_6"),button_capability("PRESET_7"),button_capability("PRESET_8"),button_capability("PRESET_9"),button_capability("OK", true, false, true),button_capability("PLAY_PAUSE"),button_capability("SEEKLEFT"),button_capability("SEEKRIGHT"),button_capability("TUNEUP"),button_capability("TUNEDOWN"),button_capability("SEARCH")}')
	end

	f = assert(io.open('./user_modules/connecttest_OnButton.lua', "w+"))
	f:write(fileContent)
	f:close()

Test = require('user_modules/connecttest_OnButton')
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

APIName = "OnButtonPress" -- set API name
NewTestSuiteNumber = 0 -- use as subfix of test case "NewTestSuite" to make different test case name.

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 
Apps[1].isMedia = commonFunctions:isMediaApp()
Apps[2] = {}
Apps[2].appName = config.application2.registerAppInterfaceParams.appName 	
Apps[3] = {}
Apps[3].appName = config.application3.registerAppInterfaceParams.appName 	

if config.application1.registerAppInterfaceParams.isMediaApplication == true then
					
	ButtonNames_WithoutCUSTOM_BUTTON = {
						"OK",
						"PLAY_PAUSE",
						"SEEKLEFT",
						"SEEKRIGHT",
						"TUNEUP",
						"TUNEDOWN",
						"PRESET_0",
						"PRESET_1",
						"PRESET_2",
						"PRESET_3",
						"PRESET_4",
						"PRESET_5",
						"PRESET_6",
						"PRESET_7",
						"PRESET_8",
						"PRESET_9",
						"SEARCH"
					}
										
	ButtonNames_WithoutCUSTOM_BUTTON_OK = {
						"PLAY_PAUSE",
						"SEEKLEFT",
						"SEEKRIGHT",
						"TUNEUP",
						"TUNEDOWN",
						"PRESET_0",
						"PRESET_1",
						"PRESET_2",
						"PRESET_3",
						"PRESET_4",
						"PRESET_5",
						"PRESET_6",
						"PRESET_7",
						"PRESET_8",
						"PRESET_9",
						"SEARCH"
					}

else --Non-media app

-- According to APPLINK-14516:  The media buttons are Tune Up\Down, Seek Right\Left, and PRESET_0-PRESET_9.
	ButtonNames_WithoutCUSTOM_BUTTON = {
						"OK",
						"SEARCH"
					}
										
	ButtonNames_WithoutCUSTOM_BUTTON_OK = {
						"SEARCH"
					}	
end

-- group of media buttons, this group  should be update also with PRESETS 0-9 due to APPLINK-14516 (APPLINK-14503)
local MediaButtons = {
					"PLAY_PAUSE",
					"SEEKLEFT",
					"SEEKRIGHT",
					"TUNEUP",
					"TUNEDOWN",
					-- "PRESET_0",
					-- "PRESET_1",
					-- "PRESET_2",
					-- "PRESET_3",
					-- "PRESET_4",
					-- "PRESET_5",
					-- "PRESET_6",
					-- "PRESET_7",
					-- "PRESET_8",
					-- "PRESET_9"
				}
					
local ButtonNames_OK = {"OK"}						
local ButtonNames_CUSTOM_BUTTON = {"CUSTOM_BUTTON"}
local ButtonPressModes = {"SHORT", "LONG"}	
local CustomButtonIDs = {0, 65535}

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------
--Parameter: AppNumber is optional
local function ActivationApp(TestCaseName, AppNumber, SessionNumber)	

	Test[TestCaseName] = function(self)
		
		local Input_AppId = Apps[AppNumber].appID
		
		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Input_AppId})
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
		if SessionNumber == 1 then
			self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		elseif SessionNumber == 2 then
			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		elseif SessionNumber == 3 then
			self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		elseif SessionNumber == 4 then
			self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end		
	end
end
---------------------------------------------------------------------------------------------

--Functions to simulate action press button on HMI and verification on Mobile and HMI
---------------------------------------------------------------------------------------------
--1. Press button
function Test.pressButton(Input_Name, Input_ButtonPressMode)

	--hmi side: send OnButtonEvent, OnButtonPress
	Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONDOWN"})
	
	if Input_ButtonPressMode == "SHORT" then
	
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONUP"})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = Input_Name, mode = Input_ButtonPressMode})	
		
	else
	
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = Input_Name, mode = Input_ButtonPressMode})	
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONUP"})		
	end
end	

--2. Press CUSTOM_BUTTON
function Test.pressButton_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Input_appID)

	--hmi side: send OnButtonEvent, OnButtonPress
	Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONDOWN", customButtonID = Input_customButtonID, appID = Input_appID})
	
	if Input_ButtonPressMode == "SHORT" then
	
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONUP", customButtonID = Input_customButtonID, appID = Input_appID})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = Input_Name, mode = Input_ButtonPressMode, customButtonID = Input_customButtonID, appID = Input_appID})	
		
	else
	
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = Input_Name, mode = Input_ButtonPressMode, customButtonID = Input_customButtonID, appID = Input_appID})	
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = Input_Name, mode = "BUTTONUP", customButtonID = Input_customButtonID, appID = Input_appID})
		
	end
end

--Functions to verify result on Mobile
---------------------------------------------------------------------------------------------
--1. Verify press button result on mobile
function Test.verifyPressButtonResult(Input_Name, Input_ButtonPressMode)
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", 
												{buttonName = Input_Name, buttonEventMode = "BUTTONUP"},
												{buttonName = Input_Name, buttonEventMode = "BUTTONDOWN"})
		:Times(2)
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = Input_Name, buttonPressMode = Input_ButtonPressMode})
end	

--2. Verify press button result on mobile for CUSTOM_BUTTON
function Test.verifyPressButtonResult_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Input_appID)
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", 
												{buttonName = Input_Name, buttonEventMode = "BUTTONUP", customButtonID = Input_customButtonID},
												{buttonName = Input_Name, buttonEventMode = "BUTTONDOWN", customButtonID = Input_customButtonID})
		:Times(2)
		
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = Input_Name, buttonPressMode = Input_ButtonPressMode, customButtonID = Input_customButtonID})
end	

--3. Verify SDL ignores notification
function Test.verifySDLIgnoresNotification(OnButtonEventNumber)
		
		commonTestCases:DelayedExp(1000)
		
		if OnButtonEventNumber == nil then
			OnButtonEventNumber = 0
		end
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", {})
		:Times(OnButtonEventNumber)
					
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {})
		:Times(0)
end	

--Functions to create common test cases
---------------------------------------------------------------------------------------------

--1. Press button and SDL forwards the notification to Mobile
local function SendOnButtonPress(Input_Name, Input_ButtonPressMode, TestCaseName)

	if Input_Name == "OK" and Input_ButtonPressMode == "LONG" then
		--Do nothing
		--SDLAQ-CRS-876: OnButtonPress LONG  (3. HMI doesn't send the notification with a ButtonPressMode of LONG to SDL when "OK" button is pressed for 2 or more seconds. Only SHORT can be sent for "OK" button and it is not dependent from press duration)
	else
		Test[TestCaseName .. "_name_" .. Input_Name .."_mode_" .. Input_ButtonPressMode] = function(self)
			
				--Press button on HMI
				self.pressButton(Input_Name, Input_ButtonPressMode)
				
				--Verify result on Mobile
				self.verifyPressButtonResult(Input_Name, Input_ButtonPressMode)
		end		
	end	
end	

--2. Press button and SDL ignores the notification
local function SendOnButtonPress_IsIgnored(Input_Name, Input_ButtonPressMode, TestCaseName, OnButtonEventNumber)
	Test[TestCaseName .. "_name_" .. Input_Name .."_mode_" .. Input_ButtonPressMode] = function(self)
		
		--Press button on HMI
		self.pressButton(Input_Name, Input_ButtonPressMode)
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification(OnButtonEventNumber)
		
	end	
end	

--3. Press CUSTOM_BUTTON and SDL forwards the notification to Mobile
local function SendOnButtonPress_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Input_appNumber, TestCaseName)
	Test[TestCaseName .. "_name_" .. Input_Name .."_mode_" .. Input_ButtonPressMode .. "_customButtonID_" .. Input_customButtonID] = function(self)
		
		--Press button on HMI
		self.pressButton_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Apps[Input_appNumber].appID)
		
		--Verify result on Mobile
		self.verifyPressButtonResult_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Apps[Input_appNumber].appID)
		
	end	
end	

--4. Press CUSTOM_BUTTON and SDL ignores the notification
local function SendOnButtonPress_CUSTOM_BUTTON_IsIgnored(Input_Name, Input_ButtonPressMode, Input_customButtonID, Input_appNumber, TestCaseName)
	Test[TestCaseName .. "_name_" .. Input_Name .."_mode_" .. Input_ButtonPressMode .. "_customButtonID_" .. Input_customButtonID] = function(self)
		
		--Press button on HMI
		self.pressButton_CUSTOM_BUTTON(Input_Name, Input_ButtonPressMode, Input_customButtonID, Apps[Input_appNumber].appID)
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification()
		
	end	
end	
	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	commonSteps:DeleteLogsFileAndPolicyTable()

	-- Precondition: removing user_modules/connecttest_OnButton.lua
	function Test:Remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnButton.lua" )
	end
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()
		
	--2. Get appID Value on HMI side
	function Test:GetAppID()
		Apps[1].appID = self.applications[Apps[1].appName]
	end
		
	--4. Send Show request with buttonIDs are lower and upper bounds
	Test["Show_buttonID_IsLowerUpperBound"] = function(self)
	
		--mobile side: request parameters
		local Request = 
		{
			softButtons = 
			{
				{
					text = "Button1",
					systemAction = "DEFAULT_ACTION",
					type = "TEXT",
					isHighlighted = false,																
					softButtonID = CustomButtonIDs[1]
				},
				{
					text = "Button2",
					systemAction = "DEFAULT_ACTION",
					type = "TEXT",
					isHighlighted = false,																
					softButtonID = CustomButtonIDs[2]
				}
			}
		}
		
		--mobile side: sending Show request
		local cid = self.mobileSession:SendRPC("Show", Request)
		
		--hmi side: expect UI.Show request
		EXPECT_HMICALL("UI.Show")
		:Do(function(_,data)
			--hmi side: sending UI.Show response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	
		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })		
	end

	--5. SubscribeButton
	for i=1,#ButtonNames_WithoutCUSTOM_BUTTON do					
		Test["SubscribeButton_" .. tostring(ButtonNames_WithoutCUSTOM_BUTTON[i])] = function(self)

			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
			{
				buttonName = ButtonNames_WithoutCUSTOM_BUTTON[i]

			})

			--expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = Apps[1].appID, isSubscribed = true, name = ButtonNames_WithoutCUSTOM_BUTTON[i]})

			--mobile side: expect SubscribeButton response
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
			
			EXPECT_NOTIFICATION("OnHashChange", {})	
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
----------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-175: OnButtonPress_v2_0: Notifies application of LONG/SHORT press events for buttons to which the application is subscribed.
	--SDLAQ-CRS-875: OnButtonPress SHORT
	--SDLAQ-CRS-876: OnButtonPress LONG
	--APPLINK-9736: SDL must ignore the invalid notifications from HMI
	
	--Verification criteria: 
		--1. OnButtonPress of LONG is sent by SDL on each long press of every subscribed hardware or SW preset HMI button.
		--2. OnButtonPress of LONG is sent by SDL on each long press of every subscribed custom HMI button.
		--3. OnButtonPress of SHORT is sent by SDL on each short press of every subscribed hardware or SW preset HMI button.
		--4. OnButtonPress of SHORT is sent by SDL on each short press of every subscribed custom HMI button.
----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. buttonName: type=ButtonName
	--2. buttonPressMode: type=ButtonPressMode
	--3. customButtonID: type=Integer, minvalue=0, maxvalue=65536
	--4. appID
----------------------------------------------------------------------------------------------
		
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")

----------------------------------------------------------------------------------------------
--Test case #1: Checks OnButtonPress notification with valid values of buttonName, buttonPressMode and customButtonID parameters
----------------------------------------------------------------------------------------------

	local function verifyOnButtonPressNotification_validValues(TestCaseName)

		--Verify buttonName and buttonPressMode parameters
		for i =1, #ButtonNames_WithoutCUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				SendOnButtonPress(ButtonNames_WithoutCUSTOM_BUTTON[i], ButtonPressModes[j], TestCaseName)
			end
		end
		

		--Verify customButtonID parameter
		for i =1, #ButtonNames_CUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				for n = 1, #CustomButtonIDs do
					SendOnButtonPress_CUSTOM_BUTTON(ButtonNames_CUSTOM_BUTTON[i], ButtonPressModes[j], CustomButtonIDs[n], 1, TestCaseName)
				end
			end
		end
	end

	verifyOnButtonPressNotification_validValues("OnButtonPress")

----------------------------------------------------------------------------------------------
--Test case #2: Checks OnButtonPress is NOT sent to application after SDL received OnButtonPress with invalid buttonName and buttonPressMode
----------------------------------------------------------------------------------------------

	local function verifyOnButtonPressNotification_InvalidValues()

		--Verify buttonName is invalid value
		local InvalidButtonNames = {
										{value = "", name = "IsEmtpy"},
										{value = "ANY", name = "NonExist"},
										{value = 123, name = "WrongDataType"}
									}
									
		for i =1, #InvalidButtonNames do
			for j =1, #ButtonPressModes do
				SendOnButtonPress_IsIgnored(InvalidButtonNames[i].value, ButtonPressModes[j], "OnButtonPress_buttonName_IsInvalid_" .. InvalidButtonNames[i].name)
			end
		end
		
		
		--Verify buttonPressMode is invalid value
		local InvalidButtonPressModes = {
											{value = "", name = "IsEmtpy"},
											{value = "ANY", name = "NonExist"},
											{value = 123, name = "WrongDataType"}
										}
		
		
		for j =1, #InvalidButtonPressModes do
			for i =1, #ButtonNames_WithoutCUSTOM_BUTTON do
				SendOnButtonPress_IsIgnored(ButtonNames_WithoutCUSTOM_BUTTON[i], InvalidButtonPressModes[j].value, "OnButtonPress_buttonPressMode_IsInvalid_" .. InvalidButtonPressModes[j].name, 2)
			end
		end
		

		--Verify customButtonID is invalid value
		local InvalidCustomButtonIDs = {
											{value = CustomButtonIDs[1]-1, name = "IsOutLowerBound"},
											{value = CustomButtonIDs[2] + 1, name = "IsOutUpperBound"},
											{value = "123", name = "WrongDataType"}
										}
		local appNumber = 1
		for i =1, #ButtonNames_CUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				for n = 1, #InvalidCustomButtonIDs do
					SendOnButtonPress_CUSTOM_BUTTON_IsIgnored(ButtonNames_CUSTOM_BUTTON[i], ButtonPressModes[j], InvalidCustomButtonIDs[n].value, appNumber, "OnButtonPress_customButtonID_IsInvalid")
				end
			end
		end
		
		--Verify appID is invalid value.
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check invalid appID")
		local Invalid_appIDs = {
											{value = 66666, name = "IsNonexistent"},
											{value = "1", name = "IsWrongDataType"},
											{value = "", name = "IsEmpty"}
										}
		for i  = 1, #Invalid_appIDs do
			Test["OnButtonPress_appID_" .. Invalid_appIDs[i].name]  = function(self)
				
				--Press button on HMI
				self.pressButton_CUSTOM_BUTTON("PRESET_0", "SHORT", 1, Invalid_appIDs[i].value)
				
				--Verify result on Mobile
				self.verifySDLIgnoresNotification()
				
			end		
		end
	end
	
	verifyOnButtonPressNotification_InvalidValues()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
	--APPLINK-9736: SDL must ignore the invalid notifications from HMI
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
	
	--1. Verify OnButtonPress with invalid Json syntax
	----------------------------------------------------------------------------------------------
	function Test:OnButtonPress_InvalidJsonSyntax()
		--hmi side: send OnButtonPress 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"jsonrpc";"2.0","params":{"mode":"SHORT","name":"SEARCH"},"method":"Buttons.OnButtonPress"}')
	
		self.verifySDLIgnoresNotification()
	end
		
	--2. Verify OnButtonPress with invalid structure
	----------------------------------------------------------------------------------------------	
	function Test:OnButtonPress_InvalidStructure()
		--hmi side: send OnButtonPress 
		--method is moved into params parameter
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"mode":"SHORT","name":"SEARCH","method":"Buttons.OnButtonPress"}}')
	
		self.verifySDLIgnoresNotification()
	end
		
	--3. Verify OnButtonPress with FakeParams
	----------------------------------------------------------------------------------------------
	function Test:OnButtonPress_FakeParams()

		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT", fake = 123})	
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", {buttonName = "SEARCH", buttonEventMode = "BUTTONDOWN"},
											{buttonName = "SEARCH", buttonEventMode = "BUTTONUP"})
		:Times(2)
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = "SEARCH", buttonPressMode = "SHORT"})
		:ValidIf(function(_,data)
								
			if data.payload.fake then
				commonFunctions:printError(" SDL forwards fake parameter to mobile ")
				return false
			else
				return true
			end
		end)
		
	end
	
	--4. Verify OnButtonPress with FakeParameterIsFromAnotherAPI
	function Test:OnButtonPress_FakeParameterIsFromAnotherAPI()
	
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT", sliderPosition = 1})	
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", {buttonName = "SEARCH", buttonEventMode = "BUTTONDOWN"},
											{buttonName = "SEARCH", buttonEventMode = "BUTTONUP"})
		:Times(2)
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = "SEARCH", buttonPressMode = "SHORT"})
		:ValidIf(function(_,data)
								
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL forwards fake parameter to mobile ")
				return false
			else
				return true
			end
		end)
		
	end	
	
	--5. Verify OnButtonPress misses mandatory parameter
	----------------------------------------------------------------------------------------------
	function Test:OnButtonPress_name_IsMissed()
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{mode = "SHORT"})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification(2)		
	end
	
	function Test:OnButtonPress_mode_IsMissed()
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH"})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification(2)		
	end
	
	function Test:OnButtonPress_appID_IsMissed()
		
		--hmi side: send OnButtonEvent, OnButtonPress
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = CustomButtonIDs[1]})
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = CustomButtonIDs[1]})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = CustomButtonIDs[1]})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification()		
	end

	function Test:OnButtonPress_customButtonID_IsMissed()
		
		--hmi side: send OnButtonEvent, OnButtonPress
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", appID = Apps[1].appID})
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONUP", appID = Apps[1].appID})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "CUSTOM_BUTTON", mode = "SHORT", appID = Apps[1].appID})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification()		
	end
	
	function Test:OnButtonPress_customButtonID_and_appID_AreMissed()
		
		--hmi side: send OnButtonEvent, OnButtonPress
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONDOWN"})
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONUP"})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "CUSTOM_BUTTON", mode = "SHORT"})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification()		
	end
	
	--6. Verify OnButtonPress MissedAllPArameters: The same as case 5.
	----------------------------------------------------------------------------------------------
	function Test:OnButtonPress_AllParameters_AreMissed()
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification(2)		
	end
	
	--7. Verify OnButtonPress with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------	
	function Test:OnButtonPress_SeveralNotifications_WithTheSameValues()
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT"})
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", 	{buttonName = "SEARCH", buttonEventMode = "BUTTONDOWN"},
												{buttonName = "SEARCH", buttonEventMode = "BUTTONUP"})
		:Times(2)
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = "SEARCH", buttonPressMode = "SHORT"})
		:Times(3)
		
	end
			
	--8. Verify UI.OnButtonPress with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------
	function Test:OnButtonPress_SeveralNotifications_WithDifferentValues()
		--hmi side: send OnButtonEvent, OnButtonPress
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONDOWN"})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "SEARCH", mode = "BUTTONUP"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "SHORT"})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "SEARCH", mode = "LONG"})
		
		--mobile side: expected OnButtonEvent notification
		EXPECT_NOTIFICATION("OnButtonEvent", 	{buttonName = "SEARCH", buttonEventMode = "BUTTONDOWN"},
												{buttonName = "SEARCH", buttonEventMode = "BUTTONUP"})
		:Times(2)
		
		--mobile side: expected OnButtonPress notification
		EXPECT_NOTIFICATION("OnButtonPress", 	{buttonName = "SEARCH", buttonPressMode = "SHORT"},
												{buttonName = "SEARCH", buttonPressMode = "LONG"})
		:Times(2)
	end		
end

SpecialResponseChecks()	
		
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

--Requirement id in JAMA:
	--1. SDLAQ-CRS-2909: OnButtonPress with unknown buttonID from HMI
	--2. APPLINK-20216: Send No OnButtonPress/OnButtonEvent to FullHmiLevelApplication in case buttons of this app is not subcribled
	--3. SDLAQ-CRS-3068: OnButtonPress to media app in FULL
	--4. SDLAQ-CRS-3069: OnButtonPress to media app in LIMITED

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")
	----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("SDLAQ-CRS-2909: OnButtonPress with unknown buttonID from HMI")
	--1. SDLAQ-CRS-2909: OnButtonPress with unknown buttonID from HMI
	function Test:OnButtonPress_WithUnknownButtonID()
	
		local UnknowButtonID = 2
		
		--hmi side: send OnButtonEvent, OnButtonPress
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = UnknowButtonID, appID = Apps[1].appID})
		Test.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = UnknowButtonID, appID = Apps[1].appID})
		Test.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = UnknowButtonID, appID = Apps[1].appID})	
		
		--Verify result on Mobile
		self.verifySDLIgnoresNotification()		
	end
	
	----------------------------------------------------------------------------------------------
	
	--2. APPLINK-20216: Send No OnButtonPress/OnButtonEvent to FullHmiLevelApplication in case buttons of this app is not subcribled
	commonFunctions:newTestCasesGroup("APPLINK-20216: Send No OnButtonPress/OnButtonEvent to FullHmiLevelApplication in case buttons of this app is not subcribled")
	
	-- Precondition 1: Opening new session
	function Test:AddNewSession2()
	
	  -- Connected expectation
		self.mobileSession2 = mobile_session.MobileSession(Test,Test.mobileConnection)
		
		self.mobileSession2:StartService(7)
	end	
	
	function Test:Register_Media_App2()

		--mobile side: RegisterAppInterface request 
		config.application2.registerAppInterfaceParams.isMediaApplication = true
		config.application2.registerAppInterfaceParams.appHMIType = nil

		local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = config.application2.registerAppInterfaceParams.appName,
				isMediaApplication = true
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

	ActivationApp("Activation_Media_App2", 2, 2)	
	
	local function OnButtonPress_NotComeToFullHmiLevelApplicationDueToNotSubcrible(TestCaseName, ButtonName, buttonPressMode)
		Test[TestCaseName] = function(self)
			
			commonTestCases:DelayedExp(1000)
		
			--hmi side: send OnButtonEvent, OnButtonPress
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = ButtonName, mode = "BUTTONDOWN"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = ButtonName, mode = "BUTTONUP"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = ButtonName, mode = buttonPressMode})	
			
			--Verify result on Mobile for app1
			self.verifySDLIgnoresNotification(0)
			
			--Verify result on Mobile for app2 in Full
			--mobile side: expected OnButtonEvent notification
			self.mobileSession2:ExpectNotification("OnButtonEvent", {})
			:Times(0)
						
			--mobile side: expected OnButtonPress notification
			self.mobileSession2:ExpectNotification("OnButtonPress", {})
			:Times(0)	
		end
	end
	for i,v in ipairs({"SHORT", "LONG"}) do
		for i=1,#MediaButtons do
			OnButtonPress_NotComeToFullHmiLevelApplicationDueToNotSubcrible("NotComeToFullHmiLevelApplicationDueToNotSubcrible" .. MediaButtons[i] .. '_' .. tostring(v), MediaButtons[i], tostring(v))
		end
	end	
	
	commonFunctions:newTestCasesGroup("SDLAQ-CRS-3068: OnButtonPress to media app in FULL")
	--3. SDLAQ-CRS-3068: OnButtonPress to media app in FULL	
	local function SubscribeMediaButton(TestCaseName, ButtonName, session)
		Test[TestCaseName] = function(self)

			if session == 2 then
				--mobile side: sending SubscribeButton request
				cid = self.mobileSession2:SendRPC("SubscribeButton",{ buttonName = ButtonName})

				--expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = Apps[2].appID, isSubscribed = true, name = ButtonName})
				:Times(1)

				--mobile side: expect SubscribeButton response
				self.mobileSession2:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
				
				self.mobileSession2:ExpectNotification("OnHashChange", {})
				:Times(1)
			end

			if session == 3 then
			    --mobile side: sending SubscribeButton request
				cid = self.mobileSession3:SendRPC("SubscribeButton",{ buttonName = ButtonName})

				--expect Buttons.OnButtonSubscription
				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = Apps[3].appID, isSubscribed = true, name = ButtonName})
				:Times(1)

				--mobile side: expect SubscribeButton response
				self.mobileSession3:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
			
				self.mobileSession3:ExpectNotification("OnHashChange", {})
				:Times(1)
			end
		end		
	end

	for i=1, #MediaButtons do
		SubscribeMediaButton("App2SubscribeButton"..MediaButtons[i], MediaButtons[i], 2)
	end
	
	--Change app2 to NONE hmi level
	function Test:Deactivate_App2_To_None_Hmi_Level()

		--hmi side: sending BasicCommunication.OnExitApplication notification
		self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = Apps[2].appID, reason = "USER_EXIT"})

		self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	end	
			
	-- Precondition 2: Opening new session
	function Test:AddNewSession3()
	
	  -- Connected expectation
		self.mobileSession3 = mobile_session.MobileSession(Test,Test.mobileConnection)
		
		self.mobileSession3:StartService(7)
	end	
	
	function Test:Register_Media_App3()

		--mobile side: RegisterAppInterface request 
		config.application3.registerAppInterfaceParams.isMediaApplication = true
		config.application3.registerAppInterfaceParams.appHMIType = nil

		local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = config.application3.registerAppInterfaceParams.appName,
				isMediaApplication = true
			}
		})
		:Do(function(_,data)
			Apps[3].appID = data.params.application.appID
			self.applications[Apps[3].appName] = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(3000)

		self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	ActivationApp("Activation_Media_App3", 3, 3)	
	
	-- Subscribe App3 to MediaButtons
	 for i=1, #MediaButtons do
		 SubscribeMediaButton("App3SubscribeButton"..MediaButtons[i], MediaButtons[i], 3)
	 end
	
	function Test:Activation_App1()
						
		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Apps[1].appID})
		EXPECT_HMIRESPONSE(RequestId)
		
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 		
	end
		
	local function OnButtonPress_OnlyComesToFullOrLimitedHmiLevelApplication(TestCaseName, ButtonName, buttonPressMode)
		Test[TestCaseName] = function(self)
		
			commonTestCases:DelayedExp(1000)
		
			--hmi side: send OnButtonEvent, OnButtonPress
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = ButtonName, mode = "BUTTONDOWN"})
			self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = ButtonName, mode = "BUTTONUP"})
			self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = ButtonName, mode = buttonPressMode})	
			
			--Verify result on Mobile for app1
			self.verifyPressButtonResult(ButtonName, buttonPressMode)

			--Verify result on Mobile for app2 in NONE
			
			--mobile side: expected OnButtonEvent notification
			self.mobileSession2:ExpectNotification("OnButtonEvent", {})
			:Times(0)
						
			--mobile side: expected OnButtonPress notification
			self.mobileSession2:ExpectNotification("OnButtonPress", {})
			:Times(0)		

			--Verify result on Mobile for app3 in BACKGROUND
			
			--mobile side: expected OnButtonEvent notification
			self.mobileSession3:ExpectNotification("OnButtonEvent", {})
			:Times(0)
						
			--mobile side: expected OnButtonPress notification
			self.mobileSession3:ExpectNotification("OnButtonPress", {})
			:Times(0)
			
		end
	end	
	
	for i,v in ipairs({"SHORT", "LONG"}) do
		for i=1,#ButtonNames_WithoutCUSTOM_BUTTON do
			OnButtonPress_OnlyComesToFullOrLimitedHmiLevelApplication("OnlyFullApplicationReceivesOnButtonPress" .. ButtonNames_WithoutCUSTOM_BUTTON[i] .. '_' .. tostring(v), ButtonNames_WithoutCUSTOM_BUTTON[i], tostring(v))
		end
	end
	----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("SDLAQ-CRS-3069: OnButtonPress to media app in LIMITED")
	--4. SDLAQ-CRS-3069: OnButtonPress to media app in LIMITED
	
	if commonFunctions:isMediaApp() then		
		--Change app1 to LIMITED
		commonSteps:ChangeHMIToLimited()
		for i,v in ipairs({"SHORT", "LONG"}) do
			for i=1,#ButtonNames_WithoutCUSTOM_BUTTON do
				OnButtonPress_OnlyComesToFullOrLimitedHmiLevelApplication("OnlyLimitedApplicationReceivesOnButtonPress"..ButtonNames_WithoutCUSTOM_BUTTON[i] .. '_' .. tostring(v), ButtonNames_WithoutCUSTOM_BUTTON[i], tostring(v))
			end
		end	
	end
	
	function Test:PostCondition_UnregisterApp2AndApp3()
		--Unregister App2
		local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
		self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		
		--Unregister App3
		local cid = self.mobileSession3:SendRPC("UnregisterAppInterface",{})
		self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	end
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-1303: HMI Status Requirements for OnButtonPress(FULL, LIMITED)
	
--Verification criteria: 
	--1. None of the applications receives OnButtonPress notification in HMI NONE.
	--2. None of the applications receives OnButtonPress notification in HMI BACKGROUND.
	--3. In case the app is of media/non-media type HMI Level is FULL the app obtains OnButtonPress notifications from all subscribed buttons.
	--4. In case the app is of media type and HMI Level is LIMITED the app obtains OnButtonPress notifications from media subscribed HW buttons only (all except OK).

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
	----------------------------------------------------------------------------------------------
	
	--1. HMI level is NONE
	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel("DeactivateAppToNoneHmiLevel_5_1")
	
	local function verifyOnButtonPressNotification_IsIgnored(TestCaseName)

		--Verify buttonName and buttonPressMode parameters
		for i =1, #ButtonNames_WithoutCUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				SendOnButtonPress_IsIgnored(ButtonNames_WithoutCUSTOM_BUTTON[i], ButtonPressModes[j], TestCaseName)
			end
		end

		--Verify customButtonID parameter
		for i =1, #ButtonNames_CUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				for n = 1, #CustomButtonIDs do
					SendOnButtonPress_CUSTOM_BUTTON_IsIgnored(ButtonNames_CUSTOM_BUTTON[i], ButtonPressModes[j], CustomButtonIDs[n], 1, TestCaseName)
				end
			end
		end
	end

	verifyOnButtonPressNotification_IsIgnored("OnButtonPress_InNoneHmiLevel_IsIgnored")
	
	--Postcondition:
	commonSteps:ActivationApp(_, "Activation_App_5_1")	
	
	----------------------------------------------------------------------------------------------

	--2. HMI level is LIMITED
	
	if commonFunctions:isMediaApp() then
		-- Precondition: Change app to LIMITED
		commonSteps:ChangeHMIToLimited("ChangeHMIToLimited_5_2")
			
		
		--Verify buttonName and buttonPressMode parameters
		for i =1, #ButtonNames_WithoutCUSTOM_BUTTON_OK do
			for j =1, #ButtonPressModes do
				SendOnButtonPress(ButtonNames_WithoutCUSTOM_BUTTON_OK[i], ButtonPressModes[j], "OnButtonPress_InLimitedHmilLevel")
			end
		end
		
		--4. In case the app is of media type and HMI Level is LIMITED the app obtains OnButtonPress notifications from media subscribed HW buttons only (all except OK).
		for i =1, #ButtonNames_OK do
			for j =1, #ButtonPressModes do
				SendOnButtonPress_IsIgnored(ButtonNames_OK[i], ButtonPressModes[j], "OnButtonPress_InLimitedHmilLevel_OK_ButtonIsIgnored")
			end
		end

		--Verify customButtonID parameter
		for i =1, #ButtonNames_CUSTOM_BUTTON do
			for j =1, #ButtonPressModes do
				for n = 1, #CustomButtonIDs do
					SendOnButtonPress_CUSTOM_BUTTON(ButtonNames_CUSTOM_BUTTON[i], ButtonPressModes[j], CustomButtonIDs[n], 1, "OnButtonPress_InLimitedHmilLevel")
				end
			end
		end
		
		--Postcondition:
		commonSteps:ActivationApp(_, "Activation_App_5_2")	
	end
	----------------------------------------------------------------------------------------------
	
	--3. HMI level is BACKGROUND
	commonTestCases:ChangeAppToBackgroundHmiLevel()
	verifyOnButtonPressNotification_IsIgnored("OnButtonPress_InBackgoundHmiLevel_IsIgnored")

----------------------------------------------------------------------------------------------

return Test
