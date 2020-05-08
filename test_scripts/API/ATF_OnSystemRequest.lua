---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Created date: 22/Jan/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local functionId = require('function_id')
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local enumParameterInNotification = require('user_modules/shared_testcases/testCasesForEnumerationParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local arrayStringParameterInNotification = require('user_modules/shared_testcases/testCasesForArrayStringParameterInNotification')
local integerParameterInNotification = require('user_modules/shared_testcases/testCasesForIntegerParameterInNotification')
require('user_modules/AppTypes')

APIName = "OnSystemRequest" -- set API name

Apps = {}
Apps[1] = {}
Apps[1].appName = config.application1.registerAppInterfaceParams.appName
Apps[2] = {}



---------------------------------------------------------------------------------------------
------------------------------------------Common Variables-----------------------------------
---------------------------------------------------------------------------------------------

local RequestType = {	                        "HTTP",
						"FILE_RESUME",
						"AUTH_REQUEST",
						"AUTH_CHALLENGE",
						"AUTH_ACK",
						"PROPRIETARY",
						--"QUERY_APPS",  --It is used on SDL4.0 only
						--"LAUNCH_APP", --It is used on SDL4.0 only
						--"LOCK_SCREEN_ICON_URL", --It is used on SDL4.0 only
						"TRAFFIC_MESSAGE_CHANNEL",
						"DRIVER_PROFILE",
						"VOICE_SEARCH",
						"NAVIGATION",
						"PHONE",
						"CLIMATE",
						"SETTINGS",
						"VEHICLE_DIAGNOSTICS",
						"EMERGENCY",
						"MEDIA",
						"FOTA"}

local FileType = {	"GRAPHIC_BMP",
					"GRAPHIC_JPEG",
					"GRAPHIC_PNG",
					"AUDIO_WAVE",
					"AUDIO_MP3",
					"AUDIO_AAC",
					"BINARY",
					"JSON"}

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. verify_SUCCESS_Notification_Case(Notification)
--2. verify_Notification_IsIgnored_Case(Notification)
---------------------------------------------------------------------------------------------

local function createDefaultNotification()

	return
	{
		requestType = "PROPRIETARY",
		fileType = "JSON",
		offset = 0,
		length = 0,
		timeout = 0,
		fileName = "a"
	}
end


local function buildMobileExpectedResult(Notification)

	--Remove parameters are not in Mobile_API.xml
	local mobileExpectation = commonFunctions:cloneTable(Notification)
	mobileExpectation.appID = nil
	mobileExpectation.fileName = nil

	--If the requestType = PROPRIETARY, add to mobile API fileType = JSON
	if mobileExpectation.requestType == "PROPRIETARY" then
		mobileExpectation.fileType = "JSON"
	end

	--If the requestType = HTTP, add to mobile API fileType =BINARY
	if mobileExpectation.requestType == "HTTP" then
		mobileExpectation.fileType = "BINARY"
	end

	--ToDo: Need update when APPLINK-22253 is closed.
	--Convert array to string
	if mobileExpectation.url ~= nil then
		if type(Notification.url) == "table" then
			mobileExpectation.url = mobileExpectation.url[1]
		end
	end

	--TODO: Should be updated after resolving APPLINK-17030.  Update {mobileExpectation} to mobileExpectation
	return  {mobileExpectation}
	--return  mobileExpectation

end


local function buildMobileExpectedResult1(Notification)

	--TODO: Should remove this function and use buildMobileExpectedResult function when APPLINK-17030 is fixed and buildMobileExpectedResult is updated.

	--Remove parameters are not in Mobile_API.xml
	local mobileExpectation = commonFunctions:cloneTable(Notification)
	mobileExpectation.appID = nil
	mobileExpectation.fileName = nil

	--If the requestType = PROPRIETARY, add to mobile API fileType = JSON
	if mobileExpectation.requestType == "PROPRIETARY" then
		mobileExpectation.fileType = "JSON"
	end

	--If the requestType = HTTP, add to mobile API fileType =BINARY
	if mobileExpectation.requestType == "HTTP" then
		mobileExpectation.fileType = "BINARY"
	end

	--ToDo: Need update when APPLINK-22253 is closed.
	--Convert array to string
	if mobileExpectation.url ~= nil then
		if type(Notification.url) == "table" then
			mobileExpectation.url = mobileExpectation.url[1]
		end
	end

	return  mobileExpectation

end


--This function is used to send default request and response with specific valid data and verify result on mobile
function Test:verify_SUCCESS_Notification_Case(Notification)

	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

	--mobile side: expected OnSystemRequest
	local mobileExpectation = buildMobileExpectedResult(Notification)
	EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
	:Timeout(1000)

end


function Test:verify_Notification_IsIgnored_Case(Notification)

	commonTestCases:DelayedExp(1000)

	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

	--mobile side: expected Notification
	EXPECT_NOTIFICATION("OnSystemRequest", {})
	:Times(0)

end


--This test case is used in some places such as verify all parameters are low bound, notification in different HMI levels
local function OnSystemRequest_AllParametersLowerBound_SUCCESS(TestCaseName)

	Test[TestCaseName] = function(self)

		local Notification =
		{
			requestType = "PROPRIETARY",
			fileType = "JSON",
			url = "a",
			offset = 0,
			length = 0,
			timeout = 0,
			fileName = "a",
			appID = Apps[1].appID
		}

		self:verify_SUCCESS_Notification_Case(Notification)

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

	--3. Update policy table
	local PermissionLines_OnSystemRequest =
[[					"OnSystemRequest": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  }]]

	local PermissionLinesForBase4 = PermissionLines_OnSystemRequest .. ",\n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnSystemRequest"})
	--TODO: PT is blocked by ATF defect APPLINK-19188. Should be used updatePolicy(PTName) after defect APPLINK-19188 is fixed.
	--testCasesForPolicyTable:updatePolicy(PTName)
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
----------------------------------Check normal cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-2637: OnSystemRequest
        	--Verification criteria:
	    	--SDL receives BasicCommunication.OnSystemRequest from HMI and forwards the notification to the named app ('appID' parameter in BasicCommunication.OnSystemRequest names the app).
