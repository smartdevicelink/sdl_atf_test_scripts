--Goal: Test is covering resumption of data while more than on application is registered
--Requirement id in JAMA/or Jira ID: APPLINK-15987
--[Data Resumption] Application data must not be resumed 
--Requirement id in JAMA/or Jira ID: APPLINK-15958 	
--[Data Resumption] hmi_appID must be the same for the application between ignition cycles 
--Requirement id in JAMA/or Jira ID: APPLINK-15657 	
--[Data Resumption]: Data resumption on Unexpected Disconnect 
--Requirement id in JAMA/or Jira ID: APPLINK-15634
--[Data Resumption]: Data resumption on IGNITION OFF 
--Requirement id in JAMA/or Jira ID: APPLINK-15683
--[Data Resumption]: SDL data resumption SUCCESS sequence 
--Requirement id in JAMA/or Jira ID: APPLINK-15670
--[Data Resumption]: RegisterAppInterface with hashID the same as stored before 
--Requirement id in JAMA/or Jira ID: APPLINK-15930
--[Data Resumption]:Database for resumption-related data 

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps     = require('user_modules/shared_testcases/commonSteps')

commonSteps:DeleteLogsFileAndPolicyTable()
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- Postcondition: removing user_modules/connecttest_resumption.lua
function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

--Precondition: backup smartDeviceLink.ini
commonPreconditions:BackupFile("smartDeviceLink.ini")

-- set  ApplicationResumingTimeout in .ini file to 3000;
commonFunctions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s?=%s-[%d]-%s-\n", "ApplicationResumingTimeout", 5000)

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local HMIAppIDNonMediaApp
local HMIAppIDMediaApp
local HMIAppIDNaviApp
local HMIAppIDComApp
local HMIAppID
local TimeToStartTimer

local timeFromRequestToNot = 0

local AppValuesOnHMIStatusFULL 
local AppValuesOnHMIStatusLIMITED 

local AppValuesOnHMIStatusDEFAULTMediaApp
local AppValuesOnHMIStatusDEFAULTNonMediaApp
local AppValuesOnHMIStatusDEFAULTNavigationApp
local AppValuesOnHMIStatusDEFAULTCommunicationApp

AppValuesOnHMIStatusDEFAULTMediaApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
AppValuesOnHMIStatusDEFAULTNonMediaApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
AppValuesOnHMIStatusDEFAULTNavigationApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
AppValuesOnHMIStatusDEFAULTCommunicationApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}

local applicationData = 
{
	mediaApp = {
				syncMsgVersion =
								{
		  							majorVersion = 3,
		  							minorVersion = 3
								},
				appName = "TestAppMedia",
				isMediaApplication = true,
				languageDesired = 'EN-US',
				hmiDisplayLanguageDesired = 'EN-US',
				appHMIType = { "DEFAULT" },
				appID = "0000002",
				deviceInfo =
							{
		  						os = "Android",
		  						carrier = "Megafon",
		  						firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  						osVersion = "4.4.2",
		  						maxNumberRFCOMMPorts = 1
							}
	  		},
	
	nonmediaApp = {
					syncMsgVersion =
									{
		  								majorVersion = 3,
		  								minorVersion = 3
									},
					appName = "TestAppNonMedia",
					isMediaApplication = false,
					languageDesired = 'EN-US',
					hmiDisplayLanguageDesired = 'EN-US',
					appHMIType = { "DEFAULT" },
		appID = "0000003",
		deviceInfo =
		{
		  os = "Android",
		  carrier = "Megafon",
		  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  osVersion = "4.4.2",
		  maxNumberRFCOMMPorts = 1
		}
	  },
	  navigationApp = {
		syncMsgVersion =
		{
		  majorVersion = 3,
		  minorVersion = 3
		},
		appName = "TestAppNavigation",
		isMediaApplication = false,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "NAVIGATION" },
		appID = "0000004",
		deviceInfo =
		{
		  os = "Android",
		  carrier = "Megafon",
		  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  osVersion = "4.4.2",
		  maxNumberRFCOMMPorts = 1
		}
	  },
	  communicationApp = {
		syncMsgVersion =
		{
		  majorVersion = 3,
		  minorVersion = 3
		},
		appName = "TestAppCommunication",
		isMediaApplication = false,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "COMMUNICATION" },
		appID = "0000005",
		deviceInfo =
		{
		  os = "Android",
		  carrier = "Megafon",
		  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  osVersion = "4.4.2",
		  maxNumberRFCOMMPorts = 1
		}
	  }
}

if 
	  config.application1.registerAppInterfaceParams.isMediaApplication == true or
	  Test.appHMITypes["NAVIGATION"] == true or
	  Test.appHMITypes["COMMUNICATION"] == true then
		AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
		AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
elseif (config.application1.registerAppInterfaceParams.isMediaApplication == false) then
	AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
end

local function userPrint( color, message)
	
  	print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end
	
function DelayedExp(time)
		local event = events.Event()
		event.matches = function(self, e) return self == e end
		
		EXPECT_EVENT(event, "Delayed event")
		:Timeout(time+1000)
		
		RUN_AFTER(function()
		
		RAISE_EVENT(event, event)
		end, time)
end
	
local function IGNITION_OFF(self, appNumber)
		StopSDL()

		if appNumber == nil then 
			appNumber = 1
		end

		-- hmi side: sends OnExitAllApplications (SUSPENDED)
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
			reason = "IGNITION_OFF"
		})

		-- hmi side: expect OnSDLClose notification
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

		-- hmi side: expect OnAppUnregistered notification
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
		:Times(appNumber)
end

local function ActivationApp(self, AppID)

		if notificationState.VRSession == true then
			self.hmiConnection:SendNotification("VR.Stopped", {})
		elseif 
		  notificationState.EmergencyEvent == true then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
		elseif
		  notificationState.PhoneCall == true then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
		end

		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = AppID})

		--hmi side: expect SDL.ActivateApp response
		EXPECT_HMIRESPONSE(RequestId)
		  :Do(function(_,data)
			--In case when app is not allowed, it is needed to allow app
			  if
				  data.result.isSDLAllowed ~= true then

					--hmi side: sending SDL.GetUserFriendlyMessage request
					  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
							  {language = "EN-US", messageCodes = {"DataConsent"}})

					  --hmi side: expect SDL.GetUserFriendlyMessage response
					  --TODO: comment until resolving APPLINK-16094
					-- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					EXPECT_HMIRESPONSE(RequestId)
						  :Do(function(_,data)

						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
						  {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

						--hmi side: expect BasicCommunication.ActivateApp request
						  EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)

							  --hmi side: sending BasicCommunication.ActivateApp response
							  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

						  end)
						  :Times(2)
						  end)

			end
			  end)

end

local function SUSPEND(self, targetLevel)

	  if 
		  (targetLevel == "LIMITED" and
		  self.hmiLevel == "LIMITED") or
		  (targetLevel == "FULL" and
		  self.hmiLevel == "FULL") or
		  targetLevel == nil then
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
			  {
				reason = "SUSPEND"
			  })

			--hmi side: expect OnSDLPersistenceComplete notification
			EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
		end
end

