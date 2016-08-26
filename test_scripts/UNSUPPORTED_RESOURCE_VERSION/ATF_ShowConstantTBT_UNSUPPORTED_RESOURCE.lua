--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_Navigation_isReady_unavailable.lua
commonPreconditions:Connecttest_Navigation_IsReady_available_false("connecttest_Navigation_isReady_unavailable.lua", true)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_Navigation_isReady_unavailable')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')


APIName = "ShowConstantTBT" -- set request name

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2 Removing user_modules/connecttest_Navigation_isReady_unavailable.lua, restore hmi_capabilities
	function Test:Precondition_remove_user_connecttest_restore_preloaded()
	 	os.execute( "rm -f ./user_modules/connecttest_Navigation_isReady_unavailable.lua" )
	 	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	--3. Activate application
	commonSteps:ActivationApp()

	--4. Update preloaded
	commonPreconditions:BackupFile("sdl_preloaded_pt.json")
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})



---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")


--Description:TC check UNSUPPORTED_RESOURCE resultCode

	--Requirement id in JAMA: SDLAQ-CRS-1033

    --Verification criteria:  Used if UI isn't available now (not supported). General request result "success" should be "false".

		function Test:ShowConstantTBT_UNSUPPORTED_RESOURCE()

			--request from mobile side
			local cid= self.mobileSession:SendRPC("ShowConstantTBT",
			{
				navigationText1 = "NavigationText1"
			})

			--response on mobile side
			EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
			:Timeout(2000)
		end
--End Test suit ResultCodeCheck

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


 return Test
