--NOTE:session:ExpectNotification("notification_name", { argument_to_check }) is chanegd to session:ExpectNotification("notification_name", {{ argument_to_check }}) due to defect APPLINK-17030 
--After this defect is done, please reverse to session:ExpectNotification("notification_name", { argument_to_check })
-------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnAppInterfaceUnregistered.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnAppInterfaceUnregistered.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnAppInterfaceUnregistered')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
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
	  --self:startSession_WithoutRegisterApp()
		startSession(self)
	end
	
end

function Test: onAppInterfaceUnregistered(reason,case)
	--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = reason})
				
	if case==nil then
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = reason}})
	end
	if case==4 then 
	
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
																	{appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																	{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																	{appID = self.applications[config.application3.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																	{appID = self.applications[config.application4.registerAppInterfaceParams.appName], unexpectedDisconnect =  false}
																	)
		
		:Times(4)	
		
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = reason}})
		self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", {{reason = reason}})
		self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {{reason = reason}})
		self.mobileSession3:ExpectNotification("OnAppInterfaceUnregistered", {{reason = reason}})
	end
	--hmi side: expect to BasicCommunication.OnSDLClose
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
end

function Test:add_Sessions()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession1:StartService(7)
	
	self.mobileSession2 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession2:StartService(7)

	self.mobileSession3 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession3:StartService(7)
end 

function Test:exitAppBy_DRIVER_DISTRACTION_VIOLATION(isExit)

	--HMI sends BasicCommunication.OnExitApplication("DRIVER_DISTRACTION_VIOLATION")
	self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {reason = "DRIVER_DISTRACTION_VIOLATION", appID=self.applications[config.application1.registerAppInterfaceParams.appName]})
	if isExit==true then		
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID=self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		--mobile side: Expected OnHMIStatus() notification
		EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
	end
	
	--mobile side: expect notification
	self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}})	
	:Times(0)
	--hmi side: expect BasicCommunication.OnAppUnregistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {})
	:Times(0)
	commonTestCases:DelayedExp(1000) 

end

function Test:change_App_Params(app,appType,isMedia)
	local session
	
	if app==1 then 
		session = config.application1.registerAppInterfaceParams
	end

	if app==2 then 
		session = config.application2.registerAppInterfaceParams
	end

	if app==3 then 
		session = config.application3.registerAppInterfaceParams
	end
	
	session.isMediaApplication = isMedia
		
	if appType=="" then 
		session.appHMIType = nil 
	else 
		session.appHMIType = appType
	end
end

