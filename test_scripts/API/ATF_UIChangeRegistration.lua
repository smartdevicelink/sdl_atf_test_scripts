Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Functions ---------------------------------------
---------------------------------------------------------------------------------------------

function Test:activate_App(app,hmiLevel)
		
	--Activate the first app	
	if app==1 then
	 	local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		--Case1: Apps are LIMITED at the same time
		if case==1 then 
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end
		
		--Case2: Apps can't be LIMITED at the same time
		if case==2 then 
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end	
	end
	-----------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Activate the second app
	if app==2 then
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		--Case1: Apps are LIMITED at the same time
		if case==1 then 
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end
		
		--Case2: Apps can't be LIMITED at the same time
		if case==2 then 
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end	
	end
	-----------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Activate the third app
	if app==3 then
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		--Case1: Apps are LIMITED at the same time
		if case==1 then 
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end
		
		--Case2: Apps can't be LIMITED at the same time
		if case==2 then 
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end	
	end
end
-----------------------------------------------------------------------------------------

function Test:unregisterAppInterface(app) 
	local session
	
	--Case1: Unregister app2
	if app==1 then 
		session= self.mobileSession1 
	end
	
	--Case2: Unregister app3
	if app==2 then 
		session= self.mobileSession2 
	end
	
	local cid = session:SendRPC("UnregisterAppInterface",{})
	session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)
end 
--------------------------------------------------------------------------------------------------------------------------

function Test:registerAppInterface2()
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
	self.mobileSession1:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		})
		:Timeout(2000)
end		
--------------------------------------------------------------------------------------------------------------------------

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
	self.mobileSession2:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		})
		:Timeout(2000)
end		
--------------------------------------------------------------------------------------------------------------------------

function Test:change_App_To_Limited(app)
	local session
	local appConfig
	
	if app==1 then
		session =self.mobileSession
		appConfig= config.application1.registerAppInterfaceParams.appName
	end
   
	if app==2 then
		session =self.mobileSession1
		appConfig= config.application2.registerAppInterfaceParams.appName
	end
	
	if app==3 then
		session =self.mobileSession2
		appConfig= config.application3.registerAppInterfaceParams.appName
	end
	
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[appConfig]
		})
		
	session:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})	
end

-------------------------------------------------------------------------------------------------------

function Test:change_AppHMIType_By_PTU(usedSession,PTName)
	local session
	
	--Case: Use app of mobile session 1 for PTU
	if usedSession ==1 then 
		session = self.mobileSession
	end
	
	--Case: Use app of mobile session 2 for PTU
	if usedSession ==2 then 
		session = self.mobileSession1
	end
	
	--hmi side: sending SDL.GetURLS request
	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

	--hmi side: expect SDL.GetURLS response from HMI
	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	:Do(function(_,data)
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			{
				requestType = "PROPRIETARY",
				fileName = "filename"
			}
		)
	
		--mobile side: expect OnSystemRequest notification 
		session:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
		:Do(function(_,data)
			--mobile side: sending SystemRequest request 
			local CorIdSystemRequest = session:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				}, PTName)
			
			local systemRequestId
			--hmi side: expect SystemRequest request
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				
				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
					{
						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
					}
				)
				
				function to_run()
					--hmi side: sending SystemRequest response
					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
				end
				
				RUN_AFTER(to_run, 500)
			end)
				
			--hmi side: expect SDL.OnStatusUpdate
			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
			:ValidIf(function(exp,data)
				if 
					exp.occurences == 1 and
					data.params.status == "UP_TO_DATE" then
						return true
				elseif
					exp.occurences == 1 and
					data.params.status == "UPDATING" then
						return true
				elseif
					exp.occurences == 2 and
					data.params.status == "UP_TO_DATE" then
						return true
				else 
					if 
						exp.occurences == 1 then
							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
					elseif exp.occurences == 2 then
							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
					end
					return false
				end
				
			end)
			:Times(Between(1,2))
			
			session:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage response
				-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
				:Do(function(_,data)	
				end)
			end)
		end)
	end)														
end

--OnHMIStatus expectation after SDL send UI.ChangeRegistration()
function Test: expect_UIChangeRegistration_OnHMIStatus(resultCode,times)
    --Case1: One app is at Limited or FULL
	if times==1 then 
	
		EXPECT_HMICALL("UI.ChangeRegistration", {})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
		end)
				
		--hmi side: expect BC.ActivateApp 
		EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
		end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})	
	end
	
	--Case1: Two apps at the Limited at the same time
	if times==2 then 
		
		EXPECT_HMICALL("UI.ChangeRegistration", {},{})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
		end)
		:Times(2)	
		
		--hmi side: expect BC.ActivateApp 
		EXPECT_HMICALL("BasicCommunication.ActivateApp", {},{})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
		end)
		:Times(2)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})	
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})	
	end
	
	--Case1: Three apps at the Limited at the same time
	if times==3 then 
	
		EXPECT_HMICALL("UI.ChangeRegistration", {},{}, {})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
		end)
		:Times(3)	
		
		--hmi side: expect BC.ActivateApp 
		EXPECT_HMICALL("BasicCommunication.ActivateApp", {},{}, {})
		:Do(function(_,data)
			--hmi side: sending Response to SDL
			self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
		end)
		:Times(3)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})	
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})	
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end	