local function AddCommand(self, icmdID, session)
	  --mobile side: sending AddCommand request
	  local cid = session:SendRPC("AddCommand",
	  {
		cmdID = icmdID,
		menuParams =  
		{
		  position = 0,
		  menuName ="Command" .. tostring(icmdID)
		}, 
		vrCommands = {"VRCommand" .. tostring(icmdID)}
	  })
	  
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
		  cmdID = icmdID,   
		  menuParams = 
		  {
			position = 0,
			menuName ="Command" .. tostring(icmdID)
		  }
		})
		:Do(function(_,data)
		  --hmi side: sending UI.AddCommand response 
		  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
		  cmdID = icmdID,             
		  type = "Command",
		  vrCommands = 
		  {
			"VRCommand" .. tostring(icmdID)
		  }
		})
		:Do(function(_,data)
		  --hmi side: sending VR.AddCommand response 
		  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)  
	  
	  --mobile side: expect AddCommand response 
		session:ExpectResponse(cid, {  success = true, resultCode = "SUCCESS"  })
		:Do(function()
		  --mobile side: expect OnHashChange notification
		  --Requirement id in JAMA/or Jira ID: APPLINK-15682
		  --[Data Resumption]: OnHashChange 
		  session:ExpectNotification("OnHashChange",{})
			:Do(function(_, data)
			  if 
				session == self.mobileSession then
				  self.currentHashID = data.payload.hashID
			  elseif
				session == self.mobileSession2 then
				  self.currentHashID2 = data.payload.hashID
			  elseif
				session == self.mobileSession3 then
				  self.currentHashID3 = data.payload.hashID
			  elseif
				session == self.mobileSession4 then
				  self.currentHashID4 = data.payload.hashID
			  elseif
				session == self.mobileSession5 then
				  self.currentHashID5 = data.payload.hashID
			  end
			end)
		end)
end

local function AddSubMenu(self, imenuID)
		--mobile side: sending AddSubMenu request
		local cid = session:SendRPC("AddSubMenu",
						  {
							menuID = imenuID,
							position = 500,
							menuName = "SubMenupositive" .. tostring(imenuID)
						  })

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu", 
			  { 
				menuID = imenuID,
				menuParams = {
				  position = 500,
				  menuName = "SubMenupositive" ..tostring(imenuID)
				}
			  })
		:Do(function(_,data)
			--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect AddSubMenu response
		session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function()
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682                
			--[Data Resumption]: OnHashChange 
			session:ExpectNotification("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
end

local function RegisterApp(self, session, RegisterData, DEFLevel)

		local correlationId = session:SendRPC("RegisterAppInterface", RegisterData)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)

			
			if(exp.occurences == 2) then 
				userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
			end


			-- self.applications[RegisterData.appName] = data.params.application.appID
			if RegisterData.appName == "TestAppMedia" then
				-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
				--        is resolved. The issue is checked only on Genivi
				local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
				
				HMIAppIDMediaApp = data.params.application.appID
			elseif RegisterData.appName == "TestAppNonMedia" then
				-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
				--        is resolved. The issue is checked only on Genivi
				local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)

				HMIAppIDNonMediaApp = data.params.application.appID
			elseif RegisterData.appName == "TestAppNavigation" then
				-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
				--        is resolved. The issue is checked only on Genivi
				local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.navigationApp)

				HMIAppIDNaviApp = data.params.application.appID
			elseif RegisterData.appName == "TestAppCommunication" then
				-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
				--        is resolved. The issue is checked only on Genivi
				local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.communicationApp)

				HMIAppIDComApp = data.params.application.appID
			end 
		end)
		:Times(1)

		session:ExpectResponse(correlationId, { success = true })

		session:ExpectNotification("OnHMIStatus", DEFLevel)

		-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
		--        is resolved. The issue is checked only on Genivi
		DelayedExp(1000)
end

local function UnregisterAppInterface(self, session, iappID) 

		--mobile side: UnregisterAppInterface request 
		local CorIdURAI = session:SendRPC("UnregisterAppInterface", {})

		--hmi side: expected  BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = iappID, unexpectedDisconnect = false})

		--mobile side: UnregisterAppInterface response 
		session:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
end

local function SecondConnect(self)
		local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
		local fileConnection = file_connection.FileConnection("mobile2.out", tcpConnection)
		self.mobileConnection2 = mobile.MobileConnection(fileConnection)
		self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection2,
		config.application2.registerAppInterfaceParams)
		event_dispatcher:AddConnection(self.mobileConnection2)
		self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
		self.mobileConnection2:Connect()

		self.mobileSession2:StartService(7)
end

local TimeRAImedia
local TimeRAInonmedia