----------------------------------------------------------------------------------------------
--List of parameters:
	--1. requestType: type="Common.RequestType" mandatory="true"
	--2. fileType" type="Common.FileType" mandatory="false"
    --3. url: type="String" maxlength="1000" minlength="1" mandatory="false", minsize="1" maxsize="100" array="true"
    --4. fileName: type="String" maxlength="255" minlength="1" mandatory="true"
	--5. offset: type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false"
	--6. length: type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false"
	--7. timeout: type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false"
    --8. appID: type="Integer" mandatory="false"
-----------------------------------------------------------------------------------------------

local function NormalNotificationChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Normal cases of HMI notification")


	local function common_Test_Cases_For_Notification()
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Common test cases of HMI notification")

		--Common Test cases for Notification
		--1. PositiveNotification:
		--2. Only mandatory parameters
		--3. All parameters are lower bound
		--4. All parameters are upper bound

      --------------------------------------------------------------------------------------------------

		--1. PositiveNotification

		Test["OnSystemRequest_PositiveNotification_SUCCESS"] = function(self)

			local Notification =
				{
					requestType = "PROPRIETARY",
					fileType = "JSON",


					--requestType = "HTTP",
					url = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST", --ToDo: Need update when APPLINK-9533 is closed.
					--fileType = "BINARY",
					offset = 1000,
					length = 10000,
					timeout = 500,
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST",
					appID = Apps[1].appID
				}

			self:verify_SUCCESS_Notification_Case(Notification)

		end

      		----------------------------------------------------------------------------------------

		--2. Only mandatory parameters

		Test["OnSystemRequest_OnlyMandatoryParameters_SUCCESS"] = function(self)

			local Notification =
				{
					requestType = "HTTP",
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST"
				}
			self:verify_SUCCESS_Notification_Case(Notification)


		end

		-----------------------------------------------------------------------------------------

		--3. All parameters are lower bound

		OnSystemRequest_AllParametersLowerBound_SUCCESS("OnSystemRequest_AllParametersLowerBound_SUCCESS")

		-----------------------------------------------------------------------------------------

		--4. All parameters are upper bound

		Test["OnSystemRequest_AllParametersUpperBound_SUCCESS"] = function(self)

			local Notification =
				{
					requestType = "HTTP",
					url = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",     			--ToDo: Need update when APPLINK-9533 is closed.
					fileType = "BINARY",
					offset = 1000,
					length = 10000,
					timeout = 500,
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
					appID = Apps[1].appID,
					offset = 100000000000,
					length = 100000000000,
					timeout = 2000000000
				}

			self:verify_SUCCESS_Notification_Case(Notification)

		end


	end
	common_Test_Cases_For_Notification()

	--Default notification
	local Notification = createDefaultNotification()

	--ToDo: APPLINK-20534: Clarify OnSystemRequest (SDLAQ-CRS-2637) requirement
	--1. requestType: type="Common.RequestType" mandatory="true"
	--2. fileType" type="Common.FileType" mandatory="false"

	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"requestType"}, RequestType, true)
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"fileType"}, FileType, false)


	--3. url: type="String" maxlength="1000" minlength="1" mandatory="false", minsize="1" maxsize="100" array="true"
        --4. fileName: type="String" maxlength="255" minlength="1" mandatory="true"

	local IsStringParameterAcceptedSpecialCharacters = false

	--ToDo: Test case OnSystemRequest_url_IsLowerBound, OnSystemRequest_url_IsUpperBound should be failed due to defect APPLINK-9533. Need to check when APPLINK-9533 is closed.
	--APPLINK-18381 (17[P][MAN]_TC_ SDL_sends_OnSystemRequest_w/o_url) is covered by test: OnSystemRequest_url_IsMissed
	local Notification_HTTP = createDefaultNotification()
	Notification_HTTP.requestType = "HTTP"
	arrayStringParameterInNotification:verify_Array_String_Parameter(Notification_HTTP, {"url"}, {1, 100},  {1, 1000}, false, IsStringParameterAcceptedSpecialCharacters)


	local function verify_String_Parameter(Notification, Parameter, Boundary, IsMandatory, IsAcceptedInvalidCharacters)


		local TestingNotification = commonFunctions:cloneTable(Notification)

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)

		--Case 1 and 2 have already been covered in verify_Array_String_Parameter()
		--1. IsMissed
		--2. IsWrongDataType


		--3. IsLowerBound
		local verification = "IsLowerBound"
		if Boundary[1] == 0 then
			verification = "IsLowerBound_IsEmpty"
		end

		local value = commonFunctions:createString(Boundary[1])
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_IsLowerBound", value, true)

		--4. IsUpperBound
		local value = commonFunctions:createString(Boundary[2])
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_IsUpperBound", value, true)


		--5. IsOutLowerBound
		local value = commonFunctions:createString(Boundary[1] - 1)
		if Boundary[1] >= 2 then
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_IsOutLowerBound", value, false)
		elseif Boundary[1] == 1 then
			commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_IsOutLowerBound_IsEmpty", value, false)
		else
			--minlength = 0, no check out lower bound
		end


		--6. IsOutUpperBound
		local value = commonFunctions:createString(Boundary[2] + 1)
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_IsOutUpperBound", value, false)


		--7. IsInvalidCharacters
		if IsAcceptedInvalidCharacters == nil then
			--no check Characters
		else
			if IsAcceptedInvalidCharacters == true then
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_ContainsNewLineCharacter", "a\nb", true)
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_ContainsTabCharacter", "a\tb", true)
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_WhiteSpacesOnly", "   ", true)
			else
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_ContainsNewLineCharacter", "a\nb", false)
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_ContainsTabCharacter", "a\tb", false)
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "InCaseString_WhiteSpacesOnly", "   ", false)
			end
		end

	end
	verify_String_Parameter(Notification, {"url"}, {1, 1000}, false, IsStringParameterAcceptedSpecialCharacters)

	stringParameterInNotification:verify_String_Parameter(Notification, {"fileName"}, {1, 255}, true, IsStringParameterAcceptedSpecialCharacters)


	--5. offset: type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false"
	--6. length: type="Integer" minvalue="0" maxvalue="100000000000" mandatory="false"
	--7. timeout: type="Integer" minvalue="0" maxvalue="2000000000" mandatory="false"

	integerParameterInNotification:verify_Integer_Parameter(Notification, {"offset"}, {0, 100000000000}, false)
	integerParameterInNotification:verify_Integer_Parameter(Notification, {"length"}, {0, 100000000000}, false)
	integerParameterInNotification:verify_Integer_Parameter(Notification, {"timeout"}, {0, 2000000000}, false)

	--8. appID: type="Integer" mandatory="false"
	--APPLINK-11778([RTC 602443] Removal of the policyAppId (string) param and change appID (string) to appID (integer)): check changing appID (string) to appID (integer))
	local InvalidCases = 	{
								{"12a", 		"IsWrongType"},
								{2147483648, 	"IsOutUpperBound"},
								{1, 			"IsNotExistAppID"},
								{0, 			"IsZero"},
								{-1, 			"IsNegativeNumber"}
							}
	local validValues = {} -- Positive case is covered in APPLINK_18377_OnSystemRequest_With_appID1_InCase_Many_Apps and APPLINK_18377_OnSystemRequest_With_appID2_InCase_Many_Apps
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"appID"}, validValues, false, InvalidCases)