-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	---------------------------------------------------------------------------------------------

	--1.Delete Policy and Log Files
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--2.Unregister App
	commonSteps:UnregisterApplication()
	
	--3.Add the second session
	function Test:Precondition_SecondSession()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
	end		
	
	--4.Add the third Session
	function Test:Precondition_ThirdSession()
		self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession2:StartService(7)
	end	

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------
--Not Applicable
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------
--Not Applicable
----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI Response-----------------------
-----------------------------------------------------------------------------------------------
	--Begin test suit HMIResponseCheck
	--Description: Verify when UI.ChangeRegistration() response is:
		--without any parameters
		--without response
		--with valid ResultCode
		--response with invalid ResultCode (empty, not existed, wrongtype)
		--{"jsonrpc":"2.0","id":38,"result":{"code":0,"method":"UI.ChangeRegistration"}}
		--response with pamameter is valid/invalid/not existed/empty/wrongtype		
		
	--Write TEST BLOCK III to ATF log
	commonFunctions:newTestCasesGroup("****************************** TEST BLOCK III: Check normal cases of HMI Response ******************************")							
		
		--Verification: This test is intended to check when HMI doesn't send UI.ChangeRegistration() response. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("Without_UIChangeRegistration_Response")
		
		local function Without_UIChangeRegistration_Response()
		
			local PermissionLinesForApplication = 
			[[			"]].."3_1" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)
			
			function Test:Precondition_Change_App1_Params_Case_Without_Response()
				config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
				config.application1.registerAppInterfaceParams.isMediaApplication = true
				config.application1.registerAppInterfaceParams.fullAppID ="3_1"
			end
			
			commonSteps:RegisterAppInterface("Precondition_Register_App_Case_Without_Response")
			
			commonSteps:ActivationApp(_,"Activate_App_Case_Without_Response")
			
			function Test:Update_Policy_Without_UIChangeRegistration_Response()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				
				--hmi side: expect BC.ActivateApp two times
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile: Expect OnHMIStatus() notification		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
		end 
		
		Without_UIChangeRegistration_Response()
		
		commonSteps:UnregisterApplication("UnRegister_App_Case_Without_Response")
		---------------------------------------------------------------------------------------------------------------------
		
		--Verification: This test is intended to check when HMI send empty UI.ChangeRegistration() response. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_IsEmpty")
		
		local function UIChangeRegistration_Response_IsEmpty()
		
			local PermissionLinesForApplication = 
			[[			"]].."3_2" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
				
			function Test:Precondition_Change_App1_Params_Case_Response_IsEmpty()
				config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
				config.application1.registerAppInterfaceParams.isMediaApplication = true
				config.application1.registerAppInterfaceParams.fullAppID ="3_2"
			end
			
			commonSteps:RegisterAppInterface("Precondition_Register_App_Case_Response_IsEmpty")
			
			commonSteps:ActivationApp(_,"Activate_App_Case_Response_IsEmpty")
			
			function Test:Update_Policy_With_Empty_UIChangeRegistration_Response()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:Send('{}')
				end)
				
				--hmi side: expect BC.ActivateApp two times
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		UIChangeRegistration_Response_IsEmpty()
		
		
		commonSteps:UnregisterApplication("UnRegister_App_Case_Response_IsEmpty")
		--------------------------------------------------------------------------------------------------------------------
		
		--Verification: HMI sends UI.ChangeRegistration() response is valid but different from SUCCESS. SDL still puts app to BackGround due to APPLINK-20522
		local resultCodes = {
			{resultCode = "INVALID_DATA", AppID =  "3_3"},
			{resultCode = "OUT_OF_MEMORY", AppID =  "3_4"},		
			{resultCode = "TOO_MANY_PENDING_REQUESTS", AppID =  "3_5"},
			{resultCode = "APPLICATION_NOT_REGISTERED", AppID =  "3_6"},
			{resultCode = "REJECTED", AppID =  "3_7"},
			{resultCode = "GENERIC_ERROR", AppID =  "3_8"},
			{resultCode = "DISALLOWED", AppID =  "3_9"},
			{resultCode = "USER_DISALLOWED", AppID =  "3_10"},		
			{resultCode = "TRUNCATED_DATA", AppID =  "3_11"}
		}
		
		for i = 1, #resultCodes do
		
			commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_Is_"..resultCodes[i].resultCode)	
			
			local PermissionLinesForApplication = 
			[[			"]]..resultCodes[i].AppID ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["DEFAULT"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
			
			local function UIChangeRegistration_Response_IsValid()
			
				Test["Change_App1_Params_Case_Response_Is_" .. resultCodes[i].resultCode] = function(self)	
					config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
					config.application1.registerAppInterfaceParams.isMediaApplication = true
					config.application1.registerAppInterfaceParams.fullAppID =resultCodes[i].AppID
				end
			
				commonSteps:RegisterAppInterface("Register_App_Case_Response_Is_"..resultCodes[i].resultCode)
				
				commonSteps:ActivationApp(_,"Activate_App_Case_Response_Is_"..resultCodes[i].resultCode)
				
				Test["Update_Policy_UIChangeRegistration_Response_Is_" .. resultCodes[i].resultCode] = function(self)	
					self:change_AppHMIType_By_PTU(1,PTName)		
					self:expect_UIChangeRegistration_OnHMIStatus(resultCodes[i].resultCode,1)	
				end
			end 
	
			UIChangeRegistration_Response_IsValid()
			
			commonSteps:UnregisterApplication("UnRegister_App_Case_Response_Is_"..resultCodes[i].resultCode)
		
		end
		---------------------------------------------------------------------------------------------------------------------
	
		--Verification: HMI sends UI.ChangeRegistration() response is invalid,SDL still puts app to BackGround due to APPLINK-20522
		local testData = {	
							{resultCode = "ANY", name = "IsNotExist", AppID="3_12" },
							{resultCode = "", name = "IsEmpty",AppID="3_13"},
							{resultCode = 123, name = "IsWrongType",AppID="3_14"}
						}
			
		for i =1, #testData do
		
			commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_Is_" ..testData[i].name)
			
			local PermissionLinesForApplication = 
			[[			"]]..testData[i].AppID ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["DEFAULT"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
			
			local function UIChangeRegistration_Response_IsInvalid()
				
				Test["Change_App1_Params_Case_Response_Is_" ..testData[i].name] = function(self)
					config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
					config.application1.registerAppInterfaceParams.isMediaApplication = true
					config.application1.registerAppInterfaceParams.fullAppID =testData[i].AppID
				end
				
				commonSteps:RegisterAppInterface("Register_App_Case_Response_Is_" ..testData[i].name)
				
				commonSteps:ActivationApp(_,"Activate_App_Case_Response_Is_" ..testData[i].name)
					
				Test["Update_Policy_UIChangeRegistration_Response_Is" ..testData[i].name] = function(self)
					self:change_AppHMIType_By_PTU(1,PTName)		
					self:expect_UIChangeRegistration_OnHMIStatus(testData[i].resultCode,1)	
				end
			
			end 
	
			UIChangeRegistration_Response_IsInvalid()
			
			commonSteps:UnregisterApplication("UnRegister_App_Case_Response_Is_" ..testData[i].name)
		
		end
		---------------------------------------------------------------------------------------------------------------------
		
	--Write TEST_BLOCK_V_End to ATF log
	commonFunctions:newTestCasesGroup("************************************************************************")
		
	--End Test suit HMIResponseCheckk	
	---------------------------------------------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
	--Begin test suit SpecialResponseCheck
	--Description:
		--InvalidJsonSyntax
		--InvalidStructure
		--FakeParams
		--FakeParameterIsFromAnotherAPI
		--Several Different Responses To One Request
		--Several Same Responses To One Request
		
	--Write TEST BLOCK IV to ATF log
	commonFunctions:newTestCasesGroup("******************************Test suite IV: Check special cases of HMI response******************************")
			
		--Verification: This test is intended to check when HMI send UI.ChangeRegistration() response with InvalidJson. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_IsInvalidJson")
		
		local function UIChangeRegistration_Response_IsInvalidJson()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_1" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
			function Test:Change_App1_Params_Case_Response_IsInvalidJson()
				config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
				config.application1.registerAppInterfaceParams.isMediaApplication = true
				config.application1.registerAppInterfaceParams.fullAppID ="4_1"
			end
			
			commonSteps:RegisterAppInterface("Register_App_Case_Response_IsInvalidJson")
			
			commonSteps:ActivationApp(_,"Activate_App_Case_Response_IsInvalidJson")
			
			function Test:Update_Policy_UIChangeRegistration_Response_IsInvalidJson()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration"}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code",0, "method":"UI.ChangeRegistration"}}')
				end)
				
				--hmi side: expect BC.ActivateApp
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		UIChangeRegistration_Response_IsInvalidJson()
		
		
		commonSteps:UnregisterApplication("UnRegister_App_Case_Response_IsInvalidJson")
		----------------------------------------------------------------------------------------------------------------------
		
		--Description: This test is intended to check when HMI send UI.ChangeRegistration() response with InvalidStructure. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_IsInvalidStructure")
		
		local function UIChangeRegistration_Response_IsInvalidStructure()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_2" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
			
			function Test:Change_App1_Params_Case_Response_Is_InvalidStructure()
				config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
				config.application1.registerAppInterfaceParams.isMediaApplication = false
				config.application1.registerAppInterfaceParams.fullAppID ="4_2"
			end
			
			commonSteps:RegisterAppInterface("Register_App_Case_Response_IsInvalidStructure")
			
			commonSteps:ActivationApp(_,"Activate_App_Case_Response_IsInvalidStructure")
			
			function Test:Update_Policy_UIChangeRegistration_Response_Is_InvalidStructure()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration"}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":"code":0, "method":"UI.ChangeRegistration"}')
				end)
				
				--hmi side: expect BC.ActivateApp 
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		UIChangeRegistration_Response_IsInvalidStructure()
		
		commonSteps:UnregisterApplication("UnRegister_App_Case_Response_Is_InvalidStructure")
		--------------------------------------------------------------------------------------------------------------------
		
		--Description: This test is intended to check when HMI send UI.ChangeRegistration() response with fake param not from any API. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_FakeParam_IsNotFromAnyAPI")
					
		local function UIChangeRegistration_Response_FakeParam_IsNotFromAnyAPI()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_3" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
			
			function Test:Change_App1_Params_Case_Response_FakeParam_IsNotFromAnyAPI()
				config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
				config.application1.registerAppInterfaceParams.isMediaApplication = false
				config.application1.registerAppInterfaceParams.fullAppID ="4_3"
			end
			
			commonSteps:RegisterAppInterface("Register_App_Case_Response_FakeParam_IsNotFromAnyAPI")
			
			commonSteps:ActivationApp(_,"Activate_App_Case_Response_FakeParam_IsNotFromAnyAPI")
			
			function Test:Update_Policy_ChangeRegistration_Response_FakeParam_IsNotFromAnyAPI()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL with fake param is not from any API
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration"}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration","fakeParam": "fakeParam"}}')
				end)
				
				--hmi side: expect BC.ActivateApp
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		UIChangeRegistration_Response_FakeParam_IsNotFromAnyAPI()
		
		commonSteps:UnregisterApplication("UnRegister_App_Case_Response_FakeParam_IsNotFromAnyAPI")
		--------------------------------------------------------------------------------------------------------------------
		
		--Description: This test is intended to check when HMI send UI.ChangeRegistration() response with FakeParam from AnotherAPI. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("UIChangeRegistration_Response_With_FakeParam_FromAnotherAPI")				
		
		local function UIChangeRegistration_Response_With_FakeParam_FromAnotherAPI()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_4" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
			
			function Test:Change_App1_Params_Case_Response_With_FakeParam_FromAnotherAPI()
				config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
				config.application1.registerAppInterfaceParams.isMediaApplication = false
				config.application1.registerAppInterfaceParams.fullAppID ="4_4"
			end
			
			commonSteps:RegisterAppInterface("RegisterApp_Case_Response_With_FakeParam_FromAnotherAPI")
			
			commonSteps:ActivationApp(_,"ActivateApp_Case_Response_With_FakeParam_FromAnotherAPI")
			
			function Test:Update_Policy_UIChangeRegistration_Response_With_FakeParam_FromAnotherAPI()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL with fake params from another API
					--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration"}}')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"UI.ChangeRegistration","sliderPosition": 5}}')
				end)
				
				--hmi side: expect BC.ActivateApp
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
				:Timeout(20000)
			end
		end 
		
		UIChangeRegistration_Response_With_FakeParam_FromAnotherAPI()
		
		commonSteps:UnregisterApplication("UnregisterApp_Case_Response_With_FakeParam_FromAnotherAPI")
		------------------------------------------------------------------------------------------------------------------
			
		--Description: This test is intended to check when HMI send UI.ChangeRegistration() response with several different responses to UI.ChangeRegistration. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("Several_Different_UIChangeRegistration_Responses")
							
		local function Several_Different_UIChangeRegistration_Responses()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_5" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
			function Test:Change_App1_Params()
				config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
				config.application1.registerAppInterfaceParams.isMediaApplication = true
				config.application1.registerAppInterfaceParams.fullAppID ="4_5"
			end
			
			commonSteps:RegisterAppInterface("RegisterApp_Several_Different_Response")
			
			commonSteps:ActivationApp(_,"ActivateApp_Several_Different_Response")
			
			function Test:Update_Policy_Several_Different_UIChangeRegistration_Responses()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA",{})
				end)
				
				--hmi side: expect BC.ActivateApp
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		Several_Different_UIChangeRegistration_Responses()
		
		commonSteps:UnregisterApplication("UnregisterApp_Case_Several_Different_Response")
		-----------------------------------------------------------------------------------------------------------------
			
		--Description: This test is intended to check when HMI send UI.ChangeRegistration() response with several same responses to UI.ChangeRegistration. SDL still puts app to BackGround due to APPLINK-20522
		commonFunctions:newTestCasesGroup("Several_Same_UIChangeRegistration_Responses")
		
		local function Several_Same_UIChangeRegistration_Responses()
		
			local PermissionLinesForApplication = 
			[[			"]].."4_6" ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["SOCIAL"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]
	
			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
	
			function Test:Change_App1_Params()
				config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
				config.application1.registerAppInterfaceParams.isMediaApplication = true
				config.application1.registerAppInterfaceParams.fullAppID ="4_6"
			end
		
			commonSteps:RegisterAppInterface("RegisterApp_Several_Same_Response")
			
			commonSteps:ActivationApp(_,"ActivateApp_Several_Same_Response")

			function Test:Update_Policy_Several_Same_UIChangeRegistration_Responses()
				self:change_AppHMIType_By_PTU(1,PTName)
				
				--hmi side: expect UI.ChangeRegistration request
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)
				
				--hmi side: expect BC.ActivateApp
				EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)
				
				--mobile expectation		
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})						
			end
		end 
		
		Several_Same_UIChangeRegistration_Responses()
		
		commonSteps:UnregisterApplication("UnregisterApp_Several_Same_Response")
		-----------------------------------------------------------------------------------------------------------------
	--Write TEST_BLOCK_IV_End to ATF log
	commonFunctions:newTestCasesGroup("************************************************************************")
		
	--End Test suit HMIResponseCheck	
	---------------------------------------------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes-------------------------------------
