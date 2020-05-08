Test = require('connecttest')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

local floatParameterInNotification = require('user_modules/shared_testcases/testCasesForFloatParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local stringArrayParameterInNotification = require('user_modules/shared_testcases/testCasesForArrayStringParameterInNotification')
local imageParameterInNotification = require('user_modules/shared_testcases/testCasesForImageParameterInNotification')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName="UnsubcribleWayPoints"
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
local storagePath = config.pathToSDL..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"	

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
------------------------------------ Common Functions ---------------------------------------
-- ---------------------------------------------------------------------------------------------

local function SubscribeWayPoints_Success(TCName)
				
	Test[TCName] = function(self)
	--self:subscribeWayPoints()
	--mobile side: send SubscribeWayPoints request
	
    	--mobile side: send SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})

    --hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")

    :Do(function(_,data)
        --hmi side: sending Navigation.SubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
      end)

    --mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
	
	--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
	--EXPECT_NOTIFICATION("OnHashChange")
	end		
end

function Test:unSubscribeWayPoints()
	--mobile side: sending UnsubscribeWayPoints request
	local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
	
	--hmi side: expect UnsubscribeWayPoints request
	EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.UnsubscribeWayPoints response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
	end)
	
	--mobile side: expect UnsubscribeWayPoints response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	
	--mobile side: expect OnHashChange notification
	--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
	--EXPECT_NOTIFICATION("OnHashChange")

end

function Test:registerAppInterface2()

	config.application2.registerAppInterfaceParams.isMediaApplication=false
	config.application2.registerAppInterfaceParams.appHMIType={"DEFAULT"}
	
	--mobile side: sending request 
	local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

	--hmi side: expect BasicCommunication.OnAppRegistered request
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = config.application2.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID					
		end)

	--mobile side: expect response
	self.mobileSession1:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = config.syncMsgVersion
		})
		:Timeout(2000)

	--mobile side: expect notification
	self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	:Timeout(2000)
end	

function Test:registerAppInterface3()
	--mobile side: sending request 
	local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)

	--hmi side: expect BasicCommunication.OnAppRegistered request
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
				{
					appName = config.application3.registerAppInterfaceParams.appName
				}
		})
		:Do(function(_,data)
			self.applications[config.application3.registerAppInterfaceParams.appName] = data.params.application.appID					
	end)

	--mobile side: expect response
	self.mobileSession2:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = config.syncMsgVersion
		})
		:Timeout(2000)

	--mobile side: expect notification
	self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Timeout(2000)
end		
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	-- Delete Logs
	commonSteps:DeleteLogsFileAndPolicyTable()
	
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
	
	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end
	
	--Activation App
	commonSteps:ActivationApp()
	
	-- PutFiles
	commonSteps:PutFile( "PutFile_MinLength", "a")
	commonSteps:PutFile( "PutFile_icon.png", "icon.png")
	commonSteps:PutFile( "PutFile_action.png", "action.png")
	commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)
	
	local PermissionLines_SubcribeWayPoints = 
[[					"SubscribeWayPoints": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						]
					  }]]

	local PermissionLines_UnsubcribeWayPoints = 