end

NormalNotificationChecks()


local function APPLINK_21366()

--Requirement id in JIRA:
        --APPLINK-21366->req_1: SDL behavior in case HMI sends OnSystemRequest (requestType = NAVIGATION)
		--Verification criteria:
		--SDL receives OnSystemRequest(NAVIGATION) from HMI and transfers it to requested app

				--Common Test cases for Notification (requestType = "NAVIGATION"):
				--1. PositiveNotification:
				--2. All parameters are lower bound
				--3. All parameters are upper bound
	------------------------------------------------------------

        --1. PositiveNotification

    		 function Test:OnSystemRequest_NAVIGATION()

       		  Notification =
			{
			    requestType = "NAVIGATION",
			    appID = Apps[1].appID,
                            fileName = "first_turn.jpg"
			}

        	 self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

       		 --mobile side: expected OnSystemRequest
       		 EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
		 :Timeout(1000)

  		 end
		 	-----------------------------------------------------------------------------------------

		--2. All parameters are lower bound

	            function Test:OSR_AllParamsLowerBound_NAVIGATION()

       		  Notification =
			{
			    requestType = "NAVIGATION",
			    appID = Apps[1].appID,
                            fileName = "first_turn.jpg",
                            fileType = "GRAPHIC_JPEG",
			    url = "a",
			    offset = 0,
			    length = 0,
			    timeout = 0
			}

        	 self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

       		 --mobile side: expected OnSystemRequest
       		 EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
		 :Timeout(1000)

  		 end

		 	-----------------------------------------------------------------------------------------

		--3. All parameters are upper bound

		   function Test:OSR_AllParamsUpperBound_NAVIGATION()

       		  Notification =
			{
			    requestType = "NAVIGATION",
			    appID = Apps[1].appID,
                            fileType = "GRAPHIC_JPEG",
			    url = "/home/luxoft/sdl_hmi/NAVI/NAVIGATION_REQUEST_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",     			            fileName = "/home/luxoft/sdl_hmi/NAVI/NAVIGATION_REQUEST_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
			    offset = 100000000000,
			    length = 100000000000,
			    timeout = 2000000000
			}

        	 self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

       		 --mobile side: expected OnSystemRequest
       		 EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
		 :Timeout(1000)

  		 end
