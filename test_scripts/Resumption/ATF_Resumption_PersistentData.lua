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
local mobile_session = require('mobile_session')
local commonSteps	  = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')
local json = require("json")



--Backup, updated preloaded file
-------------------------------------------------------------------------------------
	commonSteps:DeleteLogsFileAndPolicyTable()
	os.execute(" cp " .. config.pathToSDL .. "/sdl_preloaded_pt.json " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )

	f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "r"))

	fileContent = f:read("*all")

    -- default section
    DefaultContant = fileContent:match('"default".?:.?.?%{.-%}')

    if not DefaultContant then
      print ( " \27[31m  default group is not found in sdl_preloaded_pt.json \27[0m " )
    else
       DefaultContant =  string.gsub(DefaultContant, '".?groups.?".?:.?.?%[.-%]', '"groups": ["Base-4", "Location-1", "DrivingCharacteristics-3", "VehicleInfo-3", "Emergency-1"]')
    end

	fileContent  =  string.gsub(fileContent, '".?default.?".?:.?.?%{.-%}', DefaultContant)
	
	-- added SubscribeWayPoints, UnsubscribeWayPoints rps to Base-4 group
	Base4Group = fileContent:match('"Base%-4"%s-:%s-%{%s-"rpcs".?:.?.?%{')
	if not Base4Group then
      	print ( " \27[31m  Base-4 group is not found in sdl_preloaded_pt.json \27[0m " )
    else
    	fileContent =  string.gsub(fileContent, '"Base%-4"%s-:%s-%{%s-"rpcs".?:.?.?%{', '"Base-4": {"rpcs": { "SubscribeWayPoints": { "hmi_levels": ["BACKGROUND","FULL","LIMITED"]},"UnsubscribeWayPoints": {"hmi_levels": ["BACKGROUND", "FULL", "LIMITED"]},')
    end

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

	local mobileSessionForBackground = 
	{
		syncMsgVersion =
	    {
	      majorVersion = 3,
	      minorVersion = 3
	    },
	    appName = "AppForBackground",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "NAVIGATION", "COMMUNICATION" },
	    appID = "11223344",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
	    }
	}


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

	local function AddCommand(self, icmdID)
	
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
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
		EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
		:Do(function()
			--mobile side: expect OnHashChange notification
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
		end)
	end

	local function AddSubMenu(self, imenuID)
		--mobile side: sending AddSubMenu request
		local cid = self.mobileSession:SendRPC("AddSubMenu",
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
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function()
			--mobile side: expect OnHashChange notification
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
		end)
	end

	local function CreateInteractionChoiceSet(self, id)
		--mobile side: sending CreateInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = id,
												choiceSet = 
												{ 
													
													{ 
														choiceID = id,
														menuName = "Choice" .. tostring(id),
														vrCommands = 
														{ 
															"VrChoice" .. tostring(id),
														}
													}
												}
											})
	
		
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = id,
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						type = "Choice",
						vrCommands = {"VrChoice" ..tostring(id) }
					})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			grammarIDValue = data.params.grammarID
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	
		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function(_,data)
			
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)

		
	end

	local function SetGlobalProperites(self, prefix)
		--mobile side: sending SetGlobalProperties request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
											{
												menuTitle = "Menu Title" .. tostring(prefix),
												timeoutPrompt = 
												{
													{
														text = "Timeout prompt" .. tostring(prefix),
														type = "TEXT"
													}
												},
												vrHelp = 
												{
													{
														position = 1,
														text = "VR help item" .. tostring(prefix)
													}
												},
												helpPrompt = 
												{
													{
														text = "Help prompt" .. tostring(prefix),
														type = "TEXT"
													}
												},
												vrHelpTitle = "VR help title" .. tostring(prefix),
											})


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						timeoutPrompt = 
						{
							{
								text = "Timeout prompt" .. tostring(prefix),
								type = "TEXT"
							}
						},
						helpPrompt = 
						{
							{
								text = "Help prompt" .. tostring(prefix),
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
						menuTitle = "Menu Title" .. tostring(prefix),
						vrHelp = 
						{
							{
								position = 1,
								text = "VR help item" .. tostring(prefix)
							}
						},
						vrHelpTitle = "VR help title" .. tostring(prefix)
					})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)

			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end

	local function SubscribleButton(self, btnName)
		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
		{
			buttonName = btnName

		})

		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true, 
			name = btnName
		})

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end
 
	local function SubscribleVehicleData(self, requestParam)
	
		local response = {}
		local request = {}

		request[requestParam] = true

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	
		response[requestParam] =
		{
			resultCode = "SUCCESS",
			dataType = SVDValues[requestParam]
		} 

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
		end)
	
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end

	local function SubscribleWayPoints(self)
		
		local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})

		--hmi side: expected SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending Navigation.SubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: SubscribeWayPoints response
		EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
		:Do(function(_,data)
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange

			--userPrint(31,"DEFECT ID: APPLINK-25808")
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end
	
	local function DeleteCommand(self, icmdID)
		--mobile side: sending DeleteCommand request
		local cid = self.mobileSession:SendRPC("DeleteCommand",
		{
			cmdID = icmdID
		})
	
		--hmi side: expect UI.DeleteCommand request
		EXPECT_HMICALL("UI.DeleteCommand", 
		{ 
			cmdID = icmdID,
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
		:Do(function(_,data)
			--hmi side: sending UI.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	
		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand", 
		{ 
			cmdID = icmdID,
			type = "Command"
		})
		:Do(function(_,data)
			--hmi side: sending VR.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
				
		--mobile side: expect DeleteCommand response 
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function(_,data)
		
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	
	end

	local function DeleteSubMenu(self, imenuID)
		--mobile side: sending DeleteSubMenu request
		local cid = self.mobileSession:SendRPC("DeleteSubMenu",
											{
												menuID = imenuID
											})
		--hmi side: expect UI.DeleteSubMenu request
		EXPECT_HMICALL("UI.DeleteSubMenu", 
					{ 
						menuID = imenuID
					})
		:Do(function(_,data)
			--hmi side: sending UI.DeleteSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect DeleteSubMenu response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function(_,data)
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	
	end

	local function DeleteInteractionChoiceSet(self, id)
		--mobile side: sending DeleteInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																		{
																			interactionChoiceSetID = id
																		})
	
		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand", {cmdID = id, type = "Choice"})
		:Do(function(_,data)
			--hmi side: sending VR.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
				
		--mobile side: expect DeleteInteractionChoiceSet response 
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function(_,data)
			--mobile side: expect OnHashChange notification
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
		end)
	end

	local function ResetGlobalProperties(self)

		--mobile side: sending ResetGlobalProperties request
		local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
		{
			properties = 
			{
				"VRHELPTITLE",
				"MENUNAME",
				"VRHELPITEMS",
				"HELPPROMPT",
				"TIMEOUTPROMPT"
			}
		})
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			-- helpPrompt = {},
			timeoutPrompt = 
			{
				{
					type = "TEXT",
					text = textPromtValue[1]
				},
				{
					type = "TEXT",
					text = textPromtValue[2]
				}
			}
		})
		:Do(function(_,data)
			--hmi side: sending TTS.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			menuTitle = "",
			vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
			vrHelp = nil
		})	
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)				

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	
		end)
	end

	local function UnsubscribeButton(self, btnName)
		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = btnName
			}
		)

		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = btnName, isSubscribed = false})

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end

	local function UnsubscribeVehicleData(self, requestParam)
		local response = {}
		local request = {}

		request[requestParam] = true

		--mobile side: sending UnsubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
	
		--hmi side: expect UnsubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request)
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
		end)

		response[requestParam] =
		{
			resultCode = "SUCCESS",
			dataType = SVDValues[requestParam]
		}
	
		--mobile side: expect UnsubscribeVehicleData response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end
	
	local function UnsubscribeWayPoints(self)
		
		--mobile side: send UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
		
		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending Navigation.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
		
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			--mobile side: expect OnHashChange notification

			--userPrint(31,"DEFECT ID: APPLINK-25808")
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
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
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {resumeVrGrammars = resumeGrammars} )
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
			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode, info = "Resume succeeded."})--info = " Resume Succeed"})
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
				end)
        	end
        end)
	end

	local function CreateSession( self)
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

				EXPECT_NOTIFICATION("OnHMIStatus",
									{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
									{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 2 then
						self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
															{reason = "SUSPEND"})
				
					
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
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								{
									resumeVrGrammars = resumeGrammars,
									application = { appID = HMIAppID }
								})
		:Do(function(_,data)
			-- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
			--        is resolved. The issue is checked only on Genivi
			local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			if(exp.occurences == 2)	then 
				--userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
			end


			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)
		:Times(1)

		if (resumeGrammars == false) then
			--Requirement id in JAMA/or Jira ID: APPLINK-15686
			--[Data Resumption]: SDL data resumption failure
			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode})
		elseif (resumeGrammars == true) then
			--Requirement id in JAMA/or Jira ID: APPLINK-15683
			--[Data Resumption]: SDL data resumption SUCCESS sequence
			
			-- TODO: APPLINK-26128: "info" parameter shall be updated
			self.mobileSession:ExpectResponse(correlationId, { success = true , resultCode = iresultCode, info = "Resume succeeded."})--info = " Resume Succeed"})
		end

		if HMILevel == "FULL" then
			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)
		      	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)
		elseif HMILevel == "LIMITED" then
			EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		end

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusDEFAULT, AppValuesOnHMIStatus)
		:ValidIf(function(exp,data)
			if	exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - time
		  		if timeToresumption >= 3000 and
		  		 	timeToresumption < 3500 then 
		    		userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
		  			return true
		  		else 
		  			userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
	end

	local function BringAppToNoneLevel(self)
		if self.hmiLevel ~= "NONE" then
			-- hmi side: sending BasicCommunication.OnExitApplication request
			local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName],
				reason = "USER_EXIT"
			})

			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
		end
	end
	
	local function BringAppToLimitedLevel(self)
		if ( self.hmiLevel ~= "FULL" and self.hmiLevel ~= "LIMITED") then
      		ActivationApp(self)
			
	      	EXPECT_NOTIFICATION("OnHMIStatus",
	        		{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
	        		{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
	        :Do(function(_,data)
	          	self.hmiLevel = data.payload.hmiLevel
	        end)
	        :Times(2)
    	else 
        	EXPECT_NOTIFICATION("OnHMIStatus",
        					{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
        	:Do(function(_,data)
            	self.hmiLevel = data.payload.hmiLevel
        	end)
    	end
 		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], reason = "GENERAL"})
	end

	local function BringAppToBackgroundLevel(self)
		if  
	  		config.application1.registerAppInterfaceParams.isMediaApplication == true or
	  		self.appHMITypes["NAVIGATION"] == true or
	  		self.appHMITypes["COMMUNICATION"] == true then 

		  		if 
			    	self.hmiLevel == "NONE" then
		      			ActivationApp(self)
		      			EXPECT_NOTIFICATION("OnHMIStatus", 
		      				AppValuesOnHMIStatusFULL,
		      				{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
			      			:Do(function()
			    				local cidUnregister = self.mobileSessionForBackground:SendRPC("UnregisterAppInterface",{})

								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[mobileSessionForBackground.appName]})

								self.mobileSessionForBackground:ExpectResponse(cidUnregister, { success = true, resultCode = "SUCCESS"})
								:Timeout(2000)
								:Do(function() self.mobileSessionForBackground:Stop() end)
			    			end)
		    	else 
		    		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
		    		:Do(function()
		    			local cidUnregister = self.mobileSessionForBackground:SendRPC("UnregisterAppInterface",{})

		    			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[mobileSessionForBackground.appName]})

						self.mobileSessionForBackground:ExpectResponse(cidUnregister, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function() self.mobileSessionForBackground:Stop() end)
		    		end)
		    	end

		    	self.mobileSessionForBackground = mobile_session.MobileSession(
																			self,
																			self.mobileConnection,
																			mobileSessionForBackground)


	        	self.mobileSessionForBackground:Start()
	        	:Do(function()
	        		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		     			:Do(function(_,data)
		     				self.applications[mobileSessionForBackground.appName] = data.params.application.appID
		     				HMIAppID = data.params.application.appID
		     			end)

		     		self.mobileSessionForBackground:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
		     																		  {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
		     		:Do(function()
		     			-- hmi side: sending SDL.ActivateApp request
					    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[mobileSessionForBackground.appName]})
					 
					 	-- hmi side: expect SDL.ActivateApp response
					    EXPECT_HMIRESPONSE(RequestId)

		     		end)
		     		:Times(2)
	        	end)
		elseif ( config.application1.registerAppInterfaceParams.isMediaApplication == false) then
		  	if ( self.hmiLevel == "NONE") then
		      	ActivationApp(self)
		      	EXPECT_NOTIFICATION("OnHMIStatus", 
		      						AppValuesOnHMIStatusFULL,
		      						{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
		      						)
		    else 
		    	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
		    end

		    -- hmi side: sending BasicCommunication.OnAppDeactivated request
			local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
															{
																appID = self.applications[config.application1.registerAppInterfaceParams.appName],
																reason = "GENERAL"
															})
		end
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