---------------------------------------------------------------------------------------------
--Description: 	
	--SUCCESS: Already checked by several TCs in the TEST BLOCK I
	--INVALID_DATA:	Already checked by HMIResponseCheck3.3
	--OUT_OF_MEMORY: Already checked by HMIResponseCheck3.3
	--TOO_MANY_PENDING_REQUESTS: Already checked by HMIResponseCheck3.3
	--GENERIC_ERROR: Already checked by HMIResponseCheck3.3
	--APPLICATION_NOT_REGISTERED: Already checked by HMIResponseCheck3.3
	--REJECTED: Already checked by HMIResponseCheck3.3
	--DISALLOWED: Not applicable 
	--USER_DISALLOWED: Not applicable 
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	

--------------------------------------------------------------------------------------------------------------
--APPLINK-18404
--Verification: SDL supports the apps of the following AppHMIType to be in LIMITED at the same time: MEDIA media, NAVIGATION non-media, COMMUNICATION non-media.
--------------------------------------------------------------------------------------------------------------
     commonFunctions:newTestCasesGroup("******************************TEST BLOCK VI:Sequence with emulating of user's action(s)******************************")	
	 
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TC APPLINK-18404. Apps: Media (Media), Non Media (Navigation), Non Media (Communication) are at LIMITED at the same time")	
    local function TC_APPLINK_18404()

		function Test:TC_APPLINK_18404_Precondition1_Change_App1_Params()
			config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
			config.application1.registerAppInterfaceParams.isMediaApplication = true
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18404_Precondition2_Register_App")
				
		function Test:TC_APPLINK_18404_Precondition3_Register_Non_Media_Navigation_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
		
		function Test:TC_APPLINK_18404_Precondition4_Register_Non_Media_Communication_App()
			config.application3.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
			config.application3.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface3()
		end
		
		commonSteps:ActivationApp(_, "TC_APPLINK_18404_Step1_Activate_First_Media_App")
	
		function Test:TC_APPLINK_18404_Step2_Activate_Non_Media_Navigation_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18404_Step3_Activate_Non_Media_Communication_App()
			self:activate_App(3,1)
		end
		
		function Test:TC_APPLINK_18404_Step4_Activate_CD_Source()
		    commonTestCases:DelayedExp(1000) 
			
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
			
			--Activate CD source ==> Non Media (Communication) and Media (Media) apps are changed to BackGround. Non Media (Navigation) app still be kept as LIMITED
			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
	end
	
	TC_APPLINK_18404()
	
	commonSteps:UnregisterApplication("TC_APPLINK_18404_Postcondition_Unregister_App")
	
	for i =1,2 do 
		Test["TC_APPLINK_18404_Postcondition_Unregister_App"..i] = function(self)
			self:unregisterAppInterface(i)
		end
	end