end
-- -------------------------------------------------------------------------------------------

-- 			--Special cases for OnSystemRequest(requestType = NAVIGATION):
--                -- 1. notification with appId of the first app => SDL forwards this notification to mobile app1 only
-- 		      -- 2. notification with appId of the second app => SDL forwards this notification to mobile app2 only
-- -------------------------------------------------------------------------------------------

-- 		 function Test:OSR_NAVIGATION_ToApp1IfManyApps()

--                  commonTestCases:DelayedExp(1000)

--                  Notification =
-- 			{
-- 			    requestType = "NAVIGATION",
-- 			    appID = Apps[1].appID,
--                             fileName = "NAVIGATION_REQUEST.jpg"

-- 			}

--          	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)


-- 			--mobile side: expected OnSystemRequest
-- 			EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
-- 			:Timeout(1000)


-- 			self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "NAVIGATION"})
-- 			:Timeout(1000)
-- 			:Times(0)

-- 	       end


-- 		function Test:OSR_NAVIGATION_ToApp2IfManyApps()

--                  commonTestCases:DelayedExp(1000)

--                  Notification =
-- 			{
-- 			    requestType = "NAVIGATION",
-- 			    appID = Apps[2].appId,
--                             fileName = "NAVIGATION_REQUEST.jpg"

-- 			}

