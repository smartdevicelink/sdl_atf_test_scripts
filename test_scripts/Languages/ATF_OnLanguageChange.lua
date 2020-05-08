--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_languages.lua
commonPreconditions:Connecttest_Languages_update("connecttest_languages.lua", true)

Test = require('user_modules/connecttest_languages')
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

APIName = "OnLanguageChange" -- set API name

config.deviceMAC      = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 
Apps[1].isMedia = commonFunctions:isMediaApp()
--Set audioStreamingState
if Apps[1].isMedia then
	Apps[1].audioStreamingState = "AUDIBLE"
else
	Apps[1].audioStreamingState = "NOT_AUDIBLE"
end
	
Apps[2] = {}
Apps[2].appName = config.application2.registerAppInterfaceParams.appName 	

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

--Register an application
local function RegisterApplication(UILanguage, VRTTSLanguage)
	--Test["RegisterAppInterface_hmiDisplayLanguageDesired_" .. UILanguage .. "_languageDesired_" .. VRTTSLanguage] = function(self)
	Test["RegisterApp"] = function(self)
	
		--Set language for RegisterAppInterface request
		config.application1.registerAppInterfaceParams.hmiDisplayLanguageDesired = UILanguage
		config.application1.registerAppInterfaceParams.languageDesired = VRTTSLanguage
		
		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		--hmi side: expected  BasicCommunication.OnAppRegistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								{application = 
									{
										appName = config.application1.registerAppInterfaceParams.appName,
										ngnMediaScreenAppName = config.application1.registerAppInterfaceParams.ngnMediaScreenAppName,
										--deviceInfo = config.application1.registerAppInterfaceParams.deviceInfo,
										policyAppID = config.application1.registerAppInterfaceParams.fullAppID,
										hmiDisplayLanguageDesired = config.application1.registerAppInterfaceParams.hmiDisplayLanguageDesired,
										isMediaApplication = config.application1.registerAppInterfaceParams.isMediaApplication,
										appType = config.application1.registerAppInterfaceParams.appHMIType
									}
									})
									
		:Do(function(_,data)			
			Apps[1].appID = data.params.application.appID
			self.applications[Apps[1].appName] = data.params.application.appID
		end)
		
		
		--mobile side: RegisterAppInterface response 
		EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		:Do(function(_,data)
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)

		EXPECT_NOTIFICATION("OnPermissionsChange")
		
	end
end


--Verify SDL ignores OnLanguageChange after SDL received OnLanguageChange
function Test.verifyOnLanguageChangeNotificationIsIgnored()

		--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
		:Times(0)
		
		--mobile side: expected OnLanguageChange notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
		:Times(0)
		
		--mobile side: expected OnLanguageChange notification
		EXPECT_NOTIFICATION("OnLanguageChange")
		:Times(0)	
end	


--Verify result on HMI and mobile after SDL received OnLanguageChange 
function Test.verifyOnLanguageChangeNotification(Input_Language)

		--Choice expected languages
		local HmiDisplayLanguage, Language		
		if Method == "UI.OnLanguageChange" then
			ExpectedHmiDisplayLanguage = Input_Language
			ExpectedLanguage = "EN-US"
		elseif Method == "VR.OnLanguageChange" or  Method == "TTS.OnLanguageChange" then
			ExpectedHmiDisplayLanguage = "EN-US"
			ExpectedLanguage = Input_Language
		end
		
		
		--mobile side: expected OnLanguageChange notification
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = ExpectedHmiDisplayLanguage, language= ExpectedLanguage})
		:ValidIf (function(_,data)
			if data.payload.fake or data.payload.sliderPosition then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
		
		--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})
		
		--mobile side: expected OnAppInterfaceUnregistered notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
		
end	

	
--ExpectedResult: 1 is success, 0 is failed	
--Method: "UI/VR/TTS.OnLanguageChange"
local function SendOnLanguageChange(Method, Input_Language, TestCaseName, ExpectedResult)
	Test[TestCaseName .. "_" .. Input_Language] = function(self)
	
		--hmi side: send OnLanguageChange
		self.hmiConnection:SendNotification(Method,{language = Input_Language})
		
		--Verify expected result
		if ExpectedResult == true then
			self.verifyOnLanguageChangeNotification(Input_Language)
		else
			self.verifyOnLanguageChangeNotificationIsIgnored()
		end		
	end
	
end	