[[					"UnsubscribeWayPoints": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						]
					  }]]

	local PermissionLinesForBase4 = PermissionLines_SubcribeWayPoints .. ", \n" .. PermissionLines_UnsubcribeWayPoints ..", \n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	
	--ToDo: This TC is blocked on ATF 2.2 by defect APPLINK-19188. Please try ATF on commit f86f26112e660914b3836c8d79002e50c7219f29
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
	--ToDo: Update when new policy table update flow finishes implementation
	-- testCasesForPolicyTable:updatePolicy(PTName)	
	--local PTName = "files/ptu_general.json"
	--testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
	

	
  ---------------------------------------------------------------------------------------------
  -----------------------------------------TEST BLOCK I----------------------------------------
  ------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)----
  ---------------------------------------------------------------------------------------------
    --Postcondition: WayPoints are subcribed successfully.
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_1")
  --Begin Test suit CommonRequestCheck
  --Description:
  --Request with no parameters in Full HMI level
  --Requirement id in JAMA/or Jira ID:
  -- APPLINK-21629 req#1

  -- Verification criteria:
  -- In case mobile app sends the valid UnsuscibeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer UnsubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app
  -- The request for UnsubscribeWayPoints is sent and executed successfully. The response code SUCCESS is returned.

  --Begin Test case CommonRequestCheck.1
  
    function Test:UnSubscribeWayPoints_Success()
	
		self:unSubscribeWayPoints()

	end

  --End Test suit CommonRequestCheck.1

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For Special Request Checks")
	
	--Postcondition: WayPoints are subcribed successfully.
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_2")
	
	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON
		--Verification criteria: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.	
		--Requirement id in JAMA/or Jira ID:
		--APPLINK-21629 #3 (APPLINK-16739)
		
	function Test:UnsubscribeWayPoints_InvalidJSON()

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		--mobile side: UnsubscribeWayPoints request
		local msg =
		{
			serviceType = 7,
			frameInfo = 0,
			rpcType = 0,
			rpcFunctionId = 43,
			rpcCorrelationId = self.mobileSession.correlationId,
			--<<!-- extra ','
			payload = '{,}'
		}
		self.mobileSession:Send(msg)

		--hmi side: there is no SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)

		--mobile side:SubscribeWayPoints response
		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	
	end
	
	--End Test case NegativeRequestCheck.1

	--Begin Test case NegativeRequestCheck.2
		--Description: Check processing UnsubscribeWayPoints request with fake parameter	
		--Requirement id in JAMA/or Jira ID:
		--APPLINK-14765
		
	function Test:UnsubscribeWayPoints_FakeParam()

		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {fakeParam = "fakeParam"})

		--hmi side: there is no UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")

		:Do(function(_,data)
			--hmi side: sending Navigation.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		  end)
		:ValidIf(function(_,data)
			if data.params then
			  print("SDL re-sends fakeParam parameters to HMI in UnsubscribeWayPoints request")
			  return false
			else
			  return true
			end
		  end)

		--mobile side: UnsubscribeWayPoints response
		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})

		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")

	end
	--End Test case NegativeRequestCheck.2
	
	-- Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_3")

	--Begin Test case CommonRequestCheck.3
	  --Description: Check processing UnsubscribeWayPoints request with parameters from another request
	  --Requirement id in JAMA/or Jira ID:
	  --APPLINK-14765

	function Test:UnsubscribeWayPoints_AnotherRequest()

    --mobile side: UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", { menuName = "shouldn't be transfered" })

    --hmi side: there is no UnsubscribeWayPoints request
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")


    :Do(function(_,data)
        --hmi side: sending Navigation.UnsubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :ValidIf(function(_,data)
        if data.params then
          print("SDL re-sends fakeParam parameters to HMI in UnsubscribeWayPoints request")
          return false
        else
          return true
        end
      end)

    --mobile side: UnsubscribeWayPoints response
    self.mobileSession:ExpectResponse(CorIdSWP, { success = true, resultCode = "SUCCESS" })

    --TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
	--EXPECT_NOTIFICATION("OnHashChange")

	
	end
	--End Test case NegativeRequestCheck.3

	--Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_4")

  --Begin Test case CommonRequestCheck.4
	  --Description: Check processing requests with duplicate correlationID
	  --TODO: fill Requirement, Verification criteria about duplicate correlationID
	  --Requirement id in JAMA/or Jira ID:
	  -- APPLINK-21629 #6 (APPLINK-21906)

	function Test:UnsubscribeWayPoints_correlationIdDuplicateValue()

		--mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending Navigation.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		  end)

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,
		  { success = true, resultCode = "SUCCESS"},
		  { success = false, resultCode = "IGNORED"})
		:Times(2)
		:Do(function(exp,data)

			if exp.occurences == 1 then

			  --mobile side: UnsubscribeWayPoints request
			  local msg =
			  {
				serviceType = 7,
				frameInfo = 0,
				rpcType = 0,
				rpcFunctionId = 43,
				rpcCorrelationId = self.mobileSession.correlationId,
				payload = '{}'
			  }
			  self.mobileSession:Send(msg)
			end

		  end)

		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")
			
	end	
	--End Test case NegativeRequestCheck.4