--          	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)


-- 			--mobile side: expected OnSystemRequest
-- 			EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
-- 			:Timeout(1000)
-- 			:Times(0)

-- 			self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "NAVIGATION"})
-- 			:Timeout(1000)

-- 	       end

APPLINK_21366()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

	--Verification criteria:
		--Refer to list of test case below.
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

	local function SpecialNotificationChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Special cases of HMI notification")


		--1. Verify OnSystemRequest with invalid Json syntax
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_InvalidJsonSyntax()

			commonTestCases:DelayedExp(1000)

			--hmi side: send OnSystemRequest
			--":" is changed by ";" after "jsonrpc"
			self.hmiConnection:Send('{"params":{"fileName":"/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST","requestType":"HTTP"},"jsonrpc";"2.0","method":"BasicCommunication.OnSystemRequest"}')


			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", {})
			:Times(0)
		end

		--2. Verify OnSystemRequest with invalid structure
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_InvalidJsonStructure()

			commonTestCases:DelayedExp(1000)

			--hmi side: send OnSystemRequest
			--method is moved into params parameter
			self.hmiConnection:Send('{"params":{"fileName":"/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST","requestType":"HTTP","method":"BasicCommunication.OnSystemRequest"},"jsonrpc":"2.0"}')

			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", {})
			:Times(0)
		end

		--3. Verify OnSystemRequest with FakeParams
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_FakeParams()

			local Notification = createDefaultNotification()

			local NotificationWithFakeParameters = createDefaultNotification()
			--Add fake parameter
			NotificationWithFakeParameters["fake"] = 123

			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", NotificationWithFakeParameters)


			--mobile side: expected OnSystemRequest
			local mobileExpectation = buildMobileExpectedResult(Notification)
			EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
			:Timeout(1000)
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resends fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)
		end


		--4. Verify OnSystemRequest with FakeParameterIsFromAnotherAPI
		function Test:OnSystemRequest_FakeParameterIsFromAnotherAPI()

			local Notification = createDefaultNotification()

			local NotificationWithFakeParameters = createDefaultNotification()
			--Add fake parameter
			NotificationWithFakeParameters["sliderPosition"] = 123

			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", NotificationWithFakeParameters)


			--mobile side: expected OnSystemRequest
			local mobileExpectation = buildMobileExpectedResult(Notification)
			EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
			:Timeout(1000)
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resends fake parameter (sliderPosition) to mobile app ")
					return false
				else
					return true
				end
			end)
		end


		--5. Verify OnSystemRequest misses mandatory parameter
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_MissedmandatoryParameters()

			commonTestCases:DelayedExp(1000)

			local NotificationWithoutMadatoryParameters = {
				--requestType = "HTTP",
				url = "a", --ToDo: Need update when APPLINK-9533 is closed.
				fileType = "BINARY",
				offset = 0,
				length = 0,
				timeout = 0,
				--fileName = "a",
				appID = Apps[1].appID
			}

			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", NotificationWithoutMadatoryParameters)

			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", {})
			:Times(0)
		end



		--6. Verify OnSystemRequest MissedAllPArameters
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_MissedAllPArameters()

			commonTestCases:DelayedExp(1000)

			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {})

			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", {})
			:Times(0)
		end

		--7. Verify OnSystemRequest with SeveralNotifications_WithTheSameValues
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_SeveralNotifications_WithTheSameValues()

			local Notification = createDefaultNotification()

			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

			local mobileExpectation = buildMobileExpectedResult1(Notification)

			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", 	mobileExpectation,
													mobileExpectation,
													mobileExpectation)
				:Times(3)
		end



		--8. Verify OnSystemRequest with SeveralNotifications_WithDifferentValues
		----------------------------------------------------------------------------------------------
		function Test:OnSystemRequest_SeveralNotifications_WithDifferentValues()

			local Notification1 = createDefaultNotification()
			Notification1["timeout"] = 1

			local Notification2 = createDefaultNotification()
			Notification2["timeout"] = 2


			--hmi side: sending OnSystemRequest notification
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification1)
			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification2)


			local mobileExpectation1 = buildMobileExpectedResult1(Notification1)
			local mobileExpectation2 = buildMobileExpectedResult1(Notification2)

			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnSystemRequest", 	mobileExpectation1,
													mobileExpectation2)
				:Times(2)

		end

	end

	SpecialNotificationChecks()



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Verification criteria: Verify SDL behaviors in different states of policy table:
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	--4. Notification is exist in PT and user allow function group that contains this notification
----------------------------------------------------------------------------------------------

	local function ResultCodesChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: All Result Codes")

		local function OnSystemRequest_IsIgnored_ByPolicy(TestCaseName)

			Test[TestCaseName] = function(self)

				local Notification = createDefaultNotification()

				self:verify_Notification_IsIgnored_Case(Notification)

			end
		end



	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnSystemRequest")

		--Precondition: Update policy table
		testCasesForPolicyTable:updatePolicy(PTName)

		--Send notification and check it is ignored
		OnSystemRequest_IsIgnored_ByPolicy("OnSystemRequest_IsNotExistInPT_IsIgnored_By_Disallowed")
	----------------------------------------------------------------------------------------------


	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PermissionLinesForBase4 = nil
		local PermissionLinesForGroup1 = PermissionLines_OnSystemRequest .. "\n"
		local appID = config.application1.registerAppInterfaceParams.fullAppID
		local PermissionLinesForApplication =
		[[			"]]..appID ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4", "group1"]
					},
		]]

		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnSystemRequest"})
		testCasesForPolicyTable:updatePolicy(PTName)

		--Send notification and check it is ignored
		OnSystemRequest_IsIgnored_ByPolicy("OnSystemRequest_IsIgnored_By_UserHasNotConsentedYet_Disallowed")

	----------------------------------------------------------------------------------------------


	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: User does not allow function group
		testCasesForPolicyTable:userConsent(false, "group1")

		OnSystemRequest_IsIgnored_ByPolicy("OnSystemRequest_IsIgnored_By_UserDisallowed")
	----------------------------------------------------------------------------------------------


	--4. Notification is exist in PT and user allow function group that contains this notification
	----------------------------------------------------------------------------------------------
		--Precondition: User allows function group
		testCasesForPolicyTable:userConsent(true, "group1")

		OnSystemRequest_AllParametersLowerBound_SUCCESS("OnSystemRequest_IsAllowed")
	----------------------------------------------------------------------------------------------
	end

	--TODO: PT is blocked by ATF defect APPLINK-19188
	--ResultCodesChecks()
	--Note: OnSystemRequest is allowed in all hmi levels, no need verifying DISALLOWED cases. Remove SequenceChecks() function and precondition #3: --3. Update policy table

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC check SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions

