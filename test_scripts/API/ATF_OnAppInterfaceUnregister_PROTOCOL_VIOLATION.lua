--NOTE:session:ExpectNotification("notification_name", { argument_to_check }) is chanegd to session:ExpectNotification("notification_name", {{ argument_to_check }}) due to defect APPLINK-17030 
--After this defect is done, please reverse to session:ExpectNotification("notification_name", { argument_to_check })
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnAppInterfaceUnregister.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnAppInterfaceUnregister.lua")

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnAppInterfaceUnregister')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Functions ---------------------------------------
---------------------------------------------------------------------------------------------
local function startSession(self)

	self.mobileSession= mobile_session.MobileSession(self, self.mobileConnection)
	--start session
	self.mobileSession:StartService(7)
	
end

local function StopSDL_StartSDL_InitHMI_ConnectMobile(TestCaseSubfix)
	--Postconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
	
	Test["StopSDL_" .. TestCaseSubfix]  = function(self)
	  StopSDL()
	end
	
	Test["StartSDL_" .. TestCaseSubfix]  = function(self)
	  StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI_" .. TestCaseSubfix]  = function(self)
	  self:initHMI()
	end

	Test["InitHMI_onReady_" .. TestCaseSubfix]  = function(self)
	  self:initHMI_onReady()
	end


	Test["ConnectMobile_" .. TestCaseSubfix]  = function(self)
	  self:connectMobile()
	end

	Test["StartSession_" .. TestCaseSubfix]  = function(self)
		startSession(self)
	end
	
end

function Test:change_App_Params(appType,isMedia)	
	config.application1.registerAppInterfaceParams.appHMIType = appType
	config.application1.registerAppInterfaceParams.isMediaApplication=isMedia
end
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	-- Precondition: removing user_modules/connecttest_OnAppInterfaceUnregister.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnAppInterfaceUnregister.lua" )
	end

	--Delete Policy and Log Files
	commonSteps:DeleteLogsFileAndPolicyTable()
	commonSteps:UnregisterApplication("Precondition_Unregister")
	StopSDL_StartSDL_InitHMI_ConnectMobile("Precondition_StopSDL_StartHMI")
---------------------------------------------------------------------------------------------------------
-- Requirement Id: https://adc.luxoft.com/svn/APPLINK/doc/technical/requirements/Mobile_Nav/multiple_navi_apps
----------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("OnAppInterfaceUnregistered(PROTOCOL_VIOLATION) when app continues streaming data at Background")

local function Unregister_PROTOCOL_VIOLATION_StreamingData_AtBackGround()
    
	function Test:Case1_Change_App1_To_Navigation()
		self:change_App_Params({"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("Case1_RegisterApp")
	commonSteps:ActivationApp(_,"Case1_ActivateApp")
	
	function Test:AddNewSession()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
	end

	function Test:Case1_RegisterSecondNavigationApp()
	
		config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
		config.application2.registerAppInterfaceParams.isMediaApplication=true
		
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
		self.mobileSession1:ExpectNotification("OnHMIStatus", {{systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}})
		:Timeout(2000)
	end
	
	function Test:StartAudioVideoServices_VideoStreaming()

		self.mobileSession:StartService(10)

		EXPECT_HMICALL("Navigation.StartAudioStream")
			:Do(function(exp,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
			end)
			
		self.mobileSession:StartService(11)

		EXPECT_HMICALL("Navigation.StartStream")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
				function to_run1()
					self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
				end

				RUN_AFTER(to_run1, 1500)
			end)
	end
	
	function Test:Activate_Second_NavigationApp_Then_Continues_Streaming()
	
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
			
			function to_run2()
				self.mobileSession:StartStreaming(11,"files/Wildlife1.wmv")
			end
			--continue streaming data after 1 second
			RUN_AFTER(to_run2, 1000)
		end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID =  self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "PROTOCOL_VIOLATION"}})
	end

end

Unregister_PROTOCOL_VIOLATION_StreamingData_AtBackGround()

function Test:StopStreamAtBackGround()
	self.mobileSession:StopStreaming("files/Wildlife.wmv")
	self.mobileSession:StopStreaming("files/Wildlife1.wmv")
