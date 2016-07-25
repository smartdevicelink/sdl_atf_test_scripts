---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last update date: 18/Dec/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-------------------------------------------- Preconditions --------------------------------------
-------------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

	function Precondition_ArchivateINI()
	    commonPreconditions:BackupFile("smartDeviceLink.ini")
	end

	function Precondition_EnableProtocol4()
	    local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
	    local StringToReplace = "EnableProtocol4 = true\n"
	    f = assert(io.open(SDLini, "r"))
	    if f then
	        fileContent = f:read("*all")

	        fileContentUpdated  =  string.gsub(fileContent, "%p?EnableProtocol4%s-=%s?[%w%d;]-\n", StringToReplace)

	        if fileContentUpdated then
	          f = assert(io.open(SDLini, "w"))
	          f:write(fileContentUpdated)
	        else 
	          userPrint(31, "Finding of 'EnableProtocol4 = value' is failed. Expect string finding and replacing of value to true")
	        end
	        f:close()
	    end
	end

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnAppRegistered.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnAppRegistered.lua")

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnAppRegistered')
local mobile_session = require('mobile_session')
require('cardinalities')
local events = require('events')
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
SDLConfigurations = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')


local AppIconsFolder = SDLConfigurations:GetValue("AppIconsFolder")
local AppStorageFolder = SDLConfigurations:GetValue("AppStorageFolder")

---------------------------------------------------------------------------------------------
------------------------------------------Common variables-----------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()

	Precondition_ArchivateINI()
	Precondition_EnableProtocol4()

	-- Precondition: removing user_modules/connecttest_OnAppRegistered.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnAppRegistered.lua" )
	end

	--TODO: Remove print after resolving APPLINK-16052
	userPrint( 33, "Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.OnAppRegistered is commented.")
	--UPDATED according to APPLINK-23428
	--userPrint( 33, "Expected result is under clarification. Absence of icon in actual results are not defect for now (APPLINK-17869).")
	
----------------------------------------------------------------------------------------------
--SDLAQ-TC-1364: TC_OnAppRegistered_02 (genivi_only)
--APPLINK-18436: 05[P][MAN]_TC_SDL_sends_optional_icon_in_OnAppRegistered_during_RAI	
--Verification criteria: Check that SDL sends optional icon parameter in OnAppRegistered notification
----------------------------------------------------------------------------------------------
--Note: 
	--Copy file https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/manual_test_cases/SDL4.0/QUERRY_jsons/query_app_response.json to "/files/jsons/QUERRY_jsons/query_app_response.json"
	--TODO: update after resolving APPLINK-16052
	--TODO: Update when APPLINK-16050 is closed
	--TODO: Blocked issue APPLINK-18865. Script will be debugged when this issue is closed