-------------------------------------------------------------------------------------------------------------------------------------------
--APPLINK-18410
--Verification: After PTU, the app's AppHMIType is changed from Navigation to COMMUNICATION so SDL puts this app from LIMITED app to BACKGROUND.
-------------------------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("TC APPLINK-18410: After PTU, the app's AppHMIType is changed from Navigation to COMMUNICATION. SDL puts this app from LIMITED to Background")
	
	local function TC_APPLINK_18410_Case_AfterPTU_AppHMITypes_Are_TheSame()	
		local PermissionLinesForApplication = 
						[[			"]].."6_4" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["COMMUNICATION"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
									},
						]]
				
		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		function Test:TC_APPLINK_18410_Case1_Precondition1_Change_App1_Params()
			config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
			config.application1.registerAppInterfaceParams.fullAppID = "6_4"
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case1_Register_NON_MEDIA_NAVIGATION_App")
		
		function Test:Precondition3_Register_Non_Media_Communication()
			config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()		
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case1_Step1_Activate_First_NON_MEDIA_NAVIGATION_App")

		function Test:TC_APPLINK_18410_Case1_Step2_Activate_None_Media_COMMUNICATION_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18410_Case1_Step3_AppHMIType_App1_Changed_To_COMMUNICATION_By_PTU()
			self:change_AppHMIType_By_PTU(2,PTName)
			self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",1)
		end
   
	end
	
	TC_APPLINK_18410_Case_AfterPTU_AppHMITypes_Are_TheSame()
	
	commonSteps:UnregisterApplication("UnregisterApp_TC_APPLINK_18410_Case1")
	
	Test["TC_APPLINK_18410_Case1_Postcondition_Unregister_App2"] = function(self)
		self:unregisterAppInterface(1)
	end
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification: After PTU, the app's AppHMIType is changed from Media/Communication to Default. SDL puts App from LIMITED app to BACKGROUND.
-------------------------------------------------------------------------------------------------------------------------------------------			
	local testData = {
							{AppType = "Media_Media", 				IsMedia= true, 	AppHMIType = {"MEDIA"}, 		AppID =  "6_5"},
							{AppType = "Non_Media_Communication", 	IsMedia= false, AppHMIType = {"COMMUNICATION"}, AppID =  "6_6"}
					}
	
	local function TC_APPLINK_18410_Single_App_Changes_From_LIMITED_TO_BACKGROUND_By_PTU()
				
		for i = 1, #testData do
		
			commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes is changed. SDL puts "..testData[i].AppType.." from FULL to BACKGROUND")
			
			local PermissionLinesForApplication = 
			[[			"]]..testData[i].AppID ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["TESTING"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]

			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
			function Test:TC_APPLINK_18410_Case2_Precondition_Change_App1_Params()
				config.application1.registerAppInterfaceParams.appHMIType = testData[i].AppHMIType
				config.application1.registerAppInterfaceParams.isMediaApplication = testData[i].IsMedia
				config.application1.registerAppInterfaceParams.fullAppID =testData[i].AppID
			end
			
			commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case_Single_App"..i.."_Register_App")
			
			commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case_Single_App"..i.."Step1_Activate_App")
			
			Test["Step2_AppHMIType_IsChanged_By_PTU_Case_Single_App"..i] = function(self)	
				self:change_AppHMIType_By_PTU(1,PTName)		
				self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",1)	
			end
		
		end 

		TC_APPLINK_18410_Single_App_Changes_From_LIMITED_TO_BACKGROUND_By_PTU()()
		
		commonSteps:UnregisterApplication("TC_APPLINK_18410_Case_Single_App"..i"_Unregister_App")

	end
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes of three apps are changed to INFORMATION. SDL puts three these apps from LIMITED app to BACKGROUND
-------------------------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes of three apps are changed to INFORMATION. SDL puts these apps from LIMITED app to BACKGROUND")
	
	local function TC_APPLINK_18410_Case_Three_Apps_At_Limited_AppHMITypes_Changed_To_Information_By_PTU()
	
		local PermissionLinesForApplication = 
					[[			"]].."6_1" ..[[" : {
									"keep_context" : false,
									"steal_focus" : false,
									"priority" : "NONE",
									"default_hmi" : "NONE",
									"groups" : ["Base-4"],
									"AppHMIType": ["INFORMATION"],
									"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
								"]].."6_2" ..[[" : {
									"keep_context" : false,
									"steal_focus" : false,
									"priority" : "NONE",
									"default_hmi" : "NONE",
									"groups" : ["Base-4"],
									"AppHMIType": ["INFORMATION"],
									"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
								"]].."6_3" ..[[" : {
									"keep_context" : false,
									"steal_focus" : false,
									"priority" : "NONE",
									"default_hmi" : "NONE",
									"groups" : ["Base-4"],
									"AppHMIType": ["INFORMATION"],
									"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
					]]
			
		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)
		
		function Test:TC_APPLINK_18410_Case_Three_Apps_Precondition1_Change_App1_Params()
			config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = true
			config.application1.registerAppInterfaceParams.fullAppID = "6_1"
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case_Three_Apps_Register_Media_Media_App")
				
		function Test:TC_APPLINK_18410_Case_Three_Apps_Precondition2_Register_Non_Media_Navigation()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			config.application2.registerAppInterfaceParams.fullAppID = "6_2"
			self:registerAppInterface2()		
		end
		
		function Test:TC_APPLINK_18410_Case_Three_Apps_Precondition3_Register_Non_Media_Communication()
			config.application3.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application3.registerAppInterfaceParams.isMediaApplication = false
			config.application3.registerAppInterfaceParams.fullAppID = "6_3"
			self:registerAppInterface3()		
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case_Three_Apps_Step1_Activate_Media_Media_App")
	
		function Test:TC_APPLINK_18410_Case_Three_Apps_Step2_Activate_Non_Media_Navigation_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18410_Case_Three_Apps_Step3_Activate_Non_Media_Communication_App()
			self:activate_App(3,1)
		end
		
		function Test:TC_APPLINK_18410_Case_Three_Apps_Step4_Bring_Non_Media_Communication_App_To_Limited()
			self:change_App_To_Limited(3)
		end
		
		function Test:TC_APPLINK_18410_Case_Three_Apps_Step5_Update_Policy_AppHMIType_Changed_To_Information()		
			self:change_AppHMIType_By_PTU(1,PTName)
			self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",3)
		end
	end
	
	TC_APPLINK_18410_Case_Three_Apps_At_Limited_AppHMITypes_Changed_To_Information_By_PTU()
	
	commonSteps:UnregisterApplication("UnregisterApp_TC_APPLINK_18410_Case_Three_Apps")
	
	for i =1, 2 do 
		Test["Unregister_App".. i.."_TC_APPLINK_18410_Case_Three_Apps"] = function(self)
			self:unregisterAppInterface(i)
		end
	end	
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification: After PTU, the AppHMITypes of two apps are changed from Media and Communication to BACKGROUND_PROCESS. SDL puts two these apps from LIMITED app to BACKGROUND.
-------------------------------------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes of two apps are changed from Media and Communication to BACKGROUND_PROCESS. SDL puts two these apps from LIMITED app to BACKGROUND")
	
	local function TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_BackGround_Process_By_PTU()
		local PermissionLinesForApplication = 
						[[			"]].."6_7" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["BACKGROUND_PROCESS"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
									},
									"]].."6_8" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["BACKGROUND_PROCESS"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
						]]
				
		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_1_Precondition1_Change_App1_To_Media_Media()
			config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = true
			config.application1.registerAppInterfaceParams.fullAppID = "6_7"
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case_Two_Apps_1_Precondition1_Register_Media_Media_App")
				
		function Test:Precondition2_Register_Non_Media_Communication()
			config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			config.application2.registerAppInterfaceParams.fullAppID = "6_8"
			self:registerAppInterface2()		
		end

		commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case_Two_Apps_1_Step1_Activate_Media_Media_App")
	
		function Test:TC_APPLINK_18410_Case_Two_Apps_1_Step2_Activate_Non_Media_Communication_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_1_Step3_Bring_Non_Media_Communication_App_To_Limited()
			self:change_App_To_Limited(2)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_1_Step4_AppHMITypes_Changed_From_Communication_To_BackGround_Process_By_PTU()
			self:change_AppHMIType_By_PTU(1,PTName)
			self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",2)									
		end
		
	end
	
	TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_BackGround_Process_By_PTU()
	
	commonSteps:UnregisterApplication("UnregisterApp1_TC_APPLINK_18410_Case_Two_Apps")
	
	Test["Unregister_App2_TC_APPLINK_18410_Case_Two_Apps"] = function(self)
		self:unregisterAppInterface(1)
	end
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes of two apps are changed from Communication and Navigation to SYSTEM. SDL puts these apps from LIMITED app to BACKGROUND
-------------------------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes of two apps are changed from Communication and Navigation to SYSTEM. SDL puts two these apps from LIMITED app to BACKGROUND")
	
	local function TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_System_By_PTU()
		local PermissionLinesForApplication = 
						[[			"]].."6_9" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["SYSTEM"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
									},
									"]].."6_10" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["SYSTEM"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
						]]
				
		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_2_Precontidion1_Change_App1_To_Non_Media_Communication()
			config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
			config.application1.registerAppInterfaceParams.fullAppID = "6_9"
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case_Two_Apps_2_Precontidion1_Register_NoneMedia_Communication_App")
				
		function Test:TC_APPLINK_18410_Case_Two_Apps_2_Precondition2_Register_Non_Media_Navigation()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			config.application2.registerAppInterfaceParams.fullAppID = "6_10"
			self:registerAppInterface2()		
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case_Two_Apps_2_Step1_Activate_Non_Media_Communication_App")
	
		function Test:TC_APPLINK_18410_Case_Two_Apps_2_Step2_Activate_Non_Media_Navigation_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_2_Step3_Bring_Non_Media_Navigation_App_To_Limited()
			self:change_App_To_Limited(2)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_2_Step4_AppHMITypes_Change_To_System_By_PTU()
			self:change_AppHMIType_By_PTU(1,PTName)
			self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",2)										
		end
		
	end
	
	TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_System_By_PTU()
		
	commonSteps:UnregisterApplication("UnregisterApp1_TC_APPLINK_18410_Case_Two_Apps")
	
	Test["UnregisterApp2_TC_APPLINK_18410_Case_Two_Apps"] = function(self)
		self:unregisterAppInterface(1)
	end
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes of two apps are changed from Media and Navigation to SOCIAL. SDL puts these apps from LIMITED app to BACKGROUND
-------------------------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes of two apps are changed from Media and Navigation to SOCIAL. SDL puts two these apps from LIMITED app to BACKGROUND")
	
	local function TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_Social_By_PTU()
		local PermissionLinesForApplication = 
						[[			"]].."6_11" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["SOCIAL"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
									},
									"]].."6_12" ..[[" : {
										"keep_context" : false,
										"steal_focus" : false,
										"priority" : "NONE",
										"default_hmi" : "NONE",
										"groups" : ["Base-4"],
										"AppHMIType": ["SOCIAL"],
										"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
								},
						]]
				
		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_3_Precondition1_Change_App1_To_Media_Media()
			config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = true
			config.application1.registerAppInterfaceParams.fullAppID = "6_11"
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18410_Case_Two_Apps_3_Precondition1_Register_Media_Media_App")
				
		function Test:TC_APPLINK_18410_Case_Two_Apps_3_Precondition2_Register_Non_Media_Navigation()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			config.application2.registerAppInterfaceParams.fullAppID = "6_12"
			self:registerAppInterface2()		
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18410_Case_Two_Apps_3_Step1_Activate_Media_Media_App")
	
		function Test:TC_APPLINK_18410_Case_Two_Apps_3_Step2_Activate_Non_Media_Navigation_App()
			self:activate_App(2,1)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_3_Step3_Bring_Non_Media_Navigation_App_To_Limited()
			self:change_App_To_Limited(2)
		end
		
		function Test:TC_APPLINK_18410_Case_Two_Apps_3_Step4_Policy_Update_AppHMITypes_Change_To_SOCIAL()
			self:change_AppHMIType_By_PTU(1,PTName)
			self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",2)
		end
		
	end
	
	TC_APPLINK_18410_Case_Two_Apps_At_Limited_AppHMITypes_Changed_To_Social_By_PTU()
	
	commonSteps:UnregisterApplication("UnregisterApp1_TC_APPLINK_18410_Case_Two_Apps")
	Test["UnregisterApp2_TC_APPLINK_18410_Case_Two_Apps"] = function(self)
		self:unregisterAppInterface(1)
	end	
-------------------------------------------------------------------------------------------------------------------------------------------------
--APPLINK-18405
--Verification: Only one level either FULL or BACKGROUND at the given moment of time for two apps of one and the same AppHMIType (MEDIA, MEDIA)
--------------------------------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("TC APPLINK-18405. Apps: Media (Media),Media (Media) and only one level either FULL or BACKGROUND at the same time")
	 
	local function TC_APPLINK_18405()
			
		function Test:TC_APPLINK_18405_Precondtion1_Change_App1_To_Media_App()
			config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
			config.application1.registerAppInterfaceParams.isMediaApplication = true
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18405_Precondition2_Register_The_First_Media_Media_App")	
		
		function Test:TC_APPLINK_18405_Precondition3_Register_Media_Media_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"MEDIA"}
			config.application2.registerAppInterfaceParams.isMediaApplication = true
			self:registerAppInterface2()
		end
			
		commonSteps:ActivationApp(_, "TC_APPLINK_18405_Step1_Activate_First_Media_App")

		function Test:TC_APPLINK_18405_Step2_Activate_Second_Media_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18405_Step3_Activate_First_Media_App_Again()
			self:activate_App(1,2)
		end
	end
	
	TC_APPLINK_18405()
	commonSteps:UnregisterApplication("UnregisterApp1_TC_APPLINK_18405")
	
	Test["UnregisterApp2_TC_APPLINK_18405"] = function(self)
		self:unregisterAppInterface(1)
	end
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--APPLINK-18408
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps of one and the same AppHMIType COMMUNICATION non-media)
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
 
	commonFunctions:newTestCasesGroup("TC APPLINK-18408: Two VOICE COM apps and only one level either FULL or BACKGROUND at the same time")
 
	local function TC_APPLINK_18408_Case_Two_Communication_Apps()
		
		function Test:TC_APPLINK_18408_Precondition1_Change_App1_To_Communication()
			config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
			config.application1.registerAppInterfaceParams.isMediaApplication = false
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18408_Precondition1_Register_Communication_App1")
		
		function Test:TC_APPLINK_18408_Precondition2_Register_Communication_App2()
			config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
		
		commonSteps:ActivationApp(_, "TC_APPLINK_18408_Step1_Activate_First_Communication_App")

		function Test:TC_APPLINK_18408_Step2_Activate_Second_Communication_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18408_Step3_Activate_First_Communication_App_Again()
			self:activate_App(1,2)
		end
	end
	
	TC_APPLINK_18408_Case_Two_Communication_Apps()
	
	commonSteps:UnregisterApplication("Unregister_Communication_App1_TC_APPLINK_18408")
	
	Test["Unregister_Comunication_App2_TC_APPLINK_18408_Postcondition"] = function(self)
		self:unregisterAppInterface(1)
	end
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps with the same AppHMIType (NAVIGATION non-media)
------------------------------------------------------------------------------------------------------------------------------------------------------------   
	commonFunctions:newTestCasesGroup("TC APPLINK-18408: Two NAVI apps and only one level either FULL or BACKGROUND at the same time ")
    
	local function TC_APPLINK_18408_Case_Two_Navigation_Apps()
	
		function Test:TC_APPLINK_18408_Precondition1_Change_App1_To_Navigation()
			config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application1.registerAppInterfaceParams.isMediaApplication = false
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18408_Precondition2_Register_Navigation1")
		
		function Test:TC_APPLINK_18408_Precondtion3_Register_Navigation_App2()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
		
		commonSteps:ActivationApp(_, "TC_APPLINK_18408_Step1_Activate_First_Navigation_App")
		
		function Test:TC_APPLINK_18408_Step2_Activate_Second_Navigation_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18408_Step3_Activate_First_Navigation_App_Again()
			self:activate_App(1,2)
		end
	end
	
	TC_APPLINK_18408_Case_Two_Navigation_Apps()

	commonSteps:UnregisterApplication("Unregister_Navigation_App1_TC_APPLINK_18408")
	Test["Unregister_Navigation_App2_TC_APPLINK_18408"] = function(self)
		self:unregisterAppInterface(1)
	end
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
--APPLINK-18407
--Verification: Media Navigation and Media (without AppHMIAppType) apps don't affect rule that 2 media Apps can't have FULL and LIMITED at the same time (APPLINK-9482)
------------------------------------------------------------------------------------------------------------------------------------------------------------  
	commonFunctions:newTestCasesGroup("TC APPLINK-18407. Apps: Media (without appHMItype), Media (Navigation) can't be FULL and LIMITED at the same time")
	
	local function TC_APPLINK_18407()
	
		function Test:TC_APPLINK_18407_Precondition1_Change_App1_To_MEDIA_Without_AppHMIType()
			config.application1.registerAppInterfaceParams.appHMIType = nil 
			config.application1.registerAppInterfaceParams.isMediaApplication = true
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18407_Precondition2_Register_Media_App")
		
		function Test:TC_APPLINK_18407_Precondition2_Register_Second_Media_Navigation_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = true
			self:registerAppInterface2()
		end
		
		commonSteps:ActivationApp(_, "TC_APPLINK_18407_Step1_Activate_First_Media_NonAppType_App")
	
		function Test:TC_APPLINK_18407_Step3_Activate_Second_Media_Navigation_App()
			self:activate_App(2,2)
		end

		function Test:TC_APPLINK_18407_Step3_Activate_First_Media_NonAppType_App_Again()
			self:activate_App(1,2)
		end		
	end
	
    TC_APPLINK_18407()

	commonSteps:UnregisterApplication("Unregister_App1_TC_APPLINK_18407")
		
	Test["Unregister_App2_TC_APPLINK_18407"] = function(self)
		self:unregisterAppInterface(1)
	end	