local function Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, TimeNotTrue,  PostponeNot, reason, SendingNotFalse, TimeForRunAfter, iTimeout, iTimeToResumption)
	local TimeToStartTimer = 0

	if (TimeNotTrue == "before") then 
		if (PostponeNot == "PhoneCall") then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
			notificationState.PhoneCall = true
		elseif (PostponeNot == "EmergencyEvent") then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
			notificationState.EmergencyEvent = true
		elseif (PostponeNot == "VRSession") then
			self.hmiConnection:SendNotification("VR.Started", {})
			notificationState.VRSession = true
		end
	end

	applicationData.mediaApp.hashID = self.currentHashID
	applicationData.nonmediaApp.hashID = self.currentHashID2

	local correlationIdMedia = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
	-- got time after RAI request
	TimeRAImedia =  timestamp()

	local correlationIdNonMedia = self.mobileSession2:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)
	-- got time after RAI request
	TimeRAInonmedia =  timestamp()

	if (reason == "IGN_OFF") then
		local RAIMediaAfterOnReady = TimeRAImedia - self.timeOnReady
		local RAINonMediaAfterOnReady = TimeRAInonmedia - self.timeOnReady
		userPrint( 33, "Time of sending RAI request of media app after OnReady notification " ..tostring(RAIMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of non-media app after OnReady notification " ..tostring(RAINonMediaAfterOnReady))
	end

	if (SendingNotFalse == "WithTimeout") then 
		
		local function to_run()
			if (PostponeNot == "PhoneCall") then
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
				notificationState.PhoneCall = false
			elseif (PostponeNot == "EmergencyEvent") then
				self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
				notificationState.EmergencyEvent = false
			elseif (PostponeNot == "VRSession") then
				self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
			end
		end

		if iTimeToResumption > 5000 then
			local currentTime = timestamp()
			TimeToStartTimer = currentTime - TimeRAImedia
		end

		RUN_AFTER(to_run,TimeForRunAfter)
	end


	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
								{ application = {appID = HMIAppIDMediaApp}, resumeVrGrammars = true },
								{ application = {appID = HMIAppIDNonMediaApp}, resumeVrGrammars = true})
	:Do(function(exp,data)
		if (exp.occurences == 1) then 
			HMIAppIDMediaApp = data.params.application.appID
			
			if (TimeNotTrue == "after") then 
				if (PostponeNot == "PhoneCall" ) then
				  	self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
					notificationState.PhoneCall = true
				elseif (PostponeNot == "EmergencyEvent" ) then
					self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
					notificationState.EmergencyEvent = true
				elseif ( PostponeNot == "VRSession" ) then
					self.hmiConnection:SendNotification("VR.Started", {})
					notificationState.VRSession = true
				end
			end
		elseif (exp.occurences == 2) then
			HMIAppIDNonMediaApp = data.params.application.appID
		end
	end)
	:Times(2)

	EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = HMIAppIDNonMediaApp})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	end)
	:Timeout(iTimeout + TimeToStartTimer)


	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = HMIAppIDMediaApp})
	:Timeout(iTimeout + TimeToStartTimer)

	self.mobileSession:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession2:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	:Do(function()
		if ( SendingNotFalse == "WithoutTimeout" ) then
			if ( PostponeNot == "PhoneCall" ) then
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
				notificationState.PhoneCall = false
			elseif (PostponeNot == "EmergencyEvent" ) then
				self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
				notificationState.EmergencyEvent = false
			elseif (PostponeNot == "VRSession") then
				self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
			end
		end
	end)

	self.mobileSession:ExpectNotification("OnHMIStatus", 
									   	   AppValuesOnHMIStatusDEFAULTMediaApp,
										{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:ValidIf(function(exp,data)
		if  ( exp.occurences == 2 ) then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAImedia
			
			if ( timeToresumption >= (iTimeToResumption - 300 ) and
			  	timeToresumption < (iTimeToResumption + 1000 + TimeToStartTimer) ) then 
			
				userPrint(33, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			else 
				userPrint(31, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			end

		elseif exp.occurences == 1 then
		  	return true
		end
	end)
	:Do(function(_,data)
			self.hmiLevel = data.payload.hmiLevel
		  end)
		  :Times(2)
		  :Timeout(iTimeout + TimeToStartTimer)

		if PostponeNot == "PhoneCall" then

		  self.mobileSession2:ExpectNotification("OnHMIStatus", 
			  AppValuesOnHMIStatusDEFAULTNonMediaApp,
			  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			:ValidIf(function(exp,data)
			  if  exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - TimeRAInonmedia
				  if timeToresumption >= 5000 and
					timeToresumption < 6000 then 
					userPrint(33, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~5000" )
					return true
				  else 
					userPrint(31, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~5000" )
					return false
				  end

			  elseif exp.occurences == 1 then
				return true
			  end
			end)
			:Do(function(_,data)
			  self.hmiLevel = data.payload.hmiLevel
			end)
			:Times(2)

		else
		  self.mobileSession2:ExpectNotification("OnHMIStatus", 
			  AppValuesOnHMIStatusDEFAULTNonMediaApp,
			  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			:ValidIf(function(exp,data)
			  if  exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - TimeRAInonmedia
				  if timeToresumption >= iTimeToResumption - 300 and
					timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
					userPrint(33, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
					return true
				  else 
					userPrint(31, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
					return false
				  end

			  elseif exp.occurences == 1 then
				return true
			  end
			end)
			:Do(function(_,data)
			  self.hmiLevel = data.payload.hmiLevel
			end)
			:Times(2)
			:Timeout(iTimeout + TimeToStartTimer)

		end
	end

local function Resumption_2_Apps_FULL(self, AppToResumption, TimeNotTrue,  PostponeNot, reason, SendingNotFalse, TimeForRunAfter, iTimeout, iTimeToResumption)
  local TimeToStartTimer = 0

	if 
	  TimeNotTrue == "before" then 
		if 
		  PostponeNot == "PhoneCall" then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
			notificationState.PhoneCall = true
		elseif 
		  PostponeNot == "EmergencyEvent" then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
			notificationState.EmergencyEvent = true
		elseif
		  PostponeNot == "VRSession" then
			self.hmiConnection:SendNotification("VR.Started", {})
			notificationState.VRSession = true
		end
	end

	applicationData.mediaApp.hashID = self.currentHashID
	applicationData.nonmediaApp.hashID = self.currentHashID2

	local correlationIdMedia = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
	-- got time after RAI request
	TimeRAImedia =  timestamp()

	local correlationIdNonMedia = self.mobileSession2:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)
	-- got time after RAI request
	TimeRAInonmedia =  timestamp()

	if 
	  reason == "IGN_OFF" then
		local RAIMediaAfterOnReady = TimeRAImedia - self.timeOnReady
		local RAINonMediaAfterOnReady = TimeRAInonmedia - self.timeOnReady
		userPrint( 33, "Time of sending RAI request of media app after OnReady notification " ..tostring(RAIMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of non-media app after OnReady notification " ..tostring(RAINonMediaAfterOnReady))
	end

	-- if 
	--   TimeNotTrue == "after" then 
	--     local function PostponeNotificationTrue()
	--       if 
	--         PostponeNot == "PhoneCall" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
	--           notificationState.PhoneCall = true
	--       elseif 
	--         PostponeNot == "EmergencyEvent" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
	--           notificationState.EmergencyEvent = true
	--       elseif
	--         PostponeNot == "VRSession" then
	--           self.hmiConnection:SendNotification("VR.Started", {})
	--           notificationState.VRSession = true
	--       end
	--     end

	--     RUN_AFTER(PostponeNotificationTrue, 1000)
	-- end

	if 
	  SendingNotFalse == "WithTimeout" then 
		local function to_run()
		  if 
			PostponeNot == "PhoneCall" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
			  notificationState.PhoneCall = false
		  elseif 
			PostponeNot == "EmergencyEvent" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
			  notificationState.EmergencyEvent = false
		  elseif
			PostponeNot == "VRSession" then
			  self.hmiConnection:SendNotification("VR.Stopped", {})
			  notificationState.VRSession = false
		  end
		end

		if iTimeToResumption > 5000 then
		  local currentTime = timestamp()
		  TimeToStartTimer = currentTime - TimeRAImedia
		end

		RUN_AFTER(to_run,TimeForRunAfter)
	end

	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
	  :Times(0)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
		{ resumeVrGrammars = true },
		{ resumeVrGrammars = true})
		:ValidIf(function(exp,data)
		  if 
			data.params.application.appName == "TestAppMedia" then 
			  if 
				data.params.application.appID == HMIAppIDMediaApp then
				  HMIAppIDMediaApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  elseif 
			data.params.application.appName == "TestAppNonMedia" then 
			  if 
				data.params.application.appID == HMIAppIDNonMediaApp then
				  HMIAppIDNonMediaApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Non-media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  else 
			userPrint(31, "Registered app with wrong appName in BC.OnAppRegistered")
			return false
		  end
		end)
		:Do(function(exp, data)
		  if exp.occurences == 1 then 
			if 
			  TimeNotTrue == "after" then 
				  if 
					PostponeNot == "PhoneCall" then
					  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
					  notificationState.PhoneCall = true
				  elseif 
					PostponeNot == "EmergencyEvent" then
					  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
					  notificationState.EmergencyEvent = true
				  elseif
					PostponeNot == "VRSession" then
					  self.hmiConnection:SendNotification("VR.Started", {})
					  notificationState.VRSession = true
				  end
			end
		  end
		end)
		:Times(2)

	self.mobileSession:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession2:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	  :Do(function()
		if 
		  SendingNotFalse == "WithoutTimeout" then
			if 
			  PostponeNot == "PhoneCall" then
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
				notificationState.PhoneCall = false
			elseif 
			  PostponeNot == "EmergencyEvent" then
				self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
				notificationState.EmergencyEvent = false
			elseif
			  PostponeNot == "VRSession" then
				self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
			end
		end
	  end)

  if 
	AppToResumption == "media" then

	  EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = HMIAppIDMediaApp})
		:Do(function(_,data)
			  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		end)
		:Timeout(iTimeout + TimeToStartTimer)

	  self.mobileSession:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTMediaApp,
		  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAImedia
			  if timeToresumption >= iTimeToResumption - 300  and
				timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
				userPrint(33, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)
		:Timeout(iTimeout + TimeToStartTimer)

	  self.mobileSession2:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNonMediaApp)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
  elseif 
	  AppToResumption == "nonmedia" then

		EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = HMIAppIDNonMediaApp})
		  :Do(function(_,data)
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		  end)
		  :Timeout(iTimeout + TimeToStartTimer)


		self.mobileSession:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTMediaApp)
		  :Do(function(_,data)
			self.hmiLevel = data.payload.hmiLevel
		  end)

		if PostponeNot == "PhoneCall" then

		  self.mobileSession2:ExpectNotification("OnHMIStatus", 
			  AppValuesOnHMIStatusDEFAULTNonMediaApp,
			  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			:ValidIf(function(exp,data)
			  if  exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - TimeRAInonmedia
				  if timeToresumption >= 5000 and
					timeToresumption < 6000 then 
					userPrint(33, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~5000" )
					return true
				  else 
					userPrint(31, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~5000" )
					return false
				  end

			  elseif exp.occurences == 1 then
				return true
			  end
			end)
			:Do(function(_,data)
			  self.hmiLevel = data.payload.hmiLevel
			end)
			:Times(2)

		else
		  self.mobileSession2:ExpectNotification("OnHMIStatus", 
			  AppValuesOnHMIStatusDEFAULTNonMediaApp,
			  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			:ValidIf(function(exp,data)
			  if  exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - TimeRAInonmedia
				  if timeToresumption >= iTimeToResumption - 300 and
					timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
					userPrint(33, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
					return true
				  else 
					userPrint(31, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
					return false
				  end

			  elseif exp.occurences == 1 then
				return true
			  end
			end)
			:Do(function(_,data)
			  self.hmiLevel = data.payload.hmiLevel
			end)
			:Times(2)
			:Timeout(iTimeout + TimeToStartTimer)
		end
  end
end

local TimeRAInavi

local function Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, TimeNotTrue,  PostponeNot, reason, SendingNotFalse, TimeForRunAfter, iTimeout, iTimeToResumption)
  local TimeToStartTimer = 0

	if 
	  TimeNotTrue == "before" then 
		if 
		  PostponeNot == "PhoneCall" then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
			notificationState.PhoneCall = true
		elseif 
		  PostponeNot == "EmergencyEvent" then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
			notificationState.EmergencyEvent = true
		elseif
		  PostponeNot == "VRSession" then
			self.hmiConnection:SendNotification("VR.Started", {})
			notificationState.VRSession = true
		end
	end

	applicationData.mediaApp.hashID = self.currentHashID
	applicationData.nonmediaApp.hashID = self.currentHashID2
	applicationData.navigationApp.hashID = self.currentHashID3

	local correlationIdMedia = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
	-- got time after RAI request
	TimeRAImedia =  timestamp()

	local correlationIdNonMedia = self.mobileSession2:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)
	-- got time after RAI request
	TimeRAInonmedia =  timestamp()

	local correlationIdNavi = self.mobileSession3:SendRPC("RegisterAppInterface", applicationData.navigationApp)
	-- got time after RAI request
	TimeRAInavi =  timestamp()

	if 
	  reason == "IGN_OFF" then
		local RAIMediaAfterOnReady = TimeRAImedia - self.timeOnReady
		local RAINonMediaAfterOnReady = TimeRAInonmedia - self.timeOnReady
		local RAINaviAfterOnReady = TimeRAInavi - self.timeOnReady
		userPrint( 33, "Time of sending RAI request of media app after OnReady notification " ..tostring(RAIMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of non-media app after OnReady notification " ..tostring(RAINonMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of navi app after OnReady notification " ..tostring(RAINaviAfterOnReady))
	end

	-- if 
	--   TimeNotTrue == "after" then 
	--     local function PostponeNotificationTrue()
	--       if 
	--         PostponeNot == "PhoneCall" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
	--           notificationState.PhoneCall = true
	--       elseif 
	--         PostponeNot == "EmergencyEvent" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
	--           notificationState.EmergencyEvent = true
	--       elseif
	--         PostponeNot == "VRSession" then
	--           self.hmiConnection:SendNotification("VR.Started", {})
	--           notificationState.VRSession = true
	--       end
	--     end

	--     RUN_AFTER(PostponeNotificationTrue, 1000)
	-- end

	if 
	  SendingNotFalse == "WithTimeout" then 
		local function to_run()
		  if 
			PostponeNot == "PhoneCall" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
			  notificationState.PhoneCall = false
		  elseif 
			PostponeNot == "EmergencyEvent" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
			  notificationState.EmergencyEvent = false
		  elseif
			PostponeNot == "VRSession" then
			  self.hmiConnection:SendNotification("VR.Stopped", {})
			  notificationState.VRSession = false
		  end
		end

		-- local TimeToRun
		-- if iTimeToResumption > 5000 then
		--   local currentTime = timestamp()
		--   TimeToStartTimer = currentTime - TimeRAImedia
		--   TimeToRun = TimeForRunAfter
		-- elseif 
		--   iTimeToResumption <= 5000 then
		--     TimeToRun = TimeForRunAfter + 1000
		-- end

		 if iTimeToResumption > 5000 then
		  local currentTime = timestamp()
		  TimeToStartTimer = currentTime - TimeRAImedia
		end

		RUN_AFTER(to_run,TimeForRunAfter)
	end

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
	  { application = {appID = HMIAppIDMediaApp}, resumeVrGrammars = true },
	  { application = {appID = HMIAppIDNonMediaApp}, resumeVrGrammars = true},
	  { application = {appID = HMIAppIDNaviApp}, resumeVrGrammars = true})
	  :Do(function(exp,data)
		if 
		  exp.occurences == 1 then 
			HMIAppIDMediaApp = data.params.application.appID
			if 
			  TimeNotTrue == "after" then 
				  if 
					PostponeNot == "PhoneCall" then
					  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
					  notificationState.PhoneCall = true
				  elseif 
					PostponeNot == "EmergencyEvent" then
					  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
					  notificationState.EmergencyEvent = true
				  elseif
					PostponeNot == "VRSession" then
					  self.hmiConnection:SendNotification("VR.Started", {})
					  notificationState.VRSession = true
				  end
			end
		elseif 
		  exp.occurences == 2 then
			HMIAppIDNonMediaApp = data.params.application.appID
		elseif 
		  exp.occurences == 3 then
			HMIAppIDNaviApp = data.params.application.appID
		end
	  end)
	:Times(3)

	EXPECT_HMICALL("BasicCommunication.ActivateApp", {appID = HMIAppIDMediaApp})
	  :Do(function(_,data)
			self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	  end)
	  :Timeout(iTimeout + TimeToStartTimer)


	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = HMIAppIDNaviApp})
	  :Timeout(iTimeout + TimeToStartTimer)

	self.mobileSession:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession2:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession3:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	  :Do(function()
		if 
		  SendingNotFalse == "WithoutTimeout" then
			if 
			  PostponeNot == "PhoneCall" then
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
				notificationState.PhoneCall = false
			elseif 
			  PostponeNot == "EmergencyEvent" then
				self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
				notificationState.EmergencyEvent = false
			elseif
			  PostponeNot == "VRSession" then
				self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
			end
		end
	  end)

	self.mobileSession:ExpectNotification("OnHMIStatus", 
		AppValuesOnHMIStatusDEFAULTMediaApp,
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :ValidIf(function(exp,data)
		if  exp.occurences == 2 then 
		  local time2 =  timestamp()
		  local timeToresumption = time2 - TimeRAImedia
			if timeToresumption >= iTimeToResumption - 300 and
			  timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
			  userPrint(33, "Time to HMI level resumption of media app  is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
			  return true
			else 
			  userPrint(31, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
			  return false
			end

		elseif exp.occurences == 1 then
		  return true
		end
	  end)
	  :Do(function(_,data)
		self.hmiLevel = data.payload.hmiLevel
	  end)
	  :Times(2)
	  :Timeout(iTimeout + TimeToStartTimer)

	if PostponeNot == "PhoneCall" then

	  self.mobileSession3:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInavi
			  if timeToresumption >= 5000 and
				timeToresumption < 6000 then 
				userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000" )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~5000" )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)

	else
	  self.mobileSession3:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInavi
			  if timeToresumption >= iTimeToResumption - 300 and
				timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
				userPrint(33, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)
		:Timeout(iTimeout + TimeToStartTimer)

	end

  self.mobileSession2:ExpectNotification("OnHMIStatus", 
		AppValuesOnHMIStatusDEFAULTNonMediaApp)
end

local TimeRAIcom

local function Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, TimeNotTrue,  PostponeNot, reason, SendingNotFalse, TimeForRunAfter, iTimeout, iTimeToResumption)
  local TimeToStartTimer = 0

	if 
	  TimeNotTrue == "before" then 
		if 
		  PostponeNot == "PhoneCall" then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
			notificationState.PhoneCall = true
		elseif 
		  PostponeNot == "EmergencyEvent" then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
			notificationState.EmergencyEvent = true
		elseif
		  PostponeNot == "VRSession" then
			self.hmiConnection:SendNotification("VR.Started", {})
			notificationState.VRSession = true
		end
	end

	applicationData.mediaApp.hashID = self.currentHashID
	applicationData.nonmediaApp.hashID = self.currentHashID2
	applicationData.navigationApp.hashID = self.currentHashID3
	applicationData.communicationApp.hashID = self.currentHashID4

	local correlationIdMedia = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
	-- got time after RAI request
	TimeRAImedia =  timestamp()

	local correlationIdNonMedia = self.mobileSession2:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)
	-- got time after RAI request
	TimeRAInonmedia =  timestamp()

	local correlationIdNavi = self.mobileSession3:SendRPC("RegisterAppInterface", applicationData.navigationApp)
	-- got time after RAI request
	TimeRAInavi =  timestamp()

	local correlationIdNavi = self.mobileSession4:SendRPC("RegisterAppInterface", applicationData.communicationApp)
	-- got time after RAI request
	TimeRAIcom =  timestamp()

	if 
	  reason == "IGN_OFF" then
		local RAIMediaAfterOnReady = TimeRAImedia - self.timeOnReady
		local RAINonMediaAfterOnReady = TimeRAInonmedia - self.timeOnReady
		local RAINaviAfterOnReady = TimeRAInavi - self.timeOnReady
		local RAIComAfterOnReady = TimeRAInavi - self.timeOnReady
		userPrint( 33, "Time of sending RAI request of media app after OnReady notification " ..tostring(RAIMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of non-media app after OnReady notification " ..tostring(RAINonMediaAfterOnReady))
		userPrint( 33, "Time of sending RAI request of navigation app after OnReady notification " ..tostring(RAINaviAfterOnReady))
		userPrint( 33, "Time of sending RAI request of communication app after OnReady notification " ..tostring(RAINaviAfterOnReady))
	end

	if 
	  TimeNotTrue == "after" then 
		-- local function PostponeNotificationTrue()
		  if 
			PostponeNot == "PhoneCall" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
			  notificationState.PhoneCall = true
		  elseif 
			PostponeNot == "EmergencyEvent" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
			  notificationState.EmergencyEvent = true
		  elseif
			PostponeNot == "VRSession" then
			  self.hmiConnection:SendNotification("VR.Started", {})
			  notificationState.VRSession = true
		  end
		-- end

		-- RUN_AFTER(PostponeNotificationTrue, 500)
	end

	-- if 
	--   TimeNotTrue == "after" then 
	--     local function PostponeNotificationTrue()
	--       if 
	--         PostponeNot == "PhoneCall" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
	--           notificationState.PhoneCall = true
	--       elseif 
	--         PostponeNot == "EmergencyEvent" then
	--           self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
	--           notificationState.EmergencyEvent = true
	--       elseif
	--         PostponeNot == "VRSession" then
	--           self.hmiConnection:SendNotification("VR.Started", {})
	--           notificationState.VRSession = true
	--       end
	--     end

	--     RUN_AFTER(PostponeNotificationTrue, 500)
	-- end

	if 
	  SendingNotFalse == "WithTimeout" then 
		local function to_run()
		  if 
			PostponeNot == "PhoneCall" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
			  notificationState.PhoneCall = false
		  elseif 
			PostponeNot == "EmergencyEvent" then
			  self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
			  notificationState.EmergencyEvent = false
		  elseif
			PostponeNot == "VRSession" then
			  self.hmiConnection:SendNotification("VR.Stopped", {})
			  notificationState.VRSession = false
		  end
		end

		-- local TimeToRun
		-- if iTimeToResumption > 5000 then
		--   local currentTime = timestamp()
		--   TimeToStartTimer = currentTime - TimeRAImedia
		--   TimeToRun = TimeForRunAfter
		-- elseif 
		--   iTimeToResumption <= 5000 then
		--     TimeToRun = TimeForRunAfter + 500
		-- end

		-- RUN_AFTER(to_run,TimeToRun)

		RUN_AFTER(to_run,TimeForRunAfter)
	end


	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
		{ resumeVrGrammars = true })
		:ValidIf(function(exp,data)
		  if 
			data.params.application.appName == "TestAppMedia" then 
			  if 
				data.params.application.appID == HMIAppIDMediaApp then
				  HMIAppIDMediaApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  elseif 
			data.params.application.appName == "TestAppNonMedia" then 
			  if 
				data.params.application.appID == HMIAppIDNonMediaApp then
				  HMIAppIDNonMediaApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Non-media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  elseif 
			data.params.application.appName == "TestAppNavigation" then 
			  if 
				data.params.application.appID == HMIAppIDNaviApp then
				  HMIAppIDNaviApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Non-media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  elseif 
			data.params.application.appName == "TestAppCommunication" then 
			  if 
				data.params.application.appID == HMIAppIDComApp then
				  HMIAppIDComApp = data.params.application.appID
				  return true
			  else 
				userPrint(31, "Non-media app is registered not with appID from previous ignition cycle")
				return false
			  end
		  else 
			userPrint(31, "Registered app with wrong appName in BC.OnAppRegistered")
			return false
		  end
		end)
		:Times(4)

	EXPECT_HMICALL("BasicCommunication.ActivateApp", 
	  {appID = HMIAppIDNonMediaApp})
	  :Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	  end)
	  :Timeout(iTimeout + TimeToStartTimer)


	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", 
	  {appID = HMIAppIDMediaApp},
	  {appID = HMIAppIDNaviApp},
	  {appID = HMIAppIDComApp})
	  :Timeout(iTimeout + TimeToStartTimer)
	  :Times(3)

	self.mobileSession:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession2:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession3:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	self.mobileSession4:ExpectResponse("RegisterAppInterface", { success = true , resultCode = "SUCCESS"})
	  :Do(function()
		if 
		  SendingNotFalse == "WithoutTimeout" then
			if 
			  PostponeNot == "PhoneCall" then
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
				notificationState.PhoneCall = false
			elseif 
			  PostponeNot == "EmergencyEvent" then
				self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
				notificationState.EmergencyEvent = false
			elseif
			  PostponeNot == "VRSession" then
				self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
			end
		end
	  end)

	self.mobileSession:ExpectNotification("OnHMIStatus", 
		AppValuesOnHMIStatusDEFAULTMediaApp,
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :ValidIf(function(exp,data)
		if  exp.occurences == 2 then 
		  local time2 =  timestamp()
		  local timeToresumption = time2 - TimeRAImedia
			if timeToresumption >= iTimeToResumption - 300 and
			  timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
			  userPrint(33, "Time to HMI level resumption of media app  is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
			  return true
			else 
			  userPrint(31, "Time to HMI level resumption of media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
			  return false
			end

		elseif exp.occurences == 1 then
		  return true
		end
	  end)
	  :Do(function(_,data)
		self.hmiLevel = data.payload.hmiLevel
	  end)
	  :Times(2)
	  :Timeout(iTimeout + TimeToStartTimer)

	if PostponeNot == "PhoneCall" then

	  self.mobileSession3:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInavi
			  if timeToresumption >= 5000 and
				timeToresumption < 6000 then 
				userPrint(33, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~5000" )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~5000" )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)

	else
	  self.mobileSession3:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInavi
			  if timeToresumption >= iTimeToResumption - 300 and
				timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
				userPrint(33, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of navi app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)
		:Timeout(iTimeout + TimeToStartTimer)
	end

	if PostponeNot == "PhoneCall" then

	  self.mobileSession4:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAIcom
			  if timeToresumption >= 5000 and
				timeToresumption < 6000 then 
				userPrint(33, "Time to HMI level resumption of com app is " .. tostring(timeToresumption) ..", expected ~5000" )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of com is " .. tostring(timeToresumption) ..", expected ~5000" )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)

	else
	  self.mobileSession4:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAIcom
			  if timeToresumption >= iTimeToResumption - 300 and
				timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
				userPrint(33, "Time to HMI level resumption of com app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of com app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)
		:Timeout(iTimeout + TimeToStartTimer)
	end

	if PostponeNot == "PhoneCall" then

	  self.mobileSession2:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInonmedia
			  if timeToresumption >= 5000 and
				timeToresumption < 6000 then 
				userPrint(33, "Time to HMI level resumption of non-media is " .. tostring(timeToresumption) ..", expected ~5000" )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of non-media is " .. tostring(timeToresumption) ..", expected ~5000" )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)

	else
	  self.mobileSession2:ExpectNotification("OnHMIStatus", 
		  AppValuesOnHMIStatusDEFAULTNavigationApp,
		  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		:ValidIf(function(exp,data)
		  if  exp.occurences == 2 then 
			local time2 =  timestamp()
			local timeToresumption = time2 - TimeRAInonmedia
			  if timeToresumption >= iTimeToResumption -300 and
				timeToresumption < iTimeToResumption + 1000 + TimeToStartTimer then 
				userPrint(33, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return true
			  else 
				userPrint(31, "Time to HMI level resumption of non-media app is " .. tostring(timeToresumption) ..", expected ~" .. tostring(iTimeToResumption + TimeToStartTimer) .. " " )
				return false
			  end

		  elseif exp.occurences == 1 then
			return true
		  end
		end)
		:Do(function(_,data)
		  self.hmiLevel = data.payload.hmiLevel
		end)
		:Times(2)
		:Timeout(iTimeout + TimeToStartTimer)
	end
end

local function ResumptionData(self)
  --hmi side: expect UI.AddCommand request 
  EXPECT_HMICALL("UI.AddCommand")
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume UI.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume UI.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		end
	end)
	:Times(2)

  --hmi side: expect VR.AddCommand request 
  EXPECT_HMICALL("VR.AddCommand", 
	{           
	  type = "Command"
	})
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume VR.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume VR.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		end
	end)
	:Times(2)

	self.mobileSession:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID = data.payload.hashID
	  end)

	self.mobileSession2:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID2 = data.payload.hashID
	  end)
end

local function ResumptionData3apps(self)
  --hmi side: expect UI.AddCommand request 
  EXPECT_HMICALL("UI.AddCommand")
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume UI.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume UI.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 3 then 
			if 
			  data.params.appID == HMIAppIDNaviApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInavi
				userPrint(33, "Time to resume UI.AddCommand of navi app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Navi app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNaviApp))
			  return false
			end
		end
	end)
	:Times(3)

  --hmi side: expect VR.AddCommand request 
  EXPECT_HMICALL("VR.AddCommand", 
	{          
	  type = "Command"
	})
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume VR.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume VR.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 3 then 
			if 
			  data.params.appID == HMIAppIDNaviApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInavi
				userPrint(33, "Time to resume VR.AddCommand of navi app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Navi app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNaviApp))
			  return false
			end
		end
	end)
	:Times(3)

	self.mobileSession:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID = data.payload.hashID
	  end)

	self.mobileSession2:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID2 = data.payload.hashID
	  end)

	self.mobileSession3:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID3 = data.payload.hashID
	  end)
end

local function ResumptionData4apps(self)
  --hmi side: expect UI.AddCommand request 
  EXPECT_HMICALL("UI.AddCommand")
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume UI.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume UI.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 3 then 
			if 
			  data.params.appID == HMIAppIDNaviApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInavi
				userPrint(33, "Time to resume UI.AddCommand of navi app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Navi app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNaviApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 4 then 
			if 
			  data.params.appID == HMIAppIDComApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAIcom
				userPrint(33, "Time to resume UI.AddCommand of com app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Com app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDComApp))
			  return false
			end
		end
	end)
	:Times(4)

  --hmi side: expect VR.AddCommand request 
  EXPECT_HMICALL("VR.AddCommand", 
	{             
	  type = "Command",
	})
	:Do(function(exp,data)
	  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if 
			data.params.cmdID == 1 then 
			  if 
				data.params.appID == HMIAppIDMediaApp then
				  local AddcommandTime = timestamp()
				  local ResumptionTime =  AddcommandTime - TimeRAImedia
				  userPrint(33, "Time to resume VR.AddCommand of media app "..tostring(ResumptionTime))
				  return true
			  else 
				userPrint(31, "Media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDMediaApp))
				return false
			  end
		elseif 
		  data.params.cmdID == 2 then 
			if 
			  data.params.appID == HMIAppIDNonMediaApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInonmedia
				userPrint(33, "Time to resume VR.AddCommand of non-media app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Non-media app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNonMediaApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 3 then 
			if 
			  data.params.appID == HMIAppIDNaviApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAInavi
				userPrint(33, "Time to resume VR.AddCommand of navi app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Navi app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDNaviApp))
			  return false
			end
		elseif 
		  data.params.cmdID == 4 then 
			if 
			  data.params.appID == HMIAppIDComApp then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - TimeRAIcom
				userPrint(33, "Time to resume VR.AddCommand of com app "..tostring(ResumptionTime))
				return true
			else 
			  userPrint(31, "Com app is registered not with wrong appID " .. tostring(data.params.appID) .. ", expected ".. tostring(HMIAppIDComApp))
			  return false
			end
		end
	end)
	:Times(4)

	self.mobileSession:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID = data.payload.hashID
	  end)

	self.mobileSession2:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID2 = data.payload.hashID
	  end)

	self.mobileSession3:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID3 = data.payload.hashID
	  end)

	self.mobileSession4:ExpectNotification("OnHashChange", {})
	  :Do(function(_, data)
		self.currentHashID4 = data.payload.hashID
	  end)
end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption of 2 apps (App1 =LIMITED (media), app2 = FULL (non-media)).
--////////////////////////////////////////////////////////////////////////////////////////////--
  --======================================================================================--
  -- IGN_OFF without postpone
  --======================================================================================--
  --Requirement id in JAMA/or Jira ID: APPLINK-15634
  --[Data Resumption]: Data resumption on IGNITION OFF 

  --Requirement id in JAMA/or Jira ID: APPLINK-15702
  --[Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption 

  --Requirement id in JAMA/or Jira ID: APPLINK-15683
  --[Data Resumption]: SDL data resumption SUCCESS sequence 
  
  

function Test:UnregisterAppInterface_Success() 
	userPrint(35, "================= Resumption of 2 apps (App1 =LIMITED (media), app2 = FULL (non-media)). IGN_OFF without postpone ==================")
	userPrint(35, "======================================================= Precondition ===============================================================")

	UnregisterAppInterface(self, self.mobileSession)

end

function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
end


function Test:StartSession2()
   	self.mobileSession2 = mobile_session.MobileSession(
														self,
	  													self.mobileConnection,
	  													applicationData.nonmediaApp)
end


function Test:RegisterNonMediaApp()
	self.mobileSession2:StartService(7)
	:Do(function(_,data)
		RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
	end)
end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, _,  _, "IGN_OFF", _, _, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSessionActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "VRSession", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSession_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "VRSession", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSessionActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "VRSession", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)


  end

	--======================================================================================--
  -- IGN_OFF with postpone because of VR.Started after RAI requests, VR.Stopped in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSession_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "VRSession", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEventActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) after RAI requests, OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEvent_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEventActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "EmergencyEvent", "IGN_OFF", "WithTimeout", 500, 10000, 5000)

	ResumptionData(self)


  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.EmergencyEvent(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEvent_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "EmergencyEvent", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)

  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCallActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) after RAI requests, OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCall_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCallActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "PhoneCall", "IGN_OFF", "WithTimeout", 500, 10000, 5000)

	ResumptionData(self)


  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 2)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCall_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "PhoneCall", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, _,  _, _, _, _, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSessionActive_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSession_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started before RAI requests, VR.Stopped in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSessionActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "VRSession", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)


  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_VRSession_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "VRSession", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEventActive_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEvent_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEventActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "EmergencyEvent", _, "WithTimeout", 500, 10000, 5000)

	ResumptionData(self)


  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.EmergencyEvent(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_EmergencyEvent_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "EmergencyEvent", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCallActive_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCall_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCallActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "before", "PhoneCall", _, "WithTimeout", 500, 10000, 5000)

	ResumptionData(self)


  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_PhoneCall_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================") 

	Resumption_2_Apps_FULL_nonMedia_LIMITED_Media(self, "after", "PhoneCall", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)

  end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption of 2 apps (App1 =LIMITED (navi), app2 = FULL (media)) 3rd app in BACKGROUND.