----------------------------------------------------------------------------------------------
	local function TC_OnAppRegistered_02()
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppRegistered_02/05[P][MAN]_TC_SDL_sends_optional_icon_in_OnAppRegistered_during_RAI")
		
		--Step 1: Precondition:
		function Test:Precondition_Unregister_Application()
			
			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
		end 	

		--ToDo: shall be removed when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
		function ReRegisterAppInterface(self) 

		
			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", 
																				{
																					syncMsgVersion =
																					{
																					  majorVersion = 3,
																					  minorVersion = 0
																					},
																					appName = "Awesome Music App",
																					isMediaApplication = true,
																					languageDesired = "EN-US",
																					hmiDisplayLanguageDesired = "EN-US",
																					appHMIType = { "DEFAULT" },
																					appID = "853426",
																					deviceInfo =
																					{
																					  os = "Android",
																					  carrier = "Megafon",
																					  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
																					  osVersion = "4.4.2",
																					  maxNumberRFCOMMPorts = 1
																					}
																				})
			

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = "Awesome Music App",
					policyAppID = "853426",
					isMediaApplication = true,					
					hmiDisplayLanguageDesired = "EN-US",
					appType = { "DEFAULT" }
				}
			})
			--UPDATED according to APPLINK-23428
			:ValidIf(function(_,data)
			 	--verify OnAppRegistered notification does not contan "icon" parameter
				if data.params.application.icon == nil then
					commonFunctions:printError(" OnAppRegistered notification came without icon parameter ")
					return false
				else 									
					return true
				end
			end)		

			
		end
		
		-- Step 2: Open SyncProxyTesterAlice, specify next parameters: protocol version 1,4; AppName: Awesome Music App; AppID: 853426; "Set app icon after registration" is checked, all other paramerters leave by default, click OK
		-- Expected result: SyncProxyTester sends RegisterAppInterface request. SDL sends to HMI OnAppRegistered notification "icon" should be absent due to no icon is provided for the App. After successful registration SPTAlice sends PutFile and SetAppIcon setting the icon for the App. 

		function Test:RegisterAppInterface_Verify_OnAppRegistered_icon() 
			print("\27[31m Register application again because of APPLINK-24902: Genivi: Unexpected unregistering application at resumption after closing session.\27[0m")
		
			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", 
																				{
																					syncMsgVersion =
																					{
																					  majorVersion = 3,
																					  minorVersion = 0
																					},
																					appName = "Awesome Music App",
																					isMediaApplication = true,
																					languageDesired = "EN-US",
																					hmiDisplayLanguageDesired = "EN-US",
																					appHMIType = { "DEFAULT" },
																					appID = "853426",
																					deviceInfo =
																					{
																					  os = "Android",
																					  carrier = "Megafon",
																					  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
																					  osVersion = "4.4.2",
																					  maxNumberRFCOMMPorts = 1
																					}
																				})
			

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = "Awesome Music App",
					policyAppID = "853426",
					isMediaApplication = true,					
					hmiDisplayLanguageDesired = "EN-US",
					appType = { "DEFAULT" }
				}
			})
			--ToDo: shall be removed when APPLINK-24902: "Genivi: Unexpected unregistering application at resumption after closing session" is fixed
			:Do(function(_,data)
				local result = true
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {})
				:ValidIf(function(_,data)		
					result = ReRegisterAppInterface(self)
					return result
				end)
			end)
			--UPDATED: according to APPLINK-23428
			:ValidIf(function(_,data)
			 	--verify OnAppRegistered notification does not contan "icon" parameter
				if data.params.application.icon == nil then
					commonFunctions:printError(" OnAppRegistered notification came without icon parameter ")
					return false
				else 									
					return true
				end
			end)	

			
			--mobile side: RegisterAppInterface response 
			EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
			
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			EXPECT_NOTIFICATION("OnPermissionsChange", {})

		end

		-- Put file and set appIcon
		commonSteps:PutFile("PutFile_icon", "icon.png")
		
		function Test:SetAppIcon()
				
			local storagePath = config.pathToSDL .. AppStorageFolder .. "/853426".. "_" .. config.deviceMAC.. "/"
		
			--mobile side: sending SetAppIcon request
			local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })

			--hmi side: expect UI.SetAppIcon request
			EXPECT_HMICALL("UI.SetAppIcon",
			{
				--Verified below
				-- syncFileName = 
				-- {
				-- 	imageType = "DYNAMIC",
				-- 	value = storagePath .. "icon.png"
				-- }				
			})
			:ValidIf(function(_,data)
				local result = true
				local path  = "bin/storage/853426".. "_" .. config.deviceMAC.. "/"
          		local value_Icon = path .. "icon.png"

				if (data.params.syncFileName.imageType ~= "DYNAMIC") then
    				print("\27[31m imageType of syncFileName is WRONG. Expected: DYNAMIC; Real: " .. data.params.syncFileName.imageType .. "\27[0m")
    				result = false
    			end

			    if(string.find(data.params.syncFileName.value, value_Icon) ) then
			    else
    				print("\27[31m value of syncFileName is WRONG. Expected: ~/".. value_Icon .. "; Real: " .. data.params.syncFileName.value .. "\27[0m")
    				result = false
    			end

    			return result
			end)
			:Do(function(_,data)
				--hmi side: sending UI.SetAppIcon response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect SetAppIcon response
			EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })		
		end
		
		
		-- Step 3: Open SyncProxyTester, specify next parameters: protocol version 1,4; heartbeat unchecked; Media checked; AppName: SPT; AppID: 1234567; all other paramerters leave by default, click OK
		-- Expected result: SyncProxyTester sends RegisterAppInterface request. SDL sends to HMI OnAppRegistered notification, where application parameter contains: appName: SPT; deviceName: from UpdateDeviceList notification to HMI; appID: 1234567; device ID = hash of "usb_serial"(in case of USB connection) or hash of "device's MAC address" (in case of BlueTooth or WiFi connection), TransportType: "USB_AOA" or "USB_IOS" or "BLUETOOTH" or "WIFI"; isMediaApplicatin: true. Among other parameters there should be "icon" with path to Awesome Music App icon. After successfull registration SPT sends OnHMIStatus notification to SDL that SPT is current App on phone. SDL sends OnSystemRequest(QUERRY_APPS), SPT replay with json. SDL sends to HMI UpdateAppList with all Apps - current + from json
		
		function Test:AddSession2_Protocol4()

			self.mobileSession2 = mobile_session.MobileSession(self,self.mobileConnection)
			self.mobileSession2.version = 4
			self.mobileSession2:StartService(7)
			
		end	
		
		function Test:RegisterAppInterface_App2_And_Verify_OnAppRegistered_policyAppID() 


			
			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", {
																					syncMsgVersion =
																					{
																					  majorVersion = 3,
																					  minorVersion = 0
																					},
																					appName = "SPT",
																					isMediaApplication = true,
																					languageDesired = 'EN-US',
																					hmiDisplayLanguageDesired = 'EN-US',
																					appHMIType = { "DEFAULT" },
																					appID = "1234567",
																					deviceInfo =
																					{
																					  os = "Android",
																					  carrier = "Megafon",
																					  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
																					  osVersion = "4.4.2",
																					  maxNumberRFCOMMPorts = 1
																					}
																				})
			
			--ToDo: Shall be uncommented when APPLINK-24972 is fixed
			--mobile side: expect OnSystemRequest notification and send SystemRequest
			--[[self.mobileSession2:ExpectNotification("OnSystemRequest", 	
														{requestType = "LOCK_SCREEN_ICON_URL"},
														{requestType = "QUERRY_APPS", fileType = "BINARY"})
			:Times(2)
			:Do(function(exp,data)
				if data.payload.requestType == "QUERRY_APPS" then
					--mobile side: sending SystemRequest request 
					local CorIdSystemRequest = self.mobileSession2:SendRPC("SystemRequest",
						{
							fileName = "queryAppsResponse",
							requestType = "QUERRY_APPS"
						},
					"./files/jsons/QUERRY_jsons/query_app_response.json")
				end
				
			end)]]
			
			
			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = "SPT",
					policyAppID = "1234567",
					--[=[TODO: update after resolving APPLINK-16052
					deviceInfo = 
					{
						name = "127.0.0.1",
						id = config.deviceMAC,
						transportType = "WIFI",
						isSDLAllowed = true
					},]=]	
					isMediaApplication = true,
					--ToDo: shall be updated when APPLINK-23428 is implemented
					--icon = config.pathToSDL .. AppIconsFolder .."/853426"
									
				}
			})
			:ValidIf(function(_,data)
				local result = true

				if data.params.application.appID == nil or type(data.params.application.appID) ~= "number" then
					commonFunctions:printError(" OnAppRegistered notification came with appID parameter is nil or not a number ")
					result = (result and false)
				else 			
					self.applications["SPT"] = data.params.application.appID
					result = (result and true)
				end

				return result
			end)		
			
			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
			
			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			:Do(function(_, data)
				--mobile side: send HMI level notification to SDL
				local msg = 
					{
					  serviceType      = 7,
					  frameInfo        = 0,
					  rpcType          = 2,
					  rpcFunctionId    = 32768,
					  rpcCorrelationId = 0,
					  payload          = '{"hmiLevel" :"FULL", "audioStreamingState" : "NOT_AUDIBLE", "systemContext" : "MAIN"}'
					}

				self.mobileSession2:Send(msg)
			end)
			
			--mobile side: expect OnPermissionsChange notification
			self.mobileSession2:ExpectNotification("OnPermissionsChange", {})
			
			EXPECT_HMICALL("BasicCommunication.UpdateAppList", {applications = {
																					--ToDo: Parameter greyOut shall be uncommented when APPLINK-24972 is fixed
																					{appName = "Awesome Music App", --[[greyOut = false,]] },
																					{appName = "SPT"}
																					--ToDo: Shall be verified at review why such application is not registered. In test no conditions for registering were found
																					--{appName = "SPTAlice", greyOut = false,icon = config.pathToSDL ..AppIconsFolder  .. "/1461058790"}}
																					
																}})
			:ValidIf(function(_,data)
				local result = true
				local path  = "bin/storage/853426".. "_" .. config.deviceMAC.. "/"
          		local value_Icon = path .. "icon.png"

				--icon = config.pathToSDL .. AppIconsFolder .. "/853426"
			    if(string.find(data.params.applications[1].icon, value_Icon) ) then
			    else
    				print("\27[31m value of icon is WRONG. Expected: ~/".. value_Icon .. "; Real: " .. data.params.applications[1].icon .. "\27[0m")
    				result = false
    			end

    			return result
			end)
																					

		end
		
			
	end

	TC_OnAppRegistered_02()



	function Test:Postcondition_StopSDL_IfItIsStillRunning()
		print("----------------------------------------------------------------------------------------------")
		StopSDL()
	end


function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

return Test