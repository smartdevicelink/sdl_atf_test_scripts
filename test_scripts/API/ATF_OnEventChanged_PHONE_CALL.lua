----------------------------------------------------------------------------------------------------------
--These TCs are created by APPLINK-15427, APPLINK-15164, APPLINK-9891 and APPLINK-18854. APPLINK-15164 is not implemeted now
--ATF version 2.2
----------------------------------------------------------------------------------------------------------
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
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
local CorIdAlert
local AlertId
local SpeakId
APIName = "onEventChanged" -- use for above required scripts.

---------------------------------------------------------------------------------------------
----------------------------------- Common Fuctions------------------------------------------
function Test:onEventChanged(enable,hmiLevel, audioStreamingState,case)
	--hmi side: send OnEventChanged (ON/OFF) notification to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= enable, eventName="PHONE_CALL"})

	if enable==true then
		--Case: There are 3  applications
		if case== 3 then
			--mobile side: expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			 self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end

		--Case: There is one  application
		if case== 1 then
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmiLevel, audioStreamingState = audioStreamingState, systemContext = "MAIN"})
		end
	end

	if enable==false then
		--Case: There are 3  applications
		if case==3 then
			--mobile side: expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end

		--Case: There is one  application
		if case== 1 then
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmilevel, audioStreamingState = audioStreamingState, systemContext = "MAIN"})
		end
	end
end
-----------------------------------------------------------------------------------------

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
-----------------------------------------------------------------------------------------

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
	self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	:Timeout(2000)
end
------------------------------------------------------------------------------------------------

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
------------------------------------------------------------------------------------------------

function Test: bring_App_To_LIMITED()
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications[config.application1.registerAppInterfaceParams.appName]
				})
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end
------------------------------------------------------------------------------------------------

function Test:start_VRSESSION(hmiLevel)
	self.hmiConnection:SendNotification("VR.Started")
	self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

	--mobile side: SDL send two notifications to mobile app
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmiLevel, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
end
------------------------------------------------------------------------------------------------

function Test:stop_VRSESSION(hmiLevel,audioStreamingState)
	--hmi side: send OnSystemContext
	self.hmiConnection:SendNotification("VR.Stopped")
	self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MAIN",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

	--mobile side: SDL send 1 notification to mobile app
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmiLevel, audioStreamingState = audioStreamingState, systemContext = "MAIN"})
end
------------------------------------------------------------------------------------------------

function Test:send_Alert(hmiLevel)
	--mobile side: Alert request
	CorIdAlert = self.mobileSession:SendRPC("Alert",
		{
			alertText1 = "alertText1",
			alertText2 = "alertText2",
			alertText3 = "alertText3",
			ttsChunks =
			{

				{
					text = "TTSChunk",
					type = "TEXT",
				}
			},
			duration = 5000,
			playTone = false,
			progressIndicator = true
		})

	--hmi side: UI.Alert request
	EXPECT_HMICALL("UI.Alert",
		{
			alertStrings =
			{
				{fieldName = "alertText1", fieldText = "alertText1"},
				{fieldName = "alertText2", fieldText = "alertText2"},
				{fieldName = "alertText3", fieldText = "alertText3"}
			},
			alertType = "BOTH",
			duration = 5000,
			progressIndicator = true
		})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="ALERT"})

		--store id for response in next Test.
		AlertId = data.id

	end)

	--hmi side: TTS.Speak request
	EXPECT_HMICALL("TTS.Speak",
			{
				ttsChunks =
				{

					{
						text = "TTSChunk",
						type = "TEXT"
					}
				},
				speakType = "ALERT"
			})
	:Do(function(_,data)

		--store id for response in next Test.
		SpeakId = data.id

		local function TTS_Started()
			self.hmiConnection:SendNotification("TTS.Started")
		end

		RUN_AFTER(TTS_Started, 500)

	end)
	:ValidIf(function(_,data)
		if #data.params.ttsChunks == 1 then
			return true
		else
			print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
			return false
		end
	end)

	--mobile side: Expected OnHMIStatus() notification
	EXPECT_NOTIFICATION("OnHMIStatus",
		{ systemContext = "ALERT", hmiLevel = hmiLevel, audioStreamingState = "AUDIBLE" },
		{ systemContext = "ALERT", hmiLevel = hmiLevel, audioStreamingState = "ATTENUATED"})
	:Times(2)
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1.Unregister app
	commonSteps:UnregisterApplication()

	--2. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

	--3.Create second session
	function Test:Precondition_SecondSession()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
	end

	--4.Create third session
	function Test:Precondition_SecondSession()
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

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------