function Test:bring_App_To_LIMITED_OR_BACKGROUND(isMedia)
 
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications[config.application1.registerAppInterfaceParams.appName]
				})
	
	if isMedia==true then 
		self.mobileSession:ExpectNotification("OnHMIStatus",{{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
	
	else 
		self.mobileSession:ExpectNotification("OnHMIStatus",{{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
	end 
end

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
	self.mobileSession1:ExpectNotification("OnHMIStatus", {{systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}})
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

function Test:registerAppInterface4()
	--mobile side: sending request 
	local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface", config.application4.registerAppInterfaceParams)

	--hmi side: expect BasicCommunication.OnAppRegistered request
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
				{
					appName = config.application4.registerAppInterfaceParams.appName
				}
		})
		:Do(function(_,data)
			self.applications[config.application4.registerAppInterfaceParams.appName] = data.params.application.appID					
	end)

	--mobile side: expect response
	self.mobileSession3:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = config.syncMsgVersion
		})
		:Timeout(2000)

	--mobile side: expect notification
	self.mobileSession3:ExpectNotification("OnHMIStatus", {{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}})
		:Timeout(2000)
end		

function Test:activate_App(app)
	--Activate the first app
	if app==1 then

		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
	end
	
	
	--Activate the second app
	if app==2 then
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
	end
	
	--Activate the third app
	if app==3 then
        
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})
		
		EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
			end)
		
		self.mobileSession2:ExpectNotification("OnHMIStatus",{{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
	end
		
end

function Test:add_SecondSession()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession1:StartService(7)
end

function Test:add_ThirdSession()

	self.mobileSession2 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession2:StartService(7)
end

function Test:add_FourthSession()

	self.mobileSession3 = mobile_session.MobileSession(
	self,
	self.mobileConnection)
	self.mobileSession3:StartService(7)
end
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete Policy and Log Files
	commonSteps:DeleteLogsFileAndPolicyTable()	

	-- Precondition: removing user_modules/connecttest_OnAppInterfaceUnregistered.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnAppInterfaceUnregistered.lua" )
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

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI Response-----------------------
-----------------------------------------------------------------------------------------------

--Not Applicable
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes-------------------------------------
---------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	

----------------------------------------------------------------------------------------------------------------
----APPLINK-18538
----Verification: app is not unregisterd when exit by DRIVER_DISTRACTION_VIOLATION.
--------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18538: Without OnAppInterfaceUnregistered if app is NONE and exited by DRIVER_DISTRACTION_VIOLATION ")

local function TC_APPLINK_18538_AppIsNONE()
	 	
	function Test: ExitAppBy_DRIVER_DISTRACTION_VIOLATION()
		self:exitAppBy_DRIVER_DISTRACTION_VIOLATION(false)
	end
end

TC_APPLINK_18538_AppIsNONE()	
------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18538: Without OnAppInterfaceUnregistered if app is FULL and exited by DRIVER_DISTRACTION_VIOLATION ")

local function TC_APPLINK_18538_AppIsFULL()
	commonSteps:ActivationApp(_,"TC_APPLINK_18538_AppIsFULL_ActivateApp")
	
	function Test:TC_APPLINK_18538_AppIsFULL_ExitAppBy_DRIVER_DISTRACTION_VIOLATION()
		self:exitAppBy_DRIVER_DISTRACTION_VIOLATION(true)
	end
end

TC_APPLINK_18538_AppIsFULL()
-------------------------------------------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18538: Without OnAppInterfaceUnregistered if app is LIMITED and exited by DRIVER_DISTRACTION_VIOLATION ")

local function TC_APPLINK_18538_AppIsLIMITED()
	 
	commonSteps:UnregisterApplication("TC_APPLINK_18538_AppIsLIMITED_Unregister")
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18538_AppIsLIMITED_Precondition")
	
	function Test:TC_APPLINK_18538_AppIsLIMITED_Change_App_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end

	commonSteps:RegisterAppInterface("TC_APPLINK_18538_AppIsLIMITED_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18538_AppIsLIMITED_ActivateApp")
	
	function Test:TC_APPLINK_18538_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test:TC_APPLINK_18538_AppIsLIMITED_RegisterApp_ExitAppBy_DRIVER_DISTRACTION_VIOLATION()
		self:exitAppBy_DRIVER_DISTRACTION_VIOLATION(true)
	end
	
end

TC_APPLINK_18538_AppIsLIMITED()
-------------------------------------------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18538: Without OnAppInterfaceUnregistered if app is BACKGROUND and exited by DRIVER_DISTRACTION_VIOLATION ")

local function TC_APPLINK_18538_AppIsBACKGROUND()
	 
	commonSteps:UnregisterApplication("TC_APPLINK_18538_AppIsBACKGROUND_Precondition_Unregister")
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18538_AppIsBACKGROUND_Precondition")
	
	function Test:Change_App_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end

	commonSteps:RegisterAppInterface("TC_APPLINK_18538_AppIsBACKGROUND_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18538_AppIsBACKGROUND_ActivateApp")
	
	function Test:TC_APPLINK_18538_Bring_App_To_BACKGROUND()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18538_ExitAppBy_DRIVER_DISTRACTION_VIOLATION()
		self:exitAppBy_DRIVER_DISTRACTION_VIOLATION(true)
	end
	
end

TC_APPLINK_18538_AppIsBACKGROUND()	
---------------------------------------------------------------------------------------------------------
-- APPLINK-18414
-- Verification: OnAppInterfaceUnregistered notification with IGNITION_OFF reason.
----------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18414: (IGNITION_OFF) with one app is NONE")

local function TC_APPLINK_18414_AppIsNone()

	function Test: TC_APPLINK_18414_AppIsNone_OnAppInterfaceUnregistered_IGNITION_OFF()
		self:onAppInterfaceUnregistered("IGNITION_OFF")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18414_AppIsNone_Postcondition")
	
end 

TC_APPLINK_18414_AppIsNone()
-----------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18414: OnAppInterfaceUnregistered(IGNITION_OFF) with 4 apps")

local function TC_APPLINK_18414_Case4Apps()

	function Test:TC_APPLINK_18414_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18414_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18414_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end

	function Test:TC_APPLINK_18414_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18414_Case4Apps_RegisterMediaApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18414_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18414_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18414_Case4Apps_Activate_NonMedia_App()
	     self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18414_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18414_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18414_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18414_Case4Apps_OnAppInterfaceUnregistered_IGNITION_OFF()
		self:onAppInterfaceUnregistered("IGNITION_OFF",4)
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TTC_APPLINK_18414_Case4Apps_postcondition")
	
end 

TC_APPLINK_18414_Case4Apps()
-------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18414: OnAppInterfaceUnregistered(IGNITION_OFF) with one app is FULL")

local function TC_APPLINK_18414_AppIsFull()

    commonSteps:RegisterAppInterface("TC_APPLINK_18414_AppIsFull_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18414_AppIsFull_ActivateApp")
	
	function Test: TC_APPLINK_18414_AppIsFull_OnAppInterfaceUnregistered_IGNITION_OFF()
		self:onAppInterfaceUnregistered("IGNITION_OFF")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18414_AppIsFull_Postcondition")
	
end 
TC_APPLINK_18414_AppIsFull()
----------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18414: OnAppInterfaceUnregistered(IGNITION_OFF) with one app is LIMITED")

local function TC_APPLINK_18414_AppIsLimited()

	function Test:TC_APPLINK_18414_AppIsLimited_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
    commonSteps:RegisterAppInterface("TC_APPLINK_18414_AppIsLimited_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18414_AppIsLimited_ActivateApp")
	
	function Test:TC_APPLINK_18414_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18414_AppIsLimited_OnAppInterfaceUnregistered_IGNITION_OFF()
		self:onAppInterfaceUnregistered("IGNITION_OFF")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18414_AppIsLimited_Postcondition")
	
end 
TC_APPLINK_18414_AppIsLimited()
----------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18414: OnAppInterfaceUnregistered(IGNITION_OFF) with one app is BACKGROUND")

local function TC_APPLINK_18414_AppIsBackground()

	function Test:TC_APPLINK_18414_AppIsBackground_Change_App1_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
    commonSteps:RegisterAppInterface("TC_APPLINK_18414_AppIsBackground_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18414_AppIsBackground_ActivationApp")
	
	function Test:TC_APPLINK_18414_Bring_App_To_BACKGROUND()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18414_AppIsBackground_OnAppInterfaceUnregistered_IGNITION_OFF()
		self:onAppInterfaceUnregistered("IGNITION_OFF")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18414_AppIsBackground_Postcondition")
	
end 

TC_APPLINK_18414_AppIsBackground()

----------------------------------------------------------------------------------------------------------
--APPLINK-18416
--Verification: SDL sends OnAppInterfaceUnregistered notification to mobile app when user press Ctrl+C in the console
------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18416: Without OnAppInterfaceUnregistered() when user press Ctrl+C in the console when app is None")

--TODO: Test case must be updated after resolving APPLINK-21088 
local function TC_APPLINK_18416_AppIsNone()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18416_AppIsNone_RegisterApp")

	function Test: TC_APPLINK_18416_AppIsNone_WithoutOnAppInterfaceUnregistered()

		
		StopSDL()
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  true})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}})
		:Times(0)
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
		
	end

	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18416_AppIsNone_Postcondition")