--////////////////////////////////////////////////////////////////////////////////////////////--
  --======================================================================================--
  -- IGN_OFF without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function(_,data)
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus",
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}, {})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, _,  _, "IGN_OFF", _, _, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("Navigation level" .. data.payload.hmiLevel)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("media level" .. data.payload.hmiLevel)
	  end)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("navi level" .. data.payload.hmiLevel)
	  end)

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSessionActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "VRSession", "IGN_OFF", "WithTimeout", 35000, 40000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSession_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "VRSession", "IGN_OFF", "WithTimeout", 35000, 40000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSessionActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "VRSession", "IGN_OFF", "WithoutTimeout", _, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started after RAI requests, VR.Stopped in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSession_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "VRSession", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEventActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 40000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEvent_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEventActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "EmergencyEvent", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true)after RAI requests, BC.OnEmergencyEvent(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEvent_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "EmergencyEvent", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end


 --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("Navigation level" .. data.payload.hmiLevel)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("media level" .. data.payload.hmiLevel)
	  end)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("navi level" .. data.payload.hmiLevel)
	  end)

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCallActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 40000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCall_AfterRAI_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 40000, 35000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCallActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "PhoneCall", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true)after RAI requests, BC.OnPhoneCall(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 3)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCall_AfterRAI_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "PhoneCall", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end
  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function(_,data)
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, _,  _, _, _, _, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("Navigation level" .. data.payload.hmiLevel)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("media level" .. data.payload.hmiLevel)
	  end)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("navi level" .. data.payload.hmiLevel)
	  end)

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSessionActive_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSession_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started before RAI requests, VR.Stopped in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSessionActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "VRSession", _, "WithoutTimeout", _, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_VRSession_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "VRSession", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("Navigation level" .. data.payload.hmiLevel)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("media level" .. data.payload.hmiLevel)
	  end)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("navi level" .. data.payload.hmiLevel)
	  end)

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEventActive_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEvent_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEventActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "EmergencyEvent", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true)after RAI requests, BC.OnEmergencyEvent(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_EmergencyEvent_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "EmergencyEvent", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end


 --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("Navigation level" .. data.payload.hmiLevel)
	  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("non-media level" .. data.payload.hmiLevel)
	  end)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("media level" .. data.payload.hmiLevel)
	  end)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Do(function(_,data)
	  print("navi level" .. data.payload.hmiLevel)
	  end)

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCallActive_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) after 30 seconda
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCall_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 3 secons
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCallActive_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "before", "PhoneCall", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true)after RAI requests, BC.OnPhoneCall(false) in 3 sec
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end 

  function Test:RegisterNaviMediaApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end 

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateNaviApp()
	ActivationApp(self, HMIAppIDNaviApp)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	  :Do(function()
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
	  end)

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	 self.mobileSession2:ExpectNotification("OnHMIStatus", {})
	  :Times(0)
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
   self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
   self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.nonmediaApp)

   self.mobileSession3:StartService(7)
  end

  function Test:Resumption_FULL_media_LIMITED_navi_DAFAULT_nonmedia_PhoneCall_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_2_Apps_FULL_Media_LIMITED_Navi_3rdApp_NonMedia_WithoutResumption(self, "after", "PhoneCall", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData3apps(self)

  end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption of 2 apps with different timestamp (both of application is FULL)
--////////////////////////////////////////////////////////////////////////////////////////////--
  --======================================================================================--
  -- IGN_OFF without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:CloseConnection()
	  self.mobileConnection:Close() 
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:Case_SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
	self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

	self.mobileSession:StartService(7)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", _,  _, "IGN_OFF", _, _, 10000, 5000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_VRSessionActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "VRSession", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_VRSessionActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "VRSession", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end


  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_EmergencyEventActive__IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_EmergencyEventActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "EmergencyEvent", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_PhoneCallActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseSession()
	local function to_run()
	  self.mobileSession:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseSession2()
	local function to_run()
	  self.mobileSession2:Stop()
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:SUSPEND()
	SUSPEND(self)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 0)
  end

  function Test:StartSDL()
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_PhoneCallActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "nonmedia", "before",  "PhoneCall", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end