end

SpecialRequestChecks()

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI Response--------------------------
-----------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("Test suite: common test cases for response")
------------------------------------------------------------------------------------------------
local function HMIResponseChecks()
	--Begin Test case CommonRequestCheck.4
		 --Description: Send valid UnsubcribleWayPoints() when WayPoint is not subscribled.
		 --Requirement id in JAMA/or Jira ID:
		 -- APPLINK-21641 #6 (APPLINK-21906)

	function Test:UnsubscribeWayPoints_IGNORED()
		commonTestCases:DelayedExp(2000)
		
		--mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
   
   --End Test case NegativeRequestCheck.4
	
	--Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_5")
	
	--Begin Test case CommonRequestCheck.
		 --Description: check "info" value in out of bound, missing, with wrong type, empty, duplicate etc.
		 --Requirement id in JAMA/or Jira ID:
		 --APPLINK-14551
	function Test:UnsubscribeWayPoints_Success_info_empty()

		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")

		:Do(function(_,data)
			--hmi side: sending Navigation.UnsubscribeWayPoints response
			-- According CRS APPLINK-14551 In case HMI responds via RPC with "message" param AND the value of "message" param is empty SDL must NOT transfer "info" parameter via corresponding RPC to mobile app
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = ""} )
		  end)

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = true , resultCode = "SUCCESS"})

		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")

	end
	
	
	--Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_6")

	--Begin Test case CommonRequestCheck.
		 --Description: check "info" value in out of bound, missing, with wrong type, empty, duplicate etc.
		 --Requirement id in JAMA/or Jira ID:
		 --APPLINK-14551

	function Test:UnsubscribeWayPoints_Success_info_out_upper_bound()

		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")

		:Do(function(_,data)
			--hmi side: sending Navigation.UnsubscribeWayPoints response
			-- According CRS APPLINK-14551 In case SDL receives <message> from HMI with maxlength more than defined for <info> param at MOBILE_API SDL must:truncate <message> to maxlength of <info> defined at MOBILE_API
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMessage1001} )
		  end)

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = true , resultCode = "SUCCESS", info = infoMessage1000})

		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")

	end
	-- End Test case NegativeRequestCheck.2

end

HMIResponseChecks()		


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Related requirements: APPLINK-21641

--Verification criteria
--[[ 
	1.InvalidJsonSyntax
	2. InvalidStructure
	3. FakeParams 
	4. FakeParameterIsFromAnotherAPI
	5. SeveralNotifications with the same values
	6. SeveralNotifications with different values
--]]
commonFunctions:newTestCasesGroup("Test suite IV: SpecialHMIResponseCheck")	

