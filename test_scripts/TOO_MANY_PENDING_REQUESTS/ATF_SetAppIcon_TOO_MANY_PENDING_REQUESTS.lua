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

APIName = "SetAppIcon" -- use for above required scripts.

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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
	
	--5. PutFiles	
	commonSteps:PutFile("FutFile_app_icon_png", "app_icon.png")


----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-733

	--Verification criteria: SDL response TOO_MANY_PENDING_REQUESTS resultCode
			
  function Test:SetAppIcon_TOO_MANY_PENDING_REQUESTS()

	local numberOfRequest = 20
	
	--Sending many SetAppIcon requests
  	for i = 1, numberOfRequest do

		--mobile side: sending SetAppIcon request
		local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "app_icon.png" })
			
	end

	commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
    
  end


	--Post condition: Restore smartDeviceLink.ini file for SDL
	function Test:RestoreFile_smartDeviceLink_ini()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end


	--Postcondition: Restore_preloaded_pt
	policyTable:Restore_preloaded_pt()

return Test