------------------------------------------------------------------------------------------------------------------------------------------------------------
--APPLINK-18409
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps of one and the same AppHMIType (COMMUNICATION non-media)
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
  
	commonFunctions:newTestCasesGroup("TC APPLINK-18409. Apps: Non Media (Communication and Navigation), Non Media (Communication) can't be at FULL and LIMITED at the same time")
	
    local function TC_APPLINK_18409_Case_NonMedia_Communication_Apps()
	
		function Test:TC_APPLINK_18409_Case1_Precondition1_Change_App1_To_NonMedia_COMMUNICATION_App()
			config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
		end
		
		commonSteps:RegisterAppInterface("TC_APPLINK_18409_Case1_Precondition2_Register_NonMedia_COMMUNICATION_App")
		
		function Test:TC_APPLINK_18409_Precondition3_Register_Second_NonMedia_Communication_Navigation_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION","NAVIGATION"} 
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
		
		commonSteps:ActivationApp(_, "TC_APPLINK_18409_Case1_Step1_Activate_First_NonMedia_Communication_App")
		
		function Test:TC_APPLINK_18409_Case1_Step2_Activate_Second_NonMedia_Communication_Navigation_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18409_Case1_Step3_Activate_First_NonMedia_Communication_App_Again()
			self:activate_App(1,2)
		end
	end
	
	TC_APPLINK_18409_Case_NonMedia_Communication_Apps()
		
	commonSteps:UnregisterApplication("Unregister_App1_TC_APPLINK_18409_Case1")
	
	Test["Unregister_App2_TC_APPLINK_18409_Case1"] = function(self)
		self:unregisterAppInterface(1)
	end