--Test cases:
        -- TC_OnSystemRequest_01(SDLAQ-TC-348): It is ignored because it was moved to obsolete folder and link is not exist (https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/manual_test_cases/Obsolete/TC_OnSystemRequest_1.vsd).
        -- TC_OnSystemRequest_02(SDLAQ-TC-349): It is ignored because it was moved to obsolete folder and link is not exist (https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/manual_test_cases/v2.1/TC_OnSystemRequest_2.vsd).
        -- TC_SDL4_0_OnsystemRequest_07(SDLAQ-TC-1050): 07[P][MAN]_TC_SDL_sends_OnSystemRequest_after_unsuccessful_attempt(APPLINK-17903): is developed newly in 01[ATF]_TC_OnSystemRequest_QUERY_APPS(APPLINK-18301)
        -- TC_SDL4_0_OnsystemRequest_02(SDLAQ-TC-982): 02[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_if_SDL4.0_disabled(APPLINK-17893)
        -- It is covered in APPLINK-19305: 01[ATF]_TC_Common_cases

    -- Below test cases were covered by 01[ATF]_TC_OnSystemRequest_QUERY_APPS(APPLINK-18301):
	-- TC_SDL4_0_OnsystemRequest_01(SDLAQ-TC-978): 01[P][MAN]_TC_SDL_sends_OnSystemRequest_to_registered_app(APPLINK-17892)
	-- TC_SDL4_0_OnsystemRequest_03(SDLAQ-TC-983): 03[P][MAN]_TC_SDL_sends_OnSystemRequest_to_different_devices(APPLINK-17898)
	-- TC_SDL4_0_OnsystemRequest_04(SDLAQ-TC-986): 04[P][MAN]_TC_SDL_sends_OnSystemRequest_to_foreground_app(APPLINK-17900)
	-- TC_SDL4_0_OnsystemRequest_05(SDLAQ-TC-989): 05[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_to_background_apps(APPLINK-17901)
	-- TC_SDL4_0_OnsystemRequest_06(SDLAQ-TC-991): 06[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_to_new_foreground_app(APPLINK-17902)


local function SequenceChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Manual test cases")

	--APPLINK-18377: 13[P][MAN]_TC_SDL_resends_OnSystemRequest_with_HMI_appID
	--APPLINK-18379: 15[P][MAN]_TC_SDL_resends_OnSystemRequest_to_any_app_without_appID

	local function APPLINK_18377_and_APPLINK_18379()

		--1. Precondition: Add new session
		Test["APPLINK_18377_Precondition_Add_new_session"] = function(self)

		  -- Connected expectation
			Test.mobileSession2 = mobile_session.MobileSession(Test,Test.mobileConnection)

			Test.mobileSession2:StartService(7)
		end

		--2. Precondition: Register the second app
		Test["APPLINK_18377_Precondition_Register_App_IVSU"]  = function(self)

			local App_parameters = commonFunctions:cloneTable(config.application1.registerAppInterfaceParams)
			App_parameters.appName  = "IVSU"
			App_parameters.appID  = "IVSU"

			--mobile side: RegisterAppInterface request
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", App_parameters)

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = App_parameters.appName
				}
			})
			:Do(function(_,data)
				Apps[2].appId = data.params.application.appID
			end)

			--mobile side: RegisterAppInterface response
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end

		--3. Send OnSystemRequest notification with appId of the first app => SDL only forwards this notification to mobile app1
		Test["APPLINK_18377_OnSystemRequest_With_appID1_InCase_Many_Apps"] = function(self)

			commonTestCases:DelayedExp(1000)

			local Notification =
				{
					requestType = "PROPRIETARY",
					fileType = "JSON",
					offset = 1000,
					length = 10000,
					timeout = 500,
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST",
					appID = Apps[1].appId
				}

			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

			local mobileExpectation = buildMobileExpectedResult(Notification)

			--mobile side: expected OnSystemRequest
			EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
			:Timeout(1000)



			self.mobileSession2:ExpectNotification("OnSystemRequest", mobileExpectation)
			:Timeout(1000)
			:Times(0)

		end


		--4. Send OnSystemRequest notification with appId of the second app => SDL only forwards this notification to mobile app2

		Test["APPLINK_18377_OnSystemRequest_With_appID2_InCase_Many_Apps"] = function(self)

			commonTestCases:DelayedExp(1000)

			local Notification =
				{
					requestType = "PROPRIETARY",
					fileType = "JSON",
					offset = 1000,
					length = 10000,
					timeout = 500,
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST",
					appID = Apps[2].appId
				}

			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

			local mobileExpectation = buildMobileExpectedResult(Notification)

			--mobile side: expected OnSystemRequest
			EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
			:Timeout(1000)
			:Times(0)

			self.mobileSession2:ExpectNotification("OnSystemRequest", mobileExpectation)
			:Timeout(1000)

		end

		--5. Send OnSystemRequest notification without appId => SDL forwards this notification to mobile app1 or app2
		Test["APPLINK_18379_OnSystemRequest_Without_appID_InCase_Many_Apps"] = function(self)

			local Notification =
				{
					requestType = "PROPRIETARY",
					fileType = "JSON",
					offset = 1000,
					length = 10000,
					timeout = 500,
					fileName = "/home/luxoft/sdl_hmi/IVSU/PROPRIETARY_REQUEST"
				}

			self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)

			local mobileExpectation = buildMobileExpectedResult(Notification)

			--mobile side: expected OnSystemRequest
			EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
			:Timeout(1000)


			self.mobileSession2:ExpectNotification("OnSystemRequest", mobileExpectation)
			:Timeout(1000)
			:Times(0)

		end

		-------------------------------------------------------------------------------------------

			--Special cases for OnSystemRequest(requestType = NAVIGATION):
               -- 1. notification with appId of the first app => SDL forwards this notification to mobile app1 only
		      -- 2. notification with appId of the second app => SDL forwards this notification to mobile app2 only