--Verify result on HMI and mobile after SDL received OnLanguageChange 
function Test.verifyOnLanguageChangeNotification_InBackground(Input_Language)

		--Choice expected languages
		local HmiDisplayLanguage, Language		
		if Method == "UI.OnLanguageChange" then
			ExpectedHmiDisplayLanguage = Input_Language
			ExpectedLanguage = "EN-US"
		elseif Method == "VR.OnLanguageChange" or  Method == "TTS.OnLanguageChange" then
			ExpectedHmiDisplayLanguage = "EN-US"
			ExpectedLanguage = Input_Language
		end
		
		
		--mobile side: expected OnLanguageChange notification
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = ExpectedHmiDisplayLanguage, language= ExpectedLanguage})
		:ValidIf (function(_,data)
			if data.payload.fake or data.payload.sliderPosition then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	
		
		
		if Input_Language == "EN-US" then --app2 is not unregistered because it is registered with "EN-US"
			--hmi side: expect OnAppUnregistered notification 
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
										{appID = Apps[1].appID, unexpectedDisconnect = false}
			)
		else
			if commonFunctions.isMediaApp() then
				--hmi side: expect OnAppUnregistered notification 
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
											{appID = Apps[1].appID, unexpectedDisconnect = false},
											{appID = Apps[2].appID, unexpectedDisconnect = false}
				)
				:Times(2)
				
				Test.mobileSession2:ExpectNotification("OnLanguageChange", {hmiDisplayLanguage = ExpectedHmiDisplayLanguage, language= ExpectedLanguage})
				Test.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
			else
				--hmi side: expect OnAppUnregistered notification 
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = Apps[1].appID, unexpectedDisconnect = false})				
			end
			
		end
		
		--mobile side: expected OnAppInterfaceUnregistered notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
		
		
end	

local function SendOnLanguageChange_InBackground(Method, Input_Language, TestCaseName)
	Test[TestCaseName .. "_" .. Input_Language] = function(self)
	
		--hmi side: send OnLanguageChange
		self.hmiConnection:SendNotification(Method,{language = Input_Language})
		
		--Verify expected result
		self.verifyOnLanguageChangeNotification_InBackground(Input_Language)
	end
	
end	

local function UnregisterApp2()

	Test["Unregister_Application2"]  = function(self)

			local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})

			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end 
end



--Set default languages for HMI
local function SetDefaultLanguage()
	Test["SetDefaultLanguage_EN-US_ForUI_VR_TTS"] = function(self)
	
		commonTestCases:DelayedExp(2000)
		
		--hmi side: send OnLanguageChange
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "EN-US"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "EN-US"})
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = "EN-US"})
		
		EXPECT_NOTIFICATION("OnLanguageChange", {})
		:Times(AnyNumber())
		
	end	
end	



local Languages = {
	"AR-SA",
	"CS-CZ",
	"DA-DK",
	"DE-DE",
	"EN-AU",
	"EN-GB",
	"ES-ES",
	"ES-MX",
	"FR-CA",
	"FR-FR",
	"IT-IT",
	"JA-JP",
	"KO-KR",
	"NL-NL",
	"NO-NO",
	"PL-PL",
	"PT-PT",
	"PT-BR",
	"RU-RU",
	"SV-SE",
	"TR-TR",
	"ZH-CN",
	"ZH-TW",
	"NL-BE",
	"EL-GR",
	"HU-HU",
	"FI-FI",
	"SK-SK",
	"EN-US"
}

	
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------


	commonSteps:DeleteLogsFileAndPolicyTable()

	-- Precondition: removing user_modules/connecttest_languages.lua
	function Test:Precondition_remove_user_connecttest()
	  os.execute( "rm -f ./user_modules/connecttest_languages.lua" )
	end

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()
	
	--2. Update policy
    --TODO: Will be updated after policy flow implementation
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

	
	----Get appID Value on HMI side
	function Test:GetAppID()
		Apps[1].appID = self.applications[Apps[1].appName]
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
	--SDLAQ-CRS-187: OnLanguageChange_v2_0
	
	--Verification criteria: 
		--OnLanguageChange notification is sent by SDL to all connected apps if any of the HMI languages VR, TTS or hmiDisplayLanguage are changed on HMI.
		--If language for TTS+VR is changed two notifications come to mobile app from each of the components (VR and TTS).
		--Each OnLanguageChange notification contains both current HMI values: VR+TTS language and hmiDisplayLanguage.
----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. language: type=Language
	--2. hmiDisplayLanguage: type=Language
----------------------------------------------------------------------------------------------
	
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")