end

TC_APPLINK_18416_AppIsNone()
-----------------------------------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18416: Without OnAppInterfaceUnregistered() when user press Ctrl+C in the console with 4 apps")

--TODO: Test case must be updated after resolving APPLINK-21088 
local function TC_APPLINK_18416_Case4Apps()

	function Test:TC_APPLINK_18416_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18416_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18416_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18416_Case4Apps_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18416_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18416_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_Activate_NonMedia_App()
	        self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18416_Case4Apps_WithoutOnAppInterfaceUnregistered()
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		--self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
		StopSDL()
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  true},
																		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect =  true},
																		{appID = self.applications[config.application3.registerAppInterfaceParams.appName], unexpectedDisconnect =  true},
																		{appID = self.applications[config.application4.registerAppInterfaceParams.appName], unexpectedDisconnect =  true})
																		:Times(4)
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}}): Times(0)
		self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		self.mobileSession3:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18416_Case4Apps_postcondition")
	
end 

TC_APPLINK_18416_Case4Apps()
------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18416: Without OnAppInterfaceUnregistered() when user press Ctrl+C in the console when app is FULL")
 
--TODO: Test case must be updated after resolving APPLINK-21088 
local function TC_APPLINK_18416_AppIsFull()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18416_AppIsFull_ActivateApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18416_AppIsFull_ActivationApp")
	
	function Test: TC_APPLINK_18416_AppIsFull_WithoutOnAppInterfaceUnregistered()
		StopSDL()
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  true})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
		
	end

	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18416_AppIsFull_Postcondition")
end

TC_APPLINK_18416_AppIsFull()
-----------------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18416: Without OnAppInterfaceUnregistered() when user press Ctrl+C in the console when app is LIMITED")

--TODO: Test case must be updated after resolving APPLINK-21088 
local function TC_APPLINK_18416_AppIsLimited()

	function Test:TC_APPLINK_18416_AppIsLimited_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18416_AppIsLimited_ActivateApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18416_AppIsLimited_ActivationApp")
	
	function Test:TC_APPLINK_18416_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18416_AppIsLimited_WithoutOnAppInterfaceUnregistered()
		StopSDL()
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  true})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
		
	end

	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18416_AppIsLimited_Postcondition")
