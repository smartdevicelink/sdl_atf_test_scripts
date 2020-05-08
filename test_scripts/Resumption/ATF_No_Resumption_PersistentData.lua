
--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')

local commonSteps	  = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')
local json = require("json")

local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local applicationData = 
{
	SecondApp = {
					syncMsgVersion =
									{
		  								majorVersion = 3,
		  								minorVersion = 3
									},
					appName = "DuplicateName",
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
					}
}


--Backup, updated preloaded file
-------------------------------------------------------------------------------------
	commonSteps:DeleteLogsFileAndPolicyTable()
	os.execute(" cp " .. config.pathToSDL .. "/sdl_preloaded_pt.json " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )

	f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "r"))

	fileContent = f:read("*all")

    -- default section
    --DefaultContant = fileContent:match('".?default.?".?:.?.?%{.-%}')
    DefaultContant = fileContent:match('"default".?:.?.?%{.-%}')

    if not DefaultContant then
      print ( " \27[31m  default grpoup is not found in sdl_preloaded_pt.json \27[0m " )
    else
       DefaultContant =  string.gsub(DefaultContant, '".?groups.?".?:.?.?%[.-%]', '"groups": ["Base-4", "Location-1", "DrivingCharacteristics-3", "VehicleInfo-3", "Emergency-1"]')
    end


	fileContent  =  string.gsub(fileContent, '".?default.?".?:.?.?%{.-%}', DefaultContant)


	f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "w+"))
	
	
	
	
	f:write(fileContent)
	f:close()