----------------------------------------------------------------------------------------------
--Test case #1: Checks OnLanguageChange is sent to application after SDL received UI.OnLanguageChange or VR.OnLanguageChange or TTS.OnLanguageChange
----------------------------------------------------------------------------------------------

	local function verifyOnLanguageChange_success()

		--Verify UI.OnLanguageChange notification
		for i =1, #Languages do

			SendOnLanguageChange("UI.OnLanguageChange", Languages[i], "UIOnLanguageChange", true)
			RegisterApplication(Languages[i], "EN-US")
			--commonSteps:ActivationApp(1)
		end

		--Verify VR.OnLanguageChange notification
		for i =1, #Languages do

			SendOnLanguageChange("VR.OnLanguageChange", Languages[i], "VROnLanguageChange", true)
			RegisterApplication("EN-US", Languages[i])
			--commonSteps:ActivationApp(1)
		end

		--Verify TTS.OnLanguageChange notification
		for i =1, #Languages do

			SendOnLanguageChange("TTS.OnLanguageChange", Languages[i], "TTSOnLanguageChange", true)
			RegisterApplication("EN-US", Languages[i])
		end


		--Postcondition
		SetDefaultLanguage()	
		--RegisterApplication("EN-US", "EN-US")	

	end

	verifyOnLanguageChange_success()


