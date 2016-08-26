--Note: Update PendingRequestsAmount =3 in .ini file

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

APIName = "SetMediaClockTimer" -- use for above required scripts

local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end



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


	--4. Activate application
	commonSteps:ActivationApp()

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------


--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")

  function Test:SetMediaClockTimer_TooManyPendingRequest()
	--Sending 20 SetMediaClockTimer requests
	for n = 1, 20 do
		--mobile side: SetMediaClockTimer request
		local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
		{
			startTime =
			{
				hours = 0,
				minutes = 1,
				seconds = 33
			},
			endTime =
			{
				hours = 0,
				minutes = 1,
				seconds = 35
			},
			updateMode = "COUNTUP"
		})
	  end

    --expect response SetMediaClockTimer
    EXPECT_RESPONSE("SetMediaClockTimer")
    	:ValidIf(function(exp,data)
			if
				data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
		    		TooManyPenReqCount = TooManyPenReqCount+1
		    		print(" \27[32m SetMediaClockTimer response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
					return true
			elseif
			   	exp.occurences == 20 and TooManyPenReqCount == 0 then
			  		print(" \27[36m Response SetMediaClockTimer with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
		  			return false
			elseif
		  		data.payload.resultCode == "GENERIC_ERROR" then
		    		print(" \27[32m SetMediaClockTimer response came with resultCode GENERIC_ERROR \27[0m")
		    		return true
			else
		    	print(" \27[36m SetMediaClockTimer response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
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



---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test