------------------------------------------------------------------------------------------------------------------------------------------------------------
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps: Non Media(Communication and Navigation), Non Media (Navigation)")
------------------------------------------------------------------------------------------------------------------------------------------------------------ 

	commonFunctions:newTestCasesGroup("Apps: Non Media (Communication and Navigation), Non Media (Navigation) can't be at LIMITED and FULL at the same time")
	
	local function TC_APPLINK_18409_Case_Two_NonMedia_Navigation_Apps()
			
		function Test:TC_APPLINK_18409_Case2_Precondition1_Change_App1_To_NonMEDIA_COMMUNICATION_NAVIGATION_App()
			config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION", "NAVIGATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
			
		end

		commonSteps:RegisterAppInterface("TC_APPLINK_18409_Case2_Precondition1_Register_NonMEDIA_COMMUNICATION_NAVIGATION_App")
		
		function Test:TC_APPLINK_18409_Case2_Precondition2_Register_Second_Media_Navigation_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18409_Case2_Step1_Activate_First_NonMEDIA_COMMUNICATION_NAVIGATION_App")

		function Test:TC_APPLINK_18409_Case2_Step2_Activate_Second_NonMedia_Navigation_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18409_Case2_Step3_Activate_First_NonMedia_Communication_Navigation_App_Again()
			self:activate_App(1,2)
		end
	end

	TC_APPLINK_18409_Case_Two_NonMedia_Navigation_Apps()

	commonSteps:UnregisterApplication("Unregister_App1_TC_APPLINK_18409_Case2")
	
	Test["Unregister_App2_TC_APPLINK_18409_Case2"] = function(self)
		self:unregisterAppInterface(1)
	end
