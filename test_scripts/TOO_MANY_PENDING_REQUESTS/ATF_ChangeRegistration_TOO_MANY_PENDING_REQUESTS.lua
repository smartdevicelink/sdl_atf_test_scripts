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
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
----------------------------------------------------------------------------------------------


local n = 0
function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end
function changeRegistrationAllParams()
	local temp = {
		language ="EN-US",
		hmiDisplayLanguage ="EN-US",
		appName ="SyncProxyTester",
		ttsName =
		{
			{
				text ="SyncProxyTester",
				type ="TEXT",
			},
		},
		ngnMediaScreenAppName ="SPT",
		vrSynonyms =
		{
			"VRSyncProxyTester",
		},
	}
	return temp
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")

	--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)

	--3. Activation App by sending SDL.ActivateApp
	commonSteps:ActivationApp()

	--4. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_ForChangeRegistration.json", "files/PTU_WithOutChangeRegistrationRPC.json")

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")

--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-699

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.
	function Test:ChangeRegistration_TooManyPendingRequests()
		local numberOfRequest = 10
		for i = 1, numberOfRequest do
			--mobile side: send ChangeRegistration request
			self.mobileSession:SendRPC("ChangeRegistration", changeRegistrationAllParams())
		end

		EXPECT_ANY_SESSION_NOTIFICATION("ChangeRegistration")
		:ValidIf(function(exp,data)
      	if
          data.rpcFunctionId == 30 and
      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
            n = n+1
				print("ChangeRegistration response came with resultCode TOO_MANY_PENDING_REQUESTS")
				return true
        elseif
			exp.occurences == numberOfRequest and n == 0 then
			print("Response ChangeRegistration with resultCode TOO_MANY_PENDING_REQUESTS did not came")
			return false
        elseif
			data.rpcFunctionId == 30 and
			data.payload.resultCode == "SUCCESS" then
				print("ChangeRegistration response came with resultCode SUCCESS")
            return true
        elseif
			data.rpcFunctionId == 30 then
				print("ChangeRegistration response came with resultCode "..tostring(data.payload.resultCode))
            return false
        end
      end)
      :Times(AtLeast(numberOfRequest))

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













