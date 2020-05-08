--NOTE:session:ExpectNotification("notification_name", { argument_to_check }) is chanegd to session:ExpectNotification("notification_name", {{ argument_to_check }}) due to defect APPLINK-17030 
--After this defect is done, please reverse to session:ExpectNotification("notification_name", { argument_to_check })
----------------------------------------------------------------------------------------------------
-- AppHMILevelNoneTimeScaleMaxRequests = 10
-- AppHMILevelNoneRequestsTimeScale = 1
-- AppTimeScaleMaxRequests = 1
-- AppRequestsTimeScale = 1000
--------------------------------------------------------------------------------------------------

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local module = require('testbase')

--------------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

------------------------------------------------------------------------------------------------
---------------------------------Common functions---------------------------------------------------
------------------------------------------------------------------------------------------------
function Test:send_Many_Request(app)

	local session
	
	if app ==1 then
		session =self.mobileSession
		appName=config.application1.registerAppInterfaceParams.appName
	end 
	
	if app ==2 then
		session =self.mobileSession1
		appName=config.application2.registerAppInterfaceParams.appName
	end 
	
	if app ==3 then
		session =self.mobileSession2
		appName=config.application3.registerAppInterfaceParams.appName
	end
	
	local AppNotRegisteredReqCount=0
	
	for i = 1,10 do			
		--mobile side: sending ListFiles request
		local cid =session:SendRPC("ListFiles", {} )
	end
	
	session:ExpectResponse("ListFiles")
	:ValidIf(function(exp,data)			
		if 
			data.payload.resultCode == "APPLICATION_NOT_REGISTERED" then
			AppNotRegisteredReqCount = AppNotRegisteredReqCount+1
			print(" \27[32m ListFiles response came with resultCode APPLICATION_NOT_REGISTERED \27[0m")
			return true
		elseif				
		   exp.occurences  ==10 and AppNotRegisteredReqCount == 0 then			   
			print(" \27[36m Response ListFiles with resultCode APPLICATION_NOT_REGISTERED did not came \27[0m")
			return false
		elseif 
		  data.payload.resultCode == "SUCCESS" then
			print(" \27[32m ListFiles response came with resultCode SUCCESS \27[0m")
			return true
		else
			print(" \27[36m ListFiles response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
			return false
		end
		
	end)
	:Times(AtMost(10))

	--hmi side: expect BasicCommunication.OnAppUnregistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID =  self.applications[appName], unexpectedDisconnect =  false})
			
	--mobile side: expect notification
	session:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "TOO_MANY_REQUESTS"}})

end	

function Test:change_App(appType,isMedia,appID)
	config.application1.registerAppInterfaceParams.appHMIType = appType
	config.application1.registerAppInterfaceParams.isMediaApplication = isMedia
	config.application1.registerAppInterfaceParams.fullAppID=appID
end

-------------------------------------------------------Precondition--------------------------------------------------
function Test:Precondition_SecondSession()
	self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession1:StartService(7)
end		

function Test:Precondition_ThirdSession()
	self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession2:StartService(7)
end		

---------------------------------------------------------------------------------------------------------
--Requirement Id: APPLINK-16207
----------------------------------------------------------------------------------------------------------
--APPLINK-18427: Check when App is FULL
--Verification: OnAppInterfaceUnregistered notification with TOO_MANY_REQUESTS reason.
----------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18427: App is FULL, SDL sends OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) when app sends more than 1 requests in 1 second")

commonSteps:ActivationApp(_,"APPLINK_18427_Case_AppIsFULL_ActivateApp")

function Test:APPLINK_18427_Case_AppIsFULL()
	self:send_Many_Request(1)
end	

function Test:APPLINK_18427_Case_AppIsFULL_RegisterAppAgain()
	local cid= self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS"})
end

----------------------------------------------------------------------------------------------------------
--APPLINK-18427: Check when App is LIMITED
--Verification: OnAppInterfaceUnregistered notification with TOO_MANY_REQUESTS reason when app is LIMITED
------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18427: App is LIMITED, SDL sends OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) when app sends more than 1 requests in 1 second")
function Test:Change_App_To_MEDIA()
	config.application2.registerAppInterfaceParams.appHMIType = {"MEDIA"}
	config.application2.registerAppInterfaceParams.isMediaApplication = true
end

function Test:RegisterAppInterfaceMediaApp()
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
		{{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		}})
		:Timeout(2000)
end	

function Test:Activate_MediaApp()
	local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
	EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
		end)
	
	self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
end

function Test:Bring_App_To_Limited()
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[config.application2.registerAppInterfaceParams.appName]
		})
		
	self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
end

function Test:APPLINK_18427_Case_AppIsLIMITED()
	self:send_Many_Request(2)
end	

function Test:APPLINK_18427_Case_AppIsLIMITED_RegisterAppAgain()
	local cid= self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
	self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS"})
end

------------------------------------------------------------------------------------------------------------
--APPLINK-18427: Check when App is BACKGROUND
--Verification: OnAppInterfaceUnregistered notification with TOO_MANY_REQUESTS reason when app is BACKGROUND
--------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18427: App is BACKGROUND, SDL sends OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) when app sends more than 1 requests in 1 second")

function Test:Change_App_To_NonMEDIA()
	config.application3.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
	config.application3.registerAppInterfaceParams.isMediaApplication = false
end

function Test:RegisterAppInterfaceNonMediaApp()
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
		{{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		}})
		:Timeout(2000)
end		

function Test:Activate_NonMediaApp()
	local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})
	EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
		end)
	
	self.mobileSession2:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
end

function Test:Bring_App_To_Background()
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[config.application3.registerAppInterfaceParams.appName]
		})
		
	self.mobileSession2:ExpectNotification("OnHMIStatus",{{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
end

function Test:APPLINK_18427_Case_AppIsBACKGROUND()
	self:send_Many_Request(3)
end	

function Test:APPLINK_18427_Case_BACKGROUND_RegisterAppAgain()
	local cid= self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)
	self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS"})
end