local function SpecialNotificationChecks()

	--1. Verify UnsubscribeWayPoints with invalid Json syntax
	----------------------------------------------------------------------------------------------
	--Requirement id in JAMA/or Jira ID:
	--Verification criteria: --Description: Invalid structure of response.
	
	--Post Condition 
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_7")

	
	function Test:UnsubscribeWayPoints_Response_IsInvalidJson()
	
		commonTestCases:DelayedExp(2000)
		 --mobile side: UnsubscribeWayPoints request
		
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		
		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				--hmi side: sending the response
				 -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"Navigation.UnsubscribeWayPoints"}}')
				 self.hmiConnection:Send('{"id";'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
				 
			end)
		
		--mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR" })
		:Timeout(12000)
	
	end		
  
 
	-- 2. Verify parameter is not from any API
	
	function Test:UnsubscribeWayPoints_Response_FakeParams_IsNotFromAnyAPI()
	
		commonTestCases:DelayedExp(2000)
		
		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		
		--hmi side: there is no UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				
		end)
		
		--mobile side: expect the response
		local ExpectedResponse = commonFunctions:cloneTable()
			
		ExpectedResponse["success"] = true
		ExpectedResponse["resultCode"] = "SUCCESS"
		ExpectedResponse["fake"] = nil
		
		EXPECT_RESPONSE(CorIdSWP, ExpectedResponse)
		:ValidIf (function(_,data)
		
			if data.payload.fake then
				commonFunctions:printError(" SDL resend fake parameter to mobile app ")
				return false
			else 
				return true
			end
			
		end)
		
    end
	
	-- Post Condition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_8")
  
	-- 3. Verify parameter is from other API
	function Test:UnsubscribeWayPoints_FakeParams_IsFromAnotherAPI()
	
		--mobile side: sending the request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
									
		--hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")	
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
		end)
		--mobile side: expect the response
		local ExpectedResponse = commonFunctions:cloneTable()
		ExpectedResponse["success"] = true
		ExpectedResponse["resultCode"] = "SUCCESS"
		ExpectedResponse["sliderPosition"] = nil
		EXPECT_RESPONSE(cid, ExpectedResponse)
		:ValidIf (function(_,data)
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL resend fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)
					
	end								
		
	-- Post Condition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_9")
	
	-- 4. Verify reponse is invalid json
	function Test:UnsubscribeWayPoints_Response_IsInvalidStructure()

		--mobile side: sending the request
		
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
							
		--hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
			self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.UnsubscribeWayPoints"}}')
			 
		end)							
	
		--mobile side: expect response 
		EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
		:Timeout(12000)
					
	end

	 --Postcondition
	 SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_10")
	 
	--5. Verification criteria: the request is sent 2 times concusively
 
	function Test:UnsubscribeWayPoints_Success()
  
		self:unSubscribeWayPoints()
	
	end
  
	function Test:UnsubscribeWayPoints_IGNORED()
	
		commonTestCases:DelayedExp(2000)
		
		--mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
  
	--Postcondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_11")
 
	--6. Verification criteria: HMI send error to SDL
	function Test:UnsubscribeWayPoints_REJECTED()
	
		commonTestCases:DelayedExp(2000)
		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
		
		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
		end)

		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "REJECTED"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end

	--7. Verification criteria: SDL returns UNSUPPORTED_RESOURCE code for the request sent
	-- SDL returns UNSUPPORTED_RESOURCE code for the request sent

	function Test:UnsubscribeWayPoints_UNSUPPORTED_RESOURCE()
		
		commonTestCases:DelayedExp(2000)
		
		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")

		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "")
		  end)

		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "UNSUPPORTED_RESOURCE"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)

	 end

	--8. SDL must respond with "GENERIC_ERROR" in case HMI does NOT respond during <DefaultTimeout>

	function Test:UnsubscribeWayPoints_HMI_does_not_respond()
		
		commonTestCases:DelayedExp(2000)
		
		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})

		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")

		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "GENERIC_ERROR", info = "Navigation component does not respond"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)

	end
  
  
	--9.Verification criteria: Several response to one request
			
	function Test:UnsubscibeWayPoints_Response_SeveralResponseToOneRequest()

		commonTestCases:DelayedExp(2000)
	
		--mobile side: send UnsubscribeWayPoints request
		 local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
			
				--hmi side: expected UnsubscribeWayPoints request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		
			:Do(function(exp,data)
		
				self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				
			end)
								
			--mobile side: expect response 
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})
		
	end	
	
	
	--10.Verification criteria: Missed parameters in response
	function Test:UnsubscibeWayPoints_Response_IsMissedAllPArameters()	
	
		--mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		
			--hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				--hmi side: sending Navigation.UnsubscribeWayPoints" response
				 -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"Navigation.UnsubscribeWayPoints"}}')
				self.hmiConnection:Send('{}')
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)
		
	end
  
end

SpecialNotificationChecks()	
	

--------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes--------------------------------
--------------------------------------------------------------------------------------------
--Begin Test case ResultCodeChecks
--Description: Check all resultCodes

	--Requirement id in JAMA: 
		--APPLINK-21902 (SUCCESS)
		--APPLINK-16739 (INVALID_DATA)
		--APPLINK-16746 (APPLICATION_NOT_REGISTERED)
		--APPLINK-17396 (REJECTED)
		--APPLINK-17008 (GENERIC_ERROR)
		--APPLINK-21903 (DISALLOWED)
		--APPLINK-19584 (USER_DISALLOWED)
		

		