--////////////////////////////////////////////////////////////////////////////////////////////--
-- OnHashChanged() notification is sent to mobile after sending requests
--////////////////////////////////////////////////////////////////////////////////////////////--

	function Test:ActivationApp()
    	userPrint(35, "================= Test Group: OnHashChanged() notification is sent to mobile after sending requests ==================")
    	userPrint(35, "============================================= Precondition ===========================================================")

		-- hmi side: sending SDL.ActivateApp request
	  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

	  	-- hmi side: expect SDL.ActivateApp response
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

		--mobile side: expect OnHMIStatus notification
	  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)

  	end

	--======================================================================================--
	--AddCommand 
	--======================================================================================--
	function Test:OnHashChange_AddCommand()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		AddCommand(self, 1)
	end

	--======================================================================================--
	--AddSubMenu 
	--======================================================================================--

	function Test:OnHashChange_AddSubMenu()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		AddSubMenu(self, 1)
	end

	--======================================================================================--
	--CreateInteractionChoiceSet 
	--======================================================================================--

	function Test:OnHashChange_CreateInteractionChoiceSet()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		CreateInteractionChoiceSet(self, 1)
	end

	--======================================================================================--
	--SetGlobalProperites 
	--======================================================================================--

	function Test:OnHashChange_SetGlobalProperites()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		SetGlobalProperites(self, "")
	end
	
	--======================================================================================--
	--SubscribleButton 
	--======================================================================================--

	function Test:OnHashChange_SubscribleButton()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		SubscribleButton(self, "PRESET_0")
	end

	--======================================================================================--
	--SubscribleVehicleData 
	--======================================================================================--

	function Test:OnHashChange_SubscribleVehicleData()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		SubscribleVehicleData(self, "gps")
	end

	--======================================================================================--
	--SubscribleWayPoints 
	--======================================================================================--

	function Test:OnHashChange_SubscribleWayPoints()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		SubscribleWayPoints(self)
	end
	
	--======================================================================================--
	--DeleteCommand 
	--======================================================================================--

	function Test:OnHashChange_DeleteCommand()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		DeleteCommand(self, 1)
	end

	--======================================================================================--
	--DeleteSubMenu 
	--======================================================================================--

	function Test:OnHashChange_DeleteSubMenu()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		DeleteSubMenu(self, 1)
	end

	--======================================================================================--
	--DeleteInteractionChoiceSet 
	--======================================================================================--

	function Test:OnHashChange_DeleteInteractionChoiceSet()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		DeleteInteractionChoiceSet(self, 1)
	end

	--======================================================================================--
	--ResetGlobalProperties 
	--======================================================================================--

	function Test:OnHashChange_ResetGlobalProperties()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		ResetGlobalProperties(self)
	end

	--======================================================================================--
	--UnsubscribeButton 
	--======================================================================================--

	function Test:OnHashChange_UnsubscribeButton()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		UnsubscribeButton(self, "PRESET_0")
	end

	--======================================================================================--
	--UnsubscribeVehicleData 
	--======================================================================================--

	function Test:OnHashChange_UnsubscribeVehicleData()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		userPrint(34, "=================== Test Case ===================")
		UnsubscribeVehicleData(self, "gps")
	end

	--======================================================================================--
	--UnsubscribeWayPoints 
	--======================================================================================--

	function Test:OnHashChange_UnsubscribeWayPoints()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange		
		UnsubscribeWayPoints(self)
	end
	
	function Test:CloseConnection()
		userPrint(35, "================= Test:Resumption_data ==================")
		userPrint(35, "====================== Precondition =====================")
	  	self.mobileConnection:Close() 
	end

	function Test:ConnectMobile()
		self:connectMobile()
	end

	function Test:StartSession()
	   self.mobileSession = mobile_session.MobileSession(
															self,
															self.mobileConnection,
															config.application1.registerAppInterfaceParams
														)
	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data()
		--Requirement id in JAMA/or Jira ID: APPLINK-15987
		--[Data Resumption] Application data must not be resumed
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", _, _, true)

		EXPECT_HMICALL("UI.AddCommand")
		:Times(0)

		EXPECT_HMICALL("VR.AddCommand")
		:Times(0)

		EXPECT_HMICALL("UI.AddSubMenu")
		:Times(0)

		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Times(2)

		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Times(0)

		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON"})

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- OnHashChanged() is absent after unsuccess result code
--////////////////////////////////////////////////////////////////////////////////////////////--
	--======================================================================================--
	-- Unsuccess code from SDL 
	--======================================================================================--
	function Test:UnregisterAppInterface_Success()
		userPrint(35, "=================== Test Group: Unsuccess code from SDL ===================")
		userPrint(35, "============================== Precondition ===============================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end


	function Test:ActivateApp()
		

		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:OnHashChange_absent_AddCommand_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 1
		})
	
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_AddSubMenu_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending AddSubMenu request
		local cid = self.mobileSession:SendRPC("AddSubMenu",
												{
													menuID = 1
												})

		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

		--mobile side: expect OnHashChange notification
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end

	function Test:OnHashChange_absent_CreateInteractionChoiceSet_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
			
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending CreateInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
												{
													interactionChoiceSetID = 1
												})
		
			
		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Times(0)
	end

	function Test:OnHashChange_absent_SetGlobalProperites_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending SetGlobalProperties request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
												{
													menuTitle = 111
												})


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end
	
	function Test:OnHashChange_absent_SubscribleButton_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending SubscribeButton request
		local cid = self.mobileSession:SendRPC("SubscribeButton",
			{
				buttonName = "Button_Name"

			})

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
 
	function Test:OnHashChange_absent_SubscribleVehicleData_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{gps = "1"})
		
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
	
	--[[TODO: Uncomment when     APPLINK-26159: ATF stops at protocol value deviation is fixed
	function Test:OnHashChange_absent_SubscribeWayPoints_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
	    self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		--mobile side: SubscribeWayPoints request
		local msg =
		{
			serviceType = 7,
			frameInfo = 0,
			rpcType = 0,
			rpcFunctionId = 42,
			rpcCorrelationId = self.mobileSession.correlationId,
			--<<!-- extra ','
			payload = '{,}'
		}
		self.mobileSession:Send(msg)

		--hmi side: there is no SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Times(0)

		--mobile side:SubscribeWayPoints response
		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

		DelayedExp(10*1000)
	end]]

	function Test:OnHashChange_absent_DeleteCommand_INVALID_ID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteCommand request
		local cid = self.mobileSession:SendRPC("DeleteCommand",
		{
			cmdID = 5
		})
		
					
		--mobile side: expect DeleteCommand response 
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end

	function Test:OnHashChange_absent_DeleteSubMenu_INVALID_ID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteSubMenu request
		local cid = self.mobileSession:SendRPC("DeleteSubMenu",
												{
													menuID = 5
												})
			
		--mobile side: expect DeleteSubMenu response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_DeleteInteractionChoiceSe_INVALID_ID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 6
				})
		
					
		--mobile side: expect DeleteInteractionChoiceSet response 
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_ResetGlobalProperties_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending ResetGlobalProperties request
		local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
		{
			properties = 
			{
				"VRHELPTITLE_New"
			}
		})
				

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_UnsubscribeButton_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = "btnName"
			}
		)

		--mobile side: expect SubscribeButton response
		EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_UnsubscribeVehicleData_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending UnsubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", {gps = "1"})
		
		--mobile side: expect UnsubscribeVehicleData response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
		
	end
	
	--[[TODO: Uncomment when APPLINK-26159: ATF stops at protocol value deviation is fixed
	function Test:OnHashChange_absent_UnsubscribeWayPoints_INVALID_DATA()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

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
		--self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
		
	end]]

	
	--======================================================================================--
	-- Unsuccess code from HMI: REJECTED
	--======================================================================================--
	function Test:AddResumptionData_AddCommand()
		userPrint(35, "================= Test Group: Unsuccess code from HMI: REJECTED ==================")
		userPrint(35, "=============================== Precondition =====================================")
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end
	
	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:OnHashChange_absent_AddCommand_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		--mobile side: sending AddCommand request
		self.mobileSession:SendRPC("AddCommand",
												{
													cmdID = 2,
													menuParams = 	
													{ 
														menuName ="Command2"
													}, 
													vrCommands = 
													{ 
														"VRCommand2",
														"VRCommand2double"
													}
												})

		--mobile side: sending AddCommand request
		self.mobileSession:SendRPC("AddCommand",
												{
													cmdID = 3,
													menuParams = 	
													{ 
														menuName ="Command3"
													}, 
													vrCommands = 
													{ 
														"VRCommand3",
														"VRCommand3double"
													}
												})

		--hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(exp,data)
				if exp.occurences == 1 then
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				elseif
					 exp.occurences == 2 then
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Command is rejected ")
				end
			end)
			:Times(2)
			
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				if exp.occurences == 1 then
					--hmi side: sending VR.AddCommand response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Command is rejected ")

				elseif
					 exp.occurences == 2 then
					--hmi side: sending VR.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end
			end)
			:Times(2)

		--hmi side: expect UI.DeleteCommand request
		EXPECT_HMICALL("UI.DeleteCommand")
			:Do(function(_,data)
				--hmi side: sending UI.DeleteCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)


		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand")
			:Do(function(_,data)
				--hmi side: sending VR.DeleteCommand response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		
		--mobile side: expect AddCommand response
		EXPECT_RESPONSE("AddCommand", { success = false, resultCode = "REJECTED" })
		:Times(2)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end

	function Test:OnHashChange_absent_AddSubMenu_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending AddSubMenu request
		local cid = self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = 5,
					position = 500,
					menuName = "SubMenupositive5"
				})

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", " SubMenu is rejected ")
			end)

		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end

	function Test:OnHashChange_absent_CreateInteractionChoiceSet_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending CreateInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
												{
													interactionChoiceSetID = 5,
													choiceSet = 
													{ 
														
														{ 
															choiceID = 5,
															menuName = "Choice5",
															vrCommands = 
															{ 
																"VrChoice5",
															}
														}
													}
												})
		
			
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Command is rejected ")
		end)
		
		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
 
 	function Test:OnHashChange_absent_SetGlobalProperites_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
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
								helpPrompt = 
								{
									{
										text = "Help prompt",
										type = "TEXT"
									}
								},
							})

		self.mobileSession:SendRPC("SetGlobalProperties",
							{
								menuTitle = "Menu Title2",
								timeoutPrompt = 
								{
									{
										text = "Timeout prompt2",
										type = "TEXT"
									}
								},
								helpPrompt = 
								{
									{
										text = "Help prompt2",
										type = "TEXT"
									}
								},
							})


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
			:Do(function(_,data)
				if exp.occurences == 1 then
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				elseif
					 exp.occurences == 2 then
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Properties is rejected ")
				end
			end)
			:Times(2)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Do(function(_,data)
				if exp.occurences == 1 then
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Properties is rejected ")

				elseif
					 exp.occurences == 2 then
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end
			end)
			:Times(2)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = false, resultCode = "REJECTED"})
			:Times(2)
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

	end
	
	-- For SubscribeButton is not applicable. RPC can't be REJECTED from HMI
	
	function Test:OnHashChange_absent_SubscribleVehicleData_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData", { speed = true })

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{ speed = true })
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", " SubscribeVehicleData is rejected ")
			end)

		
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
		
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_SubscribeWayPoints_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		--mobile side: send SubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})

		--hmi side: expected SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
		end)

		EXPECT_RESPONSE(cid, {success = false , resultCode = "REJECTED"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
	
	function Test:OnHashChange_absent_DeleteCommand_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteCommand request
		local cid = self.mobileSession:SendRPC("DeleteCommand",
		{
			cmdID = 1
		})

		--hmi side: expect UI.DeleteCommand request
		EXPECT_HMICALL("UI.DeleteCommand")
		:Do(function(_,data)
			--hmi side: sending UI.DeleteCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " DeleteCommand is rejected ")
		end)

		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand")
		:Do(function(_,data)
			--hmi side: sending VR.DeleteCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " DeleteCommand is rejected ")
		end)
	
					
		--mobile side: expect DeleteCommand response 
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_DeleteSubMenu_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteSubMenu request
		local cid = self.mobileSession:SendRPC("DeleteSubMenu",
												{
													menuID = 1
												})

		--hmi side: expect UI.DeleteSubMenu request
		EXPECT_HMICALL("UI.DeleteSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.DeleteSubMenu response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " DeleteSubMenu is rejected ")
		end)
			
		--mobile side: expect DeleteSubMenu response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_DeleteInteractionChoiceSe_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending DeleteInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 1
				})

		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.DeleteCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Command is rejected ")
		end)
		
		--userPrint(31, "DEFECT ID: APPLINK-13849")
		--mobile side: expect DeleteInteractionChoiceSet response 
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	function Test:OnHashChange_absent_ResetGlobalProperties_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending ResetGlobalProperties request
		self.mobileSession:SendRPC("ResetGlobalProperties",
		{
			properties = 
			{
				"VRHELPTITLE",
				"HELPPROMPT"

			}
		})
		
		--mobile side: sending ResetGlobalProperties request
		self.mobileSession:SendRPC("ResetGlobalProperties",
		{
			properties = 
			{
				"VRHELPTITLE",
				"HELPPROMPT"

			}
		})

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
			:Do(function(_,data)
				if exp.occurences == 1 then
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				elseif
					 exp.occurences == 2 then
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Properties is rejected ")
				end
			end)
			:Times(2)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Do(function(_,data)
				if exp.occurences == 1 then
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", " Properties is rejected ")

				elseif
					 exp.occurences == 2 then
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end
			end)
			:Times(2)


		--mobile side: expect ResetGlobalProperties response
		EXPECT_RESPONSE("ResetGlobalProperties", { success = false, resultCode = "REJECTED"})
			:Times(2)

		--userPrint(31, "DEFECT ID: Not found")
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

	-- For UnsubscribeButton is not applicable. RPC can't be REJECTED from HMI
	
	function Test:OnHashChange_absent_UnsubscribeVehicleData_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		userPrint(34, "=================== Test Case ===================")

		--mobile side: sending UnsubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", {gps = true})

		--hmi side: expect UnsubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " UnsubscribeVehicleData is rejected ")	
		end)
		
		--mobile side: expect UnsubscribeVehicleData response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
		
	end

	function Test:Precondition_SubscribeWayPoints()
		local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})

		--hmi side: expected SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending Navigation.SubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: SubscribeWayPoints response
		EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
		:Do(function(_,data)
			--Requirement id in JAMA/or Jira ID: APPLINK-15682
			--[Data Resumption]: OnHashChange
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end)
	end

	function Test:OnHashChange_absent_UnsubscribeWayPoints_REJECTED_fromHMI()
		--Requirement id in JAMA/or Jira ID: APPLINK-15682
		--[Data Resumption]: OnHashChange
		
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
	
		--hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
		end)

		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "REJECTED"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- OnHashChanged() notification is not sent to mobile after sending requests