-------------------------------------------------------------------------------------------

		 function Test:OSR_NAVIGATION_ToApp1IfManyApps()

                 commonTestCases:DelayedExp(1000)

                 Notification =
			{
			    requestType = "NAVIGATION",
			    appID = Apps[1].appID,
                            fileName = "NAVIGATION_REQUEST.jpg"

			}

         	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)


			--mobile side: expected OnSystemRequest
			EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
			:Timeout(1000)


			self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "NAVIGATION"})
			:Timeout(1000)
			:Times(0)

	       end


		function Test:OSR_NAVIGATION_ToApp2IfManyApps()

                 commonTestCases:DelayedExp(1000)

                 Notification =
			{
			    requestType = "NAVIGATION",
			    appID = Apps[2].appId,
                            fileName = "NAVIGATION_REQUEST.jpg"

			}

         	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification)


			--mobile side: expected OnSystemRequest
			EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "NAVIGATION"})
			:Timeout(1000)
			:Times(0)

			self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "NAVIGATION"})
			:Timeout(1000)

	       end


	end

	APPLINK_18377_and_APPLINK_18379()

	--APPLINK-11778([RTC 602443] Removal of the policyAppId (string) param and change appID (string) to appID (integer)): check removing of the policyAppId (string) param
	function Test:APPLINK_11778_OnSystemRequest_Remove_policyAppId_Param()

		local Notification = createDefaultNotification()

		local Notification_with_policyAppId = createDefaultNotification()
		Notification_with_policyAppId.policyAppId = "abc"

		--hmi side: sending OnSystemRequest notification
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", Notification_with_policyAppId)


		--mobile side: expected OnSystemRequest
		local mobileExpectation = buildMobileExpectedResult(Notification)
		EXPECT_NOTIFICATION("OnSystemRequest", mobileExpectation)
		:Timeout(1000)
		:ValidIf (function(_,data)
			if data.payload.policyAppId then
				commonFunctions:printError(" SDL resends policyAppId parameter to mobile app ")
				return false
			else
				return true
			end
		end)
	end