end

TC_APPLINK_18416_AppIsLimited()
-----------------------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18416: Without OnAppInterfaceUnregistered() when user press Ctrl+C in the console when app is BACKGROUND")
 
--TODO: Test case must be updated after resolving APPLINK-21088 
local function TC_APPLINK_18416_AppIsBackground()

	function Test:TC_APPLINK_18416_AppIsLimited_Change_App1_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18416_AppIsBackground_ActivateApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18416_AppIsBackground_ActivationApp")
	
	function Test:TC_APPLINK_18416_Bring_App_To_Background()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18416_AppIsBackground_WithoutOnAppInterfaceUnregistered()
		StopSDL()
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  true})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{}}):Times(0)
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
		
	end

	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18416_AppIsBackground_Postcondition")
end

TC_APPLINK_18416_AppIsBackground()

--------------------------------------------------------------------------------------------------------------
--APPLINK-18417
--Verification: OnAppInterfaceUnregistered notification with FACTORY_DEFAULTS reason.
------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18417: OnAppInterfaceUnregistered(FACTORY_DEFAULTS) with one app at NONE")

local function TC_APPLINK_18417_AppIsNone()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18417_AppIsNone_RegisterApp")
	
	function Test:TC_APPLINK_18417_AppIsNone_OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
		self:onAppInterfaceUnregistered("FACTORY_DEFAULTS")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18417_AppIsNone_Postcondition")
	
end 

TC_APPLINK_18417_AppIsNone()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18417_Case4Apps: OnAppInterfaceUnregistered(FACTORY_DEFAULTS) with 4 apps")
 
local function TC_APPLINK_18417_Case4Apps()

	function Test:TC_APPLINK_18417_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18417_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18417_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18417_Case4Apps_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18417_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18417_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_Activate_NonMedia_App()
	        self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18417_Case4Apps_OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
		self:onAppInterfaceUnregistered("FACTORY_DEFAULTS",4)
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18417_Case4Apps_postcondition")
	
end 

TC_APPLINK_18417_Case4Apps()
-------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18417: OnAppInterfaceUnregistered(FACTORY_DEFAULTS) with one app at FULL")

local function TC_APPLINK_18417_AppIsFull()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18417_AppIsFull_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18417_AppIsFull_ActivateApp")
	
	function Test: TC_APPLINK_18417_AppIsFull_OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
		self:onAppInterfaceUnregistered("FACTORY_DEFAULTS")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18417_AppIsFull_Postcondition")
	
end 

TC_APPLINK_18417_AppIsFull()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18417: OnAppInterfaceUnregistered(FACTORY_DEFAULTS) with one app at LIMITED")

local function TC_APPLINK_18417_AppIsLimited()
	
	function Test:TC_APPLINK_18417_AppIsLimited_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18417_AppIsLimited_ActivateApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18417_AppIsLimited_ActivationApp")
	
	function Test:TC_APPLINK_18417_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18417_AppIsLimited_OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
		self:onAppInterfaceUnregistered("FACTORY_DEFAULTS")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18417_AppIsLimited_Postcondition")
	
end 

TC_APPLINK_18417_AppIsLimited()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18417: OnAppInterfaceUnregistered(FACTORY_DEFAULTS) with one app at BACKGROUND")

local function TC_APPLINK_18417_AppIsBackground()

	function Test:TC_APPLINK_18417_AppIsLimited_Change_App1_To_Media()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18417_AppIsBackground_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18417_AppIsBackground_ActivateApp")
	
	function Test:TC_APPLINK_18417_Bring_App_To_Background()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18417_AppIsBackground_OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
		self:onAppInterfaceUnregistered("FACTORY_DEFAULTS")
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18417_AppIsBackground_Postcondition")
	
end 

TC_APPLINK_18417_AppIsBackground()

-------------------------------------------------------------------------------------------------------------
--APPLINK-18419
--Verification: OnAppInterfaceUnregistered notification with LANGUAGE_CHANGE reason.
------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered (LANGUAGE_CHANGE) when change TTS +VR language on HMI and app is NONE")

local function TC_APPLINK_18419_Change_TTSVR_AppIsNone()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_TTSVR_AppIsNone_RegisterApp")
	
	function Test: TC_APPLINK_18419_AppIsNone_OnAppInterfaceUnregistered_TTSVR_LANGUAGE_CHANGE()
	
		--hmi side: sending TTS.OnLanguageChange/VR.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language="FR-FR"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{language="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsNone_Postcondition")
end 

 TC_APPLINK_18419_Change_TTSVR_AppIsNone()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered (LANGUAGE_CHANGE) when change TTS +VR language on HMI with 4 apps")