end

StopSDL_StartSDL_InitHMI_ConnectMobile("Unregister_PROTOCOL_VIOLATION_StreamingData_AtBackGround")
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("OnAppInterfaceUnregistered(PROTOCOL_VIOLATION) when NoACKResponse_ForEndServive")

local function Unregister_PROTOCOL_VIOLATION_NoACKResponse_ForEndServive()

	function Test:Change_App1_To_Navigation()
		self:change_App_Params({"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("Case2_RegisterApp")
	commonSteps:ActivationApp(_,"Case2_ActivateApp")

	function Test:StartAudioVideoServices()

		self.mobileSession:StartService(10)

		EXPECT_HMICALL("Navigation.StartAudioStream")
			:Do(function(exp,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
			end)

		self.mobileSession:StartService(11)

		EXPECT_HMICALL("Navigation.StartStream")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })     	
			end)
	end
	
	function Test:ExitApplication()

		--hmi side: send OnExitApplication
		self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		--mobile side: expected OnHMIStatus (NONE, NOT_AUDIBLE) notification
		--self.mobileSession:ExpectNotification("OnHMIStatus", {{systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}})
		
		 -- Event: EndService from SDL for audion and video services
 		local event = events.Event()
 		event.matches = function(_, data)
    	    return data.frameType   == 0 and
            	(data.serviceType == 11 or data.serviceType == 10) and
                 data.sessionId   == self.mobileSession.sessionId and
                (data.frameInfo   == 4) --EndService
                 end
 		self.mobileSession:ExpectEvent(event, "EndService")
    	:Timeout(60000)
    	:Times(2)
    	:ValidIf(function(s, data)
               if data.frameInfo == 4  and data.serviceType == 11 
               	then
               	--Mobile side: mobile send EndVideoService ACK to SDL
    			self.mobileSession:Send(
		           {
		             frameType   = 0,
		             serviceType = 11,
		             frameInfo   = 5,
		             sessionId   = self.mobileSession.sessionId,
		           })
                return true

    			elseif data.frameInfo == 4  and data.serviceType == 10 
               	then
               
				print("Mobile doesn't send EndAudioService ACK to SDL")
    		
                return true
            
               else return false, "End Service not received" end
        end)    	
		
		--TODO: Uncomment below script after defect APPLINK-13680 is done
		
		-- EXPECT_HMICALL("Navigation.StopAudioStream")
			-- :Do(function(_,data)
				-- -- successful StopAudioStream on HMI side
				-- self.hmiConnection:SendResponse(data.id,"Navigation.StopAudioStream", "SUCCESS", {})
			-- end)

		EXPECT_HMICALL("Navigation.StopStream")
			:Do(function(_,data)
				-- successful StopStream on HMI side
				self.hmiConnection:SendResponse(data.id,"Navigation.StopStream", "SUCCESS", {})
			end)
			
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID =  self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "PROTOCOL_VIOLATION"}})
	end
end

Unregister_PROTOCOL_VIOLATION_NoACKResponse_ForEndServive()
------------------------------------------------------------------------------------------------------------------

--NOTE: This TC can run correctly till APPLINK-14456 is implemeted
commonFunctions:newTestCasesGroup("OnAppInterfaceUnregistered(reason:PROTOCOL_VIOLATION) when received more than 2 malformed message in 1 second ")

local function Unregister_PROTOCOL_VIOLATION_MalformMessage()

	commonSteps:RegisterAppInterface("CaseMalformMessage_RegisterApp")
	commonSteps:ActivationApp(_,"CaseMalformMessage_ActiveApp")
		
	function Test:SendMalformMessage()
	
		for i =1, 3 do
			self.mobileSession:Send(
			   {
				version =05,
				 frameType   = 03,
				 dataSize    = 05,
				 messageId	 = 00,
				 serviceType = 07,
				 frameInfo   = 5,
				 sessionId   = self.mobileSession.sessionId,
			   })
		end
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID =  self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "PROTOCOL_VIOLATION"}})
	end
	
end
--Unregister_PROTOCOL_VIOLATION_MalformMessage()