--[==[ TODO: Uncomment after resolving APPLINK-10858
  --======================================================================================--
  -- Disconnect without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", _,  _, _, _, _, 10000, 5000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_VRSession_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after",  "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_VRSession_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after",  "VRSession", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end


  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_EmergencyEvent_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_EmergencyEvent_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after",  "EmergencyEvent", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_PhoneCall_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after",  "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:ActivateNonMediaApp()
	ActivationApp(self, HMIAppIDNonMediaApp)

	self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection2()
	local function to_run()
	  self.mobileConnection2:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDNonMediaApp})
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:ActivateMediaApp()
	ActivationApp(self, HMIAppIDMediaApp)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:CloseConnection()
	local function to_run()
	  self.mobileConnection:Close() 
	end

	RUN_AFTER(to_run, 3000)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppIDMediaApp})
  end

  function Test:FirstConnection()
	self:connectMobile()
  end

  function Test:SecondConnection()
	SecondConnect(self)
  end

  function Test:StartSession()
   self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.mediaApp)

   self.mobileSession:StartService(7)
  end

  function Test:Resumption_FULL_media_nonmedia_different_timestamp_PhoneCall_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")
	Resumption_2_Apps_FULL(self, "media", "after",  "PhoneCall", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData(self)
  end
]==]