----------------------------------------------------------------------------------------------
--Test case #2: Checks OnLanguageChange is NOT sent to application after SDL received UI.OnLanguageChange or VR.OnLanguageChange or TTS.OnLanguageChange with invalid language values
----------------------------------------------------------------------------------------------

	--Non-existing values
	SendOnLanguageChange("UI.OnLanguageChange", "VN-V0", "SendUIOnLanguageChange_language_IsNonExist", false)
	SendOnLanguageChange("VR.OnLanguageChange", "VN-V1", "SendVROnLanguageChange_language_IsNonExist", false)
	SendOnLanguageChange("TTS.OnLanguageChange", "VN-V2", "SendTTSOnLanguageChange_language_IsNonExist", false)
	
	--Wrong type values
	SendOnLanguageChange("UI.OnLanguageChange", 1, "SendUIOnLanguageChange_language_IsWrongType", false)
	SendOnLanguageChange("VR.OnLanguageChange", 2, "SendVROnLanguageChange_language_IsWrongType", false)
	SendOnLanguageChange("TTS.OnLanguageChange", 3, "SendTTSOnLanguageChange_language_IsWrongType", false)
	


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


	
	--1. Verify OnLanguageChange with invalid Json syntax
	----------------------------------------------------------------------------------------------
	function Test:UIOnLanguageChange_InvalidJsonSyntax()
		--hmi side: send OnLanguageChange 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnLanguageChange","params":{"language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	function Test:VROnLanguageChange_InvalidJsonSyntax()
		--hmi side: send OnLanguageChange 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"VR.OnLanguageChange","params":{"language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	function Test:TTSOnLanguageChange_InvalidJsonSyntax()
		--hmi side: send OnLanguageChange 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"TTS.OnLanguageChange","params":{"language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	
	--2. Verify OnLanguageChange with invalid structure
	----------------------------------------------------------------------------------------------
	
	function Test:UIOnLanguageChange_InvalidJsonSyntax()
		print()
		--hmi side: send OnLanguageChange 
		--method is moved into params parameter
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnLanguageChange","language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	function Test:VROnLanguageChange_InvalidJsonSyntax()
		--hmi side: send OnLanguageChange 
		--method is moved into params parameter
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"VR.OnLanguageChange","language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	function Test:TTSOnLanguageChange_InvalidJsonSyntax()
		--hmi side: send OnLanguageChange 
		--method is moved into params parameter
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"TTS.OnLanguageChange","language":"FR-CA"}}')
	
		self.verifyOnLanguageChangeNotificationIsIgnored()
	end
	
	
	
	--3. Verify OnLanguageChange with FakeParams
	----------------------------------------------------------------------------------------------

	function Test:UIOnLanguageChange_FakeParams()
		print()
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[2], fake = 123})
		
		self.verifyOnLanguageChangeNotification(Languages[2])		
	end
	
	--Postcondition
	RegisterApplication(Languages[2], "EN-US")

	function Test:VROnLanguageChange_FakeParams()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[2], fake = 123})
		
		self.verifyOnLanguageChangeNotification(Languages[2])		
	end
	
	--Postcondition
	RegisterApplication(Languages[2], Languages[2])
	
	
	function Test:TTSOnLanguageChange_FakeParams()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[3], fake = 123})
		
		self.verifyOnLanguageChangeNotification(Languages[3])		
	end
	
	--Postcondition
	SetDefaultLanguage()	
	RegisterApplication("EN-US", "EN-US")
	
	
	--4. Verify OnLanguageChange with FakeParameterIsFromAnotherAPI
	function Test:UIOnLanguageChange_FakeParams()
		print()
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[3], sliderPosition = 1})
		
		self.verifyOnLanguageChangeNotification(Languages[3])		
	end
	
	--Postcondition
	RegisterApplication(Languages[3], "EN-US")

	
	function Test:VROnLanguageChange_FakeParams()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[4], sliderPosition = 1})
		
		self.verifyOnLanguageChangeNotification(Languages[4])		
	end
	
	--Postcondition
	RegisterApplication(Languages[3], Languages[4])
	
	
	function Test:TTSOnLanguageChange_FakeParams()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[5], sliderPosition = 1})
		
		self.verifyOnLanguageChangeNotification(Languages[5])		
	end
	
	--Postcondition
	SetDefaultLanguage()	
	RegisterApplication("EN-US", "EN-US")

	
	
	--5. Verify OnLanguageChange misses mandatory parameter
	----------------------------------------------------------------------------------------------
	function Test:UIOnLanguageChange_language_IsMissed()
		print()
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {})
		
		self.verifyOnLanguageChangeNotificationIsIgnored()		
	end
	
	function Test:VROnLanguageChange_language_IsMissed()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {})
		
		self.verifyOnLanguageChangeNotificationIsIgnored()		
	end
	
	function Test:TTSOnLanguageChange_language_IsMissed()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {})
		
		self.verifyOnLanguageChangeNotificationIsIgnored()		
	end
	
	

	--6. Verify OnLanguageChange MissedAllPArameters: The same as case 5.
	----------------------------------------------------------------------------------------------
	
	
	--7. Verify OnLanguageChange with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------
	
	function Test:UIOnLanguageChange_SeveralNotifications_WithTheSameValues()
		print()
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[1]})
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[1]})
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[1]})
		
		self.verifyOnLanguageChangeNotification(Languages[1])	
	end
	
	--Postcondition
	RegisterApplication(Languages[1], "EN-US")

	
	function Test:VROnLanguageChange_SeveralNotifications_WithTheSameValues()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[2]})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[2]})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[2]})
		
		self.verifyOnLanguageChangeNotification(Languages[2])		
	end
	
	--Postcondition
	RegisterApplication(Languages[1], Languages[2])
	
	
	function Test:TTSOnLanguageChange_SeveralNotifications_WithTheSameValues()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[3]})
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[3]})
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[3]})
		
		self.verifyOnLanguageChangeNotification(Languages[3])		
	end
	
	--Postcondition
	SetDefaultLanguage()	
	RegisterApplication("EN-US", "EN-US")
	
	
	
	
	--8. Verify UI.OnLanguageChange with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------
	
	function Test:UIOnLanguageChange_SeveralNotifications_WithDifferentValues()
		print()
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[2]})
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = Languages[3]})
		
		self.verifyOnLanguageChangeNotification(Languages[2])	
	end
	
	--Postcondition
	RegisterApplication(Languages[3], "EN-US")

	function Test:VROnLanguageChange_SeveralNotifications_WithDifferentValues()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[4]})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = Languages[1]})
		
		self.verifyOnLanguageChangeNotification(Languages[4])		
	end
	
	--Postcondition
	RegisterApplication(Languages[3], Languages[1])
	
	
	function Test:TTSOnLanguageChange_SeveralNotifications_WithDifferentValues()
	
		--hmi side: sending OnLanguageChange notification			
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[3]})
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = Languages[2]})
		
		self.verifyOnLanguageChangeNotification(Languages[3])		
	end
	
	--Postcondition
	SetDefaultLanguage()	
	RegisterApplication("EN-US", "EN-US")
	
	
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

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

--Requirement id in JAMA: Mentions in each test case
	