------------------------------------------------------------------------------------------------------------------------------------------------------------
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps: Non Media(Communication), Non Media (Default)")
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
	commonFunctions:newTestCasesGroup("Apps: Non Media (Communication), Non Media (Default) can't be at LIMITED and FULL at the same time")
	
	local function TC_APPLINK_18409_Case_Non_Media_Communication_And_Non_Media_Default_Apps()
			
		function Test:TC_APPLINK_18409_Case3_Precondition1_Change_App1_To_Non_MEDIA_COMMUNICATION_App()
			config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18409_Case3_Precondition2_Register_NonMedia_Communication_App")
		
		function Test:TC_APPLINK_18409_Case3_Precondition3_Register_Second_Media_Navigation_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18409_Case3_Step1_Activate_First_NonMEDIA_COMMUNICATION_App")

		function Test:TC_APPLINK_18409_Case3_Step2_Activate_Second_NonMedia_Default_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18409_Case3_Step3_Activate_First_NonMedia_Communication_App_Again()
			self:activate_App(1,2)
		end
	end

	TC_APPLINK_18409_Case_Non_Media_Communication_And_Non_Media_Default_Apps()

	commonSteps:UnregisterApplication("Unregister_App1_TC_APPLINK_18409_Case3")
	
	Test["Unregister_App2_TC_APPLINK_18409_Case3"] = function(self)
		self:unregisterAppInterface(1)
	end
------------------------------------------------------------------------------------------------------------------------------------------------------------
--Verification: Check that SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps: Non Media(Communication), Non Media (Default)")
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
	
	commonFunctions:newTestCasesGroup("Apps: Non Media (Navigation), Non Media (SOCIAL) can't be at LIMITED and FULL at the same time")
	
	local function TC_APPLINK_18409_Case4_NonMedia_Navigation_And_NonMedia_Social_Apps()
			
		function Test:TC_APPLINK_18409_Case4_Precondition1_Change_App1_To_NonMedia_Navigation_App()
			config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
			config.application1.registerAppInterfaceParams.isMediaApplication = false
		end
	
		commonSteps:RegisterAppInterface("TC_APPLINK_18409_Case4_Precondition2_Register_NonMedia_Navigation_App")
		
		function Test:TC_APPLINK_18409_Case4_Precondition3_Register_Second_Media_Social_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"SOCIAL"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
	
		commonSteps:ActivationApp(_,"TC_APPLINK_18409_Case4_Step1_Activate_First_Non_Media_Navigation_App")
		
		function Test:TC_APPLINK_18409_Case4_Step2_Activate_Second_None_Media_Social_App()
			self:activate_App(2,2)
		end
		
		function Test:TC_APPLINK_18409_Case4_Step3_Activate_First_None_Media_Navigation_App_Again()
			self:activate_App(1,2)
		end
	end

	TC_APPLINK_18409_Case4_NonMedia_Navigation_And_NonMedia_Social_Apps()
		
	commonSteps:UnregisterApplication("Unregister_App1_TC_APPLINK_18409_Case4")
	
	Test["Unregister_App2_TC_APPLINK_18409_Case4"] = function(self)
		self:unregisterAppInterface(1)
	end
	
commonFunctions:newTestCasesGroup("****************************** END TEST BLOCK VI ******************************")	
----------------------------------------------------------------------------------------------------------------------------------------	
	