--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption of 4 apps 
--////////////////////////////////////////////////////////////////////////////////////////////--
  --======================================================================================--
  -- IGN_OFF without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:CloseFirstConnection()
	self.mobileConnection:Close()
  end

  function Test:CloseSecondConnection()
	self.mobileConnection2:Close()
  end

  function Test:StartFirstConnection()
	self:connectMobile()
  end

  function Test:StartSession()
	self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	self.mobileSession4 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.communicationApp)

	self.mobileSession4:StartService(7)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, _,  _, "IGN_OFF", _, _, 10000, 5000)

	ResumptionData4apps(self)

  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--
  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_VRSessionActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before",  "VRSession", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)
	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of VR.Started before RAI requests, VR.Stopped in 5 seconds
  --======================================================================================--
  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_VRSessionActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before",  "VRSession", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_EmergencyEventActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before", "EmergencyEvent", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnEmergencyEvent(true) before RAI requests, BC.OnEmergencyEvent(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_EmergencyEventActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before",  "EmergencyEvent", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_PhoneCallActive_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before", "PhoneCall", "IGN_OFF", "WithTimeout", 35000, 37000, 35000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- IGN_OFF with postpone because of BC.OnPhoneCall(true) before RAI requests, BC.OnPhoneCall(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_PhoneCallActive_in5sec_IGN_OFF()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "before",  "PhoneCall", "IGN_OFF", "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect without postpone
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:StartSession()
	self.mobileSession = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	self.mobileSession2 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	self.mobileSession3 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.navigationApp)

	self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	self.mobileSession4 = mobile_session.MobileSession(
	  self,
	  self.mobileConnection,
	  applicationData.communicationApp)

	self.mobileSession4:StartService(7)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, _,  _, _, _, _, 10000, 5000)

	ResumptionData4apps(self)

  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped after 30 seconds
  --======================================================================================--
  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_VRSession_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after",  "VRSession", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of VR.Started after RAI requests, VR.Stopped in 5 seconds
  --======================================================================================--
  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:SUSPEND()
	SUSPEND(self, _)
  end

  function Test:IGNITION_OFF()
	IGNITION_OFF(self, 4)
  end

  function Test:StartSDL()
	print("Start SDL")
	StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI()
	self:initHMI()
  end

  function Test:InitHMI_onReady()
	self:initHMI_onReady()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_VRSession_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after",  "VRSession", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_EmergencyEvent_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after", "EmergencyEvent", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnEmergencyEvent(true) after RAI requests, BC.OnEmergencyEvent(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_EmergencyEvent_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after",  "EmergencyEvent", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) after 30 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_PhoneCall_AfterRAI_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after", "PhoneCall", _, "WithTimeout", 15000, 17000, 15000)

	ResumptionData4apps(self)
  end

  --======================================================================================--
  -- Disconnect with postpone because of BC.OnPhoneCall(true) after RAI requests, BC.OnPhoneCall(false) in 5 seconds
  --======================================================================================--

  function Test:UnregisterAppInterface_MediaApp_Success() 
	userPrint(35, "================= Precondition ==================")
	UnregisterAppInterface(self, self.mobileSession)
  end

  function Test:UnregisterAppInterface_NonMediaApp_Success() 
	UnregisterAppInterface(self, self.mobileSession2)
  end

  function Test:UnregisterAppInterface_NaviApp_Success() 
	UnregisterAppInterface(self, self.mobileSession3)
  end

  function Test:UnregisterAppInterface_ComApp_Success() 
	UnregisterAppInterface(self, self.mobileSession4)
  end

  function Test:RegisterNonMediaApp()
	RegisterApp(self, self.mobileSession2, applicationData.nonmediaApp, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

  function Test:RegisterMediaApp()
	RegisterApp(self, self.mobileSession, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)
  end

  function Test:RegisterNavigationApp()
	RegisterApp(self, self.mobileSession3, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

  function Test:RegisterCommunicationApp()
	RegisterApp(self, self.mobileSession4, applicationData.communicationApp, AppValuesOnHMIStatusDEFAULTCommunicationApp)
  end

  function Test:ActivationMediaApp()

	ActivationApp(self, HMIAppIDMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 

  end

  function Test:AddCommandMediaApp()
	AddCommand(self, 1, self.mobileSession)
  end

  function Test:ActivationNaviApp()

	ActivationApp(self, HMIAppIDNaviApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})  

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNaviApp()
	AddCommand(self, 3, self.mobileSession3)
  end

  function Test:ActivationComApp()

	ActivationApp(self, HMIAppIDComApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandComApp()
	AddCommand(self, 4, self.mobileSession4)
  end

  function Test:ActivationNonMediaApp()

	ActivationApp(self, HMIAppIDNonMediaApp)

	--mobile side: expect OnHMIStatus notification
	self.mobileSession:ExpectNotification("OnHMIStatus", {})  
	  :Times(0)

	self.mobileSession3:ExpectNotification("OnHMIStatus", {})
	  :Times(0)

	self.mobileSession4:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

	self.mobileSession2:ExpectNotification("OnHMIStatus", 
	  {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  end

  function Test:AddCommandNonMediaApp()
	AddCommand(self, 2, self.mobileSession2)
  end

  function Test:CloseConnection()
	self.mobileConnection:Close()
  end

  function Test:ConnectMobile()
	self:connectMobile()
  end

  function Test:StartSession()
	 self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.mediaApp)

	 self.mobileSession:StartService(7)
  end

  function Test:StartSession2()
	 self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.nonmediaApp)

	 self.mobileSession2:StartService(7)
  end

  function Test:StartSession3()
	 self.mobileSession3 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.navigationApp)

	 self.mobileSession3:StartService(7)
  end

  function Test:StartSession4()
	 self.mobileSession4 = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		applicationData.communicationApp)

	 self.mobileSession4:StartService(7)
  end

  function Test:Resumption_FULL_nonmedia_LIMITED_media_navi_com_PhoneCall_AfterRAI_in5sec_Disconnect()
	userPrint(34, "=================== Test Case ===================")

	Resumption_4_Apps_FULL_NonMedia_LIMITED_Navi_Media_Com(self, "after",  "PhoneCall", _, "WithTimeout", 1000, 10000, 5000)

	ResumptionData4apps(self)
  end

function Test:Postcondition_RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end