local function TC_APPLINK_18419_Change_TTS_VR_Case4Apps()
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_TTS_VR_Case4Apps_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_TTS_VR_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Activate_NonMedia_App()
	        self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18419_Change_TTS_VR_Case4Apps_OnAppInterfaceUnregistered_TTSVR_LANGUAGE_CHANGE()
	
		--hmi side: sending TTS.OnLanguageChange/VR.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language="FR-FR"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{language="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application3.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application4.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
																		:Times(4)
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession3:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTS_VR_Case4Apps_postcondition")
	
end 

TC_APPLINK_18419_Change_TTS_VR_Case4Apps()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered (LANGUAGE_CHANGE) when change TTS +VR language on HMI and app is FULL")

local function TC_APPLINK_18419_Change_TTSVR_AppIsFull()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_TTSVR_AppIsFull_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_TTSVR_AppIsFull_ActivateApp")
	
	function Test: TC_APPLINK_18419_AppIsFull_OnAppInterfaceUnregistered_TTSVR_LANGUAGE_CHANGE()
	
		--hmi side: sending TTS.OnLanguageChange/VR.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language="FR-FR"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{language="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsFull_Postcondition")
end 

 TC_APPLINK_18419_Change_TTSVR_AppIsFull()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered (LANGUAGE_CHANGE) when change TTS +VR language on HMI and app is LIMITED")

local function TC_APPLINK_18419_Change_TTSVR_AppIsLimted()

	function Test:TC_APPLINK_18419_Change_TTSVR_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_TTSVR_AppIsLimited_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_TTSVR_AppIsLimited_ActivateApp")
	
	function Test:TC_APPLINK_18419_Change_TTSVR_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18419_AppIsLimited_OnAppInterfaceUnregistered_TTSVR_LANGUAGE_CHANGE()
	
		--hmi side: sending TTS.OnLanguageChange/VR.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language="FR-FR"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{language="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered",{ {reason = "LANGUAGE_CHANGE"}})	
		
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsLimited_Postcondition")
end 

 TC_APPLINK_18419_Change_TTSVR_AppIsLimted()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered (LANGUAGE_CHANGE) when change TTS +VR language on HMI and app is BACKGROUND")

local function TC_APPLINK_18419_Change_TTSVR_AppIsBackground()

	function Test:TC_APPLINK_18419_Change_TTSVR_Change_App1_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_TTSVR__AppIsBackground_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_TTSVR_AppIsBackground_ActivateApp")
	
	function Test:TC_APPLINK_18419_Change_TTSVR_Bring_App_To_Background()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18419_AppIsBackground_OnAppInterfaceUnregistered_TTSVR_LANGUAGE_CHANGE()
		--hmi side: sending TTS.OnLanguageChange/VR.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language="FR-FR"})
		self.hmiConnection:SendNotification("VR.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{language="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsBackground_Postcondition")
end 

 TC_APPLINK_18419_Change_TTSVR_AppIsBackground()
------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered(LANGUAGE_CHANGE) when changed UI language on HMI and app is NONE")

local function TC_APPLINK_18419_Change_UILanguage_AppIsNone()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_UILanguage_AppIsNone_RegisterApp")
	
	function Test: TC_APPLINK_18419_AppIsNone_OnAppInterfaceUnregistered_UI_LANGUAGE_CHANGE()
		--hmi side: sending UI.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage="FR-FR"})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsNone_Postcondition")
end 

TC_APPLINK_18419_Change_UILanguage_AppIsNone()
---------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered(LANGUAGE_CHANGE) when changed UI language on HMI with 4 apps")

local function TC_APPLINK_18419_Change_UI_Language_Case4Apps()

	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_UI_Language_Case4Apps_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_UI_Language_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Activate_NonMedia_App()
	        self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18419_Change_UI_Language_Case4Apps_OnAppInterfaceUnregistered_UI_LANGUAGE_CHANGE()
	
		--hmi side: sending UI.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		self.mobileSession:ExpectNotification("OnLanguageChange", {{hmiDisplayLanguage="FR-FR"}})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application3.registerAppInterfaceParams.appName], unexpectedDisconnect =  false},
																		{appID = self.applications[config.application4.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
																		:Times(4)
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered",{{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		self.mobileSession3:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "LANGUAGE_CHANGE"}})	
		

	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_UI_Language_Case4Apps_postcondition")
	
end 

TC_APPLINK_18419_Change_UI_Language_Case4Apps()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered(LANGUAGE_CHANGE) when changed UI language on HMI and app is FULL")

local function TC_APPLINK_18419_Change_UILanguage_AppIsFull()
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_UILanguage_AppIsFull_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_UILanguage_AppIsFull_ActivateApp")
	
	function Test: TC_APPLINK_18419_AppIsFull_OnAppInterfaceUnregistered_UI_LANGUAGE_CHANGE()
		--hmi side: sending UI.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage="FR-FR"})	
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsFull_Postcondition")
end 
TC_APPLINK_18419_Change_UILanguage_AppIsFull()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered(LANGUAGE_CHANGE) when changed UI language on HMI and app is LIMITED")