local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For resultCodes Checks")
	----------------------------------------------------------------------------------------------
	
	--SUCCESS: Covered by many test cases.
	--INVALID_DATA: Covered by many test cases.
	
	
	--GENERIC_ERROR: Covered by test case UnsubscribeWayPoints_HMI_does_not_respond
	--REJECTED: Covered by test case UnsubscribeWayPoints_REJECTED
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: APPLINK-16746
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
				
		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()
		
	--End Test case ResultCodeChecks.1
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED, USER_DISALLOWED
			
		--Requirement id in JAMA: APPLINK-21903, APPLINK-19584
		--Verification criteria: 
			--1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
			--2. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.		
			--SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.
				
		
		--Begin Test case ResultCodeChecks.2.1
		--Description: 1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
			
			testCasesForPolicyTable:checkPolicyWhenAPIIsNotExist()			
			
		--End Test case ResultCodeChecks.2.1
		
	
	-----------------------------------------------------------------------------------------
	
end
--TODO: updatePolicy in Genivi is implementing.
--ResultCodeChecks()

--End Test case ResultCodeChecks

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	
--Not appropriate
---------------------------------------------------------------------------------------------
---------------------------------------TEST BLOCK VII---------------------------------------
------------------------------------Different HMIStatus-------------------------------------
--------------------------------------------------------------------------------------------
-- Verification criteria: send UnsubscribeWayPoints in different HMI Level
--Requirement id in JIRA:
		-- APPLINK-23004
 -- "UnsubscribeWayPoints": {
            -- "hmi_levels": [
              -- "BACKGROUND",
              -- "FULL",
              -- "LIMITED"
            -- ]
          -- }
--[[
	1. One app is None
	2. One app is Limited
	3. One app is Background
	
--]]

commonFunctions:newTestCasesGroup("Test suite VII: Different HMI Level Checks")

local function DifferentHMIlevelChecks()
	--Postcondition
		SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_11")
		
	--Description: Checking "DISALLOWED" result code in case HMI does NOT respond during <DefaultTimeout>
	--Requirement id in JIRA:
		-- APPLINK-23004
	
	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel()

	function Test:UnsubscribeWayPoints_Notification_InNoneHmiLevel()
	
		commonTestCases:DelayedExp(2000)
		--mobile side: sending UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		--hmi side: expect UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints") 
		:Times(0)
		--mobile side: expect UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid,
		{ success = false, resultCode = "DISALLOWED" }
		)
	end	
				
	--Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_UnsubscribeWayPoints_CaseAppIsNone")	

	--2. HMI level is LIMITED
	----------------------------------------------------------------------------------------------
	if commonFunctions:isMediaApp() then
		commonSteps:ChangeHMIToLimited()
		--Description: Checking "SUCCESS" result code in case LIMITED HMI Level
		--Requirement id in JIRA:
			-- APPLINK-23004
	function Test:UnsubscribeWayPoints_Notification_InLimitedHmiLevel()
		
		--mobile side: sending UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
	
		--hmi side: expect UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)
		
		--mobile side: expect UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")
		
	end
	end
	
	--Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_UnsubscribeWayPoints_Notification_InLimitedHmiLevel_ActivateApp")
	
	--3. HMI level is BACKGROUND
	--Description: Checking "SUCCESS" result code in case LIMITED HMI Level
	--Requirement id in JIRA:
		-- APPLINK-23004
	----------------------------------------------------------------------------------------------
	
	commonTestCases:ChangeAppToBackgroundHmiLevel()
	
	 --Postcondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_12")
	
	function Test:UnsubscribeWayPoints_Notification_InBackgroundHmiLevel()
		
			--mobile side: sending UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
	
		--hmi side: expect UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)
		
		--mobile side: expect UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	
		--mobile side: expect OnHashChange notification
		--TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		--EXPECT_NOTIFICATION("OnHashChange")
		
			
	end
	
end

DifferentHMIlevelChecks()