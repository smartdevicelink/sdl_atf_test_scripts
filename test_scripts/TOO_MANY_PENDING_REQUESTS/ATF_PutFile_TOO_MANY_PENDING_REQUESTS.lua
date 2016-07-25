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

APIName = "PutFile"

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--1. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")
	
	--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3 
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)
		
	--3. Activation App by sending SDL.ActivateApp	
	commonSteps:ActivationApp()

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-708

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a time that haven't been responded yet.	
	
	
	function Test:PutFile_TooManyPendingRequests()
		
		local numberOfRequest = 100
		
		for i = 1, numberOfRequest do

			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC(APIName,
												{
													syncFileName ="icon_" .. tostring(i).. ".png",
													fileType ="GRAPHIC_PNG",
													persistentFile =false,
													systemFile = false,
													offset =0,
													length =11600
												}, "files/icon.png")
		end
		
		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
		
	end	
	
	
	--Post condition: Restore smartDeviceLink.ini file for SDL
	function Test:RestoreFile_smartDeviceLink_ini()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end

--End Test suit ResultCodeCheck














