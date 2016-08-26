Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
APIName = "Slider" -- use for above required scripts.


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--1. Backup smartDeviceLink.ini file
commonPreconditions:BackupFile("smartDeviceLink.ini")

--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3
commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)

--3. Activate application
commonSteps:ActivationApp()

--4. Update policy to allow request
policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks
--Description: Check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-655

    --Verification criteria: The system has more than 1000 requests at a time that haven't been responded yet. The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.



	function Test:Slider_VerifyResultCode_TOO_MANY_PENDING_REQUESTS()

		local numberOfRequest = 10
		for i = 1, numberOfRequest do
			--mobile side: send the request
			self.mobileSession:SendRPC(APIName,
												{
													numTicks = 7,
													position = 6,
													sliderHeader ="sliderHeader",
													sliderFooter =
													{
														"sliderFooter1",
														"sliderFooter2",
														"sliderFooter3",
														"sliderFooter4",
														"sliderFooter5",
														"sliderFooter6",
														"sliderFooter7",
													},
													timeout = 3000,
												}
										)
		end


		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
	end


--End Test case ResultCodeChecks



--Postcondition: restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()

return Test






