--////////////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================--
	--PutFile 
	--======================================================================================--

	function Test:OnHashChange_PutFile()
		userPrint(35, "=================== Test group: OnHashChanged() notification is not sent to mobile after sending requests ===================")
		userPrint(34, "======================================================= Test Case ===========================================================")
		local cid = self.mobileSession:SendRPC("PutFile",
				{			
					syncFileName = "icon.png",
					fileType	= "GRAPHIC_PNG"
				}, "files/icon.png")	

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

		DelayedExp(3000)
	end

	--======================================================================================--
	--SetAppIcon 
	--======================================================================================--

	function Test:OnHashChange_SetAppIcon()
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending SetAppIcon request
		local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })

		--hmi side: expect UI.SetAppIcon request
		EXPECT_HMICALL("UI.SetAppIcon")
		:Do(function(_,data)
			--hmi side: sending UI.SetAppIcon response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect SetAppIcon response
		EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

		DelayedExp(3000)
	end

	--======================================================================================--
	--Show 
	--======================================================================================--

	function Test:OnHashChange_Show()
		userPrint(34, "=================== Test Case ===================")
		--mobile side: sending Show request
		local cid = self.mobileSession:SendRPC("Show", {mainField1 = "mainField1"})
		
		--hmi side: expect UI.Show request
		EXPECT_HMICALL("UI.Show")
		:Do(function(_,data)
			--hmi side: sending UI.Show response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)

		DelayedExp(3000)
	end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Check saved data in app_info.dat after IGN_OFF 
--////////////////////////////////////////////////////////////////////////////////////////////--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Test Case: Check saved data in app_info.dat after IGN_OFF  ==================")
		userPrint(35, "======================================= Precondition ==========================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end


	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:ResumptionData()
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
								"VrChoice" .. tostring(i),
							}
						}
					}
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
		-- subscribe all buttons
		----------------------------------------------
		buttonName = {"OK"}
		
		for m = 1, #buttonName do
		 	-- print("buttonName["..m .."] = "..buttonName[m])
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]
				})
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

	function Test:SUSPEND()
		SUSPEND(self)
		DelayedExp(1000)
	end

	function Test:CheckSavedDataInAppInfoDatAfterSUSPEND()
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--Store all applications resumption-related data on the file system

		--Requirement id in JAMA/or Jira ID: APPLINK-15930
		--Data Resumption]:Database for resumption-related data 
		
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)

		for p = 1, #resumptionDataTable.resumption.resume_app_list do
			if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
				resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
			end
		end

		if 
			resumptionAppData.applicationChoiceSets and
			#resumptionAppData.applicationChoiceSets ~= 20 then
				self:FailTestCase("Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected 20")
		elseif
			resumptionAppData.applicationCommands and
			#resumptionAppData.applicationCommands ~= 20 then
				self:FailTestCase("Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected 20" )
		elseif
			resumptionAppData.applicationSubMenus and
			#resumptionAppData.applicationSubMenus ~= 20 then
				self:FailTestCase("Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected 20")
		elseif
			resumptionAppData.subscribtions and
			resumptionAppData.subscribtions.buttons and
			#resumptionAppData.subscribtions.buttons ~= #buttonName + 1 then
				self:FailTestCase("Wrong number of SubscribeButtons saved in app_info.dat" ..tostring(#resumptionAppData.subscribtions.buttons) .. ", expected " .. tostring(#buttonName + 1))
		elseif
			resumptionAppData.globalProperties and
			resumptionAppData.globalProperties.helpPrompt[1].text ~= "Help prompt" or
			resumptionAppData.globalProperties.timeoutPrompt[1].text ~= "Timeout prompt" or
			resumptionAppData.globalProperties.menuTitle ~= "Menu Title" or
			resumptionAppData.globalProperties.vrHelp[1].text ~= "VR help item" or
			resumptionAppData.globalProperties.vrHelpTitle ~= "VR help title" then
				self:FailTestCase("Wrong GlobalPropeerties saved in app_info.dat . Expected helpPrompt[1].text = 'Help prompt', got " .. tostring(resumptionAppData.globalProperties.helpPrompt[1].text) .. ", expected timeoutPrompt[1].text = 'Timeout prompt', got " .. tostring(resumptionAppData.globalProperties.timeoutPrompt[1].text) .. ", expected menuTitle = 'menuTitle', got " .. tostring(resumptionAppData.globalProperties.menuTitle) ..", expected vrHelp[1].text = 'VR help item then', got " .. tostring(resumptionAppData.globalProperties.vrHelp[1].text) .. ", expected vrHelpTitle = 'VR help title', got " ..tostring(resumptionAppData.globalProperties.vrHelpTitle))
		end
		--userPrint(31, "DEFECT ID: New defect!")
	end
	
	function Test:AddDataAfterSUSPEND()
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--Continue generating resumption related data (in case getting some from mobile application) without sending OnHashChanged notification to mobile app.
		----------------------------------------------
		-- 5 commands, submenus, InteractionChoices
		----------------------------------------------
		for i=1, 5 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 125 + i,
						menuParams = 	
						{
							position = 0,
							menuName ="Command" .. tostring(20 + i)
						}, 
						vrCommands = {"VRCommand" .. tostring(20 + i)}
					})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = 20 + i,
					position = 500,
					menuName = "SubMenupositive" .. tostring(20 + i)
				})

			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
				{
					interactionChoiceSetID = 20 + i,
					choiceSet = 
					{ 
						
						{ 
							choiceID = 20 + i,
							menuName = "Choice" .. tostring(20 + i),
							vrCommands = 
							{ 
								"VrChoice" .. tostring(20 + i),
							}
						}
					}
				})

		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)	
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
			:Times(5)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)
			
		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
			:Times(5)

		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
			:Times(5)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{ speed = true})
		

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{speed = true})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
			end)

		
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", speed = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})

		--userPrint(31, "DEFECT ID: New defect!")
		--mobile side: doesn't expect OnHashChange notification
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--[Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
	
	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
	end

	function Test:CheckSavedDataInAppInfoDat()
		--Requirement id in JAMA/or Jira ID: APPLINK-15703
		--[Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption 
		
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)

		if(resumptionDataTable.resumption.resume_app_list ~= nil) then

			for p = 1, #resumptionDataTable.resumption.resume_app_list do
				if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
					resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
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

			--userPrint(31, "DEFECT ID: New defect!")
		else
			userPrint(31, "Resumption application list is empty!")
			os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_Test_CheckSavedDataInAppInfoDat" )
		end
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_PersistantData()
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
					elseif 
						i == #UIAddCommandValues then
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
						if 
							data.params.cmdID == VRAddCommandValues[i].cmdID and
							data.params.appID == HMIAppID and
							data.params.vrCommands[1] == VRAddCommandValues[i].vrCommands[1] then
							return true
						elseif 
							i == #VRAddCommandValues then
								userPrint(31, "Any matches")
								userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', vrCommands[1]  = '" .. tostring(data.params.vrCommands[1] ) .. "'"  )
								return false
						end

					end
				elseif
					data.params.type == "Choice" then
						for i=1, #Choices do
						if 
							data.params.cmdID == Choices[i].cmdID and
							data.params.appID == HMIAppID and
							data.params.vrCommands[1] == Choices[i].vrCommands[1] then
							return true
						elseif 
							i == #Choices then
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

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- 	:Times(0)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- 	:Times(0)

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
					if 
						data.params.menuID == SubMenuValues[i].menuID and
						data.params.menuParams.position == 500 and
						data.params.menuParams.menuName == SubMenuValues[i].menuParams.menuName then
						return true
					elseif 
						i == #SubMenuValues then
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

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- 	:Times(0)

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
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- 	:Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
			end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- 	:Times(0)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
			:ValidIf(function(_,data)
				for i=1, #buttonName do
					if 
						data.params.name == "CUSTOM_BUTTON" and
						data.params.isSubscribed == true and
						data.params.appID == HMIAppID then
							return true
					elseif
						data.params.name == buttonName[i] and
						data.params.isSubscribed == true and
						data.params.appID == HMIAppID then
							return true
					elseif 
						i == #buttonName then
							userPrint(31, "Any matches")
							userPrint(31, "Actual values name ='" .. tostring(data.params.name) .. "', isSubscribed = '" .. tostring(data.params.isSubscribed) .. "', appID = '" .. tostring(data.params.appID) .. "'")
							return false
					end

				end
			end)
			:Times(#buttonName + 1)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	end


--////////////////////////////////////////////////////////////////////////////////////////////--
-- Check saved data in app_info.dat after SUSPEND-OnAwakeSDL-IGN_OFF
--////////////////////////////////////////////////////////////////////////////////////////////--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Test Case: Check saved data in app_info.dat after SUSPEND-OnAwakeSDL-IGN_OFF  ==================")
		userPrint(35, "======================================= Precondition =============================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end


	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:ResumptionData1()
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
								"VrChoice" .. tostring(i),
							}
						}
					}
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
		-- subscribe all buttons
		----------------------------------------------
		buttonName = {"OK"}
		
		for m = 1, #buttonName do
		 	-- print("buttonName["..m .."] = "..buttonName[m])
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]
				})
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

	function Test:SUSPEND()
		SUSPEND(self)
		DelayedExp(1000)
	end
	
	function Test:CheckSavedDataInAppInfoDatAfterSUSPEND()
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--Store all applications resumption-related data on the file system
		
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)

		for p = 1, #resumptionDataTable.resumption.resume_app_list do
			if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
				resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
			end
		end

		if 
			resumptionAppData.applicationChoiceSets and
			#resumptionAppData.applicationChoiceSets ~= 20 then
				self:FailTestCase("Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected 20")
		elseif
			resumptionAppData.applicationCommands and
			#resumptionAppData.applicationCommands ~= 20 then
				self:FailTestCase("Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected 20" )
		elseif
			resumptionAppData.applicationSubMenus and
			#resumptionAppData.applicationSubMenus ~= 20 then
				self:FailTestCase("Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected 20")
		elseif
			resumptionAppData.subscribtions and
			resumptionAppData.subscribtions.buttons and
			#resumptionAppData.subscribtions.buttons ~= #buttonName + 1 then
				self:FailTestCase("Wrong number of SubscribeButtons saved in app_info.dat" ..tostring(#resumptionAppData.subscribtions.buttons) .. ", expected " .. tostring(#buttonName + 1))
		elseif
			resumptionAppData.globalProperties and
			resumptionAppData.globalProperties.helpPrompt[1].text ~= "Help prompt" or
			resumptionAppData.globalProperties.timeoutPrompt[1].text ~= "Timeout prompt" or
			resumptionAppData.globalProperties.menuTitle ~= "Menu Title" or
			resumptionAppData.globalProperties.vrHelp[1].text ~= "VR help item" or
			resumptionAppData.globalProperties.vrHelpTitle ~= "VR help title" then
				self:FailTestCase("Wrong GlobalPropeerties saved in app_info.dat . Expected helpPrompt[1].text = 'Help prompt', got " .. tostring(resumptionAppData.globalProperties.helpPrompt[1].text) .. ", expected timeoutPrompt[1].text = 'Timeout prompt', got " .. tostring(resumptionAppData.globalProperties.timeoutPrompt[1].text) .. ", expected menuTitle = 'menuTitle', got " .. tostring(resumptionAppData.globalProperties.menuTitle) ..", expected vrHelp[1].text = 'VR help item then', got " .. tostring(resumptionAppData.globalProperties.vrHelp[1].text) .. ", expected vrHelpTitle = 'VR help title', got " ..tostring(resumptionAppData.globalProperties.vrHelpTitle))
		end
		--userPrint(31, "DEFECT ID: New defect!")
	end
	
	function Test:AddDataAfterSUSPEND()
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--Continue generating resumption related data (in case getting some from mobile application) without sending OnHashChanged notification to mobile app.
		----------------------------------------------
		-- 5 commands, submenus, InteractionChoices
		----------------------------------------------
		for i=1, 5 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 20 + i,
						menuParams = 	
						{
							position = 0,
							menuName ="Command" .. tostring(20 + i)
						}, 
						vrCommands = {"VRCommand" .. tostring(20 + i)}
					})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = 20 + i,
					position = 500,
					menuName = "SubMenupositive" .. tostring(20 + i)
				})

			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
				{
					interactionChoiceSetID = 20 + i,
					choiceSet = 
					{ 
						
						{ 
							choiceID = 20 + i,
							menuName = "Choice" .. tostring(20 + i),
							vrCommands = 
							{ 
								"VrChoice" .. tostring(20 + i),
							}
						}
					}
				})

		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)	
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
			:Times(5)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(5)
			
		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
			:Times(5)

		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
			:Times(5)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{ speed = true})
		

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{speed = true})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
			end)

		
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", speed = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})

		--userPrint(31, "DEFECT ID: New defect!")
		--mobile side: doesn't expect OnHashChange notification
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--[Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption
		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Times(0)
	end

	function Test:OnAwakeSDL_CheckOnHashID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15706 	
		--[Data Resumption]: OnAwakeSDL in terms of resumption 
		OnAwakeSDL(self, 10*1000)

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(30)
	end
		
	function Test:SUSPEND()
		SUSPEND(self)
		DelayedExp(1000)
	end

	function Test:AddDataAfterSUSPEND2()
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--Continue generating resumption related data (in case getting some from mobile application) without sending OnHashChanged notification to mobile app.
		----------------------------------------------
		-- 2 commands, submenus, InteractionChoices
		----------------------------------------------
		for i=1, 2 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
					{
						cmdID = 250 + i,
						menuParams = 	
						{
							position = 0,
							menuName ="Command" .. tostring(25 + i)
						}, 
						vrCommands = {"VRCommand" .. tostring(25 + i)}
					})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = 25 + i,
					position = 500,
					menuName = "SubMenupositive" .. tostring(25 + i)
				})

			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
				{
					interactionChoiceSetID = 25 + i,
					choiceSet = 
					{ 
						
						{ 
							choiceID = 25 + i,
							menuName = "Choice" .. tostring(25 + i),
							vrCommands = 
							{ 
								"VrChoice" .. tostring(25 + i),
							}
						}
					}
				})

		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(0)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(0)	
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
			:Times(0)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(0)
			
		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
			:Times(0)

		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
			:Times(0)

		
		
		--mobile side: doesn't expect OnHashChange notification
		--Requirement id in JAMA/or Jira ID: APPLINK-15702
		--[Data Resumption]:OnExitAllApplications(SUSPEND) in terms of resumption
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(0)
	end
	
	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
	end


	function Test:CheckSavedDataInAppInfoDat_2()
		--Requirement id in JAMA/or Jira ID: APPLINK-15703
		--[Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption 
		
		userPrint(34, "=================== Test Case ===================")
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		resumptionDataTable = json.decode(resumptionfile)

		if(resumptionDataTable.resumption.resume_app_list ~= nil) then

			for p = 1, #resumptionDataTable.resumption.resume_app_list do
				if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
					resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
				end
			end

			if ( resumptionAppData.applicationChoiceSets and #resumptionAppData.applicationChoiceSets ~= 25) then
					self:FailTestCase("Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected 25")
			elseif (resumptionAppData.applicationCommands and #resumptionAppData.applicationCommands ~= 25) then
					self:FailTestCase("Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected 25" )
			elseif (resumptionAppData.applicationSubMenus and #resumptionAppData.applicationSubMenus ~= 25) then
					self:FailTestCase("Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected 25")
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
			userPrint(31, "Resumption application list is empty!")
			os.execute(" cp " .. config.pathToSDL .. "app_info.dat " .. config.pathToSDL .. "app_info.dat_Test_CheckSavedDataInAppInfoDat" )
		end
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_PersistantData_1()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)

		local UIAddCommandValues = {}
		for m=1,25 do
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
					elseif 
						i == #UIAddCommandValues then
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
		:Times(25)

		local VRAddCommandValues = {}
		for m=1,25 do
			VRAddCommandValues[m] = {cmdID = m, vrCommands = {"VRCommand" .. tostring(m)}}
		end

		local Choices = {}
		for m=1,25 do
			Choices = {cmdID = m, vrCommands = {"VrChoice" .. tostring(m)}}
		end

		EXPECT_HMICALL("VR.AddCommand")
			:ValidIf(function(_,data)
				if data.params.type == "Command" then
					for i=1, #VRAddCommandValues do
						if 
							data.params.cmdID == VRAddCommandValues[i].cmdID and
							data.params.appID == HMIAppID and
							data.params.vrCommands[1] == VRAddCommandValues[i].vrCommands[1] then
							return true
						elseif 
							i == #VRAddCommandValues then
								userPrint(31, "Any matches")
								userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', vrCommands[1]  = '" .. tostring(data.params.vrCommands[1] ) .. "'"  )
								return false
						end

					end
				elseif
					data.params.type == "Choice" then
						for i=1, #Choices do
						if 
							data.params.cmdID == Choices[i].cmdID and
							data.params.appID == HMIAppID and
							data.params.vrCommands[1] == Choices[i].vrCommands[1] then
							return true
						elseif 
							i == #Choices then
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

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- 	:Times(0)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- 	:Times(0)

		local SubMenuValues = {}
		for m=1,25 do
			SubMenuValues[m] = { menuID = m,menuParams = {position = 500,menuName = "SubMenupositive" ..tostring(m)}}
		end

		----------------------------------------------
		-- 20 submenus
		----------------------------------------------

		EXPECT_HMICALL("UI.AddSubMenu")
			:ValidIf(function(_,data)
				for i=1, #SubMenuValues do
					if 
						data.params.menuID == SubMenuValues[i].menuID and
						data.params.menuParams.position == 500 and
						data.params.menuParams.menuName == SubMenuValues[i].menuParams.menuName then
						return true
					elseif 
						i == #SubMenuValues then
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
		:Times(25)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- 	:Times(0)

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
		:Times(3)



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


		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- 	:Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
			end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- 	:Times(0)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
			:ValidIf(function(_,data)
				for i=1, #buttonName do
					if 
						data.params.name == "CUSTOM_BUTTON" and
						data.params.isSubscribed == true and
						data.params.appID == HMIAppID then
							return true
					elseif
						data.params.name == buttonName[i] and
						data.params.isSubscribed == true and
						data.params.appID == HMIAppID then
							return true
					elseif 
						i == #buttonName then
							userPrint(31, "Any matches")
							userPrint(31, "Actual values name ='" .. tostring(data.params.name) .. "', isSubscribed = '" .. tostring(data.params.isSubscribed) .. "', appID = '" .. tostring(data.params.appID) .. "'")
							return false
					end

				end
			end)
			:Times(#buttonName + 1)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	end



	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Check abcense of resumtion in case RAI without HashID
	--////////////////////////////////////////////////////////////////////////////////////////////--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Check abcense of resumtion in case RAI without HashID ==================")
		userPrint(35, "=================================== Precondition =========================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)

	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
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
	      config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_absent_without_hashID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15681
		--[Data Resumption]:RegisterAppInterface with no or wrong hashID
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15686
		--[Data Resumption]: SDL data resumption failure 
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = nil

		RegisterApp_HMILevelResumption(self, "FULL", _, _, false)

		EXPECT_HMICALL("UI.AddCommand")
			:Times(0)

		EXPECT_HMICALL("VR.AddCommand")
			:Times(0)

		EXPECT_HMICALL("UI.AddSubMenu")
			:Times(0)

		EXPECT_HMICALL("TTS.SetGlobalProperties")

		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Times(0)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)

	end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Check abcense of resumtion in case HashID in RAI is not match
	--////////////////////////////////////////////////////////////////////////////////////////////--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Check abcense of resumtion in case HashID in RAI is not match ==================")
		userPrint(35, "======================================= Precondition =============================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
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
	      config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_absent_with_notMatched_hashID()
		--Requirement id in JAMA/or Jira ID: APPLINK-15681
		--[Data Resumption]:RegisterAppInterface with no or wrong hashID
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15686
		--[Data Resumption]: SDL data resumption failure 
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = "sdfgTYWRTdfhsdfgh"
			
		RegisterApp_HMILevelResumption(self, "FULL", _, "RESUME_FAILED", false)

		EXPECT_HMICALL("UI.AddCommand")
			:Times(0)

		EXPECT_HMICALL("VR.AddCommand")
			:Times(0)

		EXPECT_HMICALL("UI.AddSubMenu")
			:Times(0)

		EXPECT_HMICALL("TTS.SetGlobalProperties")

		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Times(0)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)

	end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Resumtion Data in case HashID in RAI match
	--////////////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================--
	--Resumption of FULL hmiLevel , persistant data after disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of FULL hmiLevel, persistant data after disconnect ==================")
		userPrint(35, "======================================== Precondition =============================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
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
	      config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_FULL_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before	
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_HMILevelResumption(self, "FULL", _, _, true)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	--======================================================================================--
	--Resumption of FULL hmiLevel with postpone because of VR.Started , persistant data after disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of FULL hmiLevel with postpone because of VR.Started , persistant data after disconnect ==================")
		userPrint(35, "================================================== Precondition =======================================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
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
	      config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_FULL_WithPostpone_VRSessionActive_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		self.hmiConnection:SendNotification("VR.Started", {})
		notificationState.VRSession = true

      	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      	--got time after RAI request
      	time =  timestamp()

      	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
	    :Do(function(_,data)
			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
	    end)

      	self.mobileSession:ExpectResponse(correlationId, { success = true })
         	:Do(function(_,data)
				local timeRAIResponse = timestamp()
	            local function to_run()
              	
				timeFromRequestToNot = timeRAIResponse - time
              	self.hmiConnection:SendNotification("VR.Stopped", {})
				notificationState.VRSession = false
            end
            RUN_AFTER(to_run, 15000)
         end)

		EXPECT_HMICALL("BasicCommunication.ActivateApp")
         :Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
               self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
         end)
        :Timeout(17000)

		EXPECT_NOTIFICATION("OnHMIStatus", 
						{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
						{hmiLevel = "FULL" , systemContext = "MAIN", audioStreamingState = audibleState})
		:ValidIf(function(exp,data)
            if exp.occurences == 2 then 
				local time2 =  timestamp()
				local timeToresumption = time2 - time
				if timeToresumption >= 15000 and
					timeToresumption < 16000 + timeFromRequestToNot then
					userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 ")
					return true
				else 
					userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 ")
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
        :Timeout(17000)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	--======================================================================================--
	--Resumption of FULL hmiLevel with postpone because of BC.OnEmergencyEvent, persistant data after disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of FULL hmiLevel with postpone because of BC.OnEmergencyEvent, persistant data after disconnect ==================")
		userPrint(35, "========================================================== Precondition =======================================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
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
	      config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_FULL_WithPostpone_EmergencyEventActive_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
		notificationState.EmergencyEvent = true

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		--got time after RAI request
		time =  timestamp()

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
		:Do(function(_,data)
		   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

		self.mobileSession:ExpectResponse(correlationId, { success = true })
		:Do(function(_,data)
			local timeRAIResponse = timestamp()
			local function to_run()
		
			timeFromRequestToNot = timeRAIResponse - time
		    self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
			notificationState.EmergencyEvent = false
		end
			RUN_AFTER(to_run, 15000)
		end)

      	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	    end)
	    :Timeout(17000)

		EXPECT_NOTIFICATION("OnHMIStatus", 
							{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
							{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = audibleState})
		:ValidIf(function(exp,data)
		  	if exp.occurences == 2 then 
			    local time2 =  timestamp()
			    local timeToresumption = time2 - time
		
				if timeToresumption >= 15000 and
			        timeToresumption < 16000 + timeFromRequestToNot then 
			        userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
					return true
			    else 
			        userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
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
		:Timeout(17000)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

	--======================================================================================--
	--Resumption of FULL hmiLevel with postpone because of BC.OnPhoneCall, persistant data after disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of FULL hmiLevel with postpone because of BC.OnPhoneCall, persistant data after disconnect ==================")
		userPrint(35, "============================================================= Precondition ===============================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
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
															config.application1.registerAppInterfaceParams
														)
	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_FULL_WithPostpone_PhoneCallActive_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
		notificationState.PhoneCall = true

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		--got time after RAI request
		time =  timestamp()

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
		:Do(function(_,data)
		   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

		self.mobileSession:ExpectResponse(correlationId, { success = true })
		:Do(function(_,data)
		    local timeRAIResponse = timestamp()
			local function to_run()
		    
			timeFromRequestToNot = timeRAIResponse - time
		    self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
			notificationState.PhoneCall = false
		end

		    RUN_AFTER(to_run, 15000)
		end)

      	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Do(function(_,data)
            --hmi side: sending BasicCommunication.ActivateApp response
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	    end)
	    :Timeout(17000)

		if (config.application1.registerAppInterfaceParams.isMediaApplication == true) then
			EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
								{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
			:ValidIf(function(exp,data)
				if exp.occurences == 2 then 
					local time2 =  timestamp()
					local timeToresumption = time2 - time
					if timeToresumption >= 15000 and
						timeToresumption < 16000 + timeFromRequestToNot then
						userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " ) 
						return true
					else 
						userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
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
			:Timeout(17000)

		elseif
			config.application1.registerAppInterfaceParams.isMediaApplication == false then
			EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
								{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
			:ValidIf(function(exp,data)
				if  exp.occurences == 2 then 
					local time2 =  timestamp()
					local timeToresumption = time2 - time
					if timeToresumption >= 3000 and
						timeToresumption < 3500 then
						userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
						return true
					else 
						userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
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
     	end

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

	--======================================================================================--
	--Resumption of FULL hmiLevel , persistant data after IGN_OFF
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of FULL hmiLevel , persistant data after IGN_OFF ==================")
		userPrint(35, "========================================== Precondition ========================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _ , false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:SUSPEND()
		SUSPEND(self, "FULL")
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_FULL_IGN_OFF_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	--======================================================================================--
	-- Resumption of LIMITED hmiLevel , persistant data after disconnect
	-- Tests are applicable only for MEDIA or NAVIGATION or COMMUNICATION application
	--======================================================================================--
	
	if
		config.application1.registerAppInterfaceParams.isMediaApplication == true or
	  	Test.appHMITypes["NAVIGATION"] == true or
	  	Test.appHMITypes["COMMUNICATION"] == true then

		function Test:UnregisterAppInterface_Success()
			userPrint(35, "================= Resumption_data_LIMITED_Disconnect_hashID_Matched ==================")
			userPrint(35, "================================== Precondition ======================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success()
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		    :Do(function(_,data)
				self.hmiLevel = data.payload.hmiLevel
		    end)
		end

		function Test:AddResumptionData_AddCommand()
			AddCommand(self, 1)
		end

		function Test:AddResumptionData_CreateInteractionChoiceSet()
			CreateInteractionChoiceSet(self, 1)
		end

		function Test:AddResumptionData_AddSubMenu()
			AddSubMenu(self, 1)
		end

		function Test:AddResumptionData_SetGlobalProperites()
			SetGlobalProperites(self, "")
		end

		function Test:AddResumptionData_SubscribleButton()
			SubscribleButton(self, "PRESET_0")
		end

		function Test:AddResumptionData_SubscribleVehicleData()
			SubscribleVehicleData(self, "gps")
		end

		function Test:DeactivateToLimited()
			BringAppToLimitedLevel(self)
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
																config.application1.registerAppInterfaceParams
															)
		  	self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_LIMITED_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
			userPrint(34, "=================== Test Case ===================")
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID
				
			RegisterApp_HMILevelResumption(self, "LIMITED", _, _, true)

			ResumedDataAfterRegistration(self)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)

		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel , persistant data after IGN_OFF
		--======================================================================================--

		function Test:UnregisterAppInterface_Success()
			userPrint(35, "================= Resumption of LIMITED hmiLevel , persistant data after IGN_OFF ==================")
			userPrint(35, "========================================= Precondition ============================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success()
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		    :Do(function(_,data)
		        self.hmiLevel = data.payload.hmiLevel
		    end)
		end

		function Test:AddResumptionData_AddCommand()
			AddCommand(self, 1)
		end

		function Test:AddResumptionData_CreateInteractionChoiceSet()
			CreateInteractionChoiceSet(self, 1)
		end

		function Test:AddResumptionData_AddSubMenu()
			AddSubMenu(self, 1)
		end

		function Test:AddResumptionData_SetGlobalProperites()
			SetGlobalProperites(self, "")
		end

		function Test:AddResumptionData_SubscribleButton()
			SubscribleButton(self, "PRESET_0")
		end

		function Test:AddResumptionData_SubscribleVehicleData()
			SubscribleVehicleData(self, "gps")
		end

		function Test:DeactivateToLimited()
			BringAppToLimitedLevel(self)
		end

		function Test:SUSPEND()
			SUSPEND(self, "LIMITED")
		end

		function Test:IGNITION_OFF()
			IGNITION_OFF(self)
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
			CreateSession(self)

			self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_LIMITED_IGN_OFF_hashID_Matched()
			--Requirement id in JAMA/or Jira ID: APPLINK-15670
			--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
			userPrint(34, "=================== Test Case ===================")
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID
				
			RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF", _, _, true)

			ResumedDataAfterRegistration(self)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)

		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel with postpone because of VR.Started , persistant data after IGN_OFF
		--======================================================================================--

		function Test:UnregisterAppInterface_Success()
			userPrint(35, "================= Resumption of LIMITED hmiLevel with postpone because of VR.Started , persistant data after IGN_OFF ==================")
			userPrint(35, "============================================================== Precondition ===========================================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success()
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		    :Do(function(_,data)
		        self.hmiLevel = data.payload.hmiLevel
		    end)
		end

		function Test:AddResumptionData_AddCommand()
			AddCommand(self, 1)
		end

		function Test:AddResumptionData_CreateInteractionChoiceSet()
			CreateInteractionChoiceSet(self, 1)
		end

		function Test:AddResumptionData_AddSubMenu()
			AddSubMenu(self, 1)
		end

		function Test:AddResumptionData_SetGlobalProperites()
			SetGlobalProperites(self, "")
		end

		function Test:AddResumptionData_SubscribleButton()
			SubscribleButton(self, "PRESET_0")
		end

		function Test:AddResumptionData_SubscribleVehicleData()
			SubscribleVehicleData(self, "gps")
		end

		function Test:DeactivateToLimited()
			BringAppToLimitedLevel(self)
		end

		function Test:SUSPEND()
			SUSPEND(self, "LIMITED")
		end

		function Test:IGNITION_OFF()
			IGNITION_OFF(self)
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
			CreateSession(self)

			self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_LIMITED_WithPostpone_VRSessionActive_IGN_OFF_hashID_Matched()
			--Requirement id in JAMA/or Jira ID: APPLINK-15670
			--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
			userPrint(34, "=================== Test Case ===================")
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID
				
	      	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
	      	--got time after RAI request
	      	time =  timestamp()

	      	local RAIAfterOnReady = time - self.timeOnReady
			userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))


			--Requirement id in JAMA/or Jira ID: APPLINK-15958 	
			--[Data Resumption] hmi_appID must be the same for the application between ignition cycles 
	      	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
		    :Do(function(_,data)
		        HMIAppID = data.params.application.appID
		        self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		    end)

	      	self.mobileSession:ExpectResponse(correlationId, { success = true })
	        :Do(function(_,data)
		        local timeRAIResponse = timestamp()
				
		        local function to_run()
					timeFromRequestToNot = timeRAIResponse - time
					self.hmiConnection:SendNotification("VR.Stopped", {})
					notificationState.VRSession = false
				end

	            RUN_AFTER(to_run, 15000)
	         end)

	      	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	        :Timeout(17000)

	      	EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
								{hmiLevel = "LIMITED" , systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
			:ValidIf(function(exp,data)
	            if exp.occurences == 2 then 
					local time2 =  timestamp()
					local timeToresumption = time2 - time
					
					if timeToresumption >= 15000 and
						timeToresumption < 16000 + timeFromRequestToNot then
						userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 ")
						return true
	               else 
						userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 ")
						return false
					end

	            elseif exp.occurences == 1 then
	            	self.hmiConnection:SendNotification("VR.Started", {})
					notificationState.VRSession = true
					return true
	            end
	        end)
	        :Do(function(_,data)
	            self.hmiLevel = data.payload.hmiLevel
	        end)
	        :Times(2)
	        :Timeout(17000)


			ResumedDataAfterRegistration(self)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel with postpone because of BC.OnEmergencyEvent, persistant data after IGN_OFF
		--======================================================================================--

		function Test:UnregisterAppInterface_Success()
			userPrint(35, "================= Resumption of LIMITED hmiLevel with postpone because of BC.OnEmergencyEvent, persistant data after IGN_OFF ==================")
			userPrint(35, "============================================================== Precondition ===================================================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success()
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      :Do(function(_,data)
		        self.hmiLevel = data.payload.hmiLevel
		      end)
		end

		function Test:AddResumptionData_AddCommand()
			AddCommand(self, 1)
		end

		function Test:AddResumptionData_CreateInteractionChoiceSet()
			CreateInteractionChoiceSet(self, 1)
		end

		function Test:AddResumptionData_AddSubMenu()
			AddSubMenu(self, 1)
		end

		function Test:AddResumptionData_SetGlobalProperites()
			SetGlobalProperites(self, "")
		end

		function Test:AddResumptionData_SubscribleButton()
			SubscribleButton(self, "PRESET_0")
		end

		function Test:AddResumptionData_SubscribleVehicleData()
			SubscribleVehicleData(self, "gps")
		end

		function Test:DeactivateToLimited()
			BringAppToLimitedLevel(self)
		end

		function Test:SUSPEND()
			SUSPEND(self, "LIMITED")
		end

		function Test:IGNITION_OFF()
			IGNITION_OFF(self)
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
			CreateSession(self)

			self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_LIMITED_WithPostpone_EmergencyEventActive_IGN_OFF_hashID_Matched()
			--Requirement id in JAMA/or Jira ID: APPLINK-15670
			--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15634
			--[Data Resumption]: Data resumption on IGNITION OFF

			--Requirement id in JAMA/or Jira ID: APPLINK-15958 	
			--[Data Resumption] hmi_appID must be the same for the application between ignition cycles 
			
		
			userPrint(34, "=================== Test Case ===================")
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID

			local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			--got time after RAI request
			time =  timestamp()

			local RAIAfterOnReady = time - self.timeOnReady
			userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
			:Do(function(_,data)
			   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)

			self.mobileSession:ExpectResponse(correlationId, { success = true })
			 	:Do(function(_,data)
				    local timeRAIResponse = timestamp()
				    local function to_run()
			      	timeFromRequestToNot = timeRAIResponse - time
			       	self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
					notificationState.EmergencyEvent = false
			    end

			    RUN_AFTER(to_run, 15000)
			 end)

	      	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		        :Timeout(17000)

			EXPECT_NOTIFICATION("OnHMIStatus", 
			 	{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
			 	{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
			 	:ValidIf(function(exp,data)
			    	if exp.occurences == 2 then 
					    local time2 =  timestamp()
					    local timeToresumption = time2 - time
				       if timeToresumption >= 15000 and
				          timeToresumption < 16000 + timeFromRequestToNot then 
				          userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
				          return true
				       else 
				          userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
				          return false
				       end

			    	elseif exp.occurences == 1 then
			    		self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})
						notificationState.EmergencyEvent = true
			       		return true
			 		 end
			 	end)
				:Do(function(_,data)
				  self.hmiLevel = data.payload.hmiLevel
				end)
				:Times(2)
				:Timeout(17000)

			ResumedDataAfterRegistration(self)

			--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						self.currentHashID = data.payload.hashID
					end)

		end

		--======================================================================================--
		--Resumption of LIMITED hmiLevel with postpone because of BC.OnPhoneCall, persistant data after IGN_OFF
		--======================================================================================--

		function Test:UnregisterAppInterface_Success()
			userPrint(35, "================= Resumption of LIMITED hmiLevel with postpone because of BC.OnPhoneCall, persistant data after IGN_OFF ==================")
			userPrint(35, "=========================================================== Precondition =================================================================")
			UnregisterAppInterface(self)
		end

		function Test:RegisterAppInterface_Success()
			RegisterApp_WithoutHMILevelResumption(self, _, false)
		end

		function Test:ActivateApp()
			ActivationApp(self)

			EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
		      :Do(function(_,data)
		        self.hmiLevel = data.payload.hmiLevel
		      end)
		end

		function Test:AddResumptionData_AddCommand()
			AddCommand(self, 1)
		end

		function Test:AddResumptionData_CreateInteractionChoiceSet()
			CreateInteractionChoiceSet(self, 1)
		end

		function Test:AddResumptionData_AddSubMenu()
			AddSubMenu(self, 1)
		end

		function Test:AddResumptionData_SetGlobalProperites()
			SetGlobalProperites(self, "")
		end

		function Test:AddResumptionData_SubscribleButton()
			SubscribleButton(self, "PRESET_0")
		end

		function Test:AddResumptionData_SubscribleVehicleData()
			SubscribleVehicleData(self, "gps")
		end

		function Test:DeactivateToLimited()
			BringAppToLimitedLevel(self)
		end

		function Test:SUSPEND()
			SUSPEND(self, "LIMITED")
		end

		function Test:IGNITION_OFF()
			IGNITION_OFF(self)
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
			CreateSession(self)

			self.mobileSession:StartService(7)
		end

		function Test:Resumption_data_LIMITED_WithPostpone_PhoneCallActive_IGN_OFF_hashID_Matched()
			--Requirement id in JAMA/or Jira ID: APPLINK-15670
			--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
			
			--Requirement id in JAMA/or Jira ID: APPLINK-15634
			--[Data Resumption]: Data resumption on IGNITION OFF

			--Requirement id in JAMA/or Jira ID: APPLINK-15958 	
			--[Data Resumption] hmi_appID must be the same for the application between ignition cycles 
			
			userPrint(34, "=================== Test Case ===================")
			config.application1.registerAppInterfaceParams.hashID = self.currentHashID

			local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			--got time after RAI request
			time =  timestamp()

			local RAIAfterOnReady = time - self.timeOnReady
			userPrint(33, "Time of sending RAI request after OnReady notification " ..tostring(RAIAfterOnReady))

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appID = HMIAppID }})
			:Do(function(_,data)
			   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)

			self.mobileSession:ExpectResponse(correlationId, { success = true })
			:Do(function(_,data)
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
				notificationState.PhoneCall = true
			    local timeRAIResponse = timestamp()
			
				local function to_run()
			      	timeFromRequestToNot = timeRAIResponse - time
			       	self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
					notificationState.PhoneCall = false
			    end

			    RUN_AFTER(to_run, 15000)
			end)

	      	EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		    :Timeout(17000)

			if (config.application1.registerAppInterfaceParams.isMediaApplication == true) then
				EXPECT_NOTIFICATION("OnHMIStatus", 
												{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
												{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				:ValidIf(function(exp,data)
					if exp.occurences == 2 then 
						local time2 =  timestamp()
						local timeToresumption = time2 - time
					
						if(  (timeToresumption >= 15000) and
							 (timeToresumption < 16000 + timeFromRequestToNot) ) then
							userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " ) 
							return true
						else 
							userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~15000 " )
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
				:Timeout(17000)

	      	elseif (config.application1.registerAppInterfaceParams.isMediaApplication == false) then
				
				EXPECT_NOTIFICATION("OnHMIStatus", 
									{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
									{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
	            :ValidIf(function(exp,data)
					if  exp.occurences == 2 then 
						local time2 =  timestamp()
						local timeToresumption = time2 - time
						
						if timeToresumption >= 3000 and
							timeToresumption < 3500 then
							userPrint(33, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " ) 
							return true
						else 
							userPrint(31, "Time to HMI level resumption is " .. tostring(timeToresumption) ..", expected ~3000 " )
							return false
						end

	                elseif exp.occurences == 1 then
	                	self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
						notificationState.PhoneCall = true
						return true
					end
	            end)
	            :Do(function(_,data)
					self.hmiLevel = data.payload.hmiLevel
				end)
	            :Times(2)
	     	end

			ResumedDataAfterRegistration(self)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)

		end
	end

	--======================================================================================--
	--Resumption of BACKGROUND hmiLevel , persistant data after disconnect
	--======================================================================================--
	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of BACKGROUND hmiLevel , persistant data after disconnect ==================")
		userPrint(35, "============================================== Precondition =============================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:DeactivateToBackground()
		BringAppToBackgroundLevel(self)
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
															config.application1.registerAppInterfaceParams)
	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_BACKGROUND_Disconnect_hashID_Matched()
	
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_WithoutHMILevelResumption(self, _, true)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	--======================================================================================--
	--Resumption of BACKGROUND hmiLevel , persistant data after IGN_OFF
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of BACKGROUND hmiLevel , persistant data after IGN_OFF ==================")
		userPrint(35, "========================================= Precondition ===============================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:DeactivateToBackground()
		BringAppToBackgroundLevel(self)
	end

	function Test:SUSPEND()
		SUSPEND(self)
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_BACKGROUND_IGN_OFF_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF", _, true )

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end		

	--======================================================================================--
	--Resumption of NONE hmiLevel , persistant data after disconnect
	--======================================================================================--
	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of NONE hmiLevel , persistant data after disconnect ==================")
		userPrint(35, "========================================= Precondition ============================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:DeactivateToNone()
		BringAppToNoneLevel(self)
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
															config.application1.registerAppInterfaceParams)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_NONE_Disconnect_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_WithoutHMILevelResumption(self, _, true)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)

	end

	--======================================================================================--
	--Resumption of NONE hmiLevel , persistant data after IGN_OFF
	--======================================================================================--
	
	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of NONE hmiLevel , persistant data after IGN_OFF ==================")
		userPrint(35, "========================================= Precondition =========================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:DeactivateToNone()
		BringAppToNoneLevel(self)
	end

	function Test:SUSPEND()
		SUSPEND(self)
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_NONE_IGN_OFF_hashID_Matched()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_WithoutHMILevelResumption(self, "IGN_OFF", true)

		ResumedDataAfterRegistration(self)

		--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)

	end

	--////////////////////////////////////////////////////////////////////////////////////////////--
	-- Resumtion Data is failed in case equired files are missed
	--////////////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================--
	-- IGN_OFF
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumtion Data is failed in case equired files are missed. IGN_OFF==================")
		userPrint(35, "======================================= Precondition =================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:AddResumptionData_AddCommand()
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
												{
													cmdID = 1,
													menuParams = 	
													{ 
														menuName ="CommandWithImage"
													}, 
													vrCommands = 
													{ 
														"VRCommandWithImage",
														"VRCommandWithImagedouble"
													}, 
													cmdIcon = 	
													{ 
														value ="icon.png",
														imageType ="DYNAMIC"
													}
												})
		--hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 1,
							cmdIcon = 
							{
								value = storagePath.."icon.png",
								imageType = "DYNAMIC"
							},
							menuParams = 
							{ 
								menuName ="CommandWithImage"
							}
						})
		:Do(function(_,data)
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
								"VRCommandWithImage", 
								"VRCommandWithImagedouble"
							}
						})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		--mobile side: sending CreateInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = 1,
												choiceSet = 
												{ 
													
													{ 
														choiceID = 1,
														menuName = "Choice1",
														vrCommands = 
														{ 
															"VrChoice1",
														},
														image =
														{ 
															value ="icon.png",
															imageType ="DYNAMIC",
														}
													}
												}
											})
	
		
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = 1,
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						type = "Choice",
						vrCommands = {"VrChoice1"}
					})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			grammarIDValue = data.params.grammarID
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	
		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		--mobile side: sending SetGlobalProperties request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
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
							text = "VR help item",
							image = 
							{
								value = "icon.png",
								imageType = "DYNAMIC"
							}
						}
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title"
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
									text = "VR help item",
								--TODO: uncomment after resolving APPLINK-16052
									-- image = 
									-- {
									-- 	value = storagePath .. "icon.png",
									-- 	imageType = "DYNAMIC"
									-- }
								}
							},
							vrHelpTitle = "VR help title"
						})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		
		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:SUSPEND()
		SUSPEND(self)
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_failed_required_file_missed_IGN_OFF()
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", "RESUME_FAILED", false)

		-- hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand")
		:Times(0)

		-- hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand")
		:Times(0)

		-- hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Times(0)

		-- hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")

		-- hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Times(0)
			
		EXPECT_HMICALL("Navigation.SubscribeWayPoints")
			:Times(0)

		-- expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true, 
			name = "CUSTOM_BUTTON"
		})

		-- hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
		:Times(0)

		-- mobile side: expect OnHashChange notification
		--OnHashChange shall be sent once because of Buttons.OnButtonSubscription
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(1)
	end

	--======================================================================================--
	-- TM disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumtion Data is failed in case equired files are missed. TM disconnect==================")
		userPrint(35, "============================================ Precondition ==================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, false)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:AddResumptionData_AddCommand()
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
												{
													cmdID = 1,
													menuParams = 	
													{ 
														menuName ="CommandWithImage"
													}, 
													vrCommands = 
													{ 
														"VRCommandWithImage",
														"VRCommandWithImagedouble"
													}, 
													cmdIcon = 	
													{ 
														value ="icon.png",
														imageType ="DYNAMIC"
													}
												})
		--hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand", 
						{ 
							cmdID = 1,
							cmdIcon = 
							{
								value = storagePath.."icon.png",
								imageType = "DYNAMIC"
							},
							menuParams = 
							{ 
								menuName ="CommandWithImage"
							}
						})
		:Do(function(_,data)
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
								"VRCommandWithImage", 
								"VRCommandWithImagedouble"
							}
						})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		--mobile side: sending CreateInteractionChoiceSet request
		local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
												{
													interactionChoiceSetID = 1,
													choiceSet = 
													{ 
														
														{ 
															choiceID = 1,
															menuName = "Choice1",
															vrCommands = 
															{ 
																"VrChoice1",
															},
															image =
															{ 
																value ="icon.png",
																imageType ="DYNAMIC",
															}
														}
													}
												})
		
			
		--hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand", 
						{ 
							cmdID = 1,
							appID = self.applications[config.application1.registerAppInterfaceParams.appName],
							type = "Choice",
							vrCommands = {"VrChoice1"}
						})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			grammarIDValue = data.params.grammarID
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		--mobile side: sending SetGlobalProperties request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
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
							text = "VR help item",
							image = 
							{
								value = "icon.png",
								imageType = "DYNAMIC"
							}
						}
					},
					helpPrompt = 
					{
						{
							text = "Help prompt",
							type = "TEXT"
						}
					},
					vrHelpTitle = "VR help title"
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
									text = "VR help item",
								--TODO: uncomment after resolving APPLINK-16052
									-- image = 
									-- {
									-- 	value = storagePath .. "icon.png",
									-- 	imageType = "DYNAMIC"
									-- }
								}
							},
							vrHelpTitle = "VR help title"
						})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		
		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	function Test:CloseConnection()
	  	self.mobileConnection:Close() 
	end

	function Test:ConnectMobile()
		self:connectMobile()
	end

	function Test:StartSession()
	   	CreateSession(self)

	  	self.mobileSession:StartService(7)
	end

	function Test:Resumption_failed_required_file_missed_Disconnect()

		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", "RESUME_FAILED", false)

		-- hmi side: expect UI.AddCommand request
		EXPECT_HMICALL("UI.AddCommand")
			:Times(0)

		-- hmi side: expect VR.AddCommand request
		EXPECT_HMICALL("VR.AddCommand")
			:Times(0)

		-- hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Times(0)

		-- hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")

		-- hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Times(0)

		-- expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
				isSubscribed = true, 
				name = "CUSTOM_BUTTON"
			})

		-- hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
			:Times(0)

		-- mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Times(0)


	end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumtion Data is failed in case error code in response from HMI