local function TC_APPLINK_18419_Change_UILanguage_AppIsLimited()
	
	function Test:TC_APPLINK_18419_Change_UILanguage_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_UILanguage_AppIsLimited_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_UILanguage_AppIsLimited_ActivateApp")
		
	function Test:TC_APPLINK_18419_Change_UILanguage_Bring_App_To_LIMITED()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18419_AppIsLimited_OnAppInterfaceUnregistered_UI_LANGUAGE_CHANGE()
		--hmi side: sending UI.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage="FR-FR"})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsLimited_Postcondition")
end 
TC_APPLINK_18419_Change_UILanguage_AppIsLimited()
---------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("TC_APPLINK_18419: OnAppInterfaceUnregistered(LANGUAGE_CHANGE) when changed UI language on HMI and app is BACKGROUND")

local function TC_APPLINK_18419_Change_UILanguage_AppIsBackground()
	
	function Test:TC_APPLINK_18419_Change_UILanguage_Change_App1_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18419_Change_UILanguage_AppIsBackground_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18419_Change_UILanguage_AppIsBackground_ActivateApp")
		
	function Test:TC_APPLINK_18419_Change_UILanguage_Bring_App_To_Background()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18419_AppIsLimited_OnAppInterfaceUnregistered_UI_LANGUAGE_CHANGE()
		--hmi side: sending UI.OnLanguageChange request to SDL
		self.hmiConnection:SendNotification("UI.OnLanguageChange", {language="FR-FR"})
		
		--hmi side: expect OnLanguageChange
		EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage="FR-FR"})	
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})	
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18419_Change_TTSVR_AppIsBackground_Postcondition")
end 
TC_APPLINK_18419_Change_UILanguage_AppIsBackground()

---------------------------------------------------------------------------------------------------------------
--APPLINK-18415
--Verification: OnAppInterfaceUnregistered notification with MASTER_RESET reason.
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18415: OnAppInterfaceUnregistered(reason:MASTER_RESET) when app is NONE")

local function TC_APPLINK_18415_AppIsNone()
 
	commonSteps:RegisterAppInterface("TC_APPLINK_18415_AppIsNone_RegisterApp")
	
	function Test: TC_APPLINK_18415_OnAppInterfaceUnregistered_MASTER_RESET()
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "MASTER_RESET"}})	
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18415_AppIsNone_Postcondition")
end

TC_APPLINK_18415_AppIsNone()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18415: OnAppInterfaceUnregistered(MASTER_RESET) with 4 apps")
 
local function TC_APPLINK_18415_Case4Apps()

	function Test:TC_APPLINK_18415_Case4Apps_Add_Second_Session()
		self:add_SecondSession()
	end

	function Test:TC_APPLINK_18415_Case4Apps_Add_Third_Session()
		self:add_ThirdSession()
	end

	function Test:TC_APPLINK_18415_Case4Apps_Add_Fourth_Session()
		self:add_FourthSession()
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
		
	commonSteps:RegisterAppInterface("TC_APPLINK_18415_Case4Apps_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18415_Case4Apps_ActivateApp")
	
	function Test:TC_APPLINK_18415_Case4Apps_Register_NonMedia_App()
		self:change_App_Params(2,{"DEFAULT"},false)
		self:registerAppInterface2()
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_Activate_NonMedia_App()
	        self:activate_App(2)
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_Register_NAVIGATION_App()
		self:change_App_Params(3,{"NAVIGATION"},false)
		self:registerAppInterface3()
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_Active_NAVIGATION_App()
		self:activate_App(3)
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_Register_The_Fourth_App()
		self:registerAppInterface4()
	end
	
	function Test:TC_APPLINK_18415_Case4Apps_OnAppInterfaceUnregistered_MASTER_RESET()
		self:onAppInterfaceUnregistered("MASTER_RESET",4)
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18415_Case4Apps_postcondition")
	
end 

TC_APPLINK_18415_Case4Apps()
-------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18415: OnAppInterfaceUnregistered(reason:MASTER_RESET) when app is FULL")

local function TC_APPLINK_18415_AppIsFull()
    
	commonSteps:RegisterAppInterface("TC_APPLINK_18415_AppIsFull_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18415_AppIsFull_ActivateApp")
	
	function Test: TC_APPLINK_18415_AppIsFull_OnAppInterfaceUnregistered_MASTER_RESET()
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "MASTER_RESET"}})	
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
	end
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18415_AppIsFull_Postcondition")
end