---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--Begin Check with Different HMIStatus
	--1.FULL
	--2.BACKGROUND
	--3.LIMITED
	
	--Write TEST_BLOCK_I_Begin to ATF log
	commonFunctions:newTestCasesGroup("****************************** Test suite VII: Check with Different HMIStatus ******************************")				
		
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes is changed. SDL puts these app from FULL app to BACKGROUND
-------------------------------------------------------------------------------------------------------------------------------------------
	local testData = {
			{AppType = "Media_Media", 			IsMedia= true, 	AppHMIType = {"MEDIA"}, 		AppID =  "7_1"},
			{AppType = "NonMedia_Navigation", 	IsMedia= false, AppHMIType = {"NAVIGATION"}, 	AppID =  "7_2"},
			{AppType = "NonMedia_Communication",IsMedia= false, AppHMIType = {"COMMUNICATION"}, AppID =  "7_3"}
		}
	
	for i = 1, #testData do
	
		commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes is changed. SDL puts "..testData[i].AppType.." from FULL to BACKGROUND")
		
		local function App_Changes_From_FULL_TO_BACKGROUND_By_PTU()
			local PermissionLinesForApplication = 
			[[			"]]..testData[i].AppID ..[[" : {
							"keep_context" : false,
							"steal_focus" : false,
							"priority" : "NONE",
							"default_hmi" : "NONE",
							"groups" : ["Base-4"],
							"AppHMIType": ["TESTING"],
							"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
						},
			]]

			local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
			function Test:Case_FULL_Precondition1_Change_App1_Params()
				config.application1.registerAppInterfaceParams.appHMIType = testData[i].AppHMIType
				config.application1.registerAppInterfaceParams.isMediaApplication = testData[i].IsMedia
				config.application1.registerAppInterfaceParams.fullAppID =testData[i].AppID
			end
			
			commonSteps:RegisterAppInterface("Case_FULL_Precondition1_Register_App"..i)
			
			commonSteps:ActivationApp(_,"Case_FULL_Step1_Activate_App"..i)
			
			Test["Case_FULL_Step2_AppHMIType_IsChanged_By_PTU"..i] = function(self)
				self:change_AppHMIType_By_PTU(1,PTName)		
				self:expect_UIChangeRegistration_OnHMIStatus("SUCCESS",1)	
			end
		end 

		App_Changes_From_FULL_TO_BACKGROUND_By_PTU()
		
		commonSteps:UnregisterApplication("UnregisterApplication_AppID_"..testData[i].AppID)
	end	
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes is changed. SDL doens't put App from BACKGROUND to LIMITED
-------------------------------------------------------------------------------------------------------------------------------------------
	
	commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes is changed from DEFAULT to MEDIA. SDL doesn't put app from BACKGROUND to LIMITED")
	
	local function App_Doesnot_Change_HMILevel_To_Limited_By_PTU_1()
	
		local PermissionLinesForApplication = 
		[[			"]].."7_6" ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4"],
						"AppHMIType": ["MEDIA"],
						"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
					},
		]]

		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
	
		function Test:Case_BACKGROUND1_Precondition1_Change_App1_Params()
			config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
			config.application1.registerAppInterfaceParams.isMediaApplication = true
			config.application1.registerAppInterfaceParams.fullAppID ="7_6"
		end
		
		commonSteps:RegisterAppInterface("Case_BACKGROUND1_Precondition1_Register_Media_Default_App")
	
		commonSteps:ActivationApp(_,"Case_BACKGROUND1_Precondition2_Activate_The_First_App")
					
		function Test:Case_BACKGROUND1_Precondition3_Register_Second_Media_Default_App()
			config.application2.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
			config.application2.registerAppInterfaceParams.isMediaApplication = true
			config.application2.registerAppInterfaceParams.fullAppID ="7_7"
			self:registerAppInterface2()
		end
	
		function Test:Case_BACKGROUND1_Step1_Bring_First_App_To_BG()
			self:activate_App(2, 2)
		end
	
		Test["Case_BACKGROUND1_Step2_AppHMIType_IsChanged_To_MEDIA_By_PTU"] = function(self)
			self:change_AppHMIType_By_PTU(2,PTName)	
			
			--HMI expecte to receive UI.ChangeRegistration
			EXPECT_HMICALL("UI.ChangeRegistration", {})
			:Do(function(_,data)
				--hmi side: sending Response to SDL
				self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
			end)
			
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			:Times(0)
			commonTestCases:DelayedExp(1000) 
		end
	
	end 

	App_Doesnot_Change_HMILevel_To_Limited_By_PTU_1()

	commonSteps:UnregisterApplication("UnregisterApp_Case_BACKGROUND1")
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes is changed. SDL doens't put App from BACKGROUND to LIMITED
-------------------------------------------------------------------------------------------------------------------------------------------	
	
	commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes is changed from DEFAULT to COMMUNICATION. SDL doesn't put app from BACKGROUND to LIMITED")
	
	local function App_Doesnot_Change_HMILevel_To_Limited_By_PTU_2()	
		local PermissionLinesForApplication = 
		[[			"]].."7_4" ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4"],
						"AppHMIType": ["COMMUNICATION"],
						"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
					},
		]]

		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		function Test:Case_BACKGROUND2_precondition1_Change_App1_Params()
			config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
			config.application1.registerAppInterfaceParams.isMediaApplication = false
			config.application1.registerAppInterfaceParams.fullAppID ="7_4"
		end
		
		commonSteps:RegisterAppInterface("Case_BACKGROUND2_Precondition2_Register_NonMedia_Default_App_")
		
		commonSteps:ActivationApp(_,"Case_BACKGROUND2_Precondition3_Activate_App")
		
		function Test:Case_BACKGROUND2_Step1_Bring_App_To_BackGround()
			local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications[config.application1.registerAppInterfaceParams.appName],
					reason = "AUDIO"
				})
				
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
		Test["Case_BACKGROUND2_Step2_AppHMIType_IsChanged_To_COMMUNICATION_By_PTU"] = function(self)
					
			self:change_AppHMIType_By_PTU(1,PTName)		
			
			--HMI expecte to receive UI.ChangeRegistration
			EXPECT_HMICALL("UI.ChangeRegistration", {})
			:Do(function(_,data)
				--hmi side: sending Response to SDL
				self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
			end)
			
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			:Times(0)
			commonTestCases:DelayedExp(1000) 
		end
	
	end 

	App_Doesnot_Change_HMILevel_To_Limited_By_PTU_2()
	
	commonSteps:UnregisterApplication("UnregisterApp_Case_BACKGROUND2")
-------------------------------------------------------------------------------------------------------------------------------------------
--Verification:  After PTU, the AppHMITypes is changed. SDL doens't put App from BACKGROUND to LIMITED
-------------------------------------------------------------------------------------------------------------------------------------------
	
		local PermissionLinesForApplication = 
		[[			"]].."7_5" ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4"],
						"AppHMIType": ["NAVIGATION"],
						"RequestType": ["TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "FILE_RESUME"]
					},
		]]

		local PTName =  policyTable:createPolicyTableFile(nil, nil, PermissionLinesForApplication)	
		
		commonFunctions:newTestCasesGroup("After PTU, the AppHMITypes is changed from SOCIAL to NAVIGATION. SDL doesn't put app from BACKGROUND to LIMITED")
		
		local function App_Doesnot_Change_HMILevel_To_Limited_By_PTU_3()
		
			function Test:Case_BACKGROUND3_Precondition1_Change_App1_Params_To_NonMedia_Social()
				config.application1.registerAppInterfaceParams.appHMIType = {"SOCIAL"}
				config.application1.registerAppInterfaceParams.isMediaApplication = false
				config.application1.registerAppInterfaceParams.fullAppID ="7_5"
			end
			
			commonSteps:RegisterAppInterface("Case_BACKGROUND3_Precondition2_Register_NonMedia_Social_App")
			
			commonSteps:ActivationApp(_,"Case_BACKGROUND3_Activate_NonMedia_Social_App")
			
			function Test:Case_BACKGROUND3_Step1_Bring_App_To_BackGround()
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						reason = "AUDIO"
					})
					
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end
					
			Test["Case_BACKGROUND3_Step2_AppHMIType_IsChanged_To_NAVIGATION_By_PTU"] = function(self)
						
				self:change_AppHMIType_By_PTU(1,PTName)		
				
				--HMI expecte to receive UI.ChangeRegistration
				EXPECT_HMICALL("UI.ChangeRegistration", {})
				:Do(function(_,data)
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id, data.method, resultCode,{})
				end)
				
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(0)
				commonTestCases:DelayedExp(1000) 
			end
		
		end 

		App_Doesnot_Change_HMILevel_To_Limited_By_PTU_3()
	
		commonSteps:UnregisterApplication("UnregisterApp_Case_BACKGROUND3")
	
	--Write TEST_BLOCK_VII_End to ATF log
	commonFunctions:newTestCasesGroup("******************************END TEST BLOCK VII******************************************")