-------------------------------------------------------------------------------------
	os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_OnButtonSubscription.lua')

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "r"))

	fileContent = f:read("*all")
	f:close()

	-- add "Buttons.OnButtonSubscription"
	local pattern1 = "registerComponent%s-%(%s-\"Buttons\"%s-[%w%s%{%}.,\"]-%)"
	local pattern1Result = fileContent:match(pattern1)

	if pattern1Result == nil then 
		print(" \27[31m Buttons registerComponent function is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern1, 'registerComponent("Buttons", {"Buttons.OnButtonSubscription"})')
	end

	local pattern2 = "%{%s-capabilities%s-=%s-%{.-%}"
	local pattern2Result = fileContent:match(pattern2)

	if pattern2Result == nil then 
		print(" \27[31m capabilities array is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern2, '{capabilities = {button_capability("PRESET_0"),button_capability("PRESET_1"),button_capability("PRESET_2"),button_capability("PRESET_3"),button_capability("PRESET_4"),button_capability("PRESET_5"),button_capability("PRESET_6"),button_capability("PRESET_7"),button_capability("PRESET_8"),button_capability("PRESET_9"),button_capability("OK", true, false, true),button_capability("PLAY_PAUSE"),button_capability("SEEKLEFT"),button_capability("SEEKRIGHT"),button_capability("TUNEUP"),button_capability("TUNEDOWN"),button_capability("CUSTOM_BUTTON")}')
	end

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "w+"))
	f:write(fileContent)
	f:close()

	

	--Precondition: backup smartDeviceLink.ini
	commonPreconditions:BackupFile("smartDeviceLink.ini")

	-- set  ApplicationResumingTimeout in .ini file to 3000;
	commonFunctions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s?=%s-[%d]-%s-\n", "ApplicationResumingTimeout", 3000)

	-- Postcondition: removing user_modules/connecttest_resumption.lua
	function Test:Postcondition_remove_user_connecttest_restore_preloaded_file()
		os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
		os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt_origin.json " .. config.pathToSDL .. "sdl_preloaded_pt.json" )
		os.execute(" rm -f " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )

		os.execute( "rm -f ./user_modules/connecttest_OnButtonSubscription.lua" )

		if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      		os.remove(config.pathToSDL .. "policy.sqlite")
    	end
	end


	config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	--ToDo: shall be removed when APPLINK-16610 is fixed
	config.defaultProtocolVersion = 2

	local storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

	local AppValuesOnHMIStatusFULL 
	local AppValuesOnHMIStatusLIMITED
	local AppValuesOnHMIStatusDEFAULT
	local DefaultHMILevel = "NONE"
	local HMIAppID
	local audibleState

	local buttonName = {"OK"}
	AppValuesOnHMIStatusDEFAULT = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }

	if 
		config.application1.registerAppInterfaceParams.isMediaApplication == true or
		Test.appHMITypes["NAVIGATION"] == true or
		Test.appHMITypes["COMMUNICATION"] == true then
		AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
		AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
		audibleState = "AUDIBLE"
	elseif 
		config.application1.registerAppInterfaceParams.isMediaApplication == false then
		AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
		audibleState = "NOT_AUDIBLE"
	end

	local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}

	local SVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}
	local textPromtValue = {"Please speak one of the following commands," ,"Please say a command,"}

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

	local function UnregisterAppInterface(self) 
		--Requirement id in JAMA/or Jira ID: APPLINK-15987
		--[Data Resumption] Application data must not be resumed 

		--mobile side: UnregisterAppInterface request 
		local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

		--hmi side: expected  BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})

		--mobile side: UnregisterAppInterface response 
		EXPECT_RESPONSE(CorIdURAI, {success = true , resultCode = "SUCCESS"})
	end

	local function RegisterApp_WithoutHMILevelResumption(self, reason, resumeGrammars)
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		-- got time after RAI request
		time =  timestamp()

		if reason == "IGN_OFF" then
			local RAIAfterOnReady = time - self.timeOnReady
			userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))
		end

		--
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
			--        is resolved. The issue is checked only on Genivi
			local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			if(exp.occurences == 2)	then 
				--userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
			end
			
				
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID	
			
		end)
		:Times(1)

		if resumeGrammars == false then
			--Requirement id in JAMA/or Jira ID: APPLINK-15686
			--[Data Resumption]: SDL data resumption failure
			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode})
		elseif
			--Requirement id in JAMA/or Jira ID: APPLINK-15683
			--[Data Resumption]: SDL data resumption SUCCESS sequence
			resumeGrammars == true then

			-- TODO: APPLINK-26128: "info" parameter shall be updated
			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode, info = "Resume succeeded"})--info = " Resume Succeed"})
		end


		EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		end)
		:Times(0)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		:Times(0)

		--Requirement id in JAMA/or Jira ID: APPLINK-15987
		--[Data Resumption] Application data must not be resumed 
		EXPECT_HMICALL("UI.AddCommand")
		:Times(0)

		EXPECT_HMICALL("VR.AddCommand")
		:Times(0)

		EXPECT_HMICALL("UI.AddSubMenu")
		:Times(0)

		EXPECT_HMICALL("TTS.SetGlobalProperties")

		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Times(0)

		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON"})

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(1)
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusDEFAULT)
		:Do(function(_,data)
			self.hmiLevel = data.payload.hmiLevel
		end)

		DelayedExp(5000)
	end

	local function ActivationApp(self)

		if 
			notificationState.VRSession == true then
			self.hmiConnection:SendNotification("VR.Stopped", {})
		elseif 
			notificationState.EmergencyEvent == true then
			self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
		elseif
			notificationState.PhoneCall == true then
			self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
		end

		-- hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		-- hmi side: expect SDL.ActivateApp response
		EXPECT_HMIRESPONSE(RequestId)
      	:Do(function(_,data)
			-- In case when app is not allowed, it is needed to allow app
          	if
				data.result.isSDLAllowed ~= true then
				
                -- hmi side: sending SDL.GetUserFriendlyMessage request
                local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
																 {language = "EN-US", messageCodes = {"DataConsent"}})

                -- hmi side: expect SDL.GetUserFriendlyMessage response
                -- TODO: comment until resolving APPLINK-16094
                -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                EXPECT_HMIRESPONSE(RequestId)
                :Do(function(_,data)
	                -- hmi side: send request SDL.OnAllowSDLFunctionality
	                self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
														{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

	                -- hmi side: expect BasicCommunication.ActivateApp request
	                EXPECT_HMICALL("BasicCommunication.ActivateApp")
	                :Do(function(_,data)
						-- hmi side: sending BasicCommunication.ActivateApp response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					
					:Times(2)
					print("\27[31m CHECK_1: Check why 2 expectation of BasicCommunication.ActivateApp \27[0m")
				end)
        	end
        end)
	end

	local function CreateSession(self)
		self.mobileSession = mobile_session.MobileSession(
															self,
															self.mobileConnection)
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

	local function SUSPEND(self, targetLevel)

		if (targetLevel == "FULL" and self.hmiLevel ~= "FULL") then
			ActivationApp(self)
				
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			:Do(function(_,data)
			
				self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
													{ reason = "SUSPEND" })

				--Requirement id in JAMA/or Jira ID: APPLINK-15702
				--Send BC.OnPersistanceComplete to HMI on data persistance complete			
				-- hmi side: expect OnSDLPersistenceComplete notification
				EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
			end)
		elseif (targetLevel == "LIMITED" and self.hmiLevel ~= "LIMITED") then
			if (self.hmiLevel ~= "FULL") then
				ActivationApp(self)

				-- UPDATE!
				-- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
				EXPECT_NOTIFICATION("OnHMIStatus",
									{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
									{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 2 then
						self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
															{reason = "SUSPEND"})
				
						print("\27[31m CHECK_2: How application becomes in LIMITED???? \27[0m")
					
						--Requirement id in JAMA/or Jira ID: APPLINK-15702
						--Send BC.OnPersistanceComplete to HMI on data persistance complete			
						-- hmi side: expect OnSDLPersistenceComplete notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
					end
				end)
				-- hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
			
			else 
				-- hmi side: sending BasicCommunication.OnAppDeactivated notification
				self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

				EXPECT_NOTIFICATION("OnHMIStatus",
									{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
														{reason = "SUSPEND"})

					--Requirement id in JAMA/or Jira ID: APPLINK-15702
					--Send BC.OnPersistanceComplete to HMI on data persistance complete			
					-- hmi side: expect OnSDLPersistenceComplete notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
				end)
			end
		elseif ( (targetLevel == "LIMITED" and self.hmiLevel == "LIMITED") or
				 (targetLevel == "FULL"    and self.hmiLevel == "FULL")    or
				  targetLevel == nil) then
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
												{reason = "SUSPEND"})

			--Requirement id in JAMA/or Jira ID: APPLINK-15702
			--Send BC.OnPersistanceComplete to HMI on data persistance complete			
			-- hmi side: expect OnSDLPersistenceComplete notification
			EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
		end
	end

	local function OnAwakeSDL(self, wait_time)
		if(wait_time == nil) then
			wait_time = 30*1000
		end
		
		local function to_run()
			self.hmiConnection:SendNotification("BasicCommunication.OnAwakeSDL",{})
		end

		RUN_AFTER(to_run, wait_time)
	end

	local function RegisterApp_HMILevelResumption(self, HMILevel, reason, iresultCode, resumeGrammars)
		local local_HMIAppID
		local AppValuesOnHMIStatus
		
		if HMILevel == "FULL" then
			AppValuesOnHMIStatus = AppValuesOnHMIStatusFULL
		elseif HMILevel == "LIMITED" then
			AppValuesOnHMIStatus = AppValuesOnHMIStatusLIMITED
		end

		if iresultCode == nil then 
			iresultCode = "SUCCESS"
		end 

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		-- got time after RAI request
		time =  timestamp()

		if reason == "IGN_OFF" then
			local RAIAfterOnReady = time - self.timeOnReady
			userPrint( 33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))
		end

		-- Requirement id in JAMA/or Jira ID: APPLINK-15958
		-- [Data Resumption] hmi_appID must be the same for the application between ignition cycles 		
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
			--        is resolved. The issue is checked only on Genivi
			local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			if(exp.occurences == 2)	then 
				--userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
			end


			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID

			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode})
		end)
		:Times(1)


		if HMILevel == "FULL" then
			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)
		      	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)
		elseif HMILevel == "LIMITED" then
			EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		end

		EXPECT_NOTIFICATION("OnHMIStatus",{})
		:Do(function(_,data)
			self.hmiLevel = data.payload.hmiLevel
		end)
	end

	local function ResumedDataAfterRegistration(self)
		--Requirement id in JAMA/or Jira ID: APPLINK-15689
		--[Data Resumption]: Data Persistance
		
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 1,		
			menuParams = 
			{
				position = 0,
				menuName ="Command1"
			}
		})
		:Do(function(_,data)
			local AddcommandTime = timestamp()
			local ResumptionTime =  AddcommandTime - time
			userPrint(33, "Time to resume UI.AddCommand "..tostring(ResumptionTime))
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 1,							
			type = "Command",
			vrCommands = 
			{
				"VRCommand1"
			}
		},
		{ 
			cmdID = 1,							
			type = "Choice",
			vrCommands = 
			{
				"VrChoice1"
			}
		})
		:Do(function(exp,data)
			if exp.occurences == 1 then
					local AddcommandTime = timestamp()
					local ResumptionTime =  AddcommandTime - time
					userPrint(33, "Time to resume VR.AddCommand "..tostring(ResumptionTime))
			elseif
				exp.occurences == 2 then
					local CreateInteractionChoiceSetTime = timestamp()
					local ResumptionTime =  CreateInteractionChoiceSetTime - time
					userPrint(33, "Time to resume VR.AddCommand from choice "..tostring(ResumptionTime))
			end
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu", 
		{ 
			menuID = 1,
			menuParams = {
				position = 500,
				menuName = "SubMenupositive1"
			}
		})
		:Do(function(_,data)
			local AddSubMenuTime = timestamp()
			local ResumptionTime =  AddSubMenuTime - time
			userPrint(33, "Time to resume UI.AddSubMenu "..tostring(ResumptionTime))
			--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true, 
			name = "CUSTOM_BUTTON"
		},
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true, 
			name = "PRESET_0"
		})
		:Times(2)
		:Do(function(exp,data)
			if exp.occurences == 2 then
				local SubscribeButtonTime = timestamp()
				local ResumptionTime =  SubscribeButtonTime - time
				userPrint(33, "Time to resume SubscribeButton "..tostring(ResumptionTime))
			end
		end)

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
		:Do(function(_,data)
			local SubscribeVehicleDataTime = timestamp()
			local ResumptionTime =  SubscribeVehicleDataTime - time
			userPrint(33, "Time to resume SubscribeVehicleData "..tostring(ResumptionTime))
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{},
		{
			timeoutPrompt = 
			{
				{
					text = "Timeout prompt",
					type = "TEXT"
				}
			},
			helpPrompt = 
			{
				{
					text = "Help prompt",
					type = "TEXT"
				}
			}
		})
		:Do(function(exp,data)
			if exp.occurences == 2 then
				local SetGlobalPropertiesTime = timestamp()
				local ResumptionTime =  SetGlobalPropertiesTime - time
				userPrint(33, "Time to resume TTS.SetGlobalProperties "..tostring(ResumptionTime))
			end
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			menuTitle = "Menu Title",
			vrHelp = 
			{
				{
					position = 1,
					text = "VR help item"
				}
			},
			vrHelpTitle = "VR help title"
		})
		:Do(function(_,data)
			local SetGlobalPropertiesTime = timestamp()
			local ResumptionTime =  SetGlobalPropertiesTime - time
			userPrint(33, "Time to resume UI.SetGlobalProperties "..tostring(ResumptionTime))
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	end

	local function AddDataForResumption(self)
		----------------------------------------------
		-- 20 commands, submenus, InteractionChoices
		----------------------------------------------
		for i=1, 20 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
										{
											cmdID = i,
											menuParams = 	
														{
															position = 0,
															menuName ="Command" .. tostring(i)
														}, 
											vrCommands = {"VRCommand" .. tostring(i)}
										})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
										{
											menuID = i,
											position = 500,
											menuName = "SubMenupositive" .. tostring(i)
										})

			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = i,
											choiceSet = 
														{ 									
															{ 
																choiceID = i,
																menuName = "Choice" .. tostring(i),
																vrCommands = 
																			{ 
																				"VrChoice" .. tostring(i)
																			}
														}	}
										})
		end

				
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(40)	
					
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
		:Times(20)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)
						
		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
		:Times(20)

		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
		:Times(20)

		----------------------------------------------
		-- subscribe button OK
		----------------------------------------------
		
					
		for m = 1, #buttonName do
		 	-- print("buttonName["..m .."] = "..buttonName[m])
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",{ buttonName = buttonName[m] })
		end 
					
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true				
		})
		:Times(#buttonName)

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE("SubscribeButton", { success = true, resultCode = "SUCCESS" })
		:Times(#buttonName)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{ gps = true})
					

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
		end)

				
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})

		----------------------------------------------
		-- SetGlobalProperites
		----------------------------------------------

		--mobile side: sending SetGlobalProperties request
		self.mobileSession:SendRPC("SetGlobalProperties",
						{
							menuTitle = "Menu Title",
							timeoutPrompt = 
							{
								{
									text = "Timeout prompt",
									type = "TEXT"
								}
							},
							vrHelp = 
							{
								{
									position = 1,
									text = "VR help item"
								}
							},
							helpPrompt = 
							{
								{
									text = "Help prompt",
									type = "TEXT"
								}
							},
							vrHelpTitle = "VR help title",
						})


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
									{
										timeoutPrompt = 
										{
											{
												text = "Timeout prompt",
												type = "TEXT"
											}
										},
										helpPrompt = 
										{
											{
												text = "Help prompt",
												type = "TEXT"
											}
										}
									})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
									{
										menuTitle = "Menu Title",
										vrHelp = 
										{
											{
												position = 1,
												text = "VR help item"
											}
										},
										vrHelpTitle = "VR help title"
									})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = true, resultCode = "SUCCESS"})

		--mobile side: expect OnHashChange notification
		--Times: After all EXPECT_RESPONSE(SUCCESS)
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(62 + #buttonName)
	end

	local function CheckPersistentData(self)
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF	

		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)

		local UIAddCommandValues = {}
		for m=1,20 do
			UIAddCommandValues[m] = {cmdID = m, menuParams = { menuName ="Command" .. tostring(m)}}
		end

		----------------------------------------------
		-- 20 commands, InteractionChoices
		----------------------------------------------
				
		EXPECT_HMICALL("UI.AddCommand")
		:ValidIf(function(_,data)
			for i=1, #UIAddCommandValues do
				if 
					data.params.cmdID == UIAddCommandValues[i].cmdID and
					data.params.menuParams.position == 0 and
					data.params.menuParams.menuName == UIAddCommandValues[i].menuParams.menuName then
					return true
				elseif (i == #UIAddCommandValues) then
					userPrint(31, "Any matches")
					userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', position = '" .. tostring(data.params.menuParams.position) .. "', menuName = '" .. tostring(data.params.menuParams.menuName ) .. "'"  )
					return false
				end

			end
		end)
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)

		local VRAddCommandValues = {}
		for m=1,20 do
			VRAddCommandValues[m] = {cmdID = m, vrCommands = {"VRCommand" .. tostring(m)}}
		end

		local Choices = {}
		for m=1,20 do
			Choices = {cmdID = m, vrCommands = {"VrChoice" .. tostring(m)}}
		end

		EXPECT_HMICALL("VR.AddCommand")
		:ValidIf(function(_,data)
			if data.params.type == "Command" then
				for i=1, #VRAddCommandValues do
					if ( data.params.cmdID == VRAddCommandValues[i].cmdID ) and
					   ( data.params.appID == HMIAppID ) and
					   ( data.params.vrCommands[1] == VRAddCommandValues[i].vrCommands[1] ) then
						return true
					elseif (i == #VRAddCommandValues) then
						userPrint(31, "Any matches")
						userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', vrCommands[1]  = '" .. tostring(data.params.vrCommands[1] ) .. "'"  )
						return false
					end
				end
			elseif ( data.params.type == "Choice" ) then
				for i=1, #Choices do
					if (data.params.cmdID == Choices[i].cmdID) and
					   (data.params.appID == HMIAppID ) and
					   (data.params.vrCommands[1] == Choices[i].vrCommands[1] ) then
						return true
					elseif (i == #Choices ) then
						userPrint(31, "Any matches")
						userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', vrCommands[1]  = '" .. tostring(data.params.vrCommands[1] ) .. "'"  )
						return false
					end
				end
			else
				userPrint(31, "VR.AddCommand request came with wrong type " .. tostring(data.params.type))
				return false
			end
		end)
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(40)

		EXPECT_RESPONSE("AddCommand")
		:Times(0)

		EXPECT_RESPONSE("CreateInteractionChoiceSet")
		:Times(0)

		local SubMenuValues = {}
		for m=1,20 do
			SubMenuValues[m] = { menuID = m,menuParams = {position = 500,menuName = "SubMenupositive" ..tostring(m)}}
		end

		----------------------------------------------
		-- 20 submenus
		----------------------------------------------

		EXPECT_HMICALL("UI.AddSubMenu")
		:ValidIf(function(_,data)
			for i=1, #SubMenuValues do
				if  (data.params.menuID == SubMenuValues[i].menuID ) and
					(data.params.menuParams.position == 500 ) and
					(data.params.menuParams.menuName == SubMenuValues[i].menuParams.menuName ) then
					return true
				elseif (i == #SubMenuValues) then
					userPrint(31, "Any matches")
					userPrint(31, "Actual values menuID ='" .. tostring(data.params.menuID) .. "', position = '" .. tostring(data.params.menuParams.position) .. "', menuName = '" .. tostring(data.params.menuParams.menuName ) .. "'"  )
					return false
				end
			end
		end)
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)

		EXPECT_RESPONSE("AddSubMenu")
		:Times(0)

		----------------------------------------------
		-- SetGlbalProperties
		----------------------------------------------

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
						{},
						{
							timeoutPrompt = 
							{
								{
									text = "Timeout prompt",
									type = "TEXT"
							}	},
							helpPrompt = 
									{
										{
											text = "Help prompt",
											type = "TEXT"
									}	}
						})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = "Menu Title",
							vrHelp = 
							{
								{
									position = 1,
									text = "VR help item" 
							}	},
							vrHelpTitle = "VR help title"
						})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties")
		:Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
		end)

		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData")
		:Times(0)
		 
		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:ValidIf(function(_,data)
			for i=1, #buttonName do
				if (data.params.name == "CUSTOM_BUTTON" and
					data.params.isSubscribed == true and
					data.params.appID == HMIAppID ) then

					return true
				elseif (data.params.name == buttonName[i] and
						data.params.isSubscribed == true and
						data.params.appID == HMIAppID ) then
						
					return true
				elseif (i == #buttonName) then
					userPrint(31, "Any matches")
					userPrint(31, "Actual values name ='" .. tostring(data.params.name) .. "', isSubscribed = '" .. tostring(data.params.isSubscribed) .. "', appID = '" .. tostring(data.params.appID) .. "'")
					return false
				end

			end
		end)
		:Times(#buttonName + 1)

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

	local function CheckNoDataResumption(self, performRAI)

		if(performRAI == nil) then
			performRAI = true
		end

		userPrint(34, "=================== Test Case ===================")

		if(performRAI == true)	then
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)
		end

		----------------------------------------------
		-- NO Data resumption; except Buttons.OnButtonSubscription(CUSTOM_BUTTON)
		-- Exception: APPLINK-20120
		----------------------------------------------
		EXPECT_HMICALL("UI.AddCommand")
		:Times(0)

		EXPECT_HMICALL("VR.AddCommand")
		:Times(0)

		EXPECT_RESPONSE("AddCommand")
		:Times(0)

		EXPECT_RESPONSE("CreateInteractionChoiceSet")
		:Times(0)

		EXPECT_HMICALL("UI.AddSubMenu")
		:Times(0)

		EXPECT_RESPONSE("AddSubMenu")
		:Times(0)

		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Times(0)

		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Times(0)

		EXPECT_RESPONSE("SetGlobalProperties")
		:Times(0)

		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
		:Times(0)
		 
		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
			
		if(performRAI == true)	then
			--expect Buttons.OnButtonSubscription
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
			:ValidIf(function(_,data)
				if (data.params.name == "CUSTOM_BUTTON") then
					return true
				else
					return false
				end				
			end)
			:Times(1)

			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		else
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
		end
	end

	local function CheckSavedDataInAppInfoDat(self, ign_cycle)
		--Requirement id in JAMA/or Jira ID: APPLINK-15703
		--[Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption 

		--Requirement id in JAMA/or Jira ID: APPLINK-15930
		--[Data Resumption]:Database for resumption-related data 

				
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable
		local file = io.open(config.pathToSDL .."app_info.dat",r)
		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)
		os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_ign_off_" ..  (ign_cycle-1) )
				
		if(resumptionDataTable.resumption.resume_app_list ~= nil) then
			for p = 1, #resumptionDataTable.resumption.resume_app_list do
				if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
					resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
				end

				if(resumptionDataTable.resumption.resume_app_list[p].ign_off_count ~= nil) then
					if(resumptionDataTable.resumption.resume_app_list[p].ign_off_count ~=  (ign_cycle) ) then
						--userPrint(31, "DEFECT ID: New defect!")
						self:FailTestCase("ign_off_count is not incremented as expected: " .. (ign_cycle) .. "; Real: " .. resumptionDataTable.resumption.resume_app_list[p].ign_off_count)
					end
				else
					self:FailTestCase("ign_off_count is not saved!")
				end
			end

			if ( resumptionAppData.applicationChoiceSets and #resumptionAppData.applicationChoiceSets ~= 20) then
					self:FailTestCase("Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected 20")
			elseif (resumptionAppData.applicationCommands and #resumptionAppData.applicationCommands ~= 20) then
					self:FailTestCase("Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected 20" )
			elseif (resumptionAppData.applicationSubMenus and #resumptionAppData.applicationSubMenus ~= 20) then
					self:FailTestCase("Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected 20")
			elseif ( resumptionAppData.subscribtions and resumptionAppData.subscribtions.buttons and #resumptionAppData.subscribtions.buttons ~= #buttonName + 1) then
					self:FailTestCase("Wrong number of SubscribeButtons saved in app_info.dat" ..tostring(#resumptionAppData.subscribtions.buttons) .. ", expected " .. tostring(#buttonName + 1))
			elseif (resumptionAppData.globalProperties and
					resumptionAppData.globalProperties.helpPrompt[1].text ~= "Help prompt" or
					resumptionAppData.globalProperties.timeoutPrompt[1].text ~= "Timeout prompt" or
					resumptionAppData.globalProperties.menuTitle ~= "Menu Title" or
					resumptionAppData.globalProperties.vrHelp[1].text ~= "VR help item" or
					resumptionAppData.globalProperties.vrHelpTitle ~= "VR help title") then
				self:FailTestCase("Wrong GlobalPropeerties saved in app_info.dat . Expected helpPrompt[1].text = 'Help prompt', got " .. tostring(resumptionAppData.globalProperties.helpPrompt[1].text) .. ", expected timeoutPrompt[1].text = 'Timeout prompt', got " .. tostring(resumptionAppData.globalProperties.timeoutPrompt[1].text) .. ", expected menuTitle = 'menuTitle', got " .. tostring(resumptionAppData.globalProperties.menuTitle) ..", expected vrHelp[1].text = 'VR help item then', got " .. tostring(resumptionAppData.globalProperties.vrHelp[1].text) .. ", expected vrHelpTitle = 'VR help title', got " ..tostring(resumptionAppData.globalProperties.vrHelpTitle))
			end
		else
			os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_Test_CheckSavedDataInAppInfoDat" )
			self:FailTestCase("Resumption application list is empty!")
		end
	end

	local function CheckNoDataInAppInfoDat(self, ign_cycle)
		--Requirement id in JAMA/or Jira ID: APPLINK-15991
		--[Data Resumption] Persistance Data clean up trigger 

		--Requirement id in JAMA/or Jira ID: APPLINK-15930
		--[Data Resumption]:Database for resumption-related data 

				
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable
		local file = io.open(config.pathToSDL .."app_info.dat",r)
		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)
		os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_ign_off_" ..  (ign_cycle-1) )
				
		if(resumptionDataTable.resumption.resume_app_list ~= nil) then
			for p = 1, #resumptionDataTable.resumption.resume_app_list do
				
				self:FailTestCase("Application with appID = " .. resumptionDataTable.resumption.resume_app_list[p].appID .. " is saved in app_info.dat")
			end
		else
			os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_Test_CheckSavedDataInAppInfoDat" )
			self:FailTestCase("Resumption application list is empty!")
		end
	end

	local function Resumption_IGN_OFF_counts()
		for ign_cycle = 1 , 5 do		

			if(ign_cycle == 1) then
				function Test:UnregisterAppInterface_Success()

					userPrint(35, "================= Test Case: Check saved data in app_info.dat after IGN_OFF  =====================")
					userPrint(35, "======================================= Precondition =============================================")
					userPrint(35, "======================================= IGN Cycle "..ign_cycle.." ==========================================")					
					UnregisterAppInterface(self)
				end

				Test["IGNcycle_".. tostring(ign_cycle) .. "_RegisterAppInterface_Success"] = function(self)

					RegisterApp_WithoutHMILevelResumption(self, _, false)
				end
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_ActivateApp"] = function(self)
				
				if(ign_cycle > 1) then
					userPrint(35, "================= Test Case: Check saved data in app_info.dat after IGN_OFF  =====================")
					userPrint(35, "======================================= Precondition =============================================")
					userPrint(35, "======================================= IGN Cycle "..ign_cycle.." ==========================================")					
				end
				
				ActivationApp(self)

				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
			      :Do(function(_,data)
			        self.hmiLevel = data.payload.hmiLevel
			      end)
			end

			if(ign_cycle == 1) then
				Test["IGNcycle_".. tostring(ign_cycle) .. "_ResumptionData"] = function(self)
					AddDataForResumption(self)
				end
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_SUSPEND"] = function(self)
				SUSPEND(self)
				DelayedExp(1000)
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_IGNITION_OFF"] = function(self)

				IGNITION_OFF(self)
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_CheckSavedDataInAppInfoDat"] = function(self)
				if( ign_cycle  <= 3) then
					CheckSavedDataInAppInfoDat(self, ign_cycle)
				else
					CheckNoDataInAppInfoDat(self, ign_cycle)
				end
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_StartSDL"] = function(self)

				StartSDL(config.pathToSDL, config.ExitOnCrash)
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_InitHMI"] = function(self)

				self:initHMI()
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_InitHMI_onReady"] = function(self)

				self:initHMI_onReady()
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_ConnectMobile"] = function(self)

				self:connectMobile()
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_StartSession"] = function(self)
				CreateSession(self)

				self.mobileSession:StartService(7)
			end

			Test["IGNcycle_".. tostring(ign_cycle) .. "_PersistantData"] = function(self)
				if( ign_cycle  <= 3) then
					CheckPersistentData(self)
				else
					CheckNoDataResumption(self)
				end
			end
		end -- END for ign_cycle = 1 , 5 do
	end

	local function NoResumption_IGN_OFF_5counts_TM_disconnect()

		function Test:ActivateApp_TM_disconnect()
			userPrint(35, "================= Test Case: No Resumption at TM disconnect when IGN_OFF > 3 counts ==================")
			userPrint(35, "======================================= Precondition =================================================")
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      	:Do(function(_,data)
	        	self.hmiLevel = data.payload.hmiLevel
	      	end)
		end


		function Test:AddData_TM_disconnect()

			AddDataForResumption(self)
		end

		function Test:CloseConnection_TM_disconnect()

	  		self.mobileConnection:Close() 
		end

		function Test:ConnectMobile_TM_disconnect()

			self:connectMobile()
		end

		function Test:StartSession()
	   		self.mobileSession = mobile_session.MobileSession(
	      														self,
	      														self.mobileConnection,
	      														config.application1.registerAppInterfaceParams)

	  		self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_FULL_Disconnect_TM_disconnect()
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
			RegisterApp_HMILevelResumption(self, "FULL", _, _, true)
			CheckNoDataResumption(self, false)
			

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end
	end
	

	local function Resumption_DUPLICATE_NAME()
		function Test:UnregisterAppInterface_Success_DUPLICATE_NAME()
			userPrint(35, "================= Test Case: Check data resumption at policy: DUPLICATE_NAME ==================")
			userPrint(35, "======================================= Precondition ==========================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success_DUPLICATE_NAME()
			
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp_DUPLICATE_NAME()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
			:Do(function(_,data)
			    self.hmiLevel = data.payload.hmiLevel
			end)
		end

		function Test:ResumptionData_DUPLICATE_NAME()
			AddDataForResumption(self)
		end

		function Test:SUSPEND_DUPLICATE_NAME()
			SUSPEND(self)
			DelayedExp(1000)
		end

		function Test:IGNITION_OFF_DUPLICATE_NAME()

			IGNITION_OFF(self)
		end

		function Test:CheckSavedDataInAppInfoDat_DUPLICATE_NAME()

			CheckSavedDataInAppInfoDat(self, 1)
		end
	
		function Test:StartSDL_DUPLICATE_NAME()

			StartSDL(config.pathToSDL, config.ExitOnCrash)
		end
	
		function Test:InitHMI_DUPLICATE_NAME()

			self:initHMI()
		end

		function Test:InitHMI_onReady_DUPLICATE_NAME()

			self:initHMI_onReady()
		end

		function Test:ConnectMobile_DUPLICATE_NAME()

			self:connectMobile()
		end

		function Test:SecondConnection_DUPLICATE_NAME()
			self.mobileSession1 = mobile_session.MobileSession(
																self,
																self.mobileConnection,
																applicationData.SecondApp)
  		end

   		function Test:RegisterSecondApp_DUPLICATE_NAME()
   			self.mobileSession1:StartService(7)
			:Do(function(_,data)
				local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", applicationData.SecondApp)

				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
					--        is resolved. The issue is checked only on Genivi
					local SecondcorrelationId = self.mobileSession1:SendRPC("RegisterAppInterface", applicationData.SecondApp)
					if(exp.occurences == 2)	then 
						--userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
					end

					self.applications[applicationData.SecondApp] = data.params.application.appID	
				end)
				:Times(1)

				self.mobileSession1:ExpectResponse(correlationId, { success = true , resultCode = "SUCCESS"})
			end)
   		end

   		function Test:CheckNoDataResumptionFirstApp1_DUPLICATE_NAME()
   			--Requirement id in JAMA/or Jira ID: APPLINK-15690
   			--[Data Resumption]: SDL data resumption process start not earlier than Duplicate name and policy table permissions check 
   			CheckNoDataResumption(self, false)
   		end
	
		function Test:StartSessionFirstApp_DUPLICATE_NAME()
			CreateSession(self)
			self.mobileSession:StartService(7)
		end

   		function Test:CheckNoDataResumptionFirstApp2_DUPLICATE_NAME()

   			config.application1.registerAppInterfaceParams.appName = applicationData.SecondApp.appName
   			
   			--Requirement id in JAMA/or Jira ID: APPLINK-15690
   			--[Data Resumption]: SDL data resumption process start not earlier than Duplicate name and policy table permissions check 
   			CheckNoDataResumption(self, false)
   		end

   		function Test:PersistantDataCorrectNameFirstApp_DUPLICATE_NAME()
			config.application1.registerAppInterfaceParams.appName = "Test Application"
			
			CheckPersistentData(self,false)
   		end
	end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Check NO saved data in app_info.dat after IGN_OFF for 4 ignition cycles
	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Requirement id in JAMA/or Jira ID: APPLINK-15634
	--[Data Resumption]: Data resumption on IGNITION OFF more than 3 cycles

	--Requirement id in JAMA/or Jira ID: APPLINK-15991
	--[Data Resumption] Persistance Data clean up trigger 
	Resumption_IGN_OFF_counts()

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Check NO saved data in app_info.dat after IGN_OFF for 4 ignition cycles
	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Requirement id in JAMA/or Jira ID: APPLINK-15657
	--[Data Resumption]: Data resumption on Unexpected Disconnect 
	NoResumption_IGN_OFF_5counts_TM_disconnect()
	
	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Resumption check must be performed after all Policies rules and DUPLICATE_NAME check performed. 
	-- In case of invalid registation because of Policies rules resumption data must not be clean up.
	--////////////////////////////////////////////////////////////////////////////////////////////--
	--Requirement id in JAMA/or Jira ID: APPLINK-23977 	
	--[Data Resumption]: Policies rules check must be performed before Resumption process 

	--Requirement id in JAMA/or Jira ID: APPLINK-15992 	
	--[Data Resumption] Data persistance for an applicatiion failed to be re-registered 

	Resumption_DUPLICATE_NAME()

	function Test:Postcondition_RestoreIniFile()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end