--Not Applicable

	
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-1312: HMI Status Requirements for OnLanguageChange (FULL, LIMITED, BACKGROUND, NONE)
	
	--Verification criteria: 
		--SDL processes OnLanguageChange notification on any HMI Level (FULL, LIMITED, BACKGROUND, NONE).


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
	----------------------------------------------------------------------------------------------
	

	--1. HMI level is NONE
	--It is verified by all above test cases
	----------------------------------------------------------------------------------------------

	--2. HMI level is FULL
	--Postcondition: Activate app
	
	local function verifyOnLanguageChange_success_inFullHmiLevel()

		--Verify UI.OnLanguageChange notification
		for i =1, #Languages do
			commonSteps:ActivationApp()
			SendOnLanguageChange("UI.OnLanguageChange", Languages[i], "UIOnLanguageChange_inFullHmiLevel", true)
			RegisterApplication(Languages[i], "EN-US")
		end

		--Verify VR.OnLanguageChange notification
		for i =1, #Languages do
			commonSteps:ActivationApp()
			SendOnLanguageChange("VR.OnLanguageChange", Languages[i], "VROnLanguageChange_inFullHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end

		--Verify TTS.OnLanguageChange notification
		for i =1, #Languages do
			commonSteps:ActivationApp()
			SendOnLanguageChange("TTS.OnLanguageChange", Languages[i], "TTSOnLanguageChange_inFullHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end


		--Postcondition
		SetDefaultLanguage()	
		--RegisterApplication("EN-US", "EN-US")	

	end

	verifyOnLanguageChange_success_inFullHmiLevel()
	----------------------------------------------------------------------------------------------
	
	--2. HMI level is LIMITED
	
	local function verifyOnLanguageChange_success_inLimitedHmiLevel()

		--Verify UI.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to LIMITED
			commonSteps:ActivationApp()
			commonSteps:ChangeHMIToLimited()
			
			SendOnLanguageChange("UI.OnLanguageChange", Languages[i], "UIOnLanguageChange_inLimitedHmiLevel", true)
			RegisterApplication(Languages[i], "EN-US")
		end

		--Verify VR.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to LIMITED
			commonSteps:ActivationApp()
			commonSteps:ChangeHMIToLimited()
			
			SendOnLanguageChange("VR.OnLanguageChange", Languages[i], "VROnLanguageChange_inLimitedHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end

		--Verify TTS.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to LIMITED
			commonSteps:ActivationApp()
			commonSteps:ChangeHMIToLimited()
			
			SendOnLanguageChange("TTS.OnLanguageChange", Languages[i], "TTSOnLanguageChange_inLimitedHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end


		--Postcondition
		SetDefaultLanguage()	
		--RegisterApplication("EN-US", "EN-US")	

	end

	if commonFunctions:isMediaApp() then
		verifyOnLanguageChange_success_inLimitedHmiLevel()				
	end
	----------------------------------------------------------------------------------------------




	--3. HMI level is BACKGROUND
	--Overwrite commonSteps:RegisterTheSecondMediaApp to use in ChangeAppToBackgroundHmiLevel()
	function commonSteps:RegisterTheSecondMediaApp()		
		
		Test["Register_The_Second_Media_App"]  = function(self)

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams) 
		 
			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = config.application2.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				appId2 = data.params.application.appID
				
				Apps[2].appID = data.params.application.appID
				self.applications[Apps[2].appName] = data.params.application.appID
			end)
			
			--mobile side: RegisterAppInterface response 
			--self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true})

			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
	end
	
	local function verifyOnLanguageChange_success_inBackgroundHmiLevel()

		--Verify UI.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to BACKGROUND
			commonSteps:ActivationApp(1)
			commonTestCases:ChangeAppToBackgroundHmiLevel()
			
			SendOnLanguageChange_InBackground("UI.OnLanguageChange", Languages[i], "UIOnLanguageChange_inBackgroundHmiLevel", true)
			RegisterApplication(Languages[i], "EN-US")
		end
		
		--Postcondition
		if commonFunctions:isMediaApp() then
			UnregisterApp2()
		end

		--Verify VR.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to BACKGROUND
			commonSteps:ActivationApp(1)
			commonTestCases:ChangeAppToBackgroundHmiLevel()
			
			SendOnLanguageChange_InBackground("VR.OnLanguageChange", Languages[i], "VROnLanguageChange_inBackgroundHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end
		
		--Postcondition
		if commonFunctions:isMediaApp() then
			UnregisterApp2()
		end

		--Verify TTS.OnLanguageChange notification
		for i =1, #Languages do
			-- Precondition: Change app to BACKGROUND
			commonSteps:ActivationApp(1)
			commonTestCases:ChangeAppToBackgroundHmiLevel()
			
			SendOnLanguageChange_InBackground("TTS.OnLanguageChange", Languages[i], "TTSOnLanguageChange_inBackgroundHmiLevel", true)
			RegisterApplication("EN-US", Languages[i])
		end
		
		--Postcondition
		if commonFunctions:isMediaApp() then
			UnregisterApp2()
		end
		
		SetDefaultLanguage()	
		--RegisterApplication("EN-US", "EN-US")	

	end
	
	verifyOnLanguageChange_success_inBackgroundHmiLevel()
	

	---------------------------------------------------------------------------------------------
	-------------------------------------------Post-conditions-----------------------------------
	---------------------------------------------------------------------------------------------

	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()   
	
return Test