TC_APPLINK_18415_AppIsFull()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18415: OnAppInterfaceUnregistered(reason:MASTER_RESET) when app is LIMITED")

local function TC_APPLINK_18415_AppIsLimited()

	function Test:TC_APPLINK_18415_Change_UILanguage_Change_App1_To_Media()
		self:change_App_Params(1,{"MEDIA"},true)
	end
	
	commonSteps:RegisterAppInterface ("TC_APPLINK_18415_AppIsLimited_RegisterApp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18415_AppIsLimited_Activate_App")
	
	function Test:TC_APPLINK_18415_Change_UILanguage_Bring_App_To_Limited()
		self:bring_App_To_LIMITED_OR_BACKGROUND(true)
	end
	
	function Test: TC_APPLINK_18415_AppIsFull_OnAppInterfaceUnregistered_MASTER_RESET()
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "MASTER_RESET"}})	
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
	end
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18415_AppIsLimited_Postcondition")
end

TC_APPLINK_18415_AppIsLimited()
--------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("TC_APPLINK_18415: OnAppInterfaceUnregistered(reason:MASTER_RESET) when app is BACKGROUND")

local function TC_APPLINK_18415_AppIsBackground()

	function Test:TC_APPLINK_18415_Change_UILanguage_Change_App1_To_NonMedia()
		self:change_App_Params(1,{"DEFAULT"},false)
	end
	
	commonSteps:RegisterAppInterface ("TC_APPLINK_18415_AppIsBackground_RegisterAppp")
	commonSteps:ActivationApp(_,"TC_APPLINK_18415_AppIsBackground_ActivateApp")
	
	function Test:TC_APPLINK_18415_Change_UILanguage_Bring_App_To_Background()
		self:bring_App_To_LIMITED_OR_BACKGROUND(false)
	end
	
	function Test: TC_APPLINK_18415_AppIsBackground_OnAppInterfaceUnregistered_MASTER_RESET()
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
				
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect =  false})
				
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "MASTER_RESET"}})	
		
		--hmi side: expect to BasicCommunication.OnSDLClose
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
	end
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18415_AppIsBackground_Postcondition")
end

TC_APPLINK_18415_AppIsBackground()
------------------------------------------------------------------------------------------------------------
--APPLINK-18428
--Verification: OnAppInterfaceUnregistered notification with APP_UNAUTHORIZED reason if appName is wrong after PTU.
----------------------------------------------------------------------------------------------------------
--NOTE: This TC is blocked on ATF 2.2 by defect APPLINK-19188. Please try ATF on commit f86f26112e660914b3836c8d79002e50c7219f29

commonFunctions:newTestCasesGroup("TC_APPLINK_18428: OnAppInterfaceUnregistered(APP_UNAUTHORIZED ) after PTU, appName is wrong")

local function TC_APPLINK_18428_WrongAppName()

	function Test:TC_APPLINK_18428_WrongAppName_ChangeAppName()
		config.application1.registerAppInterfaceParams.appName = "WrongAppName" 
		config.application1.registerAppInterfaceParams.fullAppID = "18428_1" 
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18428_WrongAppName_RegisterApp")
	
	function Test:TC_APPLINK_18428_WrongAppName_ActivateApp()
	
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["WrongAppName"]})
		
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if
				data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage message response
				--TODO: update after resolving APPLINK-16094.
				--EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)						
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

					--hmi side: expect BasicCommunication.ActivateApp request
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						--hmi side: sending BasicCommunication.ActivateApp response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(AnyNumber())
				end)

			end
		end)
		
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	end
	
	function Test: TC_APPLINK_18428_WrongAppName_OnAppInterfaceUnregistered_APP_UNAUTHORIZED()
	
		--mobile side: sending SystemRequest request 
		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
																				{
																					fileName = "PolicyTableUpdate",
																					requestType = "PROPRIETARY"
																				},
																				"files/PTU_ForOnAppInterfaceUnregistered.json")

		--hmi side: expect SystemRequest request
		EXPECT_HMICALL("BasicCommunication.SystemRequest", {requestType = "PROPRIETARY",  fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
		:Do(function(_,data)
			systemRequestId = data.id
			
			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
			
			function to_run()
				--hmi side: sending SystemRequest response
				self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
			end
			
			RUN_AFTER(to_run, 500)
		end)
				
		--hmi side: expect SDL.OnAppPermissionChanged	
		EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.applications["WrongAppName"], appUnauthorized =  true, priority = "NONE"})
		:Do(function(_,data)

			--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
			local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppUnauthorized"}})
			
			--hmi side: expect SDL.GetUserFriendlyMessage response
			EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{
												line1 = "Not Authorized", 
												messageCode = "AppUnauthorized", 
												textBody = "This version of %appName% is no longer authorized to work with AppLink.  Please update to the latest version of %appName%.",
												ttsString = "This version of %appName% is not authorized and will not work with SYNC."}}}}) 
		end)
		
		--hmi side: expect BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["WrongAppName"], unexpectedDisconnect =  false})
				
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "APP_UNAUTHORIZED"}})
		
		EXPECT_HMICALL("BasicCommunication.UpdateAppList")
		:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
		end)
		:ValidIf (function(_,data)
			for _, app in pairs(data.params.applications) do
				if app.appID == self.applications["WrongAppName"] then	
					commonFunctions:printError(" Application is not removed on AppsList ")
					return false
				end				
			end
			
			return true
			
		end)			
		
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18428_WrongAppName")
	
