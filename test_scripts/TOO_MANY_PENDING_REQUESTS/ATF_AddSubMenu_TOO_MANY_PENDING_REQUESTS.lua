Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "AddSubMenu"

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
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})
	
	--4. PutFile 
	commonSteps:PutFile("Precondition_PutFile_icon.png", "icon.png")
		

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-431

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.	
	
	function Test:AddSubMenu_TooManyPendingRequests()
	
		local numberOfRequest = 20
		
		for i = 1, numberOfRequest do
			--mobile side: sending AddSubMenu request
			local cid = self.mobileSession:SendRPC("AddSubMenu",
												{
													menuID = i,
													menuName ="SubMenu"..tostring(i)
												})
		end
		
		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)

	end	
	
	
	--Post condition: Restore smartDeviceLink.ini file for SDL
	function Test:RestoreFile_smartDeviceLink_ini()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end
	
	
	--Postcondition: restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()
	
--End Test suit ResultCodeCheck		