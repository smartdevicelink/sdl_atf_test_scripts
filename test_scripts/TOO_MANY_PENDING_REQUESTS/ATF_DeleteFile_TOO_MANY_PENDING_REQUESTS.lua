--Note: Update PendingRequestsAmount = 3 in .ini file

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')


require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "DeleteFile" -- use for above required scripts.

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--1. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")
	
	--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3 
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)
		
	--3. Activation App by sending SDL.ActivateApp	
	commonSteps:ActivationApp()
	
	--4. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	--policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")
	
	
	--4. PutFile 
	for n = 1, 30 do
		fileName = "icon_" .. tostring(n)
		commonSteps:PutFile("Precondition_PutFile_" .. fileName .. ".png", fileName .. ".png")	 
	end
	
		
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------
--Begin test case ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

    --Requirement id in JAMA: SDLAQ-CRS-717

    --Verification criteria: The system has more than 1000 requests  at a time that haven't been responded yet. The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all futher requests, until there are less than 1000 requests at a time that have not been responded by the system yet.

	  function Test:DeleteFile_TooManyPendingRequest()
		
		local numberOfRequest = 30
		
		for i = 1, numberOfRequest do
			--mobile side: DeleteFile request  
			local cid = self.mobileSession:SendRPC("DeleteFile",
			{
				syncFileName = "icon_"..tostring(i) .. ".png"
			})
		end
		
		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
	end
	  
	--End test case ResultCodeCheck

	--Post condition: Restore smartDeviceLink.ini file for SDL
	function Test:RestoreFile_smartDeviceLink_ini()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end
	
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()
	
	


return Test