end

SequenceChecks()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA:
	--SDLAQ-CRS-1304: HMI Status Requirements for OnSystemRequest (FULL, LIMITED, BACKGROUND, NONE)

	--Verification criteria:
		--The applications in HMI NONE don't reject OnSystemRequest request.
		--The applications in HMI LIMITED don't reject OnSystemRequest request.
		--The applications in HMI BACKGROUND don't reject OnSystemRequest request.
		--The applications in HMI FULL don't reject OnSystemRequest request. => It is covered by above many test cases in TEST BLOCK VII

	local function DifferentHMIlevelChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Different HMI Levels")


		--1. HMI level is NONE
		----------------------------------------------------------------------------------------------
			--Precondition: Deactivate app to NONE HMI level
			commonSteps:DeactivateAppToNoneHmiLevel()

			OnSystemRequest_AllParametersLowerBound_SUCCESS("OnSystemRequest_InNoneHmiLevel_IsAllowed")

			--Postcondition: Activate app
			commonSteps:ActivationApp()



		--2. HMI level is LIMITED
		----------------------------------------------------------------------------------------------
			if commonFunctions:isMediaApp() then
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()

				OnSystemRequest_AllParametersLowerBound_SUCCESS("OnSystemRequest_InLimitedHmiLevel_IsAllowed")

				--Postcondition: Activate app
				commonSteps:ActivationApp()
			end



		--3. HMI level is BACKGROUND
		----------------------------------------------------------------------------------------------
			--Precondition:
			commonTestCases:ChangeAppToBackgroundHmiLevel()

			OnSystemRequest_AllParametersLowerBound_SUCCESS("OnSystemRequest_InBackgroundHmiLevel_IsAllowed")

	end
	DifferentHMIlevelChecks()

---------------------------------------------------------------------------------------------
-------------------------------------------Post-conditions-----------------------------
---------------------------------------------------------------------------------------------

--Postcondition: restore sdl_preloaded_pt.json
testCasesForPolicyTable:Restore_preloaded_pt()                   
	
return Test