end 

TC_APPLINK_18428_WrongAppName()

------------------------------------------------------------------------------------------------------------
--Requirement: SDLAQ-CRS-2388
--Verification: OnAppInterfaceUnregistered notification with APP_UNAUTHORIZED reason if app's permission is NULL after PTU.
----------------------------------------------------------------------------------------------------------
--NOTE: This TC is blocked on ATF 2.2 by defect APPLINK-19188. Please try ATF on commit f86f26112e660914b3836c8d79002e50c7219f29
--TODO: This TC need to be updated when APPLINK-21434 is completed. Currently, it works following SDLAQ-CRS-2388

commonFunctions:newTestCasesGroup("TC_APPLINK_18428: OnAppInterfaceUnregistered(APP_UNAUTHORIZED) after PTU and app's permission is NULL")

local function TC_APPLINK_18428_AppPermissionIsNull()
	
    function Test:TC_APPLINK_18428_AppPermissionIsNull_ChangeAppName()
		config.application1.registerAppInterfaceParams.appName = "AppNullPermission" 
		config.application1.registerAppInterfaceParams.fullAppID = "18428_2" 
	end
	
	commonSteps:RegisterAppInterface("TC_APPLINK_18428_AppPermissionIsNull_RegisterApp")
	
	function Test:TC_APPLINK_18428_AppPermissionIsNull_ActivateApp()
	
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["AppNullPermission"]})
		
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if
				data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage message response
				--TODO: update after resolving APPLINK-16094.
				--EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)						
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

					--hmi side: expect BasicCommunication.ActivateApp request
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						--hmi side: sending BasicCommunication.ActivateApp response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(AnyNumber())
				end)

			end
		end)
		
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	end
	
	function Test: TC_APPLINK_18428_AppPermissionIsNull_OnAppInterfaceUnregistered_APP_UNAUTHORIZED()
	
		--mobile side: sending SystemRequest request 
		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
																				{
																					fileName = "PolicyTableUpdate",
																					requestType = "PROPRIETARY"
																				},
																				"files/PTU_ForOnAppInterfaceUnregistered1.json")

		--hmi side: expect SystemRequest request
		EXPECT_HMICALL("BasicCommunication.SystemRequest", {requestType = "PROPRIETARY",  fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
		:Do(function(_,data)
			systemRequestId = data.id
			
			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
			
			function to_run()
				--hmi side: sending SystemRequest response
				self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
			end
			
			RUN_AFTER(to_run, 500)
		end)
			
		--hmi side: expect SDL.OnAppPermissionChanged	
		EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.applications["AppNullPermission"], appRevoked =  true, priority = "EMERGENCY"})
			:Do(function(_,data)
				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppUnsupported"}})
			
				--hmi side: expect BC.ActivateApp 
				EXPECT_HMICALL("BasicCommunication.ActivateApp",{appID=self.applications["AppNullPermission"],level="NONE",priority="NONE"})
				:Do(function(_,data)
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["AppNullPermission"]
						})
						
					--hmi side: sending Response to SDL
					self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS",{})
				end)	
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{
												line1 = "Not Supported", 
												messageCode = "AppUnsupported", 
												textBody = "Your version of %appName% is not supported by SYNC.",
												ttsString = "This version of %appName% is not supported by SYNC."}}}})
			end)
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"}) 
	end
	
	StopSDL_StartSDL_InitHMI_ConnectMobile("TC_APPLINK_18428_AppPermissionIsNull_Postcondition")
	
end 

TC_APPLINK_18428_AppPermissionIsNull()

--Write TEST_BLOCK_VI_End to ATF log	
commonFunctions:newTestCasesGroup("****************************** END TEST BLOCK VI ******************************")	

---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--All HMILevel is checked on TCs on TEST BLOCK VI