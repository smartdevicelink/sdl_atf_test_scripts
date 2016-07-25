Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local TooManyPenReqCount = 0


---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "PerformAudioPassThru" -- use for above required scripts.

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")

	--3. Update smartDeviceLink.ini file: PendingRequestsAmount = 3
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)

	--4. Activation App by sending SDL.ActivateApp
	commonSteps:ActivationApp()

	--5. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_OmittedPerformAudioPassThru.json", "files/PTU_ForPerformAudioPassThru.json")

---------------------------------------------------------------------------------------------

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end


----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")


--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-556

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a time that haven't been responded yet.

	function Test:PerformAudioPassThru_TooManyPendingRequests()
		for i = 1, 20 do
			--mobile side: sending PerformAudioPassThru request
			local cid = self.mobileSession:SendRPC("PerformAudioPassThru",{
																samplingRate ="8KHZ",
																maxDuration = 2000,
																bitsPerSample ="8_BIT",
																audioType = "PCM"
															})
		end

		EXPECT_RESPONSE("PerformAudioPassThru")
			:ValidIf(function(exp,data)
				if
					data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
			    		TooManyPenReqCount = TooManyPenReqCount+1
			    		print(" \27[32m PerformAudioPassThru response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
						return true
				elseif
				   	exp.occurences == 20 and TooManyPenReqCount == 0 then
				  		print(" \27[36m Response PerformAudioPassThru with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
			  			return false
				elseif
			  		data.payload.resultCode == "GENERIC_ERROR" then
			    		print(" \27[32m PerformAudioPassThru response came with resultCode GENERIC_ERROR \27[0m")
			    		return true
				else
			    	print(" \27[36m PerformAudioPassThru response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
			    	return false
				end
			end)
			:Times(20)
			:Timeout(15000)

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

		DelayedExp()
	end
--End Test suit ResultCodeCheck


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test