--Verify OnEventChanged():
---- 1."isActive" is true/false
---- 2.Without "isActive" value
---- 3.With "isActive" is invalid/not existed/empty/wrongtype

	commonFunctions:newTestCasesGroup("Check normal cases of HMI notification")

	--After receiving BasicCommunication.OnEventChanged(PHONE_CALL,true) from HMI, SDL deactivates Navigation app from (FULL, AUDIBLE) to (LIMITED, NOT_AUDIBLE)
	--and deactivates Media/Communication/Non Media app to (BACKGROUND, NOT_AUDIBLE). Then SDL restore app's state when received OnEventChanged(PHONE_CALL, false).

	local testData ={
		{app = "NAVIGATION",			appType ={"NAVIGATION"},	isMedia=false,	hmiLevel="LIMITED", 	audioStreamingState="NOT_AUDIBLE"},
		{app= "MEDIA",					appType ={"MEDIA"},			isMedia=true,	hmiLevel="BACKGROUND", 	audioStreamingState="NOT_AUDIBLE"},
		{app="COMMUNICATION",	appType ={"COMMUNICATION"}, isMedia=false,	hmiLevel="BACKGROUND", 	audioStreamingState="NOT_AUDIBLE"},
		{app="NON MEDIA",	appType ={"DEFAULT"}, isMedia=false,	hmiLevel="BACKGROUND", 	audioStreamingState="NOT_AUDIBLE"}
	}

	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) with isActive: true then false")

		local function App_IsFull_PhoneCall_IsOn()

		    Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsFULL_isActiveIsValid"] = function(self)
				self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
			end

			commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsFULL_isActiveIsValid_RegisterApp")
			commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsFULL_isActiveIsValid_ActivateApp")

			Test[testData[i].app .."_CaseAppIsFULL_PhoneCallEvent_isActiveIsTrue"] = function(self)
				self:onEventChanged(true, testData[i].hmiLevel, testData[i].audioStreamingState,1)
			end

			Test[testData[i].app .."_CaseAppIsFULL_PhoneCallEvent_isActiveIsFalse"] = function(self)
				self:onEventChanged(false, "FULL", "AUDIBLE",1)
			end
		end

		App_IsFull_PhoneCall_IsOn()

		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsFULL_PhoneCallEvent_isActiveIsValid_Postcondition")
	end
	-------------------------------------------------------------------------------------------------------------------------------------------------------------

	--After receiving BasicCommunication.OnEventChanged(PHONE_CALL,true) from HMI, SDL deactivates Navigation app from (LIMITED, AUDIBLE) to (LIMITED, NOT_AUDIBLE)
	--and deactivates Media/Communication/Non Media app to (BACKGROUND, NOT_AUDIBLE). Then SDL restore app's state when received OnEventChanged(PHONE_CALL, false).

	for i =1, #testData-1 do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is LIMITED. HMI sends OnEventChanged(PHONE_CALL) with isActive: true then false")

		local function App_IsFull_PhoneCall_IsOn()

			 Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsLIMITED_isActiveIsValid"] = function(self)
				self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
			end

			commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsLIMITED_isActiveIsValid_RegisterApp")
			commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsLIMITED_isActiveIsValid_ActivateApp")

			Test[testData[i].app .."_CaseAppIsLIMITED_BringAppToLimited"]= function(self)
				self:bring_App_To_LIMITED()
			end

			Test[testData[i].app .."_CaseAppIsLIMITED_PhoneCallEvent_isActiveIsTrue"]= function(self)
				self:onEventChanged(true, testData[i].hmiLevel, testData[i].audioStreamingState,1)
			end

			--NOTE: This step only can run after APPLINK-15164 is DONE
			--Test[testData[i].app .."_CaseAppIsLIMITED_ActivateApp_WhilePhoneCallIsOn"]= function(self)
				-- local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

				-- EXPECT_HMIRESPONSE(rid)
				-- :Do(function(_,data)
					-- if data.result.code ~= 0 then
					-- quit()
					-- end
				-- end)

				-- --HMI expectes to receive OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) till APPLINK-15164 is DONE
				-- self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			-- end

			Test[testData[i].app .."_CaseAppIsLIMITED_PhoneCallEvent_isActiveIsFalse"]= function(self)
				self:onEventChanged(false, "LIMITED", "AUDIBLE",1)
				--NOTE: Currently, app returns LIMITED but after APPLINK-15164 is DONE, it should be FULL as below
				--self:onEventChanged(false, "FULL", "AUDIBLE",1)
			end

		end

		App_IsFull_PhoneCall_IsOn()

		--Poscontidion: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsLIMITED_PhoneCallEvent_isActiveIsValid_Postcondition")
	end
	----------------------------------------------------------------------------------------------------------------------------------

	--SDL doesn't deactivate Navigation app when receives BasicCommunication.OnEventChanged(PHONE_CALL) from HMI with invalid "isActive"

	local invalidValues = {	{value = nil,	name = "IsMissed"},
							{value = "", 	name = "IsEmtpy"},
							{value = "ANY", name = "NonExist"},
							{value = 123, 	name = "IsWrongDataType"}}

	for i = 1, #invalidValues  do

		for j=1,#testData do

			commonFunctions:newTestCasesGroup(testData[j].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) with isActive is " ..invalidValues[i].name)

			Test["Change_App1_Params_To" .. testData[j].app .."_isActive_"..invalidValues[i].name] = function(self)
				self:change_App_Params(1,testData[j].appType,testData[j].isMedia)
			end

			commonSteps:RegisterAppInterface(testData[j].app .."_isActive"..invalidValues[i].name.."_RegisterApp")
			commonSteps:ActivationApp(_,testData[j].app .."_isActive"..invalidValues[i].name.."_ActivateApp")

			Test[testData[j].app.."_PhoneCallEvent_isActive" .. invalidValues[i].name] = function(self)
				commonTestCases:DelayedExp(1000)
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="PHONE_CALL"})

				--mobile side: not expected OnHMIStatus
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[j].hmiLevel, audioStreamingState=testData[j].audioStreamingState, systemContext = "MAIN"})
				:Times(0)
			end

			--Poscontidion:Unregister app
			commonSteps:UnregisterApplication(testData[j].app .."_PhoneCallEvent_isActive"..invalidValues[i].name.."_Postcondition")
		end
	end