--////////////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================--
	-- TM disconnect, error codes for some requests
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumtion Data is failed in case error code in response from HMI. TM disconnect==================")
		userPrint(35, "=========================================== Precondition ==========================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:AddResumptionData_AddCommand()
		AddCommand(self, 1)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_AddSubMenu()
		AddSubMenu(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleButton()
		SubscribleButton(self, "PRESET_0")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	-- function Test:DeactivateToNone()
	-- 	BringAppToNoneLevel(self)
	-- end

	function Test:SUSPEND()
		SUSPEND(self, "FULL")
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_error_code_ToSomeRequests_IGN_OFF()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

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
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " AddCommands request is rejected ")
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
			if (exp.occurences == 1) then
				local AddcommandTime = timestamp()
				local ResumptionTime =  AddcommandTime - time
				userPrint(33, "Time to resume VR.AddCommand "..tostring(ResumptionTime))
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", " AddCommands request is rejected ")
			elseif (exp.occurences == 2) then
				local CreateInteractionChoiceSetTime = timestamp()
				local ResumptionTime =  CreateInteractionChoiceSetTime - time
				userPrint(33, "Time to resume VR.AddCommand from choice "..tostring(ResumptionTime))
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end
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
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " AddSubMenu request is rejected ")
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
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " SubscribeVehicleData request is rejected ")	
		end)


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
												{},
												{
													timeoutPrompt = {
																		{
																			text = "Timeout prompt",
																			type = "TEXT"
																		}
																	},
													helpPrompt = {
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
													vrHelp = {
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

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	--======================================================================================--
	-- TM disconnect, error codes for all requests
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= TM disconnect, error codes for all requests==================")
		userPrint(35, "================================ Precondition =================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:AddResumptionData_CreateInteractionChoiceSet()
		CreateInteractionChoiceSet(self, 1)
	end

	function Test:AddResumptionData_SetGlobalProperites()
		SetGlobalProperites(self, "")
	end

	function Test:AddResumptionData_SubscribleVehicleData()
		SubscribleVehicleData(self, "gps")
	end

	-- function Test:DeactivateToNone()
	-- 	BringAppToNoneLevel(self)
	-- end

	function Test:CloseConnection()
	  	self.mobileConnection:Close() 
	end

	function Test:ConnectMobile()
		self:connectMobile()
	end

	function Test:StartSession()
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_data_error_code_ToAllRequests_Disconnect()
		--Requirement id in JAMA/or Jira ID: APPLINK-20056
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)


		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand",
						{ 
							cmdID = 1,							
							type = "Choice",
							vrCommands = {
											"VrChoice1"
										}
						})
		:Do(function(exp,data)
			local CreateInteractionChoiceSetTime = timestamp()
			local ResumptionTime =  CreateInteractionChoiceSetTime - time
			userPrint(33, "Time to resume VR.AddCommand from choice "..tostring(ResumptionTime))
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " AddCommand request is rejected ")
		end)

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})
		:Do(function(_,data)
			local SubscribeVehicleDataTime = timestamp()
			local ResumptionTime =  SubscribeVehicleDataTime - time
			userPrint(33, "Time to resume SubscribeVehicleData "..tostring(ResumptionTime))
		
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " SubscribeVehicleData request is rejected ")	
		end)


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
						{},
						{			
							timeoutPrompt = {
												{
													text = "Timeout prompt",
													type = "TEXT"
												}
											},
							helpPrompt = {
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
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " TTS.SetGlobalProperties request is rejected ")
		end)
		:Times(2)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
												{
													menuTitle = "Menu Title",
													vrHelp = {
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
			self.hmiConnection:SendError(data.id, data.method, "REJECTED", " UI.SetGlobalProperties request is rejected ")
		end)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

--////////////////////////////////////////////////////////////////////////////////////////////--
-- Resumption of HMI level and persistent data after Ignition off with a lot of data
--////////////////////////////////////////////////////////////////////////////////////////////--
	
	--======================================================================================--
	-- IGN_OFF
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of HMI level and persistent data after Ignition off with a lot of data ==================")
		userPrint(35, "=============================================== Precondition =========================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:ResumptionData()
		
		----------------------------------------------
		-- 10 commands, submenus
		----------------------------------------------
		for i=1, 10 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
										{
											cmdID = i,
											menuParams = {
															position = 0,
															menuName ="Command" .. tostring(i)
														}, 
											vrCommands = {"VRCommand" .. tostring(i)}
										})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
										{
											menuID = i,
											position = 10,
											menuName = "SubMenupositive" .. tostring(i)
										})
		end

		----------------------------------------------
		-- 10 InteractionChoices
		----------------------------------------------

		for i=1, 10 do
			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = i,
											choiceSet = { 						
															{ 
																choiceID = i,
																menuName = "Choice" .. tostring(i),
																vrCommands = { 
																				"VrChoice" .. tostring(i),
																			}
															}
														}
										})
		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
		:Times(10)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)
			
		-- mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
		:Times(10)

		-- mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
		:Times(10)

		buttonName = {"OK"}
		----------------------------------------------
		-- subscribe all buttons
		----------------------------------------------
		for m = 1, #buttonName do
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]

				})

		end 
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true				
		})
		:Times(#buttonName)

		--mobile side: expect SubscribeButton response
		-- EXPECT_RESPONSE("SubscribeButton", {success = true, resultCode = "SUCCESS"})
		-- 	:Times(#buttonName)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
		{ 
			gps = true,
			speed = true,
			rpm = true,
			fuelLevel = true,
			fuelLevel_State = true,
			instantFuelConsumption = true,
			externalTemperature = true,
			prndl = true,
			tirePressure = true,
			odometer = true,
			beltStatus = true,
			bodyInformation = true,
			deviceStatus = true,
			driverBraking = true,
			wiperStatus = true,			
			headLampStatus = true,
			engineTorque = true,
			accPedalPosition = true,
			steeringWheelAngle = true,
			eCallInfo = true,
			airbagStatus = true,
			emergencyEvent = true,
			clusterModeStatus = true,
			myKey = true
		})
		

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
		end)

		-- --mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})

		----------------------------------------------
		-- SetGlobalProperites
		----------------------------------------------

		--mobile side: sending SetGlobalProperties request
		self.mobileSession:SendRPC("SetGlobalProperties",
									{
										menuTitle = "Menu Title",
										timeoutPrompt = {
															{
																text = "Timeout prompt",
																type = "TEXT"
															}
														},
										vrHelp = {
													{
														position = 1,
														image = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																},
														text = "VR help item"
													}
												},
										menuIcon = {
														value = "icon.png",
														imageType = "DYNAMIC"
													},
										helpPrompt = {
														{
															text = "Help prompt",
															type = "TEXT"
														}
													},
										vrHelpTitle = "VR help title",
										keyboardProperties = {
																keyboardLayout = "QWERTY",
																keypressMode = "SINGLE_KEYPRESS",
																limitedCharacterList = { "a"},
																language = "EN-US",
																autoCompleteText = "Daemon, Freedom"
															}
									})

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		-- --mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = true, resultCode = "SUCCESS"})


		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(32 + #buttonName)
	end

	function Test:SUSPEND()
		SUSPEND(self, "FULL")
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_Data_10SubMenuCommandsChoices_allSubscriptionsProperties_IGN_OFF()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)
		----------------------------------------------
		-- 10 commands, 10 InteractionChoices
		----------------------------------------------
		EXPECT_HMICALL("UI.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)

		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- :Times(0)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- :Times(0)


		----------------------------------------------
		-- 10 submenus
		----------------------------------------------

		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- :Times(0)

		----------------------------------------------
		-- SetGlbalProperties
		----------------------------------------------

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- :Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
			{
				gps = true,
				speed = true,
				rpm = true,
				fuelLevel = true,
				fuelLevel_State = true,
				instantFuelConsumption = true,
				externalTemperature = true,
				prndl = true,
				tirePressure = true,
				odometer = true,
				beltStatus = true,
				bodyInformation = true,
				deviceStatus = true,
				driverBraking = true,
				wiperStatus = true,			
				headLampStatus = true,
				engineTorque = true,
				accPedalPosition = true,
				steeringWheelAngle = true,
				eCallInfo = true,
				airbagStatus = true,
				emergencyEvent = true,
				clusterModeStatus = true,
				myKey = true
			})
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- :Times(0)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Times(#buttonName + 1)

		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
	end

	--======================================================================================--
	-- TM disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of HMI level and persistent data after TM disconnect with a lot of data ==================")
		userPrint(35, "=============================================== Precondition ==========================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	    :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	    end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:ResumptionData()
		
		----------------------------------------------
		-- 10 commands, submenus
		----------------------------------------------
		for i=1, 10 do
			--mobile side: sending AddCommand request
			self.mobileSession:SendRPC("AddCommand",
										{
											cmdID = i,
											menuParams = {
															position = 0,
															menuName ="Command" .. tostring(i)
														}, 
											vrCommands = {"VRCommand" .. tostring(i)}
										})

			--mobile side: sending AddSubMenu request
			self.mobileSession:SendRPC("AddSubMenu",
			{
				menuID = i,
				position = 10,
				menuName = "SubMenupositive" .. tostring(i)
			})

		end

		----------------------------------------------
		-- 10 InteractionChoices
		----------------------------------------------

		for i=1, 10 do
			--mobile side: sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = i,
											choiceSet = { 
															{ 
																choiceID = i,
																menuName = "Choice" .. tostring(i),
																vrCommands = { 
																				"VrChoice" .. tostring(i),
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
		:Times(10)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
		:Times(10)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)
			
		-- mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
		:Times(10)

		-- mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
		:Times(10)

		buttonName = {"OK"}
		----------------------------------------------
		-- subscribe all buttons
		----------------------------------------------
		for m = 1, #buttonName do
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]
				})
		end 
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
			isSubscribed = true				
		})
		:Times(#buttonName)

		--mobile side: expect SubscribeButton response
		-- EXPECT_RESPONSE("SubscribeButton", {success = true, resultCode = "SUCCESS"})
		-- 	:Times(#buttonName)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
												{ 
													gps = true,
													speed = true,
													rpm = true,
													fuelLevel = true,
													fuelLevel_State = true,
													instantFuelConsumption = true,
													externalTemperature = true,
													prndl = true,
													tirePressure = true,
													odometer = true,
													beltStatus = true,
													bodyInformation = true,
													deviceStatus = true,
													driverBraking = true,
													wiperStatus = true,			
													headLampStatus = true,
													engineTorque = true,
													accPedalPosition = true,
													steeringWheelAngle = true,
													eCallInfo = true,
													airbagStatus = true,
													emergencyEvent = true,
													clusterModeStatus = true,
													myKey = true
												})
		
		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
		end)

		
		-- --mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})

		----------------------------------------------
		-- SetGlobalProperites
		----------------------------------------------

		--mobile side: sending SetGlobalProperties request
		self.mobileSession:SendRPC("SetGlobalProperties",
									{
										menuTitle = "Menu Title",
										timeoutPrompt = {
															{
																text = "Timeout prompt",
																type = "TEXT"
															}
														},
										vrHelp = {
													{
														position = 1,
														image = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																},
														text = "VR help item"
													}
												},
										menuIcon = {
														value = "icon.png",
														imageType = "DYNAMIC"
													},
										helpPrompt = {
														{
															text = "Help prompt",
															type = "TEXT"
														}
													},
										vrHelpTitle = "VR help title",
										keyboardProperties = {
																keyboardLayout = "QWERTY",
																keypressMode = "SINGLE_KEYPRESS",
																limitedCharacterList = {"a"},
																language = "EN-US",
																autoCompleteText = "Daemon, Freedom"
															}
									})

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		-- --mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = true, resultCode = "SUCCESS"})


		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(32 + #buttonName)
	end

	function Test:CloseConnection()
	  	self.mobileConnection:Close() 
	end

	function Test:ConnectMobile()
		self:connectMobile()
	end

	function Test:StartSession()
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_Data_10SubMenuCommandsChoices_allSubscriptionsProperties_Disconnect()
		--Requirement id in JAMA/or Jira ID: APPLINK-20056
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", _, _, true)
		----------------------------------------------
		-- 10 commands, 10 InteractionChoices
		----------------------------------------------
		EXPECT_HMICALL("UI.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)

		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(20)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- :Times(0)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- :Times(0)

		----------------------------------------------
		-- 10 submenus
		----------------------------------------------
		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(10)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- :Times(0)

		----------------------------------------------
		-- SetGlbalProperties
		----------------------------------------------

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- :Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
		{
			gps = true,
			speed = true,
			rpm = true,
			fuelLevel = true,
			fuelLevel_State = true,
			instantFuelConsumption = true,
			externalTemperature = true,
			prndl = true,
			tirePressure = true,
			odometer = true,
			beltStatus = true,
			bodyInformation = true,
			deviceStatus = true,
			driverBraking = true,
			wiperStatus = true,			
			headLampStatus = true,
			engineTorque = true,
			accPedalPosition = true,
			steeringWheelAngle = true,
			eCallInfo = true,
			airbagStatus = true,
			emergencyEvent = true,
			clusterModeStatus = true,
			myKey = true
		})
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- :Times(0)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		:Times(#buttonName + 1)

		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)

	end

	
	--======================================================================================--
	-- IGN_OFF
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of HMI level and persistent data after IGN_OFF with 500 commands, submenus and other ==================")
		userPrint(35, "============================================================ Precondition ==========================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:ResumptionData()
		
		----------------------------------------------
		-- 500 commands, submenus
		----------------------------------------------
		for i=1, 500 do
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

		end

		----------------------------------------------
		-- 100 InteractionChoices
		----------------------------------------------

		for i=1, 100 do
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
								"VrChoice" .. tostring(i),
							}
						}
					}
				})


		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(500)
		:Timeout(200000)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(600)
		:Timeout(200000)
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
		:Times(500)
		:Timeout(200000)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
		:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(500)
		:Timeout(200000)
			
		-- mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
		:Times(500)
		:Timeout(200000)

		-- mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
		:Times(100)
		:Timeout(200000)

		buttonName = {"OK"}
		----------------------------------------------
		-- subscribe all buttons
		----------------------------------------------
		for m = 1, #buttonName do
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]
				})

		end 
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
								{
									appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
									isSubscribed = true				
								})
		:Times(#buttonName)
		:Timeout(200000)

		--mobile side: expect SubscribeButton response
		-- EXPECT_RESPONSE("SubscribeButton", {success = true, resultCode = "SUCCESS"})
		-- 	:Times(#buttonName)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
			{ 
				gps = true,
				speed = true,
				rpm = true,
				fuelLevel = true,
				fuelLevel_State = true,
				instantFuelConsumption = true,
				externalTemperature = true,
				prndl = true,
				tirePressure = true,
				odometer = true,
				beltStatus = true,
				bodyInformation = true,
				deviceStatus = true,
				driverBraking = true,
				wiperStatus = true,			
				headLampStatus = true,
				engineTorque = true,
				accPedalPosition = true,
				steeringWheelAngle = true,
				eCallInfo = true,
				airbagStatus = true,
				emergencyEvent = true,
				clusterModeStatus = true,
				myKey = true
			})
		

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
		:Do(function(_,data)
			--hmi side: sending VehicleInfo.SubscribeVehicleData response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
		end)
		:Timeout(200000)

		-- --mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})
		:Timeout(200000)

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
						image = 
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						text = "VR help item"
					}
			},
			menuIcon = 
			{
				value = "icon.png",
				imageType = "DYNAMIC"
			},
			helpPrompt = 
			{
				{
					text = "Help prompt",
					type = "TEXT"
				}
			},
			vrHelpTitle = "VR help title",
			keyboardProperties = 
			{
				keyboardLayout = "QWERTY",
				keypressMode = "SINGLE_KEYPRESS",
				limitedCharacterList = 
				{
					"a"
				},
				language = "EN-US",
				autoCompleteText = "Daemon, Freedom"
			}
		})


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Timeout(200000)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Timeout(200000)

		-- --mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = true, resultCode = "SUCCESS"})
		:Timeout(200000)

		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		:Times(1102 + #buttonName)
		:Timeout(200000)

	end

	function Test:SUSPEND()
		SUSPEND(self, "FULL")
	end

	function Test:IGNITION_OFF()
		IGNITION_OFF(self)
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
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_ALotOfData_IGN_OFF()
		--Requirement id in JAMA/or Jira ID: APPLINK-15634
		--[Data Resumption]: Data resumption on IGNITION OFF
		
		--Requirement id in JAMA/or Jira ID: APPLINK-15670
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		
		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", "IGN_OFF", _, true)
		----------------------------------------------
		-- 500 commands, 100 InteractionChoices
		----------------------------------------------
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(500)
		:Timeout(300000)

		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(600)
		:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- 	:Times(0)
		-- 	:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- 	:Times(0)
		-- 	:Timeout(300000)


		----------------------------------------------
		-- 20 submenus
		----------------------------------------------

		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(500)
		:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- 	:Times(0)
		-- 	:Timeout(300000)

		----------------------------------------------
		-- SetGlbalProperties
		----------------------------------------------

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)
		:Timeout(300000)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- --mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- 	:Times(0)
		-- 	:Timeout(300000)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
			{
				gps = true,
				speed = true,
				rpm = true,
				fuelLevel = true,
				fuelLevel_State = true,
				instantFuelConsumption = true,
				externalTemperature = true,
				prndl = true,
				tirePressure = true,
				odometer = true,
				beltStatus = true,
				bodyInformation = true,
				deviceStatus = true,
				driverBraking = true,
				wiperStatus = true,			
				headLampStatus = true,
				engineTorque = true,
				accPedalPosition = true,
				steeringWheelAngle = true,
				eCallInfo = true,
				airbagStatus = true,
				emergencyEvent = true,
				clusterModeStatus = true,
				myKey = true
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
			end)
			:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- 	:Times(0)
		-- 	:Timeout(300000)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
			:Times(#buttonName + 1)
			:Timeout(300000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Timeout(300000)
	end

	--======================================================================================--
	-- TM disconnect
	--======================================================================================--

	function Test:UnregisterAppInterface_Success()
		userPrint(35, "================= Resumption of HMI level and persistent data after TM disconnect with 500 commands, submenus and other ==================")
		userPrint(35, "===================================================== Precondition =======================================================================")
		UnregisterAppInterface(self)
	end

	function Test:RegisterAppInterface_Success()
		RegisterApp_WithoutHMILevelResumption(self, _, _)
	end

	function Test:ActivateApp()
		ActivationApp(self)

		EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)	
	      :Do(function(_,data)
	        self.hmiLevel = data.payload.hmiLevel
	      end)
	end

	function Test:PutFile()
		local cid = self.mobileSession:SendRPC("PutFile",
		{			
			syncFileName = "icon.png",
			fileType	= "GRAPHIC_PNG",
			persistentFile = false,
			systemFile = false
		}, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end

	function Test:ResumptionData()
		----------------------------------------------
		-- 500 commands, submenus
		----------------------------------------------
		for i=1, 500 do
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

		end

		----------------------------------------------
		-- 100 InteractionChoices
		----------------------------------------------

		for i=1, 100 do
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
								"VrChoice" .. tostring(i),
							}
						}
					}
				})


		end

	
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(500)
			:Timeout(300000)

		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending VR.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(600)
			:Timeout(300000)
		
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE("AddCommand", {  success = true, resultCode = "SUCCESS"  })
			:Times(500)
			:Timeout(300000)

		--hmi side: expect UI.AddSubMenu request
		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddSubMenu response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(500)
			:Timeout(300000)
			
		--mobile side: expect AddSubMenu response
		EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" })
			:Times(500)
			:Timeout(300000)

		--mobile side: expect CreateInteractionChoiceSet response
		EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
			:Times(100)
			:Timeout(300000)


		----------------------------------------------
		-- subscribe all buttons
		----------------------------------------------
		for m = 1, #buttonName do
			--mobile side: sending SubscribeButton request
			local cid = self.mobileSession:SendRPC("SubscribeButton",
				{
					buttonName = buttonName[m]

				})

		end 
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
			{
				appID = self.applications[config.application1.registerAppInterfaceParams.appName], 
				isSubscribed = true				
			})
			:Times(#buttonName)
			:Timeout(300000)

		--mobile side: expect SubscribeButton response
		-- EXPECT_RESPONSE("SubscribeButton", {success = true, resultCode = "SUCCESS"})
		-- 	:Times(#buttonName)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--mobile side: sending SubscribeVehicleData request
		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
			{ 
				gps = true,
				speed = true,
				rpm = true,
				fuelLevel = true,
				fuelLevel_State = true,
				instantFuelConsumption = true,
				externalTemperature = true,
				prndl = true,
				tirePressure = true,
				odometer = true,
				beltStatus = true,
				bodyInformation = true,
				deviceStatus = true,
				driverBraking = true,
				wiperStatus = true,			
				headLampStatus = true,
				engineTorque = true,
				accPedalPosition = true,
				steeringWheelAngle = true,
				eCallInfo = true,
				airbagStatus = true,
				emergencyEvent = true,
				clusterModeStatus = true,
				myKey = true
			})
		

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})	
			end)
			:Timeout(300000)

		
		--mobile side: expect SubscribeVehicleData response
		EXPECT_RESPONSE("SubscribeVehicleData", { success = true, resultCode = "SUCCESS", gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"}})
		:Timeout(300000)

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
						image = 
						{
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						text = "VR help item"
					}
				},
				menuIcon = 
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				helpPrompt = 
				{
					{
						text = "Help prompt",
						type = "TEXT"
					}
				},
				vrHelpTitle = "VR help title",
				keyboardProperties = 
				{
					keyboardLayout = "QWERTY",
					keypressMode = "SINGLE_KEYPRESS",
					limitedCharacterList = 
					{
						"a"
					},
					language = "EN-US",
					autoCompleteText = "Daemon, Freedom"
				}
			})


		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Timeout(300000)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Timeout(300000)


		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE("SetGlobalProperties", { success = true, resultCode = "SUCCESS"})
		:Timeout(300000)


		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Times(1102 + #buttonName)
			:Timeout(300000)
	end

	function Test:CloseConnection()
	  	self.mobileConnection:Close() 
	end

	function Test:ConnectMobile()
		self:connectMobile()
	end

	function Test:StartSession()
		CreateSession(self)

		self.mobileSession:StartService(7)
	end

	function Test:Resumption_ALotOfData_Disconnect()
		--Requirement id in JAMA/or Jira ID: APPLINK-20056	
		--[Data Resumption]: RegisterAppInterface with hashID the same as stored before
		userPrint(34, "=================== Test Case ===================")

		config.application1.registerAppInterfaceParams.hashID = self.currentHashID

		RegisterApp_HMILevelResumption(self, "FULL", _, _, true)
		----------------------------------------------
		-- 500 commands, 100 InteractionChoices
		----------------------------------------------
		EXPECT_HMICALL("UI.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(500)
		:Timeout(200000)

		EXPECT_HMICALL("VR.AddCommand")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(600)
		:Timeout(200000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddCommand")
		-- 	:Times(0)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("CreateInteractionChoiceSet")
		-- 	:Times(0)


		----------------------------------------------
		-- 20 submenus
		----------------------------------------------

		EXPECT_HMICALL("UI.AddSubMenu")
			:Do(function(_,data)
				--hmi side: sending UI.AddCommand response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		:Times(500)
		:Timeout(200000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		-- EXPECT_RESPONSE("AddSubMenu")
		-- 	:Times(0)

		----------------------------------------------
		-- SetGlbalProperties
		----------------------------------------------

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties")
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:Times(2)
		:Timeout(200000)



		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties")
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Timeout(200000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SetGlobalProperties response
		-- EXPECT_RESPONSE("SetGlobalProperties")
		-- 	:Times(0)

		----------------------------------------------
		-- SubscribeVehicleData
		----------------------------------------------

		--hmi side: expect SubscribeVehicleData request
		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
			{
				gps = true,
				speed = true,
				rpm = true,
				fuelLevel = true,
				fuelLevel_State = true,
				instantFuelConsumption = true,
				externalTemperature = true,
				prndl = true,
				tirePressure = true,
				odometer = true,
				beltStatus = true,
				bodyInformation = true,
				deviceStatus = true,
				driverBraking = true,
				wiperStatus = true,			
				headLampStatus = true,
				engineTorque = true,
				accPedalPosition = true,
				steeringWheelAngle = true,
				eCallInfo = true,
				airbagStatus = true,
				emergencyEvent = true,
				clusterModeStatus = true,
				myKey = true
			})
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.SubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
			end)
			:Timeout(200000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeVehicleData response
		-- EXPECT_RESPONSE("SubscribeVehicleData")
		-- 	:Times(0)
 
 		----------------------------------------------
		-- SubscribeButtons
		----------------------------------------------
		
		--expect Buttons.OnButtonSubscription
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
			:Times(#buttonName + 1)
			:Timeout(200000)

		-- TODO: Uncomment after resolving ATf defect APPLINK-24873
		--mobile side: expect SubscribeButtons response
		-- EXPECT_RESPONSE("SubscribeButton")
		-- 	:Times(0)

		EXPECT_NOTIFICATION("OnHashChange")
			:Do(function(_, data)
				self.currentHashID = data.payload.hashID
			end)
			:Timeout(200000)
	end

	function Test:Postcondition_RestoreIniFile()
		commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end

