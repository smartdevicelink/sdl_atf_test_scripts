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
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

APIName = "UnsubscribeWayPoints" -- use for above required scripts.


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--1. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")
	
	--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3 
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)
		
	--3. Activation App by sending SDL.ActivateApp	
	commonSteps:ActivationApp()
	
	--ToDo: This TC is blocked on ATF 2.2 by defect APPLINK-19188. Please try ATF on commit f86f26112e660914b3836c8d79002e50c7219f29
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
	--ToDo: Update when new policy table update flow finishes implementation
	-- testCasesForPolicyTable:updatePolicy(PTName)	
	--local PTName = "files/ptu_general.json"
	--testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
	
	function Test:backUpPreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
	end
	
	Test:backUpPreloadedPt()

	 function Test:updatePreloadedJson()
	  -- body
	  pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
	  local file  = io.open(pathToFile, "r")
	  local json_data = file:read("*all") -- may be abbreviated to "*a";
	  file:close()

	  local json = require("modules/json")
	   
	  local data = json.decode(json_data)
	  for k,v in pairs(data.policy_table.functional_groupings) do
	   if (data.policy_table.functional_groupings[k].rpcs == nil) then
		   --do
		   data.policy_table.functional_groupings[k] = nil
	   else
		   --do
		   local count = 0
		   for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
		   if (count < 30) then
			   --do
		 data.policy_table.functional_groupings[k] = nil
		   end
	   end
	  end
	  
	  data.policy_table.functional_groupings["Base-4"]["rpcs"]["SubscribeWayPoints"] = {}
	  data.policy_table.functional_groupings["Base-4"]["rpcs"]["SubscribeWayPoints"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}
	  
	  data.policy_table.functional_groupings["Base-4"]["rpcs"]["UnsubscribeWayPoints"] = {}
	  data.policy_table.functional_groupings["Base-4"]["rpcs"]["UnsubscribeWayPoints"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}

	  
	  data = json.encode(data)

	  file = io.open(pathToFile, "w")
	  file:write(data)
	  file:close()
	 end
	 Test:updatePreloadedJson()
	

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Begin Test case ResultCodeChecks
--Description: Check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-633

    --Verification criteria: The system has more than 1000 requests  at a time that haven't been responded yet. The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all the further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.
	
	
	function Test:UnSubscribeWayPoints_VerifyResultCode_TOO_MANY_PENDING_REQUESTS()
		print("vao ko")
		local numberOfRequest = 20
		for i = 1, numberOfRequest do
			--mobile side: send the request 	 	
			self.mobileSession:SendRPC("UnsubscribeWayPoints",{})				
		end
		

		commonTestCases:verifyResultCode_TOO_MANY_PENDING_REQUESTS(numberOfRequest)
	end	

	
	
	--End Test case ResultCodeChecks


	--Post condition: Restore smartDeviceLink.ini file for SDL
	function Test:RestoreFile_smartDeviceLink_ini()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end


	--Postcondition: Restore_preloaded_pt
	--	testCasesForPolicyTable:Restore_preloaded_pt()
	
return Test