----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK IV--------------------------------------
----------------------------------Check special cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
--Verify OnEventChanged() with:
----1.InvalidJsonSyntax
----2.InvalidStructure
----3.Fake Params
----4.Fake Parameter Is From Another API
----5.Missed mandatory Parameters
----6.Missed All PArameters
----7.Several Notifications with the same values
----8.Several otifications with different values

--Write TEST BLOCK IV to ATF log
commonFunctions:newTestCasesGroup("****************************** TEST BLOCK IV: Check special cases of HMI notification ******************************")

	--SDL must not deactive app when receives BasicCommunication.OnEventChanged(PHONE_CALL) from HMI with InvalidJSonSyntax
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) is InvalidJSonSyntax")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_IsInvalidJSonSyntax"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_IsInvalidJSonSyntax_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_IsInvalidJSonSyntax_ActivateApp")

		Test[testData[i].app .."_OnEventChanged_IsInvalidJSonSyntax"] = function(self)
			commonTestCases:DelayedExp(1000)

			--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"PHONE_CALL"}}')
			self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"PHONE_CALL"}}')

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
			:Times(0)
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseOnEventChanged_IsInvalidJSonSyntax_Postcondition")
	end
	---------------------------------------------------------------------------------------------------------

	--SDL must not deactive app when receives BasicCommunication.OnEventChanged(PHONE_CALL) from HMI with InvalidStructure
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) is InvalidStructure")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_IsInvalidStructure"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_IsInvalidStructure_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_IsInvalidStructure_ActivateApp")

		Test[testData[i].app .."_OnEventChanged_InvalidStructure"] = function(self)
			commonTestCases:DelayedExp(1000)

			--method is moved into params parameter
			--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"PHONE_CALL"}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnEventChanged","isActive":true,"eventName":"PHONE_CALL"}}')

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
			:Times(0)
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseOnEventChanged_InvalidStructure_Postcondition")
	end
	---------------------------------------------------------------------------------------------------------

	--SDL must deactive app when receives BasicCommunication.OnEventChanged(PHONE_CALL,ON) from HMI with fake param
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) with fake param")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_WithFakeParam"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_WithFakeParam_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_WithFakeParam_ActivateApp")

		Test[testData[i].app .."_OnEventChanged_WithFakeParam"] = function(self)
			--HMI side: sending BasicCommunication.OnEventChanged with fake param
			self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"PHONE_CALL","fakeparam":123}}')

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
		end

		--Postcondition1: Send BC.OnEventChanged(PHONE_CALL,OFF)
		Test[testData[i].app .."_CaseOnEventChanged_WithFakeParam_Postcondition1"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end

		--Postcondition2: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseOnEventChanged_WithFakeParam_Postcondition2")
	end
	---------------------------------------------------------------------------------------------------------

	--SDL must not put deactivates app when receives BasicCommunication.OnEventChanged() from HMI without any params
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) without any params")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_WithoutParams"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_WithoutParams_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_WithoutParams_ActivateApp")

		Test[testData[i].app .."_OnEventChanged_WithoutParams"] = function(self)
			commonTestCases:DelayedExp(1000)
			--HMI side: sending BasicCommunication.OnEventChanged without any params
			self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{}}')

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
			:Times(0)
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_OnEventChanged_WithoutParams_Postcondition")
	end
	---------------------------------------------------------------------------------------------------------

	--After receiving several BasicCommunication.OnEventChanged(PHONE_CALL,ON) from HMI,SDL must deactivates app.Then SDL restores app when it receives several BasicCommunication.OnEventChanged(PHONE_CALL,OFF) from HMI
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_PhoneCall_SeveralTimes"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_PhoneCall_SeveralTimes_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_PhoneCall_SeveralTimes_ActivateApp")

		--Send several BasicCommunication.OnEventChanged(PHONE_CALL,true)
		Test[testData[i].app .."_Send_OnEventChanged_PhoneCallOn_SeveralTimes"] = function(self)
			--HMI side: sending several BasicCommunication.OnEventChanged without any param
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
		end

		--Send several BasicCommunication.OnEventChanged(PHONE_CALL,false)
		Test[testData[i].app .."_Send_OnEventChanged_PhoneCallOff_SeveralTimes"] = function(self)
			--HMI side: sending several BasicCommunication.OnEventChanged
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

			--mobile side: expect OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseOnEventChanged_PhoneCall_SeveralTimes_Postcondition")

	end
	---------------------------------------------------------------------------------------------------------

	--Description: SDL must put app to (LIMITED/BACKGROUND, NOT_AUDIBLE,MAIN) and restore to (FULL,AUDIBLE,MAIN) and then put (LIMITED/BACKGROUND, NOT_AUDIBLE,MAIN) again when it receives several different BasicCommunication.OnEventChanged(PHONE_CALL,ON/OFF/ON) from HMI
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is FULL. HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false/true")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseOnEventChanged_PhoneCallOnOffOn"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseOnEventChanged_PhoneCallOnOffOn_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseOnEventChanged_PhoneCallOnOffOn_ActivateApp")

		--Send several BasicCommunication.OnEventChanged(PHONE_CALL) with different "isActive" param
		Test[testData[i].app .."_SendOnEventChanged_PhoneCallOnOffOn"] = function(self)
			--HMI side: sending several BasicCommunication.OnEventChanged
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"},
																{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
																{hmiLevel=testData[i].hmiLevel, audioStreamingState=testData[i].audioStreamingState, systemContext = "MAIN"})
																:Times(3)
		end

		--Postcondition1: Send BC.OnEventChanged(PHONE_CALL,false)
		Test[testData[i].app .."_SendOnEventChanged_PhoneCallOnOffOn_Postcondition1"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end

		--Postcondition2: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_SendOnEventChanged_PhoneCallOnOffOn_Postcondition2")

	end

----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

-----------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--Verification:
----1.(FULL,AUDIBLE,MAIN): Already checked by HMIResponseCheck3.1
----2.(LIMITED,AUDIBLE,MAIN): Already checked by HMIResponseCheck3.2
----3.(FULL,NOT_AUDIBLE,VRSESSION)
----4.(LIMITED,NOT_AUDIBLE,VRSESSION)
----5.(FULL,ATTENUATED,ALERT)
----6.(LIMITED,ATTENUATED,ALERT)
----7.(BACKGROUND,NOT_AUDIBLE,MAIN)
----8.Three apps are at (LIMITED,AUDIBLE,MAIN)
----9.Two apps are at (LIMITED,AUDIBLE,MAIN), one app is at (FULL,AUDIBLE,MAIN)

	--Write TEST BLOCK VII to ATF log
	commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VII: Check with Different HMIStatus ******************************")

	--Navi app is at(FULL,NOT_AUDIBLE,VRSESSION), SDL must deactives navigation app to LIMITED and restore app to FULL when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI

	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is (FULL,NOT_AUDIBLE,VRSESSION). HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsFULL_VRSESSION"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsFULL_VRSESSION_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsFULL_VRSESSION_ActivateApp")

		Test[testData[i].app .."_CaseAppIsFULL_VRSESSION_StartVRSESSION"] = function(self)
			self:start_VRSESSION("FULL")
		end

		--Send OnventChanged(PHONE_CALL,ON) to SDL: App is changed to (LIMITED/BACKGROUND,NOT_AUDIBLE,VRSESSION)
		Test[testData[i].app .."_CaseAppIsFULL_VRSESSION_PhonCallIsOn"] = function(self)
			self:onEventChanged(true,testData[i].hmiLevel, testData[i].audioStreamingState,1)
		end

		--Send OnventChanged(PHONE_CALL,OFF) to SDL: App is changed to (FULL,NOT_AUDIBLE,VRSESSION)
		Test[testData[i].app .."_CaseAppIsFULL_VRSESSION_PhonCallIsOff"] = function(self)
			self:onEventChanged(false,"FULL","NOT_AUDIBLE",1)
		end

		Test[testData[i].app .."_CaseAppIsFULL_VRSESSION_StopVRSESSION"] = function(self)
			if i==4 then
				self:stop_VRSESSION("FULL","NOT_AUDIBLE")
			else self:stop_VRSESSION("FULL","AUDIBLE") end
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsFULL_VRSESSION_Postcondition")
	end
	----------------------------------------------------------------------------------------------------------

	--Media/Commnucation app is at (LIMITED,NOT_AUDIBLE,VRSESSION), SDL must change app to(BACKGROUND,NOT_AUDIBLE,VRSESSION) and restore when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI

	for i =2, #testData-1 do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is (LIMITED,NOT_AUDIBLE,VRSESSION). HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsLIMITED_VRSESSION"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsLIMITED_VRSESSION_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsFULL_VRSESSION_ActivateApp")

		Test[testData[i].app .."_CaseAppIsLIMITED_VRSESSION_BringAppToLimited"] = function(self)
			self:bring_App_To_LIMITED()
		end

		Test[testData[i].app .."_CaseAppIsLIMITED_VRSESSION_StartVRSESSION"] = function(self)
			self:start_VRSESSION("LIMITED")
		end

		--Send OnventChanged(PHONE_CALL,ON) to SDL: App is changed to (BACKGROUND,NOT_AUDIBLE,VRSESSION)
		Test[testData[i].app .."_CaseAppIsLIMITED_VRSESSION_PhonCallIsOn"] = function(self)
			self:onEventChanged(true,testData[i].hmiLevel, testData[i].audioStreamingState,1)
		end

		--Send OnventChanged(PHONE_CALL,OFF) to SDL: App is (LIMITED,NOT_AUDIBLE,VRSESSION)
		Test[testData[i].app .."_CaseAppIsLIMITED_VRSESSION_PhonCallIsOff"] = function(self)
			self:onEventChanged(false,"LIMITED", "NOT_AUDIBLE",1)
		end

		Test[testData[i].app .."_CaseAppIsLIMITED_VRSESSION_StopVRSESSION"] = function(self)
			self:stop_VRSESSION("LIMITED","AUDIBLE")
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsLIMITED_VRSESSION_Poscontidion")

	end
	-----------------------------------------------------------------------------------------------------------

	--Navigation app is at (LIMITED,NOT_AUDIBLE,VRSESSION), SDL must not change app's state when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI

	commonFunctions:newTestCasesGroup("Navigation app is at (LIMITED,NOT_AUDIBLE,VRSESSION)")

	Test["Change_App1_Params_To_NAVIGATION_CaseAppIsLIMITED_VRSESSION"] = function(self)
		self:change_App_Params(1,{"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("NAVIGATION_CaseAppIsLIMITED_VRSESSION_RegisterApp")
	commonSteps:ActivationApp(_,"NAVIGATION_CaseAppIsLIMITED_VRSESSION_ActivateApp")

	Test["NAVIGATION_CaseAppIsLIMITED_VRSESSION_BringAppToLIMITED"] = function(self)
		self:bring_App_To_LIMITED()
	end

	--Start VRSESSION: App is changed to (LIMITED,NOT_AUDIBLE,VRSESSION)
	Test["NAVIGATION_CaseAppIsLIMITED_VRSESSION_StartVRSESSION"] = function(self)
		self:start_VRSESSION("LIMITED")
	end

	--Send OnventChanged(PHONE_CALL,ON) to SDL: App still be(LIMITED,NOT_AUDIBLE,VRSESSION)
	Test["NAVIGATION_CaseAppIsLIMITED_VRSESSION_PhoneCallIsOn"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
		:Times(0)
		commonTestCases:DelayedExp(1000)
	end

	--Send OnventChanged(PHONE_CALL,OFF) to SDL: App is changed to (LIMITED,NOT_AUDIBLE,VRSESSION)
	Test["NAVIGATION_CaseAppIsLIMITED_VRSESSION_PhoneCallIsOff"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"})
		:Times(0)
		commonTestCases:DelayedExp(1000)
	end

	Test["NAVIGATION_CaseAppIsLIMITED_VRSESSION_StopVRSESSION"] = function(self)
		self:stop_VRSESSION("LIMITED")
	end

	--Postcondition: Unregister app
	commonSteps:UnregisterApplication("NAVIGATION_CaseAppIsLIMITED_VRSESSION_Postcondition")
	-----------------------------------------------------------------------------------------------------------
	--App is (LIMITED,ATTENUATED,ALERT), SDL must change app's state to (LIMITED/BACKGROUND,NOT_AUDIBLE,ALERT)  when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI

	for i =1, #testData-1 do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is (LIMITED,ATTENUATED,ALERT). HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsLIMITED_ATTENUATED"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_ActivateApp")

		Test[testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_BringAppToLIMITED"] = function(self)
			self:bring_App_To_LIMITED()
		end

		--Send Alert() to bring app to (LIMITED,ATTENUATED,ALERT)
		Test[testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_SendAlert"] = function(self)
			--mobile side: Alert request
			CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT",
								}
							},
							duration = 5000,
							playTone = false,
							progressIndicator = true
						})


			--hmi side: UI.Alert request
			EXPECT_HMICALL("UI.Alert",
						{
							alertStrings =
							{
								{fieldName = "alertText1", fieldText = "alertText1"},
								{fieldName = "alertText2", fieldText = "alertText2"},
								{fieldName = "alertText3", fieldText = "alertText3"}
							},
							alertType = "BOTH",
							duration = 5000,
							progressIndicator = true
						})
				:Do(function(_,data)
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="ALERT"})

					--store id for response in next Test.
					AlertId = data.id

				end)

			--hmi side: TTS.Speak request
			EXPECT_HMICALL("TTS.Speak",
						{
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT"
								}
							},
							speakType = "ALERT"
						})
				:Do(function(_,data)

					--store id for response in next Test.
					SpeakId = data.id

					local function TTS_Started()
						self.hmiConnection:SendNotification("TTS.Started")
					end

					RUN_AFTER(TTS_Started, 500)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
				end)

			--mobile side: Expected OnHMIStatus() notification
			EXPECT_NOTIFICATION("OnHMIStatus",
				{ systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" },
				{ systemContext = "ALERT", hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED"})
				:Times(2)
		end

		--Send Emergency_Event(ON) during Alert(): App is changed to (LIMITED,NOT_AUDIBLE,ALERT) or (BACKGROUND,NOT_AUDIBLE,ALERT)
		Test[testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_PhonCallIsOn"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

			--mobile side: Expected OnHMIStatus() notification
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "ALERT", hmiLevel=testData[i].hmiLevel,audioStreamingState=testData[i].audioStreamingState})
		end

		--Send Response to Alert(): App is changed to (LIMITED,NOT_AUDIBLE,MAIN) or (BACKGROUND,NOT_AUDIBLE,MAIN)
		Test[testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_PhonCallIsOn_HMI_Response_ForAlert"] = function(self)
			--UI response
			self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="MAIN"})
			--SendOnSystemContext(self,"MAIN")


			--TTS response
			self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

			self.hmiConnection:SendNotification("TTS.Stopped")

			--HMI receiced StopSpeaking
			EXPECT_HMICALL("TTS.StopSpeaking")
			:Do(function(_,data)

					 --TTS StopSpeaking response
					self.hmiConnection:SendResponse(data.id,"TTS.StopSpeaking", "SUCCESS",{})
				end)

			--mobile side: Expected OnHMIStatus() notification
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel=testData[i].hmiLevel,audioStreamingState=testData[i].audioStreamingState})

			--mobile side: Alert response
			EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

		end

		--Send Emergency_Event(OFF): App is changed to (FULL,AUDIBLE,MAIN)
		Test[testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_PhonCallIsOff"] = function(self)
			self:onEventChanged(false,"LIMITED", "AUDIBLE",1)
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsLIMITED_ATTENUATED_Postcondition")
	end
	--------------------------------------------------------------------------------------------------------------------
	--App is (FULL,ATTENUATED/NOT_AUDIBLE,ALERT), SDL must change app's state to (LIMITED/BACKGROUND,NOT_AUDIBLE,ALERT) when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI
	for i =1, #testData do

		commonFunctions:newTestCasesGroup(testData[i].app.." app is (FULL,ATTENUATED,ALERT). HMI sends OnEventChanged(PHONE_CALL) with isActive:true/false")

		Test["Change_App1_Params_To" .. testData[i].app .."_CaseAppIsFULL_ATTENUATED"] = function(self)
			self:change_App_Params(1,testData[i].appType,testData[i].isMedia)
		end

		commonSteps:RegisterAppInterface(testData[i].app .."_CaseAppIsFULL_ATTENUATED_RegisterApp")
		commonSteps:ActivationApp(_,testData[i].app .."_CaseAppIsFULL_ATTENUATED_ActivateApp")

		--Send Alert() to bring app to (FULL,ATTENUATED,ALERT)
		Test[testData[i].app .."_CaseAppIsFULL_ATTENUATED_SendAlert"] = function(self)
			--mobile side: Alert request
			CorIdAlert = self.mobileSession:SendRPC("Alert",
						{
							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT",
								}
							},
							duration = 5000,
							playTone = false,
							progressIndicator = true
						})


			--hmi side: UI.Alert request
			EXPECT_HMICALL("UI.Alert",
						{
							alertStrings =
							{
								{fieldName = "alertText1", fieldText = "alertText1"},
								{fieldName = "alertText2", fieldText = "alertText2"},
								{fieldName = "alertText3", fieldText = "alertText3"}
							},
							alertType = "BOTH",
							duration = 5000,
							progressIndicator = true
						})
				:Do(function(_,data)
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="ALERT"})

					--store id for response in next Test.
					AlertId = data.id

				end)

			--hmi side: TTS.Speak request
			EXPECT_HMICALL("TTS.Speak",
						{
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT"
								}
							},
							speakType = "ALERT"
						})
				:Do(function(_,data)

					--store id for response in next Test.
					SpeakId = data.id

					local function TTS_Started()
						self.hmiConnection:SendNotification("TTS.Started")
					end

					RUN_AFTER(TTS_Started, 500)

				end)
				:ValidIf(function(_,data)
					if #data.params.ttsChunks == 1 then
						return true
					else
						print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
						return false
					end
				end)

			if i==4 then
				EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
			else
				--mobile side: Expected OnHMIStatus() notification
				EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
					{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"})
					:Times(2)
			end
		end

		--Send OnEventChanged(PHONE_CALL,ON) during Alert(): App is changed to (LIMITED,NOT_AUDIBLE,ALERT) or (BACKGROUND,NOT_AUDIBLE,ALERT)
		Test[testData[i].app .."_CaseAppIsFULL_ATTENUATED_PhonCallIsOn"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			--mobile side: Expected OnHMIStatus() notification
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "ALERT", hmiLevel=testData[i].hmiLevel,audioStreamingState=testData[i].audioStreamingState})
		end

		--Send Response to Alert(): App is changed to (LIMITED,NOT_AUDIBLE,MAIN) or (BACKGROUND,NOT_AUDIBLE,MAIN)
		Test[testData[i].app .."_CaseAppIsFULL_ATTENUATED_PhonCallIsOn_HMI_Response_ForAlert"] = function(self)
			--UI response
			self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext="MAIN"})

			--TTS response
			self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
			self.hmiConnection:SendNotification("TTS.Stopped")

			--HMI receiced StopSpeaking
			EXPECT_HMICALL("TTS.StopSpeaking")
			:Do(function(_,data)

					 --TTS StopSpeaking response
					self.hmiConnection:SendResponse(data.id,"TTS.StopSpeaking", "SUCCESS",{})
				end)

			--mobile side: Expected OnHMIStatus() notification
			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel=testData[i].hmiLevel,audioStreamingState=testData[i].audioStreamingState})

			--mobile side: Alert response
			EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
		end

		--Send --Send OnEventChanged(PHONE_CALL,OFF): App is changed to (FULL,AUDIBLE,MAIN)
		Test[testData[i].app .."_CaseAppIsFULL_ATTENUATED_PhonCallIsOff"] = function(self)
			if i==4 then
				self:onEventChanged(false,"FULL", "NOT_AUDIBLE",1)
			else self:onEventChanged(false,"FULL", "AUDIBLE",1) end
		end

		--Postcondition: Unregister app
		commonSteps:UnregisterApplication(testData[i].app .."_CaseAppIsFULL_ATTENUATED_Postcondition")
	end
	--------------------------------------------------------------------------------------------------------------------

	--App is at BACKGROUND, SDL must not send OnHMIStatus() to  app when it receices OnEventChanged(PHONE_CALL,ON/OFF) from HMI
	commonFunctions:newTestCasesGroup("App is at (BACKGROUND,NOT_AUDIBLE,MAIN)")

	function Test:Change_App1_Params_To_NonMedia()
		self:change_App_Params(1,{"SOCIAL"},false)
	end

	commonSteps:RegisterAppInterface("RegisterSocialApp")
	commonSteps:ActivationApp(_,"ActivateSocialApp")

	function Test:Change_Social_To_BACKGROUND()
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName]
			})

		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseSocialApp_PhoneCallOn_In_BACKGROUND()
		--hmi side: send OnEventChanged(Phone_Call, isActive= true) notification to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

		--Expect OnHMIStatus notification is not sent to BACKGROUND app
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:Times(0)
		commonTestCases:DelayedExp(1000)
	end

	function Test:CaseSocialApp_PhoneCallOff_In_BACKGROUND()
		--hmi side: send OnEventChanged(Phone_Call, isActive= true) notification to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

		--Expect OnHMIStatus notification is not sent to BACKGROUND app
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:Times(0)
		commonTestCases:DelayedExp(1000)
	end

	commonSteps:UnregisterApplication("CaseSocialApp_PhoneCallOff_In_BACKGROUND_Postcondition")
	------------------------------------------------------------------------------------------------------------------

	--NAVI,MEDIA and VOICE COM apps are LIMITED and try to activate Navi app during PHONE CALL >> SDL sends OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) to Navi app.
	--After PHONE_CALL is OFF, SDL sends OnHMIStatus(FULL,AUDIBLE,MAIN) to Navi app

	commonFunctions:newTestCasesGroup("Navi,Media and Communication apps are(LIMITED,AUDIBLE,MAIN) and try to activate Navi app during PHONE CALL")

	function Test:Change_App1_To_NavigationApp()
		self:change_App_Params(1,{"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("Register_Navigation_App")
	commonSteps:ActivationApp(_,"Activate_Navigation_App")

	function Test: Register_Communication_App()
		self:change_App_Params(2,{"COMMUNICATION"},false)
		self:registerAppInterface2()
	end

	function Test: Activate_Communication_App()

		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	end

	function Test: Register_Media_App()
		self:change_App_Params(3,{"MEDIA"},true)
		self:registerAppInterface3()
	end

	function Test: Activate_Media_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test: Bring_MediaApp_To_LIMITED()
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[config.application3.registerAppInterfaceParams.appName]
		})

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end


	function Test:CaseAppsAreLIMITED_PhoneCallIsOn()
		self:onEventChanged(true,"LIMITED", "AUDIBLE",3)
	end

	--NOTE: This step only can run after APPLINK-15164 is DONE
	-- function Test: CaseAppsAreLIMITED_Activate_Navigation_App_During_PHONE_CALL()
		-- local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		-- EXPECT_HMIRESPONSE(rid)
		-- :Do(function(_,data)
			-- if data.result.code ~= 0 then
			-- quit()
			-- end
		-- end)

		-- --HMI expectes to receive OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) till APPLINK-15164 is DONE
		-- self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	-- end

	function Test:CaseAppsAreLIMITED_PhoneCallIsOff()
		self:onEventChanged(false,"LIMITED", "AUDIBLE",3)
		--NOTE: After APPLINK-15164 is DONE, the expected notification should be like below
		--self:onEventChanged(false, "FULL", "AUDIBLE",3)
	end

	function Test:CaseAppsAreLIMITED_Postcondition_Unregister_All_Apps()
			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
			self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
			self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end
	-------------------------------------------------------------------------------------------------------------------------------

	--MEDIA and VOICE COM apps are LIMITED. NAVI app is FULL and try to activate Media app during PHONE CALL >> SDL sends OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) to MEDIA app.
	--After PHONE_CALL is OFF, SDL sends OnHMIStatus(FULL,AUDIBLE,MAIN) to MEDIA app

	commonFunctions:newTestCasesGroup("Media and Communication apps are(LIMITED,AUDIBLE,MAIN). Navi app is(FULL, AUDIBLE,MAIN) and try to activate Media app during PHONE CALL.")

	function Test:CaseActivateMedia_Change_App1_ToNaviApp()
		self:change_App_Params(1,{"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("CaseActivateMedia_RegisterNaviApp")

	function Test:CaseActivateMedia_Register_Communication_App()
		self:change_App_Params(2,{"COMMUNICATION"},false)
		self:registerAppInterface2()
	end

	function Test:CaseActivateMedia_Activate_Communication_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateMedia_Register_MEDIA_App()
		self:change_App_Params(3,{"MEDIA"},true)
		self:registerAppInterface3()
	end

	function Test:CaseActivateMedia_Activate_MEDIA_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateMedia_Activate_NAVIGATION_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateMedia_PhoneCallIsON()
		self:onEventChanged(true,"LIMITED", "NOT_AUDIBLE",3)
	end

	--NOTE: This step only can run after APPLINK-15164 is DONE
	-- function Test:CaseNaviAppIsFULL_Activate_Media_App_During_PHONE_CALL()
		-- local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		-- EXPECT_HMIRESPONSE(rid)
		-- :Do(function(_,data)
			-- if data.result.code ~= 0 then
			-- quit()
			-- end
		-- end)

		-- --HMI expectes to receive OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) till APPLINK-15164 is DONE
		-- self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	-- end

	function Test:CaseActivateMedia_PhoneCallIsOff()
		self:onEventChanged(false,"FULL", "AUDIBLE",3)

		--NOTE: After APPLINK-15164 is DONE, the expected notification should be like below
		-- self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

		--Expect notifications on mobile sides
		-- self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		-- self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		-- self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateMedia_Postcondition_Unregister_All_Apps()
			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
			self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
			self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end
	--------------------------------------------------------------------------------------------------
	--MEDIA and VOICE COM apps are LIMITED. NAVI app is FULL and try to activate VOICE COM app during PHONE CALL >> SDL sends OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) to VOICE COM app.
	--After PHONE_CALL is OFF, SDL sends OnHMIStatus(FULL,AUDIBLE,MAIN) to VOICE COM app

	commonFunctions:newTestCasesGroup("Media and Communication apps are(LIMITED,AUDIBLE,MAIN). Navi app is(FULL, AUDIBLE,MAIN) and try to activate VOICE COM app during PHONE CALL.")

	function Test:CaseActivateVOICECOM_Change_App1_ToNaviApp()
		self:change_App_Params(1,{"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("CaseActivateVOICECOM_RegisterNaviApp")

	function Test:CaseActivateVOICECOM_Register_COMMUNICATION_App()
		self:change_App_Params(2,{"COMMUNICATION"},false)
		self:registerAppInterface2()
	end

	function Test:CaseActivateVOICECOM_Activate_COMMUNICATION_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateVOICECOM_Register_MEDIA_App()
		self:change_App_Params(3,{"MEDIA"},true)
		self:registerAppInterface3()
	end

	function Test:CaseActivateVOICECOM_Activate_MEDIA_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateVOICECOM_Activate_NAVIGATION_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateVOICECOM_PhoneCallIsOn()
		self:onEventChanged(true,"LIMITED", "NOT_AUDIBLE",3)
	end

	--NOTE: This step only can run after APPLINK-15164 is DONE
	-- function Test:CaseActivateVOICECOM_Activate_VOICECOM_App_During_PHONE_CALL()
		-- local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		-- EXPECT_HMIRESPONSE(rid)
		-- :Do(function(_,data)
			-- if data.result.code ~= 0 then
			-- quit()
			-- end
		-- end)

		-- --HMI expectes to receive OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) till APPLINK-15164 is DONE
		-- self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	-- end

	function Test:CaseActivateVOICECOM_PhoneCallIsOff()
		self:onEventChanged(false,"FULL", "AUDIBLE",3)

		--NOTE: After APPLINK-15164 is DONE, the expected notification should be like below
		-- self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

		--Expect notifications on mobile sides
		--self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		--self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		-- self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateVOICECOM_Postcondition_Unregister_All_Apps()
			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
			self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
			self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

			local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end
	---------------------------------------------------------------------------------------------------------------------------------

    --VOICE COM app is at LIMITED, NAVI is FULL, NON MEDIA is BACKGROUND and try to activate NON MEDIA app >> SDL sends OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) NON MEDIA app

	commonFunctions:newTestCasesGroup("Communication apps are(LIMITED,AUDIBLE,MAIN). Navi app is(FULL, AUDIBLE,MAIN), Non Media is(BACKGROUND,NOT_AUDIBLE, MAIN) and try to activate NON MEDIA app during PHONE CALL.")

	function Test:CaseActivateNONMEDIA_Change_App1_ToNaviApp()
		self:change_App_Params(1,{"NAVIGATION"},false)
	end

	commonSteps:RegisterAppInterface("CaseActivateNONMEDIA_RegisterNaviApp")

	function Test:CaseActivateNONMEDIA_Register_COMMUNICATION_App()
		self:change_App_Params(2,{"COMMUNICATION"},false)
		self:registerAppInterface2()
	end

	function Test:CaseActivateNONMEDIA_Activate_COMMUNICATION_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateNONMEDIA_Register_NONMEDIA_App()
		self:change_App_Params(3,{"DEFAULT"},false)
		self:registerAppInterface3()
	end

	function Test:CaseActivateNONMEDIA_Activate_NONMEDIA_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateNONMEDIA_Activate_NAVIGATION_App()
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseActivateNONMEDIA_PhoneCallIsOn()
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})

		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	--NOTE: This step only can run after APPLINK-15164 is DONE
	-- function Test:CaseActivateNONMEDIA_Activate_NONMEDIA_App_During_PHONE_CALL()
		-- local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})

		-- EXPECT_HMIRESPONSE(rid)
		-- :Do(function(_,data)
			-- if data.result.code ~= 0 then
			-- quit()
			-- end
		-- end)

		-- --HMI expectes to receive OnHMIStatus(FULL,NOT_AUDIBLE,MAIN) till APPLINK-15164 is DONE
		-- self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	-- end

	function Test:CaseActivateVOICECOM_PhoneCallIsOff()
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})

		--Expect notifications on mobile sides
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

		--NOTE: After APPLINK-15164 is DONE, the expected notification should be like below
		--Expect notifications on mobile sides
		--self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		--self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
